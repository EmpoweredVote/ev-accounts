-- CC_0185_indianapolis_marion_consolidation.sql
-- Indianapolis / Marion County: one consolidated government, on the Nashville precedent.
-- Slot RESERVED from the allocator. Namespace CC per the operator (2026-09-29) -- the essentials
-- request document said `slot shared`, which is wrong for us: the namespace follows WHO DOES THE
-- WORK, not what the last migration was called.
--
-- Request document: essentials repo, ACCOUNTS-TEAM-REQUEST-indianapolis-consolidation.md
-- (branch docs/indianapolis-consolidation-request, PR #174).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE RULING
--
-- One government row on the COUNTY fips, labelled with the CITY name, and no separate county
-- entry. Nashville is the working example and this migration copies its exact shape:
--
--   Metropolitan Government of Nashville and Davidson County, Tennessee, US
--   type 'City' · city 'Nashville' · geo_id 47037 (a COUNTY fips)
--   chambers: 'Metropolitan Council' (41 offices) + 'Office of the Mayor' (1)
--   every office carries representing_city = 'Nashville'
--
-- ⚠ `governments.city` AND `governments.type` ARE BOTH LOAD BEARING AND THE REQUEST DOCUMENT
-- MENTIONS NEITHER. Nashville's row is type 'City' with city 'Nashville'; Marion County's is type
-- 'County' with city NULL. Renaming alone would leave Indianapolis looking like a county to every
-- consumer that reads those two columns.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- MEASURED BEFORE WRITING, 2026-09-29
--
--   City of Indianapolis, Indiana, US  395ccf2c-9369-45ab-b435-dde768fc4561
--     geo_id NULL -- which is WHY it is unreachable: a landing chip is keyed on governments.geo_id
--     6 chambers, 6 offices, 6 seated, every representing_city = ''
--     5 council chambers of ONE office each, all named '/Marion City/County Council - District N'
--       (note the leading slash), districts 8/12/13/14/18, geo_ids 18097000NN
--     1 'City Mayor' chamber -- Joe Hogsett
--
--   Marion County, Indiana, US         10dc8fce-2722-4301-a896-3bcad3d5e01e
--     geo_id 18097, type 'County', city NULL
--     38 offices, 38 seated, county-wide. LEFT ENTIRELY ALONE by this migration.
--
-- ⚠ THE REQUEST DOCUMENT SAYS MARION COUNTY HAS "11 CHAMBERS". THAT IS TRUE BY NAME AND FALSE BY
-- ROW: it has 38 chamber rows, 28 of them all named 'Superior Court Judge' with one office each --
-- the same one-chamber-per-office defect this migration fixes on the city side, twenty-eight times
-- over. Do not write a verification that counts county chambers. Office counts are safe.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE ROSTER: 25 SEATS, 5 HELD, 20 CREATED
--
-- indy.gov states its own denominator: "The City-County has 25 Councilors, one for each district."
--
-- Confirmed twice, independently, 2026-09-29:
--   Source A  the rendered member index, indy.gov/activity/city-county-council-members
--   Source B  the public Hygraph CMS the site itself queries --
--             api-us-east-1-indy.graphcms.com/v2/ckp3xrh1i657g01xp53az2mv4/master
--             25 published Person records; 23 biographies state the district outright.
--
-- 🔴 indy.gov CANNOT BE READ WITH curl. Every page returns HTTP 200 with a ~4.3 KB client-rendered
-- shell; a councillor's name appears only in the canonical URL. A 200 here is not evidence of
-- content. Use the GraphQL endpoint above, or a headless render.
--
-- The two rows the CMS could not confirm were closed by ONE HEADLESS RENDER EACH rather than
-- seeded on a single source:
--   District 5  Maggie A. Lewis  -- page heading "Councilor Maggie A. Lewis", body "District 5 and
--                                   Council President"
--   District 23 Derek Cahill     -- page heading "Councilor Derek Cahill", body "elected to serve
--                                   the 23rd District ... in November, 2023"
-- Closure also agrees: the 23 CMS-confirmed districts leave exactly {5, 23} for exactly these two.
--
-- 🔴 NO TERM IS WRITTEN. Not one source states a term start. Cahill's bio gives an ELECTION date
-- ("November, 2023") and that is NOT a term start -- deriving 2024-01-01 from it, or from "four-year
-- term" plus the 2023 election, would be inventing a date. ADR 0002 makes term_start nullable
-- precisely for this, so every new term is open-ended with start_precision 'unknown'.
--
-- ⚠ LEADERSHIP ROLES ARE DELIBERATELY NOT ENCODED. Lewis is Council President, Barth Vice
-- President, Evans Majority Leader, Mowery Minority Leader. Those rotate among members and are NOT
-- properties of the SEAT, so putting them on offices.title or offices.description would make a
-- claim that goes stale without anything changing in the world.
--
-- ⚠ PARTY IS NOT RECORDED. Only 9 of 25 bios state one, and party is antipartisan here anyway --
-- it lives on races.primary_party, never on a person.
--
-- 🔴 TWO NAME COLLISIONS FOUND AND DELIBERATELY NOT REUSED. The duplicate-name guard keys on
-- (first_name, last_name) and it hit twice:
--     Jessica Mccormick   2f1440e0-aba4-4a94-8dd6-88a8d981b9f9
--     Michael-paul Hart   fd43a41a-d16d-462f-a68c-d60d9cab52e9
-- Both are inert residue of the RETIRED indiana_discovery wave (source 'indiana_discovery',
-- created 2026-05-22, inactive, no office, no terms, no stances, no bio, no URLs, and the naive
-- title-casing of their names). The five councillors already seeded came from 'ballotready', a
-- DIFFERENT pipeline -- so nothing ties these two rows to Indianapolis rather than anywhere else in
-- Indiana. Reusing a row of uncertain identity conflates two real people; a duplicate of an inert
-- orphan strands nothing. They are recorded here so a later pass can merge them IF evidence
-- appears. Do not merge them on the name alone.

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────
-- Refuse to run against a shape this migration was not written for.
DO $$
DECLARE v_city int; v_county int;
BEGIN
  SELECT count(*) INTO v_city   FROM essentials.governments
   WHERE id = '395ccf2c-9369-45ab-b435-dde768fc4561' AND geo_id IS NULL;
  SELECT count(*) INTO v_county FROM essentials.governments
   WHERE id = '10dc8fce-2722-4301-a896-3bcad3d5e01e' AND geo_id = '18097';
  IF v_city <> 1 OR v_county <> 1 THEN
    RAISE EXCEPTION 'CC_0185 precondition: expected the City of Indianapolis row (geo_id NULL) and the Marion County row (geo_id 18097); found % and %', v_city, v_county;
  END IF;
END $$;

-- ── 1. One council chamber, and a Mayor's office, on the consolidated government ─────────────

INSERT INTO essentials.chambers (government_id, name)
SELECT '10dc8fce-2722-4301-a896-3bcad3d5e01e', 'City-County Council'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e' AND name = 'City-County Council');

INSERT INTO essentials.chambers (government_id, name)
SELECT '10dc8fce-2722-4301-a896-3bcad3d5e01e', 'Office of the Mayor'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e' AND name = 'Office of the Mayor');

-- ── 2. Move the 6 existing offices across, and clean their titles ────────────────────────────
-- The office ids do NOT change, so office_terms and every seated holder come with them untouched.
-- That is the whole reason this is a move and not a re-seed.

UPDATE essentials.offices o
   SET chamber_id = (SELECT id FROM essentials.chambers
                      WHERE government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e'
                        AND name = 'City-County Council'),
       title = 'Councilor, District ' || d.district_id,
       representing_city = 'Indianapolis'
  FROM essentials.districts d
 WHERE d.id = o.district_id
   AND o.chamber_id IN (SELECT id FROM essentials.chambers
                         WHERE government_id = '395ccf2c-9369-45ab-b435-dde768fc4561')
   AND o.title LIKE '%Council - District%';

UPDATE essentials.offices
   SET chamber_id = (SELECT id FROM essentials.chambers
                      WHERE government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e'
                        AND name = 'Office of the Mayor'),
       title = 'Mayor',
       representing_city = 'Indianapolis'
 WHERE chamber_id IN (SELECT id FROM essentials.chambers
                       WHERE government_id = '395ccf2c-9369-45ab-b435-dde768fc4561')
   AND title = 'City Mayor';

-- ── 3. The 20 districts that do not exist yet ────────────────────────────────────────────────
-- Shape copied exactly from the existing five: COUNTY type, mtfcc X0062, county-level ocd_id,
-- geo_id = '18097' || lpad(N, 5, '0'). ⚠ ocd_id ROLLS UP and is the same for all 25; geo_id is
-- what LOOKS UP, and it is the (mtfcc, geo_id) pair that is unique, never geo_id alone.

INSERT INTO essentials.districts
  (ocd_id, label, district_type, district_id, subtype, state, city, mtfcc, geo_id,
   is_judicial, has_unknown_boundaries, retention, representation_basis)
SELECT 'ocd-division/country:us/state:in/county:marion',
       'District ' || n, 'COUNTY', n::text, 'District', 'IN', '', 'X0062',
       '18097' || lpad(n::text, 5, '0'),
       false, true, false, 'residency'
  FROM generate_series(1, 25) AS n
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.districts d
    WHERE d.mtfcc = 'X0062' AND d.geo_id = '18097' || lpad(n::text, 5, '0'));

