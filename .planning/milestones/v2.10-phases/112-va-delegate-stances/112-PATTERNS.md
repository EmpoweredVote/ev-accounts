# Phase 112: VA Delegate Stances — Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 13 (10 migration SQL files + 10 CSV files + 10 pre-flight JSON files — all data files, no new TypeScript)
**Analogs found:** 3 / 3 categories (migration SQL, CSV, pre-flight script)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `supabase/migrations/20260610000001_331_va_delegates_wave1_stances.sql` through `20260610000010_340_va_delegates_wave10_stances.sql` | migration | batch (CRUD insert) | `supabase/migrations/20260609000005_330_va_senators_wave5_stances.sql` | exact |
| `backend/data/stance-research/2026-06-XX-112-va-delegates-wave[N].csv` (10 files) | data artifact | transform (WebFetch → CSV) | `backend/data/stance-research/2026-06-09-111-va-senators-wave5.csv` | exact |
| Per-wave pre-flight JSON (e.g., `2026-06-XX-112-va-delegates-wave1-preflight.json`) | data artifact | request-response (DB query) | `2026-06-09-111-va-senators-wave1-preflight.json` | exact |

**No new TypeScript or JavaScript files.** This is a pure data-ingestion phase. All code patterns (pool, psql, inline node scripts) already exist.

---

## Pattern Assignments

### Migration SQL files — 10 files, migrations 331–340

**Analog:** `C:\EV-Accounts\supabase\migrations\20260609000005_330_va_senators_wave5_stances.sql`

**Header comment block** (lines 1–29 of analog):
```sql
-- Phase 112-01: VA House Delegate Stances — Wave 1 (HD-43 through HD-52, Southwest VA)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/YYYY-MM-DD-112-va-delegates-wave1.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  <N>
--   INSERT INTO inform.politician_answers count: <N>
--   INSERT INTO inform.politician_context count: <N>
--   All UUID literals verified against YYYY-MM-DD-112-va-delegates-wave1-preflight.json
--   max_migration at authoring: 325 (psql-applied waves 326–330 not tracked in schema_migrations)
--
-- Honest skips: <list delegates with zero rows and reason, or "None">
--
-- Politician UUIDs (from YYYY-MM-DD-112-va-delegates-wave1-preflight.json):
--   James W. Morefield   (HD-43, ext_id -5120043) -> df51bc00-8a69-4bd0-9418-e61a3cfe248b
--   Israel D. O'Quinn    (HD-44, ext_id -5120044) -> 36673ec0-1045-4a98-8074-12d6deed5cc8
--   <...10 delegates total...>
--
-- Migration number: 331
-- Timestamp: 20260610000001
-- Applied: NOT YET (write-only)
```

**BEGIN/COMMIT wrapper** — every INSERT block between `BEGIN;` and `COMMIT;`. Exact structure from analog (line 30 and line 852):
```sql
BEGIN;

-- ---- <full_name> / <topic_key> / value=<N> ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '<uuid>',
  (SELECT id FROM inform.compass_topics WHERE topic_key = '<topic_key>'),
  <value>
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '<uuid>',
  (SELECT id FROM inform.compass_topics WHERE topic_key = '<topic_key>'),
  '<reasoning — escape every single-quote as two single-quotes: '' not \'>',
  ARRAY(SELECT u FROM unnest(ARRAY[
    '<source_url_1>',
    '<source_url_2>',
    '<source_url_3>'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
```

**DO $$ verification block** — appended inside the BEGIN/COMMIT (lines 831–850 of analog). Scope to each wave's external_id range:
```sql
-- Verification block scoped to Wave 1 (external_id BETWEEN -5120052 AND -5120043)
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120052 AND -5120043;
  RAISE NOTICE 'VA delegates with stances (Wave 1): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120052 AND -5120043
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 1): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;
```

**CRITICAL correctness rule** from analog line 846: use `pc.politician_id IS NULL`, NOT `pc.id IS NULL`. `inform.politician_context` has a composite PK (`politician_id`, `topic_id`) with no standalone `id` column.

**Non-contiguous wave ranges (Waves 2, 3, 5)** — use `IN ()` instead of `BETWEEN` in the DO $$ block:
```sql
-- Wave 2 example: HD-53–55 + HD-37–42 (non-contiguous external_ids)
WHERE p.external_id IN (-5120053, -5120054, -5120055, -5120037, -5120038, -5120039, -5120040, -5120041, -5120042)
```

**HD-20 Vacant seat** — Wave 8 migration header must include:
```sql
-- HD-20 (ext_id -5120020): documented skip — DB record has full_name = 'Vacant'
--   No research performed; no rows written for this seat.
```

---

### CSV files — 10 files, one per wave

