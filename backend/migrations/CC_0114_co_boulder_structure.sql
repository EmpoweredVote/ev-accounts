-- CC_0114_co_boulder_structure.sql
-- Knight Foundation program, wave CO-3 (structure half). Slot RESERVED from the allocator.
--
-- Creates both Boulder jurisdictions, which have nothing in production today -- no government row,
-- no district row for the city, no office, no official:
--
--   City of Boulder      1 chamber    1 district   9 offices  (Mayor + 8 at-large council seats)
--   Boulder County       2 chambers   0 districts  10 offices (3 commissioners + 7 county officers)
--
-- Creates NO people and NO terms -- CC_0115 does that, and the two are applied back to back.
--
-- 🔴🔴 THE ONLY "BOULDER" IN PRODUCTION IS IN NEVADA. essentials.governments holds exactly one row
-- matching '%Boulder%': 'City of Boulder City, Nevada, US', a real city of 15,000 outside Las Vegas,
-- already seated with five council offices. A wave that finds this city by NAME seats Colorado's
-- council under a Nevada city and reports success. Every lookup here is by TIGER place geo_id
-- '0807850'. This is the Saint Paul/Texas trap from CC_0109 in a second dress.
--
-- 🔴 BOULDER'S NINE SEATS ARE ONE CHAMBER, NOT TWO, AND THE MAYOR SITS INSIDE IT.
-- The city's own FAQ: "The City Council consists of nine members, including a mayor and mayor pro
-- tem", and "all City Council members are elected at-large". Boulder is council-manager: the city
-- manager is the executive and the mayor is a voting member of the council who presides. So there
-- is no 'Office of the Mayor' chamber here -- unlike Duluth and Saint Paul (CC_0109), whose mayors
-- are citywide executives sitting outside the council. The mayor IS directly elected, by ranked
-- choice since 2023 (Measure 2E, 2020), so it is a distinct OFFICE on the ballot -- but a distinct
-- office inside the council, which is what the charter describes.
--
-- 🔴 NO DISTRICT LAYER, AND THAT IS A FACT ABOUT BOULDER RATHER THAN ABOUT COLORADO.
-- All nine seats are at-large, so every office hangs on the TIGER place polygon. Colorado Springs,
-- seated in an earlier wave in this same state, is six districts plus three at-large plus a Mayor.
-- The state imposes no council shape; read each charter.
--
-- 🔴 THE EIGHT AT-LARGE SEATS ARE NOT NUMBERED AND THIS MIGRATION REFUSES TO NUMBER THEM.
-- They are filled four at a time in one citywide race. Numbering them would describe a ballot
-- designation Boulder does not have. All eight carry the IDENTICAL voter-facing title and the join
-- key lives in `description` as an internal ordinal. Same treatment as Duluth's four.
--
-- 🔴 BOULDER COUNTY ELECTS ITS COMMISSIONERS COUNTY-WIDE, SO THEY HANG ON THE COUNTY ROW.
-- Measured from the county's own tabulation rather than assumed: District 1 drew 143,314 votes,
-- District 2 135,438 and District 3 119,639 -- county-wide turnout, not a third of it. The district
-- number is a RESIDENCY requirement; the electorate is the whole county, and all three represent
-- every county voter. El Paso County (X0033) is wired the other way because it elects by district.
--
-- 🔴 BOULDER ELECTS A SURVEYOR AND THE SEATED EL PASO TEMPLATE HAS NO SURVEYOR ROW.
-- El Paso is 5 commissioners + Assessor, Clerk and Recorder, Coroner, District Attorney, Sheriff,
-- Treasurer and Public Trustee. Colo. Const. art. XIV s 8 names the surveyor among county officers,
-- so the difference is each county's practice, not the state's rule. Boulder's own Elected Officials
-- page names seven: Assessor, Clerk & Recorder, Coroner, District Attorney, Sheriff, Surveyor,
-- Treasurer. Read the county's page; never inherit the neighbour's chamber list.
--
-- ⚠ THE DISTRICT ATTORNEY IS THE 20th JUDICIAL DISTRICT, WHICH IS BOULDER COUNTY ALONE. That is why
-- the office sits under the county here. El Paso's DA could not be modelled this way: its 4th
-- Judicial District also covers Teller County.
--
-- ⚠ `08013` IS THREE DIFFERENT DISTRICTS -- G4020 (Boulder County), G5210 (State Senate 13) and
-- G5220 (State House 13) share the geo_id string. Every join below keys on (mtfcc, geo_id) or on
-- district_type, never on geo_id alone.
--
-- ⚠ districts.state is written LOWERCASE 'co', matching every other local district in production.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight: the geography this wave hangs on must already exist ─────────

