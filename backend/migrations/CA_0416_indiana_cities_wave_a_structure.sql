-- CA_0416_indiana_cities_wave_a_structure.sql
-- Indiana cities Wave A, structure half. Slot RESERVED from the allocator.
-- Scope note: .planning/todos/2026-11-24-indiana-cities-2027-scope.md
--
-- Creates 13 city governments, 39 chambers, 89 districts and 139 offices.
-- Creates NO people and NO terms -- the people migration does that.
--
-- Structure per city, from IC 36-4-6-3 / 36-4-6-4 / 36-4-10-2 and confirmed on each city's own site
-- (data/seed-in-cities-wave-a/cities/<slug>.json, checked by verify-collect.mjs):
--   Evansville       6 district + 3 at-large · City Clerk      · https://www.evansvillegov.org/city/topic/index.php?topicid=749&structureid=16
--   South Bend       6 district + 3 at-large · City Clerk      · https://southbendin.gov/official/
--   Carmel           6 district + 3 at-large · City Clerk      · https://web.archive.org/web/20261019082710/https://www.carmel.in.gov/government/city-council
--   Lafayette        6 district + 3 at-large · City Clerk      · https://web.archive.org/web/20261019082636/https://www.lafayette.in.gov/646/City-Council
--   Muncie           6 district + 3 at-large · City Clerk      · https://www.muncie.in.gov/council
--   Westfield        5 district + 2 at-large · Clerk-Treasurer · https://maps.westfield.in.gov/arcgis/rest/services/Reference/CityCouncil/MapServer/0
--   Terre Haute      6 district + 3 at-large · City Clerk      · https://www.terrehaute.in.gov/government/city_council/index.php
--   Elkhart          6 district + 3 at-large · City Clerk      · https://www.cityofelkhartin.gov/city-council/
--   Jeffersonville   6 district + 3 at-large · City Clerk      · https://cityofjeff.net/city-council/
--   Mishawaka        6 district + 3 at-large · City Clerk      · https://mishawaka.in.gov/government/city-directory
--   Lawrence         6 district + 3 at-large · City Clerk      · https://cityoflawrence.org/node/163?year=2023
--   New Albany       6 district + 3 at-large · City Clerk      · https://cityofnewalbany.com/city-council/
--   Goshen           5 district + 2 at-large · Clerk-Treasurer · https://goshen.in.gov/?p=5557
--
-- 🔴 THE AT-LARGE SEATS ARE NOT NUMBERED. Indiana elects them in one citywide race (top N win), so every
-- at-large office carries the identical title 'Council Member, At Large'. The ordinal in description is
-- INTERNAL, exists only so the people migration can attach a person deterministically, and is labelled so.
-- (CC_0090 header, the DESCRIBE-REAL-POWERS rule.)
--
-- 🔴 GEOMETRY COMES FROM scripts/load-indiana-city-council-boundaries.ts (X0091), NOT from here. The
-- pre-flight FAILS HARD unless every city has exactly its district count of X0091 boundaries and its TIGER
-- place polygon -- an office on a district with no polygon is unreachable by address and nothing errors.
--
-- ⚠ City court judges are NOT modelled in this wave (scope decision pending).
-- ⚠ districts.state is lowercase 'in' on LOCAL districts (CC_0090). Always lower(d.state).
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate per city.

BEGIN;

CREATE TEMP TABLE w_city(gov text, slug text, geoid text, n_dist int, n_al int, council text) ON COMMIT DROP;
INSERT INTO w_city VALUES
  ('City of Evansville, Indiana, US', 'evansville-in', '1822000', 6, 3, 'Evansville City Council'),
  ('City of South Bend, Indiana, US', 'south-bend-in', '1871000', 6, 3, 'South Bend Common Council'),
  ('City of Carmel, Indiana, US', 'carmel-in', '1810342', 6, 3, 'Carmel City Council'),
  ('City of Lafayette, Indiana, US', 'lafayette-in', '1840788', 6, 3, 'Lafayette Common Council'),
  ('City of Muncie, Indiana, US', 'muncie-in', '1851876', 6, 3, 'Muncie City Council'),
  ('City of Westfield, Indiana, US', 'westfield-in', '1882700', 5, 2, 'Westfield City Council'),
  ('City of Terre Haute, Indiana, US', 'terre-haute-in', '1875428', 6, 3, 'Terre Haute City Council'),
  ('City of Elkhart, Indiana, US', 'elkhart-in', '1820728', 6, 3, 'Elkhart Common Council'),
  ('City of Jeffersonville, Indiana, US', 'jeffersonville-in', '1838358', 6, 3, 'Jeffersonville City Council'),
  ('City of Mishawaka, Indiana, US', 'mishawaka-in', '1849932', 6, 3, 'Mishawaka Common Council'),
  ('City of Lawrence, Indiana, US', 'lawrence-in', '1842426', 6, 3, 'Lawrence Common Council'),
  ('City of New Albany, Indiana, US', 'new-albany-in', '1852326', 6, 3, 'New Albany City Council'),
  ('City of Goshen, Indiana, US', 'goshen-in', '1828386', 5, 2, 'Goshen Common Council');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE r record; v_b int;
