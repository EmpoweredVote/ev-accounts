-- CC_0142_wayne_county_structure.sql
-- Knight Foundation program, wave MI-4 (structure half). Slot RESERVED from the allocator.
--
-- Production holds NO government row for Wayne County and NO Wayne County office of any kind,
-- although the county's own TIGER district row (G4020 / 26163) has been present all along with a
-- NULL government_id. This migration creates:
--
--   1. the government `Wayne County, Michigan, US`;
--   2. 15 commission districts on the X0066 polygons MI-4 loaded — the countywide seats reuse
--      the EXISTING G4020 county district rather than creating a second one;
--   3. three chambers;
--   4. 21 offices, which is exactly what the charter says Wayne County elects.
--
-- Creates NO people and NO terms -- CC_0143 does that, and the two are applied back to back.
--
-- 🔴🔴 WAYNE IS A CHARTER COUNTY AND A MICHIGAN STATUTORY TEMPLATE DOES NOT DESCRIBE IT.
-- Home Rule Charter for the County of Wayne, adopted by the voters 1981-11-03, effective
-- 1983-01-01, amendments through 2012-11-06. Its own enumeration:
--   Sec. 9.111(a) — "The CEO shall be elected at large on a partisan basis for a 4 year term."
--   Sec. 3.111   — "The County Commission is the legislative body ... The Commission has 15
--                  members", elected from single-member districts (Sec. 3.112(a));
--   Sec. 2.211   — "the Sheriff, the Prosecuting Attorney, the County Clerk, the Treasurer, and
--                  the Register of Deeds are elected at large on a partisan basis to 4 year
--                  terms, which expire at the same time as the term of the Governor."
-- That is 1 + 15 + 5 = 21.
--
-- 🔴🔴 THE TEMPLATE WOULD INVENT OFFICES WAYNE'S VOTERS ABOLISHED. A general-law Michigan county
-- elects a Drain Commissioner (MCL 280.21) and may elect a Surveyor. Wayne elects NEITHER:
--   * DRAIN COMMISSIONER — deleted from Secs. 2.211 and 2.212 and its department repealed
--     (Secs. 4.261, 4.262, 4.263) at the general election of 1986-11-04, 291,053 yes to 114,465
--     no, effective 1987-01-01, its powers split between the executive and legislative branches;
--   * ROAD COMMISSION — abolished by a later amendment, its administrative powers vested in the
--     executive branch;
--   * AUDITOR GENERAL — Sec. 3.119, APPOINTED by a majority of Commissioners serving, not elected;
--   * no Surveyor and no Coroner appear in the charter at all.
-- GATE 11 asserts none of them exists. This is Summit County's lesson at OH-4 with a second
-- charter behind it: describe real powers, do not make jurisdictions uniform.
--
-- 🟢 THE CHARTER'S INVENTORY IS CORROBORATED BY A SECOND DOCUMENT. Sec. 2.112 composes the County
-- Apportionment Commission from "the County Clerk, the Treasurer, the Prosecuting Attorney and
-- the County chairperson of each of the 2 political parties". The 2021 apportionment resolution
-- is signed by Eric R. Sabree (Treasurer), Cathy M. Garrett (Clerk) and Kym L. Worthy
-- (Prosecuting Attorney) — the same three offices, named by a document written for another
-- purpose entirely.
--
-- 🔴 THE CHARTER IS THE AUTHORITY FOR THE INVENTORY BUT NOT FOR THE TERM. Sec. 3.112(a) says
-- "The term of office of a Commissioner is 2 years, concurrent with that of a State
-- representative." That is superseded by general law: Michigan extended county commissioners to
-- FOUR-year terms for those elected at or after the November 2024 general election. The county's
-- own "Commissioners by District" record heads its current block "Dist. 2025-28", and the
-- Commission's July 2025 journal treats the term appointed into as running to 2028. So
-- term_length is 4 for all three chambers. ▶ READ THE CHARTER FOR THE INVENTORY AND GENERAL LAW
-- FOR THE TERM — a charter that is right about what exists can be stale about how long it lasts.
--
-- 🔴 ONE GEOGRAPHY, ONE ELECTED BODY — THE OPPOSITE OF MI-3. Detroit's police-commission
-- districts are identical to its council districts, so each Detroit polygon carries two offices.
-- Wayne's commission districts carry exactly ONE office each, and GATE 9 pins that, so a later
-- wave cannot quietly hang a second body on this geography the way Detroit legitimately does.
--
-- 🔴 THE DISTRICT MAP IS THE 2021 APPORTIONMENT AND ITS VINTAGE WAS PROVED FROM THE DATA. The
-- county publishes four commission-district layers which are two maps, and THE COUNTY'S OWN LIVE
-- ARCGIS SERVICE IS THE SUPERSEDED 2012 ONE — byte-identical to Data Driven Detroit's 2012 layer
-- and still naming commissioners who left years ago. The current map is the static zip on the
-- county's GIS Data page, identified by reproducing all fifteen of the adopted Staff Plan 2021's
-- district populations exactly. See scripts/load-wayne-commission-boundaries.mjs.
--
-- 🔴 COUNTYWIDE SEATS HANG ON THE EXISTING G4020 COUNTY DISTRICT, geo_id 26163, already present
-- at 672.3911 sq mi. This migration does NOT create a second countywide district — Detroit
-- needed one because no Detroit district existed; Wayne's has been in the table all along.
--
-- ⚠ OUT OF SCOPE, DELIBERATELY. Wayne voters also elect Third Circuit and Probate Court judges
-- and the nine trustees of the Wayne County Community College District. No county stage 4 in
-- this programme has seated judges (Summit was Executive + 11 Council + 5 row officers). Excluded
-- as MI-3 excluded Detroit's Community Advisory Councils: a recorded, reversible debt, not an
-- oversight. The inclusion ruling does reach them.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Refuse to run without the boundaries ──────────────────────────────────
-- An office on a district with no polygon is unreachable by any address, and NOTHING ERRORS.
DO $pre$
DECLARE v_b integer; v_c integer;
BEGIN
  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries WHERE mtfcc = 'X0066';
  IF v_b <> 15 THEN
    RAISE EXCEPTION 'MI-4 pre-flight: expected 15 X0066 commission-district boundaries, found % — run scripts/load-wayne-commission-boundaries.mjs first', v_b;
  END IF;
  SELECT count(*) INTO v_c FROM essentials.geofence_boundaries
   WHERE state = '26' AND mtfcc = 'G4020' AND geo_id = '26163';
  IF v_c <> 1 THEN
    RAISE EXCEPTION 'MI-4 pre-flight: Wayne county polygon 26163 not found (got %) — the countywide seats would be unreachable', v_c;
  END IF;
  SELECT count(*) INTO v_c FROM essentials.districts
   WHERE geo_id = '26163' AND mtfcc = 'G4020' AND lower(state) = 'mi';
  IF v_c <> 1 THEN
    RAISE EXCEPTION 'MI-4 pre-flight: expected exactly 1 existing G4020 Wayne district row, found % — the countywide seats attach to it', v_c;
  END IF;
