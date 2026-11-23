BEGIN;

-- =============================================================================
-- CC_0468: custom lenses become recoverable, and every change to them is recorded
-- =============================================================================
-- Created 2026-11-22 with Chris Cantrell.
-- Design: docs/superpowers/specs/2026-11-22-lens-durability-design.md
-- Plan:   docs/superpowers/plans/2026-11-22-lens-durability.md
-- Table:  backend/migrations/1849_compass_user_lenses.sql (read that first —
--         it explains why `key` is globally unique and why topic_ids has no FK)
--
-- -----------------------------------------------------------------------------
-- 🔴 THE MEASUREMENT THIS EXISTS FOR, 2026-11-22, AGAINST PRODUCTION
-- -----------------------------------------------------------------------------
-- Three lenses stored. One `PUT /api/compass/my-lenses` carrying a single lens.
-- One survivor. HTTP 200. No warning, no error, no record. An empty payload took
-- all three. The route treated the payload as the complete set and DELETEd
-- everything it did not mention.
--
-- That hole is closed: ev-accounts#1584 makes a deletion something the caller
-- must NAME in `delete_keys`, and CompassV2#152 stops the client rendering a
-- failed fetch as an empty set. Both are live.
--
-- ⚠ BUT A GUARD IS NOT A RECORD. The guard stops the path we found; it does
-- nothing about the next one, and when something does get through there is still
-- no way back. Auditing whether any other user had already been burned, the only
-- evidence available was that one user's lens had `created_at = updated_at` to
-- the microsecond — inference from a timestamp, not a record. And one scenario
-- stayed unprovable even then: a user whose blanked client CREATED a lens,
-- destroying the earlier ones, leaves a survivor that looks freshly inserted.
--
-- This migration is what turns that question into a lookup.
--
-- -----------------------------------------------------------------------------
-- WHAT IT DOES, AND THE ONE IDEA UNDERNEATH IT
-- -----------------------------------------------------------------------------
--   1. `deleted_at` on inform.compass_user_lenses — a deletion becomes an UPDATE
--      the operator can undo, instead of a row that is gone.
--   2. inform.compass_user_lens_history — every insert, update, restore, soft
--      delete and hard delete, written by a TRIGGER.
--   3. inform.compass_lens_alert_acks — the nightly check's "Chris has seen this
--      one" record, so an alert that stays red is a real unreviewed removal and
--      not yesterday's noise.
--   4. A truncate guard, because TRUNCATE fires no row triggers and would
--      therefore destroy the table silently even with all of the above in place.
--
-- 🔴 THE HISTORY IS WRITTEN BY A TRIGGER, NOT BY THE SERVICE, AND THAT IS THE
-- WHOLE POINT. Application-written history records what the application meant to
-- do. The 2026-11-22 incident was the application doing something nobody meant.
-- A trigger records what the DATABASE did — through the route, through a psql
-- session, through a cascade, through a future route nobody has written yet.
-- There is no code path into this table that can opt out.
--
-- Additive + idempotent (safe to re-run). One transaction: a history table that
-- exists without its trigger is worse than neither, because it reads as coverage.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Soft delete.
-- -----------------------------------------------------------------------------
-- 🔴 NOTHING IS DONE TO THE UNIQUE INDEX ON `key`, DELIBERATELY. A soft-deleted
-- lens still occupies its key. `key` is meant to become a share link (see 1849),
-- so letting a second lens take the key of one that was deleted would make an
-- already-handed-out link resolve to somebody else's lens. A restore also has to
-- be able to put the row back under the name it had. The cost is that a user who
-- deletes 'u_7f3a91' cannot re-create that exact key — which no client does,
-- because keys are generated.

ALTER TABLE inform.compass_user_lenses
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

COMMENT ON COLUMN inform.compass_user_lenses.deleted_at IS
  'CC_0468. Set instead of DELETEing. Reads filter it; the unique index on key '
  'deliberately still covers soft-deleted rows so a share link cannot be '
  'reassigned and a restore can put the row back under its own key.';


