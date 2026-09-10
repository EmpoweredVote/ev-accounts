-- CC_0090_fort_wayne_structure.sql
-- Knight Foundation program, wave IN-3 (structure half). Slot RESERVED from the allocator.
--
-- Creates the City of Fort Wayne government, its THREE chambers, SEVEN districts and ELEVEN
-- offices. Creates NO people and NO terms -- CC_0091 does that, and the two are applied back
-- to back.
--
--   Fort Wayne Common Council   official_count 9   6 district + 3 at-large
--   Office of the Mayor         official_count 1   Mayor
--   Office of the City Clerk    official_count 1   City Clerk
--
-- 🔴 ELEVEN OFFICES IS WHAT THE CODE SAYS, NOT WHAT INDIANA CITIES "USUALLY" HAVE.
-- Fort Wayne Code § 31.01 ELECTED OFFICIALS reads (A) Mayor, (B) Common Council -- "six district
-- members and three at-large members" -- and (C) City Clerk. The section ENDS at (C): Fort Wayne
-- elects no city judge and no other city officer. The Council Attorney named on every agenda
-- (Joseph G. Bonahoom) is APPOINTED and is deliberately not modelled.
--
-- 🔴 THE THREE AT-LARGE SEATS ARE NOT NUMBERED, AND THIS MIGRATION REFUSES TO NUMBER THEM.
-- Georgia numbers its at-large seats -- Columbus carries "Council Member, Post 9 (At Large)" --
-- because Georgia law creates numbered posts. Indiana does not: all three run in one citywide
-- race and the top three win. So all three offices carry the IDENTICAL voter-facing title
-- 'Council Member, At Large'. Inventing "Seat 1/2/3" would describe a power Fort Wayne
-- does not have, which is the DESCRIBE-REAL-POWERS rule.
--
-- ⚠ THAT LEAVES THE THREE INDISTINGUISHABLE BY TITLE, so CC_0091 could not join a person to a
-- seat. The discriminator is therefore carried in `description`, is explicitly labelled INTERNAL,
-- and is not a claim about Fort Wayne's ballot. It exists so occupancy is deterministic; nothing
-- reads it as a seat name.
--
-- 🔴 GEOMETRY COMES FROM scripts/load-fort-wayne-council-boundaries.ts (X0048), NOT from here,
-- and the pre-flight below FAILS HARD if those six boundaries are absent -- an office on a
-- district with no polygon is unreachable by address and nothing errors.
--
-- 🔴 THE SIX DISTRICTS DO NOT TILE THE CITY, AND THAT IS CORRECT. Union 111.0025 sq mi against
-- a 112.0932 sq mi TIGER place polygon; the uncovered 1.2524 sq mi is unincorporated Allen
-- County by the Election Board's own precinct record (precinct ADAMS G, City_Dist='COUNTY').
-- See ROSTERS.md. Full coverage is NOT the right gate here.
--
-- ⚠ districts.state is written LOWERCASE 'in', matching every other LOCAL district in production
-- (fl, ga, ca) and the current TIGER loader. Indiana's LEGACY 18 legislative rows are uppercase
-- 'IN' and are not touched. Always lower(d.state).
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight: the six boundaries must already exist ───────────────────────

DO $$
DECLARE v_b int;
BEGIN
  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0048' AND geo_id LIKE 'fort-wayne-in-council-district-%';
  IF v_b <> 6 THEN
    RAISE EXCEPTION 'IN-3 pre-flight: X0048 holds % Fort Wayne council boundaries, expected 6. Run scripts/load-fort-wayne-council-boundaries.ts first.', v_b;
  END IF;
  -- The citywide seats hang on the TIGER place polygon, which must also be present.
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '1825000' AND mtfcc = 'G4110') THEN
    RAISE EXCEPTION 'IN-3 pre-flight: TIGER place 1825000/G4110 (Fort Wayne) is missing.';
  END IF;
END $$;

-- ─── 1. Government ───────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Fort Wayne, Indiana, US', 'City', 'IN', 'Fort Wayne', '1825000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Fort Wayne, Indiana, US');

-- ─── 2. Three chambers ───────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, v.name, v.name, v.official_count
FROM essentials.governments g
JOIN (VALUES
  ('Fort Wayne Common Council', 9),
  ('Office of the Mayor',       1),
  ('Office of the City Clerk',  1)
) AS v(name, official_count) ON true
WHERE g.name = 'City of Fort Wayne, Indiana, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Seven districts ──────────────────────────────────────────────────────
-- Six council districts on X0048, plus one citywide row on the TIGER place polygon which
-- carries the Mayor, the Clerk and the three at-large council seats (the Columbus/Bradenton
-- convention).

