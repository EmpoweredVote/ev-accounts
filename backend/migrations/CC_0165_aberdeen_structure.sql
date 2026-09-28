-- CC_0165_aberdeen_structure.sql
-- Knight Foundation program, wave SD-3 (structure half). Slot RESERVED from the allocator.
--
-- Aberdeen holds NO government row, NO chamber and NO office today. Measured 2026-09-28:
-- production knows Aberdeen only as a TIGER place polygon (4600100 / G4110) and 18 treasury
-- budgets, 2016-2024. This migration creates:
--
--   1. one government, 'City of Aberdeen, South Dakota, US';
--   2. two chambers -- the City Council and the Office of the Mayor;
--   3. five districts -- the four council districts and one citywide row for the mayor;
--   4. nine offices -- 8 council + 1 mayor.
--
-- Creates NO people and NO terms -- CC_0166 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE INVENTORY IS THE CHARTER'S OWN SENTENCE, AND IT IS NINE.
--
-- Aberdeen Home Rule Charter (adopted Nov 2004, amended Nov 2020) s 2.02(a): "There shall be a
-- city council composed of the mayor and eight members; the council members shall be elected by
-- the voters of the city according to districts established in s6.03 and the mayor shall be
-- elected as provided in s2.03." s 6.03(a): "There shall be four (4) city council districts."
--
-- A scan of the WHOLE charter for "shall be elected" returns those two offices and nothing else.
-- ▶ There is NO elected municipal judge. That is not an assumption: ND-3 found Grand Forks elects
-- one, named in a single sentence on a court staff page, and this charter was read for the same
-- trap. There is also no elected finance officer -- the Finance Office administers city elections
-- and is staff. Nine is the whole elected inventory.
--
-- 🔴🔴 THE COUNCIL IS MULTI-MEMBER: FOUR DISTRICTS CARRY EIGHT SEATS. This is the SECOND
-- multi-member body in this slice, after the South Dakota House. The same consequences apply:
--   * "exactly one office per district" is FALSE and fails correctly on all four districts;
--   * a duplicate sweep keyed on (district, chamber, title) reports all four. They are not
--     duplicates. Key on the office row.
--
-- 🔴 NO SEAT NUMBERS ON THE TITLE. Aberdeen's two seats in a district come up in DIFFERENT years
-- on staggered five-year terms, so each is its own contest -- but the ballot names the contest by
-- DISTRICT, not by seat. The county auditor's canvass report reads "electing Talmage Ekanger as
-- the City Council Member - SW District". Writing "(Seat 1)"/"(Seat 2)" would put a distinction on
-- a voter-facing title that no Aberdeen ballot makes. Arizona's and North Dakota's shape, not
-- Washington's. The gate asserts exactly two distinct titles per district pair.
--
-- 🔴 THE DISTRICTS ARE NAMED, NOT NUMBERED -- Northwest, Northeast, Southeast, Southwest. Nothing
-- here may be cast to an integer or ordered as one.
--
-- ⚠ THE MAYOR NEEDS NO POLYGON OF HIS OWN. He is elected citywide, so his office hangs on a LOCAL
-- district row keyed to the TIGER place boundary 4600100 / G4110 already in production -- the
-- pattern every other citywide mayor in this database uses.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THIS MIGRATION REFUSES TO RUN IF THE FOUR COUNCIL POLYGONS ARE ABSENT. An office on a
-- district with no polygon is unreachable by any address, and NOTHING ERRORS -- it is the one
-- failure mode CI cannot catch. scripts/load-aberdeen-council-boundaries.mjs must have run first;
-- it writes X0072 and carries its own five controls.
-- ⚠ ONE OF THOSE POLYGONS ARRIVED INVALID. The city's NORTHWEST district has a ring
-- self-intersection -- a zero-area digitising spike. The loader repairs it with ST_MakeValid and
-- GATES the repair: measured 2026-09-28, the fix keeps a single Polygon, takes 316 points to 319,
-- and moves the area by 0.000000 m2 of 11,515,275.41. A repair that moved more than 1 m2 would
-- have aborted rather than written.
--
-- 🔴 PARTY IS NOT WRITTEN. Aberdeen's charter s 6.01(c) is explicit that "Candidates shall run for
-- office without party designation", and party lives on races.primary_party in any case.
--
-- Idempotent: every INSERT is NOT EXISTS/count-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the council polygons must exist ──────────────────────────

DO $$
DECLARE v_poly int;
BEGIN
  SELECT count(*) INTO v_poly FROM essentials.geofence_boundaries WHERE mtfcc = 'X0072';
  IF v_poly <> 4 THEN
    RAISE EXCEPTION 'SD-3 pre-flight: expected 4 X0072 Aberdeen council polygons, found % — run scripts/load-aberdeen-council-boundaries.mjs first. An office on a district with no polygon is unreachable by any address and nothing errors.', v_poly;
  END IF;
  SELECT count(*) INTO v_poly FROM essentials.geofence_boundaries
   WHERE geo_id = '4600100' AND mtfcc = 'G4110';
  IF v_poly <> 1 THEN
    RAISE EXCEPTION 'SD-3 pre-flight: expected the TIGER place polygon 4600100/G4110 for the citywide mayor, found %', v_poly;
  END IF;
END $$;

-- ─── 1. The government ───────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Aberdeen, South Dakota, US', 'City', 'SD', 'Aberdeen', '4600100'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Aberdeen, South Dakota, US');

