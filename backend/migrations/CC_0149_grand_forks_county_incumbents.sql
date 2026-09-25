-- CC_0149_grand_forks_county_incumbents.sql
-- Knight Foundation program, wave ND-4 (occupancy half). Slot RESERVED from the allocator.
-- Applies immediately after CC_0148, which created the government, chambers and offices.
--
-- Seats all seven elected Grand Forks County officials. Creates 7 people and 7 terms, 0 vacancies.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE JUNE 2026 COUNTY RESULT IS A PRIMARY AND NOTHING FROM IT MAY BE SEATED.
--
-- North Dakota decides CITY offices at the June election and COUNTY offices in NOVEMBER. The Grand
-- Forks County sheet of 2026-06-09 — "County Commission (vote for one)", "County Commission (vote
-- for three)", "State's attorney", "Sheriff" — is a PRIMARY whose general is 2026-11-03, six weeks
-- after this migration. ND-3's June result WAS an election because it was a city race; the
-- identical-looking county sheet on the same day was not.
-- ▶ "A certified result is not a fact about who holds the seat" — and a primary result is not even
--   a result. Every date below predates that primary.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 NORTH DAKOTA GIVES COUNTY OFFICES STATUTORY START DATES, so an election year yields a DAY.
-- Per the Secretary of State's own candidate guidance: a commissioner's four-year term begins on
-- THE FIRST MONDAY IN DECEMBER following the election; a sheriff's and a state's attorney's begin
-- on JANUARY 1 following it. Computed, not guessed: first Monday in December 2022 = 2022-12-05,
-- and in December 2024 = 2024-12-02.
--
-- 🔴 A RE-ELECTION DOES NOT RESTART AN OCCUPANCY, so each date is the person's FIRST arrival.
--
--   Terry Bjerke      Commissioner  2024-12-02  day    elected 2024-11-05 (13,173 votes, 30%),
--                                                      one of the two seats on that ballot
--   Kimberly Hagen    Commissioner  2022-12-05  day    elected 2022-11-08
--   Mark Rustad       Commissioner  2022-12-05  day    elected 2022-11-08 — ⚠ ON A RECOUNT. Election
--                                                      night put him third by 27 votes over Lon
--                                                      Kvasager (6,729 to 6,702) and the initial
--                                                      report named Kvasager the winner; the
--                                                      automatic recount seated Rustad.
--   Anthony Hodny     Commissioner  2026-03-11  day    APPOINTED at a special commission meeting,
--                                                      to the seat left by Cynthia Pic's death on
--                                                      2026-02-13
--   Bob Rost          Commissioner  2019-01-01  YEAR   see below
--   Andrew Schneider  Sheriff       2019-01-01  day    elected 2018-11-06, took office January 2019
--   Haley Wamstad     State's Atty  2019-01-01  day    elected 2018-11-06, took office January 2019;
--                                                      the first woman elected to the office
--
-- ⚠ THREE OF THESE READ 2019-01-01 AND ONLY TWO OF THEM MEAN THE SAME THING. Schneider's and
-- Wamstad's are DAY precision, because the statute fixes 1 January and both took office then. Bob
-- Rost's is YEAR precision and the literal date is an artefact of the convention, not a claim about
-- 1 January. Do not read the three as a shared event.
--
-- 🔴 WHY BOB ROST IS THE ONE YEAR-PRECISION ROW. The county's own Commissioner History List — which,
-- unlike the charter, DOES carry a text layer — ends with the open group "2019-  David Engen ·
-- Cynthia Pic · Diane Knauf · Tom Falck · Bob Rost", and the file was last published in 2020. So the
-- county itself places him on the 2019 board and says nothing finer. He also won re-election on
-- 2022-11-08 (9,277 votes, the highest of that field), which does not restart the occupancy.
-- ⚠ AND HIS ARRIVAL CANNOT SIMPLY BE READ OFF THE 2018 ELECTION, because BOB ROST WAS THE SHERIFF
-- Andrew Schneider succeeded in January 2019. A man cannot have begun a commissioner's term on
-- 2018-12-03 while still holding the sheriff's office through 2018-12-31, so the obvious statutory
-- computation is unsafe for him specifically. The year is what the county publishes; the day is not
-- established, and it is left unclaimed rather than computed.
--
-- 🔴 HODNY'S TERM HAS A KNOWN END AND IT IS DELIBERATELY NOT WRITTEN. He was appointed to serve
-- only until 2026-11-30, when the winner of the 2026-11-03 general takes the unexpired seat. A
-- future term_end self-vacates a seat the moment the calendar passes it, and this program does not
-- write one — OH-2 gates against it explicitly. The end is a recorded DEBT for the wave that
-- processes the November result, not a value for this migration.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 FIVE COMMISSIONER OFFICES SHARE ONE DISTRICT, so (geo_id, title) is not a key. The seats are
-- elected at large and the ballot does not number them, so no fact says which member holds which
-- row. The pairing is made DETERMINISTIC rather than meaningful — offices ranked by their own id,
-- members by full_name, slot N to slot N — which is what makes this migration idempotent. It
-- asserts nothing about the world and nothing downstream may read meaning into it. Same construction
-- as ND-2's paired House seats, for the same reason.
--
-- 🟢 NO NAME COLLIDES. Swept on the duplicate guard's own key (first_name, last_name): 0 of 7.
-- Controlled — the same query reports 7 active rows with last_name 'Schneider', so the zero is a
-- true zero and not an empty detector.
--
-- 🔴 PARTY IS NOT WRITTEN. The charter makes the commission race expressly nonpartisan.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded on a stable key. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The seven people ─────────────────────────────────────────────────────

