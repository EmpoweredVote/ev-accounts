-- verify-fl-tiger-import.sql — Knight Foundation program, wave FL-1. Read-only.
-- Run after the sldu/sldl load, and again after the place load.
--
-- ── IDENTITY ANCHORS ────────────────────────────────────────────────────────────
-- Resolved 2026-08-28 against the ENACTED PLANS themselves, published as ArcGIS
-- feature services and identified by their official Florida plan numbers. These are
-- independent of TIGER, which is the whole point: a correct record count proves
-- nothing about WHICH map you have.
--
--   House  H000H8013:
--     https://services.arcgis.com/ptvDyBs1KkcwzQNJ/arcgis/rest/services/Florida_House_2022_H000H8013/FeatureServer/2
--   Senate S027S8058:
--     https://services.arcgis.com/ptvDyBs1KkcwzQNJ/arcgis/rest/services/Florida_Senate_2022_S027S8058/FeatureServer/1
--
--   Tallahassee (-84.2522719, 30.4535287) -> HD-9   / SD-3
--   Bradenton   (-82.5768045, 27.4897985) -> HD-71  / SD-20
--   Miami       (-80.2086152, 25.7751630) -> HD-113 / SD-36
--
-- Two of the three carry a SECOND, government-domain confirmation that agrees exactly:
--   Tallahassee — Leon County Supervisor of Elections, "FL House 2022" (layer 5) and
--     "FL Senate 2022" (layer 4) on intervector.leoncountyfl.gov: District 9 / District 3.
--   Miami — Miami-Dade County MD_KnowWhereToVote, HouseDistrict (layer 7) and
--     SenateDistrict (layer 6) on gisweb.miamidade.gov: 113 / 36.
--
-- ⚠ BRADENTON HAS ONE SOURCE ONLY. Manatee County publishes no legislative-district
-- service (searched ArcGIS Online 2026-08-28, 128 results, none legislative). The
-- enacted plan is authoritative, but if the Bradenton anchor is the only one that
-- disagrees below, suspect the anchor before suspecting the load.
--
-- The plan numbers also confirm the vintage assumption in the FL allowlist comment:
-- the operative maps are the 2022 apportionment (H000H8013 / S027S8058), and TIGER
-- 2024 carries LSY=2024 on both layers.

\echo '== districts (expect STATE_LOWER 120, STATE_UPPER 40) =='
SELECT district_type, count(*)
FROM essentials.districts
WHERE lower(state) = 'fl' AND district_type IN ('STATE_LOWER', 'STATE_UPPER')
GROUP BY 1 ORDER BY 1;

\echo '== geofence polygons (expect G5220 120, G5210 40) =='
SELECT mtfcc, count(*)
FROM essentials.geofence_boundaries
WHERE state = '12' AND mtfcc IN ('G5220', 'G5210')
GROUP BY 1 ORDER BY 1;

\echo '== every district has geometry (expect 0) =='
SELECT count(*) AS districts_without_geometry
FROM essentials.districts d
WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id);

\echo '== district numbering is complete and unduplicated (expect 0 rows) =='
WITH want AS (
  SELECT 'STATE_LOWER' AS dt, generate_series(1, 120) AS n
  UNION ALL
  SELECT 'STATE_UPPER' AS dt, generate_series(1, 40) AS n
)
SELECT w.dt, w.n, count(d.id) AS rows_found
FROM want w
LEFT JOIN essentials.districts d
  ON lower(d.state) = 'fl'
 AND d.district_type = w.dt
 AND d.geo_id = '12' || lpad(w.n::text, 3, '0')
GROUP BY w.dt, w.n
HAVING count(d.id) <> 1
ORDER BY w.dt, w.n;

\echo '== identity anchors (expect exactly 6 rows: HD-9/SD-3, HD-71/SD-20, HD-113/SD-36) =='
-- 🔴 THE mtfcc PAIRING IN THIS JOIN IS LOAD-BEARING.
-- Florida's sldl and sldu GEOIDs BOTH start at 12001 (measured 2026-08-28 from the raw
-- .dbf), so the collision is TOTAL for districts 1-40: '12040' is both HD-40 and SD-40.
-- Dropping the pairing silently reports the wrong chamber, and nothing errors. This is
-- the accepted collision class that src/lib/geoIdGuard.ts exists to disambiguate; 13
-- states already carry ~1,159 of these.
-- Note SD-3 and SD-20 are both <= 40, so this query would return wrong districts for
-- Tallahassee and Bradenton if the pairing were removed. It is not theoretical here.
WITH pts(label, lon, lat) AS (VALUES
  ('Tallahassee', -84.2522719, 30.4535287),
  ('Bradenton',   -82.5768045, 27.4897985),
  ('Miami',       -80.2086152, 25.7751630)
)
SELECT p.label, d.district_type, d.label AS district
FROM pts p
JOIN essentials.geofence_boundaries g
  ON g.state = '12' AND g.mtfcc IN ('G5220','G5210')
 AND public.ST_Covers(g.geometry, public.ST_SetSRID(public.ST_MakePoint(p.lon, p.lat), 4326))
JOIN essentials.districts d
  ON d.geo_id = g.geo_id
 AND ((g.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
   OR (g.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER'))
ORDER BY p.label, d.district_type;

\echo '== place polygons (expect 411; 0 until the place load runs) =='
SELECT count(*) AS fl_g4110_places
FROM essentials.geofence_boundaries
WHERE state = '12' AND mtfcc = 'G4110';

\echo '== the Knight FL municipalities are present BY EXACT geo_id (expect 5 rows) =='
-- This, not the STATE_CITY_ASSERTIONS gate, is the load-bearing municipality check.
-- That gate is a SUBSTRING match, so 'Miami city' is satisfied by 'West Miami city'
-- and a run missing the real Miami record would still pass it. These ids cannot lie.
--   1207950 Bradenton city   1245000 Miami city        1254025 Palm Beach town
--   1270600 Tallahassee city 1276600 West Palm Beach city
SELECT geo_id, name
FROM essentials.geofence_boundaries
WHERE state = '12' AND mtfcc = 'G4110'
  AND geo_id IN ('1207950', '1245000', '1254025', '1270600', '1276600')
ORDER BY geo_id;
