-- CC_0155_fayette_county_officers_incumbents.sql
-- Knight Foundation program, wave KY-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0154.
--
-- Seats all 18 elected Fayette County officers: the county judge/executive, three at-large Fiscal
-- Court commissioners, eight countywide constitutional officers, three magistrates and three
-- constables. 18 people, 18 terms, 0 vacancies.
--
-- Every name, date and count below was read from a source's own bytes. Full roster and sourcing:
-- backend/data/seed-ky-2026/ROSTERS-fayette.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT, AND THIS WAVE PROVES IT TWICE.
--
--   * COUNTY CLERK. Don Blevins Jr. won the November 2022 general with 69,903 votes (67%) and does
--     NOT hold the office. SUSAN LAMB was appointed 2023-02-01 and then won the November 2023
--     SPECIAL election. Her own office publishes the succession list: "Susan Lamb 2023-Present /
--     Donald W. Blevins Jr. 2009-2023". Seating the 2022 winners wholesale would seat the wrong
--     person in the office that runs Fayette County's elections.
--   * MAGISTRATE DISTRICT 3. George Biggerstaff won it in 2022, assumed office 2023-01-02 and LEFT
--     OFFICE 2023-08-26. The city's own GIS layer carries MAGREP = 'Chrysanthia Carr-Seals (D)' for
--     district 3, and districts 1 and 2 match the certified result exactly.
--
-- 🔴 AND NOTHING DATES CARR-SEALS' ARRIVAL, SO NOTHING IS WRITTEN FOR IT. No publisher gives a day,
-- a month or even a stated year for her appointment. Her row is an OPEN-ENDED term with
-- start_precision = 'unknown'. A date is not invented, and 'the day after Biggerstaff left' is not
-- a source. ⚠ A Governor's press release reappointing the same person to a STATE BOARD through
-- 2027-01-17 is a different body and is not evidence about this seat.
--
-- 🔴 "FIRST MONDAY IN JANUARY" IS A COMPUTED DATE AND IS NOT WRITTEN AT DAY PRECISION.
-- Ky. Const. s 99 fixes the start of a county officer's term at the first Monday in January after
-- the election -- 2023-01-02 for the 2022 winners -- and secondary sources print exactly that for
-- nine of these eighteen. That is a computed date wearing a citation. KY-2 and KY-3 each proved a
-- computed arrival wrong inside this same slice, so every such row is written at YEAR precision.
-- Only FOUR arrivals are claimed at day precision, and each is first-party or contemporaneous:
--     David O'Neill      2009-02-11  his own office: "since February 11, 2009, when he was
--                                    appointed by Governor Steve Beshear"
--     Angela C. Evans    2022-09-30  WKYT the same day: "He is stepping down Friday. Evans was
--                                    sworn in at 3 Friday afternoon."
--     Kimberly Baird     2022-10-01  a specific, non-default date
--     Susan Lamb         2023-02-01  a specific, non-default date
--
-- ⚠ FIVE OF EIGHTEEN DO NOT START WHEN THEIR CURRENT TERM DID -- Witt 1999, Ginn 2003, O'Neill
-- 2009, Riggs 2013, Sparks 2015. office_terms carries CONTINUOUS OCCUPANCY (North Carolina's rows
-- reach back to 1999-01-01), so a re-election must never overwrite the earlier start. That is the
-- KY-2/KY-3 gap-case trap, at 28% of this wave.
--
-- NAMESAKES -- two, both measured and both a different person. The exact (full_name) pass over
-- production returned exactly two hits and the check was CONTROLLED with names known to exist
-- (Steven Rudy from KY-2 and Linda Gorton from KY-3, each returning 1), so the other sixteen zeros
-- are real answers and not a broken query:
--     Brian Miller  -300285  a seatless discovery-cohort row, no source, is_incumbent = false
--     David Lowe    -100591  a TEXAS House District 91 member, is_incumbent = true
-- The duplicate-name guard is lifted for those two rows only, never for the migration.
--
-- external_id block -2762784..-2762767 measured EMPTY; the nearest occupied id below it is
-- -2762785, which is KY-3's last row (Hil Boone).
--
-- ⚠ NAME FORMS. The county's own certified results capitalise the surname, which is what fixed each
-- first/last split here. Two forms are deliberately not written: the nickname in
-- Edward "Eddie" SPARKS, and the surname variant "Seals" that the 2026 filing uses for
-- Chrysanthia Carr-Seals -- the city's own GIS names the sitting magistrate Carr-Seals.
--
-- Party is NOT written. Party is antipartisan and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 1. The 18 people ─────────────────────────────────────────────────────────

