-- CC_0109_mn_cities_structure.sql
-- Knight Foundation program, wave MN-3 (structure half). Slot RESERVED from the allocator.
--
-- Creates BOTH Knight jurisdictions in slice 5, which have nothing in production today -- no
-- government row, no district, no office, no official:
--
--   City of Duluth            2 chambers   6 districts   10 offices  (Mayor + 5 district + 4 at large)
--   City of Saint Paul        2 chambers   8 districts    8 offices  (Mayor + 7 ward)
--
-- Creates NO people and NO terms -- CC_0110 does that, and the two are applied back to back.
--
-- 🔴🔴 THE ONLY "SAINT PAUL" IN PRODUCTION IS IN TEXAS. essentials.governments holds exactly one
-- row matching '%Saint Paul%': 'City of Saint Paul, Texas, US', geo_id 4864220, state TX. Any
-- wave that finds this city by NAME seats the whole council under a Texas city. Every lookup
-- here is by TIGER place geo_id '2758000'. TIGER also calls the Minnesota city 'St. Paul', and
-- '%St. Paul%' matches FIVE Minnesota cities including 'St. Paul Park' (2758018), which shares
-- the capital's first five characters.
--
-- 🔴 TEN OFFICES AND EIGHT ARE WHAT THE CHARTERS SAY, NOT WHAT CITIES "USUALLY" HAVE.
-- Duluth City Charter ch. II is titled ELECTIVE OFFICERS and contains only ss 2-5. s 2 reads
-- "The council shall have nine members, four elected from the city at large and five from
-- geographical districts", and the chapter ENDS without naming another elected officer: the
-- clerk appears only as "secretary of the council" and the chief administrative officer is
-- appointed by the mayor. ch. VI s 38 names the elective titles once more and only twice,
-- "offices of mayor and councilor". Saint Paul's charter gives a mayor at large and seven
-- councilmembers, one per ward, and no at-large council seat.
--
-- 🔴 DULUTH'S FOUR AT-LARGE SEATS ARE NOT NUMBERED AND THIS MIGRATION REFUSES TO NUMBER THEM.
-- All four are elected in ONE citywide race. Numbering them would describe a power Duluth does
-- not have. All four offices therefore carry the IDENTICAL voter-facing title, and the join key
-- lives in `description`, spelled out as an internal ordinal that is not a ballot designation.
-- ⚠ Saint Paul has NO at-large council seat, so this does not apply there -- the two cities are
-- deliberately NOT made uniform.
--
-- 🟢 A DULUTH COUNCIL DISTRICT MEANS LESS THAN IT LOOKS, AND THE CHARTER SAYS SO: "The council
-- districts are established herein solely for the purposes of electing district councilors. The
-- administration of the city shall never be divided, nor any facility ever provided, nor any
-- appropriation ever made upon a council district basis." (ch. II s 2)
--
-- 🔴 GEOMETRY COMES FROM scripts/load-mn-city-council-boundaries.ts (X0052, X0053), NOT from
-- here, and the pre-flight below FAILS HARD if those twelve boundaries are absent -- an office on
-- a district with no polygon is unreachable by address and nothing errors.
--
-- 🔴🔴 DULUTH PUBLISHES TWO COUNCIL-DISTRICT MAPS AND A COUNT CANNOT TELL THEM APART: both return
-- five features numbered 1-5. The superseded 2012 map leaves 8.68 SQ MI OF DULUTH IN NO DISTRICT
-- -- 89.18% coverage against the current map's 99.98%. The loader asserts coverage; this
-- migration asserts the loader ran and left the right `source` behind.
--
-- ⚠ THE TWO CITIES HAVE OPPOSITE SHAPES AGAINST THEIR PLACE POLYGON AND BOTH ARE CORRECT.
-- Saint Paul's seven wards tile the city exactly (100.000%). Duluth's five districts OVERHANG it
-- by 11.16 sq mi of Lake Superior and unincorporated township, of which only 0.045 touches
-- another incorporated place. Full coverage is the gate; an exact tiling is not.
--
-- ⚠ districts.state is written LOWERCASE 'mn', matching every other LOCAL district in production.
-- Always lower(d.state).
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight: the twelve council boundaries and both place polygons ───────

