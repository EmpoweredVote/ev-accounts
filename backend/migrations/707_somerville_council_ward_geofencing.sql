-- Migration 707: Somerville City Council ward geofencing (MAGE-17)
--
-- Purpose: Upgrades Somerville from Tier 2 (citywide blob) to Tier 3 (per-ward
-- geofencing) for the 7 ward city council seats.
--
-- Requires: load-ma-ward-boundaries.ts --city SOMERVILLE --ward-count 7
--   must be run first (7 X0014 rows in essentials.geofence_boundaries).
--
-- Source: migrations 581 (somerville_city_government.sql) + 583 (somerville_headshots.sql)
--
-- Steps:
--   1. Insert 7 per-ward LOCAL district rows (geo_id='somerville-ma-council-ward-N')
--   2. Backfill tiger_geoid on 7 per-ward rows
--   3. Backfill tiger_geoid on citywide LOCAL row (geo_id='2562535') — no-op guard
--   4. Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2562535') — no-op guard
--   5. Re-link 7 ward councillors from citywide '2562535' LOCAL → per-ward LOCAL
--
-- Ward councillor → external_id mapping (from migrations 581 + 583):
--   Ward 1: Matthew McLaughlin       (-2562535006) → somerville-ma-council-ward-1
--   Ward 2: Jefferson Thomas Scott   (-2562535007) → somerville-ma-council-ward-2
--   Ward 3: Ben Ewen-Campen          (-2562535008) → somerville-ma-council-ward-3
--   Ward 4: Jesse Clingan            (-2562535009) → somerville-ma-council-ward-4
--   Ward 5: Naima Sait               (-2562535010) → somerville-ma-council-ward-5
--   Ward 6: Lance L. Davis           (-2562535011) → somerville-ma-council-ward-6
--   Ward 7: Emily Hardt              (-2562535012) → somerville-ma-council-ward-7
--
-- At-large councillors (NO re-link — keep at citywide '2562535' LOCAL):
--   Jon Link (-2562535002), Wilfred N. Mbah (-2562535003),
--   Kristen E. Strezo (-2562535004), Ben Wheeler (-2562535005)
-- Mayor Wilson (-2562535001) stays at citywide LOCAL_EXEC.
--
-- Post-verification gates:
--   Gate A: 7 per-ward rows with tiger_geoid IS NOT NULL
--   Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid IS NOT NULL
--   Gate C: 0 ward councillors still pointing to citywide '2562535' LOCAL
--   Gate D: 7 ward councillors pointing to per-ward rows
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight: Assert 7 X0014 somerville-ma-council-ward-* rows exist
-- Enforces that load-ma-ward-boundaries.ts ran before this migration.
-- T-119-M4: pre-flight RAISES EXCEPTION if geofence rows are missing.
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'somerville-ma-council-ward-%' AND mtfcc = 'X0014';

  IF v_count < 7 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected >= 7 X0014 somerville-ma-council-ward-* rows in geofence_boundaries, found %. Run: npx tsx scripts/load-ma-ward-boundaries.ts --city SOMERVILLE --ward-count 7', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 Somerville ward geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 7 per-ward LOCAL district rows
-- geo_id = 'somerville-ma-council-ward-{N}', mtfcc = 'X0014', state = 'ma'
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'somerville-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'somerville-ma-council-ward-2', 'Ward 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'somerville-ma-council-ward-3', 'Ward 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'somerville-ma-council-ward-4', 'Ward 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'somerville-ma-council-ward-5', 'Ward 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'somerville-ma-council-ward-6', 'Ward 6', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'somerville-ma-council-ward-7', 'Ward 7', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 2: Backfill tiger_geoid on 7 per-ward district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'somerville-ma-council-ward-1',
    'somerville-ma-council-ward-2',
    'somerville-ma-council-ward-3',
    'somerville-ma-council-ward-4',
    'somerville-ma-council-ward-5',
    'somerville-ma-council-ward-6',
    'somerville-ma-council-ward-7'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: Backfill tiger_geoid on citywide LOCAL row (geo_id='2562535')
