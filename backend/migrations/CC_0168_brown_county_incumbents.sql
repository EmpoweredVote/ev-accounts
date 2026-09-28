-- CC_0168_brown_county_incumbents.sql
-- Knight Foundation program, wave SD-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0167, which creates the government, the two chambers and the ten
-- offices. This migration creates TEN people and TEN office_terms rows and nothing else.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE ONE RULE THIS WAVE IS BUILT ON: AN ELECTION YEAR IS NOT AN ARRIVAL.
--
-- Six of these ten arrived in an office that was ALREADY THEIRS before the election that a
-- roster would credit them with, or arrived mid-term by appointment. Measured against the
-- county's own dated record:
--
--   * Mike Gage was APPOINTED on 2021-12-14 and elected eleven months later, in 2022.
--   * Lynn Heupel was APPOINTED in 2022 and elected in 2024.
--   * Karly Winter was APPOINTED in 2023 and elected in 2024.
--   * Patty VanMeter was APPOINTED before 2020 and elected in 2020 and again in 2024.
--   * Duane Sutton has served continuously since before the county's own web record begins.
--   * Mike Wiese served, LEFT, and came back -- the one case where an election really does start
--     a fresh occupancy, and the reason the others do not.
--
-- ▶ Taking the most recent election would have been wrong for six of ten. Taking the FIRST
-- election in the Secretary of State's own candidate lists would still have been wrong for four,
-- because an appointment leaves no candidate row at all.
--
-- 🔴🔴 AND THE ELECTION RESULTS ARE NOT AN INVENTORY OF WHO WAS ELECTED. South Dakota lets a
-- county auditor leave an uncontested office off the ballot entirely, so an unopposed winner
-- appears in NO result. Measured: the Secretary of State's Brown County return for the November
-- 2024 general carries NO county contest at all -- no commissioner, no treasurer, no auditor, no
-- state's attorney -- yet five people took those offices from that election. The CANDIDATE LIST
-- holds them; the RESULT does not. Doug Fjeldheim is the same shape in 2022: on the candidate
-- list, absent from the result, and sworn in on 2023-01-03.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 HOW EACH TERM START WAS ESTABLISHED. One rule, applied consistently:
--   * an ELECTED arrival takes the STATUTORY TERM COMMENCEMENT, which South Dakota fixes by
--     office and which is therefore a date the statute states, not a date this migration computes;
--   * an APPOINTED arrival takes the date the county's own minutes give it.
--
-- 🔴 THE STATUTORY START DAY IS NOT THE SAME FOR EVERY OFFICE IN THIS COUNTY. Three different
-- days, and getting them uniform would be wrong three ways:
--   SDCL 7-8-1   County Commissioner ....... FIRST TUESDAY of January after the election
--   SDCL 7-7-1   Treasurer, Register of Deeds, Sheriff, State's Attorney .. FIRST MONDAY in January
--   SDCL 7-7-1   County Auditor ............ FIRST MONDAY OF MARCH after the election
--
-- 🟢 THE DERIVATION IS CONTROLLED, NOT ASSUMED. Two commissioner oaths are recorded in the
-- county's own minutes, and BOTH land exactly on the statutory first Tuesday:
--     2023-01-03  "Drew Dennert, Mike Gage and Doug Fjeldheim were sworn in as Brown County
--                  Commissioners" -- the first Tuesday of January 2023;
--     2025-01-07  "Auditor Heupel Administered the Oaths of Office to Commissioners Sutton and
--                  Dinger" -- the first Tuesday of January 2025.
--
-- ⚠ AND THE CONTROL ALSO SHOWS THE OATH AND THE TERM START ARE DIFFERENT EVENTS. Sheriff Dave
-- Lunzman's statutory term began on the first MONDAY, 2023-01-02, but he was sworn on 2023-01-03,
-- because Brown County swears its countywide officers at the commission's reorganization meeting,
-- which falls on the commission's Tuesday. Mike Wiese's re-election oath is later still --
-- 2023-01-17, a fortnight after his term began. ▶ This is why the term start is taken from the
-- statute and not from the ceremony; the ceremony dates are recorded in the source strings.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 TWO STARTS ARE HONESTLY UNKNOWN, AND THEY ARE WRITTEN THAT WAY.
--
--   DUANE SUTTON is on the Brown County Commission in the EARLIEST archived copy of the county's
--   own Commission page, 2014-05-27, already serving as its Chair. He was re-elected in 2016, 2020
--   and 2024. His arrival is older than anything the county publishes.
--
--   PATTY VANMETER is Treasurer in the earliest archived copy of the county's Treasurer page that
--   shows her, 2020-02-26; Sheila Enderson still held the office on 2019-07-16. So VanMeter
--   arrived by appointment in that seven-month window -- but the county's individual minutes are
--   archived only from 2020-02-18, after she was already in place, and the bound annual volumes
--   that would cover 2019 survive only as the first megabyte of a 45 MB scan.
--
-- ▶ Both take an OPEN-ENDED term at start_precision 'unknown'. Writing 2014-05-27 or 2020-02-26 at
-- day precision would assert a start that is merely the edge of an archive. Their continuity since
-- those dates is a real fact and is recorded in the source strings, because it is worth knowing
-- even though it is not a start date.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ THE COUNTY'S OWN DEPARTMENT PAGES WERE STALE, AND TRUSTING THEM WOULD HAVE MOVED A DATE BY
-- MONTHS. The archived State's Attorney page still named Ernest Thompson on 2023-09-28, ten weeks
-- after Karly Winter took the office on 2023-07-10 and four months after Thompson's resignation
-- took effect. The HR record inside the minutes is what dates it. A source can be authoritative
-- for one field and stale for another.
--
-- ⚠ A SURNAME IS NOT A PERSON. Scanning the minutes for these ten names returns "Violet Dinger
-- Estate", "Gage Hansen", "Sutton Stearns", "Karly Allison", "Andrea Heupel" and "Matthew Heupel"
-- -- claim lists and 4-H premium rolls. Every date below comes from a line that names the office.
--
-- 🟢 NO NAME COLLIDED. All ten were checked against production before insert: the only surname
-- matches are Bill Sutton (Kansas), Ed Sutton (South Carolina), Michael Van Meter, Stacy Wiese and
-- Ty Winter -- five different people. Checked, not assumed.
--
-- 🔴 is_incumbent IS SET EXPLICITLY. It defaults to false since CA_0188, and a seated person
-- inserted without it is HIDDEN from address search.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party.
--
-- 🟢 THE RESERVED external_id BAND IS -2765886 .. -2765877 (10 ids), MEASURED EMPTY 2026-09-28.
-- It continues this slice's own sequence: SD-2 took -2766000..-2765896, SD-3 took -2765895..-2765887.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate on the END STATE.

