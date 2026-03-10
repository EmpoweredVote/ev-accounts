---
phase: 18-compassv2-api-contract
plan: 02
subsystem: api
tags: [express, zod, optionalAuth, compass, anonymous-mode]

# Dependency graph
requires:
  - phase: 18-01
    provides: bearer token auth + account/me endpoint changes enabling CompassV2 compatibility
provides:
  - optionalAuth short-circuit pattern on five compass answer routes (anonymous compass mode)
  - Decimal value schema for compass answers matching migration 030 NUMERIC(3,1) column
affects:
  - 18-03 (CV2-03 signup email field — follows same phase)
  - 18-04 (CV2-04 response shape — follows same phase)
  - CompassV2 frontend (must call these routes unauthenticated before sign-in)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "optionalAuth + short-circuit guard: routes use optionalAuth middleware; first line checks !authReq.userId and returns empty data ([], null, { topic_ids: [] }) before any DB access"

key-files:
  created: []
  modified:
    - backend/src/routes/compass.ts

key-decisions:
  - "Anonymous compass mode: unauthenticated requests to answer routes return empty data (not 401) so CompassV2 can display compass before sign-in"
  - "Short-circuit returns empty data, not 403: unauthenticated PUT/GET /selected-topics returns { topic_ids: [] } rather than NOT_CONNECTED, which is reserved for authenticated users without a connected_profiles row"
  - "postAnswerSchema value: z.number().multipleOf(0.5).min(0.5).max(5.5) — matches NUMERIC(3,1) column from migration 030; write-in placement values 0.5 and 5.5 are valid extremes"

patterns-established:
  - "optionalAuth short-circuit: place !authReq.userId guard as the FIRST line of handler body (before Zod parse and before try block) to avoid unnecessary validation on unauthenticated requests"

# Metrics
duration: 3min
completed: 2026-03-10
---

# Phase 18 Plan 02: Anonymous Compass Mode + Decimal Value Schema Summary

**Five compass answer routes converted from requireAuth to optionalAuth with anonymous short-circuit guards, returning empty data for unauthenticated callers; postAnswerSchema updated to accept NUMERIC(3,1) decimal values matching migration 030**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-10T~17:48Z
- **Completed:** 2026-03-10T~17:51Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Five compass answer routes now return 200 with empty data for unauthenticated requests (anonymous compass mode), enabling CompassV2 to display the compass before sign-in
- `postAnswerSchema.value` updated from `z.number().int().min(1).max(5)` to `z.number().multipleOf(0.5).min(0.5).max(5.5)`, aligned with migration 030's NUMERIC(3,1) column type
- Architecture comment block updated to document the anonymous compass mode pattern for future maintainers

## Task Commits

Each task was committed atomically:

1. **Task 1: Update Zod value schema to accept decimal compass values** - `9328cc8` (feat)
2. **Task 2: Convert five routes from requireAuth to optionalAuth with short-circuit guards** - `82c7841` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `backend/src/routes/compass.ts` — five routes (GET /answers, POST /answers/batch, GET /selected-topics, PUT /selected-topics, POST /answers) switched from requireAuth to optionalAuth with short-circuit guards; postAnswerSchema value field updated to decimal; architecture comment updated

## Decisions Made

- **Anonymous short-circuit returns empty data, not 403**: unauthenticated PUT/GET `/selected-topics` returns `{ topic_ids: [] }` (not NOT_CONNECTED). The NOT_CONNECTED response is reserved for authenticated users who haven't completed the Connect flow — a meaningful distinction. Unauthenticated users simply have no topics yet.
- **Guard placed before Zod parse on write routes**: For POST /answers/batch and PUT /selected-topics, the `!authReq.userId` guard is inserted before the schema parse. This avoids a 422 validation error for unauthenticated requests that may not supply a valid body, which would be confusing behavior.
- **requireAuth preserved on DELETE /answers/me and GET /progress**: These routes mutate or compute sensitive state — anonymous access would be meaningless and potentially harmful.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Anonymous compass mode is live; CompassV2 can now call GET /compass/topics, GET /compass/answers, POST /compass/answers/batch, GET /compass/selected-topics, PUT /compass/selected-topics, and POST /compass/answers without authentication and receive well-formed empty responses
- Ready for Phase 18 Plan 03 (CV2-03: signup email field) or Plan 04 (CV2-04: response shape)

---
*Phase: 18-compassv2-api-contract*
*Completed: 2026-03-10*
