-- CA_0418_indiana_cities_wave_a_structure_2.sql
-- Indiana cities Wave A, structure half. Slot RESERVED from the allocator.
-- Scope note: .planning/todos/2026-11-24-indiana-cities-2027-scope.md
--
-- Creates 3 city governments, 9 chambers, 21 districts and 33 offices.
-- Creates NO people and NO terms -- the people migration does that.
-- 🔴 APPLY THE PEOPLE MIGRATION THE SAME DAY. Until it runs, every new district is an office with a polygon,
-- no holder and no vacancy flag, which check:reachability counts as DEAD_GEOGRAPHY (CA_0416 alone took
-- in|LOCAL from 12 to 101 and held the gate red until CA_0417 landed).
--
-- Structure per city, from IC 36-4-6-3 / 36-4-6-4 / 36-4-10-2 and confirmed on each city's own site
-- (data/seed-in-cities-wave-a/cities/<slug>.json, checked by verify-collect.mjs):
--   Hammond          6 district + 3 at-large · City Clerk      · https://www.gohammond.com/city-council/
--   Kokomo           6 district + 3 at-large · City Clerk      · https://cityofkokomo.org/departments/common_council/index.php
--   Greenwood        6 district + 3 at-large · City Clerk      · https://www.greenwood.in.gov/officials
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
  ('City of Hammond, Indiana, US', 'hammond-in', '1831000', 6, 3, 'Hammond Common Council'),
  ('City of Kokomo, Indiana, US', 'kokomo-in', '1840392', 6, 3, 'Kokomo Common Council'),
  ('City of Greenwood, Indiana, US', 'greenwood-in', '1829898', 6, 3, 'Greenwood Common Council');

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
  ('City of Hammond, Indiana, US', 'Hammond', '1831000'),
  ('City of Kokomo, Indiana, US', 'Kokomo', '1840392'),
  ('City of Greenwood, Indiana, US', 'Greenwood', '1829898')
) AS v(name, city, geo_id)
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.name = v.name);

-- ─── 2. Chambers ─────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM (VALUES
  ('City of Hammond, Indiana, US', 'Hammond Common Council', 9),
  ('City of Hammond, Indiana, US', 'Office of the Mayor', 1),
  ('City of Hammond, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Kokomo, Indiana, US', 'Kokomo Common Council', 9),
  ('City of Kokomo, Indiana, US', 'Office of the Mayor', 1),
  ('City of Kokomo, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Greenwood, Indiana, US', 'Greenwood Common Council', 9),
  ('City of Greenwood, Indiana, US', 'Office of the Mayor', 1),
  ('City of Greenwood, Indiana, US', 'Office of the City Clerk', 1)
) AS v(gov, name, official_count)
JOIN essentials.governments g ON g.name = v.gov
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Districts ────────────────────────────────────────────────────────────
-- Council districts on X0091; one citywide row per city on its TIGER place polygon, which carries the
-- Mayor, the clerk and the at-large seats.

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT v.geo_id, v.label, 'LOCAL', 'in', v.mtfcc
FROM (VALUES
  ('hammond-in-council-district-1', 'Hammond City Council District 1', 'X0091'),
  ('hammond-in-council-district-2', 'Hammond City Council District 2', 'X0091'),
  ('hammond-in-council-district-3', 'Hammond City Council District 3', 'X0091'),
  ('hammond-in-council-district-4', 'Hammond City Council District 4', 'X0091'),
  ('hammond-in-council-district-5', 'Hammond City Council District 5', 'X0091'),
  ('hammond-in-council-district-6', 'Hammond City Council District 6', 'X0091'),
  ('1831000', 'Hammond Citywide', 'G4110'),
  ('kokomo-in-council-district-1', 'Kokomo City Council District 1', 'X0091'),
  ('kokomo-in-council-district-2', 'Kokomo City Council District 2', 'X0091'),
  ('kokomo-in-council-district-3', 'Kokomo City Council District 3', 'X0091'),
  ('kokomo-in-council-district-4', 'Kokomo City Council District 4', 'X0091'),
  ('kokomo-in-council-district-5', 'Kokomo City Council District 5', 'X0091'),
  ('kokomo-in-council-district-6', 'Kokomo City Council District 6', 'X0091'),
  ('1840392', 'Kokomo Citywide', 'G4110'),
  ('greenwood-in-council-district-1', 'Greenwood City Council District 1', 'X0091'),
  ('greenwood-in-council-district-2', 'Greenwood City Council District 2', 'X0091'),
  ('greenwood-in-council-district-3', 'Greenwood City Council District 3', 'X0091'),
  ('greenwood-in-council-district-4', 'Greenwood City Council District 4', 'X0091'),
  ('greenwood-in-council-district-5', 'Greenwood City Council District 5', 'X0091'),
  ('greenwood-in-council-district-6', 'Greenwood City Council District 6', 'X0091'),
  ('1829898', 'Greenwood Citywide', 'G4110')
) AS v(geo_id, label, mtfcc)
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Offices ──────────────────────────────────────────────────────────────

