-- =============================================================================
-- Migration 087: Add geo_id to governments + seed TX state and Collin County
--
-- geo_id stores the Census/FIPS identifier at the government level.
-- Texas state FIPS: 48
-- Collin County FIPS: 48085
--
-- This migration is the foundation for Phase 12 TX DB Foundation.
-- All city government rows (Phase 12 plans 02-04) depend on this running first.
-- =============================================================================

BEGIN;

-- Add geo_id column if it does not already exist
ALTER TABLE essentials.governments
  ADD COLUMN IF NOT EXISTS geo_id TEXT;

COMMENT ON COLUMN essentials.governments.geo_id IS
  'Census/FIPS geographic identifier. State: 2-digit (e.g. 48). County: 5-digit (e.g. 48085). City: 7-digit place GEOID (e.g. 4863000).';

-- Texas state government
INSERT INTO essentials.governments (name, type, state, city, geo_id)
VALUES ('State of Texas', 'STATE', 'TX', '', '48');

-- Collin County government
INSERT INTO essentials.governments (name, type, state, city, geo_id)
VALUES ('Collin County, Texas, US', 'County', 'TX', NULL, '48085');

COMMIT;