BEGIN;

-- ─── 0. Pre-flight: CC_0167 must have run ────────────────────────────────────

DO $$
DECLARE v_off int;
BEGIN
  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_off <> 10 THEN
    RAISE EXCEPTION 'SD-4 occupancy pre-flight: expected 10 Brown County offices from CC_0167, found %', v_off;
  END IF;
END $$;

-- ─── 1. The ten people ───────────────────────────────────────────────────────

CREATE TEMP TABLE bc_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO bc_people(external_id, full_name, first_name, last_name) VALUES
  (-2765886::bigint, 'Duane Sutton',   'Duane',    'Sutton'),
  (-2765885::bigint, 'Mike Wiese',     'Mike',     'Wiese'),
  (-2765884::bigint, 'Mike Gage',      'Mike',     'Gage'),
  (-2765883::bigint, 'Drew Dennert',   'Drew',     'Dennert'),
  (-2765882::bigint, 'Kyler Dinger',   'Kyler',    'Dinger'),
  (-2765881::bigint, 'Lynn Heupel',    'Lynn',     'Heupel'),
  (-2765880::bigint, 'Patty VanMeter', 'Patty',    'VanMeter'),
  (-2765879::bigint, 'Mariann Malsom', 'Mariann',  'Malsom'),
  (-2765878::bigint, 'Dave Lunzman',   'Dave',     'Lunzman'),
  (-2765877::bigint, 'Karly Winter',   'Karly',    'Winter');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Brown County, South Dakota — roster from the county''s own department pages at brown.sd.us (Commission, Auditor, Treasurer, Register of Deeds, Sheriff''s Office, State''s Attorney), confirmed against the South Dakota Department of Legislative Audit''s "COUNTY OFFICIALS" page in the Brown County audit reports as of December 31 in 2021, 2023 and 2024, and against the Secretary of State''s candidate lists for 2016-2024. Arrivals dated from the commission''s own minutes; read 2026-09-28 (CC_0168, SD-4)',
       true, true
