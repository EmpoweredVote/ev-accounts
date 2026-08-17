-- 1819_drop_app_auth_schema.sql
--
-- Retires the `app_auth` schema completely: drops `app_auth.users` (17 rows) and then the empty
-- schema. Finishes what 1818 started, and pairs with a code change in the same commit that removes
-- the schema's last remaining reader.
--
-- WHY THIS IS A NO-OP, NOT A FEATURE REMOVAL. This is the non-obvious part, and it is the whole
-- justification for the migration, so it is asserted as a guard below rather than merely claimed.
--
--   `app_auth.users.user_id` is `text`, holding identifiers minted by the retired pre-JWT custom
--   auth system. `auth.users.id` is `uuid`, minted by Supabase Auth. They are DISJOINT key spaces:
--   checking all 17 legacy rows against `auth.users` yields **zero** matches (17/17 orphaned).
--
--   The schema's only reader was `resolveUsername()` in backend/src/routes/campaignFinanceAdmin.ts,
--   which ran `SELECT username FROM app_auth.users WHERE user_id = $1` with `$1` bound to the
--   authenticated caller's Supabase uuid. Because the key spaces do not overlap, that query could
--   never return a row. It always fell through to `?? userId`, so the audit log's `username` column
--   has been recording the raw user id for as long as the code has existed.
--
--   Consequence: dropping this schema changes no observable behaviour. The paired code change
--   passes `authReq.userId` for both the `userId` and `username` arguments of `logSourceAudit()`,
--   which is exactly the value that was already being written.
--
-- CONTEXT. 1818 (applied 2026-08-17) dropped `app_auth.sessions` and `app_auth.users.hashed_password`
-- and deliberately preserved the table for its "username mapping" -- reasoning that turned out to be
-- based on a false premise, corrected in 1818's own header. This migration closes that out.
--
-- WHY `RESTRICT`, NOT `CASCADE`. The table is dropped by name first, then the schema is dropped
-- with the default RESTRICT semantics. CASCADE would silently destroy anything that had come to
-- depend on the schema since the pre-flight checks; RESTRICT turns that same situation into a loud
-- failure, which is the outcome we want from a destructive DDL migration.
--
-- WHY NO SNAPSHOT. Same reasoning as 1818, which documents it in full. `hashed_password` is already
-- gone as of 1818, so what is dropped here is 17 rows of `username`, `role`, `account_type`,
-- `profile_pic_url`, `completed_onboarding` keyed by identifiers that address nobody in the live
-- system. There is nothing here to restore into.
--
-- PRE-FLIGHT STATE (verified against prod 2026-08-17, after 1818):
--   objects in app_auth        users (table) + users_pkey (index) -- nothing else
--   functions in app_auth      0
--   inbound FKs from outside   0
--   app_auth.users rows        17
--   rows matching auth.users   0   <-- the invariant that makes this a no-op
--   live account store         auth.users, 20 rows, 85 live sessions, unaffected
--
-- Idempotent: DROP ... IF EXISTS throughout, and the guards assert the END state, so a re-run is a
-- no-op that still passes. Note the pre-flight guards are written to SKIP cleanly (rather than
-- fail) when the schema is already gone -- otherwise a second run would abort on a missing table.

BEGIN;

-- Guard (PRE-FLIGHT): the disjoint-key-space invariant. If ANY legacy user_id matched a real
-- auth.users id, then resolveUsername() was genuinely resolving names, this migration would be
-- losing real audit-log detail, and the premise above would be false. Refuse in that case.
DO $$
DECLARE n_match integer;
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'app_auth' AND c.relname = 'users'
  ) THEN
    SELECT count(*) INTO n_match
      FROM app_auth.users a
     WHERE EXISTS (SELECT 1 FROM auth.users u WHERE u.id::text = a.user_id);
    IF n_match <> 0 THEN
      RAISE EXCEPTION
        'Aborting: % app_auth.user_id value(s) match a live auth.users id (expected 0). '
        'resolveUsername() was resolving real names, so dropping this table WOULD lose audit '
        'detail. Re-evaluate before proceeding.', n_match;
    END IF;
  END IF;
