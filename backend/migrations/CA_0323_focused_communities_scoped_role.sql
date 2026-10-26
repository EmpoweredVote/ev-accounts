BEGIN;

-- =============================================================================
-- CA_0323: dedicated, least-privilege Postgres role for the folded Focused
--          Communities backend (focused_communities_app)
-- =============================================================================
-- Created 2026-10-26 with Chris Andrews. Engine consolidation — the Focused
-- Communities backend moves into ev-accounts-api (src/focused_communities/), the
-- same way civic-spaces slice assignment did in CA_0112.
--
-- WHAT THIS DOES
-- Creates login role `focused_communities_app` and grants it EXACTLY what the
-- module's routes use, all in the connect schema:
--   communities                 SELECT
--   threads, posts              SELECT, INSERT, UPDATE   (no DELETE: posts and
--                                                        threads are never deleted)
--   thread_edits, post_edits    SELECT                   (written only by triggers)
--   get_stances_for_community   EXECUTE
-- and nothing else in the database.
--
-- WHY A DEDICATED ROLE (not ev_api, not the service_role key)
-- The standalone service used the broad service_role key, which reaches the whole
-- database. The connect schema ALSO holds identity and identity-adjacent tables —
-- connected_profiles (PRIVACY-ARCHITECTURE property A), invite chains, gem and XP
-- ledgers, verification sessions, user_districts. A bug or a leaked credential in
-- this module must not reach them, so the role gets the five tables above and no
-- others. Modeled on civic_spaces_app (CA_0112).
--
-- NO BYPASSRLS — UNLIKE CA_0112. RLS is on for all five tables, and a raw pg
-- connection carries no request JWT, so their existing policies would refuse this
-- role. Instead of BYPASSRLS (watchlist #40 counts those roles), this file adds
-- one permissive policy per table and command, scoped TO focused_communities_app
-- only. The module is a trusted server-side writer: it checks ownership itself
-- (author_id = the verified caller) before every UPDATE, exactly as the standalone
-- did under service_role. Other roles' policies are untouched.
--
-- TRIGGERS. snapshot_author_display_name (reads connected_profiles) and
-- log_thread_edit / log_post_edit (write the edit tables) are SECURITY DEFINER, so
-- they run with their owner's rights and need no grant here. Verified 2026-10-26.
--
-- 🔴 NO PASSWORD IN GIT. The role is created WITHOUT a password. The founder sets
-- one live, once, and puts the connection string in the ev-accounts-api Render env
-- as FOCUSED_COMMUNITIES_DATABASE_URL (never committed):
--     ALTER ROLE focused_communities_app WITH PASSWORD '<generated-secret>';
-- Use the Supabase SESSION pooler (port 5432), matching DATABASE_URL — the pool
-- sets search_path per connection, which the transaction pooler (6543) resets.
--
-- There is no migration runner (see CLAUDE.md): this file documents the change and
-- lets a DB rebuild re-apply it. Idempotent — safe to re-run.
-- =============================================================================

-- 1. The role. Created without a password (see header). NOINHERIT so it never picks
--    up privileges from any role it is later added to. NOBYPASSRLS explicitly.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'focused_communities_app') THEN
    CREATE ROLE focused_communities_app WITH LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  ELSE
    ALTER ROLE focused_communities_app WITH LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END $$;

-- 2. Schema, table and function grants — the wall.
GRANT USAGE ON SCHEMA connect TO focused_communities_app;
GRANT SELECT ON connect.communities TO focused_communities_app;
GRANT SELECT, INSERT, UPDATE ON connect.threads, connect.posts TO focused_communities_app;
GRANT SELECT ON connect.thread_edits, connect.post_edits TO focused_communities_app;
GRANT EXECUTE ON FUNCTION connect.get_stances_for_community(uuid) TO focused_communities_app;

-- 3. Row-level policies for this role only (see header: instead of BYPASSRLS).
DROP POLICY IF EXISTS fc_app_select ON connect.communities;
CREATE POLICY fc_app_select ON connect.communities FOR SELECT TO focused_communities_app USING (true);

