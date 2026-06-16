-- Migration 706: Newton City Council ward geofencing (MAGE-16)
--
-- Purpose: Upgrades Newton from Tier 2 (citywide blob) to Tier 3 (per-ward
-- geofencing) for the 8 ward city council seats.
--
-- Requires: load-ma-ward-boundaries.ts --city NEWTON --ward-count 8
--   must be run first (8 X0014 rows in essentials.geofence_boundaries).
--
-- Source: migration 578 (newton_city_government.sql)
--
-- Steps:
--   1. Insert 8 per-ward LOCAL district rows (geo_id='newton-ma-council-ward-N')
--   2. Backfill tiger_geoid on 8 per-ward rows
--   3. Backfill tiger_geoid on citywide LOCAL row (geo_id='2545560') — no-op guard
--   4. Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2545560') — no-op guard
--   5. Re-link 8 ward councillors from citywide '2545560' LOCAL → per-ward LOCAL
--
-- CRITICAL (Pitfall 3): Newton ward councillors are NOT sequential by ward number.
-- Exact external_id → ward mapping (from migration 578, non-sequential insertion order):
--   Ward 1: Maria S. Greenberg   (-2545560022) → newton-ma-council-ward-1
--   Ward 2: David Micley          (-2545560025) → newton-ma-council-ward-2
--   Ward 3: Julia Malakie         (-2545560024) → newton-ma-council-ward-3
--   Ward 4: Randy Block           (-2545560020) → newton-ma-council-ward-4
--   Ward 5: Julie Irish           (-2545560023) → newton-ma-council-ward-5
--   Ward 6: Martha Bixby          (-2545560019) → newton-ma-council-ward-6
--   Ward 7: R. Lisle Baker        (-2545560018) → newton-ma-council-ward-7
--   Ward 8: Stephen Farrell       (-2545560021) → newton-ma-council-ward-8
--
-- At-large councillors (NO re-link — keep at citywide '2545560' LOCAL):
--   -2545560002 through -2545560017 (16 at-large councillors)
-- Mayor Laredo (-2545560001) stays at citywide LOCAL_EXEC.
--
-- Post-verification gates:
--   Gate A: 8 per-ward rows with tiger_geoid IS NOT NULL
--   Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid IS NOT NULL
--   Gate C: 0 ward councillors still pointing to citywide '2545560' LOCAL
--   Gate D: 8 ward councillors pointing to per-ward rows
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight: Assert 8 X0014 newton-ma-council-ward-* rows exist
-- Enforces that load-ma-ward-boundaries.ts ran before this migration.
-- T-119-M4: pre-flight RAISES EXCEPTION if geofence rows are missing.
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'newton-ma-council-ward-%' AND mtfcc = 'X0014';

  IF v_count < 8 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected >= 8 X0014 newton-ma-council-ward-* rows in geofence_boundaries, found %. Run: npx tsx scripts/load-ma-ward-boundaries.ts --city NEWTON --ward-count 8', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 Newton ward geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 8 per-ward LOCAL district rows
-- geo_id = 'newton-ma-council-ward-{N}', mtfcc = 'X0014', state = 'ma'
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'newton-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'newton-ma-council-ward-2', 'Ward 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'newton-ma-council-ward-3', 'Ward 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'newton-ma-council-ward-4', 'Ward 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'newton-ma-council-ward-5', 'Ward 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'newton-ma-council-ward-6', 'Ward 6', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'newton-ma-council-ward-7', 'Ward 7', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'newton-ma-council-ward-8', 'Ward 8', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-8' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 2: Backfill tiger_geoid on 8 per-ward district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'newton-ma-council-ward-1',
    'newton-ma-council-ward-2',
    'newton-ma-council-ward-3',
    'newton-ma-council-ward-4',
    'newton-ma-council-ward-5',
    'newton-ma-council-ward-6',
    'newton-ma-council-ward-7',
    'newton-ma-council-ward-8'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: Backfill tiger_geoid on citywide LOCAL row (geo_id='2545560')
