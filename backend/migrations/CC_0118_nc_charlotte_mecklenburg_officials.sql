-- CC_0118_nc_charlotte_mecklenburg_officials.sql
-- Knight Foundation program, wave NC-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0117, which creates the 28 offices this seats.
--
--   City of Charlotte      12 people   Mayor + 4 at large + 7 district
--   Mecklenburg County     16 people   9 commissioners + 4 officers + 3 soil and water supervisors
--
-- 28 offices, 28 people, 0 vacancies.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 EVERY term_start IS THE BEGINNING OF CONTINUOUS OCCUPANCY OF THAT OFFICE, not the
-- member's first election and not the current term's start. Two entries prove why the
-- distinction is not pedantry, and they point in OPPOSITE directions:
--
--   JAMES MITCHELL has been an at-large council member on and off since 2013. He RESIGNED the
--   seat effective 2021-01-11 and returned in 2022. A "first elected" field dates him to 2013;
--   his continuous occupancy begins 2022-09-06. The field OVERSTATES.
--
--   GEORGE DUNLAP's Mecklenburg biography says "first elected in 2008". The board's own
--   2006-2008 roster says "Valerie C. Woodard (D) District 3 (Deceased - Died 10-3-08) /
--   George R. Dunlap (D) District 3 (Effective 10-30-08 Sworn-in 10-31-08)". He was APPOINTED to
--   a vacancy six weeks before that term began. The field UNDERSTATES.
--
-- Both were found only by walking the bodies' own term-by-term records: the City Clerk's
-- 1991-2027 mayor-and-council history PDF, and the BOCC's past-and-present roster back to 1938.
--
-- 🔴 THE NINE-MONTH HOLDOVER IS WRITTEN AS CONTINUOUS OCCUPANCY, DELIBERATELY. There was no 2021
-- Charlotte municipal election: the city's own history footnote reads "Municipal elections were
-- delayed until July 2022 after the COVID-19 pandemic delayed US Census data needed to redraw
-- City Council district maps." The 2019 term expired 2021-12-06 and the next members were sworn
-- 2022-09-06. Incumbents held over under North Carolina law, so Graham (2019-12-02), Johnson
-- (2019-12-02) and Driggs (2013-12-02) carry UNBROKEN terms across that interval. Writing a
-- closed term plus a new one would assert a nine-month vacancy that did not happen.
--
-- 🔴 FOUR ROWS SHIP BELOW `day` PRECISION AND THAT IS THE HONEST ANSWER. North Carolina seats
-- county officers on the first Monday in December, and the BOCC publishes that exact date for
-- every term, so 2018-12-03 / 2016-12-05 / 2014-12-01 are all available AS AN INFERENCE for the
-- Sheriff, the Register of Deeds and the Clerk of Superior Court. The sources say a year, so the
-- rows say a year. Nancy Carter ships at `month` because her source says "January, 2012".
-- Don't invent dates.
--
-- 🔴 THREE ROWS START BY APPOINTMENT, NOT ELECTION, and how_started records which:
--   Rob Harrington  appointed by the City Council 2026-06-22 to the remainder of Vi Lyles' term
--                   after she resigned effective 2026-06-30; sworn in 2026-07-01.
--   George Dunlap   appointed to a District 3 vacancy caused by a death, sworn 2008-10-31.
--   Nancy Carter    appointed to the soil and water board in January 2012, elected in 2014;
--                   her OCCUPANCY starts at the appointment.
--
-- ⚠ THE MAYOR'S OFFICE IS `Mayor`, NOT "Interim Mayor". Every news outlet calls Harrington
-- interim. The city's own page calls him "Mayor Rob Harrington, the 60th mayor of Charlotte" and
-- its swearing-in notice says he "was appointed by Charlotte City Council to serve the remainder
-- of Vi Lyles' term" through December 2027. Under N.C. law the appointee holds the office for the
-- unexpired term. "Interim" is journalism, not the seat.
--
-- 🔴 NAME COLLISIONS: NONE. All 28 (first_name, last_name) pairs were checked against
-- essentials.politicians and every one returned zero rows -- and the check was CONTROLLED, because
-- 28 zeroes is a uniform answer: the same query returns 1 for ('Alma','Adams') and ('Becky',
-- 'Carney'), both sitting NC officeholders already in production, and 0 for a nonsense name.
-- So essentials.politician_name_duplicate_guard blocks nothing here and there is nobody to reuse.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party, never on a person or an office.
-- The soil and water election is nonpartisan by statute in any case.
--
-- 🔴 THE UNNUMBERED SEATS -- 4 council at-large, 3 commission at-large, 3 soil and water -- share
-- one title within their chamber, so a person is joined to a seat through the INTERNAL ordinal
-- CC_0117 wrote into `description`. Nothing reads that as a seat name.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── Pre-flight: CC_0117 must have run ──────────────────────────────────────────

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('3712000','37119');
  IF v <> 28 THEN
    RAISE EXCEPTION 'NC-3 pre-flight: expected 28 Charlotte/Mecklenburg offices, found %. Apply CC_0117 first.', v;
  END IF;