CREATE TEMP TABLE fw_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO fw_districts(geo_id, label, mtfcc) VALUES
  ('fort-wayne-in-council-district-1', 'Fort Wayne City Council District 1', 'X0048'),
  ('fort-wayne-in-council-district-2', 'Fort Wayne City Council District 2', 'X0048'),
  ('fort-wayne-in-council-district-3', 'Fort Wayne City Council District 3', 'X0048'),
  ('fort-wayne-in-council-district-4', 'Fort Wayne City Council District 4', 'X0048'),
  ('fort-wayne-in-council-district-5', 'Fort Wayne City Council District 5', 'X0048'),
  ('fort-wayne-in-council-district-6', 'Fort Wayne City Council District 6', 'X0048'),
  ('1825000',                          'Fort Wayne Citywide',                'G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.label, 'LOCAL', 'in', n.mtfcc
FROM fw_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.district_type = 'LOCAL');

-- ─── 4. Eleven offices ───────────────────────────────────────────────────────

CREATE TEMP TABLE fw_offices(geo_id text, chamber_name text, title text, description text) ON COMMIT DROP;
INSERT INTO fw_offices(geo_id, chamber_name, title, description) VALUES
  ('fort-wayne-in-council-district-1', 'Fort Wayne Common Council', 'Council Member, District 1', NULL),
  ('fort-wayne-in-council-district-2', 'Fort Wayne Common Council', 'Council Member, District 2', NULL),
  ('fort-wayne-in-council-district-3', 'Fort Wayne Common Council', 'Council Member, District 3', NULL),
  ('fort-wayne-in-council-district-4', 'Fort Wayne Common Council', 'Council Member, District 4', NULL),
  ('fort-wayne-in-council-district-5', 'Fort Wayne Common Council', 'Council Member, District 5', NULL),
  ('fort-wayne-in-council-district-6', 'Fort Wayne Common Council', 'Council Member, District 6', NULL),
  -- ⚠ INTERNAL ORDINAL ONLY. Indiana does not number its at-large council seats; all three are
  -- elected in one citywide race. This exists so CC_0091 can attach a person deterministically.
  ('1825000', 'Fort Wayne Common Council', 'Council Member, At Large',
   'Internal ordinal 1 of 3. Fort Wayne does not number its at-large seats; not a ballot designation.'),
  ('1825000', 'Fort Wayne Common Council', 'Council Member, At Large',
   'Internal ordinal 2 of 3. Fort Wayne does not number its at-large seats; not a ballot designation.'),
  ('1825000', 'Fort Wayne Common Council', 'Council Member, At Large',
   'Internal ordinal 3 of 3. Fort Wayne does not number its at-large seats; not a ballot designation.'),
  ('1825000', 'Office of the Mayor',       'Mayor', NULL),
  ('1825000', 'Office of the City Clerk',  'City Clerk', NULL);

INSERT INTO essentials.offices (chamber_id, district_id, title, description, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, n.description, 'IN', 'Fort Wayne', 1, false, 'full'
FROM fw_offices n
JOIN essentials.districts d ON d.geo_id = n.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.governments g ON g.name = 'City of Fort Wayne, Indiana, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = n.title
    AND o.description IS NOT DISTINCT FROM n.description);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off int; v_council int; v_atlarge int; v_unreachable int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'City of Fort Wayne, Indiana, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'IN-3 structure: % Fort Wayne government rows, expected exactly 1', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Fort Wayne, Indiana, US';
  IF v_ch <> 3 THEN RAISE EXCEPTION 'IN-3 structure: % chambers, expected 3', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'LOCAL' AND lower(state) = 'in'
     AND (geo_id LIKE 'fort-wayne-in-council-district-%' OR geo_id = '1825000');
  IF v_dist <> 7 THEN RAISE EXCEPTION 'IN-3 structure: % Fort Wayne districts, expected 7', v_dist; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Fort Wayne, Indiana, US';
  IF v_off <> 11 THEN RAISE EXCEPTION 'IN-3 structure: % offices, expected 11', v_off; END IF;

  SELECT count(*) INTO v_council FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Fort Wayne, Indiana, US' AND c.name = 'Fort Wayne Common Council';
  IF v_council <> 9 THEN RAISE EXCEPTION 'IN-3 structure: % council offices, expected 9', v_council; END IF;

  SELECT count(*) INTO v_atlarge FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Fort Wayne, Indiana, US' AND o.title = 'Council Member, At Large';
  IF v_atlarge <> 3 THEN RAISE EXCEPTION 'IN-3 structure: % at-large offices, expected 3', v_atlarge; END IF;

  -- 🔴 Every Fort Wayne district must have geometry, or its officeholder is invisible at an address.
  SELECT count(*) INTO v_unreachable
  FROM essentials.districts d
  WHERE d.district_type = 'LOCAL' AND lower(d.state) = 'in'
    AND (d.geo_id LIKE 'fort-wayne-in-council-district-%' OR d.geo_id = '1825000')
    AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                     WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_unreachable <> 0 THEN
    RAISE EXCEPTION 'IN-3 structure: % Fort Wayne district(s) have no matching boundary', v_unreachable;
  END IF;

  RAISE NOTICE 'IN-3 structure OK: 1 government, 3 chambers, 7 districts, 11 offices (9 council incl 3 at-large), all districts have geometry';
END $$;

COMMIT;
