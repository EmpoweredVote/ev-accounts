---
phase: 53-search-accuracy-bug-fix
plan: "01"
subsystem: api
tags: [go, postgis, geocoding, geofence, st_intersects, google-maps]

# Dependency graph
requires:
  - phase: essentials-phase-c
    provides: geofence_boundaries table with PostGIS geometry columns
provides:
  - Area-intersection search path using ST_Intersects for city/ZIP/county queries
  - geocoding.Result.ResultTypes field exposing Google API top-level result types
  - IsAreaQuery() method for classifying geocoding results as area vs point
  - FindGeoIDsByAreaIntersection for spatial boundary overlap queries
  - ResolveAreaBoundary for mapping geocoding results to boundary geo_id + MTFCC
  - SearchPoliticians handler with area vs point routing
affects:
  - essentials frontend (search results will now include all overlapping districts)
  - future search accuracy improvements

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Area queries use ST_Intersects (boundary overlap); point queries use ST_Covers (point-in-polygon)
    - Google geocoding result types drive area vs point classification
    - ResolveAreaBoundary priority: ZIP geo_id direct lookup → city G4110/G4120 by name → county G4020 by name
    - Fallback chain: area intersection → point-in-polygon if no boundary found in DB

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/geocoding/google.go
    - EV-Backend/internal/essentials/geofence_lookup.go
    - EV-Backend/internal/essentials/handlers.go

key-decisions:
  - "IsAreaQuery() uses a deny-list of point types (street_address, premise, subpremise, route) — anything not explicitly a point type is treated as area, erring toward broader results"
  - "ZIP queries removed from special-case delegation — all queries including ZIPs now flow through geocode → IsAreaQuery → area intersection or point-in-polygon"
  - "ResolveAreaBoundary returns geo_id + MTFCC pair so FindGeoIDsByAreaIntersection can use the exact boundary record"
  - "Old GET /politicians/{zip} endpoint (GetPoliticiansByZip + handleZipLookup) kept unchanged for backward compatibility"
  - "Area intersection falls back to point-in-polygon silently if no boundary found in geofence_boundaries DB"

patterns-established:
  - "Area detection pattern: geocode → check ResultTypes → IsAreaQuery() → route to area or point lookup"
  - "Two-step area intersection: ResolveAreaBoundary finds the queried area boundary, FindGeoIDsByAreaIntersection finds all overlapping district boundaries"

requirements-completed: [SRCH-01]

# Metrics
duration: 2min
completed: 2026-02-28
---

# Phase 53 Plan 01: Search Accuracy Bug Fix — Area Intersection Search

**ST_Intersects area-boundary search path added to backend: city/ZIP/county queries now return all representatives whose districts overlap the queried area, not just those covering the geocoded center point.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-28T23:16:54Z
- **Completed:** 2026-02-28T23:18:54Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Extended `geocoding.Result` struct with `ResultTypes []string` field populated from Google API top-level `types` array, enabling detection of what kind of location was geocoded
- Added `IsAreaQuery()` method on `*Result` that returns true for cities, ZIPs, counties, and any non-point result type — false only for explicit point types (street_address, premise, subpremise, route)
- Added `FindGeoIDsByAreaIntersection` in `geofence_lookup.go`: performs PostGIS `ST_Intersects` join between an area boundary polygon and all district boundaries, returning all overlapping geo_id + MTFCC pairs
- Added `ResolveAreaBoundary` helper that maps a geocoding result to its boundary record in `geofence_boundaries` (ZIP → city G4110/G4120 → county G4020 priority chain)
- Updated `SearchPoliticians` handler with two routing paths: area queries call `ResolveAreaBoundary` then `FindGeoIDsByAreaIntersection`; point queries use unchanged `FindGeoIDsByPoint` (ST_Covers)
- ZIP codes no longer short-circuit to `handleZipLookup` — they geocode normally and get classified as `postal_code` area type, flowing through the area intersection path
- `go build ./...` and `go vet ./...` both pass with no errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend geocoding Result and add area-intersection geofence query** - `7a64404` (feat)
2. **Task 2: Update SearchPoliticians handler with area vs point routing** - `fbba951` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `EV-Backend/internal/essentials/geocoding/google.go` - Added ResultTypes field, Types to geocodeResult, IsAreaQuery() method
- `EV-Backend/internal/essentials/geofence_lookup.go` - Added geocoding import, FindGeoIDsByAreaIntersection, ResolveAreaBoundary
- `EV-Backend/internal/essentials/handlers.go` - Replaced SearchPoliticians body with area/point routing logic

## Decisions Made

- **IsAreaQuery deny-list approach:** Rather than enumerating all area types (locality, postal_code, administrative_area_level_1, etc.), the method denies a small set of known point types and treats everything else as area. This is conservative — erring toward broader results is correct for civic search.
- **ZIP routing change:** Removed early-return ZIP delegation block entirely. ZIP codes feed into the geocoder which returns `postal_code` result type, naturally routing them through area intersection. The old `handleZipLookup` / `GetPoliticiansByZip` GET endpoint is preserved for backward compatibility.
- **ResolveAreaBoundary priority:** ZIP first (geo_id is the ZIP code itself, simplest lookup), then city G4110/G4120 by name/state, then county G4020 by name prefix. Returns geo_id + MTFCC so the intersection query has both boundary dimensions.
- **Silent fallback:** If `ResolveAreaBoundary` finds no matching boundary in DB, the code silently falls back to point-in-polygon — no error returned, just a log line. This prevents regressions for areas not yet imported.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None. All code compiled on first attempt.

## User Setup Required

None — no external service configuration required. The PostGIS `ST_Intersects` function is already available in the database via the existing `geofence_boundaries` table.

## Self-Check: PASSED

All files exist. Task commits 7a64404 and fbba951 verified in EV-Backend git repository (multi-repo workspace — EV-Backend is its own git repo separate from the planning repo).

## Next Phase Readiness

- Area intersection search backend is complete and deployed on next server start
- Effectiveness depends on `geofence_boundaries` table being populated with city/ZIP/county boundary polygons
- If boundaries are present: city name searches (e.g. "Bloomington, IN") will return all city council members, state legislators, and county officials whose districts overlap the city boundary
- If boundaries are absent for a queried area: falls back gracefully to point-in-polygon on the geocoded center point

---
*Phase: 53-search-accuracy-bug-fix*
*Completed: 2026-02-28*
