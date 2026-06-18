-- Migration 350: School district geofence geometry fix
-- Purpose: BPS (geo_id='2502790') and ACPS (geo_id='5100090') G5420 geofence
--   rows were inserted as geometry-less shells in migrations 348 and 313.
--   The routing query uses ST_Covers(gb.geometry, point), which returns NULL
--   for NULL geometry — so SCHOOL sections never appeared for any address.
--   Fix: copy the parent city G4110 boundary into each G5420 row.
--   BPS serves all of Boston (geo_id='2507000', G4110).
--   ACPS serves all of Alexandria (geo_id='5101000', G4110).

-- ============================================================
-- PRE-FLIGHT CHECKS
-- ============================================================

-- Pre-flight 1: Boston G4110 geometry exists
DO $$
DECLARE v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2507000' AND mtfcc = 'G4110' AND geometry IS NOT NULL;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Boston G4110 geometry (geo_id=2507000) not found or NULL';
  END IF;
  RAISE NOTICE 'Pre-flight 1 PASSED: Boston G4110 geometry present';
END $$;

-- Pre-flight 2: Alexandria G4110 geometry exists
DO $$
DECLARE v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '5101000' AND mtfcc = 'G4110' AND geometry IS NOT NULL;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Alexandria G4110 geometry (geo_id=5101000) not found or NULL';
  END IF;
  RAISE NOTICE 'Pre-flight 2 PASSED: Alexandria G4110 geometry present';
END $$;

-- Pre-flight 3: Both G5420 shell rows exist
DO $$
DECLARE v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id IN ('2502790', '5100090') AND mtfcc = 'G5420';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 2 G5420 shell rows, found %', v_count;
  END IF;
  RAISE NOTICE 'Pre-flight 3 PASSED: both G5420 shell rows present';
END $$;

-- ============================================================
-- STEP 1: Boston Public Schools — copy Boston G4110 geometry
-- ============================================================

UPDATE essentials.geofence_boundaries dst
SET geometry = src.geometry
FROM essentials.geofence_boundaries src
WHERE src.geo_id = '2507000' AND src.mtfcc = 'G4110'
  AND dst.geo_id = '2502790' AND dst.mtfcc = 'G5420';

-- ============================================================
-- STEP 2: Alexandria City Public Schools — copy Alexandria G4110 geometry
-- ============================================================

UPDATE essentials.geofence_boundaries dst
SET geometry = src.geometry
FROM essentials.geofence_boundaries src
WHERE src.geo_id = '5101000' AND src.mtfcc = 'G4110'
  AND dst.geo_id = '5100090' AND dst.mtfcc = 'G5420';

-- ============================================================
-- POST-VERIFICATION
-- ============================================================

DO $$
DECLARE
  v_bps_has_geom  boolean;
  v_acps_has_geom boolean;
  v_bps_covers    boolean;
  v_acps_covers   boolean;
BEGIN
  -- Gate (a): BPS geometry no longer NULL
  SELECT geometry IS NOT NULL INTO v_bps_has_geom
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2502790' AND mtfcc = 'G5420';
  IF NOT v_bps_has_geom THEN
    RAISE EXCEPTION 'Post-verification FAILED: BPS G5420 geometry still NULL after update';
  END IF;

  -- Gate (b): ACPS geometry no longer NULL
  SELECT geometry IS NOT NULL INTO v_acps_has_geom
  FROM essentials.geofence_boundaries
  WHERE geo_id = '5100090' AND mtfcc = 'G5420';
  IF NOT v_acps_has_geom THEN
    RAISE EXCEPTION 'Post-verification FAILED: ACPS G5420 geometry still NULL after update';
  END IF;

  -- Gate (c): Boston City Hall point (lng=-71.0589, lat=42.3601) is covered by BPS geofence
  SELECT public.ST_Covers(
    geometry,
    public.ST_SetSRID(public.ST_MakePoint(-71.0589, 42.3601), 4326)
  ) INTO v_bps_covers
  FROM essentials.geofence_boundaries
  WHERE geo_id = '2502790' AND mtfcc = 'G5420';
  IF NOT v_bps_covers THEN
    RAISE EXCEPTION 'Post-verification FAILED: BPS geofence does not cover Boston City Hall point — geometry copy may be wrong';
  END IF;

  -- Gate (d): Alexandria City Hall point (lng=-77.0472, lat=38.8048) is covered by ACPS geofence
  SELECT public.ST_Covers(
    geometry,
    public.ST_SetSRID(public.ST_MakePoint(-77.0472, 38.8048), 4326)
  ) INTO v_acps_covers
  FROM essentials.geofence_boundaries
  WHERE geo_id = '5100090' AND mtfcc = 'G5420';
  IF NOT v_acps_covers THEN
    RAISE EXCEPTION 'Post-verification FAILED: ACPS geofence does not cover Alexandria City Hall point — geometry copy may be wrong';
  END IF;

  RAISE NOTICE 'Post-verification PASSED: BPS and ACPS G5420 geofences now have geometry and cover expected city hall points';
END $$;

-- ============================================================
-- MIGRATION LEDGER
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('350')
ON CONFLICT (version) DO NOTHING;
