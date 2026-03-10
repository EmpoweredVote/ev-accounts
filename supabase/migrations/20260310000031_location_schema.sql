BEGIN;

-- =============================================================================
-- Migration 031: Location schema
-- Adds encrypted coordinate columns to connect.connected_profiles and creates
-- the inform.district_boundaries PostGIS table (populated via runbook, not here).
--
-- Idempotency: ADD COLUMN IF NOT EXISTS, CREATE TABLE IF NOT EXISTS,
-- CREATE INDEX IF NOT EXISTS, and CREATE POLICY IF NOT EXISTS are all safe
-- to re-run. No data is modified.
-- =============================================================================

-- Section 1: connected_profiles columns
-- Three columns for encrypted location storage and consent tracking.
-- Column type is bytea — natural output of pgp_sym_encrypt_bytea.
-- location_consent is set to true atomically by upsert_user_location RPC.
-- location_set_at is written by upsert_user_location alongside the encrypted coords.
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS encrypted_lat    bytea,
  ADD COLUMN IF NOT EXISTS encrypted_lng    bytea,
  ADD COLUMN IF NOT EXISTS location_consent boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS location_set_at  timestamptz;

-- Section 2: inform.district_boundaries table
-- Stores Indiana TIGER/Line 2024 boundaries for 5 district types.
-- Populated via runbook (ogr2ogr), not this migration.
-- geometry type: MultiPolygon — TIGER/Line features include non-contiguous
-- districts (islands, etc.); MultiPolygon handles them safely.
-- SRID 4326 (WGS84) — TIGER/Line ships as 4269 (NAD83), reprojected by ogr2ogr.
CREATE TABLE IF NOT EXISTS inform.district_boundaries (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  district_type text        NOT NULL
    CHECK (district_type IN ('congressional', 'state_senate', 'state_house', 'county', 'school_district')),
  geoid         text        NOT NULL,
  name          text        NOT NULL,
  geom          geometry(MultiPolygon, 4326) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Section 3: Indexes
-- GIST index is mandatory for spatial query performance.
-- ST_Covers without a GIST index causes a full table scan.
CREATE INDEX IF NOT EXISTS idx_district_boundaries_geom
  ON inform.district_boundaries USING GIST (geom);

-- btree index on district_type — used by resolve_user_jurisdiction for
-- per-type aggregation; improves filtering when table is fully populated.
CREATE INDEX IF NOT EXISTS idx_district_boundaries_type
  ON inform.district_boundaries (district_type);

-- Section 4: RLS
-- Authenticated users can read boundary data (needed for Phase 20 jurisdiction endpoint).
-- No user should insert/update/delete boundaries (runbook step only).
ALTER TABLE inform.district_boundaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "district_boundaries_authenticated_read"
  ON inform.district_boundaries
  FOR SELECT
  TO authenticated
  USING (true);

COMMIT;
