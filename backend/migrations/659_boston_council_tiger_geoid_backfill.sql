-- Migration 659: Boston City Council tiger_geoid backfill
--
-- Purpose: Set tiger_geoid on all 11 Boston district rows so Path 0 geofencing works
-- for Boston city council seats.
--
-- Boston is already at Tier 3 geometry (per-district X0013 polygons loaded by
-- load-boston-council-boundaries.ts in migration 347), but the tiger_geoid column
-- was never set on essentials.districts, breaking the Path 0 join:
--   JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
--
-- Scope: 11 rows total
--   - 9 LOCAL per-district rows (geo_id = 'boston-ma-council-district-1' through '-9', mtfcc='X0013')
--   - 1 LOCAL citywide row (geo_id='2507000', mtfcc=NULL — at-large councillors)
--   - 1 LOCAL_EXEC citywide row (geo_id='2507000', mtfcc=NULL — Mayor Wu)
--
-- Pattern: tiger_geoid = geo_id (same pattern as migrations 619, 622)
-- Idempotent: all UPDATEs guarded by AND tiger_geoid IS NULL
-- Applied to production Supabase via execute_sql (not apply_migration — avoids ledger duplication bug)

-- =============================================================================
-- Pre-flight: Assert 9 X0013 geofence_boundaries rows exist before updating
-- Prevents UPDATE against wrong/missing geofence data (T-119-01)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'boston-ma-council-district-%'
    AND mtfcc = 'X0013';

  IF v_count <> 9 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 9 X0013 boston-ma-council-district-* rows in geofence_boundaries, found %. Run load-boston-council-boundaries.ts first.', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0013 boston council district geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step A: Backfill tiger_geoid on 9 per-district LOCAL rows (X0013)
-- tiger_geoid = geo_id (e.g. 'boston-ma-council-district-1')
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0013')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type = 'LOCAL'
  AND geo_id LIKE 'boston-ma-council-district-%'
  AND mtfcc = 'X0013'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step B: Backfill tiger_geoid on citywide LOCAL row (at-large councillors)
-- geo_id='2507000' matches G4110 geofence already loaded from Phase 38 TIGER import
-- tiger_geoid='2507000' enables Path 0 for at-large council seats via citywide polygon
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type = 'LOCAL'
  AND geo_id = '2507000'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step C: Backfill tiger_geoid on citywide LOCAL_EXEC row (Mayor Wu)
-- geo_id='2507000' same G4110 citywide polygon
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type = 'LOCAL_EXEC'
  AND geo_id = '2507000'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Post-verification: Assert all 11 rows have tiger_geoid set
-- =============================================================================
DO $$
DECLARE
  v_district_count     INTEGER;
  v_local_citywide     INTEGER;
  v_exec_citywide      INTEGER;
  v_null_remaining     INTEGER;
BEGIN
  -- Gate 1: 9 per-district X0013 rows have tiger_geoid
  SELECT COUNT(*) INTO v_district_count
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id LIKE 'boston-ma-council-district-%'
    AND mtfcc = 'X0013'
    AND tiger_geoid IS NOT NULL;

  IF v_district_count <> 9 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 9 per-district rows with tiger_geoid set, found %', v_district_count;
  END IF;

  -- Gate 2: Citywide LOCAL row has tiger_geoid='2507000'
  SELECT COUNT(*) INTO v_local_citywide
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2507000'
    AND district_type = 'LOCAL'
    AND tiger_geoid IS NOT NULL;

  IF v_local_citywide <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 LOCAL citywide row (geo_id=2507000) with tiger_geoid set, found %', v_local_citywide;
  END IF;

  -- Gate 3: Citywide LOCAL_EXEC row has tiger_geoid='2507000'
  SELECT COUNT(*) INTO v_exec_citywide
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2507000'
    AND district_type = 'LOCAL_EXEC'
    AND tiger_geoid IS NOT NULL;

  IF v_exec_citywide <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 LOCAL_EXEC citywide row (geo_id=2507000) with tiger_geoid set, found %', v_exec_citywide;
  END IF;

  -- Gate 4: Zero NULL tiger_geoid rows for the 9 per-district slugs
  SELECT COUNT(*) INTO v_null_remaining
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id LIKE 'boston-ma-council-district-%'
    AND tiger_geoid IS NULL;

  IF v_null_remaining <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % boston-ma-council-district-* rows still have NULL tiger_geoid', v_null_remaining;
  END IF;

  RAISE NOTICE 'Migration 659 post-verification PASSED: per_district_rows=% / 9, local_citywide=% / 1, exec_citywide=% / 1, null_remaining=%',
    v_district_count, v_local_citywide, v_exec_citywide, v_null_remaining;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('659')
ON CONFLICT (version) DO NOTHING;

COMMIT;
