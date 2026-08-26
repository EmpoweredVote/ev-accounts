# Compass Seasons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every compass answer a season, a pinned ladder revision and an editor, so that editing a ladder can never again change the meaning of an answer already stored.

**Architecture:** Two new tables (`inform.seasons`, `inform.season_questions`) carry the season and its per-question pin. `inform.politician_answers` and `inform.politician_context` gain `season_id`, `topic_revision_id`, `editor_id` and timestamps, and their primary key grows a season column. Columns land nullable first, are backfilled to season 1, and are constrained only after every live consumer has been made season-aware — the key swap is the one irreversible step and it goes last.

**Tech Stack:** PostgreSQL (Supabase, schema `inform`), TypeScript/Express, `pg` pool, vitest with a mocked pool, hand-applied SQL migrations in `backend/migrations/`.

**Spec:** [`docs/superpowers/specs/2026-08-25-compass-seasons-design.md`](../specs/2026-08-25-compass-seasons-design.md)

## Global Constraints

- **Migration namespace is `CA_NNNN_snake_case.sql`.** Chris counts only within the `CA_` namespace. **`CA_0013` and `CA_0014` are reserved by ADR 0004** for its repoint/cleanup phase — do not take them. Highest used is `CA_0016`.
- **Take the migration number LAST.** Write the file as `CA_wip_<name>.sql`, and rename/apply/commit in one go. `git fetch origin` first, then `npm run check:migrations --prefix backend` to confirm the slot.
- **Every migration is idempotent** (`IF NOT EXISTS`, `NOT EXISTS` guards, guarded `UPDATE`) and **ends with a `DO $$ ... $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count.** Match `backend/migrations/CA_0015_compass_revision_lifecycle.sql`.
- **Dry-run against prod inside `BEGIN; ... ROLLBACK;` and confirm the rollback reverted** before committing any migration.
- **DDL cannot be applied as `ev_api`.** DDL needs the Supabase MCP (which is PRODUCTION). DML applies fine as `ev_api` via `psql "$DATABASE_URL"` from `backend/`.
- **Tests are vitest with a mocked pool**: `vi.mock('./db.js', () => ({ pool: { query: mockQuery } }))`. See `backend/src/lib/compassStatsService.test.ts`. Run with `npm test --prefix backend`.
- **Never cache "current" in a column** (`CLAUDE.md`). The current season is resolved at read time from `seasons.status`.
- Prod baseline, read 2026-08-25: **33,164** `politician_answers` rows, **0** using a half step, **0** with a write-in; **44** live topics, all with exactly **5** rungs; **46** `compass_topic_revisions`; **184** `compass_responses` from 8 users.

## Scope

This plan covers the **backend season model only**. Two pieces of the spec are deliberately out of scope and need their own plans:

- **Citizen import** (spec §"Import — citizens") is essentials-frontend work *and* depends on rung-map repointing, which `CA_0015`'s own header records as `REPOINTING_NOT_IMPLEMENTED`. It cannot be built until repointing exists.
- **Telemetry-driven revision** is deferred by the spec.

---

### Task 1: The `seasons` and `season_questions` tables

Purely additive. Nothing reads these yet, so this task carries no risk to live reads.

**Files:**
- Create: `backend/migrations/CA_wip_compass_seasons.sql`
- Test: the migration's own `DO $$` post-verify gate

**Interfaces:**
- Consumes: `inform.compass_topics(id)`, `inform.compass_topic_revisions(id)` — both live.
- Produces: `inform.seasons(id, number, name, status, opened_at, closed_at, public_note)`; `inform.season_questions(season_id, topic_id, topic_revision_id, question_number, display_order)` with `UNIQUE (season_id, topic_id, topic_revision_id)` — later tasks depend on that unique constraint as a foreign-key target.

- [x] **Step 1: Write the migration**

```sql
BEGIN;

DO $$ BEGIN
  CREATE TYPE inform.season_status AS ENUM ('draft', 'open', 'closed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS inform.seasons (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  number      integer NOT NULL UNIQUE,
  name        text    NOT NULL,
  status      inform.season_status NOT NULL DEFAULT 'draft',
  opened_at   timestamptz,
  closed_at   timestamptz,
  public_note text    NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT seasons_dates_follow_status CHECK (
    (status = 'draft'  AND opened_at IS NULL AND closed_at IS NULL) OR
    (status = 'open'   AND opened_at IS NOT NULL AND closed_at IS NULL) OR
    (status = 'closed' AND opened_at IS NOT NULL AND closed_at IS NOT NULL)
  )
);

