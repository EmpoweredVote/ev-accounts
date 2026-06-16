-- Migration 699: Backfill tiger_geoid for Newton MA city districts
--
-- Newton was excluded from migration 622's tiger_geoid backfill batch.
-- Migration 622 covered only 6 cities: Somerville, Lynn, Medford, Fall River,
-- Waltham, and New Bedford (geo_ids: 2562535, 2537490, 2539835, 2523000,
-- 2572600, 2545000). Newton (geo_id='2545560') was seeded in migration 578 but
-- never received its tiger_geoid backfill.
--
-- Scope: 2 rows — Newton LOCAL + LOCAL_EXEC districts at geo_id='2545560'
-- tiger_geoid = geo_id = '2545560' (FIPS place code for Newton, MA)
--
-- Purpose: Newton's tiger_geoid = NULL blocks Phase 123 (Ward Geofencing for
-- Newton), which joins essentials.districts.tiger_geoid to
-- essentials.geofence_boundaries.geo_id. Fixing it here unblocks Phase 123.
--
-- Idempotent: WHERE tiger_geoid IS NULL guard prevents re-apply side effects.
--
-- Note: Previously numbered 687, which collided with 687_leblanc_stances.sql.
-- Renumbered to 699 (CR-01 fix). The UPDATE was already applied to production
-- during the original run; this file is the canonical on-disk record with the
-- correct ledger version.

BEGIN;

-- True pre-flight: verify G4110 geofence boundary exists BEFORE making any changes.
-- Runs in its own DO block so a missing boundary aborts before the UPDATE executes.
DO $$
DECLARE
  v_geofence_exists INT;
BEGIN
  SELECT COUNT(*) INTO v_geofence_exists
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2545560' AND mtfcc = 'G4110';

  IF v_geofence_exists = 0 THEN
    RAISE EXCEPTION 'Pre-flight failed: no G4110 geofence_boundary for geo_id=2545560 — run TIGER import before this migration';
  END IF;
END $$;

-- Backfill tiger_geoid = geo_id for Newton LOCAL and LOCAL_EXEC districts
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id = '2545560'
  AND tiger_geoid IS NULL;

DO $$
DECLARE
  v_count_backfilled  INT;
  v_count_null_remain INT;
BEGIN
  SELECT COUNT(*) INTO v_count_backfilled
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2545560'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NOT NULL;

  SELECT COUNT(*) INTO v_count_null_remain
  FROM essentials.districts
  WHERE state = 'ma'
    AND geo_id = '2545560'
    AND district_type IN ('LOCAL', 'LOCAL_EXEC')
    AND tiger_geoid IS NULL;

  IF v_count_backfilled <> 2 THEN
    RAISE EXCEPTION 'Newton tiger_geoid backfill failed — expected 2, got %', v_count_backfilled;
  END IF;
  IF v_count_null_remain <> 0 THEN
    RAISE EXCEPTION '% Newton district rows still NULL after backfill', v_count_null_remain;
  END IF;
  RAISE NOTICE 'Migration 699 complete. Newton districts backfilled: % / 2', v_count_backfilled;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('699') ON CONFLICT (version) DO NOTHING;

COMMIT;
