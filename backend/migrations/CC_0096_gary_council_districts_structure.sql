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

BEGIN;

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

COMMIT;
