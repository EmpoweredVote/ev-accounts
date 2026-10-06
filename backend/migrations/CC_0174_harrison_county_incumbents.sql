-- CC_0174_harrison_county_incumbents.sql
-- Knight Foundation program, wave MS-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0173, which creates the government, chambers, districts and offices.
--
-- Seats all twenty-seven elected officials of Harrison County, Mississippi. Creates 27 new people
-- and reuses 0.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE OATH DATE IS NOT THE STATUTORY DATE, AND THE BOARD'S OWN MINUTES SAY SO IN TERMS.
--
-- Mississippi seats county officers on the first Monday of January. A reader who knew that would
-- write 2024-01-01. The Board of Supervisors' minutes of its organising meeting say otherwise, and
-- explain themselves:
--
--   "a regular meeting ... was begun and held ... on the FIRST TUESDAY OF JANUARY 2024, being
--    January 2, 2024, the first Monday of January 2024 being a legal holiday and January 2, 2024,
--    being the day succeeding the first Monday of January 2024 ... There appeared the following
--    members-elect of said Board of Supervisors from the several Supervisor Districts of Harrison
--    County, Mississippi, FOR THE TERM OF FOUR YEARS COMMENCING ON THIS DATE: DAN CUEVAS District
--    One, REBECCA POWERS District Two, MARLIN R. LADNER District Three, KENT JONES District Four,
--    NATHAN BARRETT District Five — and each of them having given bond as required by law and taken
--    the oath prescribed by the Constitution of the State of Mississippi..."
--
-- ▶ 2024-01-02, because 1 January 2024 was a holiday. A COMPUTED date would have been a day wrong,
-- for a reason no reading of the statute could supply. This is the third variant of the rule inside
-- this one slice: Biloxi's mayor was sworn two days BEFORE his advertised inauguration; Biloxi's
-- Ward 7 ceremony was announced and never reported; and here the statutory day itself moved.
--
-- ⚠ KENT JONES IS ABSENT FROM THE ROLL CALL OF THAT SAME MEETING ("Absent & Exc 1 - Kent Jones"),
-- and this is recorded rather than hidden. He is dated 2024-01-02 with the other four because what
-- office_terms records is the start of the TERM, and the recital fixes that for all five named
-- members-elect — "for the term of four years commencing on this date". Attendance at the
-- meeting's business is a different fact. He is present at the roll call of 1990-01-08's successor
-- meeting on 2024-01-08, and no later minute records a separate oath.
--
-- 🟢 THE OTHER NINETEEN ARE DATED TO THE YEAR, NOT THE DAY, AND THAT UNDER-CLAIMS DELIBERATELY.
-- The certified results establish that they won in November 2023 and Mississippi gives them a
-- four-year term from January 2024, but no document read for this wave records the day on which
-- each was sworn — they are sworn separately from the Board, commonly by a judge. Writing
-- 2024-01-02 for them would be borrowing the supervisors' minute for people it does not mention.
--
-- 🔴 THREE ELECTION COMMISSIONERS ARE HONESTLY UNKNOWN, AND THAT IS A FINDING, NOT A GAP.
-- Only Districts 2 and 4 appear on the 2023 general ballot. Districts 1, 3 and 5 are held by
-- Toni Jo Diaz, Jennifer Smith and Carolyn Handler on the county's own Election Commission page,
-- but nothing read for this wave says when they arrived. Their terms are open-ended at
-- start_precision 'unknown' and how_started 'unknown'. ▶ Do NOT copy 2024 onto them from their two
-- colleagues: the whole reason they are separate is that the ballot does not cover them.
--
-- ⚠ THE COUNTY'S OWN OFFICER PAGES CARRY DATES AND THEY ARE NOT USED. Each reads "Elected: YYYY"
-- and "Current Term Ends: MM/DD/YYYY". The Coroner's says "Elected: 2020 / Current Term Ends:
-- 12/31/2028" while the certified results show him winning in 2023, which on a four-year term ends
-- 12/31/2027 — the two cannot both be right. The Circuit Clerk's says "Elected: 2024" for a man who
-- won in November 2023. ▶ "First elected" is not a term start and these fields mean neither
-- consistently. They are excellent evidence of CURRENT INCUMBENCY, which is what they are used for,
-- and they are not used as dates.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 CURRENCY CHECKED PERSON BY PERSON, because a certified 2023 result is a fact about an
-- election and not about who holds the seat in 2026:
--   * the five supervisors — the county's Board page names the same five with the same districts,
--     and the GIS layer's own DIST_NAME field names them too;
--   * Chancery Clerk Angela Thrash — named on her own office's site, and in attendance as
--     "Chancery Clerk and Ex-Officio Clerk of the Board" in the 2024-01-02 minutes;
--   * Sheriff Matt Haley — named on the Sheriff's Office's own site;
--   * Coroner, County Prosecuting Attorney, Tax Assessor, Tax Collector, Circuit Clerk — each named
--     on their own page of the county site;
--   * the five election commissioners — the county's Election Commission page.
--
-- 🟢 THE NAMESAKE SWEEP FOUND TWO, AND BOTH ARE DIFFERENT PEOPLE. Measured on the guard's own key
-- with controls that fire (73 active Smiths, 53 Joneses, 3 existing Ladners):
--   * James Morgan — an inactive `indiana_discovery` row with no office. ⚠ Checked rather than
--     assumed: no office and is_incumbent=false is exactly the shape MI-2 reused for four sitting
--     legislators and then found hidden.
--   * Jennifer Smith — a sitting Santa Monica-Malibu Unified school board member in California.
-- 🔴 FOUR LADNERS ARE SEATED BY THIS MIGRATION AND THEY ARE FOUR DIFFERENT PEOPLE — Marlin R.
-- (Supervisor 3), Paula (Tax Assessor), Brandon (Justice Court 2) and Dianne (Justice Court 3) —
-- beside the three Ladners already in production, one of whom, Philman A. Ladner, MS-2 seated in
-- Senate District 46. Ladner is a Gulf Coast surname; a surname-keyed merge would collapse seven
-- people into one.
--
-- ⚠ TWO NAMES ARE SPLIT ON A JUDGEMENT AND IT IS WRITTEN DOWN. "Sharon Nash Barnett" is stored with
-- last_name 'Barnett' and "Nash" read as a middle name, the way the county's own page and the
-- ballot both render it; and "Toni Jo Diaz" with first_name 'Toni'. MS-2's rule is that a compound
-- surname is decided by a second publisher, and no second publisher was found for either — so these
-- are the most likely reading, not a proved one.
--
-- 🟢 TWO OF THESE JUDGES ALREADY APPEAR IN THIS SLICE'S OWN SOURCES. Justice Court Judge Nick Patano
-- administered the oath to Biloxi's mayor in 2021 and 2025, and Justice Court Judge Albert J.
-- Fountain did so in 2017 — both recorded in MS-3's research. The county's judges swear in the
-- county's mayors, and the programme now holds both ends of that.
--
-- 🔴 is_incumbent IS SET EXPLICITLY. It defaults to false since CA_0188, and a seated person
-- inserted without it is HIDDEN from address search.
--
-- 🔴 PARTY IS NOT WRITTEN, though the certified results give it for all 27.
--
-- 🟢 THE RESERVED external_id BAND IS -2766435 .. -2766409 (27 ids), ASCENDING, MEASURED EMPTY
-- 2026-09-28 — with a control, because MS-2 checked a band it did not use: the same query reports
-- 8 occupants for MS-3's band (-2766408 .. -2766401). The band below is the one the INSERT uses and
-- the one the gate asserts.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the 27 offices must exist ────────────────────────────────

