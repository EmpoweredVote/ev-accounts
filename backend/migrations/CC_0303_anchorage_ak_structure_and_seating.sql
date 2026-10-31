-- CC_0303_anchorage_ak_structure_and_seating.sql
-- Municipality of Anchorage, Alaska — full greenfield seed: government, three chambers, seven
-- districts, twenty offices, twenty officeholders.
--
-- ═══ THIS IS A TRUE GREENFIELD, WHICH IS RARE AND WAS VERIFIED, NOT ASSUMED ═══
--
-- The Wave-2 rule (`project_v170_wave2_not_greenfield`) is that a city the roadmap calls
-- greenfield is usually a reconcile. Anchorage was pre-checked against production on 2026-10-27
-- by NAME and by geo_id, in both join directions, and it really is empty:
--
--   essentials.governments  WHERE state='AK'                       → 1 row, "State of Alaska"
--   anything named %anchorage%                                     → 0 rows
--   active politicians matching any of these 20 on first+last name → 0 rows
--   duplicate same-slug chambers to merge                          → none, nothing exists
--   office-unlinked people to reseat rather than recreate          → none
--
-- Alaska held exactly five officials before this migration: Governor, Lieutenant Governor, two
-- U.S. Senators and the at-large U.S. Representative. There is no state legislature in the
-- database and no G5210/G5220 polygons for Alaska, so this seed adds a local tier under a state
-- tier that is still thin. That is a known gap, not something this migration creates.
--
-- ═══ 🔴 ANCHORAGE IS ONE GOVERNMENT WITH TWO COEXTENSIVE POLYGONS. PICK ONE. ═══
--
-- Anchorage is a UNIFIED HOME RULE MUNICIPALITY: the borough and the city are the same
-- government. Both TIGER polygons exist in production and are the same ground — measured
-- 2026-10-27, both are 1,944.5 sq mi with an identical centroid:
--
--   02020   G4020  "Anchorage Municipality"   (borough)
--   0203000 G4110  "Anchorage municipality"   (place)
--
-- Precedent in this database is SPLIT and neither side is wrong: Indianapolis (18097) and
-- Nashville (47037) register their consolidated governments under the COUNTY code; San Francisco
-- (0667000) and Columbus GA (1319000) under the PLACE code.
--
-- ⚖ DECIDED: the PLACE code, 0203000. `COVERAGE_STATES[].areas[].browseGovernmentList` in
--   essentials is populated with place geo_ids everywhere, so a borough code would need a
--   special case in the consumer to be browsable. Routing is unaffected either way — the two
--   polygons are the same ground, so an Anchorage address resolves through both.
--
-- 🔴 THERE IS A SECOND "ANCHORAGE" AND IT IS NOT THIS ONE. Place 2101504 is "Anchorage city",
--    Kentucky. Every predicate below is anchored on geo_id or on the government row, never on
--    the name alone.
--
-- ═══ THE ROSTER: THREE INDEPENDENT MUNICIPAL SOURCES, READ 2026-10-27 ═══
--
-- 🔴 Not one name, date or seat letter here came from a web-search summary or a WebFetch answer.
--    Each was read out of the document itself (`pdftotext` over the Clerk's PDF; the raw HTML of
--    the two roster pages). The CLAUDE.md rule is explicit that WebFetch fabricates names and
--    dates and formats them as quotations, so it was used only to LOCATE these documents.
--
--   S1  Municipal Clerk, "Anchorage Municipal Assembly — Assembly Members Public Contact List",
--       revised 04/29/2026 — the only source that prints the SEAT LETTERS beside the names.
--   S2  muni.org Assembly member profiles page — district names, term-expiry years, headshots.
--   S3  MOAGIS feature service AssemblyDistrict_Links layer 0 — polygons, plus SEAT1/SEAT2.
--
--   🟢 All twelve assembly names and all twelve seat letters AGREE across S1, S2 and S3. The
--      loader's GATE 6 refuses to write geometry if S1 and S3 ever diverge, because that would
--      mean one of them had been reapportioned and the other had not.
--   🔴 S3 also carries INCUMBENT1/INCUMBENT2. Those columns are NOT read for occupancy, even
--      though they are correct today — the Atlanta layer was correct on 9 of 12 while carrying
--      two different stale vintages (`load-atlanta-council-districts.mjs`). Geometry from S3,
--      occupancy from S1/S2.
--
--   S4  muni.org Mayor's page — "Mayor Suzanne LaFrance … Term: July 1, 2024 to June 30, 2027".
--   S5  asdk12.org School Board members page — "The seven-member Anchorage School Board … All
--       school board seats are elected citywide … each member serves for a three-year term."
--
-- ═══ 🔴 DATES: ONLY THE MAYOR GETS ONE, AND THAT IS DELIBERATE ═══
--
-- `office_terms.term_start` is the start of CONTINUOUS OCCUPANCY. A re-election does not open a
-- new row, and an expiry is the end of a TERM, not of an occupancy.
--
--   🟢 THE MAYOR IS DATED. S4 publishes an occupancy, not an election: "Term: July 1, 2024 to
--      June 30, 2027". July 1 is when an Anchorage mayor takes office. That is a start date, so
--      it is written with `start_precision => 'day'`.
--
--   🔴 THE OTHER NINETEEN ARE NOT. S1's column is headed "ELECTED/REELECTED" and gives month and
--      year of each election (Scout 4/2026; Perez-Verdia 4/2019, 4/2022, 4/2025; Volland 7/2022,
--      4/2025; Brawley 4/2023, 4/2026; and so on). Those are election dates, not swearing-in
--      dates, and the first of them is a statement about how someone ARRIVED. CLAUDE.md's rule
--      — "FIRST ELECTED IS NOT A TERM START" — applies exactly.
--
--   ⚠ AND THE SCHOOL BOARD PROVES WHY THE RULE IS NOT PEDANTRY. S5 labels Pat Higgins "Seat E
--     through April 2027, SECOND TERM" and says in the same paragraph that he "first served on
--     the Anchorage School Board from 2008 to 2017". His service is NOT continuous: a term start
--     inferred from "first elected" would have claimed eighteen unbroken years and been wrong by
--     most of them. Margo Bellamy is labelled "third term" with no dates at all.
--
--   So all nineteen get `start_precision => 'unknown'` with a NULL `term_start`, and the gate at
--   the foot of this file REFUSES any of the nineteen that carries a date. The published
--   election years are recorded in each row's `source` as a dating lead for a later pass.
--
-- ═══ GEOGRAPHY ═══
--
-- The six assembly-district polygons were loaded first, by
-- `scripts/load-anchorage-assembly-districts.mjs`, as `X0081` /
-- `anchorage-ak-assembly-1..6`. This migration REFUSES TO RUN without them: an office on a
-- district with no polygon is unreachable by any address and NOTHING ERRORS.
--
-- 🔴 THE DISTRICTS DO NOT TILE THE PLACE POLYGON AND THAT IS CORRECT. They cover 90.672% of it.
--    The missing 469.7 km² is the tidal water of Turnagain Arm and Knik Arm: Census 2020 PL gives
--    place 02/03000 ALAND 4,420.6 km² and AWATER 615.7 km², which sum to the 5,036.3 km² the
--    polygon measures, and the districts cover 4,566.5 km² — 145.9 km² MORE than the entire land
--    area. The loader's GATE 4b geocodes every uncovered piece over 1 km² and fails if any sits
--    on addressable land; the single 469.2 km² piece returns a census block with AREALAND = 0,
--    against a City Hall control that returns block 020200011001047.
--
-- ⚠ THE SCHOOL BOARD IS A CHAMBER OF THE MUNICIPALITY, NOT ITS OWN GOVERNMENT. The Anchorage
--   School District is coextensive with the municipality and Alaska has NO G5420 polygon in
--   production, so a separate school-district government row would have no geography and its
--   seven seats would be unreachable. This is the Augusta, Maine shape (`CC_0282`): "City
--   Council" and "School Committee" as two chambers of one city government, both on the city's
--   place geo_id.
--
-- ⚠ NO STANCES ARE WRITTEN BY THIS MIGRATION, for anybody. The school board additionally stays
--   out of stance research entirely until the school-board badge ships
--   (`feedback_no_school_board_stances_until_badge`).
--
-- ═══ WHAT ANCHORAGE DOES NOT ELECT ═══
-- Anchorage has a strong elected Mayor and an elected Assembly and School Board, and NOTHING
-- else on the municipal ballot: the Municipal Manager, Municipal Attorney and Municipal Clerk are
-- all appointed. No office below is created for them. The Assembly Chair and Vice Chair are
-- ROTATING ROLES the Assembly confers on its own members (S2 shows Volland as Vice Chair) and are
-- NOT seats — modelling one as an office would both invent an election and consume a real
-- district seat, which is the defect `CC_0292` found in six Maine cities.

