-- verify-lake-council-probes.sql
-- Knight Foundation program, wave IN-9 acceptance evidence. READ-ONLY.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-lake-council-probes.sql
--
-- Asserts that an address in each of Lake County's seven council districts returns ONE council
-- member, and the RIGHT one. 🔴 This is the only reliable detector: `check:reachability` is green
-- when nothing was swept, and a count of offices is green when every one of them is unreachable.
--
-- THE ANCHORS ARE MEASURED, NOT INVENTED. Each is an interior point of a municipal polygon taken
-- from the Lake County Surveyor's own `Cities` layer
-- (services5.arcgis.com/8CXRnvSfSpwdf0R6/.../Cities/FeatureServer/0), computed 2026-09-11.
--
--   D1 Munster · D2 Griffith · D3 Lake Station · D4 Schererville
--   D5 Whiting · D6 Merrillville · D7 Lowell
--
-- ⚠ FIVE OF THE SEVEN SIT IN A MUNICIPALITY THAT LIES WHOLLY INSIDE ITS DISTRICT (Munster, Lake
-- Station, Whiting, Merrillville, Lowell). Griffith is split D2/D6 and Schererville D4/D6, so
-- those two anchors are interior points that were individually measured into D2 and D4. District 2
-- has NO wholly-contained municipality -- Gary, Highland and Griffith are all split -- which is a
-- fact about the map, not a weakness in the probe.

\echo ''
\echo '=== 1. CONTROL ON THE PROBE ITSELF: do all seven anchors land in Lake County? ==='

WITH anchors(d, lon, lat, place) AS (VALUES
  ('1', -87.50072, 41.55323, 'Munster'),
  ('2', -87.42495, 41.53067, 'Griffith'),
  ('3', -87.26410, 41.56675, 'Lake Station'),
  ('4', -87.43964, 41.48126, 'Schererville'),
  ('5', -87.48479, 41.67806, 'Whiting'),
  ('6', -87.32065, 41.47517, 'Merrillville'),
  ('7', -87.41645, 41.29477, 'Lowell'))
SELECT a.d, a.place, gb.geo_id AS county, (gb.geo_id = '18089') AS in_lake_county
FROM anchors a
LEFT JOIN essentials.geofence_boundaries gb
  ON gb.mtfcc = 'G4020'
 AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon, a.lat), 4326))
ORDER BY a.d;

\echo ''
\echo '=== 2. THE PROBE: what council member does each anchor return? ==='

WITH anchors(d, lon, lat, place) AS (VALUES
  ('1', -87.50072, 41.55323, 'Munster'),
  ('2', -87.42495, 41.53067, 'Griffith'),
  ('3', -87.26410, 41.56675, 'Lake Station'),
  ('4', -87.43964, 41.48126, 'Schererville'),
  ('5', -87.48479, 41.67806, 'Whiting'),
  ('6', -87.32065, 41.47517, 'Merrillville'),
  ('7', -87.41645, 41.29477, 'Lowell'))
SELECT a.d AS expect_district, a.place, d.label, o.title,
       p.full_name AS holder, ot.start_precision
FROM anchors a
JOIN essentials.geofence_boundaries gb
  ON gb.mtfcc = 'X0051'
 AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon, a.lat), 4326))
JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
LEFT JOIN essentials.politicians p ON p.id = och.politician_id
LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id AND ot.politician_id = och.politician_id
ORDER BY a.d;

\echo ''
\echo '=== 3. GATE ==='

DO $$
DECLARE
  r record; v_hits int; v_holder text; v_outside int; v_total int;
  expected CONSTANT text[] := ARRAY['David Hamm','Ronald G. Brewer Sr.','Charlie Brown',
                                    'Pete Lindemulder','Christine Cid','Ted Bilski','Randy Niemeyer'];
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('1', -87.50072, 41.55323, 'Munster'),
      ('2', -87.42495, 41.53067, 'Griffith'),
      ('3', -87.26410, 41.56675, 'Lake Station'),
      ('4', -87.43964, 41.48126, 'Schererville'),
      ('5', -87.48479, 41.67806, 'Whiting'),
      ('6', -87.32065, 41.47517, 'Merrillville'),
      ('7', -87.41645, 41.29477, 'Lowell')) AS t(d, lon, lat, place)
  LOOP
    -- exactly one council district office, and it is the expected one, with a named holder
    SELECT count(*), min(p.full_name) INTO v_hits, v_holder
      FROM essentials.geofence_boundaries gb
      JOIN essentials.districts dd ON dd.geo_id = gb.geo_id AND dd.mtfcc = gb.mtfcc
      JOIN essentials.offices o ON o.district_id = dd.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE gb.mtfcc = 'X0051'
       AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(r.lon, r.lat), 4326));

    IF v_hits <> 1 THEN
      RAISE EXCEPTION 'IN-9 probe: % (expected District %) returns % council district office(s), expected exactly 1. More than one means overlapping polygons; none means the address reaches nobody.',
        r.place, r.d, v_hits;
    END IF;
    IF v_holder IS NULL THEN
      RAISE EXCEPTION 'IN-9 probe: % (District %) returns an office with NO holder -- office_current_holder LEFT JOINs, so this is the vacancy shape, not a missing row.', r.place, r.d;
    END IF;
    IF v_holder IS DISTINCT FROM expected[r.d::int] THEN
      RAISE EXCEPTION 'IN-9 probe: % returns "%", expected "%" for District %.',
        r.place, v_holder, expected[r.d::int], r.d;
    END IF;
    RAISE NOTICE '  ✓ % -> District % -> %', r.place, r.d, v_holder;
  END LOOP;

  -- 🔴 NEGATIVE CONTROL. A probe that says "yes" everywhere says nothing. Fort Wayne is in Allen
  -- County and must return ZERO Lake County council districts.
  SELECT count(*) INTO v_outside
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'X0051'
     AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-85.13935, 41.07937), 4326));
  IF v_outside <> 0 THEN
    RAISE EXCEPTION 'IN-9 probe NEGATIVE CONTROL FAILED: a Fort Wayne point matches % Lake council district(s) -- the polygons are wrong or ST_Covers is matching everything.', v_outside;
  END IF;
  RAISE NOTICE '  ✓ negative control: Fort Wayne returns 0 Lake council districts';

  -- The seven anchors must reach seven DISTINCT districts, or the probe is not discriminating.
  SELECT count(DISTINCT gb.geo_id) INTO v_total
    FROM (VALUES (-87.50072, 41.55323), (-87.42495, 41.53067), (-87.26410, 41.56675),
                 (-87.43964, 41.48126), (-87.48479, 41.67806), (-87.32065, 41.47517),
                 (-87.41645, 41.29477)) AS a(lon, lat)
    JOIN essentials.geofence_boundaries gb
      ON gb.mtfcc = 'X0051'
     AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(a.lon, a.lat), 4326));
  IF v_total <> 7 THEN
    RAISE EXCEPTION 'IN-9 probe: the seven anchors reach only % distinct district(s) -- the probe does not discriminate, so its agreement proves nothing.', v_total;
  END IF;

  RAISE NOTICE 'IN-9 probe OK: 7 anchors, 7 distinct districts, 7 correct holders, negative control clean';
END $$;
