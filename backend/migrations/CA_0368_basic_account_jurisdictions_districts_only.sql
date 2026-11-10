-- CA_0368 — basic accounts can add an address; we keep only the districts.
BEGIN;

-- Design: docs/superpowers/specs/2026-11-07-basic-account-address-districts-only-design.md
-- Decided 2026-11-07, Chris Andrews ("Districts only").
--
-- Three things:
--
-- 1. inform.account_jurisdictions — the resolved districts of a BASIC account. One row per
--    account, nothing else: no street address, no point, no vault seal.
--    🔴 It is NOT connect.connected_profiles, on purpose. A row there is what makes an
--    account Connected (requireConnected / requireInform in middleware/tierGuards.ts), so
--    writing a basic account's districts there would promote it.
--
-- 2. connect.resolve_jurisdiction_at_point(lat, lng) and
--    connect.resolve_congressional_2026_at_point(lat, lng) — the bodies of the two
--    user-keyed resolvers, taking the point as arguments. A basic account has no stored
--    point to decrypt, so it needs a resolver that never reads one.
--
-- 3. connect.resolve_user_jurisdiction(user) and connect.resolve_congressional_2026(user)
--    become thin wrappers: decrypt the stored point exactly as before, then call the
--    point function. The post-verify gate below proves they still return the SAME answer
--    for every Connected profile that has a point, captured before the replacement.
--
-- Nothing is overwritten except the two function bodies, which are recorded verbatim in
-- the repo history (CC_0038 and 1383) and re-created here with identical logic.

-- ── Answers before the change, for the gate ─────────────────────────────────────────
CREATE TEMP TABLE _ca0368_before ON COMMIT DROP AS
SELECT user_id,
       connect.resolve_user_jurisdiction(user_id) AS j,
       connect.resolve_congressional_2026(user_id) AS c26
  FROM connect.connected_profiles
 WHERE encrypted_lat IS NOT NULL
   AND encrypted_lng IS NOT NULL
   AND location_consent = true;

-- ── 1. The table ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inform.account_jurisdictions (
  user_id                     uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  congressional_geo_id        text,
  congressional_district_name text,
  state_senate_geo_id         text,
  state_senate_district_name  text,
  state_house_geo_id          text,
  state_house_district_name   text,
  county_geo_id               text,
  county_name                 text,
  school_district_geo_id      text,
  school_district_name        text,
  city_council_geo_id         text,
  city_council_district_name  text,
  municipality_geo_id         text,
  -- The geocoder's USPS code and place NAME ('NC', 'ASHEVILLE'), as on connected_profiles.
  jurisdiction_state          text,
  jurisdiction_city           text,
  -- Census FIPS place geoids ('37', '3702140').
  city_geo_id                 text,
  state_geo_id                text,
  nation_geo_id               text,
  -- When the districts were resolved. A basic row is never re-resolved (there is no point
  -- to re-resolve from), so this is how a future boundary reload finds rows to re-ask.
  resolved_at                 timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE inform.account_jurisdictions IS
  'CA_0368: resolved districts of a BASIC account. Districts only — never a street address or a point. '
  'Connected accounts keep theirs on connect.connected_profiles; a row there is what makes an account Connected.';

-- Default-deny. Only the API (ev_api, BYPASSRLS) and service_role touch it; no front end
-- reads it through PostgREST.
ALTER TABLE inform.account_jurisdictions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON inform.account_jurisdictions FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON inform.account_jurisdictions TO ev_api, service_role;

-- ── 2. Point resolvers ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION connect.resolve_jurisdiction_at_point(p_lat double precision, p_lng double precision)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_point         public.geometry;
  v_result        jsonb;
  v_cc_geo_id     text;
  v_cc_label      text;
  v_muni_geo_id   text;
BEGIN
  IF p_lat IS NULL OR p_lng IS NULL THEN
    RAISE EXCEPTION 'resolve_jurisdiction_at_point: lat and lng are required';
  END IF;

  v_point := public.ST_SetSRID(public.ST_MakePoint(p_lng, p_lat), 4326);

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
      CASE WHEN gb.mtfcc LIKE 'X%' THEN 0 ELSE 1 END,
      CASE WHEN d.geo_id LIKE '%/place:%' THEN 0
           WHEN d.geo_id LIKE '%/county:%' THEN 1
           ELSE 2 END,
      d.geo_id
    LIMIT 1;

  SELECT d.geo_id
    INTO v_muni_geo_id
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
      AND d.district_type = 'LOCAL_EXEC'
    WHERE public.ST_Covers(gb.geometry, v_point)
      AND gb.mtfcc IN ('G4110', 'G4040', 'G4120')
    ORDER BY d.geo_id
    LIMIT 1;

  v_result := v_result || jsonb_build_object(
    'city_council',      v_cc_geo_id,
    'city_council_name', v_cc_label,
    'municipality',      v_muni_geo_id
  );

  -- City, state and nation, read straight from the boundary layers by mtfcc (see
  -- CC_0038 for why not via essentials.districts, and why nation is resolved, not
  -- asserted). city is null for unincorporated addresses, and that is correct.
  v_result := v_result || jsonb_build_object(
    'city',   (SELECT gb.geo_id FROM essentials.geofence_boundaries gb
                WHERE gb.mtfcc = 'G4110'
                  AND public.ST_Covers(gb.geometry, v_point)
                ORDER BY gb.geo_id LIMIT 1),
    'state',  (SELECT gb.geo_id FROM essentials.geofence_boundaries gb
                WHERE gb.mtfcc = 'G4000' AND gb.geo_id <> 'US'
                  AND public.ST_Covers(gb.geometry, v_point)
                ORDER BY gb.geo_id LIMIT 1),
    'nation', (SELECT gb.geo_id FROM essentials.geofence_boundaries gb
                WHERE gb.mtfcc = 'G4000' AND gb.geo_id = 'US'
                  AND public.ST_Covers(gb.geometry, v_point)
                LIMIT 1)
  );

  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION connect.resolve_congressional_2026_at_point(p_lat double precision, p_lng double precision)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_point  public.geometry;
  v_geo_id text;
BEGIN
  IF p_lat IS NULL OR p_lng IS NULL THEN
    RETURN NULL;
  END IF;

  v_point := public.ST_SetSRID(public.ST_MakePoint(p_lng, p_lat), 4326);

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

-- ── 3. The user-keyed resolvers become wrappers ──────────────────────────────────────
CREATE OR REPLACE FUNCTION connect.resolve_user_jurisdiction(p_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_key           text;
  v_encrypted_lat bytea;
  v_encrypted_lng bytea;
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

  IF v_encrypted_lat IS NULL THEN
    RAISE EXCEPTION 'no location on file for user %', p_user_id;
  END IF;

  RETURN connect.resolve_jurisdiction_at_point(
    convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key), 'UTF8')::float8,
    convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key), 'UTF8')::float8
  );