END
$pre$;

-- ─── 1. The government ────────────────────────────────────────────────────────
-- ⚠ The charter's formal style is "Charter County of Wayne", which is how the Commission heads
-- its own journals. The programme's government rows are named for the reader, matching
-- `Lake County, Indiana, US` and `Baldwin County, Georgia, US`.
INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Wayne County, Michigan, US', 'County', 'MI', '', '26163'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Wayne County, Michigan, US');

-- ─── 2. The fifteen commission districts ──────────────────────────────────────
-- The countywide district is NOT created here: it already exists as G4020 / 26163.
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT 'wayne-county-mi-commission-district-' || n,
       'Wayne County Commission District ' || n,
       'LOCAL', 'mi', 'X0066'
FROM generate_series(1, 15) AS n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = 'wayne-county-mi-commission-district-' || n
     AND d.district_type = 'LOCAL' AND d.mtfcc = 'X0066');

-- ─── 3. The three chambers ────────────────────────────────────────────────────
-- term_length 4 for all three: the CEO and the five row officers by charter Secs. 9.111(a) and
-- 2.211, the Commission by general law superseding Sec. 3.112(a) (see the header).
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.n, v.term
FROM essentials.governments g
JOIN (VALUES
  ('Office of the County Executive', 1,  '4'),
  ('Wayne County Commission',        15, '4'),
  ('Elected Officials',              5,  '4')
) AS v(name, n, term) ON true
WHERE g.name = 'Wayne County, Michigan, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 4. The 21 offices ────────────────────────────────────────────────────────
CREATE TEMP TABLE wayne_offices(chamber_name text, title text, geo_id text, mtfcc text) ON COMMIT DROP;

INSERT INTO wayne_offices(chamber_name, title, geo_id, mtfcc)
SELECT 'Wayne County Commission', 'Commissioner, District ' || n,
       'wayne-county-mi-commission-district-' || n, 'X0066'
FROM generate_series(1, 15) AS n;

-- The countywide six. Titles are the charter's own words: Sec. 2.211 says "Prosecuting
-- Attorney", which is also the ballot title, although the county's website says "Prosecutor".
INSERT INTO wayne_offices(chamber_name, title, geo_id, mtfcc) VALUES
  ('Office of the County Executive', 'County Executive',     '26163', 'G4020'),
  ('Elected Officials',              'Sheriff',              '26163', 'G4020'),
  ('Elected Officials',              'Prosecuting Attorney', '26163', 'G4020'),
  ('Elected Officials',              'County Clerk',         '26163', 'G4020'),
  ('Elected Officials',              'Treasurer',            '26163', 'G4020'),
  ('Elected Officials',              'Register of Deeds',    '26163', 'G4020');

