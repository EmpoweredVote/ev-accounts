-- CC_0156_ks_legislature_structure.sql
-- Knight Foundation program, wave KS-2 (structure half). Slot RESERVED from the allocator.
--
-- Kansas has NO state legislative offices and NO legislative chambers today: production holds ONE
-- Kansas government row, 'State of Kansas', carrying 5 statewide executives (Governor, Lieutenant
-- Governor, Attorney General, Secretary of State, Treasurer), one office each. Measured, not assumed.
--
-- KS-1 loaded the geography (40 STATE_UPPER + 125 STATE_LOWER, vintage proved against the enacted
-- plan files the Kansas Legislative Research Department publishes -- the Senate map "Liberty 3" and
-- the House map "Free State 3F" of Substitute for Senate Bill 563, the names the Kansas Supreme
-- Court itself uses -- agreeing 40/40 and 125/125 with zero districts moved, with a wrong-chamber
-- control failing at 0/125 and a prior-plan control moving 5 and 13). So this is a clean seed. It:
--
--   1. creates the two chambers;
--   2. creates 165 offices -- 125 Representative and 40 Senator.
--
-- Creates NO people and NO terms -- CC_0157 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE COUNTS ARE THE LAW, NOT A MEASUREMENT, AND KANSAS IS THE ONLY SLICE WHERE THAT IS TRUE.
-- "Kansas has 40 senatorial districts and 125 representative districts. Kan. Const. art. 2, s 2;
-- K.S.A. 4-101" (No. 125,083, slip op. at 2). Both were ALSO measured against raw TIGER FIPS 20 and
-- agree. Both chambers are single-member (MEMBERS = 1 on all 165 enacted-plan polygons), so polygon
-- count IS seat count -- unlike North Dakota and South Dakota.
--
-- THE JOIN KEY IS (geo_id, district_type, state), NEVER geo_id ALONE. TIGER writes legislative
-- GEOIDs as state FIPS + district code, so Senate District 29 is '20029' and House District 29 is
-- '20029' too. Kansas's 105 counties occupy '20001'..'20209' ODD, so -- measured against production
-- -- 20 counties collide with the Senate range and 63 with the House range. 83 geo_ids are already
-- shared across MTFCCs in Kansas and that was confirmed after the KS-1 load, with ZERO duplicate
-- (mtfcc, geo_id) pairs. The gate below asserts no non-legislative district picked up an office.
-- Unlike Kentucky, THIS slice's own county escapes: Sedgwick is '20173', above both ranges, where
-- Fayette was '21067' and collided with House District 67. That is luck of numbering, not design.
--
-- Party is NOT written. Party is antipartisan in this schema and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
--
-- staggered_term is FALSE for BOTH, and that is a Kansas fact rather than a copy of Kentucky's
-- shape: all 40 senators were elected in November 2024 and all 40 took the oath together on
-- 2025-01-13 ("The roll was called from the certified list of members-elect, with forty
-- members-elect present"). Kansas does not stagger its Senate; Kentucky does.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length, staggered_term)
SELECT v.government_id, v.name, v.name_formal, v.official_count, v.term_length, v.staggered_term
FROM (VALUES
  ((SELECT id FROM essentials.governments WHERE name = 'State of Kansas'), 'Kansas House of Representatives', 'Kansas House of Representatives', 125, 2, false),
  ((SELECT id FROM essentials.governments WHERE name = 'State of Kansas'), 'Kansas Senate', 'Kansas Senate', 40, 4, false)
) AS v(government_id, name, name_formal, official_count, term_length, staggered_term)
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.name_formal = v.name_formal);

-- ─── 2. The 165 offices ───────────────────────────────────────────────────────

CREATE TEMP TABLE ks_seats(geo_id text, district_type text, chamber_formal text, title text)
  ON COMMIT DROP;

