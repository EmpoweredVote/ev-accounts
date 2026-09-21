-- CC_0094_allen_county.sql
-- Knight Foundation program, wave IN-5 (stage 4, Allen County). Slot RESERVED from the allocator.
--
-- ONE migration carrying offices AND people, per spec §3: an office with no office_terms row is
-- invisible, so shipping county offices in one wave and county people in the next would push
-- essentials.offices_missing_terms above its unflagged baseline for the days between. This is the
-- Nashville correction and it is why this file is not split.
--
--   Board of County Commissioners  official_count 3   3 offices, ALL COUNTYWIDE
--   Allen County Council           official_count 7   4 by district + 3 at-large
--   Elected Officials              official_count 9   the 8 county officers + Prosecuting Attorney
--
--   19 offices, 19 people, 19 terms, 0 vacancies.  external_id band -1332186 .. -1332168.
--
-- 🔴🔴 THE THREE COMMISSIONERS HANG ON THE COUNTY POLYGON, NOT ON COMMISSIONER DISTRICTS, AND
--    THIS IS THE CENTRAL DECISION OF THE WAVE.
--
-- Under Indiana law a county commissioner MUST RESIDE in a district but is ELECTED BY THE ENTIRE
-- COUNTY: every registered voter in Allen County votes for all three. The Election Board publishes
-- Comm_Dist_1/2/3 polygons -- three neat, correct, inviting layers -- and hanging the offices on
-- them would show a voter ONE of the three commissioners they actually elect. So the districts are
-- a CANDIDATE RESIDENCY RULE, they are deliberately not loaded, and the three offices sit on
-- 18003/G4020. The title still names the residency district, because that is a real fact about
-- the office; `description` says what it means so nobody later mistakes it for an electorate.
--
-- ⚠ THIS IS THE INVERSE OF THE LONG BEACH FAILURE. There, nine councilmembers shared one polygon
-- and every address wrongly returned all nine. Here every county address SHOULD return all three
-- commissioners. The same shape is wrong in one case and right in the other, and only the statute
-- tells you which.
--
-- 🟢 THE COUNTY COUNCIL IS GENUINELY DIFFERENT: its four district members ARE elected by district
-- (X0049, loaded by scripts/load-allen-county-council-boundaries.ts, which proves the four tile
-- the county), and its three at-large members are elected countywide.
--
-- 🔴 RULING (Cantrell, 2026-09-10): the PROSECUTING ATTORNEY is modelled; the SUPERIOR COURT
-- JUDGES are not. The county's own ballot lists both under COUNTY/LOCAL. A prosecutor is an
-- elected executive law-enforcement office; the judges are the state trial judiciary and bring
-- retention and is_judicial modelling this wave has not scoped. This keeps GA-4's line, which
-- excluded Muscogee's municipal court.
--
-- 🔴 THE COUNTY'S OWN DIRECTORY WAS THE STALE SOURCE. It still lists Josh L. Hale on County
-- Council District 1. Hale RESIGNED effective 2026-01-15 and KYLE KERLEY won the GOP caucus at
-- noon on 2026-01-16. The party page was right and the official directory was wrong -- so the
-- change-check has to ask "has this person left?" of every source, the official one included.
--
-- 🔴 NO term_end. 🔴 NO PARTY -- it lives on races.primary_party.
-- 🔴 alternate_names IS NOT NULL DEFAULT '{}'.
--
-- Idempotent throughout. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_b int;
BEGIN
  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0049' AND geo_id LIKE 'allen-county-in-council-district-%';
  IF v_b <> 4 THEN
    RAISE EXCEPTION 'IN-5 pre-flight: X0049 holds % council boundaries, expected 4. Run scripts/load-allen-county-council-boundaries.ts first.', v_b;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id='18003' AND district_type='COUNTY' AND lower(state)='in') THEN
    RAISE EXCEPTION 'IN-5 pre-flight: the Allen County COUNTY district (18003) is missing.';
  END IF;
END $$;

-- ─── 1. Government ───────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Allen County, Indiana, US', 'County', 'IN', NULL, '18003'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Allen County, Indiana, US');

-- ─── 2. Three chambers ───────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM essentials.governments g
JOIN (VALUES
  ('Board of County Commissioners', 3),
  ('Allen County Council',          7),
  ('Elected Officials',             9)
) AS v(name, official_count) ON true
WHERE g.name = 'Allen County, Indiana, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Four county council districts (the countywide row already exists) ────

CREATE TEMP TABLE ac_districts(geo_id text, label text) ON COMMIT DROP;
INSERT INTO ac_districts(geo_id, label) VALUES
  ('allen-county-in-council-district-1', 'Allen County Council District 1'),
  ('allen-county-in-council-district-2', 'Allen County Council District 2'),
  ('allen-county-in-council-district-3', 'Allen County Council District 3'),
  ('allen-county-in-council-district-4', 'Allen County Council District 4');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'COUNTY', 'in', 'X0049'
