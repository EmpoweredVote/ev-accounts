-- =============================================================================
-- Link Monroe County 2026 Primary races to geofence boundaries
--
-- Creates district + office records so races appear via address-based queries
-- (electionService Part A: races → offices → districts → geofence_boundaries).
--
-- Without this, races only show via Part B (statewide) for ALL Indiana users.
-- With this, races are scoped to correct geographic boundaries.
--
-- IDEMPOTENT — safe to re-run. Uses INSERT...WHERE NOT EXISTS patterns.
--
-- Usage: psql $DATABASE_URL -f scripts/link-monroe-county-races-to-geofences.sql
--
-- Run AFTER: seed-monroe-county-2026-primary.sql
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Create districts for geographic areas
--
-- Each district links to a geofence_boundaries record via geo_id.
-- The election query joins: races → offices → districts → geofence_boundaries
-- to determine which races show up for a given address.
-- =============================================================================

-- 1a: Monroe County district (COUNTY type) — for county-wide elected offices
-- Used by: Commissioner, Council, Assessor, Clerk, Recorder, Sheriff, Prosecutor
INSERT INTO essentials.districts (geo_id, district_type, label, state, mtfcc, district_id)
SELECT '18105', 'COUNTY', 'Monroe County', 'IN', 'G4020', '18105-election-county'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '18105' AND district_type = 'COUNTY'
)
AND EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '18105'
);

-- 1b: Monroe County district (JUDICIAL type) — for circuit court judges
INSERT INTO essentials.districts (geo_id, district_type, label, state, mtfcc, district_id)
SELECT '18105', 'JUDICIAL', 'Monroe Circuit Court, 10th Judicial Circuit', 'IN', 'G4020', '18105-election-judicial'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '18105' AND district_type = 'JUDICIAL'
)
AND EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '18105'
);

-- 1c: Township districts — look up geofence by name where geo_id starts with '18105'
-- TIGER county subdivision GEOIDs: state(2) + county(3) + cousub(5) = 10 digits
-- Falls back to county geofence if township boundary not found

-- Helper: create a temp table of township → geo_id mappings
CREATE TEMP TABLE township_geo_map AS
SELECT
  v.township_name,
  COALESCE(
    -- First try: find a dedicated township geofence (cousub MTFCC G4040 or G4210)
    (SELECT gb.geo_id FROM essentials.geofence_boundaries gb
     WHERE gb.name ILIKE v.township_name || '%'
       AND gb.geo_id LIKE '18105%'
       AND gb.mtfcc IN ('G4040', 'G4210')
     LIMIT 1),
    -- Fallback: use county geofence so races at least show for Monroe County
    '18105'
  ) AS geo_id,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM essentials.geofence_boundaries gb
      WHERE gb.name ILIKE v.township_name || '%'
        AND gb.geo_id LIKE '18105%'
        AND gb.mtfcc IN ('G4040', 'G4210')
    ) THEN true
    ELSE false
  END AS has_dedicated_geofence
FROM (VALUES
  ('Bean Blossom'),
  ('Benton'),
  ('Bloomington'),
  ('Clear Creek'),
  ('Indian Creek'),
  ('Perry'),
  ('Polk'),
  ('Richland'),
  ('Salt Creek'),
  ('Van Buren'),
  ('Washington')
) AS v(township_name);

-- Report which townships have dedicated geofences vs. falling back to county
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT * FROM township_geo_map ORDER BY township_name LOOP
    IF r.has_dedicated_geofence THEN
      RAISE NOTICE 'Township % → dedicated geofence (geo_id: %)', r.township_name, r.geo_id;
    ELSE
      RAISE NOTICE 'Township % → FALLBACK to county geofence (18105)', r.township_name;
    END IF;
  END LOOP;
END;
$$;

-- Create district records for each township
INSERT INTO essentials.districts (geo_id, district_type, label, state, mtfcc, district_id)
SELECT
  tgm.geo_id,
  'LOCAL',
  tgm.township_name || ' Township',
  'IN',
  CASE WHEN tgm.has_dedicated_geofence THEN 'G4040' ELSE 'G4020' END,
  'election-twp-' || lower(replace(tgm.township_name, ' ', '-'))
FROM township_geo_map tgm
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.district_id = 'election-twp-' || lower(replace(tgm.township_name, ' ', '-'))
);

-- 1d: Ellettsville district — look up place geofence
-- Ellettsville Census Place FIPS: 1820728 (state 18, place 20728)
INSERT INTO essentials.districts (geo_id, district_type, label, state, mtfcc, district_id)
SELECT
  COALESCE(
    (SELECT gb.geo_id FROM essentials.geofence_boundaries gb
     WHERE gb.name ILIKE 'Ellettsville%'
       AND gb.state = '18'
       AND gb.mtfcc IN ('G4110', 'G4120')
     LIMIT 1),
    -- Fallback to county if Ellettsville place boundary not found
    '18105'
  ),
  'LOCAL',
  'Ellettsville',
  'IN',
  COALESCE(
    (SELECT gb.mtfcc FROM essentials.geofence_boundaries gb
     WHERE gb.name ILIKE 'Ellettsville%'
       AND gb.state = '18'
       AND gb.mtfcc IN ('G4110', 'G4120')
     LIMIT 1),
    'G4020'
  ),
  'election-place-ellettsville'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_id = 'election-place-ellettsville'
);

