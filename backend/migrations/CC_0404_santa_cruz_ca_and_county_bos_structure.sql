-- CC_0404_santa_cruz_ca_and_county_bos_structure.sql
-- City of Santa Cruz, California — greenfield seed, STRUCTURE ONLY.
-- Santa Cruz County, California — RECONCILE: the Board of Supervisors, which the county's
-- existing record does not have at all.
-- NO PEOPLE ARE SEATED BY THIS MIGRATION. The roster is CC_0405.
--
-- ═══ 🔴 SANTA CRUZ COUNTY IS HALF-SEEDED, THE SAME SHAPE MARIN WAS IN (CC_0392) ═══
--
-- `essentials.governments` already holds 'Santa Cruz County, California, US'
-- (6cef5fff-6af7-49d2-9ac9-d1e2cdf6172f, geo_id 06087, G4020) with ONE chamber — 'Countywide
-- Elected Officials', 5 offices, all 5 occupied: Sheri Thomas (Assessor-Recorder), Laura
-- Bowers (Auditor-Controller-Treasurer-Tax Collector), Tricia Webber (County Clerk),
-- Jeffrey S. Rosell (District Attorney-Public Administrator), Christopher Clark
-- (Sheriff-Coroner). All five re-verified 2026-11-11 against their own offices' pages and all
-- five are current.
--
-- 🔴 OCCUPANCY LIVES IN `essentials.office_terms`. `essentials.offices` has no government_id
--    (offices reach a government only through `chamber_id`) and `offices.politician_id` NO
--    LONGER EXISTS. Read office_terms, or read nothing.
--
-- What the county is missing is the BOARD OF SUPERVISORS: no chamber, no district rows, no
-- offices. This migration adds exactly that and touches nothing the countywide chamber holds.
--
-- ═══ 🔴 ELEVEN CAL-ACCESS COMMITTEE NAMES ARE SITTING IN `politicians` AS IF THEY WERE
--        PEOPLE, AND FOUR OF THEM CARRY THE NAMES THIS SEED IS ABOUT ═══
--
-- e.g. 'DE SERPA FOR SANTA CRUZ COUNTY SUPERVISOR 2024; FRIENDS OF KIM',
-- 'KALANTARI-JOHNSON FOR SANTA CRUZ CITY COUNCIL 2020; SHEBREH',
-- 'TRIGUEIRO FOR CITY COUNCIL 2024; FRIENDS OF', '…DISTIRCT 3 2024' (sic, twice).
-- All eleven are is_active=false with zero images, zero answers and zero seats, so they do not
-- trip the duplicate-person gate — but a roster pass that matches on surname WILL find them.
-- No real person row exists for any of the twelve officials. CC_0405 creates them fresh and
-- must not link to any of these. See project_cal_access_lasttoken_mislinks.
--
-- ═══ THE CITY: SEVEN SEATS, AND THE MAYOR IS ONE OF THEM — BUT THE VICE MAYOR IS NOT ═══
--
-- Read from the ENACTED charter amendment, not from a description of it. Measure E of
-- 2022-06-07 rewrote Article VI and added Article VII sections 708-711; full text at
-- votescount.santacruzcountyca.gov (the County elections office's own publication of the
-- measure), read 2026-11-11:
--
--   s 601(a)  "The elective officers of this City shall consist of six Councilmembers and a
--             Mayor, each of the members of which, including the Mayor, shall have the right
--             to vote upon all questions before it."
--   s 601(b)  Councilmembers "nominated from and by the electors of each of the six districts".
--             "The term of office shall be four years."
--   s 601(c)  Mayor "nominated from and by the electors of the City and elected by the voters
--             of the City at-large." "The term of office shall be four years."
--   s 708     "The City shall be divided into six districts, the names and respective
--             boundaries of which shall be as established by ordinance."
--   s 711     Two Round Election System: a candidate taking a majority in the first round is
--             elected outright; otherwise the top two go to a runoff.
--
-- ⚖ So the Mayor IS a seat voters elect — unlike Corte Madera, where Mayor is a rotating title
--   and creating an office for it would have invented a seat. Here the opposite error is the
--   available one: leaving the Mayor out would drop a directly elected officer.
--
-- ⚖ The VICE MAYOR is the rotating title here. s 604(f): "The Council shall elect a
--   Vice-Mayor, who shall serve in such capacity at the pleasure of the City Council." No
--   voter elects one, so no office is created for it. It is recorded on the chamber instead,
--   where it is a fact about the body rather than about a seat.
--
-- 🔑 s 709 answers a question the geography raised: "Any territory constituting a part of the
--    City and not specifically included in any district shall be deemed included in the
--    district with which it has the longest common boundary line." The district polygons leave
--    0.0430 km² of city precinct ground unclaimed (shared lines digitised twice); by charter
--    that ground is not district-less, it belongs to its longest-bordering neighbour.
--
-- ⚠ SCOPE: the Mayor and the six council seats. The City of Santa Cruz elects no other
--   officer — the June 2 2026 official results carry exactly three city contests (Mayor,
--   Councilmember District 4, Councilmember District 6). That is a verified boundary, not an
--   omission.
--
-- ═══ 🔴 NOTHING FROM THE 2026 ELECTIONS IS SEATED ANYWHERE IN THIS PAIR OF MIGRATIONS ═══
--
-- Two seats change hands and NEITHER successor is recorded here or in CC_0405:
--
--   Mayor — Ryan Coonerty won the 2026-11-03 runoff with 13,157 (52.95%) to Ami Chen Mills'
--   11,472 (46.17%). Those results are published '-Unofficial Results-' and certification is
--   due about 2026-12-03. Under s 601(c) his term starts at the Council meeting that receives
--   the Clerk's certification, so Fred Keeley holds the office until then.
--
--   Supervisor 4th District — Tony Nuñez took 3,944 of 7,877 in the June 2 primary. That is
--   50.07%: SIX VOTES above the majority line, so under the county's two-round system he was
--   elected outright and no November runoff was held. Felipe Hernandez (2,429) was defeated
--   and sits until the new term begins in January 2027. Arithmetic checked against the
--   certified Official Results PDF dated 6/26/2026: 2,429 + 3,944 + 1,450 + 54 write-in =
--   7,877 exactly.
--   ⚠ `pdftotext -layout` SHIFTS THAT PDF'S PERCENTAGE COLUMN BY A ROW. The percentages above
--     are computed from the vote counts, never read off the layout extraction.
--
-- Both seats need a return visit: the Mayor at the December certification meeting, Supervisor
-- District 4 in January. See the TO DO at the foot of CC_0405.
--
-- ═══ GEOGRAPHY ═══
--
-- Both district layers load first, by scripts/load-santa-cruz-districts.mjs:
--
--   X0089  santa-cruz-ca-council-district-1..6
--   X0090  santa-cruz-county-ca-supervisorial-district-1..5
--
-- THIS MIGRATION REFUSES TO RUN without them: an office on a district with no polygon is
-- unreachable by any address and NOTHING ERRORS.
--
-- 🔴 THE CITY LAYER PUBLISHES SEVEN POLYGONS FOR SIX DISTRICTS. District 6 is a 1,773.53-acre
--    main body plus a detached 98.24-acre parcel at the Coastal Science Campus. The loader
--    dissolves on the District attribute; taken row-for-row it would have given Santa Cruz a
--    phantom seventh council district, and the office-count check below would have passed it.
--
-- 🔑 Vintage proved against the COUNTY'S OWN BALLOT LAYER, which adjudicates both maps at once.
--    Its Precincts layer (lastEditDate 2026-06-23, built for the June 2 primary) carries both
--    districts as attributes: SUPDIST on all 692 precincts and SCCC on the 97 inside the city
--    — exactly the 97 its CITYLIMITS column puts there. Every one of the 692 and every one of
--    the 97 sits in the district its own ballot attribute names, ZERO disagreements. The
--    loader's control (--control=scramble) swaps two districts and scores 256 and 28
--    disagreements, so neither gate is vacuous.
--
-- 🔴 The city council layer's `NameCouncil` column is STALE — its District 6 rows read "Vice
--    Mayor Renee Golder", but the Vice Mayor is Shebreh Kalantari-Johnson of District 3.
--    Geometry is taken from that layer; occupancy and titles never are.
--
-- ⚠ Both TIGER parent polygons reach far into Monterey Bay, so a percentage-of-polygon
--   coverage test reads 73.3% (county) and 79.9% (city) on correct maps. The loader gates on
--   census land area and on precinct coverage instead. Nothing here depends on that, but the
--   next reader should not "fix" a coverage number that is measuring the sea.

