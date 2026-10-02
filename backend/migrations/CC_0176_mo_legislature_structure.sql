-- CC_0176_mo_legislature_structure.sql
-- St. Louis MO deep seed, wave 2 (structure half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0177, which creates the people and the 188 terms.
--
-- Missouri's General Assembly is COMPLETELY ABSENT from production. Measured 2026-09-28:
-- 'State of Missouri' (066b88fd-1458-462e-a3b5-1331f1810fdf, type STATE, state MO) carries exactly
-- 5 chambers -- Governor, Lieutenant Governor, Secretary of State, Treasurer, Attorney General --
-- one office each, and NOTHING else. 0 of 163 House, 0 of 34 Senate. So no St. Louis address can
-- answer with a state representative or a state senator today.
--
-- Wave 1 loaded the geography (34 STATE_UPPER + 163 STATE_LOWER, vintage proved on 8 of 8 geocoded
-- anchors against three independent readings, with the 2011 plan failing as required). The 197
-- district rows are already correct: label 'State House District N' / 'State Senate District N',
-- ocd-division/country:us/state:mo/sldl:N, representation_basis 'residency', government_id NULL.
-- 🔴 DO NOT "FIX" THAT NULL government_id -- Kansas and South Dakota carry it too.
--
-- This migration creates 2 chambers and 197 offices. It creates NO people and NO terms.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 MISSOURI IS SINGLE-MEMBER IN BOTH CHAMBERS, so polygon count equals seat count and "exactly
-- one office per district" is TRUE here -- unlike South Dakota, where it is false on 33 of 37.
-- Three independent sources agree on both numbers:
--
--   * raw TIGER 2024 FIPS 29: 163 sldl (G5220) and 34 sldu (G5210), codes 001-163 and 001-034,
--     no gaps and no duplicates, 0 pseudo-districts;
--   * the Secretary of State's s 115.525 RSMo certification printed in each chamber's first-day
--     Journal: 163 names by district, and 34 names by district;
--   * Mo. Const. art. III s 3(a) -- "The house of representatives shall consist of one hundred
--     sixty-three members elected at each general election" -- and art. III s 5 -- "The senate
--     shall consist of thirty-four members elected by the qualified voters of the senatorial
--     districts for a term of four years."
--
-- term_length comes from those same two sections: House 2 ("elected at each general election"),
-- Senate 4. The stagger is art. III s 11, and the Journals DEMONSTRATE it rather than assert it --
-- the 103rd Senate Journal prints two district-keyed lists, "Elected November 5, 2024" (the 17 odd
-- districts) and "Elected November 8, 2022" (the 17 even ones).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE, AND MISSOURI'S COLLISION
-- SURFACE IS THE WORST THIS PROGRAM HAS MET. Measured against production, 2026-09-28:
--
--   82 MO COUNTY districts share a geo_id with a STATE_LOWER district
--   17 MO COUNTY districts share a geo_id with a STATE_UPPER district
--   ALL 34 STATE_UPPER districts share a geo_id with a STATE_LOWER district
--
-- Missouri's counties are FIPS 29001..29510 odd, and the legislative GEOIDs are state FIPS plus a
-- zero-padded district code, so '29005' is Atchison County AND State House District 5 AND State
-- Senate District 5. '29099' is Jefferson County AND State House District 99 -- the Clayton seat
-- this slice exists to serve. Every join below carries district_type and state; nothing matches on
-- a number or a label, and the gate asserts that no COUNTY district picked up a legislative office.
--
-- 🔴🔴 'St. Louis County' ALREADY EXISTS IN PRODUCTION -- IN MINNESOTA. The Duluth slice seeded
-- geo_id 27137 with a 7-member County Board. Missouri's 29189 also has a SEVEN-member council.
-- Identical label, identical seat count. A name-based match seats Missouri officials on Minnesota
-- seats and NOTHING ERRORS. This migration matches on no label anywhere, and the gate asserts as
-- an ABSENCE that neither Missouri chamber placed an office on any district outside Missouri --
-- which covers 27137 and everything else.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Missouri' row. Indiana's 18 indistinguishable government rows do not recur here, and
-- the gate asserts it.
--
-- 🔴 NINE SEATS ARE VACANT and are flagged in CC_0177, not here, so that everything about who
-- holds what lives in one file. This migration creates all 197 offices with is_vacant false.
-- ⚠ Between the two files essentials.offices_missing_terms rises by 197. That is expected and
-- transient; they are applied back to back. Baseline unflagged is 238 and must return to 238.
--
-- 🔴 ALL 197 SEATS ARE voting_powers 'full' AND representation_basis 'residency', so ADR 0003
-- requires NO representation_note. The gate asserts both, because a note is mandatory the moment
-- either is otherwise.
--
-- 🔴 OFFICE TITLES ARE BARE: 'Representative' and 'Senator'. Not "State Representative". This
-- matches Kansas and South Dakota, and the ballot carries no seat or position number.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '066b88fd-1458-462e-a3b5-1331f1810fdf', 'Missouri House of Representatives', 'Missouri House of Representatives', 163, '2'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '066b88fd-1458-462e-a3b5-1331f1810fdf' AND name = 'Missouri House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '066b88fd-1458-462e-a3b5-1331f1810fdf', 'Missouri Senate', 'Missouri Senate', 34, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '066b88fd-1458-462e-a3b5-1331f1810fdf' AND name = 'Missouri Senate');

-- ─── 2. The 34 Senate offices, one per STATE_UPPER district ───────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Senator', 'MO', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = '066b88fd-1458-462e-a3b5-1331f1810fdf' AND c.name = 'Missouri Senate'
WHERE lower(d.state) = 'mo'
  AND d.district_type::text = 'STATE_UPPER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── 3. The 163 House offices, one per STATE_LOWER district ───────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Representative', 'MO', 1, false, 'full'
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.government_id = '066b88fd-1458-462e-a3b5-1331f1810fdf' AND c.name = 'Missouri House of Representatives'
WHERE lower(d.state) = 'mo'
  AND d.district_type::text = 'STATE_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov        int;
  v_house_ch   int;
  v_senate_ch  int;
  v_house_off  int;
  v_senate_off int;
  v_not_one    int;
  v_county_off int;
  v_outside    int;
  v_mn         int;
  v_titles     int;
  v_vacant     int;
  v_note       int;
  v_dupe       int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE id = '066b88fd-1458-462e-a3b5-1331f1810fdf' AND name = 'State of Missouri';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'MO-2 structure gate: expected exactly 1 State of Missouri government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_house_ch FROM essentials.chambers
   WHERE government_id = '066b88fd-1458-462e-a3b5-1331f1810fdf' AND name = 'Missouri House of Representatives';
  SELECT count(*) INTO v_senate_ch FROM essentials.chambers
   WHERE government_id = '066b88fd-1458-462e-a3b5-1331f1810fdf' AND name = 'Missouri Senate';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'MO-2 structure gate: expected 1 House and 1 Senate chamber, found % and %', v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) INTO v_house_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'mo' AND d.district_type::text = 'STATE_LOWER';
  SELECT count(*) INTO v_senate_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'mo' AND d.district_type::text = 'STATE_UPPER';
  IF v_house_off <> 163 THEN
    RAISE EXCEPTION 'MO-2 structure gate: expected 163 MO House offices, found %', v_house_off;
  END IF;
  IF v_senate_off <> 34 THEN
    RAISE EXCEPTION 'MO-2 structure gate: expected 34 MO Senate offices, found %', v_senate_off;
  END IF;

  -- 🟢 Missouri is single-member in BOTH chambers, so this assertion is available here. It is what
  -- catches a district that received two offices while another received none -- a fault the two
  -- totals above cannot see.
  SELECT count(*) INTO v_not_one
    FROM essentials.districts d
   WHERE lower(d.state) = 'mo' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) <> 1;
  IF v_not_one <> 0 THEN
    RAISE EXCEPTION 'MO-2 structure gate: % MO legislative district(s) do not hold exactly 1 office', v_not_one;
  END IF;

  -- 🔴 The geo_id collision, asserted. 82 MO counties share a geo_id with a House district and 17
  -- with a Senate district; Jefferson County is 29099 and so is House District 99.
  SELECT count(*) INTO v_county_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'mo' AND d.district_type::text = 'COUNTY'
     AND o.title IN ('Senator', 'Representative');
  IF v_county_off <> 0 THEN
    RAISE EXCEPTION 'MO-2 structure gate: % MO COUNTY district(s) received a legislative office — geo_id collision (Jefferson County is 29099, House District 99 is also 29099)', v_county_off;
  END IF;

  -- 🔴🔴 ASSERTED AS AN ABSENCE, and this is the Minnesota guard. Either Missouri chamber holding
  -- an office on a district outside Missouri is the St. Louis County homonym landing on 27137.
  SELECT count(*) INTO v_outside
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = '066b88fd-1458-462e-a3b5-1331f1810fdf'
     AND c.name IN ('Missouri House of Representatives', 'Missouri Senate')
     AND lower(coalesce(d.state, '')) <> 'mo';
  IF v_outside <> 0 THEN
    RAISE EXCEPTION 'MO-2 structure gate: % MO legislative office(s) sit on a district outside Missouri — the St. Louis County homonym (MN 27137 vs MO 29189)', v_outside;
  END IF;

  -- The same guard stated the other way round, naming the row, so a failure is readable.
  SELECT count(*) INTO v_mn
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '27137'
     AND c.government_id = '066b88fd-1458-462e-a3b5-1331f1810fdf';
  IF v_mn <> 0 THEN
    RAISE EXCEPTION 'MO-2 structure gate: % office(s) of a Missouri chamber landed on St. Louis County, MINNESOTA (27137)', v_mn;
  END IF;

  SELECT count(DISTINCT o.title) INTO v_titles
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'mo' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER');
  IF v_titles <> 2 THEN
    RAISE EXCEPTION 'MO-2 structure gate: expected exactly 2 distinct legislative office titles, found % — Missouri ballots carry no seat or position number', v_titles;
  END IF;

  -- Vacancies are CC_0177's business. This file must leave all 197 unflagged.
  SELECT count(*) INTO v_vacant
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'mo' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'MO-2 structure gate: expected 0 vacant flags from this file (CC_0177 sets the 9), found %', v_vacant;
  END IF;

  -- 🔴 ADR 0003: a note is REQUIRED the moment voting_powers <> full or basis <> residency. All
  -- 197 are full/residency, so the correct state is "no note" -- asserted with its precondition.
  SELECT count(*) INTO v_note
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'mo' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     AND (o.voting_powers <> 'full' OR d.representation_basis::text <> 'residency');
  IF v_note <> 0 THEN
    RAISE EXCEPTION 'MO-2 structure gate: % MO legislative seat(s) are not full/residency and therefore REQUIRE a representation_note (ADR 0003)', v_note;
  END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT o.chamber_id, o.district_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'mo' AND d.district_type::text IN ('STATE_UPPER', 'STATE_LOWER')
     GROUP BY 1, 2 HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'MO-2 structure gate: % duplicate (chamber_id, district_id) pair(s)', v_dupe;
  END IF;

  RAISE NOTICE 'MO-2 structure gate PASSED: 163 House + 34 Senate = 197 offices, exactly 1 per district, 0 on a COUNTY district, 0 outside Missouri (MN 27137 clean), 2 distinct titles, 0 vacant flags, all full/residency.';
END $$;

COMMIT;
