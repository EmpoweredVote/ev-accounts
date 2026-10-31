-- CC_0320_jackson_structure.sql
-- Jackson, Mississippi deep seed (structure half). Slot RESERVED from the allocator.
--
-- Jackson holds NO government row, NO chamber and NO office today. Measured 2026-10-31: production
-- knows Jackson only as a TIGER place polygon (2836000 / G4110), with zero districts rows on that
-- geo_id. This migration creates:
--
--   1. one government, 'City of Jackson, Mississippi, US';
--   2. two chambers -- the City Council and the Office of the Mayor;
--   3. eight districts -- the seven wards and one citywide row for the mayor;
--   4. eight offices -- 7 council + 1 mayor.
--
-- Creates NO people and NO terms -- CC_0321 does that, and the two are applied back to back.
-- Record: backend/data/seed-jackson-ms-2026/ROSTERS.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE INVENTORY IS EIGHT, AND THE CODE OF ORDINANCES IS WHAT CLOSES IT.
--
-- The city's own City Council page states the form in one sentence: "The City of Jackson operates
-- under the mayor-council form of government with a full-time mayor elected at-large and seven
-- part-time council members elected (one each) from seven wards." Mayor plus seven wards.
-- Like Biloxi, Jackson has NO home-rule charter -- Mississippi's mayor-council form is a creature
-- of statute (MCA 1972, s 21-8), and the Municode publication has no charter node.
--
-- 🔴🔴 "SHALL BE ELECTED" DOES NOT MEAN ELECTED BY THE VOTERS. READ WHO DOES THE ELECTING.
--
-- MS-3 closed Biloxi's inventory by observing that its Chapter 2 contained NO occurrence of
-- "shall be elected" at all. Run against Jackson's code that same test returns THREE results and
-- NOT ONE IS A POPULAR ELECTION:
--
--   s 74-46  Chief of Police      "shall be elected BY THE CITY COUNCIL at the same time as all
--                                  other officers of the city"
--   s 2-167  five school trustees "There shall be elected BY THE CITY COUNCIL five trustees for
--                                  the public schools in the separate school district of the city"
--   s 2-37   Council President    the council electing its own presiding officer
--
--   ▶ The phrase alone would have produced three false positives here, one of them a police chief
--     and one a five-member school board. The discriminating words are "by the city council"
--     against "by the qualified electors". This is Maine's rotating-chair rule in a new form:
--     a Mayor CAN be a rotating chair -- read who ELECTS it.
--
-- 🟢 AND THE COMPLEMENTARY ZERO IS REAL, BECAUSE THE POSITIVE CONTROL PASSED FIRST. A code-wide
-- search for "qualified electors" returns 0 results. That zero is only worth anything because
-- "elected by the city council" was searched first and returned EXACTLY 2 -- ss 74-46 and 2-167,
-- precisely the two found by reading the chapters. The search engine was proved working before
-- the zero was believed.
--
-- ✅ The two traps earlier waves paid for are both closed, in the code's own words:
--   ▶ THE FORT WAYNE TRAP (an elected clerk): s 2-326, "The city clerk is to be appointed by the
--     mayor and confirmed by the city council". The city attorney, the chief administrative
--     officer (s 2-325) and the chief financial officer are appointed the same way.
--   ▶ THE GRAND FORKS TRAP (an elected municipal judge named in one sentence): Chapter 46,
--     17,940 characters, contains NO occurrence of "elected" or "elective" at all, and its court
--     administrator is "appointed by the city council". That zero is trustworthy because the same
--     query returned nine "judge" sentences from the same body -- the extractor was live, not
--     blind.
--
-- ⚠ BALLOTPEDIA COULD NOT CLOSE THIS AND SAYS SO ITSELF: "Please note that there may have been
-- more offices on the ballot in this capital city than what is listed on this page." A publisher
-- declaring its own list non-exhaustive is the Harrison County "include" trap stated out loud.
--
-- 🟢 SINGLE-MEMBER WARDS, so the office guard below can be a plain NOT EXISTS, and the polygon
-- count IS the seat count. The gate still asserts it PER DISTRICT rather than in total, because a
-- total of 7 is also what six wards with one office, one ward with two and one ward with none
-- would give -- and the empty ward would be silently unreachable.
--
-- ⚠ THE MAYOR NEEDS NO POLYGON OF HIS OWN. He is elected citywide, so his office hangs on a LOCAL
-- district row keyed to the TIGER place boundary 2836000 / G4110 already in production -- the
-- pattern every other citywide mayor in this database uses.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS MIGRATION REFUSES TO RUN IF THE SEVEN WARD POLYGONS ARE ABSENT. An office on a district
-- with no polygon is unreachable by any address, and NOTHING ERRORS -- the one failure mode CI
-- cannot catch. scripts/load-jackson-ward-boundaries.mjs must have run first; it writes X0085 and
-- carries seven controls, every one watched failing on its own target.
--
-- 🔴 X0085 IS READ, NOT COUNTED. An X boundary code has no allocator. max(mtfcc) over BOTH
-- essentials.geofence_boundaries and essentials.districts read X0084 on 2026-10-31, in the same
-- session as the write.
--
-- 🔴 EVERY JOIN PAIRS geo_id WITH mtfcc. Mississippi is the worst state in the programme for
-- unkeyed geo_id lookups: measured in production, geo_id '28049' is Hinds County (G4020), State
-- Senate District 49 (G5210) AND State House District 49 (G5220) -- three rows differing only by
-- mtfcc. MS also holds 427 ZCTA rows.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_wards int;
  v_dup   int;
  v_place int;
  v_exist int;
