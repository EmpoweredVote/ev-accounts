-- verify-compass-user-lens-history-probes.sql
-- CC_0468 acceptance evidence — custom lens history, soft delete, truncate guard.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-compass-user-lens-history-probes.sql
--
-- Migration: backend/migrations/CC_0468_compass_user_lens_history.sql
-- Design:    docs/superpowers/specs/2026-11-22-lens-durability-design.md
--
-- ⚠ SECTIONS 1-3 ARE READ-ONLY. SECTION 4 IS NOT, AND IT IS THE IMPORTANT ONE.
-- Section 4 writes a lens, deletes a real user as `supabase_auth_admin`, asserts,
-- and then ROLLS THE WHOLE THING BACK. It is one explicitly rolled-back
-- transaction and it is written to be pasted and run as-is. Nothing it does
-- survives. Run it against the database you actually care about — proving the
-- cascade on a copy proves nothing about the cascade in production, because the
-- thing under test is role grants, and those are per-database.
--
-- 🔴 RUN THIS AFTER THE MIGRATION IS APPLIED, NOT BEFORE. Section 4 in particular
-- is the one failure that would otherwise surface as "nobody can delete their
-- account any more", discovered by a user.


\echo ''
\echo '=== 1. THE FUNCTIONS: SECURITY DEFINER, owned by postgres, search_path pinned ==='
\echo '--- PASS: two rows, both prosecdef = t, owner = postgres, proconfig = {search_path=}'
\echo '--- STOP: fewer than two rows, prosecdef = f, any other owner, or proconfig NULL.'
\echo '---       prosecdef = f or a non-postgres owner means the account-deletion cascade'
\echo '---       (which runs as supabase_auth_admin, with no USAGE on inform) will raise'
\echo '---       "permission denied for schema inform" and EVERY ACCOUNT DELETION ABORTS.'
\echo '---       proconfig NULL means a SECURITY DEFINER function with a caller-controlled'
\echo '---       search_path, which is a privilege-escalation hole. Both are blockers.'

SELECT p.proname, p.prosecdef, r.rolname AS owner, p.proconfig
  FROM pg_proc p JOIN pg_roles r ON r.oid = p.proowner
 WHERE p.pronamespace = 'inform'::regnamespace
   AND p.proname IN ('log_compass_user_lens_change','refuse_compass_user_lens_truncate');


\echo ''
\echo '=== 2. THE TRIGGERS: all four, and the UPDATE one carries a WHEN clause ==='
\echo '--- PASS: exactly four rows —'
\echo '---         compass_user_lenses_history_ins   AFTER INSERT   FOR EACH ROW'
\echo '---         compass_user_lenses_history_upd   AFTER UPDATE   FOR EACH ROW'
\echo '---                                           WHEN ((old.* IS DISTINCT FROM new.*))'
\echo '---         compass_user_lenses_history_del   AFTER DELETE   FOR EACH ROW'
\echo '---         compass_user_lenses_no_truncate   AFTER TRUNCATE FOR EACH STATEMENT'
\echo '--- STOP: a missing trigger is a write path with no record — which is the entire'
\echo '---       hole this migration exists to close, so a partial pass is a fail.'
\echo '---       The UPDATE trigger WITHOUT its WHEN clause is not a blocker but it is'
\echo '---       wrong: every no-op PUT would write a history row and bury the real'
\echo '---       changes in noise, which is how the nightly check stops being read.'

SELECT tgname, tgtype, pg_get_triggerdef(oid) FROM pg_trigger
 WHERE tgrelid = 'inform.compass_user_lenses'::regclass AND NOT tgisinternal;


\echo ''
\echo '=== 3. ev_api reached both new tables WITHOUT anyone granting it ==='
\echo '--- PASS: two rows, each relacl containing ev_api=arwd/postgres, relrowsecurity = t.'
\echo '---       ev_api got that from ALTER DEFAULT PRIVILEGES IN SCHEMA inform, not from'
\echo '---       any GRANT in CC_0468 — there is none, deliberately.'
\echo '--- STOP: ev_api absent from relacl. The backend pool cannot read its own history'
\echo '---       table and the route will 500. 🔴 DO NOT FIX THIS BY WRITING A GRANT.'
\echo '---       A hand-written GRANT patches these two tables and hides a broken default,'
\echo '---       so the NEXT table created in this schema comes out unreadable too. Fix'
\echo '---       the default privileges. And do not REVOKE anything either: ev_api carries'
\echo '---       rolbypassrls = true and that grant is how the API reads this schema at all.'
\echo '--- STOP: relrowsecurity = f on either table — RLS off means PostgREST-reachable.'
\echo '--- NOTE: pg_class is not filtered by schema here (the probe is quoted verbatim from'
\echo '---       the brief). Extra rows mean a same-named table exists in another schema;'
\echo '---       read the ones in inform.'

