---
phase: 26-geofence-only-search
plan: 01
subsystem: api
tags: [go, geocoding, geofence, cors, http-headers, ballotready, google-maps]

# Dependency graph
requires:
  - phase: 25-phase-c-caching
    provides: geofence lookup infrastructure (FindGeoIDsByPoint, FindPoliticiansByGeoMatches, fetchFederalAndStateFromDB)
provides:
  - Address search path that never calls BallotReady API
  - No-geofence fallback returning federal + state officials from DB cache
  - X-Formatted-Address header on all successful address search responses
  - X-Data-Status: no-geofence-data header for coverage gap signaling
  - Relaxed geocoder accepting city/state addresses without ZIP codes
affects: [27-candidates-phase, 28-frontend-address-input, 29-production-deploy]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Nil service guard pattern: check GeoClient == nil at handler entry, return 503"
    - "Geocode error discrimination: check error message for 'could not determine US state' to return 422 vs 400"
    - "No-geofence fallback: fetchFederalAndStateFromDB(state) when geofence coverage is absent"
    - "CORS header exposure: custom X-* headers must be listed in Access-Control-Expose-Headers"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/geocoding/google.go
    - EV-Backend/internal/essentials/handlers.go
    - EV-Backend/internal/middleware/middleware.go

key-decisions:
  - "Use fetchFederalAndStateFromDB (not fetchStatewideFromDB) in no-geofence path to include NATIONAL_LOWER and STATE_UPPER/STATE_LOWER representatives"
  - "Geocode failure for international addresses (empty State) returns 422 Unprocessable Entity, not 400"
  - "Nil GeoClient returns 503 Service Unavailable — no BallotReady escape hatch remains"
  - "ZIP delegation to handleZipLookup preserved inside SearchPoliticians until Phase 28"

patterns-established:
  - "Pattern 1: Geocoder only requires coordinates + state (ZIP is metadata, not a requirement)"
  - "Pattern 2: No-geofence path uses geoResult.State from geocoder for state resolution (not ZIP prefix table)"

requirements-completed: [BR-01, BR-02]

# Metrics
duration: 3min
completed: 2026-02-22
---

# Phase 26 Plan 01: Geofence-Only Search Summary

**BallotReady address fallback deleted; geofence + DB-cache fallback with X-Formatted-Address header now covers all valid US addresses**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-22T20:46:36Z
- **Completed:** 2026-02-22T20:49:25Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Removed BallotReady API dependency from the address search path entirely
- Added federal + state cache fallback when geofence has no local coverage
- X-Formatted-Address and X-Geofence-Count headers now exposed via CORS for browser JavaScript access
- Geocoder relaxed to accept city/state addresses (no ZIP required)

## Task Commits

Each task was committed atomically:

1. **Task 1: Relax geocoder ZIP guard and add CORS header exposure** - `74855a7` (feat)
2. **Task 2: Restructure SearchPoliticians — delete BallotReady fallback, implement no-geofence path** - `d57371d` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `EV-Backend/internal/essentials/geocoding/google.go` - Replaced ZIP guard with coordinate + state validation; ZIP now optional metadata
- `EV-Backend/internal/essentials/handlers.go` - Restructured SearchPoliticians: nil GeoClient guard, geocode error handling, no-geofence fallback path, X-Formatted-Address on both response paths
- `EV-Backend/internal/middleware/middleware.go` - Added X-Formatted-Address and X-Geofence-Count to CORS Access-Control-Expose-Headers

## Decisions Made
- Used `fetchFederalAndStateFromDB` (not `fetchStatewideFromDB`) in the no-geofence path to ensure users see their US Representatives (NATIONAL_LOWER) and state legislators (STATE_UPPER/STATE_LOWER) when local geofence data is unavailable
- International addresses (geocoder returns empty State) return 422 Unprocessable Entity with "Address must be within the United States"
- Nil GeoClient returns 503 Service Unavailable — there is no longer any BallotReady escape hatch for address searches

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- EV-Backend has its own git repository separate from the workspace root — commits made inside EV-Backend/.git, not the workspace .planning repo.

## User Setup Required
None - no external service configuration required. GOOGLE_MAPS_API_KEY must remain set for address search to function (existing requirement).

## Next Phase Readiness
- Phase 27 (candidates): Backend is ready; fetchCandidatesFromDB join path from election_records to zip_politicians needs schema inspection before writing SQL (pre-existing concern from STATE.md)
- Phase 28 (frontend): Backend now exposes X-Formatted-Address header; frontend Dashboard can read it to display "Showing results for [address]". Local empty-state message condition should check dataStatus === "no-geofence-data"
- All verification criteria from the plan pass: build clean, no BallotReady in SearchPoliticians, correct headers on both paths, correct HTTP status codes

---
*Phase: 26-geofence-only-search*
*Completed: 2026-02-22*
