-- ============================================================
-- verify-phase-121.sql
-- Phase 121: Stance Research Wave 1 — Phase Gate Verification
--
-- Run via Supabase MCP execute_sql. All 9 assertions must pass
-- (RAISE EXCEPTION on failure).
--
-- Cities covered:
--   Newton     geo_id = '2545560'  (25 politicians)
--   Somerville geo_id = '2562535'  (12 politicians)
--   Medford    geo_id = '2539835'  (8 politicians; Liz Mullane via migration 700)
--
-- Requirements fulfilled:
--   MAST-01: Newton — all 25 officials have sourced stances
--   MAST-02: Somerville — all 12 officials have sourced stances
--   MAST-06: Medford — all 8 officials have stances (honest-skip via migration 700 acceptable)
-- ============================================================

-- ============================================================
-- ASSERTION 1 — MAST-01 (Newton: zero officials with 0 stances)
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
    RAISE EXCEPTION 'ASSERTION 1 FAILED [MAST-01]: % Newton officials have zero stance rows (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 1 PASSED [MAST-01]: % Newton officials with zero stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 2 — MAST-01 (Newton: zero unpaired stances)
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
    RAISE EXCEPTION 'ASSERTION 2 FAILED [MAST-01]: % Newton politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 2 PASSED [MAST-01]: % unpaired Newton stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 3 — MAST-01 (Newton: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2545560'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 3 FAILED [MAST-01]: % Newton politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 3 PASSED [MAST-01]: % Newton context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 4 — MAST-02 (Somerville: zero officials with 0 stances)
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
    RAISE EXCEPTION 'ASSERTION 4 FAILED [MAST-02]: % Somerville officials have zero stance rows (expected 0)', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 4 PASSED [MAST-02]: % Somerville officials with zero stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 5 — MAST-02 (Somerville: zero unpaired stances)
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
    RAISE EXCEPTION 'ASSERTION 5 FAILED [MAST-02]: % Somerville politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 5 PASSED [MAST-02]: % unpaired Somerville stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 6 — MAST-02 (Somerville: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2562535'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 6 FAILED [MAST-02]: % Somerville politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 6 PASSED [MAST-02]: % Somerville context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 7 — MAST-06 (Medford: zero officials with 0 stances)
--
-- Honest-skip is acceptable for Medford (migration 700 applied).
-- Any official with 0 stances is only a failure if migration 700
-- was not applied. Since migration 700 covers honest-skip entries,
-- a 0-count here means an official was genuinely missed entirely.
-- After Plan 01 (migration 700 + Liz Mullane stances), all 8
-- Medford officials should have at least 1 row in politician_answers.
-- ============================================================
DO $$ DECLARE v_count INTEGER; v_migration_applied BOOLEAN; BEGIN
  -- Check if migration 700 was applied (honest-skip migration)
  SELECT EXISTS (
    SELECT 1 FROM supabase_migrations.schema_migrations WHERE version = '700'
  ) INTO v_migration_applied;

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

  IF v_count <> 0 AND v_migration_applied THEN
    RAISE EXCEPTION 'ASSERTION 7 FAILED [MAST-06]: % Medford officials have zero stances even after migration 700 (honest-skip). Each official must have at least 1 row in politician_answers.', v_count;
  ELSIF v_count <> 0 AND NOT v_migration_applied THEN
    RAISE EXCEPTION 'ASSERTION 7 FAILED [MAST-06]: % Medford officials have zero stances AND migration 700 was not applied. Apply migration 700 first.', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 7 PASSED [MAST-06]: % Medford officials with zero stances (expected 0); migration 700 applied: %', v_count, v_migration_applied;
END $$;

-- ============================================================
-- ASSERTION 8 — MAST-06 (Medford: zero unpaired stances)
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
    RAISE EXCEPTION 'ASSERTION 8 FAILED [MAST-06]: % Medford politician_answers rows have no matching politician_context row', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 8 PASSED [MAST-06]: % unpaired Medford stances (expected 0)', v_count;
END $$;

-- ============================================================
-- ASSERTION 9 — MAST-06 (Medford: zero context rows with NULL or empty sources)
-- ============================================================
DO $$ DECLARE v_count INTEGER; BEGIN
  SELECT COUNT(*) INTO v_count
  FROM inform.politician_context pc
  JOIN essentials.offices o ON o.politician_id = pc.politician_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2539835'
  AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'ASSERTION 9 FAILED [MAST-06]: % Medford politician_context rows have NULL or empty sources array', v_count;
  END IF;
  RAISE NOTICE 'ASSERTION 9 PASSED [MAST-06]: % Medford context rows with NULL/empty sources (expected 0)', v_count;
END $$;

-- ============================================================
-- Phase 121 gate summary notice
-- ============================================================
DO $$ BEGIN
  RAISE NOTICE 'Phase 121 gate PASSED: all 9 assertions passed. MAST-01 (Newton 25), MAST-02 (Somerville 12), MAST-06 (Medford 8 incl. Liz Mullane via migration 700) fulfilled.';
END $$;
