-- Phase 49 ME TIGER import verification — SELECT only, no writes
-- Run via: psql $DATABASE_URL -f backend/scripts/verify-me-tiger-import.sql

-- Gate 1: No invalid geometries — MUST return 0
SELECT COUNT(*) AS invalid_geometry_count
FROM essentials.geofence_boundaries
WHERE state = '23' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- Gate 2: No GeometryCollection types — MUST return 0
SELECT COUNT(*) AS geometry_collection_count
FROM essentials.geofence_boundaries
WHERE state = '23'
  AND ST_GeometryType(geometry) NOT IN ('ST_Polygon', 'ST_MultiPolygon');
-- Expected: 0

-- Gate 3: Per-layer row counts (GEO-01/02)
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '23'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|16, G4110|23, G5200|2, G5210|35, G5220|151

-- Gate 4: Portland place boundary present (GEO-05 prerequisite)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '23' AND geo_id = '2360545';
-- Expected: 1 row, name='Portland city', mtfcc='G4110'

-- Gate 5: districts table counts for Maine (state abbrev, case-sensitive)
SELECT state, district_type, COUNT(*) AS cnt
FROM essentials.districts
WHERE state IN ('ME', 'me')
GROUP BY state, district_type ORDER BY state, district_type;
-- Expected:
--   ME  | COUNTY         | 16
--   ME  | NATIONAL_LOWER |  2
--   me  | STATE_LOWER    | 151
--   me  | STATE_UPPER    |  35
-- (or all ME uppercase — verify after load)

-- Gate 6: Sample congressional districts — ME-01 and ME-02 geo_ids
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '23' AND mtfcc = 'G5200'
ORDER BY geo_id;
-- Expected: 2 rows (ME-01 and ME-02)

-- Gate 7: Cumberland County present (Portland is in Cumberland)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '23' AND mtfcc = 'G4020' AND name LIKE '%Cumberland%';
-- Expected: 1 row