**Analog:** `backend/data/stance-research/2026-06-09-111-va-senators-wave5.csv` (same format)

**CSV column order** (from SKILL.md STEP 2 and RESEARCH.md Standard Stack):
```
full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3
```
Optional additional columns if agent produces them:
```
quote_text,quote_deidentified
```

**Naming convention** (from RESEARCH.md Recommended Project Structure):
```
backend/data/stance-research/2026-06-XX-112-va-delegates-wave1.csv
backend/data/stance-research/2026-06-XX-112-va-delegates-wave2.csv
...
backend/data/stance-research/2026-06-XX-112-va-delegates-wave10.csv
```

**Parsing rule:** Always use `csv-parse/sync`. Never split on commas. Names like `"Robert S. Bloxom, Jr."` and `"Thomas C. Wright, Jr."` contain commas and must be RFC-4180 quoted in the CSV.

---

### Pre-flight inline node scripts — run once per wave

**Analog:** Pattern from `111-01-PLAN.md` Task 1 and SKILL.md Topic Resolution section.

**Pool import** — from `C:\EV-Accounts\backend\src\lib\db.ts` (lines 1–16):
```typescript
import { Pool } from 'pg';
import { env } from './env.js';
export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  // session pooler: aws-0-*.pooler.supabase.com:5432
  ssl: { rejectUnauthorized: false },
});
```

**Shell invocation pattern** (from 111-01-PLAN.md Task 1 action and RESEARCH.md Pattern 2):
```bash
cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
// ... query ...
await pool.end();
"
```
On PowerShell: `cd C:\EV-Accounts\backend; Get-Content .env | ...` — use the Bash tool for the POSIX `source` pattern.

**Query A — migration number check:**
```typescript
const { rows } = await pool.query(
  'SELECT MAX(version) FROM supabase_migrations.schema_migrations'
);
// Expected: 325 (psql-applied waves 326–330 are NOT in schema_migrations)
// ALSO check: ls supabase/migrations/ | sort | tail -1 → highest file is 330
// Next free: 331
```

**Query B — live topics snapshot** (from SKILL.md Topic Resolution, lines 56–76):
```typescript
const { rows } = await pool.query(`
  SELECT t.id, t.topic_key, t.title, t.question_text,
    json_agg(json_build_object('value', s.value, 'text', s.text) ORDER BY s.value) AS stances
  FROM inform.compass_topics t
  JOIN inform.compass_stances s ON s.topic_id = t.id
  WHERE t.is_live = true
  GROUP BY t.id, t.topic_key, t.title, t.question_text ORDER BY t.topic_key
`);
// Expected: 44 rows (as of 2026-06-10; may grow — do NOT hardcode 44)
```

**Query C — UUID fetch per wave** (from RESEARCH.md Pattern 3):
```typescript
// Example for Wave 1 (HD-43–52, external_id -5120052 to -5120043)
const { rows } = await pool.query(
  'SELECT id, full_name, external_id FROM essentials.politicians WHERE external_id BETWEEN -5120052 AND -5120043 ORDER BY external_id DESC'
);
// For non-contiguous waves, use IN():
// WHERE external_id IN (-5120053, -5120054, -5120055, -5120037, ...)
```

**Pre-flight JSON output structure** (mirrors 111 pattern from 111-01-PLAN.md Task 1):
```json
{
  "max_migration": 325,
  "highest_file_on_disk": 330,
  "next_free_migration": 331,
  "topics": [ /* full 44-topic array with stances */ ],
  "delegates": [ /* wave-specific UUID list */ ]
}
```

---

## Shared Patterns

### Agent Dispatch — Sequential Only
**Source:** SKILL.md STEP 1, user memory `feedback_stance_research_one_at_a_time.md`
**Apply to:** All 10 plan files (Tasks 2)

ONE `politician-stance-researcher` agent at a time. Wait for CSV write confirmation before next dispatch. Never parallel. `subagent_type: "politician-stance-researcher"`.

### FIVE-CHAIRS Framing + Topic Embed
**Source:** SKILL.md lines 107–131 (agent prompt template)
**Apply to:** Every per-delegate agent prompt in all 10 waves

Full topic JSON from pre-flight (id, topic_key, question_text, stances array with value+text) must be embedded verbatim in each prompt. Never hardcode topic keys or values. Include honest-skip instruction: "Skip any topic where you cannot find sufficient evidence. Do NOT infer from party affiliation. Zero rows for a delegate is a valid and acceptable outcome."

### pool.query() for All DB Writes
**Source:** `backend/src/lib/db.ts`, CONTEXT.md D-14, MEMORY.md critical production pattern
**Apply to:** All pre-flight scripts and any inline DB verification

`inform` schema is NOT in the PostgREST exposed list. `supabaseAdmin.schema('inform')` fails at runtime. All reads and writes against `inform.*` and `essentials.*` must use `pool.query()`.