BEGIN;

-- ── Pre-flight: the geography this seed hangs on must already be in production ──
DO $$
DECLARE v_assembly int; v_stray int; v_place int;
BEGIN
  SELECT count(*) INTO v_assembly FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0081' AND geo_id LIKE 'anchorage-ak-assembly-%';
  IF v_assembly <> 6 THEN
    RAISE EXCEPTION 'CC_0303 pre-flight: expected 6 X0081 Anchorage assembly polygons, found % — '
                    'run scripts/load-anchorage-assembly-districts.mjs first. An office on a '
                    'district with no polygon is unreachable by any address and nothing errors.', v_assembly;
  END IF;
  SELECT count(*) INTO v_stray FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0081' AND geo_id NOT LIKE 'anchorage-ak-assembly-%';
  IF v_stray <> 0 THEN
    RAISE EXCEPTION 'CC_0303 pre-flight: % X0081 polygon(s) are not Anchorage assembly districts '
                    '— somebody else took this code', v_stray;
  END IF;
  SELECT count(*) INTO v_place FROM essentials.geofence_boundaries
   WHERE geo_id = '0203000' AND mtfcc = 'G4110' AND state = '02';
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'CC_0303 pre-flight: expected the TIGER place polygon 0203000/G4110 for the '
                    'citywide offices, found %', v_place;
  END IF;
