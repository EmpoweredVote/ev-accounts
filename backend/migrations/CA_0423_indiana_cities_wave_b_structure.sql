-- CA_0423_indiana_cities_wave_b_structure.sql
-- Indiana cities Wave B, structure half. Slot RESERVED from the allocator.
-- Scope note: .planning/todos/2026-11-24-indiana-cities-2027-scope.md
--
-- Creates 7 city governments, 21 chambers, 42 districts and 65 offices.
-- Creates NO people and NO terms -- the people migration does that.
-- 🔴 APPLY THE PEOPLE MIGRATION THE SAME DAY. Until it runs, every new district is an office with a polygon,
-- no holder and no vacancy flag, which check:reachability counts as DEAD_GEOGRAPHY (CA_0416 alone took
-- in|LOCAL from 12 to 101 and held the gate red until CA_0417 landed).
--
-- Structure per city, from IC 36-4-6-3 / 36-4-6-4 / 36-4-10-2 and confirmed on each city's own site
-- (data/seed-in-cities-wave-b/cities/<slug>.json, checked by verify-collect.mjs):
--   Michigan City    6 district + 3 at-large · City Clerk      · https://michigancityin.gov/government/boards-commissions/city-council/
--   Greensburg       4 district + 3 at-large · Clerk-Treasurer · https://www.cityofgreensburg.com/government/city-council/
--   Jasper           5 district + 2 at-large · Clerk-Treasurer · https://www.jasperindiana.gov/council
--   New Haven        5 district + 2 at-large · Clerk-Treasurer · https://www.newhaven.in.gov/574/Meet-the-Council
--   Warsaw           5 district + 2 at-large · Clerk-Treasurer · https://www.warsaw.in.gov/78/City-Elected-Officials
--   Bluffton         5 district + 2 at-large · Clerk-Treasurer · https://www.blufftonindiana.net/197/Common-Council
--   Beech Grove      5 district + 2 at-large · Clerk-Treasurer · https://www.beechgrove.com/common-council
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
  ('City of Michigan City, Indiana, US', 'michigan-city-in', '1848798', 6, 3, 'Michigan City Common Council'),
  ('City of Greensburg, Indiana, US', 'greensburg-in', '1829718', 4, 3, 'Greensburg City Council'),
  ('City of Jasper, Indiana, US', 'jasper-in', '1837782', 5, 2, 'Jasper Common Council'),
  ('City of New Haven, Indiana, US', 'new-haven-in', '1852992', 5, 2, 'New Haven City Council'),
  ('City of Warsaw, Indiana, US', 'warsaw-in', '1880306', 5, 2, 'Warsaw Common Council'),
  ('City of Bluffton, Indiana, US', 'bluffton-in', '1806220', 5, 2, 'Bluffton Common Council'),
  ('City of Beech Grove, Indiana, US', 'beech-grove-in', '1804204', 5, 2, 'Beech Grove Common Council');

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
  ('City of Michigan City, Indiana, US', 'Michigan City', '1848798'),
  ('City of Greensburg, Indiana, US', 'Greensburg', '1829718'),
  ('City of Jasper, Indiana, US', 'Jasper', '1837782'),
  ('City of New Haven, Indiana, US', 'New Haven', '1852992'),
  ('City of Warsaw, Indiana, US', 'Warsaw', '1880306'),
  ('City of Bluffton, Indiana, US', 'Bluffton', '1806220'),
  ('City of Beech Grove, Indiana, US', 'Beech Grove', '1804204')
) AS v(name, city, geo_id)
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.name = v.name);

