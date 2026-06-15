-- Migration 662: Lowell City Council district geofencing (MAGE-13)
--
-- Purpose: Upgrades Lowell from Tier 2 (citywide blob) to Tier 3 (per-district
-- geofencing) for the 8 district city council seats.
--
-- Requires: load-ma-ward-boundaries.ts --city LOWELL --ward-count 8
--   must be run first (8 X0014 rows in essentials.geofence_boundaries).
--
-- CRITICAL (T-119-M5): Lowell is Plan E (council-manager model). Migration 353
-- explicitly created NO LOCAL_EXEC district row. This migration OMITS Step 4
-- (LOCAL_EXEC tiger_geoid) because no such row exists for Lowell.
-- Post-verification Gate B checks 1 citywide row (LOCAL only), not 2.
--
-- Steps:
--   1. Insert 8 per-district LOCAL district rows (geo_id='lowell-ma-council-district-N')
--   2. Backfill tiger_geoid on 8 per-district rows
--   3. Backfill tiger_geoid on citywide LOCAL row (geo_id='2537000') — at-large/admin
--   (Step 4 intentionally omitted — Lowell has NO LOCAL_EXEC district per Plan E model)
--   4. Re-link 8 district councillors from citywide '2537000' LOCAL → per-district LOCAL
--
-- District councillor → external_id mapping (from migration 353):
--   District 1: Daniel Rourke (-253700005)
--   District 2: Corey Robinson (-253700006)
--   District 3: Belinda M. Juran (-253700007)
--   District 4: Sean McDonough (-253700008)
--   District 5: Kimberly Scott (-253700009)
--   District 6: Sokhary Chau (-253700010)
--   District 7: Sidney L. Liang (-253700011)
--   District 8: John Descoteaux (-253700012)
--
-- At-large/admin (NO re-link — keep at citywide '2537000' LOCAL):
--   City Manager Golden (-253700001), Mayor Gitschier (-253700002),
--   Mercier (-253700003), Nuon (-253700004)
--
-- Post-verification gates:
--   Gate A: 8 per-district rows with tiger_geoid IS NOT NULL
--   Gate B: 1 citywide LOCAL row (geo_id='2537000') with tiger_geoid IS NOT NULL
--           (NOT 2 — Lowell has no LOCAL_EXEC, per Plan E council-manager model)
--   Gate C: 0 district councillors still pointing to citywide '2537000' LOCAL
--   Gate D: 8 district councillors pointing to per-district rows
--
-- Applied to production via Supabase MCP execute_sql.

-- =============================================================================
-- Pre-flight: Assert 8 X0014 lowell-ma-council-district-* rows exist
-- Enforces that load-ma-ward-boundaries.ts ran before this migration.
-- T-119-M4: pre-flight RAISES EXCEPTION if geofence rows are missing.
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'lowell-ma-council-district-%' AND mtfcc = 'X0014';

  IF v_count < 8 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected >= 8 X0014 lowell-ma-council-district-* rows in geofence_boundaries, found %. Run: npx tsx scripts/load-ma-ward-boundaries.ts --city LOWELL --ward-count 8', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 Lowell district geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 8 per-district LOCAL district rows
-- geo_id = 'lowell-ma-council-district-{N}', mtfcc = 'X0014', state = 'ma'
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'lowell-ma-council-district-1', 'District 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-1' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'lowell-ma-council-district-2', 'District 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-2' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'lowell-ma-council-district-3', 'District 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-3' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'lowell-ma-council-district-4', 'District 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-4' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'lowell-ma-council-district-5', 'District 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-5' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'lowell-ma-council-district-6', 'District 6', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-6' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'lowell-ma-council-district-7', 'District 7', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-7' AND district_type = 'LOCAL' AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'lowell-ma-council-district-8', 'District 8', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-8' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Step 2: Backfill tiger_geoid on 8 per-district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'lowell-ma-council-district-1',
    'lowell-ma-council-district-2',
    'lowell-ma-council-district-3',
    'lowell-ma-council-district-4',
    'lowell-ma-council-district-5',
    'lowell-ma-council-district-6',
    'lowell-ma-council-district-7',
    'lowell-ma-council-district-8'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: Backfill tiger_geoid on citywide LOCAL row (geo_id='2537000')
-- Enables Path 0 for at-large/admin officials (City Manager, Mayor, Mercier, Nuon)
-- who remain at the citywide G4110 polygon.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id = '2537000'
  AND district_type = 'LOCAL'
  AND tiger_geoid IS NULL;