-- Every Wayne title is unique, so a plain NOT EXISTS is correct here. Detroit needed an `ord`
-- column only because its two at-large council seats share a title and a district.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'MI', 1, false, 'full'
FROM wayne_offices n
JOIN essentials.governments g ON g.name = 'Wayne County, Michigan, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND lower(d.state) = 'mi'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title);

-- ─── post-verify gate ─────────────────────────────────────────────────────────
DO $gate$
DECLARE
  v_gov integer; v_ch integer; v_off integer; v_vac integer;
  v_comm integer; v_row integer; v_exec integer;
  v_perdist integer; v_nulldist integer; v_wrongstate integer; v_abolished integer;
  v_dist integer;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'Wayne County, Michigan, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'MI-4 gate 1: expected exactly 1 Wayne County government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US';
  IF v_ch <> 3 THEN RAISE EXCEPTION 'MI-4 gate 2: expected 3 Wayne County chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'X0066' AND district_type = 'LOCAL' AND lower(state) = 'mi';
  IF v_dist <> 15 THEN RAISE EXCEPTION 'MI-4 gate 3: expected 15 X0066 commission districts, found %', v_dist; END IF;

  SELECT count(*), count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE c.name = 'Wayne County Commission'),
         count(*) FILTER (WHERE c.name = 'Elected Officials'),
         count(*) FILTER (WHERE c.name = 'Office of the County Executive'),
         count(*) FILTER (WHERE o.district_id IS NULL)
    INTO v_off, v_vac, v_comm, v_row, v_exec, v_nulldist
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US';

  IF v_off  <> 21 THEN RAISE EXCEPTION 'MI-4 gate 4: the charter names 21 elected officers (CEO + 15 commissioners + 5 row officers), found % offices', v_off; END IF;
  IF v_comm <> 15 THEN RAISE EXCEPTION 'MI-4 gate 5: charter Sec. 3.111 says the Commission has 15 members, found % offices', v_comm; END IF;
  IF v_row  <> 5  THEN RAISE EXCEPTION 'MI-4 gate 6: charter Sec. 2.211 names 5 row officers, found %', v_row; END IF;
  IF v_exec <> 1  THEN RAISE EXCEPTION 'MI-4 gate 7: expected exactly 1 County Executive, found %', v_exec; END IF;
  IF v_vac  <> 0  THEN RAISE EXCEPTION 'MI-4 gate 8: expected 0 vacant offices, found %', v_vac; END IF;
  IF v_nulldist <> 0 THEN RAISE EXCEPTION 'MI-4 gate 9a: % office(s) have no district — unreachable by address', v_nulldist; END IF;

  -- 🔴 Each commission district must carry EXACTLY ONE office. Detroit's districts carry two
  -- because its charter elects two bodies from one geography; Wayne's charter does not.
  SELECT count(*) INTO v_perdist FROM (
    SELECT d.geo_id FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Wayne County, Michigan, US' AND d.mtfcc = 'X0066'
     GROUP BY d.geo_id HAVING count(*) <> 1) x;
  IF v_perdist <> 0 THEN
    RAISE EXCEPTION 'MI-4 gate 9b: % commission district(s) do not carry exactly 1 office', v_perdist;
  END IF;

  -- Nothing may have landed on a district that is not Wayne's.
  SELECT count(*) INTO v_wrongstate
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'Wayne County, Michigan, US'
     AND (lower(d.state) <> 'mi' OR d.mtfcc NOT IN ('X0066','G4020'));
  IF v_wrongstate <> 0 THEN RAISE EXCEPTION 'MI-4 gate 10: % Wayne office(s) landed on a district that is not Wayne''s', v_wrongstate; END IF;

  -- 🔴 The offices Wayne's voters abolished must NOT exist. This is the gate that a Michigan
  -- statutory template would trip: it would create a Drain Commissioner and probably a Surveyor.
  SELECT count(*) INTO v_abolished
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Wayne County, Michigan, US'
     AND (o.title ILIKE '%drain%' OR o.title ILIKE '%surveyor%' OR o.title ILIKE '%coroner%'
          OR o.title ILIKE '%auditor%' OR o.title ILIKE '%road commission%');
  IF v_abolished <> 0 THEN
    RAISE EXCEPTION 'MI-4 gate 11: % office(s) match an office Wayne does NOT elect (Drain Commissioner repealed 1986, Road Commission abolished, Auditor General appointed, no Surveyor or Coroner in the charter)', v_abolished;
  END IF;

  RAISE NOTICE 'CC_0142 OK: 1 government, 3 chambers, 15 X0066 districts, 21 offices (1 County Executive, 15 commissioners, 5 row officers), 0 vacant, 1 office per commission district, 0 abolished offices.';
END
$gate$;

COMMIT;