FROM bc_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The five countywide terms ────────────────────────────────────────────
-- These offices are distinguished by title, so they are matched directly.

CREATE TEMP TABLE bc_wide(title text, external_id bigint, term_start date, start_precision text, how_started text, note text)
  ON COMMIT DROP;

INSERT INTO bc_wide(title, external_id, term_start, start_precision, how_started, note) VALUES
  ('County Auditor',    -2765881::bigint, '2022-09-06'::date, 'day',     'appointed',
   'Named Interim Auditor by the commission on 2022-08-09 — "Lynn Heupel was named as Interim Auditor for 2 years. She will have to run in the 2024 election" — and hired in the same meeting''s personnel report "effective September 6, 2022", the office having been run by Chief Deputy Auditor Brock Hoyle as check signatory since Cathy McNickle left in July 2022. The two-year interim term is why the auditorship is OFF the SDCL 7-7-1.1 cycle: it fell to the 2024 general, not 2026. Elected 2024 (as Lynn Meyer-Heupel on the Secretary of State''s list) — a re-election, which does not restart this occupancy.'),
  ('County Treasurer',  -2765880::bigint, NULL,               'unknown', 'unknown',
   'Continuous since AT LEAST 2020-02-26, the earliest archived copy of the county''s own Treasurer page that names her; Sheila Enderson still held the office on 2019-07-16, so VanMeter arrived by appointment inside that window. The county''s individual minutes are archived only from 2020-02-18, after she was in place, and the bound annual volume covering 2019 survives only as the first megabyte of a 45 MB scan. Elected 2020 and 2024; both are re-elections and neither restarts this occupancy. She also served as INTERIM Register of Deeds in 2022, a different office.'),
  ('Register of Deeds', -2765879::bigint, '2023-01-02'::date, 'day',     'elected',
   'Elected November 2022 (Secretary of State candidate list, filed 2022-01-25; unopposed, so the contest does not appear in the return). Term commenced the first Monday in January, SDCL 7-7-1. Her predecessor Roberta Nichols left mid-term and Treasurer Patty VanMeter held the office as INTERIM Register of Deeds on 2022-07-02; Malsom holds it in the county''s own page from 2023-02-05. ⚠ No oath is recorded for her — the swearing-in of 2023-01-03 names the three commissioners and the Sheriff only.'),
  ('Sheriff',           -2765878::bigint, '2023-01-02'::date, 'day',     'elected',
   'Elected November 2022 (Secretary of State candidate list, filed 2022-03-14), succeeding Mark Milbrandt, who held the office from 2014 through 2022-07-02 in the county''s own pages. Term commenced the first Monday in January, SDCL 7-7-1. ⚠ His OATH is one day later: the minutes of 2023-01-03 record that "Dave Lunzman was sworn in as Sheriff and Interim Coroner by Lynn Heupel, Auditor", at the commission''s reorganization meeting. He has since held the appointed coronership as well, until Brian Koens was sworn as Coroner on 2024-12-31.'),
  ('State''s Attorney', -2765877::bigint, '2023-07-10'::date, 'day',     'appointed',
   'Appointed mid-term. The commission acknowledged "the resignation of Ernest Thompson, Brown County States Attorney, effective May 12, 2023" on 2023-03-14, appointed Mark Anderson "as temporary interim State''s Attorney" on 2023-05-09, and in the personnel report of 2023-05-02 approved the "Hiring of Karly Winter as Brown County States Attorney … effective July 10, 2023". Elected November 2024 — a re-election, which does not restart this occupancy. ⚠ The county''s own State''s Attorney page still named Thompson on 2023-09-28, ten weeks after Winter took office.');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, w.term_start, NULL, w.start_precision, w.how_started,
       'Brown County, South Dakota — ' || w.note || ' Read 2026-09-28 (CC_0168, SD-4)'