-- ─── 2. Two chambers ─────────────────────────────────────────────────────────
-- term_length: charter s 2.02(c) and s 2.03(a) -- FIVE years for both the council and the mayor,
-- staggered. Five is unusual and it is not a typo: the city's own Elections page says "The offices
-- of mayor and City Council members are five-year terms on a staggered basis."

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '5'
FROM essentials.governments g
JOIN (VALUES
  ('Aberdeen City Council', 8),
  ('Office of the Mayor',   1)
) AS v(name, official_count) ON true
WHERE g.name = 'City of Aberdeen, South Dakota, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Five districts ───────────────────────────────────────────────────────

CREATE TEMP TABLE ab_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO ab_districts(geo_id, label, mtfcc) VALUES
  ('aberdeen-sd-council-district-northwest', 'Aberdeen City Council Northwest District', 'X0072'),
  ('aberdeen-sd-council-district-northeast', 'Aberdeen City Council Northeast District', 'X0072'),
  ('aberdeen-sd-council-district-southeast', 'Aberdeen City Council Southeast District', 'X0072'),
  ('aberdeen-sd-council-district-southwest', 'Aberdeen City Council Southwest District', 'X0072'),
  ('4600100',                                'Aberdeen Citywide',                        'G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'sd', n.mtfcc
FROM ab_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Nine offices — TWO per council district, ONE for the mayor ───────────
-- 🔴 The guard is a COUNT, not a NOT EXISTS, because a NOT EXISTS guard can only ever create one
-- office per district and would silently seat HALF the Aberdeen council. Same reason as the South
-- Dakota House in CC_0163. The count subquery sees the statement-start snapshot, so a first run
-- inserts 2 per district and a re-run inserts 0.

CREATE TEMP TABLE ab_offices(geo_id text, chamber_name text, title text, seats_here int) ON COMMIT DROP;
INSERT INTO ab_offices(geo_id, chamber_name, title, seats_here) VALUES
  ('aberdeen-sd-council-district-northwest', 'Aberdeen City Council', 'Council Member, Northwest District', 2),
  ('aberdeen-sd-council-district-northeast', 'Aberdeen City Council', 'Council Member, Northeast District', 2),
  ('aberdeen-sd-council-district-southeast', 'Aberdeen City Council', 'Council Member, Southeast District', 2),
  ('aberdeen-sd-council-district-southwest', 'Aberdeen City Council', 'Council Member, Southwest District', 2),
  ('4600100',                                'Office of the Mayor',   'Mayor',                              1);

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'SD', 'Aberdeen', 1, false, 'full'
FROM ab_offices n
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'sd'
JOIN essentials.governments g ON g.name = 'City of Aberdeen, South Dakota, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
CROSS JOIN (VALUES (1), (2)) AS seat(k)
WHERE seat.k <= n.seats_here
  AND (SELECT count(*) FROM essentials.offices o
        WHERE o.district_id = d.id AND o.chamber_id = c.id) < seat.k;

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
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'City of Aberdeen, South Dakota, US';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'SD-3 gate: expected exactly 1 Aberdeen government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Aberdeen, South Dakota, US';
  IF v_ch <> 2 THEN
    RAISE EXCEPTION 'SD-3 gate: expected 2 Aberdeen chambers, found %', v_ch;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'LOCAL' AND lower(state) = 'sd'
     AND (mtfcc = 'X0072' OR geo_id = '4600100');
  IF v_dist <> 5 THEN
    RAISE EXCEPTION 'SD-3 gate: expected 5 Aberdeen LOCAL districts (4 council + 1 citywide), found %', v_dist;
  END IF;

  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Aberdeen, South Dakota, US';
  IF v_off <> 9 THEN
    RAISE EXCEPTION 'SD-3 gate: expected 9 Aberdeen offices (8 council + 1 mayor), found %', v_off;
  END IF;

  SELECT count(*) INTO v_council
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Aberdeen, South Dakota, US' AND c.name = 'Aberdeen City Council';
  SELECT count(*) INTO v_mayor
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Aberdeen, South Dakota, US' AND c.name = 'Office of the Mayor';
  IF v_council <> 8 OR v_mayor <> 1 THEN
    RAISE EXCEPTION 'SD-3 gate: expected 8 council and 1 mayor, found % and %', v_council, v_mayor;
  END IF;

  -- 🔴 The multi-member shape asserted PER DISTRICT. A total of 8 is also what 8 single-member
  -- districts would give, so the total alone cannot see one district with three and another with
  -- one.
  SELECT count(*) INTO v_wrong
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'sd' AND d.mtfcc = 'X0072'
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 2;
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'SD-3 gate: % Aberdeen council district(s) do not hold exactly 2 offices', v_wrong;
  END IF;

  -- 🔴 Exactly four distinct council titles — one per district, no seat numbers.
  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Aberdeen, South Dakota, US' AND c.name = 'Aberdeen City Council';
  IF v_titles <> 4 THEN
    RAISE EXCEPTION 'SD-3 gate: expected 4 distinct council titles (one per district, no seat numbers), found %', v_titles;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Aberdeen, South Dakota, US' AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'SD-3 gate: expected 0 vacant Aberdeen offices, found %', v_vacant;
  END IF;

  -- 🔴 EVERY Aberdeen office must sit on a district that HAS a polygon. This is the failure mode
  -- CI cannot catch: an office on a geometry-less district is invisible to address search and
  -- nothing errors.
  SELECT count(*) INTO v_nogeom
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'City of Aberdeen, South Dakota, US'
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries b
        WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'SD-3 gate: % Aberdeen office(s) sit on a district with NO polygon — unreachable by any address', v_nogeom;
  END IF;

  RAISE NOTICE 'SD-3 structure gate PASSED: 1 government, 2 chambers, 5 districts, 9 offices (8 council over 4 districts at 2 each + 1 citywide mayor), 4 distinct council titles, 0 vacant, every office on a district with geometry.';
END $$;

COMMIT;
