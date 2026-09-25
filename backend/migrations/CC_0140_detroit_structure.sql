-- CC_0140_detroit_structure.sql
-- Knight Foundation program, wave MI-3 (structure half). Slot RESERVED from the allocator.
--
-- Production holds NO government row for Detroit and NO Detroit office of any kind. This
-- migration creates:
--
--   1. the government `City of Detroit, Michigan, US`;
--   2. eight districts — 7 council districts on the X0065 polygons MI-3 loaded, plus the
--      citywide district the at-large and executive seats hang on;
--   3. four chambers;
--   4. 18 offices, which is exactly what the charter says Detroit elects.
--
-- Creates NO people and NO terms -- CC_0141 does that, and the two are applied back to back.
--
-- 🔴🔴 THE OFFICE INVENTORY IS THE CHARTER'S OWN SENTENCE, NOT A TEMPLATE.
-- 2012 Detroit City Charter: "The elective officers of the city are the Mayor, the nine (9)
-- members comprising the City Council, the City Clerk and seven (7) elected Board of Police
-- Commissioners." That is 1 + 9 + 1 + 7 = 18, and the council splits 7 district + 2 at-large
-- because the charter establishes "seven (7) non at-large districts and one (1) at-large
-- district ... one (1) member shall be elected from each non at-large district and two (2)
-- members shall be elected from the at-large district".
--
-- 🔴🔴 DETROIT ELECTS ITS POLICE OVERSIGHT BOARD, AND MOST CITIES DO NOT. The Board of Police
-- Commissioners has ELEVEN members: 7 elected by district and 4 appointed by the Mayor with
-- Council approval. Only the 7 elected are seated here. The 4 appointees are NOT offices the
-- voters fill, and one of them is vacant today — neither fact belongs in this table.
-- ⚠ The elected members serve FOUR-year terms; the APPOINTED members serve up to five. The
-- board's own page states the five-year figure prominently, and it does not govern the seats
-- this migration creates.
--
-- 🔴🔴 ONE GEOGRAPHY, TWO ELECTED BODIES. "Police Commissioner districts have identical
-- boundaries to the City Council districts", so each of the 7 X0065 polygons carries TWO
-- offices and a Detroit address correctly returns BOTH a council member and a police
-- commissioner. ⚠ That is the Long Beach fan-out shape, and here it is CORRECT — the same
-- reason IN-5's three county commissioners all had to return. No coverage or fan-out check can
-- separate the two cases; only the charter can. The gate below asserts exactly 2 offices per
-- council district, so a future wave cannot quietly add a third.
--
-- 🔴 COMMUNITY ADVISORY COUNCILS ARE DELIBERATELY EXCLUDED (ruling 2026-09-24, Cantrell).
-- Detroit also elects 5-member Community Advisory Councils, on the city ballot, in the 3 of 7
-- districts that created one by petition (D4, D5, D7) — 15 more elected people. They are NOT in
-- the charter's enumeration of "the elective officers of the city", they hold no governing
-- power, and the set changes as districts opt in or out. Excluded, as SC-4 excluded Horry's 15
-- watershed commissioners. This is a recorded debt, not an oversight.
--
-- 🔴 THE DISTRICT MAP IS THE 2026 MAP AND THE VINTAGE QUESTION WAS REAL. Detroit publishes
-- `city_council_districts_2013`, `city_council_districts_2026` and a layer titled "Current".
-- The 2026 layer's own description: selected by City Council 8-1 on 2024-02-06 under charter
-- Sec. 3-108, "used to determine resident districts when voting in 2025 municipal elections,
-- and will officially take effect January 1, 2026". The sitting members took office that same
-- day. ⚠ NOTE THIS IS THE OPPOSITE ANSWER TO MI-1's SENATE, where the newer map was authorised
-- for a FUTURE election and the sitting members still represented the old one.
--
-- 🔴 CITYWIDE SEATS HANG ON THE PLACE POLYGON, district `2622000` / G4110 — the Akron pattern.
-- Detroit city is already present in geofence_boundaries at 142.9027 sq mi.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Refuse to run without the boundaries ──────────────────────────────────
-- An office on a district with no polygon is unreachable by any address, and NOTHING ERRORS.
DO $pre$
DECLARE v_b integer; v_p integer;
BEGIN
  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries WHERE mtfcc = 'X0065';
  IF v_b <> 7 THEN
    RAISE EXCEPTION 'MI-3 pre-flight: expected 7 X0065 council-district boundaries, found % — run scripts/load-detroit-council-boundaries.mjs first', v_b;
  END IF;
  SELECT count(*) INTO v_p FROM essentials.geofence_boundaries
   WHERE state = '26' AND mtfcc = 'G4110' AND geo_id = '2622000';
  IF v_p <> 1 THEN
    RAISE EXCEPTION 'MI-3 pre-flight: Detroit place polygon 2622000 not found (got %) — the citywide seats would be unreachable', v_p;
  END IF;
