-- CC_0111_mn_counties_structure.sql
-- Knight Foundation program, wave MN-4 (structure half). Slot RESERVED from the allocator.
--
-- Creates both county governments in slice 5, which have nothing in production today -- no
-- government row, no district, no office, no official. Every MN COUNTY-type office count in
-- production is 0, so both counties are a clean seed with nothing to repair:
--
--   St. Louis County   4 chambers   8 districts   10 offices  (7 commissioners + Sheriff + Attorney + Auditor)
--   Ramsey County      3 chambers   8 districts    9 offices  (7 commissioners + Sheriff + Attorney)
--
-- Creates NO people and NO terms -- CC_0112 does that, and the two are applied back to back.
--
-- 🔴🔴 THE TWO COUNTIES DO NOT ELECT THE SAME OFFICES, AND THE DIFFERENCE IS STATUTORY.
-- Minnesota's general rule, Minn. Stat. s 382.01, has every county elect an auditor, treasurer,
-- sheriff, recorder, attorney and coroner. NEITHER COUNTY MATCHES IT and they do not match each
-- other, because each is governed by its own special law:
--
--   Ramsey     s 383A.20 subd. 2(a): "the offices of county auditor, county treasurer, court
--              commissioner, and county recorder are not elective but filled by appointment by
--              the Ramsey County Board of Commissioners." Ramsey is Minnesota's ONLY home rule
--              charter county. Sheriff and County Attorney remain elective. -> NINE offices.
--   St. Louis  s 383C.136: the treasurer's office was abolished in 1969 and its duties
--              transferred to the auditor; no person was to be elected after 1986 to succeed the
--              recorder. So St. Louis elects an AUDITOR carrying the treasurer's functions --
--              styled Auditor/Treasurer -- which Ramsey does not elect at all. -> TEN offices.
--
-- ⚠ NEITHER COUNTY ELECTS A CORONER. Ramsey's medical examiner is appointed by the board and
--   serves Ramsey and Washington; St. Louis contracts with the Midwest Medical Examiner's Office
--   and has no county coroner post of any kind. s 382.01's coroner is not live in either.
--
-- ⚠ A SEARCH SUMMARY ASSERTED RAMSEY STILL ELECTS ITS AUDITOR, in the same breath as a list of
--   elective offices that did not include it. The statute settles it. A summary that contradicts
--   itself in adjacent sentences is not a source.
--
-- ▶ Nine and ten, not "the usual six". Read the governing instrument; do not carry one
--   jurisdiction's answer to the next, and do not make municipalities uniform.
--
-- 🔴 GEOMETRY COMES FROM scripts/load-mn-county-commissioner-boundaries.ts (X0054, X0055), NOT
-- from here, and the pre-flight below FAILS HARD if those fourteen boundaries are absent -- an
-- office on a district with no polygon is unreachable by address and nothing errors.
--
-- 🔴🔴 THE LOADER'S COVERAGE GATE IS NOT MN-3's, AND COPYING MN-3's WOULD HAVE REFUSED A CORRECT
-- MAP. Ramsey's seven districts tile the county exactly (100.000%). St. Louis's cover 98.220% --
-- below MN-3's 99.9% threshold -- and the layer is RIGHT: the gap is one 120.593 sq mi wedge of
-- Lake Superior lying between where the districts stop and where the county's boundary runs out
-- into the lake, plus 912 slivers under 0.01 sq mi of two agencies' line work. No incorporated
-- place sits in it; the nearest is Duluth, 3.98 km away. A SINGLE PERCENTAGE IS NOT A GATE --
-- what separated 98.220% from Duluth's superseded 89.176% was decomposing the gap.
--
-- ⚠ The 14 countywide seats hang on the EXISTING G4020 county polygons, which were already in
--   production before this wave opened. The seven commissioner districts per county hang on the
--   X0054/X0055 polygons the loader writes.
--
-- ⚠ districts.state is written LOWERCASE 'mn' and district_type is COUNTY, matching Manatee and
--   Palm Beach, the existing commissioner-district precedent. Always lower(d.state).
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight: the fourteen commissioner boundaries and both county polygons ───────

