-- =============================================================================
-- Migration 047: Add city council district columns to connect.connected_profiles
--
-- Adds two new columns to store the user's resolved city council district,
-- extends the resolve_user_jurisdiction RPC to return city_council keys,
-- and backfills existing users who have location_consent = true.
--
-- Section 1: ALTER TABLE — two new nullable text columns
-- Section 2: CREATE OR REPLACE resolve_user_jurisdiction — adds city_council
--            and city_council_name keys via a second PostGIS lookup.
--            Selection logic prefers sub-city (X% MTFCC) over city-wide
--            (G4040/G4110/G4120) to surface the most specific council district.
-- Section 3: Backfill — calls the updated RPC for all users with
--            location_consent = true and city_council_geo_id IS NULL.
--
-- Idempotency:
--   - ADD COLUMN IF NOT EXISTS is safe to re-run.
--   - CREATE OR REPLACE is inherently idempotent.
--   - UPDATE ... WHERE city_council_geo_id IS NULL is a no-op on second run.
--
-- Prerequisites:
--   - Migration 045: connect.resolve_user_jurisdiction (base RPC)
--   - Migration 046: pattern for resolve_user_local_officials (X% MTFCC reference)
--   - essentials.geofence_boundaries + essentials.districts populated with LOCAL rows
--   - Extensions: pgcrypto (extensions schema), postgis (public schema)
--   - Vault secret: 'location_encryption_key'
-- =============================================================================

-- =============================================================================
-- Section 1: Add columns
-- =============================================================================

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS city_council_geo_id TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS city_council_district_name TEXT DEFAULT NULL;

-- =============================================================================
-- Section 2: Extend resolve_user_jurisdiction RPC
--
-- Replaces the migration 045 version. All existing 10 keys remain unchanged.
-- Adds city_council and city_council_name keys via a separate SELECT...INTO.
--
-- City council selection logic (user can be inside multiple LOCAL boundaries):
--   - Prefer X% MTFCC (sub-city ward/district boundaries) over G4040/G4110/G4120
--     (city-wide boundaries). X% rows are more specific; they represent actual
--     council districts whereas G4040 is just the incorporated place boundary.
--   - If multiple X% matches exist, pick alphabetically-first geo_id (deterministic).
--   - If no X% match, fall back to city-wide LOCAL (G4040/G4110/G4120).
--   - Returns NULL city_council + city_council_name if no LOCAL district found
--     (user outside any loaded city boundaries — not an error).
--
-- MTFCC references:
--   G4040          → incorporated place (city boundary) — LOCAL / LOCAL_EXEC
--   G4110, G4120   → consolidated city variants         — LOCAL / LOCAL_EXEC
--   X%             → custom sub-city boundaries         — LOCAL only
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
  v_cc_geo_id     text;
  v_cc_label      text;
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

  -- Resolve city council district: prefer sub-city (X% MTFCC) over city-wide
  -- (G4040/G4110/G4120). If multiple X% rows exist, pick alphabetically-first
  -- geo_id for a deterministic result. Falls back to city-wide if no X% match.
  -- Returns NULL if user is outside all loaded LOCAL boundaries (not an error).
  SELECT d.geo_id, d.label
    INTO v_cc_geo_id, v_cc_label
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
      AND d.district_type = 'LOCAL'
    WHERE public.ST_Covers(gb.geometry, v_point)
      AND (
        gb.mtfcc LIKE 'X%'
        OR gb.mtfcc IN ('G4040', 'G4110', 'G4120')
      )
    ORDER BY
      CASE WHEN gb.mtfcc LIKE 'X%' THEN 0 ELSE 1 END,  -- prefer sub-city (X%) first
      d.geo_id                                            -- deterministic tiebreak within tier
    LIMIT 1;

  -- Append city_council keys to the existing result object.
  -- NULL values are included explicitly so callers receive a consistent shape.
  v_result := v_result || jsonb_build_object(
    'city_council',      v_cc_geo_id,
    'city_council_name', v_cc_label
  );

  RETURN v_result;
END;
$$;

-- =============================================================================
-- Section 3: Backfill existing users
--
-- For all connected users with location_consent = true who do not yet have
-- city_council_geo_id populated, call the updated RPC and write the result.
-- Pattern mirrors Phase 49 migration backfill (migration 043/044).
-- WHERE city_council_geo_id IS NULL makes this a no-op on second run.
-- =============================================================================

UPDATE connect.connected_profiles cp
SET
  city_council_geo_id = (j->>'city_council'),
  city_council_district_name = (j->>'city_council_name')
FROM (
  SELECT user_id, connect.resolve_user_jurisdiction(user_id) AS j
  FROM connect.connected_profiles
  WHERE location_consent = true
    AND city_council_geo_id IS NULL
) sub
WHERE cp.user_id = sub.user_id;
