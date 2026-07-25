# Read & Rank Question Model — Data Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Read & Rank *question* a first-class DB entity — add `essentials.readrank_questions`, attach quotes to a question (`quotes.question_id`), and expose a tested query that computes question-level rankability — without breaking any existing topic-level read path.

**Architecture:** One hand-applied SQL migration (`1377_readrank_questions.sql`) creates the new table, adds the nullable `quotes.question_id` column, and folds the existing per-(race,topic) override table (`readrank_race_topic_questions`, migration 1323) in as `confirmed` `emergent` questions. Rankability stays **derived, not stored**: a new `readrankQuestionsService.ts` computes per-question "rankable (≥2 candidates) vs. surfaced (≥1)" with a raw-`pg` query matching `readrankService.ts`. Everything is additive — the current topic-level read path is untouched, so this ships independently.

**Tech Stack:** TypeScript (ESM, Node 20), node-postgres (`pg`) via the shared `pool` in `src/lib/db.ts`, Vitest (DB mocked — no live DB in tests), Supabase Postgres. Migrations are hand-applied SQL (no runner, no `schema_migrations` ledger).

**Source spec:** `on-the-record/docs/superpowers/specs/2026-07-21-readrank-question-as-unit-design.md` (Section 1 — Data model). This plan is Plan 1 of 3; Plan 2 (surfacing + attach-time gate, in on-the-record) and Plan 3 (coverage-grid admin UI, in ev-accounts) build on it.

**Scope guardrails:**
- **No historical quote backfill.** `quotes.question_id` starts NULL for existing rows and is populated going forward by publish (Plan 2) and curation (Plan 3). A retroactive backfill is deliberately out of scope: `readrank_questions` is nearly empty at migration time, and mapping a quote to a race is ambiguous (a politician can appear in multiple `race_candidates` rows). Documented, not forgotten.
- **The old `readrank_race_topic_questions` table is NOT dropped.** Existing read paths still use it; it retires in a later cleanup once Plan 3 switches reads to `readrank_questions`.
- **Migrations are hand-applied, not unit-tested** (repo convention — there is no migration test harness and no DB in tests). The migration's correctness is checked by the apply script's verification `SELECT`s against a **Supabase branch / dev DB first**, then prod on explicit human approval. The TDD portion of this plan is the service function.

**Connection-string rule (load-bearing):** apply migrations with the **direct/session** connection (port 5432, `db.<ref>.supabase.co`), NOT the transaction pooler (port 6543) — multi-statement migrations fail on the pooler.

---

### Task 1: Migration `1377_readrank_questions.sql` + apply script

**Files:**
- Create: `backend/migrations/1377_readrank_questions.sql`
- Create: `backend/scripts/_apply-migration-1377.ts`

- [ ] **Step 1: Write the migration SQL**

Create `backend/migrations/1377_readrank_questions.sql`:

