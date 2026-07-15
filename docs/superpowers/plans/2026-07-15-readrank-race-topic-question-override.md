# Read & Rank Race-Topic Question Override — Implementation Plan (ev-accounts)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a curator override the Read & Rank "ranking question" per race-topic (falling back to the Compass question), and seed the first override for CA Governor × fossil fuels.

**Architecture:** New table `essentials.readrank_race_topic_questions` keyed by `(race_id, topic_key)`. The blind-quotes query resolves `COALESCE(override.question_text, inform.compass_topics.question_text)` server-side, so the API payload contract is unchanged (still one `question` string per topic). The override is axis-invariant by curation policy — it reframes wording only, never the topic/axis.

**Tech Stack:** TypeScript (Node), Postgres (Supabase), `pg`, Vitest. Migrations are numbered SQL files in `backend/migrations/` applied by a per-migration `backend/scripts/_apply-migration-NNN.ts` runner (direct connection, port 5432).

**Scope note:** This is Parts A (data model) + D (CA-governor seed) of the design spec `read-rank/docs/superpowers/specs/2026-07-15-bespoke-race-topic-questions-design.md`. Part B (frontend banner) shipped in read-rank#70. Part C (curation docs/skills) is a separate plan.

**Deployment order (important):** apply migration 1323 to the DB **before** deploying the query change (Task 2 LEFT-JOINs the new table; the code fails at runtime if the table is absent). Then draft + seed the override (Tasks 3–5).

---

## File Structure

- **Create:** `backend/migrations/1323_readrank_race_topic_questions.sql` — the override table (schema only).
- **Create:** `backend/scripts/_apply-migration-1323.ts` — apply + post-verify runner (models `_apply-migration-1230.ts`).
- **Modify:** `backend/src/lib/readrankService.ts` — `getRaceBlindQuotes` query: add LEFT JOIN + COALESCE.
- **Modify:** `backend/src/lib/readrankService.test.ts` — new `getRaceBlindQuotes` test (resolved question + query shape).
- **Create:** `backend/migrations/1324_seed_ca_governor_fossil_fuels_question.sql` — first override row (Part D, after approval).
- **Create:** `backend/scripts/_apply-migration-1324.ts` — apply + post-verify runner for the seed.

---

## Task 1: Migration — override table (1323)

**Files:**
- Create: `backend/migrations/1323_readrank_race_topic_questions.sql`
- Create: `backend/scripts/_apply-migration-1323.ts`

- [ ] **Step 1: Write the migration SQL**

Create `backend/migrations/1323_readrank_race_topic_questions.sql`:

```sql
-- 1323_readrank_race_topic_questions.sql
-- Per-(race, topic) override for the Read & Rank "ranking question".
-- The public payload resolves COALESCE(override, inform.compass_topics.question_text),
-- so an unset row falls back to the canonical Compass question. Axis-invariant by
-- curation policy (QUOTE-CURATION-PRINCIPLES §7.3): stores reframed wording only,
-- never a different topic/axis.

BEGIN;

CREATE TABLE IF NOT EXISTS essentials.readrank_race_topic_questions (
  race_id       uuid NOT NULL REFERENCES essentials.races(id) ON DELETE CASCADE,
  topic_key     text NOT NULL CHECK (topic_key = lower(topic_key)),
  question_text text NOT NULL CHECK (length(btrim(question_text)) > 0),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    text,
  PRIMARY KEY (race_id, topic_key)
);

COMMENT ON TABLE essentials.readrank_race_topic_questions IS
  'Read & Rank per-race ranking-question override; resolves via COALESCE over inform.compass_topics.question_text. Axis-invariant (QUOTE-CURATION-PRINCIPLES §7.3).';

COMMIT;
```

- [ ] **Step 2: Write the apply/verify runner**

Create `backend/scripts/_apply-migration-1323.ts` (models `_apply-migration-1230.ts`):

```ts
import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({
  connectionString: process.env['DATABASE_URL'],
  ssl: { rejectUnauthorized: false },
});

const sql = readFileSync(
  path.join(process.cwd(), 'migrations', '1323_readrank_race_topic_questions.sql'),
  'utf8',
);

try {
  await pool.query(sql);
  console.log('Migration 1323 applied.');

  const r = await pool.query(
    `SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'essentials'
        AND table_name = 'readrank_race_topic_questions'`,
  );
  console.log(`readrank_race_topic_questions table present: ${r.rowCount === 1}`);
  if (r.rowCount !== 1) process.exitCode = 1;
} catch (e) {
  console.error('Migration 1323 failed:', e);
  process.exitCode = 1;
} finally {
  await pool.end();
}
```

- [ ] **Step 3: Apply the migration to the database**

