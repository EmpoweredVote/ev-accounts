-- verify-compass-user-lens-history-probes.sql
-- CC_0468 acceptance evidence — custom lens history, soft delete, truncate guard.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-compass-user-lens-history-probes.sql
--
-- Migration: backend/migrations/CC_0468_compass_user_lens_history.sql
-- Design:    docs/superpowers/specs/2026-11-22-lens-durability-design.md
--
-- ⚠ SECTIONS 1-3 ARE READ-ONLY. SECTION 4 IS NOT, AND IT IS THE IMPORTANT ONE.
-- Section 4 writes a lens, deletes a real `auth.users` row as `supabase_auth_admin`
-- and follows the cascade down, asserts, and then ROLLS THE WHOLE THING BACK —
-- see its own 🔴 block for why auth.users and not public.users. It is one
-- explicitly rolled-back
-- transaction and it is written to be pasted and run as-is. Nothing it does
-- survives. Run it against the database you actually care about — proving the
-- cascade on a copy proves nothing about the cascade in production, because the
-- thing under test is role grants, and those are per-database.
--
-- 🔴 RUN THIS AFTER THE MIGRATION IS APPLIED, NOT BEFORE. Section 4 in particular
-- is the one failure that would otherwise surface as "nobody can delete their
-- account any more", discovered by a user.
--
-- 🔴 A CLEAN MIGRATION APPLY IS NOT A PASS ON THE ev_api GRANT. SECTION 3 IS THE
-- AUTHORITATIVE ANSWER, AND IT HAS TO BE RUN.
-- CC_0468's verification block checks the same thing, but it reports it with
-- RAISE WARNING rather than RAISE EXCEPTION (deliberately: the only remedy an
-- abort would pressure anyone toward is a hand-written GRANT, which is forbidden
-- here and would hide a broken default). A WARNING travels on a channel the MCP
-- apply path does not surface. So the migration can apply, report success, and
-- have warned that `ev_api` cannot read its own history table — with nobody told.
-- Section 3 is how that gets seen. Do not skip it because the apply was green.


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
\echo '--- deletion is broken". It deletes a REAL auth.users row as supabase_auth_admin'
\echo '--- inside a transaction that is explicitly rolled back, and asserts that the two'
\echo '--- cascade hops reached inform.compass_user_lenses and that the trigger wrote a'
\echo '--- hard_delete row.'
\echo '---'
\echo '--- 🔴 IT DELETES FROM auth.users, NOT public.users, AND THAT IS NOT A DETAIL.'
\echo '--- Measured read-only against production, 2026-11-22:'
\echo '---     has_table_privilege(supabase_auth_admin, public.users, DELETE) = FALSE'
\echo '---     has_table_privilege(supabase_auth_admin, auth.users,   DELETE) = TRUE'
\echo '---     has_schema_privilege(supabase_auth_admin, inform, USAGE)       = FALSE'
\echo '---     FK chain: auth.users -cascade-> public.users -cascade-> compass_user_lenses'
\echo '--- An earlier draft of this probe deleted from public.users, following the task'
\echo '--- brief. It could never pass: it raised "permission denied for table users"'
\echo '--- before ever reaching the trigger, so it proved nothing about the property it'
\echo '--- exists to prove. auth.users is the real path. The delete is permitted there,'
\echo '--- BOTH FK cascades bypass permission checks — and our user-defined AFTER DELETE'
\echo '--- trigger is the one link in the chain that does NOT. That is the risk under test:'
\echo '--- supabase_auth_admin has no USAGE on inform, so an INVOKER trigger would abort'
\echo '--- every account deletion in the product.'
\echo '---'
\echo '--- PASS: NOTICE "CC_0468 cascade probe PASS", then ROLLBACK, then probe_rows_left = 0.'
\echo '--- STOP: ERROR "permission denied for schema inform" — the trigger is NOT running as'
\echo '---       postgres. Every account deletion in the product would abort. Fix the'
\echo '---       function owner / SECURITY DEFINER before going any further; do not ship.'
\echo '--- STOP: ERROR "...no hard_delete row" — the cascade deleted lenses and left no'
\echo '---       record, which is exactly the hole CC_0468 claims to close.'
\echo '--- STOP: ERROR "permission denied for table users" — the grant measured above has'
\echo '---       changed. The probe did not exercise the cascade at all. Not a pass.'
\echo '--- STOP: ERROR mentioning a closed season — the chosen account had compass answers'
\echo '---       in a closed season and CC_0046 closed_season_is_immutable() aborted the'
\echo '---       cascade before it reached lenses. The query below already excludes those'
\echo '---       accounts; if this appears, that exclusion no longer matches the trigger.'
\echo '--- STOP: no borrowable account could be found — do not relax the filters to make it'
\echo '---       run. An account that already holds lenses collides on key; one with'
\echo '---       closed-season answers fails for an unrelated reason.'
\echo '---'
\echo '--- ⚠ UNDER -v ON_ERROR_STOP=1 ANY STOP ABOVE EXITS psql IMMEDIATELY, so section 4b'
\echo '---   never prints. That is expected and it is safe: the transaction was never'
\echo '---   committed, so disconnecting rolls it back. Absence of the 4b output after an'
\echo '---   ERROR is not a second problem to chase.'

