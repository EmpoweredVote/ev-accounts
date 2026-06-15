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
-- Expected: G4020|14, G4040|293, G4110|58, G5200|9, G5210|40, G5220|160
-- NOTE: G4110=58 (58 incorporated cities with city charters; 293 MA towns are G4040 COUSUB, not loaded in Phase 38)
-- NOTE: G4040=293 loaded in Phase 48 (MA towns via COUSUB, FUNCSTAT='A')

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

-- ─── Phase 48: G4040 COUSUB town gates ──────────────────────────────────────

-- MACOUSUB-01: Total active town count — MUST return exactly 293
SELECT COUNT(*) AS cousub_count
FROM essentials.geofence_boundaries
WHERE state = '25' AND mtfcc = 'G4040';
-- Expected: 293

-- MACOUSUB-02: Cambridge MUST NOT appear in G4040 (FUNCSTAT='F' correctly excluded)
SELECT COUNT(*) AS cambridge_cousub_count
FROM essentials.geofence_boundaries
WHERE state = '25' AND mtfcc = 'G4040' AND geo_id = '2501711000';
-- Expected: 0

-- MACOUSUB-03: Lexington town boundary present
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '25' AND mtfcc = 'G4040' AND geo_id = '2501735215';
-- Expected: 1 row, name includes 'Lexington'

-- MACOUSUB-04: Concord town boundary present
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '25' AND mtfcc = 'G4040' AND geo_id = '2501715060';
-- Expected: 1 row, name includes 'Concord'

-- MACOUSUB-05: No invalid geometries in G4040 layer
SELECT COUNT(*) AS invalid_cousub_count
FROM essentials.geofence_boundaries
WHERE state = '25' AND mtfcc = 'G4040' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- MACOUSUB-06: Complete MA picture after Phase 48
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '25'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|14, G4040|293, G4110|58, G5200|9, G5210|40, G5220|160

-- ─── Phase 118: MA TIGER Geofencing — tiger_geoid backfill gates ──────────────

-- MAGE-00: MA geofence_boundaries counts by MTFCC (post-Phase 118 baseline)
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '25'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|14, G4040|293, G4110|58, G5200|9, G5210|40, G5220|160, G5420|5, X0013|9
-- (8 rows total — G5420 and X0013 are pre-existing and unaffected by Phase 118)

-- MAGE-01: STATE_LOWER tiger_geoid IS NULL count = 0 — MUST return 0
SELECT COUNT(*) AS state_lower_null
FROM essentials.districts
WHERE state = 'ma' AND district_type = 'STATE_LOWER' AND tiger_geoid IS NULL;
-- Expected: 0 (migration 619 backfilled all 160 STATE_LOWER rows)

-- MAGE-02: STATE_UPPER tiger_geoid IS NULL count = 0 — MUST return 0
SELECT COUNT(*) AS state_upper_null
FROM essentials.districts
WHERE state = 'ma' AND district_type = 'STATE_UPPER' AND tiger_geoid IS NULL;
-- Expected: 0 (migration 619 backfilled all 40 STATE_UPPER rows)

-- MAGE-03: 6 new city LOCAL/LOCAL_EXEC tiger_geoid IS NULL count = 0 — MUST return 0
SELECT COUNT(*) AS city_null
FROM essentials.districts
WHERE state = 'ma'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IN ('2562535', '2537490', '2539835', '2523000', '2572600', '2545000')
  AND tiger_geoid IS NULL;
-- Expected: 0 (migration 622 backfilled all 12 city LOCAL + LOCAL_EXEC rows)
-- Cities: Somerville(2562535), Lynn(2537490), Medford(2539835), Fall River(2523000),
--         Waltham(2572600), New Bedford(2545000)

-- MAGE-04: Medford geo_id corrected (2540115 was Melrose; 2539835 is Medford) — MUST return 2
SELECT COUNT(*) AS medford_correct
FROM essentials.districts
WHERE state = 'ma' AND geo_id = '2539835' AND district_type IN ('LOCAL', 'LOCAL_EXEC');
-- Expected: 2 (LOCAL + LOCAL_EXEC rows; migration 622 corrected from Melrose's FIPS code)

-- MAGE-05: Path 0 smoke test — Porter Square Cambridge → MA state senate + house districts
-- Confirms tiger_geoid join works end-to-end after backfill
-- NOTE: subquery filters mtfcc IN ('G5210','G5220') to avoid false match on geo_id '25017'
-- which exists in both Middlesex County (G4020) and 8th Bristol SLDL district (G5220).
SELECT district_type, geo_id, label
FROM essentials.districts
WHERE tiger_geoid IN (
  SELECT gb.geo_id
  FROM essentials.geofence_boundaries gb
  WHERE gb.state = '25'
    AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-71.1190, 42.3876), 4326))
    AND gb.mtfcc IN ('G5210', 'G5220')
)
AND district_type IN ('STATE_UPPER', 'STATE_LOWER')
ORDER BY district_type;
-- Expected: 2 rows
--   STATE_LOWER: geo_id='25083' (25th Middlesex District — MA House)
--   STATE_UPPER: geo_id='25D27' (Second Middlesex District — MA Senate)
