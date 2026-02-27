BEGIN;

-- =============================================================================
-- Migration 016: RLS policies and grants for the inform schema
-- =============================================================================
-- All 10 inform tables get RLS enabled.
-- 8 reference tables (topics, categories, stances, politicians, etc.) get
--   public-read policies accessible to both anon and authenticated roles.
-- 2 personal data tables (compass_responses, compass_change_history) get
--   owner-only SELECT policies (authenticated only).
-- NO INSERT/UPDATE/DELETE policies on compass_responses or compass_change_history —
--   all writes are performed via pg pool (service layer) or SECURITY DEFINER
--   RPC functions. The architecture test enforces that routes/ never use
--   supabaseAdmin — this is the RLS complement to that constraint.
--
-- GRANT pattern follows migration 011 (public schema) and 012 (connect schema):
--   GRANT USAGE ON SCHEMA inform TO anon, authenticated;
--   GRANT SELECT ON ALL TABLES IN SCHEMA inform TO anon, authenticated;
--   Note: GRANT SELECT on ALL TABLES grants the permission at the table level,
--   but RLS policies further restrict what each role can actually see.
--   For compass_responses and compass_change_history, anon gets SELECT grant
--   but the RLS policy only allows authenticated users to see their own rows —
--   so anon effectively reads nothing from those tables.
-- =============================================================================


-- =============================================================================
-- Section 1: Enable RLS on all 10 inform tables
-- =============================================================================

ALTER TABLE inform.compass_categories        ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.compass_topics            ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.compass_topic_categories  ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.compass_topic_roles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.compass_stances           ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.compass_responses         ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.compass_change_history    ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.politicians               ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.politician_answers        ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.politician_context        ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- Section 2: Public-read policies on 8 reference tables
-- These tables contain no personal data — anyone (anon or authenticated) may
-- SELECT all rows. USING (true) means no row-level restriction.
-- =============================================================================

-- inform.compass_categories
CREATE POLICY "compass_categories: public read"
  ON inform.compass_categories
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- inform.compass_topics
CREATE POLICY "compass_topics: public read"
  ON inform.compass_topics
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- inform.compass_topic_categories
CREATE POLICY "compass_topic_categories: public read"
  ON inform.compass_topic_categories
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- inform.compass_topic_roles
CREATE POLICY "compass_topic_roles: public read"
  ON inform.compass_topic_roles
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- inform.compass_stances
CREATE POLICY "compass_stances: public read"
  ON inform.compass_stances
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- inform.politicians
CREATE POLICY "politicians: public read"
  ON inform.politicians
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- inform.politician_answers
CREATE POLICY "politician_answers: public read"
  ON inform.politician_answers
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- inform.politician_context
CREATE POLICY "politician_context: public read"
  ON inform.politician_context
  FOR SELECT
  TO anon, authenticated
  USING (true);


-- =============================================================================
-- Section 3: Owner-only SELECT policies on 2 personal data tables
-- Users can only read their own calibration data.
-- No INSERT/UPDATE/DELETE policies — the service layer writes directly via
-- pg pool (which bypasses RLS). See SECURITY DEFINER RPCs for empowerment/demotion.
-- Uses (select auth.uid()) subquery form (not bare auth.uid()) — consistent
-- with pattern established in migrations 007, 008, 009, and 014.
-- =============================================================================

-- inform.compass_responses — owner-only SELECT
-- No INSERT/UPDATE/DELETE policies. All writes via:
--   - compassService.ts upsert (pg pool, bypasses RLS)
--   - empower.execute_empowerment/execute_demotion (SECURITY DEFINER)
CREATE POLICY "compass_responses: owner select"
  ON inform.compass_responses
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- inform.compass_change_history — owner-only SELECT
-- Append-only audit log. Inserts only from:
--   - compassService.ts promoteCompassImportDraft (pg pool)
--   - POST /compass/answers service layer (Phase 4 Plan 03)
CREATE POLICY "compass_change_history: owner select"
  ON inform.compass_change_history
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);


-- =============================================================================
-- Section 4: GRANT USAGE + SELECT on inform schema
-- Without GRANT USAGE, all queries to inform.* return "permission denied for schema".
-- Without GRANT SELECT, even allowed-by-RLS rows return permission errors.
-- This mirrors the pattern from migration 011 (public) and 012 (connect).
-- =============================================================================

GRANT USAGE ON SCHEMA inform TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA inform TO anon, authenticated;


COMMIT;
