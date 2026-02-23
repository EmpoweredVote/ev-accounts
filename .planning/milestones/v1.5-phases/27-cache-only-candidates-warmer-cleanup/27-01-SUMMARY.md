---
phase: 27-cache-only-candidates-warmer-cleanup
plan: 01
subsystem: api
tags: [go, postgres, gorm, ballotready, candidates, election-records]

# Dependency graph
requires:
  - phase: 26-geofence-only-search
    provides: DB-only search paths established; BallotReady fallback removed from address search

provides:
  - GetCandidatesByZip reads from election_records with is_active=true (no live API call)
  - warmFederal, warmState, warmLocal, warmZip deleted entirely
  - handleZipLookup simplified to DB-only fetchOfficialsFromDB call
  - ensureCandidacyData lazy-fetch goroutine deleted
  - GetCacheStatus endpoint and /cache-status/{zip} route removed
  - Lock infrastructure (tryAcquireLock, releaseLock, isWarmingInProgress, waitForDataMin) deleted
  - CacheStatusResponse struct deleted
  - IsActive bool column added to ElectionRecord model

affects: [28-address-search-frontend, 29-ballotready-audit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DB-only candidate reads: election_records joined through offices/districts/chambers with is_active filter"
    - "ZIP-to-state derivation: zipPrefixToState() static lookup (no API call)"
    - "Local candidate geo-filtering: EXISTS subquery on zip_politicians table"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/models.go
    - EV-Backend/internal/essentials/handlers.go
    - EV-Backend/internal/essentials/routes.go
    - EV-Backend/internal/essentials/admin.go
    - EV-Backend/cmd/bulk-import/main.go

key-decisions:
  - "admin.go WarmZip/WarmZipWith removed; runBulkImport returns immediate failure with message — live warmer no longer available"
  - "cmd/bulk-import deprecated in place (main.go prints message, returns) — not deleted to preserve git history"
  - "ensureCandidacyData removed entirely (no stub): profile pages now read DB only, no background goroutine on profile view"
  - "FederalCache, StateCache, ZipCache GORM models kept in models.go and setup.go for this plan — table drops deferred to Plan 02 per RESEARCH.md pitfall guidance"

patterns-established:
  - "Warmer removal pattern: delete function + all call sites + supporting infrastructure in single task"

requirements-completed: [BR-03, CAND-01]

# Metrics
duration: 7min
completed: 2026-02-22
---

# Phase 27 Plan 01: Cache-Only Candidates & Warmer Cleanup Summary

**Replaced live BallotReady GetCandidatesByZip with DB-only election_records query (is_active filter) and deleted all three cache warmers, lock infrastructure, and GetCacheStatus endpoint**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-22T05:38:15Z
- **Completed:** 2026-02-22T05:45:03Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- GetCandidatesByZip now reads from `essentials.election_records` with `is_active=true AND withdrawn=false`, joined through politicians/offices/districts/chambers — no BallotReady API call
- Added `IsActive bool` field (gorm default:false) to ElectionRecord model; GORM AutoMigrate will add the column on next server start
- Deleted warmFederal, warmState, warmLocal, warmZip functions entirely (1,294 lines removed)
- Simplified handleZipLookup to three lines: derive state, fetchOfficialsFromDB, return JSON with X-Data-Status: fresh
- Removed warmer goroutine blocks from SearchPoliticians
- Deleted GetCacheStatus/getCacheStatus functions and /cache-status/{zip} route
- Deleted all lock and polling infrastructure (tryAcquireLock, releaseLock, isWarmingInProgress, tryAcquireZipWarmLock, releaseZipWarmLock, waitForDataMin, waitForData)
- Deleted ensureCandidacyData lazy-fetch goroutine and its call site in GetPoliticianByID

## Task Commits

Each task was committed atomically:

1. **Task 1: Add is_active column and rewrite GetCandidatesByZip to DB-only** - `5aeb4ee` (feat)
2. **Task 2: Delete all warmer functions, cache status endpoint, and lock infrastructure** - `791b6c2` (feat)

_Note: commits are in EV-Backend git repo (not workspace root)_

## Files Created/Modified
- `EV-Backend/internal/essentials/models.go` - Added IsActive bool to ElectionRecord struct
- `EV-Backend/internal/essentials/handlers.go` - Rewrote GetCandidatesByZip, simplified handleZipLookup, deleted all warmers and lock functions, removed ensureCandidacyData, removed ballotready import
- `EV-Backend/internal/essentials/routes.go` - Removed /cache-status/{zip} route registration
- `EV-Backend/internal/essentials/admin.go` - Removed WarmZip/WarmZipWith exports, simplified runBulkImport to immediate failure
- `EV-Backend/cmd/bulk-import/main.go` - Deprecated CLI tool (prints message and exits)

## Decisions Made
- admin.go WarmZip/WarmZipWith removed; runBulkImport now returns immediate failure — live warmer no longer available, data import needs new pipeline in a future phase
- cmd/bulk-import deprecated in place: main.go replaced with a message-and-exit program rather than deleting the file, preserving git history
- ensureCandidacyData removed entirely (no stub): profile pages read from DB only going forward
- FederalCache, StateCache, ZipCache GORM models are still defined in models.go and listed in setup.go AutoMigrate — the cache table DROP statements and model removals are deferred to Plan 02 (correct per RESEARCH.md pitfall guidance: remove all reads before dropping tables)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] admin.go called warmLocal (undefined after deletion)**
- **Found during:** Task 2 (Delete warmer functions)
- **Issue:** admin.go had WarmZip(), WarmZipWith(), and runBulkImport() all calling warmLocal() which no longer exists after Task 2 deletion. Build failed with "undefined: warmLocal".
- **Fix:** Removed WarmZip() and WarmZipWith() exported functions. Replaced runBulkImport() with a stub that immediately marks the job as failed with an explanatory message. Removed `provider` import (no longer needed).
- **Files modified:** EV-Backend/internal/essentials/admin.go
- **Verification:** go build ./... passes
- **Committed in:** 791b6c2 (Task 2 commit)

**2. [Rule 3 - Blocking] cmd/bulk-import/main.go called essentials.WarmZipWith (undefined after admin.go update)**
- **Found during:** Task 2 (Delete warmer functions)
- **Issue:** CLI tool directly called essentials.WarmZipWith() which was removed as part of warmer cleanup. Build failed with "undefined: essentials.WarmZipWith".
- **Fix:** Replaced cmd/bulk-import/main.go with a minimal program that prints a deprecation message and exits. Removed all cicero/provider imports.
- **Files modified:** EV-Backend/cmd/bulk-import/main.go
- **Verification:** go build ./... passes
- **Committed in:** 791b6c2 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking compile errors caused by warmer removal)
**Impact on plan:** Both fixes were necessary consequences of deleting warmLocal. No scope creep — no new features added, only cleanup of broken callers.

## Issues Encountered
None beyond the two auto-fixed blocking compile errors documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plan 02 can now proceed: drop federal_cache, state_caches, zip_caches tables and remove their GORM models and AutoMigrate entries from setup.go. All reads against those tables have been removed in this plan.
- State flag for Phase 27 blocker resolved: the election_records → zip_politicians join path was confirmed valid during Task 1 implementation.

---
*Phase: 27-cache-only-candidates-warmer-cleanup*
*Completed: 2026-02-22*
