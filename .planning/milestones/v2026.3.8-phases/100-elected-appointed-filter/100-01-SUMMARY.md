---
phase: 100-elected-appointed-filter
plan: "01"
subsystem: essentials-api
tags: [backend, typescript, sql, politician-data, filter]
dependency_graph:
  requires: []
  provides: [is_appointed-field, faces_retention_vote-field, PoliticianFlatRecord-contract]
  affects: [essentials-frontend-filter, Plan-02]
tech_stack:
  added: []
  patterns: [explicit-field-whitelist, sql-select-extension, typescript-interface-extension]
key_files:
  created:
    - ev-accounts/tests/integration/essentials-fields.test.ts
  modified:
    - ev-accounts/backend/src/lib/essentialsService.ts
    - ev-accounts/backend/src/lib/essentialsBrowseService.ts
decisions:
  - Added is_appointed and faces_retention_vote to PoliticianFlatRecord as non-nullable booleans with ?? false defaults
  - Fixed essentialsBrowseService.ts as a Rule 3 blocking deviation — it also implements PoliticianFlatRecord
metrics:
  duration: "8 minutes"
  completed: "2026-03-30"
  tasks_completed: 2
  files_modified: 3
  files_created: 1
---

# Phase 100 Plan 01: Surface is_appointed and faces_retention_vote in API Summary

Added `is_appointed` and `faces_retention_vote` to `PoliticianFlatRecord` interface and all SQL SELECT clauses and row-mapping locations in the essentials address-search API, enabling the frontend filter (Plan 02) to resolve elected/appointed status using the priority chain and handle retention judges.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Add is_appointed and faces_retention_vote to PoliticianFlatRecord and all queries | aa425cb |
| 2 | Add integration test for field presence in API response shape | 8f85099 |

## Verification

- `npm run typecheck` exits 0 (verified)
- `essentials-fields.test.ts` — 3 tests pass (verified)
- `p.is_appointed, o.faces_retention_vote` — 4 matches in essentialsService.ts SQL queries
- `is_appointed: row.is_appointed` — 3 matches across row mappings
- `faces_retention_vote: .*row.faces_retention_vote` — 3 matches across row mappings

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] essentialsBrowseService.ts also implements PoliticianFlatRecord**
- **Found during:** Task 1 (TypeScript typecheck after editing essentialsService.ts)
- **Issue:** `essentialsBrowseService.ts` at line 231 also maps query rows to `PoliticianFlatRecord[]`. After adding the two required fields to the interface, this file failed to compile with `missing properties: is_appointed, faces_retention_vote`.
- **Fix:** Added `p.is_appointed, o.faces_retention_vote` to both SQL SELECT clauses in that file, plus `is_appointed` and `faces_retention_vote` row mappings.
- **Files modified:** `ev-accounts/backend/src/lib/essentialsBrowseService.ts`
- **Commit:** aa425cb (included in Task 1 commit)

## Known Stubs

None.

## Self-Check: PASSED

- `ev-accounts/tests/integration/essentials-fields.test.ts` — EXISTS
- `aa425cb` — FOUND in git log
- `8f85099` — FOUND in git log
