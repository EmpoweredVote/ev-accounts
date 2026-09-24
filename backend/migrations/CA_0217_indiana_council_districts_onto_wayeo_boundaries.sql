-- CA_0217_indiana_council_districts_onto_wayeo_boundaries.sql
--
-- Put 27 Indiana council seats onto the boundaries that scripts/load-indiana-wayeo-council-boundaries.ts
-- loads (mtfcc X0062, the Indiana GIO statewide county-council layer behind the Secretary of State's
-- "Who Are Your Elected Officials" lookup). Run the loader FIRST; this file refuses to run without them.
--
-- WHY (measured 2026-09-24)
-- -------------------------
--   15 seats sit on a district with NO geofence, so no address reaches them (they are the whole of the
--   reachability baseline UNREACHABLE in|COUNTY 15): Greene Council Districts 1-4, Lawrence 1-4,
--   Jackson 1, Morgan 4, and the five Indianapolis City-County Council seats in the data (8, 12, 13, 14,
--   18). Their districts already carry the geo_id the loader writes ('1805500001', '1809700012', ...);
--   only mtfcc changes, '' -> 'X0062', so readers of the district's own code (readrank frames, the
--   elections lateral) agree with the geofence.
--   12 more — Brown, Martin and Owen Council Districts 1-4 — sit on the WHOLE-COUNTY district (geo_id =
--   the county FIPS, G4020), so every resident of those counties is shown all four district members.
--   Each has its own district row (one office each, gated), which moves to its own boundary:
--   geo_id '18013' -> '1801300001' .. '1811900004', mtfcc G4020 -> X0062 — the id form the other eleven
--   and Monroe's council districts ('1810500001') already use.
--
-- WHAT A USER WILL SEE
-- --------------------
--   An address in Greene / Lawrence / Jackson / Morgan / Indianapolis now reaches its council member (the
--   15 were in browse since CA_0210, but no address reached them). An address in Brown / Martin / Owen
--   shows ONE district council member plus the three at-large members, instead of all four district
--   members. At-large seats, commissioners and row officers stay on the county-wide district.
--
-- THE BOUNDARIES (see the loader header for the full gate record)
-- ----------------------------------------------------------------
--   Vintage: every 2024 precinct of each county nests in one district (the current members were elected
--   on the 2022 maps). Controls: the same state layer equals Monroe's own county layer (0.000%), Allen's
--   Election Board layer (<= 0.005%) and Indianapolis's own City Council layer, General Ordinance 18, 2022
--   (0.000% in all 25). ⚠ Brown County merged its precincts for 2026 and the new JACKSON 2 crosses the
--   District 1 / 2 line — next-election geography, to check before seeding Brown's 2026 council races.
--
-- NOT CHANGED: no office, chamber, government, politician, term or race row; no other district.
--   Missing seats found on the way, not added here: Jackson has 3 of its 7 council seats (District 1 and
--   two at-large), Morgan 4 of 7 (District 4 and three at-large), Indianapolis 5 of 25.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: NOT APPLIED.
--
-- ROLLBACK:
--   UPDATE essentials.districts d SET geo_id = t.old_geo_id, mtfcc = t.old_mtfcc
--     FROM <ca0217_district below> t WHERE d.id = t.district_id;
--   (old_mtfcc is the stored value: '' — an empty string, not NULL — for the 15, 'G4020' for the 12.)
--   The X0062 boundary rows the loader wrote are harmless without a district; delete them only if the
--   loader itself is being undone.
-- IDEMPOTENT: the UPDATE is guarded on the old (geo_id, mtfcc); a re-run changes 0 rows and every gate passes.

BEGIN;