FROM ac_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = n.geo_id AND d.district_type = 'COUNTY');

-- ─── 4. Nineteen offices ─────────────────────────────────────────────────────

CREATE TEMP TABLE ac_offices(geo_id text, chamber_name text, title text, description text, ord int) ON COMMIT DROP;
INSERT INTO ac_offices(geo_id, chamber_name, title, description, ord) VALUES
  -- 🔴 Commissioners: countywide electorate, district is residency only.
  ('18003', 'Board of County Commissioners', 'Commissioner, District 1',
   'Elected by the whole county; District 1 is a residency requirement for the officeholder, not an electorate.', NULL),
  ('18003', 'Board of County Commissioners', 'Commissioner, District 2',
   'Elected by the whole county; District 2 is a residency requirement for the officeholder, not an electorate.', NULL),
  ('18003', 'Board of County Commissioners', 'Commissioner, District 3',
   'Elected by the whole county; District 3 is a residency requirement for the officeholder, not an electorate.', NULL),
  -- County Council: four elected BY district.
  ('allen-county-in-council-district-1', 'Allen County Council', 'Council Member, District 1', NULL, NULL),
  ('allen-county-in-council-district-2', 'Allen County Council', 'Council Member, District 2', NULL, NULL),
  ('allen-county-in-council-district-3', 'Allen County Council', 'Council Member, District 3', NULL, NULL),
  ('allen-county-in-council-district-4', 'Allen County Council', 'Council Member, District 4', NULL, NULL),
  -- County Council: three at large, unnumbered, told apart by an INTERNAL ordinal.
  ('18003', 'Allen County Council', 'Council Member, At Large',
   'Internal ordinal 1 of 3. Allen County does not number its at-large council seats; not a ballot designation.', 1),
  ('18003', 'Allen County Council', 'Council Member, At Large',
   'Internal ordinal 2 of 3. Allen County does not number its at-large council seats; not a ballot designation.', 2),
  ('18003', 'Allen County Council', 'Council Member, At Large',
   'Internal ordinal 3 of 3. Allen County does not number its at-large council seats; not a ballot designation.', 3),
  -- The eight county officers, plus the Prosecuting Attorney.
  ('18003', 'Elected Officials', 'Assessor',                    NULL, NULL),
  ('18003', 'Elected Officials', 'Auditor',                     NULL, NULL),
  ('18003', 'Elected Officials', 'Clerk of the Circuit Court',  NULL, NULL),
  ('18003', 'Elected Officials', 'Coroner',                     NULL, NULL),
  ('18003', 'Elected Officials', 'Recorder',                    NULL, NULL),
  ('18003', 'Elected Officials', 'Sheriff',                     NULL, NULL),
  ('18003', 'Elected Officials', 'Surveyor',                    NULL, NULL),
  ('18003', 'Elected Officials', 'Treasurer',                   NULL, NULL),
  ('18003', 'Elected Officials', 'Prosecuting Attorney',
   'Elected in the 38th Judicial Circuit, which is coterminous with Allen County.', NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'IN', 1, false, 'full'
FROM ac_offices n
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.district_type = 'COUNTY' AND lower(d.state) = 'in'
JOIN essentials.governments g ON g.name = 'Allen County, Indiana, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── 5. Nineteen people ──────────────────────────────────────────────────────

CREATE TEMP TABLE ac_people(external_id bigint, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO ac_people VALUES
  (-1332168, 'Ron Turpin',            'Ron',          'Turpin'),
  (-1332169, 'Therese Brown',         'Therese',      'Brown'),
  (-1332170, 'Richard Beck',          'Richard',      'Beck'),
  (-1332171, 'Kyle Kerley',           'Kyle',         'Kerley'),
  (-1332172, 'Thomas Harris',         'Thomas',       'Harris'),
  (-1332173, 'Paul Lagemann',         'Paul',         'Lagemann'),
  (-1332174, 'Donald Wyss',           'Donald',       'Wyss'),
  (-1332175, 'Robert Armstrong',      'Robert',       'Armstrong'),
  (-1332176, 'Ken Fries',             'Ken',          'Fries'),
  (-1332177, 'Lindsey Hammond',       'Lindsey',      'Hammond'),
  (-1332178, 'Stacey O''Day',         'Stacey',       'O''Day'),
  (-1332179, 'Jacquelynn Scheuman',   'Jacquelynn',   'Scheuman'),
  (-1332180, 'Christopher Nancarrow', 'Christopher',  'Nancarrow'),
  (-1332181, 'Jon Brandenberger',     'Jon',          'Brandenberger'),
  (-1332182, 'Nicole Keesling',       'Nicole',       'Keesling'),
  (-1332183, 'Troy Hershberger',      'Troy',         'Hershberger'),
  (-1332184, 'Michael Fruchey',       'Michael',      'Fruchey'),
  (-1332185, 'Samantha Chenery',      'Samantha',     'Chenery'),
  (-1332186, 'Michael McAlexander',   'Michael',      'McAlexander');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Allen County elected officials, allencounty.in.gov directory and the county''s own Offices on the 2026 General Ballot, cross-checked against allencountygop.com, read 2026-09-10 (CC_0094, IN-5)',
       '{}'
FROM ac_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 6. Nineteen terms ───────────────────────────────────────────────────────

CREATE TEMP TABLE ac_terms(external_id bigint, geo_id text, title text, ord int,
                           term_start date, start_precision text, date_source text) ON COMMIT DROP;
INSERT INTO ac_terms VALUES
  (-1332168, '18003', 'Commissioner, District 1', NULL, DATE '2025-01-01', 'year', 'Ballotpedia tenure 2025 - Present'),
  (-1332169, '18003', 'Commissioner, District 2', NULL, DATE '2011-01-01', 'year', 'Ballotpedia tenure 2011 - Present'),
  (-1332170, '18003', 'Commissioner, District 3', NULL, NULL,             'unknown', 'No Ballotpedia page under any slug tried, and no other source publishes a tenure start'),
  (-1332171, 'allen-county-in-council-district-1', 'Council Member, District 1', NULL, DATE '2026-01-01', 'month',
   'Won the GOP caucus at noon 2026-01-16 after Josh Hale resigned effective 2026-01-15; the swearing-in DAY is not published'),
  (-1332172, 'allen-county-in-council-district-2', 'Council Member, District 2', NULL, DATE '2011-01-01', 'year', 'Ballotpedia tenure 2011 - Present'),
  (-1332173, 'allen-county-in-council-district-3', 'Council Member, District 3', NULL, DATE '2023-01-01', 'year', 'Ballotpedia tenure 2023 - Present'),
  (-1332174, 'allen-county-in-council-district-4', 'Council Member, District 4', NULL, DATE '2023-01-01', 'year', 'Ballotpedia tenure 2023 - Present'),
  (-1332175, '18003', 'Council Member, At Large', 1, DATE '2008-01-01', 'year', 'Ballotpedia tenure 2008 - Present'),
  (-1332176, '18003', 'Council Member, At Large', 2, DATE '2018-01-01', 'year', 'Ballotpedia tenure 2018 - Present'),
  (-1332177, '18003', 'Council Member, At Large', 3, DATE '2025-01-01', 'year', 'Ballotpedia tenure 2025 - Present'),
  (-1332178, '18003', 'Assessor',                   NULL, DATE '2014-01-01', 'year', 'Ballotpedia tenure 2014 - Present'),
  (-1332179, '18003', 'Auditor',                    NULL, DATE '2025-01-01', 'year', 'Ballotpedia tenure 2025 - Present'),
  (-1332180, '18003', 'Clerk of the Circuit Court', NULL, DATE '2019-01-01', 'year', 'Ballotpedia tenure 2019 - Present'),
  (-1332181, '18003', 'Coroner',                    NULL, DATE '2021-01-01', 'year', 'Ballotpedia tenure 2021 - Present'),
  (-1332182, '18003', 'Recorder',                   NULL, DATE '2023-01-01', 'year', 'Ballotpedia tenure 2023 - Present'),
  (-1332183, '18003', 'Sheriff',                    NULL, DATE '2023-01-01', 'year', 'Ballotpedia tenure 2023 - Present'),
  (-1332184, '18003', 'Surveyor',                   NULL, DATE '2022-01-01', 'year', 'Ballotpedia tenure 2022 - Present'),
  (-1332185, '18003', 'Treasurer',                  NULL, DATE '2025-01-01', 'year', 'Ballotpedia tenure 2025 - Present'),
  (-1332186, '18003', 'Prosecuting Attorney',       NULL, DATE '2023-01-01', 'year', 'Ballotpedia tenure 2023 - Present');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, 'unknown', 'Allen County IN-5 (CC_0094): ' || t.date_source
FROM ac_terms t
JOIN essentials.districts d ON d.geo_id = t.geo_id AND d.district_type = 'COUNTY' AND lower(d.state) = 'in'
JOIN essentials.offices o
  ON o.district_id = d.id AND o.title = t.title
 AND (t.ord IS NULL OR o.description LIKE 'Internal ordinal ' || t.ord || ' of 3%')
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'Allen County, Indiana, US'
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_ch int; v_off int; v_seated int; v_comm int; v_commcty int; v_cncl_d int; v_cncl_al int;
  v_officers int; v_year int; v_month int; v_unknown int; v_ended int; v_dupe int; v_nogeom int;
BEGIN
  SELECT count(*) INTO v_ch FROM essentials.chambers c
   JOIN essentials.governments g ON g.id=c.government_id WHERE g.name='Allen County, Indiana, US';
  IF v_ch <> 3 THEN RAISE EXCEPTION 'IN-5: % chambers, expected 3', v_ch; END IF;

  SELECT count(o.id), count(och.politician_id) INTO v_off, v_seated
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id=o.chamber_id
  JOIN essentials.governments g ON g.id=c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
  WHERE g.name='Allen County, Indiana, US';
  IF v_off <> 19 OR v_seated <> 19 THEN
    RAISE EXCEPTION 'IN-5: expected 19 offices all seated, got % offices / % seated', v_off, v_seated;
  END IF;

  -- 🔴 All three commissioners must be COUNTYWIDE. If any ends up on a sub-county district, a
  -- voter would see one of the three they elect.
  SELECT count(*) INTO v_comm FROM essentials.offices o
   JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.governments g ON g.id=c.government_id
   WHERE g.name='Allen County, Indiana, US' AND c.name='Board of County Commissioners';
  SELECT count(*) INTO v_commcty FROM essentials.offices o
   JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.governments g ON g.id=c.government_id
   JOIN essentials.districts d ON d.id=o.district_id
   WHERE g.name='Allen County, Indiana, US' AND c.name='Board of County Commissioners' AND d.geo_id='18003';
  IF v_comm <> 3 OR v_commcty <> 3 THEN
    RAISE EXCEPTION 'IN-5: % commissioner office(s), % of them countywide -- all 3 must sit on 18003, because Indiana elects them county-wide', v_comm, v_commcty;
  END IF;

  SELECT count(*) INTO v_cncl_d FROM essentials.offices o
   JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.governments g ON g.id=c.government_id
   JOIN essentials.districts d ON d.id=o.district_id
   WHERE g.name='Allen County, Indiana, US' AND c.name='Allen County Council' AND d.mtfcc='X0049';
  SELECT count(*) INTO v_cncl_al FROM essentials.offices o
   JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.governments g ON g.id=c.government_id
   JOIN essentials.districts d ON d.id=o.district_id
   WHERE g.name='Allen County, Indiana, US' AND o.title='Council Member, At Large' AND d.geo_id='18003';
  IF v_cncl_d <> 4 OR v_cncl_al <> 3 THEN
    RAISE EXCEPTION 'IN-5: council is % by-district + % at-large, expected 4 + 3', v_cncl_d, v_cncl_al;
  END IF;

  SELECT count(*) INTO v_officers FROM essentials.offices o
   JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.governments g ON g.id=c.government_id
   WHERE g.name='Allen County, Indiana, US' AND c.name='Elected Officials';
  IF v_officers <> 9 THEN RAISE EXCEPTION 'IN-5: % elected officers, expected 9 (8 county officers + Prosecuting Attorney)', v_officers; END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.offices o
    JOIN essentials.chambers c ON c.id=o.chamber_id JOIN essentials.governments g ON g.id=c.government_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
    WHERE g.name='Allen County, Indiana, US' AND o.title='Council Member, At Large'
    GROUP BY och.politician_id HAVING count(*)>1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'IN-5: an at-large person holds more than one at-large seat'; END IF;

  SELECT count(*) FILTER (WHERE ot.start_precision='year'),
         count(*) FILTER (WHERE ot.start_precision='month'),
         count(*) FILTER (WHERE ot.start_precision='unknown'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_year, v_month, v_unknown, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id=ot.office_id
  JOIN essentials.chambers c ON c.id=o.chamber_id
  JOIN essentials.governments g ON g.id=c.government_id
  WHERE g.name='Allen County, Indiana, US';
  IF v_year <> 17 OR v_month <> 1 OR v_unknown <> 1 THEN
    RAISE EXCEPTION 'IN-5: expected 17 year / 1 month / 1 unknown, got % / % / %', v_year, v_month, v_unknown;
  END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'IN-5: % terms carry a term_end; none may', v_ended; END IF;

  -- Every Allen County district carrying an office must have geometry.
  SELECT count(*) INTO v_nogeom FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='in'
     AND (d.geo_id='18003' OR d.geo_id LIKE 'allen-county-in-council-district-%')
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id=d.geo_id AND gb.mtfcc=d.mtfcc);
  IF v_nogeom <> 0 THEN RAISE EXCEPTION 'IN-5: % Allen County district(s) have no boundary', v_nogeom; END IF;

  RAISE NOTICE 'IN-5 OK: 19 offices, 19 seated, 3 commissioners ALL countywide, council 4+3, 9 officers, 17 year + 1 month + 1 unknown';
END $$;

COMMIT;
