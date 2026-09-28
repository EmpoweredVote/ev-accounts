-- CC_0169_ms_legislature_structure.sql
-- Knight Foundation program, wave MS-2 (structure half). Slot RESERVED from the allocator.
--
-- Mississippi has NO state legislative offices and NO legislative chambers today. Measured
-- 2026-09-28: production holds ONE Mississippi government row, 'State of Mississippi'
-- (20507fd2-ccdd-4436-9093-63047da0196d, type STATE, state MS, geo_id 28), carrying 5 chambers and 5
-- offices -- Governor, Lieutenant Governor, Attorney General, Secretary of State, Treasurer --
-- all 5 seated, and NOTHING else. 0 of 122 House, 0 of 52 Senate.
--
-- MS-1 loaded the geography (52 STATE_UPPER + 122 STATE_LOWER), so this is a clean seed with
-- nothing to repair. It creates the two chambers and 174 offices. It creates NO people and NO
-- terms -- CC_0170 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 BOTH CHAMBERS ARE SINGLE-MEMBER, so unlike SD, ND, AZ and WA the polygon count IS the seat
-- count and "exactly one office per district" is the right shape. No subdistricts, no position
-- numbers, no block voting. The gate asserts one office per district in both chambers.
--
-- ⚠ THE COUNTS ARE MEASURED, NOT CONSTITUTIONAL. Miss. Const. art. 13 s 254 sets CEILINGS --
-- "The Senate shall consist of not more than fifty-two (52) Senators, and the House of
-- Representatives shall consist of not more than one hundred twenty-two (122) Representatives,
-- the number of members of each house to be determined by the Legislature" -- so 52 and 122 are
-- what the current apportionment chose, not a constant. Every apportionment since 1982 has used
-- the ceiling. Read the apportionment before changing these numbers.
--
-- 🔴 TERM LENGTH IS FOUR YEARS IN BOTH CHAMBERS. Members were elected at the general election of
-- November 2023 and the next regular legislative elections are November 2027 -- which is also
-- what art. 13 s 254 means by "Each apportionment shall be effective for the next regularly
-- scheduled elections of members of the Legislature", and what the three-judge court relied on
-- in Doc 318 (2026-09-11) when it recorded that "the Legislature's current composition will
-- remain unchanged until the 2027 election".
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE, AND MISSISSIPPI IS THE WORST
-- CASE THE PROGRAM HAS MET AFTER PENNSYLVANIA. All three of these overlap:
--     STATE_UPPER  '28001'..'28052'
--     STATE_LOWER  '28001'..'28122'
--     COUNTY       '28001'..'28163'
-- So Senate District 47, House District 47 and HARRISON COUNTY -- this slice's own county -- are
-- ALL '28047'. Nothing below matches on a number or a label; the office insert joins districts by
-- district_type and state, and the gate asserts that no COUNTY district received a legislative
-- office. ⚠ Mississippi also holds 427 G6350 ZCTA rows, which Ohio's slice already recorded
-- colliding with a Summit County lookup.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Mississippi' row and exactly one government row with state = 'MS'. Indiana's 18
-- indistinguishable government rows do not recur here, and the gate asserts it.
--
-- 🔴🔴 THE MAP AND THE MEMBER HAVE COME APART IN FIFTEEN DISTRICTS, AND THAT IS RECORDED RATHER
-- THAN SMOOTHED OVER. MS-1 loaded the 2022 lines, because the Supreme Court vacated the judgment
-- approving the 2025 remedial plans on 2026-05-18, the Secretary of State reverted the State's
-- own SEMS to the 2022 lines on 2026-07-24, and the three-judge court held on 2026-09-11 that the
-- 2025 Joint Resolutions "are not operative". But the members seated by the 2025-11-04 specials
-- were elected under the 2025 lines. So in Senate 1, 2, 10, 11, 19, 34, 41, 42, 44, 45 and House
-- 16, 22, 36, 39, 41 the holder of district N may have been elected by a differently-shaped
-- district N. Those districts are named in each office's description.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '20507fd2-ccdd-4436-9093-63047da0196d', 'Mississippi House of Representatives', 'Mississippi House of Representatives', 122, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '20507fd2-ccdd-4436-9093-63047da0196d' AND name = 'Mississippi House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '20507fd2-ccdd-4436-9093-63047da0196d', 'Mississippi State Senate', 'Mississippi State Senate', 52, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '20507fd2-ccdd-4436-9093-63047da0196d' AND name = 'Mississippi State Senate');