SELECT relname, relacl, relrowsecurity FROM pg_class
 WHERE relname IN ('compass_user_lens_history','compass_lens_alert_acks');


\echo ''
\echo '=== 4. THE CASCADE PROOF — writes, then ROLLS BACK. Read the notice output. ==='
\echo '--- This is the failure that would otherwise surface in production as "account'
\echo '--- deletion is broken". It deletes a REAL user row as supabase_auth_admin inside a'
\echo '--- transaction that is explicitly rolled back, and asserts that the cascade reached'
\echo '--- inform.compass_user_lenses and that the trigger wrote a hard_delete row.'
\echo '---'
\echo '--- PASS: NOTICE "CC_0468 cascade probe PASS", then ROLLBACK, then users_after equal'
\echo '---       to users_before and probe_rows_left = 0.'
\echo '--- STOP: ERROR "permission denied for schema inform" — the trigger is NOT running as'
\echo '---       postgres. Every account deletion in the product would abort. Fix the'
\echo '---       function owner / SECURITY DEFINER before going any further; do not ship.'
\echo '--- STOP: ERROR "...no hard_delete row" — the cascade deleted lenses and left no'
\echo '---       record, which is exactly the hole CC_0468 claims to close.'
\echo '--- NOTE: ERROR "permission denied for table users" is a DIFFERENT finding — it says'
\echo '---       supabase_auth_admin cannot reach public.users directly in this database, so'
\echo '---       this probe could not exercise the cascade at all. It is not a pass.'
\echo '---       Re-aim the probe at whatever the real deletion path deletes from.'
\echo '--- STOP: no "lens-free user" could be found — do not relax the probe by borrowing a'
\echo '---       user who already holds lenses; the insert below would collide on key.'

SELECT count(*) AS users_before FROM public.users;

BEGIN;

DO $probe$
DECLARE
  v_user uuid;
  v_hist int;
BEGIN
  -- 1. A real user who holds no lenses. Read-only; chosen rather than invented so
  --    the FK and the cascade are the real ones.
  SELECT u.id INTO v_user
    FROM public.users u
   WHERE NOT EXISTS (SELECT 1 FROM inform.compass_user_lenses l WHERE l.owner_id = u.id)
   LIMIT 1;

  IF v_user IS NULL THEN
    RAISE EXCEPTION 'CC_0468 cascade probe: no lens-free user to borrow — see the STOP note above';
  END IF;

  -- 2. Give them a lens to lose. Zero lenses would cascade to zero history rows and
  --    the probe would pass vacuously, which is the shape of a check that has quietly
  --    stopped working.
  INSERT INTO inform.compass_user_lenses (owner_id, key, name)
  VALUES (v_user, 'u_cc0468probe', 'CC_0468 cascade probe');

  -- 3. Delete as the role the product's account deletion actually runs as. This role
  --    is not superuser, does not bypass RLS, and has no USAGE on inform — which is
  --    the whole reason the trigger is SECURITY DEFINER.
  EXECUTE 'SET LOCAL ROLE supabase_auth_admin';
  DELETE FROM public.users WHERE id = v_user;
  EXECUTE 'RESET ROLE';

  -- 4. The cascade took the lens AND the trigger recorded it.
  IF EXISTS (SELECT 1 FROM inform.compass_user_lenses WHERE key = 'u_cc0468probe') THEN
    RAISE EXCEPTION 'CC_0468 cascade probe: the lens survived the account deletion — '
                    'the ON DELETE CASCADE on owner_id is not what this assumed';
  END IF;

  SELECT count(*) INTO v_hist
    FROM inform.compass_user_lens_history
   WHERE lens_key = 'u_cc0468probe' AND op = 'hard_delete';

  IF v_hist <> 1 THEN
    RAISE EXCEPTION 'CC_0468 cascade probe: expected 1 hard_delete history row, found % — '
                    'the cascade destroyed lenses and left no record', v_hist;
  END IF;

  RAISE NOTICE 'CC_0468 cascade probe PASS: user % deleted as supabase_auth_admin, cascade '
               'removed the lens, trigger wrote 1 hard_delete row. Rolling back.', v_user;
END
$probe$;

ROLLBACK;

\echo ''
\echo '--- 4b. Nothing survived the probe. PASS: users_after = users_before (printed above),'
\echo '---     probe_rows_left = 0. STOP on any other result: the ROLLBACK did not take and'
\echo '---     a real user row is gone — restore it before doing anything else.'

SELECT count(*) AS users_after FROM public.users;

SELECT count(*) AS probe_rows_left
  FROM inform.compass_user_lens_history
 WHERE lens_key = 'u_cc0468probe';
