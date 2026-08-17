-- 1818_retire_app_auth_credentials.sql
--
-- Removes the credential material left behind by the retired custom auth system: drops
-- `app_auth.sessions` outright and drops the `hashed_password` column from `app_auth.users`.
-- The `app_auth.users` table itself SURVIVES -- see "WHY THE TABLE STAYS" below.
--
-- BACKGROUND. Before the Supabase-JWT migration, ev-accounts ran its own session-cookie auth:
-- `app_auth.users` (user_id, username, hashed_password, role, account_type, ...) plus
-- `app_auth.sessions` (session_id, user_id, expires_at). PLATFORM-CONSOLIDATION.md records the
-- decision to retire it in favour of Supabase JWT. The code was retired; the tables were not.
--
-- EVIDENCE THAT THE LOGIN PATH IS DEAD (swept 2026-08-17 across all twelve EmpoweredVote repos):
--
--   1. Exactly ONE code reference to the `app_auth` schema exists anywhere --
--      backend/src/routes/campaignFinanceAdmin.ts:80, `resolveUsername()`, a best-effort
--      `SELECT username FROM app_auth.users WHERE user_id = $1` used only to put a human-readable
--      name in admin audit-log rows. It is wrapped in try/catch and falls back to the raw userId.
--   2. `hashed_password` is read by NOTHING. There is no bcrypt/argon2/scrypt dependency and no
--      password-verification call in backend/src or admin/src.
--   3. `app_auth.sessions` is read by NOTHING. No code references the table at all.
--   4. The schema is not reachable through the API. PostgREST is configured
--      (DEPLOY.md step 1b) as `pgrst.db_schemas = 'public, connect, empower, inform'`, so
--      `app_auth` is not exposed to the `anon` or `authenticated` roles.
--   5. Least privilege already applies: the runtime role `ev_api` (migration 1386) holds SELECT
--      on `app_auth.users` and NO grant whatsoever on `app_auth.sessions`. Only `postgres` writes.
--
-- WHY THIS IS WORTH DOING ANYWAY. Points 4 and 5 mean this is not an open door, and the RLS-off
-- state of both tables is far less severe than it looks in the Supabase advisor output -- an
-- unexposed table with no anon grant is not reachable by the API regardless of RLS. What remains
-- is 17 live bcrypt hashes ($2a$) sitting in a table nothing authenticates against. They serve no
-- purpose, and because people reuse passwords across sites, a dump retains real value to an
-- attacker even though it cannot be used to log in HERE. The cheapest correct action is to stop
-- storing them.
--
-- WHY THE TABLE STAYS. Dropping `app_auth.users` entirely would degrade `resolveUsername()` to
-- emitting raw UUIDs in the admin audit log. That is a graceful degradation, not a break (the
-- try/catch already returns userId on error) -- but the username mapping is the one genuinely
-- useful thing in the table and costs nothing to keep once the hashes are gone. Retiring the
-- table completely is a separate decision that should first repoint `resolveUsername()` at
-- `auth.users.email` or `public.users.display_name`; deliberately NOT bundled here, so this
-- migration touches no application code.
--
-- ^^ CORRECTION, same day, BEFORE this file was committed. The paragraph above is WRONG about the
-- table being worth keeping, and the reason is worth recording because it is not visible from the
-- code. `app_auth.users.user_id` is `text` in the legacy custom-auth key format; a check of all 17
-- rows against `auth.users` found **zero** matches (17/17 orphaned). `resolveUsername()` is handed
-- an authenticated Supabase **uuid**, so it could NEVER match a row -- it has always fallen through
-- to returning `userId`, and the audit log's `username` column has always held the user id. The
-- "username mapping" this migration preserved is therefore unreachable, and the table is pure dead
-- weight. Migration 1819 drops it and the schema outright, with zero behaviour change. This
-- migration is still correct as applied -- merely conservative -- so it was left as-is rather than
-- rewritten after the fact.
--
-- WHY NO SNAPSHOT. House practice (cf. the July 2026 `EV-Backend-Dev` deletion) is to snapshot
-- before destructive work. That is deliberately skipped for the hashes: a backup file containing
-- the 17 credentials defeats the entire purpose of deleting them. The other dropped data is 13
-- session rows that all expired on or before 2026-03-13 and are worthless. `username`, `role`,
-- `account_type` and every other column of `app_auth.users` are untouched.
--
-- PRE-FLIGHT STATE (verified against prod 2026-08-17):
--   app_auth.users            17 rows, all 17 with a non-empty $2a$ bcrypt hash
--   app_auth.sessions         13 rows, 0 unexpired, newest expires_at = 2026-03-13
--   FKs pointing AT sessions  0        (the only FK is sessions -> users, dropped with the child)
--   dependent views/matviews  0
--   non-internal triggers     0
--
-- Idempotent: both statements are IF EXISTS, and every guard asserts the END state, so a re-run
-- is a no-op that still passes.

