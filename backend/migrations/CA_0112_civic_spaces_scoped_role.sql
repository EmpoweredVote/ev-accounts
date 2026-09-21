BEGIN;

-- =============================================================================
-- CA_0112: dedicated, least-privilege Postgres role for the folded Civic Spaces
--          slice-assignment module (civic_spaces_app)
-- =============================================================================
-- Created 2026-09-12 with Chris Andrews. Engine consolidation — ev-cto decision 0018.
--
-- WHAT THIS DOES
-- Creates login role `civic_spaces_app` and grants it access to EXACTLY the three
-- civic_spaces tables the slice-assignment module writes — slices, slice_members,
-- connected_profiles — and nothing else in the database.
--
-- WHY A DEDICATED ROLE (not ev_api, not the service_role key)
-- The standalone service wrote via the broad per-service Supabase service key (decision
-- 0014), which maps to `service_role` — BYPASSRLS across the WHOLE database. The engine's
-- own role `ev_api` is likewise broad (it reaches every schema). Neither is acceptable
-- here: civic_spaces.connected_profiles.user_id joins to identity
-- (PRIVACY-ARCHITECTURE property A), so a bug or a leaked credential in this module must
-- not be able to read identity or any other schema. `civic_spaces_app` holds grants on
-- only the three tables, so it is walled off by construction. Modeled on the trivia
-- ev_api grant + search_path pattern (CA_0102), but scoped to its own role.
--
-- BYPASSRLS: the three tables have RLS enabled and their policies key on
-- civic_spaces.current_user_id() (the request JWT). A raw pg connection carries no JWT,
-- so the module — a trusted server-side writer that assigns rows on behalf of the
-- already-authenticated caller — bypasses RLS exactly as the old service key did. This is
-- safe precisely because the role can touch nothing but those three tables: BYPASSRLS
-- only skips RLS, it does NOT grant table access.
--
-- 🔴 NO PASSWORD IN GIT. This file creates the role WITHOUT a password. The founder must,
-- once, set a strong password live and put the resulting connection string in the
-- ev-accounts-api Render env as CIVIC_SPACES_DATABASE_URL (never committed):
--     ALTER ROLE civic_spaces_app WITH PASSWORD '<generated-secret>';
-- Point the connection string at the Supabase SESSION pooler (port 5432), matching
-- DATABASE_URL — the module's pool uses SET search_path and BEGIN/COMMIT, which the
-- transaction pooler (6543) resets between transactions.
--
-- There is no migration runner (see CLAUDE.md): this file documents the change and lets a
-- DB rebuild re-apply it. Idempotent — safe to re-run.
-- =============================================================================

-- 1. The role. Idempotent; created without a password (see header — founder sets it live).
--    NOINHERIT so it never picks up privileges from any role it is later added to.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'civic_spaces_app') THEN
    CREATE ROLE civic_spaces_app WITH LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE BYPASSRLS;
  ELSE
    -- Keep attributes correct on re-run without disturbing an existing password.
    ALTER ROLE civic_spaces_app WITH LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE BYPASSRLS;
  END IF;
END $$;

-- 2. Schema + table grants — the wall. USAGE on the schema, DML on ONLY the three tables.
--    No grants on posts/replies/notifications/flags/etc., no other schema, no sequences
--    (ids are gen_random_uuid()), no function EXECUTE (trigger functions are not
--    EXECUTE-checked when fired by a trigger).
GRANT USAGE ON SCHEMA civic_spaces TO civic_spaces_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON
  civic_spaces.slices,
  civic_spaces.slice_members,
  civic_spaces.connected_profiles
  TO civic_spaces_app;

-- 3. Pin search_path at the role level (belt-and-braces with the pool's connect hook).
ALTER ROLE civic_spaces_app SET search_path = civic_spaces, public;

-- 4. Post-verify gate — fail loudly if the role is not exactly what the module needs.
DO $$
BEGIN
  IF NOT (SELECT rolbypassrls FROM pg_roles WHERE rolname = 'civic_spaces_app') THEN
    RAISE EXCEPTION 'CA_0112: civic_spaces_app lacks BYPASSRLS';
  END IF;
  IF NOT has_schema_privilege('civic_spaces_app', 'civic_spaces', 'USAGE') THEN
    RAISE EXCEPTION 'CA_0112: civic_spaces_app lacks USAGE on schema civic_spaces';
  END IF;
  IF NOT has_table_privilege('civic_spaces_app', 'civic_spaces.slices', 'SELECT')
     OR NOT has_table_privilege('civic_spaces_app', 'civic_spaces.slices', 'INSERT')
     OR NOT has_table_privilege('civic_spaces_app', 'civic_spaces.slices', 'UPDATE') THEN
    RAISE EXCEPTION 'CA_0112: civic_spaces_app missing privileges on civic_spaces.slices';
  END IF;
  IF NOT has_table_privilege('civic_spaces_app', 'civic_spaces.slice_members', 'INSERT')
     OR NOT has_table_privilege('civic_spaces_app', 'civic_spaces.slice_members', 'DELETE') THEN
    RAISE EXCEPTION 'CA_0112: civic_spaces_app missing privileges on civic_spaces.slice_members';
  END IF;
  IF NOT has_table_privilege('civic_spaces_app', 'civic_spaces.connected_profiles', 'INSERT')
     OR NOT has_table_privilege('civic_spaces_app', 'civic_spaces.connected_profiles', 'UPDATE') THEN
    RAISE EXCEPTION 'CA_0112: civic_spaces_app missing privileges on civic_spaces.connected_profiles';
  END IF;

  -- The wall, asserted from the other side: the role must NOT be able to read identity.
  -- Not fatal (grants to PUBLIC on those tables are outside this migration's control), but
  -- surfaced so a regression is visible in the apply log.
  IF has_table_privilege('civic_spaces_app', 'public.users', 'SELECT')
     OR has_table_privilege('civic_spaces_app', 'connect.connected_profiles', 'SELECT') THEN
    RAISE WARNING 'CA_0112: civic_spaces_app can read an identity table — investigate the wall';
  END IF;

  RAISE NOTICE 'CA_0112 OK — civic_spaces_app created (BYPASSRLS), granted DML on civic_spaces.{slices, slice_members, connected_profiles} only, search_path pinned. Founder: set its password + CIVIC_SPACES_DATABASE_URL (see header).';
END $$;

COMMIT;
