-- Phase 38 MA TIGER import verification — SELECT only, no writes
-- Run via: psql $DATABASE_URL -f scripts/verify-ma-tiger-import.sql

-- Gate 1: No invalid geometries — MUST return 0
SELECT COUNT(*) AS invalid_geometry_count
FROM essentials.geofence_boundaries
WHERE state = '25' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- Gate 2: No GeometryCollection types — MUST return 0
SELECT COUNT(*) AS geometry_collection_count
FROM essentials.geofence_boundaries
WHERE state = '25'
  AND ST_GeometryType(geometry) NOT IN ('ST_Polygon', 'ST_MultiPolygon');
-- Expected: 0

-- MAGEO-01/02/03/04: Per-layer row counts
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '25'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|14, G4110|58, G5200|9, G5210|40, G5220|160
-- NOTE: G4110=58 (58 incorporated cities with city charters; 293 MA towns are G4040 COUSUB, not loaded in Phase 38)

-- Cambridge place boundary (MAGEO-03)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '25' AND geo_id = '2511000';
-- Expected: 1 row, name='Cambridge city', mtfcc='G4110'

-- Middlesex County boundary (MAGEO-04)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '25' AND geo_id = '25017';
-- Expected: 1 row, name includes 'Middlesex', mtfcc='G4020'

-- Districts table (Phase 39 prerequisite)
SELECT district_type, COUNT(*) AS cnt
FROM essentials.districts
WHERE state = 'MA'
GROUP BY district_type ORDER BY district_type;
-- Expected: COUNTY|14, NATIONAL_LOWER|9, STATE_LOWER|160, STATE_UPPER|40

-- Point-in-polygon: north Cambridge (MA-05 side, Porter Square area)
-- Longitude first in ST_MakePoint
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '25'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-71.1190, 42.3876), 4326))
ORDER BY mtfcc;
-- Expected: at least G5200 (MA-05 geo_id='2505'), G5210 (MA Senate), G5220 (MA House), G4110 (Cambridge), G4020 (Middlesex)

-- Point-in-polygon: south Cambridge / Kendall Square (MA-07 side)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '25'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-71.0870, 42.3626), 4326))
ORDER BY mtfcc;
-- Expected: G5200 geo_id='2507' (MA-07), G5210, G5220, G4110 (Cambridge city), G4020 (Middlesex)

-- Point-in-polygon: Cambridge/Somerville border (Inman Square side)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '25'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-71.1015, 42.3733), 4326))
  AND mtfcc = 'G4110';
-- Expected: exactly 1 row with name='Cambridge city' (NOT Somerville city)

-- Somerville sanity check: a Somerville address should NOT return Cambridge G4110
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '25'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-71.0990, 42.3790), 4326))
  AND mtfcc = 'G4110';
-- Expected: 1 row with name='Somerville city' (geo_id='2562535')