DO $$
DECLARE v_place int; v_county int; v_nv int;
BEGIN
  SELECT count(*) INTO v_place FROM essentials.geofence_boundaries
   WHERE geo_id = '0807850' AND mtfcc = 'G4110';
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'CO-3 pre-flight: TIGER place 0807850/G4110 (Boulder city) is missing -- the nine citywide offices would be unreachable by address and nothing would error.';
  END IF;

  SELECT count(*) INTO v_county FROM essentials.districts
   WHERE geo_id = '08013' AND mtfcc = 'G4020' AND district_type::text = 'COUNTY';
  IF v_county <> 1 THEN
    RAISE EXCEPTION 'CO-3 pre-flight: the Boulder County district row (08013/G4020/COUNTY) is missing or duplicated -- got %', v_county;
  END IF;

  -- 🔴 The Nevada city must be present and untouched, because it is the row a name-based lookup
  -- would have found. If it has gone, something else has already gone wrong.
  SELECT count(*) INTO v_nv FROM essentials.governments WHERE name = 'City of Boulder City, Nevada, US';
  IF v_nv <> 1 THEN
    RAISE EXCEPTION 'CO-3 pre-flight: expected exactly 1 Boulder City, Nevada government, got %', v_nv;
  END IF;
END $$;

-- ─── 1. Two governments ──────────────────────────────────────────────────────
-- ⚠ Matched and guarded on geo_id, never on name. See the Nevada note above.

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Boulder, Colorado, US', 'LOCAL', 'CO', 'Boulder', '0807850'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '0807850');

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Boulder County, Colorado, US', 'County', 'CO', NULL, '08013'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '08013');

-- ─── 2. Three chambers ───────────────────────────────────────────────────────
-- One for the city: nine members INCLUDING the mayor, per the charter.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Boulder City Council', 'Boulder City Council', 9
FROM essentials.governments g
WHERE g.geo_id = '0807850'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Boulder City Council');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Board of County Commissioners', 'Boulder County Board of County Commissioners', 3
FROM essentials.governments g
WHERE g.geo_id = '08013'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'County Elected Officials', 'Boulder County Elected Officials', 7
FROM essentials.governments g
WHERE g.geo_id = '08013'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'County Elected Officials');

-- ─── 3. One district ─────────────────────────────────────────────────────────
-- The city place polygon exists as a BOUNDARY and carries no district row -- the same gap GA-1 left
-- for Columbus and Macon. Without this row the nine citywide offices resolve to nothing.
-- The county already has its district row; this migration does not touch it.

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT '0807850', 'Boulder Citywide', 'LOCAL', 'co', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '0807850' AND mtfcc = 'G4110' AND district_type::text = 'LOCAL');

-- ─── 4. Nineteen offices ─────────────────────────────────────────────────────

CREATE TEMP TABLE co3_offices(
  gov_geo_id text, district_geo_id text, district_mtfcc text,
  chamber_name text, title text, description text, city text) ON COMMIT DROP;

