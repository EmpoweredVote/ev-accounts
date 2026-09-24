-- CC_0133_akron_structure.sql
-- Knight Foundation program, wave OH-3 (structure half). Slot RESERVED from the allocator.
--
-- Akron holds NO offices and NO government row today; Ohio holds no local government of any kind
-- (measured 2026-09-23). This migration creates:
--
--   1 government  City of Akron, Ohio, US (TIGER place 3901000)
--   2 chambers    Akron City Council (13), Office of the Mayor (1)
--  11 districts   10 wards on X0063 + 1 citywide row on the TIGER place polygon
--  14 offices     10 ward + 3 at-large + Mayor
--
-- Creates NO people and NO terms -- CC_0134 does that, and the two are applied back to back.
--
-- 🔴 THE OFFICE INVENTORY IS THE CITY'S OWN STATEMENT, NOT AN INFERENCE. akronohio.gov's
-- government page: "A Mayor, three At-Large Council persons, and Ward City Council are elected by
-- City residents every four years. The City's Council is comprised of 10 Ward Representatives,
-- and 3 At-Large members." So FOURTEEN elected city offices and no more. The Clerk of Council is
-- NOT among them -- unlike Fort Wayne and Gary, where the City Clerk is elected and was seated.
-- ⚠ Akron Municipal Court judges and its Clerk of Courts are elected but are OUT, with the judges
-- wave, exactly as in every earlier slice.
-- ⚠ A web summary asserted "Akron has 8 wards". It has TEN. A count from a summary is not a
-- count from the body.
--
-- 🔴 THE THREE AT-LARGE SEATS ARE NOT NUMBERED, AND THIS MIGRATION REFUSES TO NUMBER THEM.
-- All three are elected in one citywide race. They share a title and a district and are told
-- apart only by an INTERNAL ORDINAL in `description`, which is a join key for CC_0134 and NOT a
-- ballot designation. This is the Fort Wayne (IN-3) convention.
--
-- 🔴 GEOMETRY MUST EXIST FIRST. The pre-flight refuses to run without the ten X0063 ward polygons
-- and the TIGER place row. An office on a district with no polygon is unreachable by any address
-- and NOTHING ERRORS -- the one failure mode CI cannot catch.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_wards int; v_place int; v_gov int;
BEGIN
  SELECT count(*) INTO v_wards FROM essentials.geofence_boundaries WHERE mtfcc = 'X0063';
  IF v_wards <> 10 THEN
    RAISE EXCEPTION 'OH-3 pre-flight: expected 10 X0063 Akron ward boundaries, found %. Run scripts/load-akron-ward-boundaries.mjs first.', v_wards;
  END IF;
  SELECT count(*) INTO v_place FROM essentials.geofence_boundaries
   WHERE geo_id = '3901000' AND mtfcc = 'G4110' AND state = '39';
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'OH-3 pre-flight: TIGER place 3901000/G4110 (Akron) is missing.';
  END IF;
  -- Ohio must still hold exactly one government, the state, before this adds the second.
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE lower(state) IN ('oh','ohio');
  IF v_gov > 2 THEN
    RAISE EXCEPTION 'OH-3 pre-flight: Ohio already holds % government rows; expected at most 2 (the state, and Akron on a re-run)', v_gov;
  END IF;
END $$;

-- ─── 1. Government ───────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Akron, Ohio, US', 'City', 'OH', 'Akron', '3901000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Akron, Ohio, US');

-- ─── 2. Two chambers ─────────────────────────────────────────────────────────
-- Akron elects no City Clerk, so there is no third chamber (Fort Wayne had one).

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM essentials.governments g
JOIN (VALUES
  ('Akron City Council', 13),
  ('Office of the Mayor', 1)
) AS v(name, official_count) ON true
WHERE g.name = 'City of Akron, Ohio, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Eleven districts ─────────────────────────────────────────────────────
-- Ten wards on X0063, plus one citywide row on the TIGER place polygon which carries the Mayor
-- and the three at-large council seats (the Fort Wayne / Columbus / Bradenton convention).