END $$;

-- Guard (PRE-FLIGHT): nothing outside app_auth may depend on it. An inbound FK, a view, or a
-- function living in the schema would all mean this migration has not reasoned about the full
-- blast radius. 1818 verified all three at zero; re-verify at apply time.
DO $$
DECLARE n_fks integer; n_views integer; n_funcs integer;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'app_auth') THEN
    RETURN;  -- already dropped; nothing to check
  END IF;

  SELECT count(*) INTO n_fks
    FROM pg_constraint
   WHERE contype = 'f'
     AND confrelid IN (SELECT c.oid FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                        WHERE n.nspname = 'app_auth')
     AND conrelid NOT IN (SELECT c.oid FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                           WHERE n.nspname = 'app_auth');
  IF n_fks <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % foreign key(s) from outside app_auth point into it (expected 0).', n_fks;
  END IF;

  SELECT count(*) INTO n_views
    FROM pg_depend d
    JOIN pg_rewrite r ON r.oid = d.objid
    JOIN pg_class   v ON v.oid = r.ev_class
   WHERE d.refobjid IN (SELECT c.oid FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                         WHERE n.nspname = 'app_auth')
     AND v.relkind IN ('v', 'm')
     AND v.relnamespace <> 'app_auth'::regnamespace;
  IF n_views <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % view(s)/matview(s) outside app_auth depend on it (expected 0).', n_views;
  END IF;

  SELECT count(*) INTO n_funcs
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'app_auth';
  IF n_funcs <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % function(s) live in app_auth (expected 0); dropping the schema would remove '
      'them silently.', n_funcs;
  END IF;
END $$;

-- Drop the table by name, so the schema drop below has nothing to cascade over.
DROP TABLE IF EXISTS app_auth.users;

-- RESTRICT (the default) is deliberate -- see header. Fails loudly if anything unexpected remains.
DROP SCHEMA IF EXISTS app_auth RESTRICT;

-- Guard: the schema and everything in it are gone.
DO $$
DECLARE n_objs integer;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'app_auth') THEN
    RAISE EXCEPTION 'Aborting: schema app_auth still exists after DROP SCHEMA.';
  END IF;

  SELECT count(*) INTO n_objs
    FROM information_schema.columns WHERE table_schema = 'app_auth';
  IF n_objs <> 0 THEN
    RAISE EXCEPTION 'Aborting: % column(s) still reported under app_auth.', n_objs;
  END IF;
END $$;

-- Guard: the LIVE account store is untouched. The entire risk of this migration is confusing the
-- retired store for the real one, so assert the real one is intact -- accounts present, sessions
-- still live (nobody was logged out), and refresh tokens still active.
DO $$
DECLARE n_users integer; n_sessions integer; n_tokens integer;
BEGIN
  SELECT count(*) INTO n_users    FROM auth.users;
  SELECT count(*) INTO n_sessions FROM auth.sessions WHERE not_after IS NULL OR not_after > now();
  SELECT count(*) INTO n_tokens   FROM auth.refresh_tokens WHERE revoked = false;

  IF n_users < 20 THEN
    RAISE EXCEPTION
      'Aborting: auth.users holds % row(s); expected at least the 20 present at 2026-08-17. '
      'The live account store must not shrink.', n_users;
  END IF;
  IF n_sessions = 0 THEN
    RAISE EXCEPTION
      'Aborting: auth.sessions holds no live sessions. Expected the pre-existing live sessions to '
      'survive -- this migration must not log anyone out.';
  END IF;
  IF n_tokens = 0 THEN
    RAISE EXCEPTION 'Aborting: no active refresh tokens remain in auth.refresh_tokens.';
  END IF;
END $$;

COMMIT;
