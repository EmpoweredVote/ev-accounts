-- CC_0115_co_boulder_officials.sql
-- Knight Foundation program, wave CO-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0114, which creates the governments, chambers, district and offices.
--
-- Seats all nineteen Boulder officials: 9 city (Mayor + 8 at-large council) and 10 county
-- (3 commissioners + 7 county officers). Creates 19 people; NONE of these names exists in
-- production today, verified before writing.
--
-- 🔴 TERM STARTS ARE THE START OF CONTINUOUS OCCUPANCY, NOT THE START OF THE CURRENT TERM.
-- Re-election does not end an occupancy, so a person re-elected in 2025 who has served since 2021
-- gets a 2021 row. That is the San José ruling (CC_0059): continuous service is one term row.
-- Four of Boulder's nine have served continuously since 2021 and were re-elected in 2025.
--
-- 🔴 THE CITY'S OWN COUNCIL PAGE LISTS EIGHT OF THE NINE. Mark Wallach is absent from
-- bouldercolorado.gov/government/city-council, and he is not a departure: he drew the second
-- highest total in 2025 (17,476) and appears in the city's own 12.07.23 minutes roll. A roster page
-- is the thing under test, not the authority. Reconciled against the county's tabulation and the
-- city's minutes.
--
-- 🔴 THE COUNTY'S RESULTS LISTING IS NOT ORDERED BY VOTES. Wallach is the NINTH row of the 2025
-- council contest and the highest total in it; Speer is the first row and third by votes. Reading
-- listing order would have seated Montserrat Palacios (2,957) and Rob Smoke (1,499) over Benjamin
-- and Wallach. Every winner below was taken by sorting on the vote column.
--
-- 🔴 A FILE NAMED `2025-Boulder-County-Coordinated-Canvass.pdf` IS A SLIDE DECK ABOUT THE
-- RISK-LIMITING AUDIT -- right county, right election, no votes in it. The votes are in the results
-- archive, Home/IndexCategory/49.html (2025) and /39.html (2023).
--
-- COLORADO COUNTY TERMS COMMENCE ON THE SECOND TUESDAY OF JANUARY after the election (C.R.S. tit.
-- 1). The county's own coroner release corroborates it by naming 2025-01-14 -- the second Tuesday
-- of January 2025 -- as the day the appointed coroner's tenure gave way to his elected one. So:
-- Jan 2015 = the 13th, Jan 2019 = the 8th, Jan 2021 = the 12th, Jan 2023 = the 10th.
--
-- ⚠ ONE ROW IS DELIBERATELY UNDATED. Lee Stadele's first seating as Surveyor is not sourced, so his
-- term is written OPEN-ENDED with start_precision 'unknown' rather than guessed from his most recent
-- election. An undated row is honest; a plausible wrong date is not, and 2022 would assert a first
-- seating that may be years late.
--
-- ⚠ AND ONE PERSON HOLDS A SEAT THAT DID NOT EXIST BEFORE 2023. Aaron Brockett sat on this council
-- earlier and was mayor before 2023 -- but that was the council-selected mayoralty. The DIRECTLY
-- ELECTED Mayor office begins with the 2023 election, so his occupancy of THIS office starts at the
-- 2023 swearing-in, not at his first council service.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. Nineteen people ──────────────────────────────────────────────────────
-- Reserved external_id band -813001..-813019, keyed off the county FIPS 08013. Verified unused.

CREATE TEMP TABLE co3_people(external_id bigint, full_name text, first_name text, last_name text,
                             source text, alternate_names text[]) ON COMMIT DROP;