BEGIN;

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_cc int; v_sup int; v_city_poly int; v_county_poly int;
        v_city int; v_county uuid; v_bos int;
BEGIN
  SELECT count(*) INTO v_cc FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0089' AND geo_id LIKE 'santa-cruz-ca-council-district-%';
  IF v_cc <> 6 THEN
    RAISE EXCEPTION 'CC_0404 pre-flight: expected 6 X0089 Santa Cruz council polygons, found % — '
                    'run scripts/load-santa-cruz-districts.mjs first. An office on a district '
                    'with no polygon is unreachable by any address, and nothing errors. '
                    '(7 would mean the loader did NOT dissolve the split District 6.)', v_cc;
  END IF;

  SELECT count(*) INTO v_sup FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0090' AND geo_id LIKE 'santa-cruz-county-ca-supervisorial-district-%';
  IF v_sup <> 5 THEN
    RAISE EXCEPTION 'CC_0404 pre-flight: expected 5 X0090 Santa Cruz supervisorial polygons, '
                    'found % — run scripts/load-santa-cruz-districts.mjs first.', v_sup;
  END IF;

  SELECT count(*) INTO v_city_poly FROM essentials.geofence_boundaries
   WHERE geo_id = '0669112' AND mtfcc = 'G4110';
  IF v_city_poly <> 1 THEN
    RAISE EXCEPTION 'CC_0404 pre-flight: the Santa Cruz city polygon (0669112/G4110) is missing.';
  END IF;

  SELECT count(*) INTO v_county_poly FROM essentials.geofence_boundaries
   WHERE geo_id = '06087' AND mtfcc = 'G4020';
  IF v_county_poly <> 1 THEN
    RAISE EXCEPTION 'CC_0404 pre-flight: the Santa Cruz County polygon (06087/G4020) is missing.';
  END IF;

  -- The city must be ABSENT: this half is a greenfield seed.
  SELECT count(*) INTO v_city FROM essentials.governments
   WHERE geo_id = '0669112' OR name = 'City of Santa Cruz, California, US';
  IF v_city <> 0 THEN
    RAISE EXCEPTION 'CC_0404 pre-flight: the City of Santa Cruz already exists (% row(s)). This '
                    'half is written as a greenfield seed; re-check before re-running.', v_city;
  END IF;

  -- The county must be PRESENT: this half is a reconcile, and running it against a missing
  -- county would silently create nothing at all.
  SELECT id INTO v_county FROM essentials.governments
   WHERE name = 'Santa Cruz County, California, US' AND geo_id = '06087';
  IF v_county IS NULL THEN
    RAISE EXCEPTION 'CC_0404 pre-flight: Santa Cruz County is missing. This half is a RECONCILE '
                    'of an existing government, not a greenfield seed.';
  END IF;

  SELECT count(*) INTO v_bos FROM essentials.chambers
   WHERE government_id = v_county AND name ILIKE '%supervisor%';
  IF v_bos <> 0 THEN
    RAISE EXCEPTION 'CC_0404 pre-flight: the county already has % Board of Supervisors '
                    'chamber(s).', v_bos;
  END IF;