END
$pre$;

-- ─── 1. The government ────────────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Detroit, Michigan, US', 'City', 'MI', 'Detroit', '2622000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'City of Detroit, Michigan, US');

-- ─── 2. The districts ─────────────────────────────────────────────────────────
CREATE TEMP TABLE det_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO det_districts(geo_id, label, mtfcc) VALUES
  ('2622000',                      'Detroit Citywide',                 'G4110'),
  ('detroit-mi-council-district-1','Detroit City Council District 1',  'X0065'),
  ('detroit-mi-council-district-2','Detroit City Council District 2',  'X0065'),
  ('detroit-mi-council-district-3','Detroit City Council District 3',  'X0065'),
  ('detroit-mi-council-district-4','Detroit City Council District 4',  'X0065'),
  ('detroit-mi-council-district-5','Detroit City Council District 5',  'X0065'),
  ('detroit-mi-council-district-6','Detroit City Council District 6',  'X0065'),
  ('detroit-mi-council-district-7','Detroit City Council District 7',  'X0065');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'mi', n.mtfcc
FROM det_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.district_type = 'LOCAL' AND d.mtfcc = n.mtfcc);

-- ─── 3. The four chambers ─────────────────────────────────────────────────────
-- term_length: charter art. 3 — Mayor, Clerk and Council four years; elected Police
-- Commissioners four years (the board's five-year figure describes the APPOINTED members).
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.n, v.term
FROM essentials.governments g
JOIN (VALUES
  ('Office of the Mayor',                    1, '4'),
  ('Office of the City Clerk',               1, '4'),
  ('Detroit City Council',                   9, '4'),
  ('Detroit Board of Police Commissioners',  7, '4')
) AS v(name, n, term) ON true
WHERE g.name = 'City of Detroit, Michigan, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 4. The 18 offices ────────────────────────────────────────────────────────
CREATE TEMP TABLE det_offices(chamber_name text, title text, geo_id text, mtfcc text, ord int) ON COMMIT DROP;
INSERT INTO det_offices(chamber_name, title, geo_id, mtfcc, ord) VALUES
  ('Office of the Mayor',                   'Mayor',                        '2622000', 'G4110', 1),
  ('Office of the City Clerk',              'City Clerk',                   '2622000', 'G4110', 1),
  ('Detroit City Council', 'Council Member, District 1', 'detroit-mi-council-district-1', 'X0065', 1),
  ('Detroit City Council', 'Council Member, District 2', 'detroit-mi-council-district-2', 'X0065', 1),
  ('Detroit City Council', 'Council Member, District 3', 'detroit-mi-council-district-3', 'X0065', 1),
  ('Detroit City Council', 'Council Member, District 4', 'detroit-mi-council-district-4', 'X0065', 1),
  ('Detroit City Council', 'Council Member, District 5', 'detroit-mi-council-district-5', 'X0065', 1),
  ('Detroit City Council', 'Council Member, District 6', 'detroit-mi-council-district-6', 'X0065', 1),
  ('Detroit City Council', 'Council Member, District 7', 'detroit-mi-council-district-7', 'X0065', 1),
  ('Detroit City Council', 'Council Member, At Large',   '2622000', 'G4110', 1),
  ('Detroit City Council', 'Council Member, At Large',   '2622000', 'G4110', 2),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 1', 'detroit-mi-council-district-1', 'X0065', 1),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 2', 'detroit-mi-council-district-2', 'X0065', 1),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 3', 'detroit-mi-council-district-3', 'X0065', 1),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 4', 'detroit-mi-council-district-4', 'X0065', 1),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 5', 'detroit-mi-council-district-5', 'X0065', 1),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 6', 'detroit-mi-council-district-6', 'X0065', 1),
  ('Detroit Board of Police Commissioners', 'Police Commissioner, District 7', 'detroit-mi-council-district-7', 'X0065', 1);