The migration is idempotent (`CREATE TABLE IF NOT EXISTS`). Run from the `backend/` directory with the DIRECT connection string (port 5432, `db.<ref>.supabase.co`):

Run: `cd backend && DATABASE_URL="<direct-connection-url>" npx tsx scripts/_apply-migration-1323.ts`
Expected output: `Migration 1323 applied.` then `readrank_race_topic_questions table present: true`.

(If `DATABASE_URL` is not available in this environment, STOP and report NEEDS_CONTEXT — the controller/user will apply it. Do not fake success.)

- [ ] **Step 4: Commit**

```bash
git add backend/migrations/1323_readrank_race_topic_questions.sql backend/scripts/_apply-migration-1323.ts
git commit -m "feat(readrank): add essentials.readrank_race_topic_questions override table"
```

---

## Task 2: Resolve the override in getRaceBlindQuotes (TDD)

**Files:**
- Modify: `backend/src/lib/readrankService.test.ts`
- Modify: `backend/src/lib/readrankService.ts` (`getRaceBlindQuotes`, ~lines 513–535)

- [ ] **Step 1: Write the failing test**

In `backend/src/lib/readrankService.test.ts`, add `getRaceBlindQuotes` to the existing import:

```ts
import { getPlayableRaces, deriveTierScope, deriveOfficeSeat, getRaceBlindQuotes } from './readrankService.js';
```

Then add this describe block at the end of the file:

```ts
describe('getRaceBlindQuotes — resolved ranking question (override ?? compass)', () => {
  it('maps the resolved topic_question into the payload and LEFT JOINs the override table', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [
        { quote_id: 'q1', deidentified_text: 'Answer one.', topic_key: 'fossil-fuels', politician_id: 'p1', topic_title: 'Fossil fuels', topic_question: 'RESOLVED QUESTION', position_name: 'Governor' },
        { quote_id: 'q2', deidentified_text: 'Answer two.', topic_key: 'fossil-fuels', politician_id: 'p2', topic_title: 'Fossil fuels', topic_question: 'RESOLVED QUESTION', position_name: 'Governor' },
      ],
    });

    const payload = await getRaceBlindQuotes('race-1');

    expect(payload).not.toBeNull();
    expect(payload!.topics).toHaveLength(1);
    expect(payload!.topics[0].question).toBe('RESOLVED QUESTION');
    expect(payload!.topics[0].quotes).toHaveLength(2);

    // The query must resolve the override over the Compass default.
    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toContain('essentials.readrank_race_topic_questions');
    expect(sql).toMatch(/COALESCE\(\s*rtq\.question_text\s*,\s*ct\.question_text\s*\)/);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npx vitest run src/lib/readrankService.test.ts -t "resolved ranking question"`
Expected: FAIL — the current SQL has no `readrank_race_topic_questions` join and selects `ct.question_text` directly (not COALESCE), so the two SQL assertions fail. (The `.question` mapping assertion already passes.)

- [ ] **Step 3: Update the query**

In `backend/src/lib/readrankService.ts`, in `getRaceBlindQuotes`, change the SELECT list and add the LEFT JOIN. Find:

```ts
    SELECT q.id AS quote_id, q.deidentified_text, lower(q.topic_key) AS topic_key,
           q.politician_id,
           ct.short_title AS topic_title, ct.question_text AS topic_question,
           r.position_name
    FROM essentials.races r
    JOIN essentials.race_candidates rc
      ON rc.race_id = r.id
     AND rc.politician_id IS NOT NULL
     AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
     AND q.readrank_selected = true
    JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
    WHERE r.id = $1
    ORDER BY ct.short_title
```

Replace it with (adds the SELECT COALESCE and the LEFT JOIN; everything else unchanged):

```ts
    SELECT q.id AS quote_id, q.deidentified_text, lower(q.topic_key) AS topic_key,
           q.politician_id,
           ct.short_title AS topic_title,
           COALESCE(rtq.question_text, ct.question_text) AS topic_question,
           r.position_name
    FROM essentials.races r
    JOIN essentials.race_candidates rc
      ON rc.race_id = r.id
     AND rc.politician_id IS NOT NULL
     AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
     AND q.readrank_selected = true
    JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
    LEFT JOIN essentials.readrank_race_topic_questions rtq
      ON rtq.race_id = r.id AND rtq.topic_key = lower(q.topic_key)
    WHERE r.id = $1
    ORDER BY ct.short_title
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd backend && npx vitest run src/lib/readrankService.test.ts -t "resolved ranking question"`
Expected: PASS.

- [ ] **Step 5: Run the full service test file (no regressions)**

Run: `cd backend && npx vitest run src/lib/readrankService.test.ts`
Expected: PASS (all existing `getPlayableRaces` / `deriveTierScope` / `deriveOfficeSeat` tests + the new one).