END $$;

-- ══ CITY OF SANTA CRUZ ════════════════════════════════════════════════════════

INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'City of Santa Cruz, California, US', 'City', 'CA', 'Santa Cruz', '0669112', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Santa Cruz, California, US');

-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, NOT from `name`. Leaving
--    name_formal NULL silently generates an EMPTY slug, and the slug is what the app routes
--    on. A bare 'city-council' would also collide with every other City Council in the country.
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length,
                                 term_limit, election_method, election_frequency, election_rules,
                                 inauguration_rules, staggered_term, vacancy_rules, remarks)
SELECT g.id, 'City Council', 'Santa Cruz City Council', 7, '4',
       'Two consecutive full terms, then ineligible for two years; 16 consecutive years on the '
       || 'Council in total (Charter s 601(d)). A by-district Councilmember may run for Mayor '
       || 'immediately after two terms, and a Mayor for a district seat.',
       'six by-district, Mayor at-large', 'November of even-numbered years',
       'Two Round Election System (Charter s 711): a candidate taking a majority of the votes '
       || 'cast for that office in the first round is elected outright; otherwise the top two '
       || 'go to a runoff. In 2026 the two district contests were settled in the June 2 first '
       || 'round and the Mayor went to a November 3 runoff.',
       'A term begins at the Council meeting that receives the City Clerk''s certification of '
       || 'the election results (Charter s 601(b), (c)) — NOT on a fixed January date.',
       true,
       'A council vacancy is filled by Council appointment from the same district, or by '
       || 'special election. A vacancy in the office of Mayor is filled only by special '
       || 'election, held 88-103 days after the vacancy (Charter s 605).',
       'Seven elective officers: six Councilmembers elected by district and a Mayor elected '
       || 'at large, all seven voting members of the Council (Charter s 601(a), amended by '
       || 'Measure E of 2022-06-07). Four-year staggered terms. The VICE MAYOR is chosen BY '
       || 'THE COUNCIL from among its own members and serves at the Council''s pleasure '
       || '(s 604(f)) — a rotating title on a seat, not an office, and no voter elects one. '
       || 'The City keeps a Council-Manager form of government: the Mayor presides, is the '
       || 'titular head for ceremonial purposes, sets agendas, and has "no regular '
       || 'administrative duties" (s 604). Source: the enacted text of Measure E, published by '
       || 'the County elections office at votescount.santacruzcountyca.gov, read 2026-11-11.'