-- ─── 2. The 52 Senate offices, one per STATE_UPPER district ───────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Senator', 'MS', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = '20507fd2-ccdd-4436-9093-63047da0196d' AND c.name = 'Mississippi State Senate'
WHERE lower(d.state) = 'ms'
  AND d.district_type::text = 'STATE_UPPER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── 3. The 122 House offices, one per STATE_LOWER district ───────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Representative', 'MS', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = '20507fd2-ccdd-4436-9093-63047da0196d' AND c.name = 'Mississippi House of Representatives'
WHERE lower(d.state) = 'ms'
  AND d.district_type::text = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov        int;
  v_ms_govs    int;
  v_house_ch   int;
  v_senate_ch  int;
  v_senate_off int;
  v_house_off  int;
  v_wrong      int;
  v_county_off int;
  v_vacant     int;
  v_titles     int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE id = '20507fd2-ccdd-4436-9093-63047da0196d' AND name = 'State of Mississippi';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'MS-2 gate: expected exactly 1 State of Mississippi government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_ms_govs FROM essentials.governments WHERE state = 'MS';
  IF v_ms_govs <> 1 THEN
    RAISE EXCEPTION 'MS-2 gate: expected exactly 1 government row with state MS, found % — Indiana had 18 indistinguishable rows', v_ms_govs;
  END IF;

  SELECT count(*) INTO v_house_ch FROM essentials.chambers
   WHERE government_id = '20507fd2-ccdd-4436-9093-63047da0196d' AND name = 'Mississippi House of Representatives';
  SELECT count(*) INTO v_senate_ch FROM essentials.chambers
   WHERE government_id = '20507fd2-ccdd-4436-9093-63047da0196d' AND name = 'Mississippi State Senate';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 1 House chamber and 1 Senate chamber, found % and %', v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) INTO v_senate_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text = 'STATE_UPPER';
  SELECT count(*) INTO v_house_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text = 'STATE_LOWER';
  IF v_senate_off <> 52 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 52 MS Senate offices, found %', v_senate_off;
  END IF;
  IF v_house_off <> 122 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 122 MS House offices, found %', v_house_off;
  END IF;

  -- 🔴 Single-member, asserted PER DISTRICT rather than only in total. A total of 174 is also
  -- what 173 districts with one office and one district with two would give.
  SELECT count(*) INTO v_wrong
    FROM essentials.districts d
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % MS legislative district(s) do not hold exactly 1 office — both chambers are single-member', v_wrong;
  END IF;

  SELECT count(*) INTO v_county_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text = 'COUNTY'
     AND o.title IN ('Senator', 'Representative');
  IF v_county_off <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: % MS COUNTY district(s) received a legislative office — geo_id collision (Harrison County is 28047, Senate District 47 is also 28047)', v_county_off;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'MS-2 gate: expected 0 vacant MS legislative offices, found %', v_vacant;
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ms' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_titles <> 2 THEN
    RAISE EXCEPTION 'MS-2 gate: expected exactly 2 distinct legislative office titles, found % — Mississippi ballots carry no seat or position number', v_titles;
  END IF;

  RAISE NOTICE 'MS-2 structure gate PASSED: 52 Senate + 122 House = 174 offices, every district holds exactly 1, no COUNTY district received one, 0 vacant, 2 distinct titles.';
END $$;

COMMIT;
