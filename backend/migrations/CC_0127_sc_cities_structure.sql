-- CC_0127_sc_cities_structure.sql
-- Knight Foundation program, wave SC-3 (structure half). Slot RESERVED from the allocator.
--
-- Seats nobody. Creates the two city governments, their four chambers, the six districts they
-- need and the 14 offices. CC_0128 puts people in them, and the two are applied back to back.
--
-- Production held NOTHING for either city before this wave: one South Carolina government row
-- (the state), no city government, no local district, no city office. Measured 2026-09-20.
--
-- 🔴 THE TWO JURISDICTIONS ARE NOT MADE UNIFORM, AND THE DIFFERENCE IS THE POINT:
--   Columbia — Mayor + SIX council members: 4 on single-member district polygons and 2 AT-LARGE,
--   unnumbered, on the citywide polygon. The council's own page: "City Council consists of the
--   Mayor, Council District members (4), and At-Large Council members (2)" — so the council of
--   SEVEN counts the mayor, and official_count carries the city's own number.
--   Myrtle Beach — Mayor + SIX council members, ALL AT LARGE. The Municipal Association of South
--   Carolina's directory states the method in one word, "At large". NO ward or district layer
--   exists and none is invented: Tallahassee, State College and Boulder again.
--
-- 🔴 COLUMBIA'S FOUR DISTRICT POLYGONS MUST ALREADY EXIST. scripts/load-columbia-council-boundaries.mjs
-- loads them as X0059; this migration ABORTS if they are absent, because an office on a district
-- with no polygon is unreachable by any address and NOTHING ERRORS.
--
-- 🔴 THE JOIN KEY IS (geo_id, mtfcc). '45079' is Richland County AND State House District 79 —
-- Richland is Columbia's county — and '45051' is Horry County AND House District 51. Nothing here
-- matches on a geo_id alone, and the gate asserts that no county or legislative district picked
-- up a city office.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the polygons every office in this wave hangs on ───────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = 'X0059' AND state = '45';
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'SC-3 structure: expected 4 X0059 council-district boundaries, found % — run scripts/load-columbia-council-boundaries.mjs first', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4110' AND state = '45' AND geo_id IN ('4516000','4549075');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'SC-3 structure: expected the Columbia and Myrtle Beach place polygons, found %', v_n;
  END IF;
END $$;

-- ─── 1. The two governments ───────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'City of Columbia, South Carolina, US', 'City', 'SC', '4516000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '4516000' AND state = 'SC');

INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'City of Myrtle Beach, South Carolina, US', 'City', 'SC', '4549075'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '4549075' AND state = 'SC');

-- ─── 2. The four chambers ─────────────────────────────────────────────────────
-- official_count is each city's OWN number, not a house convention: Columbia says seven
-- (counting the mayor), Myrtle Beach's charter seats a mayor and six councilmembers.
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Columbia City Council', 'Columbia City Council', 7
FROM essentials.governments g
WHERE g.geo_id = '4516000' AND g.state = 'SC'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.government_id = g.id AND ch.name = 'Columbia City Council');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Office of the Mayor', 'Office of the Mayor of Columbia', 1
FROM essentials.governments g
WHERE g.geo_id = '4516000' AND g.state = 'SC'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.government_id = g.id AND ch.name = 'Office of the Mayor');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Myrtle Beach City Council', 'Myrtle Beach City Council', 7
FROM essentials.governments g
WHERE g.geo_id = '4549075' AND g.state = 'SC'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.government_id = g.id AND ch.name = 'Myrtle Beach City Council');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, 'Office of the Mayor', 'Office of the Mayor of Myrtle Beach', 1
FROM essentials.governments g
WHERE g.geo_id = '4549075' AND g.state = 'SC'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch WHERE ch.government_id = g.id AND ch.name = 'Office of the Mayor');

-- ─── 3. The six districts ─────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, mtfcc, district_type, label, state, government_id)
SELECT v.geo_id, v.mtfcc, 'LOCAL', v.label, 'sc', gov.id
FROM (VALUES
  ('cola-council-district-1', 'X0059', 'Columbia City Council District 1', '4516000'),
  ('cola-council-district-2', 'X0059', 'Columbia City Council District 2', '4516000'),
  ('cola-council-district-3', 'X0059', 'Columbia City Council District 3', '4516000'),
  ('cola-council-district-4', 'X0059', 'Columbia City Council District 4', '4516000'),
  ('4516000', 'G4110', 'Columbia Citywide', '4516000'),
  ('4549075', 'G4110', 'Myrtle Beach Citywide', '4549075')
) AS v(geo_id, mtfcc, label, gov_geo_id)
JOIN essentials.governments gov ON gov.geo_id = v.gov_geo_id AND gov.state = 'SC'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.mtfcc = v.mtfcc);