INSERT INTO ks_seats(geo_id, district_type, chamber_formal, title) VALUES
  ('20057', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20045', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20072', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20061', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20044', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20076', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20093', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20091', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20012', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20064', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20086', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20015', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20052', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20112', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20035', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20085', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20011', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20040', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20068', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20033', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20066', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20092', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20081', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20075', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20084', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20065', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20002', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20054', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20008', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20032', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20094', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20013', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20047', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20014', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20078', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20087', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20113', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20016', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20125', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20009', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20007', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20119', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20053', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20100', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20083', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20001', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20116', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20097', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20071', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20082', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20098', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20017', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20090', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20099', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20004', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20038', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20096', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20074', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20123', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20124', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20103', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20049', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20050', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20036', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20029', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20118', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20106', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20046', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20042', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20018', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20089', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20037', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20048', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20024', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20088', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20122', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20006', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20020', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20041', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20110', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20063', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20080', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20067', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20079', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20031', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20023', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20069', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20005', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20095', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20019', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20055', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20059', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20060', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20114', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20101', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20058', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20120', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20003', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20051', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20039', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20021', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20121', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20043', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20102', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20027', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20117', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20028', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20026', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20022', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20104', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20105', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20111', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20109', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20056', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20115', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20010', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20073', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20062', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20030', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20077', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20070', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20034', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20107', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20108', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20025', 'STATE_LOWER', 'Kansas House of Representatives', 'Representative'),
  ('20032', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20017', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20040', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20026', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20033', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20036', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20001', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20027', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20039', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20007', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20020', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20030', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20014', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20029', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20002', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20009', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20004', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20024', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20008', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20005', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20003', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20016', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20025', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20034', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20031', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20015', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20028', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20006', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20035', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20038', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20019', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20013', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20037', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20022', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20021', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20023', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20010', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20018', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20012', 'STATE_UPPER', 'Kansas Senate', 'Senator'),
  ('20011', 'STATE_UPPER', 'Kansas Senate', 'Senator');

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant)
SELECT c.id, d.id, ks.title, 'KS', 1, false
FROM ks_seats ks
JOIN essentials.chambers c ON c.name_formal = ks.chamber_formal
JOIN essentials.districts d
  ON d.geo_id = ks.geo_id AND d.district_type = ks.district_type AND lower(d.state) = 'ks'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id
);

-- ─── 3. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_house int; v_senate int; v_contam int; v_multi int; v_outside int; v_seeds int;
BEGIN
  SELECT count(*) INTO v_seeds FROM ks_seats;
  IF v_seeds <> 165 THEN
    RAISE EXCEPTION 'KS-2 structure: the seat list carries % rows, expected 165', v_seeds;
  END IF;

  SELECT count(*) INTO v_house
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Kansas House of Representatives';
  SELECT count(*) INTO v_senate
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Kansas Senate';

  IF v_house <> 125 THEN
    RAISE EXCEPTION 'KS-2 structure: expected 125 House offices (Kan. Const. art. 2 s 2), got %', v_house;
  END IF;
  IF v_senate <> 40 THEN
    RAISE EXCEPTION 'KS-2 structure: expected 40 Senate offices (Kan. Const. art. 2 s 2), got %', v_senate;
  END IF;

  -- The collision gate: no non-legislative district may have picked up a legislative office.
  SELECT count(*) INTO v_contam
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Kansas House of Representatives','Kansas Senate')
     AND d.district_type NOT IN ('STATE_LOWER','STATE_UPPER');
  IF v_contam <> 0 THEN
    RAISE EXCEPTION 'KS-2 structure: % legislative office(s) landed on a non-legislative district - the 83 shared Kansas geo_ids', v_contam;
  END IF;

  -- Both Kansas chambers are single-member, so exactly one office per district.
  SELECT count(*) INTO v_multi FROM (
    SELECT o.district_id
      FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.name_formal IN ('Kansas House of Representatives','Kansas Senate')
     GROUP BY o.district_id HAVING count(*) > 1) x;
  IF v_multi <> 0 THEN
    RAISE EXCEPTION 'KS-2 structure: % district(s) carry more than one office; both Kansas chambers are single-member', v_multi;
  END IF;

  -- Every office must sit on a Kansas district, not a same-numbered district in another state.
  SELECT count(*) INTO v_outside
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Kansas House of Representatives','Kansas Senate')
     AND lower(d.state) <> 'ks';
  IF v_outside <> 0 THEN
    RAISE EXCEPTION 'KS-2 structure: % office(s) landed on a district outside Kansas', v_outside;
  END IF;

  RAISE NOTICE 'KS-2 structure OK: % offices (% House, % Senate), 0 contamination, 1 office per district', v_house + v_senate, v_house, v_senate;
END $$;

COMMIT;
