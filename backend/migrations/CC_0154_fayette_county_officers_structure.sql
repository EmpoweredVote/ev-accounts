-- CC_0154_fayette_county_officers_structure.sql
-- Knight Foundation program, wave KY-4 (structure half). Slot RESERVED from the allocator.
--
-- Creates the Fayette County layer on the EXISTING Lexington-Fayette government row -- two chambers,
-- three magisterial districts and 18 offices. Creates NO people and NO terms; CC_0155 does that and
-- the two are applied back to back, because an office with no office_terms row is invisible and
-- NOTHING ERRORS (spec section 3, the Nashville correction).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 A CONSOLIDATED CITY-COUNTY DOES NOT ALWAYS DROP ITS COMMISSION, AND LEXINGTON DOES NOT.
-- Spec section 3.2 says stage 4 for a consolidated jurisdiction drops the county commission because
-- the city council already is it -- true for Philadelphia, Columbus-Muscogee and Macon-Bibb. The
-- Lexington-Fayette charter keeps BOTH the County Judge (11.01) and the Fiscal Court (11.02):
--   "The County Fiscal Court shall be composed of the Judge of the County Court and three (3)
--    Commissioners to be elected from the Urban County at-large"
-- It is vestigial but real: the school ad valorem levy, the county road-aid advisory power under
-- KRS 179.415, and one seat on the County Budget Commission. READ THE CHARTER, NOT THE PATTERN.
--
-- 🔴 FAYETTE ELECTS COMMISSIONERS *AND* MAGISTRATES. They are not alternative forms of one body
-- here. The Fiscal Court is the commissioner form; the Justices of the Peace survive separately
-- under charter 11.07 and, in Fayette, solemnise marriages and nothing else -- they do NOT sit on
-- the Fiscal Court. The county's own certified November 2022 general results list all nine district
-- and at-large seats: COMMISSIONER 1/2/3, MAGISTRATE 1/2/3, CONSTABLE 1/2/3.
--
-- 🔴 THE COMMISSIONERS ARE AT-LARGE, AND THE VOTE TOTALS ARE WHAT PROVED IT. The certified 2022
-- results give the commissioners 66,529 / 66,114 / 503 against a 102,742-vote countywide
-- judge/executive race, while the magistrates and constables polled 18,904-23,292 -- one third.
-- So "District 1/2/3" on a commissioner ballot line is a SEAT NUMBER, not a geography, and all
-- three commissioner offices hang on the COUNTYWIDE district. The title still reads "District N"
-- because that is what the county prints on the ballot; offices.description carries the truth.
-- ⚠ An earlier reading of the 2026 PRIMARY report put them at district scale. pdftotext had
-- INTERLEAVED that report's columns. A total you did not see labelled TOTAL is not a total.
--
-- 🔴 THERE IS NO ELECTED JAILER AND THIS MIGRATION MUST NOT CREATE ONE. Ky. Const. s 105 lets the
-- General Assembly merge Jailer into Sheriff and requires that SHERIFF be the office retained; the
-- charter's own editor's note records it -- "The sheriff and jailer were merged effective
-- January 3, 1994, by 1990 Ky. Acts Ch. 138." KRS 67A.028 then let the urban-county government
-- create a correctional services division holding every jail duty of both offices; that division is
-- Chapter 24 of the code and its staff are classified civil service. A named gate below refuses any
-- office titled Jailer.
--
-- 🔴 THE geo_id COLLISION LANDS ON THIS COUNTY. geo_id '21067' is Fayette County (G4020) AND State
-- House District 67 (G5220) -- the collision KY-1 measured and CLAUDE.md warns about. Every join
-- below pairs geo_id with district_type AND mtfcc, and a named gate asserts that no office of this
-- wave landed on a non-county, non-magisterial district.
--
-- REFUSES TO RUN IF THE X0069 BOUNDARIES ARE ABSENT. load-fayette-magisterial-boundaries.mjs writes
-- them. An office on a district with no polygon is unreachable by any address and nothing errors.
--
-- ⚠ NOTE FOR ANYONE RE-RUNNING CC_0152: this migration takes Kentucky's LOCAL district count from
-- 13 to 16, so CC_0152's post-verify gate ("expected 13 Kentucky LOCAL districts") no longer holds.
-- Migrations in this repo are applied once by hand and never replayed, so nothing breaks; the note
-- exists so the discrepancy is not read as drift.
--
-- Party is NOT written. Party is antipartisan and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 0. Refuse to run without the geometry ────────────────────────────────────

DO $$
DECLARE v_b int;
BEGIN
  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries WHERE mtfcc = 'X0069';
  IF v_b <> 3 THEN
    RAISE EXCEPTION 'CC_0154: X0069 holds % boundaries, expected 3. Run load-fayette-magisterial-boundaries.mjs first - an office on a district with no polygon is unreachable and nothing errors.', v_b;
  END IF;
