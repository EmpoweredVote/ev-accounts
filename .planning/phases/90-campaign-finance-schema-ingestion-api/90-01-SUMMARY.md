---
phase: 90-campaign-finance-schema-ingestion-api
plan: "01"
subsystem: essentials-schema
tags:
  - schema-migration
  - jsonb
  - tdd
  - campaign-finance
dependency_graph:
  requires: []
  provides:
    - essentials.politicians.finance_summary (JSONB column, remote DB)
    - backend/test/essentialsService-finance-summary.test.ts (RED wave-0 gate)
  affects:
    - essentialsService.ts (Plan 03 must add finance_summary to SELECT + interfaces + mappers)
tech_stack:
  added: []
  patterns:
    - ADD COLUMN IF NOT EXISTS (idempotent DDL)
    - Source-scan vitest test (static regex over TypeScript source, no runtime import)
key_files:
  created:
    - backend/migrations/268_finance_summary_column.sql
    - backend/test/essentialsService-finance-summary.test.ts
  modified: []
decisions:
  - "Target table is essentials.politicians, not inform.politicians — REQUIREMENTS.md text predates Phase 35 dedup; confirmed in RESEARCH.md Critical Finding"
  - "No index on finance_summary — JSONB is read-only display data, no WHERE clause queries"
  - "Wave-0 test uses source-scan pattern from essentialsService-mtfcc-routing.test.ts — no runtime import"
metrics:
  duration: "~12 minutes"
  completed: "2026-06-04"
  tasks_completed: 3
  files_created: 2
  files_modified: 0
---

# Phase 90 Plan 01: Campaign Finance Schema — finance_summary JSONB Column and Wave-0 RED Test

**One-liner:** Added idempotent `finance_summary JSONB` column to `essentials.politicians` (migration 268, applied to remote DB), and laid down the Wave-0 RED source-scan test that gates Plan 03's API surface update.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write migration 268 | 84c0915 | backend/migrations/268_finance_summary_column.sql |
| 2 | Apply migration 268 to remote DB | (apply-only, no edit) | Remote DB — essentials.politicians |
| 3 | Wave-0 RED test | 390c7cd | backend/test/essentialsService-finance-summary.test.ts |

---

## Task 2: Migration Apply — Channel and Verification

**Apply channel:** `psql "$DATABASE_URL"` against remote Supabase pooler at `aws-0-us-west-1.pooler.supabase.com:5432` using `DATABASE_URL` from `backend/.env` (path B per plan — MCP tools not available in this execution context).

**Migration output:**
```
ALTER TABLE
COMMENT
```

**Verification query output:**
```
   column_name   | data_type | is_nullable
-----------------+-----------+-------------
 finance_summary | jsonb     | YES
(1 row)
```

Column exists on `essentials.politicians` with `data_type=jsonb` and `is_nullable=YES`. Acceptance criteria met.

---

## Task 3: Wave-0 Vitest Output (RED State)

Test file: `backend/test/essentialsService-finance-summary.test.ts`

Run from main repo (worktree has no node_modules; test logic verified by copying to main repo's `test/` dir temporarily):

```
 Test Files  1 failed (1)
       Tests  5 failed (5)
   Start at  10:08:36
   Duration  687ms
```

All 5 tests fail (RED) as expected — `finance_summary` is not yet in `essentialsService.ts`. These 5 tests are the GREEN gate for Plan 03.

**Test cases:**
1. `PoliticianFlatRecord interface declares finance_summary` — FAIL (not yet in interface)
2. `PoliticianDetail interface declares finance_summary` — FAIL (not yet in interface)
3. `getPoliticiansFlatList SELECT references p.finance_summary` — FAIL (not in SELECT)
4. `getPoliticianById SELECT references p.finance_summary` — FAIL (not in SELECT)
5. `row mappers project finance_summary into the returned record` — FAIL (not in mapper)

---

## Deviations from Plan

None — plan executed exactly as written.

**Note on FINA-01 table target:** RESEARCH.md correctly identifies that `essentials.politicians` (not `inform.politicians`) is the correct target. The migration and this summary reflect the RESEARCH.md finding. The REQUIREMENTS.md requirement text predates Phase 35 deduplication. No deviation from plan was needed — the plan itself already incorporates the correction.

---

## Threat Surface Scan

No new network endpoints introduced. No auth paths modified. No new trust boundaries. Migration adds a nullable JSONB column with no constraints — `ADD COLUMN IF NOT EXISTS` with no default is metadata-only in Postgres 11+ (no table rewrite).

No threat flags.

---

## Self-Check: PASSED

| Item | Status |
|------|--------|
| backend/migrations/268_finance_summary_column.sql | FOUND |
| backend/test/essentialsService-finance-summary.test.ts | FOUND |
| 90-01-SUMMARY.md | FOUND |
| Commit 84c0915 (migration) | FOUND |
| Commit 390c7cd (test) | FOUND |