CREATE TEMP TABLE ak_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO ak_districts(geo_id, label, mtfcc) VALUES
  ('akron-oh-ward-1',  'Akron City Council Ward 1',  'X0063'),
  ('akron-oh-ward-2',  'Akron City Council Ward 2',  'X0063'),
  ('akron-oh-ward-3',  'Akron City Council Ward 3',  'X0063'),
  ('akron-oh-ward-4',  'Akron City Council Ward 4',  'X0063'),
  ('akron-oh-ward-5',  'Akron City Council Ward 5',  'X0063'),
  ('akron-oh-ward-6',  'Akron City Council Ward 6',  'X0063'),
  ('akron-oh-ward-7',  'Akron City Council Ward 7',  'X0063'),
  ('akron-oh-ward-8',  'Akron City Council Ward 8',  'X0063'),
  ('akron-oh-ward-9',  'Akron City Council Ward 9',  'X0063'),
  ('akron-oh-ward-10', 'Akron City Council Ward 10', 'X0063'),
  ('3901000',          'Akron Citywide',             'G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'oh', n.mtfcc
FROM ak_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Fourteen offices ─────────────────────────────────────────────────────

CREATE TEMP TABLE ak_offices(geo_id text, chamber_name text, title text, description text) ON COMMIT DROP;
INSERT INTO ak_offices(geo_id, chamber_name, title, description) VALUES
  ('akron-oh-ward-1',  'Akron City Council', 'Council Member, Ward 1',  NULL),
  ('akron-oh-ward-2',  'Akron City Council', 'Council Member, Ward 2',  NULL),
  ('akron-oh-ward-3',  'Akron City Council', 'Council Member, Ward 3',  NULL),
  ('akron-oh-ward-4',  'Akron City Council', 'Council Member, Ward 4',  NULL),
  ('akron-oh-ward-5',  'Akron City Council', 'Council Member, Ward 5',  NULL),
  ('akron-oh-ward-6',  'Akron City Council', 'Council Member, Ward 6',  NULL),
  ('akron-oh-ward-7',  'Akron City Council', 'Council Member, Ward 7',  NULL),
  ('akron-oh-ward-8',  'Akron City Council', 'Council Member, Ward 8',  NULL),
  ('akron-oh-ward-9',  'Akron City Council', 'Council Member, Ward 9',  NULL),
  ('akron-oh-ward-10', 'Akron City Council', 'Council Member, Ward 10', NULL),
  -- ⚠ INTERNAL ORDINAL ONLY. Akron does not number its at-large seats; all three are elected in
  -- one citywide race. This exists so CC_0134 can attach a person deterministically.
  ('3901000', 'Akron City Council', 'Council Member, At Large',
   'Internal ordinal 1 of 3. Akron does not number its at-large seats; not a ballot designation.'),
  ('3901000', 'Akron City Council', 'Council Member, At Large',
   'Internal ordinal 2 of 3. Akron does not number its at-large seats; not a ballot designation.'),
  ('3901000', 'Akron City Council', 'Council Member, At Large',
   'Internal ordinal 3 of 3. Akron does not number its at-large seats; not a ballot designation.'),
  ('3901000', 'Office of the Mayor', 'Mayor', NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'OH', 'Akron', 1, false, 'full'
FROM ak_offices n
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'oh'
JOIN essentials.governments g ON g.name = 'City of Akron, Ohio, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov       int;
  v_chambers  int;
  v_districts int;
  v_nogeom    int;
  v_offices   int;
  v_ward      int;
  v_atlarge   int;
  v_mayor     int;
  v_ordinals  int;
  v_leg       int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'City of Akron, Ohio, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'OH-3 structure: expected 1 Akron government row, got %', v_gov; END IF;

  SELECT count(*) INTO v_chambers FROM essentials.chambers c
  JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = 'City of Akron, Ohio, US';
  IF v_chambers <> 2 THEN RAISE EXCEPTION 'OH-3 structure: expected 2 Akron chambers, got %', v_chambers; END IF;

  SELECT count(*) INTO v_districts FROM essentials.districts
   WHERE district_type = 'LOCAL' AND lower(state) = 'oh';
  IF v_districts <> 11 THEN RAISE EXCEPTION 'OH-3 structure: expected 11 Ohio LOCAL districts, got %', v_districts; END IF;

  -- 🔴 EVERY district must have geometry. A district with no polygon is address-unreachable and
  -- nothing errors. Keyed on (geo_id, mtfcc), never geo_id alone.
  SELECT count(*) INTO v_nogeom FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'oh'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc AND b.geometry IS NOT NULL);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'OH-3 structure: % Akron district(s) have no geometry — unreachable by address', v_nogeom;
  END IF;

  SELECT count(*) FILTER (WHERE o.title LIKE 'Council Member, Ward %'),
         count(*) FILTER (WHERE o.title = 'Council Member, At Large'),
         count(*) FILTER (WHERE o.title = 'Mayor'),
         count(*)
    INTO v_ward, v_atlarge, v_mayor, v_offices
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Akron, Ohio, US';
  IF v_ward <> 10 THEN RAISE EXCEPTION 'OH-3 structure: % ward offices, expected 10', v_ward; END IF;
  IF v_atlarge <> 3 THEN RAISE EXCEPTION 'OH-3 structure: % at-large offices, expected 3', v_atlarge; END IF;
  IF v_mayor <> 1 THEN RAISE EXCEPTION 'OH-3 structure: % mayor offices, expected 1', v_mayor; END IF;
  IF v_offices <> 14 THEN RAISE EXCEPTION 'OH-3 structure: % Akron offices, expected 14', v_offices; END IF;

  -- The three at-large ordinals must be distinct, or CC_0134 would seat one person three times.
  SELECT count(DISTINCT o.description) INTO v_ordinals
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Akron, Ohio, US' AND o.title = 'Council Member, At Large';
  IF v_ordinals <> 3 THEN
    RAISE EXCEPTION 'OH-3 structure: the 3 at-large offices carry % distinct ordinals, expected 3', v_ordinals;
  END IF;

  -- 🔴 THE COLLISION GATE, in the other direction from OH-2: nothing here may have attached a
  -- LOCAL office to a legislative or county district.
  SELECT count(*) INTO v_leg
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE g.name = 'City of Akron, Ohio, US' AND d.district_type::text <> 'LOCAL';
  IF v_leg <> 0 THEN
    RAISE EXCEPTION 'OH-3 structure: % Akron office(s) hang on a non-LOCAL district', v_leg;
  END IF;

  RAISE NOTICE 'OH-3 structure OK: 1 government, 2 chambers, 11 districts all with geometry, 14 offices (10 ward + 3 at-large + Mayor)';
END $$;

COMMIT;