BEGIN
  FOR r IN SELECT * FROM w_city LOOP
    SELECT count(*) INTO v_b FROM essentials.geofence_boundaries
     WHERE mtfcc = 'X0091' AND geo_id LIKE r.slug || '-council-district-%';
    IF v_b <> r.n_dist THEN
      RAISE EXCEPTION 'pre-flight: X0091 holds % council boundaries for %, expected %. Run scripts/load-indiana-city-council-boundaries.ts first.', v_b, r.slug, r.n_dist;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = r.geoid AND mtfcc = 'G4110') THEN
      RAISE EXCEPTION 'pre-flight: TIGER place %/G4110 (%) is missing', r.geoid, r.slug;
    END IF;
    -- A government already on this place under ANOTHER name would be duplicated silently by the name guard.
    IF EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id = r.geoid AND g.name <> r.gov) THEN
      RAISE EXCEPTION 'pre-flight: place % already has a government under a different name', r.geoid;
    END IF;
  END LOOP;
END $$;

-- ─── 1. Governments ──────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT v.name, 'City', 'IN', v.city, v.geo_id, 'G4110'
FROM (VALUES
  ('City of Evansville, Indiana, US', 'Evansville', '1822000'),
  ('City of South Bend, Indiana, US', 'South Bend', '1871000'),
  ('City of Carmel, Indiana, US', 'Carmel', '1810342'),
  ('City of Lafayette, Indiana, US', 'Lafayette', '1840788'),
  ('City of Muncie, Indiana, US', 'Muncie', '1851876'),
  ('City of Westfield, Indiana, US', 'Westfield', '1882700'),
  ('City of Terre Haute, Indiana, US', 'Terre Haute', '1875428'),
  ('City of Elkhart, Indiana, US', 'Elkhart', '1820728'),
  ('City of Jeffersonville, Indiana, US', 'Jeffersonville', '1838358'),
  ('City of Mishawaka, Indiana, US', 'Mishawaka', '1849932'),
  ('City of Lawrence, Indiana, US', 'Lawrence', '1842426'),
  ('City of New Albany, Indiana, US', 'New Albany', '1852326'),
  ('City of Goshen, Indiana, US', 'Goshen', '1828386')
) AS v(name, city, geo_id)
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.name = v.name);

