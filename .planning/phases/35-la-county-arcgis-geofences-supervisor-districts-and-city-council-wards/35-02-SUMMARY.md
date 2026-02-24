---
phase: 35-la-county-arcgis-geofences-supervisor-districts-and-city-council-wards
plan: 02
subsystem: database
tags: [postgis, geopandas, arcgis, geofences, python, la-county]

# Dependency graph
requires:
  - phase: 35-01
    provides: arcgis_sources.json config with TBD entries, import_arcgis_geofences.py script infrastructure
  - phase: 34-tiger-geofences-federal-state-school-city
    provides: geofence_boundaries table, G4110 CA place boundaries

provides:
  - 9 Long Beach city council ward polygons (X0001, OCD-ID geo_ids)
  - 7 Pasadena city council ward polygons (X0001, OCD-ID geo_ids)
  - 6 Torrance city council ward polygons (X0001, OCD-ID geo_ids)
  - 4 Inglewood city council ward polygons (X0001, OCD-ID geo_ids, dissolved duplicate)
  - 5 West Covina city council ward polygons (X0001, OCD-ID geo_ids)
  - Complete arcgis_sources.json with resolved URLs for 5 cities and 5 documented gaps
  - Updated import script handling "District N" string fields and duplicate geo_id dissolve
  - Total: 51 X0001 CA records (5 supervisor + 15 LA City + 31 other cities), all ST_IsValid
affects:
  - 36 (district geo_id updates — geofences for Long Beach/Pasadena/Torrance/Inglewood/West Covina ready)
  - Phase 36/37 gap resolution (Santa Clarita, Downey, El Monte, Palmdale, Pomona documented)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ArcGIS URL discovery via ArcGIS Online sharing REST API search endpoint
    - "District N" string field parsing via regex with district_field_format config key
    - unary_union dissolve for duplicate geo_id features in same source (Inglewood pattern)
    - Gap documentation in config gaps array with db_districts and investigation_notes

key-files:
  created: []
  modified:
    - EV-Backend/scripts/arcgis_sources.json
    - EV-Backend/scripts/import_arcgis_geofences.py

key-decisions:
  - "Long Beach council districts sourced from ArcGIS item c21dc4adc0d344c49a3298e3bc4adeb3 via services6.arcgis.com/yCArG7wGXGyWLqav — COUNCIL_NUMBER field (integer)"
  - "Torrance and West Covina use district_field_format='District {n}' config key — DISTRICTID/DISTRICT fields contain string like 'District 6', not numeric"
  - "Inglewood duplicate CD=2 handled via unary_union dissolve, quality_flag=geometry_dissolved — source elsa79 publishes 5 features for 4 districts"
  - "7 unmatched geofence geo_ids (Long Beach D8, Pasadena D1/D5, Torrance D3/D5, West Covina D1/D3) have no current BallotReady politician records — geometry correctly imported, awaiting Phase 37 politician sync"
  - "5 cities documented as gaps in config: Santa Clarita, Downey, El Monte, Palmdale, Pomona — no ArcGIS FeatureServer URL found after investigation"

patterns-established:
  - "ArcGIS URL discovery: use ArcGIS Online sharing REST search API (arcgis.com/sharing/rest/search?q=...&f=json) — returns Feature Service items with direct URL"
  - "String district fields: add district_field_format='District {n}' key to config; import script parses number via regex"
  - "Duplicate geometry dissolve: unary_union on features with same geo_id; quality_flag=geometry_dissolved"

requirements-completed: [GEO-08]

# Metrics
duration: 8min
completed: 2026-02-24
---

# Phase 35 Plan 02: City Council Ward Boundaries for LA County Cities Summary