```sql
-- 1377_readrank_questions.sql
-- Make the Read & Rank QUESTION the first-class unit of comparison.
-- Adds essentials.readrank_questions (N questions per (race, topic_key), each parented
-- to a compass topic via topic_key) and essentials.quotes.question_id (a quote answers
-- exactly one question). Folds the per-(race,topic) override table (1323) in as
-- confirmed 'emergent' questions. Rankability is DERIVED, not stored (see
-- src/lib/readrankQuestionsService.ts).
-- Additive + idempotent: safe to re-run; does not touch existing topic-level read paths.

BEGIN;

CREATE TABLE IF NOT EXISTS essentials.readrank_questions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  race_id         uuid NOT NULL REFERENCES essentials.races(id) ON DELETE CASCADE,
  topic_key       text NOT NULL CHECK (topic_key = lower(topic_key)),
  question_text   text NOT NULL CHECK (length(btrim(question_text)) > 0),
  origin          text NOT NULL CHECK (origin IN ('compass','moderator','emergent')),
  origin_quote_id uuid REFERENCES essentials.quotes(id) ON DELETE SET NULL,
  source_ref      jsonb,
  status          text NOT NULL DEFAULT 'proposed' CHECK (status IN ('proposed','confirmed','rejected')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      text
);

COMMENT ON TABLE essentials.readrank_questions IS
  'Read & Rank ranking questions — the first-class unit of comparison. N per (race, topic_key); topic_key parents to inform.compass_topics for Compass coupling. Rankability is derived, not stored (src/lib/readrankQuestionsService.ts).';

CREATE INDEX IF NOT EXISTS readrank_questions_race_topic_idx
  ON essentials.readrank_questions (race_id, topic_key);

ALTER TABLE essentials.quotes
  ADD COLUMN IF NOT EXISTS question_id uuid REFERENCES essentials.readrank_questions(id) ON DELETE SET NULL;

COMMENT ON COLUMN essentials.quotes.question_id IS
  'The Read & Rank question this quote answers (essentials.readrank_questions.id). NULL until attached by publish/curation. topic_key is retained for Compass coupling.';

CREATE INDEX IF NOT EXISTS quotes_question_id_idx
  ON essentials.quotes (question_id);

-- Fold the per-(race,topic) override table (1323) in as confirmed race-local questions.
-- Overrides were curator-set race-local reframings -> origin 'emergent'; already live -> 'confirmed'.
INSERT INTO essentials.readrank_questions (race_id, topic_key, question_text, origin, status, updated_by)
SELECT src.race_id, src.topic_key, src.question_text, 'emergent', 'confirmed', src.updated_by
FROM essentials.readrank_race_topic_questions src
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.readrank_questions rq
  WHERE rq.race_id = src.race_id
    AND rq.topic_key = src.topic_key
    AND rq.question_text = src.question_text
);

COMMIT;
```

- [ ] **Step 2: Write the apply-and-verify script**

Create `backend/scripts/_apply-migration-1377.ts` (mirrors `backend/scripts/_apply-migration-1346.ts`; run from `backend/`):

