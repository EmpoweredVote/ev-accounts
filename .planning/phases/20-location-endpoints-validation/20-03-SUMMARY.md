---
phase: 20-location-endpoints-validation
plan: 03
subsystem: api
tags: [supabase, express, typescript, location, jurisdiction, postgis]

# Dependency graph
requires:
  - phase: 20-01
    provides: geocodeAddress service and env validation
  - phase: 19-03
    provides: resolve_user_jurisdiction RPC in connect schema
  - phase: 19-01
    provides: upsert_user_location RPC and location_consent column on connected_profiles
provides:
  - GET /api/account/me/jurisdiction endpoint with consent gate
  - location_consent boolean field on GET /api/account/me response
affects: [phase-21, location-feature-consumers, frontend-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - supabaseAdmin used for trusted server-side consent check in jurisdiction route (consistent with tierGuards.ts)
    - requireConnected middleware blocks Inform-tier users before consent check
    - adminRpc() for resolve_user_jurisdiction RPC call

key-files:
  created: []
  modified:
    - backend/src/routes/account.ts
    - backend/src/types/database.types.ts

key-decisions:
  - "jurisdiction route uses supabaseAdmin (not user client) for consent check — trusted server-side read, consistent with tierGuards pattern"
  - "GET /me returns only location_consent boolean — never calls resolve_user_jurisdiction"
  - "location_consent added to database.types.ts manually since column added in Phase 19 migrations but type file not regenerated"

patterns-established:
  - "Consent gate pattern: check column on connected_profiles via supabaseAdmin, return 403 LOCATION_CONSENT_REQUIRED before calling expensive RPC"

# Metrics
duration: 2min
completed: 2026-03-13
---

# Phase 20 Plan 03: Location Endpoints Validation Summary

**GET /api/account/me/jurisdiction with consent gate (403 when location_consent false/null) and location_consent boolean added to GET /me response**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-14T00:35:57Z
- **Completed:** 2026-03-14T00:38:00Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- GET /api/account/me/jurisdiction route: requireAuth + requireConnected + consent gate, calls resolve_user_jurisdiction RPC, returns structured jurisdiction JSON
- GET /api/account/me now includes `location_consent: boolean` at response root for Connected users
- GET /me never calls resolve_user_jurisdiction — clean separation of concerns

## Task Commits

Each task was committed atomically:

1. **Task 1: GET /api/account/me/jurisdiction + location_consent on GET /me** - `bf74620` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `backend/src/routes/account.ts` - Added /me/jurisdiction route; added location_consent to connected_profiles SELECT and meResponse
- `backend/src/types/database.types.ts` - Added location_consent field to connected_profiles Row/Insert/Update (was missing from generated types)

## Decisions Made
- Jurisdiction route uses `supabaseAdmin` for the consent check, not the user-scoped client. This is consistent with how `tierGuards.ts` does tier checks — trusted server-side reads don't need RLS-scoped client.
- GET /me returns only `location_consent: boolean`. The jurisdiction data is only available via the dedicated /me/jurisdiction endpoint, keeping the GET /me response lean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added location_consent to database.types.ts**
- **Found during:** Task 1 (TypeScript compilation after adding location_consent to SELECT)
- **Issue:** `location_consent` column was added to `connect.connected_profiles` in Phase 19 migrations (migration 031) but `database.types.ts` was never regenerated. Supabase type inference produced `SelectQueryError` for the entire connected_profiles query, breaking all field access.
- **Fix:** Manually added `location_consent: boolean | null` to Row, `location_consent?: boolean | null` to Insert and Update shapes.
- **Files modified:** `backend/src/types/database.types.ts`
- **Verification:** `npx tsc --noEmit` — 0 errors after fix
- **Committed in:** bf74620 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required to unblock TypeScript compilation. No scope creep.

## Issues Encountered
None beyond the type file deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- GET /api/account/me/jurisdiction is ready for integration testing once a user with location set (location_consent = true) exists in the test DB
- GET /me now exposes location_consent for frontend to conditionally show location-related UI
- Plan 04 (validation/testing) can proceed

---
*Phase: 20-location-endpoints-validation*
*Completed: 2026-03-13*
