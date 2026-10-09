-- CC_0171_biloxi_structure.sql
-- Knight Foundation program, wave MS-3 (structure half). Slot RESERVED from the allocator.
--
-- Biloxi holds NO government row, NO chamber and NO office today. Measured 2026-09-28: production
-- knows Biloxi only as a TIGER place polygon (2806220 / G4110). This migration creates:
--
--   1. one government, 'City of Biloxi, Mississippi, US';
--   2. two chambers -- the City Council and the Office of the Mayor;
--   3. eight districts -- the seven wards and one citywide row for the mayor;
--   4. eight offices -- 7 council + 1 mayor.
--
-- Creates NO people and NO terms -- CC_0172 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE INVENTORY IS EIGHT, AND THE BALLOT IS WHAT PROVES IT.
--
-- Biloxi has NO home-rule charter. Its Municode publication holds a Code of Ordinances and a Land
-- Development Ordinance and no charter node at all, because Mississippi's mayor-council form is a
-- creature of statute (MCA 1972, s 21-8-21 et seq., cited by the code itself at s 2-1-3) rather
-- than an instrument the city wrote. So the move every earlier stage 3 used -- read the charter's
-- own enumerating sentence -- has no target here, and the enumeration had to come from elsewhere.
--
-- 🟢 IT COMES FROM THE 2025 BALLOT, AND IT IS EXHAUSTIVE BY CONSTRUCTION. Every Mississippi
-- municipal office runs on one four-year cycle, so ONE general election lists every elected seat
-- the city has. The city's own report of 2025-06-03: "Voters faced a Biloxi ballot with contested
-- races for Mayor and Wards 1 and 2, while council member candidates in Wards 3, 4, 5, 6, and 7
-- were unopposed." Mayor plus seven wards. Nothing else was on the ballot.
--
-- ✅ TWO INDEPENDENT INSTRUMENTS AGREE. The Code of Ordinances ch. 2 (ADMINISTRATION, 92,594
-- characters, Supp. 63 Update 1, codified through Ord. 2607 of 2026-07-28) contains NO occurrence
-- of "shall be elected" at all. Every body it creates -- human resources agency, city development
-- commission, neighbourhood heritage advisory board, the CAO -- is "appointed by the mayor,
-- subject to confirmation by the city council".
--   ▶ The MUNICIPAL CLERK is among them (s 2-1-4(a)(2)): "The mayor ... may appoint a municipal
--     clerk and/or one or more deputy municipal clerk(s)". That closes the Fort Wayne trap, where
--     a city DOES elect its clerk.
--   ▶ The MUNICIPAL COURT sits inside the legal department (s 2-1-4(e)) and its judges are staff.
--     That closes the Grand Forks trap, where an elected municipal judge was named in a single
--     sentence on a staff page.
-- Ch. 2 also states the ward count in passing, twice: "each of the seven wards of the city".
--
-- 🟢 SINGLE-MEMBER WARDS, so the office guard below can be a plain NOT EXISTS. This is NOT the
-- Aberdeen or South Dakota House shape, where four districts carried eight seats and a NOT EXISTS
-- guard would have seated half the body. Here the polygon count IS the seat count. The gate still
-- asserts it per district rather than in total, because a total of 7 is also what 7 districts with
-- one empty and one doubled would give.
--
-- ⚠ THE MAYOR NEEDS NO POLYGON OF HIS OWN. He is elected citywide, so his office hangs on a LOCAL
-- district row keyed to the TIGER place boundary 2806220 / G4110 already in production -- the
-- pattern every other citywide mayor in this database uses.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS MIGRATION REFUSES TO RUN IF THE SEVEN WARD POLYGONS ARE ABSENT. An office on a district
-- with no polygon is unreachable by any address, and NOTHING ERRORS -- the one failure mode CI
-- cannot catch. scripts/load-biloxi-ward-boundaries.mjs must have run first; it writes X0073 and
-- carries its own seven controls, every one watched failing.
--
-- 🔴 X0073 IS READ, NOT COUNTED. An X boundary code has no allocator. max(mtfcc) over BOTH
-- essentials.geofence_boundaries and essentials.districts read X0072 (Aberdeen, SD-3) on
-- 2026-09-28, in the same session as the write.
--
-- 🔴🔴 THE geo_id COLLISION IS AT ITS WORST IN THIS STATE. Mississippi's STATE_UPPER runs
-- 28001-28052, STATE_LOWER 28001-28122 and COUNTY 28001-28163, so Senate District 47, House
-- District 47 and Harrison County are ALL '28047'; the state also holds 427 G6350 ZCTA rows. The
-- ward geo_ids here are deliberately NON-NUMERIC ('biloxi-ms-ward-1'), so they cannot collide with
-- any of them -- but every join below still pairs geo_id with mtfcc, and none matches on a number
-- or a name alone.
--
-- 🔴 PARTY IS NOT WRITTEN. Biloxi's municipal elections are partisan and the city publishes each
-- member's affiliation, but party lives on races.primary_party in this database -- which ballot a
-- voter requests -- and never on a person or an office. Antipartisan by design.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the ward polygons and the place polygon must exist ───────

