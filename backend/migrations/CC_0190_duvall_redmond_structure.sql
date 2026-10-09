-- CC_0190_duvall_redmond_structure.sql
-- Duvall + Redmond WA deep seed, wave 1 (structure half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0191, which seats all 16 officials.
--
-- Creates 2 governments, 4 chambers, 4 districts and 16 offices.
-- Creates NO people and NO terms.
--
-- Roster and every citation: backend/data/seed-duvall-redmond-2026/ROSTERS.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THERE IS NO GEOGRAPHY LOAD IN THIS WAVE, AND THAT IS NOT AN OVERSIGHT.
-- load-state-tiger-boundaries.ts already carries WA: new Set(['place','sldu','sldl']), so both
-- city polygons are in essentials.geofence_boundaries from census_tiger_2024 and were verified
-- with PostGIS on 2026-10-06, not trusted from a loader count:
--
--   5319035 / G4110  Duvall city    ST_Polygon        6.40 km2  (published 2.47 sq mi)
--   5357535 / G4110  Redmond city   ST_MultiPolygon  44.65 km2  (published 17.2 sq mi)
--
--   Duvall City Hall  (-121.9857, 47.7423) -> inside Duvall,  OUTSIDE Redmond
--   Redmond City Hall (-122.1215, 47.6740) -> inside Redmond, OUTSIDE Duvall
--   Chicago control   ( -87.6298, 41.8781) -> inside NEITHER
--
-- The pre-flight below refuses to run if either polygon has gone away. An office on a district
-- with no polygon is unreachable by any address and NOTHING ERRORS.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 NEITHER CITY HAS WARDS. All 14 councilmembers are elected AT LARGE by numbered position, so
-- every council office hangs on the one citywide LOCAL district. The position number is part of
-- the office title, not a district — the same shape as Bainbridge Island, already seeded.
--
-- 🔴 NEITHER CITY ELECTS A MUNICIPAL COURT JUDGE, and that is a measured absence. 52 distinct
-- city contests were read across SIX certified King County cycles (2015, 2017, 2019, 2021, 2023,
-- 2025); none is judicial. Positive control: the same scan finds "Municipal Court Judge" contests
-- in the SAME 2025 file for Federal Way, Kent, Kirkland and Renton, so the detector works. There
-- is also no District Name variant for either city. 16 seats, not 17 or 18.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 BOTH MAYORS ARE voting_powers = 'non_voting', NOT 'full'.
--
-- Both cities are non-charter code cities under RCW 35A.12 — Redmond says so in its Council Rules
-- of Procedure, Duvall in its Council Procedures (Res 26-02). So RCW 35A.12.100 governs:
--
--   "The mayor shall preside over all meetings of the city council, when present, but shall have
--    a vote only in the case of a tie in the votes of the councilmembers with respect to matters
--    other than the passage of any ordinance, grant, or revocation of franchise or license, or
--    any resolution for the payment of money."
--
-- The discriminator already settled in this database is whether the office PRESIDES over the
-- legislative body, not whether it is an executive:
--   presides, tie-break only -> non_voting + required note : Columbus GA Mayor, Macon-Bibb GA
--                                                            Mayor, Nashville Vice Mayor
--   does not preside         -> full                       : Seattle Mayor, Nashville Mayor,
--                                                            St. Louis Mayor, King County Executive
-- A WA code-city mayor presides, so these two join the first group.
--
-- representation_note is REQUIRED by the CHECK whenever voting_powers <> 'full', and the read path
-- must not render either Mayor without it. Both notes below name the statute and both carve-outs.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 COUNCIL PRESIDENT, COUNCIL VICE PRESIDENT AND MAYOR PRO TEMPORE GET NO OFFICE ROW.
-- Redmond elects a President and a Vice-President "from its members" biennially; Duvall's
-- councilmembers "nominate and elect one of their peers" as Mayor Pro Tempore, who "will retain
-- their Councilmember voting privileges". All three are board roles held BY a seated member, not
-- separately elected seats. Creating an office for one would invent a seat and double-count its
-- holder. This follows the Asheville Vice Mayor precedent.
--
-- 🟢 OCD IDS ARE THE REGISTRY'S OWN, looked up in opencivicdata/ocd-division-ids rather than
-- composed. Both rows carry the very place id this migration uses, which is a free cross-check:
--   ocd-division/country:us/state:wa/place:duvall  ,Duvall city ,...,place-5319035
--   ocd-division/country:us/state:wa/place:redmond ,Redmond city,...,place-5357535
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 0. Refuse to run without the geography ───────────────────────────────────

DO $$
DECLARE v_duvall int; v_redmond int;
BEGIN
  SELECT count(*) INTO v_duvall
    FROM essentials.geofence_boundaries WHERE geo_id = '5319035' AND mtfcc = 'G4110';
  SELECT count(*) INTO v_redmond
    FROM essentials.geofence_boundaries WHERE geo_id = '5357535' AND mtfcc = 'G4110';
  IF v_duvall <> 1 THEN
    RAISE EXCEPTION 'WA-1 pre-flight: place 5319035/G4110 (Duvall) is not loaded — every Duvall seat would be unreachable by any address and nothing would error';
  END IF;
  IF v_redmond <> 1 THEN
    RAISE EXCEPTION 'WA-1 pre-flight: place 5357535/G4110 (Redmond) is not loaded — every Redmond seat would be unreachable by any address and nothing would error';
  END IF;
END $$;

-- ─── 1. The two governments ───────────────────────────────────────────────────
-- 🔴 geo_id AND mtfcc are both set here, at creation. A city can be fully seeded, answer every
-- address, and still be INVISIBLE on the landing page, because a landing chip is keyed on
-- governments.geo_id, which address search never touches. The key is the (mtfcc, geo_id) PAIR —
-- geo_id alone collides across states.

INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT v.name, 'City', 'WA', v.city, v.geo_id, 'G4110'
FROM (VALUES
  ('City of Duvall, Washington, US',  'Duvall',  '5319035'),
  ('City of Redmond, Washington, US', 'Redmond', '5357535')
) AS v(name, city, geo_id)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments g WHERE g.geo_id = v.geo_id AND g.mtfcc = 'G4110');

