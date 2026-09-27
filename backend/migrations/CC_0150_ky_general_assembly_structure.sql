-- CC_0150_ky_general_assembly_structure.sql
-- Knight Foundation program, wave KY-2 (structure half). Slot RESERVED from the allocator.
--
-- Kentucky has NO state legislative offices and NO legislative chambers today: production holds
-- ONE Kentucky government row, 'State of Kentucky', carrying 5 statewide executives (Governor,
-- Lieutenant Governor, Attorney General, Secretary of State, Treasurer), all 5 seated. There is
-- no candidate-office decoy of the kind Ohio carried; that was checked, not assumed.
--
-- KY-1 loaded the geography (38 STATE_UPPER + 100 STATE_LOWER, vintage proved against the
-- Legislative Research Commission's own published districts 138/138, with a cross-chamber control
-- failing as required at 3/100), so this migration is a clean seed. It:
--
--   1. creates the two chambers;
--   2. creates 138 offices -- 100 Representative and 38 Senator.
--
-- Creates NO people and NO terms -- CC_0151 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE JOIN KEY IS (geo_id, district_type, state), NEVER geo_id ALONE, AND KENTUCKY IS THE WORST
-- CASE THE PROGRAM HAS MET. TIGER writes legislative GEOIDs as state FIPS + district code, so
-- Senate District 20 is '21020' and House District 20 is '21020' too. Kentucky's 120 counties
-- occupy '21001'..'21239' odd, so 19 counties collide with the Senate range and 50 with the House
-- range -- and '21067' is FAYETTE COUNTY as well as House District 67, the very county this slice
-- exists to seat. Grand Forks escaped the identical collision only by luck of odd numbering.
-- The gate below asserts that no non-legislative district picked up a legislative office.
--
-- Both chambers are SINGLE-MEMBER (Ky. Const. s 33: 100 House districts, 38 Senate districts), so
-- polygon count IS seat count here -- unlike North Dakota and South Dakota. "Exactly one office
-- per district" is TRUE in Kentucky, and the gate asserts it rather than assuming it.
--
-- Party is NOT written. Party is antipartisan in this schema and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length, staggered_term)
SELECT v.government_id, v.name, v.name_formal, v.official_count, v.term_length, v.staggered_term
FROM (VALUES
  ((SELECT id FROM essentials.governments WHERE name = 'State of Kentucky'), 'Kentucky House of Representatives', 'Kentucky House of Representatives', 100, 2, false),
  ((SELECT id FROM essentials.governments WHERE name = 'State of Kentucky'), 'Kentucky Senate', 'Kentucky Senate', 38, 4, true)
) AS v(government_id, name, name_formal, official_count, term_length, staggered_term)
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.name_formal = v.name_formal);

-- ─── 2. The 138 offices ───────────────────────────────────────────────────────

CREATE TEMP TABLE ky_seats(geo_id text, district_type text, chamber_formal text, title text)
  ON COMMIT DROP;

INSERT INTO ky_seats(geo_id, district_type, chamber_formal, title) VALUES
  ('21001', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21002', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21003', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21004', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21005', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21006', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21007', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21008', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21009', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21010', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21011', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21012', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21013', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21014', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21015', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21016', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21017', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21018', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21019', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21020', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21021', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21022', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21023', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21024', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21025', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21026', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21027', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21028', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21029', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21030', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21031', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21032', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21033', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21034', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21035', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21036', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21037', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21038', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21039', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21040', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21041', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21042', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21043', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21044', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21045', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21046', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21047', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21048', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21049', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21050', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21051', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21052', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21053', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21054', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21055', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21056', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21057', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21058', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21059', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21060', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21061', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21062', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21063', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21064', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21065', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21066', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21067', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21068', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21069', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21070', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21071', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21072', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21073', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21074', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21075', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21076', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21077', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21078', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21079', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21080', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21081', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21082', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21083', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21084', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21085', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21086', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21087', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21088', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21089', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21090', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21091', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21092', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21093', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21094', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21095', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21096', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21097', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21098', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21099', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21100', 'STATE_LOWER', 'Kentucky House of Representatives', 'Representative'),
  ('21001', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21002', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21003', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21004', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21005', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21006', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21007', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21008', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21009', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21010', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21011', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21012', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21013', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21014', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21015', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21016', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21017', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21018', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21019', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21020', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21021', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21022', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21023', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21024', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21025', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21026', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21027', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21028', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21029', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21030', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21031', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21032', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21033', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21034', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21035', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21036', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21037', 'STATE_UPPER', 'Kentucky Senate', 'Senator'),
  ('21038', 'STATE_UPPER', 'Kentucky Senate', 'Senator');

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant)
SELECT c.id, d.id, ks.title, 'KY', 1, false
FROM ky_seats ks
JOIN essentials.chambers c ON c.name_formal = ks.chamber_formal
JOIN essentials.districts d
  ON d.geo_id = ks.geo_id AND d.district_type = ks.district_type AND lower(d.state) = 'ky'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id
);

-- ─── 3. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_house int; v_senate int; v_contam int; v_multi int; v_seats int;
BEGIN
  SELECT count(*) INTO v_house
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Kentucky House of Representatives';
  SELECT count(*) INTO v_senate
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Kentucky Senate';

  IF v_house <> 100 THEN
    RAISE EXCEPTION 'KY-2 structure: expected 100 House offices, got %', v_house;
  END IF;
  IF v_senate <> 38 THEN
    RAISE EXCEPTION 'KY-2 structure: expected 38 Senate offices, got %', v_senate;
  END IF;

  -- The collision gate: no non-legislative district may have picked up a legislative office.
  SELECT count(*) INTO v_contam
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
     AND d.district_type NOT IN ('STATE_LOWER','STATE_UPPER');
  IF v_contam <> 0 THEN
    RAISE EXCEPTION 'KY-2 structure: % legislative office(s) landed on a non-legislative district - the 21067 Fayette/House-67 geo_id collision', v_contam;
  END IF;

  -- Kentucky is single-member in both chambers, so exactly one office per district.
  SELECT count(*) INTO v_multi FROM (
    SELECT o.district_id
      FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
     GROUP BY o.district_id HAVING count(*) > 1) x;
  IF v_multi <> 0 THEN
    RAISE EXCEPTION 'KY-2 structure: % district(s) carry more than one office; both Kentucky chambers are single-member', v_multi;
  END IF;

  -- Every office must sit on a Kentucky district, not a same-numbered district in another state.
  SELECT count(*) INTO v_seats
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Kentucky House of Representatives','Kentucky Senate')
     AND lower(d.state) <> 'ky';
  IF v_seats <> 0 THEN
    RAISE EXCEPTION 'KY-2 structure: % office(s) landed on a district outside Kentucky', v_seats;
  END IF;

  RAISE NOTICE 'KY-2 structure OK: % offices (% House, % Senate), 0 contamination, 1 office per district', v_house + v_senate, v_house, v_senate;
END $$;

COMMIT;
