BEGIN;

-- =============================================================================
-- CA_0298: least-privilege login role for CTC content tooling (trivia_content);
--          retire ctc_app and trivia_service
-- =============================================================================
-- Created 2026-09-28 with Chris Andrews. ev-cto decision 0025, option B.
--
-- PRE-FLIGHT (read-only, production kxsdzaojfaibhuzmclfq, 2026-09-28, PostgreSQL 17.6)
--   Current user postgres: NOSUPERUSER, CREATEROLE, BYPASSRLS.
--   pg_roles:
--     ev_api          LOGIN   BYPASSRLS
--     ctc_app         NOLOGIN BYPASSRLS
--     trivia_service  NOLOGIN BYPASSRLS
--     trivia_content  (does not exist)
--   Schema trivia: 13 tables, all owned by postgres, RLS ENABLED on all 13 (not FORCED):
--     bobit_progress, claim_fingerprints, collection_questions, collection_topics,
--     collections, election_races, generation_jobs, player_prefs, player_stats,
--     question_flags, questions, topics, user_collection_mutes
--   Sequences: claim_fingerprints_id_seq, collections_id_seq, election_races_id_seq,
--     generation_jobs_id_seq, question_flags_id_seq, questions_id_seq, topics_id_seq
--   pg_policies (trivia): 19 existing policies — NOT default-deny as decision 0025 says.
--     - "Public read" SELECT for anon, authenticated on collections, collection_questions,
--       collection_topics, election_races, questions, topics.
--     - Own-row (auth.uid() = user_id) policies on player_prefs, player_stats,
--       question_flags (authenticated) and bobit_progress, user_collection_mutes (PUBLIC).
--     None of them names trivia_content, so none of them widens it. The PUBLIC own-row
--     policies evaluate auth.uid() = NULL for a raw connection, so they match no rows.
--   ctc_app / trivia_service:
--     - Own no objects (pg_shdepend deptype 'o' = 0).
--     - 0 connections in pg_stat_activity.
--     - STILL HOLD PRIVILEGES (deptype 'a'): USAGE on schema trivia, DML on the 13 tables,
--       rU on the 7 sequences, and entries in postgres's two DEFAULT PRIVILEGES rows for
--       schema trivia. So decision 0025's "no grants on trivia" is wrong; the only thing
--       that stopped ctc_app was NOLOGIN (watchlist #55).
--     - postgres is a member of both roles.
--   extensions.similarity(text, text) exists (pg_trgm).
--   Re-checked 2026-09-30: all of the above unchanged. postgres holds ADMIN OPTION on
--   both old roles (granted by supabase_admin), so DROP ROLE is allowed.
--   The engine copy of the content scripts (backend/src/trivia/) uses only
--   pgSchema('trivia') and extensions.similarity().
--
-- APPLIED to production 2026-10-01 00:28 UTC (schema_migrations 20261001002822,
-- ca_0298_trivia_content_role), BEGIN/COMMIT stripped. Post-apply catalog check:
-- trivia_content LOGIN NOBYPASSRLS NOINHERIT; 13/13 policies; DML on 13/13 tables;
-- USAGE on 7/7 sequences; EXECUTE on similarity; 0 inform tables readable;
-- ctc_app and trivia_service gone.
-- 🔴 Pre-existing, not changed here: PUBLIC can EXECUTE some net.* (pg_net) functions,
-- including http_delete and worker_restart, so trivia_content can too.
--
-- WHY NOBYPASSRLS + ONE POLICY PER TABLE
-- A role without BYPASSRLS sees zero rows in a table with RLS on unless a policy lets it.
-- trivia_content gets one permissive FOR ALL policy per table, scoped TO trivia_content
-- only. Other roles are unaffected: permissive policies are OR'd per role.
-- 🔴 A NEW trivia table needs its own trivia_content_all policy, or content scripts see
-- zero rows on it. The default-privileges grant below covers the table grant, not the policy.
--
-- 🔴 NO PASSWORD IN GIT OR IN MIGRATION HISTORY. This file creates the role WITHOUT a
-- password. apply_migration stores the SQL text in supabase_migrations.schema_migrations,
-- so a password here would persist in the database too. Set it once, live, from a local
-- psql session (\password trivia_content), and hand it to the CTC maintainer through a
-- password manager. Never paste it into chat, a transcript, or a memory file.
-- Connection: aws-0-us-west-1.pooler.supabase.com:5432 (session pooler),
-- user trivia_content.kxsdzaojfaibhuzmclfq.
--
-- There is no migration runner (see CLAUDE.md). Idempotent — safe to re-run.
-- =============================================================================

-- 1. The role. No password here (see header).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'trivia_content') THEN
    CREATE ROLE trivia_content WITH LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  ELSE
    ALTER ROLE trivia_content WITH LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END $$;