FROM bc_wide w
JOIN essentials.governments g ON g.name = 'Brown County, South Dakota, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Brown County Elected Officials'
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = w.title
JOIN essentials.politicians p ON p.external_id = w.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── 3. The five commissioner terms ──────────────────────────────────────────
-- 🔴 The five commissioner offices are INTERCHANGEABLE rows on one district with one title — the
-- seats are at large and the ballot numbers nothing. A slot resolves them; sort_key makes the
-- assignment deterministic across re-runs, and asserts nothing about which seat is which.

CREATE TEMP TABLE bc_comm(external_id bigint, sort_key text, term_start date, start_precision text, how_started text, note text)
  ON COMMIT DROP;

INSERT INTO bc_comm(external_id, sort_key, term_start, start_precision, how_started, note) VALUES
  (-2765883::bigint, 'Drew Dennert',  '2023-01-03'::date, 'day',     'elected',
   'Elected November 2022, top of the poll with 8,398 votes in the Secretary of State''s own return for "County Commissioner At Large - Brown". Sworn on 2023-01-03 — "Drew Dennert, Mike Gage and Doug Fjeldheim were sworn in as Brown County Commissioners … by Lynn Heupel, Auditor" — which is exactly the first Tuesday of January that SDCL 7-8-1 fixes. He is absent from the county''s Commission page on 2022-09-24 and present on 2023-02-03.'),
  (-2765882::bigint, 'Kyler Dinger',  '2025-01-07'::date, 'day',     'elected',
   'Elected November 2024; unopposed after the June primary, so the contest does not appear in the Secretary of State''s return at all. Sworn on 2025-01-07 — "Auditor Heupel Administered the Oaths of Office to Commissioners Sutton and Dinger" — which is exactly the first Tuesday of January that SDCL 7-8-1 fixes. He took the seat that Doug Fjeldheim held to the end of 2024.'),
  (-2765884::bigint, 'Mike Gage',     '2021-12-14'::date, 'day',     'appointed',
   'APPOINTED, not elected, and the minutes date it to the day: "SWEARING IN CEREMONY: Mike Gage was sworn in by County Auditor, Cathy McNickle as Brown County Commissioner", 2021-12-14, filling the seat of "former Commissioner Kippley who resigned December 7, 2021". He is absent from the attendance of 2021-11-30 and present on 2021-12-14. He was then elected in his own right in November 2022 (7,122 votes) — a later election that does not restart this occupancy.'),
  (-2765886::bigint, 'Duane Sutton',  NULL,               'unknown', 'unknown',
   'Continuous since AT LEAST 2014-05-27, the earliest archived copy of the county''s own Commission page, where he already appears as Chair. Re-elected in 2016 (9,408 votes), 2020 (9,227) and 2024. His arrival predates every record Brown County publishes and every Secretary of State candidate list that is online, so the start is unknown rather than guessed.'),
  (-2765885::bigint, 'Mike Wiese',    '2019-01-01'::date, 'day',     'elected',
   'Elected November 2018, third of six for three seats with 6,819 votes in the Secretary of State''s own return. Term commenced the first Tuesday of January 2019, SDCL 7-8-1. 🔴 This is a FRESH occupancy, not a continuation: Wiese sat on the commission through 2014, is ABSENT from the county''s own Commission page from 2015-01-21 to 2018-07-01, and returns on 2019-01-01. He was re-elected in 2022 and took a second oath on 2023-01-17, a fortnight after that term began — a re-election, which does not restart this occupancy.');

