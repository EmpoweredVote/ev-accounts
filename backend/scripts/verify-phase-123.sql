-- ============================================================
-- verify-phase-123.sql
-- Phase 123: Ward Geofencing — All 7 Cities — Phase Gate Verification
--
-- Run via Supabase MCP execute_sql. All 7 assertions must pass
-- (RAISE EXCEPTION on failure). 7 Path 0 spot checks follow —
-- review output for geographic correctness.
--
-- MAGE-16: Newton    — 8 X0014 ward boundaries + 8 per-ward district rows + 8 office re-links
-- MAGE-17: Somerville — 7 X0014 ward boundaries + 7 per-ward district rows + 7 office re-links
-- MAGE-18: Lynn       — 7 X0014 ward boundaries + 7 per-ward district rows + 7 office re-links
-- MAGE-19: Fall River — 9 X0014 ward boundaries + 9 per-ward district rows + 0 office re-links (at-large)
-- MAGE-20: Waltham    — 9 X0014 ward boundaries + 9 per-ward district rows + 9 office re-links
-- MAGE-21: Medford    — 8 X0014 ward boundaries + 8 per-ward district rows + 0 office re-links (at-large)
-- MAGE-22: New Bedford — 6 X0014 ward boundaries + 6 per-ward district rows + 6 office re-links
-- ============================================================

-- ============================================================
-- ASSERTION 1 — MAGE-16 (Newton X0014 geofence_boundaries count: 8)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'newton-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 8 THEN
    RAISE EXCEPTION 'ASSERTION 1 FAILED [MAGE-16]: expected 8 Newton X0014 ward rows in geofence_boundaries, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 1 PASSED [MAGE-16]: % Newton X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 2 — MAGE-16 (Newton re-link: 0 ward councillors still at citywide LOCAL)
