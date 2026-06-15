-- Migration 660: Worcester City Council district geofencing
--
-- Purpose: Upgrade Worcester from Tier 2 (citywide blob) to Tier 3 (per-district geofencing).
--   A user in Worcester District 3 will now resolve to John Fresolo rather than all 10 councillors.
--
-- Prerequisites: load-worcester-council-boundaries.ts must be run first.
--   That script inserts 5 X0014 rows into essentials.geofence_boundaries with
--   geo_ids 'worcester-ma-council-district-1' through 'worcester-ma-council-district-5'.
--
-- Steps:
--   Pre-flight: Assert 5 X0014 worcester-ma-council-district-* rows exist in geofence_boundaries
--   Step 1: Insert 5 per-district LOCAL rows (idempotent WHERE NOT EXISTS)
--   Step 2: tiger_geoid backfill on the 5 per-district rows
--   Step 3: tiger_geoid backfill on citywide LOCAL row (at-large councillors)
--   Step 4: tiger_geoid backfill on citywide LOCAL_EXEC row (Mayor Petty)
--   Step 5: Re-link 5 district councillors' offices from citywide LOCAL → per-ward LOCAL
--     -258200007 Tony Economou → worcester-ma-council-district-1
--     -258200008 Robert A. Bilotta → worcester-ma-council-district-2
--     -258200009 John P. Fresolo → worcester-ma-council-district-3
--     -258200010 Luis A. Ojeda → worcester-ma-council-district-4
--     -258200011 Jose A. Rivera → worcester-ma-council-district-5
--   Post-verification: 5 gates (A through E)
--   Ledger: INSERT VALUES ('660')
--
-- Idempotent: WHERE NOT EXISTS guards on INSERTs; tiger_geoid IS NULL guards on UPDATEs;
--             office re-link guards against already-pointing-to-correct-district.
--
-- Applied to production via mcp__supabase-local__execute_sql.

-- =============================================================================
-- Pre-flight: Assert 5 X0014 geofence_boundaries rows exist
-- Enforces script-before-migration ordering (T-119-W2)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'worcester-ma-council-district-%'
    AND mtfcc = 'X0014';

  IF v_count < 5 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 5 X0014 worcester-ma-council-district-* rows in geofence_boundaries, found %. Run load-worcester-council-boundaries.ts first.', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight PASSED: % X0014 Worcester council district geofences present', v_count;
END $$;

BEGIN;

-- =============================================================================
-- Step 1: Insert 5 per-district LOCAL rows
-- geo_ids: 'worcester-ma-council-district-1' through 'worcester-ma-council-district-5'
-- mtfcc='X0014' (Phase 119 MA city council districts)
-- state='ma' LOWERCASE (routing query convention — matches other MA district rows)
-- WHERE NOT EXISTS guard for idempotency.
-- =============================================================================

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'worcester-ma-council-district-1', 'District 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-1'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'worcester-ma-council-district-2', 'District 2', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-2'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'worcester-ma-council-district-3', 'District 3', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-3'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'worcester-ma-council-district-4', 'District 4', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-4'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'worcester-ma-council-district-5', 'District 5', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-5'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

-- =============================================================================
-- Step 2: tiger_geoid backfill on the 5 per-district rows
-- Path 0 join: d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc ('X0014')
-- Pattern: tiger_geoid = geo_id (same as migrations 619, 622, 659)
-- Idempotent: tiger_geoid IS NULL guard.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id IN (
    'worcester-ma-council-district-1',
    'worcester-ma-council-district-2',
    'worcester-ma-council-district-3',
    'worcester-ma-council-district-4',
    'worcester-ma-council-district-5'
  )
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 3: tiger_geoid backfill on citywide LOCAL row
-- geo_id='2582000' matches the G4110 citywide geofence for Worcester.
-- Enables at-large councillors (King, Mitra, Toomey, Bergman, Rosen) to appear via Path 0.
-- Idempotent: tiger_geoid IS NULL guard.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type = 'LOCAL'
  AND geo_id = '2582000'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 4: tiger_geoid backfill on citywide LOCAL_EXEC row
-- geo_id='2582000' same G4110 citywide polygon.
-- Enables Mayor Petty to appear via Path 0.
-- Idempotent: tiger_geoid IS NULL guard.
-- =============================================================================
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type = 'LOCAL_EXEC'
  AND geo_id = '2582000'
  AND tiger_geoid IS NULL;

-- =============================================================================
-- Step 5: Re-link 5 district councillors' offices from citywide LOCAL → per-ward LOCAL
--
-- Current state (Tier 2): all 5 district councillors point to citywide LOCAL (geo_id='2582000')
-- Target state (Tier 3): each district councillor points to their per-district LOCAL row
--
-- Pattern: one UPDATE per councillor; guarded by:
--   (a) politician_id = the specific external_id
--   (b) district_id = citywide LOCAL id (natural no-op on second run — if already re-linked,
--       the source district_id no longer matches, so UPDATE affects 0 rows)
--
-- Mapping from migration 351 (Worcester government seeding):
--   -258200007 Tony Economou   → City Councilor (District 1)
--   -258200008 Robert A. Bilotta → City Councilor (District 2)
--   -258200009 John P. Fresolo → City Councilor (District 3)
--   -258200010 Luis A. Ojeda   → City Councilor (District 4)
--   -258200011 Jose A. Rivera  → City Councilor (District 5)
-- =============================================================================