CREATE TEMP TABLE ca0217_district ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('877b4f41-18a2-47e3-a4fe-828679934328'::uuid, 'Brown County', '1', '18013', 'G4020', '1801300001'),
  ('d4a833bf-84f2-461d-8250-d70548e4f8c0'::uuid, 'Brown County', '2', '18013', 'G4020', '1801300002'),
  ('4ca0c134-c17a-4939-86ce-31939b6ee93f'::uuid, 'Brown County', '3', '18013', 'G4020', '1801300003'),
  ('46830b8e-dbeb-49ed-a4fb-10074ba2e7a9'::uuid, 'Brown County', '4', '18013', 'G4020', '1801300004'),
  ('abce55c8-f6c2-40cb-b920-1c4f38d5a5dc'::uuid, 'City of Indianapolis', '8', '1809700008', '', '1809700008'),
  ('2af14486-e240-4aa4-bf25-1771c2f35266'::uuid, 'City of Indianapolis', '12', '1809700012', '', '1809700012'),
  ('514e01b3-a06a-490e-9e89-da16aec083a3'::uuid, 'City of Indianapolis', '13', '1809700013', '', '1809700013'),
  ('58c7e560-957d-444a-9c8e-cd798a4bbb50'::uuid, 'City of Indianapolis', '14', '1809700014', '', '1809700014'),
  ('cf3de5f7-2500-4c51-9f24-bc2c349e8ca7'::uuid, 'City of Indianapolis', '18', '1809700018', '', '1809700018'),
  ('5d49971e-fcc4-424a-9844-f363a14d2b5f'::uuid, 'Greene County', '1', '1805500001', '', '1805500001'),
  ('d7999055-9288-42f5-ba72-06802d453bee'::uuid, 'Greene County', '2', '1805500002', '', '1805500002'),
  ('6a9fb33d-d7f1-4631-b147-3e3b16c20ad5'::uuid, 'Greene County', '3', '1805500003', '', '1805500003'),
  ('d70d25b5-993e-4bca-b754-2fb811a142d4'::uuid, 'Greene County', '4', '1805500004', '', '1805500004'),
  ('5c363e73-cf7a-453c-95cf-500dfb0c7419'::uuid, 'Jackson County', '1', '1807100001', '', '1807100001'),
  ('b03d0fd2-70f9-434b-aabf-d6fca9ae6be7'::uuid, 'Lawrence County', '1', '1809300001', '', '1809300001'),
  ('26cc2f29-01e2-4f7b-a680-29b1d7a8310e'::uuid, 'Lawrence County', '2', '1809300002', '', '1809300002'),
  ('31752516-281b-4ed1-b721-28368d3d5b20'::uuid, 'Lawrence County', '3', '1809300003', '', '1809300003'),
  ('6ca360f2-45f5-44aa-94bb-0340a5b5adc1'::uuid, 'Lawrence County', '4', '1809300004', '', '1809300004'),
  ('aa9db313-8c5d-40bf-9da9-bc1b248cc648'::uuid, 'Martin County', '1', '18101', 'G4020', '1810100001'),
  ('6ea62b56-a218-4544-8022-751a233a6e43'::uuid, 'Martin County', '2', '18101', 'G4020', '1810100002'),
  ('a18647c9-ffaa-4930-aa14-5e6f8a65e3ce'::uuid, 'Martin County', '3', '18101', 'G4020', '1810100003'),
  ('b50dab37-0c39-4937-b0b8-0557f6eb4dac'::uuid, 'Martin County', '4', '18101', 'G4020', '1810100004'),
  ('7867f1a3-78b4-4bc5-b0d1-ca6893cae309'::uuid, 'Morgan County', '4', '1810900004', '', '1810900004'),
  ('9616862d-32b3-4ea1-b58e-e1c1f74a4d62'::uuid, 'Owen County', '1', '18119', 'G4020', '1811900001'),
  ('e2019356-36d7-45b1-994d-f4960f936f68'::uuid, 'Owen County', '2', '18119', 'G4020', '1811900002'),
  ('731d7fc7-bb71-4896-ae64-b0c4a6a2ea7f'::uuid, 'Owen County', '3', '18119', 'G4020', '1811900003'),
  ('e2e613f2-4098-4f5d-9b8c-0fa00f5ca3b0'::uuid, 'Owen County', '4', '18119', 'G4020', '1811900004')
) AS v(district_id, gov, n, old_geo_id, old_mtfcc, new_geo_id);

-- ---------------------------------------------------------------------------
-- 0. Pre-flight.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n_found int; n_bad int; n_fence int; n_taken int; n_office_bad int;
BEGIN
  -- 0a. The 27 districts as recorded: old (geo_id, mtfcc) on a first run, new on a re-run; COUNTY-typed.
  SELECT count(d.id),
         count(d.id) FILTER (WHERE d.district_type IS DISTINCT FROM 'COUNTY'
                               OR ((d.geo_id, COALESCE(d.mtfcc, '')) IS DISTINCT FROM (t.old_geo_id, t.old_mtfcc)
                                   AND (d.geo_id, COALESCE(d.mtfcc, '')) IS DISTINCT FROM (t.new_geo_id, 'X0062')))
    INTO n_found, n_bad
    FROM ca0217_district t LEFT JOIN essentials.districts d ON d.id = t.district_id;
  IF n_found <> 27 OR n_bad > 0 THEN
    RAISE EXCEPTION 'districts: % of 27 found, % not as recorded', n_found, n_bad;
  END IF;

  -- 0b. Each is used by exactly one office, and that office is its county's "District N" council seat.
  SELECT count(*) INTO n_office_bad
    FROM ca0217_district t
   WHERE (SELECT count(*) FROM essentials.offices o WHERE o.district_id = t.district_id) <> 1
      OR NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = t.district_id
                       AND o.title ~* ('Council.*District ' || t.n || '$'));
  IF n_office_bad > 0 THEN
    RAISE EXCEPTION '% district(s) not used by exactly one matching council office', n_office_bad;
  END IF;

  -- 0c. The loader has run: every target boundary exists on X0062.
  SELECT count(*) INTO n_fence
    FROM ca0217_district t
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = t.new_geo_id AND gb.mtfcc = 'X0062';
  IF n_fence <> 27 THEN
    RAISE EXCEPTION 'X0062 boundaries present: % of 27 — run scripts/load-indiana-wayeo-council-boundaries.ts first', n_fence;
  END IF;

  -- 0d. No OTHER district already carries a new geo_id.
  SELECT count(*) INTO n_taken
    FROM essentials.districts d
   WHERE d.geo_id IN (SELECT new_geo_id FROM ca0217_district) AND d.id NOT IN (SELECT district_id FROM ca0217_district);
  IF n_taken > 0 THEN
    RAISE EXCEPTION '% other district(s) already use a target geo_id', n_taken;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Onto the X0062 boundaries.