-- ─── 2. The four chambers ─────────────────────────────────────────────────────
-- Shaped after Seattle and Bainbridge Island, the two WA cities already seeded: a "City Council"
-- for the legislature and a "Mayor" chamber for the separately elected executive.

-- NOTE: chambers.slug is a GENERATED column — inserting it raises 428C9. Do not add it back.
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length, staggered_term)
SELECT g.id, v.name, v.name_formal, v.n, '4', v.staggered
FROM essentials.governments g
JOIN (VALUES
  ('5319035', 'City Council', 'Duvall City Council',  7, true ),
  ('5319035', 'Mayor',        'Duvall Mayor',         1, false),
  ('5357535', 'City Council', 'Redmond City Council', 7, true ),
  ('5357535', 'Mayor',        'Redmond Mayor',        1, false)
) AS v(geo_id, name, name_formal, n, staggered) ON v.geo_id = g.geo_id
WHERE g.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. The four citywide districts ───────────────────────────────────────────
-- Two per city on the SAME place polygon: LOCAL carries the at-large council seats, LOCAL_EXEC
-- carries the Mayor. This is the Seattle and St. Louis shape.

INSERT INTO essentials.districts (geo_id, mtfcc, label, district_type, state, ocd_id, representation_basis)
SELECT v.geo_id, 'G4110', v.label, v.dt, 'wa', v.ocd_id, 'residency'
FROM (VALUES
  ('5319035', 'Duvall Citywide (At-large)',  'LOCAL',      'ocd-division/country:us/state:wa/place:duvall'),
  ('5319035', 'City of Duvall',              'LOCAL_EXEC', 'ocd-division/country:us/state:wa/place:duvall'),
  ('5357535', 'Redmond Citywide (At-large)', 'LOCAL',      'ocd-division/country:us/state:wa/place:redmond'),
  ('5357535', 'City of Redmond',             'LOCAL_EXEC', 'ocd-division/country:us/state:wa/place:redmond')
) AS v(geo_id, label, dt, ocd_id)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = v.geo_id AND d.mtfcc = 'G4110' AND d.district_type::text = v.dt);

