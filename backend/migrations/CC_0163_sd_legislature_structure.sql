-- CC_0163_sd_legislature_structure.sql
-- Knight Foundation program, wave SD-2 (structure half). Slot RESERVED from the allocator.
--
-- South Dakota has NO state legislative offices and NO legislative chambers today. Measured
-- 2026-09-28: production holds ONE South Dakota government row, 'State of South Dakota'
-- (29fbd5e8-ef43-456b-b89f-2d170062a3b8, type STATE, state SD, geo_id 46), carrying 5 chambers
-- and 5 offices -- Governor, Lieutenant Governor, Attorney General, Secretary of State,
-- Treasurer -- all 5 seated, and NOTHING else. 0 of 70 House, 0 of 35 Senate.
--
-- SD-1 loaded the geography (35 STATE_UPPER + 37 STATE_LOWER, vintage proved on all 72 polygons
-- against the Legislature's own adopted-map layer, with TIGER 2020 failing as required), so this
-- migration is a clean seed with nothing to repair. It:
--
--   1. creates the two chambers;
--   2. creates 105 offices -- 35 Senate and 70 House.
--
-- Creates NO people and NO terms -- CC_0164 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE HOUSE IS MULTI-MEMBER *AND PARTLY SINGLE-MEMBER*, AND A COUNT OF 70 PASSES ON BOTH A
-- RIGHT AND A WRONG STRUCTURE.
--
-- Every South Dakota legislative district elects one senator and two representatives, EXCEPT
-- districts 26 and 28, which are divided into single-member subdistricts:
--
--   33 whole districts x 2 representatives  = 66
--   26A, 26B, 28A, 28B x 1 representative   =  4
--                                             --
--                                             70 representatives over 37 polygons,
--   plus 35 senators over 35 polygons       = 105 offices.
--
-- ⚠ A FLAT 35 x 2 IS ALSO 70. The seat total cannot distinguish the real structure from a
-- uniform two-per-district one, so it is asserted per district below and never only in total.
-- This is the same separation ND-2 used, for the same reason.
--
-- 🔴 THERE IS NO '46026' AND NO '46028' STATE_LOWER DISTRICT. TIGER files districts 26 and 28
-- only as their subdistricts in the House, while the SENATE keeps both WHOLE -- so the House
-- geo_id set is legitimately NON-CONTIGUOUS. A contiguity check of the kind Kansas uses would
-- fail correctly here. The gate below asserts the ABSENCE of those two instead.
--
-- 🔴 THE CONSTITUTION CANNOT VERIFY THESE COUNTS, UNLIKE KANSAS AND NORTH DAKOTA. S.D. Const.
-- art. III s 2 sets only RANGES -- the house "not less than fifty nor more than seventy-five"
-- and the senate "not less than twenty-five nor more than thirty-five". 70 is merely inside the
-- range and 35 is the maximum permitted, so neither number is fixed by law; both come from the
-- apportionment act, and both were MEASURED: 37/35 TIGER polygons, and the Legislature's own
-- 101st-session roster, which returns 70 representatives over 33 two-member districts plus
-- 26A/26B/28A/28B, and 35 senators one per district. Three independent sources agree.
--
-- ▶ CONSEQUENCES FOR EVERY LATER GATE:
--   * "exactly one office per district" is FALSE in South Dakota and will fail correctly on 33
--     of 37 House districts. The SD form is: exactly TWO offices on each of the 33 whole
--     districts, exactly ONE on each of 26A/26B/28A/28B, and 70 in total.
--   * A duplicate sweep keyed on (district, chamber, title) will report all 33 whole districts.
--     They are not duplicates. Key on the office row.
--   * The program's four-answer address probe returns FIVE answers on a whole district and FOUR
--     inside a subdistrict. Aberdeen sits in District 3, a whole district, so Aberdeen returns
--     five.
--
-- 🔴 NO SEAT NUMBERS ON THE TITLE. South Dakota is ARIZONA's and NORTH DAKOTA's shape, not
-- WASHINGTON's: the ballot carries no position number, and the Legislature's own first-day
-- journal lists the two members of a district as plain names under one district heading
-- ("District No. 1: Logan Manhart, Aberdeen / Christopher Reder, Warner"). Writing '(Seat 1)' /
-- '(Seat 2)' would put a distinction on a voter-facing title that no South Dakota ballot makes.
-- The gate asserts exactly two distinct titles.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. TIGER writes South Dakota's
-- legislative GEOIDs as state FIPS + district code, so Senate District 20 is '46020' and House
-- District 20 is '46020' TOO -- separated only by district_type. Worse, South Dakota's 66 COUNTY
-- districts occupy '46003'..'46137' odd, so SEVENTEEN of them fall inside the Senate range:
-- Senate District 3 is '46003' AND SO IS AURORA COUNTY, and Brown County -- this slice's own
-- county -- is '46013', which collides with Senate District 13. Nothing here matches on a number
-- or a label; the office insert joins districts by district_type and state, and the gate asserts
-- that no COUNTY district picked up a legislative office.
-- 🟢 The four subdistricts are safe by construction: '4626A' ends in a letter and cannot collide
-- with a numeric county GEOID.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of South Dakota' row. Indiana's 18 indistinguishable government rows do not recur here,
-- and the gate asserts it.
--
-- 🟢 NO SEAT IS VACANT. The Legislature's own 101st-session roster returns exactly 105 members
-- with 0 InactiveDate, and every one of the 37 House and 35 Senate districts is filled to its
-- exact seat count -- verified against production geography before this migration was written.
-- So this migration writes no is_vacant flag at all, and the gate asserts that too.
--
-- ⚠ THE PRIOR SESSION'S ROSTER IS CUMULATIVE AND WOULD HAVE SEATED 109 PEOPLE INTO 105 SEATS.
-- The 100th session (2025) list retains everyone who held a seat during the session, so it
-- returns 109. The four extras each carry an InactiveDate and are the four members who left:
-- Reder (H-01, 2025-05-01), Vasgaard (H-16, 2025-08-27), Venhuizen (H-13, 2025-01-29) and
-- Wheeler (S-22, 2025-04-24). The roster used here is the 101st session's, which holds exactly
-- 105. Because South Dakota's House is legitimately two-per-district, "three in a district"
-- would have survived a shape check that a single-member state would have caught instantly.
--
-- 🔴 PARTY IS NOT WRITTEN. The roster carries it; party lives on races.primary_party.
--
-- Idempotent: every INSERT is NOT EXISTS/count-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: S.D. Const. art. III s 6 -- "The terms of office of the members of the Legislature
-- shall be two years." BOTH chambers are two, unlike North Dakota's four.
-- official_count: 70 and 35 -- MEASURED, not constitutional (see the s 2 note above).

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '29fbd5e8-ef43-456b-b89f-2d170062a3b8', 'South Dakota House of Representatives', 'South Dakota House of Representatives', 70, '2'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '29fbd5e8-ef43-456b-b89f-2d170062a3b8' AND name = 'South Dakota House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '29fbd5e8-ef43-456b-b89f-2d170062a3b8', 'South Dakota Senate', 'South Dakota Senate', 35, '2'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '29fbd5e8-ef43-456b-b89f-2d170062a3b8' AND name = 'South Dakota Senate');

-- ─── 2. The 35 Senate offices, one per STATE_UPPER district ───────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Senator', 'SD', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = '29fbd5e8-ef43-456b-b89f-2d170062a3b8' AND c.name = 'South Dakota Senate'
WHERE lower(d.state) = 'sd'
  AND d.district_type::text = 'STATE_UPPER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── 3. The 70 House offices — TWO per whole district, ONE per subdistrict ────
-- 🔴 The guard is a COUNT, not a NOT EXISTS, because a NOT EXISTS guard can only ever create one
-- office per district and would silently seat half the South Dakota House. The count subquery is
-- evaluated against the statement-start snapshot, so rows this statement inserts are invisible to
-- it: a first run inserts 2 (or 1 for a subdistrict) and a re-run inserts 0.
-- ⚠ The CASE is the whole multi-member rule in one line. 26A/26B/28A/28B are single-member; every
-- other House district elects two at large.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Representative', 'SD', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = '29fbd5e8-ef43-456b-b89f-2d170062a3b8' AND c.name = 'South Dakota House of Representatives'
CROSS JOIN (VALUES (1), (2)) AS seat(n)
WHERE lower(d.state) = 'sd'
  AND d.district_type::text = 'STATE_LOWER'
  AND seat.n <= CASE WHEN d.geo_id IN ('4626A', '4626B', '4628A', '4628B') THEN 1 ELSE 2 END
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
  v_absent_parent  int;
  v_county_off     int;
  v_vacant         int;
  v_titles         int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE id = '29fbd5e8-ef43-456b-b89f-2d170062a3b8' AND name = 'State of South Dakota';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'SD-2 gate: expected exactly 1 State of South Dakota government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_house_ch FROM essentials.chambers
   WHERE government_id = '29fbd5e8-ef43-456b-b89f-2d170062a3b8' AND name = 'South Dakota House of Representatives';
  SELECT count(*) INTO v_senate_ch FROM essentials.chambers
   WHERE government_id = '29fbd5e8-ef43-456b-b89f-2d170062a3b8' AND name = 'South Dakota Senate';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'SD-2 gate: expected 1 House chamber and 1 Senate chamber, found % and %', v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) INTO v_senate_off
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sd' AND d.district_type::text = 'STATE_UPPER';
  SELECT count(*) INTO v_house_off
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sd' AND d.district_type::text = 'STATE_LOWER';
  IF v_senate_off <> 35 THEN
    RAISE EXCEPTION 'SD-2 gate: expected 35 SD Senate offices, found %', v_senate_off;
  END IF;
  IF v_house_off <> 70 THEN
    RAISE EXCEPTION 'SD-2 gate: expected 70 SD House offices (33 districts x 2 + subdistricts 26A/26B/28A/28B x 1), found %', v_house_off;
  END IF;

  -- 🔴 The multi-member shape itself, asserted PER DISTRICT rather than only in total. A total of
  -- 70 is also what a flat 35 x 2 would give, so the total alone cannot see a subdistrict that
  -- wrongly received two offices while some other district received none.
  SELECT count(*) INTO v_whole_wrong
    FROM essentials.districts d
   WHERE lower(d.state) = 'sd' AND d.district_type::text = 'STATE_LOWER'
     AND d.geo_id NOT IN ('4626A', '4626B', '4628A', '4628B')
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 2;
  IF v_whole_wrong <> 0 THEN
    RAISE EXCEPTION 'SD-2 gate: % whole House district(s) do not hold exactly 2 offices', v_whole_wrong;
  END IF;

  SELECT count(*) INTO v_sub_wrong
    FROM essentials.districts d
   WHERE lower(d.state) = 'sd' AND d.district_type::text = 'STATE_LOWER'
     AND d.geo_id IN ('4626A', '4626B', '4628A', '4628B')
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_sub_wrong <> 0 THEN
    RAISE EXCEPTION 'SD-2 gate: a 26A/26B/28A/28B subdistrict does not hold exactly 1 office (% offending)', v_sub_wrong;
  END IF;

  -- 🔴 ASSERTED AS AN ABSENCE. A whole '46026' or '46028' STATE_LOWER district would mean the
  -- geography is not the map SD-1 loaded, and the two-per-district rule above would silently
  -- seat two more representatives than South Dakota has.
  SELECT count(*) INTO v_absent_parent
    FROM essentials.districts d
   WHERE lower(d.state) = 'sd' AND d.district_type::text = 'STATE_LOWER'
     AND d.geo_id IN ('46026', '46028');
  IF v_absent_parent <> 0 THEN
    RAISE EXCEPTION 'SD-2 gate: % whole STATE_LOWER district(s) 46026/46028 exist — the House splits 26 and 28 into subdistricts and must carry neither', v_absent_parent;
  END IF;

  SELECT count(*) INTO v_county_off
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sd' AND d.district_type::text = 'COUNTY'
     AND o.title IN ('Senator', 'Representative');
  IF v_county_off <> 0 THEN
    RAISE EXCEPTION 'SD-2 gate: % SD COUNTY district(s) received a legislative office — geo_id collision (Aurora County is 46003, Senate District 3 is also 46003)', v_county_off;
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'SD-2 gate: expected 0 vacant SD legislative offices, found %', v_vacant;
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sd' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_titles <> 2 THEN
    RAISE EXCEPTION 'SD-2 gate: expected exactly 2 distinct legislative office titles, found % — South Dakota ballots carry no seat or position number', v_titles;
  END IF;

  RAISE NOTICE 'SD-2 structure gate PASSED: 35 Senate + 70 House = 105 offices, 33 whole House districts hold 2 each, 26A/26B/28A/28B hold 1 each, no whole 46026/46028, 0 vacant, 2 distinct titles.';
END $$;

COMMIT;