BEGIN;

-- Guard (PRE-FLIGHT, runs before the drops): abort if the dead login path came back to life.
-- If someone re-enabled custom auth between the sweep above and this migration being applied,
-- there would be unexpired sessions -- and dropping the table would silently log those people
-- out. Refuse rather than guess. This is the one condition under which this migration is wrong.
DO $$
DECLARE n_live integer;
BEGIN
  SELECT count(*) INTO n_live FROM app_auth.sessions WHERE expires_at > now();
  IF n_live <> 0 THEN
    RAISE EXCEPTION
      'Aborting: app_auth.sessions holds % unexpired session(s). The custom auth path was assumed '
      'dead (0 live as of 2026-08-17). Re-verify before dropping.', n_live;
  END IF;
END $$;

-- Guard (PRE-FLIGHT): abort if anything has come to depend on these objects since the sweep --
-- a new inbound FK, or a view built over them. Either would make the drops cascade or fail in
-- ways this migration has not reasoned about.
DO $$
DECLARE n_fks integer; n_views integer;
BEGIN
  SELECT count(*) INTO n_fks
    FROM pg_constraint
   WHERE contype = 'f'
     AND confrelid = 'app_auth.sessions'::regclass;
  IF n_fks <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % foreign key(s) now point at app_auth.sessions (expected 0).', n_fks;
  END IF;

  SELECT count(*) INTO n_views
    FROM pg_depend d
    JOIN pg_rewrite r ON r.oid = d.objid
    JOIN pg_class   v ON v.oid = r.ev_class
   WHERE d.refobjid IN ('app_auth.users'::regclass, 'app_auth.sessions'::regclass)
     AND v.relkind IN ('v', 'm');
  IF n_views <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % view(s)/matview(s) now depend on app_auth objects (expected 0).', n_views;
  END IF;
END $$;

-- The retired session store. No code reads it; all 13 rows expired on or before 2026-03-13.
-- Dropping the child also removes fk_app_auth_users_session, so no CASCADE is needed.
DROP TABLE IF EXISTS app_auth.sessions;

-- The credential material. Everything else on app_auth.users is retained.
ALTER TABLE app_auth.users DROP COLUMN IF EXISTS hashed_password;

-- Guard: the session table is gone.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'app_auth' AND c.relname = 'sessions'
  ) THEN
    RAISE EXCEPTION 'Aborting: app_auth.sessions still exists after DROP TABLE.';
  END IF;
END $$;

-- Guard: no password hash column survives anywhere in app_auth. Broader than the single DROP on
-- purpose -- the point of the migration is that the schema stores no credentials, not merely that
-- one named column went away.
DO $$
DECLARE n_secret integer; cols text;
BEGIN
  SELECT count(*), COALESCE(string_agg(table_name || '.' || column_name, ', '), '')
    INTO n_secret, cols
    FROM information_schema.columns
   WHERE table_schema = 'app_auth'
     AND column_name ~* '(password|secret|token|hash)';
  IF n_secret <> 0 THEN
    RAISE EXCEPTION
      'Aborting: app_auth still exposes % credential-like column(s): %.', n_secret, cols;
  END IF;
END $$;

-- Guard: resolveUsername() must still work. campaignFinanceAdmin.ts:80 runs
-- `SELECT username FROM app_auth.users WHERE user_id = $1` -- assert both columns survive AND
-- that the exact query still plans, so a column rename cannot pass this migration silently.
DO $$
DECLARE n_cols integer; probe text;
BEGIN
  SELECT count(*) INTO n_cols
    FROM information_schema.columns
   WHERE table_schema = 'app_auth' AND table_name = 'users'
     AND column_name IN ('user_id', 'username');
  IF n_cols <> 2 THEN
    RAISE EXCEPTION
      'Aborting: app_auth.users must retain user_id and username for resolveUsername(); found % of 2.',
      n_cols;
  END IF;

  -- Executes the real read path against a value that matches nothing; proves it parses.
  SELECT username INTO probe
    FROM app_auth.users
   WHERE user_id = '__migration_1818_probe__'
   LIMIT 1;
END $$;

-- Guard: no rows were lost. Dropping a column and a child table must not delete users.
DO $$
DECLARE n_users integer;
BEGIN
  SELECT count(*) INTO n_users FROM app_auth.users;
  IF n_users <> 17 THEN
    RAISE EXCEPTION
      'Aborting: expected 17 rows in app_auth.users (unchanged by this migration), found %.',
      n_users;
  END IF;
END $$;

COMMIT;