CREATE TEMP TABLE gfc_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO gfc_people(external_id, full_name, first_name, last_name) VALUES
  (-2762250, 'Terry Bjerke',     'Terry',   'Bjerke'),
  (-2762249, 'Kimberly Hagen',   'Kimberly','Hagen'),
  (-2762248, 'Anthony Hodny',    'Anthony', 'Hodny'),
  (-2762247, 'Bob Rost',         'Bob',     'Rost'),
  (-2762246, 'Mark Rustad',      'Mark',    'Rustad'),
  (-2762245, 'Andrew Schneider', 'Andrew',  'Schneider'),
  (-2762244, 'Haley Wamstad',    'Haley',   'Wamstad');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Grand Forks County, gfcounty.nd.gov Commissioners page and staff directory; office inventory from the county Home Rule Charter art. 6 s 1 "Offices to be Elected" (adopted November 2022 by 18 votes after recount, effective 2023-01-01), OCR''d from the county''s own scanned PDF; arrival dates from the statutory term starts in the ND Secretary of State''s candidate guidance combined with the election year for each officeholder, and for Anthony Hodny from his appointment at a special commission meeting on 2026-03-11 after Cynthia Pic''s death on 2026-02-13; read 2026-09-25 (ND-4) (CC_0149, ND-4)',
       true, true
FROM gfc_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The seven terms ──────────────────────────────────────────────────────

CREATE TEMP TABLE gfc_terms(title text, external_id bigint, sort_key text, term_start date, start_precision text, how_started text)
  ON COMMIT DROP;

INSERT INTO gfc_terms(title, external_id, sort_key, term_start, start_precision, how_started) VALUES
  ('Commissioner',     -2762250, 'Terry Bjerke',     DATE '2024-12-02', 'day',  'elected'),
  ('Commissioner',     -2762249, 'Kimberly Hagen',   DATE '2022-12-05', 'day',  'elected'),
  ('Commissioner',     -2762248, 'Anthony Hodny',    DATE '2026-03-11', 'day',  'appointed'),
  ('Commissioner',     -2762247, 'Bob Rost',         DATE '2019-01-01', 'year', 'elected'),
  ('Commissioner',     -2762246, 'Mark Rustad',      DATE '2022-12-05', 'day',  'elected'),
  ('Sheriff',          -2762245, 'Andrew Schneider', DATE '2019-01-01', 'day',  'elected'),
  ('State''s Attorney',-2762244, 'Haley Wamstad',    DATE '2019-01-01', 'day',  'elected');

WITH office_slots AS (
  SELECT o.id AS office_id, o.title,
         row_number() OVER (PARTITION BY o.title ORDER BY o.id) AS slot
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'Grand Forks County, North Dakota, US'
),
member_slots AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.title ORDER BY t.sort_key) AS slot
  FROM gfc_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, ms.term_start, NULL, ms.start_precision, ms.how_started,
       'Statutory term starts per the ND Secretary of State (commissioner: first Monday in December following the election; sheriff and state''s attorney: January 1 following it), with each officeholder''s election year from contemporaneous reporting; Bob Rost at YEAR precision from the county''s own Commissioner History List ("2019- ... Bob Rost"); Anthony Hodny appointed 2026-03-11; read 2026-09-25 (ND-4) (CC_0149, ND-4)'