-- ── 4. The 20 offices ────────────────────────────────────────────────────────────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city)
SELECT (SELECT id FROM essentials.chambers
         WHERE government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e'
           AND name = 'City-County Council'),
       d.id, 'Councilor, District ' || d.district_id, 'IN', 'Indianapolis'
  FROM essentials.districts d
 WHERE d.mtfcc = 'X0062'
   AND d.geo_id LIKE '18097000%'
   AND d.district_id::int BETWEEN 1 AND 25
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ── 5. The 20 councillors, and their open-ended terms ────────────────────────────────────────
-- 🔴 is_incumbent IS SET EXPLICITLY. It defaults to false since CA_0188, and a seated person
-- inserted without it is HIDDEN from address search. check:occupancy fails an INSERT that omits it.

WITH incoming(district, first_name, last_name, full_name) AS (VALUES
  ( 1, 'Leroy',        'Robinson',   'Leroy Robinson'),
  ( 2, 'Brienne',      'Delaney',    'Brienne Delaney'),
  ( 3, 'Dan',          'Boots',      'Dan Boots'),
  ( 4, 'Nick',         'Roberts',    'Nick Roberts'),
  ( 5, 'Maggie',       'Lewis',      'Maggie A. Lewis'),
  ( 6, 'Carlos',       'Perkins',    'Carlos Perkins'),
  ( 7, 'John',         'Barth',      'John Barth'),
  ( 9, 'Keith',        'Graves',     'Keith L. Graves'),
  (10, 'Ali',          'Brown',      'Ali Brown'),
  (11, 'Crista',       'Wells',      'Crista Lee Wells'),
  (15, 'Rena',         'Allen',      'Rena Allen'),
  (16, 'Jessica',      'McCormick',  'Jessica McCormick'),
  (17, 'Jared',        'Evans',      'Jared Evans'),
  (19, 'Frank',        'Mascari',    'Frank Mascari'),
  (20, 'Michael-Paul', 'Hart',       'Michael-Paul Hart'),
  (21, 'Josh',         'Masquelier', 'Josh Masquelier'),
  (22, 'Paul',         'Annee',      'Paul Annee'),
  (23, 'Derek',        'Cahill',     'Derek Cahill'),
  (24, 'Michael',      'Dilk',       'Michael Dilk'),
  (25, 'Brian',        'Mowery',     'Brian Mowery')
), created AS (
  INSERT INTO essentials.politicians
    (first_name, last_name, full_name, is_active, is_incumbent, is_vacant, source)
  SELECT i.first_name, i.last_name, i.full_name, true, true, false,
         'indy.gov City-County Council member index + Hygraph CMS Person records, retrieved 2026-09-29 | CC_0185'
    FROM incoming i
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.politicians p
      WHERE p.full_name = i.full_name AND p.is_active AND p.is_incumbent)
  RETURNING id, full_name
)
-- 🔴 seat_officeholder IS NOT USED HERE, AND THAT IS DELIBERATE. It REFUSES a NULL term_start:
--    "seat_officeholder requires a real term_start. If the source gives only a year, pass Jan 1
--     with p_start_precision => 'year' rather than NULL."
-- That guard is right for a source that gives a year. It has no path for a source that gives
-- NOTHING, which is this case -- and CLAUDE.md is explicit that a genuinely unknown start is
-- written open-ended rather than guessed. Taking the helper's advice here would mean inventing
-- January the 1st, which is exactly the error the rule forbids.
-- So this writes office_terms directly, in the shape the earlier waves used for the same reason:
-- term_start NULL, start_precision 'unknown', how_started 'unknown'
-- (Pennsylvania 252 rows, Georgia 235, Minnesota 200, Mississippi 167, ADR 0002 phase-2 3,962).
-- Safe without the helper's two-step because these offices are NEW and hold no predecessor term
-- for an open-ended range to collide with.
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, c.id, NULL::date, NULL::date, 'unknown', 'unknown',
       'indy.gov + Hygraph CMS, retrieved 2026-09-29 | CC_0185'
  FROM created c
  JOIN incoming i ON i.full_name = c.full_name
  JOIN essentials.districts d
    ON d.mtfcc = 'X0062' AND d.geo_id = '18097' || lpad(i.district::text, 5, '0')
  JOIN essentials.offices o ON o.district_id = d.id;

