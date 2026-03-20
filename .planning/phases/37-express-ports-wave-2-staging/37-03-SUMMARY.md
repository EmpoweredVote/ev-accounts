---
phase: 37-express-ports-wave-2-staging
plan: "03"
subsystem: api
tags: [postgres, pool, staging, stances, building-photos, auto-promote]

# Dependency graph
requires:
  - phase: 37-02
    provides: stagingService.ts with politician CRUD/review/lock/merge (8 functions) and shared helpers
provides:
  - Stance CRUD, review with auto-promotion to inform.politician_answers, and locking (7 functions)
  - Building photo CRUD and review with auto-promotion to essentials.building_photos (4 functions)
  - stagingService.ts complete with 19 exported functions covering all three entity types
affects:
  - 37-04 (staging routes will import all 19 exported functions)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Stance approve: topic_id null-check (422) + essentials politician lookup by external_id before promotion to inform.politician_answers"
    - "Photo approve: UPSERT into essentials.building_photos ON CONFLICT (place_geoid)"
    - "newValue in reviewStance: UPDATE staging value before promotion + capture previousValue/newValue in review log"
    - "No lock functions for photos: building_photos has no locked_by/locked_at columns"

key-files:
  created: []
  modified:
    - backend/src/lib/stagingService.ts

key-decisions:
  - "Stance approval resolves politician via essentials.politicians WHERE external_id = Number(politicianExternalId) — NaN guard throws 422 before query"
  - "newValue in reviewStance: update staging.stances.value first, then promote updated value to politician_answers"
  - "review_log previous_value always = record.value at time of review call (before any newValue update)"
  - "Building photos have no lock endpoints — schema has no locked_by/locked_at columns"

patterns-established:
  - "Stance approve pattern: assertPending → topic_id guard → politician resolution → optional value update → promote → status update → log"
  - "Photo approve pattern: assertPending → upsert essentials → status update → log"

# Metrics
duration: 2min
completed: 2026-03-20
---

# Phase 37 Plan 03: Staging Service Stance and Photo Functions Summary

**Stance CRUD/review/lock + building photo CRUD/review with auto-promotion to inform.politician_answers and essentials.building_photos — stagingService.ts complete at 19 exported functions**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-20T16:17:05Z
- **Completed:** 2026-03-20T16:19:47Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added 7 stance service functions: getStances, getStanceById, createStance, updateStance, reviewStance, lockStance, unlockStance
- Added 4 building photo service functions: getPhotos, getPhotoById, createPhoto, reviewPhoto
- Stance approval enforces topic_id non-null (422) and resolves politician from essentials via external_id lookup before promoting to inform.politician_answers
- Photo approval upserts to essentials.building_photos on place_geoid conflict
- No lock/unlock functions for photos (schema has no locked_by/locked_at columns)

## Task Commits

Each task was committed atomically:

1. **Task 1: Stance service functions** - `9f4b820` (feat)
2. **Task 2: Building photo service functions** - `3052b4b` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `backend/src/lib/stagingService.ts` - Extended from 597 lines to 1010 lines; stance and photo sections appended; 19 total exported functions

## Decisions Made

- Stance approval NaN guard: if `Number(politicianExternalId)` is NaN (null or non-numeric string), throw 422 before hitting the DB — same guard pattern used in politician auto-promote
- `newValue` in `reviewStance` updates `staging.stances.value` before the `inform.politician_answers` upsert so the promoted value is consistent with what the staging row shows
- `previousValue` in review log is captured from `record.value` at the start of the call, before any newValue update — captures the original submitted value

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- stagingService.ts is complete with all 19 exported functions needed by routes
- Plan 37-04 (staging routes) is unblocked — can import all politician, stance, and photo functions
- No blockers

---
*Phase: 37-express-ports-wave-2-staging*
*Completed: 2026-03-20*