FROM member_slots ms
JOIN office_slots os ON os.title = ms.title AND os.slot = ms.slot
JOIN essentials.politicians p ON p.external_id = ms.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people  int;
  v_offices int;
  v_terms   int;
  v_seated  int;
  v_day     int;
  v_year    int;
  v_ended   int;
  v_appt    int;
  v_distinct int;
  v_dup     int;
  v_probe   int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2762250 AND -2762244;
  IF v_people <> 7 THEN
    RAISE EXCEPTION 'ND-4 occupancy: expected 7 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Grand Forks County, North Dakota, US';
  IF v_offices <> 7 THEN
    RAISE EXCEPTION 'ND-4 occupancy: expected 7 offices from CC_0148, got %', v_offices;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Grand Forks County, North Dakota, US';
  IF v_terms <> 7 THEN
    RAISE EXCEPTION 'ND-4 occupancy: expected 7 terms, got %', v_terms;
  END IF;

  -- 🔴 Count och.politician_id, never rows: office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Grand Forks County, North Dakota, US';
  IF v_seated <> 7 THEN
    RAISE EXCEPTION 'ND-4 occupancy: expected 7 seated county offices, got %', v_seated;
  END IF;

  SELECT count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL),
         count(*) FILTER (WHERE ot.how_started = 'appointed')
    INTO v_day, v_year, v_ended, v_appt
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Grand Forks County, North Dakota, US';
  IF v_day <> 6 THEN
    RAISE EXCEPTION 'ND-4 occupancy: expected 6 day-precision terms, got %', v_day;
  END IF;
  IF v_year <> 1 THEN
    RAISE EXCEPTION 'ND-4 occupancy: expected exactly 1 year-precision term (Bob Rost, whose day the county does not publish), got %', v_year;
  END IF;
  IF (v_day + v_year) <> 7 THEN
    RAISE EXCEPTION 'ND-4 occupancy: % county term(s) are neither day nor year precision — nothing here may be unknown', 7 - v_day - v_year;
  END IF;
  -- 🔴 Hodny's seat ends 2026-11-30 and that END IS DELIBERATELY UNWRITTEN: a future term_end
  -- self-vacates a seat. If one appears here, someone has written the debt as data.
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'ND-4 occupancy: % county term(s) carry a term_end — Hodny''s 2026-11-30 end is a recorded debt, not a value', v_ended;
  END IF;
  IF v_appt <> 1 THEN
    RAISE EXCEPTION 'ND-4 occupancy: expected exactly 1 appointed arrival (Hodny, to Cynthia Pic''s seat), got %', v_appt;
  END IF;

  -- 🔴 The five commissioner seats must resolve to FIVE DIFFERENT people. Five terms naming fewer
  -- people would satisfy every count above.
  SELECT count(DISTINCT och.politician_id) INTO v_distinct
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Grand Forks County, North Dakota, US' AND o.title = 'Commissioner';
  IF v_distinct <> 5 THEN
    RAISE EXCEPTION 'ND-4 occupancy: the 5 at-large commissioner seats resolve to % distinct holders', v_distinct;
  END IF;

  SELECT count(*) INTO v_dup
  FROM (SELECT och.politician_id
          FROM essentials.office_current_holder och
          JOIN essentials.offices o ON o.id = och.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.name = 'Grand Forks County, North Dakota, US' AND och.politician_id IS NOT NULL
         GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'ND-4 occupancy: % person/people hold more than one county office', v_dup;
  END IF;

  -- 🟢 END TO END, AND IT IS THE PROGRAM'S OWN ACCEPTANCE TEST. Grand Forks City Hall
  -- (47.926125, -97.034585) must now reach a county commissioner, which is the answer the slice
  -- has been missing since ND-1.
  SELECT count(och.politician_id) INTO v_probe
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc AND d.district_type::text = 'COUNTY'
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE gb.state = '38' AND gb.mtfcc = 'G4020' AND gb.geo_id = '38035'
     AND o.title = 'Commissioner'
     AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-97.034585, 47.926125), 4326));
  IF v_probe <> 5 THEN
    RAISE EXCEPTION 'ND-4 occupancy: Grand Forks City Hall reaches % county commissioners, expected 5 (they are elected at large)', v_probe;
  END IF;

  RAISE NOTICE 'ND-4 occupancy gate PASSED: 7 people, 7 offices, 7 terms, 7 seated, 6 day + 1 year, 0 unknown, 0 ended, 1 appointed, 5 distinct commissioners, and City Hall reaches all 5.';
END $$;

COMMIT;
