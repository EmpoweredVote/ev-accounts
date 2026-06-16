-- Migration 712: New Bedford City Council ward geofencing (MAGE-22)
--
-- Purpose: Upgrades New Bedford from Tier 2 (citywide blob) to Tier 3 (per-ward
-- geofencing) for the 6 ward city council seats.
--
-- Requires: load-ma-ward-boundaries.ts --city "NEW BEDFORD" --ward-count 6
--   must be run first (6 X0014 rows in essentials.geofence_boundaries).
--   NOTE: TOWN='NEW BEDFORD' with space — URL-encoded as NEW%20BEDFORD. This was
--   handled correctly by load-ma-ward-boundaries.ts via encodeURIComponent (Plan 01).
--
-- Source: migration 587 (new_bedford_city_government.sql)
--
-- Steps:
--   1. Insert 6 per-ward LOCAL district rows (geo_id='new-bedford-ma-council-ward-N')
--   2. Backfill tiger_geoid on 6 per-ward rows
--   3. Backfill tiger_geoid on citywide LOCAL row (geo_id='2545000') — no-op guard
--   4. Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2545000') — no-op guard
--   5. Re-link 6 ward councillors from citywide '2545000' LOCAL → per-ward LOCAL
--
-- Ward councillor → external_id mapping (from migration 587):
--   Ward 1: Leo Choquette      (-2545000007) → new-bedford-ma-council-ward-1
--   Ward 2: Scott Pemberton    (-2545000008) → new-bedford-ma-council-ward-2
--   Ward 3: Shawn Oliver       (-2545000009) → new-bedford-ma-council-ward-3
--   Ward 4: Derek Baptiste     (-2545000010) → new-bedford-ma-council-ward-4
--   Ward 5: Joseph Lopes       (-2545000011) → new-bedford-ma-council-ward-5
--   Ward 6: Ryan Pereira       (-2545000012) → new-bedford-ma-council-ward-6  (Council President — title unchanged)
--
-- At-large councillors (NO re-link — keep at citywide '2545000' LOCAL):
--   -2545000002 (Abreu), -2545000003 (Burgo), -2545000004 (Carney),
--   -2545000005 (Gomes), -2545000006 (Roy) — 5 at-large councillors
-- Mayor Mitchell (-2545000001) stays at citywide LOCAL_EXEC.
--
-- Post-verification gates:
--   Gate A: 6 per-ward rows with tiger_geoid IS NOT NULL
--   Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2545000') with tiger_geoid IS NOT NULL
--   Gate C: 0 ward councillors (ext_ids -2545000007..-2545000012) still pointing to citywide '2545000' LOCAL
--   Gate D: 6 ward councillors pointing to per-ward rows
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight: Assert 6 X0014 new-bedford-ma-council-ward-* rows exist
-- Enforces that load-ma-ward-boundaries.ts ran before this migration.
-- T-119-M4: pre-flight RAISES EXCEPTION if geofence rows are missing.
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'new-bedford-ma-council-ward-%' AND mtfcc = 'X0014';

  IF v_count < 6 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected >= 6 X0014 new-bedford-ma-council-ward-* rows in geofence_boundaries, found %. Run: npx tsx scripts/load-ma-ward-boundaries.ts --city "NEW BEDFORD" --ward-count 6', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 New Bedford ward geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 6 per-ward LOCAL district rows
-- geo_id = 'new-bedford-ma-council-ward-{N}', mtfcc = 'X0014', state = 'ma'
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'new-bedford-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'new-bedford-ma-council-ward-2', 'Ward 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'new-bedford-ma-council-ward-3', 'Ward 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'new-bedford-ma-council-ward-4', 'Ward 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'new-bedford-ma-council-ward-5', 'Ward 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'new-bedford-ma-council-ward-6', 'Ward 6', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 2: Backfill tiger_geoid on 6 per-ward district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'new-bedford-ma-council-ward-1',
    'new-bedford-ma-council-ward-2',
    'new-bedford-ma-council-ward-3',
    'new-bedford-ma-council-ward-4',
    'new-bedford-ma-council-ward-5',
    'new-bedford-ma-council-ward-6'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: Backfill tiger_geoid on citywide LOCAL row (geo_id='2545000')
