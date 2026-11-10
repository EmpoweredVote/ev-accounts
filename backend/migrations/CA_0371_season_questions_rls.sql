BEGIN;

-- =============================================================================
-- CA_0371: turn on row-level security for inform.season_questions
-- =============================================================================
-- Steward slot CA_0371. Clears the Supabase security advisor ERROR
-- `rls_disabled_in_public` on inform.season_questions (ev-cto task
-- 2026-11-09-season-questions-rls).
--
-- WHY IT WAS MISSED
-- * CA_0017 (2026-08-27) created the table with RLS off.
-- * CA_0109 (2026-09-10, the default-deny sweep) did not include it: at that
--   time only postgres and ev_api held grants on it, so the advisor did not
--   flag it.
-- * CA_0348 (2026-11-02) granted SELECT to service_role, and CA_0367
--   (2026-11-06) granted SELECT to authenticated, so the security_invoker view
--   inform.compass_topics_promoted keeps working. Once an API role could read
--   the table, the advisor raised the ERROR.
-- * No CI job checks RLS on new or changed tables; the advisor is the only
--   guard, and it runs against prod after apply.
--
-- WHAT THIS DOES
-- 1. ENABLE ROW LEVEL SECURITY on inform.season_questions.
-- 2. A SELECT policy for `authenticated`, USING (true). This keeps today's
--    reach exactly: CA_0367 gave authenticated SELECT so signed-in users can
--    read compass_responses_effective -> compass_topics_promoted (invoker
--    views) -> season_questions. Without this policy, RLS default-deny would
--    filter that join to zero rows — the same silent break CA_0109 caused on
--    inform.seasons and CA_0110 repaired.
--
-- WHAT THIS EXPOSES
-- Nothing new. The table is the public question list of each season (season,
-- topic, pinned revision, question number, display order). No user data.
-- anon has no grant and gets no policy.
--
-- WHO IS UNAFFECTED (read on prod 2026-11-09)
-- * Writers: inform.admin_season_add_topic, admin_season_remove_topic,
--   admin_season_repin_topic, admin_create_draft_season, admin_open_season,
--   admin_season_pin_revision — all SECURITY DEFINER, owned by postgres
--   (rolbypassrls = true).
-- * ev_api and service_role: rolbypassrls = true.
-- * FORCE ROW LEVEL SECURITY is NOT set, so the owner (postgres) is unaffected.
--
-- VALUES THIS OVERWRITES (read on prod 2026-11-09)
-- * relrowsecurity = false, no policies.
-- * relacl {postgres=arwdDxtm/postgres,ev_api=arwd/postgres,
--           service_role=r/postgres,authenticated=r/postgres} — unchanged.
--
-- IDEMPOTENT: ENABLE is safe to repeat; DROP POLICY IF EXISTS then CREATE.
--
-- REVERSAL:
--   DROP POLICY IF EXISTS season_questions_read_authenticated ON inform.season_questions;
--   ALTER TABLE inform.season_questions DISABLE ROW LEVEL SECURITY;
--   (Drop the policy only together with DISABLE, or signed-in compass reads
--   return no rows.)
-- =============================================================================

ALTER TABLE inform.season_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS season_questions_read_authenticated ON inform.season_questions;
CREATE POLICY season_questions_read_authenticated ON inform.season_questions
  FOR SELECT
  TO authenticated
  USING (true);

-- =============================================================================
-- Post-verify gate. Reads as the roles the routes use, because a policy that
-- exists is not the same as a read that works (watchlist #57).
-- =============================================================================
DO $$
DECLARE
  v_total  bigint;
  v_authed bigint;
  v_view   bigint;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class
    WHERE oid = 'inform.season_questions'::regclass AND relrowsecurity
  ) THEN
    RAISE EXCEPTION 'CA_0371: RLS is not enabled on inform.season_questions';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'inform' AND tablename = 'season_questions'
      AND policyname = 'season_questions_read_authenticated'
      AND cmd = 'SELECT'
      AND roles = ARRAY['authenticated']::name[]
  ) THEN
    RAISE EXCEPTION 'CA_0371: season_questions_read_authenticated is missing or not SELECT/authenticated-only';
  END IF;

  IF has_table_privilege('anon', 'inform.season_questions', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0371: anon can SELECT inform.season_questions';
  END IF;

  SELECT count(*) INTO v_total FROM inform.season_questions;

  SET LOCAL ROLE authenticated;
  SELECT count(*) INTO v_authed FROM inform.season_questions;
  SELECT count(*) INTO v_view   FROM inform.compass_topics_promoted;
  RESET ROLE;

  IF v_authed <> v_total THEN
    RAISE EXCEPTION 'CA_0371: authenticated sees % of % season_questions rows', v_authed, v_total;
  END IF;
  IF v_view = 0 THEN
    RAISE EXCEPTION 'CA_0371: authenticated sees 0 rows in inform.compass_topics_promoted';
  END IF;

  RAISE NOTICE 'CA_0371 OK — RLS on; authenticated reads % of % rows and % promoted topics; anon closed.',
    v_authed, v_total, v_view;
END $$;

COMMIT;