END $$;

-- The countywide district must already exist; this wave creates no county row.
DO $$
DECLARE v_c int;
BEGIN
  SELECT count(*) INTO v_c FROM essentials.districts
   WHERE geo_id = '21067' AND district_type = 'COUNTY' AND mtfcc = 'G4020' AND lower(state) = 'ky';
  IF v_c <> 1 THEN
    RAISE EXCEPTION 'CC_0154: expected exactly 1 Fayette County (21067/G4020/COUNTY) district, found %', v_c;
  END IF;
END $$;

-- ─── 1. Two chambers on the EXISTING government row ───────────────────────────
--
-- No second government is invented for a county that IS the city -- Philadelphia's shape in PA-4,
-- and Columbus and Macon-Bibb before it.

DO $$
DECLARE v_g int;
BEGIN
  SELECT count(*) INTO v_g FROM essentials.governments
   WHERE name = 'Lexington-Fayette Urban County Government, Kentucky, US';
  IF v_g <> 1 THEN
    RAISE EXCEPTION 'CC_0154: expected the KY-3 government row to exist exactly once, found %', v_g;
  END IF;
END $$;

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length, staggered_term)
SELECT v.gid, v.nm, v.nm, v.cnt, v.tl, false
FROM (VALUES
  ((SELECT id FROM essentials.governments WHERE name = 'Lexington-Fayette Urban County Government, Kentucky, US'), 'Fayette County Fiscal Court', 4, 4),
  ((SELECT id FROM essentials.governments WHERE name = 'Lexington-Fayette Urban County Government, Kentucky, US'), 'Fayette County Elected Officials', 14, 4)
) AS v(gid, nm, cnt, tl)
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.name_formal = v.nm);

-- ─── 2. The three magisterial districts ───────────────────────────────────────
--
-- ONE SET OF POLYGONS, USED TWICE: Ky. Const. s 99 elects one Justice of the Peace AND one
-- Constable in each Justice's District, so each of these three districts carries TWO offices.
-- district_type is LOCAL, matching KY-3's council districts -- deliberately an EXISTING type, because
-- a novel district_type risks being invisible to the address read path, which is this program's
-- worst failure mode.

CREATE TEMP TABLE fay_districts(geo_id text, label text) ON COMMIT DROP;
INSERT INTO fay_districts(geo_id, label) VALUES
  ('fayette-county-ky-magisterial-district-1', 'Fayette County Magisterial District 1'),
  ('fayette-county-ky-magisterial-district-2', 'Fayette County Magisterial District 2'),
  ('fayette-county-ky-magisterial-district-3', 'Fayette County Magisterial District 3');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT fd.geo_id, fd.label, 'LOCAL', 'ky', 'X0069'
FROM fay_districts fd
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = fd.geo_id AND d.district_type = 'LOCAL' AND d.mtfcc = 'X0069' AND lower(d.state) = 'ky'
);

-- ─── 3. The 18 offices ────────────────────────────────────────────────────────

CREATE TEMP TABLE fay_seats(
  geo_id text, mtfcc text, district_type text, chamber_formal text, title text, descr text
) ON COMMIT DROP;

