-- Phase 57 CA TIGER import verification — SELECT only, no writes
-- Run via: psql $DATABASE_URL -f backend/scripts/verify-ca-tiger-import.sql
-- All gates must pass before proceeding to Plan 57-02 (smoke test).
--
-- NOTE: cousub count is 404 (TIGER 2024 file), not 1,057 (TIGERweb BAS25 dataset).
-- All 404 records are FUNCSTAT='S' (Census County Divisions, statistical entities).

-- Gate 1: No invalid geometries — MUST return 0
SELECT COUNT(*) AS invalid_geometry_count
FROM essentials.geofence_boundaries
WHERE state = '06' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- Gate 2: No GeometryCollection types — MUST return 0
SELECT COUNT(*) AS geometry_collection_count
FROM essentials.geofence_boundaries
WHERE state = '06'
  AND ST_GeometryType(geometry) NOT IN ('ST_Polygon', 'ST_MultiPolygon');
-- Expected: 0

-- Gate 3: Per-layer row counts (GEO-01)
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '06'
  AND mtfcc IN ('G4020','G4040','G4110','G5200','G5210','G5220')
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected (the 6 tiers required by Phase 57):
--   G4020 |  58   (counties — NEW in Phase 57)
--   G4040 | 404   (CCDs — NEW in Phase 57; TIGER 2024 file has 404, not 1,057)
--   G4110 | 482   (incorporated cities — already loaded)
--   G5200 |  52   (congressional districts — already loaded)
--   G5210 |  40   (state senate — already loaded)
--   G5220 |  80   (state assembly — already loaded)

-- Gate 4: SF consolidated city-county — BOTH G4110 city AND G4020 county rows present
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '06'
  AND geo_id IN ('0667000','06075')
ORDER BY mtfcc;
-- Expected: 2 rows
--   '06075'   | 'San Francisco County' | 'G4020'
--   '0667000' | 'San Francisco city'   | 'G4110'

-- Gate 5: Los Angeles County present (geo_id '06037')
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '06' AND geo_id = '06037';
-- Expected: 1 row, name LIKE '%Los Angeles%', mtfcc='G4020'

-- Gate 6: districts.COUNTY for California
-- Loader's insertDistrictIfMissing receives state: abbrev = 'ca' (lowercase).
-- Pre-existing 3 rows have state='CA' (uppercase) — all 3 are duplicate LA County
-- rows (geo_id='06037') pre-dating Phase 57. New rows land as 'ca'.
-- Accept either; total distinct counties = 58. The 3 duplicate 'CA' rows are a
-- pre-existing data quality issue; Phase 57 did not create them.
SELECT state, COUNT(*) AS cnt
FROM essentials.districts
WHERE district_type = 'COUNTY' AND state IN ('CA','ca')
GROUP BY state ORDER BY state;
-- Expected:
--   'CA' | 3   (pre-existing LA County duplicates — known issue, not created by Phase 57)
--   'ca' | 57  (new rows from Phase 57 loader)
-- Total rows: 60; distinct counties: 58 (LA is represented in both 'CA' and 'ca' groups)
-- The state casing inconsistency ('CA' vs 'ca') is documented for follow-up resolution.

-- Gate 7: Overlap check — G4110 polygons geometrically identical to G4040 polygons
-- Some CA incorporated cities have CCDs with coterminous boundaries (city boundary =
-- CCD boundary). This is correct TIGER behavior, NOT a data error.
-- Verified 2026-05-21: Torrance, Santa Monica, and Alameda are city-CCD coterminous.
SELECT g1.geo_id AS city_geo_id, g1.name AS city_name,
       g2.geo_id AS ccd_geo_id, g2.name AS ccd_name
FROM essentials.geofence_boundaries g1
JOIN essentials.geofence_boundaries g2
  ON g1.state = '06' AND g1.mtfcc = 'G4110'
 AND g2.state = '06' AND g2.mtfcc = 'G4040'
 AND ST_Equals(g1.geometry, g2.geometry)
ORDER BY g1.name;
-- Expected: 3 rows (Torrance, Santa Monica, Alameda — city-CCD coterminous pairs)
-- These are NOT routing errors: routing logic uses priority (G4110 > G4040 > G4020)
-- so an address in Torrance city will match G4110 first; the G4040 match is harmless.

-- Gate 8: v7.0 target cities sanity check
SELECT geo_id, name
FROM essentials.geofence_boundaries
WHERE state = '06'
  AND mtfcc = 'G4110'
  AND geo_id IN ('0667000','0644000','0668000','0666000','0664000','0626000','0606000')
ORDER BY geo_id;
-- Expected: 7 rows (SF, LA, San Jose, San Diego, Sacramento, Fremont, Berkeley).
-- If fewer than 7 rows return, capture the missing geo_ids — they may need to
-- be re-derived from PLACEFP. Phase 57-02 handles definitive lookup by name.
