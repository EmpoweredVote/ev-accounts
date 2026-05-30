BEGIN;

-- =============================================================================
-- Migration 089: TIGER geo_districts schema
-- GEO-01: essentials.geo_districts (point-in-polygon source of truth)
-- GEO-02: connect.user_districts   (per-user district cache)
-- GEO-03: essentials.districts.tiger_geoid (TIGER join key for politicians)
--
-- PostGIS 3.3 is already enabled in this project (confirmed in spec).
-- Geometry SRID 4326 (WGS84) — TIGER ships as 4269 (NAD83); ogr2ogr reprojects
-- on import (see 69-02 seed script, -t_srs EPSG:4326).
--
-- Idempotency: CREATE TABLE IF NOT EXISTS, CREATE INDEX IF NOT EXISTS,
-- CREATE POLICY IF NOT EXISTS, ADD COLUMN IF NOT EXISTS — all safe to re-run.
-- =============================================================================

-- Section 1: essentials.geo_districts (GEO-01)
-- layer values: 'ca_assembly' | 'ca_senate' | 'us_house' (Phase 71 will add school layers).
-- geoid is the TIGER GEOID, e.g. CA Assembly District 36 = '06036'.
-- UNIQUE (layer, geoid) makes seed script INSERT ... ON CONFLICT idempotent.
CREATE TABLE IF NOT EXISTS essentials.geo_districts (
  id           BIGSERIAL   PRIMARY KEY,
  layer        TEXT        NOT NULL,
  geoid        TEXT        NOT NULL,
  district_num TEXT        NOT NULL,
  name         TEXT,
  geom         GEOMETRY(MULTIPOLYGON, 4326) NOT NULL,
  UNIQUE (layer, geoid)
);

-- GIST index on geom is mandatory for ST_Contains performance.
-- Without it the resolve_user_districts RPC does a full table scan.
CREATE INDEX IF NOT EXISTS idx_geo_districts_geom
  ON essentials.geo_districts USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_geo_districts_layer
  ON essentials.geo_districts (layer);

CREATE INDEX IF NOT EXISTS idx_geo_districts_layer_district_num
  ON essentials.geo_districts (layer, district_num);

ALTER TABLE essentials.geo_districts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'essentials'
      AND tablename = 'geo_districts'
      AND policyname = 'geo_districts_public_read'
  ) THEN
    CREATE POLICY "geo_districts_public_read"
      ON essentials.geo_districts
      FOR SELECT
      USING (true);
  END IF;
END;
$$;

-- Section 2: connect.user_districts (GEO-02)
-- Per-user district cache, keyed by (user_id, layer). Resolved lazily by
-- cache_user_districts RPC after a user sets/updates their location.
-- ON DELETE CASCADE on public.users — same pattern as connect.connected_profiles.
CREATE TABLE IF NOT EXISTS connect.user_districts (
  user_id      UUID  NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  layer        TEXT  NOT NULL,
  geoid        TEXT  NOT NULL,
  district_num TEXT  NOT NULL,
  resolved_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, layer)
);

CREATE INDEX IF NOT EXISTS idx_user_districts_user_id
  ON connect.user_districts (user_id);

ALTER TABLE connect.user_districts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'connect'
      AND tablename = 'user_districts'
      AND policyname = 'user_districts_own'
  ) THEN
    CREATE POLICY "user_districts_own"
      ON connect.user_districts
      FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END;
$$;

-- Section 3: essentials.districts.tiger_geoid (GEO-03)
-- Adds the TIGER GEOID join key on the existing districts table. Nullable
-- for now (backfill happens in 69-02 after geo_districts is populated).
-- UNIQUE because each TIGER district maps to exactly one row in essentials.districts.
ALTER TABLE essentials.districts
  ADD COLUMN IF NOT EXISTS tiger_geoid TEXT UNIQUE;

COMMIT;