DO $$
DECLARE v_slc int; v_ram int;
BEGIN
  SELECT count(*) INTO v_slc FROM essentials.geofence_boundaries WHERE mtfcc = 'X0054';
  IF v_slc <> 7 THEN
    RAISE EXCEPTION 'MN-4 pre-flight: X0054 holds % St. Louis commissioner boundaries, expected 7. Run scripts/load-mn-county-commissioner-boundaries.ts first.', v_slc;
  END IF;
  SELECT count(*) INTO v_ram FROM essentials.geofence_boundaries WHERE mtfcc = 'X0055';
  IF v_ram <> 7 THEN
    RAISE EXCEPTION 'MN-4 pre-flight: X0055 holds % Ramsey commissioner boundaries, expected 7. Run scripts/load-mn-county-commissioner-boundaries.ts first.', v_ram;
  END IF;

  -- The countywide seats -- both sheriffs, both attorneys, St. Louis's auditor -- hang on these.
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '27137' AND mtfcc = 'G4020') THEN
    RAISE EXCEPTION 'MN-4 pre-flight: county polygon 27137/G4020 (St. Louis) is missing.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '27123' AND mtfcc = 'G4020') THEN
    RAISE EXCEPTION 'MN-4 pre-flight: county polygon 27123/G4020 (Ramsey) is missing.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id = '27137' AND district_type::text = 'COUNTY') THEN
    RAISE EXCEPTION 'MN-4 pre-flight: COUNTY district 27137 (St. Louis) is missing.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id = '27123' AND district_type::text = 'COUNTY') THEN
    RAISE EXCEPTION 'MN-4 pre-flight: COUNTY district 27123 (Ramsey) is missing.';
  END IF;

  -- 🔴 The boundaries must have come from THIS wave's loader. The loader stamps which.
  IF EXISTS (SELECT 1 FROM essentials.geofence_boundaries
              WHERE mtfcc = 'X0054' AND source NOT LIKE '%Open_Data/MapServer/21%') THEN
    RAISE EXCEPTION 'MN-4 pre-flight: an X0054 boundary did not come from GeneralUse/Open_Data/MapServer/21.';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.geofence_boundaries
              WHERE mtfcc = 'X0055' AND source NOT LIKE '%BOUND_CommissionerDistrict2022%') THEN
    RAISE EXCEPTION 'MN-4 pre-flight: an X0055 boundary did not come from BOUND_CommissionerDistrict2022_ViewOnly.';
  END IF;
END $$;

-- ─── 1. Two governments ──────────────────────────────────────────────────────
-- ⚠ Matched and guarded on geo_id, never on name. MN-3 met a Saint Paul in TEXAS; the same class
--   of collision is why nothing in this wave resolves a jurisdiction by its name.

INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'St. Louis County, Minnesota, US', 'County', 'MN', '27137'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '27137');

INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'Ramsey County, Minnesota, US', 'County', 'MN', '27123'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '27123');

-- ─── 2. Seven chambers -- FOUR for St. Louis, THREE for Ramsey ───────────────
-- 🔴 The asymmetry is the point. Ramsey gets no Office of the Auditor because s 383A.20 makes
--    that post appointive; St. Louis gets one because s 383C.136 left it elective and gave it
--    the abolished treasurer's duties.

CREATE TEMP TABLE mn4_chambers(county_geo_id text, name text, name_formal text, official_count int) ON COMMIT DROP;
INSERT INTO mn4_chambers(county_geo_id, name, name_formal, official_count) VALUES
  ('27137', 'Board of County Commissioners', 'St. Louis County Board of Commissioners', 7),
  ('27137', 'Office of the Sheriff',         'Office of the St. Louis County Sheriff', 1),
  ('27137', 'Office of the County Attorney', 'Office of the St. Louis County Attorney', 1),
  ('27137', 'Office of the Auditor',         'Office of the St. Louis County Auditor', 1),
  ('27123', 'Board of County Commissioners', 'Ramsey County Board of Commissioners', 7),
  ('27123', 'Office of the Sheriff',         'Office of the Ramsey County Sheriff', 1),
  ('27123', 'Office of the County Attorney', 'Office of the Ramsey County Attorney', 1);

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, n.name, n.name_formal, n.official_count
FROM mn4_chambers n
JOIN essentials.governments g ON g.geo_id = n.county_geo_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = n.name);

