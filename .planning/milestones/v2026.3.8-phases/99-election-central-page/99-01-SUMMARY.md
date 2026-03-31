---
phase: 99-election-central-page
plan: 01
subsystem: api
tags: [elections, geocoding, district_type, typescript, expressjs, postgresql, postGIS]

# Dependency graph
requires:
  - phase: 98-election-data-import
    provides: getElectionsByCoordinate function and elections schema (races, candidates)
provides:
  - "GET /api/essentials/elections-by-address endpoint (address → geocode → elections)"
  - "district_type field on ElectionRace interface and SQL responses"
  - "Synthetic district_type for statewide races via jurisdiction_level mapping"
  - "Integration tests for elections-by-address in tests/integration/"
affects:
  - "99-02 (frontend Election Central page consumes this endpoint)"
  - "essentials frontend (classifyCategory tier sorting uses district_type)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Address-based election lookup: geocodeAddress() then getElectionsByCoordinate() — lat/lng never exposed"
    - "Graceful geocoding errors: ADDRESS_NOT_FOUND + PO_BOX_REJECTED return 200 { elections: [] }"
    - "Synthetic district_type: jurisdiction_level string mapped to district_type enum for statewide races"

key-files:
  created:
    - "tests/integration/essentials-elections.test.ts"
  modified:
    - "ev-accounts/backend/src/lib/electionService.ts"
    - "ev-accounts/backend/src/routes/essentials.ts"

key-decisions:
  - "ADDRESS_NOT_FOUND and PO_BOX_REJECTED return 200 { elections: [] } instead of 422 — consistent with non-geocodable address = no elections rather than an error"
  - "district_type added as string | null to allow for future race types without strict enum constraint"
  - "Test file placed at tests/integration/ (not src/routes/__tests__/) to match actual project vitest config include pattern"

patterns-established:
  - "Synthetic district_type mapping: federal=NATIONAL_EXEC, state=STATE_EXEC, local=LOCAL_EXEC for statewide races"

requirements-completed: [ELEC-01, ELEC-06]

# Metrics
duration: 3min
completed: 2026-03-30
---

# Phase 99 Plan 01: Elections-by-Address Backend Endpoint Summary

**Address-based election lookup endpoint with district_type enrichment on ElectionRace for frontend tier classification**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-30T00:50:45Z
- **Completed:** 2026-03-30T00:54:00Z
- **Tasks:** 3 (Task 0, Task 1, Task 2)
- **Files modified:** 3

## Accomplishments
- New `GET /api/essentials/elections-by-address?address=...` endpoint that geocodes internally and returns enriched election data
- `district_type: string | null` added to `ElectionRace` interface with SQL support in both geofence query (Part A) and statewide fallback query (Part B)
- Post-processing synthetic `district_type` for statewide races: maps `jurisdiction_level` → `NATIONAL_EXEC` / `STATE_EXEC` / `LOCAL_EXEC`
- Integration tests with 4 CI-safe test cases following existing project supertest patterns

## Task Commits

Each task was committed atomically in the `ev-accounts` repo:

1. **Task 0: Create stub test file** - `23d8dd1` (test)
2. **Task 1: Add district_type to ElectionRace and SQL queries** - `5609a16` (feat)
3. **Task 2: Add elections-by-address endpoint** - `67c860c` (feat)

## Files Created/Modified
- `tests/integration/essentials-elections.test.ts` - 4 CI-safe integration tests for the new endpoint
- `ev-accounts/backend/src/lib/electionService.ts` - district_type on interfaces and SQL queries, post-processing synthetic district_type
- `ev-accounts/backend/src/routes/essentials.ts` - New GET /elections-by-address route, geocodeAddress import

## Decisions Made
- Placed test file in `tests/integration/` (the project's actual vitest include path) instead of `src/routes/__tests__/` as specified in the plan — the plan's path would have been outside vitest's configured scope.
- ADDRESS_NOT_FOUND and PO_BOX_REJECTED return `200 { elections: [] }` rather than 422 — consistent with "this address has no elections" being a valid result rather than a user error.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test file path corrected to match project vitest config**
- **Found during:** Task 0 (stub test file)
- **Issue:** Plan specified `src/routes/__tests__/essentials-elections.test.ts` but vitest config includes `../tests/**/*.{test,spec}.{ts,js}` — files in `src/routes/__tests__/` are not discovered
- **Fix:** Created test file at `tests/integration/essentials-elections.test.ts` matching the project's actual test discovery pattern
- **Files modified:** `tests/integration/essentials-elections.test.ts`
- **Verification:** Test runs and all 4 test cases execute with `ADMIN_INGEST_TOKEN=test npm test`
- **Committed in:** 23d8dd1

---

**Total deviations:** 1 auto-fixed (1 blocking path correction)
**Impact on plan:** File placement corrected to match project reality. No scope changes.

## Issues Encountered
- Pre-existing test failures in 16 test files due to missing `ADMIN_INGEST_TOKEN` env var in the CI environment — not caused by this plan's changes. All 4 new tests pass when the env var is set.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `GET /api/essentials/elections-by-address` is live and type-safe
- `ElectionRace.district_type` available for frontend tier classification via existing `classifyCategory()` logic
- Phase 99-02 (Election Central frontend page) can consume this endpoint directly with address string from existing Google Maps autocomplete

---
*Phase: 99-election-central-page*
*Completed: 2026-03-30*
