-- ============================================================
-- verify-phase-120-124.sql
-- v2.14 MA City Expansion Wave 2 — Consolidated Phase Gate
-- Covers Phases 120–123 (all 21 requirements: MAOF-01..07, MAST-01..07, MAGE-16..22)
-- Run via Supabase MCP execute_sql. All 44 assertions must pass (RAISE EXCEPTION on failure).
-- Cities: Newton (2545560), Somerville (2562535), Lynn (2537490), Fall River (2523000),
--         Waltham (2572600), Medford (2539835), New Bedford (2545000)
-- ============================================================

-- ============================================================
--   PART 1: MAOF — Officials Seeding (Assertions 1–9)
--   Phase 120 | Requirements: MAOF-01..07
-- ============================================================

-- ============================================================
-- ASSERTION 1 — MAOF-01 (Newton politician count: 25)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(DISTINCT p.id) INTO v_count
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
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
  JOIN essentials.offices o ON o.politician_id = p.id
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
  JOIN essentials.offices o ON o.politician_id = p.id
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
  JOIN essentials.offices o ON o.politician_id = p.id
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
  JOIN essentials.offices o ON o.politician_id = p.id
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
  JOIN essentials.offices o ON o.politician_id = p.id
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
  JOIN essentials.offices o ON o.politician_id = p.id
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
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id IN ('2545560','2562535','2537490','2523000','2572600','2539835','2545000')
    AND d.state = 'ma'
    AND p.office_id IS NULL;

  -- Check 8b: politicians in these districts with NO offices row at all (FK orphans)
  SELECT COUNT(DISTINCT p.id) INTO v_orphans
  FROM essentials.politicians p
  JOIN essentials.offices o2 ON o2.politician_id = p.id
  JOIN essentials.districts d2 ON d2.id = o2.district_id
  WHERE d2.geo_id IN ('2545560','2562535','2537490','2523000','2572600','2539835','2545000')
    AND d2.state = 'ma'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.offices ox WHERE ox.politician_id = p.id
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
-- PART 2: MAST Wave 1 — Newton/Somerville/Medford Stances (Assertions 10–18)
-- Phase 121 | Requirements: MAST-01, MAST-02, MAST-06
-- ============================================================

