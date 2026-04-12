-- Migration 064: backfill city_council_geo_id for all Connected users with stored location
--
-- The ordering bug fixed in 063 caused city_council_geo_id to be stored incorrectly
-- for users whose coordinates fall in areas covered by both a county supervisor district
-- and a city council district (e.g. southern 90066 / Mar Vista → stored District 2
-- instead of correct District 11).
--
-- This migration re-runs resolve_user_jurisdiction for every user with coordinates
-- and updates only the city_council columns. Other jurisdiction fields are unaffected
-- by the 063 fix and are left untouched.
--
-- Failures are logged as warnings (not errors) so one bad row doesn't abort the rest.

DO $$
DECLARE
  rec      RECORD;
  v_result jsonb;
  v_count  int := 0;
  v_errors int := 0;
BEGIN
  FOR rec IN
    SELECT user_id
    FROM connect.connected_profiles
    WHERE encrypted_lat IS NOT NULL
      AND location_consent = true
  LOOP
    BEGIN
      SELECT connect.resolve_user_jurisdiction(rec.user_id) INTO v_result;

      UPDATE connect.connected_profiles
      SET city_council_geo_id        = v_result->>'city_council',
          city_council_district_name = v_result->>'city_council_name',
          updated_at                 = now()
      WHERE user_id = rec.user_id;

      v_count := v_count + 1;

    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'backfill 064: failed for user % — %', rec.user_id, SQLERRM;
      v_errors := v_errors + 1;
    END;
  END LOOP;

  RAISE NOTICE 'backfill 064 complete: % updated, % errors', v_count, v_errors;
END;
$$;