-- ─── 3. Fourteen commissioner districts ──────────────────────────────────────
-- The countywide offices reuse the COUNTY districts already in production (27137, 27123); only
-- the commissioner districts are new.

CREATE TEMP TABLE mn4_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO mn4_districts(geo_id, label, mtfcc) VALUES
  ('st-louis-mn-commissioner-district-1', 'St. Louis County Commissioner District 1', 'X0054'),
  ('st-louis-mn-commissioner-district-2', 'St. Louis County Commissioner District 2', 'X0054'),
  ('st-louis-mn-commissioner-district-3', 'St. Louis County Commissioner District 3', 'X0054'),
  ('st-louis-mn-commissioner-district-4', 'St. Louis County Commissioner District 4', 'X0054'),
  ('st-louis-mn-commissioner-district-5', 'St. Louis County Commissioner District 5', 'X0054'),
  ('st-louis-mn-commissioner-district-6', 'St. Louis County Commissioner District 6', 'X0054'),
  ('st-louis-mn-commissioner-district-7', 'St. Louis County Commissioner District 7', 'X0054'),
  ('ramsey-mn-commissioner-district-1',   'Ramsey County Commissioner District 1',    'X0055'),
  ('ramsey-mn-commissioner-district-2',   'Ramsey County Commissioner District 2',    'X0055'),
  ('ramsey-mn-commissioner-district-3',   'Ramsey County Commissioner District 3',    'X0055'),
  ('ramsey-mn-commissioner-district-4',   'Ramsey County Commissioner District 4',    'X0055'),
  ('ramsey-mn-commissioner-district-5',   'Ramsey County Commissioner District 5',    'X0055'),
  ('ramsey-mn-commissioner-district-6',   'Ramsey County Commissioner District 6',    'X0055'),
  ('ramsey-mn-commissioner-district-7',   'Ramsey County Commissioner District 7',    'X0055');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'COUNTY', 'mn', n.mtfcc
FROM mn4_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = n.geo_id AND d.district_type::text = 'COUNTY');

-- ─── 4. Nineteen offices ─────────────────────────────────────────────────────
-- 🔴 Every commissioner seat is numbered and district-based, so unlike Duluth's four at-large
--    councilors no internal ordinal is needed: title and district identify a seat uniquely.