BEGIN
  SELECT count(*) INTO v_wards FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0085' AND geo_id LIKE 'jackson-ms-ward-%';
  IF v_wards <> 7 THEN
    RAISE EXCEPTION 'Jackson pre-flight: expected 7 X0085 ward polygons from the loader, found %', v_wards;
  END IF;

  SELECT count(*) INTO v_dup FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0085' AND geo_id NOT LIKE 'jackson-ms-ward-%';
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'Jackson pre-flight: % X0085 polygon(s) are not Jackson wards — somebody else took this code', v_dup;
  END IF;

  SELECT count(*) INTO v_place FROM essentials.geofence_boundaries
   WHERE geo_id = '2836000' AND mtfcc = 'G4110';
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'Jackson pre-flight: expected the TIGER place polygon 2836000/G4110 for the citywide mayor, found %', v_place;
  END IF;

  -- 🔴 The Indiana lesson: a DUPLICATE government row hides for years and launders a de-dup.
  SELECT count(*) INTO v_exist FROM essentials.governments
   WHERE geo_id = '2836000' OR name ILIKE '%City of Jackson, Mississippi%';
  IF v_exist <> 0 THEN
    RAISE EXCEPTION 'Jackson pre-flight: % government row(s) for Jackson already exist — merge, do not duplicate', v_exist;
  END IF;
END $$;

-- ─── 1. The government ───────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Jackson, Mississippi, US', 'City', 'MS', 'Jackson', '2836000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Jackson, Mississippi, US');

-- ─── 2. Two chambers ─────────────────────────────────────────────────────────
-- term_length: FOUR years for both. The city's own Code of Ordinances fixes the cycle in passing
-- at s 2-170(d): "From and after the next general election of municipal officers to be in the
-- year 2025 and the next elected mayor takes office in July 2029" -- a four-year step, and the
-- July start that the Municipal Clerk's results page states for the sitting mayor.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '4'
FROM essentials.governments g
JOIN (VALUES
  ('Jackson City Council', 7),
  ('Office of the Mayor', 1)
) AS v(name, official_count) ON true
WHERE g.name = 'City of Jackson, Mississippi, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Eight districts — seven wards plus one citywide ──────────────────────

