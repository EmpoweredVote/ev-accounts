-- Phase 34: RLS + grants for transparent_motivations schema (7 tables)
-- 5 public-read tables, 2 authenticated-read tables (ingestion_runs, source_audit_log — admin audit logs).
-- No INSERT/UPDATE/DELETE policies — all writes via service role (pool.query()).

BEGIN;

-- ============================================================
-- Section 1: Enable RLS on every table
-- ============================================================
ALTER TABLE transparent_motivations.committees ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.data_source_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.donors ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.politician_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.ingestion_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.source_audit_log ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Section 2: Public-read policies (anon + authenticated)
-- ============================================================
CREATE POLICY "committees: public read"
  ON transparent_motivations.committees FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "contributions: public read"
  ON transparent_motivations.contributions FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "data_source_metadata: public read"
  ON transparent_motivations.data_source_metadata FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "donors: public read"
  ON transparent_motivations.donors FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "politician_sources: public read"
  ON transparent_motivations.politician_sources FOR SELECT TO anon, authenticated USING (true);

-- ============================================================
-- Section 3: Authenticated-read policies (NOT anon — admin audit logs)
-- ============================================================
CREATE POLICY "ingestion_runs: authenticated read"
  ON transparent_motivations.ingestion_runs FOR SELECT TO authenticated USING (true);

CREATE POLICY "source_audit_log: authenticated read"
  ON transparent_motivations.source_audit_log FOR SELECT TO authenticated USING (true);

-- ============================================================
-- Section 4: Grants
-- ============================================================
GRANT USAGE ON SCHEMA transparent_motivations TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA transparent_motivations TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA transparent_motivations GRANT SELECT ON TABLES TO anon, authenticated;

COMMIT;