-- At most one open season. A draft may be prepared while one is open.
CREATE UNIQUE INDEX IF NOT EXISTS seasons_one_open
  ON inform.seasons ((status)) WHERE status = 'open';

CREATE TABLE IF NOT EXISTS inform.season_questions (
  season_id         uuid    NOT NULL REFERENCES inform.seasons(id) ON DELETE CASCADE,
  topic_id          uuid    NOT NULL REFERENCES inform.compass_topics(id) ON DELETE RESTRICT,
  topic_revision_id uuid    NOT NULL REFERENCES inform.compass_topic_revisions(id),
  question_number   integer NOT NULL,
  display_order     integer NOT NULL,
  PRIMARY KEY (season_id, topic_id),
  UNIQUE (season_id, question_number),
  UNIQUE (season_id, display_order),
  -- Foreign-key target for the answer tables in Task 6. Without this the
  -- composite FK will not compile.
  UNIQUE (season_id, topic_id, topic_revision_id)
);

COMMENT ON COLUMN inform.season_questions.topic_revision_id IS
  'THE PIN. The ladder revision current when this season opened. Immutable once '
  'the season leaves draft — see the trigger in CA_wip_compass_seasons_constrain.';
COMMENT ON COLUMN inform.season_questions.question_number IS
  'A human-facing label, per season. NOT identity — seeding joins on topic_id. '
  'Matching the previous season''s number is best practice, warned not enforced.';

DO $$
DECLARE v_missing text[] := '{}';
BEGIN
  IF to_regclass('inform.seasons') IS NULL THEN
    v_missing := v_missing || 'seasons'; END IF;
  IF to_regclass('inform.season_questions') IS NULL THEN
    v_missing := v_missing || 'season_questions'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes
                 WHERE schemaname='inform' AND indexname='seasons_one_open') THEN
    v_missing := v_missing || 'seasons_one_open'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
    WHERE t.relname='season_questions' AND c.contype='u'
      AND pg_get_constraintdef(c.oid) LIKE '%season_id, topic_id, topic_revision_id%'
  ) THEN v_missing := v_missing || 'fk-target unique'; END IF;

  IF array_length(v_missing,1) > 0 THEN
    RAISE EXCEPTION 'CA_wip_compass_seasons INCOMPLETE: missing %',
      array_to_string(v_missing, ', ');
  END IF;

  -- This migration must not have touched existing content.
  IF (SELECT count(*) FROM inform.compass_topics) <> 44 THEN
    RAISE EXCEPTION 'topic count changed: expected 44, got %',
      (SELECT count(*) FROM inform.compass_topics);
  END IF;

  RAISE NOTICE 'compass seasons OK — 2 tables, 0 seasons, 44 topics untouched';
END $$;

COMMIT;
```

- [x] **Step 2: Dry-run against prod and confirm the rollback**

Wrap the body in `BEGIN; ... ROLLBACK;` and run it via the Supabase MCP (DDL cannot run as `ev_api`). Expected: the `RAISE NOTICE` fires, then after rollback `to_regclass('inform.seasons')` is `NULL` again. **Confirm that null before trusting the dry run.**

- [x] **Step 3: Take the number, apply, commit**

```bash
git fetch origin && npm run check:migrations --prefix backend
# CA_0013/CA_0014 are reserved by ADR 0004. Expect CA_0017 to be free.
git mv backend/migrations/CA_wip_compass_seasons.sql \
       backend/migrations/CA_0017_compass_seasons.sql
```

Apply for real via the Supabase MCP, then record the applied-date header comment in the file exactly as `CA_0015` does.

```bash
git add backend/migrations/CA_0017_compass_seasons.sql
git commit -m "feat(compass): add seasons and season_questions (CA_0017)"
```

---

### Task 2: Nullable provenance columns on both answer tables

Still additive — every column is nullable, so no existing write breaks.

**Files:**
- Create: `backend/migrations/CA_wip_answer_provenance_columns.sql`

**Interfaces:**
- Consumes: `inform.seasons(id)`, `inform.compass_topic_revisions(id)`, `public.users(id)`.
- Produces: `season_id`, `topic_revision_id`, `editor_id`, `created_at`, `updated_at` on both `inform.politician_answers` and `inform.politician_context`, all nullable.

- [x] **Step 1: Write the migration**

```sql
BEGIN;