INSERT INTO co3_offices VALUES
  -- City: the mayor and eight unnumbered at-large seats, all on the place polygon.
  ('0807850', '0807850', 'G4110', 'Boulder City Council', 'Mayor',
   'Directly elected by ranked-choice vote since 2023 (Measure 2E, 2020). A voting member of the nine-member council who presides; Boulder is council-manager, so the city manager is the executive.', 'Boulder'),
  ('0807850', '0807850', 'G4110', 'Boulder City Council', 'Council Member',
   'Internal ordinal 1 of 8. Boulder does not number its council seats; all are elected at large, four at a time. Not a ballot designation.', 'Boulder'),
  ('0807850', '0807850', 'G4110', 'Boulder City Council', 'Council Member',
   'Internal ordinal 2 of 8. Boulder does not number its council seats; all are elected at large, four at a time. Not a ballot designation.', 'Boulder'),
  ('0807850', '0807850', 'G4110', 'Boulder City Council', 'Council Member',
   'Internal ordinal 3 of 8. Boulder does not number its council seats; all are elected at large, four at a time. Not a ballot designation.', 'Boulder'),
  ('0807850', '0807850', 'G4110', 'Boulder City Council', 'Council Member',
   'Internal ordinal 4 of 8. Boulder does not number its council seats; all are elected at large, four at a time. Not a ballot designation.', 'Boulder'),
  ('0807850', '0807850', 'G4110', 'Boulder City Council', 'Council Member',
   'Internal ordinal 5 of 8. Boulder does not number its council seats; all are elected at large, four at a time. Not a ballot designation.', 'Boulder'),
  ('0807850', '0807850', 'G4110', 'Boulder City Council', 'Council Member',
   'Internal ordinal 6 of 8. Boulder does not number its council seats; all are elected at large, four at a time. Not a ballot designation.', 'Boulder'),
  ('0807850', '0807850', 'G4110', 'Boulder City Council', 'Council Member',
   'Internal ordinal 7 of 8. Boulder does not number its council seats; all are elected at large, four at a time. Not a ballot designation.', 'Boulder'),
  ('0807850', '0807850', 'G4110', 'Boulder City Council', 'Council Member',
   'Internal ordinal 8 of 8. Boulder does not number its council seats; all are elected at large, four at a time. Not a ballot designation.', 'Boulder'),
  -- County: three commissioners, elected county-wide, on the county row.
  ('08013', '08013', 'G4020', 'Board of County Commissioners', 'Commissioner, District 1',
   'Elected county-wide. The district is a residency requirement, not a separate electorate.', NULL),
  ('08013', '08013', 'G4020', 'Board of County Commissioners', 'Commissioner, District 2',
   'Elected county-wide. The district is a residency requirement, not a separate electorate.', NULL),
  ('08013', '08013', 'G4020', 'Board of County Commissioners', 'Commissioner, District 3',
   'Elected county-wide. The district is a residency requirement, not a separate electorate.', NULL),
  -- County: the seven officers Boulder's own Elected Officials page names.
  ('08013', '08013', 'G4020', 'County Elected Officials', 'Assessor', NULL, NULL),
  ('08013', '08013', 'G4020', 'County Elected Officials', 'Clerk and Recorder', NULL, NULL),
  ('08013', '08013', 'G4020', 'County Elected Officials', 'Coroner', NULL, NULL),
  ('08013', '08013', 'G4020', 'County Elected Officials', 'District Attorney',
   'Elected for the 20th Judicial District, which is Boulder County alone.', NULL),
  ('08013', '08013', 'G4020', 'County Elected Officials', 'Sheriff', NULL, NULL),
  ('08013', '08013', 'G4020', 'County Elected Officials', 'Surveyor', NULL, NULL),
  ('08013', '08013', 'G4020', 'County Elected Officials', 'Treasurer', NULL, NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, description,
                                representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'CO', n.city, 1, false, 'full'
FROM co3_offices n
JOIN essentials.districts d
  ON d.geo_id = n.district_geo_id AND d.mtfcc = n.district_mtfcc AND lower(d.state) = 'co'
JOIN essentials.governments g ON g.geo_id = n.gov_geo_id
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off_city int; v_off_cty int;
  v_seats int; v_seat_desc int; v_nv_offices int; v_mayor int; v_surveyor int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE geo_id IN ('0807850','08013');
  IF v_gov <> 2 THEN RAISE EXCEPTION 'CO-3 structure: expected 2 governments, got %', v_gov; END IF;

  -- 🔴 The Nevada city must be untouched, and must still hold exactly its own five offices.
  SELECT count(*) INTO v_nv_offices
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Boulder City, Nevada, US';
  IF v_nv_offices <> 5 THEN
    RAISE EXCEPTION 'CO-3 structure: Boulder City, NEVADA now holds % offices, expected 5 -- Colorado work has landed on the wrong city', v_nv_offices;
  END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.geo_id IN ('0807850','08013');
  IF v_ch <> 3 THEN RAISE EXCEPTION 'CO-3 structure: expected 3 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE geo_id = '0807850' AND mtfcc = 'G4110' AND district_type::text = 'LOCAL' AND lower(state) = 'co';
  IF v_dist <> 1 THEN RAISE EXCEPTION 'CO-3 structure: expected 1 Boulder citywide district, got %', v_dist; END IF;

  SELECT count(*) INTO v_off_city FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '0807850';
  IF v_off_city <> 9 THEN RAISE EXCEPTION 'CO-3 structure: expected 9 city offices, got %', v_off_city; END IF;

  SELECT count(*) INTO v_off_cty FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '08013';
  IF v_off_cty <> 10 THEN RAISE EXCEPTION 'CO-3 structure: expected 10 county offices, got %', v_off_cty; END IF;

  -- Exactly one Mayor, inside the council chamber -- not a chamber of its own.
  SELECT count(*) INTO v_mayor FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '0807850' AND o.title = 'Mayor' AND c.name = 'Boulder City Council';
  IF v_mayor <> 1 THEN
    RAISE EXCEPTION 'CO-3 structure: expected exactly 1 Mayor office inside Boulder City Council, got %', v_mayor;
  END IF;

  -- Eight at-large seats sharing one title, with eight DISTINCT internal ordinals -- without which
  -- CC_0115 cannot attach a person to a seat deterministically.
  SELECT count(*), count(DISTINCT o.description) INTO v_seats, v_seat_desc
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id = '0807850' AND o.title = 'Council Member';
  IF v_seats <> 8 OR v_seat_desc <> 8 THEN
    RAISE EXCEPTION 'CO-3 structure: Boulder council is % seat(s) with % distinct ordinal(s), expected 8 and 8', v_seats, v_seat_desc;
  END IF;

  -- Boulder must have NO numbered council seat and NO council district: all nine are at large.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.geo_id = '0807850' AND o.title ~ 'District [0-9]'
  ) THEN
    RAISE EXCEPTION 'CO-3 structure: a Boulder city office is titled by district; every seat is at large';
  END IF;

  -- The Surveyor is the row El Paso's template does not have. Assert it explicitly, so a future
  -- reader who "tidies" the chamber list against El Paso breaks a gate rather than a county.
  SELECT count(*) INTO v_surveyor FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '08013' AND o.title = 'Surveyor';
  IF v_surveyor <> 1 THEN
    RAISE EXCEPTION 'CO-3 structure: expected exactly 1 Boulder County Surveyor office, got % -- Boulder elects one and El Paso County does not', v_surveyor;
  END IF;

  -- Every city office must resolve through the place polygon, or it is unreachable by address.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE g.geo_id = '0807850' AND (d.geo_id <> '0807850' OR d.mtfcc <> 'G4110')
  ) THEN
    RAISE EXCEPTION 'CO-3 structure: a Boulder city office does not hang on place 0807850/G4110';
  END IF;

  RAISE NOTICE 'CO-3 structure OK: % governments, % chambers, 1 citywide district, % city offices, % county offices (8 at-large ordinals, 1 surveyor, Nevada untouched at % offices)',
    v_gov, v_ch, v_off_city, v_off_cty, v_nv_offices;
END $$;

COMMIT;