-- ── 6. The consolidated government row ───────────────────────────────────────────────────────
-- 🔴 type AND city, not just the name -- see the header. geo_id stays 18097.

UPDATE essentials.governments
   SET name = 'Consolidated City of Indianapolis and Marion County, Indiana, US',
       type = 'City',
       city = 'Indianapolis'
 WHERE id = '10dc8fce-2722-4301-a896-3bcad3d5e01e';

-- ── 7. Retire the emptied City of Indianapolis row ───────────────────────────────────────────
-- 🔴 ORDER MATTERS AND NOTHING WILL STOP YOU GETTING IT WRONG. chambers.government_id has no FK
-- and districts has no inbound FKs at all, so deleting the government first would orphan its
-- chambers silently, with no error. Chambers first, and only those proven empty.

DELETE FROM essentials.chambers c
 WHERE c.government_id = '395ccf2c-9369-45ab-b435-dde768fc4561'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id);

DELETE FROM essentials.governments g
 WHERE g.id = '395ccf2c-9369-45ab-b435-dde768fc4561'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id);

-- ── 8. Post-verify gate ──────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_council int; v_seated int; v_districts int; v_mayor int;
  v_city_rows int; v_repr int; v_county int; v_orphan_ch int; v_terms_dated int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE geo_id = '18097' AND type = 'City' AND city = 'Indianapolis'
     AND name = 'Consolidated City of Indianapolis and Marion County, Indiana, US';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'CC_0185 gate: expected 1 consolidated government on 18097, found %', v_gov;
  END IF;

  SELECT count(DISTINCT o.id), count(DISTINCT och.politician_id), count(DISTINCT o.district_id)
    INTO v_council, v_seated, v_districts
    FROM essentials.chambers c
    JOIN essentials.offices o ON o.chamber_id = c.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e'
     AND c.name = 'City-County Council';
  IF v_council <> 25 OR v_seated <> 25 OR v_districts <> 25 THEN
    RAISE EXCEPTION 'CC_0185 gate: City-County Council has % offices / % seated / % distinct districts, expected 25/25/25',
      v_council, v_seated, v_districts;
  END IF;

  SELECT count(*) INTO v_mayor
    FROM essentials.chambers c
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e'
     AND c.name = 'Office of the Mayor' AND och.politician_id IS NOT NULL;
  IF v_mayor <> 1 THEN
    RAISE EXCEPTION 'CC_0185 gate: expected 1 seated Mayor, found %', v_mayor;
  END IF;

  -- representing_city is load bearing: buildingImages resolves the city banner off it, so an
  -- empty string means no banner even once a chip exists.
  SELECT count(*) INTO v_repr
    FROM essentials.chambers c
    JOIN essentials.offices o ON o.chamber_id = c.id
   WHERE c.government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e'
     AND c.name IN ('City-County Council', 'Office of the Mayor')
     AND o.representing_city = 'Indianapolis';
  IF v_repr <> 26 THEN
    RAISE EXCEPTION 'CC_0185 gate: % city offices carry representing_city Indianapolis, expected 26', v_repr;
  END IF;

  -- The county's own 38 are untouched. Counted by OFFICE, never by chamber -- see the header.
  SELECT count(*) INTO v_county
    FROM essentials.chambers c
    JOIN essentials.offices o ON o.chamber_id = c.id
   WHERE c.government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e'
     AND c.name NOT IN ('City-County Council', 'Office of the Mayor');
  IF v_county <> 38 THEN
    RAISE EXCEPTION 'CC_0185 gate: county side holds % offices, expected 38 untouched', v_county;
  END IF;

  SELECT count(*) INTO v_city_rows FROM essentials.governments
   WHERE id = '395ccf2c-9369-45ab-b435-dde768fc4561';
  IF v_city_rows <> 0 THEN
    RAISE EXCEPTION 'CC_0185 gate: the City of Indianapolis row still exists';
  END IF;

  -- 🔴 The delete must not have left chambers behind pointing at a government that is gone.
  SELECT count(*) INTO v_orphan_ch
    FROM essentials.chambers c
   WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = c.government_id);
  IF v_orphan_ch <> 0 THEN
    RAISE EXCEPTION 'CC_0185 gate: % orphaned chamber(s) point at a missing government', v_orphan_ch;
  END IF;

  -- No invented dates: every term written here is open-ended.
  SELECT count(*) INTO v_terms_dated
    FROM essentials.chambers c
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE c.government_id = '10dc8fce-2722-4301-a896-3bcad3d5e01e'
     AND c.name = 'City-County Council'
     AND ot.term_start IS NOT NULL;
  IF v_terms_dated > 5 THEN
    RAISE EXCEPTION 'CC_0185 gate: % council terms carry a term_start; only the 5 pre-existing may', v_terms_dated;
  END IF;

  RAISE NOTICE 'CC_0185 gate PASSED: one government on 18097 (type City, city Indianapolis); City-County Council 25 offices / 25 seated / 25 districts; Mayor 1; 26 offices representing_city Indianapolis; county 38 untouched; City of Indianapolis row retired with no orphaned chambers.';
END $$;

COMMIT;