-- No-op guard — migration 699 already set this. Included for safety.
-- Enables Path 0 for at-large councillors who remain at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2545560'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 4: Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2545560')
-- No-op guard — migration 699 already set this. Included for safety.
-- Enables Path 0 for Mayor Laredo who remains at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2545560'
  AND district_type = 'LOCAL_EXEC'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 5: Re-link 8 ward councillors from citywide '2545560' LOCAL → per-ward
-- CRITICAL: Newton mapping is non-sequential (Pitfall 3) — use exact mapping
-- from migration 578. Each UPDATE uses external_id + citywide LOCAL district_id
-- guard (natural no-op on second run).
-- T-119-M6: No SQL injection risk — external_ids are hardcoded constants.
-- =============================================================================

-- Ward 1: Maria S. Greenberg (-2545560022) → newton-ma-council-ward-1
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545560022
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545560' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 2: David Micley (-2545560025) → newton-ma-council-ward-2
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545560025
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545560' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 3: Julia Malakie (-2545560024) → newton-ma-council-ward-3
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545560024
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545560' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 4: Randy Block (-2545560020) → newton-ma-council-ward-4
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545560020
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545560' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 5: Julie Irish (-2545560023) → newton-ma-council-ward-5
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545560023
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545560' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 6: Martha Bixby (-2545560019) → newton-ma-council-ward-6
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545560019
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545560' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 7: R. Lisle Baker (-2545560018) → newton-ma-council-ward-7
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545560018
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545560' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 8: Stephen Farrell (-2545560021) → newton-ma-council-ward-8
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-8' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545560021
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545560' AND district_type = 'LOCAL' AND state = 'ma'
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
  -- Gate A: 8 per-ward rows with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_ward_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id IN (
      'newton-ma-council-ward-1', 'newton-ma-council-ward-2',
      'newton-ma-council-ward-3', 'newton-ma-council-ward-4',
      'newton-ma-council-ward-5', 'newton-ma-council-ward-6',
      'newton-ma-council-ward-7', 'newton-ma-council-ward-8'
    )
    AND tiger_geoid IS NOT NULL;

  IF v_ward_rows <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate A): expected 8 per-ward rows with tiger_geoid, found %', v_ward_rows;
  END IF;

  -- Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2545560') with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_citywide_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2545560'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NOT NULL;

  IF v_citywide_rows <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate B): expected 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid, found %', v_citywide_rows;
  END IF;

  -- Gate C: 0 ward councillors (ext_ids -2545560018..-2545560025) still pointing to citywide '2545560' LOCAL
  SELECT COUNT(*) INTO v_still_citywide
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-2545560018, -2545560019, -2545560020, -2545560021,
                          -2545560022, -2545560023, -2545560024, -2545560025)
    AND d.geo_id = '2545560'
    AND d.district_type = 'LOCAL';

  IF v_still_citywide <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate C): % ward councillors still point to citywide 2545560 LOCAL (expected 0)', v_still_citywide;
  END IF;

  -- Gate D: 8 ward councillors pointing to per-ward rows
  SELECT COUNT(*) INTO v_per_ward
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-2545560018, -2545560019, -2545560020, -2545560021,
                          -2545560022, -2545560023, -2545560024, -2545560025)
    AND d.geo_id LIKE 'newton-ma-council-ward-%';

  IF v_per_ward <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate D): expected 8 ward councillors pointing to per-ward rows, found %', v_per_ward;
  END IF;

  RAISE NOTICE 'Migration 706 post-verification PASSED: ward_rows=%, citywide_rows=%, still_citywide=%, per_ward=%',
    v_ward_rows, v_citywide_rows, v_still_citywide, v_per_ward;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('706')
ON CONFLICT (version) DO NOTHING;

COMMIT;
