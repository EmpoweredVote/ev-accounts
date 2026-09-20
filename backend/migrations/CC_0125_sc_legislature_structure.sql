-- CC_0125_sc_legislature_structure.sql
-- Knight Foundation program, wave SC-2 (structure half). Slot RESERVED from the allocator.
--
-- South Carolina has NO state legislative offices and NO legislative chambers today: production
-- holds 15 SC offices in total -- 7 US House, 2 US Senate, 5 statewide executives, plus one US
-- Senate CANDIDATE office. SC-1 loaded the geography (124 STATE_LOWER + 46 STATE_UPPER, vintage
-- proved on all 170 polygons against the state's own RFA layer), so this migration is a clean
-- seed with nothing to repair. It:
--
--   1. creates the two chambers;
--   2. creates 170 offices, one per district SC-1 loaded.
--
-- Creates NO people and NO terms -- CC_0126 does that, and the two are applied back to back.
--
-- 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. '45079' is House District 79
-- AND RICHLAND COUNTY, which is Columbia's county; '45051' is House District 51 AND HORRY COUNTY,
-- which is Myrtle Beach's. ALL 46 of South Carolina's counties share a geo_id string with a House
-- district and 23 with a Senate district. Nothing here matches on a number or a label; the office
-- insert joins districts by district_type and state, and the gate below asserts that no COUNTY
-- district picked up a legislative office.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of South Carolina' row, daccc0ea-eafb-4962-ba00-2ee043fa6709 (type STATE, state SC, geo_id 45).
-- Indiana's 18 indistinguishable government rows do NOT recur here, and the gate asserts it.
--
-- 🟢 NO SEAT IS VACANT. All 124 House and all 46 Senate districts carry a member: each chamber's
-- own list shows no hole, Open States agrees on all 170 by name AND by member code, all 170
-- individual member pages were read and every one names the member the list assigned to that
-- district and states that district, and 273 sitting days of both chambers' journals report no
-- unfilled seat.
--
-- 🔴 SD-15 IS A KNOWN FUTURE VACANCY AND IS DELIBERATELY SEATED ANYWAY. Wes Climer signed an
-- irrevocable resignation under S.C. Code s 8-1-145 effective 2026-11-03, so his successor is
-- elected at the November general election. He holds the seat until that date. No term_end is
-- written (a future term_end self-vacates a seat); the debt is recorded in ROSTERS.md and sc.md.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: S.C. Const. art. III s 3 and s 6 -- Representatives two years, Senators four.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'daccc0ea-eafb-4962-ba00-2ee043fa6709', 'South Carolina House of Representatives', 'South Carolina House of Representatives', 124, '2'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'daccc0ea-eafb-4962-ba00-2ee043fa6709' AND name = 'South Carolina House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'daccc0ea-eafb-4962-ba00-2ee043fa6709', 'South Carolina Senate', 'South Carolina Senate', 46, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'daccc0ea-eafb-4962-ba00-2ee043fa6709' AND name = 'South Carolina Senate');

-- ─── 2. The 170 offices, one per district SC-1 loaded ─────────────────────────
-- Guarded on district_id: South Carolina has no legislative office at all today, so this inserts
-- 170 on a first run and 0 on any re-run.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, ch.title, 'SC', 1, false, 'full'
FROM essentials.districts d
JOIN (VALUES
  ('STATE_LOWER', 'South Carolina House of Representatives', 'Representative'),
  ('STATE_UPPER', 'South Carolina Senate', 'Senator')
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type::text
JOIN essentials.chambers c ON c.government_id = 'daccc0ea-eafb-4962-ba00-2ee043fa6709' AND c.name = ch.chamber_name
WHERE lower(d.state) = 'sc'
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
   WHERE id = 'daccc0ea-eafb-4962-ba00-2ee043fa6709' AND name = 'State of South Carolina' AND type = 'STATE' AND state = 'SC';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'SC-2 structure: the State of South Carolina government row is not what this migration assumed (got %)', v_gov;
  END IF;

  SELECT count(*) FILTER (WHERE name = 'South Carolina House of Representatives'),
         count(*) FILTER (WHERE name = 'South Carolina Senate')
    INTO v_house_ch, v_senate_ch
  FROM essentials.chambers WHERE government_id = 'daccc0ea-eafb-4962-ba00-2ee043fa6709';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'SC-2 structure: expected exactly 1 House chamber (got %) and 1 Senate chamber (got %)',
      v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type::text = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type::text = 'STATE_UPPER')
    INTO v_lower, v_upper
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc';
  IF v_lower <> 124 OR v_upper <> 46 THEN
    RAISE EXCEPTION 'SC-2 structure: expected 124 House / 46 Senate offices, got % / %', v_lower, v_upper;
  END IF;

  -- One office per district, and no district left without one. LEFT JOIN so a district with ZERO
  -- offices is caught too — an inner join would drop exactly the row being looked for.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'SC-2 structure: a South Carolina legislative district does not have exactly one office';
  END IF;

  SELECT count(DISTINCT o.chamber_id) INTO v_chambers
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_chambers <> 2 THEN
    RAISE EXCEPTION 'SC-2 structure: South Carolina legislative offices span % chambers, expected exactly 2', v_chambers;
  END IF;

  SELECT count(*) INTO v_mistitled
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc'
    AND ((d.district_type::text = 'STATE_LOWER' AND o.title <> 'Representative')
      OR (d.district_type::text = 'STATE_UPPER' AND o.title <> 'Senator'));
  IF v_mistitled <> 0 THEN
    RAISE EXCEPTION 'SC-2 structure: % legislative office(s) carry the wrong title', v_mistitled;
  END IF;

  -- 🔴 THE COLLISION GATE. If anything here had matched on geo_id alone, a county would have
  -- picked up a legislative office. South Carolina's 46 COUNTY districts -- Richland '45079' and
  -- Horry '45051' among them -- must still hold exactly the offices they held before.
  SELECT count(*) INTO v_county
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text = 'COUNTY'
    AND o.title IN ('Representative','Senator');
  IF v_county <> 0 THEN
    RAISE EXCEPTION 'SC-2 structure: % South Carolina COUNTY district(s) picked up a legislative office — a geo_id-only join', v_county;
  END IF;

  RAISE NOTICE 'SC-2 structure OK: 2 chambers, 124 House + 46 Senate offices, 0 on a county';
END $$;

COMMIT;
