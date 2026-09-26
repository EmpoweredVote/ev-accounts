-- CC_0144_nd_legislative_assembly_structure.sql
-- Knight Foundation program, wave ND-2 (structure half). Slot RESERVED from the allocator.
--
-- North Dakota has NO state legislative offices and NO legislative chambers today: production
-- holds 8 North Dakota offices in total -- 1 US Representative (at large), 2 US Senators and 5
-- statewide executives, all 8 seated. 🟢 There is no candidate-office decoy of the kind Ohio
-- carried; both US Senate rows are real seats, and that was checked rather than assumed.
--
-- ND-1 loaded the geography (47 STATE_UPPER + 48 STATE_LOWER, vintage proved on all 95 polygons
-- against the state's own NDGISHUB Legislative Districts layer, with the TIGER 2022 control
-- failing as required), so this migration is a clean seed with nothing to repair. It:
--
--   1. creates the two chambers;
--   2. creates 141 offices -- 47 Senate and 94 House.
--
-- Creates NO people and NO terms -- CC_0145 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE HOUSE IS MULTI-MEMBER, SO THE OFFICE COUNT IS NOT THE DISTRICT COUNT. THIS IS THE
-- FIRST SLICE IN THE PROGRAM WHERE THAT IS TRUE.
--
-- N.D. Const. art. IV s 2: "A senator and at least two representatives must be apportioned to
-- each senatorial district and be elected at large or from subdistricts from those districts."
-- North Dakota exercises both halves of that sentence at once:
--
--   * 46 whole districts elect TWO representatives at large within the district (block voting,
--     one contest, "vote for two"). There are NO position numbers on the ballot, so the two
--     seats are NOT distinguishable and must not be given distinguishing titles.
--   * District 4 is divided into subdistricts 4A and 4B, each electing ONE representative.
--
--   46 x 2 + 2 = 94 representatives over 48 polygons, plus 47 senators over 47 polygons = 141.
--
-- 🔴 THE PRECEDENT WAS CHOSEN ON BALLOT TRUTH, NOT CONVENIENCE. Production already holds two
-- shapes for a multi-member lower house:
--   * ARIZONA -- 60 offices over 30 districts, ONE title 'State Representative', the two rows
--     differing only by id. Arizona elects two at large per district.
--   * WASHINGTON -- 98 offices over 49 districts, titled 'State Representative (Position 1)' and
--     '(Position 2)', because Washington's ballot really does number the seats.
-- North Dakota is Arizona's shape. Writing '(Seat 1)' / '(Seat 2)' here would put a distinction
-- on a voter-facing title that does not exist on any North Dakota ballot.
--
-- ▶ CONSEQUENCES FOR EVERY LATER GATE, stated here because they are easy to get wrong:
--   * "exactly one office per district" is FALSE in North Dakota and will fail correctly on 46
--     of 48 House districts. The ND form is: exactly TWO offices on each of the 46 whole
--     districts, exactly ONE on each of 4A and 4B, and 94 in total.
--   * A duplicate sweep keyed on (district, chamber, title) will report all 46 whole districts.
--     They are not duplicates. Key on the office row.
--   * The program's four-answer address probe returns FIVE answers here.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. TIGER writes North Dakota's
-- legislative GEOIDs as state FIPS + district code, so Senate District 20 is '38020' and House
-- District 20 is '38020' TOO -- the two layers share the string and are separated only by
-- district_type. North Dakota's 53 COUNTY districts occupy '38001'..'38105' odd, so 24 of them
-- also fall inside the Senate range. Nothing here matches on a number or a label; the office
-- insert joins districts by district_type and state, and the gate asserts that no COUNTY
-- district picked up a legislative office.
-- 🟢 The two subdistricts are safe by construction: '3804A' ends in a letter and cannot collide
-- with a numeric county GEOID.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of North Dakota' row, cda06c83-809e-4239-9e7b-cc6b3db00fa1 (type STATE, state ND,
-- geo_id 38). Indiana's 18 indistinguishable government rows do NOT recur here, and the gate
-- asserts it.
--
-- 🟢 NO SEAT IS VACANT. All 141 members of the 69th Legislative Assembly were verified present
-- on 2026-09-25 by reading each of the 141 individual biography pages, not a roster index:
-- ZERO carry a departure marker on a 69th-Assembly row. The detector was proved live against the
-- cumulative regular-session roster, where it found all SEVEN departures, each dated to the day.
-- So this migration writes no is_vacant flag at all, and the gate asserts that too.
--
-- 🔴🔴 AND THE OBVIOUS ROSTER WOULD HAVE SEATED 148 PEOPLE INTO 141 SEATS. ndlegis.gov's
-- regular-session member list is CUMULATIVE: it retains everyone who held a seat during the
-- assembly, so seven districts list FOUR members. Because North Dakota's House is legitimately
-- two-per-district, "four in a district" reads as 2x2 and survives a shape check that would have
-- caught it instantly in a single-member state. The roster used here is the Sep 2026 special
-- session's (convened 2026-09-02), which holds exactly 141: 47 senators and 94 representatives,
-- every district one senator and two representatives.
--
-- 🔴 PARTY IS NOT WRITTEN. The rosters carry it; party lives on races.primary_party.
--
-- Idempotent: every INSERT is NOT EXISTS/count-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: N.D. Const. art. IV s 4 -- "Senators and representatives must be elected for
-- terms of four years." BOTH chambers are four, unlike almost every other state in this corpus.
-- official_count: 47 and 94, from art. IV s 2 -- and note 94 is NOT the House polygon count (48).

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'cda06c83-809e-4239-9e7b-cc6b3db00fa1', 'North Dakota House of Representatives', 'North Dakota House of Representatives', 94, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'cda06c83-809e-4239-9e7b-cc6b3db00fa1' AND name = 'North Dakota House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'cda06c83-809e-4239-9e7b-cc6b3db00fa1', 'North Dakota Senate', 'North Dakota Senate', 47, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'cda06c83-809e-4239-9e7b-cc6b3db00fa1' AND name = 'North Dakota Senate');

