-- Phase 49: Add 12 jurisdiction columns to connect.connected_profiles
-- Enables stored jurisdiction cross-app location profile

-- Add 12 jurisdiction columns to connect.connected_profiles
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS congressional_geo_id TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS congressional_district_name TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS state_senate_geo_id TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS state_senate_district_name TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS state_house_geo_id TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS state_house_district_name TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS county_geo_id TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS county_name TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS school_district_geo_id TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS school_district_name TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS jurisdiction_state TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS jurisdiction_city TEXT DEFAULT NULL;

-- Backfill existing users with location consent
-- resolve_user_jurisdiction returns jsonb with keys:
-- congressional, congressional_name, state_senate, state_senate_name,
-- state_house, state_house_name, county, county_name, school_district, school_district_name
UPDATE connect.connected_profiles cp
SET
  congressional_geo_id        = (j->>'congressional'),
  congressional_district_name = (j->>'congressional_name'),
  state_senate_geo_id         = (j->>'state_senate'),
  state_senate_district_name  = (j->>'state_senate_name'),
  state_house_geo_id          = (j->>'state_house'),
  state_house_district_name   = (j->>'state_house_name'),
  county_geo_id               = (j->>'county'),
  county_name                 = (j->>'county_name'),
  school_district_geo_id      = (j->>'school_district'),
  school_district_name        = (j->>'school_district_name')
FROM (
  SELECT user_id, connect.resolve_user_jurisdiction(user_id) AS j
  FROM connect.connected_profiles
  WHERE location_consent = true
) sub
WHERE cp.user_id = sub.user_id;
-- Note: jurisdiction_state and jurisdiction_city are NOT backfillable from RPC
-- (RPC doesn't return state/city) -- populated on next set-location call