-- ---------------------------------------------------------------------------
UPDATE essentials.districts d
   SET geo_id = t.new_geo_id, mtfcc = 'X0062'
  FROM ca0217_district t
 WHERE d.id = t.district_id
   AND (d.geo_id, COALESCE(d.mtfcc, '')) = (t.old_geo_id, t.old_mtfcc);

-- ---------------------------------------------------------------------------
-- 2. Post-verify.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n_on int; n_roundtrip int; r record;
BEGIN
  -- 2a. All 27 on their boundary.
  SELECT count(*) INTO n_on
    FROM ca0217_district t JOIN essentials.districts d ON d.id = t.district_id
   WHERE d.geo_id = t.new_geo_id AND d.mtfcc = 'X0062';
  IF n_on <> 27 THEN
    RAISE EXCEPTION 'districts on X0062: % of 27', n_on;
  END IF;

  -- 2b. Round trip through the address join (GEOFENCE_DISTRICT_JOIN's X-code clause, which admits COUNTY):
  --     a point on each boundary's surface reaches its own district.
  SELECT count(*) INTO n_roundtrip
    FROM ca0217_district t
    JOIN essentials.geofence_boundaries gb0 ON gb0.geo_id = t.new_geo_id AND gb0.mtfcc = 'X0062'
   WHERE EXISTS (
     SELECT 1 FROM essentials.geofence_boundaries gb
       JOIN essentials.districts d ON d.geo_id = gb.geo_id
        AND gb.mtfcc LIKE 'X%' AND gb.mtfcc NOT IN ('X0001', 'X0002', 'X0003', 'X0004')
        AND d.district_type IN ('LOCAL', 'COUNTY', 'JUDICIAL')
      WHERE ST_Covers(gb.geometry, ST_PointOnSurface(gb0.geometry)) AND d.id = t.district_id);
  IF n_roundtrip <> 27 THEN
    RAISE EXCEPTION 'address round trip: % of 27 districts reached from a point on their own boundary', n_roundtrip;
  END IF;

  -- 2c. Brown / Martin / Owen: a point in each district reaches exactly ONE of the county's four district
  --     council seats (it used to reach all four through the county-wide district).
  FOR r IN
    SELECT t.gov, t.n,
           (SELECT count(DISTINCT d2.id)
              FROM essentials.geofence_boundaries gb
              JOIN essentials.districts d2 ON d2.geo_id = gb.geo_id
               AND ((gb.mtfcc = 'G4020' AND d2.district_type IN ('COUNTY', 'JUDICIAL'))
                 OR (gb.mtfcc LIKE 'X%' AND gb.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d2.district_type IN ('LOCAL','COUNTY','JUDICIAL')))
             WHERE ST_Covers(gb.geometry, ST_PointOnSurface(gb0.geometry))
               AND d2.id IN (SELECT district_id FROM ca0217_district t2 WHERE t2.gov = t.gov)) AS seats_reached
      FROM ca0217_district t
      JOIN essentials.geofence_boundaries gb0 ON gb0.geo_id = t.new_geo_id AND gb0.mtfcc = 'X0062'
     WHERE t.gov IN ('Brown County', 'Martin County', 'Owen County')
  LOOP
    IF r.seats_reached <> 1 THEN
      RAISE EXCEPTION '%: a point in District % reaches % district council seat(s) (want 1)', r.gov, r.n, r.seats_reached;
    END IF;
  END LOOP;

  RAISE NOTICE 'OK: 27 Indiana council districts on X0062 (15 now reachable; 12 Brown/Martin/Owen seats off the county-wide district); round trip 27/27';
END $$;

COMMIT;
