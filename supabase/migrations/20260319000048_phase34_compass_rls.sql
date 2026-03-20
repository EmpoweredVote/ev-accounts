-- Phase 34: RLS + grants for compass schema (8 tables)
-- 4 public-read tables, 4 owner-read tables (user_id is TEXT storing UUID values).
-- No INSERT/UPDATE/DELETE policies — all writes via service role (pool.query()).

BEGIN;

-- ============================================================
-- Section 1: Enable RLS on every table
-- ============================================================
ALTER TABLE compass.answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE compass.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE compass.contexts ENABLE ROW LEVEL SECURITY;
ALTER TABLE compass.quote_verdicts ENABLE ROW LEVEL SECURITY;
ALTER TABLE compass.stances ENABLE ROW LEVEL SECURITY;
ALTER TABLE compass.topic_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE compass.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE compass.user_compasses ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Section 2: Public-read policies (anon + authenticated)
-- ============================================================
CREATE POLICY "categories: public read"
  ON compass.categories FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "stances: public read"
  ON compass.stances FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "topic_categories: public read"
  ON compass.topic_categories FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "topics: public read"
  ON compass.topics FOR SELECT TO anon, authenticated USING (true);

-- ============================================================
-- Section 3: Owner-read policies (authenticated only)
-- CRITICAL: user_id is TEXT storing UUID values — must cast to uuid for auth.uid() comparison.
-- Use (select auth.uid()) form for query plan caching.
-- ============================================================
CREATE POLICY "answers: owner read"
  ON compass.answers
  FOR SELECT
  TO authenticated
  USING (user_id::uuid = (select auth.uid()));

CREATE POLICY "contexts: owner read"
  ON compass.contexts
  FOR SELECT
  TO authenticated
  USING (user_id::uuid = (select auth.uid()));

CREATE POLICY "quote_verdicts: owner read"
  ON compass.quote_verdicts
  FOR SELECT
  TO authenticated
  USING (user_id::uuid = (select auth.uid()));

CREATE POLICY "user_compasses: owner read"
  ON compass.user_compasses
  FOR SELECT
  TO authenticated
  USING (user_id::uuid = (select auth.uid()));

-- ============================================================
-- Section 4: Grants
-- ============================================================
GRANT USAGE ON SCHEMA compass TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA compass TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA compass GRANT SELECT ON TABLES TO anon, authenticated;

COMMIT;
