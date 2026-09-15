-- CC_0107_mn_legislature_structure.sql
-- Knight Foundation program, wave MN-2 (structure half). Slot RESERVED from the allocator.
--
-- Minnesota has NO state legislative offices and NO legislative chambers today. MN-1 loaded the
-- geography -- 67 STATE_UPPER and 134 STATE_LOWER districts, plan L2022, vintage-proved -- so
-- this migration is a clean seed with nothing to repair. It:
--
--   1. creates the two chambers;
--   2. creates 201 offices, one per existing district;
--   3. flags HD-21A vacant through essentials.vacate_office().
--
-- Creates NO people and NO terms -- CC_0108 does that, and the two are applied back to back.
--
-- 🔴 MINNESOTA HOUSE DISTRICTS ARE NOT INTEGERS. Each Senate district holds exactly two House
-- districts labelled `NA` and `NB`. The join key here is the TIGER geo_id -- `2721A` for House
-- 21A, `27035` for Senate 35 -- paired with district_type, never a number and never a label.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Minnesota' row, b610e3f3-0ffa-4450-9ce8-f695ce7926a0 (type STATE, state MN, geo_id 27).
-- Indiana's 22 indistinguishable government rows do NOT recur here.
--
-- 🔴 HD-21A IS VACANT AND THE DATE IS KNOWN. Joe Schomacker resigned effective 11:59 p.m. on
-- Sunday 2026-06-21, so the first vacant day is 2026-06-22. The House's own Session Daily
-- reports that no special election will be called; the seat is filled at the 2026-11-03 general.
-- vacate_office() is used rather than a hand-written UPDATE: with no open term it writes no span,
-- sets is_vacant and vacant_since, and is idempotent. NO vacancy span and NO person row is
-- written for Schomacker -- this wave seats who holds a seat today.
-- ⚠ GEORGIA'S SD-12 was flagged with a NULL vacant_since because only the ANNOUNCEMENT was
-- documented. Minnesota's date is documented, so it is written.
--
-- 🔴🔴 NEITHER CHAMBER'S ROSTER PAGE IS A CHANGE-CHECK. house.mn.gov/members/ still lists
-- Schomacker for 21A on 2026-09-14, three months after he left, and neither chamber publishes a
-- vacancy marker anywhere. The change-check is the 201 individual member pages.
--
-- 🔴 ALL 201 SEATS ARE ON THE 2026-11-03 BALLOT -- every House seat every two years, and the
-- Senate class elected in 2022 serves through 2026. Re-run the change-check before applying if
-- this slips past early November; a certified result is not a fact about who holds the seat.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded and vacate_office() is idempotent by
-- construction. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: the House is two years. The Senate is four, except for the term beginning in the
-- year after a decennial census, which is two (Minn. Const. art. IV, s 4). The column records
-- the ordinary term.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'b610e3f3-0ffa-4450-9ce8-f695ce7926a0', 'Minnesota House of Representatives', 'Minnesota House of Representatives', 134, '2'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'b610e3f3-0ffa-4450-9ce8-f695ce7926a0' AND name = 'Minnesota House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT 'b610e3f3-0ffa-4450-9ce8-f695ce7926a0', 'Minnesota Senate', 'Minnesota Senate', 67, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'b610e3f3-0ffa-4450-9ce8-f695ce7926a0' AND name = 'Minnesota Senate');

