-- CC_0134_akron_people.sql
-- Knight Foundation program, wave OH-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0133, which creates the government, chambers, districts and the
-- 14 offices.
--
-- Seats all 14 Akron offices: 14 people created, external_id band -2761200 .. -2761001
-- (used -2761014 .. -2761001), 0 reused, 0 vacancies.
--
-- 🔴🔴 ONLY THE MAYOR IS DATED, AND THE OTHER THIRTEEN ARE NOT GUESSED -- BECAUSE A BLANKET DATE
-- WAS TESTED AND IS WRONG. Akron elects its Mayor and all 13 council members to four-year terms
-- at the same November election, so "everyone started 2024-01-01" is exactly the kind of rule
-- that looks safe. It is false for at least two of the thirteen:
--   · WARD 1 -- Nancy Holland resigned effective 4pm on 2024-01-05, five days into the term.
--     Samuel DeShazior was appointed to hold the seat, and the seat was then filled for the
--     REMAINDER OF THE UNEXPIRED TERM at the 2025 general election. FRAN WILSON, the current
--     member, therefore did not arrive in January 2024 and is not the appointee either.
--   · WARD 8 -- James Hardy resigned effective 2024-07-01. BRUCE BOLDEN, the current member,
--     was appointed in July 2024.
-- Neither arrival date is published by the city in a form this wave read, so both are written
-- open-ended at 'unknown' -- and so are the other eleven, because the same failure could be true
-- of any of them and nothing checked has ruled it out. ▶ THE POINT IS NOT THAT THE DATE IS
-- UNKNOWN; IT IS THAT TWO SEATS PROVE THE BLANKET RULE FALSE, so applying it to the other eleven
-- would be asserting something already shown to fail. This is the San Jose D8/D10 lesson with
-- the counter-example found BEFORE the write instead of after it.
--
-- 🟢 THE MAYOR IS DATED BECAUSE THE CITY PUBLISHES THE DATE. akronohio.gov's Mayor's Office page:
-- "Mayor Malik was sworn in as Akron's 63rd Mayor on Jan. 1, 2024." That is an oath date from the
-- office's own page, so 2024-01-01 at 'day' precision, how_started 'elected'.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
-- 🔴 PARTY IS NOT WRITTEN. Akron's council races are partisan; party lives on races.primary_party.
--
-- 🟢 THE ROSTER HAS TWO INDEPENDENT CITY PUBLISHERS AND THEY AGREE ON ALL TEN WARDS. The
-- council's own members page (akroncitycouncil.org/members) and the CITY GIS ward layer's
-- COUNCILPERSON field (AkronGIS) name the same ten people; the loader's GATE 2 enforces it and
-- was watched failing. The three at-large members and the Mayor come from the council page and
-- the Mayor's Office page respectively. ⚠ Akron publishes NO per-member pages, so the page-by-page
-- change-check used at OH-2 is not available here; the two-publisher agreement is what replaces it,
-- and that is a weaker instrument on the three at-large seats, where only one publisher exists.
--
-- ⚠ THE GIS LAYER IS CURRENT ON NAMES AND STALE ON TITLES. It calls Ward 6 "President Pro Tem";
-- the council's page says Ward 6 is Vice-President and Ward 9 is President Pro-Tem. Leadership
-- titles are not stored on offices, so nothing here depends on it -- but a source can be fresh in
-- one column and stale in another.
--
-- 🔴 NAME COLLISIONS WERE CHECKED ON THE GUARD'S OWN KEY, (first_name, last_name), which is the
-- lesson OH-2 paid for: 0 of 14 collide, against a control of 198 active rows with first_name
-- 'John'. No duplicate-name override is needed in this migration.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- ─── 1. The 14 people ────────────────────────────────────────────────────────

CREATE TEMP TABLE ak_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ak_people(external_id, full_name, first_name, last_name) VALUES
  (-2761001, 'Fran Wilson',          'Fran',    'Wilson'),
  (-2761002, 'Phil Lombardo',        'Phil',    'Lombardo'),
  (-2761003, 'Margo Sommerville',    'Margo',   'Sommerville'),
  (-2761004, 'Jan Davis',            'Jan',     'Davis'),
  (-2761005, 'Johnnie Hannah',       'Johnnie', 'Hannah'),
  (-2761006, 'Brad McKitrick',       'Brad',    'McKitrick'),
  (-2761007, 'Donnie Kammer',        'Donnie',  'Kammer'),
  (-2761008, 'Bruce Bolden',         'Bruce',   'Bolden'),
  (-2761009, 'Tina Boyes',           'Tina',    'Boyes'),
  (-2761010, 'Sharon Connor',        'Sharon',  'Connor'),
  (-2761011, 'Linda F. R. Omobien',  'Linda',   'Omobien'),
  (-2761012, 'Mark Greer',           'Mark',    'Greer'),
  (-2761013, 'Eric D. Garrett, Sr.', 'Eric',    'Garrett'),
  (-2761014, 'Shammas Malik',        'Shammas', 'Malik');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Akron City Council members page, https://www.akroncitycouncil.org/members, cross-checked ward by ward against the City of Akron GIS ward layer''s COUNCILPERSON field (services1.arcgis.com/8roChjXOF0iBhNoB, owner AkronGIS) — 10 of 10 agree; Mayor from https://www.akronohio.gov/government/mayor_s_office/index.php; read 2026-09-23 (CC_0134, OH-3)',
       true, true
FROM ak_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 14 terms ─────────────────────────────────────────────────────────
-- The join key is (geo_id, title). For the three at-large seats it is additionally the internal
-- ordinal in `description` — matching loosely there would seat one person three times and leave
-- two seats empty.

