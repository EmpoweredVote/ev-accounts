-- CC_0099_lake_county_council_districts_structure.sql
-- Knight Foundation program, wave IN-9 (structure half). Slot RESERVED from the allocator.
--
-- Creates Lake County's SEVEN council district rows and their SEVEN offices, on the boundaries
-- scripts/load-lake-county-council-boundaries.ts wrote to mtfcc 'X0051'.
-- Creates NO people and NO terms -- CC_0100 does that, applied immediately after.
--
-- After this pair, Lake County holds 19 of 19 offices: 3 commissioners + 9 elected officials
-- (CC_0095) + 7 council districts.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THESE SEVEN SEATS WERE DEFERRED THROUGH IN-4, IN-6 AND IN-8 BECAUSE THE GEOMETRY WAS
--    BELIEVED NOT TO EXIST. IT DID. IT IS PUBLISHED BY THE STATE, NOT THE COUNTY.
--
-- The districts are `WAYEO_WebMap_WFL1` layer 8 -- the Indiana GIO's statewide county-council
-- layer behind the Secretary of State's "Who Are Your Elected Officials" lookup. The county's
-- own page, `departments/council/find-my-council-district`, tells residents to use exactly that
-- tool and filter to the County level. So the answer was in PROSE on the page the earlier waves
-- had already read, while three sweeps looked for a LAYER in the county's ArcGIS orgs.
--
-- ▶ IN-8 learned "a negative result is only ever true of the place you looked", and that was
--   right but not sufficient. The sharper rule: READ THE HUMAN-FACING PAGE BEFORE SWEEPING THE
--   MACHINE-FACING ONE. The Surveyor's org has now been enumerated to exhaustion -- 149 services,
--   234 layers -- and genuinely holds no council-district layer. It never would.
--
-- 🔴 THE LAYER IS STATEWIDE. Lake is the ONLY Indiana county with seven council districts
-- (89 counties have 4, St. Joseph 9, Marion 25), and `councildistrictid` carries '089', Lake's
-- FIPS county code. The loader's GATE 1 pins both, because a missing County filter would load
-- some other county's map under these geo_ids.
--
-- 🔴🔴 VINTAGE. Gary's six seats were blocked for three waves by maps that were the WRONG YEAR
-- and looked right. This layer was therefore compared, precinct by precinct, against the county's
-- own `CC_District_Map3X5.pdf` -- prepared by the Lake County Board of Elections & Registration
-- in Esri ArcMap 10.8.1 on 2022-01-26, the post-2020-census redistricting map:
--
--     339 of 339 precincts agree. Zero disagreements.
--     All 342 current precincts nest wholly inside exactly one district.
--     The seven close against the county polygon: 626.6373 sq mi against 626.6286.
--
-- That comparison is frozen in backend/data/seed-lake-county-2026/wayeo-vs-county-2022-precinct-gate.json
-- and re-checked by the loader's GATE 6 on every run.
--
-- ⚠ FOUR DETACHED FRAGMENTS, all islands inside District 6, and TWO OF THEM ARE REAL:
-- unincorporated pockets inside Crown Point holding 29 addresses between them, which the county's
-- own map paints District 7 on every colour-bearing sample. The other two reach no address at all.
-- GATE 7 in the loader pins the inventory. Do not "clean" them.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────
-- 🔴 The seven boundaries must already exist. Creating an office with no geometry is the defect
-- this slice measured at 671 unreachable Indiana offices, and it is exactly what IN-4 and IN-6
-- refused to do here. If the loader has not run, stop.

DO $$
DECLARE v_b int; v_gov int; v_ch int; v_off int; v_count int;
BEGIN
  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0051' AND geo_id LIKE 'lake-county-in-council-district-%';
  IF v_b <> 7 THEN
    RAISE EXCEPTION 'IN-9 pre-flight: % X0051 Lake council boundaries, expected 7. Run scripts/load-lake-county-council-boundaries.ts first.', v_b;
  END IF;

  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'Lake County, Indiana, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'IN-9 pre-flight: % Lake County government rows, expected 1 (CC_0095)', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Lake County, Indiana, US' AND c.name = 'Lake County Council';
  IF v_ch <> 1 THEN RAISE EXCEPTION 'IN-9 pre-flight: Lake County Council chamber missing (CC_0095)'; END IF;

  -- IN-6 created the chamber and deliberately left it EMPTY rather than create seven offices
  -- with no geometry. That emptiness is the thing this migration is allowed to change.
  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Lake County, Indiana, US' AND c.name = 'Lake County Council';
  IF v_off NOT IN (0, 7) THEN
    RAISE EXCEPTION 'IN-9 pre-flight: Lake County Council already holds % office(s); expected 0 (deferred) or 7 (re-run)', v_off;
  END IF;

  SELECT official_count INTO v_count FROM essentials.chambers c
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Lake County, Indiana, US' AND c.name = 'Lake County Council';
  IF v_count <> 7 THEN RAISE EXCEPTION 'IN-9 pre-flight: Lake County Council official_count is %, expected 7', v_count; END IF;
END $$;