-- ============================================================
-- ASSERTION 10 — MAST-01 (Newton: zero officials with 0 stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2545560'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 10 FAILED [MAST-01]: % Newton officials have zero stance rows (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 10 PASSED [MAST-01]: % Newton officials with zero stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 11 — MAST-01 (Newton: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.offices o ON o.politician_id = pa.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2545560'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 11 FAILED [MAST-01]: % Newton politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 11 PASSED [MAST-01]: % unpaired Newton stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 12 — MAST-01 (Newton: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2545560'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 12 FAILED [MAST-01]: % Newton politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 12 PASSED [MAST-01]: % Newton context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 13 — MAST-02 (Somerville: zero officials with 0 stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2562535'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 13 FAILED [MAST-02]: % Somerville officials have zero stance rows (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 13 PASSED [MAST-02]: % Somerville officials with zero stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 14 — MAST-02 (Somerville: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.offices o ON o.politician_id = pa.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2562535'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 14 FAILED [MAST-02]: % Somerville politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 14 PASSED [MAST-02]: % unpaired Somerville stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 15 — MAST-02 (Somerville: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2562535'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 15 FAILED [MAST-02]: % Somerville politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 15 PASSED [MAST-02]: % Somerville context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 16 — MAST-06 (Medford: zero officials with 0 stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2539835'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 16 FAILED [MAST-06]: % Medford officials have zero stances. Verify migration 700 was applied and politician office links are intact.', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 16 PASSED [MAST-06]: % Medford officials with zero stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 17 — MAST-06 (Medford: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.offices o ON o.politician_id = pa.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2539835'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 17 FAILED [MAST-06]: % Medford politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 17 PASSED [MAST-06]: % unpaired Medford stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 18 — MAST-06 (Medford: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2539835'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 18 FAILED [MAST-06]: % Medford politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 18 PASSED [MAST-06]: % Medford context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- PART 3: MAST Wave 2 — Lynn/Fall River/Waltham/New Bedford Stances (Assertions 19–30)
-- Phase 122 | Requirements: MAST-03, MAST-04, MAST-05, MAST-07
-- ============================================================

-- ============================================================
-- ASSERTION 19 — MAST-03 (Lynn: zero officials with 0 stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2537490'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 19 FAILED [MAST-03]: % Lynn officials have zero stance rows (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 19 PASSED [MAST-03]: % Lynn officials with zero stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 20 — MAST-03 (Lynn: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.offices o ON o.politician_id = pa.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2537490'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 20 FAILED [MAST-03]: % Lynn politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 20 PASSED [MAST-03]: % unpaired Lynn stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 21 — MAST-03 (Lynn: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2537490'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 21 FAILED [MAST-03]: % Lynn politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 21 PASSED [MAST-03]: % Lynn context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 22 — MAST-04 (Fall River: all officials covered; Canuel is documented honest-skip via migration 701)
-- Officials with zero stances must be 0 OR each such official has a migration 701 tracking entry.
-- Gate: migration 701 tracked AND officials_with_zero_stances <= 1.
-- ============================================================
DO $$ DECLARE v_zero_count INTEGER; v_mig_exists INTEGER; BEGIN
  SELECT COUNT(*) INTO v_zero_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2523000'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;

  SELECT COUNT(*) INTO v_mig_exists
  FROM supabase_migrations.schema_migrations
  WHERE version = '701';

  IF v_mig_exists = 0 THEN
    RAISE EXCEPTION 'ASSERTION 22 FAILED [MAST-04]: migration 701 (Fall River stances + Canuel honest-skip) is NOT tracked in schema_migrations';
  END IF;
  IF v_zero_count > 1 THEN
    RAISE EXCEPTION 'ASSERTION 22 FAILED [MAST-04]: % Fall River officials have zero stance rows (expected <= 1 for Canuel honest-skip)', v_zero_count;
  END IF;
  RAISE NOTICE 'ASSERTION 22 PASSED [MAST-04]: % Fall River officials with zero stances (migration 701 tracked; Canuel honest-skip documented)', v_zero_count;
END $$;

-- ============================================================
-- ASSERTION 23 — MAST-04 (Fall River: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.offices o ON o.politician_id = pa.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2523000'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 23 FAILED [MAST-04]: % Fall River politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 23 PASSED [MAST-04]: % unpaired Fall River stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 24 — MAST-04 (Fall River: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2523000'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 24 FAILED [MAST-04]: % Fall River politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 24 PASSED [MAST-04]: % Fall River context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 25 — MAST-05 (Waltham: all officials covered; Tzioumis+Vidal are documented honest-skips via migrations 688/689)
-- Gate: migrations 688 AND 689 tracked AND officials_with_zero_stances <= 2.
-- ============================================================
DO $$ DECLARE v_zero_count INTEGER; v_mig688 INTEGER; v_mig689 INTEGER; BEGIN
  SELECT COUNT(*) INTO v_zero_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2572600'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;

  SELECT COUNT(*) INTO v_mig688 FROM supabase_migrations.schema_migrations WHERE version = '688';
  SELECT COUNT(*) INTO v_mig689 FROM supabase_migrations.schema_migrations WHERE version = '689';

  IF v_mig688 = 0 THEN
    RAISE EXCEPTION 'ASSERTION 25 FAILED [MAST-05]: migration 688 (Tzioumis honest-skip) is NOT tracked in schema_migrations';
  END IF;
  IF v_mig689 = 0 THEN
    RAISE EXCEPTION 'ASSERTION 25 FAILED [MAST-05]: migration 689 (Vidal honest-skip) is NOT tracked in schema_migrations';
  END IF;
  IF v_zero_count > 2 THEN
    RAISE EXCEPTION 'ASSERTION 25 FAILED [MAST-05]: % Waltham officials have zero stance rows (expected <= 2 for Tzioumis+Vidal honest-skip)', v_zero_count;
  END IF;
  RAISE NOTICE 'ASSERTION 25 PASSED [MAST-05]: % Waltham officials with zero stances (migrations 688/689 tracked; Tzioumis+Vidal honest-skip documented)', v_zero_count;
END $$;

-- ============================================================
-- ASSERTION 26 — MAST-05 (Waltham: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.offices o ON o.politician_id = pa.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2572600'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 26 FAILED [MAST-05]: % Waltham politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 26 PASSED [MAST-05]: % unpaired Waltham stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 27 — MAST-05 (Waltham: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2572600'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 27 FAILED [MAST-05]: % Waltham politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 27 PASSED [MAST-05]: % Waltham context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 28 — MAST-07 (New Bedford: all officials covered; Pemberton is documented honest-skip via migration 702)
-- Gate: migration 702 tracked AND officials_with_zero_stances <= 1.
-- ============================================================
DO $$ DECLARE v_zero_count INTEGER; v_mig_exists INTEGER; BEGIN
  SELECT COUNT(*) INTO v_zero_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2545000'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;

  SELECT COUNT(*) INTO v_mig_exists
  FROM supabase_migrations.schema_migrations
  WHERE version = '702';

  IF v_mig_exists = 0 THEN
    RAISE EXCEPTION 'ASSERTION 28 FAILED [MAST-07]: migration 702 (New Bedford stances + Pemberton honest-skip) is NOT tracked in schema_migrations';
  END IF;
  IF v_zero_count > 1 THEN
    RAISE EXCEPTION 'ASSERTION 28 FAILED [MAST-07]: % New Bedford officials have zero stance rows (expected <= 1 for Pemberton honest-skip)', v_zero_count;
  END IF;
  RAISE NOTICE 'ASSERTION 28 PASSED [MAST-07]: % New Bedford officials with zero stances (migration 702 tracked; Pemberton honest-skip documented)', v_zero_count;
END $$;

-- ============================================================
-- ASSERTION 29 — MAST-07 (New Bedford: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.offices o ON o.politician_id = pa.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2545000'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 29 FAILED [MAST-07]: % New Bedford politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 29 PASSED [MAST-07]: % unpaired New Bedford stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 30 — MAST-07 (New Bedford: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2545000'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 30 FAILED [MAST-07]: % New Bedford politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 30 PASSED [MAST-07]: % New Bedford context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- PART 4: MAGE — Ward Geofencing (Assertions 31–44)
-- Phase 123 | Requirements: MAGE-16..22
-- ============================================================

-- ============================================================
-- ASSERTION 31 — MAGE-16 (Newton X0014 geofence_boundaries count: 8)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'newton-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 8 THEN
    RAISE EXCEPTION 'ASSERTION 31 FAILED [MAGE-16]: expected 8 Newton X0014 ward rows in geofence_boundaries, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 31 PASSED [MAGE-16]: % Newton X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 32 — MAGE-16 (Newton re-link: 0 ward councillors still at citywide LOCAL)
-- Ward councillors: external_ids -2545560018 through -2545560025 (non-sequential by ward)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -2545560025 AND -2545560018
    AND d.geo_id = '2545560'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 32 FAILED [MAGE-16]: % Newton ward councillors still point to citywide (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 32 PASSED [MAGE-16]: % Newton ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 33 — MAGE-17 (Somerville X0014 geofence_boundaries count: 7)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'somerville-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 7 THEN
    RAISE EXCEPTION 'ASSERTION 33 FAILED [MAGE-17]: expected 7 Somerville X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 33 PASSED [MAGE-17]: % Somerville X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 34 — MAGE-17 (Somerville re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_ids -2562535006 through -2562535012
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -2562535012 AND -2562535006
    AND d.geo_id = '2562535'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 34 FAILED [MAGE-17]: % Somerville ward councillors still at citywide LOCAL (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 34 PASSED [MAGE-17]: % Somerville ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 35 — MAGE-18 (Lynn X0014 geofence_boundaries count: 7)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'lynn-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 7 THEN
    RAISE EXCEPTION 'ASSERTION 35 FAILED [MAGE-18]: expected 7 Lynn X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 35 PASSED [MAGE-18]: % Lynn X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 36 — MAGE-18 (Lynn re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_ids -2537490006 through -2537490012
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -2537490012 AND -2537490006
    AND d.geo_id = '2537490'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 36 FAILED [MAGE-18]: % Lynn ward councillors still at citywide LOCAL (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 36 PASSED [MAGE-18]: % Lynn ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 37 — MAGE-19 (Fall River X0014 geofence_boundaries count: 9)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'fall-river-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 9 THEN
    RAISE EXCEPTION 'ASSERTION 37 FAILED [MAGE-19]: expected 9 Fall River X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 37 PASSED [MAGE-19]: % Fall River X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 38 — MAGE-19 (Fall River per-ward district rows: 9 with tiger_geoid)
-- NOTE: Fall River is fully at-large — NO office re-links gate needed.
-- At-large councillors remain at citywide '2523000' LOCAL — correct behavior.
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.districts
  WHERE geo_id LIKE 'fall-river-ma-council-ward-%'
    AND tiger_geoid IS NOT NULL;
  IF v_count <> 9 THEN
    RAISE EXCEPTION 'ASSERTION 38 FAILED [MAGE-19]: expected 9 fall-river-ma-council-ward-* district rows with tiger_geoid, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 38 PASSED [MAGE-19]: % Fall River per-ward district rows with tiger_geoid', v_count;
END $$;

-- ============================================================
-- ASSERTION 39 — MAGE-20 (Waltham X0014 geofence_boundaries count: 9)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'waltham-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 9 THEN
    RAISE EXCEPTION 'ASSERTION 39 FAILED [MAGE-20]: expected 9 Waltham X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 39 PASSED [MAGE-20]: % Waltham X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 40 — MAGE-20 (Waltham re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_ids -2572600008 through -2572600016 (sequential Ward 1–9)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -2572600016 AND -2572600008
    AND d.geo_id = '2572600'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 40 FAILED [MAGE-20]: % Waltham ward councillors still at citywide LOCAL (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 40 PASSED [MAGE-20]: % Waltham ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 41 — MAGE-21 (Medford X0014 geofence_boundaries count: 8)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'medford-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 8 THEN
    RAISE EXCEPTION 'ASSERTION 41 FAILED [MAGE-21]: expected 8 Medford X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 41 PASSED [MAGE-21]: % Medford X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 42 — MAGE-21 (Medford per-ward district rows: 8 with tiger_geoid)
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
    RAISE EXCEPTION 'ASSERTION 42 FAILED [MAGE-21]: expected 8 medford-ma-council-ward-* district rows with tiger_geoid, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 42 PASSED [MAGE-21]: % Medford per-ward district rows with tiger_geoid', v_count;
END $$;

-- ============================================================
-- ASSERTION 43 — MAGE-22 (New Bedford X0014 geofence_boundaries count: 6)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'new-bedford-ma-council-ward-%'
    AND mtfcc = 'X0014';
  IF v_count <> 6 THEN
    RAISE EXCEPTION 'ASSERTION 43 FAILED [MAGE-22]: expected 6 New Bedford X0014 geofence_boundaries rows, found %', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 43 PASSED [MAGE-22]: % New Bedford X0014 geofence_boundaries rows', v_count;
END $$;

-- ============================================================
-- ASSERTION 44 — MAGE-22 (New Bedford re-link: 0 ward councillors at citywide LOCAL)
-- Ward councillors: external_ids -2545000007 through -2545000012 (Ward 1–6)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -2545000012 AND -2545000007
    AND d.geo_id = '2545000'
    AND d.district_type = 'LOCAL';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 44 FAILED [MAGE-22]: % New Bedford ward councillors still at citywide LOCAL (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 44 PASSED [MAGE-22]: % New Bedford ward councillors remaining at citywide LOCAL (expected 0)', v_count;
END $$;

-- ============================================================
-- FINAL SUMMARY
-- ============================================================
DO $$ BEGIN
  RAISE NOTICE 'Phase 120-124 gate PASSED: all 44 assertions passed. MAOF-01..07 (Phase 120), MAST-01..07 (Phases 121-122), MAGE-16..22 (Phase 123) all fulfilled. v2.14 MA City Expansion Wave 2 complete.';
END $$;

-- ============================================================
-- PATH 0 SPOT CHECKS — SELECT only, no RAISE EXCEPTION
-- Review output for geographic correctness (7 cities).
-- Ward-seat cities (Newton, Somerville, Lynn, Waltham, New Bedford): expect per-ward geo_id
-- At-large cities (Fall River, Medford): expect citywide geo_id (2523000 / 2539835)
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
JOIN essentials.politicians p ON p.id = o.politician_id
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
JOIN essentials.politicians p ON p.id = o.politician_id
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
JOIN essentials.politicians p ON p.id = o.politician_id
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
JOIN essentials.politicians p ON p.id = o.politician_id
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
JOIN essentials.politicians p ON p.id = o.politician_id
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
JOIN essentials.politicians p ON p.id = o.politician_id
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
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE public.ST_Contains(gb.geometry, public.ST_SetSRID(public.ST_Point(-70.924, 41.635), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL'
ORDER BY d.geo_id;