-- ─── 2. Chambers ─────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM (VALUES
  ('City of Evansville, Indiana, US', 'Evansville City Council', 9),
  ('City of Evansville, Indiana, US', 'Office of the Mayor', 1),
  ('City of Evansville, Indiana, US', 'Office of the City Clerk', 1),
  ('City of South Bend, Indiana, US', 'South Bend Common Council', 9),
  ('City of South Bend, Indiana, US', 'Office of the Mayor', 1),
  ('City of South Bend, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Carmel, Indiana, US', 'Carmel City Council', 9),
  ('City of Carmel, Indiana, US', 'Office of the Mayor', 1),
  ('City of Carmel, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Lafayette, Indiana, US', 'Lafayette Common Council', 9),
  ('City of Lafayette, Indiana, US', 'Office of the Mayor', 1),
  ('City of Lafayette, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Muncie, Indiana, US', 'Muncie City Council', 9),
  ('City of Muncie, Indiana, US', 'Office of the Mayor', 1),
  ('City of Muncie, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Westfield, Indiana, US', 'Westfield City Council', 7),
  ('City of Westfield, Indiana, US', 'Office of the Mayor', 1),
  ('City of Westfield, Indiana, US', 'Office of the Clerk-Treasurer', 1),
  ('City of Terre Haute, Indiana, US', 'Terre Haute City Council', 9),
  ('City of Terre Haute, Indiana, US', 'Office of the Mayor', 1),
  ('City of Terre Haute, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Elkhart, Indiana, US', 'Elkhart Common Council', 9),
  ('City of Elkhart, Indiana, US', 'Office of the Mayor', 1),
  ('City of Elkhart, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Jeffersonville, Indiana, US', 'Jeffersonville City Council', 9),
  ('City of Jeffersonville, Indiana, US', 'Office of the Mayor', 1),
  ('City of Jeffersonville, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Mishawaka, Indiana, US', 'Mishawaka Common Council', 9),
  ('City of Mishawaka, Indiana, US', 'Office of the Mayor', 1),
  ('City of Mishawaka, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Lawrence, Indiana, US', 'Lawrence Common Council', 9),
  ('City of Lawrence, Indiana, US', 'Office of the Mayor', 1),
  ('City of Lawrence, Indiana, US', 'Office of the City Clerk', 1),
  ('City of New Albany, Indiana, US', 'New Albany City Council', 9),
  ('City of New Albany, Indiana, US', 'Office of the Mayor', 1),
  ('City of New Albany, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Goshen, Indiana, US', 'Goshen Common Council', 7),
  ('City of Goshen, Indiana, US', 'Office of the Mayor', 1),
  ('City of Goshen, Indiana, US', 'Office of the Clerk-Treasurer', 1)
) AS v(gov, name, official_count)
JOIN essentials.governments g ON g.name = v.gov
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Districts ────────────────────────────────────────────────────────────
-- Council districts on X0091; one citywide row per city on its TIGER place polygon, which carries the
-- Mayor, the clerk and the at-large seats.

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT v.geo_id, v.label, 'LOCAL', 'in', v.mtfcc
FROM (VALUES
  ('evansville-in-council-district-1', 'Evansville City Council District 1', 'X0091'),
  ('evansville-in-council-district-2', 'Evansville City Council District 2', 'X0091'),
  ('evansville-in-council-district-3', 'Evansville City Council District 3', 'X0091'),
  ('evansville-in-council-district-4', 'Evansville City Council District 4', 'X0091'),
  ('evansville-in-council-district-5', 'Evansville City Council District 5', 'X0091'),
  ('evansville-in-council-district-6', 'Evansville City Council District 6', 'X0091'),
  ('1822000', 'Evansville Citywide', 'G4110'),
  ('south-bend-in-council-district-1', 'South Bend City Council District 1', 'X0091'),
  ('south-bend-in-council-district-2', 'South Bend City Council District 2', 'X0091'),
  ('south-bend-in-council-district-3', 'South Bend City Council District 3', 'X0091'),
  ('south-bend-in-council-district-4', 'South Bend City Council District 4', 'X0091'),
  ('south-bend-in-council-district-5', 'South Bend City Council District 5', 'X0091'),
  ('south-bend-in-council-district-6', 'South Bend City Council District 6', 'X0091'),
  ('1871000', 'South Bend Citywide', 'G4110'),
  ('carmel-in-council-district-1', 'Carmel City Council District 1', 'X0091'),
  ('carmel-in-council-district-2', 'Carmel City Council District 2', 'X0091'),
  ('carmel-in-council-district-3', 'Carmel City Council District 3', 'X0091'),
  ('carmel-in-council-district-4', 'Carmel City Council District 4', 'X0091'),
  ('carmel-in-council-district-5', 'Carmel City Council District 5', 'X0091'),
  ('carmel-in-council-district-6', 'Carmel City Council District 6', 'X0091'),
  ('1810342', 'Carmel Citywide', 'G4110'),
  ('lafayette-in-council-district-1', 'Lafayette City Council District 1', 'X0091'),
  ('lafayette-in-council-district-2', 'Lafayette City Council District 2', 'X0091'),
  ('lafayette-in-council-district-3', 'Lafayette City Council District 3', 'X0091'),
  ('lafayette-in-council-district-4', 'Lafayette City Council District 4', 'X0091'),
  ('lafayette-in-council-district-5', 'Lafayette City Council District 5', 'X0091'),
  ('lafayette-in-council-district-6', 'Lafayette City Council District 6', 'X0091'),
  ('1840788', 'Lafayette Citywide', 'G4110'),
  ('muncie-in-council-district-1', 'Muncie City Council District 1', 'X0091'),
  ('muncie-in-council-district-2', 'Muncie City Council District 2', 'X0091'),
  ('muncie-in-council-district-3', 'Muncie City Council District 3', 'X0091'),
  ('muncie-in-council-district-4', 'Muncie City Council District 4', 'X0091'),
  ('muncie-in-council-district-5', 'Muncie City Council District 5', 'X0091'),
  ('muncie-in-council-district-6', 'Muncie City Council District 6', 'X0091'),
  ('1851876', 'Muncie Citywide', 'G4110'),
  ('westfield-in-council-district-1', 'Westfield City Council District 1', 'X0091'),
  ('westfield-in-council-district-2', 'Westfield City Council District 2', 'X0091'),
  ('westfield-in-council-district-3', 'Westfield City Council District 3', 'X0091'),
  ('westfield-in-council-district-4', 'Westfield City Council District 4', 'X0091'),
  ('westfield-in-council-district-5', 'Westfield City Council District 5', 'X0091'),
  ('1882700', 'Westfield Citywide', 'G4110'),
  ('terre-haute-in-council-district-1', 'Terre Haute City Council District 1', 'X0091'),
  ('terre-haute-in-council-district-2', 'Terre Haute City Council District 2', 'X0091'),
  ('terre-haute-in-council-district-3', 'Terre Haute City Council District 3', 'X0091'),
  ('terre-haute-in-council-district-4', 'Terre Haute City Council District 4', 'X0091'),
  ('terre-haute-in-council-district-5', 'Terre Haute City Council District 5', 'X0091'),
  ('terre-haute-in-council-district-6', 'Terre Haute City Council District 6', 'X0091'),
  ('1875428', 'Terre Haute Citywide', 'G4110'),
  ('elkhart-in-council-district-1', 'Elkhart City Council District 1', 'X0091'),
  ('elkhart-in-council-district-2', 'Elkhart City Council District 2', 'X0091'),
  ('elkhart-in-council-district-3', 'Elkhart City Council District 3', 'X0091'),
  ('elkhart-in-council-district-4', 'Elkhart City Council District 4', 'X0091'),
  ('elkhart-in-council-district-5', 'Elkhart City Council District 5', 'X0091'),
  ('elkhart-in-council-district-6', 'Elkhart City Council District 6', 'X0091'),
  ('1820728', 'Elkhart Citywide', 'G4110'),
  ('jeffersonville-in-council-district-1', 'Jeffersonville City Council District 1', 'X0091'),
  ('jeffersonville-in-council-district-2', 'Jeffersonville City Council District 2', 'X0091'),
  ('jeffersonville-in-council-district-3', 'Jeffersonville City Council District 3', 'X0091'),
  ('jeffersonville-in-council-district-4', 'Jeffersonville City Council District 4', 'X0091'),
  ('jeffersonville-in-council-district-5', 'Jeffersonville City Council District 5', 'X0091'),
  ('jeffersonville-in-council-district-6', 'Jeffersonville City Council District 6', 'X0091'),
  ('1838358', 'Jeffersonville Citywide', 'G4110'),
  ('mishawaka-in-council-district-1', 'Mishawaka City Council District 1', 'X0091'),
  ('mishawaka-in-council-district-2', 'Mishawaka City Council District 2', 'X0091'),
  ('mishawaka-in-council-district-3', 'Mishawaka City Council District 3', 'X0091'),
  ('mishawaka-in-council-district-4', 'Mishawaka City Council District 4', 'X0091'),
  ('mishawaka-in-council-district-5', 'Mishawaka City Council District 5', 'X0091'),
  ('mishawaka-in-council-district-6', 'Mishawaka City Council District 6', 'X0091'),
  ('1849932', 'Mishawaka Citywide', 'G4110'),
  ('lawrence-in-council-district-1', 'Lawrence City Council District 1', 'X0091'),
  ('lawrence-in-council-district-2', 'Lawrence City Council District 2', 'X0091'),
  ('lawrence-in-council-district-3', 'Lawrence City Council District 3', 'X0091'),
  ('lawrence-in-council-district-4', 'Lawrence City Council District 4', 'X0091'),
  ('lawrence-in-council-district-5', 'Lawrence City Council District 5', 'X0091'),
  ('lawrence-in-council-district-6', 'Lawrence City Council District 6', 'X0091'),
  ('1842426', 'Lawrence Citywide', 'G4110'),
  ('new-albany-in-council-district-1', 'New Albany City Council District 1', 'X0091'),
  ('new-albany-in-council-district-2', 'New Albany City Council District 2', 'X0091'),
  ('new-albany-in-council-district-3', 'New Albany City Council District 3', 'X0091'),
  ('new-albany-in-council-district-4', 'New Albany City Council District 4', 'X0091'),
  ('new-albany-in-council-district-5', 'New Albany City Council District 5', 'X0091'),
  ('new-albany-in-council-district-6', 'New Albany City Council District 6', 'X0091'),
  ('1852326', 'New Albany Citywide', 'G4110'),
  ('goshen-in-council-district-1', 'Goshen City Council District 1', 'X0091'),
  ('goshen-in-council-district-2', 'Goshen City Council District 2', 'X0091'),
  ('goshen-in-council-district-3', 'Goshen City Council District 3', 'X0091'),
  ('goshen-in-council-district-4', 'Goshen City Council District 4', 'X0091'),
  ('goshen-in-council-district-5', 'Goshen City Council District 5', 'X0091'),
  ('1828386', 'Goshen Citywide', 'G4110')
) AS v(geo_id, label, mtfcc)
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Offices ──────────────────────────────────────────────────────────────