END $$;

-- ── Government ────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'Municipality of Anchorage, Alaska, US', 'City', 'AK', 'Anchorage', '0203000', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Municipality of Anchorage, Alaska, US');

-- ── Chambers ──────────────────────────────────────────────────────────────────
-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, NOT from `name`. Leaving
--    name_formal NULL silently generates an EMPTY slug, and the slug is what the app routes on.
--    Both columns are set, and the gate below asserts every slug is non-empty.
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '3'
FROM essentials.governments g
JOIN (VALUES
  ('Anchorage Assembly',     12),
  ('Office of the Mayor',     1),
  ('Anchorage School Board',  7)
) AS v(name, official_count) ON true
WHERE g.name = 'Municipality of Anchorage, Alaska, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ── Districts ─────────────────────────────────────────────────────────────────
CREATE TEMP TABLE anc_districts(geo_id text, label text, mtfcc text, num_officials bigint) ON COMMIT DROP;
INSERT INTO anc_districts(geo_id, label, mtfcc, num_officials) VALUES
  ('anchorage-ak-assembly-1', 'Anchorage Assembly District 1', 'X0081', 2),
  ('anchorage-ak-assembly-2', 'Anchorage Assembly District 2', 'X0081', 2),
  ('anchorage-ak-assembly-3', 'Anchorage Assembly District 3', 'X0081', 2),
  ('anchorage-ak-assembly-4', 'Anchorage Assembly District 4', 'X0081', 2),
  ('anchorage-ak-assembly-5', 'Anchorage Assembly District 5', 'X0081', 2),
  ('anchorage-ak-assembly-6', 'Anchorage Assembly District 6', 'X0081', 2),
  ('0203000',                 'Anchorage Citywide',            'G4110', 8);

INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc, num_officials)
SELECT n.geo_id, n.label, 'LOCAL', 'ak', 'Anchorage', n.mtfcc, n.num_officials
FROM anc_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL');

-- ── Offices ───────────────────────────────────────────────────────────────────
-- Seat letters are the Municipality's own and are load-bearing: an Anchorage ballot names the
-- seat, not just the district, and two members of the same district are elected in different
-- years. The letter is carried in the title so a voter can match what they saw on the ballot.
CREATE TEMP TABLE anc_offices(geo_id text, mtfcc text, chamber_name text, title text, note text) ON COMMIT DROP;
INSERT INTO anc_offices(geo_id, mtfcc, chamber_name, title, note) VALUES
  ('anchorage-ak-assembly-1','X0081','Anchorage Assembly','Assembly Member, District 1 Seat B', NULL),
  ('anchorage-ak-assembly-1','X0081','Anchorage Assembly','Assembly Member, District 1 Seat L', NULL),
  ('anchorage-ak-assembly-2','X0081','Anchorage Assembly','Assembly Member, District 2 Seat A', NULL),
  ('anchorage-ak-assembly-2','X0081','Anchorage Assembly','Assembly Member, District 2 Seat C', NULL),
  ('anchorage-ak-assembly-3','X0081','Anchorage Assembly','Assembly Member, District 3 Seat D', NULL),
  ('anchorage-ak-assembly-3','X0081','Anchorage Assembly','Assembly Member, District 3 Seat E', NULL),
  ('anchorage-ak-assembly-4','X0081','Anchorage Assembly','Assembly Member, District 4 Seat F', NULL),
  ('anchorage-ak-assembly-4','X0081','Anchorage Assembly','Assembly Member, District 4 Seat G', NULL),
  ('anchorage-ak-assembly-5','X0081','Anchorage Assembly','Assembly Member, District 5 Seat H', NULL),
  ('anchorage-ak-assembly-5','X0081','Anchorage Assembly','Assembly Member, District 5 Seat I', NULL),
  ('anchorage-ak-assembly-6','X0081','Anchorage Assembly','Assembly Member, District 6 Seat J', NULL),
  ('anchorage-ak-assembly-6','X0081','Anchorage Assembly','Assembly Member, District 6 Seat K', NULL),
  ('0203000','G4110','Office of the Mayor','Mayor',
     'Elected municipality-wide to a three-year term beginning 1 July. Anchorage is a strong-mayor '
     || 'municipality: the Mayor is the chief executive and is not a member of the Assembly.'),
  ('0203000','G4110','Anchorage School Board','School Board Member, Seat A', NULL),
  ('0203000','G4110','Anchorage School Board','School Board Member, Seat B', NULL),
  ('0203000','G4110','Anchorage School Board','School Board Member, Seat C', NULL),
  ('0203000','G4110','Anchorage School Board','School Board Member, Seat D', NULL),
  ('0203000','G4110','Anchorage School Board','School Board Member, Seat E', NULL),
  ('0203000','G4110','Anchorage School Board','School Board Member, Seat F', NULL),
  ('0203000','G4110','Anchorage School Board','School Board Member, Seat G', NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers, representation_note)