-- No-op guard — migration 622 already set this. Included for safety.
-- Enables Path 0 for at-large councillors who remain at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2562535'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 4: Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2562535')
-- No-op guard — migration 622 already set this. Included for safety.
-- Enables Path 0 for Mayor Wilson who remains at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2562535'
  AND district_type = 'LOCAL_EXEC'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 5: Re-link 7 ward councillors from citywide '2562535' LOCAL → per-ward
-- Each UPDATE uses external_id + citywide LOCAL district_id guard
-- (natural no-op on second run).
-- T-119-M6: No SQL injection risk — external_ids are hardcoded constants.
-- =============================================================================

-- Ward 1: Matthew McLaughlin (-2562535006) → somerville-ma-council-ward-1
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2562535006
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2562535' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 2: Jefferson Thomas Scott (-2562535007) → somerville-ma-council-ward-2
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2562535007
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2562535' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 3: Ben Ewen-Campen (-2562535008) → somerville-ma-council-ward-3
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2562535008
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2562535' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 4: Jesse Clingan (-2562535009) → somerville-ma-council-ward-4
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2562535009
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2562535' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 5: Naima Sait (-2562535010) → somerville-ma-council-ward-5
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2562535010
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2562535' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 6: Lance L. Davis (-2562535011) → somerville-ma-council-ward-6
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2562535011
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2562535' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 7: Emily Hardt (-2562535012) → somerville-ma-council-ward-7
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'somerville-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2562535012
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2562535' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Post-verification: 4 gates
-- =============================================================================
DO $$
DECLARE
  v_ward_rows       INTEGER;
  v_citywide_rows   INTEGER;
  v_still_citywide  INTEGER;
  v_per_ward        INTEGER;
BEGIN
  -- Gate A: 7 per-ward rows with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_ward_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id IN (
      'somerville-ma-council-ward-1', 'somerville-ma-council-ward-2',
      'somerville-ma-council-ward-3', 'somerville-ma-council-ward-4',
      'somerville-ma-council-ward-5', 'somerville-ma-council-ward-6',
      'somerville-ma-council-ward-7'
    )
    AND tiger_geoid IS NOT NULL;

  IF v_ward_rows <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate A): expected 7 per-ward rows with tiger_geoid, found %', v_ward_rows;
  END IF;

  -- Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2562535') with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_citywide_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2562535'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NOT NULL;

  IF v_citywide_rows <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate B): expected 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid, found %', v_citywide_rows;
  END IF;

  -- Gate C: 0 ward councillors (ext_ids -2562535006..-2562535012) still pointing to citywide '2562535' LOCAL
  SELECT COUNT(*) INTO v_still_citywide
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-2562535006, -2562535007, -2562535008, -2562535009,
                          -2562535010, -2562535011, -2562535012)
    AND d.geo_id = '2562535'
    AND d.district_type = 'LOCAL';

  IF v_still_citywide <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate C): % ward councillors still point to citywide 2562535 LOCAL (expected 0)', v_still_citywide;
  END IF;

  -- Gate D: 7 ward councillors pointing to per-ward rows
  SELECT COUNT(*) INTO v_per_ward
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-2562535006, -2562535007, -2562535008, -2562535009,
                          -2562535010, -2562535011, -2562535012)
    AND d.geo_id LIKE 'somerville-ma-council-ward-%';

  IF v_per_ward <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate D): expected 7 ward councillors pointing to per-ward rows, found %', v_per_ward;
  END IF;

  RAISE NOTICE 'Migration 707 post-verification PASSED: ward_rows=%, citywide_rows=%, still_citywide=%, per_ward=%',
    v_ward_rows, v_citywide_rows, v_still_citywide, v_per_ward;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('707')
ON CONFLICT (version) DO NOTHING;

COMMIT;
