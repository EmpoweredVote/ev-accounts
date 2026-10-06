-- CC_0172_biloxi_incumbents.sql
-- Knight Foundation program, wave MS-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0171, which creates the government, chambers, districts and offices.
--
-- Seats all eight elected officials of the City of Biloxi: the mayor and seven ward council
-- members. Creates 8 new people and reuses 0.
--
-- 🟢 THE NAMESAKE SWEEP FOUND NOTHING, AND ITS CONTROLS FIRED. Measured 2026-09-28 on the guard's
-- own key (lower(first_name), lower(last_name)): 0 of the eight names exist in production. That is
-- a measurement, not a silence -- the same query shape returns 73 active Smiths, and a surname-only
-- sweep returns 14 Grays, 14 Marshalls and 1 Nail, so the key discriminates rather than missing.
-- ⚠ THE ONE NAIL WAS CHECKED RATHER THAN ASSUMED. 'Larry Nail' is a different person and holds a
-- term of his own. This is MS-2's Rick/Richard Bennett case: a nickname stored as the first name
-- would slip past a first+last key, and Ward 3's member is published BOTH as 'Mike Nail' (his own
-- page) and 'Robert "Mike" Nail' (the city's election result). He is written here in the house
-- style -- legal first name, nickname in quotes inside full_name -- so neither form is lost.
-- 🟢 And no row anywhere in production carries any of the eight surnames against a Mississippi
-- office, so this wave cannot be re-seating somebody MS-2 already placed.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 AN INAUGURATION DATE IS NOT AN OATH DATE, AND THIS CITY'S OWN RECORD PROVES IT.
--
-- Mayor Gilich's public inauguration was Wednesday 2015-05-20. He was not sworn in then. The city
-- reported on Monday 2015-05-18: "His inauguration is not until Wednesday afternoon, but Mayor-elect
-- Andrew 'FoFo' Gilich wanted to begin the workweek early, so this morning he became Mayor Andrew
-- 'FoFo' Gilich" -- the oath administered "shortly after 8" by Clare Sekul Hornsby, his 93-year-old
-- aunt, expressly so that he could sign city documents and sit as mayor at Tuesday's council
-- meeting. ▶ Taking the advertised ceremony as the start would have been TWO DAYS WRONG, and
-- nothing in the ceremony announcement could have revealed it.
--
-- ▶ THAT IS WHY WARD 7 IS DATED TO A MONTH AND NOT A DAY. David Shoemaker won the special election
-- of 2024-02-27 for the unexpired term of Nathan Barrett, who resigned on being elected Harrison
-- County Supervisor for District 5. The city published an INVITATION to his inauguration --
-- "Tuesday, March 19, 2024, 12:00 p.m., Biloxi City Hall, 2nd Floor Council Chambers" -- and then
-- published nothing afterwards: a full-text sweep of the city's posts returns nine Shoemaker hits
-- and none between 2024-03-15 and 2025-03-21, and the council agendas of 19 and 26 March carry no
-- roster and no oath item. An invitation is a plan, and in this city a plan and an oath have
-- already come apart by two days. So 2024-03 at 'month', not 2024-03-19 at 'day'.
-- 🔴 DO NOT PROMOTE IT WITHOUT THE MINUTES (Laserfiche, weblink.mccinnovations.com, LogName=Biloxi).
--
-- 🟢 THE ARITHMETIC CLOSES, AND THAT IS THE REAL CONTROL ON THESE DATES. The mayor's inaugural
-- address of 2025-06-30 says the term begins with "four new council members". Against the city's
-- 2021 inaugural list, FIVE seats changed -- which would make the mayor wrong. He is not:
-- Shoemaker was already sitting, seated at the 2024 special, and the 2025 result post confirms it
-- by listing him among "Council members ... all unopposed". Four genuinely new (Gray, Marshall,
-- Nail, Creel), three continuing (Tisdale, Glavan, Shoemaker). The mayor's own count and the seat
-- histories agree ONLY if Ward 7 is dated to 2024 rather than 2025.
--
-- 🔴 A RE-ELECTION DOES NOT RESTART AN OCCUPANCY, AND TWO MEMBERS ARE THE PROOF. Paul A. Tisdale
-- and Kenny Glavan were both sworn at the 2013-07-01 inauguration and appear in the city's record
-- of every ceremony since -- 2017-06-28, 2021-06-29, 2025-06-30. Dating them from the most recent
-- oath would have erased twelve years of tenure.
-- ⚠ AND THE 2013 CEREMONY REPORT ALONE COULD NOT HAVE DATED THEM: it names the members sworn but
-- gives no wards, so a member who had since CHANGED ward would be mis-dated exactly as MS-2's
-- SD-44 would have been. The city's 2013 RESULT post supplies what the ceremony post lacks --
-- "Ward 5, Dr. Paul Tisdale; and Ward 6, Kenny Glavan, who defeated incumbent Edward 'Ed' Gemmill"
-- -- so both have held the SAME ward continuously. office_terms is a seat, not a career.
--
-- 🔴 is_incumbent IS SET EXPLICITLY. It defaults to false since CA_0188, and a seated person
-- inserted without it is HIDDEN from address search.
--
-- 🔴 PARTY IS NOT WRITTEN. Biloxi's municipal elections are partisan and the city publishes each
-- member's affiliation on their own page, which makes this the easy place to get it wrong. Party
-- lives on races.primary_party in this database -- which ballot a voter requests -- and never on a
-- person or an office.
--
-- 🟢 THE RESERVED external_id BAND IS -2766408 .. -2766401 (8 ids), ASCENDING, MEASURED EMPTY
-- 2026-09-28 -- and measured with a control, because MS-2 checked a band it did not use. The same
-- query reports 174 occupants for MS-2's actual band (-2766400 .. -2766227), so it can see rows.
-- The band below is the one the INSERT uses and the one the gate asserts; they are the same
-- numbers in both places.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the eight offices must exist ─────────────────────────────

DO $$
DECLARE v_off int;
BEGIN
  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US';
  IF v_off <> 8 THEN
    RAISE EXCEPTION 'MS-3 occupancy pre-flight: expected 8 Biloxi offices from CC_0171, found %', v_off;
  END IF;
END $$;

-- ─── 1. The eight people ─────────────────────────────────────────────────────

CREATE TEMP TABLE bx_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO bx_people(external_id, full_name, first_name, last_name) VALUES
  (-2766408::bigint, 'Andrew M. "FoFo" Gilich, Jr.', 'Andrew',  'Gilich'),
  (-2766407::bigint, 'Wayne Gray',                   'Wayne',   'Gray'),
  (-2766406::bigint, 'Anthony L. Marshall',          'Anthony', 'Marshall'),
  (-2766405::bigint, 'Robert "Mike" Nail',           'Robert',  'Nail'),
  (-2766404::bigint, 'Jamie Creel',                  'Jamie',   'Creel'),
  (-2766403::bigint, 'Paul A. Tisdale',              'Paul',    'Tisdale'),
  (-2766402::bigint, 'Kenny J. Glavan, Sr.',         'Kenny',   'Glavan'),
  (-2766401::bigint, 'David Shoemaker',              'David',   'Shoemaker');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'City of Biloxi, Mississippi — City Council and Mayor pages (biloxi.ms.us/departments/city-council/, /departments/mayor/); roster confirmed against the city''s own general election report of 2025-06-03 ("Four plus four equals Biloxi") and its inauguration notice of 2025-06-27; read 2026-09-28 (CC_0172, MS-3)',
       true, true
FROM bx_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The eight terms ──────────────────────────────────────────────────────
-- 🟢 SINGLE-MEMBER, so a term joins its office through (geo_id, mtfcc) alone. No slot arithmetic
-- is needed here, unlike Aberdeen's two-per-district council.
-- 🔴 Every join pairs geo_id WITH mtfcc — Mississippi is the programme's worst state for unkeyed
-- geo_id lookups, and the citywide row and the ward rows live in different layers.

CREATE TEMP TABLE bx_terms(
  geo_id text, mtfcc text, external_id bigint,
  term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO bx_terms(geo_id, mtfcc, external_id, term_start, start_precision, how_started) VALUES
  -- Citywide. Sworn 2015-05-18, two days BEFORE his advertised inauguration; re-elected 2017,
  -- 2021 and 2025, which does not restart the occupancy.
  ('2806220',          'G4110', -2766408::bigint, '2015-05-18'::date, 'day',   'elected'),
  -- The four seated at the 2025-06-30 inauguration, confirmed after the fact by the mayor's own
  -- inaugural address of 2025-07-01: "this City Council which has also just taken their oath".
  ('biloxi-ms-ward-1', 'X0073', -2766407::bigint, '2025-06-30'::date, 'day',   'elected'),
  ('biloxi-ms-ward-2', 'X0073', -2766406::bigint, '2025-06-30'::date, 'day',   'elected'),
  ('biloxi-ms-ward-3', 'X0073', -2766405::bigint, '2025-06-30'::date, 'day',   'elected'),
  ('biloxi-ms-ward-4', 'X0073', -2766404::bigint, '2025-06-30'::date, 'day',   'elected'),
  -- Continuous in the SAME ward since the 2013-07-01 inauguration.
  ('biloxi-ms-ward-5', 'X0073', -2766403::bigint, '2013-07-01'::date, 'day',   'elected'),
  ('biloxi-ms-ward-6', 'X0073', -2766402::bigint, '2013-07-01'::date, 'day',   'elected'),
  -- Special election 2024-02-27; the ceremony was announced for 2024-03-19 and never reported.
  ('biloxi-ms-ward-7', 'X0073', -2766401::bigint, '2024-03-01'::date, 'month', 'elected');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       'City of Biloxi, Mississippi — arrivals dated from the city''s own published records: the oath of 2015-05-18 for Mayor Gilich (taken two days before his advertised inauguration, and reported by the city on the day); the inauguration of 2025-06-30 for Wards 1-4, announced 2025-06-27 and confirmed after the fact by the mayor''s inaugural address of 2025-07-01; the inauguration of 2013-07-01 for Wards 5 and 6, whose ward assignments come from the city''s 2013 election result rather than the ceremony report; and March 2024 at month precision for Ward 7, whose special election was 2024-02-27 and whose ceremony was announced for 2024-03-19 but never reported — an invitation is a plan, and in this city a plan and an oath have already come apart by two days. Read 2026-09-28 (CC_0172, MS-3)'
FROM bx_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.mtfcc = t.mtfcc AND d.district_type = 'LOCAL' AND lower(d.state) = 'ms'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'City of Biloxi, Mississippi, US'
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people  int;
  v_terms   int;
  v_seated  int;
  v_day     int;
  v_month   int;
  v_noninc  int;
  v_perward int;
  v_dupe    int;
  v_mayor   date;
  v_ward7   date;
  v_leg     int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2766408 AND -2766401;
  IF v_people <> 8 THEN
    RAISE EXCEPTION 'MS-3 occupancy gate: expected 8 people in the reserved band, got %', v_people;
  END IF;

  -- 🔴 Count och.politician_id, NOT *: office_current_holder LEFT JOINs from offices, so a vacancy
  -- is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Biloxi, Mississippi, US';
  IF v_seated <> 8 THEN
    RAISE EXCEPTION 'MS-3 occupancy gate: expected 8 seated Biloxi offices, found %', v_seated;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US';
  IF v_terms <> 8 THEN
    RAISE EXCEPTION 'MS-3 occupancy gate: expected 8 Biloxi terms, found %', v_terms;
  END IF;

  -- 🟢 Seven to the day, one to the month. Asserted so that a later pass cannot quietly promote
  -- Ward 7's month to a day without the minutes that would justify it.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'day'   AND ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.start_precision = 'month' AND ot.term_start IS NOT NULL)
    INTO v_day, v_month
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US';
  IF v_day <> 7 OR v_month <> 1 THEN
    RAISE EXCEPTION 'MS-3 occupancy gate: expected 7 day-precision and 1 month-precision terms, found % and %', v_day, v_month;
  END IF;

  -- 🔴 THE MAYOR'S DATE ASSERTED DIRECTLY, because it is the one a reasonable person would
  -- "correct". 2015-05-20 is the inauguration; 2015-05-18 is the oath.
  SELECT ot.term_start INTO v_mayor
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Biloxi, Mississippi, US' AND c.name = 'Office of the Mayor';
  IF v_mayor IS DISTINCT FROM '2015-05-18'::date THEN
    RAISE EXCEPTION 'MS-3 occupancy gate: mayor term_start is %, expected 2015-05-18 (the oath, not the 2015-05-20 inauguration)', v_mayor;
  END IF;

  -- 🔴 AND WARD 7'S, because dating it to 2025-06-30 would make the mayor's own "four new council
  -- members" wrong by one.
  SELECT ot.term_start INTO v_ward7
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = 'biloxi-ms-ward-7' AND d.mtfcc = 'X0073';
  IF v_ward7 IS DISTINCT FROM '2024-03-01'::date THEN
    RAISE EXCEPTION 'MS-3 occupancy gate: Ward 7 term_start is %, expected 2024-03-01 at month precision', v_ward7;
  END IF;

  SELECT count(*) INTO v_noninc FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2766408 AND -2766401
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'MS-3 occupancy gate: % Biloxi official(s) are not is_incumbent/is_active', v_noninc;
  END IF;

  -- 🔴 Each ward must hold exactly ONE distinct person. A total of 8 would also pass with one ward
  -- empty and another doubled.
  SELECT count(*) INTO v_perward
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'ms' AND d.mtfcc = 'X0073'
     AND (SELECT count(DISTINCT ot.politician_id)
            FROM essentials.offices o
            JOIN essentials.office_terms ot ON ot.office_id = o.id
           WHERE o.district_id = d.id) <> 1;
  IF v_perward <> 0 THEN
    RAISE EXCEPTION 'MS-3 occupancy gate: % Biloxi ward(s) do not hold exactly 1 distinct person', v_perward;
  END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT ot.politician_id
      FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Biloxi, Mississippi, US'
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'MS-3 occupancy gate: % person(s) hold more than one Biloxi office', v_dupe;
  END IF;

  -- 🔴 CONTROL, IN THE SAME TRANSACTION: MS-2's 174 legislative seats must still be seated. Again,
  -- count the politician_id, not the row.
  SELECT count(och.politician_id) INTO v_leg
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc IN ('G5210', 'G5220') AND lower(d.state) = 'ms';
  IF v_leg <> 174 THEN
    RAISE EXCEPTION 'MS-3 occupancy gate CONTROL: expected 174 seated Mississippi legislative offices from MS-2, found %', v_leg;
  END IF;

  RAISE NOTICE 'MS-3 occupancy gate PASSED: 8 people, 8 terms, 8 seated, 0 vacant, 7 day-precision + 1 month, mayor at 2015-05-18 and Ward 7 at 2024-03-01, one distinct person per ward; 174 MS legislative seats unmoved.';
END $$;

COMMIT;
