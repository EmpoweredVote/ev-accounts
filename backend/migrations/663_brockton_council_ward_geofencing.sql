-- Migration 663: Brockton City Council ward geofencing (MAGE-14)
--
-- Purpose: Upgrades Brockton from Tier 2 (citywide blob) to Tier 3 (per-ward
-- geofencing) for the 7 ward city council seats.
--
-- Requires: load-ma-ward-boundaries.ts --city BROCKTON --ward-count 7
--   must be run first (7 X0014 rows in essentials.geofence_boundaries).
--
-- Steps:
--   1. Insert 7 per-ward LOCAL district rows (geo_id='brockton-ma-council-ward-N')
--   2. Backfill tiger_geoid on 7 per-ward rows
--   3. Backfill tiger_geoid on citywide LOCAL row (geo_id='2509000') — at-large councillors
--   4. Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2509000') — Mayor Rodrigues
--   5. Re-link 7 ward councillors from citywide '2509000' LOCAL → per-ward LOCAL
--
-- Ward councillor → external_id mapping (from migration 354):
--   Ward 1: Marlon D. Green (-250900002)
--   Ward 2: Maria T. Tavares (-250900003)
--   Ward 3: Philip E. Griffin (-250900004)
--   Ward 4: Susan Nicastro (-250900005)
--   Ward 5: Jeffrey A. Thompson (-250900006)
--   Ward 6: John Lally (-250900007)
--   Ward 7: Shirley Asack (-250900008)
--
-- At-large councillors (NO re-link — keep at citywide '2509000' LOCAL):
--   Darosa (-250900009), Charnel (-250900010), Farwell (-250900011), Teixeira (-250900012)
-- Mayor Rodrigues (-250900001) stays at citywide LOCAL_EXEC.
--
-- Post-verification gates:
--   Gate A: 7 per-ward rows with tiger_geoid IS NOT NULL
--   Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid IS NOT NULL
--   Gate C: 0 ward councillors still pointing to citywide '2509000' LOCAL
--   Gate D: 7 ward councillors pointing to per-ward rows
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight: Assert 7 X0014 brockton-ma-council-ward-* rows exist
-- Enforces that load-ma-ward-boundaries.ts ran before this migration.
-- T-119-M4: pre-flight RAISES EXCEPTION if geofence rows are missing.
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'brockton-ma-council-ward-%' AND mtfcc = 'X0014';

  IF v_count < 7 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected >= 7 X0014 brockton-ma-council-ward-* rows in geofence_boundaries, found %. Run: npx tsx scripts/load-ma-ward-boundaries.ts --city BROCKTON --ward-count 7', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 Brockton ward geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 7 per-ward LOCAL district rows
-- geo_id = 'brockton-ma-council-ward-{N}', mtfcc = 'X0014', state = 'ma'
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'brockton-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'brockton-ma-council-ward-2', 'Ward 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'brockton-ma-council-ward-3', 'Ward 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'brockton-ma-council-ward-4', 'Ward 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'brockton-ma-council-ward-5', 'Ward 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'brockton-ma-council-ward-6', 'Ward 6', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'brockton-ma-council-ward-7', 'Ward 7', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 2: Backfill tiger_geoid on 7 per-ward district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'brockton-ma-council-ward-1',
    'brockton-ma-council-ward-2',
    'brockton-ma-council-ward-3',
    'brockton-ma-council-ward-4',
    'brockton-ma-council-ward-5',
    'brockton-ma-council-ward-6',
    'brockton-ma-council-ward-7'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: Backfill tiger_geoid on citywide LOCAL row (geo_id='2509000')
-- Enables Path 0 for at-large councillors (Darosa/Charnel/Farwell/Teixeira)
-- who remain at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2509000'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 4: Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2509000')
-- Enables Path 0 for Mayor Rodrigues who remains at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2509000'
  AND district_type = 'LOCAL_EXEC'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 5: Re-link 7 ward councillors from citywide '2509000' LOCAL → per-ward
-- Each UPDATE uses external_id (precise politician identifier) + citywide LOCAL
-- district_id guard (natural no-op on second run — Pitfall 6 prevention).
-- =============================================================================

-- Ward 1: Marlon D. Green (-250900002) → brockton-ma-council-ward-1
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -250900002
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2509000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 2: Maria T. Tavares (-250900003) → brockton-ma-council-ward-2
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -250900003
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2509000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 3: Philip E. Griffin (-250900004) → brockton-ma-council-ward-3
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -250900004
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2509000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 4: Susan Nicastro (-250900005) → brockton-ma-council-ward-4
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -250900005
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2509000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 5: Jeffrey A. Thompson (-250900006) → brockton-ma-council-ward-5
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -250900006
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2509000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 6: John Lally (-250900007) → brockton-ma-council-ward-6
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -250900007
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2509000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 7: Shirley Asack (-250900008) → brockton-ma-council-ward-7
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'brockton-ma-council-ward-7' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -250900008
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2509000' AND district_type = 'LOCAL' AND state = 'ma'
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
      'brockton-ma-council-ward-1', 'brockton-ma-council-ward-2',
      'brockton-ma-council-ward-3', 'brockton-ma-council-ward-4',
      'brockton-ma-council-ward-5', 'brockton-ma-council-ward-6',
      'brockton-ma-council-ward-7'
    )
    AND tiger_geoid IS NOT NULL;

  IF v_ward_rows <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate A): expected 7 per-ward rows with tiger_geoid, found %', v_ward_rows;
  END IF;

  -- Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2509000') with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_citywide_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2509000'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NOT NULL;

  IF v_citywide_rows <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate B): expected 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid, found %', v_citywide_rows;
  END IF;

  -- Gate C: 0 ward councillors (ext_ids -250900002..-250900008) still pointing to citywide '2509000' LOCAL
  SELECT COUNT(*) INTO v_still_citywide
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-250900002, -250900003, -250900004, -250900005,
                          -250900006, -250900007, -250900008)
    AND d.geo_id = '2509000'
    AND d.district_type = 'LOCAL';

  IF v_still_citywide <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate C): % ward councillors still point to citywide 2509000 LOCAL (expected 0)', v_still_citywide;
  END IF;

  -- Gate D: 7 ward councillors pointing to per-ward rows
  SELECT COUNT(*) INTO v_per_ward
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-250900002, -250900003, -250900004, -250900005,
                          -250900006, -250900007, -250900008)
    AND d.geo_id LIKE 'brockton-ma-council-ward-%';

  IF v_per_ward <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate D): expected 7 ward councillors pointing to per-ward rows, found %', v_per_ward;
  END IF;

  RAISE NOTICE 'Migration 663 post-verification PASSED: ward_rows=%, citywide_rows=%, still_citywide=%, per_ward=%',
    v_ward_rows, v_citywide_rows, v_still_citywide, v_per_ward;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('663')
ON CONFLICT (version) DO NOTHING;

COMMIT;