-- District 1: Tony Economou (-258200007)
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-1'
    AND district_type = 'LOCAL'
    AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -258200007
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2582000'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

-- District 2: Robert A. Bilotta (-258200008)
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-2'
    AND district_type = 'LOCAL'
    AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -258200008
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2582000'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

-- District 3: John P. Fresolo (-258200009)
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-3'
    AND district_type = 'LOCAL'
    AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -258200009
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2582000'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

-- District 4: Luis A. Ojeda (-258200010)
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-4'
    AND district_type = 'LOCAL'
    AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -258200010
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2582000'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

-- District 5: Jose A. Rivera (-258200011)
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'worcester-ma-council-district-5'
    AND district_type = 'LOCAL'
    AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -258200011
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2582000'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);

-- =============================================================================
-- Post-verification: 5 gates (A through E)
-- =============================================================================
DO $$
DECLARE
  v_gate_a  INTEGER;
  v_gate_b  INTEGER;
  v_gate_c  INTEGER;
  v_gate_d  INTEGER;
  v_gate_e  INTEGER;
BEGIN

  -- Gate A: 5 per-district LOCAL rows have tiger_geoid set
  SELECT COUNT(*) INTO v_gate_a
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id IN (
      'worcester-ma-council-district-1',
      'worcester-ma-council-district-2',
      'worcester-ma-council-district-3',
      'worcester-ma-council-district-4',
      'worcester-ma-council-district-5'
    )
    AND mtfcc = 'X0014'
    AND tiger_geoid IS NOT NULL;

  IF v_gate_a <> 5 THEN
    RAISE EXCEPTION 'Gate A FAILED: expected 5 per-district X0014 rows with tiger_geoid set, found %', v_gate_a;
  END IF;
  RAISE NOTICE 'Gate A PASSED: % / 5 per-district X0014 rows have tiger_geoid', v_gate_a;

  -- Gate B: Both citywide rows (LOCAL + LOCAL_EXEC) at geo_id='2582000' have tiger_geoid='2582000'
  SELECT COUNT(*) INTO v_gate_b
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2582000'
    AND tiger_geoid = '2582000'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC');

  IF v_gate_b <> 2 THEN
    RAISE EXCEPTION 'Gate B FAILED: expected 2 citywide rows (LOCAL + LOCAL_EXEC) with tiger_geoid=2582000, found %', v_gate_b;
  END IF;
  RAISE NOTICE 'Gate B PASSED: % / 2 citywide rows have tiger_geoid=2582000', v_gate_b;

  -- Gate C: 0 district councillors (ext_ids -258200007..-258200011) still point to citywide LOCAL row
  -- Confirms all 5 have been re-linked away from geo_id='2582000' LOCAL.
  SELECT COUNT(*) INTO v_gate_c
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -258200011 AND -258200007
    AND d.geo_id = '2582000'
    AND d.district_type = 'LOCAL';

  IF v_gate_c <> 0 THEN
    RAISE EXCEPTION 'Gate C FAILED: expected 0 district councillors pointing to citywide LOCAL, found % still pointing to geo_id=2582000 LOCAL', v_gate_c;
  END IF;
  RAISE NOTICE 'Gate C PASSED: 0 district councillors still pointing to citywide LOCAL (all re-linked)';

  -- Gate D: Exactly 5 district councillors now point to per-district rows
  SELECT COUNT(*) INTO v_gate_d
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -258200011 AND -258200007
    AND d.geo_id LIKE 'worcester-ma-council-district-%';

  IF v_gate_d <> 5 THEN
    RAISE EXCEPTION 'Gate D FAILED: expected 5 district councillors pointing to per-district rows, found %', v_gate_d;
  END IF;
  RAISE NOTICE 'Gate D PASSED: % / 5 district councillors point to per-district rows', v_gate_d;

  -- Gate E: All 5 point to DISTINCT per-district rows (no two councillors share same district)
  SELECT COUNT(DISTINCT d.geo_id) INTO v_gate_e
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -258200011 AND -258200007
    AND d.geo_id LIKE 'worcester-ma-council-district-%';

  IF v_gate_e <> 5 THEN
    RAISE EXCEPTION 'Gate E FAILED: expected 5 distinct per-district geo_ids, found % (two councillors share a district)', v_gate_e;
  END IF;
  RAISE NOTICE 'Gate E PASSED: % distinct per-district geo_ids (1 councillor per district)', v_gate_e;

  RAISE NOTICE 'Migration 660 post-verification PASSED: gate_a=%, gate_b=%, gate_c=%, gate_d=%, gate_e=%',
    v_gate_a, v_gate_b, v_gate_c, v_gate_d, v_gate_e;

END $$;

-- =============================================================================
-- Migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('660')
ON CONFLICT (version) DO NOTHING;

COMMIT;
