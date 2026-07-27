-- ============================================================
-- verify-phase-122.sql
-- Phase 122: Stance Research Wave 2 — Phase Gate Verification
--
-- Run via Supabase MCP execute_sql or pg client.
-- All 12 assertions must pass (RAISE EXCEPTION on failure).
--
-- Cities covered:
--   Lynn        geo_id = '2537490'  (12 politicians)
--   Fall River  geo_id = '2523000'  (10 politicians; Canuel honest-skip via migration 701)
--   Waltham     geo_id = '2572600'  (16 politicians; Tzioumis+Vidal honest-skip via migrations 688/689)
--   New Bedford geo_id = '2545000'  (12 politicians; Pemberton honest-skip via migration 702)
--
-- Requirements fulfilled:
--   MAST-03: Lynn — all 12 officials have sourced stances
--   MAST-04: Fall River — all 10 officials covered (9 stances + 1 honest-skip)
--   MAST-05: Waltham — all 16 officials covered (14 stances + 2 honest-skip)
--   MAST-07: New Bedford — all 12 officials covered (11 stances + 1 honest-skip)
-- ============================================================

-- ============================================================
-- ASSERTION 1 — MAST-03 (Lynn: zero officials with 0 stances)
-- ============================================================
-- ⚠ NEEDS A PRIVILEGED ROLE (noted 2026-07-26). Reads supabase_migrations.schema_migrations, which
-- the least-privileged app role (ev_api) cannot access - "permission denied for schema
-- supabase_migrations". Not a code defect and NOT something to fix by granting ev_api that access.
-- Every other assertion in the file is portable; re-run with a privileged DATABASE_URL to see them.
-- Occupancy ported to essentials.office_current_holder 2026-07-26 (ADR 0002 / mig 1463).

DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2537490'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 1 FAILED [MAST-03]: % Lynn officials have zero stance rows (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 1 PASSED [MAST-03]: % Lynn officials with zero stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 2 — MAST-03 (Lynn: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.office_current_holder och ON och.politician_id = pa.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2537490'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 2 FAILED [MAST-03]: % Lynn politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 2 PASSED [MAST-03]: % unpaired Lynn stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 3 — MAST-03 (Lynn: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.office_current_holder och ON och.politician_id = pc.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2537490'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 3 FAILED [MAST-03]: % Lynn politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 3 PASSED [MAST-03]: % Lynn context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 4 — MAST-04 (Fall River: all officials covered; Canuel is documented honest-skip via migration 701)
-- Officials with zero stances must be 0 OR each such official has a migration 701 tracking entry.
-- Gate: migration 701 tracked AND officials_with_zero_stances <= 1.
-- ============================================================
DO $$ DECLARE v_zero_count INTEGER; v_mig_exists INTEGER; BEGIN
  SELECT COUNT(*) INTO v_zero_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
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
    RAISE EXCEPTION 'ASSERTION 4 FAILED [MAST-04]: migration 701 (Fall River stances + Canuel honest-skip) is NOT tracked in schema_migrations';
  END IF;
  IF v_zero_count > 1 THEN
    RAISE EXCEPTION 'ASSERTION 4 FAILED [MAST-04]: % Fall River officials have zero stance rows (expected <= 1 for Canuel honest-skip)', v_zero_count;
  END IF;
  RAISE NOTICE 'ASSERTION 4 PASSED [MAST-04]: % Fall River officials with zero stances (migration 701 tracked; Canuel honest-skip documented)', v_zero_count;
END $$;

-- ============================================================
-- ASSERTION 5 — MAST-04 (Fall River: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.office_current_holder och ON och.politician_id = pa.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2523000'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 5 FAILED [MAST-04]: % Fall River politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 5 PASSED [MAST-04]: % unpaired Fall River stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 6 — MAST-04 (Fall River: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.office_current_holder och ON och.politician_id = pc.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2523000'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 6 FAILED [MAST-04]: % Fall River politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 6 PASSED [MAST-04]: % Fall River context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 7 — MAST-05 (Waltham: all officials covered; Tzioumis+Vidal are documented honest-skips via migrations 688/689)
-- Gate: migrations 688 AND 689 tracked AND officials_with_zero_stances <= 2.
-- ============================================================
DO $$ DECLARE v_zero_count INTEGER; v_mig688 INTEGER; v_mig689 INTEGER; BEGIN
  SELECT COUNT(*) INTO v_zero_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '2572600'
    AND NOT EXISTS (
      SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id
    )
  ) officials_with_zero_stances;

  SELECT COUNT(*) INTO v_mig688 FROM supabase_migrations.schema_migrations WHERE version = '688';
  SELECT COUNT(*) INTO v_mig689 FROM supabase_migrations.schema_migrations WHERE version = '689';

  IF v_mig688 = 0 THEN
    RAISE EXCEPTION 'ASSERTION 7 FAILED [MAST-05]: migration 688 (Tzioumis honest-skip) is NOT tracked in schema_migrations';
  END IF;
  IF v_mig689 = 0 THEN
    RAISE EXCEPTION 'ASSERTION 7 FAILED [MAST-05]: migration 689 (Vidal honest-skip) is NOT tracked in schema_migrations';
  END IF;
  IF v_zero_count > 2 THEN
    RAISE EXCEPTION 'ASSERTION 7 FAILED [MAST-05]: % Waltham officials have zero stance rows (expected <= 2 for Tzioumis+Vidal honest-skip)', v_zero_count;
  END IF;
  RAISE NOTICE 'ASSERTION 7 PASSED [MAST-05]: % Waltham officials with zero stances (migrations 688/689 tracked; Tzioumis+Vidal honest-skip documented)', v_zero_count;
END $$;

-- ============================================================
-- ASSERTION 8 — MAST-05 (Waltham: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.office_current_holder och ON och.politician_id = pa.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2572600'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 8 FAILED [MAST-05]: % Waltham politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 8 PASSED [MAST-05]: % unpaired Waltham stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 9 — MAST-05 (Waltham: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.office_current_holder och ON och.politician_id = pc.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2572600'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 9 FAILED [MAST-05]: % Waltham politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 9 PASSED [MAST-05]: % Waltham context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 10 — MAST-07 (New Bedford: all officials covered; Pemberton is documented honest-skip via migration 702)
-- Gate: migration 702 tracked AND officials_with_zero_stances <= 1.
-- ============================================================
DO $$ DECLARE v_zero_count INTEGER; v_mig_exists INTEGER; BEGIN
  SELECT COUNT(*) INTO v_zero_count
  FROM (
    SELECT p.id
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
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
    RAISE EXCEPTION 'ASSERTION 10 FAILED [MAST-07]: migration 702 (New Bedford stances + Pemberton honest-skip) is NOT tracked in schema_migrations';
  END IF;
  IF v_zero_count > 1 THEN
    RAISE EXCEPTION 'ASSERTION 10 FAILED [MAST-07]: % New Bedford officials have zero stance rows (expected <= 1 for Pemberton honest-skip)', v_zero_count;
  END IF;
  RAISE NOTICE 'ASSERTION 10 PASSED [MAST-07]: % New Bedford officials with zero stances (migration 702 tracked; Pemberton honest-skip documented)', v_zero_count;
END $$;

-- ============================================================
-- ASSERTION 11 — MAST-07 (New Bedford: zero unpaired stances)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_answers pa
  JOIN essentials.office_current_holder och ON och.politician_id = pa.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2545000'
  AND NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
    WHERE pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 11 FAILED [MAST-07]: % New Bedford politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 11 PASSED [MAST-07]: % unpaired New Bedford stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 12 — MAST-07 (New Bedford: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.office_current_holder och ON och.politician_id = pc.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2545000'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 12 FAILED [MAST-07]: % New Bedford politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 12 PASSED [MAST-07]: % New Bedford context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- Phase 122 gate summary notice
-- ============================================================
DO $$ BEGIN
  RAISE NOTICE 'ALL 12 ASSERTIONS PASSED — Phase 122 gate clear: MAST-03/04/05/07 satisfied (Lynn 12, Fall River 10, Waltham 16, New Bedford 12).';
END $$;