ALTER TABLE inform.politician_answers
  ADD COLUMN IF NOT EXISTS season_id         uuid REFERENCES inform.seasons(id),
  ADD COLUMN IF NOT EXISTS topic_revision_id uuid REFERENCES inform.compass_topic_revisions(id),
  ADD COLUMN IF NOT EXISTS editor_id         uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS created_at        timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at        timestamptz NOT NULL DEFAULT now();

ALTER TABLE inform.politician_context
  ADD COLUMN IF NOT EXISTS season_id         uuid REFERENCES inform.seasons(id),
  ADD COLUMN IF NOT EXISTS topic_revision_id uuid REFERENCES inform.compass_topic_revisions(id),
  ADD COLUMN IF NOT EXISTS editor_id         uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS created_at        timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at        timestamptz NOT NULL DEFAULT now();

COMMENT ON COLUMN inform.politician_answers.editor_id IS
  'Who wrote this row. NULL means it predates provenance — the 33,164 rows '
  'backfilled into season 1 are exactly that, and the column stays nullable '
  'for them. See the spec, Open before implementation #1 and #2.';

DO $$
DECLARE v_cols int;
BEGIN
  SELECT count(*) INTO v_cols FROM information_schema.columns
   WHERE table_schema='inform' AND table_name IN ('politician_answers','politician_context')
     AND column_name IN ('season_id','topic_revision_id','editor_id','created_at','updated_at');
  IF v_cols <> 10 THEN
    RAISE EXCEPTION 'expected 10 new columns across both tables, found %', v_cols;
  END IF;

  IF (SELECT count(*) FROM inform.politician_answers) <> 33164 THEN
    RAISE EXCEPTION 'answer count changed: expected 33164, got %',
      (SELECT count(*) FROM inform.politician_answers);
  END IF;

  RAISE NOTICE 'provenance columns OK — 10 columns added, 33164 answers intact';
END $$;

COMMIT;
```

- [x] **Step 2: Dry-run, confirm the rollback, take the number, apply, commit**

Same procedure as Task 1, Steps 2-3. Expected slot: `CA_0018`.

```bash
git commit -m "feat(compass): nullable season/revision/editor columns on answers (CA_0018)"
```

---

### Task 3: Backfill season 1

The only large-DML task. 33,164 answer rows and their context rows.

**Files:**
- Create: `backend/migrations/CA_wip_season_one_backfill.sql`

**Interfaces:**
- Consumes: everything from Tasks 1 and 2.
- Produces: exactly one row in `inform.seasons` (`number = 1`, `status = 'closed'`); 44 rows in `inform.season_questions`; every answer and context row carrying `season_id` and `topic_revision_id`.

- [ ] **Step 1: Write the migration**

`editor_id` is **Chris Cantrell — `Kades`, `4e6dde8f-2bd0-4054-824f-4164744165ea`** (confirmed by Chris on 2026-08-25: email
chris@empowered.vote, username Kades). ⚠ It is **not** `chrisandrewsedu` / `854fbc06…` — that is
**Chris Andrews**, a teammate who works primarily on On the Record and Read & Rank, and who authored
the one `judicial-bail-pretrial` revision. Inferring the editor from "who has authored compass
content" produced that wrong answer. **Two Chrises work in this system; never resolve either by
first name or by authorship.**

**DECISION, Chris, 2026-08-25 — `editor_id` for the season-1 rows.** The draft contained a
contradiction: it stamped Kades onto all 33,164 rows and gated on no NULLs, while writing a
`public_note` that said editors were null. Chris chose to **keep the stamp** and **fix the note**.
He is the editor of record for the pre-seasons corpus. The `public_note` below now says that
authorship was not recorded *per row*, and that the season is attributed to its editor of record —
which is true, and does not claim he typed each row. The alternative considered and rejected was
leaving `editor_id` NULL. Do not "fix" this back.

```sql
BEGIN;

INSERT INTO inform.seasons (number, name, status, opened_at, closed_at, public_note)
SELECT 1, 'Season 1', 'closed',
       '2025-01-01T00:00:00Z', now(),
       'The corpus as it stood before seasons existed. Every answer written up to '
       '2026-08-25 is recorded here, pinned to the ladder revision that was current '
       'when seasons were introduced. Per-row authorship was not recorded at the '
       'time, so the whole season is attributed to its editor of record rather '
       'than to whoever typed each individual row.'
WHERE NOT EXISTS (SELECT 1 FROM inform.seasons WHERE number = 1);