CREATE TEMP TABLE w_off(gov text, geo_id text, chamber text, title text, description text) ON COMMIT DROP;
INSERT INTO w_off VALUES
  ('City of Evansville, Indiana, US', 'evansville-in-council-district-1', 'Evansville City Council', 'Council Member, District 1', NULL),
  ('City of Evansville, Indiana, US', 'evansville-in-council-district-2', 'Evansville City Council', 'Council Member, District 2', NULL),
  ('City of Evansville, Indiana, US', 'evansville-in-council-district-3', 'Evansville City Council', 'Council Member, District 3', NULL),
  ('City of Evansville, Indiana, US', 'evansville-in-council-district-4', 'Evansville City Council', 'Council Member, District 4', NULL),
  ('City of Evansville, Indiana, US', 'evansville-in-council-district-5', 'Evansville City Council', 'Council Member, District 5', NULL),
  ('City of Evansville, Indiana, US', 'evansville-in-council-district-6', 'Evansville City Council', 'Council Member, District 6', NULL),
  ('City of Evansville, Indiana, US', '1822000', 'Evansville City Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Evansville does not number its at-large seats; not a ballot designation.'),
  ('City of Evansville, Indiana, US', '1822000', 'Evansville City Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Evansville does not number its at-large seats; not a ballot designation.'),
  ('City of Evansville, Indiana, US', '1822000', 'Evansville City Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Evansville does not number its at-large seats; not a ballot designation.'),
  ('City of Evansville, Indiana, US', '1822000', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Evansville, Indiana, US', '1822000', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of South Bend, Indiana, US', 'south-bend-in-council-district-1', 'South Bend Common Council', 'Council Member, District 1', NULL),
  ('City of South Bend, Indiana, US', 'south-bend-in-council-district-2', 'South Bend Common Council', 'Council Member, District 2', NULL),
  ('City of South Bend, Indiana, US', 'south-bend-in-council-district-3', 'South Bend Common Council', 'Council Member, District 3', NULL),
  ('City of South Bend, Indiana, US', 'south-bend-in-council-district-4', 'South Bend Common Council', 'Council Member, District 4', NULL),
  ('City of South Bend, Indiana, US', 'south-bend-in-council-district-5', 'South Bend Common Council', 'Council Member, District 5', NULL),
  ('City of South Bend, Indiana, US', 'south-bend-in-council-district-6', 'South Bend Common Council', 'Council Member, District 6', NULL),
  ('City of South Bend, Indiana, US', '1871000', 'South Bend Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. South Bend does not number its at-large seats; not a ballot designation.'),
  ('City of South Bend, Indiana, US', '1871000', 'South Bend Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. South Bend does not number its at-large seats; not a ballot designation.'),
  ('City of South Bend, Indiana, US', '1871000', 'South Bend Common Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. South Bend does not number its at-large seats; not a ballot designation.'),
  ('City of South Bend, Indiana, US', '1871000', 'Office of the Mayor', 'Mayor', NULL),
  ('City of South Bend, Indiana, US', '1871000', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Carmel, Indiana, US', 'carmel-in-council-district-1', 'Carmel City Council', 'Council Member, District 1', NULL),
  ('City of Carmel, Indiana, US', 'carmel-in-council-district-2', 'Carmel City Council', 'Council Member, District 2', NULL),
  ('City of Carmel, Indiana, US', 'carmel-in-council-district-3', 'Carmel City Council', 'Council Member, District 3', NULL),
  ('City of Carmel, Indiana, US', 'carmel-in-council-district-4', 'Carmel City Council', 'Council Member, District 4', NULL),
  ('City of Carmel, Indiana, US', 'carmel-in-council-district-5', 'Carmel City Council', 'Council Member, District 5', NULL),
  ('City of Carmel, Indiana, US', 'carmel-in-council-district-6', 'Carmel City Council', 'Council Member, District 6', NULL),
  ('City of Carmel, Indiana, US', '1810342', 'Carmel City Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Carmel does not number its at-large seats; not a ballot designation.'),
  ('City of Carmel, Indiana, US', '1810342', 'Carmel City Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Carmel does not number its at-large seats; not a ballot designation.'),
  ('City of Carmel, Indiana, US', '1810342', 'Carmel City Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Carmel does not number its at-large seats; not a ballot designation.'),
  ('City of Carmel, Indiana, US', '1810342', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Carmel, Indiana, US', '1810342', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Lafayette, Indiana, US', 'lafayette-in-council-district-1', 'Lafayette Common Council', 'Council Member, District 1', NULL),
  ('City of Lafayette, Indiana, US', 'lafayette-in-council-district-2', 'Lafayette Common Council', 'Council Member, District 2', NULL),
  ('City of Lafayette, Indiana, US', 'lafayette-in-council-district-3', 'Lafayette Common Council', 'Council Member, District 3', NULL),
  ('City of Lafayette, Indiana, US', 'lafayette-in-council-district-4', 'Lafayette Common Council', 'Council Member, District 4', NULL),
  ('City of Lafayette, Indiana, US', 'lafayette-in-council-district-5', 'Lafayette Common Council', 'Council Member, District 5', NULL),
  ('City of Lafayette, Indiana, US', 'lafayette-in-council-district-6', 'Lafayette Common Council', 'Council Member, District 6', NULL),
  ('City of Lafayette, Indiana, US', '1840788', 'Lafayette Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Lafayette does not number its at-large seats; not a ballot designation.'),
  ('City of Lafayette, Indiana, US', '1840788', 'Lafayette Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Lafayette does not number its at-large seats; not a ballot designation.'),
  ('City of Lafayette, Indiana, US', '1840788', 'Lafayette Common Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Lafayette does not number its at-large seats; not a ballot designation.'),
  ('City of Lafayette, Indiana, US', '1840788', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Lafayette, Indiana, US', '1840788', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Muncie, Indiana, US', 'muncie-in-council-district-1', 'Muncie City Council', 'Council Member, District 1', NULL),
  ('City of Muncie, Indiana, US', 'muncie-in-council-district-2', 'Muncie City Council', 'Council Member, District 2', NULL),
  ('City of Muncie, Indiana, US', 'muncie-in-council-district-3', 'Muncie City Council', 'Council Member, District 3', NULL),
  ('City of Muncie, Indiana, US', 'muncie-in-council-district-4', 'Muncie City Council', 'Council Member, District 4', NULL),
  ('City of Muncie, Indiana, US', 'muncie-in-council-district-5', 'Muncie City Council', 'Council Member, District 5', NULL),
  ('City of Muncie, Indiana, US', 'muncie-in-council-district-6', 'Muncie City Council', 'Council Member, District 6', NULL),
  ('City of Muncie, Indiana, US', '1851876', 'Muncie City Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Muncie does not number its at-large seats; not a ballot designation.'),
  ('City of Muncie, Indiana, US', '1851876', 'Muncie City Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Muncie does not number its at-large seats; not a ballot designation.'),
  ('City of Muncie, Indiana, US', '1851876', 'Muncie City Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Muncie does not number its at-large seats; not a ballot designation.'),
  ('City of Muncie, Indiana, US', '1851876', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Muncie, Indiana, US', '1851876', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Westfield, Indiana, US', 'westfield-in-council-district-1', 'Westfield City Council', 'Council Member, District 1', NULL),
  ('City of Westfield, Indiana, US', 'westfield-in-council-district-2', 'Westfield City Council', 'Council Member, District 2', NULL),
  ('City of Westfield, Indiana, US', 'westfield-in-council-district-3', 'Westfield City Council', 'Council Member, District 3', NULL),
  ('City of Westfield, Indiana, US', 'westfield-in-council-district-4', 'Westfield City Council', 'Council Member, District 4', NULL),
  ('City of Westfield, Indiana, US', 'westfield-in-council-district-5', 'Westfield City Council', 'Council Member, District 5', NULL),
  ('City of Westfield, Indiana, US', '1882700', 'Westfield City Council', 'Council Member, At Large', 'Internal ordinal 1 of 2. Westfield does not number its at-large seats; not a ballot designation.'),
  ('City of Westfield, Indiana, US', '1882700', 'Westfield City Council', 'Council Member, At Large', 'Internal ordinal 2 of 2. Westfield does not number its at-large seats; not a ballot designation.'),
  ('City of Westfield, Indiana, US', '1882700', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Westfield, Indiana, US', '1882700', 'Office of the Clerk-Treasurer', 'Clerk-Treasurer', NULL),
  ('City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-1', 'Terre Haute City Council', 'Council Member, District 1', NULL),
  ('City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-2', 'Terre Haute City Council', 'Council Member, District 2', NULL),
  ('City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-3', 'Terre Haute City Council', 'Council Member, District 3', NULL),
  ('City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-4', 'Terre Haute City Council', 'Council Member, District 4', NULL),
  ('City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-5', 'Terre Haute City Council', 'Council Member, District 5', NULL),
  ('City of Terre Haute, Indiana, US', 'terre-haute-in-council-district-6', 'Terre Haute City Council', 'Council Member, District 6', NULL),
  ('City of Terre Haute, Indiana, US', '1875428', 'Terre Haute City Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Terre Haute does not number its at-large seats; not a ballot designation.'),
  ('City of Terre Haute, Indiana, US', '1875428', 'Terre Haute City Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Terre Haute does not number its at-large seats; not a ballot designation.'),
  ('City of Terre Haute, Indiana, US', '1875428', 'Terre Haute City Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Terre Haute does not number its at-large seats; not a ballot designation.'),
  ('City of Terre Haute, Indiana, US', '1875428', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Terre Haute, Indiana, US', '1875428', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Elkhart, Indiana, US', 'elkhart-in-council-district-1', 'Elkhart Common Council', 'Council Member, District 1', NULL),
  ('City of Elkhart, Indiana, US', 'elkhart-in-council-district-2', 'Elkhart Common Council', 'Council Member, District 2', NULL),
  ('City of Elkhart, Indiana, US', 'elkhart-in-council-district-3', 'Elkhart Common Council', 'Council Member, District 3', NULL),
  ('City of Elkhart, Indiana, US', 'elkhart-in-council-district-4', 'Elkhart Common Council', 'Council Member, District 4', NULL),
  ('City of Elkhart, Indiana, US', 'elkhart-in-council-district-5', 'Elkhart Common Council', 'Council Member, District 5', NULL),
  ('City of Elkhart, Indiana, US', 'elkhart-in-council-district-6', 'Elkhart Common Council', 'Council Member, District 6', NULL),
  ('City of Elkhart, Indiana, US', '1820728', 'Elkhart Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Elkhart does not number its at-large seats; not a ballot designation.'),
  ('City of Elkhart, Indiana, US', '1820728', 'Elkhart Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Elkhart does not number its at-large seats; not a ballot designation.'),
  ('City of Elkhart, Indiana, US', '1820728', 'Elkhart Common Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Elkhart does not number its at-large seats; not a ballot designation.'),
  ('City of Elkhart, Indiana, US', '1820728', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Elkhart, Indiana, US', '1820728', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-1', 'Jeffersonville City Council', 'Council Member, District 1', NULL),
  ('City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-2', 'Jeffersonville City Council', 'Council Member, District 2', NULL),
  ('City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-3', 'Jeffersonville City Council', 'Council Member, District 3', NULL),
  ('City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-4', 'Jeffersonville City Council', 'Council Member, District 4', NULL),
  ('City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-5', 'Jeffersonville City Council', 'Council Member, District 5', NULL),
  ('City of Jeffersonville, Indiana, US', 'jeffersonville-in-council-district-6', 'Jeffersonville City Council', 'Council Member, District 6', NULL),
  ('City of Jeffersonville, Indiana, US', '1838358', 'Jeffersonville City Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Jeffersonville does not number its at-large seats; not a ballot designation.'),
  ('City of Jeffersonville, Indiana, US', '1838358', 'Jeffersonville City Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Jeffersonville does not number its at-large seats; not a ballot designation.'),
  ('City of Jeffersonville, Indiana, US', '1838358', 'Jeffersonville City Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Jeffersonville does not number its at-large seats; not a ballot designation.'),
  ('City of Jeffersonville, Indiana, US', '1838358', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Jeffersonville, Indiana, US', '1838358', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-1', 'Mishawaka Common Council', 'Council Member, District 1', NULL),
  ('City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-2', 'Mishawaka Common Council', 'Council Member, District 2', NULL),
  ('City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-3', 'Mishawaka Common Council', 'Council Member, District 3', NULL),
  ('City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-4', 'Mishawaka Common Council', 'Council Member, District 4', NULL),
  ('City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-5', 'Mishawaka Common Council', 'Council Member, District 5', NULL),
  ('City of Mishawaka, Indiana, US', 'mishawaka-in-council-district-6', 'Mishawaka Common Council', 'Council Member, District 6', NULL),
  ('City of Mishawaka, Indiana, US', '1849932', 'Mishawaka Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Mishawaka does not number its at-large seats; not a ballot designation.'),
  ('City of Mishawaka, Indiana, US', '1849932', 'Mishawaka Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Mishawaka does not number its at-large seats; not a ballot designation.'),
  ('City of Mishawaka, Indiana, US', '1849932', 'Mishawaka Common Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Mishawaka does not number its at-large seats; not a ballot designation.'),
  ('City of Mishawaka, Indiana, US', '1849932', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Mishawaka, Indiana, US', '1849932', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Lawrence, Indiana, US', 'lawrence-in-council-district-1', 'Lawrence Common Council', 'Council Member, District 1', NULL),
  ('City of Lawrence, Indiana, US', 'lawrence-in-council-district-2', 'Lawrence Common Council', 'Council Member, District 2', NULL),
  ('City of Lawrence, Indiana, US', 'lawrence-in-council-district-3', 'Lawrence Common Council', 'Council Member, District 3', NULL),
  ('City of Lawrence, Indiana, US', 'lawrence-in-council-district-4', 'Lawrence Common Council', 'Council Member, District 4', NULL),
  ('City of Lawrence, Indiana, US', 'lawrence-in-council-district-5', 'Lawrence Common Council', 'Council Member, District 5', NULL),
  ('City of Lawrence, Indiana, US', 'lawrence-in-council-district-6', 'Lawrence Common Council', 'Council Member, District 6', NULL),
  ('City of Lawrence, Indiana, US', '1842426', 'Lawrence Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Lawrence does not number its at-large seats; not a ballot designation.'),
  ('City of Lawrence, Indiana, US', '1842426', 'Lawrence Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Lawrence does not number its at-large seats; not a ballot designation.'),
  ('City of Lawrence, Indiana, US', '1842426', 'Lawrence Common Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Lawrence does not number its at-large seats; not a ballot designation.'),
  ('City of Lawrence, Indiana, US', '1842426', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Lawrence, Indiana, US', '1842426', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of New Albany, Indiana, US', 'new-albany-in-council-district-1', 'New Albany City Council', 'Council Member, District 1', NULL),
  ('City of New Albany, Indiana, US', 'new-albany-in-council-district-2', 'New Albany City Council', 'Council Member, District 2', NULL),
  ('City of New Albany, Indiana, US', 'new-albany-in-council-district-3', 'New Albany City Council', 'Council Member, District 3', NULL),
  ('City of New Albany, Indiana, US', 'new-albany-in-council-district-4', 'New Albany City Council', 'Council Member, District 4', NULL),
  ('City of New Albany, Indiana, US', 'new-albany-in-council-district-5', 'New Albany City Council', 'Council Member, District 5', NULL),
  ('City of New Albany, Indiana, US', 'new-albany-in-council-district-6', 'New Albany City Council', 'Council Member, District 6', NULL),
  ('City of New Albany, Indiana, US', '1852326', 'New Albany City Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. New Albany does not number its at-large seats; not a ballot designation.'),
  ('City of New Albany, Indiana, US', '1852326', 'New Albany City Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. New Albany does not number its at-large seats; not a ballot designation.'),
  ('City of New Albany, Indiana, US', '1852326', 'New Albany City Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. New Albany does not number its at-large seats; not a ballot designation.'),
  ('City of New Albany, Indiana, US', '1852326', 'Office of the Mayor', 'Mayor', NULL),
  ('City of New Albany, Indiana, US', '1852326', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Goshen, Indiana, US', 'goshen-in-council-district-1', 'Goshen Common Council', 'Council Member, District 1', NULL),
  ('City of Goshen, Indiana, US', 'goshen-in-council-district-2', 'Goshen Common Council', 'Council Member, District 2', NULL),
  ('City of Goshen, Indiana, US', 'goshen-in-council-district-3', 'Goshen Common Council', 'Council Member, District 3', NULL),
  ('City of Goshen, Indiana, US', 'goshen-in-council-district-4', 'Goshen Common Council', 'Council Member, District 4', NULL),
  ('City of Goshen, Indiana, US', 'goshen-in-council-district-5', 'Goshen Common Council', 'Council Member, District 5', NULL),
  ('City of Goshen, Indiana, US', '1828386', 'Goshen Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 2. Goshen does not number its at-large seats; not a ballot designation.'),
  ('City of Goshen, Indiana, US', '1828386', 'Goshen Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 2. Goshen does not number its at-large seats; not a ballot designation.'),
  ('City of Goshen, Indiana, US', '1828386', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Goshen, Indiana, US', '1828386', 'Office of the Clerk-Treasurer', 'Clerk-Treasurer', NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'IN', g.city, 1, false, 'full'
FROM w_off n
JOIN essentials.governments g ON g.name = n.gov
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify, per city ───────────────────────────────────────────────────

DO $$
DECLARE r record; v_gov int; v_ch int; v_off int; v_council int; v_al int; v_dist int; v_unreach int;
        v_total int := 0;
BEGIN
  FOR r IN SELECT * FROM w_city LOOP
    SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = r.gov;
    SELECT count(*) INTO v_ch FROM essentials.chambers c JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = r.gov;
    SELECT count(*), count(*) FILTER (WHERE c.name = r.council), count(*) FILTER (WHERE o.title = 'Council Member, At Large')
      INTO v_off, v_council, v_al
      FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = r.gov;
    SELECT count(*) INTO v_dist FROM essentials.districts
     WHERE district_type = 'LOCAL' AND lower(state) = 'in'
       AND (geo_id LIKE r.slug || '-council-district-%' OR geo_id = r.geoid);
    -- 🔴 Every district must meet a boundary on (geo_id, mtfcc), or its officeholder is invisible at an address.
    SELECT count(*) INTO v_unreach FROM essentials.districts d
     WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'in'
       AND (d.geo_id LIKE r.slug || '-council-district-%' OR d.geo_id = r.geoid)
       AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
    IF v_gov <> 1 OR v_ch <> 3 OR v_off <> r.n_dist + r.n_al + 2 OR v_council <> r.n_dist + r.n_al
       OR v_al <> r.n_al OR v_dist <> r.n_dist + 1 OR v_unreach <> 0 THEN
      RAISE EXCEPTION 'post-verify %: gov % ch % offices % (want %) council % al % districts % (want %) unreachable %',
        r.slug, v_gov, v_ch, v_off, r.n_dist + r.n_al + 2, v_council, v_al, v_dist, r.n_dist + 1, v_unreach;
    END IF;
    RAISE NOTICE 'ok %: % offices (% district + % at-large + mayor + clerk), % districts, all reachable',
      r.slug, v_off, r.n_dist, r.n_al, v_dist;
    v_total := v_total + v_off;
  END LOOP;
  IF v_total <> 139 THEN RAISE EXCEPTION 'post-verify: % offices in total, expected 139', v_total; END IF;
  RAISE NOTICE 'structure OK: 13 cities, 139 offices, 89 districts';
END $$;

COMMIT;