```ts
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { Pool } from 'pg';

async function main() {
  const connectionString = process.env['DATABASE_URL'];
  if (!connectionString) throw new Error('DATABASE_URL is required (use the direct 5432 connection, not the 6543 pooler)');

  const pool = new Pool({ connectionString, ssl: { rejectUnauthorized: false } });
  const sqlPath = path.join(process.cwd(), 'migrations', '1377_readrank_questions.sql');
  const sql = readFileSync(sqlPath, 'utf8');

  try {
    await pool.query(sql);
    console.log('Applied 1377_readrank_questions.sql');

    const tbl = await pool.query(
      `SELECT column_name FROM information_schema.columns
       WHERE table_schema = 'essentials' AND table_name = 'readrank_questions'
       ORDER BY ordinal_position`
    );
    console.log('readrank_questions columns:', tbl.rows.map((r) => r.column_name).join(', '));

    const col = await pool.query(
      `SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'essentials' AND table_name = 'quotes' AND column_name = 'question_id'`
    );
    console.log('quotes.question_id present:', col.rowCount === 1);

    const migrated = await pool.query(
      `SELECT
         (SELECT count(*) FROM essentials.readrank_race_topic_questions) AS overrides,
         (SELECT count(*) FROM essentials.readrank_questions WHERE origin = 'emergent' AND status = 'confirmed') AS folded_in`
    );
    console.log('overrides vs folded-in:', migrated.rows[0]);
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

- [ ] **Step 3: Commit the migration + script (application is a separate gated step)**

```bash
git add backend/migrations/1377_readrank_questions.sql backend/scripts/_apply-migration-1377.ts
git commit -m "feat(readrank): add readrank_questions table + quotes.question_id (migration 1377)"
```

- [ ] **Step 4: Apply against a Supabase BRANCH / dev DB and read the verification output** (do NOT apply to prod yet)

Run from `backend/`, with the direct (5432) connection string of a dev/branch database:

```bash
DATABASE_URL="postgresql://postgres:<pw>@db.<ref>.supabase.co:5432/postgres" npx tsx scripts/_apply-migration-1377.ts
```

Expected output includes:
- `readrank_questions columns: id, race_id, topic_key, question_text, origin, origin_quote_id, source_ref, status, created_at, updated_at, updated_by`
- `quotes.question_id present: true`
- `overrides vs folded-in: { overrides: '<N>', folded_in: '<N>' }` where `folded_in` equals `overrides` (every override row folded in).

If `folded_in` < `overrides`, stop and investigate before any prod apply (a re-run is safe — the INSERT is guarded by `NOT EXISTS`).

- [ ] **Step 5: Prod apply is a human-gated deploy step** — per `DEPLOY.md`, apply to prod only after the branch verification passes and a human approves. Not performed by the plan executor.

---

### Task 2: `readrankQuestionsService.listRaceQuestions` (derived rankability) — TDD

**Files:**
- Create: `backend/src/lib/readrankQuestionsService.ts`
- Test: `backend/src/lib/readrankQuestionsService.test.ts`

- [ ] **Step 1: Write the failing test**

Create `backend/src/lib/readrankQuestionsService.test.ts` (mirrors the `vi.mock('./db.js', …)` convention in `readrankQuotesService.test.ts`):

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

const mockQuery = vi.fn();
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { listRaceQuestions } from './readrankQuestionsService.js';

describe('listRaceQuestions', () => {
  beforeEach(() => mockQuery.mockReset());

  it('queries readrank_questions for the race and maps rankable/surfaced from candidate counts', async () => {
    // pg returns COUNT(...) as a string; two answers -> rankable, one -> surfaced only, zero -> neither.
    mockQuery.mockResolvedValueOnce({
      rows: [
        { question_id: 'q-rankable', topic_key: 'economic-development', question_text: 'Should the state legalize gambling?', origin: 'emergent', status: 'confirmed', answering_candidates: '2' },
        { question_id: 'q-solo', topic_key: 'religious-freedom', question_text: 'What role should religion play in government?', origin: 'emergent', status: 'confirmed', answering_candidates: '1' },
        { question_id: 'q-empty', topic_key: 'healthcare', question_text: 'What role should government play in healthcare access?', origin: 'compass', status: 'confirmed', answering_candidates: '0' },
      ],
    });

    const result = await listRaceQuestions('race-123');

    // Correct table + params
    expect(mockQuery).toHaveBeenCalledTimes(1);
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toContain('essentials.readrank_questions');
    expect(sql).toContain('q.question_id = rq.id');       // quotes attach by question, not topic
    expect(sql).toContain('q.readrank_selected = true');   // only live quotes count
    expect(sql).toContain("rq.status = 'confirmed'");      // proposed/rejected excluded
    expect(params).toEqual(['race-123']);

    // Correct derivation
    expect(result).toEqual([
      { questionId: 'q-rankable', topicKey: 'economic-development', questionText: 'Should the state legalize gambling?', origin: 'emergent', status: 'confirmed', answeringCandidates: 2, rankable: true, surfaced: true },
      { questionId: 'q-solo', topicKey: 'religious-freedom', questionText: 'What role should religion play in government?', origin: 'emergent', status: 'confirmed', answeringCandidates: 1, rankable: false, surfaced: true },
      { questionId: 'q-empty', topicKey: 'healthcare', questionText: 'What role should government play in healthcare access?', origin: 'compass', status: 'confirmed', answeringCandidates: 0, rankable: false, surfaced: false },
    ]);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run (from `backend/`): `npm test -- readrankQuestionsService`
Expected: FAIL — `Failed to resolve import './readrankQuestionsService.js'` (the module doesn't exist yet).

- [ ] **Step 3: Write the minimal implementation**

Create `backend/src/lib/readrankQuestionsService.ts` (raw-`pg` pattern from `readrankService.ts`; rankable/surfaced derived in TS from the `COUNT`):

```ts
import { pool } from './db.js';

