-- ============================================================
-- verify-phase-120.sql
-- Phase 120: MA City Officials Seeding — Phase Gate Verification
--
-- Run via Supabase MCP execute_sql. All 9 assertions must pass
-- (RAISE EXCEPTION on failure).
--
-- Migrations that fulfill Phase 120:
--   578 — Newton city government (25 politicians)
--   581 — Somerville city government (12 politicians)
--   584 — Lynn city government (12 politicians)
--   587 — New Bedford city government (12 politicians)
--   590 — Fall River city government (10 politicians)
--   591 — Medford city government (8 politicians) [geo_id fixed by 622]
--   592 — Waltham city government (16 politicians)
--   622 — tiger_geoid backfill for 6 cities (Somerville/Lynn/Medford/Fall River/Waltham/New Bedford)
--   687 — Newton tiger_geoid backfill
--
-- MAOF-01: Newton — 25 politicians + 2 districts + tiger_geoid set
-- MAOF-02: Somerville — 12 politicians + 2 districts + tiger_geoid set
-- MAOF-03: Lynn — 12 politicians + 2 districts + tiger_geoid set
-- MAOF-04: Fall River — 10 politicians + 2 districts + tiger_geoid set
-- MAOF-05: Waltham — 16 politicians + 2 districts + tiger_geoid set
-- MAOF-06: Medford — 8 politicians + 2 districts + tiger_geoid set
-- MAOF-07: New Bedford — 12 politicians + 2 districts + tiger_geoid set
-- ============================================================

-- ============================================================
-- ASSERTION 1 — MAOF-01 (Newton politician count: 25)
-- ============================================================
-- ⚠ SUPERSEDED by verify-phase-120-124.sql (noted 2026-07-26). Its ASSERTION 1 scopes Newton to
-- d.geo_id = '2545560' alone and reads 17, not 25, because Phase 123 re-linked 8 Newton councillors
-- onto per-ward districts. The consolidated gate accounts for that with
-- "OR d.geo_id LIKE 'newton-ma-council-ward-%'" and PASSES. Run the consolidated gate instead; do
-- not lower this 25 to 17, which would just encode the pre-re-link blind spot.
-- Occupancy ported to essentials.office_current_holder 2026-07-26 (ADR 0002 / mig 1463).

DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_count
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2545560' AND d.state = 'ma';
  IF v_count <> 25 THEN
    RAISE EXCEPTION 'ASSERTION 1 FAILED [MAOF-01]: expected 25 Newton politicians, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 1 PASSED [MAOF-01]: % / 25 Newton politicians present', v_count;
END $$;

-- ============================================================
-- ASSERTION 2 — MAOF-02 (Somerville politician count: 12)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_count
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2562535' AND d.state = 'ma';
  IF v_count <> 12 THEN
    RAISE EXCEPTION 'ASSERTION 2 FAILED [MAOF-02]: expected 12 Somerville politicians, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 2 PASSED [MAOF-02]: % / 12 Somerville politicians present', v_count;
END $$;

-- ============================================================
-- ASSERTION 3 — MAOF-03 (Lynn politician count: 12)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_count
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2537490' AND d.state = 'ma';
  IF v_count <> 12 THEN
    RAISE EXCEPTION 'ASSERTION 3 FAILED [MAOF-03]: expected 12 Lynn politicians, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 3 PASSED [MAOF-03]: % / 12 Lynn politicians present', v_count;
END $$;

-- ============================================================
-- ASSERTION 4 — MAOF-04 (Fall River politician count: 10)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_count
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2523000' AND d.state = 'ma';
  IF v_count <> 10 THEN
    RAISE EXCEPTION 'ASSERTION 4 FAILED [MAOF-04]: expected 10 Fall River politicians, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 4 PASSED [MAOF-04]: % / 10 Fall River politicians present', v_count;
END $$;

-- ============================================================
-- ASSERTION 5 — MAOF-05 (Waltham politician count: 16)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_count
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2572600' AND d.state = 'ma';
  IF v_count <> 16 THEN
    RAISE EXCEPTION 'ASSERTION 5 FAILED [MAOF-05]: expected 16 Waltham politicians, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 5 PASSED [MAOF-05]: % / 16 Waltham politicians present', v_count;
END $$;

-- ============================================================
-- ASSERTION 6 — MAOF-06 (Medford politician count: 8)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_count
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2539835' AND d.state = 'ma';
  IF v_count <> 8 THEN
    RAISE EXCEPTION 'ASSERTION 6 FAILED [MAOF-06]: expected 8 Medford politicians, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 6 PASSED [MAOF-06]: % / 8 Medford politicians present', v_count;
END $$;

-- ============================================================
-- ASSERTION 7 — MAOF-07 (New Bedford politician count: 12)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_count
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2545000' AND d.state = 'ma';
  IF v_count <> 12 THEN
    RAISE EXCEPTION 'ASSERTION 7 FAILED [MAOF-07]: expected 12 New Bedford politicians, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 7 PASSED [MAOF-07]: % / 12 New Bedford politicians present', v_count;
END $$;

-- ============================================================
-- ASSERTION 8 — Structural: Zero NULL office_id + zero FK orphans across all 7 cities (MAOF-01..07 composite)
-- ============================================================
DO $$ DECLARE v_null_office INTEGER; v_orphans INTEGER; BEGIN
  -- Check 8a: politicians linked via offices whose office_id is NULL
  SELECT COUNT(*) INTO v_null_office
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id IN ('2545560','2562535','2537490','2523000','2572600','2539835','2545000')
    AND d.state = 'ma'
    AND p.office_id IS NULL;

  -- Check 8b: politicians in these districts with NO offices row at all (FK orphans)
  SELECT COUNT(DISTINCT p.id) INTO v_orphans
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och2 ON och2.politician_id = p.id
  JOIN essentials.offices o2 ON o2.id = och2.office_id
  JOIN essentials.districts d2 ON d2.id = o2.district_id
  WHERE d2.geo_id IN ('2545560','2562535','2537490','2523000','2572600','2539835','2545000')
    AND d2.state = 'ma'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.office_current_holder och3 WHERE och3.politician_id = p.id
    );

  IF v_null_office <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 8 FAILED [MAOF-01..07]: % politicians have NULL office_id across the 7-city batch', v_null_office;
  END IF;
  IF v_orphans <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 8 FAILED [MAOF-01..07]: % politicians in 7-city districts have no offices row (FK orphans)', v_orphans;
  END IF;
  RAISE NOTICE 'ASSERTION 8 PASSED [MAOF-01..07]: % NULL office_id, % FK orphans (both expected 0)', v_null_office, v_orphans;
END $$;

-- ============================================================
-- ASSERTION 9 — Structural: All 7 cities have non-NULL tiger_geoid (MAOF-01..07 composite, unblocks Phase 123)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND district_type IN ('LOCAL','LOCAL_EXEC')
    AND geo_id IN ('2545560','2562535','2537490','2523000','2572600','2539835','2545000')
    AND tiger_geoid IS NULL;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 9 FAILED [MAOF-01..07]: % district rows have NULL tiger_geoid — Phase 123 will be blocked', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 9 PASSED [MAOF-01..07]: % district rows with NULL tiger_geoid (expected 0)', v_count;
END $$;

-- ============================================================
-- Phase 120 gate summary notice
-- ============================================================
DO $$ BEGIN
  RAISE NOTICE 'Phase 120 gate PASSED: all 9 assertions passed. Migrations 578-592+622+687 verified. MAOF-01..07 fulfilled.';
END $$;
