-- =============================================================================
-- Fix: Salt Lake County Council District motif (blank map → county-framed district)
--
-- Symptom (read-rank hub): "Salt Lake County Council District 5" renders the
-- dot-field placeholder instead of a map. The live /api/readrank/races payload
-- returns boundaryRef:null and scope:"county" for this race — scope:"county"
-- only happens via the position-name fallback, which proves d.mtfcc is NULL,
-- i.e. the race is not resolving to its council-district geofence at all.
--
-- Root cause (two parts):
--   3a (DATA, this script): the council-district races were seeded with
--       office_id = NULL (see seed-ut-2026-06-23-primary-slco.sql lines 60-63,
--       "District-specific office_id backfill is a follow-up task"). Until the
--       race points at its council-district office → district → X0001 geofence,
--       getPlayableRaces() has no mtfcc/geo_id to resolve.
--   3b (CODE, already landed in readrankService.ts): once mtfcc=X0001 resolves,
--       the frame for an X% layer is chosen by district_type — 'COUNTY' frames
--       to the county (G4020), anything else frames to the city (G4110). SLCo
--       council districts and SLC city wards SHARE mtfcc='X0001' (verified in
--       verify-ut-arcgis-import.sql GEO-03/GEO-04), so district_type is the ONLY
--       discriminator. This script guarantees district_type='COUNTY' on them.
--
-- The geofence geometry already exists (X0001, geo_id
--   ocd-division/country:us/state:ut/county:salt_lake/council_district:{1,3,5}).
--
-- Office IDs (from fix-sl-council-district-race-office-ids.sql, verified prior session):
--   District 1 → d490589b-1205-4d39-8515-a73892b39232
--   District 3 → 6e10fb50-0d39-4793-83cb-65bc02f4131e
--   District 5 → fec9ad7c-7f7d-4d2c-b39f-0f4cedeba493
--
-- Idempotent. Usage:
--   1. Run STEP 0 (diagnostics) FIRST and read the output — it tells you exactly
--      where the chain breaks before you change anything.
--   2. If diagnostics confirm the gap, run STEP 1–3 (wrapped in one transaction).
--   3. Run STEP 4 to verify, then re-fetch /api/readrank/races to confirm the map.
--
--   psql "$DATABASE_URL" -f scripts/fix-slco-council-district-motif-2026.sql
-- =============================================================================

\set ON_ERROR_STOP on

-- -----------------------------------------------------------------------------
-- STEP 0 — DIAGNOSE (read-only). Run this first.
-- -----------------------------------------------------------------------------
\echo '=== STEP 0a: current race → office → district chain ==='
SELECT r.position_name,
       r.primary_party,
       r.office_id,
       o.id              AS office_id_join,
       d.id              AS district_id,
       d.mtfcc,
       d.geo_id,
       d.district_type
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.offices o   ON o.id = r.office_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE e.state = 'UT'
  AND r.position_name LIKE 'Salt Lake County Council District%'
ORDER BY r.position_name, r.primary_party;

\echo '=== STEP 0b: do the matching X0001 geofences exist? (expect 3 rows: cd 1,3,5) ==='
SELECT mtfcc, geo_id, name
FROM essentials.geofence_boundaries
WHERE mtfcc = 'X0001'
  AND geo_id LIKE 'ocd-division/country:us/state:ut/county:salt_lake/council_district:%'
ORDER BY geo_id;

BEGIN;

-- -----------------------------------------------------------------------------
-- STEP 1 — Link each council-district race to its specific office.
--          (Same effect as fix-sl-council-district-race-office-ids.sql.)
-- -----------------------------------------------------------------------------
\echo '=== STEP 1: link races to council-district offices ==='
UPDATE essentials.races r
SET office_id = mapping.office_id::uuid,
    updated_at = now()
