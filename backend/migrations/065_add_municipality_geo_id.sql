-- Migration 065: Add municipality_geo_id column to connect.connected_profiles
--
-- Purpose: Stores the geo_id of the incorporated place (city boundary) for
-- users whose coordinates fall inside a city. This is the LOCAL_EXEC district
-- geo_id (e.g. '0644000' for City of Los Angeles). When included in the geoIds
-- array passed to getElectionsByGeoIds, citywide offices (City Attorney, City
-- Controller, City Clerk) surface for residents of that city.
--
-- This column is distinct from city_council_geo_id (which stores the specific
-- council ward/district). municipality_geo_id is the city-wide boundary.
--
-- Idempotency: ADD COLUMN IF NOT EXISTS is safe to re-run.

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS municipality_geo_id TEXT DEFAULT NULL;
