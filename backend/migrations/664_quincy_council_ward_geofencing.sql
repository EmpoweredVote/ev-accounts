-- Migration 664: Quincy City Council ward geofencing (MAGE-15)
--
-- Purpose: Upgrades Quincy from Tier 2 (citywide blob) to Tier 3 (per-ward
-- geofencing) for the 6 ward city council seats.
--
-- Requires: load-ma-ward-boundaries.ts --city QUINCY --ward-count 6
--   must be run first (6 X0014 rows in essentials.geofence_boundaries).
--
-- CRITICAL (T-119-M6): Quincy geo_id is '2555745' (non-round FIPS). This exact
-- string must be used in ALL WHERE clauses referencing the citywide district rows.
-- Do NOT use '2555000' or any other approximate value.
--
-- Steps:
--   1. Insert 6 per-ward LOCAL district rows (geo_id='quincy-ma-council-ward-N')
--   2. Backfill tiger_geoid on 6 per-ward rows
--   3. Backfill tiger_geoid on citywide LOCAL row (geo_id='2555745') — at-large councillors
--   4. Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2555745') — Mayor Koch
--   5. Re-link 6 ward councillors from citywide '2555745' LOCAL → per-ward LOCAL
--
-- Ward councillor → external_id mapping (from migration 355):
--   Ward 1: David Jacobs (-255574502)
--   Ward 2: Richard Ash (-255574503)
--   Ward 3: Walter Hubley (-255574504)
--   Ward 4: Virginia Ryan (-255574505)
--   Ward 5: Maggie McKee (-255574506)
--   Ward 6: Deborah Riley (-255574507)
--
-- At-large councillors (NO re-link — keep at citywide '2555745' LOCAL):
--   DiBona (-255574508), Mahoney (-255574509), Yuan (-255574510)
-- Mayor Koch (-255574501) stays at citywide LOCAL_EXEC.
--
-- Post-verification gates:
--   Gate A: 6 per-ward rows with tiger_geoid IS NOT NULL
--   Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid='2555745' IS NOT NULL
--   Gate C: 0 ward councillors still pointing to citywide '2555745' LOCAL
--   Gate D: 6 ward councillors pointing to per-ward rows
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight: Assert 6 X0014 quincy-ma-council-ward-* rows exist
-- Enforces that load-ma-ward-boundaries.ts ran before this migration.
-- T-119-M4: pre-flight RAISES EXCEPTION if geofence rows are missing.
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'quincy-ma-council-ward-%' AND mtfcc = 'X0014';

  IF v_count < 6 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected >= 6 X0014 quincy-ma-council-ward-* rows in geofence_boundaries, found %. Run: npx tsx scripts/load-ma-ward-boundaries.ts --city QUINCY --ward-count 6', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 Quincy ward geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 6 per-ward LOCAL district rows
-- geo_id = 'quincy-ma-council-ward-{N}', mtfcc = 'X0014', state = 'ma'
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'quincy-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'quincy-ma-council-ward-2', 'Ward 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'quincy-ma-council-ward-3', 'Ward 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'quincy-ma-council-ward-4', 'Ward 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'quincy-ma-council-ward-5', 'Ward 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'quincy-ma-council-ward-6', 'Ward 6', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 2: Backfill tiger_geoid on 6 per-ward district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'quincy-ma-council-ward-1',
    'quincy-ma-council-ward-2',
    'quincy-ma-council-ward-3',
    'quincy-ma-council-ward-4',
    'quincy-ma-council-ward-5',
    'quincy-ma-council-ward-6'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: Backfill tiger_geoid on citywide LOCAL row (geo_id='2555745')
