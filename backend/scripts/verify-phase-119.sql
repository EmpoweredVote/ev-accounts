-- ============================================================
-- verify-phase-119.sql
-- Phase 119: MA City Council District Geofencing — Phase Gate Verification
--
-- Run via Supabase MCP execute_sql. All 8 assertions must pass
-- (RAISE EXCEPTION on failure). 6 Path 0 spot checks follow —
-- review output for geographic correctness.
--
-- MAGE-10: Boston — 9 X0013 district rows + 2 citywide rows have tiger_geoid
-- MAGE-11: Worcester — 5 X0014 geofence_boundaries + 5 district councillors re-linked
-- MAGE-12: Springfield — 8 X0014 ward rows + 8 ward councillors re-linked
-- MAGE-13: Lowell — 8 X0014 district rows + 8 district councillors re-linked
-- MAGE-14: Brockton — 7 X0014 ward rows + 7 ward councillors re-linked
-- MAGE-15: Quincy — 6 X0014 ward rows + 6 ward councillors re-linked
-- ============================================================

-- ============================================================
-- ASSERTION 1 — MAGE-10 (Boston X0013 tiger_geoid count: 9 per-district rows)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id LIKE 'boston-ma-council-district-%'
    AND mtfcc = 'X0013'
    AND tiger_geoid IS NOT NULL;
  IF v_count <> 9 THEN
    RAISE EXCEPTION 'ASSERTION 1 FAILED [MAGE-10]: expected 9 Boston X0013 rows with tiger_geoid, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 1 PASSED [MAGE-10]: % Boston X0013 per-district rows have tiger_geoid', v_count;
END $$;

-- ============================================================
-- ASSERTION 2 — MAGE-10 (Boston citywide rows: 2 rows at geo_id='2507000' with tiger_geoid)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2507000'
    AND tiger_geoid IS NOT NULL;
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'ASSERTION 2 FAILED [MAGE-10]: expected 2 Boston citywide rows with tiger_geoid (LOCAL + LOCAL_EXEC), found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 2 PASSED [MAGE-10]: % Boston citywide rows have tiger_geoid', v_count;
END $$;

-- ============================================================
-- ASSERTION 3 — MAGE-11 (Worcester X0014 geofence_boundaries count: 5)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'worcester-ma-council-district-%'
    AND mtfcc = 'X0014';
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'ASSERTION 3 FAILED [MAGE-11]: expected 5 Worcester X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 3 PASSED [MAGE-11]: % Worcester X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 4 — MAGE-11 (Worcester district re-link: 0 councillors still at citywide LOCAL)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -258200011 AND -258200007
    AND d.geo_id = '2582000'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 4 FAILED [MAGE-11]: expected 0 Worcester ward councillors at citywide LOCAL, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 4 PASSED [MAGE-11]: % Worcester ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 5 — MAGE-12+13+14+15 (Total X0014 ward rows across 4 cities: 29)
-- Springfield=8, Lowell=8, Brockton=7, Quincy=6
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE mtfcc = 'X0014'
    AND (
      geo_id LIKE 'springfield-ma-council-ward-%'
      OR geo_id LIKE 'lowell-ma-council-district-%'
      OR geo_id LIKE 'brockton-ma-council-ward-%'
      OR geo_id LIKE 'quincy-ma-council-ward-%'
    );
  IF v_count <> 29 THEN
    RAISE EXCEPTION 'ASSERTION 5 FAILED [MAGE-12+13+14+15]: expected 29 X0014 ward/district rows (8+8+7+6), found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 5 PASSED [MAGE-12+13+14+15]: % total X0014 geofence rows across Springfield/Lowell/Brockton/Quincy', v_count;
END $$;

-- ============================================================
-- ASSERTION 6 — MAGE-12 (Springfield re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_id -256700002 through -256700009
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -256700009 AND -256700002
    AND d.geo_id = '2567000'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 6 FAILED [MAGE-12]: expected 0 Springfield ward councillors at citywide LOCAL, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 6 PASSED [MAGE-12]: % Springfield ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 7 — MAGE-13 (Lowell re-link: 0 district councillors at citywide LOCAL)
-- District councillors: external_id -253700005 through -253700012
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -253700012 AND -253700005
    AND d.geo_id = '2537000'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 7 FAILED [MAGE-13]: expected 0 Lowell district councillors at citywide LOCAL, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 7 PASSED [MAGE-13]: % Lowell district councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 8a — MAGE-14 (Brockton re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_id -250900002 through -250900008
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -250900008 AND -250900002
    AND d.geo_id = '2509000'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 8a FAILED [MAGE-14]: Brockton ward councillors still linked to citywide — expected 0, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 8a PASSED [MAGE-14]: % Brockton ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 8b — MAGE-15 (Quincy re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_id -255574502 through -255574507
-- Quincy FIPS: '2555745' (non-round — exact string required)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -255574507 AND -255574502
    AND d.geo_id = '2555745'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 8b FAILED [MAGE-15]: Quincy ward councillors still linked to citywide — expected 0, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 8b PASSED [MAGE-15]: % Quincy ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- Phase 119 gate summary notice
-- ============================================================
DO $$ BEGIN
  RAISE NOTICE 'Phase 119 gate PASSED: all 8 assertions passed.';
END $$;

-- ============================================================
-- PATH 0 SPOT CHECKS — SELECT only, no RAISE EXCEPTION
-- Review output for geographic correctness:
-- Each query should return at least 1 row showing the per-ward councillor
-- for that city hall location. Zero rows = geofencing bug for that city.
-- ============================================================
DO $$ BEGIN
  RAISE NOTICE '=== PATH 0 SPOT CHECKS ===';
END $$;

-- Path 0 spot check 1: Boston (-71.056, 42.360 — Faneuil Hall area)
-- Expected: at least 1 row with geo_id LIKE 'boston-ma-council-district-N'
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.056, 42.360), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;

-- Path 0 spot check 2: Worcester (-71.803, 42.262 — City Hall Plaza)
-- Expected: at least 1 row with geo_id LIKE 'worcester-ma-council-district-N'
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.803, 42.262), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;

-- Path 0 spot check 3: Springfield (-72.589, 42.102 — City Hall)
-- Expected: at least 1 row with geo_id LIKE 'springfield-ma-council-ward-N'
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-72.589, 42.102), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;

-- Path 0 spot check 4: Lowell (-71.310, 42.634 — City Hall)
-- Expected: at least 1 row with geo_id LIKE 'lowell-ma-council-district-N'
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.310, 42.634), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;

-- Path 0 spot check 5: Brockton (-71.018, 42.082 — Brockton City Hall)
-- Expected: at least 1 row with geo_id LIKE 'brockton-ma-council-ward-N'
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.018, 42.082), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;

-- Path 0 spot check 6: Quincy (-71.003, 42.251 — Quincy City Hall)
-- Expected: at least 1 row with geo_id LIKE 'quincy-ma-council-ward-N'
SELECT d.geo_id, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-71.003, 42.251), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;
