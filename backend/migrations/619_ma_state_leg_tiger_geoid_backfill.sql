-- Migration 619: tiger_geoid backfill for MA state legislative districts
--
-- Populates tiger_geoid on essentials.districts for MA districts that have
-- TIGER boundary files: STATE_LOWER (160 house districts), STATE_UPPER (40 senate districts).
--
-- Pattern: tiger_geoid = geo_id (same value). Dual-column Path 0 join requires
-- both columns set. Mirrors VA backfill (migration 321).
--
-- Scope: 200 rows
--   STATE_LOWER  × 160  state='ma' geo_ids 25001–25160
--   STATE_UPPER  × 40   state='ma' geo_ids 25D01–25D40
--
-- Idempotent: WHERE tiger_geoid IS NULL guard prevents double-apply.
-- Applied to production Supabase via Supabase MCP.

BEGIN;

UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND tiger_geoid IS NULL;

DO $$
DECLARE
  v_sl  INT;
  v_su  INT;
  v_rem INT;
BEGIN
  SELECT COUNT(*) INTO v_sl  FROM essentials.districts WHERE state = 'ma' AND district_type = 'STATE_LOWER'  AND tiger_geoid IS NOT NULL;
  SELECT COUNT(*) INTO v_su  FROM essentials.districts WHERE state = 'ma' AND district_type = 'STATE_UPPER'  AND tiger_geoid IS NOT NULL;
  SELECT COUNT(*) INTO v_rem FROM essentials.districts WHERE state = 'ma' AND district_type IN ('STATE_LOWER', 'STATE_UPPER') AND tiger_geoid IS NULL;

  RAISE NOTICE 'STATE_LOWER: % / 160', v_sl;
  RAISE NOTICE 'STATE_UPPER: % / 40',  v_su;

  IF v_sl <> 160 OR v_su <> 40 THEN
    RAISE EXCEPTION 'Count mismatch — expected 160/40, got %/%', v_sl, v_su;
  END IF;
  IF v_rem <> 0 THEN
    RAISE EXCEPTION '% rows still NULL after backfill', v_rem;
  END IF;
  RAISE NOTICE 'Migration 619 complete: STATE_LOWER=%, STATE_UPPER=%', v_sl, v_su;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('619') ON CONFLICT DO NOTHING;

COMMIT;