FROM essentials.governments g
WHERE g.name = 'City of Santa Cruz, California, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'City Council');

-- The Mayor's district is the whole city. Reusing the TIGER place polygon, as Corte Madera's
-- at-large council does.
INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc,
                                  num_officials, representation_basis, government_id)
SELECT '0669112', 'City of Santa Cruz (Citywide)', 'LOCAL', 'ca', 'Santa Cruz', 'G4110',
       1, 'residency', g.id
FROM essentials.governments g
WHERE g.name = 'City of Santa Cruz, California, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.districts d
    WHERE d.geo_id = '0669112' AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL');

CREATE TEMP TABLE sc_council(num int, geo_id text, label text) ON COMMIT DROP;
INSERT INTO sc_council(num, geo_id, label) VALUES
  (1, 'santa-cruz-ca-council-district-1', 'Santa Cruz City Council District 1'),
  (2, 'santa-cruz-ca-council-district-2', 'Santa Cruz City Council District 2'),
  (3, 'santa-cruz-ca-council-district-3', 'Santa Cruz City Council District 3'),
  (4, 'santa-cruz-ca-council-district-4', 'Santa Cruz City Council District 4'),
  (5, 'santa-cruz-ca-council-district-5', 'Santa Cruz City Council District 5'),
  (6, 'santa-cruz-ca-council-district-6', 'Santa Cruz City Council District 6');

INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc,
                                  num_officials, representation_basis, government_id)
SELECT n.geo_id, n.label, 'LOCAL', 'ca', 'Santa Cruz', 'X0089', 1, 'residency', g.id
FROM sc_council n
JOIN essentials.governments g ON g.name = 'City of Santa Cruz, California, US'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = 'X0089' AND d.district_type = 'LOCAL');

-- ⚖ Office title = the seat AS THE BALLOT ELECTS IT. The County's June 2 2026 Official Results
--   name these contests "City of Santa Cruz Mayor" and "City of Santa Cruz Councilmember -
--   District 4"; the city qualifier lives in representing_city, so the titles are "Mayor" and
--   "Councilmember, District N". The city's own roster page uses the same "Councilmember -
--   District N" form.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state,
                                representing_city, seats, is_vacant, is_appointed_position,
                                voting_powers, representation_note)
SELECT c.id, d.id, 'Mayor', 'CA', 'Santa Cruz', 1, true, false, 'full',
       'Elected at large by the whole city to a four-year term (Charter s 601(c)). A voting '
       || 'member of the Council and its presiding officer, with no regular administrative '
       || 'duties — the City has a Council-Manager form of government.'
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'City Council'
JOIN essentials.districts d
  ON d.geo_id = '0669112' AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL'
 AND lower(d.state) = 'ca'
WHERE g.name = 'City of Santa Cruz, California, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = 'Mayor');

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state,
                                representing_city, seats, is_vacant, is_appointed_position,
                                voting_powers, representation_note)
