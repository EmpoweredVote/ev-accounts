-- Migration 709: Fall River City Council ward geofencing (MAGE-19)
--
-- Purpose: Inserts per-ward district rows and backfills tiger_geoid for Fall River
-- ward boundary coverage. Fall River is FULLY AT-LARGE — this migration does NOT
-- re-link any offices. All 9 at-large councillors and Mayor Coogan remain on
-- citywide districts.
--
-- Requires: load-ma-ward-boundaries.ts --city "FALL RIVER" --ward-count 9
--   must be run first (9 X0014 rows in essentials.geofence_boundaries).
--
-- Source: migration 590 (fall_river_city_government.sql)
--
-- CRITICAL: Fall River is fully at-large — NO office re-links.
--   All 9 councillors (-2523000002 through -2523000010) and Mayor Coogan
--   (-2523000001) remain linked to the citywide LOCAL/LOCAL_EXEC rows.
--   Per-ward district rows are created for boundary data completeness only,
--   enabling future ward-based display or potential structural changes.
--
-- Steps:
--   1. Insert 9 per-ward LOCAL district rows (geo_id='fall-river-ma-council-ward-N')
--   2. Backfill tiger_geoid on 9 per-ward rows
--   3. Backfill tiger_geoid on citywide LOCAL row (geo_id='2523000') — no-op guard
--   4. Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2523000') — no-op guard
--   [Step 5 OMITTED — Fall River is fully at-large. All 9 councillors
--    (ext_ids -2523000002..-2523000010) and Mayor Coogan (-2523000001) remain
--    at citywide LOCAL/LOCAL_EXEC districts.]
--
-- Post-verification gates (2 only — no re-link gates):
--   Gate A: 9 per-ward rows with tiger_geoid IS NOT NULL
--   Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid IS NOT NULL
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight: Assert 9 X0014 fall-river-ma-council-ward-* rows exist
-- Enforces that load-ma-ward-boundaries.ts ran before this migration.
-- T-119-M4: pre-flight RAISES EXCEPTION if geofence rows are missing.
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'fall-river-ma-council-ward-%' AND mtfcc = 'X0014';

  IF v_count < 9 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected >= 9 X0014 fall-river-ma-council-ward-* rows in geofence_boundaries, found %. Run: npx tsx scripts/load-ma-ward-boundaries.ts --city "FALL RIVER" --ward-count 9', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 Fall River ward geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 9 per-ward LOCAL district rows (for boundary coverage only)
-- Fall River is at-large — NO office re-links will be done in this migration.
-- geo_id = 'fall-river-ma-council-ward-{N}', mtfcc = 'X0014', state = 'ma'
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-2', 'Ward 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-3', 'Ward 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-4', 'Ward 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-5', 'Ward 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-6', 'Ward 6', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-7', 'Ward 7', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-8', 'Ward 8', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-8' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-9', 'Ward 9', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-9' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 2: Backfill tiger_geoid on 9 per-ward district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'fall-river-ma-council-ward-1',
    'fall-river-ma-council-ward-2',
    'fall-river-ma-council-ward-3',
    'fall-river-ma-council-ward-4',
    'fall-river-ma-council-ward-5',
    'fall-river-ma-council-ward-6',
    'fall-river-ma-council-ward-7',
    'fall-river-ma-council-ward-8',
    'fall-river-ma-council-ward-9'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: Backfill tiger_geoid on citywide LOCAL row (geo_id='2523000')
-- No-op guard — migration 622 already set this. Included for safety.
-- All 9 at-large councillors continue to resolve via this citywide row.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2523000'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 4: Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2523000')
-- No-op guard — migration 622 already set this. Included for safety.
-- Mayor Coogan continues to resolve via this citywide row.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2523000'
  AND district_type = 'LOCAL_EXEC'
  AND tiger_geoid IS NULL;

-- Step 5: OMITTED — Fall River is fully at-large. All 9 councillors
-- (ext_ids -2523000002..-2523000010) and Mayor Coogan (-2523000001) remain
-- at citywide LOCAL/LOCAL_EXEC districts. No office re-links needed.
-- At-large councillors resolve via tiger_geoid='2523000' → G4110 citywide polygon.

-- =============================================================================
-- Post-verification: 2 gates (no Gate C/D — no office re-links for at-large city)
-- =============================================================================
DO $$
DECLARE
  v_ward_rows       INTEGER;
  v_citywide_rows   INTEGER;
BEGIN
  -- Gate A: 9 per-ward rows with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_ward_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id IN (
      'fall-river-ma-council-ward-1', 'fall-river-ma-council-ward-2',
      'fall-river-ma-council-ward-3', 'fall-river-ma-council-ward-4',
      'fall-river-ma-council-ward-5', 'fall-river-ma-council-ward-6',
      'fall-river-ma-council-ward-7', 'fall-river-ma-council-ward-8',
      'fall-river-ma-council-ward-9'
    )
    AND tiger_geoid IS NOT NULL;

  IF v_ward_rows <> 9 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate A): expected 9 per-ward rows with tiger_geoid, found %', v_ward_rows;
  END IF;

  -- Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2523000') with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_citywide_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2523000'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NOT NULL;

  IF v_citywide_rows <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate B): expected 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid, found %', v_citywide_rows;
  END IF;

  RAISE NOTICE 'Migration 709 post-verification PASSED: ward_rows=%, citywide_rows=% (Fall River at-large — no office re-link gates)',
    v_ward_rows, v_citywide_rows;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('709')
ON CONFLICT (version) DO NOTHING;

COMMIT;