- [ ] **Step 6: Commit**

```bash
git add backend/src/lib/readrankService.ts backend/src/lib/readrankService.test.ts
git commit -m "feat(readrank): resolve race-topic question override in getRaceBlindQuotes"
```

---

## Task 3: Gather the CA-governor fossil-fuels source data (Part D-a)

Read-only discovery. No commits. Produces the three inputs the override needs: the race id, the topic_key, the current Compass question, the candidates' selected quotes, and the actual debate question. Requires DB access; if unavailable, report NEEDS_CONTEXT.

- [ ] **Step 1: Find the CA Governor race id**

Run (adjust the state/office predicates to the actual schema — inspect `essentials.races` columns first with `\d essentials.races` if unsure):

```sql
SELECT id, position_name
FROM essentials.races
WHERE position_name ILIKE '%governor%'
  AND id IN (
    SELECT race_id FROM essentials.race_candidates GROUP BY race_id
  )
ORDER BY position_name;
-- Identify the California Governor row; record its id as CA_GOV_RACE_ID.
```

- [ ] **Step 2: Find the fossil-fuels topic_key + current Compass question**

```sql
SELECT topic_key, short_title, question_text
FROM inform.compass_topics
WHERE is_live = true
  AND (topic_key ILIKE '%fossil%' OR short_title ILIKE '%fossil%' OR topic_key ILIKE '%energy%' OR short_title ILIKE '%energy%');
-- Record the fossil-fuels FF_TOPIC_KEY (lowercased) and its current question_text.
```

- [ ] **Step 3: Pull the candidates' selected quotes for that race-topic**

```sql
SELECT q.politician_id, q.deidentified_text
FROM essentials.races r
JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id IS NOT NULL
JOIN essentials.quotes q ON q.politician_id = rc.politician_id
  AND q.readrank_selected = true AND lower(q.topic_key) = '<FF_TOPIC_KEY>'
WHERE r.id = '<CA_GOV_RACE_ID>';
```

- [ ] **Step 4: Pull the actual debate question from the source meeting**

Meeting `6f206fe5-a18b-4af5-b945-c72178d53289` (on-the-record). Inspect `meetings.segments` and locate the moderator's fossil-fuels/energy question:

```sql
-- Confirm columns first (e.g. \d meetings.segments), then:
SELECT * FROM meetings.segments
WHERE meeting_id = '6f206fe5-a18b-4af5-b945-c72178d53289'
  AND (text ILIKE '%fossil%' OR text ILIKE '%oil%' OR text ILIKE '%gas%' OR text ILIKE '%drill%' OR text ILIKE '%energy%')
ORDER BY /* segment order column */;
-- Record the verbatim debate question posed to the candidates.
```

- [ ] **Step 5: Report the gathered inputs**

Report back (do not commit): `CA_GOV_RACE_ID`, `FF_TOPIC_KEY`, current Compass `question_text`, the candidate quotes, and the verbatim debate question. These feed Task 4.

---

## Task 4: Draft the override question + get approval (Part D-b)

Human-gated curation. No commits.

- [ ] **Step 1: Draft the ranking question**

