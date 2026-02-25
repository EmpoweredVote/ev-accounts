BEGIN;

-- Migration 009: RLS policies for the empower schema
--
-- Design decisions (from CONTEXT.md):
--   - empowered_profiles: anonymous users can read ACTIVE profiles (public candidate pages).
--     This is intentional — Phase 8 serves unauthenticated visitors looking up civic leaders.
--   - INACTIVE profiles (is_active = false): only the owner can see their own inactive record.
--     Anon and non-owning authenticated users get zero rows for inactive profiles.
--   - legal_name: readable on active profiles (it is the public name of a civic leader).
--     The column is present on active rows; for inactive rows the entire row is hidden.

-- -------------------------------------------------------------------------
-- empower.empowered_profiles
-- -------------------------------------------------------------------------
ALTER TABLE empower.empowered_profiles ENABLE ROW LEVEL SECURITY;

-- Anonymous AND authenticated users can read active (is_active = true) profiles.
-- This enables Phase 8 public candidate pages without requiring login.
-- Note: anon role in Supabase = unauthenticated user; authenticated = logged-in user.
CREATE POLICY "empowered_profiles: public read active"
  ON empower.empowered_profiles
  FOR SELECT
  TO anon, authenticated
  USING (is_active = true AND deleted_at IS NULL);

-- Owner reads their own profile regardless of is_active status.
-- This allows a demoted user to see their own (now inactive) record — e.g., for
-- the empowerment re-entry flow (Phase 5).
CREATE POLICY "empowered_profiles: owner read own"
  ON empower.empowered_profiles
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- No INSERT/UPDATE/DELETE policies for non-service-role:
--   All empowered_profiles writes go through execute_empowerment() and
--   execute_demotion() SECURITY DEFINER RPC functions (atomicity guarantee).
--   Direct writes to this table are forbidden for application code.

COMMIT;
