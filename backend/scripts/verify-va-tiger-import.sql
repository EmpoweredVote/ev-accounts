-- Phase 100 VA TIGER import verification — SELECT only, no writes
-- Run via: psql $DATABASE_URL -f backend/scripts/verify-va-tiger-import.sql

-- Gate 1: No invalid geometries — MUST return 0
SELECT COUNT(*) AS invalid_geometry_count
FROM essentials.geofence_boundaries
WHERE state = '51' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- Gate 2: No GeometryCollection types — MUST return 0
SELECT COUNT(*) AS geometry_collection_count
FROM essentials.geofence_boundaries
WHERE state = '51'
  AND ST_GeometryType(geometry) NOT IN ('ST_Polygon', 'ST_MultiPolygon');
-- Expected: 0

-- Gate 3: Per-layer row counts (VA-GEO-01)
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '51'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|133, G4110|[DRY-RUN-COUNT], G5200|11, G5210|40, G5220|[DRY-RUN-COUNT]
-- (Update G4110 and G5220 expected counts after dry-run confirms actual values)

-- Gate 4: Alexandria dual-tier sentinel (VA-GEO-02 invariant)
-- Both rows must exist: G4110 (incorporated place) AND G4020 (independent city-county)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '51' AND geo_id IN ('5101000', '51510')
ORDER BY mtfcc;
-- Expected: 2 rows
-- geo_id='51510',  name='Alexandria city', mtfcc='G4020'  (independent city-county)
-- geo_id='5101000',name='Alexandria city', mtfcc='G4110'  (incorporated place)

-- Gate 5: districts table counts for Virginia (case-sensitive)
SELECT state, district_type, COUNT(*) AS cnt
FROM essentials.districts
WHERE state IN ('VA', 'va')
GROUP BY state, district_type ORDER BY state, district_type;
-- Expected: ALL rows under state='va' (lowercase — loader passes abbrev from FIPS_TO_STATE['51']='va')
--   va | COUNTY         | 133
--   va | STATE_LOWER    | 100
--   va | STATE_UPPER    | 40
--   va | NATIONAL_LOWER | 11
-- NOTE: no 'VA' (uppercase) rows expected; all layers including cd119 pass abbrev='va' not abbrevUpper

-- Gate 6: Fairfax County sentinel (Alexandria's neighbor — confirms county layer)
-- NOTE: Fairfax County AND Fairfax city are SEPARATE entities in VA (independent city pattern)
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '51' AND mtfcc = 'G4020' AND name LIKE '%Fairfax%'
ORDER BY name;
-- Expected: 2 rows
-- geo_id='51059', name='Fairfax County', mtfcc='G4020'
-- geo_id='51600', name='Fairfax city',   mtfcc='G4020'

-- Gate 7: Section-split check — OR-direction (geofence -> districts)
-- MUST return 0 rows (all G5200/G5210/G5220/G4020 geofences must have matching districts row)
-- NOTE: Use OR-direction to avoid false positives from pre-existing NATIONAL_UPPER row
-- (geo_id='51', no polygon — statewide senator rows have no geofence boundary)
SELECT gb.geo_id, gb.name, gb.mtfcc
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc IN ('G5200', 'G5210', 'G5220', 'G4020')
  AND gb.state = '51'
  AND gb.geo_id NOT IN (SELECT geo_id FROM essentials.districts)
LIMIT 10;
-- Expected: 0 rows
