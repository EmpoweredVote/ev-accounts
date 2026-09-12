\set ON_ERROR_STOP on
BEGIN;
\echo === migrations/CC_0096_gary_council_districts_structure.sql ===
-- CC_0096_gary_council_districts_structure.sql
-- Knight Foundation program, wave IN-8 (structure half). Slot RESERVED from the allocator.
--
-- Creates Gary's SIX council district rows and their SIX offices, on the boundaries
-- scripts/load-gary-council-boundaries.ts wrote to mtfcc 'X0050'.
-- Creates NO people and NO terms -- CC_0097 does that, applied immediately after.
--
-- After this pair, the Gary Common Council holds 9 of 9 seats: 3 at-large (IN-4) + 6 district.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS MIGRATION EXISTS BECAUSE A NEGATIVE RESULT WAS TRUE OF THE PLACE WE LOOKED.
--
-- IN-4 deferred these six seats: the City's own GeoJSON repo has ONE COMMIT from 2014-07-21,
-- the City's live GIS carries no council layer, and Lake County published the districts as PDF
-- only. IN-6 then swept Lake County's open-data organisation (`lakecountyod`, 174 layers) and
-- recorded that it holds NO electoral district layer.
--
-- All of that was true, and the conclusion drawn from it -- that the geometry does not exist --
-- was false. The layer is public, in a DIFFERENT ArcGIS organisation: the Lake County
-- SURVEYOR's hub (`lakecountyhub-lakeingispro`), linked from the county's own "Request GIS Map
-- or Data" button. ▶ A NEGATIVE RESULT IS ONLY EVER TRUE OF THE PLACE YOU LOOKED.
--
-- 🔴🔴 AND TWO WRONG MAPS WERE REJECTED BEFORE THIS ONE WAS ACCEPTED.
--   1. The City's 2014 GeoJSON -- right format, right projection, right names, nine years stale.
--   2. Census `tl_2020_18_vtd20` -- all 52 Gary precincts under the SAME `G<d>-<p>` naming,
--      dissolving into a six-district map that looks correct at a glance, and is the
--      PRE-SETTLEMENT assignment.
-- The loader's GATE 2 separates them on three precincts -- G4 01, G5 22, G5 28 -- which this
-- layer and the Board of Elections' own 2024-03-01 map carry and TIGER 2020 does not.
--
-- ⚠ THE DISTRICTS ARE A DISSOLVE, NOT A PUBLISHED LAYER. The council district is the leading
-- digit of the precinct's P26 name. Each of the six dissolves to ONE connected valid polygon
-- with zero pairwise overlap, which is itself evidence the assignment is coherent.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────
-- 🔴 The six boundaries must already exist. Creating an office with no geometry is the defect
-- this slice measured at 671 unreachable Indiana offices, and it is exactly what IN-4 refused
-- to do. If the loader has not run, stop here.

DO $$
DECLARE v_b int; v_gov int; v_ch int;
BEGIN
  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0050' AND geo_id LIKE 'gary-in-council-district-%';
  IF v_b <> 6 THEN
    RAISE EXCEPTION 'IN-8 pre-flight: % X0050 Gary council boundaries, expected 6. Run scripts/load-gary-council-boundaries.ts first.', v_b;
  END IF;

  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'City of Gary, Indiana, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'IN-8 pre-flight: % Gary government rows, expected 1 (CC_0092)', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND c.name = 'Gary Common Council';
  IF v_ch <> 1 THEN RAISE EXCEPTION 'IN-8 pre-flight: Gary Common Council chamber missing (CC_0092)'; END IF;
END $$;

-- ─── 1. Six districts ────────────────────────────────────────────────────────

CREATE TEMP TABLE gary_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO gary_districts VALUES
  ('gary-in-council-district-1', 'Gary City Council District 1', 'X0050'),
  ('gary-in-council-district-2', 'Gary City Council District 2', 'X0050'),
  ('gary-in-council-district-3', 'Gary City Council District 3', 'X0050'),
  ('gary-in-council-district-4', 'Gary City Council District 4', 'X0050'),
  ('gary-in-council-district-5', 'Gary City Council District 5', 'X0050'),
  ('gary-in-council-district-6', 'Gary City Council District 6', 'X0050');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'in', n.mtfcc
