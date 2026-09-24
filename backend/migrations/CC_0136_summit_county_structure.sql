-- CC_0136_summit_county_structure.sql
-- Knight Foundation program, wave OH-4 (structure half). Slot RESERVED from the allocator.
--
-- Summit County holds NO offices and NO government row today. This migration creates:
--
--   1 government  County of Summit, Ohio, US (TIGER county 39153)
--   3 chambers    Summit County Council (11), Office of the County Executive (1),
--                 Elected Officials (5)
--   8 districts   the council districts on X0064; the COUNTYWIDE district ALREADY EXISTS and is
--                 REUSED, not recreated (essentials.districts geo_id 39153 / G4020, 0 offices,
--                 NULL government_id, measured 2026-09-24)
--  17 offices     8 district council + 3 at-large council + Executive + 5 elected officers
--
-- Creates NO people and NO terms -- CC_0137 does that, and the two are applied back to back.
--
-- 🔴🔴 SUMMIT IS A CHARTER COUNTY, SO THE OHIO STATUTORY TEMPLATE IS WRONG HERE, AND THE KNIGHT
-- SPEC'S "THE COUNTY OFFICER TEMPLATE IS STATE-SCOPED BECAUSE STATE LAW DEFINES IT" DOES NOT HOLD.
-- Ohio's other 86 counties elect three County Commissioners plus an Auditor, Treasurer, Recorder,
-- Clerk of Courts, Coroner, Engineer, Prosecutor and Sheriff. Summit elects NONE of that shape:
--   · an elected COUNTY EXECUTIVE and NO commissioners;
--   · an ELEVEN-member Council -- 8 by district, 3 at large -- enlarged to 11 by the voters in 1988;
--   · and only FIVE row officers: Clerk of Courts, Engineer, Fiscal Officer, Prosecutor, Sheriff.
-- 🔴 THERE IS NO ELECTED AUDITOR, TREASURER OR RECORDER: the charter merged all three into the
-- FISCAL OFFICER, and the Fiscal Officer's own site says so in its own words -- "manages the county
-- divisions of Auditor, Recorder, and Treasurer". There is no elected Coroner either; Summit uses
-- an appointed Medical Examiner. ▶ A statutory Ohio template would have invented FOUR offices that
-- do not exist and missed TWO that do. Only Cuyahoga shares this shape, so stage 4 here buys
-- nothing reusable for a later Ohio county -- the opposite of what the state-slice argument predicts.
--
-- 🔴🔴 THE COUNTY PUBLISHES TWO COUNCIL MAPS THAT DISAGREE ABOUT AKRON, AND THE CHOICE WAS
-- ARBITRATED, NOT GUESSED. Akron City Hall is District 5 on the superseded `County_Council_2023`
-- layer and District 4 on `Summit_County_Council_2025` ("Plan A4"), which is what X0064 carries.
-- Full reasoning and the 17-of-18 arbiter live in scripts/load-summit-council-boundaries.mjs.
-- ⚠ ONE PIECE OF EVIDENCE POINTS THE OTHER WAY and is recorded rather than buried: Jeff Wilhite's
-- own council page says his District 4 covers Bath Township, which Plan A4 places in District 5.
-- ▶ If this is ever overturned, District 4 vs District 5 for Akron is the first thing to re-check.
--
-- 🔴 THE COUNTYWIDE DISTRICT IS REUSED, NOT CREATED. essentials.districts already holds Summit
-- County as a COUNTY district on (geo_id 39153, mtfcc G4020) with an ocd_id and zero offices.
-- Creating a second row would split the county in two and leave one of them address-unreachable.
-- ⚠ district_type is 'COUNTY', not 'LOCAL' -- the Racine County precedent. 'LOCAL' is for city
-- bodies and consolidated city-counties.
--
-- 🔴 GEOMETRY MUST EXIST FIRST. The pre-flight refuses to run without the eight X0064 polygons and
-- the TIGER county row. An office on a district with no polygon is unreachable by any address and
-- NOTHING ERRORS.
--
-- ⚠ THERE IS A SUMMIT COUNTY IN UTAH AND PRODUCTION ALREADY HOLDS IT ('Summit County, Utah, US',
-- geo_id 49043). Every guard below keys on the Ohio row's own name or on (geo_id, state).
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_d int; v_cty int; v_existing int;
BEGIN
  SELECT count(*) INTO v_d FROM essentials.geofence_boundaries WHERE mtfcc = 'X0064';
  IF v_d <> 8 THEN
    RAISE EXCEPTION 'OH-4 pre-flight: expected 8 X0064 Summit council-district boundaries, found %. Run scripts/load-summit-council-boundaries.mjs first.', v_d;
  END IF;
  SELECT count(*) INTO v_cty FROM essentials.geofence_boundaries
   WHERE geo_id = '39153' AND mtfcc = 'G4020' AND state = '39';
  IF v_cty <> 1 THEN
    RAISE EXCEPTION 'OH-4 pre-flight: the TIGER county boundary 39153/G4020 (Summit, Ohio) is missing.';
  END IF;
  -- The countywide district must exist exactly once, and must be the OHIO one.
  SELECT count(*) INTO v_existing FROM essentials.districts
   WHERE geo_id = '39153' AND mtfcc = 'G4020' AND lower(state) = 'oh' AND district_type::text = 'COUNTY';
  IF v_existing <> 1 THEN
    RAISE EXCEPTION 'OH-4 pre-flight: expected exactly 1 existing Summit County (Ohio) COUNTY district, found %', v_existing;
  END IF;
