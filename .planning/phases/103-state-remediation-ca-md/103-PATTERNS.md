# Phase 103: State Remediation — CA + MD - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 5 new/modified files
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `backend/scripts/run-ca-source-triage.ts` | utility/script | batch, request-response | `backend/scripts/run-house-source-triage.ts` | exact |
| `supabase/migrations/YYYYMMDD_270_ca_state_source_remediation.sql` | migration | CRUD (UPSERT + DELETE) | `supabase/migrations/20260606000002_269_house_source_remediation.sql` | exact |
| `supabase/migrations/YYYYMMDD_271_md_officials_stances.sql` | migration | CRUD (INSERT only) | `supabase/migrations/20260606000002_269_house_source_remediation.sql` | role-match (INSERT-only subset) |
| `.planning/phases/103-state-remediation-ca-md/103-DELETION-LOG.md` | repository artifact | — | `.planning/phases/102-federal-house-remediation/102-DELETION-LOG.md` | exact |
| `backend/data/stance-research/YYYY-MM-DD-ca-state-remediation.csv` | data artifact | batch | `backend/data/stance-research/2026-06-06-candidate-remediation.csv` | exact |

---

## Pattern Assignments

### `backend/scripts/run-ca-source-triage.ts` (utility/script, batch)

**Analog:** `backend/scripts/run-house-source-triage.ts` (lines 1–1036)

**Imports + boilerplate pattern** (lines 34–48):
```typescript
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import { writeFileSync, mkdirSync } from 'node:fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

if (!process.env.DATABASE_URL) {
  console.error('Fatal: DATABASE_URL is not set. Ensure backend/.env exists and contains DATABASE_URL.');
  process.exit(1);
}

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const DRY_RUN = process.argv.includes('--dry-run');
```

**SOURCED_CASE constant** (lines 60–71) — copy verbatim, do not modify:
```typescript
const SOURCED_CASE = `
  CASE
    WHEN pc.politician_id IS NOT NULL
         AND pc.sources IS NOT NULL
         AND array_length(pc.sources, 1) IS NOT NULL
         AND EXISTS (
           SELECT 1 FROM unnest(pc.sources) AS s(url)
           WHERE url IS NOT NULL AND trim(url) <> ''
         )
    THEN 1
    ELSE 0
  END`;
```

**UNSOURCED_CASE constant** (lines 74–85) — copy verbatim:
```typescript
const UNSOURCED_CASE = `
  CASE
    WHEN pc.politician_id IS NULL
         OR pc.sources IS NULL
         OR array_length(pc.sources, 1) IS NULL
         OR NOT EXISTS (
           SELECT 1 FROM unnest(pc.sources) AS s(url)
           WHERE url IS NOT NULL AND trim(url) <> ''
         )
    THEN 1
    ELSE 0
  END`;
```

**HOMEPAGE_ONLY_REGEX constant** (line 89) — copy verbatim:
```typescript
const HOMEPAGE_ONLY_REGEX = `'^https?://[^/]+/?$'`;
```

**CA_POLITICIANS_CTE** — replace `HOUSE_POLITICIANS_CTE` (lines 133–149) with this CA-scoped equivalent:
```typescript
const CA_POLITICIANS_CTE = `
  ca_politicians AS (
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name,
      p.party,
      d.state,
      d.district_type
    FROM essentials.politicians p
    JOIN essentials.offices o
      ON o.politician_id = p.id
      AND o.is_vacant = false
    JOIN essentials.districts d
      ON d.id = o.district_id
    WHERE p.is_active = true
      AND d.state = 'CA'
      AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC', 'STATE_BOARD')
    ORDER BY p.id
  )`;
```
NOTE: Verify actual district_type values via `SELECT DISTINCT district_type FROM essentials.districts WHERE state = 'CA'` before finalizing the IN() list. `STATE_EXEC` is assumed for the governor — confirm before running.

**Summary query pattern** (lines 181–212) — adapt `queryHouseSummary()` for CA. Replace CTE reference and alias:
```typescript
async function queryCASummary(): Promise<SummaryRow> {
  const result = await pool.query<SummaryRow>(`
    WITH ${CA_POLITICIANS_CTE}
    SELECT
      (SELECT COUNT(*) FROM ca_politicians)::text AS total_politicians,
      COUNT(pa.topic_id)::text AS total_stances,
      COALESCE(SUM(${UNSOURCED_CASE}), 0)::text AS unsourced_stance_count,
      COUNT(
        CASE
          WHEN pc.politician_id IS NOT NULL
            AND pc.sources IS NOT NULL
            AND array_length(pc.sources, 1) IS NOT NULL
            AND NOT EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL
                AND trim(url) <> ''
                AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
            )
            AND EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL AND trim(url) <> ''
            )
          THEN 1
        END
      )::text AS weak_stance_count
    FROM ca_politicians cp
    JOIN inform.politician_answers pa ON pa.politician_id = cp.id
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
  `);
  return result.rows[0];
}
```