DROP POLICY IF EXISTS fc_app_select ON connect.threads;
CREATE POLICY fc_app_select ON connect.threads FOR SELECT TO focused_communities_app USING (true);
DROP POLICY IF EXISTS fc_app_insert ON connect.threads;
CREATE POLICY fc_app_insert ON connect.threads FOR INSERT TO focused_communities_app WITH CHECK (true);
DROP POLICY IF EXISTS fc_app_update ON connect.threads;
CREATE POLICY fc_app_update ON connect.threads FOR UPDATE TO focused_communities_app USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS fc_app_select ON connect.posts;
CREATE POLICY fc_app_select ON connect.posts FOR SELECT TO focused_communities_app USING (true);
DROP POLICY IF EXISTS fc_app_insert ON connect.posts;
CREATE POLICY fc_app_insert ON connect.posts FOR INSERT TO focused_communities_app WITH CHECK (true);
DROP POLICY IF EXISTS fc_app_update ON connect.posts;
CREATE POLICY fc_app_update ON connect.posts FOR UPDATE TO focused_communities_app USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS fc_app_select ON connect.thread_edits;
CREATE POLICY fc_app_select ON connect.thread_edits FOR SELECT TO focused_communities_app USING (true);
DROP POLICY IF EXISTS fc_app_select ON connect.post_edits;
CREATE POLICY fc_app_select ON connect.post_edits FOR SELECT TO focused_communities_app USING (true);

-- 4. Pin search_path at the role level (belt-and-braces with the pool's connect hook).
ALTER ROLE focused_communities_app SET search_path = connect, public;

-- 5. Post-verify gate — fail loudly if the role is not exactly what the module needs.
DO $$
BEGIN
  IF (SELECT rolbypassrls FROM pg_roles WHERE rolname = 'focused_communities_app') THEN
    RAISE EXCEPTION 'CA_0323: focused_communities_app must NOT hold BYPASSRLS';
  END IF;
  IF NOT has_schema_privilege('focused_communities_app', 'connect', 'USAGE') THEN
    RAISE EXCEPTION 'CA_0323: missing USAGE on schema connect';
  END IF;
  IF NOT has_table_privilege('focused_communities_app', 'connect.communities', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0323: missing SELECT on connect.communities';
  END IF;
  IF NOT has_table_privilege('focused_communities_app', 'connect.threads', 'SELECT,INSERT,UPDATE')
     OR NOT has_table_privilege('focused_communities_app', 'connect.posts', 'SELECT,INSERT,UPDATE') THEN
    RAISE EXCEPTION 'CA_0323: missing SELECT/INSERT/UPDATE on connect.threads or connect.posts';
  END IF;
  IF NOT has_table_privilege('focused_communities_app', 'connect.thread_edits', 'SELECT')
     OR NOT has_table_privilege('focused_communities_app', 'connect.post_edits', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0323: missing SELECT on the edit tables';
  END IF;
  IF NOT has_function_privilege('focused_communities_app', 'connect.get_stances_for_community(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0323: missing EXECUTE on connect.get_stances_for_community(uuid)';
  END IF;
  IF has_table_privilege('focused_communities_app', 'connect.threads', 'DELETE')
     OR has_table_privilege('focused_communities_app', 'connect.posts', 'DELETE') THEN
    RAISE EXCEPTION 'CA_0323: focused_communities_app must not be able to DELETE threads or posts';
  END IF;

  -- The wall, asserted from the other side: the role must NOT be able to read identity.
  -- Not fatal (a grant to PUBLIC on those tables is outside this migration's control), but
  -- surfaced so a regression is visible in the apply log.
  IF has_table_privilege('focused_communities_app', 'connect.connected_profiles', 'SELECT')
     OR has_table_privilege('focused_communities_app', 'public.users', 'SELECT') THEN
    RAISE WARNING 'CA_0323: focused_communities_app can read an identity table — investigate the wall';
  END IF;

  RAISE NOTICE 'CA_0323 OK — focused_communities_app created (no BYPASSRLS), scoped to 5 connect tables + get_stances_for_community, search_path pinned. Founder: set its password + FOCUSED_COMMUNITIES_DATABASE_URL (see header).';
END $$;

COMMIT;