SELECT c.id, d.id, n.title, 'AK', 'Anchorage', 1, false, 'full', n.note
FROM anc_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL' AND lower(d.state) = 'ak'
JOIN essentials.governments g ON g.name = 'Municipality of Anchorage, Alaska, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ── People ────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE anc_roster(
  title       text PRIMARY KEY,
  full_name   text NOT NULL,
  first_name  text NOT NULL,
  last_name   text NOT NULL,
  term_start  date,
  precision   text NOT NULL,
  source      text NOT NULL,
  office_id     uuid,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO anc_roster(title, full_name, first_name, last_name, term_start, precision, source) VALUES
  ('Mayor', 'Suzanne LaFrance', 'Suzanne', 'LaFrance', DATE '2024-07-01', 'day',
   'muni.org Mayor''s page, read 2026-10-27 (CC_0303): "Mayor Suzanne LaFrance ... Term: July 1, 2024 to June 30, 2027". This is an occupancy, published by the office itself, not an election date.'),

  ('Assembly Member, District 1 Seat B','Sydney Scout','Sydney','Scout', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2026 and TERM ENDS 4/2029; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 1 Seat L','Daniel Volland','Daniel','Volland', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 7/2022 and 4/2025, TERM ENDS 4/2028; start_precision unknown because an election date is not an occupancy start. Serves as Assembly Vice Chair, a rotating role conferred by the Assembly and not a seat.'),
  ('Assembly Member, District 2 Seat A','Jared Goecker','Jared','Goecker', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2025 and TERM ENDS 4/2028; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 2 Seat C','Donald Handeland','Donald','Handeland', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2026 and TERM ENDS 4/2029; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 3 Seat D','Kameron Perez-Verdia','Kameron','Perez-Verdia', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2019, 4/2022 and 4/2025, TERM ENDS 4/2028; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 3 Seat E','Anna Brawley','Anna','Brawley', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2023 and 4/2026, TERM ENDS 4/2029; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 4 Seat F','Erin Baldwin Day','Erin','Baldwin Day', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2025 and TERM ENDS 4/2028; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 4 Seat G','Janice Park','Janice','Park', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2026 and TERM ENDS 4/2029; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 5 Seat H','Yarrow Silvers','Yarrow','Silvers', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2025 and TERM ENDS 4/2028; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 5 Seat I','George Martinez','George','Martinez', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2023 and 4/2026, TERM ENDS 4/2029; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 6 Seat J','Keith McCormick','Keith','McCormick', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2025 and TERM ENDS 4/2028; start_precision unknown because an election date is not an occupancy start.'),
  ('Assembly Member, District 6 Seat K','Zac Johnson','Zac','Johnson', NULL,'unknown',
   'Municipal Clerk, Assembly Members Public Contact List rev. 04/29/2026, and muni.org member profiles, both read 2026-10-27 (CC_0303). Clerk prints ELECTED/REELECTED 4/2023 and 4/2026, TERM ENDS 4/2029; start_precision unknown because an election date is not an occupancy start.'),

  ('School Board Member, Seat A','Margo Bellamy','Margo','Bellamy', NULL,'unknown',
   'asdk12.org School Board members page, read 2026-10-27 (CC_0303): "Margo Bellamy — Seat A through April 2028, third term", serving as Clerk. No election or swearing-in date is published; start_precision unknown.'),
  ('School Board Member, Seat B','Kelly Lessens','Kelly','Lessens', NULL,'unknown',
   'asdk12.org School Board members page, read 2026-10-27 (CC_0303): "Kelly Lessens — Seat B through April 2028, second full term", serving as Vice President. No election or swearing-in date is published; start_precision unknown.'),
  ('School Board Member, Seat C','Rachel Blakeslee','Rachel','Blakeslee', NULL,'unknown',
   'asdk12.org School Board members page, read 2026-10-27 (CC_0303): "Rachel Blakeslee — Seat C through April 2029, first term", serving as Treasurer. No election or swearing-in date is published; start_precision unknown.'),
  ('School Board Member, Seat D','Paul McDonogh','Paul','McDonogh', NULL,'unknown',
   'asdk12.org School Board members page, read 2026-10-27 (CC_0303): "Paul McDonogh — Seat D through April 2029, first term". No election or swearing-in date is published; start_precision unknown.'),
  ('School Board Member, Seat E','Pat Higgins','Pat','Higgins', NULL,'unknown',
   'asdk12.org School Board members page, read 2026-10-27 (CC_0303): "Pat Higgins — Seat E through April 2027, second term". 🔴 His service is NOT continuous — the same page says he "first served on the Anchorage School Board from 2008 to 2017" — so no start date may be inferred from a first-elected year. start_precision unknown.'),
  ('School Board Member, Seat F','Dora Wilson','Dora','Wilson', NULL,'unknown',
   'asdk12.org School Board members page, read 2026-10-27 (CC_0303): "Dora Wilson — Seat F through April 2027, second term". No election or swearing-in date is published; start_precision unknown.'),
  ('School Board Member, Seat G','Carl Jacobs','Carl','Jacobs', NULL,'unknown',
   'asdk12.org School Board members page, read 2026-10-27 (CC_0303): "Carl Jacobs — Seat G through April 2027, second term", serving as School Board President; first elected 2021. No election or swearing-in date is published; start_precision unknown.');

-- Resolve each roster row to the office this migration just created.
UPDATE anc_roster r SET office_id = o.id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.name = 'Municipality of Anchorage, Alaska, US' AND o.title = r.title;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM anc_roster WHERE office_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'CC_0303: % roster row(s) did not resolve to an Anchorage office', n;
  END IF;
  SELECT count(*) INTO n FROM anc_roster r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'CC_0303: % Anchorage office(s) already carry a term — this is meant to be a '
                    'greenfield seed, so read those rows before going further', n;
  END IF;
END $$;

-- 🔴 `is_incumbent` is set EXPLICITLY on every insert. It defaults to false, and a seated person
--    inserted without it is HIDDEN from address search; `check:occupancy` fails an INSERT that
--    omits it.
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, true, true, r.source
  FROM anc_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.is_active);

