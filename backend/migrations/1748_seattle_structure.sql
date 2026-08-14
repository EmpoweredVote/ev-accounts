-- 1748_seattle_structure.sql
-- City of Seattle: government + 3 chambers + 11 offices.
--
-- Seattle is a MAYOR-COUNCIL (strong mayor) city. The Mayor is DIRECTLY ELECTED,
-- not selected by the council from its own members, so the Mayor is LOCAL_EXEC
-- and seated above the council count — the Boston/Long Beach pattern, not the
-- Cambridge rotational-mayor pattern. Seattle also ELECTS its City Attorney.
--
-- geo_id 5363000 confirmed against the loaded TIGER place layer, not estimated.
--
-- DISTRICTS
--   7 council districts on the X0025 geofences (loaded by
--   scripts/load-seattle-council-boundaries.ts from SCCDST_AREA_2237 — the
--   unsuffixed CURRENT layer; SCCDST_2015_AREA_3044 is the historic pre-
--   redistricting map and would load without error).
--   Citywide seats (Mayor, City Attorney, Council Positions 8 and 9) attach to
--   two citywide district rows on geo_id 5363000 / mtfcc G4110: one LOCAL_EXEC
--   for the two executive offices and one LOCAL for the two at-large council
--   seats. Splitting by district_type keeps the executive offices from being
--   returned as council seats.
--
-- TITLES follow Seattle's own usage (citizen-experience-first): "Councilmember"
-- as ONE word, district seats as "Councilmember, District N", and the at-large
-- pair as "Councilmember, Position 8 (Citywide)" / "Position 9 (Citywide)".
-- The City Clerk formally lists these as "Position 1: District 1" through
-- "Position 7: District 7" and "Position 8/9: At-large".
--
-- chambers.slug is a GENERATED column derived from name_formal — do not insert.
--
-- Idempotency: NOT EXISTS throughout.

-- ─── Government ──────────────────────────────────────────────────────────────

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Seattle, Washington, US', 'City', 'WA', 'Seattle', '5363000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '5363000' AND type = 'City'
);

-- ─── District rows ───────────────────────────────────────────────────────────

-- 7 council districts on the X0025 geofences.
INSERT INTO essentials.districts (id, geo_id, label, district_type, state, mtfcc)
SELECT gen_random_uuid(), gb.geo_id,
       'Seattle City Council District ' || right(gb.geo_id, 1),
       'LOCAL', 'wa', 'X0025'
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc = 'X0025'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.districts d WHERE d.geo_id = gb.geo_id AND d.mtfcc = 'X0025'
  );

-- Citywide executive district (Mayor, City Attorney).
INSERT INTO essentials.districts (id, geo_id, label, district_type, state, mtfcc)
SELECT gen_random_uuid(), '5363000', 'City of Seattle', 'LOCAL_EXEC', 'wa', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '5363000' AND district_type = 'LOCAL_EXEC' AND mtfcc = 'G4110'
);

-- Citywide council district (Positions 8 and 9).
INSERT INTO essentials.districts (id, geo_id, label, district_type, state, mtfcc)
SELECT gen_random_uuid(), '5363000', 'Seattle Citywide (At-large)', 'LOCAL', 'wa', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '5363000' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
);

-- ─── Chambers ────────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, v.name, v.name_formal, v.official_count, v.term_length, v.staggered, v.pel::essentials.policy_engagement_level
FROM essentials.governments g
CROSS JOIN (VALUES
  ('Mayor',        'Seattle Mayor',        1, 4, false, 'full'),
  ('City Council', 'Seattle City Council', 9, 4, true,  'full'),
  ('City Attorney','Seattle City Attorney',1, 4, false, 'full')
) AS v(name, name_formal, official_count, term_length, staggered, pel)
WHERE g.geo_id = '5363000' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name
  );

-- ─── Citywide offices: Mayor, City Attorney ──────────────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, is_appointed_position)
SELECT c.id, d.id, v.title, 'WA', 'Seattle', false
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id
JOIN (VALUES ('Mayor', 'Mayor'), ('City Attorney', 'City Attorney')) AS v(chamber_name, title)
  ON c.name = v.chamber_name
CROSS JOIN essentials.districts d
WHERE g.geo_id = '5363000' AND g.type = 'City'
  AND d.geo_id = '5363000' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = v.title
  );

-- ─── Council district seats 1-7 ──────────────────────────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, is_appointed_position)
SELECT c.id, d.id,
       'Councilmember, District ' || right(d.geo_id, 1),
       'WA', 'Seattle', false
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'City Council'
JOIN essentials.districts d ON d.mtfcc = 'X0025' AND d.district_type = 'LOCAL'
WHERE g.geo_id = '5363000' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.title = 'Councilmember, District ' || right(d.geo_id, 1)
  );

-- ─── At-large council seats: Positions 8 and 9 ───────────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, is_appointed_position)
SELECT c.id, d.id, v.title, 'WA', 'Seattle', false
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'City Council'
CROSS JOIN essentials.districts d
CROSS JOIN (VALUES
  ('Councilmember, Position 8 (Citywide)'),
  ('Councilmember, Position 9 (Citywide)')
) AS v(title)
WHERE g.geo_id = '5363000' AND g.type = 'City'
  AND d.geo_id = '5363000' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = v.title
  );
