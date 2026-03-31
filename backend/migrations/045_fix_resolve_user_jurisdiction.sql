-- =============================================================================
-- Migration 045: Fix connect.resolve_user_jurisdiction
--
-- Replaces the old RPC that queried the empty `inform.district_boundaries` table
-- with one that queries live geometry data in `essentials.geofence_boundaries`
-- joined to `essentials.districts`. Also adds name fields to the returned jsonb
-- so the set-location consumer can denormalise district names without a second
-- round-trip.
--
-- Breaking change in return shape (additive only):
--   Before: 5 keys  — congressional, state_senate, state_house, county, school_district
--   After:  10 keys — above + _name variants for each
--
-- The set-location route in connect.ts already reads *_name keys; this migration
-- makes those keys non-null for users inside loaded geofence boundaries.
--
-- Prerequisites:
--   - Migration 031: connect.connected_profiles location columns
--   - Migration 032: original upsert_user_location (unchanged here)
--   - Essentials schema populated with geofence_boundaries + districts
--   - Extensions: pgcrypto, postgis enabled; Vault secret 'location_encryption_key'
--
-- Idempotency: CREATE OR REPLACE is inherently idempotent.
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
  v_point         public.geometry;
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

  -- Decrypt: bytea → UTF8 text → float8.
  -- convert_from() required — bytea::text gives hex representation (\x...) not
  -- the original string. convert_from(bytea, 'UTF8') recovers the original text.
  -- extensions. prefix required; pgcrypto installs into extensions schema in Supabase.
  v_lat := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key), 'UTF8')::float8;
  v_lng := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key), 'UTF8')::float8;

  -- Build geometry point: ST_MakePoint(longitude, latitude) — X=lng, Y=lat per PostGIS convention.
  -- LONGITUDE FIRST. SRID 4326 (WGS84) must match geofence_boundaries.geometry SRID.
  -- public. prefix required; PostGIS installs into public schema in this Supabase project.
  -- (pgcrypto installs into extensions schema; PostGIS installs into public schema.)
  v_point := public.ST_SetSRID(public.ST_MakePoint(v_lng, v_lat), 4326);

  -- Query live geometry from essentials schema.
  -- MTFCC-to-district_type join condition prevents cross-matching (e.g., SLDU rows
  -- matching NATIONAL_LOWER districts). Only the 5 district types returned by this RPC
  -- are included — LOCAL, LOCAL_EXEC, JUDICIAL are intentionally excluded here.
  -- ST_Covers preferred over ST_Contains: handles boundary-coincident points correctly.
  -- public. prefix for PostGIS functions (PostGIS installs into public, not extensions).
  -- MAX(x) FILTER pattern aggregates all matching districts per type in one scan.
  -- Raw coordinates (v_lat, v_lng) are never included in the return value.
  SELECT jsonb_build_object(
    'congressional',        MAX(d.geo_id)  FILTER (WHERE d.district_type = 'NATIONAL_LOWER'),
    'congressional_name',   MAX(d.label)   FILTER (WHERE d.district_type = 'NATIONAL_LOWER'),
    'state_senate',         MAX(d.geo_id)  FILTER (WHERE d.district_type = 'STATE_UPPER'),
    'state_senate_name',    MAX(d.label)   FILTER (WHERE d.district_type = 'STATE_UPPER'),
    'state_house',          MAX(d.geo_id)  FILTER (WHERE d.district_type = 'STATE_LOWER'),
    'state_house_name',     MAX(d.label)   FILTER (WHERE d.district_type = 'STATE_LOWER'),
    'county',               MAX(d.geo_id)  FILTER (WHERE d.district_type = 'COUNTY'),
    'county_name',          MAX(d.label)   FILTER (WHERE d.district_type = 'COUNTY'),
    'school_district',      MAX(d.geo_id)  FILTER (WHERE d.district_type = 'SCHOOL'),
    'school_district_name', MAX(d.label)   FILTER (WHERE d.district_type = 'SCHOOL')
  )
  INTO v_result
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id
    AND (
      (gb.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
      OR (gb.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER')
      OR (gb.mtfcc = 'G5200' AND d.district_type = 'NATIONAL_LOWER')
      OR (gb.mtfcc = 'G4020' AND d.district_type = 'COUNTY')
      OR (gb.mtfcc IN ('G5400', 'G5410', 'G5420') AND d.district_type = 'SCHOOL')
    )
  WHERE public.ST_Covers(gb.geometry, v_point);

  RETURN v_result;
END;
$$;