**Target list query pattern — per-rep query with HAVING clause** (lines 257–373). Adapt `queryHouseTargets()` for CA:
- Replace `HOUSE_POLITICIANS_CTE` → `CA_POLITICIANS_CTE`
- Replace alias `hp` → `cp`
- Add `district_type` to GROUP BY (CA triage reports district_type for governor vs. legislator distinction)
- Keep HAVING clause verbatim: `HAVING SUM(${UNSOURCED_CASE}) > 0 OR COUNT(...weak...) > 0`

**Topic detail query pattern** (lines 502–578). Adapt `queryHouseTopicDetail()` for CA:
- Replace `HOUSE_POLITICIANS_CTE` → `CA_POLITICIANS_CTE`, alias `hp` → `cp`
- WHERE clause checking both unsourced and weak-sourced rows is copied verbatim

**TargetRow type** (lines 102–113) — add `district_type` field for CA (CA triage distinguishes STATE_LOWER / STATE_UPPER / STATE_EXEC):
```typescript
interface TargetRow {
  full_name: string;
  politician_id: string;
  state: string;
  district_type: string;   // CA-specific addition
  party: string;
  total_stances: string;
  unsourced_count: string;
  weak_count: string;
  affected_topic_keys: string[];
  classification: string;
}
```

**Output path** (line 1007–1014) — adapt to Phase 103 paths:
```typescript
const phaseDir = path.resolve(__dirname, '..', '..', '.planning', 'phases', '103-state-remediation-ca-md');
mkdirSync(phaseDir, { recursive: true });

const reportPath = path.resolve(phaseDir, '103-CA-TRIAGE-REPORT.md');
writeFileSync(reportPath, report, 'utf8');

const csvPath = path.resolve(phaseDir, '103-CA-TARGETS.csv');
writeFileSync(csvPath, csv, 'utf8');
```

**CSV header** (line 934) — add `district_type` column:
```typescript
const header = 'full_name,politician_id,state,district_type,party,total_stances,unsourced_count,weak_count,affected_topic_keys,classification';
```

**Error handling / main()** (lines 947–1036) — copy verbatim, adapting phase number, query function names, and log messages. The `pool.end()` + `process.exit(1)` pattern in the catch block is required.

---

### `supabase/migrations/YYYYMMDD_270_ca_state_source_remediation.sql` (migration, CRUD)

**Analog:** `supabase/migrations/20260606000002_269_house_source_remediation.sql` (lines 1–347)

**File header comment pattern** (lines 1–19):
```sql
-- Phase 103: CA State Remediation
-- Requirements covered: STAX-01, QUAL-01, QUAL-02
-- Source CSV: backend/data/stance-research/YYYY-MM-DD-ca-state-remediation.csv
-- Source deletion log: .planning/phases/103-state-remediation-ca-md/103-DELETION-LOG.md
--
-- Pre-write cross-check:
--   Expected upserts: N, deletes: M, total = N+M
--   (N) + (M) = (total flagged stances from 103-CA-TARGETS.csv) ✓
--   Intersection of UPSERT and DELETE (politician_id, topic_id) pairs: empty ✓
--
-- Migration number: 270 (verified via SELECT MAX(version) → 269; next = 270)
-- Applied: YYYY-MM-DD via psql session pooler
```

**BEGIN / COMMIT wrapper** (lines 20, 346) — always wrap entire migration:
```sql
BEGIN;
-- ... all UPSERT and DELETE statements ...
COMMIT;
```

**UPSERT block — standard pattern** (lines 27–46 for answers, lines 35–46 for context). Each stance remediation is two statements:
```sql
-- ---- [Politician Name] / [topic_key] / value=[N] ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'politician-uuid-here',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'topic-key-here'),
  N
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'politician-uuid-here',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'topic-key-here'),
  'Reasoning text here...',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://real-source-url.com/page'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;
```

**UPSERT block — CA weak-source ARRAY_CAT variant** (D-05 from CONTEXT.md — not in migration 269, new for Phase 103). When a CA politician already has a context row with sources (even homepage-only), use ARRAY_CAT in the conflict clause instead of overwrite:
```sql
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'politician-uuid-here',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'topic-key-here'),
  'Reasoning text here...',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://new-real-source-url.com/specific-page'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = politician_context.sources || EXCLUDED.sources;
--                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--                ARRAY_CAT: append new URLs to existing (preserves homepage-only history)
--                Use this form for CA politicians with pre-existing weak-source context rows.
--                Use sources = EXCLUDED.sources (plain overwrite) only when context row is new.
```

