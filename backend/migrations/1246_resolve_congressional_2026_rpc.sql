-- 1246: connect.resolve_congressional_2026(uuid) — D-11 Connected-tier live fallback RPC
--
-- WHY (Phase 164.1, D-11, user-approved 2026-07-06): a logged-in Connected-tier user's
-- /elections Path 1 keys off the CACHED connected_profiles.congressional_geo_id, which was
-- resolved against the current-vintage (G5200) congressional map and can never see the
-- 2026-vintage (mtfcc = 'G5200V26') geometry landing in this phase for TN/MO/AL/LA/UT
-- (FIPS 47/29/01/22/49). A Connected user living in a differential zone of one of those
-- states would otherwise see their OLD district's race through the Nov-2026 general.
--
-- WHAT: a READ-ONLY SECURITY DEFINER function that decrypts the user's stored coordinate
-- (same Vault + pgcrypto preamble as connect.resolve_user_jurisdiction — which stays on
-- G5200 for the reps feed per D-04 and is NOT modified) and resolves the congressional
-- district against mtfcc = 'G5200V26' boundaries for the 5 refreshed states only.
-- Returns the covering NATIONAL_LOWER geo_id, or NULL when:
--   - the user has no stored/consented coordinate, or
--   - the point is not covered by any G5200V26 boundary (i.e. not in a refreshed state).
-- With zero G5200V26 rows in the DB this returns NULL for every user — a proven no-op
-- until 2026 polygons land (fail-safe default).
--
-- NO WRITES: does not touch connected_profiles / connect.user_districts /
-- essentials.geo_districts (D-04). Retired by the Jan-2027 boundary-promotion phase once
-- the cached geo_ids are re-resolved against promoted 2026 geometry.
--
-- Idempotent: CREATE OR REPLACE + re-runnable GRANTs.

BEGIN;

CREATE OR REPLACE FUNCTION connect.resolve_congressional_2026(p_user_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_key           text;
  v_encrypted_lat bytea;
  v_encrypted_lng bytea;
  v_lat           float8;
  v_lng           float8;
  v_point         public.geometry;
  v_geo_id        text;
BEGIN
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
   WHERE name = 'location_encryption_key'
   LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'location_encryption_key not found in Vault';
  END IF;

  SELECT encrypted_lat, encrypted_lng INTO v_encrypted_lat, v_encrypted_lng
    FROM connect.connected_profiles
   WHERE user_id = p_user_id
     AND location_consent = true;

  -- Read-path fallback: no coordinate on file (or no consent) → NULL, never an error.
  IF v_encrypted_lat IS NULL OR v_encrypted_lng IS NULL THEN
    RETURN NULL;
  END IF;

  v_lat := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key), 'UTF8')::float8;
  v_lng := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key), 'UTF8')::float8;

  v_point := public.ST_SetSRID(public.ST_MakePoint(v_lng, v_lat), 4326);

  SELECT d.geo_id
    INTO v_geo_id
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d
      ON d.geo_id = gb.geo_id
     AND d.district_type = 'NATIONAL_LOWER'
   WHERE gb.mtfcc = 'G5200V26'
     -- 2026-refresh states only: TN=47, MO=29, AL=01, LA=22, UT=49
     AND substring(gb.geo_id FROM 1 FOR 2) IN ('47', '29', '01', '22', '49')
     AND gb.geometry IS NOT NULL
     AND public.ST_Covers(gb.geometry, v_point)
   ORDER BY d.geo_id
   LIMIT 1;

  RETURN v_geo_id;
END;
$function$;

-- Match resolve_user_jurisdiction's grant surface: service_role only.
REVOKE ALL ON FUNCTION connect.resolve_congressional_2026(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION connect.resolve_congressional_2026(uuid) TO service_role;

COMMIT;
