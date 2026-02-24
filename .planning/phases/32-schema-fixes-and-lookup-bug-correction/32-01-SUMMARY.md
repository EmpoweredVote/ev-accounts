---
phase: 32-schema-fixes-and-lookup-bug-correction
plan: 01
subsystem: database
tags: [postgis, geofence, spatial-index, mtfcc, go]

# Dependency graph
requires:
  - phase: 31-geofence-lookup
    provides: geofence_boundaries table, FindGeoIDsByPoint, mtfccToDistrictTypes map, X0001 entry
provides:
  - Composite unique index (geo_id, mtfcc) on geofence_boundaries preventing duplicate rows
  - Dedup guard that cleans existing duplicates before index creation
  - ST_Covers spatial predicate replacing ST_Contains for boundary-coincident address matching
  - Complete MTFCC map with 11 entries including G4120, G5400, G5410
affects:
  - 34-tiger-geofence-import
  - 35-arcgis-geofence-import
  - 36-la-county-politicians

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dedup before unique index: run DELETE ... WHERE id NOT IN (DISTINCT ON ...) before CREATE UNIQUE INDEX to prevent constraint creation failures on dirty data"
    - "id DESC for dedup ordering: use id (not timestamps) as tiebreaker to avoid NULL issues with imported_at columns"
    - "log.Printf for schema warnings: dedup steps that may fail on fresh databases use Printf not Fatal"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/setup.go
    - EV-Backend/internal/essentials/geofence_lookup.go

key-decisions:
  - "Use id DESC (not imported_at DESC) for dedup row selection — imported_at may be NULL for pre-existing rows"
  - "Dedup uses log.Printf not log.Fatal — table may not exist on fresh database, that is normal and not an error"
  - "ST_Covers chosen over ST_Contains — both have identical argument order, Covers returns TRUE for boundary-coincident points while Contains returns FALSE"
  - "G4120 maps to LOCAL/LOCAL_EXEC (same as G4110) — consolidated cities use identical BallotReady district types as incorporated places"
  - "G5400/G5410 map to SCHOOL — elementary and secondary school districts use same district type as unified (G5420)"

patterns-established:
  - "Composite unique index pattern: dedup guard -> CREATE UNIQUE INDEX IF NOT EXISTS in setup.go Init()"
  - "MTFCC expansion pattern: add new entries to mtfccToDistrictTypes with matching BallotReady district type strings"

requirements-completed: [SCHEMA-01, SCHEMA-02, SCHEMA-03]

# Metrics
duration: 1min
completed: 2026-02-24
---

# Phase 32 Plan 01: Schema Fixes and Lookup Bug Correction Summary

**Composite unique index on geofence_boundaries (geo_id, mtfcc), ST_Covers boundary fix, and 3 missing MTFCC codes (G4120/G5400/G5410) added to district type map**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-02-24T01:12:41Z
- **Completed:** 2026-02-24T01:13:44Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Dedup guard + composite unique index on (geo_id, mtfcc) prevents silent duplicate row creation when importing multiple MTFCC layers (SCHEMA-01)
- ST_Covers replaces ST_Contains so boundary-coincident addresses return matches instead of empty results (SCHEMA-02)
- MTFCC map expanded from 8 to 11 entries: G4120 (Consolidated City), G5400 (Elementary School District), G5410 (Secondary School District) all map correctly without falling through to catch-all (SCHEMA-03)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add dedup cleanup and composite unique index to setup.go** - `9e671fd` (feat)
2. **Task 2: Fix ST_Contains to ST_Covers and expand mtfccToDistrictTypes map** - `bb1a79b` (fix)

## Files Created/Modified

- `EV-Backend/internal/essentials/setup.go` - Added dedup DELETE block and CREATE UNIQUE INDEX IF NOT EXISTS idx_geofence_boundaries_geo_id_mtfcc
- `EV-Backend/internal/essentials/geofence_lookup.go` - ST_Covers replaces ST_Contains; added G4120, G5400, G5410 to mtfccToDistrictTypes

## Decisions Made

- Used `id DESC` ordering in dedup query (not `imported_at DESC`) because `imported_at` may be NULL for rows inserted before the column existed
- Dedup error uses `log.Printf` warning (not `log.Fatal`) because on a fresh database the table may not exist yet — this is expected behavior
- ST_Covers is a strict drop-in replacement for ST_Contains with identical argument order; no other query changes needed
- G4120 gets the same `{"LOCAL", "LOCAL_EXEC"}` mapping as G4110 — consolidated cities function identically to incorporated places in BallotReady's classification
- G5400 and G5410 get `{"SCHOOL"}` matching G5420 — all school district variants use the same BallotReady district type

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Both files compiled cleanly. All 7 verification checks passed:
- `go build` succeeds with zero errors
- `grep -c "ST_Contains"` returns 0
- `grep -c "ST_Covers"` returns 1
- `grep "idx_geofence_boundaries_geo_id_mtfcc"` returns a match
- G4120, G5400, G5410 each return count 1

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- geofence_boundaries table is now safe for multi-layer MTFCC imports (Phases 34-35)
- ON CONFLICT (geo_id, mtfcc) DO UPDATE idiom is unblocked for import scripts
- All TIGER Census MTFCC codes relevant to LA County (G4110, G4120, G4020, G5200, G5210, G5220, G5400, G5410, G5420) map correctly to BallotReady district types
- Phase 33 (import utilities) can proceed in parallel — no dependency on this plan's output

---
*Phase: 32-schema-fixes-and-lookup-bug-correction*
*Completed: 2026-02-24*
