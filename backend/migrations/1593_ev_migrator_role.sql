-- 1593_ev_migrator_role.sql
--
-- Create the `ev_migrator` login role so scripts/_apply-file.ts can apply migrations that contain
-- DDL, without widening the live API's role.
--
--   Rollback: REASSIGN OWNED BY ev_migrator TO postgres; DROP OWNED BY ev_migrator; DROP ROLE ev_migrator;
--
-- ⚠ THE PASSWORD IS NOT IN THIS FILE AND MUST NOT BE ADDED TO IT. It was generated out-of-band and
-- lives only in backend/.env as MIGRATION_DATABASE_URL (local only — it is NOT set on Render, because
-- the running API must never hold DDL rights). To rotate:
--   ALTER ROLE ev_migrator PASSWORD '<new>';   -- then update backend/.env
--
-- 🔴 AFTER ROTATING, WAIT 30-60s BEFORE BELIEVING AN AUTH FAILURE. Supabase's pooler (Supavisor)
-- caches credentials, so a CORRECT new password is rejected with "password authentication failed"
-- for up to a minute. Learned the hard way on 2026-08-07: that failure was diagnosed as a mismatch
-- between .env and the database and the role was rotated a SECOND time, when the only thing that
-- actually fixed it was the passage of time. Retry before re-rotating. _apply-file.ts now decodes
-- SQLSTATE 28P01 with this warning so the next person does not repeat it.
--
-- Note the password is alphanumeric on purpose: it sits between ':' and '@' in a connection URL, so
-- '@', ':', '/', '?', '#' and '%' in a password will corrupt the parse rather than fail cleanly.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY THIS ROLE EXISTS
-- ---------------------------------------------------------------------------------------------------
-- _apply-file.ts connected as DATABASE_URL, which is `ev_api` — the role the live API runs as. That
-- role has USAGE on `essentials` and full SELECT/INSERT/UPDATE/DELETE, but NO CREATE on the schema.
-- So every migration containing CREATE TABLE failed with "permission denied for schema essentials",
-- a message that sends you looking at schema access when the missing privilege is CREATE.
--
-- The obvious fix — GRANT CREATE ON SCHEMA essentials TO ev_api — was REJECTED. `ev_api` serves
-- https://accounts-api.empowered.vote and already holds BYPASSRLS; giving the internet-facing web
-- role the ability to create and drop objects in the schema that holds the election corpus is a
-- privilege escalation with no upside. A migration tool is not a web server and should not share
-- its credentials.
--
-- HOW LONG THIS WAS BROKEN: it was never true that DDL migrations went through _apply-file.ts. All
-- four pre-existing archive tables (_fabricated_1588_removed, _fabricated_1590_removed,
-- _retired_1589_races, _retired_1589_candidates) are owned by `postgres`, so they were applied over a
-- `postgres` connection while every migration header claimed the _apply-file.ts path. The header line
-- was boilerplate. Headers from 1593 on should say which role the file needs.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE CEILING — READ THIS BEFORE ASSUMING ev_migrator CAN APPLY ANY MIGRATION
-- ---------------------------------------------------------------------------------------------------
-- CREATE INDEX and ALTER TABLE on an EXISTING table require table OWNERSHIP. Postgres has no
-- grantable "alter any table" privilege, so NO amount of granting fixes this — every table in
-- `essentials` is owned by `postgres`. Verified empirically, not assumed: a CREATE INDEX on
-- essentials.race_candidates as ev_migrator fails with "must be owner of table race_candidates".
--
--   Works as ev_migrator ...... data migrations, and archive-then-mutate migrations that CREATE a new
--                              table (1588, 1590, 1591, 1592).
--   Still needs `postgres` .... adding a column or building an index (1574, 1586, 1589).
--
-- Making ev_migrator a table owner, or a member of `postgres`, would close that gap and was NOT done:
-- it would hand this role the whole database and recreate the problem it was created to avoid.
--
-- Attributes are deliberately left at CREATE ROLE defaults (NOSUPERUSER, NOCREATEDB, NOCREATEROLE,
-- NOBYPASSRLS). They are not stated explicitly because `postgres` is NOT a superuser on Supabase
-- (rolsuper = false) and therefore cannot toggle those attributes at all — an explicit
-- `ALTER ROLE ... NOSUPERUSER NOBYPASSRLS` fails with "permission denied to alter role".
-- ---------------------------------------------------------------------------------------------------

-- CREATE ROLE ev_migrator LOGIN PASSWORD '<set out-of-band; see the warning above>';

GRANT USAGE, CREATE ON SCHEMA essentials TO ev_migrator;
GRANT USAGE, CREATE ON SCHEMA inform     TO ev_migrator;
GRANT USAGE          ON SCHEMA compass   TO ev_migrator;
GRANT USAGE          ON SCHEMA public    TO ev_migrator;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES    IN SCHEMA essentials TO ev_migrator;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES    IN SCHEMA inform     TO ev_migrator;
GRANT SELECT                         ON ALL TABLES    IN SCHEMA compass    TO ev_migrator;
GRANT USAGE, SELECT, UPDATE          ON ALL SEQUENCES IN SCHEMA essentials TO ev_migrator;
GRANT USAGE, SELECT, UPDATE          ON ALL SEQUENCES IN SCHEMA inform     TO ev_migrator;
GRANT EXECUTE                        ON ALL FUNCTIONS IN SCHEMA essentials TO ev_migrator;

-- Tables created later by `postgres` are reachable without re-running the grants above.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA essentials
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ev_migrator;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA inform
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ev_migrator;

-- Verification (expected: ev_migrator create=true bypassrls=false; ev_api create=FALSE, unchanged)
--   SELECT rolname, rolsuper, rolbypassrls,
--          has_schema_privilege(rolname,'essentials','CREATE') AS can_create
--     FROM pg_roles WHERE rolname IN ('ev_api','ev_migrator');
