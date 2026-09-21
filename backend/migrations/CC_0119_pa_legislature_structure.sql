-- CC_0119_pa_legislature_structure.sql
-- Knight Foundation program, wave PA-2 (structure half). Slot RESERVED from the allocator.
--
-- Pennsylvania has NO state legislative offices and NO legislative chambers today: production
-- holds 23 PA offices in total -- 17 US House, 2 US Senate, 4 statewide executives. PA-1 loaded
-- the geography (203 STATE_LOWER + 50 STATE_UPPER, the 2022 LRC Final Plan, vintage-proved
-- against PennDOT on all 253 polygons), so this migration is a clean seed with nothing to
-- repair. It:
--
--   1. creates the two chambers;
--   2. creates 253 offices, one per district PA-1 loaded.
--
-- Creates NO people and NO terms -- CC_0120 does that, and the two are applied back to back.
--
-- 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. '42101' is House District 101
-- AND Philadelphia County: ALL 67 of Pennsylvania's counties share a geo_id string with a House
-- district, 25 also with a Senate district, and every Senate id is also a House id. Nothing here
-- matches on a number or a label; the office insert joins districts by district_type and state.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Pennsylvania' row, a3dc099e-039d-4df0-9e83-1bd8f08b09d4 (type STATE, state PA, geo_id 42).
-- Indiana's 18 indistinguishable government rows do NOT recur here, and the gate below asserts it.
--
-- 🟢 NO SEAT IS VACANT. All 203 House and all 50 Senate districts carry a member: each chamber's
-- own list shows no hole, Open States agrees on all 253, and all 253 individual member pages were
-- read and every one names the member the list assigned to that district. HD-12 turned over six
-- weeks ago (see CC_0120) and the list already carries the successor.
--
-- 🔴 EVERY HOUSE SEAT AND HALF THE SENATE ARE ON THE 2026-11-03 BALLOT. Re-run the change-check
-- before applying if this slips past early November: a certified result is not a fact about who
-- holds a seat, but a sworn-in successor is.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: Pa. Const. art. II s 3 -- Representatives two years, Senators four.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'a3dc099e-039d-4df0-9e83-1bd8f08b09d4', 'Pennsylvania House of Representatives', 'Pennsylvania House of Representatives', 203, '2'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'a3dc099e-039d-4df0-9e83-1bd8f08b09d4' AND name = 'Pennsylvania House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'a3dc099e-039d-4df0-9e83-1bd8f08b09d4', 'Pennsylvania Senate', 'Pennsylvania Senate', 50, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'a3dc099e-039d-4df0-9e83-1bd8f08b09d4' AND name = 'Pennsylvania Senate');

-- ─── 2. The 253 offices, one per district PA-1 loaded ─────────────────────────
-- Guarded on district_id: Pennsylvania has no legislative office at all today, so this inserts
-- 253 on a first run and 0 on any re-run.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, ch.title, 'PA', 1, false, 'full'
FROM essentials.districts d
JOIN (VALUES
  ('STATE_LOWER', 'Pennsylvania House of Representatives', 'Representative'),
  ('STATE_UPPER', 'Pennsylvania Senate', 'Senator')
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type::text
JOIN essentials.chambers c ON c.government_id = 'a3dc099e-039d-4df0-9e83-1bd8f08b09d4' AND c.name = ch.chamber_name
WHERE lower(d.state) = 'pa'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov        int;
  v_house_ch   int;
  v_senate_ch  int;
  v_lower      int;
  v_upper      int;
  v_chambers   int;
  v_mistitled  int;
  v_county     int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE id = 'a3dc099e-039d-4df0-9e83-1bd8f08b09d4' AND name = 'State of Pennsylvania' AND type = 'STATE' AND state = 'PA';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'PA-2 structure: the State of Pennsylvania government row is not what this migration assumed (got %)', v_gov;
  END IF;

  SELECT count(*) FILTER (WHERE name = 'Pennsylvania House of Representatives'),
         count(*) FILTER (WHERE name = 'Pennsylvania Senate')
    INTO v_house_ch, v_senate_ch
  FROM essentials.chambers WHERE government_id = 'a3dc099e-039d-4df0-9e83-1bd8f08b09d4';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'PA-2 structure: expected exactly 1 House chamber (got %) and 1 Senate chamber (got %)',
      v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type::text = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type::text = 'STATE_UPPER')
    INTO v_lower, v_upper
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa';
  IF v_lower <> 203 OR v_upper <> 50 THEN
    RAISE EXCEPTION 'PA-2 structure: expected 203 House / 50 Senate offices, got % / %', v_lower, v_upper;
  END IF;

  -- One office per district, and no district left without one. LEFT JOIN so a district with ZERO
  -- offices is caught too — an inner join would drop exactly the row being looked for.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'PA-2 structure: a Pennsylvania legislative district does not have exactly one office';
  END IF;

  SELECT count(DISTINCT o.chamber_id) INTO v_chambers
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_chambers <> 2 THEN
    RAISE EXCEPTION 'PA-2 structure: Pennsylvania legislative offices span % chambers, expected exactly 2', v_chambers;
  END IF;

  SELECT count(*) INTO v_mistitled
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa'
    AND ((d.district_type::text = 'STATE_LOWER' AND o.title <> 'Representative')
      OR (d.district_type::text = 'STATE_UPPER' AND o.title <> 'Senator'));
  IF v_mistitled <> 0 THEN
    RAISE EXCEPTION 'PA-2 structure: % legislative office(s) carry the wrong title', v_mistitled;
  END IF;

  -- 🔴 THE COLLISION GATE. If anything in this migration had matched on geo_id alone, a county
  -- would have picked up a legislative office. Pennsylvania's 67 COUNTY districts must still hold
  -- exactly the offices they held before: none of them is a legislative seat.
  SELECT count(*) INTO v_county
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text = 'COUNTY'
    AND o.title IN ('Representative','Senator');
  IF v_county <> 0 THEN
    RAISE EXCEPTION 'PA-2 structure: % Pennsylvania COUNTY district(s) picked up a legislative office — a geo_id-only join', v_county;
  END IF;

  RAISE NOTICE 'PA-2 structure OK: 2 chambers, 203 House + 50 Senate offices, 0 on a county';
END $$;

COMMIT;
