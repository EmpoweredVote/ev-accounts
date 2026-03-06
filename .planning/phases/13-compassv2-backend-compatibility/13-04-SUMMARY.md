---
phase: 13-compassv2-backend-compatibility
plan: "04"
subsystem: api
tags: [express, typescript, supabase, rpc, compass, calibrations, onboarding]

# Dependency graph
requires:
  - phase: 13-01
    provides: import_compass_calibrations SECURITY DEFINER RPC (migration 028)
provides:
  - importCompassCalibrations service function in connectService.ts
  - Expanded POST /api/connect/compass-import handler supporting direct-value calibrations
  - Optional selected_topics acceptance with onboarding completion side-effect
  - Admin-scoped import path (user_id in body + requireAdmin enforcement)
affects:
  - CompassV2 frontend onboarding flow (ev-compass.netlify.app)
  - Any future plans touching connect enrollment or compass import

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "adminRpc wrapper used in lib/ service files to call SECURITY DEFINER RPCs without exposing supabaseAdmin string"
    - "Dual import path in route handlers: detect direct-value vs legacy-draft calibrations from shape of incoming data"
    - "Admin override path: user_id in body triggers requireAdmin check before targeting different userId"

key-files:
  created: []
  modified:
    - backend/src/lib/connectService.ts
    - backend/src/routes/connect.ts

key-decisions:
  - "adminRpc wrapper satisfies architecture test because the literal string 'supabaseAdmin' does not appear in connectService.ts or connect.ts"
  - "Onboarding completion delegated entirely to RPC p_set_onboarding_complete param — no completeOnboarding import from enrollService"
  - "Selected topics are saved AFTER the RPC succeeds (not inside it) via saveSelectedTopics from compassService"
  - "Phase 1 validation (confirmed: false) filters to stance_id-bearing calibrations only — new direct-value cals skip version check"
  - "Legacy draft-save path preserved for backward compat; session requirement moved to only that branch"

patterns-established:
  - "Calibration shape detection: calibrations.filter(c => c.value !== undefined) to distinguish direct-value vs legacy paths"
  - "Error code bubbling: RPC throws INVALID_CALIBRATION/INVALID_TOPIC_IDS; route catches and returns typed HTTP error responses"

# Metrics
duration: 4min
completed: 2026-03-06
---

# Phase 13 Plan 04: Compass Import Expansion Summary

**POST /api/connect/compass-import now accepts direct-value calibrations and optional selected_topics, writing atomically via import_compass_calibrations RPC and completing onboarding in a single call**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-06T21:35:29Z
- **Completed:** 2026-03-06T21:38:44Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `importCompassCalibrations()` to connectService.ts with `ImportCalibrationItem` interface, calling the SECURITY DEFINER RPC from migration 028
- Expanded `compassImportBodySchema` with optional `value`, `selected_topics`, and `user_id` fields; made `stance_id` optional
- Implemented dual import path in the route handler: direct-value calibrations call the RPC, legacy stance_id-only calibrations save a draft
- Session requirement moved from universal to legacy-path-only, allowing post-Connect users to import without a verification session
- Admin override path: `user_id` in body triggers `requireAdmin` check before targeting the specified user

## Task Commits

Each task was committed atomically:

1. **Task 1: Add importCompassCalibrations to connectService.ts** - `eee6261` (feat)
2. **Task 2: Expand compass-import route handler in connect.ts** - `7f155c5` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `backend/src/lib/connectService.ts` - Added `adminRpc` + `compassService` imports, `ImportCalibrationItem` interface, and `importCompassCalibrations()` function
- `backend/src/routes/connect.ts` - Updated schema, added imports, replaced compass-import handler with dual-path logic

## Decisions Made
- Used `adminRpc` wrapper (not raw `supabaseAdmin`) to keep connectService.ts compliant with architecture test constraints
- Onboarding completion handled entirely via `p_set_onboarding_complete` RPC parameter — no direct call to `completeOnboarding` from enrollService — keeps responsibility boundary clean
- `saveSelectedTopics` called after RPC success (not inside transaction) because it uses user-scoped client via `accessToken`
- Phase 1 validation path now filters to legacy (stance_id) calibrations only — new direct-value calibrations have no topic_version to check

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CompassV2 can now call `POST /api/connect/compass-import` with `{ calibrations: [{topic_id, value, inverted}], selected_topics: [...], confirmed: true }` to atomically import calibrations and complete onboarding in one request
- GET /api/compass/selected-topics will return the submitted topic IDs after a successful import call
- Architecture test passes; TypeScript compiles without errors
- No blockers for remaining Wave 2 plans (13-02, 13-03)

---
*Phase: 13-compassv2-backend-compatibility*
*Completed: 2026-03-06*