export type QuestionOrigin = 'compass' | 'moderator' | 'emergent';
export type QuestionStatus = 'proposed' | 'confirmed' | 'rejected';

export interface RaceQuestion {
  questionId: string;
  topicKey: string;
  questionText: string;
  origin: QuestionOrigin;
  status: QuestionStatus;
  answeringCandidates: number;
  rankable: boolean; // >= 2 distinct non-withdrawn candidates with a live quote on this question
  surfaced: boolean; // >= 1
}

interface RaceQuestionRow {
  question_id: string;
  topic_key: string;
  question_text: string;
  origin: QuestionOrigin;
  status: QuestionStatus;
  answering_candidates: string; // pg returns COUNT(...) as text
}

// Per-question comparability for a race. A candidate "answers" a question when they have a
// live quote (readrank_selected + deidentified_text present) attached to it and they are a
// non-withdrawn candidate in the race. Mirrors the predicates in readrankService.ts.
const LIST_RACE_QUESTIONS_SQL = `
  SELECT rq.id            AS question_id,
         rq.topic_key     AS topic_key,
         rq.question_text AS question_text,
         rq.origin        AS origin,
         rq.status        AS status,
         COUNT(DISTINCT rc.politician_id) AS answering_candidates
  FROM essentials.readrank_questions rq
  LEFT JOIN essentials.quotes q
    ON q.question_id = rq.id
   AND q.readrank_selected = true
   AND q.deidentified_text IS NOT NULL
  LEFT JOIN essentials.race_candidates rc
    ON rc.race_id = rq.race_id
   AND rc.politician_id = q.politician_id
   AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
  WHERE rq.race_id = $1
    AND rq.status = 'confirmed'
  GROUP BY rq.id, rq.topic_key, rq.question_text, rq.origin, rq.status
  ORDER BY rq.topic_key, rq.question_text
`;

export async function listRaceQuestions(raceId: string): Promise<RaceQuestion[]> {
  const { rows } = await pool.query<RaceQuestionRow>(LIST_RACE_QUESTIONS_SQL, [raceId]);
  return rows.map((r) => {
    const answeringCandidates = Number(r.answering_candidates);
    return {
      questionId: r.question_id,
      topicKey: r.topic_key,
      questionText: r.question_text,
      origin: r.origin,
      status: r.status,
      answeringCandidates,
      rankable: answeringCandidates >= 2,
      surfaced: answeringCandidates >= 1,
    };
  });
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run (from `backend/`): `npm test -- readrankQuestionsService`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add backend/src/lib/readrankQuestionsService.ts backend/src/lib/readrankQuestionsService.test.ts
git commit -m "feat(readrank): question-level rankable/surfaced query (readrankQuestionsService)"
```

---

## Self-review

- **Spec coverage (Section 1 — Data model):** `readrank_questions` table with all specified columns + N-per-(race,topic) → Task 1. `quotes.question_id` → Task 1. Rankable (≥2) vs. surfaced (≥1) derived → Task 2. Fold-in of `readrank_race_topic_questions` → Task 1 Step 1. Compass floor question & historical quote backfill → explicitly deferred in Scope guardrails (materialization happens in Plan 2/3). Topics-as-coupling → preserved (`topic_key` retained, no read-path change).
- **Placeholder scan:** none — every step has full SQL/TS/commands. The one intentional fill-in is the DB connection string in Task 1 Step 4 (an environment secret the operator supplies), clearly marked.
- **Type consistency:** `listRaceQuestions` return type `RaceQuestion` matches the object asserted in the test (`questionId`, `topicKey`, `questionText`, `origin`, `status`, `answeringCandidates`, `rankable`, `surfaced`); the SQL column aliases (`question_id`, `topic_key`, `question_text`, `origin`, `status`, `answering_candidates`) match `RaceQuestionRow`; the test's SQL-substring assertions (`q.question_id = rq.id`, `q.readrank_selected = true`, `rq.status = 'confirmed'`) all appear verbatim in `LIST_RACE_QUESTIONS_SQL`.
