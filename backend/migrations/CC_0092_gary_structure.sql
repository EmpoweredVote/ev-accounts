-- CC_0092_gary_structure.sql
-- Knight Foundation program, wave IN-4 (structure half). Slot RESERVED from the allocator.
--
-- Creates the City of Gary government, its FOUR chambers, ONE citywide district and SIX offices.
-- Creates NO people and NO terms -- CC_0093 does that, applied immediately after.
--
--   Gary Common Council       official_count 9   3 at-large seated here; 6 DISTRICT SEATS DEFERRED
--   Office of the Mayor       official_count 1   Mayor
--   Office of the City Clerk  official_count 1   City Clerk
--   Gary City Court           official_count 1   Judge of the City Court
--
-- 🔴🔴 GARY ELECTS TWELVE OFFICES AND FORT WAYNE ELECTS ELEVEN. THE DIFFERENCE IS A JUDGE.
-- Fort Wayne Code § 31.01 ends at City Clerk. Gary additionally elects a Judge of the City Court
-- (IC 36-4-9 permits a city court in a second-class city; Fort Wayne has none). The Lake County
-- certified 2023 municipal results carry a "Judge of the City Court" race, won unopposed by
-- Deidre L Monroe. Inheriting Fort Wayne's answer would have silently dropped an elected
-- judgeship -- the DESCRIBE-REAL-POWERS rule, caught by reading the ballot rather than the
-- neighbouring city.
--
-- 🔴🔴 THE SIX DISTRICT COUNCIL SEATS ARE DELIBERATELY NOT CREATED, AND THIS IS THE WHOLE
-- DESIGN DECISION OF THE WAVE.
--
-- Gary missed the statutory redistricting deadline of 2022-12-31, was sued in federal court
-- (total district deviation measured at about 24%), and under a settlement adopted a NEW MAP on
-- 2023-02-10 which governs from the 2023 primary onward. That map is not published in any
-- machine-readable form:
--
--   * github.com/cityofgary/administrative-boundaries -- the City's own repo, six districts,
--     EPSG 4326 GeoJSON, correctly named. ONE COMMIT, 2014-07-21; repo not pushed since
--     2014-08-13. It predates the 2020 census AND the settlement map. It is the trap: correct
--     format, correct projection, correct names, wrong map by nine years.
--   * The City's live GIS (GaryINsight, 15 items, updated 2026-09) has NO council-district layer.
--   * Lake County publishes Gary's six districts as PDF and JPG only, updated 2026-06-10.
--   * ArcGIS Online carries nothing for Lake County precincts or Gary districts.
--
-- Creating the six offices without geometry would make six offices NO ADDRESS CAN EVER REACH,
-- and nothing would error. That is exactly the defect this slice measured at 671 offices in the
-- 'indiana_discovery' cohort. So they are not created. The post-verify gate below ASSERTS their
-- absence, so a later wave that adds geometry has to add the offices deliberately.
--
-- ⚠ official_count on the Council stays 9, NOT 3. It records the body's real size. A 3 would
-- assert that Gary has a three-member council.
--
-- 🔴 THE THREE AT-LARGE SEATS ARE NOT NUMBERED, exactly as in Fort Wayne: all three are elected
-- in one citywide race. They share the identical voter-facing title and are told apart by an
-- INTERNAL ORDINAL in `description`, which is not a ballot designation.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '1827000' AND mtfcc = 'G4110') THEN
    RAISE EXCEPTION 'IN-4 pre-flight: TIGER place 1827000/G4110 (Gary) is missing; the citywide seats would be unreachable.';
  END IF;
END $$;

-- ─── 1. Government ───────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Gary, Indiana, US', 'City', 'IN', 'Gary', '1827000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'City of Gary, Indiana, US');

-- ─── 2. Four chambers ────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM essentials.governments g
JOIN (VALUES
  ('Gary Common Council',      9),
  ('Office of the Mayor',      1),
  ('Office of the City Clerk', 1),
  ('Gary City Court',          1)
) AS v(name, official_count) ON true
WHERE g.name = 'City of Gary, Indiana, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. One citywide district ────────────────────────────────────────────────

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT '1827000', 'Gary Citywide', 'LOCAL', 'in', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts WHERE geo_id = '1827000' AND district_type = 'LOCAL');

-- ─── 4. Six citywide offices ─────────────────────────────────────────────────

CREATE TEMP TABLE gary_offices(chamber_name text, title text, description text) ON COMMIT DROP;
INSERT INTO gary_offices(chamber_name, title, description) VALUES
  ('Office of the Mayor',      'Mayor',                    NULL),
  ('Office of the City Clerk', 'City Clerk',               NULL),
  ('Gary City Court',          'Judge of the City Court',  NULL),
  -- ⚠ INTERNAL ORDINAL ONLY. Indiana does not number its at-large council seats.
  ('Gary Common Council', 'Council Member, At Large',
   'Internal ordinal 1 of 3. Gary does not number its at-large seats; not a ballot designation.'),
  ('Gary Common Council', 'Council Member, At Large',
   'Internal ordinal 2 of 3. Gary does not number its at-large seats; not a ballot designation.'),
  ('Gary Common Council', 'Council Member, At Large',
   'Internal ordinal 3 of 3. Gary does not number its at-large seats; not a ballot designation.');

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'IN', 'Gary', 1, false, 'full'
FROM gary_offices n
JOIN essentials.districts d ON d.geo_id = '1827000' AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.governments g ON g.name = 'City of Gary, Indiana, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_gov int; v_ch int; v_off int; v_atlarge int; v_council_count int; v_districtseats int; v_nogeom int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'City of Gary, Indiana, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'IN-4 structure: % Gary government rows, expected 1', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
   JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = 'City of Gary, Indiana, US';
  IF v_ch <> 4 THEN RAISE EXCEPTION 'IN-4 structure: % chambers, expected 4 (the fourth is the City Court)', v_ch; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = 'City of Gary, Indiana, US';
  IF v_off <> 6 THEN RAISE EXCEPTION 'IN-4 structure: % offices, expected 6', v_off; END IF;

  SELECT count(*) INTO v_atlarge FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title = 'Council Member, At Large';
  IF v_atlarge <> 3 THEN RAISE EXCEPTION 'IN-4 structure: % at-large offices, expected 3', v_atlarge; END IF;

  -- The Council records its REAL size even though only the at-large seats exist yet.
  SELECT official_count INTO v_council_count FROM essentials.chambers c
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND c.name = 'Gary Common Council';
  IF v_council_count <> 9 THEN
    RAISE EXCEPTION 'IN-4 structure: Gary Common Council official_count is %, expected 9 -- it records the body size, not the seated count', v_council_count;
  END IF;

  -- 🔴 The six district seats MUST NOT exist yet. If a later wave adds geometry it must add these
  -- deliberately; this assertion is what makes that a decision rather than an accident.
  SELECT count(*) INTO v_districtseats FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%';
  IF v_districtseats <> 0 THEN
    RAISE EXCEPTION 'IN-4 structure: % Gary district council office(s) exist. They are deferred until the 2023 settlement map is obtained in machine-readable form -- see ROSTERS.md.', v_districtseats;
  END IF;

  -- Every Gary district that DOES exist must have geometry.
  SELECT count(*) INTO v_nogeom FROM essentials.districts d
   WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'in' AND d.geo_id = '1827000'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN RAISE EXCEPTION 'IN-4 structure: the Gary citywide district has no boundary'; END IF;

  RAISE NOTICE 'IN-4 structure OK: 1 government, 4 chambers, 1 citywide district, 6 offices (3 at-large); 6 district seats correctly absent';
END $$;

COMMIT;