CREATE TEMP TABLE mn4_offices(county_geo_id text, district_geo_id text, chamber_name text, title text) ON COMMIT DROP;
INSERT INTO mn4_offices(county_geo_id, district_geo_id, chamber_name, title) VALUES
  ('27137', 'st-louis-mn-commissioner-district-1', 'Board of County Commissioners', 'Commissioner, District 1'),
  ('27137', 'st-louis-mn-commissioner-district-2', 'Board of County Commissioners', 'Commissioner, District 2'),
  ('27137', 'st-louis-mn-commissioner-district-3', 'Board of County Commissioners', 'Commissioner, District 3'),
  ('27137', 'st-louis-mn-commissioner-district-4', 'Board of County Commissioners', 'Commissioner, District 4'),
  ('27137', 'st-louis-mn-commissioner-district-5', 'Board of County Commissioners', 'Commissioner, District 5'),
  ('27137', 'st-louis-mn-commissioner-district-6', 'Board of County Commissioners', 'Commissioner, District 6'),
  ('27137', 'st-louis-mn-commissioner-district-7', 'Board of County Commissioners', 'Commissioner, District 7'),
  ('27137', '27137', 'Office of the Sheriff',         'Sheriff'),
  ('27137', '27137', 'Office of the County Attorney', 'County Attorney'),
  ('27137', '27137', 'Office of the Auditor',         'Auditor/Treasurer'),
  ('27123', 'ramsey-mn-commissioner-district-1',   'Board of County Commissioners', 'Commissioner, District 1'),
  ('27123', 'ramsey-mn-commissioner-district-2',   'Board of County Commissioners', 'Commissioner, District 2'),
  ('27123', 'ramsey-mn-commissioner-district-3',   'Board of County Commissioners', 'Commissioner, District 3'),
  ('27123', 'ramsey-mn-commissioner-district-4',   'Board of County Commissioners', 'Commissioner, District 4'),
  ('27123', 'ramsey-mn-commissioner-district-5',   'Board of County Commissioners', 'Commissioner, District 5'),
  ('27123', 'ramsey-mn-commissioner-district-6',   'Board of County Commissioners', 'Commissioner, District 6'),
  ('27123', 'ramsey-mn-commissioner-district-7',   'Board of County Commissioners', 'Commissioner, District 7'),
  ('27123', '27123', 'Office of the Sheriff',         'Sheriff'),
  ('27123', '27123', 'Office of the County Attorney', 'County Attorney');

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'MN', 1, false, 'full'
FROM mn4_offices n
JOIN essentials.districts d ON d.geo_id = n.district_geo_id AND d.district_type::text = 'COUNTY' AND lower(d.state) = 'mn'
JOIN essentials.governments g ON g.geo_id = n.county_geo_id
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch_slc int; v_ch_ram int; v_dist int; v_off_slc int; v_off_ram int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE geo_id IN ('27137','27123') AND type = 'County';
  IF v_gov <> 2 THEN RAISE EXCEPTION 'MN-4 structure: expected 2 county governments, got %', v_gov; END IF;

  SELECT count(*) FILTER (WHERE g.geo_id = '27137'), count(*) FILTER (WHERE g.geo_id = '27123')
    INTO v_ch_slc, v_ch_ram
  FROM essentials.chambers c JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('27137','27123');
  -- 🔴 FOUR AND THREE, NOT "four and four". Ramsey's auditor is appointive under s 383A.20.
  IF v_ch_slc <> 4 OR v_ch_ram <> 3 THEN
    RAISE EXCEPTION 'MN-4 structure: expected 4 St. Louis + 3 Ramsey chambers, got % + %', v_ch_slc, v_ch_ram;
  END IF;

  -- Ramsey must NOT gain an elected auditor, treasurer or recorder. The two counties are not
  -- made uniform, and this is the assertion that keeps them apart.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.geo_id = '27123'
      AND (o.title ILIKE '%auditor%' OR o.title ILIKE '%treasurer%' OR o.title ILIKE '%recorder%')
  ) THEN
    RAISE EXCEPTION 'MN-4 structure: Ramsey has an elected auditor/treasurer/recorder office; s 383A.20 subd. 2(a) makes all three appointive';
  END IF;

  -- Neither county elects a coroner. Both use an appointed or contracted medical examiner.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.geo_id IN ('27137','27123') AND o.title ILIKE '%coroner%'
  ) THEN
    RAISE EXCEPTION 'MN-4 structure: a coroner office exists; neither county elects one';
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type::text = 'COUNTY' AND lower(state) = 'mn' AND mtfcc IN ('X0054','X0055');
  IF v_dist <> 14 THEN RAISE EXCEPTION 'MN-4 structure: expected 14 commissioner districts, got %', v_dist; END IF;

  SELECT count(*) FILTER (WHERE g.geo_id = '27137'), count(*) FILTER (WHERE g.geo_id = '27123')
    INTO v_off_slc, v_off_ram
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id IN ('27137','27123');
  IF v_off_slc <> 10 OR v_off_ram <> 9 THEN
    RAISE EXCEPTION 'MN-4 structure: expected 10 St. Louis + 9 Ramsey offices, got % + %', v_off_slc, v_off_ram;
  END IF;

  -- Every commissioner district must carry exactly one office, and every one of them must have a
  -- polygon. 🔴 An office on a district with no geometry is unreachable and nothing errors.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE d.mtfcc IN ('X0054','X0055') AND lower(d.state) = 'mn'
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'MN-4 structure: a commissioner district does not carry exactly one office';
  END IF;

  SELECT count(*) INTO v_orphan
  FROM essentials.districts d
  WHERE d.mtfcc IN ('X0054','X0055') AND lower(d.state) = 'mn'
    AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_orphan <> 0 THEN
    RAISE EXCEPTION 'MN-4 structure: % commissioner district(s) have no polygon', v_orphan;
  END IF;

  RAISE NOTICE 'MN-4 structure OK: 2 governments, % + % chambers, % commissioner districts, % + % offices',
    v_ch_slc, v_ch_ram, v_dist, v_off_slc, v_off_ram;
END $$;

COMMIT;
