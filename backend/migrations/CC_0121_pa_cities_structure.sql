-- CC_0121_pa_cities_structure.sql
-- Knight Foundation program, wave PA-3 (structure half). Slot RESERVED from the allocator.
--
-- Seats nobody. Creates the two city governments, their four chambers, the twelve districts they
-- need and the 26 offices. CC_0122 puts people in them, and the two are applied back to back.
--
-- 🔴 THE TWO JURISDICTIONS ARE NOT MADE UNIFORM, AND THE DIFFERENCE IS THE POINT:
--   Philadelphia — Mayor + a Council of SEVENTEEN: 10 district seats on the ten council-district
--   polygons, and 7 AT-LARGE seats which are UNNUMBERED and sit on the citywide polygon (the
--   Fort Wayne and Duluth convention).
--   State College — Mayor + SEVEN council members, "elected at large" in the words of the Home
--   Rule Charter quoted on the borough's own page. NO ward layer exists and none is invented:
--   all eight offices sit on the borough's citywide polygon. Tallahassee and Boulder again.
--
-- 🔴 PHILADELPHIA'S ROW OFFICERS ARE NOT HERE. District Attorney, City Controller, Sheriff,
-- Register of Wills and the three City Commissioners are the county officers a consolidated
-- city keeps, and they belong to stage 4 (spec §3.2). Its elected JUDGES belong to the judges
-- wave, as North Carolina's do.
--
-- 🔴 THE TEN DISTRICT POLYGONS MUST ALREADY EXIST. scripts/load-phl-council-boundaries.mjs loads
-- them as X0058; this migration ABORTS if they are absent, because an office on a district with
-- no polygon is unreachable by any address and NOTHING ERRORS.
--
-- 🔴 WHICH ten polygons was proved, not read off a service name. The city publishes FIVE
-- council-district layers and all five have ten features numbered 1-10. A city-wide spread of
-- addresses cannot separate them — all 54 Free Library branches agree with the superseded 2016
-- map as well. Only the ~4% of addresses the 2022 remap moved can: on those the loaded layer
-- matches the City's own address service 6/6 and the 2016 layer 0/6.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the council-district polygons ─────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = 'X0058' AND state = '42';
  IF v_n <> 10 THEN
    RAISE EXCEPTION 'PA-3 structure: expected 10 X0058 council-district boundaries, found % — run scripts/load-phl-council-boundaries.mjs first', v_n;
  END IF;
  -- The two TIGER place polygons carry every citywide office in this wave.
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4110' AND state = '42' AND geo_id IN ('4260000','4273808');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'PA-3 structure: expected the Philadelphia and State College place polygons, found %', v_n;
  END IF;
END $$;

-- ─── 1. The two governments ───────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'City of Philadelphia, Pennsylvania, US', 'City', 'PA', '4260000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '4260000' AND state = 'PA');

INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'Borough of State College, Pennsylvania, US', 'City', 'PA', '4273808'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '4273808' AND state = 'PA');

-- ─── 2. The four chambers ─────────────────────────────────────────────────────
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT gov.id, 'Philadelphia City Council', 'Philadelphia City Council', 17
FROM essentials.governments gov
WHERE gov.geo_id = '4260000' AND gov.state = 'PA'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = gov.id AND c.name = 'Philadelphia City Council');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT gov.id, 'Office of the Mayor', 'Office of the Mayor', 1
FROM essentials.governments gov
WHERE gov.geo_id = '4260000' AND gov.state = 'PA'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = gov.id AND c.name = 'Office of the Mayor');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT gov.id, 'State College Borough Council', 'State College Borough Council', 7
FROM essentials.governments gov
WHERE gov.geo_id = '4273808' AND gov.state = 'PA'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = gov.id AND c.name = 'State College Borough Council');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT gov.id, 'Office of the Mayor', 'Office of the Mayor', 1
FROM essentials.governments gov
WHERE gov.geo_id = '4273808' AND gov.state = 'PA'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = gov.id AND c.name = 'Office of the Mayor');

