-- Migration 1386: least-privilege application role `ev_api` for the API's DATABASE_URL
--
-- WHY: the API (backend/src/lib/db.ts pool) connects as `postgres` — the project's most-
--   privileged non-superuser role (BYPASSRLS, owns ~all objects, full DDL/role-management,
--   can read `vault`). A leaked DATABASE_URL = total DB control. This creates a scoped login
--   role that can do exactly what the pool.query surface needs and nothing else. Surfaced by
--   the 2026-07-22 finance-slowdown incident (that role also had no statement_timeout).
--   See .planning/todos/2026-07-22-URGENT-prod-db-campaign-finance-slowdown.md.
--
-- MODEL: BYPASSRLS trusted-backend role (matches existing app roles ctc_app / trivia_service).
--   The API relies on bypassing RLS (46/51 essentials tables + connect/inform/empower/public
--   have RLS); it is the trusted server tier. The security win is NOT RLS — it is removing
--   object ownership, DDL, role management, and access to unrelated schemas (civic_spaces,
--   civic, validation_quests, trivia, vault, auth) and secrets.
--
-- CLUSTER-LEVEL: roles are not per-database, so this is not captured by a fresh-DB restore the
--   way table DDL is. It is idempotent and safe to re-run. The LOGIN PASSWORD is set OUT OF
--   BAND (operator: `ALTER ROLE ev_api PASSWORD '…'`), never stored in the repo.
--
-- SCOPE (pool.query surface, from the 2026-07-22 audit):
--   Full DML: essentials, transparent_motivations, connect, inform, treasury, meetings,
--             staging, empower
--   public:   explicit table list only (shared schema)
--   app_auth: SELECT on users only
--   judicial: INSERT/SELECT on donations only
--   EXECUTE:  10 in-band SECURITY DEFINER/helper RPCs (they run as owner=postgres)
--
-- Apply OUTSIDE a transaction is NOT required (no CONCURRENTLY here); a transaction is fine.

DO $mig$
DECLARE
  full_schemas text[] := ARRAY[
    'essentials','transparent_motivations','connect','inform',
    'treasury','meetings','staging','empower'
  ];
  s text;
  r record;
BEGIN
  -- 1. Role (idempotent). NOSUPERUSER/NOCREATEDB/NOCREATEROLE + BYPASSRLS. No password here.
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ev_api') THEN
    CREATE ROLE ev_api LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT BYPASSRLS;
  ELSE
    ALTER ROLE ev_api LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE BYPASSRLS;
  END IF;
  ALTER ROLE ev_api SET statement_timeout = '30s';

  -- Membership: postgres must be a member of ev_api to (a) reassign object ownership to it
  -- (postgres is not superuser) and (b) `SET ROLE ev_api` for validation. NOINHERIT on ev_api
  -- means this does not change postgres's own effective privileges.
  GRANT ev_api TO postgres;

  -- 2. Full-DML schemas: USAGE + DML on postgres-owned relations + sequences + default privs.
  FOREACH s IN ARRAY full_schemas LOOP
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO ev_api', s);
    -- Tables/views/matviews/partitioned tables owned by postgres (skip foreign-owned to avoid errors)
    FOR r IN
      SELECT format('%I.%I', n.nspname, c.relname) AS obj
      FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = s AND c.relkind IN ('r','p','v','m')
        AND pg_get_userbyid(c.relowner) = 'postgres'
    LOOP
      EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %s TO ev_api', r.obj);
    END LOOP;
    -- Sequences (for serial/identity inserts)
    FOR r IN
      SELECT format('%I.%I', n.nspname, c.relname) AS obj
      FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = s AND c.relkind = 'S'
        AND pg_get_userbyid(c.relowner) = 'postgres'
    LOOP
      EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE %s TO ev_api', r.obj);
    END LOOP;
    -- Future objects created by postgres in these schemas
    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA %I GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ev_api', s);
    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA %I GRANT USAGE, SELECT ON SEQUENCES TO ev_api', s);
  END LOOP;

  -- 3. transparent_motivations extras: runtime DDL path in fecBackfill.ts (CREATE TABLE/ALTER
  --    … IF NOT EXISTS on fec_candidate_totals). Grant CREATE + own that one table so the
  --    existing no-op DDL still succeeds. (Follow-up: move that DDL to a migration, revoke CREATE.)
  GRANT CREATE ON SCHEMA transparent_motivations TO ev_api;
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='transparent_motivations' AND c.relname='fec_candidate_totals') THEN
    ALTER TABLE transparent_motivations.fec_candidate_totals OWNER TO ev_api;
  END IF;

  -- 4. public: explicit, bounded table set (shared schema — do NOT grant on ALL tables).
  GRANT USAGE ON SCHEMA public TO ev_api;
  GRANT SELECT, INSERT, UPDATE, DELETE ON
    public.users, public.roles, public.user_roles, public.admin_users,
    public.role_audit_log, public.access_requests, public.cta_events,
    public.source_verifications
    TO ev_api;
  -- sequences backing those tables (owned by postgres)
  FOR r IN
    SELECT format('%I.%I', n.nspname, c.relname) AS obj
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relkind='S' AND pg_get_userbyid(c.relowner)='postgres'
      AND EXISTS (
        SELECT 1 FROM pg_depend d
        JOIN pg_class t ON t.oid = d.refobjid
        WHERE d.objid = c.oid AND d.deptype IN ('a','i')
          AND t.relname IN ('users','roles','user_roles','admin_users','role_audit_log',
                            'access_requests','cta_events','source_verifications'))
  LOOP
    EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE %s TO ev_api', r.obj);
  END LOOP;

  -- 5. app_auth: read-only username lookup.
  GRANT USAGE ON SCHEMA app_auth TO ev_api;
  GRANT SELECT ON app_auth.users TO ev_api;

  -- 6. judicial: write-only donations ingest (SELECT too for ON CONFLICT/RETURNING paths).
  GRANT USAGE ON SCHEMA judicial TO ev_api;
  GRANT INSERT, SELECT ON judicial.donations TO ev_api;
  FOR r IN
    SELECT format('%I.%I', n.nspname, c.relname) AS obj
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='judicial' AND c.relkind='S' AND pg_get_userbyid(c.relowner)='postgres'
  LOOP
    EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE %s TO ev_api', r.obj);
  END LOOP;

  -- 6b. extensions schema: USAGE so in-band pg_trgm search (word_similarity / the %> operator,
  --     used by donor + politician + location search) and other extension objects are reachable.
  --     USAGE only (no DML) — it is a utility schema; EXECUTE on the functions is PUBLIC.
  GRANT USAGE ON SCHEMA extensions TO ev_api;

  -- 7. EXECUTE on the in-band RPCs (all overloads of each schema.name).
  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE (n.nspname='essentials' AND p.proname IN ('cache_user_districts','recache_user_districts_for_user'))
       OR (n.nspname='connect'    AND p.proname IN ('resolve_user_local_officials','generate_invite_code_if_allowed',
                                                    'get_my_invitees','get_invite_cap_for_level','sanction_invitee',
                                                    'unlock_referral_code','maybe_refresh_referral_for_invitee'))
       OR (n.nspname='inform'     AND p.proname IN ('award_inform_yellow_gem'))
  LOOP
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO ev_api', r.sig);
  END LOOP;
END
$mig$;