DO $$
DECLARE v_d int; v_s int;
BEGIN
  SELECT count(*) INTO v_d FROM essentials.geofence_boundaries WHERE mtfcc = 'X0052';
  IF v_d <> 5 THEN
    RAISE EXCEPTION 'MN-3 pre-flight: X0052 holds % Duluth council boundaries, expected 5. Run scripts/load-mn-city-council-boundaries.ts first.', v_d;
  END IF;
  SELECT count(*) INTO v_s FROM essentials.geofence_boundaries WHERE mtfcc = 'X0053';
  IF v_s <> 7 THEN
    RAISE EXCEPTION 'MN-3 pre-flight: X0053 holds % Saint Paul ward boundaries, expected 7. Run scripts/load-mn-city-council-boundaries.ts first.', v_s;
  END IF;
  -- The citywide seats -- both mayors and Duluth's four at-large councilors -- hang on the TIGER
  -- place polygons, which MN-1 loaded.
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '2717000' AND mtfcc = 'G4110') THEN
    RAISE EXCEPTION 'MN-3 pre-flight: TIGER place 2717000/G4110 (Duluth) is missing.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '2758000' AND mtfcc = 'G4110') THEN
    RAISE EXCEPTION 'MN-3 pre-flight: TIGER place 2758000/G4110 (St. Paul) is missing.';
  END IF;
  -- 🔴 The Duluth boundaries must have come from the CURRENT service. The loader stamps which.
  IF EXISTS (SELECT 1 FROM essentials.geofence_boundaries
              WHERE mtfcc = 'X0052' AND source NOT LIKE '%VotingDistricts/MapServer/16%') THEN
    RAISE EXCEPTION 'MN-3 pre-flight: an X0052 boundary did not come from VotingDistricts/MapServer/16 -- it may be the superseded 2012 map, which leaves 8.68 sq mi of Duluth in no district.';
  END IF;
END $$;

-- ─── 1. Two governments ──────────────────────────────────────────────────────
-- ⚠ Matched and guarded on geo_id, never on name. See the Texas note above.

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Duluth, Minnesota, US', 'City', 'MN', 'Duluth', '2717000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2717000');

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Saint Paul, Minnesota, US', 'City', 'MN', 'Saint Paul', '2758000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '2758000');

-- ─── 2. Four chambers ────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Duluth City Council', 'Duluth City Council', 9
FROM essentials.governments g
WHERE g.geo_id = '2717000'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Duluth City Council');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Office of the Mayor', 'Office of the Mayor of Duluth', 1
FROM essentials.governments g
WHERE g.geo_id = '2717000'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Office of the Mayor');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Saint Paul City Council', 'Saint Paul City Council', 7
FROM essentials.governments g
WHERE g.geo_id = '2758000'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Saint Paul City Council');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Office of the Mayor', 'Office of the Mayor of Saint Paul', 1
FROM essentials.governments g
WHERE g.geo_id = '2758000'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Office of the Mayor');

-- ─── 3. Fourteen districts ───────────────────────────────────────────────────
-- Twelve council districts on X0052/X0053, plus one citywide row per city on the TIGER place
-- polygon carrying the Mayor and, in Duluth, the four at-large councilors.