BEGIN;

DO $probe$
DECLARE
  v_user uuid;
  v_hist int;
BEGIN
  -- 1. A real account to borrow, read-only. Three conditions, each load bearing:
  --
  --      * it exists in BOTH auth.users and public.users under the same id — the
  --        probe deletes by id from auth.users and then asserts the public.users
  --        row went with it, which is the first cascade hop;
  --      * it holds no lenses, because step 2 inserts one under a fixed key and
  --        would otherwise collide on the globally-unique index;
  --      * it has no compass answers outside the open season. CC_0046 attached
  --        inform.closed_season_is_immutable() to compass_responses as a BEFORE
  --        DELETE trigger, and auth.users cascades through that table too. An
  --        account with closed-season answers makes the DELETE raise there — long
  --        before the lens trigger runs — and the probe would report a failure
  --        that has nothing to do with what it is testing.
  SELECT u.id INTO v_user
    FROM public.users u
   WHERE EXISTS (SELECT 1 FROM auth.users a WHERE a.id = u.id)
     AND NOT EXISTS (SELECT 1 FROM inform.compass_user_lenses l WHERE l.owner_id = u.id)
     AND NOT EXISTS (
           SELECT 1 FROM inform.compass_responses cr
             JOIN inform.seasons s ON s.id = cr.season_id
            WHERE cr.user_id = u.id AND s.status <> 'open')
   LIMIT 1;

  IF v_user IS NULL THEN
    RAISE EXCEPTION 'CC_0468 cascade probe: no borrowable account found — see the STOP note above';
  END IF;

  -- 2. Give them a lens to lose. Zero lenses would cascade to zero history rows
  --    and the probe would pass vacuously, which is the shape of a check that has
  --    quietly stopped working.
  INSERT INTO inform.compass_user_lenses (owner_id, key, name)
  VALUES (v_user, 'u_cc0468probe', 'CC_0468 cascade probe');

  -- 3. Delete as the role the product's account deletion actually runs as, from
  --    the table it actually deletes from. This role is not superuser, does not
  --    bypass RLS, and has no USAGE on inform — which is the whole reason the
  --    history trigger is SECURITY DEFINER.
  EXECUTE 'SET LOCAL ROLE supabase_auth_admin';
  DELETE FROM auth.users WHERE id = v_user;
  EXECUTE 'RESET ROLE';

  -- 4a. Hop one: auth.users -> public.users.
  IF EXISTS (SELECT 1 FROM public.users WHERE id = v_user) THEN
    RAISE EXCEPTION 'CC_0468 cascade probe: the public.users row survived the auth.users '
                    'delete — the FK chain this probe assumes is not the one in place';
  END IF;

  -- 4b. Hop two: public.users -> inform.compass_user_lenses.
  IF EXISTS (SELECT 1 FROM inform.compass_user_lenses WHERE key = 'u_cc0468probe') THEN
    RAISE EXCEPTION 'CC_0468 cascade probe: the lens survived the account deletion — the '
                    'ON DELETE CASCADE on owner_id is not what this assumed';
  END IF;

  -- 4c. And the trigger recorded it. THIS is the assertion the probe exists for:
  --     reaching this line at all means the SECURITY DEFINER trigger ran inside a
  --     statement issued by a role with no rights in the inform schema.
  SELECT count(*) INTO v_hist
    FROM inform.compass_user_lens_history
   WHERE lens_key = 'u_cc0468probe' AND op = 'hard_delete';

  IF v_hist <> 1 THEN
    RAISE EXCEPTION 'CC_0468 cascade probe: expected 1 hard_delete history row, found % — '
                    'the cascade destroyed lenses and left no record', v_hist;
  END IF;

  RAISE NOTICE 'CC_0468 cascade probe PASS: account % deleted from auth.users as '
               'supabase_auth_admin, both cascade hops fired, trigger wrote 1 hard_delete '
               'row. Rolling back.', v_user;
END
$probe$;

ROLLBACK;

\echo ''
\echo '--- 4b. Nothing survived the probe.'
\echo '--- PASS: probe_rows_left = 0. 🔴 THAT IS THE ONE THAT SETTLES IT — it is read after'
\echo '---       the ROLLBACK, and a surviving history row is the only durable trace the'
\echo '---       probe could have left.'
\echo '--- The users_after count below is a SANITY CHECK ONLY, and comparing it across runs'
\echo '--- is racy: a signup or a real account deletion moves it legitimately. A number you'
\echo '--- did not expect is NOT on its own evidence that this probe destroyed a user —'
\echo '--- check probe_rows_left first, and only then go looking.'
\echo '--- STOP: probe_rows_left <> 0 — the ROLLBACK did not take. Investigate before'
\echo '---       running anything else against this database.'

SELECT count(*) AS probe_rows_left
  FROM inform.compass_user_lens_history
 WHERE lens_key = 'u_cc0468probe';

SELECT count(*) AS users_after FROM public.users;