-- CRITICAL (T-119-M5): Step 4 intentionally omitted.
-- Lowell is Plan E (council-manager model) — migration 353 created NO LOCAL_EXEC
-- district row for Lowell. There is no LOCAL_EXEC row to update. Adding a
-- LOCAL_EXEC tiger_geoid UPDATE here would be a no-op but is misleading;
-- this comment documents the intentional omission for future maintainers.

-- =============================================================================
-- Step 4 (renumbered): Re-link 8 district councillors from citywide '2537000' LOCAL → per-district
-- Each UPDATE uses external_id (precise politician identifier) + citywide LOCAL
-- district_id guard (natural no-op on second run — Pitfall 6 prevention).
-- =============================================================================

-- District 1: Daniel Rourke (-253700005) → lowell-ma-council-district-1
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-1' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -253700005
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2537000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- District 2: Corey Robinson (-253700006) → lowell-ma-council-district-2
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-2' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -253700006
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2537000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- District 3: Belinda M. Juran (-253700007) → lowell-ma-council-district-3
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-3' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -253700007
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2537000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- District 4: Sean McDonough (-253700008) → lowell-ma-council-district-4
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-4' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -253700008
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2537000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- District 5: Kimberly Scott (-253700009) → lowell-ma-council-district-5
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-5' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -253700009
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2537000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- District 6: Sokhary Chau (-253700010) → lowell-ma-council-district-6
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-6' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -253700010
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2537000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- District 7: Sidney L. Liang (-253700011) → lowell-ma-council-district-7
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-7' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -253700011
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2537000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- District 8: John Descoteaux (-253700012) → lowell-ma-council-district-8
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'lowell-ma-council-district-8' AND district_type = 'LOCAL' AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -253700012
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2537000' AND district_type = 'LOCAL' AND state = 'ma'
);

-- =============================================================================
-- Post-verification: 4 gates
-- NOTE: Gate B checks 1 citywide row (LOCAL only) — Lowell has no LOCAL_EXEC.
-- =============================================================================
DO $$
DECLARE
  v_district_rows   INTEGER;
  v_citywide_rows   INTEGER;
  v_still_citywide  INTEGER;
  v_per_district    INTEGER;
BEGIN
  -- Gate A: 8 per-district rows with tiger_geoid IS NOT NULL
  SELECT COUNT(*) INTO v_district_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id IN (
      'lowell-ma-council-district-1', 'lowell-ma-council-district-2',
      'lowell-ma-council-district-3', 'lowell-ma-council-district-4',
      'lowell-ma-council-district-5', 'lowell-ma-council-district-6',
      'lowell-ma-council-district-7', 'lowell-ma-council-district-8'
    )
    AND tiger_geoid IS NOT NULL;

  IF v_district_rows <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate A): expected 8 per-district rows with tiger_geoid, found %', v_district_rows;
  END IF;

  -- Gate B: 1 citywide LOCAL row (geo_id='2537000') with tiger_geoid IS NOT NULL
  -- CRITICAL: Lowell has NO LOCAL_EXEC (Plan E council-manager model — migration 353).
  -- Checking for 1 row (LOCAL only), NOT 2 rows like Springfield/Brockton/Quincy.
  SELECT COUNT(*) INTO v_citywide_rows
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2537000'
    AND district_type = 'LOCAL'
    AND tiger_geoid IS NOT NULL;

  IF v_citywide_rows <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate B): expected 1 LOCAL citywide row (geo_id=2537000) with tiger_geoid, found % (Lowell has no LOCAL_EXEC — Plan E council-manager model)', v_citywide_rows;
  END IF;

  -- Gate C: 0 district councillors (ext_ids -253700005..-253700012) still pointing to citywide '2537000' LOCAL
  SELECT COUNT(*) INTO v_still_citywide
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-253700005, -253700006, -253700007, -253700008,
                          -253700009, -253700010, -253700011, -253700012)
    AND d.geo_id = '2537000'
    AND d.district_type = 'LOCAL';

  IF v_still_citywide <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate C): % district councillors still point to citywide 2537000 LOCAL (expected 0)', v_still_citywide;
  END IF;

  -- Gate D: 8 district councillors pointing to per-district rows
  SELECT COUNT(*) INTO v_per_district
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (-253700005, -253700006, -253700007, -253700008,
                          -253700009, -253700010, -253700011, -253700012)
    AND d.geo_id LIKE 'lowell-ma-council-district-%';

  IF v_per_district <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED (Gate D): expected 8 district councillors pointing to per-district rows, found %', v_per_district;
  END IF;

  RAISE NOTICE 'Migration 662 post-verification PASSED: district_rows=%, citywide_rows=%, still_citywide=%, per_district=%',
    v_district_rows, v_citywide_rows, v_still_citywide, v_per_district;
END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('662')
ON CONFLICT (version) DO NOTHING;

COMMIT;