END $$;

-- ─── 1. Government ───────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'County of Summit, Ohio, US', 'County', 'OH', NULL, '39153'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'County of Summit, Ohio, US');

-- ─── 2. Three chambers ───────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, remarks)
SELECT g.id, v.name, v.name_formal, v.official_count, v.remarks
FROM essentials.governments g
JOIN (VALUES
  ('Summit County Council', 'Summit County Council', 11,
   'Eight single-member districts plus three members elected at large. The voters enlarged the Council to eleven in 1988. District boundaries are drawn by the five-member Nonpartisan Independent Council Fair Districting Commission, which the voters created in 2015; the Council elects its own President and Vice President, so neither is a separate office.'),
  ('Office of the County Executive', 'Summit County Executive', 1,
   'Summit County is a CHARTER county. The charter gives administrative control to an elected County Executive, so Summit elects NO county commissioners -- unlike Ohio''s 86 statutory counties, which elect three.'),
  ('Elected Officials', 'Summit County Elected Officials', 5,
   'Clerk of Courts, Engineer, Fiscal Officer, Prosecutor and Sheriff, each elected countywide. There is NO elected Auditor, Treasurer or Recorder: the charter merged all three into the FISCAL OFFICER, whose office describes itself as managing "the county divisions of Auditor, Recorder, and Treasurer". There is no elected Coroner either; Summit uses an appointed Medical Examiner.')
) AS v(name, name_formal, official_count, remarks) ON true
WHERE g.name = 'County of Summit, Ohio, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Eight council districts ──────────────────────────────────────────────
-- The COUNTYWIDE district is deliberately absent from this list: it already exists.

CREATE TEMP TABLE sm_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO sm_districts(geo_id, label, mtfcc) VALUES
  ('summit-oh-council-district-1', 'Summit County Council District 1', 'X0064'),
  ('summit-oh-council-district-2', 'Summit County Council District 2', 'X0064'),
  ('summit-oh-council-district-3', 'Summit County Council District 3', 'X0064'),
  ('summit-oh-council-district-4', 'Summit County Council District 4', 'X0064'),
  ('summit-oh-council-district-5', 'Summit County Council District 5', 'X0064'),
  ('summit-oh-council-district-6', 'Summit County Council District 6', 'X0064'),
  ('summit-oh-council-district-7', 'Summit County Council District 7', 'X0064'),
  ('summit-oh-council-district-8', 'Summit County Council District 8', 'X0064');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'COUNTY', 'oh', n.mtfcc
