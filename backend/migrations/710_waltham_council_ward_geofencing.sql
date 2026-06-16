-- Migration 710: Waltham City Council ward geofencing (MAGE-20)
--
-- Purpose: Upgrades Waltham from Tier 2 (citywide blob) to Tier 3 (per-ward
-- geofencing) for the 9 ward city council seats.
--
-- Requires: load-ma-ward-boundaries.ts --city WALTHAM --ward-count 9
--   must be run first (9 X0014 rows in essentials.geofence_boundaries).
--
-- Source: migrations 592 + 596 (waltham_city_government.sql + waltham_headshots.sql)
--
-- Steps:
--   1. Insert 9 per-ward LOCAL district rows (geo_id='waltham-ma-council-ward-N')
--   2. Backfill tiger_geoid on 9 per-ward rows
--   3. Backfill tiger_geoid on citywide LOCAL row (geo_id='2572600') — no-op guard
--   4. Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2572600') — no-op guard
--   5. Re-link 9 ward councillors from citywide '2572600' LOCAL → per-ward LOCAL
--
-- NOTE: Waltham uses 'City Councillor' (double-L British spelling). However,
--   all lookups in this migration use external_id — title strings are not referenced.
--
-- Ward councillor → external_id mapping (from migrations 592 + 596, sequential):
--   Ward 1: Anthony LaFauci       (-2572600008) → waltham-ma-council-ward-1
--   Ward 2: Caren Dunn            (-2572600009) → waltham-ma-council-ward-2
--   Ward 3: Bill Hanley           (-2572600010) → waltham-ma-council-ward-3
--   Ward 4: John J. McLaughlin    (-2572600011) → waltham-ma-council-ward-4
--   Ward 5: Joseph P. LaCava      (-2572600012) → waltham-ma-council-ward-5
--   Ward 6: Sean Durkee           (-2572600013) → waltham-ma-council-ward-6
--   Ward 7: Paul S. Katz          (-2572600014) → waltham-ma-council-ward-7
--   Ward 8: Cathyann Harris       (-2572600015) → waltham-ma-council-ward-8
--   Ward 9: Robert G. Logan       (-2572600016) → waltham-ma-council-ward-9  (Council President — title unchanged)
--
-- At-large councillors (NO re-link — keep at citywide '2572600' LOCAL):
--   -2572600002 (Bradley-MacArthur) through -2572600007 (Vidal) — 6 at-large councillors
-- Mayor Donahue (-2572600001) stays at citywide LOCAL_EXEC.
--
-- Post-verification gates:
--   Gate A: 9 per-ward rows with tiger_geoid IS NOT NULL
--   Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2572600') with tiger_geoid IS NOT NULL
--   Gate C: 0 ward councillors (ext_ids -2572600008..-2572600016) still pointing to citywide '2572600' LOCAL
--   Gate D: 9 ward councillors pointing to per-ward rows
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight: Assert 9 X0014 waltham-ma-council-ward-* rows exist
-- Enforces that load-ma-ward-boundaries.ts ran before this migration.
-- T-119-M4: pre-flight RAISES EXCEPTION if geofence rows are missing.
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'waltham-ma-council-ward-%' AND mtfcc = 'X0014';

  IF v_count < 9 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected >= 9 X0014 waltham-ma-council-ward-* rows in geofence_boundaries, found %. Run: npx tsx scripts/load-ma-ward-boundaries.ts --city WALTHAM --ward-count 9', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 Waltham ward geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 9 per-ward LOCAL district rows
-- geo_id = 'waltham-ma-council-ward-{N}', mtfcc = 'X0014', state = 'ma'
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'waltham-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'waltham-ma-council-ward-2', 'Ward 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'waltham-ma-council-ward-3', 'Ward 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'waltham-ma-council-ward-4', 'Ward 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'waltham-ma-council-ward-5', 'Ward 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'waltham-ma-council-ward-6', 'Ward 6', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'waltham-ma-council-ward-7', 'Ward 7', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'waltham-ma-council-ward-8', 'Ward 8', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-8' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'waltham-ma-council-ward-9', 'Ward 9', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-9' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 2: Backfill tiger_geoid on 9 per-ward district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'waltham-ma-council-ward-1',
    'waltham-ma-council-ward-2',
    'waltham-ma-council-ward-3',
    'waltham-ma-council-ward-4',
    'waltham-ma-council-ward-5',
    'waltham-ma-council-ward-6',
    'waltham-ma-council-ward-7',
    'waltham-ma-council-ward-8',
    'waltham-ma-council-ward-9'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: Backfill tiger_geoid on citywide LOCAL row (geo_id='2572600')
