-- CC_0166_aberdeen_incumbents.sql
-- Knight Foundation program, wave SD-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0165, which creates the government, chambers, districts and offices.
--
-- Seats all nine elected officials of the City of Aberdeen: 8 council members and the mayor.
-- Creates 9 new people and reuses 0 -- measured 2026-09-28, NONE of the nine names exists in
-- production, so there is no namesake guard to lift here.
--
-- ⚠ DAVID NOVSTRUP (council, Southeast) AND AL NOVSTRUP (State Representative, District 3) ARE
-- DIFFERENT PEOPLE, both of Aberdeen, and both are seated by this slice -- Al by CC_0164. The full
-- names differ so nothing collides, but a surname match across the two waves would merge them.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 SEVEN OF NINE ARE DATED TO THE DAY FROM THE COUNCIL'S OWN OATH RECORDS.
--
--   2022-07-05  Erin Fouberg, Charlotte Liebelt, David Novstrup
--               "Finance Officer Jordan McQuillen administered the oath of office to new City
--                Council Members Erin Fouberg, Charlotte Liebelt, and David Novstrup."
--   2024-07-01  Rich Ward, and Mayor Travis Schaunaman's SECOND oath (see below)
--               "administered the oath of office to Mayor Travis Schaunaman and new City Council
--                Member Rich Ward."
--   2019-07-01  Travis Schaunaman, Mayor -- the FIRST oath, and the one that counts
--               "administered the oath of office to Travis Schaunaman, Mayor of the City of
--                Aberdeen, SD and Josh Rife, City Council Member - NW District."
--   2025-06-06  Talmage Ekanger
--               "Finance Officer McQuillen administered the Oath of Office to Talmage Ekanger."
--   2025-07-01  Chad Nilson -- charter s 2.02(c); no oath is recorded, and see below.
--
-- 🔴🔴 TWO MEMBERS OF THE SAME ELECTION STARTED 25 DAYS APART, AND DERIVING THE DATE WOULD HAVE
-- BEEN WRONG FOR ONE OF THEM. Ekanger and Nilson both won on 2025-06-03. Charter s 2.02(c) says
-- terms "begin on the first day of July after their election" -- which is right for Nilson and
-- WRONG for Ekanger, because the same sentence carries an exception: a member filling a VACANCY
-- takes office "immediately".
--   * Ekanger's SW seat was already vacant -- Justin Reinbold is gone from the roll by 2025-06-02.
--     At the canvass meeting on 2025-06-06 the council resolved that he "begin discharging the
--     duties of the office as soon as he has qualified", the Finance Officer administered the oath
--     AT THAT MEETING, and the Mayor "thereafter invited Council Member Ekanger to join the
--     meeting", where he moved the adjournment. He is at the roll call on 2025-06-16 and
--     2025-06-23, both BEFORE 1 July.
--   * Nilson's SE seat was NOT vacant: Tiffany Langer served it to the end of her term and is at
--     the roll call through 2025-06-23. And the SE race went to a RECOUNT -- Nilson won 124 to 123
--     -- with Resolution 25-06-02R "declaring results of SE District election following recount
--     board determination" adopted 2025-06-16. He first appears at the roll call on 2025-07-07.
-- ▶ A published term-end year cannot tell the two apart: both men read "Term Ends 2030". Only the
-- minutes can.
--
-- 🔴 A RE-ELECTION DOES NOT RESTART AN OCCUPANCY, AND THE MAYOR IS THE PROOF. Schaunaman was sworn
-- on 2019-07-01 and sworn AGAIN on 2024-07-01. The second is a re-election of a continuously
-- serving mayor, so his tenure starts in 2019. Taking the most recent oath would have shortened it
-- by five years.
--
-- ⚠ TWO ARRIVALS ARE OLDER THAN THE CITY'S OWN ARCHIVE, AND ARE WRITTEN AS UNKNOWN RATHER THAN
-- GUESSED. Aberdeen's Agenda Center offers 2015 onward and holds no 2015 council minutes, so the
-- earliest usable roll call is 2016-06-27 -- and ROB RONAYNE and ALAN JOHNSON are both present in
-- it. Both were re-elected in 2023 (their terms end 2028), but their continuous tenure began
-- before the record starts. Their terms are open-ended at start_precision 'unknown'. Writing
-- 2016-06-27 at day precision would assert a start that is merely the edge of the archive.
-- 🟢 Their continuity since at least 2016-06-27 is a real fact and is recorded here even though it
-- is not a start date.
--
-- 🔴 is_incumbent IS SET EXPLICITLY. It defaults to false since CA_0188, and a seated person
-- inserted without it is HIDDEN from address search.
--
-- 🔴 PARTY IS NOT WRITTEN -- Aberdeen's charter s 6.01(c): "Candidates shall run for office without
-- party designation."
--
-- 🟢 THE RESERVED external_id BAND IS -2765895 .. -2765887 (9 ids), MEASURED EMPTY 2026-09-28.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The nine people ──────────────────────────────────────────────────────