-- The season's question set: every live topic, pinned to its current revision,
-- numbered and ordered by topic_key so the numbering is reproducible.
INSERT INTO inform.season_questions
  (season_id, topic_id, topic_revision_id, question_number, display_order)
SELECT s.id, t.id, r.id,
       row_number() OVER (ORDER BY t.topic_key),
       row_number() OVER (ORDER BY t.topic_key)
  FROM inform.seasons s
  CROSS JOIN inform.compass_topics t
  JOIN inform.compass_topic_revisions r
    ON r.topic_id = t.id AND r.is_current AND r.status = 'published'
 WHERE s.number = 1
   AND t.is_live
   AND NOT EXISTS (
     SELECT 1 FROM inform.season_questions sq
      WHERE sq.season_id = s.id AND sq.topic_id = t.id);

UPDATE inform.politician_answers a
   SET season_id = sq.season_id, topic_revision_id = sq.topic_revision_id,
       editor_id = '4e6dde8f-2bd0-4054-824f-4164744165ea'   -- Chris Cantrell (Kades)
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 1
 WHERE sq.topic_id = a.topic_id
   AND a.season_id IS NULL;

UPDATE inform.politician_context c
   SET season_id = sq.season_id, topic_revision_id = sq.topic_revision_id,
       editor_id = '4e6dde8f-2bd0-4054-824f-4164744165ea'   -- Chris Cantrell (Kades)
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 1
 WHERE sq.topic_id = c.topic_id
   AND c.season_id IS NULL;

DO $$
DECLARE v_q int; v_a int; v_c int;
BEGIN
  SELECT count(*) INTO v_q FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id WHERE s.number = 1;
  IF v_q <> 44 THEN
    RAISE EXCEPTION 'season 1 should pin 44 questions, pinned %', v_q; END IF;

  SELECT count(*) INTO v_a FROM inform.politician_answers WHERE season_id IS NULL;
  IF v_a <> 0 THEN
    RAISE EXCEPTION '% answers left without a season', v_a; END IF;

  SELECT count(*) INTO v_c FROM inform.politician_context WHERE season_id IS NULL;
  IF v_c <> 0 THEN
    RAISE EXCEPTION '%% context rows left without a season', v_c; END IF;

  IF EXISTS (SELECT 1 FROM inform.politician_answers WHERE editor_id IS NULL) THEN
    RAISE EXCEPTION 'answers left without an editor'; END IF;

  -- Every answer must cite the revision its season actually pinned.
  IF EXISTS (
    SELECT 1 FROM inform.politician_answers a
     WHERE NOT EXISTS (
       SELECT 1 FROM inform.season_questions sq
        WHERE sq.season_id = a.season_id AND sq.topic_id = a.topic_id
          AND sq.topic_revision_id = a.topic_revision_id)
  ) THEN RAISE EXCEPTION 'an answer cites a revision its season did not pin'; END IF;

  RAISE NOTICE 'season 1 backfill OK — 44 questions pinned, % answers, % contexts',
    (SELECT count(*) FROM inform.politician_answers),
    (SELECT count(*) FROM inform.politician_context);
END $$;

COMMIT;
```

- [ ] **Step 2: Dry-run against prod and read the NOTICE**

Expected: `44 questions pinned, 33164 answers, <n> contexts`. If the question count is not 44, a topic has no current published revision — stop and investigate rather than widening the join.

- [ ] **Step 3: Confirm the rollback, take the number, apply, commit**

Expected slot: `CA_0019`.

```bash
git commit -m "feat(compass): backfill season 1 across 33,164 answers (CA_0019)"
```

---

### Task 4: The consumer gate

A permanent check that starts **red** and turns green as Task 5 lands. This is the mechanism that makes the Task 6 key swap safe.

**Files:**
- Create: `backend/scripts/check-answer-season-consumers.mjs`
- Modify: `backend/package.json` (add the `check:answer-seasons` script)
- Test: run the script; it must exit non-zero and name the offending files

**Interfaces:**
- Produces: `npm run check:answer-seasons --prefix backend`, exit 0 when every live consumer is season-aware.

- [ ] **Step 1: Write the gate**

```javascript
#!/usr/bin/env node
// Every live query against the answer tables must constrain the season.
//
// Once politician_answers is keyed (politician_id, topic_id, season_id), a join
// on (politician_id, topic_id) alone FANS OUT — silently, and only after a
// second season exists. This gate is the reason that cannot happen: it fails
// until every live consumer names a season.
//
// Scope is backend/src ONLY. The 345 one-off apply-*-stances.ts scripts and
// NNN-verify.sql files are historical records of past batches, not live
// consumers; rewriting them would change nothing and lose their meaning.
import { readFileSync, globSync } from 'node:fs';   // globSync needs Node >= 22; CI runs 24