-- The two at-large council seats share a title and a district, so they are distinguished by
-- `ord` and inserted one at a time; a plain NOT EXISTS on (chamber, district, title) would
-- create only one of them. This is the Akron/Duluth unnumbered-at-large shape.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'MI', 1, false, 'full'
FROM det_offices n
JOIN essentials.governments g ON g.name = 'City of Detroit, Michigan, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'LOCAL' AND lower(d.state) = 'mi'
WHERE (
  SELECT count(*) FROM essentials.offices o
   WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
) < n.ord;

-- ─── post-verify gate ─────────────────────────────────────────────────────────
DO $gate$
DECLARE
  v_gov integer; v_ch integer; v_off integer; v_vac integer;
  v_council integer; v_bopc integer; v_atlarge integer;
  v_perdist integer; v_nulldist integer; v_wrongstate integer;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'City of Detroit, Michigan, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'MI-3 gate 1: expected exactly 1 Detroit government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Detroit, Michigan, US';
  IF v_ch <> 4 THEN RAISE EXCEPTION 'MI-3 gate 2: expected 4 Detroit chambers, found %', v_ch; END IF;

  SELECT count(*), count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE c.name = 'Detroit City Council'),
         count(*) FILTER (WHERE c.name = 'Detroit Board of Police Commissioners'),
         count(*) FILTER (WHERE o.title = 'Council Member, At Large'),
         count(*) FILTER (WHERE o.district_id IS NULL)
    INTO v_off, v_vac, v_council, v_bopc, v_atlarge, v_nulldist
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Detroit, Michigan, US';

  IF v_off <> 18 THEN RAISE EXCEPTION 'MI-3 gate 3: the charter names 18 elective officers, found % offices', v_off; END IF;
  IF v_council <> 9 THEN RAISE EXCEPTION 'MI-3 gate 4: expected 9 council offices, found %', v_council; END IF;
  IF v_bopc <> 7 THEN RAISE EXCEPTION 'MI-3 gate 5: expected 7 ELECTED police commissioner offices, found % (the 4 mayoral appointees must never be seated)', v_bopc; END IF;
  IF v_atlarge <> 2 THEN RAISE EXCEPTION 'MI-3 gate 6: expected exactly 2 at-large council seats, found %', v_atlarge; END IF;
  IF v_vac <> 0 THEN RAISE EXCEPTION 'MI-3 gate 7: expected 0 vacant offices, found %', v_vac; END IF;
  IF v_nulldist <> 0 THEN RAISE EXCEPTION 'MI-3 gate 8: % office(s) have no district — unreachable by address', v_nulldist; END IF;

  -- 🔴 Each council district must carry EXACTLY TWO offices: one council member and one police
  -- commissioner. Fewer means a body was missed; more means something was double-created.
  SELECT count(*) INTO v_perdist FROM (
    SELECT d.geo_id FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Detroit, Michigan, US' AND d.mtfcc = 'X0065'
     GROUP BY d.geo_id HAVING count(*) <> 2) x;
  IF v_perdist <> 0 THEN
    RAISE EXCEPTION 'MI-3 gate 9: % council district(s) do not carry exactly 2 offices (1 council member + 1 police commissioner)', v_perdist;
  END IF;

  -- Nothing may have landed on a non-Detroit district.
  SELECT count(*) INTO v_wrongstate
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'City of Detroit, Michigan, US'
     AND (lower(d.state) <> 'mi' OR d.mtfcc NOT IN ('X0065','G4110'));
  IF v_wrongstate <> 0 THEN RAISE EXCEPTION 'MI-3 gate 10: % Detroit office(s) landed on a district that is not Detroit''s', v_wrongstate; END IF;

  RAISE NOTICE 'CC_0140 OK: 1 government, 4 chambers, 18 offices (9 council incl. 2 at-large, 7 elected police commissioners, Mayor, Clerk), 0 vacant, 2 offices per council district.';
END
$gate$;

COMMIT;