CREATE TEMP TABLE ab_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ab_people(external_id, full_name, first_name, last_name) VALUES
  (-2765895::bigint, 'Travis Schaunaman', 'Travis',    'Schaunaman'),
  (-2765894::bigint, 'Rob Ronayne',       'Rob',       'Ronayne'),
  (-2765893::bigint, 'Erin Fouberg',      'Erin',      'Fouberg'),
  (-2765892::bigint, 'Charlotte Liebelt', 'Charlotte', 'Liebelt'),
  (-2765891::bigint, 'Rich Ward',         'Rich',      'Ward'),
  (-2765890::bigint, 'David Novstrup',    'David',     'Novstrup'),
  (-2765889::bigint, 'Chad Nilson',       'Chad',      'Nilson'),
  (-2765888::bigint, 'Alan Johnson',      'Alan',      'Johnson'),
  (-2765887::bigint, 'Talmage Ekanger',   'Talmage',   'Ekanger');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'City of Aberdeen, South Dakota — City Council page (aberdeen.sd.us/74/City-Council) and Home Rule Charter ss 2.02, 2.03, 6.03; roster confirmed by the roll call of the City Council minutes of 2026-07-06; arrivals dated from the council''s own oath records in the minutes of 2019-07-01, 2022-07-05, 2024-07-01 and 2025-06-06; read 2026-09-28 (CC_0166, SD-3)',
       true, true
FROM ab_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The nine terms ───────────────────────────────────────────────────────
-- 🔴 Keyed on (geo_id, slot). The two council offices in a district are interchangeable rows, so
-- the slot is what resolves them; sort_key makes the assignment deterministic across re-runs.

CREATE TEMP TABLE ab_terms(
  geo_id text, external_id bigint, sort_key text,
  term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO ab_terms(geo_id, external_id, sort_key, term_start, start_precision, how_started) VALUES
  -- Citywide
  ('4600100',                                -2765895::bigint, 'Travis Schaunaman', '2019-07-01'::date, 'day',     'elected'),
  -- Northeast: oath 2022-07-05 (Fouberg); Ronayne predates the archive
  ('aberdeen-sd-council-district-northeast',  -2765893::bigint, 'Erin Fouberg',      '2022-07-05'::date, 'day',     'elected'),
  ('aberdeen-sd-council-district-northeast',  -2765894::bigint, 'Rob Ronayne',       NULL,               'unknown', 'unknown'),
  -- Northwest: oath 2022-07-05 (Liebelt), 2024-07-01 (Ward)
  ('aberdeen-sd-council-district-northwest',  -2765892::bigint, 'Charlotte Liebelt', '2022-07-05'::date, 'day',     'elected'),
  ('aberdeen-sd-council-district-northwest',  -2765891::bigint, 'Rich Ward',         '2024-07-01'::date, 'day',     'elected'),
  -- Southeast: oath 2022-07-05 (Novstrup); Nilson by charter s 2.02(c) after the recount
  ('aberdeen-sd-council-district-southeast',  -2765890::bigint, 'David Novstrup',    '2022-07-05'::date, 'day',     'elected'),
  ('aberdeen-sd-council-district-southeast',  -2765889::bigint, 'Chad Nilson',       '2025-07-01'::date, 'day',     'elected'),
  -- Southwest: Ekanger sworn early into a VACANT seat; Johnson predates the archive
  ('aberdeen-sd-council-district-southwest',  -2765887::bigint, 'Talmage Ekanger',   '2025-06-06'::date, 'day',     'elected'),
  ('aberdeen-sd-council-district-southwest',  -2765888::bigint, 'Alan Johnson',      NULL,               'unknown', 'unknown');

WITH office_slots AS (
  SELECT o.id AS office_id, d.geo_id,
         row_number() OVER (PARTITION BY o.district_id ORDER BY o.id) AS slot
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Aberdeen, South Dakota, US'
),
member_slots AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.geo_id ORDER BY t.sort_key) AS slot
  FROM ab_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, ms.term_start, NULL, ms.start_precision, ms.how_started,
       'City of Aberdeen, South Dakota — arrivals dated from the council''s own oath records: minutes of 2019-07-01 (Schaunaman), 2022-07-05 (Fouberg, Liebelt, Novstrup), 2024-07-01 (Ward) and the special meeting of 2025-06-06 (Ekanger, sworn into a vacant seat on the day of the canvass); Nilson by Home Rule Charter s 2.02(c) after the SE recount, Resolution 25-06-02R of 2025-06-16; Ronayne and Johnson continuous since at least 2016-06-27, the earliest council minute the city publishes, so their start is unknown rather than guessed; read 2026-09-28 (CC_0166, SD-3)'