DO $$
DECLARE v_off int;
BEGIN
  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US';
  IF v_off <> 27 THEN
    RAISE EXCEPTION 'MS-4 occupancy pre-flight: expected 27 Harrison County offices from CC_0173, found %', v_off;
  END IF;
END $$;

-- ─── 1. The twenty-seven people ──────────────────────────────────────────────

CREATE TEMP TABLE hc_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO hc_people(external_id, full_name, first_name, last_name) VALUES
  (-2766435::bigint, 'Dan Cuevas',             'Dan',       'Cuevas'),
  (-2766434::bigint, 'Rebecca Powers',         'Rebecca',   'Powers'),
  (-2766433::bigint, 'Marlin R. Ladner',       'Marlin',    'Ladner'),
  (-2766432::bigint, 'Kent Jones',             'Kent',      'Jones'),
  (-2766431::bigint, 'Nathan Barrett',         'Nathan',    'Barrett'),
  (-2766430::bigint, 'Angela Thrash',          'Angela',    'Thrash'),
  (-2766429::bigint, 'Justin W. Wetzel',       'Justin',    'Wetzel'),
  (-2766428::bigint, 'Brian Switzer',          'Brian',     'Switzer'),
  (-2766427::bigint, 'Herman F. Cox',          'Herman',    'Cox'),
  (-2766426::bigint, 'Matt Haley',             'Matt',      'Haley'),
  (-2766425::bigint, 'Paula Ladner',           'Paula',     'Ladner'),
  (-2766424::bigint, 'Sharon Nash Barnett',    'Sharon',    'Barnett'),
  (-2766423::bigint, 'Albert J. Fountain',     'Albert',    'Fountain'),
  (-2766422::bigint, 'Brandon Ladner',         'Brandon',   'Ladner'),
  (-2766421::bigint, 'Dianne Ladner',          'Dianne',    'Ladner'),
  (-2766420::bigint, 'Theressia A. Lyons',     'Theressia', 'Lyons'),
  (-2766419::bigint, 'Nick Patano',            'Nick',      'Patano'),
  (-2766418::bigint, 'James Morgan',           'James',     'Morgan'),
  (-2766417::bigint, 'Angel Kibler-Middleton', 'Angel',     'Kibler-Middleton'),
  (-2766416::bigint, 'Alan Weatherford',       'Alan',      'Weatherford'),
  (-2766415::bigint, 'Sammie Taylor',          'Sammie',    'Taylor'),
  (-2766414::bigint, 'Jeff Migues',            'Jeff',      'Migues'),
  (-2766413::bigint, 'Toni Jo Diaz',           'Toni',      'Diaz'),
  (-2766412::bigint, 'Becky Payne',            'Becky',     'Payne'),
  (-2766411::bigint, 'Jennifer Smith',         'Jennifer',  'Smith'),
  (-2766410::bigint, 'Christene F. Brice',     'Christene', 'Brice'),
  (-2766409::bigint, 'Carolyn Handler',        'Carolyn',   'Handler');