-- ─── 2. The 201 offices, one per district MN-1 loaded ─────────────────────────
-- Guarded on district_id: Minnesota has no legislative office at all today, so this inserts 201
-- on a first run and 0 on any re-run.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, ch.title, 'MN', 1, false, 'full'
FROM essentials.districts d
JOIN (VALUES
  ('STATE_LOWER', 'Minnesota House of Representatives', 'Representative'),
  ('STATE_UPPER', 'Minnesota Senate', 'Senator')
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type::text
JOIN essentials.chambers c ON c.government_id = 'b610e3f3-0ffa-4450-9ce8-f695ce7926a0' AND c.name = ch.chamber_name
WHERE lower(d.state) = 'mn'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── 3. HD-21A is vacant ──────────────────────────────────────────────────────
-- 21A: Joe Schomacker left at the end of 2026-06-21, so 2026-06-22 is the first vacant day.
--   https://www.house.mn.gov/members/profile/15367 (banner: "Resigning effective 11:59 p.m. Sunday, June 21st 2026")
--   https://www.house.mn.gov/SessionDaily/Story/19204 ("No special election will be called to fill the remainder of his term")
SELECT essentials.vacate_office(
         o.id,
         '2026-06-22'::date,
         'Joe Schomacker resigned; https://www.house.mn.gov/SessionDaily/Story/19204 ("No special election will be called to fill the remainder of his term") (CC_0107, MN-2)',
         'resigned')
FROM essentials.districts d
JOIN essentials.offices o ON o.district_id = d.id
WHERE lower(d.state) = 'mn' AND d.district_type::text = 'STATE_LOWER' AND d.geo_id = '2721A';

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_house_ch   int;
  v_senate_ch  int;
  v_lower      int;
  v_upper      int;
  v_chambers   int;
  v_mistitled  int;
  v_vacant     int;
  v_vsince     date;
BEGIN
  SELECT count(*) FILTER (WHERE name = 'Minnesota House of Representatives'),
         count(*) FILTER (WHERE name = 'Minnesota Senate')
    INTO v_house_ch, v_senate_ch
  FROM essentials.chambers WHERE government_id = 'b610e3f3-0ffa-4450-9ce8-f695ce7926a0';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'MN-2 structure: expected exactly 1 House chamber (got %) and 1 Senate chamber (got %)',
      v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type::text = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type::text = 'STATE_UPPER')
    INTO v_lower, v_upper
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn';
  IF v_lower <> 134 OR v_upper <> 67 THEN
    RAISE EXCEPTION 'MN-2 structure: expected 134 House / 67 Senate offices, got % / %', v_lower, v_upper;
  END IF;

  -- One office per district, and no district left without one. LEFT JOIN so a district with
  -- ZERO offices is caught too -- an inner join would drop exactly the row being looked for.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'MN-2 structure: a Minnesota legislative district does not have exactly one office';
  END IF;

  SELECT count(DISTINCT o.chamber_id) INTO v_chambers
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_chambers <> 2 THEN
    RAISE EXCEPTION 'MN-2 structure: Minnesota legislative offices span % chambers, expected exactly 2', v_chambers;
  END IF;

  SELECT count(*) INTO v_mistitled
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn'
    AND ((d.district_type::text = 'STATE_LOWER' AND o.title <> 'Representative')
      OR (d.district_type::text = 'STATE_UPPER' AND o.title <> 'Senator'));
  IF v_mistitled <> 0 THEN
    RAISE EXCEPTION 'MN-2 structure: % Minnesota legislative offices carry a non-standard title', v_mistitled;
  END IF;

  -- Exactly one vacancy, on 21A, carrying the documented date.
  SELECT count(*) INTO v_vacant
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER') AND o.is_vacant;
  IF v_vacant <> 1 THEN
    RAISE EXCEPTION 'MN-2 structure: expected 1 vacant Minnesota legislative office(s), got %', v_vacant;
  END IF;

  SELECT o.vacant_since::date INTO v_vsince
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.geo_id = '2721A' AND d.district_type::text = 'STATE_LOWER';
  IF v_vsince IS DISTINCT FROM '2026-06-22'::date THEN
    RAISE EXCEPTION 'MN-2 structure: HD-21A vacant_since is %, expected %', v_vsince, '2026-06-22'::date;
  END IF;

  -- A vacancy flag must not have written a span: nothing seats 21A, and no term row exists.
  IF EXISTS (
    SELECT 1 FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'mn' AND d.geo_id = '2721A' AND d.district_type::text = 'STATE_LOWER'
  ) THEN
    RAISE EXCEPTION 'MN-2 structure: HD-21A carries an office_terms row; this migration writes none';
  END IF;

  RAISE NOTICE 'MN-2 structure OK: 2 chambers, % House + % Senate offices, % vacant (21A since %)',
    v_lower, v_upper, v_vacant, v_vsince;
END $$;

COMMIT;
