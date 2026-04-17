---
phase: 121-county-council-d1-d4-geofence-repair
plan: 02
subsystem: database
tags: [postgis, geofence, monroe-county, county-council, polygon-import, gis]

# Dependency graph
requires:
  - phase: 121-01
    provides: ground-truth attestation (Kirkwood=D4), diagnosis CSV, evidence directory
provides:
  - fetch-mcc-district-polygons.ts (HTTPS GET + validate + write GeoJSON to evidence/)
  - import-mcc-district-polygons.ts (idempotent INSERT into geofence_boundaries + districts)
  - evidence/mcc-district-polygons.geojson (4-feature FeatureCollection, EPSG:4326)
  - 4 rows in essentials.geofence_boundaries (geo_id 18105-mcc-d1..d4, mtfcc=X-MCC-DIST)
  - 4 rows in essentials.districts (district_id election-mcc-d1..d4)
affects: [121-03, 121-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ArcGIS FeatureServer GeoJSON fetch via Node built-in https.get with redirect follow"
    - "Idempotent PostGIS geometry INSERT: ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($N)), 4326) ON CONFLICT (geo_id, mtfcc) DO NOTHING"
    - "Idempotent districts INSERT: WHERE NOT EXISTS guard keyed on district_id"

key-files:
  created:
    - ev-accounts/backend/scripts/fetch-mcc-district-polygons.ts
    - ev-accounts/backend/scripts/import-mcc-district-polygons.ts
    - .planning/phases/121-county-council-d1-d4-geofence-repair/evidence/mcc-district-polygons.geojson
  modified: []

key-decisions:
  - "MTFCC shortened from X-MCC-DISTRICT (14 chars) to X-MCC-DIST (10 chars) to fit varchar(10) column constraint on essentials.geofence_boundaries.mtfcc"
  - "geo_id values 18105-mcc-d1 through 18105-mcc-d4 are NEW and distinct from pre-existing 1810500001-1810500004 (X0001) rows"
  - "district_id values election-mcc-d1 through election-mcc-d4 did not pre-exist — clean inserts"
  - "Smoke test [121-geo] PASS is expected at Wave 1 end — offices not yet re-linked to new geo_ids"

requirements-completed: [GEO-01]

# Metrics
duration: 45min
completed: 2026-04-17
---

# Phase 121 Plan 02: MCC District Polygon Import — Wave 1 Summary

**Fetch 4 authoritative MCC Council District polygons from Monroe County GIS FeatureServer, persist to disk, and INSERT into essentials.geofence_boundaries + essentials.districts on dev DB with idempotent scripts.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-17T00:00:00Z
- **Completed:** 2026-04-17T00:13:56Z
- **Tasks:** 2
- **Files modified:** 3 created

## Accomplishments

- Created `fetch-mcc-district-polygons.ts`: validates and fetches 4 MCC Council District polygons from `gis.co.monroe.in.us` FeatureServer; supports `--dry-run` flag; writes verbatim GeoJSON to evidence/
- Persisted authoritative GeoJSON at `evidence/mcc-district-polygons.geojson` (4 Polygon features, EPSG:4326)
- Created `import-mcc-district-polygons.ts`: idempotent INSERT of 4 geofence_boundaries rows + 4 districts rows; supports `--check` flag; proves idempotency on re-run
- Executed import against dev DB — 4 new `18105-mcc-d{N}` geofence rows + 4 new `election-mcc-d{N}` district rows confirmed

## FeatureServer Data — What Was Imported

| OBJECTID | CountyCouncil | Council | Rep | geo_id | district_id |
|----------|---------------|---------|-----|--------|-------------|
| 2 | 1 | Council 1 | Peter Iversen | 18105-mcc-d1 | election-mcc-d1 |
| 4 | 2 | Council 2 | Kate Wiltz | 18105-mcc-d2 | election-mcc-d2 |
| 1 | 3 | Council 3 | Marty Hawk | 18105-mcc-d3 | election-mcc-d3 |
| 3 | 4 | Council 4 | Jennifer Crossley | 18105-mcc-d4 | election-mcc-d4 |

All 4 features are `Polygon` geometry type. Coordinates confirmed in Monroe County bbox (lng: -87.0 to -86.0, lat: 39.0 to 39.4). Source: `monroe_county_gis`.

## Dev DB State After Import

```sql
-- geofence_boundaries new rows:
SELECT geo_id, mtfcc, name FROM essentials.geofence_boundaries
WHERE geo_id LIKE '18105-mcc-d%' ORDER BY geo_id;
-- Returns: 18105-mcc-d1, 18105-mcc-d2, 18105-mcc-d3, 18105-mcc-d4 (all mtfcc=X-MCC-DIST)

-- districts new rows:
SELECT district_id, geo_id, district_type FROM essentials.districts
WHERE district_id LIKE 'election-mcc-d%' ORDER BY district_id;
-- Returns: election-mcc-d1, election-mcc-d2, election-mcc-d3, election-mcc-d4

-- County-wide row untouched:
SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '18105' AND mtfcc = 'G4020';
-- Returns: 1 row (intact)
```

## Smoke Test Status (Expected at Wave 1)

The `[121-geo]` assertion returns **PASS** (kirkwood_mcc_count=1). This is expected behavior at the end of Wave 1:

- The pre-existing `1810500004` polygon (mtfcc=X0001, source=monroe_county_arcgis_council_districts_2022) still covers Kirkwood and correctly returns D4 via the offices→districts join
- The NEW `18105-mcc-d{N}` rows (mtfcc=X-MCC-DIST) are in geofence_boundaries but offices/districts are not yet re-linked to them
- Wave 2 (Plan 03) will re-link the 4 MCC offices to the new `election-mcc-d{N}` district rows

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fetch 4 MCC district polygons from Monroe County GIS FeatureServer | `218cad5` | fetch-mcc-district-polygons.ts, evidence/mcc-district-polygons.geojson |
| 2 | Create idempotent import script + run against dev DB | `fef1fcc` | import-mcc-district-polygons.ts |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] MTFCC value shortened from X-MCC-DISTRICT to X-MCC-DIST**
- **Found during:** Task 2 first import run
- **Issue:** `essentials.geofence_boundaries.mtfcc` is `varchar(10)`. The plan specified `X-MCC-DISTRICT` (14 chars) which exceeds the column limit, causing all 4 inserts to fail with "value too long for type character varying(10)"
- **Fix:** Changed MTFCC constant to `X-MCC-DIST` (exactly 10 chars). Still starts with `X` — matches the `LIKE 'X%'` pattern in `essentialsService.ts` line 574. Both tables use the same value (mtfcc_match=true)
- **Files modified:** `import-mcc-district-polygons.ts` (MTFCC constant + docstring)
- **Commit:** `fef1fcc`