CREATE TEMP TABLE w_off(gov text, geo_id text, chamber text, title text, description text) ON COMMIT DROP;
INSERT INTO w_off VALUES
  ('City of Hammond, Indiana, US', 'hammond-in-council-district-1', 'Hammond Common Council', 'Council Member, District 1', NULL),
  ('City of Hammond, Indiana, US', 'hammond-in-council-district-2', 'Hammond Common Council', 'Council Member, District 2', NULL),
  ('City of Hammond, Indiana, US', 'hammond-in-council-district-3', 'Hammond Common Council', 'Council Member, District 3', NULL),
  ('City of Hammond, Indiana, US', 'hammond-in-council-district-4', 'Hammond Common Council', 'Council Member, District 4', NULL),
  ('City of Hammond, Indiana, US', 'hammond-in-council-district-5', 'Hammond Common Council', 'Council Member, District 5', NULL),
  ('City of Hammond, Indiana, US', 'hammond-in-council-district-6', 'Hammond Common Council', 'Council Member, District 6', NULL),
  ('City of Hammond, Indiana, US', '1831000', 'Hammond Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Hammond does not number its at-large seats; not a ballot designation.'),
  ('City of Hammond, Indiana, US', '1831000', 'Hammond Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Hammond does not number its at-large seats; not a ballot designation.'),
  ('City of Hammond, Indiana, US', '1831000', 'Hammond Common Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Hammond does not number its at-large seats; not a ballot designation.'),
  ('City of Hammond, Indiana, US', '1831000', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Hammond, Indiana, US', '1831000', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Kokomo, Indiana, US', 'kokomo-in-council-district-1', 'Kokomo Common Council', 'Council Member, District 1', NULL),
  ('City of Kokomo, Indiana, US', 'kokomo-in-council-district-2', 'Kokomo Common Council', 'Council Member, District 2', NULL),
  ('City of Kokomo, Indiana, US', 'kokomo-in-council-district-3', 'Kokomo Common Council', 'Council Member, District 3', NULL),
  ('City of Kokomo, Indiana, US', 'kokomo-in-council-district-4', 'Kokomo Common Council', 'Council Member, District 4', NULL),
  ('City of Kokomo, Indiana, US', 'kokomo-in-council-district-5', 'Kokomo Common Council', 'Council Member, District 5', NULL),
  ('City of Kokomo, Indiana, US', 'kokomo-in-council-district-6', 'Kokomo Common Council', 'Council Member, District 6', NULL),
  ('City of Kokomo, Indiana, US', '1840392', 'Kokomo Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Kokomo does not number its at-large seats; not a ballot designation.'),
  ('City of Kokomo, Indiana, US', '1840392', 'Kokomo Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Kokomo does not number its at-large seats; not a ballot designation.'),
  ('City of Kokomo, Indiana, US', '1840392', 'Kokomo Common Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Kokomo does not number its at-large seats; not a ballot designation.'),
  ('City of Kokomo, Indiana, US', '1840392', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Kokomo, Indiana, US', '1840392', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Greenwood, Indiana, US', 'greenwood-in-council-district-1', 'Greenwood Common Council', 'Council Member, District 1', NULL),
  ('City of Greenwood, Indiana, US', 'greenwood-in-council-district-2', 'Greenwood Common Council', 'Council Member, District 2', NULL),
  ('City of Greenwood, Indiana, US', 'greenwood-in-council-district-3', 'Greenwood Common Council', 'Council Member, District 3', NULL),
  ('City of Greenwood, Indiana, US', 'greenwood-in-council-district-4', 'Greenwood Common Council', 'Council Member, District 4', NULL),
  ('City of Greenwood, Indiana, US', 'greenwood-in-council-district-5', 'Greenwood Common Council', 'Council Member, District 5', NULL),
  ('City of Greenwood, Indiana, US', 'greenwood-in-council-district-6', 'Greenwood Common Council', 'Council Member, District 6', NULL),
  ('City of Greenwood, Indiana, US', '1829898', 'Greenwood Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Greenwood does not number its at-large seats; not a ballot designation.'),
  ('City of Greenwood, Indiana, US', '1829898', 'Greenwood Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Greenwood does not number its at-large seats; not a ballot designation.'),
  ('City of Greenwood, Indiana, US', '1829898', 'Greenwood Common Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Greenwood does not number its at-large seats; not a ballot designation.'),
  ('City of Greenwood, Indiana, US', '1829898', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Greenwood, Indiana, US', '1829898', 'Office of the City Clerk', 'City Clerk', NULL);

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
  IF v_total <> 33 THEN RAISE EXCEPTION 'post-verify: % offices in total, expected 33', v_total; END IF;
  RAISE NOTICE 'structure OK: 3 cities, 33 offices, 21 districts';
END $$;

COMMIT;