-- =============================================================================
-- Step 2: Create offices for each race position
--
-- Offices are geographic anchors linking races to districts.
-- politician_id is NULL — these represent contested SEATS, not current holders.
-- =============================================================================

-- Helper: get the election ID
CREATE TEMP TABLE election_ref AS
SELECT id AS election_id
FROM essentials.elections
WHERE name = '2026 Indiana Primary'
  AND election_date = '2026-05-05'
  AND state = 'IN';

-- 2a: County-wide offices (linked to COUNTY district)
-- NOTE: Monroe County Council District 1/2/3/4 moved to 2e (per-district geofences)
-- per Phase 121 to fix the D1→D4 binding bug (all 4 districts previously resolved
-- to the shared county-wide polygon, matching every county address at once).
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, v.title, 'IN', false, false
FROM essentials.districts d,
(VALUES
  ('Monroe County Commissioner District 1'),
  ('Monroe County Assessor'),
  ('Monroe County Clerk'),
  ('Monroe County Recorder'),
  ('Monroe County Sheriff'),
  ('Monroe County Prosecuting Attorney')
) AS v(title)
WHERE d.geo_id = '18105' AND d.district_type = 'COUNTY'
AND NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = v.title
);

-- 2b: Judicial offices (linked to JUDICIAL district)
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, v.title, 'IN', false, false
FROM essentials.districts d,
(VALUES
  ('Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 5'),
  ('Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 9')
) AS v(title)
WHERE d.geo_id = '18105' AND d.district_type = 'JUDICIAL'
AND NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = v.title
);

-- 2c: Township offices (linked to respective township districts)
-- Trustee offices (1 per township that has a trustee race)
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, v.township_name || ' Township Trustee', 'IN', false, false
FROM essentials.districts d
JOIN (VALUES
  ('Bean Blossom',  'election-twp-bean-blossom'),
  ('Benton',        'election-twp-benton'),
  ('Bloomington',   'election-twp-bloomington'),
  ('Clear Creek',   'election-twp-clear-creek'),
  ('Indian Creek',  'election-twp-indian-creek'),
  ('Perry',         'election-twp-perry'),
  ('Polk',          'election-twp-polk'),
  ('Richland',      'election-twp-richland'),
  ('Salt Creek',    'election-twp-salt-creek'),
  ('Van Buren',     'election-twp-van-buren'),
  ('Washington',    'election-twp-washington')
) AS v(township_name, did) ON d.district_id = v.did
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = v.township_name || ' Township Trustee'
);

-- Board offices (1 per township that has a board race)
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, v.township_name || ' Township Board', 'IN', false, false
FROM essentials.districts d
JOIN (VALUES
  ('Benton',        'election-twp-benton'),
  ('Bloomington',   'election-twp-bloomington'),
  ('Clear Creek',   'election-twp-clear-creek'),
  ('Indian Creek',  'election-twp-indian-creek'),
  ('Perry',         'election-twp-perry'),
  ('Richland',      'election-twp-richland'),
  ('Salt Creek',    'election-twp-salt-creek'),
  ('Van Buren',     'election-twp-van-buren'),
  ('Washington',    'election-twp-washington')
) AS v(township_name, did) ON d.district_id = v.did
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = v.township_name || ' Township Board'
);

-- 2d: Ellettsville offices
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, v.title, 'IN', false, false
FROM essentials.districts d,
(VALUES
  ('Ellettsville Town Council Ward 4'),
  ('Ellettsville Town Council Ward 5')
) AS v(title)
WHERE d.district_id = 'election-place-ellettsville'
AND NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = v.title
);

-- 2e: Monroe County Council District offices (per-district geofences)
-- Created by Phase 121 — each MCC District race links to its own polygon
-- (sourced from Monroe County GIS FeatureServer, imported as geo_id='18105-mcc-d{N}'
-- with mtfcc='X-MCC-DIST' by scripts/import-mcc-district-polygons.ts).
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, v.title, 'IN', false, false
FROM essentials.districts d
JOIN (VALUES
  ('Monroe County Council District 1', 'election-mcc-d1'),
  ('Monroe County Council District 2', 'election-mcc-d2'),
  ('Monroe County Council District 3', 'election-mcc-d3'),
  ('Monroe County Council District 4', 'election-mcc-d4')
) AS v(title, did) ON d.district_id = v.did
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = v.title
);

-- =============================================================================
-- Step 3: Link races to offices
--
-- UPDATE each race to set office_id, matching by position_name.
-- This enables the geofence-based address query (Part A in electionService).
-- =============================================================================

-- 3a: County-wide races → county offices
UPDATE essentials.races r
SET office_id = o.id, updated_at = now()
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.geo_id = '18105' AND d.district_type = 'COUNTY'
  AND o.title = r.position_name
  AND r.election_id = (SELECT election_id FROM election_ref)
  AND r.office_id IS NULL;