**2. [Rule 1 - Bug] Output path had extra `..` segment in fetch script**
- **Found during:** Task 1 live run
- **Issue:** First version of `fetch-mcc-district-polygons.ts` used 4 `..` segments from `scripts/` directory to reach repo root, landing at the parent worktrees directory instead of the worktree root
- **Fix:** Corrected to 3 `..` segments (`scripts/ -> backend/ -> ev-accounts/ -> repo root`)
- **Files modified:** `fetch-mcc-district-polygons.ts` (EVIDENCE_DIR path.resolve call)
- **Commit:** `218cad5` (fixed before commit)

## Pre-existing DB Context (from Plan 01 Diagnosis)

The dev DB already had:
- `geo_id` values `1810500001`-`1810500004` with `mtfcc='X0001'` from a prior import (source: `monroe_county_arcgis_council_districts_2022`)
- These pre-existing rows caused the smoke test to already PASS before Wave 1

The new Wave 1 rows use different `geo_id` values (`18105-mcc-d{N}`) and a different `mtfcc` (`X-MCC-DIST`), so there is no conflict. Both sets of rows now coexist. Plan 03 (office re-linking) must wire to the NEW `election-mcc-d{N}` district rows.

## Issues Encountered

None beyond the two auto-fixed bugs above.

## User Setup Required

None — dev DB writes executed directly.

## Next Phase Readiness

- Wave 1 complete: 4 new geofence_boundaries rows + 4 new districts rows on dev DB
- Plan 03 (Wave 2) re-links the 4 MCC offices to `district_id='election-mcc-d{N}'` rows
- Plan 04 verifies on production after Render deploy

---
*Phase: 121-county-council-d1-d4-geofence-repair*
*Completed: 2026-04-17*

## Self-Check: PASSED

### Files verified:
- `ev-accounts/backend/scripts/fetch-mcc-district-polygons.ts` — FOUND
- `ev-accounts/backend/scripts/import-mcc-district-polygons.ts` — FOUND
- `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/mcc-district-polygons.geojson` — FOUND
- `.planning/phases/121-county-council-d1-d4-geofence-repair/121-02-SUMMARY.md` — FOUND

### Commits verified:
- `218cad5` feat(121-02): fetch 4 MCC district polygons from Monroe County GIS FeatureServer — FOUND
- `fef1fcc` feat(121-02): create idempotent MCC district polygon import script + run against dev DB — FOUND

### Acceptance criteria verified:
- FeatureServer URL present in fetch script — PASS
- outSR=4326 parameter present — PASS
- ON CONFLICT (geo_id, mtfcc) DO NOTHING in import script — PASS
- WHERE NOT EXISTS guard in import script — PASS
- ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON)) pattern — PASS
- 18105-mcc-d geo_id pattern — PASS
- election-mcc-d district_id pattern — PASS
- source='monroe_county_gis' — PASS
- final_boundary_count=4 (--check) — PASS
- final_district_count=4 (--check) — PASS
- Idempotency proven (re-run: inserted_boundary=0, inserted_district=0) — PASS
- County-wide geo_id=18105/G4020 row intact — PASS
- [121-geo] smoke test PASS (expected at Wave 1) — PASS