END;
$function$;

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

  RETURN connect.resolve_congressional_2026_at_point(
    convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key), 'UTF8')::float8,
    convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key), 'UTF8')::float8
  );
END;
$function$;

-- A fresh CREATE grants EXECUTE to PUBLIC; CREATE OR REPLACE keeps the existing ACL. Set
-- all four explicitly to the existing resolvers' ACL: service_role only (the API calls
-- them through adminRpc).
REVOKE ALL ON FUNCTION connect.resolve_jurisdiction_at_point(double precision, double precision) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION connect.resolve_congressional_2026_at_point(double precision, double precision) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION connect.resolve_user_jurisdiction(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION connect.resolve_congressional_2026(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION connect.resolve_jurisdiction_at_point(double precision, double precision) TO service_role;
GRANT EXECUTE ON FUNCTION connect.resolve_congressional_2026_at_point(double precision, double precision) TO service_role;
GRANT EXECUTE ON FUNCTION connect.resolve_user_jurisdiction(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION connect.resolve_congressional_2026(uuid) TO service_role;

-- ── Post-verify gate ─────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n        int;
  v_diff     int;
  v_atlantic jsonb;
BEGIN
  SELECT count(*) INTO v_n FROM _ca0368_before;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'CA_0368: compared 0 Connected profiles — the gate below would pass on nothing';
  END IF;

  -- The wrappers must give every Connected profile exactly the answer it got before.
  SELECT count(*) INTO v_diff
    FROM _ca0368_before b
   WHERE connect.resolve_user_jurisdiction(b.user_id) IS DISTINCT FROM b.j
      OR connect.resolve_congressional_2026(b.user_id) IS DISTINCT FROM b.c26;
  IF v_diff <> 0 THEN
    RAISE EXCEPTION 'CA_0368: % of % Connected profiles resolve differently after the wrapper change', v_diff, v_n;
  END IF;

  -- Positive control: a point in the Atlantic resolves to nothing, not to a nation.
  v_atlantic := connect.resolve_jurisdiction_at_point(30.0, -50.0);
  IF v_atlantic->>'nation' IS NOT NULL OR v_atlantic->>'congressional' IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0368: the Atlantic control resolved to something: %', v_atlantic;
  END IF;

  IF has_table_privilege('anon', 'inform.account_jurisdictions', 'SELECT')
     OR has_table_privilege('authenticated', 'inform.account_jurisdictions', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0368: anon or authenticated can read inform.account_jurisdictions';
  END IF;

  IF has_function_privilege('anon', 'connect.resolve_jurisdiction_at_point(double precision, double precision)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'connect.resolve_jurisdiction_at_point(double precision, double precision)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0368: anon or authenticated can execute resolve_jurisdiction_at_point';
  END IF;

  RAISE NOTICE 'CA_0368: % Connected profiles resolve identically through the wrappers', v_n;
END $$;

COMMIT;