**DELETE block pattern** (lines 185–281). Always delete context row FIRST, then answers row:
```sql
-- DELETED: [Full Name] / [topic_key] / former value=[N] / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'politician-uuid-here'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'topic-key-here');
DELETE FROM inform.politician_answers
WHERE politician_id = 'politician-uuid-here'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'topic-key-here');
```

**POST-STATE DO $$ RAISE NOTICE block** (lines 288–339). Embed inline verification counts as informational notices — does NOT block commit. Adapt V1/V2 query to CA district_type filter:
```sql
DO $$
DECLARE
  v_unsourced_ca integer;
  v_weak_ca integer;
BEGIN
  -- V1: CA state unsourced stances (target: 0)
  SELECT COUNT(*) INTO v_unsourced_ca
  FROM inform.politician_answers pa
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE o.politician_id = pa.politician_id
      AND o.is_vacant = false
      AND d.state = 'CA'
      AND d.district_type IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC','STATE_BOARD')
  )
  AND (
    pc.politician_id IS NULL
    OR pc.sources IS NULL
    OR array_length(pc.sources, 1) IS NULL
    OR NOT EXISTS (
      SELECT 1 FROM unnest(pc.sources) s(u)
      WHERE u IS NOT NULL AND trim(u) != ''
    )
  );
  RAISE NOTICE 'POST-MIGRATION CA STATE unsourced stances: %', v_unsourced_ca;

  -- V2: CA state weak-source stances (target: 0)
  -- ... (see 103-RESEARCH.md Verification SQL V2 for full query)
  RAISE NOTICE 'POST-MIGRATION CA STATE weak-source stances: %', v_weak_ca;
END $$;
```

**Migration registration** (lines 342–344):
```sql
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('270', '270_ca_state_source_remediation')
ON CONFLICT (version) DO NOTHING;
```

---

### `supabase/migrations/YYYYMMDD_271_md_officials_stances.sql` (migration, INSERT-only)

**Analog:** `supabase/migrations/20260606000002_269_house_source_remediation.sql` — INSERT/UPSERT block only; no DELETE block needed.

**File header comment**:
```sql
-- Phase 103: MD Officials Fresh Stances
-- Requirements covered: STAX-02, QUAL-01
-- Source CSV: backend/data/stance-research/YYYY-MM-DD-md-officials.csv
-- No deletion log: MD officials had zero existing stances before this migration
--
-- MD officials (UUIDs from Phase 100 audit — use UUID literals, not name lookup):
--   Wes Moore          → 21e534c8-c0c0-42f5-b52b-5eb2f246d632
--   Aruna Miller       → ea9fc2d6-3b26-469a-978c-e8c846d2d49a
--   Anthony G. Brown   → 60329719-1d5b-4bb4-8295-38ea18f6f378
--   Brooke Lierman     → b26fb5d2-90eb-4108-8ce5-838df719473d
--   Dereck E. Davis    → 75378a96-8886-46eb-b0c1-37cbe2579265
--
-- Migration number: 271 (verify via SELECT MAX(version) before writing)
-- Applied: YYYY-MM-DD via psql session pooler
```

**INSERT-only UPSERT pattern** — same two-statement shape as migration 269 UPSERT block, but NO ARRAY_CAT needed (no prior context rows for MD officials). Use plain `sources = EXCLUDED.sources`:
```sql
BEGIN;

-- ---- Wes Moore / [topic_key] / value=[N] ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'topic-key-here'),
  N
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'topic-key-here'),
  'Reasoning text...',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://source-url.com/specific-page'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;
-- Plain overwrite (not ARRAY_CAT) — MD officials have no prior context rows

-- (repeat for each topic × official where evidence was found)

-- ============================================================
-- NO DELETE BLOCK — MD officials had zero existing stances
-- ============================================================

-- POST-STATE verification (V3 from 103-RESEARCH.md)
DO $$
DECLARE v_count integer; BEGIN
  SELECT COUNT(*) INTO v_count FROM essentials.politicians p
  LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
  WHERE p.id = ANY(ARRAY[
    '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
    'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
    '60329719-1d5b-4bb4-8295-38ea18f6f378',
    'b26fb5d2-90eb-4108-8ce5-838df719473d',
    '75378a96-8886-46eb-b0c1-37cbe2579265'
  ]::uuid[]) AND pa.topic_id IS NULL;
  RAISE NOTICE 'MD officials still with zero stances: %', v_count;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('271', '271_md_officials_stances')
ON CONFLICT (version) DO NOTHING;

COMMIT;
```

---

### `.planning/phases/103-state-remediation-ca-md/103-DELETION-LOG.md` (repository artifact)

**Analog:** `.planning/phases/102-federal-house-remediation/102-DELETION-LOG.md` (lines 1–34)

