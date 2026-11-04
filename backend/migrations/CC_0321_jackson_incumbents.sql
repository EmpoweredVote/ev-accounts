-- CC_0321_jackson_incumbents.sql
-- Jackson, Mississippi deep seed (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0320, which creates the government, chambers, districts and offices.
--
-- Creates 8 people and 8 office_terms: the Mayor and one Council Member per ward.
-- Record: backend/data/seed-jackson-ms-2026/ROSTERS.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE COUNCIL'S OWN MINUTES BIND EVERY MEMBER TO A WARD, AND THEY DATE THE TRANSITION.
--
-- The city publishes its council minutes as PDFs (34 dated files, 2025-01-14 .. 2025-12-30; a
-- bogus filename returns a real HTTP 404, which is the control). Two meetings straddle the 2025
-- transition and each opens with a roll of members BY WARD:
--
--   2025-06-17 regular (outgoing)        2025-07-08 special (incoming)
--   Mayor  Chokwe Antar Lumumba          Mayor  John A. Horhn
--   W1 Ashby Foote                       W1 Ashby Foote
--   W2 Montyne Clay                      W2 Montyne Clay
--   W3 Kenneth Stokes                    W3 Kenneth Stokes
--   W4 Brian Grizzell                    W4 Brian Grizzell
--   W5 Vernon Hartley                    W5 Vernon Hartley
--   W6 Aaron Banks                       W6 Lashia Brown-Thomas
--   W7 Virgi Lindsay                     W7 Kevin Parkinson
--
-- ▶ So the 2025 election changed the mayoralty and EXACTLY TWO WARDS. Five members continue.
-- That is a structural fact from a primary document, and every date below is checked against it.
-- The 2025-07-08 meeting is the organisational one: it elected Grizzell president and Hartley
-- vice president under MCA s 21-8-11 and Jackson Code of Ordinances s 2-37.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE DATES, AND WHY BALLOTPEDIA IS USABLE HERE.
--
-- The Municipal Clerk's own results page states: "Horhn began his term on July 1, 2025." That is a
-- statement about TAKING OFFICE -- not an election result, not an advertised ceremony -- which is
-- what the programme's oath-date rule asks for. Ballotpedia independently gives Horhn 2025-07-01.
-- TWO SOURCES AGREE ON THE ONE DATE THAT CAN BE CHECKED, which is what licenses using Ballotpedia
-- for the other seven.
--
-- 🟢 AND THE DATES AGREE WITH THE MINUTES ON THE ONLY THING THE MINUTES CAN SETTLE: the three
-- dated 2025-07-01 are exactly the three seats the roll call shows changing hands, and the five
-- dated earlier are exactly the five members present at BOTH meetings. A date and a roll call are
-- different kinds of fact, and they corroborate.
--
-- 🔴 BALLOTPEDIA IS AN AGGREGATOR AND WAS TREATED AS ONE. scripts/verify-jackson-roster-dates.mjs
-- asserts, from each page's OWN TEXT, that it names Jackson, Mississippi and the exact ward, and
-- reports any page saying "was appointed" -- because BP publishes APPOINTED and ASSUMED OFFICE and
-- ONLY THE SECOND IS A term_start. All eight pass; none mentions an appointment.
--   ⚠ Ward 2 has NO page under "Tina Clay" (404). It is under "Montyne_Clay". THE USED NAME IS NOT
--     THE PAGE NAME, and the 404 nearly recorded a missing date that exists.
--
-- 🔴 FOOTE AND STOKES ARE 'year' PRECISION AND MUST STAY THAT WAY. Ballotpedia gives both a bare
-- year, and their own pages give FIRST ELECTED statements -- Foote "In 2014, Ashby ran for and was
-- elected as Councilman for Ward I", Stokes "In 1989, he was elected to the Jackson [City
-- Council]". "FIRST ELECTED" IS NOT A TERM START, and Stokes served on the Hinds County Board of
-- Supervisors in between, so his service is explicitly not continuous from 1989. Promoting either
-- to a day needs an oath record and nothing else will do.
--
-- 🔴 WARD 2 IS DATED 2024-11-01, NOT 2025. There was a Ward 2 SPECIAL ELECTION on 2024-10-01 --
-- the Municipal Clerk's notice of 2024-08-19: "The Jackson City Council has declared the Ward 2
-- City Council seat vacant, thereby requiring a Special Election to be held October 1, 2024."
-- Clay is present in the 2025-06-17 minutes, so she held the seat before the 2025 general.
-- office_terms records a SEAT, not an election: dating her from 2025 would erase a real tenure,
-- which is the mirror of MS-2's Chris Johnson rule and what MS-3 avoided for Biloxi's Ward 7.
--
-- ⚠ BILOXI AND JACKSON TOOK OFFICE ON DIFFERENT DAYS IN THE SAME STATE -- Biloxi's 2025 cohort is
-- dated 2025-06-30 from its own inaugural record, Jackson's mayor 2025-07-01 from his. DO NOT
-- RECONCILE THEM. Each is that city's own statement, and Mississippi has already produced three
-- variants of the oath-date failure inside one slice: an oath two days before the advertised
-- ceremony (Biloxi's mayor), a ceremony announced and never reported (Biloxi Ward 7), and a
-- statutory day that moved for a holiday (Harrison County).
--
-- ⚠ THERE IS NO MINUTED OATH. The minutes jump from 2025-06-17 to 2025-07-08, so no meeting on or
-- near 1 July is recorded. The city holds swearing-in photographs (MayorCouncilSwearingIN-*) but
-- they were uploaded in 2026-02, and AN UPLOAD DATE IS NOT AN EVENT DATE.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 is_incumbent IS SET EXPLICITLY. It defaults to false since CA_0188, and a seated person
-- inserted without it is HIDDEN from address search. check:occupancy fails an INSERT that omits it.
--
-- 🟢 NO NAMESAKE COLLISION, MEASURED ON THE GUARD'S OWN KEY (first_name, last_name): all eight
-- pairs return ZERO existing rows, active or archived. The query was controlled first -- the same
-- shape finds 87 active Smiths, 81 Johnsons and MS-2's Scott DeLano -- so the zero is real.
--   ⚠ The guard is blind to a full_name split differently, so surnames were swept too: 2 Clays
--     (an LA County Superior Court judge and an inactive indiana_discovery stub), 2 Parkinsons
--     (a Tennessee Representative and the San Luis Obispo County Sheriff-Coroner) and 32 Thomases.
--     EVERY ROW WAS READ. None is one of these eight. No guard lift is needed.
--
-- 🟢 THE RESERVED external_id BAND IS -2767000 .. -2766993 (8 ids), ASCENDING, MEASURED EMPTY in
-- the same session as the write. 🔴 ND-2's rule: RE-CHECK THE BAND YOU USE -- a generator that
-- decremented once put the real ids outside the band that had been checked. The gate below asserts
-- against this same band.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_off  int;
  v_band int;
  v_term int;
BEGIN
  SELECT count(*) INTO v_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US';
  IF v_off <> 8 THEN
    RAISE EXCEPTION 'Jackson occupancy pre-flight: expected 8 offices from CC_0320, found % — apply the structure half first', v_off;
  END IF;

  SELECT count(*) INTO v_band FROM essentials.politicians
   WHERE external_id BETWEEN -2767000 AND -2766993;
  IF v_band <> 0 THEN
    RAISE EXCEPTION 'Jackson occupancy pre-flight: external_id band -2767000..-2766993 already holds % row(s)', v_band;
  END IF;

  SELECT count(*) INTO v_term
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US';
  IF v_term <> 0 THEN
    RAISE EXCEPTION 'Jackson occupancy pre-flight: Jackson offices already carry % term(s)', v_term;
  END IF;
END $$;

-- ─── 1. Eight people ─────────────────────────────────────────────────────────
-- ⚠ preferred_name carries the USED name where the city publishes one; full_name carries what the
-- Municipal Clerk's own results page writes. The council roster page says "Tina Clay"; the results
-- page says "Montyne \"Tina\" Clay". THE DISPLAY NAME IS NOT THE FULL NAME -- MS-3's Biloxi finding
-- (Mike / Robert Nail) in the same state.
-- ⚠ name_suffix carries Foote's "III" rather than a comma inside full_name, because a comma-suffix
-- is what breaks last-token name matching repo-wide.

CREATE TEMP TABLE jx_people(
  external_id bigint, full_name text, first_name text, last_name text,
  preferred_name text, name_suffix text
) ON COMMIT DROP;

INSERT INTO jx_people(external_id, full_name, first_name, last_name, preferred_name, name_suffix) VALUES
  (-2767000, 'John Horhn',          'John',    'Horhn',        NULL,   NULL),
  (-2766999, 'Ashby M. Foote III',  'Ashby',   'Foote',        NULL,   'III'),
  (-2766998, 'Montyne Clay',        'Montyne', 'Clay',         'Tina', NULL),
  (-2766997, 'Kenneth Stokes',      'Kenneth', 'Stokes',       NULL,   NULL),
  (-2766996, 'Brian C. Grizzell',   'Brian',   'Grizzell',     NULL,   NULL),
  (-2766995, 'Vernon Hartley',      'Vernon',  'Hartley',      NULL,   NULL),
  (-2766994, 'Lashia Brown-Thomas', 'Lashia',  'Brown-Thomas', NULL,   NULL),
  (-2766993, 'Kevin Parkinson',     'Kevin',   'Parkinson',    NULL,   NULL);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, preferred_name, name_suffix, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.preferred_name, n.name_suffix,
       'City of Jackson, Mississippi — council member pages (jacksonms.gov/government/city-council/council-member-ward-N/) and the Office of the Mayor page; every ward binding confirmed against the City Council''s own minutes of 2025-06-17 and 2025-07-08, which roll the members by ward; read 2026-10-31 (CC_0321)',
       true, true
FROM jx_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Eight terms ──────────────────────────────────────────────────────────
-- 🔴 Every join pairs geo_id WITH mtfcc.

CREATE TEMP TABLE jx_terms(
  geo_id text, mtfcc text, external_id bigint,
  term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO jx_terms(geo_id, mtfcc, external_id, term_start, start_precision, how_started) VALUES
  ('2836000',           'G4110', -2767000, DATE '2025-07-01', 'day',  'elected'),
  ('jackson-ms-ward-1', 'X0085', -2766999, DATE '2014-01-01', 'year', 'elected'),
  ('jackson-ms-ward-2', 'X0085', -2766998, DATE '2024-11-01', 'day',  'elected'),
  ('jackson-ms-ward-3', 'X0085', -2766997, DATE '2015-01-01', 'year', 'elected'),
  ('jackson-ms-ward-4', 'X0085', -2766996, DATE '2021-07-01', 'day',  'elected'),
  ('jackson-ms-ward-5', 'X0085', -2766995, DATE '2021-07-01', 'day',  'elected'),
  ('jackson-ms-ward-6', 'X0085', -2766994, DATE '2025-07-01', 'day',  'elected'),
  ('jackson-ms-ward-7', 'X0085', -2766993, DATE '2025-07-01', 'day',  'elected');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       'City of Jackson Municipal Clerk, Municipal Election Results ("Horhn began his term on July 1, 2025"); Ballotpedia assumed-office dates, each page verified to name Jackson, Mississippi and the exact ward by scripts/verify-jackson-roster-dates.mjs; continuity cross-checked against the City Council minutes of 2025-06-17 and 2025-07-08; read 2026-10-31 (CC_0321)'
FROM jx_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.mtfcc = t.mtfcc AND d.district_type = 'LOCAL' AND lower(d.state) = 'ms'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'City of Jackson, Mississippi, US'
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
  v_noninc  int;
  v_open    int;
  v_w2      date;
  v_w1prec  text;
  v_w3prec  text;
  v_mayor   date;
  v_dupward int;
  v_leg     int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2767000 AND -2766993;
  IF v_people <> 8 THEN
    RAISE EXCEPTION 'Jackson occupancy gate: expected 8 people in the reserved band, found %', v_people;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US';
  IF v_terms <> 8 THEN
    RAISE EXCEPTION 'Jackson occupancy gate: expected 8 Jackson office_terms, found %', v_terms;
  END IF;

  -- 🔴 THE REAL TEST IS THE VIEW, NOT THE TABLE. office_current_holder LEFT JOINs from offices, so
  -- a vacancy comes back as a NULL politician_id and count(*) would pass vacuously. Count the
  -- HOLDER column.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Jackson, Mississippi, US';
  IF v_seated <> 8 THEN
    RAISE EXCEPTION 'Jackson occupancy gate: expected 8 SEATED Jackson offices, found % (counting och.politician_id, not rows)', v_seated;
  END IF;

  -- The precision split, asserted as a split rather than a total.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year')
    INTO v_day, v_year
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US';
  IF v_day <> 6 OR v_year <> 2 THEN
    RAISE EXCEPTION 'Jackson occupancy gate: expected 6 day-precision and 2 year-precision terms, found % and %', v_day, v_year;
  END IF;

  -- 🔴 Ward 1 and Ward 3 must stay at 'year'. Their sources give a FIRST ELECTED year, not a term
  -- start, and Stokes's service is not continuous from the year his own page names.
  SELECT ot.start_precision INTO v_w1prec
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = 'jackson-ms-ward-1' AND d.mtfcc = 'X0085';
  SELECT ot.start_precision INTO v_w3prec
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = 'jackson-ms-ward-3' AND d.mtfcc = 'X0085';
  IF v_w1prec <> 'year' OR v_w3prec <> 'year' THEN
    RAISE EXCEPTION 'Jackson occupancy gate: Ward 1/Ward 3 precision is %/% — both must be year', v_w1prec, v_w3prec;
  END IF;

  -- 🔴 Ward 2 predates the 2025 general. Dating it from 2025 would erase the 2024 special.
  SELECT ot.term_start INTO v_w2
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = 'jackson-ms-ward-2' AND d.mtfcc = 'X0085';
  IF v_w2 <> DATE '2024-11-01' THEN
    RAISE EXCEPTION 'Jackson occupancy gate: Ward 2 term_start is % — expected 2024-11-01, after the 2024-10-01 special', v_w2;
  END IF;

  SELECT ot.term_start INTO v_mayor
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '2836000' AND d.mtfcc = 'G4110';
  IF v_mayor <> DATE '2025-07-01' THEN
    RAISE EXCEPTION 'Jackson occupancy gate: mayor term_start is % — the city states 2025-07-01', v_mayor;
  END IF;

  SELECT count(*) INTO v_noninc FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2767000 AND -2766993
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'Jackson occupancy gate: % Jackson official(s) are not is_incumbent/is_active — they would be hidden from address search', v_noninc;
  END IF;

  SELECT count(*) INTO v_open
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Jackson, Mississippi, US' AND ot.term_end IS NOT NULL;
  IF v_open <> 0 THEN
    RAISE EXCEPTION 'Jackson occupancy gate: % Jackson term(s) are closed — all eight are sitting', v_open;
  END IF;

  -- 🔴 ONE HOLDER PER WARD, asserted per district. A total of 8 is also what one doubled ward and
  -- one empty ward would give, and the empty one would answer no address.
  SELECT count(*) INTO v_dupward
    FROM essentials.districts d
   WHERE d.mtfcc = 'X0085'
     AND (SELECT count(och.politician_id)
            FROM essentials.offices o
            LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
           WHERE o.district_id = d.id) <> 1;
  IF v_dupward <> 0 THEN
    RAISE EXCEPTION 'Jackson occupancy gate: % Jackson ward(s) do not have exactly 1 seated holder', v_dupward;
  END IF;

  -- 🔴 CONTROL, IN THE SAME TRANSACTION: Mississippi's 174 legislative seats must be untouched.
  SELECT count(och.politician_id) INTO v_leg
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc IN ('G5210', 'G5220') AND lower(d.state) = 'ms';
  IF v_leg <> 174 THEN
    RAISE EXCEPTION 'Jackson occupancy gate CONTROL: expected 174 seated MS legislative offices, found %', v_leg;
  END IF;

  RAISE NOTICE 'Jackson occupancy gate PASSED: 8 people, 8 open terms, 8 seated (counted on the holder column), 6 day + 2 year precision, Ward 1/3 at year, Ward 2 at 2024-11-01, mayor at 2025-07-01, one holder per ward, all is_incumbent; 174 MS legislative seats unmoved.';
END $$;

COMMIT;
