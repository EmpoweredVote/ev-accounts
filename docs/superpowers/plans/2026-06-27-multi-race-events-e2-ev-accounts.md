# Multi-Race Events — E2 (ev-accounts) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the ev-accounts API treat a meeting's races as a set backed by the new `meetings.event_races` join table — returning `raceIds[]` on meetings, supporting a race→meetings filter, and removing all use of the single `meetings.meetings.race_id` column (admin endpoints stop setting races).

**Architecture:** Add the `meetings.event_races` join table (migration) + backfill from the existing `race_id` column; switch `meetingsService.ts` reads to aggregate `raceIds[]` via a correlated subquery and add a `raceId` list filter; drop `race_id` from the admin create/update paths, the entity-state validator, and the route Zod schemas; finally drop the `race_id` column in a gated migration.

**Tech Stack:** Node + TypeScript, raw `pg` SQL (no ORM), Express, Zod, Vitest (DB mocked via `vi.mock('./db.js')`). Run from `backend/`: build `npm run build`, typecheck `npm run typecheck`, tests `npm test`. Numbered SQL migrations in `backend/migrations/` (latest is 1070; applied via the project's existing migration process, not npm).

**Spec:** `on-the-record/docs/superpowers/specs/2026-06-27-multi-race-events-design.md` (shared design; E1 is the pipeline-side plan in that repo).

**Coordination (critical):** This is the read/write half of a cross-repo change. Deploy order: (1) Task 1 migration here → (2) on-the-record E1 deploy (publish writes the join table) → (3) Tasks 2–5 here deploy (reads switched to the join) → (4) Task 6 migration here (drop the column). **Task 6's DROP must be applied only after Tasks 2–5 are live**, or readers of the old column break. Tasks 1–5 are safe to write and ship; Task 6 is gated.

---

## File Structure

- **Create `backend/migrations/1071_event_races.sql`** — create `meetings.event_races` + index + backfill from `meetings.meetings.race_id`.
- **Create `backend/migrations/1072_drop_meetings_race_id.sql`** — gated `DROP COLUMN race_id` (applied last, after Tasks 2–5 deploy).
- **Modify `backend/src/lib/eventEntityRules.ts`** — drop `raceId` from `EventEntityState` and the validator.
- **Modify `backend/src/lib/meetingsService.ts`** — `raceIds[]` on the `Meeting`/`MeetingRow` types + `mapMeeting`; `MEETING_COLS` aggregates `race_ids`; `getMeetings` gains a `raceId` filter; `getMeetingEntityState`, `createMeeting`, `updateMeeting` drop `race_id`.
- **Modify `backend/src/routes/meetings.ts`** — drop `raceId` from the Zod schemas + validator calls + PATCH `nextState`; add `?raceId=` filter to `GET /api/meetings`.
- **Modify the tests:** `backend/src/lib/eventEntityRules.test.ts`, `backend/src/lib/meetingsService.test.ts`, `backend/src/routes/meetings.test.ts`.

---

## Task 1: Migration — create `meetings.event_races` + backfill

**Files:**
- Create: `backend/migrations/1071_event_races.sql`

Context: migrations are numbered `NNNN_*.sql`, wrapped in `BEGIN/COMMIT`, with idempotent guards (see `579_event_entity_fks.sql`). Migration 579 created `meetings.meetings.race_id UUID REFERENCES essentials.races(id)` and index `meetings_meetings_race_id_idx`. This migration adds the join table and backfills existing single-race links; it does **not** drop the column (that's Task 6).

- [ ] **Step 1: Write the migration**

Create `backend/migrations/1071_event_races.sql`:

```sql
-- Migration 1071: meetings.event_races — a meeting belongs to MANY races.
-- Replaces the single meetings.meetings.race_id (dropped in 1072, after the
-- API is switched to read this table). Backfills existing single-race links.

BEGIN;

CREATE TABLE IF NOT EXISTS meetings.event_races (
  meeting_id UUID NOT NULL REFERENCES meetings.meetings(id) ON DELETE CASCADE,
  race_id    UUID NOT NULL REFERENCES essentials.races(id),
  PRIMARY KEY (meeting_id, race_id)          -- serves meeting -> races
);

CREATE INDEX IF NOT EXISTS event_races_race_id_idx
  ON meetings.event_races (race_id);          -- serves race -> meetings

-- Backfill from the existing single-race column.
INSERT INTO meetings.event_races (meeting_id, race_id)
SELECT id, race_id
FROM meetings.meetings
WHERE race_id IS NOT NULL
ON CONFLICT DO NOTHING;

COMMIT;
```

- [ ] **Step 2: Apply it via the project's migration process** (staging/dev DB first, the same way 1070 was applied). Then verify the backfill:

```sql
-- row count matches the number of meetings that had a race_id
SELECT
  (SELECT COUNT(*) FROM meetings.meetings WHERE race_id IS NOT NULL) AS old_single,
  (SELECT COUNT(*) FROM meetings.event_races) AS new_rows;
```
Expected: `new_rows >= old_single` (≥ because the on-the-record pipeline may have already written multi-race rows for forums by deploy time). At minimum every old single race is present.

- [ ] **Step 3: Commit**

```bash
git add backend/migrations/1071_event_races.sql
git commit -m "feat(multi-race): add meetings.event_races join table + backfill (migration 1071)"
```

---

## Task 2: `eventEntityRules` — drop `raceId`

**Files:**
- Modify: `backend/src/lib/eventEntityRules.ts`
- Test: `backend/src/lib/eventEntityRules.test.ts`

Context: races are now derived/owned by the pipeline and stored in `event_races`; ev-accounts no longer validates a meeting's `raceId`. The validator keeps only the chamber rules.

- [ ] **Step 1: Update the test** — In `backend/src/lib/eventEntityRules.test.ts`, replace any case that sets/asserts `raceId` with the chamber-only rules. The full intended test body:

```typescript
import { describe, it, expect } from 'vitest';
import { validateEventEntities } from './eventEntityRules.js';

const CHAMBER = '11111111-1111-4111-8111-111111111111';

describe('validateEventEntities', () => {
  it('requires chamberId for council and school_board', () => {
    expect(validateEventEntities({ eventKind: 'council', chamberId: null })).toMatch(/chamberId is required/);
    expect(validateEventEntities({ eventKind: 'school_board', chamberId: null })).toMatch(/chamberId is required/);
    expect(validateEventEntities({ eventKind: 'council', chamberId: CHAMBER })).toBeNull();
  });

  it('does not require anything for debate/forum (races derived from candidates)', () => {
    expect(validateEventEntities({ eventKind: 'debate', chamberId: null })).toBeNull();
    expect(validateEventEntities({ eventKind: 'forum', chamberId: null })).toBeNull();
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npm test -- eventEntityRules`
Expected: FAIL — `EventEntityState` still requires `raceId`, and/or the import shape differs.

- [ ] **Step 3: Update the implementation** — Replace `backend/src/lib/eventEntityRules.ts` with:

```typescript
import type { EventKind } from './eventKinds.js';

export interface EventEntityState {
  eventKind: EventKind;
  chamberId: string | null;
}

export function validateEventEntities(
  state: EventEntityState
): string | null {
  if (
    (state.eventKind === 'council' || state.eventKind === 'school_board') &&
    state.chamberId === null
  ) {
    return `chamberId is required for eventKind ${state.eventKind}`;
  }
  return null;
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd backend && npm test -- eventEntityRules`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/eventEntityRules.ts backend/src/lib/eventEntityRules.test.ts
git commit -m "feat(multi-race): eventEntityRules drops raceId (races derived in pipeline)"
```

---

## Task 3: `meetingsService` — `raceIds[]` reads, `raceId` filter, drop column writes

**Files:**
- Modify: `backend/src/lib/meetingsService.ts` — `Meeting` (line ~45), `MeetingRow` (line ~153), `mapMeeting` (line ~230), `MEETING_COLS` (line ~311), `getMeetings` (line ~318), `getMeetingEntityState` (line ~604), `createMeeting` (line ~530), `updateMeeting` (line ~553).
- Test: `backend/src/lib/meetingsService.test.ts`

Context: raw `pg`. `MEETING_COLS` is the shared SELECT list used by `getMeetings`, `getMeetingById`, and the `RETURNING` of `createMeeting`/`updateMeeting`. Tests mock `pool.query` via `vi.mock('./db.js')` and a `baseRow` fixture; that fixture currently has `race_id: null` (line ~45 of the test).

- [ ] **Step 1: Update the tests** — In `backend/src/lib/meetingsService.test.ts`:
  (a) In the `baseRow` fixture, replace `race_id: null,` with `race_ids: [],`.
  (b) Add these tests (append inside the file, after the existing `getMeetings`/`getMeetingById` describes):

```typescript
describe('raceIds (event_races)', () => {
  it('maps race_ids array onto the meeting payload', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{ ...baseRow, event_kind: 'forum', race_ids: ['race-clerk', 'race-pros'] }],
    });
    const m = await getMeetingById('m1');
    expect(m).not.toBeNull();
    expect(m!.raceIds).toEqual(['race-clerk', 'race-pros']);
    // getMeetingById issues a 2nd query for speakers; serve an empty set.
  });

  it('defaults raceIds to [] when null', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ ...baseRow, race_ids: null }] });
    const [item] = await getMeetings();
    expect(item.raceIds).toEqual([]);
  });

  it('filters meetings by raceId via event_races', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });
    await getMeetings({ raceId: '22222222-2222-4222-8222-222222222222' });
    const sql = mockQuery.mock.calls[0][0] as string;
    const params = mockQuery.mock.calls[0][1] as unknown[];
    expect(sql).toMatch(/meetings\.event_races/);
    expect(params).toContain('22222222-2222-4222-8222-222222222222');
  });
});