CREATE TEMP TABLE jx_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO jx_districts(geo_id, label, mtfcc) VALUES
  ('jackson-ms-ward-1', 'Jackson City Council Ward 1', 'X0085'),
  ('jackson-ms-ward-2', 'Jackson City Council Ward 2', 'X0085'),
  ('jackson-ms-ward-3', 'Jackson City Council Ward 3', 'X0085'),
  ('jackson-ms-ward-4', 'Jackson City Council Ward 4', 'X0085'),
  ('jackson-ms-ward-5', 'Jackson City Council Ward 5', 'X0085'),
  ('jackson-ms-ward-6', 'Jackson City Council Ward 6', 'X0085'),
  ('jackson-ms-ward-7', 'Jackson City Council Ward 7', 'X0085'),
  ('2836000',           'Jackson Citywide',            'G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'ms', n.mtfcc
FROM jx_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL');

-- ─── 4. Eight offices — ONE per ward, ONE for the mayor ──────────────────────

CREATE TEMP TABLE jx_offices(geo_id text, mtfcc text, chamber_name text, title text) ON COMMIT DROP;
INSERT INTO jx_offices(geo_id, mtfcc, chamber_name, title) VALUES
  ('jackson-ms-ward-1', 'X0085', 'Jackson City Council', 'Council Member, Ward 1'),
  ('jackson-ms-ward-2', 'X0085', 'Jackson City Council', 'Council Member, Ward 2'),
  ('jackson-ms-ward-3', 'X0085', 'Jackson City Council', 'Council Member, Ward 3'),
  ('jackson-ms-ward-4', 'X0085', 'Jackson City Council', 'Council Member, Ward 4'),
  ('jackson-ms-ward-5', 'X0085', 'Jackson City Council', 'Council Member, Ward 5'),
  ('jackson-ms-ward-6', 'X0085', 'Jackson City Council', 'Council Member, Ward 6'),
  ('jackson-ms-ward-7', 'X0085', 'Jackson City Council', 'Council Member, Ward 7'),
  ('2836000',           'G4110', 'Office of the Mayor',  'Mayor');

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'MS', 'Jackson', 1, false, 'full'
FROM jx_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL' AND lower(d.state) = 'ms'
JOIN essentials.governments g ON g.name = 'City of Jackson, Mississippi, US'
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
  v_biloxi  int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'City of Jackson, Mississippi, US';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'Jackson gate: expected exactly 1 Jackson government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US';
  IF v_ch <> 2 THEN
    RAISE EXCEPTION 'Jackson gate: expected 2 Jackson chambers, found %', v_ch;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'LOCAL' AND lower(state) = 'ms'
     AND (mtfcc = 'X0085' OR (geo_id = '2836000' AND mtfcc = 'G4110'));
  IF v_dist <> 8 THEN
    RAISE EXCEPTION 'Jackson gate: expected 8 Jackson LOCAL districts (7 wards + 1 citywide), found %', v_dist;
  END IF;

  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US';
  IF v_off <> 8 THEN
    RAISE EXCEPTION 'Jackson gate: expected 8 Jackson offices (7 council + 1 mayor), found %', v_off;
  END IF;

  SELECT count(*) INTO v_council
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US' AND c.name = 'Jackson City Council';
  SELECT count(*) INTO v_mayor
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US' AND c.name = 'Office of the Mayor';
  IF v_council <> 7 OR v_mayor <> 1 THEN
    RAISE EXCEPTION 'Jackson gate: expected 7 council and 1 mayor, found % and %', v_council, v_mayor;
  END IF;

  -- 🔴 The single-member shape asserted PER WARD. A total of 7 is also what six wards with one
  -- office and one ward with two would give, with a seventh ward holding none and silently
  -- unreachable by every address in it.
  SELECT count(*) INTO v_wrong
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'ms' AND d.mtfcc = 'X0085'
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'Jackson gate: % Jackson ward(s) do not hold exactly 1 office', v_wrong;
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US' AND c.name = 'Jackson City Council';
  IF v_titles <> 7 THEN
    RAISE EXCEPTION 'Jackson gate: expected 7 distinct council titles, one per ward, found %', v_titles;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US' AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'Jackson gate: expected 0 vacant Jackson offices, found %', v_vacant;
  END IF;

  -- 🔴 EVERY Jackson office must sit on a district that HAS a polygon, matched on (geo_id, mtfcc).
  -- This is the failure mode CI cannot catch: an office on a geometry-less district is invisible
  -- to address search and nothing errors.
  SELECT count(*) INTO v_nogeom
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'City of Jackson, Mississippi, US'
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries b
        WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'Jackson gate: % Jackson office(s) sit on a district with NO polygon — unreachable by any address', v_nogeom;
  END IF;

  -- 🔴 CONTROLS, IN THE SAME TRANSACTION. A city wave has no business moving the legislature or
  -- another city, and this is the cheapest place to notice.
  SELECT count(*) INTO v_leg
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc IN ('G5210', 'G5220') AND lower(d.state) = 'ms';
  IF v_leg <> 174 THEN
    RAISE EXCEPTION 'Jackson gate CONTROL: expected 174 Mississippi legislative offices from MS-2, found %', v_leg;
  END IF;

  SELECT count(*) INTO v_biloxi
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US';
  IF v_biloxi <> 8 THEN
    RAISE EXCEPTION 'Jackson gate CONTROL: expected Biloxi to still hold 8 offices from MS-3, found %', v_biloxi;
  END IF;

  RAISE NOTICE 'Jackson structure gate PASSED: 1 government, 2 chambers, 8 districts, 8 offices (7 council one per ward + 1 citywide mayor), 7 distinct council titles, 0 vacant, every office on a district with geometry; 174 MS legislative offices and 8 Biloxi offices unmoved.';
END $$;

COMMIT;
