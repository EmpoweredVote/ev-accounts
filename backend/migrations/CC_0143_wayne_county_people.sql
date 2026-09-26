-- CC_0143_wayne_county_people.sql
-- Knight Foundation program, wave MI-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0142, which creates the government, chambers, districts and the
-- 21 offices this migration seats.
--
-- Creates 21 people and 21 open-ended terms. No row is reused: the name sweep below found ZERO
-- collisions, which is unusual for this programme and was therefore controlled before it was
-- believed.
--
-- 🔴 THE ROSTER WAS CHANGE-CHECKED AGAINST THREE CURRENT AUTHORITIES, AND THE COUNTY'S OWN
-- HISTORICAL RECORD DISAGREED WITH ALL THREE ON TWO SEATS.
--   (a) each commissioner's own page on waynecountymi.gov — all 15 name their own member;
--   (b) the district -> commissioner redirect map, maintained separately from those pages;
--   (c) the ROLL CALL of the full Commission meeting of 2026-09-15, which lists all fifteen.
-- Against those, the county's "Commissioners by District" record — the term-by-term document
-- that the "first elected is not a term start" rule asks for — still shows Irma Clark-Coleman in
-- District 5 and David M. Knezek Jr. in District 8. It is not wrong; it is stamped 2025-01-02 and
-- says so only in its filename. Both seats have since turned over, and NEITHER TURNOVER IS
-- MENTIONED ON THE PAGE OF THE PERSON WHO ARRIVED. Only the Commission's own journal carries them:
--
--   D5  Commissioner Irma Clark-Coleman DIED IN OFFICE on 2025-06-10. Angelique Peterson-Mayberry
--       was appointed to the vacancy at the meeting of TUESDAY 2025-07-02, 14-0, Journal of the
--       Commission No. 13, item X.A.1 "Filling of the District 5 Vacancy", Resolution 2025-455.
--       ⚠ A newspaper account of this appointment says "Thursday" and is dated 2025-07-03. The
--       journal is the record, and it moves the date by a day.
--   D8  David M. Knezek Jr. left to become president of Henry Ford College. Hassan M. Ahmad was
--       appointed at the meeting of 2026-08-06, 11-0 with one abstention, Journal No. 16, item
--       X.A.4 "Filling of the District 8 vacancy", Resolution 2026-572. Seven weeks before this
--       migration. The roll call of that meeting lists fourteen members, because Ahmad was not one
--       yet.
--   D14 Raymond E. Basham resigned the 14th District seat effective 2023-12-31 (letter dated
--       2023-12-14). Alex Garza was appointed 2024-01-04, 9-0 with four abstentions, Resolution
--       2024-007; that meeting's roll call prints "District 14 - vacant".
-- ▶ A CHANGE-CHECK ASKS "HAS THIS PERSON LEFT?", AND FOR AN APPOINTED ARRIVAL THE ONLY DOCUMENT
--   THAT ANSWERS IS THE BODY'S OWN JOURNAL. A roster says who is there now; it cannot say since
--   when, and the member's own biography did not mention its own beginning in any of these three.
--
-- 🔴 FIFTEEN OF TWENTY-ONE TERMS ARE DATED, AND THE SIX THAT ARE NOT ARE THE COUNTYWIDE OFFICES.
-- The Commission publishes its membership term by term since 1983, so each commissioner's
-- continuous occupancy OF THAT SEAT can be read off it rather than guessed:
--   * eleven entered at a term boundary — year precision, 1 January of that year, how_started
--     'elected'. This is the CLAUDE.md rule for a source that gives only a year.
--   * Glenn S. Anderson arrived mid-term: his page says "sworn in ... in January 2016", and the
--     record shows the 2015-16 seat as "Richard LeBlanc/Glenn S. Anderson". Month precision.
--   * the three appointees above are day precision, from their resolutions.
-- ⚠ TWO SEATS ARE DATED FROM 2013 FOR A REASON THAT IS EASY TO GET WRONG. Alisha R. Bell has
--   served continuously since 2003 and Joseph Palamara since 1999, but both moved district number
--   at the 2013 term — Bell from 8 to 7, Palamara from 14 to 15. `office_terms` records occupancy
--   of a SEAT, so the D7 and D15 terms begin in 2013. Their longer service is a fact about the
--   person, not about this office.
-- ⚠ Martha G. Scott's own biography says she is "currently serving her sixth term". The record
--   shows her in District 3 continuously from 2011-12, which is her eighth. The bio is stale; the
--   record is used. A term COUNT in a biography is not a date and is not evidence.
-- The six countywide officers get `unknown`, open-ended. Not one of their pages states when they
-- took office, and the programme does not invent a date to fill a column. Recorded as a debt.
--
-- 🔴 THE NAME SWEEP RETURNED ZERO, AND ZERO IS THE ANSWER A BROKEN DETECTOR GIVES. Swept on the
-- duplicate guard's own key — lower(first_name), lower(last_name), active rows only — for all 21
-- names: no collisions. That is unlike MI-2 (6 hits) and MI-3 (1), so the sweep was re-run with
-- Mary Sheffield, Joseph Tate and Mary Waters planted in the same query shape; all three were
-- found. The detector works and the answer is genuinely zero. ⚠ There are 68 active Smiths, 12
-- Evanses, 10 Garretts and 5 McCormicks in production — plenty of surnames, none of these people.
--
-- 🔴 MI-2's DEFECT CANNOT ARISE HERE BUT IS ASSERTED ANYWAY. No row is reused, so nothing
-- inherits is_incumbent = false from a candidate record. Gate 7 still runs the reps-feed
-- predicate over all 21, because "it cannot happen" is not a measurement.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- ─── 0. Refuse to run before the structure exists ─────────────────────────────
DO $pre$
DECLARE v_off integer;
BEGIN
  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US';
  IF v_off <> 21 THEN
    RAISE EXCEPTION 'MI-4 pre-flight: expected 21 Wayne County offices from CC_0142, found % — apply CC_0142 first', v_off;
  END IF;
