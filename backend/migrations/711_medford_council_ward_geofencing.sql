-- Migration 711: Medford City Council ward geofencing (MAGE-21)
--
-- Purpose: Inserts per-ward district rows and backfills tiger_geoid for Medford
-- ward boundary coverage. Medford is FULLY AT-LARGE (charter reform 2020) —
-- this migration does NOT re-link any offices. All 7 at-large councillors and
-- Mayor Lungo-Koehn remain on citywide districts.
--
-- Requires: load-ma-ward-boundaries.ts --city MEDFORD --ward-count 8
--   must be run first (8 X0014 rows in essentials.geofence_boundaries).
--
-- Source: migration 591 (medford_city_government.sql)
--
-- CRITICAL — Medford geo_id asymmetry:
--   Migration 591 seeded Medford with the wrong FIPS place code (2540115 = Melrose).
--   Migration 622 corrected the citywide district geo_id to '2539835' (correct Medford FIPS).
--   However, the external_id range for Medford politicians was NOT changed by migration 622:
--   external_ids remain -2540115001 through -2540115008 (the original encoding from migration 591).
--   This migration uses '2539835' as the citywide geo_id in ALL WHERE clauses.
--   External_id lookups (if needed) use -2540115001..-2540115008.
--
-- CRITICAL: Medford is fully at-large — NO office re-links.
--   All 7 councillors (-2540115002 through -2540115008) and Mayor Lungo-Koehn
--   (-2540115001) remain linked to the citywide LOCAL/LOCAL_EXEC rows (geo_id='2539835').
--   Per-ward district rows are created for boundary data completeness only,
--   enabling future ward-based display or potential structural changes.
--
-- Steps:
--   1. Insert 8 per-ward LOCAL district rows (geo_id='medford-ma-council-ward-N')
--   2. Backfill tiger_geoid on 8 per-ward rows
--   3. Backfill tiger_geoid on citywide LOCAL row (geo_id='2539835') — no-op guard
--   4. Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2539835') — no-op guard
--   [Step 5 OMITTED — Medford is fully at-large (charter reform 2020, migration 591).
--    All 7 at-large councillors (-2540115002..-2540115008) and Mayor Lungo-Koehn
--    (-2540115001) remain at citywide LOCAL/LOCAL_EXEC districts.]
--
-- Post-verification gates (2 only — no re-link gates):
--   Gate A: 8 per-ward rows with tiger_geoid IS NOT NULL
--   Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2539835') with tiger_geoid IS NOT NULL
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight: Assert 8 X0014 medford-ma-council-ward-* rows exist
-- Enforces that load-ma-ward-boundaries.ts ran before this migration.
-- T-119-M4: pre-flight RAISES EXCEPTION if geofence rows are missing.
-- CRITICAL: Use geo_id LIKE 'medford-ma-council-ward-%' (not '2540115' or '2539835').
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'medford-ma-council-ward-%' AND mtfcc = 'X0014';

  IF v_count < 8 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected >= 8 X0014 medford-ma-council-ward-* rows in geofence_boundaries, found %. Run: npx tsx scripts/load-ma-ward-boundaries.ts --city MEDFORD --ward-count 8', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 Medford ward geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 8 per-ward LOCAL district rows (for boundary coverage only)
-- Medford is at-large — NO office re-links will be done in this migration.
-- geo_id = 'medford-ma-council-ward-{N}', mtfcc = 'X0014', state = 'ma'
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'medford-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'medford-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'medford-ma-council-ward-2', 'Ward 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'medford-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'medford-ma-council-ward-3', 'Ward 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'medford-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'medford-ma-council-ward-4', 'Ward 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'medford-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'medford-ma-council-ward-5', 'Ward 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'medford-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'medford-ma-council-ward-6', 'Ward 6', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'medford-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'medford-ma-council-ward-7', 'Ward 7', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'medford-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'medford-ma-council-ward-8', 'Ward 8', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'medford-ma-council-ward-8' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 2: Backfill tiger_geoid on 8 per-ward district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'medford-ma-council-ward-1',
    'medford-ma-council-ward-2',
    'medford-ma-council-ward-3',
    'medford-ma-council-ward-4',
    'medford-ma-council-ward-5',
    'medford-ma-council-ward-6',
    'medford-ma-council-ward-7',
    'medford-ma-council-ward-8'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: Backfill tiger_geoid on citywide LOCAL row (geo_id='2539835')
-- CRITICAL: Use '2539835' (corrected by migration 622) — NOT '2540115'.
-- No-op guard — migration 622 already set this. Included for safety.
-- All 7 at-large councillors continue to resolve via this citywide row.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2539835'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 4: Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2539835')
-- CRITICAL: Use '2539835' (corrected by migration 622) — NOT '2540115'.
-- No-op guard — migration 622 already set this. Included for safety.
-- Mayor Lungo-Koehn continues to resolve via this citywide row.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2539835'
  AND district_type = 'LOCAL_EXEC'
  AND tiger_geoid IS NULL;

-- Step 5: OMITTED — Medford is fully at-large (charter reform 2020, migration 591).
-- All 7 at-large councillors (-2540115002..-2540115008) and Mayor Lungo-Koehn
-- (-2540115001) remain at citywide LOCAL/LOCAL_EXEC districts (geo_id='2539835').
-- No office re-links needed. At-large councillors resolve via tiger_geoid='2539835'
-- → G4110 citywide polygon.

-- =============================================================================
-- Post-verification: 2 gates (no Gate C/D — no office re-links for at-large city)
-- =============================================================================
DO $$
DECLARE
  v_ward_rows       INTEGER;
  v_citywide_rows   INTEGER;
BEGIN
  -- Gate A: 8 per-ward rows with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_ward_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id IN (
      'medford-ma-council-ward-1', 'medford-ma-council-ward-2',
      'medford-ma-council-ward-3', 'medford-ma-council-ward-4',
      'medford-ma-council-ward-5', 'medford-ma-council-ward-6',
      'medford-ma-council-ward-7', 'medford-ma-council-ward-8'
    )
    AND tiger_geoid IS NOT NULL;

  IF v_ward_rows <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate A): expected 8 per-ward rows with tiger_geoid, found %', v_ward_rows;
  END IF;

  -- Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2539835') with tiger_geoid IS NOT NULL
  -- CRITICAL: Use '2539835' (corrected FIPS) — NOT '2540115'.
  SELECT COUNT(*) INTO v_citywide_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2539835'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NOT NULL;

  IF v_citywide_rows <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate B): expected 2 citywide rows (LOCAL + LOCAL_EXEC geo_id=''2539835'') with tiger_geoid, found %', v_citywide_rows;
  END IF;

  RAISE NOTICE 'Migration 711 post-verification PASSED: ward_rows=%, citywide_rows=% (Medford at-large — no office re-link gates)',
    v_ward_rows, v_citywide_rows;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('711')
ON CONFLICT (version) DO NOTHING;

COMMIT;
