-- Phase 158 NV TIGER import verification — SELECT only, no writes
-- Run via: psql $DATABASE_URL -f backend/scripts/verify-nv-tiger-import.sql

-- Gate 1: No invalid geometries — MUST return 0
SELECT COUNT(*) AS invalid_geometry_count
FROM essentials.geofence_boundaries
WHERE state = '32' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- Gate 2: No GeometryCollection types — MUST return 0
SELECT COUNT(*) AS geometry_collection_count
FROM essentials.geofence_boundaries
WHERE state = '32'
  AND ST_GeometryType(geometry) NOT IN ('ST_Polygon', 'ST_MultiPolygon');
-- Expected: 0

-- Gate 3: Per-layer row counts (NV-GEO-01)
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '32'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|17, G4110|[DRY-RUN-COUNT], G5200|4, G5210|21, G5220|[DRY-RUN-COUNT]
-- (Update G4110 and G5220 expected counts after dry-run confirms actual values)
-- G4020=17: 16 NV counties + Carson City independent city-county
-- G4110=[DRY-RUN-COUNT]: NV incorporated cities (all G4110 places; ~19 expected)
-- G5200=4: 4 NV congressional districts (post-2022 redistricting)
-- G5210=21: 21 NV State Senate districts (single-member)
-- G5220=[DRY-RUN-COUNT]: NV Assembly districts (~42 expected)

-- Gate 4: Strip-unincorporated invariant (success criterion #1)
-- A Las Vegas Strip coordinate (near the Bellagio) must return Clark County tiers
-- but NO G4110 row — the Strip is unincorporated Clark County, not a city.
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '32'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-115.1728, 36.1147), 4326))
ORDER BY mtfcc;
-- Expected: G4020 row (Clark County, geo_id='32003') + G5200/G5210/G5220 tiers
--           NO G4110 row (the Strip is unincorporated — no incorporated city boundary covers it)

-- Gate 5: districts table casing for Nevada
-- cd119 uses uppercase 'NV' (abbrevUpper); county/sldu/sldl use lowercase 'nv' (abbrev).
SELECT state, district_type, COUNT(*) AS cnt
FROM essentials.districts
WHERE state IN ('NV', 'nv')
GROUP BY state, district_type ORDER BY state, district_type;
-- Expected:
--   nv | COUNTY         | 17
--   nv | STATE_LOWER    | [DRY-RUN-COUNT]  (~42 NV Assembly districts)
--   nv | STATE_UPPER    | 21
--   NV | NATIONAL_LOWER | 4   (cd119 uses abbrevUpper='NV')

-- Gate 6: Clark County sentinel — confirms county layer loaded correctly
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '32' AND mtfcc = 'G4020' AND name LIKE '%Clark County%';
-- Expected: 1 row — geo_id='32003', name='Clark County', mtfcc='G4020'

-- Gate 7: Section-split check — OR-direction (geofence -> districts)
-- MUST return 0 rows (all G5200/G5210/G5220/G4020 geofences must have matching districts row).
-- NOTE: Use OR-direction (geofence_boundaries -> districts) NOT the inverse (districts -> geofence_boundaries).
-- Reason: pre-existing NATIONAL_UPPER rows for NV US Senators (no polygon, no geofence_boundaries row)
-- would produce a false positive under the inverse direction (districts -> geofence_boundaries).
-- The OR-direction query surfaces geofence polygons that are missing a matching districts row.
SELECT gb.geo_id, gb.name, gb.mtfcc
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc IN ('G5200', 'G5210', 'G5220', 'G4020')
  AND gb.state = '32'
  AND gb.geo_id NOT IN (SELECT geo_id FROM essentials.districts)
LIMIT 10;
-- Expected: 0 rows (clean section-split)