-- 3b: Judicial races → judicial offices
UPDATE essentials.races r
SET office_id = o.id, updated_at = now()
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.geo_id = '18105' AND d.district_type = 'JUDICIAL'
  AND o.title = r.position_name
  AND r.election_id = (SELECT election_id FROM election_ref)
  AND r.office_id IS NULL;

-- 3c: Township trustee races → township offices
-- Match by position_name (e.g., "Clear Creek Township Trustee" matches office title)
UPDATE essentials.races r
SET office_id = o.id, updated_at = now()
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.district_id LIKE 'election-twp-%'
  AND o.title = r.position_name
  AND r.election_id = (SELECT election_id FROM election_ref)
  AND r.office_id IS NULL;

-- 3d: Township board races → township offices
UPDATE essentials.races r
SET office_id = o.id, updated_at = now()
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.district_id LIKE 'election-twp-%'
  AND o.title = r.position_name
  AND r.election_id = (SELECT election_id FROM election_ref)
  AND r.office_id IS NULL;

-- 3e: Ellettsville races → Ellettsville offices
UPDATE essentials.races r
SET office_id = o.id, updated_at = now()
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.district_id = 'election-place-ellettsville'
  AND o.title = r.position_name
  AND r.election_id = (SELECT election_id FROM election_ref)
  AND r.office_id IS NULL;

-- 3f: Monroe County Council District races → per-district offices
-- First, null out any existing link for the 4 MCC races so the re-link UPDATE
-- below can run. This handles the case where a previous run of this script
-- (before Phase 121's 2a/2e split) linked them to the shared county office.
-- Per Phase 121 Pitfall 5: the r.office_id IS NULL guard in 3a wouldn't fire
-- if the races were already linked.
UPDATE essentials.races r
SET office_id = NULL, updated_at = now()
WHERE r.position_name LIKE 'Monroe County Council District%'
  AND r.election_id = (SELECT election_id FROM election_ref);

-- Now link each of the 4 council district races to its per-district office.
UPDATE essentials.races r
SET office_id = o.id, updated_at = now()
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.district_id LIKE 'election-mcc-d%'
  AND o.title = r.position_name
  AND r.election_id = (SELECT election_id FROM election_ref)
  AND r.office_id IS NULL;

-- =============================================================================
-- Step 4: Verification
-- =============================================================================

-- Report linked vs. unlinked races
DO $$
DECLARE
  linked INT;
  unlinked INT;
  total INT;
  r RECORD;
BEGIN
  SELECT COUNT(*) INTO total
  FROM essentials.races WHERE election_id = (SELECT election_id FROM election_ref);

  SELECT COUNT(*) INTO linked
  FROM essentials.races WHERE election_id = (SELECT election_id FROM election_ref) AND office_id IS NOT NULL;

  unlinked := total - linked;

  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'LINKING RESULTS';
  RAISE NOTICE '  Total races:    %', total;
  RAISE NOTICE '  Linked:         % (address-scoped)', linked;
  RAISE NOTICE '  Unlinked:       % (statewide fallback)', unlinked;
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

  IF unlinked > 0 THEN
    RAISE NOTICE 'Unlinked races:';
    FOR r IN
      SELECT position_name, primary_party
      FROM essentials.races
      WHERE election_id = (SELECT election_id FROM election_ref) AND office_id IS NULL
      ORDER BY position_name
    LOOP
      RAISE NOTICE '  - % (%)', r.position_name, COALESCE(r.primary_party, 'general');
    END LOOP;
  END IF;
END;
$$;

-- Cleanup temp tables
DROP TABLE IF EXISTS township_geo_map;
DROP TABLE IF EXISTS election_ref;

COMMIT;

-- =============================================================================
-- Post-run verification queries:
--
-- Check linked races:
--   SELECT r.position_name, r.primary_party, d.label AS district, d.district_type, d.geo_id
--   FROM essentials.races r
--   JOIN essentials.offices o ON o.id = r.office_id
--   JOIN essentials.districts d ON d.id = o.district_id
--   JOIN essentials.elections e ON r.election_id = e.id
--   WHERE e.name = '2026 Indiana Primary'
--   ORDER BY d.district_type, r.position_name;
--
-- Check unlinked races (still using statewide fallback):
--   SELECT r.position_name, r.primary_party
--   FROM essentials.races r
--   JOIN essentials.elections e ON r.election_id = e.id
--   WHERE e.name = '2026 Indiana Primary' AND r.office_id IS NULL;
--
-- Test address lookup:
--   SELECT r.position_name, r.primary_party, rc.full_name
--   FROM essentials.elections e
--   JOIN essentials.races r ON r.election_id = e.id
--   JOIN essentials.race_candidates rc ON rc.race_id = r.id
--   JOIN essentials.offices o ON o.id = r.office_id
--   JOIN essentials.districts d ON d.id = o.district_id
--   JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
--   WHERE e.name = '2026 Indiana Primary'
--     AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-86.5264, 39.1653), 4326))
--   ORDER BY r.position_name;
-- =============================================================================