INSERT INTO co3_people VALUES
  (-813001, 'Aaron Brockett',       'Aaron',    'Brockett',    'City of Boulder council minutes 2023-12-07; Boulder County 2023 Coordinated results', ARRAY[]::text[]),
  (-813002, 'Matt Benjamin',        'Matt',     'Benjamin',    'Boulder County 2021 and 2025 Coordinated results; City of Boulder council minutes 2023-12-07', ARRAY[]::text[]),
  (-813003, 'Nicole Speer',         'Nicole',   'Speer',       'Boulder County 2021 and 2025 Coordinated results', ARRAY[]::text[]),
  (-813004, 'Mark Wallach',         'Mark',     'Wallach',     'Boulder County 2021 and 2025 Coordinated results; City of Boulder council minutes 2023-12-07', ARRAY[]::text[]),
  (-813005, 'Tara Winer',           'Tara',     'Winer',       'Boulder County 2021 (two-year seat) and 2023 Coordinated results', ARRAY[]::text[]),
  (-813006, 'Taishya Adams',        'Taishya',  'Adams',       'Boulder County 2023 Coordinated results; City of Boulder council minutes 2023-12-07', ARRAY[]::text[]),
  (-813007, 'Tina Marquis',         'Tina',     'Marquis',     'Boulder County 2023 Coordinated results; City of Boulder council minutes 2023-12-07', ARRAY[]::text[]),
  (-813008, 'Ryan Schuchard',       'Ryan',     'Schuchard',   'Boulder County 2023 Coordinated results; City of Boulder council minutes 2023-12-07', ARRAY[]::text[]),
  (-813009, 'Rob Kaplan',           'Rob',      'Kaplan',      'Boulder County 2025 Coordinated results', ARRAY['Robert Kaplan']),
  (-813010, 'Claire Levy',          'Claire',   'Levy',        'Boulder County 2024 General results; Boulder County Elected Officials page', ARRAY[]::text[]),
  (-813011, 'Marta Loachamin',      'Marta',    'Loachamin',   'Boulder County 2024 General results; Boulder County Elected Officials page', ARRAY[]::text[]),
  (-813012, 'Ashley Stolzmann',     'Ashley',   'Stolzmann',   'Boulder County 2022 General results; Boulder County Elected Officials page', ARRAY[]::text[]),
  (-813013, 'Cynthia Braddock',     'Cynthia',  'Braddock',    'Boulder County 2022 General results; Boulder County Elected Officials page', ARRAY[]::text[]),
  (-813014, 'Molly Fitzpatrick',    'Molly',    'Fitzpatrick', 'Boulder County 2022 General results; Boulder County Elected Officials page', ARRAY[]::text[]),
  (-813015, 'Jeff Martin',          'Jeff',     'Martin',      'Boulder County 2024 General results; Boulder County news release, commissioners appoint Jeff Martin as Coroner', ARRAY[]::text[]),
  (-813016, 'Michael T. Dougherty', 'Michael',  'Dougherty',   'Boulder County 2024 General results (District Attorney, 20th Judicial District)', ARRAY['Michael Dougherty']),
  (-813017, 'Curtis Johnson',       'Curtis',   'Johnson',     'Boulder County 2022 General results; Boulder County Elected Officials page', ARRAY[]::text[]),
  (-813018, 'Lee Stadele',          'Lee',      'Stadele',     'Boulder County 2022 General results; Boulder County Elected Officials page', ARRAY[]::text[]),
  (-813019, 'Paul Weissmann',       'Paul',     'Weissmann',   'Boulder County 2022 General results; Boulder County Elected Officials page', ARRAY[]::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.source, n.alternate_names
FROM co3_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Nineteen dated terms, one per office ─────────────────────────────────
-- `seat_ordinal` matches the internal ordinal CC_0114 wrote into offices.description for the eight
-- at-large seats. It is a join key and NOT a ballot designation: Boulder elects four at a time in
-- one citywide race. Ordinals here run oldest service first, then alphabetically within a cohort.

CREATE TEMP TABLE co3_terms(gov_geo_id text, title text, seat_ordinal int, external_id bigint,
                            term_start date, start_precision text, how_started text, note text)
  ON COMMIT DROP;
INSERT INTO co3_terms VALUES
  -- City. Sworn in at the first council business meeting after each election.
  ('0807850', 'Mayor',          NULL, -813001, '2023-12-07'::date, 'day', 'elected', 'First directly elected mayor; ranked-choice, 2023'),
  ('0807850', 'Council Member', 1,    -813002, '2021-11-16'::date, 'day', 'elected', 'Continuous since 2021; re-elected 2025 with the highest total but one'),
  ('0807850', 'Council Member', 2,    -813003, '2021-11-16'::date, 'day', 'elected', 'Continuous since 2021; re-elected 2025'),
  ('0807850', 'Council Member', 3,    -813004, '2021-11-16'::date, 'day', 'elected', 'Continuous since 2021; re-elected 2025. ABSENT from the city roster page'),
  ('0807850', 'Council Member', 4,    -813005, '2021-11-16'::date, 'day', 'elected', 'Continuous since 2021: won the FIFTH seat in 2021, a two-year term, then a full term in 2023'),
  ('0807850', 'Council Member', 5,    -813006, '2023-12-07'::date, 'day', 'elected', 'Three-year transition term, 2023-2026'),
  ('0807850', 'Council Member', 6,    -813007, '2023-12-07'::date, 'day', 'elected', 'Three-year transition term, 2023-2026'),
  ('0807850', 'Council Member', 7,    -813008, '2023-12-07'::date, 'day', 'elected', 'Three-year transition term, 2023-2026'),
  ('0807850', 'Council Member', 8,    -813009, '2025-12-04'::date, 'day', 'elected', 'Unseated an incumbent in 2025'),
  -- County. Second Tuesday of January after the first election of continuous service.
  ('08013', 'Commissioner, District 1', NULL, -813010, '2021-01-12'::date, 'day',     'elected',   'First elected 2020; re-elected 2024'),
  ('08013', 'Commissioner, District 2', NULL, -813011, '2021-01-12'::date, 'day',     'elected',   'First elected 2020; re-elected 2024'),
  ('08013', 'Commissioner, District 3', NULL, -813012, '2023-01-10'::date, 'day',     'elected',   'First elected 2022'),
  ('08013', 'Assessor',                 NULL, -813013, '2017-01-01'::date, 'year',    'appointed', 'Appointed in January 2017 to fill a vacancy, then elected 2018 and 2022. The exact appointment day is not sourced, so the precision is year'),
  ('08013', 'Clerk and Recorder',       NULL, -813014, '2019-01-08'::date, 'day',     'elected',   'First elected 2018; re-elected 2022'),
  ('08013', 'Coroner',                  NULL, -813015, '2024-02-01'::date, 'month',   'appointed', 'Appointed February 2024 after the elected coroner resigned, then elected in November 2024 -- so occupancy runs from the APPOINTMENT. The county release is dated 2024-02-16 and the exact vote day is not sourced, so the precision is month'),
  ('08013', 'District Attorney',        NULL, -813016, '2019-01-08'::date, 'day',     'elected',   'First elected 2018; re-elected 2024'),
  ('08013', 'Sheriff',                  NULL, -813017, '2023-01-10'::date, 'day',     'elected',   'First elected 2022'),
  ('08013', 'Surveyor',                 NULL, -813018, NULL,               'unknown', 'elected',   'Re-elected 2022, but the FIRST seating is not sourced. Deliberately undated rather than guessed'),
  ('08013', 'Treasurer',                NULL, -813019, '2015-01-13'::date, 'day',     'elected',   'First elected November 2014; re-elected 2018 and 2022');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end,
                                     start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       n.source || ' (CC_0115, CO-3)'
FROM co3_terms t
JOIN essentials.governments g ON g.geo_id = t.gov_geo_id
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = t.title
  AND (t.seat_ordinal IS NULL OR o.description LIKE 'Internal ordinal ' || t.seat_ordinal || ' of 8.%')
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN co3_people n ON n.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_off int; v_seated int; v_terms int; v_ended int;
  v_undated int; v_undated_title text; v_2021 int; v_mayor text; v_nv int; v_dupe int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN -813019 AND -813001;
  IF v_people <> 19 THEN RAISE EXCEPTION 'CO-3 occupancy: expected 19 people in the reserved band, got %', v_people; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('0807850','08013');
  IF v_off <> 19 THEN RAISE EXCEPTION 'CO-3 occupancy: expected 19 Boulder offices, got %', v_off; END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*): office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician rather than an absent row and count(*) passes vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.geo_id IN ('0807850','08013');
  IF v_seated <> 19 THEN RAISE EXCEPTION 'CO-3 occupancy: expected 19 seated offices, got %', v_seated; END IF;

  SELECT count(*), count(*) FILTER (WHERE ot.term_end IS NOT NULL) INTO v_terms, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('0807850','08013');
  IF v_terms <> 19 THEN RAISE EXCEPTION 'CO-3 occupancy: expected 19 terms, got %', v_terms; END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'CO-3 occupancy: % term(s) already ended', v_ended; END IF;

  -- EXACTLY ONE undated row, and it must be the Surveyor. If a second appears, someone has stopped
  -- sourcing dates; if this one gains a date, it must come with a source.
  SELECT count(*) INTO v_undated
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('0807850','08013') AND ot.term_start IS NULL;
  IF v_undated <> 1 THEN
    RAISE EXCEPTION 'CO-3 occupancy: expected exactly 1 undated term (the Surveyor), got %', v_undated;
  END IF;
  SELECT o.title INTO v_undated_title
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('0807850','08013') AND ot.term_start IS NULL;
  IF v_undated_title <> 'Surveyor' THEN
    RAISE EXCEPTION 'CO-3 occupancy: the undated term is "%", expected the Surveyor', v_undated_title;
  END IF;

  -- The four councillors with continuous service since 2021 must carry the 2021 swearing-in, not a
  -- 2025 re-election date. This is the assertion that fails if someone "corrects" them to 2025.
  SELECT count(*) INTO v_2021
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '0807850' AND ot.term_start = DATE '2021-11-16';
  IF v_2021 <> 4 THEN
    RAISE EXCEPTION 'CO-3 occupancy: expected 4 council terms starting 2021-11-16 (continuous service), got %', v_2021;
  END IF;

  -- The Mayor must be the person the city's own minutes swore in.
  SELECT p.full_name INTO v_mayor
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.geo_id = '0807850' AND o.title = 'Mayor';
  IF v_mayor IS DISTINCT FROM 'Aaron Brockett' THEN
    RAISE EXCEPTION 'CO-3 occupancy: the Mayor of Boulder is "%", expected Aaron Brockett', v_mayor;
  END IF;

  -- 🔴 No Colorado person may have landed in Nevada.
  SELECT count(och.politician_id) INTO v_nv
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'City of Boulder City, Nevada, US' AND p.external_id BETWEEN -813019 AND -813001;
  IF v_nv <> 0 THEN
    RAISE EXCEPTION 'CO-3 occupancy: % Boulder COLORADO official(s) are seated in Boulder City, NEVADA', v_nv;
  END IF;

  -- One person per office and one office per person, inside this wave.
  SELECT count(*) INTO v_dupe FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
    JOIN essentials.politicians p ON p.id = ot.politician_id
    WHERE p.external_id BETWEEN -813019 AND -813001
    GROUP BY ot.politician_id HAVING count(*) <> 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'CO-3 occupancy: % of this wave''s people hold other than exactly one term', v_dupe;
  END IF;

  RAISE NOTICE 'CO-3 occupancy OK: % people, % offices, % seated, % terms, 1 undated (Surveyor), 4 continuous since 2021, mayor %',
    v_people, v_off, v_seated, v_terms, v_mayor;
END $$;

COMMIT;