DO $$
DECLARE
  v_ward  int;
  v_place int;
  v_dup   int;
BEGIN
  SELECT count(*) INTO v_ward FROM essentials.geofence_boundaries WHERE mtfcc = 'X0073';
  IF v_ward <> 7 THEN
    RAISE EXCEPTION 'MS-3 pre-flight: expected 7 X0073 Biloxi ward polygons, found % — run scripts/load-biloxi-ward-boundaries.mjs first. An office on a district with no polygon is unreachable by any address and nothing errors.', v_ward;
  END IF;

  -- 🔴 The polygons must be BILOXI's. X0073 was free when it was chosen, but this migration may be
  -- applied later than the load, and an X code nobody allocates is exactly the kind of thing two
  -- sessions can both reach for.
  SELECT count(*) INTO v_dup FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0073' AND geo_id NOT LIKE 'biloxi-ms-ward-%';
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'MS-3 pre-flight: % X0073 polygon(s) are not Biloxi wards — somebody else took this code', v_dup;
  END IF;

  SELECT count(*) INTO v_place FROM essentials.geofence_boundaries
   WHERE geo_id = '2806220' AND mtfcc = 'G4110';
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'MS-3 pre-flight: expected the TIGER place polygon 2806220/G4110 for the citywide mayor, found %', v_place;
  END IF;
END $$;

-- ─── 1. The government ───────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Biloxi, Mississippi, US', 'City', 'MS', 'Biloxi', '2806220'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Biloxi, Mississippi, US');

-- ─── 2. Two chambers ─────────────────────────────────────────────────────────
-- term_length: FOUR years for both, under the mayor-council form. The city says so in its own
-- words on the City Council page -- "The City of Biloxi operates under a Mayor-Council form of
-- government, with leaders elected every four years" -- and the 2025-06-27 inauguration notice
-- repeats it: "Biloxi elected leaders will begin a new four-year term".

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '4'
FROM essentials.governments g
JOIN (VALUES
  ('Biloxi City Council', 7),
  ('Office of the Mayor', 1)
) AS v(name, official_count) ON true
WHERE g.name = 'City of Biloxi, Mississippi, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Eight districts — seven wards plus one citywide ──────────────────────