const FILES = globSync('src/**/*.ts', { cwd: process.cwd() })
  .filter((f) => !f.endsWith('.test.ts'));

const TABLE = /inform\.(politician_answers|politician_context)/;
const SEASON = /season_id|current_season|seasonId/;

const offenders = [];
for (const file of FILES) {
  const text = readFileSync(file, 'utf8');
  if (!TABLE.test(text)) continue;
  if (SEASON.test(text)) continue;
  offenders.push(file);
}

if (offenders.length) {
  console.error(
    `answer-season consumers — ${offenders.length} file(s) query the answer ` +
    `tables without naming a season:`);
  for (const f of offenders) console.error(`  · ${f}`);
  console.error(
    '\nA join on (politician_id, topic_id) alone fans out once a second season ' +
    'exists. Add the season predicate before CA_0020 swaps the primary key.');
  process.exit(1);
}
console.log('answer-season consumers OK — every live consumer names a season.');
```

- [ ] **Step 2: Run it and confirm it fails with the expected list**

Run: `npm run check:answer-seasons --prefix backend`
Expected: **FAIL**, listing the live consumers. As of 2026-08-25, 15 files under `backend/src` match. One is a test (`lib/compassStatsService.test.ts`, excluded by the glob) and one is generated (`types/database.types.ts`, regenerated not edited), leaving **13 hand-written consumers**:
`lib/adminService.ts`, `lib/compassService.ts`, `lib/compassStatsService.ts`, `lib/coverageMapService.ts`, `lib/coverageService.ts`, `lib/electionsMapService.ts`, `lib/federalCoverage.ts`, `lib/researchEvidenceService.ts`, `lib/sourceVerificationService.ts`, `lib/stagingService.ts`, `routes/admin.ts`, `routes/compassAdmin.ts`, `routes/compassContributor.ts`.

- [ ] **Step 3: Wire it into package.json and CI**

```json
"check:answer-seasons": "node scripts/check-answer-season-consumers.mjs"
```

Add a CI job mirroring the existing `stance sourcing` job in `.github/workflows/`. ⚠ Note it will be **red until Task 5 completes** — land Tasks 4 and 5 on the same branch so master never sees a failing gate.

- [ ] **Step 4: Commit**

```bash
git add backend/scripts/check-answer-season-consumers.mjs backend/package.json
git commit -m "feat(compass): gate live answer-table consumers on naming a season"
```

---

### Task 5: Make every live consumer season-aware

**Files:**
- Create: `backend/src/lib/seasonService.ts`
- Create: `backend/src/lib/seasonService.test.ts`
- Modify: the 13 non-test files listed in Task 4, Step 2

**Interfaces:**
- Produces: `currentSeasonId(): Promise<string>` and `latestAnsweredSeason(politicianId, topicId)` from `seasonService.ts`; every consumer constrains on a season.

- [ ] **Step 1: Write the failing test**

```typescript
// backend/src/lib/seasonService.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { currentSeasonId } from './seasonService.js';

beforeEach(() => mockQuery.mockReset());