**31 city council ward boundaries imported for 5 LA County cities (Long Beach, Pasadena, Torrance, Inglewood, West Covina) via resolved ArcGIS FeatureServer URLs, with 5 cities documented as gaps; Phase 35 complete with 51 total X0001 CA geofences, all passing ST_IsValid**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-24T16:40:03Z
- **Completed:** 2026-02-24T16:47:48Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- GEO-08 satisfied: city council district boundaries imported for all LA County cities where ArcGIS data is available (5 cities, 31 wards)
- ArcGIS URL resolution: discovered working FeatureServer endpoints for Long Beach, Pasadena, Torrance, Inglewood, West Covina using ArcGIS Online sharing REST search API
- Gap documentation: Santa Clarita, Downey, El Monte, Palmdale, Pomona documented with specific reasons and DB district lists for future resolution
- Phase 35 complete: 51 total X0001 CA records (5 supervisor + 15 LA City + 31 other cities); all passing ST_IsValid; point-in-polygon tests confirm correct spatial coverage
- Import script enhanced: handles "District N" string fields and unary_union dissolve for duplicate geo_ids

## Task Commits

1. **Task 1: Discover ArcGIS URLs and import city council ward boundaries** - `b33504c` (feat) — EV-Backend repo
2. **Task 2: Verify GEO-08 and full Phase 35 coverage** — verification-only, no file changes

## Files Created/Modified

- `EV-Backend/scripts/arcgis_sources.json` - Completed config: 8 city_council entries (5 resolved, 1 at-large, 2 null), 5 gaps documented
- `EV-Backend/scripts/import_arcgis_geofences.py` - Enhanced: parse_district_number() for "District N" fields, unary_union dissolve for duplicate geo_ids, updated verify_import() with Long Beach and East LA point-in-polygon tests

## Decisions Made

- **Long Beach URL:** `services6.arcgis.com/yCArG7wGXGyWLqav` — discovered via ArcGIS Online item metadata API for Hub item `c21dc4adc0d344c49a3298e3bc4adeb3`. COUNCIL_NUMBER field (integer 1-9).
- **Torrance URL:** `services1.arcgis.com/38fAqAZVRCrVtPUU/arcgis/rest/services/City_Council_Districts/FeatureServer/0` — official TorranceCA_GIS owner. DISTRICTID field is "District N" string format; added `district_field_format` config key.
- **Pasadena URL:** `services2.arcgis.com/zNjnZafDYCAJAbN0/arcgis/rest/services/City_Council_Districts_view/FeatureServer/0` — official CityOfPasadenaCAGIS owner, "view" service is current boundaries. DISTRICT field (integer 1-7).
- **West Covina URL:** `services8.arcgis.com/WV8ogNubjFL2BKPt/arcgis/rest/services/Council_Districts/FeatureServer/2` — official TVictoria_westcovina owner. Layer ID 2 (not 0). DISTRICT field is "District N" string.
- **Inglewood URL:** `services.arcgis.com/YkFgoL8JnWkLrVRi/arcgis/rest/services/CityofInglewoodCDAreas_Aug2025/FeatureServer/0` — owner elsa79 (city GIS staff, Aug 2025 dataset). CD field (integer 1-4), but 5 features (CD=2 duplicated as two polygons — dissolved via unary_union).
- **Inglewood duplicate dissolve:** Service has OBJECTID=1 (area ~1.1M m2 = ~1.1 km2) and OBJECTID=5 (area ~42M m2 = ~42 km2) both with CD=2. Merged via unary_union, quality_flag=geometry_dissolved. This may represent an enclave or data artifact; geometry is usable for point-in-polygon.
- **7 unmatched geofence geo_ids:** Long Beach D8, Pasadena D1/D5, Torrance D3/D5, West Covina D1/D3 have imported polygon boundaries but no matching `essentials.districts` records. These are valid geofences — the politician records are simply not in the DB yet (BallotReady may not have current officeholders for those seats). Phase 37 politician warm will populate them.
- **Gap cities:** Santa Clarita, Downey, El Monte, Palmdale, Pomona — no ArcGIS council district FeatureServices found after systematic search. El Monte DB records have malformed OCD-IDs (`state:nv/place:elmonte` instead of `state:ca/place:el_monte`), likely a BallotReady data issue.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed import script to handle "District N" string district fields**
- **Found during:** Task 1 (URL discovery for Torrance and West Covina)
- **Issue:** Both Torrance DISTRICTID and West Covina DISTRICT fields contain strings like "District 6" — the existing `int(district_num)` conversion would throw ValueError. These cities are in the config, so import would fail.
- **Fix:** Added `parse_district_number(value, district_field_format)` function with regex parsing. Added `district_field_format` key to config for affected cities. Existing numeric fields work unchanged.
- **Files modified:** EV-Backend/scripts/import_arcgis_geofences.py, EV-Backend/scripts/arcgis_sources.json
- **Verification:** Torrance imported 6 features, West Covina imported 5 features — all correct district numbers
- **Committed in:** b33504c (Task 1 commit)