describe('admin writes no longer touch race_id', () => {
  it('createMeeting INSERT omits race_id', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });
    await createMeeting({ state: 'IN', date: '2026-02-18', meetingType: 'City Council' });
    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).not.toMatch(/race_id/);
  });

  it('updateMeeting SET omits race_id even if passed', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [baseRow] });
    // @ts-expect-error raceId is no longer part of the update type
    await updateMeeting('m1', { raceId: 'x' });
    // With only an unknown field, there are no SET clauses → falls back to getMeetingById path.
    // Assert no UPDATE wrote race_id.
    const calls = mockQuery.mock.calls.map((c) => c[0] as string);
    expect(calls.some((s) => /UPDATE meetings\.meetings[\s\S]*race_id/.test(s))).toBe(false);
  });
});
```

Note for the first test: `getMeetingById` runs a second `pool.query` for speakers — add `mockQuery.mockResolvedValueOnce({ rows: [] })` after the first mock if the test framework requires both queues; adjust to the file's existing convention for `getMeetingById` tests (they already handle the two-query shape elsewhere — mirror that).

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd backend && npm test -- meetingsService`
Expected: FAIL (raceIds undefined; SQL still references `race_id`).

- [ ] **Step 3: Update the type + mapper** — In `backend/src/lib/meetingsService.ts`:
  (a) `Meeting` interface (line ~45): replace `raceId: string | null;` with `raceIds: string[];`.
  (b) `MeetingRow` interface (line ~153): replace `race_id: string | null;` with `race_ids: string[] | null;`.
  (c) `mapMeeting` (line ~230): replace `raceId: row.race_id,` with `raceIds: row.race_ids ?? [],`.

