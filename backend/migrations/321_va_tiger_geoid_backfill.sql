-- Migration 321: tiger_geoid backfill for VA legislative districts
--
-- Populates tiger_geoid on essentials.districts for VA districts that have
-- TIGER boundary files: STATE_LOWER (100 delegates), STATE_UPPER (40 senators),
-- NATIONAL_LOWER (11 US House reps).
--
-- Pattern: tiger_geoid = geo_id (same value). Dual-column Path 0 join requires
-- both columns set. Mirrors CA backfill (CA STATE_LOWER×80, STATE_UPPER×40,
-- NATIONAL_LOWER×52 all follow the same pattern).
--
-- Scope: 151 rows
--   STATE_LOWER   × 100  state='va' geo_ids 51001–51100
--   STATE_UPPER   × 40   state='va' geo_ids 51001–51040
--   NATIONAL_LOWER × 11  state='VA' geo_ids 5101–5111
--
-- NOT backfilling: COUNTY, LOCAL, LOCAL_EXEC, SCHOOL, STATE_EXEC, NATIONAL_UPPER
-- (no TIGER boundary match needed for these types in the geofence router).
--
-- Idempotent: WHERE tiger_geoid IS NULL guard prevents double-apply.
-- Applied to production Supabase via Supabase MCP.

BEGIN;

UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'va'
  AND district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND tiger_geoid IS NULL;

UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'VA'
  AND district_type = 'NATIONAL_LOWER'
  AND tiger_geoid IS NULL;

DO $$
DECLARE
  v_sl  INT;
  v_su  INT;
  v_nl  INT;
  v_rem INT;
BEGIN
  SELECT COUNT(*) INTO v_sl  FROM essentials.districts WHERE state = 'va'  AND district_type = 'STATE_LOWER'    AND tiger_geoid IS NOT NULL;
  SELECT COUNT(*) INTO v_su  FROM essentials.districts WHERE state = 'va'  AND district_type = 'STATE_UPPER'    AND tiger_geoid IS NOT NULL;
  SELECT COUNT(*) INTO v_nl  FROM essentials.districts WHERE state = 'VA'  AND district_type = 'NATIONAL_LOWER' AND tiger_geoid IS NOT NULL;
  SELECT COUNT(*) INTO v_rem FROM essentials.districts WHERE state IN ('va','VA') AND district_type IN ('STATE_LOWER','STATE_UPPER','NATIONAL_LOWER') AND tiger_geoid IS NULL;

  RAISE NOTICE 'STATE_LOWER:    % / 100', v_sl;
  RAISE NOTICE 'STATE_UPPER:    % / 40',  v_su;
  RAISE NOTICE 'NATIONAL_LOWER: % / 11',  v_nl;

  IF v_sl <> 100 OR v_su <> 40 OR v_nl <> 11 THEN
    RAISE EXCEPTION 'Count mismatch — expected 100/40/11, got %/%/%', v_sl, v_su, v_nl;
  END IF;
  IF v_rem <> 0 THEN
    RAISE EXCEPTION '% rows still NULL after backfill', v_rem;
  END IF;
  RAISE NOTICE 'Migration 321 complete.';
END $$;

COMMIT;