-- -----------------------------------------------------------------------------
-- 2. The history table.
-- -----------------------------------------------------------------------------
-- 🔴 owner_id HAS NO FOREIGN KEY AND NO CASCADE, AND THAT IS THE POINT.
-- compass_user_lenses.owner_id references public.users(id) ON DELETE CASCADE, so
-- deleting an account takes its lenses with it. If history carried the same FK,
-- the cascade would delete the history in the same statement — the record of the
-- deletion would be destroyed BY the deletion. History has to outlive its
-- subject or it is not history. An orphaned owner_id here is correct and
-- expected; it is the only remaining evidence that those rows existed.
--
-- `before`/`after` are whole-row to_jsonb snapshots rather than a column diff.
-- Recovery is the use case, not reporting: an operator restoring a destroyed
-- lens needs the row, and a snapshot survives this table gaining or losing
-- columns later without the history becoming unreadable.

CREATE TABLE IF NOT EXISTS inform.compass_user_lens_history (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null,              -- 🔴 no FK on purpose — see above
  lens_key    text not null,
  op          text not null,
  before      jsonb,
  after       jsonb,
  created_at  timestamptz not null default now()
);

DO $$
BEGIN
  -- The five ops are a closed set, checked here rather than left to convention,
  -- because Task 4's nightly check reads them by name: anything it does not
  -- recognise would be a removal it silently fails to alert on.
  --
  --   insert       a lens was created
  --   update       its name or topic_ids changed, still live
  --   soft_delete  deleted_at went NULL -> NOT NULL        ← recoverable
  --   restore      deleted_at went NOT NULL -> NULL
  --   hard_delete  the row is gone: a cascade, or a hand-written DELETE
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conrelid = 'inform.compass_user_lens_history'::regclass
       AND conname  = 'compass_user_lens_history_op'
  ) THEN
    ALTER TABLE inform.compass_user_lens_history
      ADD CONSTRAINT compass_user_lens_history_op
      CHECK (op IN ('insert', 'update', 'restore', 'soft_delete', 'hard_delete'));
  END IF;
END $$;

COMMENT ON TABLE inform.compass_user_lens_history IS
  'CC_0468. Every change to inform.compass_user_lenses, written by the trigger '
  'inform.log_compass_user_lens_change() — application code cannot bypass it. '
  'owner_id is intentionally un-FKd so an account deletion cannot destroy the '
  'record of itself.';

COMMENT ON COLUMN inform.compass_user_lens_history.op IS
  'One of insert | update | restore | soft_delete | hard_delete. Read by name by '
  'the nightly durability check; the CHECK constraint keeps the set closed.';


-- -----------------------------------------------------------------------------
-- 3. The two indexes, and what each one is for.
-- -----------------------------------------------------------------------------
-- (owner_id, created_at DESC) is the RECOVERY read: "show me everything that
-- happened to this user's lenses, newest first" — the question asked at the
-- moment somebody reports their lenses are gone.
--
-- (created_at DESC) alone is the NIGHTLY's window scan: "what was removed in the
-- last 7 days, across every user". Without it that scan is a seq scan over a
-- table that only ever grows, run every night forever.

CREATE INDEX IF NOT EXISTS compass_user_lens_history_owner_idx
  ON inform.compass_user_lens_history (owner_id, created_at DESC);

CREATE INDEX IF NOT EXISTS compass_user_lens_history_created_idx
  ON inform.compass_user_lens_history (created_at DESC);


-- -----------------------------------------------------------------------------
-- 4. The acknowledgement table.
-- -----------------------------------------------------------------------------
-- ⚠ AN ALERT THAT CANNOT BE ACKNOWLEDGED BECOMES AN ALERT THAT IS IGNORED.
-- The nightly check reports removals in a rolling window. Without a record of
-- which ones a human has already looked at, every ordinary deletion keeps the
-- check red for seven days, and a red check that is red every morning stops
-- being read — which is the failure mode this whole plan exists to prevent
-- (goal 2: "Chris finds out within a day, and cannot miss it").
--
-- history_id IS the primary key, so an ack is idempotent and one history row
-- cannot be acknowledged twice. This FK IS present and SHOULD cascade-by-absence:
-- history rows are never deleted, so the reference can never dangle.

CREATE TABLE IF NOT EXISTS inform.compass_lens_alert_acks (
  history_id  uuid primary key references inform.compass_user_lens_history(id),
  acked_at    timestamptz not null default now(),
  acked_by    text not null,
  note        text
);