END $$;

-- ─── 28 people ──────────────────────────────────────────────────────────────────

CREATE TEMP TABLE nc3_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[], source text)
  ON COMMIT DROP;

INSERT INTO nc3_people VALUES
  (-3712001,'Rob Harrington','Rob','Harrington','{}'::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; swearing-in notice published 2026-07-01; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712002,'Dimple Ajmera','Dimple','Ajmera','{}'::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712003,'LaWana Mayfield','LaWana','Mayfield','{}'::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712004,'James Mitchell Jr.','James','Mitchell',ARRAY['James Mitchell','James "Smuggie" Mitchell Jr.']::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712005,'Victoria Watlington','Victoria','Watlington',ARRAY['Dr. Victoria Watlington']::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712006,'Danté Anderson','Danté','Anderson',ARRAY['Dante Anderson']::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712007,'Malcolm Graham','Malcolm','Graham','{}'::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712008,'Joi Mayo','Joi','Mayo','{}'::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712009,'Reneé Johnson','Reneé','Johnson',ARRAY['Reneé Perkins Johnson','Renee Johnson']::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712010,'JD Mazuera Arias','JD','Mazuera Arias',ARRAY['Juan Diego Mazuera Arias']::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712011,'Kimberly Owens','Kimberly','Owens','{}'::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712012,'Edmund H. Driggs','Edmund','Driggs',ARRAY['Ed Driggs']::text[],'City of Charlotte, Mayor and City Council pages and the City Clerk''s mayor-council-history-1991-2027 PDF; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),

  (-3712013,'Leigh Altman','Leigh','Altman','{}'::text[],'Mecklenburg Board of County Commissioners, bocc.mecknc.gov and its past-and-present-commissioners roster; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712014,'Arthur Griffin','Arthur','Griffin','{}'::text[],'Mecklenburg Board of County Commissioners, bocc.mecknc.gov and its past-and-present-commissioners roster; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712015,'Yvette Townsend-Ingram','Yvette','Townsend-Ingram','{}'::text[],'Mecklenburg Board of County Commissioners, bocc.mecknc.gov and its past-and-present-commissioners roster; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712016,'Elaine Powell','Elaine','Powell','{}'::text[],'Mecklenburg Board of County Commissioners, bocc.mecknc.gov and its past-and-present-commissioners roster; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712017,'Vilma D. Leake','Vilma','Leake',ARRAY['Vilma Leake']::text[],'Mecklenburg Board of County Commissioners, bocc.mecknc.gov and its past-and-present-commissioners roster; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712018,'George Dunlap','George','Dunlap',ARRAY['George R. Dunlap']::text[],'Mecklenburg Board of County Commissioners, bocc.mecknc.gov and its past-and-present-commissioners roster (2006-2008 entry records the appointment); change-checked against his own page, read 2026-09-17 (NC-3)'),
  (-3712019,'Mark Jerrell','Mark','Jerrell',ARRAY['Mark D. Jerrell']::text[],'Mecklenburg Board of County Commissioners, bocc.mecknc.gov and its past-and-present-commissioners roster; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712020,'Laura J. Meier','Laura','Meier',ARRAY['Laura Meier']::text[],'Mecklenburg Board of County Commissioners, bocc.mecknc.gov and its past-and-present-commissioners roster; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),
  (-3712021,'Susan Rodriguez-McDowell','Susan','Rodriguez-McDowell','{}'::text[],'Mecklenburg Board of County Commissioners, bocc.mecknc.gov and its past-and-present-commissioners roster; change-checked against each member''s own page, read 2026-09-17 (NC-3)'),

  (-3712022,'Garry L. McFadden','Garry','McFadden',ARRAY['Garry McFadden']::text[],'Mecklenburg County Sheriff''s Office, mecksheriff.com ("45th Sheriff of the Mecklenburg County Sheriff''s Office"), read 2026-09-17 (NC-3)'),
  (-3712023,'Fredrick Smith','Fredrick','Smith',ARRAY['Fred Smith']::text[],'Mecklenburg County Register of Deeds, deeds.mecknc.gov/Fredrick-Smith ("Fred was first elected to office in 2016"), read 2026-09-17 (NC-3)'),
  (-3712024,'Elisa Chinn-Gary','Elisa','Chinn-Gary',ARRAY['Elisa Chinn Gary']::text[],'Mecklenburg County Court, mecklenburgcountycourt.org; first elected November 2014, sworn for a second term 2018-12-03, read 2026-09-17 (NC-3)'),
  (-3712025,'Spencer B. Merriweather III','Spencer','Merriweather',ARRAY['Spencer Merriweather']::text[],'Mecklenburg County District Attorney, charmeckda.com/about-the-da ("sworn into office on November 27, 2017, and he was subsequently elected in 2018 by the people of Mecklenburg County"), read 2026-09-17 (NC-3)'),

  (-3712026,'Barbara Bleiweis','Barbara','Bleiweis','{}'::text[],'Mecklenburg Soil and Water Conservation District, conserve.mecknc.gov/Board ("served on the Board since 2017 and is in her second term as an elected Supervisor"), read 2026-09-17 (NC-3)'),
  (-3712027,'Nancy Carter','Nancy','Carter','{}'::text[],'Mecklenburg Soil and Water Conservation District, conserve.mecknc.gov/Board ("appointed to the Board in January, 2012, elected in 2014"), read 2026-09-17 (NC-3)'),
  (-3712028,'Mitchell Mullen','Mitchell','Mullen',ARRAY['Mitchel Mullen']::text[],'Mecklenburg Soil and Water Conservation District, conserve.mecknc.gov/Board ("will serve a four-year term effective December 4, 2024"), read 2026-09-17 (NC-3)');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, n.source, n.alternate_names
FROM nc3_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 28 dated terms, one per office ─────────────────────────────────────────────

CREATE TEMP TABLE nc3_terms(gov_geo_id text, district_geo_id text, district_mtfcc text, title text, description text,
                            external_id bigint, term_start date, start_precision text, how_started text) ON COMMIT DROP;

INSERT INTO nc3_terms VALUES
  ('3712000','3712000','G4110','Mayor','Elected citywide to a two-year term. Charlotte City Charter (S.L. 2000-26) s 3.23: the Mayor "shall preside, if present, but shall have no vote except in case of a tie, or as provided herein", and may veto an action of the Council, which requires at least seven members voting in the affirmative to override.',-3712001,'2026-07-01'::date,'day','appointed'),
  ('3712000','3712000','G4110','Council Member, At Large','Internal ordinal 1 of 4. Charlotte does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.',-3712002,'2017-12-04'::date,'day','elected'),
  ('3712000','3712000','G4110','Council Member, At Large','Internal ordinal 2 of 4. Charlotte does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.',-3712003,'2022-09-06'::date,'day','elected'),
  ('3712000','3712000','G4110','Council Member, At Large','Internal ordinal 3 of 4. Charlotte does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.',-3712004,'2022-09-06'::date,'day','elected'),
  ('3712000','3712000','G4110','Council Member, At Large','Internal ordinal 4 of 4. Charlotte does not number its at-large seats; all four are elected in one citywide race. Not a ballot designation.',-3712005,'2023-12-04'::date,'day','elected'),
  ('3712000','charlotte-nc-council-district-1','X0056','Council Member, District 1',NULL,-3712006,'2022-09-06'::date,'day','elected'),
  ('3712000','charlotte-nc-council-district-2','X0056','Council Member, District 2',NULL,-3712007,'2019-12-02'::date,'day','elected'),
  ('3712000','charlotte-nc-council-district-3','X0056','Council Member, District 3',NULL,-3712008,'2025-12-01'::date,'day','elected'),
  ('3712000','charlotte-nc-council-district-4','X0056','Council Member, District 4',NULL,-3712009,'2019-12-02'::date,'day','elected'),
  ('3712000','charlotte-nc-council-district-5','X0056','Council Member, District 5',NULL,-3712010,'2025-12-01'::date,'day','elected'),
  ('3712000','charlotte-nc-council-district-6','X0056','Council Member, District 6',NULL,-3712011,'2025-12-01'::date,'day','elected'),
  ('3712000','charlotte-nc-council-district-7','X0056','Council Member, District 7',NULL,-3712012,'2013-12-02'::date,'day','elected'),

  ('37119','37119','G4020','Commissioner, At Large','Internal ordinal 1 of 3. Mecklenburg does not number its at-large seats; all three are elected in one countywide race. Not a ballot designation.',-3712013,'2020-12-08'::date,'day','elected'),
  ('37119','37119','G4020','Commissioner, At Large','Internal ordinal 2 of 3. Mecklenburg does not number its at-large seats; all three are elected in one countywide race. Not a ballot designation.',-3712014,'2022-12-06'::date,'day','elected'),
  ('37119','37119','G4020','Commissioner, At Large','Internal ordinal 3 of 3. Mecklenburg does not number its at-large seats; all three are elected in one countywide race. Not a ballot designation.',-3712015,'2024-12-02'::date,'day','elected'),
  ('37119','mecklenburg-nc-commissioner-district-1','X0057','Commissioner, District 1',NULL,-3712016,'2018-12-03'::date,'day','elected'),
  ('37119','mecklenburg-nc-commissioner-district-2','X0057','Commissioner, District 2',NULL,-3712017,'2008-12-01'::date,'day','elected'),
  ('37119','mecklenburg-nc-commissioner-district-3','X0057','Commissioner, District 3',NULL,-3712018,'2008-10-31'::date,'day','appointed'),
  ('37119','mecklenburg-nc-commissioner-district-4','X0057','Commissioner, District 4',NULL,-3712019,'2018-12-03'::date,'day','elected'),
  ('37119','mecklenburg-nc-commissioner-district-5','X0057','Commissioner, District 5',NULL,-3712020,'2020-12-08'::date,'day','elected'),
  ('37119','mecklenburg-nc-commissioner-district-6','X0057','Commissioner, District 6',NULL,-3712021,'2018-12-03'::date,'day','elected'),

  ('37119','37119','G4020','Sheriff',NULL,-3712022,'2018-01-01'::date,'year','elected'),
  ('37119','37119','G4020','Register of Deeds',NULL,-3712023,'2016-01-01'::date,'year','elected'),
  ('37119','37119','G4020','Clerk of Superior Court',NULL,-3712024,'2014-01-01'::date,'year','elected'),
  ('37119','37119','G4020','District Attorney','Elected countywide. North Carolina Prosecutorial District 26 is coterminous with Mecklenburg County. A judicial-branch officer whom county voters elect, seated here under the inclusion ruling of 2026-09-17.',-3712025,'2017-11-27'::date,'day','appointed'),

  ('37119','37119','G4020','Soil and Water Conservation District Supervisor','Internal ordinal 1 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.',-3712026,'2017-01-01'::date,'year','elected'),
  ('37119','37119','G4020','Soil and Water Conservation District Supervisor','Internal ordinal 2 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.',-3712027,'2012-01-01'::date,'month','appointed'),
  ('37119','37119','G4020','Soil and Water Conservation District Supervisor','Internal ordinal 3 of 3. Elected countywide on a nonpartisan ballot; the seats are not numbered. Not a ballot designation.',-3712028,'2024-12-04'::date,'day','elected');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started, n.source || ' (CC_0118, NC-3)'
FROM nc3_terms t
JOIN essentials.districts d ON d.geo_id = t.district_geo_id AND d.mtfcc = t.district_mtfcc AND lower(d.state) = 'nc'
JOIN essentials.governments g ON g.geo_id = t.gov_geo_id
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.district_id = d.id AND o.chamber_id = c.id AND o.title = t.title
  AND o.description IS NOT DISTINCT FROM t.description
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN nc3_people n ON n.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_undated int; v_ended int;
  v_clt int; v_meck int; v_dupes int; v_prec int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN -3712028 AND -3712001;
  IF v_people <> 28 THEN RAISE EXCEPTION 'NC-3 occupancy: expected 28 people, got %', v_people; END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('3712000','37119');
  IF v_terms <> 28 THEN RAISE EXCEPTION 'NC-3 occupancy: expected 28 terms, got %', v_terms; END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*): office_current_holder LEFT JOINs from offices, so
  -- count(*) would pass vacuously on a table full of vacancies.
  SELECT count(och.politician_id) INTO v_seated
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.geo_id IN ('3712000','37119');
  IF v_seated <> 28 THEN RAISE EXCEPTION 'NC-3 occupancy: expected 28 seated offices, got %', v_seated; END IF;

  SELECT count(*) INTO v_clt FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.geo_id = '3712000' AND och.politician_id IS NOT NULL;
  SELECT count(*) INTO v_meck FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.geo_id = '37119' AND och.politician_id IS NOT NULL;
  IF v_clt <> 12 OR v_meck <> 16 THEN
    RAISE EXCEPTION 'NC-3 occupancy: expected Charlotte 12 / Mecklenburg 16 seated, got % / %', v_clt, v_meck;
  END IF;

  -- Every term is dated and none has ended. 🔴 term_end IS NULL is not "current" in general, but
  -- here it is asserted as a property of what this migration wrote.
  SELECT count(*) INTO v_undated
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('3712000','37119') AND (ot.term_start IS NULL OR ot.start_precision = 'unknown');
  IF v_undated <> 0 THEN RAISE EXCEPTION 'NC-3 occupancy: % term(s) undated or unknown-precision', v_undated; END IF;

  SELECT count(*) INTO v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('3712000','37119') AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'NC-3 occupancy: % term(s) already ended', v_ended; END IF;

  -- The precision mix is asserted, not assumed: 23 day, 4 year, 1 month.
  --   year  = Sheriff (2018), Register of Deeds (2016), Clerk of Superior Court (2014) and
  --           Barbara Bleiweis (2017) -- four sources that give a year and no more.
  --   month = Nancy Carter, whose source says "January, 2012".
  -- ⚠ This gate earned its keep during the dry run: it was first written expecting 24 day-precision
  -- terms, having missed that Bleiweis is a year too, and it refused the migration.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'day') INTO v_prec
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('3712000','37119');
  IF v_prec <> 23 THEN
    RAISE EXCEPTION 'NC-3 occupancy: expected 23 day-precision terms, got %', v_prec;
  END IF;

  SELECT count(*) INTO v_prec
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('3712000','37119') AND ot.start_precision = 'year';
  IF v_prec <> 4 THEN
    RAISE EXCEPTION 'NC-3 occupancy: expected 4 year-precision terms, got %', v_prec;
  END IF;

  SELECT count(*) INTO v_prec
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('3712000','37119') AND ot.start_precision = 'month';
  IF v_prec <> 1 THEN
    RAISE EXCEPTION 'NC-3 occupancy: expected 1 month-precision term (Nancy Carter), got %', v_prec;
  END IF;

  -- 🔴 NOBODY HOLDS TWO OF THESE SEATS. office_current_holder fans out when joined FROM
  -- politicians, so a person seated twice would be invisible to a per-office count.
  SELECT count(*) INTO v_dupes FROM (
    SELECT och.politician_id
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE g.geo_id IN ('3712000','37119') AND och.politician_id IS NOT NULL
    GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dupes <> 0 THEN RAISE EXCEPTION 'NC-3 occupancy: % person(s) hold more than one NC-3 seat', v_dupes; END IF;

  RAISE NOTICE 'NC-3 occupancy OK: % people, % terms, % seated (Charlotte % / Mecklenburg %), 0 undated, 0 ended',
    v_people, v_terms, v_seated, v_clt, v_meck;
END $$;

COMMIT;