-- No-op guard — migration 622 already set this. Included for safety.
-- Enables Path 0 for at-large councillors who remain at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2572600'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 4: Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2572600')
-- No-op guard — migration 622 already set this. Included for safety.
-- Enables Path 0 for Mayor Donahue who remains at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2572600'
  AND district_type = 'LOCAL_EXEC'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 5: Re-link 9 ward councillors from citywide '2572600' LOCAL → per-ward
-- Ward councillors are sequential by ward number (unlike Newton which is non-sequential).
-- Each UPDATE uses external_id + citywide '2572600' LOCAL district_id guard
-- (natural no-op on second run).
-- T-119-M6: No SQL injection risk — external_ids are hardcoded constants.
-- =============================================================================

-- Ward 1: Anthony LaFauci (-2572600008) → waltham-ma-council-ward-1
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2572600008
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 2: Caren Dunn (-2572600009) → waltham-ma-council-ward-2
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2572600009
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 3: Bill Hanley (-2572600010) → waltham-ma-council-ward-3
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2572600010
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 4: John J. McLaughlin (-2572600011) → waltham-ma-council-ward-4
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2572600011
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 5: Joseph P. LaCava (-2572600012) → waltham-ma-council-ward-5
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2572600012
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 6: Sean Durkee (-2572600013) → waltham-ma-council-ward-6
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2572600013
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 7: Paul S. Katz (-2572600014) → waltham-ma-council-ward-7
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2572600014
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 8: Cathyann Harris (-2572600015) → waltham-ma-council-ward-8
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-8' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2572600015
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 9: Robert G. Logan (-2572600016) → waltham-ma-council-ward-9  (Council President — title unchanged)
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'waltham-ma-council-ward-9' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2572600016
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2572600' AND district_type = 'LOCAL' AND state = 'ma'
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
  -- Gate A: 9 per-ward rows with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_ward_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id IN (
      'waltham-ma-council-ward-1', 'waltham-ma-council-ward-2',
      'waltham-ma-council-ward-3', 'waltham-ma-council-ward-4',
      'waltham-ma-council-ward-5', 'waltham-ma-council-ward-6',
      'waltham-ma-council-ward-7', 'waltham-ma-council-ward-8',
      'waltham-ma-council-ward-9'
    )
    AND tiger_geoid IS NOT NULL;

  IF v_ward_rows <> 9 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate A): expected 9 per-ward rows with tiger_geoid, found %', v_ward_rows;
  END IF;

  -- Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2572600') with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_citywide_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2572600'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NOT NULL;

  IF v_citywide_rows <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate B): expected 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid, found %', v_citywide_rows;
  END IF;

  -- Gate C: 0 ward councillors (ext_ids -2572600008..-2572600016) still pointing to citywide '2572600' LOCAL
  SELECT COUNT(*) INTO v_still_citywide
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-2572600008, -2572600009, -2572600010, -2572600011, -2572600012,
                          -2572600013, -2572600014, -2572600015, -2572600016)
    AND d.geo_id = '2572600'
    AND d.district_type = 'LOCAL';

  IF v_still_citywide <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate C): % ward councillors still point to citywide 2572600 LOCAL (expected 0)', v_still_citywide;
  END IF;

  -- Gate D: 9 ward councillors pointing to per-ward rows
  SELECT COUNT(*) INTO v_per_ward
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-2572600008, -2572600009, -2572600010, -2572600011, -2572600012,
                          -2572600013, -2572600014, -2572600015, -2572600016)
    AND d.geo_id LIKE 'waltham-ma-council-ward-%';

  IF v_per_ward <> 9 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate D): expected 9 ward councillors pointing to per-ward rows, found %', v_per_ward;
  END IF;

  RAISE NOTICE 'Migration 710 post-verification PASSED: ward_rows=%, citywide_rows=%, still_citywide=%, per_ward=%',
    v_ward_rows, v_citywide_rows, v_still_citywide, v_per_ward;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('710')
ON CONFLICT (version) DO NOTHING;

COMMIT;