SELECT c.id, d.id, 'Councilmember, District ' || n.num, 'CA', 'Santa Cruz', 1, true, false,
       'full',
       'Nominated from and elected by the voters of District ' || n.num || ' to a four-year '
       || 'term (Charter s 601(b)). Terms are staggered: Districts 4 and 6 stand with the '
       || 'Mayor, Districts 1, 2, 3 and 5 in the other cycle.'
FROM sc_council n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = 'X0089' AND d.district_type = 'LOCAL'
JOIN essentials.governments g ON g.name = 'City of Santa Cruz, California, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'City Council'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.chamber_id = c.id
    AND o.title = 'Councilmember, District ' || n.num);

-- ══ SANTA CRUZ COUNTY BOARD OF SUPERVISORS ════════════════════════════════════

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length,
                                 election_method, election_frequency, election_rules,
                                 staggered_term, remarks)
SELECT g.id, 'Board of Supervisors', 'Santa Cruz County Board of Supervisors', 5, '4',
       'by-district', 'June of even-numbered years, with a November runoff where needed',
       'California''s two-round county system: a candidate taking a majority in the June '
       || 'primary is elected outright, otherwise the top two meet in November. Both 2026 '
       || 'contests were settled in June — District 3 was effectively unopposed, and District '
       || '4 was decided by a 50.07% first-round majority, six votes above the line.',
       true,
       'Five supervisors elected BY DISTRICT to four-year staggered terms. The Board elects '
       || 'its own Chair and Vice Chair from among its members, which is a role and not a '
       || 'seat, so no office is created for it. The Board is the governing body of the '
       || 'county. Source: the County''s own Board of Supervisors pages '
       || '(santacruzcountyca.gov/Government/BoardofSupervisors.aspx and the five district '
       || 'pages), read 2026-11-11.'
FROM essentials.governments g
WHERE g.name = 'Santa Cruz County, California, US' AND g.geo_id = '06087'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Board of Supervisors');

CREATE TEMP TABLE sc_sup(num int, ordinal text, geo_id text, label text) ON COMMIT DROP;
INSERT INTO sc_sup(num, ordinal, geo_id, label) VALUES
  (1, '1st', 'santa-cruz-county-ca-supervisorial-district-1', 'Santa Cruz County Supervisorial District 1'),
  (2, '2nd', 'santa-cruz-county-ca-supervisorial-district-2', 'Santa Cruz County Supervisorial District 2'),
  (3, '3rd', 'santa-cruz-county-ca-supervisorial-district-3', 'Santa Cruz County Supervisorial District 3'),
  (4, '4th', 'santa-cruz-county-ca-supervisorial-district-4', 'Santa Cruz County Supervisorial District 4'),
  (5, '5th', 'santa-cruz-county-ca-supervisorial-district-5', 'Santa Cruz County Supervisorial District 5');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc,
                                  num_officials, representation_basis, government_id)
SELECT n.geo_id, n.label, 'COUNTY', 'ca', 'X0090', 1, 'residency', g.id
FROM sc_sup n
JOIN essentials.governments g
  ON g.name = 'Santa Cruz County, California, US' AND g.geo_id = '06087'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = 'X0090' AND d.district_type = 'COUNTY');

-- ⚖ Title follows the County's own contest wording. Its June 2 2026 Official Results name the
--   contests "Supervisor, 3rd District" and "Supervisor, 4th District" — ORDINAL, not
--   "District N". That differs from Marin's "County Supervisor, District N" (CC_0392) because
--   the two counties word their ballots differently, and the ballot is the rule.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state,
                                seats, is_vacant, is_appointed_position, voting_powers,
                                representation_note)
SELECT c.id, d.id, 'Supervisor, ' || n.ordinal || ' District', 'CA', 1, true, false, 'full',
       'Elected by the voters of Supervisorial District ' || n.num || ' to a four-year term; '
       || 'terms are staggered, so districts 1, 2 and 5 stand in one cycle and 3 and 4 in the '
       || 'next.'
FROM sc_sup n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = 'X0090' AND d.district_type = 'COUNTY'
JOIN essentials.governments g
  ON g.name = 'Santa Cruz County, California, US' AND g.geo_id = '06087'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Board of Supervisors'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.chamber_id = c.id
    AND o.title = 'Supervisor, ' || n.ordinal || ' District');