-- ─── 2. The 47 Senate offices, one per STATE_UPPER district ───────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Senator', 'ND', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = 'cda06c83-809e-4239-9e7b-cc6b3db00fa1' AND c.name = 'North Dakota Senate'
WHERE lower(d.state) = 'nd'
  AND d.district_type::text = 'STATE_UPPER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── 3. The 94 House offices — TWO per whole district, ONE per subdistrict ────
-- 🔴 The guard is a COUNT, not a NOT EXISTS, because a NOT EXISTS guard can only ever create one
-- office per district and would silently seat half the North Dakota House. The count subquery is
-- evaluated against the statement-start snapshot, so rows this statement inserts are invisible to
-- it: a first run inserts 2 (or 1 for a subdistrict) and a re-run inserts 0.
-- ⚠ The CASE is the whole multi-member rule in one line. 4A and 4B are single-member; every other
-- House district elects two at large.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Representative', 'ND', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = 'cda06c83-809e-4239-9e7b-cc6b3db00fa1' AND c.name = 'North Dakota House of Representatives'
CROSS JOIN (VALUES (1), (2)) AS seat(n)
WHERE lower(d.state) = 'nd'
  AND d.district_type::text = 'STATE_LOWER'
  AND seat.n <= CASE WHEN d.geo_id IN ('3804A', '3804B') THEN 1 ELSE 2 END
  AND (SELECT count(*) FROM essentials.offices o
        WHERE o.district_id = d.id AND o.chamber_id = c.id) < seat.n;

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov            int;
  v_house_ch       int;
  v_senate_ch      int;
  v_senate_off     int;
  v_house_off      int;
  v_whole_wrong    int;
  v_sub_wrong      int;
  v_county_off     int;
  v_vacant         int;
  v_titles         int;