FROM gary_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = n.geo_id AND d.district_type = 'LOCAL');

-- ─── 2. Six offices ──────────────────────────────────────────────────────────

CREATE TEMP TABLE gary_district_offices(geo_id text, title text) ON COMMIT DROP;
INSERT INTO gary_district_offices VALUES
  ('gary-in-council-district-1', 'Council Member, District 1'),
  ('gary-in-council-district-2', 'Council Member, District 2'),
  ('gary-in-council-district-3', 'Council Member, District 3'),
  ('gary-in-council-district-4', 'Council Member, District 4'),
  ('gary-in-council-district-5', 'Council Member, District 5'),
  ('gary-in-council-district-6', 'Council Member, District 6');

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, NULL, 'IN', 'Gary', 1, false, 'full'
FROM gary_district_offices n
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.governments g ON g.name = 'City of Gary, Indiana, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Gary Common Council'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_d int; v_nogeom int; v_off int; v_council int; v_atlarge int; v_count int; v_fan int;
BEGIN
  SELECT count(*) INTO v_d FROM essentials.districts
   WHERE mtfcc = 'X0050' AND district_type = 'LOCAL' AND lower(state) = 'in';
  IF v_d <> 6 THEN RAISE EXCEPTION 'IN-8 structure: % X0050 districts, expected 6', v_d; END IF;

  -- Every district created here must have geometry. This is the whole reason IN-4 deferred.
  SELECT count(*) INTO v_nogeom FROM essentials.districts d
   WHERE d.mtfcc = 'X0050'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'IN-8 structure: % Gary council district(s) have NO boundary -- they would be unreachable by any address', v_nogeom;
  END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%';
  IF v_off <> 6 THEN RAISE EXCEPTION 'IN-8 structure: % Gary district offices, expected 6', v_off; END IF;

  -- The council is now complete: 3 at-large + 6 district = 9, matching official_count.
  SELECT count(*) INTO v_council FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND c.name = 'Gary Common Council';
  IF v_council <> 9 THEN RAISE EXCEPTION 'IN-8 structure: Gary Common Council holds % offices, expected 9', v_council; END IF;

  SELECT count(*) INTO v_atlarge FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title = 'Council Member, At Large';
  IF v_atlarge <> 3 THEN RAISE EXCEPTION 'IN-8 structure: % at-large offices, expected 3 (IN-4)', v_atlarge; END IF;

  SELECT official_count INTO v_count FROM essentials.chambers c
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND c.name = 'Gary Common Council';
  IF v_count <> 9 THEN RAISE EXCEPTION 'IN-8 structure: official_count is %, expected 9', v_count; END IF;

  -- 🔴 THE LONG BEACH TEST. Nine councilmembers sharing one polygon returned all nine to every
  -- address. Each district office must sit on its OWN district row, so six distinct districts
  -- carry the six district offices.
  SELECT count(*) INTO v_fan FROM (
    SELECT o.district_id FROM essentials.offices o
     JOIN essentials.chambers c ON c.id = o.chamber_id
     JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%'
     GROUP BY o.district_id HAVING count(*) > 1) s;
  IF v_fan <> 0 THEN
    RAISE EXCEPTION 'IN-8 structure: % district row(s) carry more than one council office -- one address would return several councilmembers (the Long Beach defect)', v_fan;
  END IF;

  RAISE NOTICE 'IN-8 structure OK: 6 districts on X0050 all with geometry, 6 offices; Gary Common Council now 9 of 9';
END $$;

