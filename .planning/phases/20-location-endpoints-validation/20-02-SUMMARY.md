---
phase: 20-location-endpoints-validation
plan: "02"
subsystem: api
tags: [express, geocoding, postgis, typescript, location, jurisdiction]

# Dependency graph
requires:
  - phase: 20-01
    provides: geocodeAddress() and GeocodingError exports from geocodingService.ts
  - phase: 19-location-schema-rpcs
    provides: upsert_user_location and resolve_user_jurisdiction RPCs in connect schema

provides:
  - POST /api/connect/set-location HTTP endpoint
  - PO Box rejection before geocoding (422 PO_BOX_REJECTED)
  - Coverage bounding box filter for Indiana and LA County (422 OUT_OF_COVERAGE)
  - Full pipeline: address -> geocode -> coverage check -> upsert_user_location RPC -> resolve_user_jurisdiction RPC -> jurisdiction JSON response

affects:
  - 20-03 (location consent endpoint relies on location_consent column set by upsert_user_location)
  - 20-04 (validation plan tests this endpoint end-to-end)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Coverage bounding box as fast client-side pre-filter before PostGIS RPC"
    - "requireConnected middleware blocks Inform-tier users (403 Forbidden)"
    - "Raw lat/lng consumed immediately by adminRpc — never logged or serialized"
    - "GeocodingError code dispatch: PO_BOX_REJECTED / ADDRESS_NOT_FOUND / LOW_CONFIDENCE mapped to 422"

key-files:
  created: []
  modified:
    - backend/src/routes/connect.ts

key-decisions:
  - "isInCoverage() bounding box in connect.ts (not geocodingService) — keeps the geocoding service generic; coverage policy belongs in the route layer"
  - "OUT_OF_COVERAGE returns 422 not 403 — address is syntactically valid but outside service area; 422 aligns with the other location validation errors"

patterns-established:
  - "Coverage bounding box: check AFTER geocoding succeeds, BEFORE calling RPC"
  - "Jurisdiction response shape: { location_consent: true, jurisdiction: { congressional_district, state_senate_district, state_house_district, county, school_district } }"

# Metrics
duration: 8min
completed: 2026-03-13
---

# Phase 20 Plan 02: Set-Location Route Summary

**POST /api/connect/set-location wired end-to-end: PO Box guard, Google geocoding, Indiana/LA County bounding box, upsert_user_location encryption RPC, resolve_user_jurisdiction PostGIS RPC, jurisdiction JSON response — raw coordinates never leave the function**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-13T00:35:29Z
- **Completed:** 2026-03-13T00:43:00Z
- **Tasks:** 2 (1 implementation + 1 verification)
- **Files modified:** 1

## Accomplishments

- POST /api/connect/set-location in connect.ts with requireAuth + requireConnected middleware
- Complete validation pipeline: PO Box rejected before network call, geocoding, bounding box coverage filter, encryption via RPC, jurisdiction resolution via PostGIS RPC
- TypeScript strict compilation passes (0 errors)
- Raw lat/lng never appear in response body or console output

## Task Commits

Each task was committed atomically:

1. **Task 1: POST /api/connect/set-location route handler** - `8809eb5` (feat)
2. **Task 2: Verify connect router mounting in index.ts** - no commit needed (index.ts already mounts connectRouter at /api/connect; no change required)

**Plan metadata:** (docs commit to follow)

## Files Created/Modified

- `backend/src/routes/connect.ts` - Added imports (requireConnected, geocodeAddress, GeocodingError), setLocationBodySchema, isInCoverage() helper, and full POST /set-location route handler (112 lines added)

## Decisions Made

- **isInCoverage() lives in connect.ts, not geocodingService.ts** — coverage policy is route-layer concern; geocodingService stays generic and reusable
- **OUT_OF_COVERAGE is 422, not 403** — address is valid input but outside service area; consistent with other location validation error codes in this endpoint

## Deviations from Plan

None - plan executed exactly as written.

(Note: TSC initially appeared to error with `SelectQueryError` on `location_consent`, but re-running tsc showed 0 errors — the types file already contained `location_consent: boolean | null` and the apparent failure was a stale compilation artifact.)

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. GOOGLE_MAPS_API_KEY was provisioned in Plan 01.

## Next Phase Readiness

- POST /api/connect/set-location is live and compilable
- Plan 03 (GET /api/connect/location and PATCH location_consent) can proceed immediately — the upsert_user_location RPC sets location_consent = true on write
- Plan 04 (end-to-end validation) depends on Plans 01-03 all being complete

---
*Phase: 20-location-endpoints-validation*
*Completed: 2026-03-13*
