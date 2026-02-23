---
phase: 27-cache-only-candidates-warmer-cleanup
plan: 02
subsystem: api
tags: [go, postgres, gorm, ballotready, cache, cleanup]

# Dependency graph
requires:
  - phase: 27-cache-only-candidates-warmer-cleanup
    plan: 01
    provides: Warmer functions deleted, ensureCandidacyData removed, all reads against cache tables gone

provides:
  - BallotReady blank import removed from setup.go — init() no longer runs at startup
  - Provider var and provider.NewProvider() initialization removed from setup.go
  - DROP TABLE IF EXISTS for federal_cache, state_caches, zip_caches added to Init()
  - FederalCache, StateCache, ZipCache structs deleted from models.go
  - Cache structs removed from AutoMigrate list in setup.go
  - Backend starts with no BallotReady provider at all

affects: [29-ballotready-audit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Idempotent table cleanup: DROP TABLE IF EXISTS in Init() before AutoMigrate — safe to run repeatedly"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/setup.go
    - EV-Backend/internal/essentials/models.go

key-decisions:
  - "cicero blank import kept in setup.go — handlers.go directly references cicero types and functions; Phase 29 will audit remaining cicero dependencies"
  - "external_global_id field kept in upsert map (handlers.go line 606) — this is the data-ingestion path, not the GetPoliticianByID query"
  - "Task 1 (ensureCandidacyData / ExternalGlobalID cleanup) was already completed by Plan 01 (791b6c2) — Plan 02 only needed to execute Task 2"

patterns-established:
  - "DROP TABLE IF EXISTS before AutoMigrate: safe idempotent cleanup of deprecated tables on each server start"

requirements-completed: [BR-03, BR-04, CAND-01]

# Metrics
duration: 5min
completed: 2026-02-22
---

# Phase 27 Plan 02: Cache-Only Candidates & Warmer Cleanup Summary

**Removed BallotReady provider registration from startup, deleted cache table GORM models, and added DROP TABLE statements for federal_cache/state_caches/zip_caches — completing full BallotReady API disconnection**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-22T21:48:39Z
- **Completed:** 2026-02-22T21:53:00Z
- **Tasks:** 2 (Task 1 pre-completed by Plan 01; Task 2 executed here)
- **Files modified:** 2

## Accomplishments
- Removed `_ "ballotready"` blank import from setup.go — BallotReady init() no longer registers at server startup
- Removed `var Provider provider.OfficialProvider` package-level variable and its `provider.NewProvider()` initialization block from Init()
- Removed `provider` package import from setup.go (no longer needed after Provider var deletion)
- Added DROP TABLE IF EXISTS for `essentials.federal_cache`, `essentials.state_caches`, `essentials.zip_caches` in Init() before AutoMigrate
- Deleted `FederalCache`, `StateCache`, `ZipCache` struct definitions and their `TableName()` methods from models.go
- Removed the three cache structs from the AutoMigrate list in setup.go
- Backend now starts with zero BallotReady touchpoints

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove ensureCandidacyData lazy-fetch and clean up GetPoliticianByID** - `791b6c2` (feat) _(completed in Plan 01)_
2. **Task 2: Deregister BallotReady provider and drop cache tracking tables** - `9a1de3c` (feat)

_Note: Task 1 was pre-completed by Plan 01 commit 791b6c2. Plan 02 only needed Task 2._

**Plan metadata:** _(docs commit recorded below)_

## Files Created/Modified
- `EV-Backend/internal/essentials/setup.go` - Removed ballotready blank import, Provider var, provider initialization block, provider import; added DROP TABLE statements; removed cache structs from AutoMigrate
- `EV-Backend/internal/essentials/models.go` - Deleted FederalCache, StateCache, ZipCache structs and their TableName() methods

## Decisions Made
- cicero blank import kept in setup.go since handlers.go directly uses `cicero` package (type aliases, upsertOfficial, fetchCiceroOfficialsByTypes) — Phase 29 will audit remaining cicero dependencies
- `external_global_id` in the politician upsert map (handlers.go line 606) was not touched — it is in the data-ingestion path (upsertNormalizedOfficial), not the GetPoliticianByID query that was cleaned up in Plan 01
- Task 1 was already completed by Plan 01 per its SUMMARY — Plan 02 execution correctly skipped re-doing that work

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written for Task 2. Task 1 was pre-completed by Plan 01.

---

**Total deviations:** 0

## Issues Encountered
None. Plan 01 had already removed ensureCandidacyData, ExternalGlobalID from GetPoliticianByID, and the ballotready handler import. Task 2 changes were clean and compiled on the first attempt.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 27 complete: BallotReady is fully disconnected from the running server (no warmers, no lazy-fetch, no provider registration, no cache tables)
- Phase 28 (address-search-frontend) can proceed — backend is stable and DB-only
- Phase 29 (ballotready-audit) can begin cicero/provider cleanup when scheduled
- Cache tables (federal_cache, state_caches, zip_caches) will be dropped automatically on next server start

---
*Phase: 27-cache-only-candidates-warmer-cleanup*
*Completed: 2026-02-22*
