-- Migration 063: fix resolve_user_jurisdiction city council district ordering
--
-- Root cause: county supervisor district boundaries (e.g. county:los_angeles/council_district:2,
-- a large west-LA-County polygon) and city council district boundaries both use mtfcc X0001.
-- When both cover the user's coordinates, LIMIT 1 with ORDER BY d.geo_id picks the county
-- record first because "county" < "place" alphabetically. This causes the wrong district to
-- be stored (e.g. Supervisor District 2 instead of City Council District 11 for 90066).
--
-- Fix: add a secondary sort key that prefers /place: geo_ids over /county: ones.
-- City council districts live under /place:<city_name>; county supervisor districts live
-- under /county:<county_name>. The place-level record is always the correct city council hit.

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

  -- City council district: prefer place-scoped geo_ids over county-scoped ones.
  -- County supervisor districts share the same mtfcc (X0001) and district_type (LOCAL)
  -- as city council districts but have geo_ids under /county:<name>/ rather than
  -- /place:<name>/. Without this ordering a large county supervisor boundary can
  -- shadow the smaller city council boundary when both cover the same point.
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

  v_result := v_result || jsonb_build_object(
    'city_council',      v_cc_geo_id,
    'city_council_name', v_cc_label
  );

  RETURN v_result;
END;
$function$