CREATE TEMP TABLE mn3_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO mn3_districts(geo_id, label, mtfcc) VALUES
  ('duluth-mn-council-district-1', 'Duluth City Council District 1', 'X0052'),
  ('duluth-mn-council-district-2', 'Duluth City Council District 2', 'X0052'),
  ('duluth-mn-council-district-3', 'Duluth City Council District 3', 'X0052'),
  ('duluth-mn-council-district-4', 'Duluth City Council District 4', 'X0052'),
  ('duluth-mn-council-district-5', 'Duluth City Council District 5', 'X0052'),
  ('2717000', 'Duluth Citywide', 'G4110'),
  ('saint-paul-mn-ward-1', 'Saint Paul City Council Ward 1', 'X0053'),
  ('saint-paul-mn-ward-2', 'Saint Paul City Council Ward 2', 'X0053'),
  ('saint-paul-mn-ward-3', 'Saint Paul City Council Ward 3', 'X0053'),
  ('saint-paul-mn-ward-4', 'Saint Paul City Council Ward 4', 'X0053'),
  ('saint-paul-mn-ward-5', 'Saint Paul City Council Ward 5', 'X0053'),
  ('saint-paul-mn-ward-6', 'Saint Paul City Council Ward 6', 'X0053'),
  ('saint-paul-mn-ward-7', 'Saint Paul City Council Ward 7', 'X0053'),
  ('2758000', 'Saint Paul Citywide', 'G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'mn', n.mtfcc
FROM mn3_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = n.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Eighteen offices ─────────────────────────────────────────────────────

CREATE TEMP TABLE mn3_offices(place_geo_id text, district_geo_id text, chamber_name text, title text, description text, city text) ON COMMIT DROP;
INSERT INTO mn3_offices(place_geo_id, district_geo_id, chamber_name, title, description, city) VALUES
  ('2717000', 'duluth-mn-council-district-1', 'Duluth City Council', 'Councilor, District 1', NULL, 'Duluth'),
  ('2717000', 'duluth-mn-council-district-2', 'Duluth City Council', 'Councilor, District 2', NULL, 'Duluth'),
  ('2717000', 'duluth-mn-council-district-3', 'Duluth City Council', 'Councilor, District 3', NULL, 'Duluth'),
  ('2717000', 'duluth-mn-council-district-4', 'Duluth City Council', 'Councilor, District 4', NULL, 'Duluth'),
  ('2717000', 'duluth-mn-council-district-5', 'Duluth City Council', 'Councilor, District 5', NULL, 'Duluth'),
  ('2717000', '2717000', 'Duluth City Council', 'Councilor, At Large', 'Internal ordinal 1 of 4. Duluth does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.', 'Duluth'),
  ('2717000', '2717000', 'Duluth City Council', 'Councilor, At Large', 'Internal ordinal 2 of 4. Duluth does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.', 'Duluth'),
  ('2717000', '2717000', 'Duluth City Council', 'Councilor, At Large', 'Internal ordinal 3 of 4. Duluth does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.', 'Duluth'),
  ('2717000', '2717000', 'Duluth City Council', 'Councilor, At Large', 'Internal ordinal 4 of 4. Duluth does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.', 'Duluth'),
  ('2717000', '2717000', 'Office of the Mayor', 'Mayor', NULL, 'Duluth'),
  ('2758000', 'saint-paul-mn-ward-1', 'Saint Paul City Council', 'Councilmember, Ward 1', NULL, 'Saint Paul'),
  ('2758000', 'saint-paul-mn-ward-2', 'Saint Paul City Council', 'Councilmember, Ward 2', NULL, 'Saint Paul'),
  ('2758000', 'saint-paul-mn-ward-3', 'Saint Paul City Council', 'Councilmember, Ward 3', NULL, 'Saint Paul'),
  ('2758000', 'saint-paul-mn-ward-4', 'Saint Paul City Council', 'Councilmember, Ward 4', NULL, 'Saint Paul'),
  ('2758000', 'saint-paul-mn-ward-5', 'Saint Paul City Council', 'Councilmember, Ward 5', NULL, 'Saint Paul'),
  ('2758000', 'saint-paul-mn-ward-6', 'Saint Paul City Council', 'Councilmember, Ward 6', NULL, 'Saint Paul'),
  ('2758000', 'saint-paul-mn-ward-7', 'Saint Paul City Council', 'Councilmember, Ward 7', NULL, 'Saint Paul'),
  ('2758000', '2758000', 'Office of the Mayor', 'Mayor', NULL, 'Saint Paul');

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'MN', n.city, 1, false, 'full'
FROM mn3_offices n
JOIN essentials.districts d ON d.geo_id = n.district_geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'mn'
JOIN essentials.governments g ON g.geo_id = n.place_geo_id
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off int; v_atlarge int; v_atlarge_desc int; v_tx int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE geo_id IN ('2717000','2758000');
  IF v_gov <> 2 THEN RAISE EXCEPTION 'MN-3 structure: expected 2 governments, got %', v_gov; END IF;

  -- 🔴 The Texas Saint Paul must be untouched and must still be the ONLY TX one.
  SELECT count(*) INTO v_tx FROM essentials.governments WHERE geo_id = '4864220' AND state = 'TX';
  IF v_tx <> 1 THEN RAISE EXCEPTION 'MN-3 structure: the Texas Saint Paul row (4864220) is not intact; got %', v_tx; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id IN ('2717000','2758000');
  IF v_ch <> 4 THEN RAISE EXCEPTION 'MN-3 structure: expected 4 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type::text = 'LOCAL' AND lower(state) = 'mn' AND mtfcc IN ('X0052','X0053');
  IF v_dist <> 12 THEN
    RAISE EXCEPTION 'MN-3 structure: expected 12 council districts, got %', v_dist;
  END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('2717000','2758000');
  IF v_off <> 18 THEN RAISE EXCEPTION 'MN-3 structure: expected 18 offices, got %', v_off; END IF;

  -- Duluth's four at-large offices must exist, share one title, and carry FOUR DISTINCT internal
  -- ordinals -- without which CC_0110 cannot attach a person to a seat deterministically.
  SELECT count(*), count(DISTINCT o.description) INTO v_atlarge, v_atlarge_desc
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id = '2717000' AND o.title = 'Councilor, At Large';
  IF v_atlarge <> 4 OR v_atlarge_desc <> 4 THEN
    RAISE EXCEPTION 'MN-3 structure: Duluth at-large is % office(s) with % distinct description(s), expected 4 and 4', v_atlarge, v_atlarge_desc;
  END IF;

  -- Saint Paul must have NO at-large council seat. The two cities are not made uniform.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.geo_id = '2758000' AND o.title ILIKE '%at large%'
  ) THEN
    RAISE EXCEPTION 'MN-3 structure: Saint Paul has an at-large council office; its charter creates none';
  END IF;

  -- Every council district must carry exactly one office.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE d.mtfcc IN ('X0052','X0053') AND lower(d.state) = 'mn'
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'MN-3 structure: a council district does not carry exactly one office';
  END IF;

  RAISE NOTICE 'MN-3 structure OK: % governments, % chambers, % council districts, % offices (Duluth at-large % distinct)',
    v_gov, v_ch, v_dist, v_off, v_atlarge_desc;
END $$;

COMMIT;