\echo === migrations/CC_0097_gary_council_districts_people.sql ===
-- CC_0097_gary_council_districts_people.sql
-- Knight Foundation program, wave IN-8 (occupancy half). Slot RESERVED from the allocator.
--
-- Seats the six Gary district councilmembers created by CC_0096. 6 people, 6 terms, 0 vacancies.
-- Apply immediately after CC_0096: between the two, six offices exist with no term, which is the
-- state `essentials.offices_missing_terms` counts.
--
--   D1  Lori Latham             D4  Marian Ivey
--   D2  Dwayne Halliburton      D5  Linda Barnes-Caldwell   (Council President)
--   D3  Mary Brown              D6  Dwight A Williams
--
-- SOURCE: garycommoncouncil.gov/council-members/ -- the Council's OWN page, which pairs each
-- member with their district in its own text. Re-read live 2026-09-11 as the change-check: all
-- six still named, all six still on the same district, and no unexplained name on the page.
-- ⚠ garycommoncouncil.ORG also exists and is stale; the .gov is current (IN-4).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 FIVE OF THE SIX TERMS ARE `unknown`, AND THAT IS THE HONEST ANSWER, NOT A GAP.
-- IN-4 established that Ballotpedia returns HTTP 404 for ten of Gary's twelve officials -- Fort
-- Wayne is a top-100 city and Gary is not -- and that the Council's own member pages are prose
-- biographies carrying no tenure data. No source covering Gary publishes a first-taking-office
-- date for these five. Georgia's 235 legislative terms are open-ended `unknown` for the same
-- reason. Inventing a January would be arithmetic on an election year, not a source.
--
-- ⚠ THE ONE DATED ROW IS DATED FROM THE CAUCUS, NOT THE SWEARING-IN, so it is `month`.
-- Marian Ivey held an AT-LARGE seat (succeeding Ronald G Brewer Sr) and moved to District 4 when
-- Tai Adkins became Calumet Township trustee; she won the District 4 caucus on 2025-02-19 on the
-- county chairman's tie-break. The swearing-in is a different event, days later, and is not
-- published -- so the day is not claimed. This is the same rule CC_0093 applied to Kenneth
-- Whisenton and Myles Tolliver.
--
-- 🔴 IVEY'S AT-LARGE SEAT IS ALREADY HELD BY SOMEONE ELSE, AND THAT IS CORRECT.
-- Myles Tolliver took it at the 2025-03-21 caucus and CC_0093 seated him there. So Ivey must end
-- up holding EXACTLY ONE Gary office -- District 4 -- and the gate asserts it. Seating her here
-- without that check is how the same person ends up on two live seats, which this slice already
-- came within one wave of doing with Mark Spencer.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_off int; v_band int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%';
  IF v_off <> 6 THEN RAISE EXCEPTION 'IN-8 occupancy pre-flight: % district offices, expected 6 (run CC_0096 first)', v_off; END IF;

  -- The band must be free. An external_id collision seats the WRONG person silently.
  SELECT count(*) INTO v_band FROM essentials.politicians
   WHERE external_id BETWEEN -1332204 AND -1332199;
  IF v_band <> 0 THEN
    RAISE EXCEPTION 'IN-8 occupancy pre-flight: % politician(s) already occupy the band -1332204..-1332199', v_band;
  END IF;
END $$;

-- ─── 1. Six people ───────────────────────────────────────────────────────────

CREATE TEMP TABLE gary_d_people(
  external_id bigint, full_name text, first_name text, last_name text, district text) ON COMMIT DROP;
INSERT INTO gary_d_people VALUES
  (-1332199, 'Lori Latham',           'Lori',   'Latham',         '1'),
  (-1332200, 'Dwayne Halliburton',    'Dwayne', 'Halliburton',    '2'),
  (-1332201, 'Mary Brown',            'Mary',   'Brown',          '3'),
  (-1332202, 'Marian Ivey',           'Marian', 'Ivey',           '4'),
  (-1332203, 'Linda Barnes-Caldwell', 'Linda',  'Barnes-Caldwell','5'),
  (-1332204, 'Dwight A Williams',     'Dwight', 'Williams',       '6');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active, source)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, true,
       'gary_in8_council_districts'
FROM gary_d_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Six terms ────────────────────────────────────────────────────────────

CREATE TEMP TABLE gary_d_terms(
  external_id bigint, district text,
  term_start date, start_precision text, date_source text) ON COMMIT DROP;
INSERT INTO gary_d_terms VALUES
  (-1332199, '1', NULL, 'unknown',
   'No source covering Gary publishes a first-taking-office date; Ballotpedia 404s'),
  (-1332200, '2', NULL, 'unknown',
   'No source covering Gary publishes a first-taking-office date; Ballotpedia 404s'),
  (-1332201, '3', NULL, 'unknown',
   'No source covering Gary publishes a first-taking-office date; Ballotpedia 404s'),
  (-1332202, '4', DATE '2025-02-01', 'month',
   'Won the District 4 caucus 2025-02-19 on the county chairman tie-break, moving from an at-large seat after Tai Adkins became Calumet Township trustee; swearing-in day not published'),
  (-1332203, '5', NULL, 'unknown',
   'Council President; no source covering Gary publishes a tenure start'),
  (-1332204, '6', NULL, 'unknown',
   'No source covering Gary publishes a first-taking-office date; Ballotpedia 404s');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, 'unknown',
       'Gary IN-8 (CC_0097): ' || t.date_source