CREATE TEMP TABLE fay_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO fay_people(external_id, full_name, first_name, last_name) VALUES
  (-2762784, 'Mary Diane McCord Hanna', 'Mary Diane', 'Hanna'),
  (-2762783, 'Brian Miller',            'Brian',      'Miller'),
  (-2762782, 'Alayne White',            'Alayne',     'White'),
  (-2762781, 'David Lowe',              'David',      'Lowe'),
  (-2762780, 'Susan Lamb',              'Susan',      'Lamb'),
  (-2762779, 'Angela C. Evans',         'Angela',     'Evans'),
  (-2762778, 'Kathy H. Witt',           'Kathy',      'Witt'),
  (-2762777, 'David O''Neill',          'David',      'O''Neill'),
  (-2762776, 'Gary W. Ginn',            'Gary',       'Ginn'),
  (-2762775, 'Gary D. Roland',          'Gary',       'Roland'),
  (-2762774, 'Vincent Riggs',           'Vincent',    'Riggs'),
  (-2762773, 'Kimberly Baird',          'Kimberly',   'Baird'),
  (-2762772, 'Rosalind A. Bryant',      'Rosalind',   'Bryant'),
  (-2762771, 'Lisa Moore Fath',         'Lisa',       'Fath'),
  (-2762770, 'Chrysanthia Carr-Seals',  'Chrysanthia','Carr-Seals'),
  (-2762769, 'Andrea Welker',           'Andrea',     'Welker'),
  (-2762768, 'Jim McKenzie',            'Jim',        'McKenzie'),
  (-2762767, 'Edward Sparks',           'Edward',     'Sparks');

-- 🔴 is_incumbent IS SET EXPLICITLY. It defaults to false since CA_0188, and a seated person
-- inserted without it is HIDDEN from address search. Every one of these 18 holds the seat now.
--
-- 🔴 THE DUPLICATE-NAME GUARD STAYS ARMED FOR 16 OF THE 18, AND IS LIFTED FOR EXACTLY TWO ROWS.
-- The insert is split for that reason and no other. Both collisions were opened and read before
-- the guard was touched, because the guard's own warning is right -- a sitting officeholder
-- running for a different seat is the normal case, not a different person:
--   * Brian Miller (-300285) is a candidate for U.S. REPRESENTATIVE, MONTANA DISTRICT 2 in the
--     2026 general. Fayette's Brian Miller is a county fiscal court commissioner in Kentucky.
--   * David Lowe (-100591) is a sitting member for TEXAS HOUSE DISTRICT 91.
-- Neither can be the Fayette officer. Nothing else in the wave collided, and that zero was
-- CONTROLLED against two names known to exist (Steven Rudy, Linda Gorton), each returning 1.

-- The sixteen that collide with nothing -- guard fully armed.
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Fayette County, Kentucky elected officers. Office inventory read from the Lexington-Fayette Urban County Charter, Article 11, at Municode (lexington-fayette_urban client, content updated 2026-07-17), cross-checked against the Fayette County Clerk''s own certified November 2022 general results. Occupancy verified per officer against the officeholder''s own publisher where one exists -- fayettesheriff.com, fayettekyclerk.gov, fayettecountyattorney.com, fayettepva.com, the LFUCG Coroner''s Office page and kycourts.gov -- and against the city''s own Magisterial_District GIS layer for the magistrates. Read 2026-09-26 (KY-4) (CC_0155, KY-4)',
       true, true
FROM fay_people n
WHERE n.external_id NOT IN (-2762783, -2762781)
  AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- The two measured namesakes, and only those two.