INSERT INTO fay_seats(geo_id, mtfcc, district_type, chamber_formal, title, descr) VALUES
  -- The Fiscal Court: the county judge/executive and three AT-LARGE commissioners.
  ('21067', 'G4020', 'COUNTY', 'Fayette County Fiscal Court', 'County Judge/Executive',
   'Presides over the Fayette County Fiscal Court. Under the Lexington-Fayette charter the Urban County Council and Mayor hold the governing powers a county judge/executive exercises elsewhere; this office retains the power to fill vacancies in the other county constitutional offices under KRS 63.220, to appoint the board of assessment appeals under KRS 133.020, and a seat on the County Budget Commission under KRS 68.230.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Fiscal Court', 'Fiscal Court Commissioner, District 1',
   'One of three Fayette County Fiscal Court commissioners. ELECTED AT-LARGE by the whole county - charter section 11.02 - so "District 1" is the seat number the county prints on the ballot, not a geography. The Fiscal Court retains the school district ad valorem levy, the county road-aid advisory power under KRS 179.415, and one appointment to the County Budget Commission; the Urban County Council holds everything else.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Fiscal Court', 'Fiscal Court Commissioner, District 2',
   'One of three Fayette County Fiscal Court commissioners. ELECTED AT-LARGE by the whole county - charter section 11.02 - so "District 2" is the seat number the county prints on the ballot, not a geography. The Fiscal Court retains the school district ad valorem levy, the county road-aid advisory power under KRS 179.415, and one appointment to the County Budget Commission; the Urban County Council holds everything else.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Fiscal Court', 'Fiscal Court Commissioner, District 3',
   'One of three Fayette County Fiscal Court commissioners. ELECTED AT-LARGE by the whole county - charter section 11.02 - so "District 3" is the seat number the county prints on the ballot, not a geography. The Fiscal Court retains the school district ad valorem levy, the county road-aid advisory power under KRS 179.415, and one appointment to the County Budget Commission; the Urban County Council holds everything else.'),

  -- The countywide constitutional officers.
  ('21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'County Clerk',
   'Fayette County Clerk. Records and administers official documents, prepares property tax bills, registers voters and conducts elections, and registers and titles motor vehicles. Charter section 11.03.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'County Attorney',
   'Fayette County Attorney. Prosecutes misdemeanours and traffic offences in District Court, advises the urban-county government, and handles child support and juvenile matters. Charter section 11.04.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Sheriff',
   'Fayette County Sheriff. Serves court process, provides courthouse and court security, and is the primary collector of current-year ad valorem property taxes. ⚠ NOT the principal conservator of the peace: charter section 11.05 transfers that function to the Chief of Police. The office also absorbed the Jailer, merged into it effective 1994-01-03 by 1990 Ky. Acts Ch. 138 under Ky. Const. s 105, though the jail itself is run by the urban-county correctional services division under KRS 67A.028.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Property Valuation Administrator',
   'Fayette County Property Valuation Administrator. The chief assessing officer of the urban-county government: determines the fair cash value of property and administers the homestead and disability exemptions. Charter section 11.06; the office is the elected successor to the constitutional Assessor abolished under Ky. Const. s 104.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Coroner',
   'Fayette County Coroner. Investigates deaths falling under the office''s jurisdiction and administers the indigent burial and cremation programme. Charter section 11.07.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'County Surveyor',
   'Fayette County Surveyor, a constitutional county office under Ky. Const. s 99, preserved by charter section 11.07.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Circuit Court Clerk',
   'Fayette Circuit Court Clerk. Keeps the records of the Circuit, Family, District and Business courts. Elected countywide to a SIX-year term under Ky. Const. s 97, on a different cycle from the four-year county offices. Charter section 11.07.'),
  ('21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Commonwealth''s Attorney',
   'Commonwealth''s Attorney for the 22nd Judicial Circuit, which is Fayette County. Prosecutes felonies in Circuit Court. Elected to a SIX-year term under Ky. Const. s 97. Charter section 11.07.'),

  -- Magistrates and constables: one of each per Justice's District, on the same three polygons.
  ('fayette-county-ky-magisterial-district-1', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Magistrate, District 1',
   'Justice of the Peace for Fayette County Magisterial District 1. ⚠ In Fayette County the magistrate does NOT sit on the Fiscal Court - the county uses the commissioner form, and its three commissioners are elected at-large. The office is preserved by charter section 11.07 under Ky. Const. s 99, and in practice its role is to solemnise marriages.'),
  ('fayette-county-ky-magisterial-district-2', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Magistrate, District 2',
   'Justice of the Peace for Fayette County Magisterial District 2. ⚠ In Fayette County the magistrate does NOT sit on the Fiscal Court - the county uses the commissioner form, and its three commissioners are elected at-large. The office is preserved by charter section 11.07 under Ky. Const. s 99, and in practice its role is to solemnise marriages.'),
  ('fayette-county-ky-magisterial-district-3', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Magistrate, District 3',
   'Justice of the Peace for Fayette County Magisterial District 3. ⚠ In Fayette County the magistrate does NOT sit on the Fiscal Court - the county uses the commissioner form, and its three commissioners are elected at-large. The office is preserved by charter section 11.07 under Ky. Const. s 99, and in practice its role is to solemnise marriages.'),
  ('fayette-county-ky-magisterial-district-1', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Constable, District 1',
   'Constable for Fayette County Magisterial District 1, a peace officer elected in the same Justice''s District as the magistrate under Ky. Const. s 99 and preserved by charter section 11.07. The Division of Police, not the constable, is the urban-county government''s police force.'),
  ('fayette-county-ky-magisterial-district-2', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Constable, District 2',
   'Constable for Fayette County Magisterial District 2, a peace officer elected in the same Justice''s District as the magistrate under Ky. Const. s 99 and preserved by charter section 11.07. The Division of Police, not the constable, is the urban-county government''s police force.'),
  ('fayette-county-ky-magisterial-district-3', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Constable, District 3',
   'Constable for Fayette County Magisterial District 3, a peace officer elected in the same Justice''s District as the magistrate under Ky. Const. s 99 and preserved by charter section 11.07. The Division of Police, not the constable, is the urban-county government''s police force.');

