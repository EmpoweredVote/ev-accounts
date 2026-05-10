BEGIN;

-- =============================================================================
-- Migration 092: Bulk recache user_districts RPCs
-- GEO-10 (Phase 70-03): Admin re-cache mechanism for connect.user_districts.
--
-- Closes the redistricting-readiness gap: after a redistricting event or TIGER
-- data import, an operator can call essentials.recache_user_districts_bulk()
-- to refresh all (or selectively stale) users without waiting for each user
-- to update their location individually.
--
-- Both functions: SECURITY DEFINER + SET search_path = '' + fully-qualified refs.
-- Vault key: location_encryption_key (same key used by connect.upsert_user_location
-- and connect.resolve_user_jurisdiction).
-- Decrypt pattern: convert_from(extensions.pgp_sym_decrypt_bytea(encrypted_bytes, key), 'UTF8')::float8
--
-- No plaintext coordinates are ever returned to callers.
-- =============================================================================


-- =============================================================================
-- Function A: essentials.recache_user_districts_for_user(p_user_id uuid)
-- Per-user variant. Decrypts encrypted_lat/lng from the Vault-keyed column on
-- connect.connected_profiles, then calls essentials.cache_user_districts to
-- refresh connect.user_districts rows for that user.
--
-- Returns: TABLE(user_id uuid, layers_resolved int, status text)
--   status = 'ok'        — districts resolved and cached successfully
--   status = 'no_coords' — location_consent is false or encrypted_lat is NULL;
--                          no-op, not an error
--   status = 'error'     — unexpected exception (message in layers_resolved = 0)
-- =============================================================================

CREATE OR REPLACE FUNCTION essentials.recache_user_districts_for_user(p_user_id uuid)
RETURNS TABLE(user_id uuid, layers_resolved int, status text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key           text;
  v_encrypted_lat bytea;
  v_encrypted_lng bytea;
  v_lat           float8;
  v_lng           float8;
  v_layers_count  int;
BEGIN
  -- Guard: only process users with consent and stored coords.
  -- Return early with status='no_coords' if the user is not eligible.
  SELECT cp.encrypted_lat, cp.encrypted_lng
    INTO v_encrypted_lat, v_encrypted_lng
    FROM connect.connected_profiles cp
   WHERE cp.user_id = p_user_id
     AND cp.location_consent = true
     AND cp.encrypted_lat IS NOT NULL;

  IF v_encrypted_lat IS NULL THEN
    RETURN QUERY SELECT p_user_id, 0, 'no_coords'::text;
    RETURN;
  END IF;

  -- Fetch Vault key. SECURITY DEFINER grants access to vault.decrypted_secrets.
  SELECT ds.decrypted_secret INTO v_key
    FROM vault.decrypted_secrets ds
   WHERE ds.name = 'location_encryption_key'
   LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'location_encryption_key not found in Vault';
  END IF;

  -- Decrypt: bytea → UTF8 text → float8.
  -- convert_from() recovers the original text; bytea::text produces \x... hex.
  -- extensions. prefix required: pgcrypto installs into extensions schema in Supabase.
  v_lat := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key), 'UTF8')::float8;
  v_lng := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key), 'UTF8')::float8;

  -- Call the Phase 69 cache function (ON CONFLICT DO UPDATE — idempotent).
  -- Raw lat/lng values are never returned to the caller.
  PERFORM essentials.cache_user_districts(p_user_id, v_lat, v_lng);

  -- Count resulting rows so the caller knows how many layers were resolved.
  SELECT COUNT(*) INTO v_layers_count
    FROM connect.user_districts ud
   WHERE ud.user_id = p_user_id;

  -- If layers_count = 0, the point fell outside all loaded TIGER districts (out-of-CA).
  -- Report as 'ok' with layers_resolved=0 — the caller tally handles out-of-CA reporting.
  RETURN QUERY SELECT p_user_id, v_layers_count, 'ok'::text;
END;
$$;

REVOKE ALL ON FUNCTION essentials.recache_user_districts_for_user(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION essentials.recache_user_districts_for_user(uuid) TO service_role;


-- =============================================================================
-- Function B: essentials.recache_user_districts_bulk(p_cutoff timestamptz)
-- Bulk variant. Iterates all eligible Connected users (optionally filtered by
-- how stale their user_districts rows are) and calls the per-user function for
-- each. Returns SETOF status rows.
--
-- p_cutoff IS NULL  → process every user with encrypted_lat + location_consent.
-- p_cutoff IS NOT NULL → process only users whose MIN(user_districts.resolved_at)
--                        is older than p_cutoff OR who have no user_districts rows.
--
-- Each user is wrapped in a sub-BEGIN/EXCEPTION block so one bad user never
-- aborts the whole batch.
-- =============================================================================

CREATE OR REPLACE FUNCTION essentials.recache_user_districts_bulk(
  p_cutoff timestamptz DEFAULT NULL
)
RETURNS TABLE(user_id uuid, layers_resolved int, status text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid          uuid;
  v_result_user  uuid;
  v_result_layers int;
  v_result_status text;
BEGIN
  -- Select candidates matching the cutoff filter.
  -- LEFT JOIN against user_districts lets us pick up users with NO rows at all
  -- (COALESCE to -infinity so they always satisfy < p_cutoff).
  FOR v_uid IN
    SELECT cp.user_id
      FROM connect.connected_profiles cp
      LEFT JOIN connect.user_districts ud ON ud.user_id = cp.user_id
     WHERE cp.encrypted_lat IS NOT NULL
       AND cp.location_consent = true
     GROUP BY cp.user_id
    HAVING (p_cutoff IS NULL OR COALESCE(MIN(ud.resolved_at), '-infinity'::timestamptz) < p_cutoff)
  LOOP
    BEGIN
      -- Call per-user function; surface its single result row.
      SELECT r.user_id, r.layers_resolved, r.status
        INTO v_result_user, v_result_layers, v_result_status
        FROM essentials.recache_user_districts_for_user(v_uid) r;

      RETURN QUERY SELECT v_result_user, v_result_layers, v_result_status;

    EXCEPTION WHEN OTHERS THEN
      -- One bad user must not abort the batch. Return an error row and continue.
      RETURN QUERY SELECT v_uid, 0, ('error: ' || SQLERRM)::text;
    END;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION essentials.recache_user_districts_bulk(timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION essentials.recache_user_districts_bulk(timestamptz) TO service_role;

COMMIT;
