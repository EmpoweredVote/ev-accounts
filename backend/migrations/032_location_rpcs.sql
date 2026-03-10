-- =============================================================================
-- Migration 032: Location RPCs
-- Creates connect.upsert_user_location and connect.resolve_user_jurisdiction.
--
-- IMPORTANT: Both RPCs require the Vault secret 'location_encryption_key' to
-- exist before being called at runtime. The secret is created in the runbook
-- (docs/RUNBOOK-TIGER-LOAD.md), not this migration. Embedding the key value
-- in a migration would store it in migration history — a security anti-pattern.
--
-- Prerequisites (must be applied before this migration):
--   - Migration 031: connect.connected_profiles location columns must exist
--   - Extensions: pgcrypto and postgis must be enabled (Phase 17 DEPLOY.md Step 1)
--   - Vault: pgsodium / Supabase Vault must be enabled
--
-- Idempotency: CREATE OR REPLACE is inherently idempotent.
--
-- Must be run against the live DB via the admin apply-migration tooling
-- (direct connection, not pooler).
-- =============================================================================


-- =============================================================================
-- RPC 1: connect.upsert_user_location
-- Encrypts lat/lng using pgcrypto AES-256 and writes them atomically with
-- location_consent = true. Key fetched from Vault at runtime.
-- =============================================================================

CREATE OR REPLACE FUNCTION connect.upsert_user_location(
  p_user_id uuid,
  p_lat     float8,
  p_lng     float8
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key text;
BEGIN
  -- Two-pass validation: validate all inputs before any writes
  IF p_lat IS NULL OR p_lng IS NULL THEN
    RAISE EXCEPTION 'lat and lng are required';
  END IF;
  IF p_lat < -90 OR p_lat > 90 THEN
    RAISE EXCEPTION 'lat out of range: %', p_lat;
  END IF;
  IF p_lng < -180 OR p_lng > 180 THEN
    RAISE EXCEPTION 'lng out of range: %', p_lng;
  END IF;

  -- Fetch key from Vault (SECURITY DEFINER allows vault schema access)
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
   WHERE name = 'location_encryption_key'
   LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'location_encryption_key not found in Vault';
  END IF;

  -- Atomic write: encrypt coords, set consent and timestamp.
  -- Encoding path: float8 → ::text → ::bytea → pgp_sym_encrypt_bytea → bytea column.
  -- extensions. prefix required because SET search_path = '' removes all implicit
  -- schema resolution; pgcrypto installs into the extensions schema in Supabase.
  UPDATE connect.connected_profiles
     SET encrypted_lat    = extensions.pgp_sym_encrypt_bytea(
                               p_lat::text::bytea, v_key, 'cipher-algo=aes256'
                             ),
         encrypted_lng    = extensions.pgp_sym_encrypt_bytea(
                               p_lng::text::bytea, v_key, 'cipher-algo=aes256'
                             ),
         location_consent = true,
         location_set_at  = now()
   WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'connected_profile not found for user_id %', p_user_id;
  END IF;
END;
$$;


-- =============================================================================
-- RPC 2: connect.resolve_user_jurisdiction
-- Decrypts stored coordinates and runs ST_Covers against inform.district_boundaries
-- to return a jsonb map of { district_type → geoid } for all 5 district types.
-- Raw coordinates are never included in the return value.
-- =============================================================================

CREATE OR REPLACE FUNCTION connect.resolve_user_jurisdiction(p_user_id uuid)
RETURNS jsonb
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
  v_point         geometry;
  v_result        jsonb;
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
  SELECT encrypted_lat, encrypted_lng INTO v_encrypted_lat, v_encrypted_lng
    FROM connect.connected_profiles
   WHERE user_id = p_user_id
     AND location_consent = true;

  IF v_encrypted_lat IS NULL THEN
    RAISE EXCEPTION 'no location on file for user %', p_user_id;
  END IF;

  -- Decrypt: bytea → text → float8.
  -- extensions. prefix required; pgcrypto installs into extensions schema in Supabase.
  v_lat := extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key)::text::float8;
  v_lng := extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key)::text::float8;

  -- Build geometry point: ST_MakePoint(longitude, latitude) — X=lng, Y=lat per PostGIS convention.
  -- LONGITUDE FIRST. SRID 4326 (WGS84) must match district_boundaries.geom SRID.
  -- extensions. prefix required; PostGIS installs into extensions schema in Supabase.
  v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(v_lng, v_lat), 4326);

  -- ST_Covers preferred over ST_Contains: handles boundary-coincident points correctly
  -- (ST_Contains excludes points exactly on the boundary line; ST_Covers includes them).
  -- Return shape: exactly 5 keys — congressional, state_senate, state_house, county, school_district.
  -- MAX(geoid) FILTER pattern aggregates all matching districts per type in a single scan.
  -- Raw coordinates (v_lat, v_lng) are never included in the return value.
  SELECT jsonb_build_object(
    'congressional',   MAX(geoid) FILTER (WHERE district_type = 'congressional'),
    'state_senate',    MAX(geoid) FILTER (WHERE district_type = 'state_senate'),
    'state_house',     MAX(geoid) FILTER (WHERE district_type = 'state_house'),
    'county',          MAX(geoid) FILTER (WHERE district_type = 'county'),
    'school_district', MAX(geoid) FILTER (WHERE district_type = 'school_district')
  )
  INTO v_result
  FROM inform.district_boundaries
  WHERE extensions.ST_Covers(geom, v_point);

  RETURN v_result;
END;
$$;