-- ─── 4. The 14 at-large council offices ───────────────────────────────────────
-- Position number lives in the TITLE, because the seat is citywide — there is no Position-N
-- district to hang it on. Bainbridge Island is titled the same way.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, is_vacant, voting_powers)
SELECT c.id, d.id, 'Councilmember, Position ' || n, 'WA', g.city, false, 'full'
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'City Council'
JOIN essentials.districts d ON d.geo_id = g.geo_id AND d.mtfcc = 'G4110' AND d.district_type::text = 'LOCAL'
CROSS JOIN generate_series(1, 7) AS n
WHERE g.geo_id IN ('5319035','5357535') AND g.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
     WHERE o.chamber_id = c.id AND o.title = 'Councilmember, Position ' || n);

-- ─── 5. The two Mayor offices ─────────────────────────────────────────────────
-- 🔴 non_voting + a required representation_note. See the header for why.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, is_vacant, voting_powers, representation_note)
SELECT c.id, d.id, 'Mayor', 'WA', g.city, false, 'non_voting', v.note
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Mayor'
JOIN essentials.districts d ON d.geo_id = g.geo_id AND d.mtfcc = 'G4110' AND d.district_type::text = 'LOCAL_EXEC'
JOIN (VALUES
  ('5319035',
   'The Mayor of Duvall is elected citywide and presides over the seven-member Duvall City Council. Under RCW 35A.12.100 the Mayor has a vote only in the case of a tie in the votes of the councilmembers, and has no vote at all on the passage of an ordinance, the grant or revocation of a franchise or licence, or a resolution for the payment of money. Duvall is a non-charter code city with a strong-mayor form of government, so the Mayor is also its chief executive, in charge of all departments and employees. The Mayor may veto an ordinance, and the Council may override that veto by a majority of all councilmembers plus one more vote. If the office of Mayor becomes vacant, the Mayor Pro Tempore acts as Mayor until the vacancy is filled at the next general election.'),
  ('5357535',
   'The Mayor of Redmond is elected citywide and presides over the seven-member Redmond City Council. Under RCW 35A.12.100 the Mayor has a vote only in the case of a tie in the votes of the councilmembers, and has no vote at all on the passage of an ordinance, the grant or revocation of a franchise or licence, or a resolution for the payment of money. Redmond is a non-charter code city with a strong-mayor form of government, so the Mayor is also its chief executive, in charge of all departments and employees. The Mayor may veto an ordinance, and the Council may override that veto by a majority of all councilmembers plus one more vote. The Council President acts as Mayor Pro Tem and presides at business meetings in the Mayor''s absence.')
) AS v(geo_id, note) ON v.geo_id = g.geo_id
WHERE g.mtfcc = 'G4110'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = 'Mayor');