SET LOCAL essentials.allow_duplicate_name = 'on';

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Fayette County, Kentucky elected officers. Office inventory read from the Lexington-Fayette Urban County Charter, Article 11, at Municode (lexington-fayette_urban client, content updated 2026-07-17), cross-checked against the Fayette County Clerk''s own certified November 2022 general results. NAMESAKE: an unrelated politician row already carries this exact name -- Brian Miller is a 2026 U.S. House candidate in MONTANA district 2, David Lowe is a sitting TEXAS House district 91 member -- and both were read before the duplicate-name guard was lifted for these two rows. Read 2026-09-26 (KY-4) (CC_0155, KY-4)',
       true, true
FROM fay_people n
WHERE n.external_id IN (-2762783, -2762781)
  AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 2. The 18 terms ──────────────────────────────────────────────────────────

CREATE TEMP TABLE fay_terms(
  external_id bigint, geo_id text, mtfcc text, district_type text, chamber_formal text, title text,
  term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO fay_terms(external_id, geo_id, mtfcc, district_type, chamber_formal, title, term_start, start_precision, how_started) VALUES
  -- The Fiscal Court, all four elected countywide.
  (-2762784, '21067', 'G4020', 'COUNTY', 'Fayette County Fiscal Court', 'County Judge/Executive',                DATE '2023-01-01', 'year', 'elected'),
  (-2762783, '21067', 'G4020', 'COUNTY', 'Fayette County Fiscal Court', 'Fiscal Court Commissioner, District 1', DATE '2023-01-01', 'year', 'elected'),
  (-2762782, '21067', 'G4020', 'COUNTY', 'Fayette County Fiscal Court', 'Fiscal Court Commissioner, District 2', DATE '2023-01-01', 'year', 'elected'),
  -- ⚠ David Lowe won this countywide seat as a WRITE-IN with 503 votes, marked (W) on the county's
  -- own certified return. A turnout sanity check would flag that row as broken data. It is correct.
  (-2762781, '21067', 'G4020', 'COUNTY', 'Fayette County Fiscal Court', 'Fiscal Court Commissioner, District 3', DATE '2023-01-01', 'year', 'elected'),

  -- The countywide constitutional officers.
  (-2762780, '21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'County Clerk',                     DATE '2023-02-01', 'day',  'appointed'),
  (-2762779, '21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'County Attorney',                  DATE '2022-09-30', 'day',  'appointed'),
  (-2762778, '21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Sheriff',                          DATE '1999-01-01', 'year', 'elected'),
  (-2762777, '21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Property Valuation Administrator', DATE '2009-02-11', 'day',  'appointed'),
  (-2762776, '21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Coroner',                          DATE '2003-01-01', 'year', 'elected'),
  (-2762775, '21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'County Surveyor',                  DATE '2019-01-01', 'year', 'elected'),
  (-2762774, '21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Circuit Court Clerk',              DATE '2013-01-01', 'year', 'elected'),
  (-2762773, '21067', 'G4020', 'COUNTY', 'Fayette County Elected Officials', 'Commonwealth''s Attorney',         DATE '2022-10-01', 'day',  'appointed'),

  -- Magistrates and constables, on the three magisterial polygons.
  (-2762772, 'fayette-county-ky-magisterial-district-1', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Magistrate, District 1', DATE '2023-01-01', 'year', 'elected'),
  (-2762771, 'fayette-county-ky-magisterial-district-2', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Magistrate, District 2', DATE '2023-01-01', 'year', 'elected'),
  -- 🔴 NULL start, 'unknown' precision: she replaced Biggerstaff after 2023-08-26 and no source
  -- anywhere states when. An open-ended term is the honest record; a guess would not be.
  (-2762770, 'fayette-county-ky-magisterial-district-3', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Magistrate, District 3', NULL,              'unknown', 'appointed'),
  (-2762769, 'fayette-county-ky-magisterial-district-1', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Constable, District 1',  DATE '2023-01-01', 'year', 'elected'),
  (-2762768, 'fayette-county-ky-magisterial-district-2', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Constable, District 2',  DATE '2023-01-01', 'year', 'elected'),
  -- ⚠ Sparks predates the 2022 win: continuous occupancy since 2015, not since this term.
  (-2762767, 'fayette-county-ky-magisterial-district-3', 'X0069', 'LOCAL', 'Fayette County Elected Officials', 'Constable, District 3',  DATE '2015-01-01', 'year', 'elected');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       'Fayette County, Kentucky elected officers. Office inventory from the Lexington-Fayette Urban County Charter, Article 11 (Municode, lexington-fayette_urban, content updated 2026-07-17). Occupancy and arrival dates per officer: the officeholder''s own publisher where one exists, the Fayette County Clerk''s certified November 2022 general results, and a per-seat departure check that found two changes (County Clerk -- Blevins Jr. replaced by Lamb 2023-02-01; Magistrate District 3 -- Biggerstaff left 2023-08-26, replaced by Carr-Seals on a date no publisher states). Day precision is claimed only where a first-party or contemporaneous source gives a day; the Ky. Const. s 99 "first Monday in January" default is treated as COMPUTED and written at year precision. Read 2026-09-26 (KY-4) (CC_0155, KY-4)'
FROM fay_terms t
JOIN essentials.chambers c ON c.name_formal = t.chamber_formal
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type = t.district_type AND d.mtfcc = t.mtfcc AND lower(d.state) = 'ky'
JOIN essentials.offices o ON o.chamber_id = c.id AND o.district_id = d.id AND o.title = t.title
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── 3. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_day int; v_year int; v_unknown int;
  v_appointed int; v_ended int; v_dupes int; v_notinc int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2762784 AND -2762767;
  IF v_people <> 18 THEN RAISE EXCEPTION 'CC_0155: expected 18 people, got %', v_people; END IF;

  -- 🔴 is_incumbent is a CACHED FLAG the incumbents-only reads filter on. A seated person with
  -- is_incumbent = false is hidden from address search and NOTHING ERRORS.
  SELECT count(*) INTO v_notinc FROM essentials.politicians
   WHERE external_id BETWEEN -2762784 AND -2762767 AND is_incumbent IS DISTINCT FROM true;
  IF v_notinc <> 0 THEN RAISE EXCEPTION 'CC_0155: % of the 18 are not flagged is_incumbent - they would be hidden from address search', v_notinc; END IF;

  SELECT count(*), count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown'),
         count(*) FILTER (WHERE ot.how_started = 'appointed'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_terms, v_day, v_year, v_unknown, v_appointed, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN ('Fayette County Fiscal Court', 'Fayette County Elected Officials');

  IF v_terms <> 18 THEN RAISE EXCEPTION 'CC_0155: expected 18 terms, got %', v_terms; END IF;
  IF v_day <> 4 THEN RAISE EXCEPTION 'CC_0155: expected 4 day-precision terms (O''Neill, Evans, Baird, Lamb), got %', v_day; END IF;
  IF v_year <> 13 THEN RAISE EXCEPTION 'CC_0155: expected 13 year-precision terms, got %', v_year; END IF;
  IF v_unknown <> 1 THEN RAISE EXCEPTION 'CC_0155: expected exactly 1 unknown-precision term (Magistrate District 3), got %', v_unknown; END IF;
  IF v_appointed <> 5 THEN RAISE EXCEPTION 'CC_0155: expected 5 appointed arrivals, got %', v_appointed; END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'CC_0155: % term(s) already ended', v_ended; END IF;

  -- The one unknown row must be the magistrate seat and must carry a NULL start, not a zero date.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
     WHERE o.title = 'Magistrate, District 3' AND ot.start_precision = 'unknown' AND ot.term_start IS NULL
  ) THEN
    RAISE EXCEPTION 'CC_0155: the Magistrate District 3 term must be open-ended with a NULL term_start - no source dates Carr-Seals'' arrival, and a computed date must not be substituted';
  END IF;

  -- Count och.politician_id, never rows: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.name_formal IN ('Fayette County Fiscal Court', 'Fayette County Elected Officials');
  IF v_seated <> 18 THEN RAISE EXCEPTION 'CC_0155: expected 18 seated, got %', v_seated; END IF;

  SELECT count(*) INTO v_dupes FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.name_formal IN ('Fayette County Fiscal Court', 'Fayette County Elected Officials')
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dupes <> 0 THEN RAISE EXCEPTION 'CC_0155: % person/people hold more than one Fayette County seat', v_dupes; END IF;

  RAISE NOTICE 'CC_0155 OK: 18 people, 18 terms, 18 seated, % day / % year / % unknown, % appointed',
    v_day, v_year, v_unknown, v_appointed;
END $$;

COMMIT;