-- CRITICAL (T-119-M6): '2555745' is a non-round FIPS — use exact string.
-- Enables Path 0 for at-large councillors (DiBona/Mahoney/Yuan)
-- who remain at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2555745'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 4: Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2555745')
-- CRITICAL (T-119-M6): '2555745' exact string required — non-round FIPS.
-- Enables Path 0 for Mayor Koch who remains at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2555745'
  AND district_type = 'LOCAL_EXEC'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 5: Re-link 6 ward councillors from citywide '2555745' LOCAL → per-ward
-- CRITICAL (T-119-M6): '2555745' exact string in ALL WHERE clauses.
-- Each UPDATE uses external_id (precise politician identifier) + citywide LOCAL
-- district_id guard (natural no-op on second run — Pitfall 6 prevention).
-- =============================================================================

-- Ward 1: David Jacobs (-255574502) → quincy-ma-council-ward-1
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -255574502
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2555745' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 2: Richard Ash (-255574503) → quincy-ma-council-ward-2
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -255574503
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2555745' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 3: Walter Hubley (-255574504) → quincy-ma-council-ward-3
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -255574504
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2555745' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 4: Virginia Ryan (-255574505) → quincy-ma-council-ward-4
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -255574505
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2555745' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 5: Maggie McKee (-255574506) → quincy-ma-council-ward-5
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -255574506
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2555745' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 6: Deborah Riley (-255574507) → quincy-ma-council-ward-6
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'quincy-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -255574507
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2555745' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Post-verification: 4 gates
-- CRITICAL (T-119-M6): All geo_id='2555745' references use exact non-round FIPS.
-- =============================================================================
DO $$
DECLARE
  v_ward_rows       INTEGER;
  v_citywide_rows   INTEGER;
  v_still_citywide  INTEGER;
  v_per_ward        INTEGER;
BEGIN
  -- Gate A: 6 per-ward rows with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_ward_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id IN (
      'quincy-ma-council-ward-1', 'quincy-ma-council-ward-2',
      'quincy-ma-council-ward-3', 'quincy-ma-council-ward-4',
      'quincy-ma-council-ward-5', 'quincy-ma-council-ward-6'
    )
    AND tiger_geoid IS NOT NULL;

  IF v_ward_rows <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate A): expected 6 per-ward rows with tiger_geoid, found %', v_ward_rows;
  END IF;

  -- Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2555745') with tiger_geoid IS NOT NULL
  -- CRITICAL (T-119-M6): '2555745' exact string — non-round Quincy FIPS.
  SELECT COUNT(*) INTO v_citywide_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2555745'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NOT NULL;

  IF v_citywide_rows <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate B): expected 2 citywide rows (LOCAL + LOCAL_EXEC, geo_id=2555745) with tiger_geoid, found %', v_citywide_rows;
  END IF;

  -- Gate C: 0 ward councillors (ext_ids -255574502..-255574507) still pointing to citywide '2555745' LOCAL
  -- CRITICAL (T-119-M6): '2555745' exact string.
  SELECT COUNT(*) INTO v_still_citywide
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-255574502, -255574503, -255574504,
                          -255574505, -255574506, -255574507)
    AND d.geo_id = '2555745'
    AND d.district_type = 'LOCAL';

  IF v_still_citywide <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate C): % ward councillors still point to citywide 2555745 LOCAL (expected 0)', v_still_citywide;
  END IF;

  -- Gate D: 6 ward councillors pointing to per-ward rows
  SELECT COUNT(*) INTO v_per_ward
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-255574502, -255574503, -255574504,
                          -255574505, -255574506, -255574507)
    AND d.geo_id LIKE 'quincy-ma-council-ward-%';

  IF v_per_ward <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate D): expected 6 ward councillors pointing to per-ward rows, found %', v_per_ward;
  END IF;

  RAISE NOTICE 'Migration 664 post-verification PASSED: ward_rows=%, citywide_rows=%, still_citywide=%, per_ward=%',
    v_ward_rows, v_citywide_rows, v_still_citywide, v_per_ward;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('664')
ON CONFLICT (version) DO NOTHING;

COMMIT;