FROM sm_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc);

-- ─── 4. Seventeen offices ────────────────────────────────────────────────────

CREATE TEMP TABLE sm_offices(geo_id text, mtfcc text, chamber_name text, title text, description text) ON COMMIT DROP;
INSERT INTO sm_offices(geo_id, mtfcc, chamber_name, title, description) VALUES
  ('summit-oh-council-district-1', 'X0064', 'Summit County Council', 'Council Member, District 1', NULL),
  ('summit-oh-council-district-2', 'X0064', 'Summit County Council', 'Council Member, District 2', NULL),
  ('summit-oh-council-district-3', 'X0064', 'Summit County Council', 'Council Member, District 3', NULL),
  ('summit-oh-council-district-4', 'X0064', 'Summit County Council', 'Council Member, District 4', NULL),
  ('summit-oh-council-district-5', 'X0064', 'Summit County Council', 'Council Member, District 5', NULL),
  ('summit-oh-council-district-6', 'X0064', 'Summit County Council', 'Council Member, District 6', NULL),
  ('summit-oh-council-district-7', 'X0064', 'Summit County Council', 'Council Member, District 7', NULL),
  ('summit-oh-council-district-8', 'X0064', 'Summit County Council', 'Council Member, District 8', NULL),
  -- ⚠ INTERNAL ORDINAL ONLY. Summit does not number its at-large seats; all three are elected
  -- countywide. This exists so CC_0137 can attach a person deterministically.
  ('39153', 'G4020', 'Summit County Council', 'Council Member, At Large',
   'Internal ordinal 1 of 3. Summit County does not number its at-large seats; not a ballot designation.'),
  ('39153', 'G4020', 'Summit County Council', 'Council Member, At Large',
   'Internal ordinal 2 of 3. Summit County does not number its at-large seats; not a ballot designation.'),
  ('39153', 'G4020', 'Summit County Council', 'Council Member, At Large',
   'Internal ordinal 3 of 3. Summit County does not number its at-large seats; not a ballot designation.'),
  ('39153', 'G4020', 'Office of the County Executive', 'County Executive', NULL),
  ('39153', 'G4020', 'Elected Officials', 'Clerk of Courts', NULL),
  ('39153', 'G4020', 'Elected Officials', 'County Engineer', NULL),
  ('39153', 'G4020', 'Elected Officials', 'Fiscal Officer',
   'The charter merged the statutory Auditor, Recorder and Treasurer into this one elected office.'),
  ('39153', 'G4020', 'Elected Officials', 'Prosecuting Attorney', NULL),
  ('39153', 'G4020', 'Elected Officials', 'Sheriff', NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'OH', 1, false, 'full'
FROM sm_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND lower(d.state) = 'oh' AND d.district_type::text = 'COUNTY'
JOIN essentials.governments g ON g.name = 'County of Summit, Ohio, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_chambers int; v_districts int; v_nogeom int;
  v_offices int; v_dist int; v_al int; v_exec int; v_officers int;
  v_ordinals int; v_banned int; v_utah int; v_akron int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'County of Summit, Ohio, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'OH-4 structure: expected 1 Summit (Ohio) government row, got %', v_gov; END IF;

  -- ⚠ The Utah namesake must be untouched.
  SELECT count(*) INTO v_utah FROM essentials.governments WHERE name = 'Summit County, Utah, US';
  IF v_utah <> 1 THEN RAISE EXCEPTION 'OH-4 structure: the Utah Summit County government row is not intact (got %)', v_utah; END IF;

  SELECT count(*) INTO v_chambers FROM essentials.chambers c
  JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = 'County of Summit, Ohio, US';
  IF v_chambers <> 3 THEN RAISE EXCEPTION 'OH-4 structure: expected 3 Summit chambers, got %', v_chambers; END IF;

  SELECT count(*) INTO v_districts FROM essentials.districts
   WHERE mtfcc = 'X0064' AND district_type::text = 'COUNTY' AND lower(state) = 'oh';
  IF v_districts <> 8 THEN RAISE EXCEPTION 'OH-4 structure: expected 8 X0064 districts, got %', v_districts; END IF;

  -- Every district carrying a Summit office must have geometry, keyed on (geo_id, mtfcc).
  SELECT count(*) INTO v_nogeom
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE g.name = 'County of Summit, Ohio, US'
    AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                     WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc AND b.geometry IS NOT NULL);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'OH-4 structure: % Summit office(s) sit on a district with no geometry — unreachable by address', v_nogeom;
  END IF;

  SELECT count(*) FILTER (WHERE o.title LIKE 'Council Member, District %'),
         count(*) FILTER (WHERE o.title = 'Council Member, At Large'),
         count(*) FILTER (WHERE o.title = 'County Executive'),
         count(*) FILTER (WHERE c.name = 'Elected Officials'),
         count(*)
    INTO v_dist, v_al, v_exec, v_officers, v_offices
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'County of Summit, Ohio, US';
  IF v_dist <> 8 THEN RAISE EXCEPTION 'OH-4 structure: % district council offices, expected 8', v_dist; END IF;
  IF v_al <> 3 THEN RAISE EXCEPTION 'OH-4 structure: % at-large council offices, expected 3', v_al; END IF;
  IF v_exec <> 1 THEN RAISE EXCEPTION 'OH-4 structure: % County Executive offices, expected 1', v_exec; END IF;
  IF v_officers <> 5 THEN RAISE EXCEPTION 'OH-4 structure: % elected-officer offices, expected 5', v_officers; END IF;
  IF v_offices <> 17 THEN RAISE EXCEPTION 'OH-4 structure: % Summit offices, expected 17', v_offices; END IF;

  SELECT count(DISTINCT o.description) INTO v_ordinals
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'County of Summit, Ohio, US' AND o.title = 'Council Member, At Large';
  IF v_ordinals <> 3 THEN
    RAISE EXCEPTION 'OH-4 structure: the 3 at-large offices carry % distinct ordinals, expected 3', v_ordinals;
  END IF;

  -- 🔴 THE CHARTER GATE. None of the four statutory offices the charter abolished may exist here,
  -- and no commissioner may either. This is the gate that would have caught an Ohio template.
  SELECT count(*) INTO v_banned
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'County of Summit, Ohio, US'
    AND o.title IN ('Auditor','County Auditor','Treasurer','County Treasurer','Recorder',
                    'County Recorder','Coroner','County Coroner','County Commissioner','Commissioner');
  IF v_banned <> 0 THEN
    RAISE EXCEPTION 'OH-4 structure: % Summit office(s) carry a title the charter abolished (Auditor/Treasurer/Recorder/Coroner/Commissioner)', v_banned;
  END IF;

  -- 🟢 The wave's own reason for existing: Akron City Hall must now sit in exactly one Summit
  -- council district, and it must be District 4 under the map this wave chose.
  SELECT count(*) INTO v_akron
  FROM essentials.geofence_boundaries b
  JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc AND lower(d.state) = 'oh'
  JOIN essentials.offices o ON o.district_id = d.id
  WHERE b.mtfcc = 'X0064'
    AND ST_Contains(b.geometry, ST_SetSRID(ST_Point(-81.51900, 41.08113), 4326))
    AND o.title = 'Council Member, District 4';
  IF v_akron <> 1 THEN
    RAISE EXCEPTION 'OH-4 structure: Akron City Hall does not resolve to exactly one District 4 council office (got %)', v_akron;
  END IF;

  RAISE NOTICE 'OH-4 structure OK: 1 government, 3 chambers, 8 new districts + the reused countywide row, 17 offices, 0 abolished titles, Akron City Hall = District 4';
END $$;

COMMIT;