FROM gary_d_terms t
JOIN essentials.districts d
  ON d.geo_id = 'gary-in-council-district-' || t.district
 AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = 'Council Member, District ' || t.district
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'City of Gary, Indiana, US'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_people int; v_seated int; v_month int; v_unknown int; v_ended int;
        v_ivey int; v_dupe int; v_council int; v_vacant int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -1332204 AND -1332199;
  IF v_people <> 6 THEN RAISE EXCEPTION 'IN-8 occupancy: % people in the band, expected 6', v_people; END IF;

  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%';
  IF v_seated <> 6 THEN
    RAISE EXCEPTION 'IN-8 occupancy: % district seats filled, expected 6 (office_current_holder LEFT JOINs, so count the politician, not the row)', v_seated;
  END IF;

  -- 🔴 Marian Ivey must hold EXACTLY ONE Gary office. Her old at-large seat belongs to Myles
  -- Tolliver since the 2025-03-21 caucus. Two live seats for one person is the Mark Spencer
  -- failure this slice already caught once.
  SELECT count(*) INTO v_ivey
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND p.full_name = 'Marian Ivey';
  IF v_ivey <> 1 THEN
    RAISE EXCEPTION 'IN-8 occupancy: Marian Ivey holds % Gary offices, expected exactly 1 (District 4). Her at-large seat is Myles Tolliver''s.', v_ivey;
  END IF;

  -- Nobody holds two Gary council seats.
  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
     JOIN essentials.offices o ON o.id = och.office_id
     JOIN essentials.chambers c ON c.id = o.chamber_id
     JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Gary, Indiana, US' AND c.name = 'Gary Common Council'
     GROUP BY och.politician_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'IN-8 occupancy: % person(s) hold more than one Gary council seat', v_dupe; END IF;

  -- The council is now completely seated: 9 of 9.
  SELECT count(och.politician_id) INTO v_council
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Gary, Indiana, US' AND c.name = 'Gary Common Council';
  IF v_council <> 9 THEN RAISE EXCEPTION 'IN-8 occupancy: Gary Common Council seats % of 9', v_council; END IF;

  SELECT count(*) INTO v_vacant FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%' AND o.is_vacant;
  IF v_vacant <> 0 THEN RAISE EXCEPTION 'IN-8 occupancy: % district office(s) flagged vacant', v_vacant; END IF;

  -- The precision tuple, asserted so a later "tidy" that invents dates fails loudly.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'month'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_month, v_unknown, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%';
  IF v_month <> 1 OR v_unknown <> 5 THEN
    RAISE EXCEPTION 'IN-8 occupancy: precision is % month + % unknown, expected 1 + 5', v_month, v_unknown;
  END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'IN-8 occupancy: % district term(s) already closed', v_ended; END IF;

  RAISE NOTICE 'IN-8 occupancy OK: 6 district members seated, Gary Common Council 9 of 9, Ivey on exactly one seat, 1 month + 5 unknown';
END $$;

\echo '=== measurements INSIDE the transaction ==='
SELECT (SELECT count(*) FROM essentials.districts WHERE mtfcc='X0050') AS districts,
       (SELECT count(*) FROM essentials.offices o JOIN essentials.chambers c ON c.id=o.chamber_id
          JOIN essentials.governments g ON g.id=c.government_id
         WHERE g.name='City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%') AS offices,
       (SELECT count(*) FROM essentials.politicians WHERE external_id BETWEEN -1332204 AND -1332199) AS people,
       (SELECT count(och.politician_id) FROM essentials.offices o
          JOIN essentials.chambers c ON c.id=o.chamber_id
          JOIN essentials.governments g ON g.id=c.government_id
          LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
         WHERE g.name='City of Gary, Indiana, US' AND c.name='Gary Common Council') AS council_seated,
       (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms;
ROLLBACK;