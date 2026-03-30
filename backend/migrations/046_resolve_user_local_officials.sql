-- =============================================================================
-- Migration 046: connect.resolve_user_local_officials
--
-- New RPC that decrypts a user's stored coordinates and returns geo_ids for
-- LOCAL and LOCAL_EXEC district types (city council, mayor, etc.) via PostGIS
-- ST_Covers intersection against essentials.geofence_boundaries.
--
-- Background (BUG-03):
--   connect.resolve_user_jurisdiction (migration 045) handles the 5 pre-computed
--   district types: NATIONAL_LOWER, STATE_UPPER, STATE_LOWER, COUNTY, SCHOOL.
--   LOCAL / LOCAL_EXEC districts (city council sub-districts, mayor citywide
--   districts) are not stored as simple geo_id columns on connected_profiles
--   because each city uses different boundary files and a user may be covered by
--   multiple LOCAL boundaries simultaneously. These require a live PostGIS lookup
--   every time.
--
--   After quick-008 populated pre-computed geo_ids, Path 2 (Census Geocoder
--   fallback) in GET /essentials/representatives/me stopped running, causing
--   local officials to disappear. This RPC restores them via a coordinate-based
--   lookup that Path 1 can call directly.
--
-- Return type: TABLE(geo_id text, district_type text)
--   Caller iterates rows and looks up politicians for each returned geo_id.
--   Returns empty set (no error) if the user has no stored location.
--
-- MTFCC mapping for LOCAL/LOCAL_EXEC (mirrors getRepresentativesByAddress):
--   G4040          → LOCAL, LOCAL_EXEC  (incorporated places / city boundaries)
--   G4110, G4120   → LOCAL, LOCAL_EXEC  (consolidated city variants)
--   X%             → LOCAL only         (custom sub-city boundaries)
--
-- COUNTY is intentionally excluded — already covered by county_geo_id in
-- connect.connected_profiles (pre-computed by upsert_user_location).
--
-- Prerequisites:
--   - Migration 031: connect.connected_profiles location columns
--   - Migration 045: pattern for decrypt + point construction
--   - Essentials schema populated with geofence_boundaries + districts
--   - Extensions: pgcrypto (in extensions schema), postgis (in public schema)
--   - Vault secret: 'location_encryption_key'
--
-- Idempotency: CREATE OR REPLACE is inherently idempotent.
-- =============================================================================

CREATE OR REPLACE FUNCTION connect.resolve_user_local_officials(p_user_id uuid)
RETURNS TABLE(geo_id text, district_type text)
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
  v_point         public.geometry;
BEGIN
  -- Fetch key from Vault (SECURITY DEFINER allows vault schema access)
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
   WHERE name = 'location_encryption_key'
   LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'location_encryption_key not found in Vault';
  END IF;

  -- Fetch encrypted coordinates; location_consent check is implicit —
  -- only rows where upsert_user_location completed will have consent = true.
  SELECT cp.encrypted_lat, cp.encrypted_lng
    INTO v_encrypted_lat, v_encrypted_lng
    FROM connect.connected_profiles cp
   WHERE cp.user_id = p_user_id
     AND cp.location_consent = true;

  -- Return empty set if user has no stored location (no error — caller handles gracefully).
  IF v_encrypted_lat IS NULL THEN
    RETURN;
  END IF;

  -- Decrypt: bytea → UTF8 text → float8.
  -- convert_from() required — bytea::text gives hex representation (\x...) not
  -- the original string. convert_from(bytea, 'UTF8') recovers the original text.
  -- extensions. prefix required; pgcrypto installs into extensions schema in Supabase.
  v_lat := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key), 'UTF8')::float8;
  v_lng := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key), 'UTF8')::float8;

  -- Build geometry point: ST_MakePoint(longitude, latitude) — X=lng, Y=lat per PostGIS convention.
  -- LONGITUDE FIRST. SRID 4326 (WGS84) must match geofence_boundaries.geometry SRID.
  -- public. prefix required; PostGIS installs into public schema in this Supabase project.
  v_point := public.ST_SetSRID(public.ST_MakePoint(v_lng, v_lat), 4326);

  -- Return geo_ids for LOCAL and LOCAL_EXEC district types only.
  -- COUNTY is excluded here — pre-computed county_geo_id handles it.
  -- MTFCC mapping mirrors getRepresentativesByAddress in essentialsService.ts:
  --   G4040          → incorporated places (city boundaries) → LOCAL, LOCAL_EXEC
  --   G4110, G4120   → consolidated city variants             → LOCAL, LOCAL_EXEC
  --   X%             → custom sub-city boundaries             → LOCAL only
  -- ST_Covers preferred over ST_Contains: handles boundary-coincident points correctly.
  RETURN QUERY
  SELECT d.geo_id, d.district_type
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
      AND (
        (gb.mtfcc = 'G4040'                    AND d.district_type IN ('LOCAL', 'LOCAL_EXEC'))
        OR (gb.mtfcc IN ('G4110', 'G4120')     AND d.district_type IN ('LOCAL', 'LOCAL_EXEC'))
        OR (gb.mtfcc LIKE 'X%'                 AND d.district_type = 'LOCAL')
      )
   WHERE public.ST_Covers(gb.geometry, v_point);
END;
$$;