-- ─── 3. The twelve districts ──────────────────────────────────────────────────
-- Ten council districts on the loaded polygons, plus one citywide district per jurisdiction.
-- 🔴 (geo_id, mtfcc) IS THE KEY. '42101' is Philadelphia County AND State House District 101,
-- and all 67 PA counties collide with a House district this way. Nothing here matches on a
-- number, a name or a geo_id alone.
INSERT INTO essentials.districts (geo_id, mtfcc, district_type, label, state, government_id)
SELECT v.geo_id, v.mtfcc, 'LOCAL', v.label, 'pa', gov.id
FROM (VALUES
  ('phl-council-district-1', 'X0058', 'Philadelphia City Council District 1', '4260000'),
  ('phl-council-district-2', 'X0058', 'Philadelphia City Council District 2', '4260000'),
  ('phl-council-district-3', 'X0058', 'Philadelphia City Council District 3', '4260000'),
  ('phl-council-district-4', 'X0058', 'Philadelphia City Council District 4', '4260000'),
  ('phl-council-district-5', 'X0058', 'Philadelphia City Council District 5', '4260000'),
  ('phl-council-district-6', 'X0058', 'Philadelphia City Council District 6', '4260000'),
  ('phl-council-district-7', 'X0058', 'Philadelphia City Council District 7', '4260000'),
  ('phl-council-district-8', 'X0058', 'Philadelphia City Council District 8', '4260000'),
  ('phl-council-district-9', 'X0058', 'Philadelphia City Council District 9', '4260000'),
  ('phl-council-district-10', 'X0058', 'Philadelphia City Council District 10', '4260000'),
  ('4260000', 'G4110', 'Philadelphia Citywide', '4260000'),
  ('4273808', 'G4110', 'State College Borough Citywide', '4273808')
) AS v(geo_id, mtfcc, label, gov_geo_id)
JOIN essentials.governments gov ON gov.geo_id = v.gov_geo_id AND gov.state = 'PA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.mtfcc = v.mtfcc);