FROM member_slots ms
JOIN office_slots os ON os.geo_id = ms.geo_id AND os.slot = ms.slot
JOIN essentials.politicians p ON p.external_id = ms.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people  int;
  v_terms   int;
  v_seated  int;
  v_day     int;
  v_unknown int;
  v_noninc  int;
  v_twoseat int;
  v_dupe    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2765895 AND -2765887;
  IF v_people <> 9 THEN
    RAISE EXCEPTION 'SD-3 occupancy gate: expected 9 people in the reserved band, got %', v_people;
  END IF;

  -- 🔴 Count och.politician_id, NOT *: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Aberdeen, South Dakota, US';
  IF v_seated <> 9 THEN
    RAISE EXCEPTION 'SD-3 occupancy gate: expected 9 seated Aberdeen offices, found %', v_seated;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Aberdeen, South Dakota, US';
  IF v_terms <> 9 THEN
    RAISE EXCEPTION 'SD-3 occupancy gate: expected 9 Aberdeen terms, found %', v_terms;
  END IF;

  -- 🟢 Seven dated to the day, two honestly unknown. Asserted so a later edit cannot quietly
  -- convert an unknown into a guessed date, or lose a dated one.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'day' AND ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.start_precision = 'unknown' AND ot.term_start IS NULL)
    INTO v_day, v_unknown
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Aberdeen, South Dakota, US';
  IF v_day <> 7 OR v_unknown <> 2 THEN
    RAISE EXCEPTION 'SD-3 occupancy gate: expected 7 day-precision and 2 unknown terms, found % and %', v_day, v_unknown;
  END IF;

  SELECT count(*) INTO v_noninc FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2765895 AND -2765887
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'SD-3 occupancy gate: % Aberdeen official(s) are not is_incumbent/is_active', v_noninc;
  END IF;

  -- 🔴 Each council district must hold two DISTINCT people. Two terms on one person would pass a
  -- count of 8.
  SELECT count(*) INTO v_twoseat
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'sd' AND d.mtfcc = 'X0072'
     AND (SELECT count(DISTINCT ot.politician_id)
            FROM essentials.offices o
            JOIN essentials.office_terms ot ON ot.office_id = o.id
           WHERE o.district_id = d.id) <> 2;
  IF v_twoseat <> 0 THEN
    RAISE EXCEPTION 'SD-3 occupancy gate: % Aberdeen council district(s) do not hold 2 DISTINCT people', v_twoseat;
  END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT ot.politician_id
      FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Aberdeen, South Dakota, US'
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'SD-3 occupancy gate: % person(s) hold more than one Aberdeen office', v_dupe;
  END IF;

  RAISE NOTICE 'SD-3 occupancy gate PASSED: 9 people, 9 terms, 9 seated, 0 vacant, 7 day-precision + 2 honestly unknown, each council district holding 2 distinct people.';
END $$;

COMMIT;