-- 🔴 THE DUPLICATE-NAME GUARD IS LIFTED FOR ONE ROW, NOT FOR THIS MIGRATION.
-- Exactly one incoming name collides with an ACTIVE row: Jennifer Smith, Election Commissioner for
-- District 3, against a sitting Santa Monica-Malibu Unified school board member in California
-- (CA_0148). Checked, not assumed. The other twenty-six insert with the guard armed, so a collision
-- introduced by a later edit to this list would still stop the migration.
-- ⚠ James Morgan collides too and does NOT trip the guard, because the existing row is INACTIVE and
-- the guard only sees active rows. That row is an `indiana_discovery` stub with no office — the
-- shape MI-2 reused for four sitting legislators and then found hidden — so it was read rather than
-- waved through. It is a different man.

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Harrison County, Mississippi — roster from the Mississippi Secretary of State''s Official Recapitulation for the 2023 General Election in Harrison County (certified by the County Election Commission 2023-11-17), except the five Election Commissioners, who come from the county''s own Election Commission page; current incumbency re-checked officer by officer against each office''s own page, the Sheriff''s and Chancery Clerk''s own sites, the county Board page and the county GIS layer''s DIST_NAME field; read 2026-09-28 (CC_0174, MS-4)',
       true, true
FROM hc_people n
WHERE n.external_id <> -2766411
  AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'on';

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Harrison County, Mississippi — Election Commissioner, District 3, from the county''s own Election Commission page. ⚠ A DIFFERENT PERSON from the Jennifer Smith already in production, who is a sitting Santa Monica-Malibu Unified school board member in California (CA_0148); the duplicate-name guard is lifted for this row alone. Read 2026-09-28 (CC_0174, MS-4)',
       true, true