WITH office_slots AS (
  SELECT o.id AS office_id,
         row_number() OVER (ORDER BY o.id) AS slot
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'Brown County, South Dakota, US' AND c.name = 'Brown County Commission'
),
member_slots AS (
  SELECT t.*, row_number() OVER (ORDER BY t.sort_key) AS slot FROM bc_comm t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, ms.term_start, NULL, ms.start_precision, ms.how_started,
       'Brown County, South Dakota — ' || ms.note || ' Read 2026-09-28 (CC_0168, SD-4)'
FROM member_slots ms
JOIN office_slots os ON os.slot = ms.slot
JOIN essentials.politicians p ON p.external_id = ms.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_comm int; v_wide int;
  v_day int; v_unknown int; v_elected int; v_appointed int;
  v_notinc int; v_dupe int; v_twoseats int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2765886 AND -2765877;
  IF v_people <> 10 THEN RAISE EXCEPTION 'SD-4 occupancy gate: expected 10 people in the reserved band, found %', v_people; END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_terms <> 10 THEN RAISE EXCEPTION 'SD-4 occupancy gate: expected 10 office_terms rows, found %', v_terms; END IF;

  -- 🔴 COUNT och.politician_id, NOT *: office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) FILTER (WHERE c.name = 'Brown County Commission'),
         count(och.politician_id) FILTER (WHERE c.name = 'Brown County Elected Officials')
    INTO v_comm, v_wide
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_comm <> 5 OR v_wide <> 5 THEN
    RAISE EXCEPTION 'SD-4 occupancy gate: seated split is % commission / % countywide, expected 5 / 5', v_comm, v_wide;
  END IF;
  v_seated := v_comm + v_wide;

  -- 🔴 Precision is asserted EXPLICITLY so a later edit cannot quietly turn an unknown into a guess.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown')
    INTO v_day, v_unknown
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_day <> 8 OR v_unknown <> 2 THEN
    RAISE EXCEPTION 'SD-4 occupancy gate: expected 8 day-precision + 2 unknown starts, found % + %. Duane Sutton and Patty VanMeter arrived before the county''s own published record begins; anything else is a guess.', v_day, v_unknown;
  END IF;

  -- Every unknown-precision term must carry a NULL term_start. A date at 'unknown' is a guess
  -- wearing a disclaimer.
  IF EXISTS (SELECT 1 FROM essentials.office_terms ot
               JOIN essentials.offices o ON o.id = ot.office_id
               JOIN essentials.chambers c ON c.id = o.chamber_id
               JOIN essentials.governments g ON g.id = c.government_id
              WHERE g.name = 'Brown County, South Dakota, US'
                AND ot.start_precision = 'unknown' AND ot.term_start IS NOT NULL) THEN
    RAISE EXCEPTION 'SD-4 occupancy gate: an unknown-precision term carries a term_start date';
  END IF;

  SELECT count(*) FILTER (WHERE ot.how_started = 'elected'),
         count(*) FILTER (WHERE ot.how_started = 'appointed')
    INTO v_elected, v_appointed
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Brown County, South Dakota, US';
  IF v_elected <> 5 OR v_appointed <> 3 THEN
    RAISE EXCEPTION 'SD-4 occupancy gate: expected 5 elected + 3 appointed (+2 unknown), found % + %. Gage 2021-12-14, Heupel 2022-09-06 and Winter 2023-07-10 all arrived by APPOINTMENT and were elected later.', v_elected, v_appointed;
  END IF;

  SELECT count(*) INTO v_notinc FROM essentials.politicians
   WHERE external_id BETWEEN -2765886 AND -2765877 AND is_incumbent IS NOT TRUE;
  IF v_notinc <> 0 THEN
    RAISE EXCEPTION 'SD-4 occupancy gate: % of the ten are not is_incumbent — they would be hidden from address search', v_notinc;
  END IF;

  -- Ten DISTINCT people, one office each.
  SELECT count(*) INTO v_dupe FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Brown County, South Dakota, US'
     GROUP BY ot.politician_id HAVING count(*) > 1) t;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'SD-4 occupancy gate: % person(s) hold two Brown County offices', v_dupe;
  END IF;

  -- None of the ten may also hold a South Dakota legislative or Aberdeen seat.
  -- ⚠ David Novstrup (Aberdeen council) and Al Novstrup (State Representative) are DIFFERENT
  -- people already in production; this asserts that nothing in THIS band was merged into them.
  SELECT count(*) INTO v_twoseats FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
     WHERE ot.politician_id IN (SELECT id FROM essentials.politicians
                                 WHERE external_id BETWEEN -2765886 AND -2765877)
     GROUP BY ot.politician_id HAVING count(*) > 1) t;
  IF v_twoseats <> 0 THEN
    RAISE EXCEPTION 'SD-4 occupancy gate: % of the ten hold more than one office anywhere', v_twoseats;
  END IF;

  RAISE NOTICE 'SD-4 occupancy gate PASSED: 10 people, 10 terms, % seated (5 commission + 5 countywide), 8 day-precision + 2 honestly unknown, 5 elected + 3 appointed + 2 unknown, all is_incumbent.', v_seated;
END $$;

COMMIT;
