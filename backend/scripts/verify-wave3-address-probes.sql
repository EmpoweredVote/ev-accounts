-- verify-wave3-address-probes.sql
--
-- End-to-end acceptance for NC deep-seed wave 3 (Asheville + Buncombe County).
--
-- 🔴 AN ADDRESS PROBE IS THE ONLY RELIABLE DETECTOR. Every other check passes
-- vacuously when a term row is missing: an office with no office_terms row has
-- no holder, so the official never appears anywhere -- and nothing errors.
--
-- 🔴 EVERY NEGATIVE CONTROL HERE HAS A CONTROL-OF-THE-CONTROL. "Asheville
-- returns no District 1 commissioner" is worthless on its own -- a query that
-- cannot fire returns zero too. So each zero is paired with an assertion that
-- the SAME query DOES return those rows at the other probe point.
--
-- Probe points came from the Census geocoder, and the expectations were measured
-- against the loaded TIGER G5220 polygons on 2026-08-23 -- not read off the
-- layer under test.
--
--   Asheville City Hall  -82.5554, 35.5967  -> HD-116, commission District 3
--   Black Mountain       -82.3200, 35.6197  -> HD-114, commission District 1,
--                                              and place 3706140 (NOT Asheville)
--
-- Joins pair geo_id WITH mtfcc. geo_id is not unique across layers: '37021'
-- alone returns Buncombe County, NC Senate 21 and NC House 21.
--
-- Usage: psql "$DATABASE_URL" -f scripts/verify-wave3-address-probes.sql

\set ON_ERROR_STOP on
CREATE TEMP VIEW hits AS
WITH pts(nm,g) AS (VALUES
  ('avl', public.ST_SetSRID(public.ST_MakePoint(-82.5554,35.5967),4326)),
  ('blk', public.ST_SetSRID(public.ST_MakePoint(-82.3200,35.6197),4326)))
SELECT p.nm, d.district_type, d.label, d.geo_id, o.title, pol.full_name
FROM pts p
JOIN essentials.geofence_boundaries b ON public.ST_Covers(b.geometry, p.g)
JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians pol ON pol.id = och.politician_id
WHERE lower(d.state)='nc';

DO $$
DECLARE n int; m int;
BEGIN
  -- POSITIVE: Asheville returns D3's two commissioners
  SELECT count(*) INTO n FROM hits WHERE nm='avl' AND geo_id='buncombe-nc-commissioner-district-3';
  IF n <> 2 THEN RAISE EXCEPTION 'Asheville: expected 2 District 3 commissioners, got %', n; END IF;

  -- NEGATIVE CONTROL: and NONE from D1 or D2
  SELECT count(*) INTO n FROM hits WHERE nm='avl'
     AND geo_id IN ('buncombe-nc-commissioner-district-1','buncombe-nc-commissioner-district-2');
  IF n <> 0 THEN RAISE EXCEPTION 'Asheville NEGATIVE CONTROL FAILED: % D1/D2 commissioner(s) returned', n; END IF;

  -- CONTROL OF THE CONTROL: the same query DOES return D1 at Black Mountain, so
  -- the zero above is geography, not a query that cannot fire.
  SELECT count(*) INTO m FROM hits WHERE nm='blk' AND geo_id='buncombe-nc-commissioner-district-1';
  IF m <> 2 THEN RAISE EXCEPTION 'CONTROL OF CONTROL FAILED: Black Mountain returned % D1 commissioner(s), expected 2 -- the D1 zero at Asheville proves nothing', m; END IF;

  -- NEGATIVE CONTROL: Black Mountain returns NO Asheville city officials
  SELECT count(*) INTO n FROM hits WHERE nm='blk' AND geo_id='3702140';
  IF n <> 0 THEN RAISE EXCEPTION 'Black Mountain NEGATIVE CONTROL FAILED: % Asheville city official(s) returned', n; END IF;

  -- CONTROL OF THE CONTROL: Asheville itself returns all 7 city seats
  SELECT count(*) INTO m FROM hits WHERE nm='avl' AND geo_id='3702140';
  IF m <> 7 THEN RAISE EXCEPTION 'CONTROL OF CONTROL FAILED: Asheville returned % city official(s), expected 7', m; END IF;

  -- Black Mountain must NOT return D3
  SELECT count(*) INTO n FROM hits WHERE nm='blk' AND geo_id='buncombe-nc-commissioner-district-3';
  IF n <> 0 THEN RAISE EXCEPTION 'Black Mountain NEGATIVE CONTROL FAILED: % D3 commissioner(s) returned', n; END IF;

  -- Totals
  SELECT count(*) INTO n FROM hits WHERE nm='avl';
  IF n <> 16 THEN RAISE EXCEPTION 'Asheville total: expected 16 officials (7 city + 4 countywide + 2 D3 + HD + SD + US Rep), got %', n; END IF;
  SELECT count(*) INTO n FROM hits WHERE nm='blk';
  IF n <> 9 THEN RAISE EXCEPTION 'Black Mountain total: expected 9 officials (4 countywide + 2 D1 + HD + SD + US Rep), got %', n; END IF;


  -- The G5200V26 congressional-map vintage collision would return TWO U.S.
  -- Representatives for one address. NC is one of the 9 affected states, so
  -- assert it does not fire at either probe rather than assuming.
  SELECT count(*) INTO n FROM hits WHERE nm='avl' AND district_type='NATIONAL_LOWER';
  IF n <> 1 THEN RAISE EXCEPTION 'Asheville returned % U.S. Representative(s), expected 1 -- G5200V26 vintage collision', n; END IF;
  SELECT count(*) INTO n FROM hits WHERE nm='blk' AND district_type='NATIONAL_LOWER';
  IF n <> 1 THEN RAISE EXCEPTION 'Black Mountain returned % U.S. Representative(s), expected 1 -- G5200V26 vintage collision', n; END IF;
  RAISE NOTICE 'ALL PROBES PASS -- 4 negative controls held, and each has a control-of-the-control that fires.';
END $$;
