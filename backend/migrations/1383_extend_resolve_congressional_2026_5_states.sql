-- 1383: extend connect.resolve_congressional_2026 D-11 fallback to the Phase-164.2 states
--
-- WHY (Phase 164.2-01, D-11): Phase 164.2-02 landed enacted-2026 (mtfcc='G5200V26')
--   congressional polygons for FL=12, CA=06, NC=37, OH=39, TX=48. The anonymous Path-B
--   opt-in already auto-resolves them (generic 164.1 JOIN), but a logged-in Connected-tier
--   user's /elections Path 1 keys off the CACHED connected_profiles.congressional_geo_id
--   (resolved against the OLD G5200 map). Without widening this read-only fallback, a
--   Connected user in a FL/CA/NC/OH/TX differential zone keeps seeing their OLD district's
--   race through the Nov-2026 general.
--
-- WHAT: CREATE OR REPLACE identical to migration 1246 EXCEPT the FIPS IN-list is widened
--   from the original 5 (47/29/01/22/49) to 10 (adding 12/06/37/39/48). Everything else is
--   byte-identical: SECURITY DEFINER, SET search_path='', the Vault decrypt preamble,
--   public.ST_* point build + ST_Covers, the G5200V26 + NATIONAL_LOWER join, ORDER BY
--   d.geo_id LIMIT 1, read-only (no DML). Re-runnable REVOKE/GRANT.
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
     -- 2026-refresh states: 164.1 (TN=47, MO=29, AL=01, LA=22, UT=49)
     --                    + 164.2 (FL=12, CA=06, NC=37, OH=39, TX=48)
     AND substring(gb.geo_id FROM 1 FOR 2) IN ('47', '29', '01', '22', '49', '12', '06', '37', '39', '48')
     AND gb.geometry IS NOT NULL
     AND public.ST_Covers(gb.geometry, v_point)
   ORDER BY d.geo_id
   LIMIT 1;

  RETURN v_geo_id;
END;
$function$;

REVOKE ALL ON FUNCTION connect.resolve_congressional_2026(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION connect.resolve_congressional_2026(uuid) TO service_role;

COMMIT;