-- Every seat here has a DISTINCT (chamber, district, title), unlike Lexington's three at-large
-- council seats, so a plain NOT EXISTS guard is correct and idempotent.
INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant)
SELECT c.id, d.id, s.title, s.descr, 'KY', 'Lexington', 1, false
FROM fay_seats s
JOIN essentials.chambers c ON c.name_formal = s.chamber_formal
JOIN essentials.districts d
  ON d.geo_id = s.geo_id AND d.district_type = s.district_type AND d.mtfcc = s.mtfcc AND lower(d.state) = 'ky'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = s.title
);

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_ch int; v_dist int; v_fc int; v_eo int; v_off int;
  v_countywide int; v_magisterial int; v_collide int; v_nogeo int;
BEGIN
  SELECT count(*) INTO v_ch FROM essentials.chambers
   WHERE name_formal IN ('Fayette County Fiscal Court', 'Fayette County Elected Officials');
  IF v_ch <> 2 THEN RAISE EXCEPTION 'CC_0154: expected 2 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'LOCAL' AND mtfcc = 'X0069' AND lower(state) = 'ky';
  IF v_dist <> 3 THEN RAISE EXCEPTION 'CC_0154: expected 3 magisterial districts, got %', v_dist; END IF;

  SELECT count(*) INTO v_fc FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.name_formal = 'Fayette County Fiscal Court';
  SELECT count(*) INTO v_eo FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.name_formal = 'Fayette County Elected Officials';
  v_off := v_fc + v_eo;
  IF v_fc <> 4 THEN RAISE EXCEPTION 'CC_0154: expected 4 Fiscal Court offices (judge/executive + 3 at-large commissioners), got %', v_fc; END IF;
  IF v_eo <> 14 THEN RAISE EXCEPTION 'CC_0154: expected 14 Fayette County Elected Officials offices, got %', v_eo; END IF;

  -- 🔴 THE JAILER GATE. Ky. Const. s 105 merged the office into the Sheriff effective 1994-01-03.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.chambers c ON c.id = o.chamber_id
              WHERE c.name_formal IN ('Fayette County Fiscal Court', 'Fayette County Elected Officials')
                AND o.title ILIKE '%jailer%') THEN
    RAISE EXCEPTION 'CC_0154: a JAILER office exists. The sheriff and jailer were merged effective 1994-01-03 by 1990 Ky. Acts Ch. 138 under Ky. Const. s 105, and the Sheriff is the office retained. Fayette elects no jailer.';
  END IF;

  -- 🔴 THE geo_id COLLISION GATE. '21067' is Fayette County AND State House District 67.
  SELECT count(*) INTO v_collide FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Fayette County Fiscal Court', 'Fayette County Elected Officials')
     AND NOT (d.mtfcc = 'G4020' AND d.district_type = 'COUNTY')
     AND NOT (d.mtfcc = 'X0069' AND d.district_type = 'LOCAL');
  IF v_collide <> 0 THEN
    RAISE EXCEPTION 'CC_0154: % Fayette office(s) landed on a district that is neither the county (21067/G4020) nor a magisterial district (X0069). geo_id 21067 is ALSO State House District 67 - pair geo_id with mtfcc, always.', v_collide;
  END IF;

  -- Twelve seats countywide, six on the magisterial polygons.
  SELECT count(*) INTO v_countywide FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Fayette County Fiscal Court', 'Fayette County Elected Officials')
     AND d.mtfcc = 'G4020';
  SELECT count(*) INTO v_magisterial FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Fayette County Fiscal Court', 'Fayette County Elected Officials')
     AND d.mtfcc = 'X0069';
  IF v_countywide <> 12 THEN RAISE EXCEPTION 'CC_0154: expected 12 countywide offices, got %', v_countywide; END IF;
  IF v_magisterial <> 6 THEN RAISE EXCEPTION 'CC_0154: expected 6 magisterial-district offices (3 magistrates + 3 constables), got %', v_magisterial; END IF;

  -- Every magisterial seat must sit on a district that actually has a polygon.
  SELECT count(*) INTO v_nogeo FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN ('Fayette County Fiscal Court', 'Fayette County Elected Officials')
     AND d.mtfcc = 'X0069'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = 'X0069');
  IF v_nogeo <> 0 THEN
    RAISE EXCEPTION 'CC_0154: % magisterial office(s) sit on a district with no X0069 polygon - unreachable by address, and nothing would error', v_nogeo;
  END IF;

  RAISE NOTICE 'CC_0154 OK: 2 chambers, 3 magisterial districts, % offices (% fiscal court, % elected officials; % countywide, % magisterial)',
    v_off, v_fc, v_eo, v_countywide, v_magisterial;
END $$;

COMMIT;
