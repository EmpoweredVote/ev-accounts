-- Migration 342: tiger_geoid backfill for all NATIONAL_LOWER districts (national US House)
--
-- Sets tiger_geoid = geo_id for every essentials.districts row with
-- district_type = 'NATIONAL_LOWER' and tiger_geoid IS NULL.
--
-- Background: geo_id on these rows IS the TIGER GEOID (4-char, e.g. '4805' for TX-5).
-- The Path 0 join in essentials.ts line ~535 requires tiger_geoid to be set.
-- Without this, users outside CA have no Path 0 match for their House rep.
--
-- Scope: all NATIONAL_LOWER rows across all states (CA already backfilled in
-- supabase/migrations/20260509000003_091_tiger_geoid_backfill.sql;
-- VA backfilled in backend/migrations/321_va_tiger_geoid_backfill.sql).
-- Those rows will match WHERE tiger_geoid IS NULL = false and be skipped.
--
-- Idempotent: WHERE tiger_geoid IS NULL guard prevents double-apply.
-- Applied to production Supabase via Supabase MCP.

BEGIN;

UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE district_type = 'NATIONAL_LOWER'
  AND tiger_geoid IS NULL;

DO $$
DECLARE
  v_total INT;
  v_null  INT;
BEGIN
  SELECT COUNT(*) INTO v_total
    FROM essentials.districts
    WHERE district_type = 'NATIONAL_LOWER';

  SELECT COUNT(*) INTO v_null
    FROM essentials.districts
    WHERE district_type = 'NATIONAL_LOWER'
      AND tiger_geoid IS NULL;

  RAISE NOTICE 'NATIONAL_LOWER total: %', v_total;
  RAISE NOTICE 'NATIONAL_LOWER tiger_geoid IS NULL remaining: %', v_null;

  IF v_null <> 0 THEN
    RAISE EXCEPTION '% NATIONAL_LOWER rows still have tiger_geoid IS NULL after backfill', v_null;
  END IF;
  IF v_total < 430 THEN
    RAISE EXCEPTION 'NATIONAL_LOWER total % is suspiciously low (expected >= 430)', v_total;
  END IF;
  RAISE NOTICE 'Migration 342 complete.';
END $$;

COMMIT;