-- ─── 6. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_cham int; v_dist int; v_off int; v_council int; v_mayor int;
  v_unreach int; v_outside int; v_vac int; v_note int; v_dupe int; v_ocd int; v_nogeoid int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE geo_id IN ('5319035','5357535') AND mtfcc = 'G4110';
  IF v_gov <> 2 THEN RAISE EXCEPTION 'WA-1 gate: expected 2 governments, got %', v_gov; END IF;

  -- 🔴 Both halves of the landing key. A NULL mtfcc or geo_id makes the city unreachable from
  -- any browse URL while every address still resolves — invisible, with nothing erroring.
  SELECT count(*) INTO v_nogeoid FROM essentials.governments
   WHERE name IN ('City of Duvall, Washington, US','City of Redmond, Washington, US')
     AND (geo_id IS NULL OR mtfcc IS NULL);
  IF v_nogeoid <> 0 THEN RAISE EXCEPTION 'WA-1 gate: % government(s) missing geo_id or mtfcc', v_nogeoid; END IF;

  SELECT count(*) INTO v_cham FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND g.mtfcc = 'G4110';
  IF v_cham <> 4 THEN RAISE EXCEPTION 'WA-1 gate: expected 4 chambers, got %', v_cham; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE geo_id IN ('5319035','5357535') AND mtfcc = 'G4110'
     AND district_type::text IN ('LOCAL','LOCAL_EXEC');
  IF v_dist <> 4 THEN RAISE EXCEPTION 'WA-1 gate: expected 4 districts, got %', v_dist; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND g.mtfcc = 'G4110';
  IF v_off <> 16 THEN RAISE EXCEPTION 'WA-1 gate: expected 16 offices, got %', v_off; END IF;

  -- 7 council seats and 1 mayor in EACH city, not 14 and 2 lopsided across the two
  SELECT count(*) INTO v_council FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id AND c.name = 'City Council'
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '5319035' AND o.title LIKE 'Councilmember, Position %';
  IF v_council <> 7 THEN RAISE EXCEPTION 'WA-1 gate: Duvall has % council offices, expected 7', v_council; END IF;
  SELECT count(*) INTO v_council FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id AND c.name = 'City Council'
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '5357535' AND o.title LIKE 'Councilmember, Position %';
  IF v_council <> 7 THEN RAISE EXCEPTION 'WA-1 gate: Redmond has % council offices, expected 7', v_council; END IF;

  -- 🔴 Both Mayors must be non_voting AND carry a note. 'full' would tell a voter their mayor
  -- votes on ordinances, which RCW 35A.12.100 says they cannot.
  SELECT count(*) INTO v_mayor FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND o.title = 'Mayor'
     AND o.voting_powers = 'non_voting'
     AND o.representation_note IS NOT NULL
     AND o.representation_note LIKE '%RCW 35A.12.100%';
  IF v_mayor <> 2 THEN
    RAISE EXCEPTION 'WA-1 gate: expected 2 Mayor offices that are non_voting AND cite RCW 35A.12.100 in representation_note, got %', v_mayor;
  END IF;

  -- 🔴 THE ASSERTION THAT ACTUALLY MATTERS: every district this wave created must have a polygon.
  SELECT count(*) INTO v_unreach FROM essentials.districts d
   WHERE d.geo_id IN ('5319035','5357535') AND d.mtfcc = 'G4110'
     AND d.district_type::text IN ('LOCAL','LOCAL_EXEC')
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_unreach <> 0 THEN
    RAISE EXCEPTION 'WA-1 gate: % district(s) have NO geofence boundary — their offices would be unreachable by any address', v_unreach;
  END IF;

  SELECT count(*) INTO v_outside FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND lower(g.state) <> 'wa';
  IF v_outside <> 0 THEN RAISE EXCEPTION 'WA-1 gate: % office(s) outside Washington', v_outside; END IF;

  -- Occupancy is CC_0191's business. Nothing here is flagged vacant.
  SELECT count(*) INTO v_vac FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND o.is_vacant IS true;
  IF v_vac <> 0 THEN RAISE EXCEPTION 'WA-1 gate: expected 0 vacant flags, found %', v_vac; END IF;

  -- ADR 0003: any seat that is not full/residency REQUIRES a note. The 14 council seats are
  -- full/residency; the 2 Mayors are non_voting and were just checked to carry one.
  SELECT count(*) INTO v_note FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.geo_id IN ('5319035','5357535')
     AND (o.voting_powers <> 'full' OR d.representation_basis::text <> 'residency')
     AND o.representation_note IS NULL;
  IF v_note <> 0 THEN RAISE EXCEPTION 'WA-1 gate: % seat(s) need a representation_note and have none', v_note; END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT o.chamber_id, o.title FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.geo_id IN ('5319035','5357535')
     GROUP BY 1,2 HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'WA-1 gate: % duplicate (chamber, title)', v_dupe; END IF;

  SELECT count(*) INTO v_ocd FROM essentials.districts d
   WHERE d.geo_id IN ('5319035','5357535') AND d.mtfcc = 'G4110'
     AND d.district_type::text IN ('LOCAL','LOCAL_EXEC')
     AND d.ocd_id NOT IN ('ocd-division/country:us/state:wa/place:duvall',
                          'ocd-division/country:us/state:wa/place:redmond');
  IF v_ocd <> 0 THEN RAISE EXCEPTION 'WA-1 gate: % district(s) carry an unregistered ocd_id', v_ocd; END IF;

  RAISE NOTICE 'WA-1 structure gate PASSED: 2 governments (geo_id + mtfcc both set), 4 chambers, 4 districts, 16 offices (7+1 Duvall, 7+1 Redmond), every district has a polygon, 0 outside Washington, 0 vacant flags, both Mayors non_voting with an RCW 35A.12.100 note, ocd_ids from the registry.';
END $$;

COMMIT;