COMMENT ON TABLE inform.compass_lens_alert_acks IS
  'CC_0468. One row per history row a human has reviewed. The nightly '
  'durability check treats an unacked removal inside its window as red; this is '
  'what stops an ordinary deletion keeping it red for a week.';


-- -----------------------------------------------------------------------------
-- 5. RLS on, no policies, NO GRANTS.
-- -----------------------------------------------------------------------------
-- 🔴 DO NOT ADD A GRANT HERE, AND DO NOT REVOKE ANYTHING.
-- This matches inform.compass_user_lenses, inform.compass_lenses and
-- compass_lens_topics: RLS enabled with no policies means unreachable from
-- PostgREST by design. The backend reaches these tables through its service-role
-- pool (lib/db.ts).
--
-- `ev_api` gets arwd on these tables WITHOUT ANY GRANT STATEMENT, because
-- ALTER DEFAULT PRIVILEGES IN SCHEMA inform already grants it on new tables
-- created by `postgres`. That is how the API reads every other table in this
-- schema, and `ev_api` carries rolbypassrls = true, so RLS here is not what
-- stands between the service and the data — the absence of an anon/authenticated
-- grant is.
--
-- Writing a GRANT by hand would work and would also hide a broken default — the
-- next table created in this schema would come out unreadable and nobody would
-- know why. The verification block at the bottom checks the default actually
-- fired instead.

ALTER TABLE inform.compass_user_lens_history  ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.compass_lens_alert_acks    ENABLE ROW LEVEL SECURITY;


-- -----------------------------------------------------------------------------
-- 6. The trigger function.
-- -----------------------------------------------------------------------------
-- 🔴 SECURITY DEFINER IS NOT OPTIONAL, AND THE REASON IS THE ACCOUNT-DELETION
-- CASCADE. Deleting an account runs as `supabase_auth_admin`. That role is not a
-- superuser, does not bypass RLS, and has no USAGE on the `inform` schema at all.
-- An INVOKER trigger would therefore raise `permission denied for schema inform`
-- the moment the cascade reached compass_user_lenses — and because the trigger
-- is in the same transaction, EVERY ACCOUNT DELETION IN THE PRODUCT WOULD ABORT.
-- A durability feature that breaks account deletion is not a durability feature.
-- SECURITY DEFINER owned by `postgres` makes the insert run as postgres instead.
--
-- 🔴 `SET search_path TO ''` goes with it, always. A SECURITY DEFINER function
-- with a mutable search_path is a privilege-escalation hole: the caller chooses
-- which schema `compass_user_lens_history` resolves to. Pinned to empty, every
-- reference in the body MUST be schema-qualified — which is why they all are.
--
-- The body is branched rather than COALESCEd for a reason worth keeping:
-- `AFTER` triggers return NULL because the return value is ignored; the work is
-- already done.

CREATE OR REPLACE FUNCTION inform.log_compass_user_lens_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE
  v_op text;
BEGIN
  -- 🔴 BRANCHED, NOT COALESCED. In a DELETE trigger plpgsql leaves NEW
  -- unassigned, and touching NEW.owner_id there raises. Likewise OLD on INSERT.
  IF TG_OP = 'DELETE' THEN
    INSERT INTO inform.compass_user_lens_history (owner_id, lens_key, op, before, after)
    VALUES (OLD.owner_id, OLD.key, 'hard_delete', to_jsonb(OLD), NULL);
    RETURN NULL;
  END IF;

  IF TG_OP = 'INSERT' THEN
    INSERT INTO inform.compass_user_lens_history (owner_id, lens_key, op, before, after)
    VALUES (NEW.owner_id, NEW.key, 'insert', NULL, to_jsonb(NEW));
    RETURN NULL;
  END IF;

  IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
    v_op := 'soft_delete';
  ELSIF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
    v_op := 'restore';
  ELSE
    v_op := 'update';
  END IF;

  INSERT INTO inform.compass_user_lens_history (owner_id, lens_key, op, before, after)
  VALUES (NEW.owner_id, NEW.key, v_op, to_jsonb(OLD), to_jsonb(NEW));
  RETURN NULL;
END;
$function$;