-- ── Post-conditions ───────────────────────────────────────────────────────────
-- 🔴 VERIFY ON ROW COUNTS AND ON THE SLUG, not on "the inserts did not error". An empty slug
--    is the silent failure mode here, and it does not raise.
DO $$
DECLARE v_city uuid; v_county uuid; v_ch int; v_off int; v_dist int; v_badslug int;
        v_mayor int; v_bos_off int; v_seated int; v_countywide int; v_nopoly int;
BEGIN
  SELECT id INTO v_city FROM essentials.governments
   WHERE name = 'City of Santa Cruz, California, US';
  IF v_city IS NULL THEN
    RAISE EXCEPTION 'CC_0404 post: the City of Santa Cruz government row is missing';
  END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers WHERE government_id = v_city;
  IF v_ch <> 1 THEN
    RAISE EXCEPTION 'CC_0404 post: expected 1 city chamber, found %', v_ch;
  END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.government_id = v_city;
  IF v_off <> 7 THEN
    RAISE EXCEPTION 'CC_0404 post: expected 7 city council offices (Mayor + 6 districts), '
                    'found % — 8 would mean the phantom District 7 got through', v_off;
  END IF;

  SELECT count(*) INTO v_mayor FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_city AND o.title = 'Mayor';
  IF v_mayor <> 1 THEN
    RAISE EXCEPTION 'CC_0404 post: expected exactly 1 Mayor office, found %', v_mayor;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'X0089' AND district_type = 'LOCAL';
  IF v_dist <> 6 THEN
    RAISE EXCEPTION 'CC_0404 post: expected 6 X0089 council district rows, found %', v_dist;
  END IF;

  SELECT id INTO v_county FROM essentials.governments
   WHERE name = 'Santa Cruz County, California, US' AND geo_id = '06087';

  SELECT count(*) INTO v_bos_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_county AND c.name = 'Board of Supervisors';
  IF v_bos_off <> 5 THEN
    RAISE EXCEPTION 'CC_0404 post: expected 5 supervisor offices, found %', v_bos_off;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'X0090' AND district_type = 'COUNTY';
  IF v_dist <> 5 THEN
    RAISE EXCEPTION 'CC_0404 post: expected 5 X0090 district rows, found %', v_dist;
  END IF;

  -- Every office created here must sit on a district that HAS a polygon.
  SELECT count(*) INTO v_nopoly FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE (c.government_id = v_city
          OR (c.government_id = v_county AND c.name = 'Board of Supervisors'))
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nopoly <> 0 THEN
    RAISE EXCEPTION 'CC_0404 post: % office(s) sit on a district with no polygon — unreachable '
                    'by any address', v_nopoly;
  END IF;

  -- And every office must sit on a DISTINCT district: a copy-paste that pointed two council
  -- offices at one district would pass every count above.
  SELECT count(*) INTO v_dist FROM (
    SELECT o.district_id FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = v_city
        OR (c.government_id = v_county AND c.name = 'Board of Supervisors')
     GROUP BY o.district_id HAVING count(*) > 1) t;
  IF v_dist <> 0 THEN
    RAISE EXCEPTION 'CC_0404 post: % district(s) carry more than one of these offices', v_dist;
  END IF;

  SELECT count(*) INTO v_badslug FROM essentials.chambers
   WHERE government_id IN (v_city, v_county) AND (slug IS NULL OR slug = '');
  IF v_badslug <> 0 THEN
    RAISE EXCEPTION 'CC_0404 post: % chamber(s) have an empty slug — name_formal was not set, '
                    'and the app routes on the slug', v_badslug;
  END IF;

  -- This migration seats NOBODY.
  SELECT count(*) INTO v_seated FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_city
      OR (c.government_id = v_county AND c.name = 'Board of Supervisors');
  IF v_seated <> 0 THEN
    RAISE EXCEPTION 'CC_0404 post: % office_terms row(s) exist — this migration seats nobody; '
                    'the roster is CC_0405', v_seated;
  END IF;

  -- And it must not have disturbed the five countywide officers that were already seated.
  SELECT count(*) INTO v_countywide FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_county AND c.name = 'Countywide Elected Officials';
  IF v_countywide <> 5 THEN
    RAISE EXCEPTION 'CC_0404 post: expected the 5 countywide office_terms to be untouched, '
                    'found %', v_countywide;
  END IF;
END $$;

COMMIT;
