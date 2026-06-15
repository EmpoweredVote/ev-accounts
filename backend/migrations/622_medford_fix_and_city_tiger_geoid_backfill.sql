-- Migration 622: Fix Medford geo_id (2540115→2539835) + backfill tiger_geoid for 6 MA city districts
--
-- Bug: Migration 591 seeded Medford with FIPS place code 40115 (Melrose), not 39835 (Medford).
-- This caused Medford district rows to reference Melrose's geofence boundary in Path 0.
--
-- Fix order is critical:
--   Step 1: Correct Medford geo_id in essentials.districts (LOCAL + LOCAL_EXEC)
--   Step 2: Correct Medford geo_id in essentials.governments (data integrity)
--   Step 3: Backfill tiger_geoid = geo_id for all 6 new city LOCAL + LOCAL_EXEC districts
--           (Medford now has geo_id='2539835' after Step 1, so backfill sets tiger_geoid='2539835')
--
-- Scope: 12 rows (6 cities × 2 types: LOCAL + LOCAL_EXEC)
-- Affected cities: Somerville (2562535), Lynn (2537490), Medford (2539835),
--                  Fall River (2523000), Waltham (2572600), New Bedford (2545000)
--
-- Idempotent: WHERE tiger_geoid IS NULL guard on Step 3.
-- Applied to production Supabase via pg Pool.

BEGIN;

-- Step 1: Fix Medford geo_id in districts (was seeded with Melrose's FIPS code 2540115)
UPDATE essentials.districts
SET geo_id = '2539835'
WHERE state = 'ma'
  AND geo_id = '2540115'
  AND label IN ('Medford', 'Medford (Citywide)');

-- Step 2: Fix Medford geo_id in governments (data integrity — governments.geo_id is metadata only,
-- not used by Path 0 geofencing, but must match the correct FIPS place code)
UPDATE essentials.governments
SET geo_id = '2539835'
WHERE name = 'City of Medford, Massachusetts, US';

-- Step 3: Backfill tiger_geoid = geo_id for all 6 new city LOCAL and LOCAL_EXEC districts
-- (Medford geo_id is now '2539835' after Step 1, so this sets tiger_geoid='2539835' correctly)
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IN ('2562535', '2537490', '2539835', '2523000', '2572600', '2545000')
  AND tiger_geoid IS NULL;

DO $$
DECLARE
  v_medford_districts  INT;
  v_medford_gov        INT;
  v_city_backfilled    INT;
  v_city_null_remain   INT;
BEGIN
  -- Verify Medford districts corrected
  SELECT COUNT(*) INTO v_medford_districts
  FROM essentials.districts
  WHERE state = 'ma' AND geo_id = '2539835' AND label IN ('Medford', 'Medford (Citywide)');

  -- Verify Medford government corrected
  SELECT COUNT(*) INTO v_medford_gov
  FROM essentials.governments
  WHERE name = 'City of Medford, Massachusetts, US' AND geo_id = '2539835';

  -- Verify all 12 city district rows have tiger_geoid set
  SELECT COUNT(*) INTO v_city_backfilled
  FROM essentials.districts
  WHERE state = 'ma'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND geo_id IN ('2562535', '2537490', '2539835', '2523000', '2572600', '2545000')
    AND tiger_geoid IS NOT NULL;

  -- Verify no city district rows remain NULL
  SELECT COUNT(*) INTO v_city_null_remain
  FROM essentials.districts
  WHERE state = 'ma'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND geo_id IN ('2562535', '2537490', '2539835', '2523000', '2572600', '2545000')
    AND tiger_geoid IS NULL;

  RAISE NOTICE 'Medford districts with correct geo_id: % / 2', v_medford_districts;
  RAISE NOTICE 'Medford government with correct geo_id: % / 1', v_medford_gov;
  RAISE NOTICE 'City districts tiger_geoid backfilled: % / 12', v_city_backfilled;

  IF v_medford_districts <> 2 THEN
    RAISE EXCEPTION 'Medford district geo_id fix failed — expected 2 rows at 2539835, got %', v_medford_districts;
  END IF;
  IF v_medford_gov <> 1 THEN
    RAISE EXCEPTION 'Medford government geo_id fix failed — expected 1 row at 2539835, got %', v_medford_gov;
  END IF;
  IF v_city_backfilled <> 12 THEN
    RAISE EXCEPTION 'City tiger_geoid backfill mismatch — expected 12, got %', v_city_backfilled;
  END IF;
  IF v_city_null_remain <> 0 THEN
    RAISE EXCEPTION '% city district rows still NULL after backfill', v_city_null_remain;
  END IF;
  RAISE NOTICE 'Migration 622 complete.';
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('622') ON CONFLICT DO NOTHING;

COMMIT;
