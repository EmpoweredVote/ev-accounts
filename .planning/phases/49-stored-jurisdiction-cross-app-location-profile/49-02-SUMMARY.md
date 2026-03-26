---
phase: 49-stored-jurisdiction-cross-app-location-profile
plan: 02
subsystem: api
tags: [postgres, jurisdiction, geocoding, connected-profiles, pool-query]

# Dependency graph
requires:
  - phase: 49-01
    provides: 12 jurisdiction columns on connect.connected_profiles (congressional_geo_id, congressional_district_name, state_senate_geo_id, state_senate_district_name, state_house_geo_id, state_house_district_name, county_geo_id, county_name, school_district_geo_id, school_district_name, jurisdiction_state, jurisdiction_city)
provides:
  - geocodeAddress now returns city alongside state
  - set-location writes 12 stored jurisdiction columns at location-set time (no per-request RPC)
  - /account/me, PATCH /account/me, /account/me/jurisdiction all read jurisdiction from stored columns
  - /representatives/me Path 1 reads stored GEO IDs (no RPC); X-Formatted-Address uses stored city/state
affects:
  - phase 50+ (any phase consuming jurisdiction fields from /account/me or /representatives/me)
  - essentials frontend (receives state/city in representatives response headers)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Jurisdiction stored at write time (set-location), read from columns at request time — eliminates per-request PostGIS point-in-polygon RPC"
    - "pool.query<T>() with explicit generic type for all stored-column reads from connect schema"

key-files:
  created: []
  modified:
    - backend/src/lib/geocodingService.ts
    - backend/src/routes/connect.ts
    - backend/src/routes/essentials.ts
    - backend/src/routes/account.ts

key-decisions:
  - "Remove home_address fire-and-forget write from set-location (Phase 49 privacy constraint: Connected tier does not store home_address at set-location time)"
  - "Jurisdiction write uses try/catch so write failures are logged but never fail the set-location request"
  - "adminRpc import removed from essentials.ts — no longer used after Path 1 conversion to pool.query"
  - "account.ts adminRpc import retained — still used for calculate_level RPC"

patterns-established:
  - "Stored jurisdiction read pattern: pool.query<{...}>(SELECT ... FROM connect.connected_profiles WHERE user_id = $1) with explicit column type"
  - "Jurisdiction guard: if (j && (j.congressional_geo_id || j.state_senate_geo_id)) before populating jurisdictionData"

# Metrics
duration: 20min
completed: 2026-03-26
---

# Phase 49 Plan 02: Stored Jurisdiction Application Layer Summary

**set-location now writes 12 jurisdiction columns once at location-set time; /account/me, PATCH /account/me, /account/me/jurisdiction, and /representatives/me all read from stored columns — eliminating four per-request resolve_user_jurisdiction RPC calls**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-03-26T00:00:00Z
- **Completed:** 2026-03-26T00:20:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- geocodeAddress returns `city` (from Census addressComponents.city), cached and included in return type
- set-location writes all 12 jurisdiction columns (5 GEO IDs + 5 district name fields + jurisdiction_state + jurisdiction_city) to connect.connected_profiles after the resolve_user_jurisdiction RPC call; write is wrapped in try/catch (non-fatal)
- Removed fire-and-forget home_address write from set-location (Phase 49 privacy constraint)
- All three account.ts jurisdiction reads converted from adminRpc to pool.query on stored columns; responses now include _name fields, state, and city
- essentials.ts Path 1 converted to pool.query on stored GEO IDs; X-Formatted-Address now uses stored city/state (falls back to homeAddress)
- adminRpc import removed from essentials.ts

## Task Commits

Each task was committed atomically:

1. **Task 1: Add city to geocodingService + update set-location to write GEO IDs and names** - `ec47b2c` (feat)
2. **Task 2: Update account.ts and essentials.ts to read stored columns** - `4997817` (feat)

**Plan metadata:** (pending)

## Files Created/Modified

- `backend/src/lib/geocodingService.ts` - Return type, cache, and return updated to include `city`
- `backend/src/routes/connect.ts` - set-location: removed home_address write, added 12-column jurisdiction write + state/city in response
- `backend/src/routes/account.ts` - GET /me, PATCH /me, GET /me/jurisdiction: all replaced adminRpc calls with pool.query on stored columns; _name fields, state, and city added to responses
- `backend/src/routes/essentials.ts` - /representatives/me Path 1: replaced adminRpc with pool.query on stored GEO IDs; X-Formatted-Address uses stored city/state; adminRpc import removed

## Decisions Made

- **home_address write removed from set-location.** The fire-and-forget `pool.query` that wrote `matchedAddress` to `home_address` was removed per Phase 49 privacy constraint — Connected tier no longer stores home_address at set-location time. The `home_address` column is only written during enrollment step machine.
- **Jurisdiction write is non-fatal.** The 12-column UPDATE is inside try/catch; a DB error is logged but does not fail the set-location request. This matches the existing pattern for non-critical writes.
- **adminRpc removed from essentials.ts** because the only usage (resolve_user_jurisdiction) was eliminated. account.ts retains adminRpc because calculate_level RPC is still called there.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused `matchedAddress` variable**

- **Found during:** Task 1 (set-location changes)
- **Issue:** After removing the home_address write, `matchedAddress` was declared and assigned but never used — TypeScript strict mode would flag this
- **Fix:** Removed `let matchedAddress: string` declaration and `matchedAddress = coords.matchedAddress` assignment
- **Files modified:** `backend/src/routes/connect.ts`
- **Verification:** `npx tsc --noEmit` passes cleanly
- **Committed in:** `ec47b2c` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — unused variable)
**Impact on plan:** Necessary fix for TypeScript compliance. No scope creep.

## Issues Encountered

None — plan executed cleanly. TypeScript passed after each task.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All four routes now read jurisdiction from stored columns — zero per-request PostGIS RPC calls for jurisdiction data
- Any future phase adding jurisdiction display or filtering can rely on stored columns being populated at set-location time
- Path 2 in /representatives/me (address-based geocoding fallback) is unchanged — still handles users with home_address but no stored GEO IDs

---
*Phase: 49-stored-jurisdiction-cross-app-location-profile*
*Completed: 2026-03-26*