COMMENT ON FUNCTION inform.log_compass_user_lens_change() IS
  'CC_0468. Writes inform.compass_user_lens_history for every row change on '
  'inform.compass_user_lenses. SECURITY DEFINER owned by postgres because the '
  'account-deletion cascade runs as supabase_auth_admin, which has no USAGE on '
  'inform — an INVOKER trigger would abort every account deletion.';


-- -----------------------------------------------------------------------------
-- 7. The truncate guard.
-- -----------------------------------------------------------------------------
-- ⚠ TRUNCATE FIRES NO ROW TRIGGERS. Everything above records row-level change;
-- a single TRUNCATE would empty compass_user_lenses and leave the history table
-- showing nothing happened. That is strictly worse than having no history,
-- because the empty history reads as proof that nothing was lost.
--
-- There is no legitimate TRUNCATE of this table. If one is ever genuinely
-- needed, the operator drops the trigger deliberately and in writing, which is
-- exactly the amount of friction this is for.
--
-- Same SECURITY DEFINER + pinned search_path as above, for the same reason: it
-- must be able to raise from inside a cascade-driven statement run by a role
-- with no rights in this schema.

CREATE OR REPLACE FUNCTION inform.refuse_compass_user_lens_truncate()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
BEGIN
  RAISE EXCEPTION 'compass_user_lenses must not be truncated: it would destroy lenses with no history';
END;
$function$;

COMMENT ON FUNCTION inform.refuse_compass_user_lens_truncate() IS
  'CC_0468. Refuses TRUNCATE on inform.compass_user_lenses. TRUNCATE fires no '
  'row triggers, so without this the table could be emptied while the history '
  'table shows nothing happened.';


-- -----------------------------------------------------------------------------
-- 8. The four triggers.
-- -----------------------------------------------------------------------------
-- CREATE OR REPLACE TRIGGER is PostgreSQL 14+ and this is 17.6, so these are
-- idempotent without a DROP — which matters, because a DROP ... CREATE pair
-- leaves a window (inside this transaction, but still) where the table is
-- unguarded, and would quietly re-create a trigger an operator had deliberately
-- removed under a different name.
--
-- They are AFTER triggers: the row change has already succeeded, so the history
-- row records something that actually happened rather than something attempted.
--
-- ⚠ THE WHEN CLAUSE ON THE UPDATE TRIGGER IS DEFENCE IN DEPTH, NOT DUPLICATION.
-- The service's ON CONFLICT ... WHERE (IS DISTINCT FROM) guards the app write
-- path; this guards ANY write path. A no-op UPDATE — the same lens written back
-- unchanged, which an idempotent client PUT does constantly — would otherwise
-- write a history row per request and bury the real changes in noise.

CREATE OR REPLACE TRIGGER compass_user_lenses_history_ins
  AFTER INSERT ON inform.compass_user_lenses
  FOR EACH ROW EXECUTE FUNCTION inform.log_compass_user_lens_change();

CREATE OR REPLACE TRIGGER compass_user_lenses_history_upd
  AFTER UPDATE ON inform.compass_user_lenses
  FOR EACH ROW WHEN (OLD.* IS DISTINCT FROM NEW.*)
  EXECUTE FUNCTION inform.log_compass_user_lens_change();

CREATE OR REPLACE TRIGGER compass_user_lenses_history_del
  AFTER DELETE ON inform.compass_user_lenses
  FOR EACH ROW EXECUTE FUNCTION inform.log_compass_user_lens_change();

CREATE OR REPLACE TRIGGER compass_user_lenses_no_truncate
  AFTER TRUNCATE ON inform.compass_user_lenses
  FOR EACH STATEMENT EXECUTE FUNCTION inform.refuse_compass_user_lens_truncate();


-- -----------------------------------------------------------------------------
-- 9. Ownership.
-- -----------------------------------------------------------------------------
-- SECURITY DEFINER means "run as the OWNER". Stated explicitly rather than left
-- to whoever happened to run the migration: if these were applied by any role
-- other than postgres, the functions would define-to that role instead, and the
-- cascade would fail exactly as it would with an INVOKER trigger. Re-running as
-- postgres is a no-op.

ALTER FUNCTION inform.log_compass_user_lens_change()      OWNER TO postgres;
ALTER FUNCTION inform.refuse_compass_user_lens_truncate() OWNER TO postgres;