CREATE TEMP TABLE ak_terms(
  external_id bigint, geo_id text, title text, ordinal int,
  term_start date, start_precision text, how_started text, date_source text
) ON COMMIT DROP;

INSERT INTO ak_terms(external_id, geo_id, title, ordinal, term_start, start_precision, how_started, date_source) VALUES
  (-2761001, 'akron-oh-ward-1',  'Council Member, Ward 1',  NULL, NULL, 'unknown', 'unknown',
   'arrival not published; the seat was filled at the 2025 general election for the remainder of Nancy Holland''s unexpired term, so the January 2024 commencement does not apply'),
  (-2761002, 'akron-oh-ward-2',  'Council Member, Ward 2',  NULL, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761003, 'akron-oh-ward-3',  'Council Member, Ward 3',  NULL, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761004, 'akron-oh-ward-4',  'Council Member, Ward 4',  NULL, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761005, 'akron-oh-ward-5',  'Council Member, Ward 5',  NULL, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761006, 'akron-oh-ward-6',  'Council Member, Ward 6',  NULL, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761007, 'akron-oh-ward-7',  'Council Member, Ward 7',  NULL, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761008, 'akron-oh-ward-8',  'Council Member, Ward 8',  NULL, NULL, 'unknown', 'unknown',
   'arrival not published; appointed in July 2024 to the seat James Hardy resigned effective 2024-07-01, so the January 2024 commencement does not apply'),
  (-2761009, 'akron-oh-ward-9',  'Council Member, Ward 9',  NULL, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761010, 'akron-oh-ward-10', 'Council Member, Ward 10', NULL, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761011, '3901000', 'Council Member, At Large', 1, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761012, '3901000', 'Council Member, At Large', 2, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761013, '3901000', 'Council Member, At Large', 3, NULL, 'unknown', 'unknown', 'arrival not published by the city'),
  (-2761014, '3901000', 'Mayor', NULL, DATE '2024-01-01', 'day', 'elected',
   'akronohio.gov Mayor''s Office: "Mayor Malik was sworn in as Akron''s 63rd Mayor on Jan. 1, 2024."');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       'Akron OH-3 (CC_0134): ' || t.date_source
FROM ak_terms t
JOIN essentials.districts d ON d.geo_id = t.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'oh'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.title = t.title
 AND (t.ordinal IS NULL OR o.description LIKE 'Internal ordinal ' || t.ordinal || ' of 3%')
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people  int;
  v_offices int;
  v_terms   int;
  v_seated  int;
  v_dated   int;
  v_ended   int;
  v_fanout  int;
  v_two     int;
  v_mayor   date;
  v_ward3   int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2761200 AND -2761001;
  IF v_people <> 14 THEN RAISE EXCEPTION 'OH-3 occupancy: expected 14 people in the reserved band, got %', v_people; END IF;

  SELECT count(*) INTO v_offices FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Akron, Ohio, US';
  IF v_offices <> 14 THEN RAISE EXCEPTION 'OH-3 occupancy: expected 14 Akron offices, got %', v_offices; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Akron, Ohio, US';
  IF v_terms <> 14 THEN RAISE EXCEPTION 'OH-3 occupancy: expected 14 Akron terms, got %', v_terms; END IF;

  -- No office may be left unseated: Akron has no vacancy today.
  SELECT count(*) INTO v_seated FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Akron, Ohio, US'
    AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);
  IF v_seated <> 0 THEN RAISE EXCEPTION 'OH-3 occupancy: % Akron office(s) have no term', v_seated; END IF;

  -- Exactly ONE term may carry a date, and it must be the Mayor's.
  SELECT count(*) FILTER (WHERE ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Akron, Ohio, US';
  IF v_dated <> 1 THEN
    RAISE EXCEPTION 'OH-3 occupancy: % Akron term(s) carry a start date, expected exactly 1 (the Mayor)', v_dated;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'OH-3 occupancy: % Akron term(s) carry a term_end — a future end self-vacates a seat', v_ended;
  END IF;

  SELECT ot.term_start INTO v_mayor
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Akron, Ohio, US' AND o.title = 'Mayor';
  IF v_mayor IS DISTINCT FROM DATE '2024-01-01' THEN
    RAISE EXCEPTION 'OH-3 occupancy: the Mayor''s term_start is %, expected 2024-01-01', v_mayor;
  END IF;

  -- One term per office, and nobody holding two.
  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.office_id FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.name = 'City of Akron, Ohio, US'
    GROUP BY ot.office_id HAVING count(*) <> 1) x;
  IF v_fanout <> 0 THEN RAISE EXCEPTION 'OH-3 occupancy: % Akron office(s) do not have exactly one term', v_fanout; END IF;

  -- 🔴 The at-large ordinal join is the one that can silently seat one person three times.
  SELECT count(*) INTO v_two FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
    WHERE ot.politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -2761200 AND -2761001)
    GROUP BY ot.politician_id HAVING count(*) <> 1) y;
  IF v_two <> 0 THEN RAISE EXCEPTION 'OH-3 occupancy: % Akron person/people hold more than one office', v_two; END IF;

  -- Named assertion, not a count: Ward 3 must hold Margo Sommerville, the Council President.
  SELECT count(*) INTO v_ward3
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = ot.politician_id
  WHERE d.geo_id = 'akron-oh-ward-3' AND d.district_type = 'LOCAL' AND p.full_name = 'Margo Sommerville';
  IF v_ward3 <> 1 THEN
    RAISE EXCEPTION 'OH-3 occupancy: Akron Ward 3 does not hold Margo Sommerville (got %)', v_ward3;
  END IF;

  RAISE NOTICE 'OH-3 occupancy OK: 14 people, 14 terms, 0 unseated, 1 dated (Mayor 2024-01-01), Ward 3 = Sommerville';
END $$;

COMMIT;
