BEGIN;

-- =============================================================================
-- Migration 049: RLS policies and grants for the staging schema
-- =============================================================================
-- Staging contains volunteer data entry and review workflow data.
-- Access: authenticated users only — anon is NEVER granted access.
-- Reviewer/admin role gating is enforced at the route middleware layer,
-- not the RLS layer (all authenticated users may read staging rows).
-- NO INSERT/UPDATE/DELETE policies — all writes via service role (pool.query()).
-- =============================================================================

-- Section 1: Enable RLS on all 6 staging tables
ALTER TABLE staging.building_photo_review_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE staging.building_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE staging.politician_review_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE staging.politicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE staging.review_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE staging.stances ENABLE ROW LEVEL SECURITY;

-- Section 2: Authenticated-only read policies (no anon)
CREATE POLICY "building_photo_review_logs: authenticated read"
  ON staging.building_photo_review_logs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "building_photos: authenticated read"
  ON staging.building_photos
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "politician_review_logs: authenticated read"
  ON staging.politician_review_logs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "politicians: authenticated read"
  ON staging.politicians
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "review_logs: authenticated read"
  ON staging.review_logs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "stances: authenticated read"
  ON staging.stances
  FOR SELECT
  TO authenticated
  USING (true);

-- Section 3: Grants (authenticated only — anon intentionally excluded)
GRANT USAGE ON SCHEMA staging TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA staging TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA staging GRANT SELECT ON TABLES TO authenticated;

-- Service role explicit access (bypasses RLS by default, but grant needed for PostgREST visibility)
GRANT USAGE ON SCHEMA staging TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA staging TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA staging GRANT ALL ON TABLES TO service_role;

COMMIT;