-- ─── 1. Seven districts ──────────────────────────────────────────────────────
-- 🔴 district_type = 'COUNTY', matching Allen County's X0049 rows. Gary's are 'LOCAL' because
-- they are city council districts; these are county ones and must not be inherited from Gary.

CREATE TEMP TABLE lake_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO lake_districts VALUES
  ('lake-county-in-council-district-1', 'Lake County Council District 1', 'X0051'),
  ('lake-county-in-council-district-2', 'Lake County Council District 2', 'X0051'),
  ('lake-county-in-council-district-3', 'Lake County Council District 3', 'X0051'),
  ('lake-county-in-council-district-4', 'Lake County Council District 4', 'X0051'),
  ('lake-county-in-council-district-5', 'Lake County Council District 5', 'X0051'),
  ('lake-county-in-council-district-6', 'Lake County Council District 6', 'X0051'),
  ('lake-county-in-council-district-7', 'Lake County Council District 7', 'X0051');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'COUNTY', 'in', n.mtfcc
FROM lake_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = n.geo_id AND d.district_type = 'COUNTY');

-- ─── 2. Seven offices ────────────────────────────────────────────────────────
-- 🔴 UNLIKE THE THREE COMMISSIONERS, THESE SEVEN ARE ELECTED BY DISTRICT. Lake's commissioners
-- sit on the county polygon because Indiana elects them county-wide from residency districts;
-- the council's seven are genuinely single-member, so each hangs on its own polygon.

CREATE TEMP TABLE lake_district_offices(geo_id text, title text) ON COMMIT DROP;
INSERT INTO lake_district_offices VALUES
  ('lake-county-in-council-district-1', 'Council Member, District 1'),
  ('lake-county-in-council-district-2', 'Council Member, District 2'),
  ('lake-county-in-council-district-3', 'Council Member, District 3'),
  ('lake-county-in-council-district-4', 'Council Member, District 4'),
  ('lake-county-in-council-district-5', 'Council Member, District 5'),
  ('lake-county-in-council-district-6', 'Council Member, District 6'),
  ('lake-county-in-council-district-7', 'Council Member, District 7');

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, NULL, 'IN', NULL, 1, false, 'full'
FROM lake_district_offices n
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.district_type = 'COUNTY' AND lower(d.state) = 'in'
JOIN essentials.governments g ON g.name = 'Lake County, Indiana, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Lake County Council'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title);

-- ─── Post-verify gate ────────────────────────────────────────────────────────
-- 🔴 SCOPED TO WHAT THIS MIGRATION CREATES. GA-5's gates counted a whole GOVERNMENT and broke
-- when a later wave added offices to it. These count X0051 and the council chamber only.

DO $$
DECLARE v_d int; v_nogeom int; v_off int; v_council int; v_fan int; v_vac int;
BEGIN
  SELECT count(*) INTO v_d FROM essentials.districts
   WHERE mtfcc = 'X0051' AND district_type = 'COUNTY' AND lower(state) = 'in';
  IF v_d <> 7 THEN RAISE EXCEPTION 'IN-9 structure: % X0051 districts, expected 7', v_d; END IF;

  -- Every district created here must have geometry. This is the whole reason IN-4 and IN-6 deferred.
  SELECT count(*) INTO v_nogeom FROM essentials.districts d
   WHERE d.mtfcc = 'X0051'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'IN-9 structure: % Lake council district(s) have NO boundary -- they would be unreachable by any address', v_nogeom;
  END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0051' AND o.title LIKE 'Council Member, District%';
  IF v_off <> 7 THEN RAISE EXCEPTION 'IN-9 structure: % offices on X0051 districts, expected 7', v_off; END IF;

  -- The council is complete at seven, which is its official_count and its statutory size.
  SELECT count(*) INTO v_council FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Lake County, Indiana, US' AND c.name = 'Lake County Council';
  IF v_council <> 7 THEN RAISE EXCEPTION 'IN-9 structure: Lake County Council holds % offices, expected 7', v_council; END IF;

  -- 🔴 THE LONG BEACH TEST. Nine councilmembers sharing one polygon returned all nine to every
  -- address. Each of the seven must sit on its OWN district row.
  SELECT count(*) INTO v_fan FROM (
    SELECT o.district_id FROM essentials.offices o
     JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.mtfcc = 'X0051'
     GROUP BY o.district_id HAVING count(*) > 1) s;
  IF v_fan <> 0 THEN
    RAISE EXCEPTION 'IN-9 structure: % district row(s) carry more than one council office -- one address would return several councilmembers (the Long Beach defect)', v_fan;
  END IF;

  -- 🔴 THE is_vacant TRAP. These seven are about to be seated by CC_0100; none may be flagged
  -- vacant, or a query filtering is_vacant = false emits a spurious all-NULL row for its holder.
  SELECT count(*) INTO v_vac FROM essentials.offices o
   JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0051' AND o.is_vacant;
  IF v_vac <> 0 THEN RAISE EXCEPTION 'IN-9 structure: % X0051 office(s) flagged is_vacant', v_vac; END IF;

  RAISE NOTICE 'IN-9 structure OK: 7 districts on X0051 all with geometry, 7 offices; Lake County Council now 7 of 7, unseated';
END $$;

COMMIT;