-- ─── 2. Chambers ─────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM (VALUES
  ('City of Michigan City, Indiana, US', 'Michigan City Common Council', 9),
  ('City of Michigan City, Indiana, US', 'Office of the Mayor', 1),
  ('City of Michigan City, Indiana, US', 'Office of the City Clerk', 1),
  ('City of Greensburg, Indiana, US', 'Greensburg City Council', 7),
  ('City of Greensburg, Indiana, US', 'Office of the Mayor', 1),
  ('City of Greensburg, Indiana, US', 'Office of the Clerk-Treasurer', 1),
  ('City of Jasper, Indiana, US', 'Jasper Common Council', 7),
  ('City of Jasper, Indiana, US', 'Office of the Mayor', 1),
  ('City of Jasper, Indiana, US', 'Office of the Clerk-Treasurer', 1),
  ('City of New Haven, Indiana, US', 'New Haven City Council', 7),
  ('City of New Haven, Indiana, US', 'Office of the Mayor', 1),
  ('City of New Haven, Indiana, US', 'Office of the Clerk-Treasurer', 1),
  ('City of Warsaw, Indiana, US', 'Warsaw Common Council', 7),
  ('City of Warsaw, Indiana, US', 'Office of the Mayor', 1),
  ('City of Warsaw, Indiana, US', 'Office of the Clerk-Treasurer', 1),
  ('City of Bluffton, Indiana, US', 'Bluffton Common Council', 7),
  ('City of Bluffton, Indiana, US', 'Office of the Mayor', 1),
  ('City of Bluffton, Indiana, US', 'Office of the Clerk-Treasurer', 1),
  ('City of Beech Grove, Indiana, US', 'Beech Grove Common Council', 7),
  ('City of Beech Grove, Indiana, US', 'Office of the Mayor', 1),
  ('City of Beech Grove, Indiana, US', 'Office of the Clerk-Treasurer', 1)
) AS v(gov, name, official_count)
JOIN essentials.governments g ON g.name = v.gov
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Districts ────────────────────────────────────────────────────────────
-- Council districts on X0091; one citywide row per city on its TIGER place polygon, which carries the
-- Mayor, the clerk and the at-large seats.

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT v.geo_id, v.label, 'LOCAL', 'in', v.mtfcc
FROM (VALUES
  ('michigan-city-in-council-district-1', 'Michigan City City Council District 1', 'X0091'),
  ('michigan-city-in-council-district-2', 'Michigan City City Council District 2', 'X0091'),
  ('michigan-city-in-council-district-3', 'Michigan City City Council District 3', 'X0091'),
  ('michigan-city-in-council-district-4', 'Michigan City City Council District 4', 'X0091'),
  ('michigan-city-in-council-district-5', 'Michigan City City Council District 5', 'X0091'),
  ('michigan-city-in-council-district-6', 'Michigan City City Council District 6', 'X0091'),
  ('1848798', 'Michigan City Citywide', 'G4110'),
  ('greensburg-in-council-district-1', 'Greensburg City Council District 1', 'X0091'),
  ('greensburg-in-council-district-2', 'Greensburg City Council District 2', 'X0091'),
  ('greensburg-in-council-district-3', 'Greensburg City Council District 3', 'X0091'),
  ('greensburg-in-council-district-4', 'Greensburg City Council District 4', 'X0091'),
  ('1829718', 'Greensburg Citywide', 'G4110'),
  ('jasper-in-council-district-2', 'Jasper City Council District 2', 'X0091'),
  ('jasper-in-council-district-3', 'Jasper City Council District 3', 'X0091'),
  ('jasper-in-council-district-4', 'Jasper City Council District 4', 'X0091'),
  ('jasper-in-council-district-5', 'Jasper City Council District 5', 'X0091'),
  ('jasper-in-council-district-6', 'Jasper City Council District 6', 'X0091'),
  ('1837782', 'Jasper Citywide', 'G4110'),
  ('new-haven-in-council-district-1', 'New Haven City Council District 1', 'X0091'),
  ('new-haven-in-council-district-2', 'New Haven City Council District 2', 'X0091'),
  ('new-haven-in-council-district-3', 'New Haven City Council District 3', 'X0091'),
  ('new-haven-in-council-district-4', 'New Haven City Council District 4', 'X0091'),
  ('new-haven-in-council-district-5', 'New Haven City Council District 5', 'X0091'),
  ('1852992', 'New Haven Citywide', 'G4110'),
  ('warsaw-in-council-district-1', 'Warsaw City Council District 1', 'X0091'),
  ('warsaw-in-council-district-2', 'Warsaw City Council District 2', 'X0091'),
  ('warsaw-in-council-district-3', 'Warsaw City Council District 3', 'X0091'),
  ('warsaw-in-council-district-4', 'Warsaw City Council District 4', 'X0091'),
  ('warsaw-in-council-district-5', 'Warsaw City Council District 5', 'X0091'),
  ('1880306', 'Warsaw Citywide', 'G4110'),
  ('bluffton-in-council-district-1', 'Bluffton City Council District 1', 'X0091'),
  ('bluffton-in-council-district-2', 'Bluffton City Council District 2', 'X0091'),
  ('bluffton-in-council-district-3', 'Bluffton City Council District 3', 'X0091'),
  ('bluffton-in-council-district-4', 'Bluffton City Council District 4', 'X0091'),
  ('bluffton-in-council-district-5', 'Bluffton City Council District 5', 'X0091'),
  ('1806220', 'Bluffton Citywide', 'G4110'),
  ('beech-grove-in-council-district-1', 'Beech Grove City Council District 1', 'X0091'),
  ('beech-grove-in-council-district-2', 'Beech Grove City Council District 2', 'X0091'),
  ('beech-grove-in-council-district-3', 'Beech Grove City Council District 3', 'X0091'),
  ('beech-grove-in-council-district-4', 'Beech Grove City Council District 4', 'X0091'),
  ('beech-grove-in-council-district-5', 'Beech Grove City Council District 5', 'X0091'),
  ('1804204', 'Beech Grove Citywide', 'G4110')
) AS v(geo_id, label, mtfcc)
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Offices ──────────────────────────────────────────────────────────────