CREATE TEMP TABLE bx_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO bx_districts(geo_id, label, mtfcc) VALUES
  ('biloxi-ms-ward-1', 'Biloxi City Council Ward 1', 'X0073'),
  ('biloxi-ms-ward-2', 'Biloxi City Council Ward 2', 'X0073'),
  ('biloxi-ms-ward-3', 'Biloxi City Council Ward 3', 'X0073'),
  ('biloxi-ms-ward-4', 'Biloxi City Council Ward 4', 'X0073'),
  ('biloxi-ms-ward-5', 'Biloxi City Council Ward 5', 'X0073'),
  ('biloxi-ms-ward-6', 'Biloxi City Council Ward 6', 'X0073'),
  ('biloxi-ms-ward-7', 'Biloxi City Council Ward 7', 'X0073'),
  ('2806220',          'Biloxi Citywide',            'G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'ms', n.mtfcc
FROM bx_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL');

-- ─── 4. Eight offices — ONE per ward, ONE for the mayor ──────────────────────
-- 🔴 Every join pairs geo_id WITH mtfcc. '2806220' is unique enough, but the ward rows and the
-- citywide row differ only by mtfcc in the general case, and this state is the worst in the
-- programme for unkeyed geo_id lookups.

CREATE TEMP TABLE bx_offices(geo_id text, mtfcc text, chamber_name text, title text) ON COMMIT DROP;
INSERT INTO bx_offices(geo_id, mtfcc, chamber_name, title) VALUES
  ('biloxi-ms-ward-1', 'X0073', 'Biloxi City Council', 'Council Member, Ward 1'),
  ('biloxi-ms-ward-2', 'X0073', 'Biloxi City Council', 'Council Member, Ward 2'),
  ('biloxi-ms-ward-3', 'X0073', 'Biloxi City Council', 'Council Member, Ward 3'),
  ('biloxi-ms-ward-4', 'X0073', 'Biloxi City Council', 'Council Member, Ward 4'),
  ('biloxi-ms-ward-5', 'X0073', 'Biloxi City Council', 'Council Member, Ward 5'),
  ('biloxi-ms-ward-6', 'X0073', 'Biloxi City Council', 'Council Member, Ward 6'),
  ('biloxi-ms-ward-7', 'X0073', 'Biloxi City Council', 'Council Member, Ward 7'),
  ('2806220',          'G4110', 'Office of the Mayor', 'Mayor');

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'MS', 'Biloxi', 1, false, 'full'
FROM bx_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL' AND lower(d.state) = 'ms'
JOIN essentials.governments g ON g.name = 'City of Biloxi, Mississippi, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov     int;
  v_ch      int;
  v_dist    int;
  v_off     int;
  v_council int;
  v_mayor   int;
  v_wrong   int;
  v_titles  int;
  v_vacant  int;
  v_nogeom  int;
  v_leg     int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'City of Biloxi, Mississippi, US';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'MS-3 gate: expected exactly 1 Biloxi government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US';
  IF v_ch <> 2 THEN
    RAISE EXCEPTION 'MS-3 gate: expected 2 Biloxi chambers, found %', v_ch;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'LOCAL' AND lower(state) = 'ms'
     AND (mtfcc = 'X0073' OR (geo_id = '2806220' AND mtfcc = 'G4110'));
  IF v_dist <> 8 THEN
    RAISE EXCEPTION 'MS-3 gate: expected 8 Biloxi LOCAL districts (7 wards + 1 citywide), found %', v_dist;
  END IF;

  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US';
  IF v_off <> 8 THEN
    RAISE EXCEPTION 'MS-3 gate: expected 8 Biloxi offices (7 council + 1 mayor), found %', v_off;
  END IF;

  SELECT count(*) INTO v_council
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US' AND c.name = 'Biloxi City Council';
  SELECT count(*) INTO v_mayor
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US' AND c.name = 'Office of the Mayor';
  IF v_council <> 7 OR v_mayor <> 1 THEN
    RAISE EXCEPTION 'MS-3 gate: expected 7 council and 1 mayor, found % and %', v_council, v_mayor;
  END IF;

  -- 🔴 The single-member shape asserted PER WARD. A total of 7 is also what six wards with one
  -- office and one ward with two would give, with a seventh ward holding none and silently
  -- unreachable.
  SELECT count(*) INTO v_wrong
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'ms' AND d.mtfcc = 'X0073'
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'MS-3 gate: % Biloxi ward(s) do not hold exactly 1 office', v_wrong;
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US' AND c.name = 'Biloxi City Council';
  IF v_titles <> 7 THEN
    RAISE EXCEPTION 'MS-3 gate: expected 7 distinct council titles, one per ward, found %', v_titles;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US' AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'MS-3 gate: expected 0 vacant Biloxi offices, found %', v_vacant;
  END IF;

  -- 🔴 EVERY Biloxi office must sit on a district that HAS a polygon, matched on (geo_id, mtfcc).
  -- This is the failure mode CI cannot catch: an office on a geometry-less district is invisible
  -- to address search and nothing errors.
  SELECT count(*) INTO v_nogeom
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'City of Biloxi, Mississippi, US'
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries b
        WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'MS-3 gate: % Biloxi office(s) sit on a district with NO polygon — unreachable by any address', v_nogeom;
  END IF;

  -- 🔴 CONTROL, IN THE SAME TRANSACTION: Mississippi's 174 legislative offices from MS-2 must be
  -- untouched. A city wave has no business moving them, and this is the cheapest place to notice.
  SELECT count(*) INTO v_leg
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc IN ('G5210', 'G5220') AND lower(d.state) = 'ms';
  IF v_leg <> 174 THEN
    RAISE EXCEPTION 'MS-3 gate CONTROL: expected 174 Mississippi legislative offices from MS-2, found %', v_leg;
  END IF;

  RAISE NOTICE 'MS-3 structure gate PASSED: 1 government, 2 chambers, 8 districts, 8 offices (7 council one per ward + 1 citywide mayor), 7 distinct council titles, 0 vacant, every office on a district with geometry; 174 MS legislative offices unmoved.';
END $$;

COMMIT;