### psql Apply Pattern
**Source:** 111-01-PLAN.md Task 4, RESEARCH.md Environment Availability
**Apply to:** All 10 migration apply tasks

```bash
psql "$DATABASE_URL" -f supabase/migrations/20260610000001_331_va_delegates_wave1_stances.sql
```
Must use session pooler URL (`aws-0-*.pooler.supabase.com:5432`), not the IPv6 direct host.

### Single-Quote Escaping in SQL Strings
**Source:** `20260609000005_330_va_senators_wave5_stances.sql` (lines 44, 66, 87, 108, etc.)
**Apply to:** All reasoning string literals in all 10 migrations

Every `'` inside a reasoning string must be written as `''`. Example from analog:
```sql
'Carroll Foy was the chief patron ... she ''Led the charge for the Reproductive Health Protection Act'''
```
Never use `\'` — that is not valid PostgreSQL string literal syntax.

### ARRAY() sources filter
**Source:** `20260609000005_330_va_senators_wave5_stances.sql` lines 46–49 (repeated throughout)
**Apply to:** Every `politician_context` INSERT in all 10 migrations

```sql
ARRAY(SELECT u FROM unnest(ARRAY[
  '<url1>',
  '<url2>',
  '<url3>'
]) AS u WHERE u IS NOT NULL AND trim(u) != '')
```
This filters out empty/null URL slots produced by agents that found fewer than 3 sources.

### Phase Gate SQL (Wave 10 only)
**Source:** RESEARCH.md Pattern 5, CONTEXT.md D-13
**Apply to:** 112-10-PLAN.md Task 5 (post all-waves verification)

```sql
-- Run after migration 340 applied
SELECT COUNT(DISTINCT pa.politician_id) AS delegates_with_stances
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
WHERE p.external_id BETWEEN -5120100 AND -5120001;
-- Target: > 0 (honest-skip means total will be < 99); HD-20 Vacant excluded

SELECT COUNT(*) AS unsourced
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE p.external_id BETWEEN -5120100 AND -5120001
  AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
-- Must return 0 (VAST-05 invariant)
```

---

## No Analog Found

No files in Phase 112 lack an analog. All patterns are direct carry-forwards from Phase 111.

---

## Wave-to-Migration Filename Map

| Wave | Plan | Migration # | Filename | External_id Scope | DO $$ Clause Type |
|------|------|-------------|----------|-------------------|-------------------|
| 1 | 112-01 | 331 | `20260610000001_331_va_delegates_wave1_stances.sql` | BETWEEN -5120052 AND -5120043 | BETWEEN |
| 2 | 112-02 | 332 | `20260610000002_332_va_delegates_wave2_stances.sql` | IN(-5120055,-5120054,-5120053,-5120042,...,-5120037) | IN() — non-contiguous |
| 3 | 112-03 | 333 | `20260610000003_333_va_delegates_wave3_stances.sql` | IN(-5120036,...,-5120031,-5120059,...,-5120056) | IN() — non-contiguous |
| 4 | 112-04 | 334 | `20260610000004_334_va_delegates_wave4_stances.sql` | BETWEEN -5120069 AND -5120060 | BETWEEN |
| 5 | 112-05 | 335 | `20260610000005_335_va_delegates_wave5_stances.sql` | IN(-5120075,...,-5120070,-5120079,...,-5120076) | IN() — non-contiguous |
| 6 | 112-06 | 336 | `20260610000006_336_va_delegates_wave6_stances.sql` | BETWEEN -5120089 AND -5120080 | BETWEEN |
| 7 | 112-07 | 337 | `20260610000007_337_va_delegates_wave7_stances.sql` | BETWEEN -5120100 AND -5120090 | BETWEEN |
| 8 | 112-08 | 338 | `20260610000008_338_va_delegates_wave8_stances.sql` | BETWEEN -5120030 AND -5120017 | BETWEEN (HD-20 no rows — ASSERT still holds) |
| 9 | 112-09 | 339 | `20260610000009_339_va_delegates_wave9_stances.sql` | BETWEEN -5120010 AND -5120001 | BETWEEN |
| 10 | 112-10 | 340 | `20260610000010_340_va_delegates_wave10_stances.sql` | BETWEEN -5120016 AND -5120011 | BETWEEN + phase gate |

---

## Metadata

**Analog search scope:** `supabase/migrations/` (migration SQL), `backend/src/lib/` (pool), `.claude/skills/research-stances/` (orchestration), `.planning/phases/111-*/` (plan structure)
**Files scanned:** 4 primary analogs read in full (330 migration SQL, db.ts, SKILL.md, 111-01-PLAN.md)
**Pattern extraction date:** 2026-06-10