FROM hc_people n
WHERE n.external_id = -2766411
  AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 2. The twenty-seven terms ───────────────────────────────────────────────
-- 🔴 Keyed on the office TITLE, which CC_0173's gate has just asserted is distinct across all 27.
-- Four offices share each supervisor district, so a district-keyed join would fan out four ways.

CREATE TEMP TABLE hc_terms(
  title text, external_id bigint, term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO hc_terms(title, external_id, term_start, start_precision, how_started) VALUES
  -- The five supervisors, dated to the day by the Board's own organising minute.
  ('Supervisor, District 1',            -2766435::bigint, '2024-01-02'::date, 'day',     'elected'),
  ('Supervisor, District 2',            -2766434::bigint, '2024-01-02'::date, 'day',     'elected'),
  ('Supervisor, District 3',            -2766433::bigint, '2024-01-02'::date, 'day',     'elected'),
  ('Supervisor, District 4',            -2766432::bigint, '2024-01-02'::date, 'day',     'elected'),
  ('Supervisor, District 5',            -2766431::bigint, '2024-01-02'::date, 'day',     'elected'),
  -- The seven countywide officers, certified winners of November 2023, four-year term from 2024.
  ('Chancery Clerk',                    -2766430::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Circuit Clerk',                     -2766429::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Coroner',                           -2766428::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('County Prosecuting Attorney',       -2766427::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Sheriff',                           -2766426::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Tax Assessor',                      -2766425::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Tax Collector',                     -2766424::bigint, '2024-01-01'::date, 'year',    'elected'),
  -- The five justice court judges.
  ('Justice Court Judge, District 1',   -2766423::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Justice Court Judge, District 2',   -2766422::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Justice Court Judge, District 3',   -2766421::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Justice Court Judge, District 4',   -2766420::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Justice Court Judge, District 5',   -2766419::bigint, '2024-01-01'::date, 'year',    'elected'),
  -- The five constables.
  ('Constable, District 1',             -2766418::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Constable, District 2',             -2766417::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Constable, District 3',             -2766416::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Constable, District 4',             -2766415::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Constable, District 5',             -2766414::bigint, '2024-01-01'::date, 'year',    'elected'),
  -- 🔴 The election commission splits. Districts 2 and 4 were on the 2023 ballot; 1, 3 and 5 were
  -- not, and nothing read for this wave says when they arrived.
  ('Election Commissioner, District 1', -2766413::bigint, NULL,               'unknown', 'unknown'),
  ('Election Commissioner, District 2', -2766412::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Election Commissioner, District 3', -2766411::bigint, NULL,               'unknown', 'unknown'),
  ('Election Commissioner, District 4', -2766410::bigint, '2024-01-01'::date, 'year',    'elected'),
  ('Election Commissioner, District 5', -2766409::bigint, NULL,               'unknown', 'unknown');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       'Harrison County, Mississippi — the five supervisors are dated to the day from the Board of Supervisors'' own organising minutes of 2024-01-02, which record the members-elect by district "for the term of four years commencing on this date", the meeting having moved from the statutory first Monday because 1 January 2024 was a legal holiday; the other nineteen dated officers are certified winners of the general election of 2023-11-07 taking a four-year term from January 2024, written at year precision because no document read for this wave records the day each was sworn; Election Commissioners for Districts 1, 3 and 5 were not on that ballot and their arrival is honestly unknown. Read 2026-09-28 (CC_0174, MS-4)'
FROM hc_terms t
JOIN essentials.governments g ON g.name = 'Harrison County, Mississippi, US'
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = t.title
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people  int;
  v_terms   int;
  v_seated  int;
  v_day     int;
  v_year    int;
  v_unknown int;
  v_noninc  int;
  v_perdist int;
  v_dupe    int;
  v_sup     date;
  v_ec      int;
  v_biloxi  int;
  v_leg     int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2766435 AND -2766409;
  IF v_people <> 27 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate: expected 27 people in the reserved band, got %', v_people;
  END IF;

  -- 🔴 Count och.politician_id, NOT *: office_current_holder LEFT JOINs from offices, so a vacancy
  -- is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Harrison County, Mississippi, US';
  IF v_seated <> 27 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate: expected 27 seated Harrison County offices, found %', v_seated;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US';
  IF v_terms <> 27 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate: expected 27 Harrison County terms, found %', v_terms;
  END IF;

  -- 🟢 5 day, 19 year, 3 honestly unknown. Asserted so that a later pass cannot quietly promote the
  -- three unknown election commissioners to 2024 by copying their colleagues.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'day'     AND ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.start_precision = 'year'    AND ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.start_precision = 'unknown' AND ot.term_start IS NULL)
    INTO v_day, v_year, v_unknown
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US';
  IF v_day <> 5 OR v_year <> 19 OR v_unknown <> 3 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate: expected 5 day / 19 year / 3 unknown terms, found % / % / %', v_day, v_year, v_unknown;
  END IF;

  -- 🔴 THE SUPERVISORS' DATE ASSERTED DIRECTLY, because 2024-01-01 is what a reasonable person
  -- would "correct" it to, and the holiday is the whole reason it is wrong.
  SELECT min(ot.term_start) INTO v_sup
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US'
     AND c.name = 'Harrison County Board of Supervisors';
  IF v_sup IS DISTINCT FROM '2024-01-02'::date THEN
    RAISE EXCEPTION 'MS-4 occupancy gate: supervisor term_start is %, expected 2024-01-02 (the first Monday of January 2024 was a legal holiday)', v_sup;
  END IF;

  -- 🔴 AND THE THREE UNDATED ELECTION COMMISSIONERS ASSERTED BY DISTRICT, so that the split cannot
  -- drift onto the wrong three.
  SELECT count(*) INTO v_ec
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Harrison County, Mississippi, US'
     AND c.name = 'Harrison County Election Commission'
     AND o.title IN ('Election Commissioner, District 1', 'Election Commissioner, District 3', 'Election Commissioner, District 5')
     AND ot.start_precision = 'unknown' AND ot.term_start IS NULL;
  IF v_ec <> 3 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate: expected Election Commissioners 1, 3 and 5 undated, found % of 3', v_ec;
  END IF;

  SELECT count(*) INTO v_noninc FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2766435 AND -2766409
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate: % Harrison County official(s) are not is_incumbent/is_active', v_noninc;
  END IF;

  -- 🔴 Each supervisor district must hold FOUR DISTINCT people. Four terms on one person would pass
  -- a count of 20.
  SELECT count(*) INTO v_perdist
    FROM essentials.districts d
   WHERE d.mtfcc = 'X0074' AND lower(d.state) = 'ms'
     AND (SELECT count(DISTINCT ot.politician_id)
            FROM essentials.offices o
            JOIN essentials.office_terms ot ON ot.office_id = o.id
           WHERE o.district_id = d.id) <> 4;
  IF v_perdist <> 0 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate: % supervisor district(s) do not hold 4 DISTINCT people', v_perdist;
  END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT ot.politician_id
      FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Harrison County, Mississippi, US'
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate: % person(s) hold more than one Harrison County office', v_dupe;
  END IF;

  -- 🔴 CONTROLS, IN THE SAME TRANSACTION.
  SELECT count(och.politician_id) INTO v_biloxi
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Biloxi, Mississippi, US';
  IF v_biloxi <> 8 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate CONTROL: expected 8 seated Biloxi offices from MS-3, found %', v_biloxi;
  END IF;

  SELECT count(och.politician_id) INTO v_leg
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc IN ('G5210', 'G5220') AND lower(d.state) = 'ms';
  IF v_leg <> 174 THEN
    RAISE EXCEPTION 'MS-4 occupancy gate CONTROL: expected 174 seated Mississippi legislative offices from MS-2, found %', v_leg;
  END IF;

  RAISE NOTICE 'MS-4 occupancy gate PASSED: 27 people, 27 terms, 27 seated, 0 vacant, 5 day-precision (supervisors at 2024-01-02) + 19 year + 3 honestly unknown, 4 distinct people on each supervisor district; Biloxi 8 and the MS legislature 174 unmoved.';
END $$;

COMMIT;