- [ ] **Step 4: Update `MEETING_COLS`** (line ~311) — remove `race_id` and add an aggregated `race_ids` correlated subquery:

```typescript
const MEETING_COLS = `
  id, title, event_kind, city, state, date::text AS date, meeting_type,
  duration_seconds, video_url, audio_source,
  status, segment_count, speaker_count, created_at, updated_at,
  chamber_id,
  COALESCE(
    (SELECT array_agg(er.race_id) FROM meetings.event_races er
     WHERE er.meeting_id = meetings.meetings.id),
    ARRAY[]::uuid[]
  ) AS race_ids,
  source_url, playback_kind, slug, summary, processing_metadata
`;
```

(The correlated subquery references `meetings.meetings.id`; it resolves in `getMeetings`/`getMeetingById` (`FROM meetings.meetings`) and in the `RETURNING` of create/update. `pg` returns `uuid[]` as a JS `string[]`.)

- [ ] **Step 5: Add the `raceId` filter to `getMeetings`** (line ~318) — extend the filter type and conditions:

```typescript
export async function getMeetings(
  filters?: { city?: string; state?: string; status?: string; raceId?: string }
): Promise<MeetingListItem[]> {
  const params: string[] = [];
  const conditions: string[] = [];

  if (filters?.city !== undefined) {
    params.push(filters.city);
    conditions.push(`city = $${params.length}`);
  }
  if (filters?.state !== undefined) {
    params.push(filters.state);
    conditions.push(`state = $${params.length}`);
  }
  if (filters?.status !== undefined) {
    params.push(filters.status);
    conditions.push(`status = $${params.length}`);
  }
  if (filters?.raceId !== undefined) {
    params.push(filters.raceId);
    conditions.push(
      `EXISTS (SELECT 1 FROM meetings.event_races er
               WHERE er.meeting_id = meetings.meetings.id
                 AND er.race_id = $${params.length}::uuid)`
    );
  }
  // ...unchanged whereClause + query below...
```