-- No-op guard — migration 622 already set this. Included for safety.
-- Enables Path 0 for at-large councillors who remain at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2545000'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 4: Backfill tiger_geoid on citywide LOCAL_EXEC row (geo_id='2545000')
-- No-op guard — migration 622 already set this. Included for safety.
-- Enables Path 0 for Mayor Mitchell who remains at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2545000'
  AND district_type = 'LOCAL_EXEC'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 5: Re-link 6 ward councillors from citywide '2545000' LOCAL → per-ward
-- Ward councillors are sequential by ward number.
-- Each UPDATE uses external_id + citywide '2545000' LOCAL district_id guard
-- (natural no-op on second run).
-- T-119-M6: No SQL injection risk — external_ids are hardcoded constants.
-- =============================================================================

-- Ward 1: Leo Choquette (-2545000007) → new-bedford-ma-council-ward-1
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545000007
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 2: Scott Pemberton (-2545000008) → new-bedford-ma-council-ward-2
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-2' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545000008
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 3: Shawn Oliver (-2545000009) → new-bedford-ma-council-ward-3
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-3' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545000009
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 4: Derek Baptiste (-2545000010) → new-bedford-ma-council-ward-4
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-4' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545000010
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 5: Joseph Lopes (-2545000011) → new-bedford-ma-council-ward-5
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-5' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545000011
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- Ward 6: Ryan Pereira (-2545000012) → new-bedford-ma-council-ward-6  (Council President — title unchanged)
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'new-bedford-ma-council-ward-6' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545000012
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545000' AND district_type = 'LOCAL' AND state = 'ma'
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
  -- Gate A: 6 per-ward rows with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_ward_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id IN (
      'new-bedford-ma-council-ward-1', 'new-bedford-ma-council-ward-2',
      'new-bedford-ma-council-ward-3', 'new-bedford-ma-council-ward-4',
      'new-bedford-ma-council-ward-5', 'new-bedford-ma-council-ward-6'
    )
    AND tiger_geoid IS NOT NULL;

  IF v_ward_rows <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate A): expected 6 per-ward rows with tiger_geoid, found %', v_ward_rows;
  END IF;

  -- Gate B: 2 citywide rows (LOCAL + LOCAL_EXEC geo_id='2545000') with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_citywide_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2545000'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NOT NULL;

  IF v_citywide_rows <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate B): expected 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid, found %', v_citywide_rows;
  END IF;

  -- Gate C: 0 ward councillors (ext_ids -2545000007..-2545000012) still pointing to citywide '2545000' LOCAL
  SELECT COUNT(*) INTO v_still_citywide
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-2545000007, -2545000008, -2545000009,
                          -2545000010, -2545000011, -2545000012)
    AND d.geo_id = '2545000'
    AND d.district_type = 'LOCAL';

  IF v_still_citywide <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate C): % ward councillors still point to citywide 2545000 LOCAL (expected 0)', v_still_citywide;
  END IF;

  -- Gate D: 6 ward councillors pointing to per-ward rows
  SELECT COUNT(*) INTO v_per_ward
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-2545000007, -2545000008, -2545000009,
                          -2545000010, -2545000011, -2545000012)
    AND d.geo_id LIKE 'new-bedford-ma-council-ward-%';

  IF v_per_ward <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate D): expected 6 ward councillors pointing to per-ward rows, found %', v_per_ward;
  END IF;

  RAISE NOTICE 'Migration 712 post-verification PASSED: ward_rows=%, citywide_rows=%, still_citywide=%, per_ward=%',
    v_ward_rows, v_citywide_rows, v_still_citywide, v_per_ward;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('712')
ON CONFLICT (version) DO NOTHING;

COMMIT;