describe('currentSeasonId', () => {
  it('returns the id of the one open season', async () => {
    mockQuery.mockResolvedValue({ rows: [{ id: 'season-2' }] });
    expect(await currentSeasonId()).toBe('season-2');
  });

  it('throws when no season is open, rather than falling back to the newest', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await expect(currentSeasonId()).rejects.toThrow('no open season');
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npx vitest run src/lib/seasonService.test.ts`
Expected: FAIL — `Cannot find module './seasonService.js'`

- [ ] **Step 3: Write the minimal implementation**

```typescript
// backend/src/lib/seasonService.ts
import { pool } from './db.js';

/**
 * The id of the open season. Resolved at read time, never cached in a column —
 * no trigger fires because the calendar advanced (CLAUDE.md).
 *
 * Throws rather than falling back to the highest-numbered season: a closed
 * season is not a place to write answers, and silently choosing one would
 * reintroduce exactly the ambiguity seasons exist to remove.
 */
export async function currentSeasonId(): Promise<string> {
  const { rows } = await pool.query(
    `SELECT id FROM inform.seasons WHERE status = 'open'`);
  if (rows.length !== 1) throw new Error('no open season');
  return rows[0].id as string;
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npx vitest run src/lib/seasonService.test.ts`
Expected: PASS, 2 tests.

- [ ] **Step 5: Update each consumer, one commit per file**

For each of the 13 files, add the season predicate to every query touching the answer tables. The read shape is *newest season in which this person has an answer*, not *the current season*, because a person may not have been researched this season:

```sql
JOIN LATERAL (
  SELECT a.value, a.season_id
    FROM inform.politician_answers a
    JOIN inform.seasons s ON s.id = a.season_id
   WHERE a.politician_id = p.id AND a.topic_id = t.id
   ORDER BY s.number DESC
   LIMIT 1
) ans ON true
```

⚠ A `LATERAL … LIMIT 1` is required, not a plain join — the same trap `check-stance-sources.mjs` documents for `office_current_holder`, where joining a one-row-per-office view on `politician_id` fans out a dual-office holder.

Run `npm test --prefix backend` after each file.

- [ ] **Step 6: Run the gate and confirm it is green**

Run: `npm run check:answer-seasons --prefix backend`
Expected: `answer-season consumers OK — every live consumer names a season.`

- [ ] **Step 7: Commit**

```bash
git add backend/src
git commit -m "feat(compass): make every live answer-table consumer season-aware"
```

---

### Task 6: Constrain — the irreversible step

Only after Task 5's gate is green.

**Files:**
- Create: `backend/migrations/CA_wip_answer_season_constraints.sql`

**Interfaces:**
- Produces: `PRIMARY KEY (politician_id, topic_id, season_id)` on both answer tables; a composite FK to `season_questions`; a whole-number value CHECK; a pin-immutability trigger.

- [ ] **Step 1: Write the migration**

```sql
BEGIN;

ALTER TABLE inform.politician_answers
  ALTER COLUMN season_id SET NOT NULL,
  ALTER COLUMN topic_revision_id SET NOT NULL;
ALTER TABLE inform.politician_context
  ALTER COLUMN season_id SET NOT NULL,
  ALTER COLUMN topic_revision_id SET NOT NULL;

ALTER TABLE inform.politician_answers DROP CONSTRAINT politician_answers_pkey;
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_pkey
  PRIMARY KEY (politician_id, topic_id, season_id);

ALTER TABLE inform.politician_context DROP CONSTRAINT politician_context_pkey;
ALTER TABLE inform.politician_context
  ADD CONSTRAINT politician_context_pkey
  PRIMARY KEY (politician_id, topic_id, season_id);

-- A row cannot cite a ladder its season never pinned.
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_pin_fkey
  FOREIGN KEY (season_id, topic_id, topic_revision_id)
  REFERENCES inform.season_questions (season_id, topic_id, topic_revision_id);
ALTER TABLE inform.politician_context
  ADD CONSTRAINT politician_context_pin_fkey
  FOREIGN KEY (season_id, topic_id, topic_revision_id)
  REFERENCES inform.season_questions (season_id, topic_id, topic_revision_id);

-- A politician takes one of the five we publish. Half steps are the CITIZEN
-- signal and stay legal on compass_responses; they were never legal for a
-- politician in intent, only in the constraint. 0 of 33,164 rows use one.
ALTER TABLE inform.politician_answers DROP CONSTRAINT politician_answers_value_half_step;
ALTER TABLE inform.politician_answers DROP CONSTRAINT politician_answers_value_check;
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_value_whole_1_to_5
  CHECK (value IN (1, 2, 3, 4, 5));

CREATE OR REPLACE FUNCTION inform.season_pin_is_immutable()
RETURNS trigger LANGUAGE plpgsql AS $fn$
DECLARE v_status inform.season_status;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = OLD.season_id;
  IF v_status <> 'draft' AND NEW.topic_revision_id IS DISTINCT FROM OLD.topic_revision_id THEN
    RAISE EXCEPTION 'PIN_IMMUTABLE: season % is %, its pins cannot move',
      OLD.season_id, v_status;
  END IF;
  RETURN NEW;
END $fn$;

DROP TRIGGER IF EXISTS season_questions_pin_immutable ON inform.season_questions;
CREATE TRIGGER season_questions_pin_immutable
  BEFORE UPDATE ON inform.season_questions
  FOR EACH ROW EXECUTE FUNCTION inform.season_pin_is_immutable();

DO $$
BEGIN
  IF (SELECT count(*) FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
       WHERE t.relname='politician_answers' AND c.contype='p'
         AND pg_get_constraintdef(c.oid) LIKE '%season_id%') <> 1 THEN
    RAISE EXCEPTION 'politician_answers primary key does not include season_id'; END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
              WHERE t.relname='politician_answers'
                AND c.conname='politician_answers_value_half_step') THEN
    RAISE EXCEPTION 'the half-step CHECK is still present on politician_answers'; END IF;

  IF (SELECT count(*) FROM inform.politician_answers) <> 33164 THEN
    RAISE EXCEPTION 'answer count changed during constrain: %',
      (SELECT count(*) FROM inform.politician_answers); END IF;

  RAISE NOTICE 'constraints OK — keys swapped, pins enforced, value whole 1-5';
END $$;

COMMIT;
```

- [ ] **Step 2: Dry-run against prod, confirm the rollback**

⚠ This is the irreversible step. After the rollback, re-read `politician_answers_pkey` and confirm it is back to `(politician_id, topic_id)` **before** applying for real.

- [ ] **Step 3: Prove the trigger refuses a moved pin**

In a rolled-back transaction: open season 1, `UPDATE inform.season_questions SET topic_revision_id = <some other revision>` for one row.
Expected: `PIN_IMMUTABLE: season … is open, its pins cannot move`.

- [ ] **Step 4: Take the number, apply, commit**

Expected slot: `CA_0020`.

```bash
git commit -m "feat(compass): key answers by season, enforce the pin, whole 1-5 (CA_0020)"
```

---

### Task 7: The politician seed

**Files:**
- Create: `backend/src/lib/seasonSeedService.ts`
- Create: `backend/src/lib/seasonSeedService.test.ts`

**Interfaces:**
- Consumes: `currentSeasonId()` from Task 5.
- Produces: `getSeed(politicianId, topicId, seasonId): Promise<Seed | null>` where
  `Seed = { value: number; reasoning: string; sources: string[]; seasonNumber: number; isFresh: boolean }`.

- [ ] **Step 1: Write the failing test**

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { getSeed } from './seasonSeedService.js';

beforeEach(() => mockQuery.mockReset());

describe('getSeed', () => {
  it('is fresh when both seasons pin the same revision', async () => {
    mockQuery.mockResolvedValue({ rows: [{
      value: 3, reasoning: 'because', sources: ['https://x'],
      season_number: 1, is_fresh: true }] });
    const seed = await getSeed('p1', 't1', 'season-2');
    expect(seed).toEqual({ value: 3, reasoning: 'because', sources: ['https://x'],
      seasonNumber: 1, isFresh: true });
  });

  it('is stale when the pins differ, so a confirm must be refused', async () => {
    mockQuery.mockResolvedValue({ rows: [{
      value: 3, reasoning: 'because', sources: ['https://x'],
      season_number: 1, is_fresh: false }] });
    expect((await getSeed('p1', 't1', 'season-2'))!.isFresh).toBe(false);
  });

  it('returns null when the person has no previous-season answer', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    expect(await getSeed('p1', 't1', 'season-2')).toBeNull();
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npx vitest run src/lib/seasonSeedService.test.ts`
Expected: FAIL — `Cannot find module './seasonSeedService.js'`

- [ ] **Step 3: Write the implementation**

```typescript
import { pool } from './db.js';

export interface Seed {
  value: number; reasoning: string; sources: string[];
  seasonNumber: number; isFresh: boolean;
}

/**
 * The previous season's answer, for a researcher to start from. A READ — it
 * never writes a season-N row. `isFresh` is false when the ladder moved between
 * the two seasons, and a false seed must not be confirmable: an evolved question
 * needs new research, not a carried-forward chair.
 */
export async function getSeed(
  politicianId: string, topicId: string, seasonId: string,
): Promise<Seed | null> {
  const { rows } = await pool.query(
    `WITH target AS (
       SELECT s.number, sq.topic_revision_id
         FROM inform.seasons s
         JOIN inform.season_questions sq
           ON sq.season_id = s.id AND sq.topic_id = $2
        WHERE s.id = $3
     ), prev AS (
       SELECT s.id, s.number, sq.topic_revision_id
         FROM inform.seasons s
         JOIN inform.season_questions sq
           ON sq.season_id = s.id AND sq.topic_id = $2
        WHERE s.number < (SELECT number FROM target)
        ORDER BY s.number DESC
        LIMIT 1
     )
     SELECT a.value, c.reasoning, c.sources,
            prev.number AS season_number,
            (prev.topic_revision_id = (SELECT topic_revision_id FROM target)) AS is_fresh
       FROM prev
       JOIN inform.politician_answers a
         ON a.season_id = prev.id AND a.politician_id = $1 AND a.topic_id = $2
       LEFT JOIN inform.politician_context c
         ON c.season_id = prev.id AND c.politician_id = $1 AND c.topic_id = $2`,
    [politicianId, topicId, seasonId]);

  if (!rows.length) return null;
  const r = rows[0];
  return {
    value: Number(r.value), reasoning: r.reasoning, sources: r.sources,
    seasonNumber: Number(r.season_number), isFresh: r.is_fresh === true,
  };
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npx vitest run src/lib/seasonSeedService.test.ts`
Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/seasonSeedService.ts backend/src/lib/seasonSeedService.test.ts
git commit -m "feat(compass): read the previous season's answer as a seed, fresh or stale"
```

---

### Task 8: "Last reviewed in season N" on the read path

**Files:**
- Modify: `backend/src/lib/compassService.ts`
- Modify: `backend/src/lib/compassService.test.ts` (create if absent, matching `compassStatsService.test.ts`)

**Interfaces:**
- Produces: each politician answer in the API response carries `seasonNumber` and `isCurrentSeason`.

- [ ] **Step 1: Write the failing test**

```typescript
it('flags an answer from an older season as not current', async () => {
  mockRows({ answers: [{ topic_id: 't1', value: 2, season_number: 1 }],
             currentSeasonNumber: 2 });
  const out = await getPoliticianCompass('p1');
  expect(out.answers[0]).toMatchObject({ seasonNumber: 1, isCurrentSeason: false });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npx vitest run src/lib/compassService.test.ts`
Expected: FAIL — `isCurrentSeason` is undefined.

- [ ] **Step 3: Implement**

```typescript
// backend/src/lib/compassService.ts
import { pool } from './db.js';

export interface PoliticianAnswer {
  topicId: string; value: number; seasonNumber: number; isCurrentSeason: boolean;
}

export async function getPoliticianCompass(politicianId: string) {
  // One row per topic: the NEWEST season this person has an answer in. The
  // LATERAL … LIMIT 1 is load-bearing — a plain join fans a person out across
  // every season they were researched in.
  const { rows } = await pool.query(
    `SELECT t.id AS topic_id, ans.value, ans.season_number
       FROM inform.compass_topics t
       JOIN LATERAL (
         SELECT a.value, s.number AS season_number
           FROM inform.politician_answers a
           JOIN inform.seasons s ON s.id = a.season_id
          WHERE a.politician_id = $1 AND a.topic_id = t.id
          ORDER BY s.number DESC
          LIMIT 1
       ) ans ON true
      WHERE t.is_live`,
    [politicianId]);

  const { rows: cur } = await pool.query(
    `SELECT number FROM inform.seasons WHERE status = 'open'`);
  // No open season is a legitimate state between seasons; nothing is current then.
  const currentSeasonNumber = cur.length === 1 ? Number(cur[0].number) : null;

  return {
    answers: rows.map((r): PoliticianAnswer => ({
      topicId: r.topic_id,
      value: Number(r.value),
      seasonNumber: Number(r.season_number),
      // Derived at read time, never stored — CLAUDE.md's "never cache current".
      isCurrentSeason: Number(r.season_number) === currentSeasonNumber,
    })),
  };
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npx vitest run src/lib/compassService.test.ts`
Expected: PASS.

- [ ] **Step 5: Full check sweep and commit**

```bash
npm run lint --prefix backend && npm run typecheck --prefix backend \
  && npm test --prefix backend \
  && npm run check:answer-seasons --prefix backend \
  && npm run check:stance-sources --prefix backend
git add backend/src
git commit -m "feat(compass): expose season number and a last-reviewed flag on the read path"
```

---

## Follow-on plans, not built here

1. **Citizen import.** Blocked: `CA_0015`'s header records rung-map repointing as `REPOINTING_NOT_IMPLEMENTED`. Repointing must exist before the import rule (chosen rung *and its immediate neighbours* all map `identity`) can be evaluated. Also spans the essentials frontend for the "imported" disclosure.
2. **The six ladder defects.** Once a second season can open, each becomes a revision plus a season boundary rather than an edit to live text.
3. **Question-number drift warning.** The best-practice check from spec decision 4. Small; needs two seasons to exist before it can do anything.
4. **Seasons for ReadRank questions.** ADR 0004 §8 already puts them on this machinery. **Chris Andrews owns Read & Rank** — that decision is his, and this plan deliberately does not pre-empt it.