**Exact header and table format to replicate** (lines 1–16):
```markdown
# Phase 103 — Deletion Log (QUAL-02)

**Phase:** 103 — State Remediation — CA + MD
**Plan:** 02
**Migration:** 270 (supabase/migrations/YYYYMMDD_270_ca_state_source_remediation.sql)
**Produced:** YYYY-MM-DD

## Notes

Methodology applied (Phase 101 D-04): Delete if no real specific URL was found by the research-stances
agent, regardless of the current value. No "directional keep." No party-affiliation inference.

## Deletions

| politician full_name | topic_key | former value | reason |
|----------------------|-----------|--------------|--------|
| [Full Name] | [topic_key] | [N] | no evidence found |

**Total deletions: N**

Cross-check: [upsert count] CSV rows (upserts) + [delete count] deletions = [total] = Plan 01 flagged-stance count ✓
```

Key constraint: This log only covers CA (Plan 02). MD officials (Plan 03) have zero existing stances — no deletion log entries for MD.

---

## Shared Patterns

### pool.query() for all inform.* access
**Source:** `backend/scripts/run-house-source-triage.ts` (line 47), `supabase/migrations/20260606000002_269_house_source_remediation.sql` (direct SQL)
**Apply to:** `run-ca-source-triage.ts`, both migration files
```typescript
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
// ALL inform.* reads and writes go through pool.query()
// NEVER: supabaseAdmin.schema('inform').from(...)
```

### Blank-URL array filter in ARRAY() constructor
**Source:** `supabase/migrations/20260606000002_269_house_source_remediation.sql` (lines 40–43, repeated throughout)
**Apply to:** Both migration files, every sources array value
```sql
ARRAY(SELECT u FROM unnest(ARRAY[
  'https://url1.com/page',
  'https://url2.com/page'
]) AS u WHERE u IS NOT NULL AND trim(u) != '')
```

### Migration number verification before writing filename
**Source:** `supabase/migrations/20260606000002_269_house_source_remediation.sql` (line 17 comment)
**Apply to:** Both migration files
```bash
psql "$DATABASE_URL" -c "SELECT MAX(version) FROM supabase_migrations.schema_migrations;"
# Verify result before writing migration filenames 270 and 271
```

### DELETE context before answers (ordering)
**Source:** `supabase/migrations/20260606000002_269_house_source_remediation.sql` (line 185–186 comment)
**Apply to:** Migration 270 DELETE block
```sql
-- Order: DELETE context FIRST, then answers (defensive ordering)
DELETE FROM inform.politician_context WHERE politician_id = '...' AND topic_id = (...);
DELETE FROM inform.politician_answers WHERE politician_id = '...' AND topic_id = (...);
```

### UUID literals, not name-based lookup
**Source:** `supabase/migrations/20260606000002_269_house_source_remediation.sql` (all WHERE clauses)
**Apply to:** Both migration files (especially MD migration 271)
```sql
-- CORRECT: UUID literal
WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'

-- WRONG: name-based lookup (silent 0-row match risk due to middle-initial variants)
-- WHERE p.full_name = 'Anthony Brown'
```

### ON CONFLICT (version) DO NOTHING for migration registration
**Source:** `supabase/migrations/20260606000002_269_house_source_remediation.sql` (lines 342–344)
**Apply to:** Both migration files
```sql
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('270', '270_ca_state_source_remediation')
ON CONFLICT (version) DO NOTHING;
```

---

## No Analog Found

None — all files in Phase 103 have strong direct analogs from Phases 101 and 102.

---

## Metadata

**Analog search scope:** `backend/scripts/`, `supabase/migrations/`, `.planning/phases/102-federal-house-remediation/`
**Files scanned:** 5 analog files fully read
**Pattern extraction date:** 2026-06-06

### Critical differences from Phase 102 (CA-specific)

1. **Single CTE, not two.** Phase 102 had `HOUSE_POLITICIANS_CTE` + `DEFERRED_CANDIDATES_CTE`. Phase 103 has one `CA_POLITICIANS_CTE` covering all CA politicians (all district_types in one query).

2. **ARRAY_CAT vs plain overwrite in migration UPSERT.** Phase 102 used `sources = EXCLUDED.sources` (plain overwrite) throughout. Phase 103 CA migration must use `sources = politician_context.sources || EXCLUDED.sources` for any politician that already has a context row with existing sources (even homepage-only). MD migration 271 uses plain overwrite (no prior rows).

3. **`district_type` in GROUP BY.** The CA triage should include `district_type` in the GROUP BY and SELECT to distinguish Assembly / Senate / statewide exec in report output. Phase 102 did not need this because all house reps share one district_type.

4. **`scope` field in TargetRow removed or renamed.** Phase 102 used `scope: 'NATIONAL_LOWER' | 'NATIONAL_UPPER_DEFERRED'`. Phase 103 can use `district_type` directly (e.g., `'STATE_LOWER'`, `'STATE_UPPER'`, `'STATE_EXEC'`) — no need for a separate `scope` field.
