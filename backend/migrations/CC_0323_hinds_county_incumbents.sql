-- CC_0323_hinds_county_incumbents.sql
-- Hinds County, Mississippi deep seed (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0322, which creates the government, chambers, districts and offices.
--
-- Creates 28 people and 28 office_terms.
-- Record: backend/data/seed-jackson-ms-2026/ROSTERS.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT, AND THIS WAVE PROVES IT AGAIN.
--
-- The certified 2023 general gives the winners. The county's own published phone book gives who is
-- there NOW. They agree on 26 of 27 and DISAGREE ON THE CORONER:
--
--   certified 2023 winner   Sharon Grisham-Stewart
--   county phone book       Howard
--
-- 🟢 THE BOARD'S OWN MINUTE SETTLES BOTH THE FACT AND THE SPELLING. Minutes of 2024-12-02:
--   "Appoint JEREMIAH HOWARD Interim Coroner, Effective January 1, 2025"
--   "RESOLVED to approve Appointing Jeremiah Howard Interim Coroner"
-- Grisham-Stewart retired at the end of 2024 after 25 years; Howard was appointed interim from
-- 2025-01-01 and then won the special election of 2025-12-02 for the remainder of the term.
--   ▶ office_terms records a SEAT, not an election, so his tenure is ONE OPEN TERM from 2025-01-01,
--     and how_started is 'appointed', because that is how this tenure began.
--   ⚠ THREE SPELLINGS ARE IN CIRCULATION -- "Jeremiah" (the Board's own resolution), "Jermiah"
--     (the county phone book) and "Jeramiah" (press). THE FORMAL RESOLUTION IS TAKEN AS THE
--     AUTHORITY and the disagreement is written down rather than silently resolved.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE DATES ARE 'year' PRECISION, AND HINDS IS NOT HARRISON ABOUT THIS.
--
-- Mississippi seats county officers on the first Monday of January. 2024-01-01 was New Year's Day,
-- a legal holiday, and the Hinds Board's first meeting of the term was TUESDAY 2024-01-02 -- the
-- same shift MS-4 found in Harrison, where the Board's minute said so explicitly:
--   Harrison: "...on the FIRST TUESDAY OF JANUARY 2024, being January 2, 2024, the first Monday of
--              January 2024 being a legal holiday ... for the term of four years COMMENCING ON
--              THIS DATE..."
--
-- 🔴 HINDS'S MINUTE CARRIES NO SUCH RECITAL. It records that the Board met on 2024-01-02 under
-- Miss. Code s 19-3-13, elected Robert Graham president and Wanda Evers vice-president, and
-- resolved "to approve the Bonds of the Board of Supervisors for the four-year term ... per Section
-- 25-1-19". That proves they HELD OFFICE on 2024-01-02. It does not state when the term BEGAN.
--   ▶ So the day is NOT written. Borrowing Harrison's recital for a county it does not mention is
--     exactly what MS-4 refused to do for its own 19 undated officers, and computing the statutory
--     day is what the holiday shift exists to warn against. All 2023-elected officers are written
--     at 2024-01-01 with start_precision => 'year'.
--
-- 🔴 AND THREE ELECTION COMMISSIONERS ARE WRITTEN WITH NO DATE AT ALL. Only Districts 2 and 4 were
-- on the 2023 ballot. Districts 1, 3 and 5 are named by the county's own phone book -- that is
-- evidence of INCUMBENCY, not of arrival. MS-4's rule, in its own words: "Do not copy 2024 onto
-- them from their two colleagues." They get an open-ended term with start_precision => 'unknown'.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 is_incumbent IS SET EXPLICITLY on every insert. It defaults to false since CA_0188, and a
-- seated person inserted without it is HIDDEN from address search.
--
-- 🟢 NO NAMESAKE COLLISION, measured on the guard's own key (first_name, last_name) for all 28,
-- active and archived: zero. The query was controlled first -- the same shape finds 53 Browns and
-- 89 Smiths -- so the zero is the data, not a blind detector.
--
-- 🟢 THE RESERVED external_id BAND IS -2767100 .. -2767073 (28 ids), ASCENDING, MEASURED EMPTY in
-- the same session as the write. The gate asserts against the same band.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_off  int;
  v_band int;
  v_term int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US';
  IF v_off <> 28 THEN
    RAISE EXCEPTION 'Hinds occupancy pre-flight: expected 28 offices from CC_0322, found % — apply the structure half first', v_off;
  END IF;

  SELECT count(*) INTO v_band FROM essentials.politicians
   WHERE external_id BETWEEN -2767100 AND -2767073;
  IF v_band <> 0 THEN
    RAISE EXCEPTION 'Hinds occupancy pre-flight: external_id band -2767100..-2767073 already holds % row(s)', v_band;
  END IF;

  SELECT count(*) INTO v_term FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US';
  IF v_term <> 0 THEN
    RAISE EXCEPTION 'Hinds occupancy pre-flight: Hinds offices already carry % term(s)', v_term;
  END IF;
END $$;

-- ─── 1. Twenty-eight people ──────────────────────────────────────────────────

CREATE TEMP TABLE hc_people(
  external_id bigint, full_name text, first_name text, last_name text,
  preferred_name text, name_suffix text, title text
) ON COMMIT DROP;

INSERT INTO hc_people(external_id, full_name, first_name, last_name, preferred_name, name_suffix, title) VALUES
  -- countywide
  (-2767100, 'Eddie Jean Carr',        'Eddie',    'Carr',           NULL,     NULL,  'Chancery Clerk'),
  (-2767099, 'Zack Wallace',           'Zack',     'Wallace',        NULL,     NULL,  'Circuit Clerk'),
  (-2767098, 'Jeremiah Howard',        'Jeremiah', 'Howard',         NULL,     NULL,  'Coroner'),
  (-2767097, 'Gerald A. Mumford',      'Gerald',   'Mumford',        NULL,     NULL,  'County Attorney'),
  (-2767096, 'Jeffrey Maurice Lewis',  'Jeffrey',  'Lewis',          NULL,     NULL,  'County Surveyor'),
  (-2767095, 'Tyree D. Jones',         'Tyree',    'Jones',          NULL,     NULL,  'Sheriff'),
  (-2767094, 'Charles E. Stokes',      'Charles',  'Stokes',         NULL,     NULL,  'Tax Assessor'),
  (-2767093, 'Eddie J. Fair',          'Eddie',    'Fair',           NULL,     NULL,  'Tax Collector'),
  -- supervisors
  (-2767092, 'Robert Graham',          'Robert',   'Graham',         NULL,     NULL,  'Supervisor, District 1'),
  (-2767091, 'Anthony Smith',          'Anthony',  'Smith',          'Tony',   NULL,  'Supervisor, District 2'),
  (-2767090, 'Deborah Butler Dixon',   'Deborah',  'Dixon',          NULL,     NULL,  'Supervisor, District 3'),
  (-2767089, 'Wanda Evers',            'Wanda',    'Evers',          NULL,     NULL,  'Supervisor, District 4'),
  (-2767088, 'Bobby McGowan',          'Bobby',    'McGowan',        'Bobcat', NULL,  'Supervisor, District 5'),
  -- justice court judges
  (-2767087, 'Don Palmer',             'Don',      'Palmer',         NULL,     NULL,  'Justice Court Judge, District 1'),
  (-2767086, 'Tabitha Britton-Porter', 'Tabitha',  'Britton-Porter', NULL,     NULL,  'Justice Court Judge, District 2'),
  (-2767085, 'Frank L. Sutton, Sr.',   'Frank',    'Sutton',         NULL,     'Sr.', 'Justice Court Judge, District 3'),
  (-2767084, 'Kenny W. Lewis',         'Kenny',    'Lewis',          NULL,     NULL,  'Justice Court Judge, District 4'),
  (-2767083, 'Pearlie Brown Owens',    'Pearlie',  'Owens',          NULL,     NULL,  'Justice Court Judge, District 5'),
  -- constables
  (-2767082, 'Jerry Moore',            'Jerry',    'Moore',          NULL,     NULL,  'Constable, District 1'),
  (-2767081, 'John Brown',             'John',     'Brown',          NULL,     NULL,  'Constable, District 2'),
  (-2767080, 'Lawrence Funchess',      'Lawrence', 'Funchess',       NULL,     NULL,  'Constable, District 3'),
  (-2767079, 'Leon Seals',             'Leon',     'Seals',          NULL,     NULL,  'Constable, District 4'),
  (-2767078, 'Beverly Wade-Green',     'Beverly',  'Wade-Green',     NULL,     NULL,  'Constable, District 5'),
  -- election commissioners
  (-2767077, 'Kidada Brown',           'Kidada',   'Brown',          NULL,     NULL,  'Election Commissioner, District 1'),
  (-2767076, 'Bobbie McClure Graves',  'Bobbie',   'Graves',         NULL,     NULL,  'Election Commissioner, District 2'),
  (-2767075, 'Jermal Clark',           'Jermal',   'Clark',          NULL,     NULL,  'Election Commissioner, District 3'),
  (-2767074, 'Yvonne R. Horton',       'Yvonne',   'Horton',         NULL,     NULL,  'Election Commissioner, District 4'),
  (-2767073, 'Felicia McClinton',      'Felicia',  'McClinton',      NULL,     NULL,  'Election Commissioner, District 5');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.name_suffix,
       'Hinds County, Mississippi — certified 2023 General Election results published by the county (Summary Results Report, Official Election Results, November 7, 2023), reconciled against the county''s own published phone book for current incumbency; the Coroner from the Board of Supervisors'' minutes of 2024-12-02; read 2026-10-31 (CC_0323)',
       true, true
FROM hc_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Twenty-eight terms ───────────────────────────────────────────────────
-- 🔴 Election Commissioners 1, 3 and 5 get a NULL term_start with 'unknown' precision. A phone book
-- proves incumbency, not arrival.

CREATE TEMP TABLE hc_terms(external_id bigint, term_start date, start_precision text, how_started text) ON COMMIT DROP;
INSERT INTO hc_terms(external_id, term_start, start_precision, how_started)
SELECT p.external_id,
       CASE WHEN p.external_id = -2767098 THEN DATE '2025-01-01'
            WHEN p.external_id IN (-2767077, -2767075, -2767073) THEN NULL
            ELSE DATE '2024-01-01' END,
       CASE WHEN p.external_id = -2767098 THEN 'day'
            WHEN p.external_id IN (-2767077, -2767075, -2767073) THEN 'unknown'
            ELSE 'year' END,
       CASE WHEN p.external_id = -2767098 THEN 'appointed' ELSE 'elected' END
FROM hc_people p;

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       CASE WHEN t.external_id = -2767098
            THEN 'Hinds County Board of Supervisors, minutes of 2024-12-02: "Appoint Jeremiah Howard Interim Coroner, Effective January 1, 2025"; he then won the special election of 2025-12-02 for the remainder of the term (CC_0323)'
            WHEN t.start_precision = 'unknown'
            THEN 'Hinds County published phone book names this commissioner in office; the seat was NOT on the certified 2023 ballot, so the arrival date is not established and is deliberately left NULL (CC_0323)'
            ELSE 'Hinds County certified 2023 General Election results (November 7, 2023). The Board''s organising minute of 2024-01-02 records the new Board meeting and approving bonds "for the four-year term" but carries NO recital of when the term began, so the day is NOT written (CC_0323)'
       END
FROM hc_terms t
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN hc_people n ON n.external_id = t.external_id
JOIN essentials.chambers c ON c.name IN (
  'Hinds County Board of Supervisors','Hinds County Constables','Hinds County Elected Officials',
  'Hinds County Election Commission','Hinds County Justice Court')
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'Hinds County, Mississippi, US'
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = n.title
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people  int;
  v_terms   int;
  v_seated  int;
  v_year    int;
  v_day     int;
  v_unknown int;
  v_noninc  int;
  v_open    int;
  v_cor     date;
  v_corhow  text;
  v_perdis  int;
  v_leg     int;
  v_harr    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2767100 AND -2767073;
  IF v_people <> 28 THEN RAISE EXCEPTION 'Hinds occupancy gate: expected 28 people in the band, found %', v_people; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US';
  IF v_terms <> 28 THEN RAISE EXCEPTION 'Hinds occupancy gate: expected 28 terms, found %', v_terms; END IF;

  -- 🔴 COUNT THE HOLDER COLUMN, NOT THE ROWS. office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Hinds County, Mississippi, US';
  IF v_seated <> 28 THEN
    RAISE EXCEPTION 'Hinds occupancy gate: expected 28 SEATED offices, found % (counting och.politician_id)', v_seated;
  END IF;

  SELECT count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown')
    INTO v_year, v_day, v_unknown
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US';
  IF v_year <> 24 OR v_day <> 1 OR v_unknown <> 3 THEN
    RAISE EXCEPTION 'Hinds occupancy gate: expected 24 year / 1 day / 3 unknown precision, found % / % / %', v_year, v_day, v_unknown;
  END IF;

  -- 🔴 The three undated commissioners must carry a NULL term_start, not a borrowed 2024.
  IF EXISTS (
    SELECT 1 FROM essentials.office_terms ot
     WHERE ot.start_precision = 'unknown' AND ot.term_start IS NOT NULL
       AND ot.office_id IN (SELECT o.id FROM essentials.offices o
                             JOIN essentials.chambers c ON c.id = o.chamber_id
                             JOIN essentials.governments g ON g.id = c.government_id
                            WHERE g.name = 'Hinds County, Mississippi, US')
  ) THEN
    RAISE EXCEPTION 'Hinds occupancy gate: an unknown-precision term carries a date — do not copy 2024 onto an undated commissioner';
  END IF;

  SELECT ot.term_start, ot.how_started INTO v_cor, v_corhow
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US' AND o.title = 'Coroner';
  IF v_cor <> DATE '2025-01-01' OR v_corhow <> 'appointed' THEN
    RAISE EXCEPTION 'Hinds occupancy gate: Coroner term is %/% — the Board''s minute says appointed effective 2025-01-01', v_cor, v_corhow;
  END IF;

  SELECT count(*) INTO v_noninc FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2767100 AND -2767073
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'Hinds occupancy gate: % official(s) are not is_incumbent/is_active — they would be hidden from address search', v_noninc;
  END IF;

  SELECT count(*) INTO v_open FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Hinds County, Mississippi, US' AND ot.term_end IS NOT NULL;
  IF v_open <> 0 THEN RAISE EXCEPTION 'Hinds occupancy gate: % term(s) are closed — all 28 are sitting', v_open; END IF;

  -- 🔴 FOUR SEATED HOLDERS PER SUPERVISOR DISTRICT, asserted per district.
  SELECT count(*) INTO v_perdis FROM essentials.districts d
   WHERE d.mtfcc = 'G4040' AND lower(d.state) = 'ms'
     AND d.geo_id IN ('2804990225','2804990963','2804991701','2804992439','2804993177')
     AND (SELECT count(och.politician_id) FROM essentials.offices o
            LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
           WHERE o.district_id = d.id) <> 4;
  IF v_perdis <> 0 THEN
    RAISE EXCEPTION 'Hinds occupancy gate: % supervisor district(s) do not have exactly 4 seated holders', v_perdis;
  END IF;

  SELECT count(och.politician_id) INTO v_leg FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc IN ('G5210','G5220') AND lower(d.state) = 'ms';
  IF v_leg <> 174 THEN RAISE EXCEPTION 'Hinds occupancy gate CONTROL: expected 174 seated MS legislative offices, found %', v_leg; END IF;

  SELECT count(och.politician_id) INTO v_harr FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Harrison County, Mississippi, US';
  IF v_harr <> 27 THEN RAISE EXCEPTION 'Hinds occupancy gate CONTROL: expected 27 seated Harrison offices, found %', v_harr; END IF;

  RAISE NOTICE 'Hinds occupancy gate PASSED: 28 people, 28 open terms, 28 seated (counted on the holder column), 24 year + 1 day + 3 unknown precision, the three undated commissioners carry NULL, Coroner appointed 2025-01-01, 4 holders per supervisor district, all is_incumbent; 174 MS legislative and 27 Harrison seats unmoved.';
END $$;

COMMIT;