**2. [Rule 1 - Bug] Added unary_union dissolve for duplicate geo_id features (Inglewood)**
- **Found during:** Task 1 (Inglewood URL verification)
- **Issue:** Inglewood source has CD=2 appearing in 5 features for 4 districts. Without dissolve, two records with identical geo_id would cause unique constraint violation on `(geo_id, mtfcc)`.
- **Fix:** Added dissolve step in `build_geodataframe()` — groups rows by geo_id, merges duplicate geometries via `unary_union`, sets quality_flag='geometry_dissolved'.
- **Files modified:** EV-Backend/scripts/import_arcgis_geofences.py
- **Verification:** Inglewood imported 4 features (not 5), quality_flag=geometry_dissolved on 1 record
- **Committed in:** b33504c (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs — import would fail without fixes)
**Impact on plan:** Both fixes necessary for correctness. No scope creep.

## Issues Encountered

- EV-Backend is a separate git repo from the workspace `.planning/` git repo. Per-task commits were made to the EV-Backend git repo at `/Users/chrisandrews/Documents/GitHub/EV-Backend`.
- West Covina service layer is at layer ID 2 (not 0) — the standard `/FeatureServer/0` pattern returns 404. Discovered by inspecting `/FeatureServer?f=json` to list layers.
- Torrance has two services: `Council_Districts/FeatureServer` (has layer ID 4 named CityCouncil) and `City_Council_Districts/FeatureServer` (has layer ID 0). Used the latter as it's more clearly named and has current data.

## Verification Results

**GEO-08 (Other City Council Districts):**
- Total CA X0001 records: 51 [PASS - expected ≥ 20]
- Invalid geometries: 0/51 [PASS]
- No TBD entries in config [PASS]
- Config: 8 city_council entries, 5 documented gaps [PASS]

**Point-in-polygon spot checks:**
- LA City Hall: supervisor (District 1) + council ward (District 14) [PASS]
- Long Beach City Hall: supervisor (District 4) + Long Beach council (District 1) [PASS]
- East LA unincorporated: supervisor (District 1), no city ward [PASS]

**geo_id join coverage:**
- 44/51 X0001 CA records join to essentials.districts.ocd_id [PASS for supervisor+LA City guarantee]
- 7 unmatched = geofences with no current BallotReady politician records (normal — Phase 37 will add politicians)
- 39/52 district records (CA LOCAL council districts) have X0001 geofences; 13 are in gap cities

**Full hierarchy at LA City Hall:**
- G4020 (county), G4040 (metro), G4110 (place), G5200-5220 (federal/state legislative), G5420 (school), X0001 (supervisor + council ward) — all present [PASS]

## Next Phase Readiness

- Phase 36 (district geo_id updates): geofences ready for all 5 imported cities + LA City + supervisors. UPDATE essentials.districts SET geo_id = ocd_id will enable point-in-polygon → politician lookup chain.
- Gap cities (Santa Clarita, Downey, El Monte, Palmdale, Pomona): documented in arcgis_sources.json gaps array with BallotReady OCD-IDs — future resolution can add source_url and run import script
- El Monte: BallotReady may have malformed OCD-IDs (state:nv instead of state:ca) — worth investigation during Phase 37 politician sync

---
*Phase: 35-la-county-arcgis-geofences-supervisor-districts-and-city-council-wards*
*Completed: 2026-02-24*

## Self-Check: PASSED

- FOUND: .planning/phases/35-la-county-arcgis-geofences-supervisor-districts-and-city-council-wards/35-02-SUMMARY.md
- FOUND: EV-Backend/scripts/arcgis_sources.json
- FOUND: EV-Backend/scripts/import_arcgis_geofences.py
- FOUND: commit b33504c in EV-Backend repo
