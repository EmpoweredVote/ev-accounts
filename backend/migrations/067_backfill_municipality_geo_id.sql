-- Migration 067: Backfill municipality_geo_id for all Connected users with stored location
--
-- The resolve_user_jurisdiction RPC updated in migration 066 now returns a
-- `municipality` key containing the LOCAL_EXEC geo_id of the incorporated place
-- enclosing the user's coordinates. This migration re-runs the RPC for every user
-- with encrypted coordinates and writes the municipality_geo_id column.
--
-- Only municipality_geo_id is written — all other jurisdiction columns are unaffected.
--
-- Failures are logged as warnings (not errors) so one bad row doesn't abort the rest.
-- Idempotency: safe to re-run — overwrites with the same value.

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
      SET municipality_geo_id = v_result->>'municipality',
          updated_at           = now()
      WHERE user_id = rec.user_id;

      v_count := v_count + 1;

    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'backfill 067: failed for user % — %', rec.user_id, SQLERRM;
      v_errors := v_errors + 1;
    END;
  END LOOP;

  RAISE NOTICE 'backfill 067 complete: % updated, % errors', v_count, v_errors;
END;
$$;
