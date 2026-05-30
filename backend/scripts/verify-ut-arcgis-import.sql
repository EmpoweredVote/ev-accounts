\set ON_ERROR_STOP on
-- Phase 132 verification (D-13). Run after all Phase 132 loaders complete.
-- Asserts per-layer row counts. Any FAIL aborts the script with non-zero exit.

\echo '=== GEO-03: Salt Lake County Council (expected 6, mtfcc=X0001) ==='
DO $$
DECLARE c int;
BEGIN
  SELECT COUNT(*) INTO c FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0001'
     AND geo_id LIKE 'ocd-division/country:us/state:ut/county:salt_lake/council_district:%';
  IF c <> 6 THEN RAISE EXCEPTION 'GEO-03 FAIL: SL County council expected 6, got %', c; END IF;
  RAISE NOTICE 'GEO-03 PASS: SL County council = 6';
END $$;

\echo '=== GEO-04 (SLC): Salt Lake City wards (expected 7, mtfcc=X0001) ==='
DO $$
DECLARE c int;
BEGIN
  SELECT COUNT(*) INTO c FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0001'
     AND geo_id LIKE 'ocd-division/country:us/state:ut/place:salt_lake_city/ward:%';
  IF c <> 7 THEN RAISE EXCEPTION 'GEO-04(SLC) FAIL: SLC wards expected 7, got %', c; END IF;
  RAISE NOTICE 'GEO-04(SLC) PASS: SLC wards = 7';
END $$;

\echo '=== GEO-04 (Provo): Provo wards (expected 5, mtfcc=X0001, source=manual_digitize) ==='
DO $$
DECLARE c int;
BEGIN
  SELECT COUNT(*) INTO c FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0001'
     AND geo_id LIKE 'ocd-division/country:us/state:ut/place:provo/ward:%'
     AND source LIKE 'manual_digitize_provo_wards_2026_pdf%';
  IF c <> 5 THEN RAISE EXCEPTION 'GEO-04(Provo) FAIL: Provo wards expected 5 (manual_digitize), got %', c; END IF;
  RAISE NOTICE 'GEO-04(Provo) PASS: Provo wards = 5 (manual_digitize)';
END $$;

\echo '=== GEO-06: State Board of Education sub-districts (expected 15, mtfcc=X0003) ==='
DO $$
DECLARE c int;
BEGIN
  SELECT COUNT(*) INTO c FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0003'
     AND geo_id LIKE 'ocd-division/country:us/state:ut/sboe:%';
  IF c <> 15 THEN RAISE EXCEPTION 'GEO-06 FAIL: SBOE expected 15, got %', c; END IF;
  RAISE NOTICE 'GEO-06 PASS: SBOE = 15';
END $$;

\echo '=== GEO-07: Tribal aiannh polygons (expected 6-11, mtfcc=X0004) ==='
DO $$
DECLARE c int;
BEGIN
  SELECT COUNT(*) INTO c FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0004'
     AND geo_id LIKE 'ocd-division/country:us/state:ut/tribe:%';
  IF c < 6 OR c > 11 THEN RAISE EXCEPTION 'GEO-07 FAIL: aiannh expected 6-11, got %', c; END IF;
  RAISE NOTICE 'GEO-07 PASS: aiannh = %', c;
END $$;

\echo '=== SCHEMA-01: STATE_BOARD enum value present ==='
DO $$
BEGIN
  PERFORM 'STATE_BOARD'::district_type;
  RAISE NOTICE 'SCHEMA-01 PASS: STATE_BOARD castable';
EXCEPTION WHEN invalid_text_representation THEN
  RAISE EXCEPTION 'SCHEMA-01 FAIL: STATE_BOARD not in district_type enum';
END $$;

\echo '=== GEO-08 carryover: zero invalid UT geometries ==='
DO $$
DECLARE c int;
BEGIN
  SELECT COUNT(*) INTO c FROM essentials.geofence_boundaries
   WHERE state = '49' AND NOT public.ST_IsValid(geometry);
  IF c <> 0 THEN RAISE EXCEPTION 'GEO-08 FAIL: % invalid geometries in UT', c; END IF;
  RAISE NOTICE 'GEO-08 PASS: zero invalid UT geometries';
END $$;

\echo '=== Phase 131 baseline preserved (cd119/sldu/sldl/unsd/place/county untouched) ==='
DO $$
DECLARE c int;
BEGIN
  SELECT COUNT(*) INTO c FROM essentials.geofence_boundaries
   WHERE state = '49' AND mtfcc = 'G4020';
  IF c <> 29 THEN RAISE EXCEPTION 'BASELINE FAIL: UT G4020 (counties) expected 29, got %', c; END IF;
  RAISE NOTICE 'BASELINE PASS: UT counties = 29';
END $$;

\echo '=== ALL ASSERTIONS PASSED ==='
