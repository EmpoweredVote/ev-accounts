-- CC_0137_summit_county_people.sql
-- Knight Foundation program, wave OH-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0136, which creates the government, chambers, districts and the
-- 17 offices.
--
-- Seats all 17 Summit County offices: 17 people created, external_id band -2762200 .. -2762001
-- (used -2762017 .. -2762001), 0 reused, 0 vacancies.
--
-- 🟢 THE EIGHT DISTRICT MEMBERS HAVE TWO INDEPENDENT COUNTY PUBLISHERS AND THEY AGREE. The
-- Summit_County_Council_2025 layer carries a `Name` field per district, and each member's OWN
-- council page (linked from the layer's `InfoURL`) names the same person. The loader's GATE 2
-- enforces it and was watched failing. 🟢 That layer ALSO carries the three at-large members, as
-- rows with PA4 = 0 and NULL geometry -- which is how the at-large roster was obtained without a
-- second source, and each of those three was then read from their own council page too.
--
-- 🔴 THE FIVE ROW OFFICERS AND THE EXECUTIVE COME FROM THEIR OWN OFFICES' SITES, one at a time,
-- because the county's portal page names only the Executive:
--   County Executive      Ilene Shapiro        co.summitoh.net portal page
--   Clerk of Courts       Tavia Galonski       clerkweb.summitoh.net
--   County Engineer       B. Alan Brubaker     summitengineer.net (the office's own site)
--   Fiscal Officer        Kristen M. Scalise   fiscaloffice.summitoh.net
--   Prosecuting Attorney  Elliot Kolkovich     prosecutor.summitoh.net
--   Sheriff               Kandy Fatheree       sheriff.summitoh.net
-- ⚠ engineer.summitoh.net and clerkofcourts.summitoh.net DO NOT RESOLVE. The working hosts are
-- summitengineer.net and clerkweb.summitoh.net. A guessed subdomain is not an absence.
--
-- 🟢 ONLY TWO TERMS ARE DATED, AND BOTH DATES COME FROM THE OFFICE'S OWN PAGE:
--   · Fiscal Officer -- "has served as the Summit County Fiscal Officer since May 2011", so
--     2011-05-01 at 'month' precision. The day is not published and is not invented.
--   · Prosecuting Attorney -- "was sworn into office on February 21, 2024", so 2024-02-21 at
--     'day'. ⚠ how_started is 'unknown', not 'elected': a February start is mid-term and the page
--     does not say whether he was appointed or elected to it. The DATE is sourced; the MECHANISM
--     is not, and only the sourced half is written.
--
-- 🔴 THE OTHER FIFTEEN ARE OPEN-ENDED AT 'unknown', AND OH-3 IS WHY THAT IS NOT LAZINESS. Akron's
-- wave proved a blanket commencement date false on 2 of 13 seats with published counter-examples.
-- Summit's Clerk of Courts is a live instance of the same shape: Tavia Galonski was APPOINTED in
-- January 2024 to a seat she then won in November 2024, so neither "elected 2025-01-01" nor her
-- election year describes when she took the office -- it is the San Jose Candelas case exactly.
-- Her appointment date is not published, so nothing is written. ▶ Dating these fifteen is a debt.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party.
--
-- 🔴 NAME COLLISIONS WERE CHECKED ON THE GUARD'S OWN KEY, (first_name, last_name) -- the lesson
-- OH-2 paid for, where a full_name check and a last-token check both missed "Tom Young, Jr.".
-- 0 of 17 collide, against a control of 198 active rows with first_name 'John'. No override needed.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- ─── 1. The 17 people ────────────────────────────────────────────────────────

CREATE TEMP TABLE sm_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO sm_people(external_id, full_name, first_name, last_name) VALUES
  (-2762001, 'Rita Darrow',             'Rita',      'Darrow'),
  (-2762002, 'John N. Schmidt',         'John',      'Schmidt'),
  (-2762003, 'David Licate',            'David',     'Licate'),
  (-2762004, 'Jeff Wilhite',            'Jeff',      'Wilhite'),
  (-2762005, 'Brandon Ford',            'Brandon',   'Ford'),
  (-2762006, 'Christine Wiedie Higham', 'Christine', 'Higham'),
  (-2762007, 'Bethany McKenney',        'Bethany',   'McKenney'),
  (-2762008, 'Joseph Kacyon',           'Joseph',    'Kacyon'),
  (-2762009, 'John Donofrio',           'John',      'Donofrio'),
  (-2762010, 'Elizabeth Walters',       'Elizabeth', 'Walters'),
  (-2762011, 'Erin Dickinson',          'Erin',      'Dickinson'),
  (-2762012, 'Ilene Shapiro',           'Ilene',     'Shapiro'),
  (-2762013, 'Tavia Galonski',          'Tavia',     'Galonski'),
  (-2762014, 'B. Alan Brubaker',        'Alan',      'Brubaker'),
  (-2762015, 'Kristen M. Scalise',      'Kristen',   'Scalise'),
  (-2762016, 'Elliot Kolkovich',        'Elliot',    'Kolkovich'),
  (-2762017, 'Kandy Fatheree',          'Kandy',     'Fatheree');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Summit County Council roster from the county''s own Summit_County_Council_2025 ("Plan A4") layer, which carries all eleven members, cross-checked one by one against each member''s own page at council.summitoh.net; County Executive from co.summitoh.net; Clerk of Courts from clerkweb.summitoh.net; Engineer from summitengineer.net; Fiscal Officer from fiscaloffice.summitoh.net; Prosecutor from prosecutor.summitoh.net; Sheriff from sheriff.summitoh.net; read 2026-09-24 (CC_0137, OH-4)',
       true, true
FROM sm_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 17 terms ─────────────────────────────────────────────────────────
-- Keyed on (geo_id, mtfcc, title), plus the internal ordinal for the three at-large seats --
-- matching loosely there would seat one person three times and leave two seats empty.

CREATE TEMP TABLE sm_terms(
  external_id bigint, geo_id text, mtfcc text, title text, ordinal int,
  term_start date, start_precision text, how_started text, date_source text
) ON COMMIT DROP;

INSERT INTO sm_terms(external_id, geo_id, mtfcc, title, ordinal, term_start, start_precision, how_started, date_source) VALUES
  (-2762001, 'summit-oh-council-district-1', 'X0064', 'Council Member, District 1', NULL, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762002, 'summit-oh-council-district-2', 'X0064', 'Council Member, District 2', NULL, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762003, 'summit-oh-council-district-3', 'X0064', 'Council Member, District 3', NULL, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762004, 'summit-oh-council-district-4', 'X0064', 'Council Member, District 4', NULL, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762005, 'summit-oh-council-district-5', 'X0064', 'Council Member, District 5', NULL, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762006, 'summit-oh-council-district-6', 'X0064', 'Council Member, District 6', NULL, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762007, 'summit-oh-council-district-7', 'X0064', 'Council Member, District 7', NULL, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762008, 'summit-oh-council-district-8', 'X0064', 'Council Member, District 8', NULL, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762009, '39153', 'G4020', 'Council Member, At Large', 1, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762010, '39153', 'G4020', 'Council Member, At Large', 2, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762011, '39153', 'G4020', 'Council Member, At Large', 3, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762012, '39153', 'G4020', 'County Executive',     NULL, NULL, 'unknown', 'unknown', 'arrival not published by the county'),
  (-2762013, '39153', 'G4020', 'Clerk of Courts',      NULL, NULL, 'unknown', 'unknown', 'appointed January 2024 and elected November 2024; the appointment DATE is not published, and the election year is not a term start'),
  (-2762014, '39153', 'G4020', 'County Engineer',      NULL, NULL, 'unknown', 'unknown', 'the office''s own site does not publish an arrival date'),
  (-2762015, '39153', 'G4020', 'Fiscal Officer',       NULL, DATE '2011-05-01', 'month', 'unknown',
   'fiscaloffice.summitoh.net: "has served as the Summit County Fiscal Officer since May 2011"; the day is not published'),
  (-2762016, '39153', 'G4020', 'Prosecuting Attorney', NULL, DATE '2024-02-21', 'day', 'unknown',
   'prosecutor.summitoh.net: "was sworn into office on February 21, 2024"; the page does not say whether by appointment or election'),
  (-2762017, '39153', 'G4020', 'Sheriff',              NULL, NULL, 'unknown', 'unknown', 'the office''s own site does not publish an arrival date');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       'Summit County OH-4 (CC_0137): ' || t.date_source
FROM sm_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.mtfcc = t.mtfcc AND lower(d.state) = 'oh' AND d.district_type::text = 'COUNTY'
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
  v_people int; v_offices int; v_terms int; v_unseated int;
  v_dated int; v_ended int; v_fanout int; v_two int;
  v_fiscal date; v_pros date; v_akron int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2762200 AND -2762001;
  IF v_people <> 17 THEN RAISE EXCEPTION 'OH-4 occupancy: expected 17 people in the reserved band, got %', v_people; END IF;

  SELECT count(*) INTO v_offices FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'County of Summit, Ohio, US';
  IF v_offices <> 17 THEN RAISE EXCEPTION 'OH-4 occupancy: expected 17 Summit offices, got %', v_offices; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'County of Summit, Ohio, US';
  IF v_terms <> 17 THEN RAISE EXCEPTION 'OH-4 occupancy: expected 17 Summit terms, got %', v_terms; END IF;

  SELECT count(*) INTO v_unseated FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'County of Summit, Ohio, US'
    AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);
  IF v_unseated <> 0 THEN RAISE EXCEPTION 'OH-4 occupancy: % Summit office(s) have no term', v_unseated; END IF;

  SELECT count(*) FILTER (WHERE ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'County of Summit, Ohio, US';
  IF v_dated <> 2 THEN
    RAISE EXCEPTION 'OH-4 occupancy: % Summit term(s) carry a start date, expected exactly 2 (Fiscal Officer, Prosecutor)', v_dated;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'OH-4 occupancy: % Summit term(s) carry a term_end — a future end self-vacates a seat', v_ended;
  END IF;

  SELECT max(ot.term_start) FILTER (WHERE o.title = 'Fiscal Officer'),
         max(ot.term_start) FILTER (WHERE o.title = 'Prosecuting Attorney')
    INTO v_fiscal, v_pros
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'County of Summit, Ohio, US';
  IF v_fiscal IS DISTINCT FROM DATE '2011-05-01' THEN
    RAISE EXCEPTION 'OH-4 occupancy: Fiscal Officer term_start is %, expected 2011-05-01', v_fiscal;
  END IF;
  IF v_pros IS DISTINCT FROM DATE '2024-02-21' THEN
    RAISE EXCEPTION 'OH-4 occupancy: Prosecutor term_start is %, expected 2024-02-21', v_pros;
  END IF;

  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.office_id FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.name = 'County of Summit, Ohio, US'
    GROUP BY ot.office_id HAVING count(*) <> 1) x;
  IF v_fanout <> 0 THEN RAISE EXCEPTION 'OH-4 occupancy: % Summit office(s) do not have exactly one term', v_fanout; END IF;

  -- 🔴 The at-large ordinal join is the one that can silently seat one person three times.
  SELECT count(*) INTO v_two FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
    WHERE ot.politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -2762200 AND -2762001)
    GROUP BY ot.politician_id HAVING count(*) <> 1) y;
  IF v_two <> 0 THEN RAISE EXCEPTION 'OH-4 occupancy: % Summit person/people hold more than one office', v_two; END IF;

  -- 🟢 Named assertion, not a count: Akron City Hall's county council member must be Jeff Wilhite,
  -- which is the whole point of the two-map arbitration in CC_0136 and the loader.
  SELECT count(*) INTO v_akron
  FROM essentials.geofence_boundaries b
  JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc AND lower(d.state) = 'oh'
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.office_terms ot ON ot.office_id = o.id
  JOIN essentials.politicians p ON p.id = ot.politician_id
  WHERE b.mtfcc = 'X0064'
    AND ST_Contains(b.geometry, ST_SetSRID(ST_Point(-81.51900, 41.08113), 4326))
    AND p.full_name = 'Jeff Wilhite';
  IF v_akron <> 1 THEN
    RAISE EXCEPTION 'OH-4 occupancy: Akron City Hall does not resolve to Jeff Wilhite (got %)', v_akron;
  END IF;

  RAISE NOTICE 'OH-4 occupancy OK: 17 people, 17 terms, 0 unseated, 2 dated (Fiscal Officer 2011-05 month, Prosecutor 2024-02-21 day), Akron = Wilhite';
END $$;

COMMIT;