(Leave the rest of `getMeetings` — `whereClause`, the `pool.query`, `rows.map(mapMeetingListItem)` — unchanged.)

- [ ] **Step 6: Drop `race_id` from `getMeetingEntityState`** (line ~604) — it now returns only `eventKind` + `chamberId`:

```typescript
export async function getMeetingEntityState(
  id: string
): Promise<EventEntityState | null> {
  const { rows } = await pool.query<{ event_kind: EventKind; chamber_id: string | null }>(
    `SELECT event_kind, chamber_id FROM meetings.meetings WHERE id = $1`,
    [id]
  );
  if (rows.length === 0) return null;
  return { eventKind: rows[0].event_kind, chamberId: rows[0].chamber_id };
}
```

- [ ] **Step 7: Drop `race_id` from `createMeeting`** (line ~530) — remove `raceId` from the param type, `race_id` from the INSERT column list and `$N` placeholders, and the `data.raceId ?? null` value. The INSERT becomes:

```typescript
  const { rows } = await pool.query<MeetingRow>(
    `INSERT INTO meetings.meetings
       (city, state, date, meeting_type, duration_seconds, video_url,
        audio_source, status, title, event_kind, chamber_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     RETURNING ${MEETING_COLS}`,
    [
      data.city ?? null,
      data.state,
      data.date,
      data.meetingType,
      data.durationSeconds ?? null,
      data.videoUrl ?? null,
      data.audioSource ?? null,
      data.status ?? 'processing',
      data.title ?? null,
      data.eventKind ?? 'council',
      data.chamberId ?? null,
    ]
  );
```

Also remove `raceId?: string | null;` from the `createMeeting` parameter object type (line ~523).

- [ ] **Step 8: Drop `race_id` from `updateMeeting`** (line ~553) — remove `raceId` from the `Partial<{...}>` type (line ~560) and delete the line that pushes the `race_id` SET clause (line ~576):

```typescript
  // DELETE this line entirely:
  // if (data.raceId !== undefined) { params.push(data.raceId); setClauses.push(`race_id = $${params.length}`); }
```

(Leave every other `setClauses.push(...)` line intact.)

- [ ] **Step 9: Run the tests to verify they pass**

Run: `cd backend && npm test -- meetingsService`
Expected: PASS (existing + new raceIds/filter/write tests).

- [ ] **Step 10: Commit**

```bash
git add backend/src/lib/meetingsService.ts backend/src/lib/meetingsService.test.ts
git commit -m "feat(multi-race): meetingsService returns raceIds[], adds raceId filter, stops writing race_id"
```

---

## Task 4: Routes — drop `raceId` from schemas/validation, add `?raceId` filter

**Files:**
- Modify: `backend/src/routes/meetings.ts` — `GET /` handler (line ~47), `createMeetingSchema` (line ~168), POST validator call (line ~195), `updateMeetingSchema` (line ~218), PATCH `nextState` (line ~260).
- Test: `backend/src/routes/meetings.test.ts`

Context: routes validate bodies with Zod (unknown keys are stripped by default), call `validateEventEntities`, then the service. The `EventEntityState` no longer has `raceId` (Task 2), so the validator calls must drop it.

- [ ] **Step 1: Update the route tests** — In `backend/src/routes/meetings.test.ts`, add a race-filter test and adjust any create/update test that sent `raceId` or expected a `raceId`-related 422. Add:

```typescript
it('GET /api/meetings?raceId=<uuid> forwards the filter to the service', async () => {
  // mirror however this file mocks meetingsService.getMeetings
  const res = await request(app).get('/api/meetings?raceId=22222222-2222-4222-8222-222222222222');
  expect(res.status).toBe(200);
  expect(getMeetingsMock).toHaveBeenCalledWith(
    expect.objectContaining({ raceId: '22222222-2222-4222-8222-222222222222' })
  );
});
```

(Use the file's existing mock handle for `getMeetings` — match the established mocking style in this test file. Remove/adjust any prior test asserting `raceId is required` for debate/forum, since that rule is gone.)

- [ ] **Step 2: Run to verify failure**

Run: `cd backend && npm test -- routes/meetings`
Expected: FAIL (filter not forwarded; or removed-rule tests still present).

- [ ] **Step 3: Add the `raceId` filter to `GET /`** (line ~47) — in the handler, after the `status` filter line, add:

```typescript
  if (typeof req.query.raceId === 'string') filters.raceId = req.query.raceId;
```

and widen the local `filters` type to include `raceId?: string`.

- [ ] **Step 4: Drop `raceId` from the Zod schemas** — In `createMeetingSchema` (line ~176) and `updateMeetingSchema` (line ~226), delete the line:

```typescript
  raceId: z.string().uuid().optional().nullable(),
```

from both.

- [ ] **Step 5: Drop `raceId` from the validator calls** — In the POST handler (line ~195), the `validateEventEntities({...})` argument becomes:

```typescript
      const entityError = validateEventEntities({
        eventKind: parsed.data.eventKind,
        chamberId: parsed.data.chamberId ?? null,
      });
```

In the PATCH handler (line ~260), `nextState` becomes:

```typescript
      const nextState = {
        eventKind: parsed.data.eventKind ?? current.eventKind,
        chamberId:
          parsed.data.chamberId !== undefined ? parsed.data.chamberId : current.chamberId,
      };
```

(Remove the `raceId:` property from both objects.)

- [ ] **Step 6: Run the route tests**

Run: `cd backend && npm test -- routes/meetings`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add backend/src/routes/meetings.ts backend/src/routes/meetings.test.ts
git commit -m "feat(multi-race): meetings routes drop raceId, add ?raceId filter"
```

---

## Task 5: Build, typecheck, full test suite

**Files:** none (verification only)

- [ ] **Step 1: Typecheck** — `cd backend && npm run typecheck`. Expected: clean. Fix any remaining `raceId`/`race_id` references the compiler flags (search `grep -rn "raceId\|race_id" backend/src` and resolve each — all reads/writes should now go through `raceIds`/`event_races`).

- [ ] **Step 2: Full test suite** — `cd backend && npm test`. Expected: all pass.

- [ ] **Step 3: Build** — `cd backend && npm run build`. Expected: clean compile.

- [ ] **Step 4: Commit any fixups**

```bash
git add -u
git commit -m "test(multi-race): align remaining ev-accounts code/tests with event_races"
```

(Skip if Steps 1–3 were already green.)

---

## Task 6: Migration — drop `meetings.meetings.race_id` (GATED — apply last)

**Files:**
- Create: `backend/migrations/1072_drop_meetings_race_id.sql`

Context: this is the destructive, deploy-gated final step. **Apply only after Tasks 2–5 are deployed** (no code reads `race_id` anymore) AND after on-the-record E1 is deployed (the pipeline writes `event_races`, not the column).

- [ ] **Step 1: Write the migration**

Create `backend/migrations/1072_drop_meetings_race_id.sql`:

```sql
-- Migration 1072: drop the single-race column now that meetings.event_races is
-- the source of truth and all readers/writers use it. GATED: apply only after
-- the ev-accounts API (event_races reads) and the on-the-record pipeline
-- (event_races writes) are both deployed.

BEGIN;

DROP INDEX IF EXISTS meetings.meetings_meetings_race_id_idx;

ALTER TABLE meetings.meetings
  DROP COLUMN IF EXISTS race_id;

COMMIT;
```

- [ ] **Step 2: Commit (do not apply yet)**

```bash
git add backend/migrations/1072_drop_meetings_race_id.sql
git commit -m "feat(multi-race): drop meetings.meetings.race_id column (migration 1072, gated)"
```

- [ ] **Step 3: Apply during the coordinated deploy** — after confirming Tasks 2–5 + on-the-record E1 are live, apply 1072 via the project's migration process. Verify:

```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'meetings' AND table_name = 'meetings' AND column_name = 'race_id';
```
Expected: zero rows (column gone).

---

## Self-Review Notes (reconciled against the spec)

- **Spec coverage:** join table + backfill (Task 1) · bidirectional reads — meeting→races via `raceIds[]` (Task 3 MEETING_COLS), race→meetings via `?raceId` filter (Tasks 3+4) · admin stops setting races (Task 3 create/update, Task 4 schemas) · validator mirrors the pipeline (Task 2) · gated column drop (Task 6) · build/typecheck/tests (Task 5). The pipeline-side derivation + reconcile is **E1** (on-the-record), out of this plan.
- **Type/name consistency:** `Meeting.raceIds: string[]`, `MeetingRow.race_ids`, `mapMeeting → raceIds`, the `race_ids` SQL alias, and the `EventEntityState { eventKind, chamberId }` shape are used consistently across Tasks 2–4. The table/columns `meetings.event_races(meeting_id, race_id)` match the on-the-record E1 plan and the shared spec.
- **Deploy ordering:** Task 1 first; Tasks 2–5 ship together; Task 6 applied last, gated on E1 + Tasks 2–5 being live (header + Task 6 reiterate this).