CREATE TEMP TABLE w_off(gov text, geo_id text, chamber text, title text, description text) ON COMMIT DROP;
INSERT INTO w_off VALUES
  ('City of Michigan City, Indiana, US', 'michigan-city-in-council-district-1', 'Michigan City Common Council', 'Council Member, District 1', NULL),
  ('City of Michigan City, Indiana, US', 'michigan-city-in-council-district-2', 'Michigan City Common Council', 'Council Member, District 2', NULL),
  ('City of Michigan City, Indiana, US', 'michigan-city-in-council-district-3', 'Michigan City Common Council', 'Council Member, District 3', NULL),
  ('City of Michigan City, Indiana, US', 'michigan-city-in-council-district-4', 'Michigan City Common Council', 'Council Member, District 4', NULL),
  ('City of Michigan City, Indiana, US', 'michigan-city-in-council-district-5', 'Michigan City Common Council', 'Council Member, District 5', NULL),
  ('City of Michigan City, Indiana, US', 'michigan-city-in-council-district-6', 'Michigan City Common Council', 'Council Member, District 6', NULL),
  ('City of Michigan City, Indiana, US', '1848798', 'Michigan City Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Michigan City does not number its at-large seats; not a ballot designation.'),
  ('City of Michigan City, Indiana, US', '1848798', 'Michigan City Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Michigan City does not number its at-large seats; not a ballot designation.'),
  ('City of Michigan City, Indiana, US', '1848798', 'Michigan City Common Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Michigan City does not number its at-large seats; not a ballot designation.'),
  ('City of Michigan City, Indiana, US', '1848798', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Michigan City, Indiana, US', '1848798', 'Office of the City Clerk', 'City Clerk', NULL),
  ('City of Greensburg, Indiana, US', 'greensburg-in-council-district-1', 'Greensburg City Council', 'Council Member, District 1', NULL),
  ('City of Greensburg, Indiana, US', 'greensburg-in-council-district-2', 'Greensburg City Council', 'Council Member, District 2', NULL),
  ('City of Greensburg, Indiana, US', 'greensburg-in-council-district-3', 'Greensburg City Council', 'Council Member, District 3', NULL),
  ('City of Greensburg, Indiana, US', 'greensburg-in-council-district-4', 'Greensburg City Council', 'Council Member, District 4', NULL),
  ('City of Greensburg, Indiana, US', '1829718', 'Greensburg City Council', 'Council Member, At Large', 'Internal ordinal 1 of 3. Greensburg does not number its at-large seats; not a ballot designation.'),
  ('City of Greensburg, Indiana, US', '1829718', 'Greensburg City Council', 'Council Member, At Large', 'Internal ordinal 2 of 3. Greensburg does not number its at-large seats; not a ballot designation.'),
  ('City of Greensburg, Indiana, US', '1829718', 'Greensburg City Council', 'Council Member, At Large', 'Internal ordinal 3 of 3. Greensburg does not number its at-large seats; not a ballot designation.'),
  ('City of Greensburg, Indiana, US', '1829718', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Greensburg, Indiana, US', '1829718', 'Office of the Clerk-Treasurer', 'Clerk-Treasurer', NULL),
  ('City of Jasper, Indiana, US', 'jasper-in-council-district-2', 'Jasper Common Council', 'Council Member, District 2', NULL),
  ('City of Jasper, Indiana, US', 'jasper-in-council-district-3', 'Jasper Common Council', 'Council Member, District 3', NULL),
  ('City of Jasper, Indiana, US', 'jasper-in-council-district-4', 'Jasper Common Council', 'Council Member, District 4', NULL),
  ('City of Jasper, Indiana, US', 'jasper-in-council-district-5', 'Jasper Common Council', 'Council Member, District 5', NULL),
  ('City of Jasper, Indiana, US', 'jasper-in-council-district-6', 'Jasper Common Council', 'Council Member, District 6', NULL),
  ('City of Jasper, Indiana, US', '1837782', 'Jasper Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 2. Jasper does not number its at-large seats; not a ballot designation.'),
  ('City of Jasper, Indiana, US', '1837782', 'Jasper Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 2. Jasper does not number its at-large seats; not a ballot designation.'),
  ('City of Jasper, Indiana, US', '1837782', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Jasper, Indiana, US', '1837782', 'Office of the Clerk-Treasurer', 'Clerk-Treasurer', NULL),
  ('City of New Haven, Indiana, US', 'new-haven-in-council-district-1', 'New Haven City Council', 'Council Member, District 1', NULL),
  ('City of New Haven, Indiana, US', 'new-haven-in-council-district-2', 'New Haven City Council', 'Council Member, District 2', NULL),
  ('City of New Haven, Indiana, US', 'new-haven-in-council-district-3', 'New Haven City Council', 'Council Member, District 3', NULL),
  ('City of New Haven, Indiana, US', 'new-haven-in-council-district-4', 'New Haven City Council', 'Council Member, District 4', NULL),
  ('City of New Haven, Indiana, US', 'new-haven-in-council-district-5', 'New Haven City Council', 'Council Member, District 5', NULL),
  ('City of New Haven, Indiana, US', '1852992', 'New Haven City Council', 'Council Member, At Large', 'Internal ordinal 1 of 2. New Haven does not number its at-large seats; not a ballot designation.'),
  ('City of New Haven, Indiana, US', '1852992', 'New Haven City Council', 'Council Member, At Large', 'Internal ordinal 2 of 2. New Haven does not number its at-large seats; not a ballot designation.'),
  ('City of New Haven, Indiana, US', '1852992', 'Office of the Mayor', 'Mayor', NULL),
  ('City of New Haven, Indiana, US', '1852992', 'Office of the Clerk-Treasurer', 'Clerk-Treasurer', NULL),
  ('City of Warsaw, Indiana, US', 'warsaw-in-council-district-1', 'Warsaw Common Council', 'Council Member, District 1', NULL),
  ('City of Warsaw, Indiana, US', 'warsaw-in-council-district-2', 'Warsaw Common Council', 'Council Member, District 2', NULL),
  ('City of Warsaw, Indiana, US', 'warsaw-in-council-district-3', 'Warsaw Common Council', 'Council Member, District 3', NULL),
  ('City of Warsaw, Indiana, US', 'warsaw-in-council-district-4', 'Warsaw Common Council', 'Council Member, District 4', NULL),
  ('City of Warsaw, Indiana, US', 'warsaw-in-council-district-5', 'Warsaw Common Council', 'Council Member, District 5', NULL),
  ('City of Warsaw, Indiana, US', '1880306', 'Warsaw Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 2. Warsaw does not number its at-large seats; not a ballot designation.'),
  ('City of Warsaw, Indiana, US', '1880306', 'Warsaw Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 2. Warsaw does not number its at-large seats; not a ballot designation.'),
  ('City of Warsaw, Indiana, US', '1880306', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Warsaw, Indiana, US', '1880306', 'Office of the Clerk-Treasurer', 'Clerk-Treasurer', NULL),
  ('City of Bluffton, Indiana, US', 'bluffton-in-council-district-1', 'Bluffton Common Council', 'Council Member, District 1', NULL),
  ('City of Bluffton, Indiana, US', 'bluffton-in-council-district-2', 'Bluffton Common Council', 'Council Member, District 2', NULL),
  ('City of Bluffton, Indiana, US', 'bluffton-in-council-district-3', 'Bluffton Common Council', 'Council Member, District 3', NULL),
  ('City of Bluffton, Indiana, US', 'bluffton-in-council-district-4', 'Bluffton Common Council', 'Council Member, District 4', NULL),
  ('City of Bluffton, Indiana, US', 'bluffton-in-council-district-5', 'Bluffton Common Council', 'Council Member, District 5', NULL),
  ('City of Bluffton, Indiana, US', '1806220', 'Bluffton Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 2. Bluffton does not number its at-large seats; not a ballot designation.'),
  ('City of Bluffton, Indiana, US', '1806220', 'Bluffton Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 2. Bluffton does not number its at-large seats; not a ballot designation.'),
  ('City of Bluffton, Indiana, US', '1806220', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Bluffton, Indiana, US', '1806220', 'Office of the Clerk-Treasurer', 'Clerk-Treasurer', NULL),
  ('City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-1', 'Beech Grove Common Council', 'Council Member, District 1', NULL),
  ('City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-2', 'Beech Grove Common Council', 'Council Member, District 2', NULL),
  ('City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-3', 'Beech Grove Common Council', 'Council Member, District 3', NULL),
  ('City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-4', 'Beech Grove Common Council', 'Council Member, District 4', NULL),
  ('City of Beech Grove, Indiana, US', 'beech-grove-in-council-district-5', 'Beech Grove Common Council', 'Council Member, District 5', NULL),
  ('City of Beech Grove, Indiana, US', '1804204', 'Beech Grove Common Council', 'Council Member, At Large', 'Internal ordinal 1 of 2. Beech Grove does not number its at-large seats; not a ballot designation.'),
  ('City of Beech Grove, Indiana, US', '1804204', 'Beech Grove Common Council', 'Council Member, At Large', 'Internal ordinal 2 of 2. Beech Grove does not number its at-large seats; not a ballot designation.'),
  ('City of Beech Grove, Indiana, US', '1804204', 'Office of the Mayor', 'Mayor', NULL),
  ('City of Beech Grove, Indiana, US', '1804204', 'Office of the Clerk-Treasurer', 'Clerk-Treasurer', NULL);

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
  IF v_total <> 65 THEN RAISE EXCEPTION 'post-verify: % offices in total, expected 65', v_total; END IF;
  RAISE NOTICE 'structure OK: 7 cities, 65 offices, 42 districts';
END $$;

COMMIT;
