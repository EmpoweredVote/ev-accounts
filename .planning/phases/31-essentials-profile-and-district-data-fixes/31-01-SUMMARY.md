---
phase: 31-essentials-profile-and-district-data-fixes
plan: 01
subsystem: api
tags: [go, gorm, postgresql, geofence, essentials]

# Dependency graph
requires:
  - phase: 26-geofence-only-search
    provides: FindPoliticiansByGeoMatches and geofence_lookup.go with mtfccToDistrictTypes map
  - phase: 27-cache-only-candidates-warmer-cleanup
    provides: fetchOfficialsFromDB, fetchFederalAndStateFromDBFiltered, GetPoliticianByID query functions
provides:
  - district_id field in all 4 API query paths (ZIP, address/geofence, federal+state, single politician)
  - X0001 MTFCC code mapped to LOCAL district type in geofence lookup
affects: essentials-frontend, profile-page-subtitles, geofence-bloomington-council-districts

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Use COALESCE(d.district_id, '') AS district_id_text alias to avoid ambiguity with o.district_id UUID FK"
    - "Row struct field DistrictIDText maps to SQL column alias district_id_text via GORM column name mapping"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/handlers.go
    - EV-Backend/internal/essentials/geofence_lookup.go

key-decisions:
  - "Use district_id_text column alias (not district_id) in all SELECTs to avoid ambiguity with offices.district_id UUID FK"
  - "X0001 MTFCC added to mtfccToDistrictTypes as LOCAL — BallotReady custom code for city council sub-district ward boundaries"

patterns-established:
  - "district_id_text alias pattern: always alias d.district_id as district_id_text when offices table is also joined (to avoid UUID FK collision)"

requirements-completed: [DIST-02, CARD-01, PROF-01]

# Metrics
duration: 2min
completed: 2026-02-23
---

# Phase 31 Plan 01: Essentials Profile and District Data Fixes Summary

**district_id field added to all 4 politician API query paths and X0001 MTFCC mapped to LOCAL for Bloomington council district geofence matching**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-23T03:38:30Z
- **Completed:** 2026-02-23T03:40:30Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `district_id` (e.g., "1", "40", "At Large") to `OfficialOut` struct with `json:"district_id,omitempty"` for backward compatibility
- Extended all 4 query functions to SELECT `COALESCE(d.district_id, '') AS district_id_text` using alias to avoid collision with `offices.district_id` UUID FK
- Added X0001 MTFCC to `mtfccToDistrictTypes` map mapped to LOCAL, enabling Bloomington city council ward boundaries (imported as BallotReady custom geofences) to resolve to LOCAL politicians

## Task Commits

Each task was committed atomically:

1. **Task 1: Add district_id to OfficialOut and all query paths** - `3b8a574` (feat)
2. **Task 2: Add X0001 MTFCC mapping to geofence lookup** - `d32a463` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `EV-Backend/internal/essentials/handlers.go` - Added DistrictID to OfficialOut; added DistrictIDText to row structs and COALESCE(d.district_id) AS district_id_text to SELECTs in fetchOfficialsFromDB, fetchFederalAndStateFromDBFiltered, and GetPoliticianByID; added DistrictID to all assembly loops
- `EV-Backend/internal/essentials/geofence_lookup.go` - Added district_id_text to SELECT and &off.DistrictID to Scan in FindPoliticiansByGeoMatches; added X0001 entry to mtfccToDistrictTypes map

## Decisions Made
- Used `district_id_text` as the SQL column alias (not `district_id`) because the `offices` table has a `district_id` UUID FK column — using `d.district_id` directly would cause GORM to map to the wrong struct field. The alias makes the intent explicit and avoids ambiguity.
- X0001 maps to `{"LOCAL"}` (not LOCAL_EXEC) because city council sub-districts represent ward-level council seats, not executive positions.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. All SQL aliases applied cleanly, build succeeded on first attempt.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Backend now serves `district_id` in all API responses; frontend can use this to construct "Chamber, District N" subtitles on politician cards and profiles
- X0001 geofence boundaries will correctly resolve to LOCAL politicians when Bloomington council district polygons are present in `geofence_boundaries` table
- No blockers for next plan in Phase 31

---
*Phase: 31-essentials-profile-and-district-data-fixes*
*Completed: 2026-02-23*

## Self-Check: PASSED

- SUMMARY.md at `.planning/phases/31-essentials-profile-and-district-data-fixes/31-01-SUMMARY.md`: FOUND
- Commit 3b8a574 (Task 1: district_id to all API paths): FOUND
- Commit d32a463 (Task 2: X0001 MTFCC mapping): FOUND
