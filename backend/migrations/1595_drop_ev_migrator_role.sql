-- 1595_drop_ev_migrator_role.sql
--
-- Drop the `ev_migrator` role created in migration 1593. It cannot do the job it was created for and
-- leaving it in place is a live credential with no purpose.
--
--   Rollback: re-run migration 1593's grants after CREATE ROLE ev_migrator LOGIN PASSWORD '<new>'.
--             Don't. Read the correction in 1593 first.
--
-- ⚠ Applied as `postgres` over the supabase MCP. (DROP ROLE needs CREATEROLE, which ev_api lacks and
-- which the dropped role obviously cannot use on itself.)
--
-- ---------------------------------------------------------------------------------------------------
-- WHY IT IS GOING, ONE DAY AFTER IT ARRIVED
-- ---------------------------------------------------------------------------------------------------
-- 1593 created ev_migrator so `scripts/_apply-file.ts` could apply DDL without widening `ev_api`, the
-- live API's role. The reasoning about ev_api was right and stands: it serves
-- accounts-api.empowered.vote, it already holds BYPASSRLS, and it must not gain CREATE.
--
-- What was wrong was the assumption that a non-BYPASSRLS role could work with this data at all. Every
-- table in `essentials` has RLS ENABLED with no permissive policy, so ev_migrator saw ZERO rows in
-- race_candidates, races, politicians, elections and offices. Worse, that failed SILENTLY: an UPDATE
-- matching zero rows succeeds, so a data migration applied as ev_migrator reported "Applied OK" and
-- changed nothing. Migration 1594 is what exposed it, by finally doing an INSERT (RLS refuses those
-- loudly) instead of an UPDATE (RLS drops those quietly).
--
-- It could not be rescued by granting: BYPASSRLS requires SUPERUSER and `postgres` is not one on
-- Supabase. The alternative — permissive RLS policies for ev_migrator on every table — is a
-- policy-shaped bypass that widens production security surface to re-create a capability `postgres`
-- already has. Operator decision 2026-08-07: drop the role, apply migrations as `postgres`.
--
-- The guard added to _apply-file.ts in 1594 STAYS. It refuses to apply when the connected role can see
-- zero rows, and that protects any future role, not just this one. The lesson generalises: a migration
-- tool that cannot see the data can still report success.
--
-- ev_migrator owns NO objects (verified: 0 relations, 0 schemas), so nothing is orphaned. It holds only
-- grants — 4 schema grants, 96 table grants, 2 default-ACL entries — all removed below.
--
-- ⚠ ALSO REMOVE `MIGRATION_DATABASE_URL` FROM backend/.env. After this migration that line holds
-- credentials for a role that no longer exists; _apply-file.ts would try it and fail at authentication.
-- ---------------------------------------------------------------------------------------------------

-- ⚠ `DROP OWNED BY ev_migrator` DOES NOT WORK HERE and was removed after failing:
--     ERROR 42501: permission denied to drop objects
--     DETAIL: Only roles with privileges of role "ev_migrator" may drop objects owned by it.
-- It needs MEMBERSHIP in the target role, which `postgres` does not have (and cannot self-grant
-- without superuser). Granting `ev_migrator` TO `postgres` just to drop it would be a wider privilege
-- than the drop itself. Since the role owns nothing, revoking explicitly is the exact inverse of
-- migration 1593's grants and needs no membership — that is what was applied.

BEGIN;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA essentials
  REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM ev_migrator;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA inform
  REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM ev_migrator;

REVOKE ALL ON ALL TABLES    IN SCHEMA essentials, inform, compass, public FROM ev_migrator;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA essentials, inform                  FROM ev_migrator;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA essentials                          FROM ev_migrator;
REVOKE ALL ON SCHEMA essentials, inform, compass, public                  FROM ev_migrator;

-- DROP ROLE refuses while the role is still named in any ACL, so the revokes above are prerequisites,
-- not tidiness.
DROP ROLE ev_migrator;

COMMIT;

-- Verification (expected: 0 rows, and ev_api unchanged with create=false, bypassrls=true)
--   SELECT count(*) FROM pg_roles WHERE rolname='ev_migrator';
--   SELECT rolname, rolbypassrls, has_schema_privilege(rolname,'essentials','CREATE') AS can_create
--     FROM pg_roles WHERE rolname='ev_api';