FROM essentials.elections e,
(VALUES
  ('Salt Lake County Council District 1', 'd490589b-1205-4d39-8515-a73892b39232'),
  ('Salt Lake County Council District 3', '6e10fb50-0d39-4793-83cb-65bc02f4131e'),
  ('Salt Lake County Council District 5', 'fec9ad7c-7f7d-4d2c-b39f-0f4cedeba493')
) AS mapping(position_name, office_id)
WHERE r.election_id = e.id
  AND e.state = 'UT'
  AND r.position_name = mapping.position_name
  AND r.office_id IS DISTINCT FROM mapping.office_id::uuid;

-- -----------------------------------------------------------------------------
-- STEP 2 — Ensure the linked districts carry mtfcc/geo_id pointing at the
--          X0001 council-district geofence. Only fills NULLs — never clobbers a
--          value that's already set. Skip/adjust if STEP 0a already shows the
--          correct mtfcc='X0001' + geo_id.
-- -----------------------------------------------------------------------------
\echo '=== STEP 2: backfill district mtfcc/geo_id where missing ==='
UPDATE essentials.districts d
SET mtfcc  = 'X0001',
    geo_id = m.geo_id
FROM essentials.offices o
JOIN essentials.races r    ON r.office_id = o.id
JOIN essentials.elections e ON e.id = r.election_id
JOIN (VALUES
  ('Salt Lake County Council District 1', 'ocd-division/country:us/state:ut/county:salt_lake/council_district:1'),
  ('Salt Lake County Council District 3', 'ocd-division/country:us/state:ut/county:salt_lake/council_district:3'),
  ('Salt Lake County Council District 5', 'ocd-division/country:us/state:ut/county:salt_lake/council_district:5')
) AS m(position_name, geo_id) ON m.position_name = r.position_name
WHERE o.district_id = d.id
  AND e.state = 'UT'
  AND (d.mtfcc IS NULL OR d.geo_id IS NULL)
  -- Safety: the target geofence must actually exist before we point at it.
  AND EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries gb
    WHERE gb.mtfcc = 'X0001' AND gb.geo_id = m.geo_id
  );

-- -----------------------------------------------------------------------------
-- STEP 3 — Ensure district_type='COUNTY' so 3b frames these to the county
--          (G4020), NOT to a containing city. Scoped to the county-council
--          OCD geo_id so SLC *city wards* (also X0001) are never touched.
-- -----------------------------------------------------------------------------
\echo '=== STEP 3: set district_type=COUNTY on council districts ==='
UPDATE essentials.districts d
SET district_type = 'COUNTY'
FROM essentials.offices o
JOIN essentials.races r    ON r.office_id = o.id
JOIN essentials.elections e ON e.id = r.election_id
WHERE o.district_id = d.id
  AND e.state = 'UT'
  AND r.position_name LIKE 'Salt Lake County Council District%'
  AND d.geo_id LIKE 'ocd-division/country:us/state:ut/county:salt_lake/council_district:%'
  AND d.district_type IS DISTINCT FROM 'COUNTY';

COMMIT;

-- -----------------------------------------------------------------------------
-- STEP 4 — VERIFY. Expect, for each council district race:
--   mtfcc='X0001', geo_id=ocd-.../council_district:N, district_type='COUNTY',
--   geofence_exists=t.  (boundaryRef → {X0001, geo_id}; frameRef → Salt Lake
--   County G4020 49035 via the readrankService LATERAL containment query.)
-- -----------------------------------------------------------------------------
\echo '=== STEP 4: verification ==='
SELECT r.position_name,
       d.mtfcc,
       d.geo_id,
       d.district_type,
       (SELECT true FROM essentials.geofence_boundaries gb
         WHERE gb.mtfcc = d.mtfcc AND gb.geo_id = d.geo_id) AS geofence_exists
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.offices o   ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
WHERE e.state = 'UT'
  AND r.position_name LIKE 'Salt Lake County Council District%'
ORDER BY r.position_name, r.primary_party;
