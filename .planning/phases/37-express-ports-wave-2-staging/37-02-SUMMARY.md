---
phase: 37-express-ports-wave-2-staging
plan: 02
subsystem: api
tags: [typescript, postgres, pool-query, staging, essentials, politicians, review-workflow]

# Dependency graph
requires:
  - phase: 37-01
    provides: requireStagingReviewer middleware, staging_reviewer role, status defaults
  - phase: 35
    provides: essentials.politicians as sole politician source of truth
provides:
  - "StagingPolitician and PoliticianReviewLog TypeScript interfaces"
  - "stagingService.ts with 8 exported politician service functions"
  - "Auto-promotion from staging.politicians to essentials.politicians on approve"
  - "Atomic lock acquire/release pattern for concurrent reviewer safety"
  - "Merge workflow: source marked rejected with merged_to_id set"
affects: [37-03, 37-04, phase-38-essentials]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pool.query() for all staging schema operations (not in PostgREST exposed list)"
    - "assertPending() state machine guard — 422 for non-pending mutations"
    - "getDisplayName() server-derives reviewer/submitter names from public.users — never trust client body"
    - "Atomic lock acquire: UPDATE ... WHERE locked_by IS NULL RETURNING id"
    - "Dynamic parameterized SET clause in updatePolitician — no string interpolation"
    - "External_id type bridge: staging text -> essentials bigint via Number() with NaN guard"
    - "Upsert-vs-insert branching on external_id nullability for essentials promotion"

key-files:
  created:
    - backend/src/lib/stagingService.ts
  modified: []

key-decisions:
  - "promoteToEssentials is non-exported private helper — called only by reviewPolitician on approve path"
  - "mergePolitician does NOT increment review_count — merge is a routing decision, not a quality review"
  - "lockPolitician stores userId (UUID string) in locked_by column, not display_name — avoids stale name if user renames"
  - "unlockPolitician has no ownership check at service layer — route layer enforces who can unlock"
  - "Both tasks implemented in a single file write for atomicity — committed as one task commit"

patterns-established:
  - "stagingService pattern: matches treasuryService header, explicit whitelist mapper, pool.query() only"
  - "httpStatus error shape: attach .httpStatus to Error before throw; route handler reads err.httpStatus"

# Metrics
duration: 2min
completed: 2026-03-20
---

# Phase 37 Plan 02: Staging Service Summary

**pool.query()-only staging politician service with 8 exports: CRUD, approve-with-auto-promotion, reject, atomic lock, and merge into essentials.politicians**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-20T16:09:41Z
- **Completed:** 2026-03-20T16:11:59Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Created `stagingService.ts` with all 8 politician service functions, zero supabaseAdmin references
- Auto-promotion on approve: upserts to `essentials.politicians` via pool.query() with external_id conflict handling (staging text -> essentials bigint conversion)
- Atomic lock acquire using `UPDATE ... WHERE locked_by IS NULL` pattern — prevents TOCTOU races in concurrent review sessions
- State machine enforcement via `assertPending()`: updatePolitician, reviewPolitician, and mergePolitician all throw 422 for non-pending records

## Task Commits

Both tasks implemented in a single atomic file write (both modify same file; written together for correctness):

1. **Task 1: Shared helpers, types, and politician CRUD** - `617f860` (feat)
2. **Task 2: Review, lock, merge, auto-promotion** - `617f860` (feat — included in Task 1 commit)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `backend/src/lib/stagingService.ts` — StagingPolitician type, PoliticianReviewLog type, CreatePoliticianInput type, mapPoliticianRow mapper, getDisplayName/assertPending helpers, and 8 exported service functions

## Decisions Made

- **promoteToEssentials is private**: Only `reviewPolitician` calls it on the approve path. Not exported — no caller should trigger essentials promotion outside the review workflow.
- **lockPolitician stores userId in locked_by**: The column stores the raw UUID, not the display name. This avoids stale name issues if a reviewer changes their display_name between lock and unlock. Route layer can resolve display_name for the UI response.
- **mergePolitician omits review_count increment**: The plan spec does not list it for merge. Merge is a routing decision (this record is a duplicate of target), not a quality-review event. review_count semantically tracks how many times the record was evaluated for approval/rejection.
- **Dynamic SET clause in updatePolitician**: Iterates `columnMap` entries, skips `undefined` values, builds parameterized query. Only columns explicitly present in the patch body are updated. No string interpolation at any point.
- **Both tasks in one commit**: Tasks 1 and 2 both target the same file. Writing them together in a single pass was more correct (avoids a partial-state commit where the file exists but lacks review functions that rely on shared helpers). Documented here for traceability.

## Deviations from Plan

None — plan executed as specified. Both tasks written together in one file creation for atomicity (noted in decisions above). All plan-specified behaviors are present.

## Issues Encountered

- **tsc OOM constraint (known)**: Node v24 + Windows environment causes tsc --noEmit to OOM. Static analysis used instead: confirmed correct imports, all 8 exports present, no supabaseAdmin references, pool.query() exclusive, assertPending/getDisplayName called correctly in each function.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 37-03 (stances service) unblocked — same pool.query() pattern established
- Plan 37-04 (building photos service) unblocked
- Route files (37-05 or later) can import all 8 exports from stagingService.ts
- Auto-promotion tested at the service layer; route integration test deferred to route plan

---
*Phase: 37-express-ports-wave-2-staging*
*Completed: 2026-03-20*