-- -----------------------------------------------------------------------------
-- Verification. Read-only; it asserts what the migration itself controls and
-- WARNS about the one thing it deliberately does not (see the grants note).
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_bad      text;
  v_triggers int;
  v_when     text;
BEGIN
  -- (a) Both functions are SECURITY DEFINER, owned by postgres, search_path pinned.
  --     This is the account-deletion cascade's survival condition.
  SELECT string_agg(p.proname, ', ') INTO v_bad
    FROM pg_proc p JOIN pg_roles r ON r.oid = p.proowner
   WHERE p.pronamespace = 'inform'::regnamespace
     AND p.proname IN ('log_compass_user_lens_change', 'refuse_compass_user_lens_truncate')
     -- proconfig stores the pin as the single element `search_path=`. The btrim is
     -- because the empty value has been seen written back as "" on some servers;
     -- what matters is that the pin EXISTS and resolves to empty, not its spelling.
     AND NOT (
       p.prosecdef
       AND r.rolname = 'postgres'
       AND btrim(coalesce((SELECT substring(c, 13) FROM unnest(p.proconfig) AS c
                            WHERE c LIKE 'search_path=%'), 'UNPINNED'), '"''') = ''
     );
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION
      'CC_0468: % is not SECURITY DEFINER owned by postgres with an empty search_path — '
      'every account deletion would abort on permission denied for schema inform', v_bad;
  END IF;

  -- (b) All four triggers are attached, and the UPDATE one carries its WHEN clause.
  SELECT count(*) INTO v_triggers
    FROM pg_trigger
   WHERE tgrelid = 'inform.compass_user_lenses'::regclass
     AND NOT tgisinternal
     AND tgname IN ('compass_user_lenses_history_ins', 'compass_user_lenses_history_upd',
                    'compass_user_lenses_history_del', 'compass_user_lenses_no_truncate');
  IF v_triggers <> 4 THEN
    RAISE EXCEPTION 'CC_0468: expected 4 triggers on compass_user_lenses, found %', v_triggers;
  END IF;

  SELECT pg_get_triggerdef(oid) INTO v_when
    FROM pg_trigger
   WHERE tgrelid = 'inform.compass_user_lenses'::regclass
     AND tgname = 'compass_user_lenses_history_upd';
  IF v_when NOT ILIKE '%IS DISTINCT FROM%' THEN
    RAISE EXCEPTION
      'CC_0468: the UPDATE trigger has no WHEN clause — every no-op write would log a row';
  END IF;

  -- (c) ev_api reached the new tables through ALTER DEFAULT PRIVILEGES, with no
  --     GRANT written here. A WARNING, not an exception: the remedy is to fix the
  --     default privileges in the schema, not to paper over it with a GRANT, and
  --     aborting the migration would not make that any more likely to happen.
  --
  -- 🔴 IF THIS WARNS, STOP AND SAY SO BEFORE SHIPPING TASK 2. It means the
  --    service cannot read its own history table and the route will 500.
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ev_api') THEN
    SELECT string_agg(t, ', ') INTO v_bad
      FROM unnest(ARRAY['inform.compass_user_lens_history', 'inform.compass_lens_alert_acks']) AS t
     WHERE NOT (has_table_privilege('ev_api', t, 'SELECT')
            AND has_table_privilege('ev_api', t, 'INSERT')
            AND has_table_privilege('ev_api', t, 'UPDATE')
            AND has_table_privilege('ev_api', t, 'DELETE'));
    IF v_bad IS NOT NULL THEN
      RAISE WARNING
        'CC_0468: ev_api does NOT have arwd on % — ALTER DEFAULT PRIVILEGES IN SCHEMA inform '
        'did not apply. The service will 500 on these tables. Fix the default privileges; '
        'do NOT paper over it with a hand-written GRANT.', v_bad;
    END IF;
  ELSE
    RAISE WARNING 'CC_0468: no ev_api role here, so the default-privileges check did not run.';
  END IF;

  RAISE NOTICE 'CC_0468 OK: soft delete added, history and ack tables created, 4 triggers armed, '
               'both functions SECURITY DEFINER owned by postgres with search_path pinned.';
END $$;

COMMIT;