ALTER ROLE trivia_content SET search_path = trivia, extensions;

-- 2. Grants — trivia and extensions only.
GRANT USAGE ON SCHEMA trivia, extensions TO trivia_content;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA trivia TO trivia_content;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA trivia TO trivia_content;
GRANT EXECUTE ON FUNCTION extensions.similarity(text, text) TO trivia_content;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA trivia
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO trivia_content;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA trivia
  GRANT USAGE, SELECT ON SEQUENCES TO trivia_content;

-- 3. One RLS policy per trivia table, for trivia_content only.
DO $$
DECLARE t text;
BEGIN
  FOR t IN
    SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'trivia' AND c.relkind IN ('r', 'p')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS trivia_content_all ON trivia.%I', t);
    EXECUTE format(
      'CREATE POLICY trivia_content_all ON trivia.%I FOR ALL TO trivia_content USING (true) WITH CHECK (true)', t);
  END LOOP;
END $$;

-- 4. Retire ctc_app and trivia_service.
--    Guard: abort if either owns an object or has a live connection.
DO $$
DECLARE n_owned int; n_conn int;
BEGIN
  SELECT count(*) INTO n_owned FROM pg_shdepend d
  WHERE d.deptype = 'o' AND d.refclassid = 'pg_authid'::regclass
    AND d.refobjid IN (SELECT oid FROM pg_roles WHERE rolname IN ('ctc_app', 'trivia_service'));
  SELECT count(*) INTO n_conn FROM pg_stat_activity
  WHERE usename IN ('ctc_app', 'trivia_service');
  IF n_owned > 0 THEN
    RAISE EXCEPTION 'CA_0298: ctc_app/trivia_service own % object(s) — stop', n_owned;
  END IF;
  IF n_conn > 0 THEN
    RAISE EXCEPTION 'CA_0298: ctc_app/trivia_service have % live connection(s) — stop', n_conn;
  END IF;
END $$;

--    They own nothing but still hold privileges, and DROP ROLE fails while any remain.
DO $$
DECLARE r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['ctc_app', 'trivia_service'] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('REVOKE ALL ON ALL TABLES IN SCHEMA trivia FROM %I', r);
      EXECUTE format('REVOKE ALL ON ALL SEQUENCES IN SCHEMA trivia FROM %I', r);
      EXECUTE format('REVOKE ALL ON SCHEMA trivia FROM %I', r);
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA trivia REVOKE ALL ON TABLES FROM %I', r);
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA trivia REVOKE ALL ON SEQUENCES FROM %I', r);
      IF EXISTS (
        SELECT 1 FROM pg_shdepend d
        WHERE d.refclassid = 'pg_authid'::regclass
          AND d.refobjid = (SELECT oid FROM pg_roles WHERE rolname = r)
      ) THEN
        RAISE EXCEPTION 'CA_0298: % still has dependencies after revoke — stop', r;
      END IF;
    END IF;
  END LOOP;
END $$;

DROP ROLE IF EXISTS ctc_app;
DROP ROLE IF EXISTS trivia_service;

-- 5. Post-verify gate.
DO $$
DECLARE n_tables int; n_policies int;
BEGIN
  IF (SELECT rolbypassrls FROM pg_roles WHERE rolname = 'trivia_content') THEN
    RAISE EXCEPTION 'CA_0298: trivia_content has BYPASSRLS';
  END IF;
  SELECT count(*) INTO n_tables FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'trivia' AND c.relkind IN ('r', 'p');
  SELECT count(*) INTO n_policies FROM pg_policies
  WHERE schemaname = 'trivia' AND policyname = 'trivia_content_all';
  IF n_policies <> n_tables THEN
    RAISE EXCEPTION 'CA_0298: % trivia tables but % trivia_content_all policies', n_tables, n_policies;
  END IF;
  IF has_schema_privilege('trivia_content', 'inform', 'USAGE') THEN
    RAISE EXCEPTION 'CA_0298: trivia_content can reach schema inform';
  END IF;
  IF NOT has_function_privilege('trivia_content', 'extensions.similarity(text, text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0298: trivia_content lacks EXECUTE on extensions.similarity';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname IN ('ctc_app', 'trivia_service')) THEN
    RAISE EXCEPTION 'CA_0298: ctc_app or trivia_service still exists';
  END IF;
END $$;

COMMIT;