-- Ward councillors: external_ids -2545560018 through -2545560025 (non-sequential by ward)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE p.external_id BETWEEN -2545560025 AND -2545560018
    AND d.geo_id = '2545560'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 2 FAILED [MAGE-16]: % Newton ward councillors still point to citywide (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 2 PASSED [MAGE-16]: % Newton ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 3a — MAGE-17 (Somerville X0014 geofence_boundaries count: 7)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'somerville-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 7 THEN
    RAISE EXCEPTION 'ASSERTION 3a FAILED [MAGE-17]: expected 7 Somerville X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 3a PASSED [MAGE-17]: % Somerville X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 3b — MAGE-17 (Somerville re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_ids -2562535006 through -2562535012
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE p.external_id BETWEEN -2562535012 AND -2562535006
    AND d.geo_id = '2562535'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 3b FAILED [MAGE-17]: % Somerville ward councillors still at citywide LOCAL (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 3b PASSED [MAGE-17]: % Somerville ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 4a — MAGE-18 (Lynn X0014 geofence_boundaries count: 7)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'lynn-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 7 THEN
    RAISE EXCEPTION 'ASSERTION 4a FAILED [MAGE-18]: expected 7 Lynn X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 4a PASSED [MAGE-18]: % Lynn X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 4b — MAGE-18 (Lynn re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_ids -2537490006 through -2537490012
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE p.external_id BETWEEN -2537490012 AND -2537490006
    AND d.geo_id = '2537490'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 4b FAILED [MAGE-18]: % Lynn ward councillors still at citywide LOCAL (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 4b PASSED [MAGE-18]: % Lynn ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 5a — MAGE-19 (Fall River X0014 geofence_boundaries count: 9)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'fall-river-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 9 THEN
    RAISE EXCEPTION 'ASSERTION 5a FAILED [MAGE-19]: expected 9 Fall River X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 5a PASSED [MAGE-19]: % Fall River X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 5b — MAGE-19 (Fall River per-ward district rows: 9 with tiger_geoid)
-- NOTE: Fall River is fully at-large — NO office re-links gate needed.
-- At-large councillors remain at citywide '2523000' LOCAL — correct behavior.
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.districts
  WHERE geo_id LIKE 'fall-river-ma-council-ward-%'
    AND tiger_geoid IS NOT NULL;
  IF v_count <> 9 THEN
    RAISE EXCEPTION 'ASSERTION 5b FAILED [MAGE-19]: expected 9 fall-river-ma-council-ward-* district rows with tiger_geoid, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 5b PASSED [MAGE-19]: % Fall River per-ward district rows with tiger_geoid', v_count;
END $$;

-- ============================================================
-- ASSERTION 6a — MAGE-20 (Waltham X0014 geofence_boundaries count: 9)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'waltham-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 9 THEN
    RAISE EXCEPTION 'ASSERTION 6a FAILED [MAGE-20]: expected 9 Waltham X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 6a PASSED [MAGE-20]: % Waltham X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 6b — MAGE-20 (Waltham re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_ids -2572600008 through -2572600016 (sequential Ward 1–9)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE p.external_id BETWEEN -2572600016 AND -2572600008
    AND d.geo_id = '2572600'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 6b FAILED [MAGE-20]: % Waltham ward councillors still at citywide LOCAL (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 6b PASSED [MAGE-20]: % Waltham ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 7a — MAGE-21 (Medford X0014 geofence_boundaries count: 8)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'medford-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 8 THEN
    RAISE EXCEPTION 'ASSERTION 7a FAILED [MAGE-21]: expected 8 Medford X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 7a PASSED [MAGE-21]: % Medford X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 7b — MAGE-21 (Medford per-ward district rows: 8 with tiger_geoid)
-- NOTE: Medford is fully at-large (charter reform 2020) — NO office re-links gate.
-- All 7 at-large councillors remain at citywide '2539835' LOCAL — correct behavior.
-- geo_id is '2539835' (corrected by migration 622), NOT '2540115' (Melrose FIPS — Pitfall 4).
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.districts
  WHERE geo_id LIKE 'medford-ma-council-ward-%'
    AND tiger_geoid IS NOT NULL;
  IF v_count <> 8 THEN
    RAISE EXCEPTION 'ASSERTION 7b FAILED [MAGE-21]: expected 8 medford-ma-council-ward-* district rows with tiger_geoid, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 7b PASSED [MAGE-21]: % Medford per-ward district rows with tiger_geoid', v_count;
END $$;

-- ============================================================
-- ASSERTION 7c — MAGE-22 (New Bedford X0014 geofence_boundaries count: 6)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'new-bedford-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 6 THEN
    RAISE EXCEPTION 'ASSERTION 7c FAILED [MAGE-22]: expected 6 New Bedford X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 7c PASSED [MAGE-22]: % New Bedford X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 7d — MAGE-22 (New Bedford re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_ids -2545000007 through -2545000012 (Ward 1–6)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE p.external_id BETWEEN -2545000012 AND -2545000007
    AND d.geo_id = '2545000'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 7d FAILED [MAGE-22]: % New Bedford ward councillors still at citywide LOCAL (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 7d PASSED [MAGE-22]: % New Bedford ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- Phase 123 gate summary notice
-- ============================================================
DO $$ BEGIN
  RAISE NOTICE 'Phase 123 gate PASSED: all assertions passed.';
END $$;

-- ============================================================
-- PATH 0 SPOT CHECKS — SELECT only, no RAISE EXCEPTION
-- Review output for geographic correctness:
-- Ward-seat cities (Newton, Somerville, Lynn, Waltham, New Bedford): expect per-ward rows
-- At-large cities (Fall River, Medford): expect citywide geo_id rows (correct behavior)
-- ============================================================
DO $$ BEGIN
  RAISE NOTICE '=== PATH 0 SPOT CHECKS ===';
END $$;

-- Path 0 spot check 1: Newton (-71.209, 42.337 — City Hall area)
-- Expected: at least 1 row with geo_id LIKE 'newton-ma-council-ward-N'
-- Newton City Hall is on Court Street — expect Ward 2 or Ward 3 area
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.209, 42.337), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;

-- Path 0 spot check 2: Somerville (-71.100, 42.387 — Davis Square area)
-- Expected: at least 1 row with geo_id LIKE 'somerville-ma-council-ward-N'
-- Davis Square is in West Somerville — likely Ward 7 (Emily Hardt -2562535012)
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.100, 42.387), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;

-- Path 0 spot check 3: Lynn (-70.947, 42.467 — Lynn City Hall)
-- Expected: at least 1 row with geo_id LIKE 'lynn-ma-council-ward-N'
-- Lynn City Hall is in the city center — expect Ward 1 or Ward 3 area
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-70.947, 42.467), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;

-- Path 0 spot check 4: Fall River (-71.157, 41.701 — Fall River City Hall)
-- Expected: rows with geo_id='2523000' (citywide) — Fall River is fully at-large.
-- All 9 at-large councillors should appear. geo_id must NOT be 'fall-river-ma-council-ward-N'.
-- NOTE: Fall River's citywide LOCAL row has mtfcc=NULL; geofence_boundaries uses G4110.
-- The tiger_geoid join (d.tiger_geoid=gb.geo_id AND gb.mtfcc=d.mtfcc) fails for NULL mtfcc.
-- Use the essentialsService-compatible join pattern (d.geo_id=gb.geo_id with G4110 match)
-- to verify at-large resolution works end-to-end. Ward-seat cities above use tiger_geoid join.
SELECT d.geo_id, d.label, p.full_name
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id = gb.geo_id
  AND (
    (gb.mtfcc IN ('G4110', 'G4120') AND d.district_type IN ('LOCAL', 'LOCAL_EXEC'))
    OR (gb.mtfcc LIKE 'X%' AND gb.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d.district_type IN ('LOCAL', 'COUNTY'))
  )
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.157, 41.701), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY p.full_name;

-- Path 0 spot check 5: Waltham (-71.236, 42.376 — Waltham City Hall)
-- Expected: at least 1 row with geo_id LIKE 'waltham-ma-council-ward-N'
-- Waltham City Hall is on Moody Street — expect Ward 5 area (Joseph LaCava -2572600012)
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.236, 42.376), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;

-- Path 0 spot check 6: Medford (-71.107, 42.418 — Medford City Hall)
-- Expected: rows with geo_id='2539835' (citywide) — Medford is fully at-large.
-- All 7 at-large councillors should appear. geo_id must NOT be 'medford-ma-council-ward-N'.
-- Note: Medford geo_id is '2539835' (corrected FIPS), NOT '2540115' (Melrose FIPS — Pitfall 4).
-- NOTE: Same G4110 join pattern required as Fall River (citywide mtfcc=NULL, geofence uses G4110).
SELECT d.geo_id, d.label, p.full_name
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id = gb.geo_id
  AND (
    (gb.mtfcc IN ('G4110', 'G4120') AND d.district_type IN ('LOCAL', 'LOCAL_EXEC'))
    OR (gb.mtfcc LIKE 'X%' AND gb.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d.district_type IN ('LOCAL', 'COUNTY'))
  )
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.107, 42.418), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY p.full_name;

-- Path 0 spot check 7: New Bedford (-70.924, 41.635 — New Bedford City Hall)
-- Expected: at least 1 row with geo_id LIKE 'new-bedford-ma-council-ward-N'
-- New Bedford City Hall is in the city center — expect Ward 3 or Ward 4 area
-- Ward 3 = Shawn Oliver (-2545000009), Ward 4 = Derek Baptiste (-2545000010)
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-70.924, 41.635), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;
