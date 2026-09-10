-- CC_0091_fort_wayne_people.sql
-- Knight Foundation program, wave IN-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0090, which creates the government, chambers, districts and offices.
--
-- Seats all ELEVEN Fort Wayne offices: 11 people, 11 terms, 0 vacancies.
-- external_id band -1332151 .. -1332161, measured free 2026-09-10.
--
-- 🟢 ALL ELEVEN PEOPLE ARE NEW TO PRODUCTION, AND THAT WAS CONTROLLED RATHER THAN ASSUMED.
-- None of the eleven matches any existing politician row, including the 672-row
-- 'indiana_discovery' cohort that supplied 84 of the legislature's seats in CC_0089. Because
-- "no match" for all eleven is a uniform answer, the same query was run against Kyle Miller,
-- Justin Busch and Greg Taylor -- it matched all three. The absence is real, not a broken join.
--
-- 🔴 THREE MEMBERS ARE 'day' AT 2024-01-01 AND FIVE ARE 'year', FROM THE SAME DOCUMENT.
-- The Council's own agenda prints "Elected to a 4-year term: 1/1/24 - 12/31/27". That is the
-- TERM. For Bender, Hartman and Myers -- new in 2024 -- the term start IS the start of continuous
-- occupancy, so 2024-01-01 at 'day' is correct and sourced. For Ensley, Jehl, Paddock, Chambers
-- and Freistroffer the same sentence is NOT their occupancy start: they were re-elected in 2023
-- having served since 2012, 2016 or 2020, and RE-ELECTION DOES NOT END AN OCCUPANCY. Ballotpedia
-- publishes only a YEAR for those five ("Tenure 2012 - Present"), so they are written at 'year'
-- precision on January 1 of that year -- NOT back-filled to a day no source states.
--
-- 🔴 TWO SEATS CHANGED HANDS MID-TERM AND A STALE SOURCE WOULD HAVE SEATED THE WRONG PERSON:
--   City Clerk  Lana Keesling RESIGNED 2026-01-06 on becoming Indiana GOP chair; John McGauley
--               won the Allen County GOP caucus and was sworn in the morning of Sat 2026-01-17.
--               Confirmed by the Council's own 24 Feb 2026 agenda, which names McGauley.
--   District 6  Sharon Tucker left on becoming Mayor; Rohli Booker won the Allen County
--               Democratic caucus 2024-05-18 and was sworn in by Mayor Tucker on Tue 2024-05-21.
--
-- ⚠ AND THE OBVIOUS READING OF THE SECOND ONE IS WRONG. Scott Myers (District 4) did NOT replace
-- Tucker: he WON District 4 at the 2023 election, the seat having opened when Jason Arp left to
-- run for mayor. Tucker's seat was District 6. Giving Myers a mid-term caucus date would have put
-- a sourced-looking but false date on a real person.
--
-- 🔴 THE THREE AT-LARGE SEATS SHARE ONE TITLE, so they are matched on the INTERNAL ORDINAL that
-- CC_0090 wrote into `description`. Indiana does not number these seats; the ordinal is a join
-- key, not a ballot designation, and nothing voter-facing reads it.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate -- these terms
-- run to 2027-12-31 and writing that would vacate all nine council seats on that date with no
-- successor.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party, never on a person or an office.
-- 🔴 alternate_names IS NOT NULL DEFAULT '{}' -- an empty array is emitted, never NULL.
--
-- seat_officeholder() is NOT used: there is no predecessor row to close (these offices are new
-- in CC_0090), and the helper would refuse the 'year'-precision rows anyway.
--
-- Idempotent: people NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- ─── Eleven people ───────────────────────────────────────────────────────────

