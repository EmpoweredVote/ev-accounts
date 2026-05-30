-- =============================================================================
-- Migration 114: Set geo_id on LA City and LA County government rows
--
-- Purpose: Enables the browse-by-government-list endpoint to find City of LA
-- and LA County officials without relying on PostGIS geofence intersection.
--
-- Background: LA City Council members use OCD-division IDs for their district
-- geo_ids (e.g. ocd-division/.../council_district:2). These are not in
-- essentials.geofence_boundaries, so browse-by-area cannot find them via the
-- PostGIS intersection cascade. Setting geo_id on the government rows lets
-- browse-by-government-list fetch all officials for these governments directly.
--
-- LA City government geo_id: '0644000' (Census FIPS place code for City of LA)
-- LA County government geo_id: '06037' (Census FIPS county code for LA County)
--
-- Safe to re-run — WHERE clause guards against overwriting existing values.
-- =============================================================================

BEGIN;

-- City of Los Angeles: set geo_id = '0644000' (Census FIPS place code)
UPDATE essentials.governments
SET geo_id = '0644000'
WHERE name = 'Los Angeles, California, US'
  AND (geo_id IS NULL OR geo_id = '');

-- Los Angeles County: set geo_id = '06037' (Census FIPS county code)
UPDATE essentials.governments
SET geo_id = '06037'
WHERE name = 'Los Angeles County, California, US'
  AND (geo_id IS NULL OR geo_id = '');

-- LA Unified School District: set geo_id = '0622710' (Census unified school district GEOID)
UPDATE essentials.governments
SET geo_id = '0622710'
WHERE name = 'Los Angeles Unified, California, US'
  AND (geo_id IS NULL OR geo_id = '');

COMMIT;