BEGIN
  -- Exactly one host government, and it is the one this migration names.
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE id = 'cda06c83-809e-4239-9e7b-cc6b3db00fa1' AND name = 'State of North Dakota';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'ND-2 gate: expected exactly 1 State of North Dakota government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_house_ch FROM essentials.chambers
   WHERE government_id = 'cda06c83-809e-4239-9e7b-cc6b3db00fa1' AND name = 'North Dakota House of Representatives';
  SELECT count(*) INTO v_senate_ch FROM essentials.chambers
   WHERE government_id = 'cda06c83-809e-4239-9e7b-cc6b3db00fa1' AND name = 'North Dakota Senate';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'ND-2 gate: expected 1 House chamber and 1 Senate chamber, found % and %', v_house_ch, v_senate_ch;
  END IF;

  -- 47 Senate offices, 94 House offices.
  SELECT count(*) INTO v_senate_off
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nd' AND d.district_type::text = 'STATE_UPPER';
  SELECT count(*) INTO v_house_off
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nd' AND d.district_type::text = 'STATE_LOWER';
  IF v_senate_off <> 47 THEN
    RAISE EXCEPTION 'ND-2 gate: expected 47 ND Senate offices, found %', v_senate_off;
  END IF;
  IF v_house_off <> 94 THEN
    RAISE EXCEPTION 'ND-2 gate: expected 94 ND House offices (46 districts x 2 + subdistricts 4A and 4B x 1), found %', v_house_off;
  END IF;

  -- 🔴 The multi-member shape itself, asserted per district rather than only in total. A total of
  -- 94 is also what 47 districts x 2 would give, so the total alone cannot see a subdistrict that
  -- wrongly received two offices while some other district received none.
  SELECT count(*) INTO v_whole_wrong
    FROM essentials.districts d
   WHERE lower(d.state) = 'nd' AND d.district_type::text = 'STATE_LOWER'
     AND d.geo_id NOT IN ('3804A', '3804B')
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 2;
  IF v_whole_wrong <> 0 THEN
    RAISE EXCEPTION 'ND-2 gate: % whole House district(s) do not hold exactly 2 offices', v_whole_wrong;
  END IF;

  SELECT count(*) INTO v_sub_wrong
    FROM essentials.districts d
   WHERE lower(d.state) = 'nd' AND d.district_type::text = 'STATE_LOWER'
     AND d.geo_id IN ('3804A', '3804B')
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_sub_wrong <> 0 THEN
    RAISE EXCEPTION 'ND-2 gate: subdistrict 4A/4B does not hold exactly 1 office (% offending)', v_sub_wrong;
  END IF;

  -- No COUNTY district picked up a legislative office via a geo_id collision.
  SELECT count(*) INTO v_county_off
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nd' AND d.district_type::text = 'COUNTY'
     AND o.title IN ('Senator', 'Representative');
  IF v_county_off <> 0 THEN
    RAISE EXCEPTION 'ND-2 gate: % ND COUNTY district(s) received a legislative office — geo_id collision', v_county_off;
  END IF;

  -- No seat is vacant: all 141 members were verified present on their own biography pages.
  SELECT count(*) INTO v_vacant
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'ND-2 gate: expected 0 vacant ND legislative offices, found %', v_vacant;
  END IF;

  -- 🔴 Exactly two distinct titles. A '(Seat 1)'/'(Seat 2)' slip would show up here.
  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_titles <> 2 THEN
    RAISE EXCEPTION 'ND-2 gate: expected exactly 2 distinct legislative office titles, found % — North Dakota ballots carry no seat or position number', v_titles;
  END IF;

  RAISE NOTICE 'ND-2 structure gate PASSED: 47 Senate + 94 House = 141 offices, 46 whole House districts hold 2 each, 4A and 4B hold 1 each, 0 vacant, 2 distinct titles.';
END $$;

COMMIT;
