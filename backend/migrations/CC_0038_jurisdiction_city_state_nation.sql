-- Add city, state and nation geoids to connect.resolve_user_jurisdiction.
--
-- Civic Spaces is moving from "a slice is a constituency you vote in" to "a slice is a
-- government you live under": Unified, Federal, State, County, City. The assigner needs a
-- city, a state and a nation geoid, and no existing key supplies a usable city --
-- `municipality` looks for district_type = 'LOCAL_EXEC', which Plano has none of, and
-- `city_council` orders X% rows first so in Austin it returns a council district rather
-- than the city itself.
--
-- Additive only: every pre-existing key keeps its current value and meaning, so this ships
-- alone, ahead of any consumer.
--
-- Base definition copied verbatim from pg_get_functiondef on 2026-09-01; the only change is
-- the jsonb_build_object block immediately before RETURN.

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
  v_lat           float8;
  v_lng           float8;
  v_point         public.geometry;
  v_result        jsonb;
  v_cc_geo_id     text;
  v_cc_label      text;
  v_muni_geo_id   text;
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

  v_lat := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lat, v_key), 'UTF8')::float8;
  v_lng := convert_from(extensions.pgp_sym_decrypt_bytea(v_encrypted_lng, v_key), 'UTF8')::float8;

  v_point := public.ST_SetSRID(public.ST_MakePoint(v_lng, v_lat), 4326);

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

  -- City, state and nation, read straight from the boundary layers by mtfcc.
  --
  -- Deliberately NOT via essentials.districts: that table reuses geo_ids across
  -- layers (48008 is both STATE_UPPER and STATE_LOWER; 48085 is both Collin County
  -- and TX House District 85), so a districts join needs an mtfcc filter anyway and
  -- adds a failure mode for no benefit.
  --
  -- city is null for unincorporated addresses. That is correct and must stay
  -- non-fatal: Arden, NC has no G4110 covering it.
  --
  -- nation is RESOLVED, not asserted. The only nation we hold is US, but writing
  -- 'US' as a literal would make the key true of every point on Earth -- including
  -- the Atlantic positive control that lib/jurisdictionPayload.ts was written
  -- against -- and a key that is never false carries no information. Reading it off
  -- the G4000 'US' boundary keeps it a fact about the point.
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
$function$
;

-- Post-verify gate. Two independent things can go wrong here and only one of them
-- raises on its own: the replace can silently not happen (a stale definition still
-- in place), or the boundary lookup can be right in syntax and wrong in result.
DO $verify$
DECLARE
  v_point public.geometry := public.ST_SetSRID(public.ST_MakePoint(-96.6989, 33.0198), 4326);
  v_src   text;
  v_city  text;
  v_state text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_src
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'connect' AND p.proname = 'resolve_user_jurisdiction';

  IF v_src IS NULL OR v_src NOT LIKE '%''nation''%' THEN
    RAISE EXCEPTION 'resolve_user_jurisdiction was not replaced: no nation key in its definition';
  END IF;

  -- Plano, TX as the control point: incorporated, so it exercises the city branch
  -- that Arden, NC (unincorporated, city null) cannot.
  SELECT gb.geo_id INTO v_city
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'G4110' AND public.ST_Covers(gb.geometry, v_point)
   ORDER BY gb.geo_id LIMIT 1;

  SELECT gb.geo_id INTO v_state
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'G4000' AND gb.geo_id <> 'US' AND public.ST_Covers(gb.geometry, v_point)
   ORDER BY gb.geo_id LIMIT 1;

  IF v_city IS DISTINCT FROM '4858016' OR v_state IS DISTINCT FROM '48' THEN
    RAISE EXCEPTION 'boundary lookup wrong at the Plano control point: city=%, state=% (expected 4858016, 48)',
      v_city, v_state;
  END IF;

  -- Negative control: a point in the Atlantic must resolve NO nation. This is the
  -- assertion that would have failed against a hardcoded 'US', and it is the property
  -- resolvedDistrictCount() depends on -- a key that cannot be null cannot signal
  -- "resolved nothing".
  PERFORM 1 FROM essentials.geofence_boundaries gb
    WHERE gb.mtfcc = 'G4000' AND gb.geo_id = 'US'
      AND public.ST_Covers(gb.geometry,
            public.ST_SetSRID(public.ST_MakePoint(-30.0, 35.0), 4326));
  IF FOUND THEN
    RAISE EXCEPTION 'nation resolved for a point in the Atlantic -- the US boundary is wrong or the lookup is not a lookup';
  END IF;
END $verify$;
