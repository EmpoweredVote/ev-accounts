-- Phase 190 AZ TIGER import verification — SELECT only, no writes
-- Run via: psql $DATABASE_URL -f backend/scripts/verify-az-tiger-import.sql

-- Gate 1: No invalid geometries — MUST return 0
SELECT COUNT(*) AS invalid_geometry_count
FROM essentials.geofence_boundaries
WHERE state = '04' AND NOT ST_IsValid(geometry);
-- Expected: 0

-- Gate 2: No GeometryCollection types — MUST return 0
SELECT COUNT(*) AS geometry_collection_count
FROM essentials.geofence_boundaries
WHERE state = '04'
  AND ST_GeometryType(geometry) NOT IN ('ST_Polygon', 'ST_MultiPolygon');
-- Expected: 0

-- Gate 3: Per-layer row counts (AZ-GEO-01)
SELECT mtfcc, COUNT(*) AS row_count
FROM essentials.geofence_boundaries
WHERE state = '04'
GROUP BY mtfcc ORDER BY mtfcc;
-- Expected: G4020|15, G4110|[DRY-RUN-COUNT ~91], G5200|9, G5210|30, G5220|30
-- (Compare G4110 against EXPECTED_AZ_MTFCC.place after the live load)
-- G4020=15: 15 AZ counties (NO independent cities, unlike VA/NV)
-- G4110=[DRY-RUN-COUNT]: AZ incorporated municipalities (all G4110 places; ~91 expected)
-- G5200=9: 9 AZ congressional districts
-- G5210=30: 30 AZ legislative districts (single senator each)
-- G5220=30: 30 AZ legislative-district polygons (D-04 — 2 house seats per district, ONE polygon; NOT 60)

-- Gate 4: unincorporated-Pima invariant (headline correctness check)
-- A Catalina Foothills coordinate (unincorporated Pima County, north of Tucson city
-- limits) must return Pima County tiers but NO G4110 and NO G4040 row — Catalina
-- Foothills has no municipal government (the county governs it), the AZ analog of
-- NV's Las Vegas Strip check.
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '04'
  AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-110.9210, 32.3130), 4326))
ORDER BY mtfcc;
-- Expected: G4020 row (Pima County, geo_id='04019') + G5200/G5210/G5220 tiers
--           NO G4110 row (Catalina Foothills is unincorporated — no city boundary covers it)
--           NO G4040 row (no township tier)

-- Gate 5: districts table casing for Arizona
-- county/sldu/sldl are written lowercase 'az' by THIS load (D-00 — insertDistrictIfMissing
-- always receives lowercase abbrev; there is NO abbrevUpper branch for cd119/NATIONAL_LOWER).
-- The uppercase AZ|NATIONAL_LOWER|9 rows come from a PRE-EXISTING seed, NOT this load — the
-- loader's 9 cd119 writes are SKIPPED by the WHERE NOT EXISTS (geo_id, district_type) guard
-- because all 9 CD geo_ids (0401–0409) already exist. AZ|NATIONAL_UPPER|1 and AZ|STATE_EXEC|4
-- are also pre-existing seed rows — do NOT treat these extra uppercase rows as a defect.
SELECT state, district_type, COUNT(*) AS cnt
FROM essentials.districts
WHERE state IN ('AZ', 'az')
GROUP BY state, district_type ORDER BY state, district_type;
-- Expected:
--   az | COUNTY         | 15   (written by this load)
--   az | STATE_LOWER    | 30   (written by this load — 30 SLDL polygons per D-04)
--   az | STATE_UPPER    | 30   (written by this load)
--   AZ | NATIONAL_LOWER | 9    (PRE-EXISTING seed — cd119 writes skipped by NOT-EXISTS guard)
--   AZ | NATIONAL_UPPER | 1    (PRE-EXISTING seed — do NOT treat as defect)
--   AZ | STATE_EXEC     | 4    (PRE-EXISTING seed — do NOT treat as defect)

-- Gate 6: Pima County sentinel — confirms county layer loaded correctly
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE state = '04' AND mtfcc = 'G4020' AND name LIKE '%Pima County%';
-- Expected: 1 row — geo_id='04019', name='Pima County', mtfcc='G4020'

-- Gate 7: Section-split check — OR-direction (geofence -> districts)
-- MUST return 0 rows (all G5200/G5210/G5220/G4020 geofences must have matching districts row).
-- NOTE: Use OR-direction (geofence_boundaries -> districts) NOT the inverse (districts -> geofence_boundaries).
-- Reason: pre-existing NATIONAL_UPPER rows for AZ US Senators (no polygon, no geofence_boundaries row)
-- would produce a false positive under the inverse direction (districts -> geofence_boundaries).
-- The OR-direction query surfaces geofence polygons that are missing a matching districts row.
SELECT gb.geo_id, gb.name, gb.mtfcc
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc IN ('G5200', 'G5210', 'G5220', 'G4020')
  AND gb.state = '04'
  AND gb.geo_id NOT IN (SELECT geo_id FROM essentials.districts)
LIMIT 10;
-- Expected: 0 rows (clean section-split)