CREATE TEMP TABLE fw_people(external_id bigint, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO fw_people(external_id, full_name, first_name, last_name) VALUES
  (-1332151, 'Sharon Tucker',       'Sharon',   'Tucker'),
  (-1332152, 'John McGauley',       'John',     'McGauley'),
  (-1332153, 'Paul Ensley',         'Paul',     'Ensley'),
  (-1332154, 'Russ Jehl',           'Russ',     'Jehl'),
  (-1332155, 'Nathan Hartman',      'Nathan',   'Hartman'),
  (-1332156, 'Scott Myers',         'Scott',    'Myers'),
  (-1332157, 'Geoff Paddock',       'Geoff',    'Paddock'),
  (-1332158, 'Rohli Booker',        'Rohli',    'Booker'),
  (-1332159, 'Martin Bender',       'Martin',   'Bender'),
  (-1332160, 'Michelle Chambers',   'Michelle', 'Chambers'),
  (-1332161, 'Thomas Freistroffer', 'Thomas',   'Freistroffer');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'City of Fort Wayne Common Council roster, cityoffortwayne.in.gov/185/City-Council, reconciled against the Common Council agenda of 2026-02-24, read 2026-09-10 (CC_0091, IN-3)',
       '{}'
FROM fw_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── Eleven terms ────────────────────────────────────────────────────────────
-- office_match: for the six district seats and the two citywide singletons this is the geo_id +
-- title. For the three at-large seats it is the internal ordinal in `description`.

CREATE TEMP TABLE fw_terms(
  external_id bigint, geo_id text, title text, ordinal int,
  term_start date, start_precision text, date_source text) ON COMMIT DROP;
INSERT INTO fw_terms VALUES
  (-1332151, '1825000', 'Mayor',      NULL, DATE '2024-04-23', 'day',
   'Assumed office 2024-04-23, succeeding Tom Henry who died in office'),
  (-1332152, '1825000', 'City Clerk', NULL, DATE '2026-01-17', 'day',
   'Sworn in the morning of the Allen County GOP caucus, Sat 2026-01-17, succeeding Lana Keesling'),
  (-1332153, 'fort-wayne-in-council-district-1', 'Council Member, District 1', NULL, DATE '2016-01-01', 'year',
   'Ballotpedia tenure 2016 - Present; no day is published'),
  (-1332154, 'fort-wayne-in-council-district-2', 'Council Member, District 2', NULL, DATE '2012-01-01', 'year',
   'Ballotpedia tenure 2012 - Present; no day is published'),
  (-1332155, 'fort-wayne-in-council-district-3', 'Council Member, District 3', NULL, DATE '2024-01-01', 'day',
   'New in 2024; Common Council agenda states the term begins 1/1/24'),
  (-1332156, 'fort-wayne-in-council-district-4', 'Council Member, District 4', NULL, DATE '2024-01-01', 'day',
   'New in 2024, elected 2023-11-07 for the seat Jason Arp vacated; term begins 1/1/24'),
  (-1332157, 'fort-wayne-in-council-district-5', 'Council Member, District 5', NULL, DATE '2012-01-01', 'year',
   'Ballotpedia tenure 2012 - Present; no day is published'),
  (-1332158, 'fort-wayne-in-council-district-6', 'Council Member, District 6', NULL, DATE '2024-05-21', 'day',
   'Sworn in by Mayor Tucker Tue 2024-05-21 after the 2024-05-18 caucus, succeeding Sharon Tucker'),
  (-1332159, '1825000', 'Council Member, At Large', 1, DATE '2024-01-01', 'day',
   'New in 2024; Common Council agenda states the term begins 1/1/24'),
  (-1332160, '1825000', 'Council Member, At Large', 2, DATE '2020-01-01', 'year',
   'Ballotpedia tenure 2020 - Present; no day is published'),
  (-1332161, '1825000', 'Council Member, At Large', 3, DATE '2016-01-01', 'year',
   'Ballotpedia tenure 2016 - Present; no day is published');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, 'unknown',
       'Fort Wayne IN-3 (CC_0091): ' || t.date_source
FROM fw_terms t
JOIN essentials.districts d ON d.geo_id = t.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.title = t.title
 AND (t.ordinal IS NULL OR o.description LIKE 'Internal ordinal ' || t.ordinal || ' of 3%')
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_offices int; v_seated int; v_ended int; v_day int; v_year int; v_dupe int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -1332161 AND -1332151;
  IF v_people <> 11 THEN RAISE EXCEPTION 'IN-3 occupancy: % people in the band, expected 11', v_people; END IF;

  -- count(och.politician_id), never count(*): office_current_holder LEFT JOINs from offices.
  SELECT count(o.id), count(och.politician_id) INTO v_offices, v_seated
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.name = 'City of Fort Wayne, Indiana, US';
  IF v_offices <> 11 OR v_seated <> 11 THEN
    RAISE EXCEPTION 'IN-3 occupancy: expected 11 offices all seated, got % offices / % seated', v_offices, v_seated;
  END IF;

  -- 🔴 Each of the three at-large seats must hold a DIFFERENT person. A join that matched the
  -- ordinal loosely would seat one person three times and leave two seats empty.
  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE g.name = 'City of Fort Wayne, Indiana, US' AND o.title = 'Council Member, At Large'
    GROUP BY och.politician_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'IN-3 occupancy: an at-large person holds more than one at-large seat'; END IF;

  SELECT count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_day, v_year, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Fort Wayne, Indiana, US';
  IF v_day <> 6 OR v_year <> 5 THEN
    RAISE EXCEPTION 'IN-3 occupancy: expected 6 day-precision and 5 year-precision terms, got % / %', v_day, v_year;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'IN-3 occupancy: % terms carry a term_end; none may, or the seat self-vacates', v_ended;
  END IF;

  RAISE NOTICE 'IN-3 occupancy OK: 11 people, 11 offices, 11 seated, 6 day + 5 year, 0 ended, 3 distinct at-large holders';
END $$;

COMMIT;