END
$pre$;

-- ─── 1. The 21 people ─────────────────────────────────────────────────────────
CREATE TEMP TABLE wayne_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO wayne_people(external_id, full_name, first_name, last_name) VALUES
  (-2790001, 'Warren C. Evans',             'Warren',    'Evans'),
  (-2790002, 'Raphael Washington',          'Raphael',   'Washington'),
  (-2790003, 'Kym L. Worthy',               'Kym',       'Worthy'),
  (-2790004, 'Cathy M. Garrett',            'Cathy',     'Garrett'),
  (-2790005, 'Eric R. Sabree',              'Eric',      'Sabree'),
  (-2790006, 'Bernard J. Youngblood',       'Bernard',   'Youngblood'),
  (-2790007, 'Tim Killeen',                 'Tim',       'Killeen'),
  (-2790008, 'Jonathan C. Kinloch',         'Jonathan',  'Kinloch'),
  (-2790009, 'Martha G. Scott',             'Martha',    'Scott'),
  (-2790010, 'Cara A. Clemente',            'Cara',      'Clemente'),
  (-2790011, 'Angelique Peterson-Mayberry', 'Angelique', 'Peterson-Mayberry'),
  (-2790012, 'Monique Baker McCormick',     'Monique',   'Baker McCormick'),
  (-2790013, 'Alisha R. Bell',              'Alisha',    'Bell'),
  (-2790014, 'Hassan M. Ahmad',             'Hassan',    'Ahmad'),
  (-2790015, 'Terry Marecki',               'Terry',     'Marecki'),
  (-2790016, 'Melissa Daub',                'Melissa',   'Daub'),
  (-2790017, 'Allen R. Wilson',             'Allen',     'Wilson'),
  (-2790018, 'Glenn S. Anderson',           'Glenn',     'Anderson'),
  (-2790019, 'Sam Baydoun',                 'Sam',       'Baydoun'),
  (-2790020, 'Alex Garza',                  'Alex',      'Garza'),
  (-2790021, 'Joseph Palamara',             'Joseph',    'Palamara');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       $$Wayne County official pages, waynecountymi.gov — /Government/Elected-Officials and each officer's own page, /Government/Elected-Officials/Commission/Districts and each commissioner's own page (the Sheriff's office publishes at sheriffconnect.com, to which the county links); office inventory from the Home Rule Charter for the County of Wayne, Secs. 9.111(a), 3.111 and 2.211; roster change-checked against all 15 individual commissioner pages, the county's district-to-commissioner redirect map, and the roll call of the full Commission meeting of 2026-09-15; read 2026-09-25 (MI-4) (CC_0143, MI-4)$$,
       true, true
FROM wayne_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 21 terms ──────────────────────────────────────────────────────────
CREATE TEMP TABLE wayne_terms(title text, external_id bigint, term_start date,
                              start_precision text, how_started text, src text) ON COMMIT DROP;

INSERT INTO wayne_terms(title, external_id, term_start, start_precision, how_started, src) VALUES
  -- Countywide. No county page states a start date for any of these six.
  ('County Executive',     -2790001, NULL, 'unknown', 'unknown', 'page'),
  ('Sheriff',              -2790002, NULL, 'unknown', 'unknown', 'page'),
  ('Prosecuting Attorney', -2790003, NULL, 'unknown', 'unknown', 'page'),
  ('County Clerk',         -2790004, NULL, 'unknown', 'unknown', 'page'),
  ('Treasurer',            -2790005, NULL, 'unknown', 'unknown', 'page'),
  ('Register of Deeds',    -2790006, NULL, 'unknown', 'unknown', 'page'),
  -- Commissioners, from the Commission's own term-by-term record.
  ('Commissioner, District 1',  -2790007, DATE '2007-01-01', 'year',  'elected',   'record'),
  ('Commissioner, District 2',  -2790008, DATE '2021-01-01', 'year',  'elected',   'record'),
  ('Commissioner, District 3',  -2790009, DATE '2011-01-01', 'year',  'elected',   'record'),
  ('Commissioner, District 4',  -2790010, DATE '2023-01-01', 'year',  'elected',   'record'),
  ('Commissioner, District 5',  -2790011, DATE '2025-07-02', 'day',   'appointed', 'journal455'),
  ('Commissioner, District 6',  -2790012, DATE '2019-01-01', 'year',  'elected',   'record'),
  ('Commissioner, District 7',  -2790013, DATE '2013-01-01', 'year',  'elected',   'seatmove'),
  ('Commissioner, District 8',  -2790014, DATE '2026-08-06', 'day',   'appointed', 'journal572'),
  ('Commissioner, District 9',  -2790015, DATE '2015-01-01', 'year',  'elected',   'record'),
  ('Commissioner, District 10', -2790016, DATE '2019-01-01', 'year',  'elected',   'record'),
  ('Commissioner, District 11', -2790017, DATE '2025-01-01', 'year',  'elected',   'record'),
  ('Commissioner, District 12', -2790018, DATE '2016-01-01', 'month', 'appointed', 'anderson'),
  ('Commissioner, District 13', -2790019, DATE '2019-01-01', 'year',  'elected',   'record'),
  ('Commissioner, District 14', -2790020, DATE '2024-01-04', 'day',   'appointed', 'journal007'),
  ('Commissioner, District 15', -2790021, DATE '2013-01-01', 'year',  'elected',   'seatmove');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end,
                                     start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       CASE t.src
         WHEN 'journal455' THEN $$Journal of the Commission, Charter County of Wayne, No. 13, Tuesday 2025-07-02, item X.A.1 "Filling of the District 5 Vacancy", Resolution No. 2025-455, adopted 14-0; the vacancy arose on the death of Commissioner Irma Clark-Coleman, 2025-06-10 (CC_0143, MI-4)$$
         WHEN 'journal572' THEN $$Journal of the Commission, Charter County of Wayne, No. 16, Thursday 2026-08-06, item X.A.4 "Filling of the District 8 vacancy", Resolution No. 2026-572, adopted 11-0 with 1 abstention; the vacancy arose when David M. Knezek Jr. left to become president of Henry Ford College (CC_0143, MI-4)$$
         WHEN 'journal007' THEN $$Journal of the Commission, Charter County of Wayne, 2024-01-04, "Filling of the vacancy for District 14", Resolution No. 2024-007, adopted 9-0 with 4 abstentions; Raymond E. Basham resigned the seat effective 2023-12-31 by letter dated 2023-12-14, and that meeting's roll call records District 14 as vacant (CC_0143, MI-4)$$
         WHEN 'anderson'   THEN $$Wayne County Commission, Commissioner Glenn S. Anderson's own page: "sworn in as a member of the Wayne County Commission in January 2016 and was elected for his first full term in November of 2016"; the county's "Commissioners by District" record shows the 2015-16 District 12 seat as "Richard LeBlanc/Glenn S. Anderson". Month precision — the day is not published (CC_0143, MI-4)$$
         WHEN 'seatmove'   THEN $$Wayne County Commission, "Commissioners by District" (the Commission's own term-by-term record since 1983, edition of 2025-01-02): continuous occupancy of THIS seat from the 2013-14 term. The member has served the Commission longer, from a differently numbered district — Bell in District 8 to 2011, Palamara in District 14 to 2011 — and office_terms records occupancy of a seat, not a career (CC_0143, MI-4)$$
         WHEN 'record'     THEN $$Wayne County Commission, "Commissioners by District" (the Commission's own term-by-term record since 1983, edition of 2025-01-02): continuous occupancy of this seat from the stated two-year term block onward. Year precision — the record gives a term, not a day (CC_0143, MI-4)$$
         ELSE                   $$Wayne County official pages, waynecountymi.gov, read 2026-09-25; no county page states a start date for any of the six countywide offices, so occupancy is open-ended at unknown precision rather than guessed (CC_0143, MI-4)$$
       END
FROM wayne_terms t
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN essentials.governments g ON g.name = 'Wayne County, Michigan, US'
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = t.title
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── post-verify gate ─────────────────────────────────────────────────────────
DO $gate$
DECLARE
  v_terms integer; v_people integer; v_seated integer;
  v_dated integer; v_ended integer; v_two integer; v_hidden integer;
  v_day integer; v_month integer; v_year integer; v_unknown integer;
  v_appointed integer; v_distinct integer;
BEGIN
  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US';
  IF v_terms <> 21 THEN RAISE EXCEPTION 'MI-4 gate 1: expected 21 terms, found %', v_terms; END IF;

  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2790021 AND -2790001;
  IF v_people <> 21 THEN RAISE EXCEPTION 'MI-4 gate 2: expected 21 new people in the MI-4 band, found %', v_people; END IF;

  -- 🔴 Count och.politician_id, not och.*: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL holder and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Wayne County, Michigan, US';
  IF v_seated <> 21 THEN RAISE EXCEPTION 'MI-4 gate 3: expected 21 seated offices, found %', v_seated; END IF;

  SELECT count(*) FILTER (WHERE t.term_start IS NOT NULL),
         count(*) FILTER (WHERE t.term_end IS NOT NULL),
         count(*) FILTER (WHERE t.start_precision = 'day'),
         count(*) FILTER (WHERE t.start_precision = 'month'),
         count(*) FILTER (WHERE t.start_precision = 'year'),
         count(*) FILTER (WHERE t.start_precision = 'unknown'),
         count(*) FILTER (WHERE t.how_started = 'appointed')
    INTO v_dated, v_ended, v_day, v_month, v_year, v_unknown, v_appointed
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US';

  IF v_dated <> 15 THEN RAISE EXCEPTION 'MI-4 gate 4: expected 15 dated terms (the commissioners), found %', v_dated; END IF;
  IF v_ended <> 0  THEN RAISE EXCEPTION 'MI-4 gate 5: % term(s) carry a term_end — a future end silently self-vacates the seat', v_ended; END IF;
  IF (v_day, v_month, v_year, v_unknown) IS DISTINCT FROM (3, 1, 11, 6) THEN
    RAISE EXCEPTION 'MI-4 gate 6: precision mix is (day %, month %, year %, unknown %), expected (3, 1, 11, 6)', v_day, v_month, v_year, v_unknown;
  END IF;

  -- 🔴 The four mid-term arrivals are the only claims in this migration that rest on a single
  -- document each. Assert they survived rather than trusting the INSERT.
  IF v_appointed <> 4 THEN RAISE EXCEPTION 'MI-4 gate 7: expected 4 appointed arrivals (D5, D8, D12, D14), found %', v_appointed; END IF;

  PERFORM 1 FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US'
     AND o.title = 'Commissioner, District 5' AND t.term_start = DATE '2025-07-02';
  IF NOT FOUND THEN RAISE EXCEPTION 'MI-4 gate 8: District 5 is not dated 2025-07-02 (Resolution 2025-455)'; END IF;
  PERFORM 1 FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US'
     AND o.title = 'Commissioner, District 8' AND t.term_start = DATE '2026-08-06';
  IF NOT FOUND THEN RAISE EXCEPTION 'MI-4 gate 9: District 8 is not dated 2026-08-06 (Resolution 2026-572)'; END IF;

  -- The exclusion constraint forbids two people on one office; it cannot see one person on two.
  SELECT count(*) INTO v_two FROM (
    SELECT t.politician_id FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Wayne County, Michigan, US'
     GROUP BY t.politician_id HAVING count(*) > 1) x;
  IF v_two <> 0 THEN RAISE EXCEPTION 'MI-4 gate 10: % person(s) hold two Wayne County offices', v_two; END IF;

  -- Fifteen commissioners on fifteen different districts.
  SELECT count(DISTINCT o.district_id) INTO v_distinct
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US' AND c.name = 'Wayne County Commission';
  IF v_distinct <> 15 THEN RAISE EXCEPTION 'MI-4 gate 11: the 15 seated commissioners sit on % distinct districts', v_distinct; END IF;

  -- 🔴 MI-2's defect, asserted rather than assumed absent: every seated Wayne official must
  -- survive the reps-feed predicate, not merely exist.
  SELECT count(*) INTO v_hidden
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US'
     AND NOT ((p.is_active = true OR o.is_vacant = true)
              AND coalesce(p.is_incumbent, true) = true
              AND coalesce(o.title, '') NOT ILIKE 'Candidate for%');
  IF v_hidden <> 0 THEN
    RAISE EXCEPTION 'MI-4 gate 12: % seated Wayne County official(s) are hidden from the reps feed', v_hidden;
  END IF;

  RAISE NOTICE 'CC_0143 OK: 21 terms, 21 seated, 21 new people, 0 reused, 15 dated (3 day / 1 month / 11 year) and 6 countywide unknown, 4 appointed arrivals, 0 hidden from the reps feed.';
END
$gate$;

COMMIT;
