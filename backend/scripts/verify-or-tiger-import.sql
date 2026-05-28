-- Phase 72 OR TIGER import verification — SELECT only, no writes
-- Run via: psql $DATABASE_URL -f backend/scripts/verify-or-tiger-import.sql

-- Gate 1: No invalid geometries — MUST return 0
SELECT COUNT(*) AS invalid_geometry_count
FROM essentials.geofence_boundaries
WHERE state = '41' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- Gate 2: No GeometryCollection types — MUST return 0
SELECT COUNT(*) AS geometry_collection_count
FROM essentials.geofence_boundaries
WHERE state = '41'
  AND ST_GeometryType(geometry) NOT IN ('ST_Polygon', 'ST_MultiPolygon');
-- Expected: 0

-- Gate 3: Per-layer row counts (GEO-OR-01/02)
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '41'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|36, G4110|241, G5200|6, G5210|30, G5220|60
-- (G4110 count confirmed via dry-run 2026-05-28: 241 OR G4110 incorporated cities)

-- Gate 4: Portland OR sentinel (GEO-OR-05 prerequisite)
-- Note: geo_id '4159000' is ASSUMED (STATEFP='41' + PLACEFP='59000'); confirm after place layer loads
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '41' AND geo_id = '4159000';
-- Expected: 1 row, name='Portland city', mtfcc='G4110'

-- Gate 5: districts table counts for Oregon (state abbrev, case-sensitive)
SELECT state, district_type, COUNT(*) AS cnt
FROM essentials.districts
WHERE state IN ('OR', 'or')
GROUP BY state, district_type ORDER BY state, district_type;
-- Expected:
--   or  | COUNTY         | 36
--   or  | NATIONAL_LOWER |  6
--   or  | STATE_LOWER    | 60
--   or  | STATE_UPPER    | 30
-- (OR has no pre-existing uppercase rows unlike CA; IN clause covers both cases for robustness)

-- Gate 6: Multnomah County sentinel (Portland's county)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '41' AND mtfcc = 'G4020' AND geo_id = '41051';
-- Expected: 1 row, name='Multnomah County'

-- Gate 7: Section-split check — any district row missing a matching geofence row
-- Expected: 0 rows (all district geo_ids must have geofence coverage)
SELECT gb.geo_id, gb.name, gb.mtfcc
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc IN ('G5200', 'G5210', 'G5220', 'G4020')
  AND gb.state = '41'
  AND gb.geo_id NOT IN (SELECT geo_id FROM essentials.districts)
LIMIT 10;
-- Expected: 0 rows