From Task 3's inputs, draft the sharpened ranking question, obeying the design's guards:
- **Faithful** to the actual debate question the candidates answered (shorten if long).
- **Axis-invariant** — engages the SAME axis/dimension as the current Compass question (do not shift what's being measured). If the debate question is on a different axis than the Compass topic, STOP — that is a Compass fix or a re-home, not an override (spec §2.3/§2.4).
- **Blind** — shown identically to all candidates; must not name or contextually leak a candidate.
- Confirm all candidate quotes from Task 3 genuinely answer the drafted question (responsiveness holds against the resolved question).

- [ ] **Step 2: Present for approval**

Present to the user: the current Compass question, the verbatim debate question, and the proposed override, with a one-line rationale (why it's more faithful and still on-axis). **Wait for explicit approval.** Record the approved string as `APPROVED_QUESTION`. If the user edits it, use their final wording.

---

## Task 5: Seed migration for the CA-governor override (1324)

**Files:**
- Create: `backend/migrations/1324_seed_ca_governor_fossil_fuels_question.sql`
- Create: `backend/scripts/_apply-migration-1324.ts`

Use the concrete values from Tasks 3–4 (`CA_GOV_RACE_ID`, `FF_TOPIC_KEY`, `APPROVED_QUESTION`) — these are real values produced by the prior tasks, not placeholders. Do not invent them; if any is missing, return to the relevant task.

- [ ] **Step 1: Write the seed migration**

Create `backend/migrations/1324_seed_ca_governor_fossil_fuels_question.sql`:

```sql
-- 1324_seed_ca_governor_fossil_fuels_question.sql
-- First race-local ranking-question override: CA Governor × fossil fuels.
-- Derived from the actual debate question (on-the-record meeting
-- 6f206fe5-a18b-4af5-b945-c72178d53289), shortened, axis-invariant, blind.
-- Idempotent: re-running updates the wording in place.

BEGIN;

INSERT INTO essentials.readrank_race_topic_questions (race_id, topic_key, question_text, updated_by)
VALUES (
  '<CA_GOV_RACE_ID>',            -- from Task 3 Step 1
  '<FF_TOPIC_KEY>',             -- from Task 3 Step 2 (lowercased)
  '<APPROVED_QUESTION>',        -- from Task 4 Step 2 (user-approved)
  'migration:1324'
)
ON CONFLICT (race_id, topic_key) DO UPDATE
  SET question_text = EXCLUDED.question_text,
      updated_at    = now(),
      updated_by    = EXCLUDED.updated_by;

COMMIT;
```

- [ ] **Step 2: Write the apply/verify runner**

Create `backend/scripts/_apply-migration-1324.ts`:

```ts
import 'dotenv/config';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import path from 'path';

const pool = new Pool({
  connectionString: process.env['DATABASE_URL'],
  ssl: { rejectUnauthorized: false },
});

const sql = readFileSync(
  path.join(process.cwd(), 'migrations', '1324_seed_ca_governor_fossil_fuels_question.sql'),
  'utf8',
);

try {
  await pool.query(sql);
  console.log('Migration 1324 applied.');

  const r = await pool.query(
    `SELECT question_text FROM essentials.readrank_race_topic_questions
      WHERE race_id = $1 AND topic_key = $2`,
    ['<CA_GOV_RACE_ID>', '<FF_TOPIC_KEY>'],
  );
  console.log(`override row present: ${r.rowCount === 1}`, r.rows[0]?.question_text);
  if (r.rowCount !== 1) process.exitCode = 1;
} catch (e) {
  console.error('Migration 1324 failed:', e);
  process.exitCode = 1;
} finally {
  await pool.end();
}
```

- [ ] **Step 3: Apply the seed**

Run: `cd backend && DATABASE_URL="<direct-connection-url>" npx tsx scripts/_apply-migration-1324.ts`
Expected: `Migration 1324 applied.` then `override row present: true <APPROVED_QUESTION>`.

- [ ] **Step 4: End-to-end verification**

Confirm the resolve works against the real DB (not just the mocked unit test):

```sql
-- Should now return the override, not the Compass default, for the fossil-fuels topic:
SELECT lower(q.topic_key) AS topic_key,
       COALESCE(rtq.question_text, ct.question_text) AS resolved_question
FROM essentials.races r
JOIN essentials.race_candidates rc ON rc.race_id = r.id
JOIN essentials.quotes q ON q.politician_id = rc.politician_id AND q.readrank_selected = true
JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
LEFT JOIN essentials.readrank_race_topic_questions rtq
  ON rtq.race_id = r.id AND rtq.topic_key = lower(q.topic_key)
WHERE r.id = '<CA_GOV_RACE_ID>' AND lower(q.topic_key) = '<FF_TOPIC_KEY>'
GROUP BY 1, 2;
```

Expected: `resolved_question` = `APPROVED_QUESTION`. Also spot-check a topic WITHOUT an override in the same race still returns its Compass `question_text` (fallback holds).

- [ ] **Step 5: Commit**

```bash
git add backend/migrations/1324_seed_ca_governor_fossil_fuels_question.sql backend/scripts/_apply-migration-1324.ts
git commit -m "feat(readrank): seed CA-governor fossil-fuels ranking-question override"
```

---

## Self-Review (completed by plan author)

- **Spec coverage:** Part A table (Task 1) ✓; COALESCE resolve, contract unchanged (Task 2) ✓; blindness/thin-topic invariants untouched (query only adds a LEFT JOIN — sanitize/≥2 rules unaffected) ✓; Part D seed from the real debate question, axis-invariant/blind, user-approved (Tasks 3–5) ✓; migration-based authoring (spec §3.3) ✓.
- **Placeholders:** the `<CA_GOV_RACE_ID>` / `<FF_TOPIC_KEY>` / `<APPROVED_QUESTION>` tokens in Task 5 are values produced by Tasks 3–4, explicitly sourced — not vague TODOs. All code/SQL/commands are complete.
- **Type/name consistency:** table name `essentials.readrank_race_topic_questions`, alias `rtq`, columns `race_id`/`topic_key`/`question_text`, and the COALESCE expression match across the migration, the query, the test assertion, and both apply scripts.
- **Deployment safety:** order-of-operations calls out applying 1323 before deploying the Task 2 query change.
