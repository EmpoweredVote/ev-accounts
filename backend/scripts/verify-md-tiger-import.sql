-- Phase 91 MD TIGER import verification — SELECT only, no writes
-- Run via: psql $DATABASE_URL -f backend/scripts/verify-md-tiger-import.sql

-- Gate 1: No invalid geometries — MUST return 0
SELECT COUNT(*) AS invalid_geometry_count
FROM essentials.geofence_boundaries
WHERE state = '24' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- Gate 2: No GeometryCollection types — MUST return 0
SELECT COUNT(*) AS geometry_collection_count
FROM essentials.geofence_boundaries
WHERE state = '24'
  AND ST_GeometryType(geometry) NOT IN ('ST_Polygon', 'ST_MultiPolygon');
-- Expected: 0

-- Gate 3: Per-layer row counts (MD-GEO-01/02/03/04/05)
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '24'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|24, G4110|[DRY-RUN-COUNT], G5200|8, G5210|47, G5220|[DRY-RUN-COUNT]
-- (Update G4110 and G5220 expected counts after dry-run confirms actual values)

-- Gate 4: Baltimore City dual-tier sentinel (D-01 invariant)
-- Both rows must exist: G4110 (incorporated city) AND G4020 (independent city-county)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '24' AND geo_id IN ('2404000', '24510')
ORDER BY mtfcc;
-- Expected: 2 rows
-- geo_id='24510',   name='Baltimore city', mtfcc='G4020'  (independent city-county)
-- geo_id='2404000', name='Baltimore city', mtfcc='G4110'  (incorporated place)

-- Gate 5: districts table counts for Maryland (case-sensitive)
SELECT state, district_type, COUNT(*) AS cnt
FROM essentials.districts
WHERE state IN ('MD', 'md')
GROUP BY state, district_type ORDER BY state, district_type;
-- Expected:
--   md  | COUNTY         | 24
--   md  | STATE_LOWER    | [DRY-RUN-COUNT, ~71]
--   md  | STATE_UPPER    | 47
--   MD  | NATIONAL_LOWER |  8
-- (cd119 writes district rows with state=abbrevUpper='MD' per loader casing pattern)

-- Gate 6: St. Mary's County sentinel (Phase 95 prerequisite)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '24' AND mtfcc = 'G4020' AND name LIKE '%Mary%';
-- Expected: 1 row, name="St. Mary's County", geo_id='24037'

-- Gate 7: Section-split check — any district row missing a matching geofence row
-- MUST return 0 rows (all district geo_ids must have geofence coverage)
SELECT d.geo_id, d.district_type, d.state
FROM essentials.districts d
WHERE d.state IN ('MD', 'md')
  AND d.geo_id NOT IN (SELECT geo_id FROM essentials.geofence_boundaries WHERE state = '24')
LIMIT 10;
-- Expected: 0 rows