-- ─── 4. The 26 offices ────────────────────────────────────────────────────────
-- ⚠ The at-large seats are UNNUMBERED: seven Philadelphia offices share the title
-- 'Councilmember, At Large' and seven State College offices share 'Council Member, At Large',
-- all on their own citywide district. The count is what distinguishes them, not a seat number
-- the city does not use.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'PA', 1, false, 'full'
FROM (VALUES
  (0, 'Mayor', '4260000', 'G4110', 'Office of the Mayor', '4260000'),
  (1, 'Councilmember, District 1', 'phl-council-district-1', 'X0058', 'Philadelphia City Council', '4260000'),
  (2, 'Councilmember, District 2', 'phl-council-district-2', 'X0058', 'Philadelphia City Council', '4260000'),
  (3, 'Councilmember, District 3', 'phl-council-district-3', 'X0058', 'Philadelphia City Council', '4260000'),
  (4, 'Councilmember, District 4', 'phl-council-district-4', 'X0058', 'Philadelphia City Council', '4260000'),
  (5, 'Councilmember, District 5', 'phl-council-district-5', 'X0058', 'Philadelphia City Council', '4260000'),
  (6, 'Councilmember, District 6', 'phl-council-district-6', 'X0058', 'Philadelphia City Council', '4260000'),
  (7, 'Councilmember, District 7', 'phl-council-district-7', 'X0058', 'Philadelphia City Council', '4260000'),
  (8, 'Councilmember, District 8', 'phl-council-district-8', 'X0058', 'Philadelphia City Council', '4260000'),
  (9, 'Councilmember, District 9', 'phl-council-district-9', 'X0058', 'Philadelphia City Council', '4260000'),
  (10, 'Councilmember, District 10', 'phl-council-district-10', 'X0058', 'Philadelphia City Council', '4260000'),
  (11, 'Councilmember, At Large', '4260000', 'G4110', 'Philadelphia City Council', '4260000'),
  (12, 'Councilmember, At Large', '4260000', 'G4110', 'Philadelphia City Council', '4260000'),
  (13, 'Councilmember, At Large', '4260000', 'G4110', 'Philadelphia City Council', '4260000'),
  (14, 'Councilmember, At Large', '4260000', 'G4110', 'Philadelphia City Council', '4260000'),
  (15, 'Councilmember, At Large', '4260000', 'G4110', 'Philadelphia City Council', '4260000'),
  (16, 'Councilmember, At Large', '4260000', 'G4110', 'Philadelphia City Council', '4260000'),
  (17, 'Councilmember, At Large', '4260000', 'G4110', 'Philadelphia City Council', '4260000'),
  (18, 'Mayor', '4273808', 'G4110', 'Office of the Mayor', '4273808'),
  (19, 'Council Member, At Large', '4273808', 'G4110', 'State College Borough Council', '4273808'),
  (20, 'Council Member, At Large', '4273808', 'G4110', 'State College Borough Council', '4273808'),
  (21, 'Council Member, At Large', '4273808', 'G4110', 'State College Borough Council', '4273808'),
  (22, 'Council Member, At Large', '4273808', 'G4110', 'State College Borough Council', '4273808'),
  (23, 'Council Member, At Large', '4273808', 'G4110', 'State College Borough Council', '4273808'),
  (24, 'Council Member, At Large', '4273808', 'G4110', 'State College Borough Council', '4273808'),
  (25, 'Council Member, At Large', '4273808', 'G4110', 'State College Borough Council', '4273808')
) AS v(ord, title, district_geo_id, district_mtfcc, chamber_name, gov_geo_id)
JOIN essentials.governments gov ON gov.geo_id = v.gov_geo_id AND gov.state = 'PA'
JOIN essentials.chambers c ON c.government_id = gov.id AND c.name = v.chamber_name
JOIN essentials.districts d ON d.geo_id = v.district_geo_id AND d.mtfcc = v.district_mtfcc AND lower(d.state) = 'pa'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title
  GROUP BY o.chamber_id, o.district_id, o.title
  HAVING count(*) >= (SELECT count(*) FROM (VALUES
    (0, 'Mayor', '4260000'),
    (1, 'Councilmember, District 1', 'phl-council-district-1'),
    (2, 'Councilmember, District 2', 'phl-council-district-2'),
    (3, 'Councilmember, District 3', 'phl-council-district-3'),
    (4, 'Councilmember, District 4', 'phl-council-district-4'),
    (5, 'Councilmember, District 5', 'phl-council-district-5'),
    (6, 'Councilmember, District 6', 'phl-council-district-6'),
    (7, 'Councilmember, District 7', 'phl-council-district-7'),
    (8, 'Councilmember, District 8', 'phl-council-district-8'),
    (9, 'Councilmember, District 9', 'phl-council-district-9'),
    (10, 'Councilmember, District 10', 'phl-council-district-10'),
    (11, 'Councilmember, At Large', '4260000'),
    (12, 'Councilmember, At Large', '4260000'),
    (13, 'Councilmember, At Large', '4260000'),
    (14, 'Councilmember, At Large', '4260000'),
    (15, 'Councilmember, At Large', '4260000'),
    (16, 'Councilmember, At Large', '4260000'),
    (17, 'Councilmember, At Large', '4260000'),
    (18, 'Mayor', '4273808'),
    (19, 'Council Member, At Large', '4273808'),
    (20, 'Council Member, At Large', '4273808'),
    (21, 'Council Member, At Large', '4273808'),
    (22, 'Council Member, At Large', '4273808'),
    (23, 'Council Member, At Large', '4273808'),
    (24, 'Council Member, At Large', '4273808'),
    (25, 'Council Member, At Large', '4273808')
  ) AS w(ord, title, district_geo_id) WHERE w.title = v.title AND w.district_geo_id = v.district_geo_id));

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off int; v_phl int; v_sc int; v_al int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE state = 'PA' AND geo_id IN ('4260000','4273808');
  IF v_gov <> 2 THEN RAISE EXCEPTION 'PA-3 structure: expected 2 city governments, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808');
  IF v_ch <> 4 THEN RAISE EXCEPTION 'PA-3 structure: expected 4 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE lower(state) = 'pa' AND (mtfcc = 'X0058' OR (mtfcc = 'G4110' AND geo_id IN ('4260000','4273808')));
  IF v_dist <> 12 THEN RAISE EXCEPTION 'PA-3 structure: expected 12 districts, got %', v_dist; END IF;

  SELECT count(*) INTO v_phl FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '4260000' AND g.state = 'PA';
  SELECT count(*) INTO v_sc FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '4273808' AND g.state = 'PA';
  IF v_phl <> 18 THEN RAISE EXCEPTION 'PA-3 structure: expected 18 Philadelphia offices (Mayor + 17), got %', v_phl; END IF;
  IF v_sc <> 8 THEN RAISE EXCEPTION 'PA-3 structure: expected 8 State College offices (Mayor + 7), got %', v_sc; END IF;
  v_off := v_phl + v_sc;

  -- 🔴 EXACTLY SEVEN at-large seats in Philadelphia and SEVEN in State College. An unnumbered
  -- seat is the one shape where a re-run can quietly add an extra office, so it is counted.
  SELECT count(*) INTO v_al FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '4260000' AND o.title = 'Councilmember, At Large';
  IF v_al <> 7 THEN RAISE EXCEPTION 'PA-3 structure: expected 7 Philadelphia at-large offices, got %', v_al; END IF;
  SELECT count(*) INTO v_al FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '4273808' AND o.title = 'Council Member, At Large';
  IF v_al <> 7 THEN RAISE EXCEPTION 'PA-3 structure: expected 7 State College at-large offices, got %', v_al; END IF;

  -- 🔴 NO OFFICE ON A DISTRICT WITH NO POLYGON. That is the one failure CI cannot catch: the
  -- office exists, the official is invisible to every address, and nothing errors.
  SELECT count(*) INTO v_orphan FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   JOIN essentials.districts d ON d.id = o.district_id
   LEFT JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808') AND b.id IS NULL;
  IF v_orphan <> 0 THEN
    RAISE EXCEPTION 'PA-3 structure: % office(s) sit on a district with no polygon — unreachable by any address', v_orphan;
  END IF;

  RAISE NOTICE 'PA-3 structure OK: 2 governments, 4 chambers, 12 districts, % offices (PHL 18 + SC 8)', v_off;
END $$;

COMMIT;