-- ─── 4. The 14 offices ────────────────────────────────────────────────────────
-- ⚠ The at-large seats are UNNUMBERED: two Columbia offices and six Myrtle Beach offices share a
-- title on their own citywide polygon. The COUNT is what distinguishes them, not a seat number
-- the cities do not use — the Fort Wayne, Duluth and Philadelphia convention.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'SC', v.city, 1, false, 'full'
FROM (VALUES
  (0, 'Mayor', '4516000', 'G4110', 'Office of the Mayor', '4516000', 'Columbia'),
  (1, 'Council Member, District 1', 'cola-council-district-1', 'X0059', 'Columbia City Council', '4516000', 'Columbia'),
  (2, 'Council Member, District 2', 'cola-council-district-2', 'X0059', 'Columbia City Council', '4516000', 'Columbia'),
  (3, 'Council Member, District 3', 'cola-council-district-3', 'X0059', 'Columbia City Council', '4516000', 'Columbia'),
  (4, 'Council Member, District 4', 'cola-council-district-4', 'X0059', 'Columbia City Council', '4516000', 'Columbia'),
  (5, 'Council Member, At Large', '4516000', 'G4110', 'Columbia City Council', '4516000', 'Columbia'),
  (6, 'Council Member, At Large', '4516000', 'G4110', 'Columbia City Council', '4516000', 'Columbia'),
  (7, 'Mayor', '4549075', 'G4110', 'Office of the Mayor', '4549075', 'Myrtle Beach'),
  (8, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075', 'Myrtle Beach'),
  (9, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075', 'Myrtle Beach'),
  (10, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075', 'Myrtle Beach'),
  (11, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075', 'Myrtle Beach'),
  (12, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075', 'Myrtle Beach'),
  (13, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075', 'Myrtle Beach')
) AS v(ord, title, district_geo_id, district_mtfcc, chamber_name, gov_geo_id, city)
JOIN essentials.governments gov ON gov.geo_id = v.gov_geo_id AND gov.state = 'SC'
JOIN essentials.chambers c ON c.government_id = gov.id AND c.name = v.chamber_name
JOIN essentials.districts d ON d.geo_id = v.district_geo_id AND d.mtfcc = v.district_mtfcc AND lower(d.state) = 'sc'
WHERE (
  SELECT count(*) FROM essentials.offices o
   WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title
) < (
  -- how many offices this wave wants with exactly this (chamber, district, title)
  SELECT count(*) FROM (VALUES
    (0, 'Mayor', '4516000', 'G4110', 'Office of the Mayor', '4516000'),
    (1, 'Council Member, District 1', 'cola-council-district-1', 'X0059', 'Columbia City Council', '4516000'),
    (2, 'Council Member, District 2', 'cola-council-district-2', 'X0059', 'Columbia City Council', '4516000'),
    (3, 'Council Member, District 3', 'cola-council-district-3', 'X0059', 'Columbia City Council', '4516000'),
    (4, 'Council Member, District 4', 'cola-council-district-4', 'X0059', 'Columbia City Council', '4516000'),
    (5, 'Council Member, At Large', '4516000', 'G4110', 'Columbia City Council', '4516000'),
    (6, 'Council Member, At Large', '4516000', 'G4110', 'Columbia City Council', '4516000'),
    (7, 'Mayor', '4549075', 'G4110', 'Office of the Mayor', '4549075'),
    (8, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075'),
    (9, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075'),
    (10, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075'),
    (11, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075'),
    (12, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075'),
    (13, 'Council Member, At Large', '4549075', 'G4110', 'Myrtle Beach City Council', '4549075')
  ) AS w(ord, title, district_geo_id, district_mtfcc, chamber_name, gov_geo_id)
  WHERE w.title = v.title AND w.district_geo_id = v.district_geo_id
    AND w.district_mtfcc = v.district_mtfcc AND w.chamber_name = v.chamber_name
    AND w.gov_geo_id = v.gov_geo_id
);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov      int;
  v_ch       int;
  v_d        int;
  v_col      int;
  v_mb       int;
  v_leak     int;
  v_nodist   int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE state = 'SC' AND geo_id IN ('4516000','4549075') AND type = 'City';
  IF v_gov <> 2 THEN RAISE EXCEPTION 'SC-3 structure: expected 2 city governments, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers ch
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075');
  IF v_ch <> 4 THEN RAISE EXCEPTION 'SC-3 structure: expected 4 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_d FROM essentials.districts
   WHERE lower(state) = 'sc' AND (mtfcc = 'X0059' OR (mtfcc = 'G4110' AND geo_id IN ('4516000','4549075')));
  IF v_d <> 6 THEN RAISE EXCEPTION 'SC-3 structure: expected 6 districts, got %', v_d; END IF;

  SELECT count(*) INTO v_col FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4516000' AND g.state = 'SC';
  SELECT count(*) INTO v_mb FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4549075' AND g.state = 'SC';
  IF v_col <> 7 OR v_mb <> 7 THEN
    RAISE EXCEPTION 'SC-3 structure: expected 7 Columbia and 7 Myrtle Beach offices, got % and %', v_col, v_mb;
  END IF;

  -- Every Columbia district polygon carries exactly one district office; the citywide polygons
  -- carry the mayor plus the at-large seats.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
     LEFT JOIN essentials.offices o ON o.district_id = d.id
     WHERE d.mtfcc = 'X0059' AND lower(d.state) = 'sc'
     GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'SC-3 structure: a Columbia council district does not carry exactly one office';
  END IF;

  -- 🔴 THE COLLISION GATE. Nothing in this wave may have landed on a county or a legislative
  -- district: '45079' is Richland County AND House District 79.
  SELECT count(*) INTO v_leak FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'sc'
     AND d.district_type::text IN ('COUNTY','STATE_LOWER','STATE_UPPER')
     AND o.title LIKE 'Council Member%';
  IF v_leak <> 0 THEN
    RAISE EXCEPTION 'SC-3 structure: % county/legislative district(s) picked up a city office — a geo_id-only join', v_leak;
  END IF;

  -- No city office may hang on a district with no polygon.
  SELECT count(*) INTO v_nodist FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.state = 'SC' AND g.geo_id IN ('4516000','4549075')
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc AND b.state = '45');
  IF v_nodist <> 0 THEN
    RAISE EXCEPTION 'SC-3 structure: % city office(s) sit on a district with no polygon — unreachable by address', v_nodist;
  END IF;

  RAISE NOTICE 'SC-3 structure OK: 2 governments, 4 chambers, 6 districts, 7 + 7 offices, 0 on a county';
END $$;

COMMIT;