UPDATE anc_roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
   AND p.is_active;

-- ── Seating ───────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM anc_roster ORDER BY title LOOP
    IF r.politician_id IS NULL THEN
      RAISE EXCEPTION 'CC_0303: % did not resolve to a person', r.title;
    END IF;
    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, start_precision, how_started, source)
    VALUES (r.office_id, r.politician_id, r.term_start, r.precision, 'elected', r.source);
    n := n + 1;
  END LOOP;
  IF n <> 20 THEN RAISE EXCEPTION 'CC_0303: expected 20 seatings, got %', n; END IF;
END $$;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov int; v_ch int; v_slug int; v_dist int; v_off int;
  v_assembly int; v_mayor int; v_school int;
  v_terms int; v_dated int; v_mayor_start date;
  v_nogeom int; v_notincumbent int; v_vacant int; v_dupname int;
  v_reach int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'Municipality of Anchorage, Alaska, US' AND geo_id = '0203000' AND mtfcc = 'G4110';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'CC_0303 gate: expected 1 Anchorage government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US';
  IF v_ch <> 3 THEN RAISE EXCEPTION 'CC_0303 gate: expected 3 chambers, found %', v_ch; END IF;

  -- The generated slug is what the app routes on; an empty one is a silent 404.
  SELECT count(*) INTO v_slug FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US'
     AND (c.slug IS NULL OR btrim(c.slug) = '');
  IF v_slug <> 0 THEN
    RAISE EXCEPTION 'CC_0303 gate: % Anchorage chamber(s) generated an EMPTY slug — name_formal '
                    'was not set', v_slug;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'LOCAL' AND lower(state) = 'ak' AND city = 'Anchorage';
  IF v_dist <> 7 THEN RAISE EXCEPTION 'CC_0303 gate: expected 7 Anchorage districts, found %', v_dist; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US';
  IF v_off <> 20 THEN RAISE EXCEPTION 'CC_0303 gate: expected 20 Anchorage offices, found %', v_off; END IF;

  SELECT
    count(*) FILTER (WHERE c.name = 'Anchorage Assembly'),
    count(*) FILTER (WHERE c.name = 'Office of the Mayor'),
    count(*) FILTER (WHERE c.name = 'Anchorage School Board')
    INTO v_assembly, v_mayor, v_school
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US';
  IF v_assembly <> 12 OR v_mayor <> 1 OR v_school <> 7 THEN
    RAISE EXCEPTION 'CC_0303 gate: chamber sizes are %/1 assembly, %/1 mayor, %/7 school board',
                    v_assembly, v_mayor, v_school;
  END IF;

  -- Every office is held. An office with no term row is invisible and nothing errors.
  SELECT count(*) INTO v_terms FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US' AND och.politician_id IS NOT NULL;
  IF v_terms <> 20 THEN
    RAISE EXCEPTION 'CC_0303 gate: % of 20 Anchorage offices resolve to a current holder', v_terms;
  END IF;

  -- 🔴 Exactly ONE dated term, and it is the Mayor's. See the DATES block in the header.
  SELECT count(*) INTO v_dated FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US' AND t.term_start IS NOT NULL;
  IF v_dated <> 1 THEN
    RAISE EXCEPTION 'CC_0303 gate: % Anchorage term(s) carry a start date, expected exactly 1 (the '
                    'Mayor). An "elected/reelected" year is not an occupancy start — see the '
                    'header, and note that Pat Higgins'' service is not continuous.', v_dated;
  END IF;
  SELECT t.term_start INTO v_mayor_start FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US' AND o.title = 'Mayor';
  IF v_mayor_start IS DISTINCT FROM DATE '2024-07-01' THEN
    RAISE EXCEPTION 'CC_0303 gate: the Mayor''s term_start is %, expected 2024-07-01', v_mayor_start;
  END IF;

  -- Every office sits on a district that has a polygon.
  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'CC_0303 gate: % Anchorage office(s) sit on a district with no polygon — '
                    'unreachable by any address, and nothing would error', v_nogeom;
  END IF;

  SELECT count(*) INTO v_notincumbent FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US'
     AND (p.is_incumbent IS NOT TRUE OR p.is_active IS NOT TRUE);
  IF v_notincumbent <> 0 THEN
    RAISE EXCEPTION 'CC_0303 gate: % seated Anchorage official(s) are not active incumbents and '
                    'would be hidden from address search', v_notincumbent;
  END IF;

  SELECT count(*) INTO v_vacant FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Municipality of Anchorage, Alaska, US'
     AND (o.is_vacant OR o.vacant_since IS NOT NULL);
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'CC_0303 gate: % Anchorage office(s) are flagged vacant while held — the '
                    'is_vacant trap emits a spurious all-NULL row for the holder', v_vacant;
  END IF;

  -- No two Anchorage seats resolve to the same person.
  SELECT count(*) INTO v_dupname FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Municipality of Anchorage, Alaska, US'
     GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'CC_0303 gate: % person(s) hold more than one Anchorage seat', v_dupname;
  END IF;

  -- An address in each of the six districts must reach exactly one assembly seat. Anchorage
  -- City Hall stands in for a real lookup; the loader proved the other three probes.
  SELECT count(*) INTO v_reach
    FROM essentials.geofence_boundaries b
    JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc AND d.district_type = 'LOCAL'
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE b.mtfcc = 'X0081'
     AND ST_Contains(b.geometry, ST_SetSRID(ST_MakePoint(-149.894191, 61.216527), 4326));
  IF v_reach <> 2 THEN
    RAISE EXCEPTION 'CC_0303 gate: an Anchorage City Hall point reaches % assembly office(s), '
                    'expected 2 (District 1 elects two seats)', v_reach;
  END IF;

  RAISE NOTICE 'CC_0303 OK: Anchorage seeded — 1 government, 3 chambers, 7 districts, 20 offices, '
               '20 holders, 1 dated term (Mayor 2024-07-01), City Hall reaches 2 assembly seats';
END $$;

COMMIT;
