-- 1817_rename_compass_schema_to_deprecated.sql
--
-- Renames the legacy `compass` schema to `compass_deprecated`. Eight tables, 1,475 rows total,
-- all preserved. Nothing is dropped.
--
-- APPLIED OUT-OF-BAND. This rename was executed directly against prod on 2026-08-17 via
-- `ALTER SCHEMA compass RENAME TO compass_deprecated` before this file existed. The migration is
-- therefore a verified no-op on prod and exists to keep a from-scratch rebuild in step with
-- production. It is written to detect that case and skip cleanly (see STEP 2).
--
-- WHY RENAME, NOT DROP. `compass.answers` holds 698 real user compass responses and
-- `compass.user_compasses` 4 saved compasses, all from live users between 2026-02-05 and
-- 2026-03-12. That is real history, not scaffolding. Renaming removes the footgun (see below)
-- while keeping every row restorable with a one-line revert:
--
--     ALTER SCHEMA compass_deprecated RENAME TO compass;
--
-- WHAT FOOTGUN. The live Compass tables are `inform.compass_topics` / `inform.compass_stances` /
-- `inform.compass_responses`. The legacy `compass` schema held same-named concepts under
-- overlapping `topic_key` values but DIFFERENT wording -- e.g. `fossil-fuels` is titled "Fossil
-- Fuel Policy" in `inform` and carries a longer bipolar title in the legacy schema, and the legacy
-- schema has only 21 of the 44 live topics. Querying the wrong schema therefore returns
-- plausible-looking stale content with no error. That has already caused at least one wrong-data
-- incident during topic-review work. Renaming makes the mistake impossible to make silently.
--
-- WHY THIS IS SAFE. Verified against prod 2026-08-17, before the rename:
--   edge functions referencing compass.*        0  (only treasury-sync, treasury-sync-orchestrator,
--                                                   givebutter-webhook exist)
--   pg_cron jobs referencing compass.*          0  (only 2 treasury syncs + 1 matview refresh)
--   views / matviews over compass.*             0
--   functions / procs with compass. in body     0
--   inbound FKs from outside the schema         0
--   pg_depend rewrite deps from outside         0
--   role / function / db search_path refs       0
--   source refs in ev-accounts, CompassV2,      0  (ev-accounts backend/src queries only
--     empowered-api, essentials, ev-analytics        inform.compass_*; CompassV2 does not touch
--                                                   Supabase directly -- it calls the accounts API)
--   last write to compass.answers          2026-03-12  (dormant ~5 months)
--
-- Grants and RLS survive a schema rename untouched, so no re-GRANT is needed. Prod carries
-- anon/authenticated USAGE on the schema and SELECT on its tables, with RLS enabled on all eight
-- tables -- unchanged by this migration, and called out here only so the posture is on the record.
--
-- KNOWN LOOSE END (not fixed here). `1593_ev_migrator_role.sql` contains
-- `GRANT USAGE ON SCHEMA compass TO ev_migrator` and a matching table-level grant, both hardcoding
-- the old schema name. Those lines would fail on a from-scratch replay after this migration. 1593
-- is already not replay-clean independently of this change -- the `ev_migrator` role does not exist
-- in prod (0 rows in pg_roles), so its grants would fail on the role name first. Left alone rather
-- than edited, because rewriting an applied migration is worse than documenting a known-stale one.
--
-- WHY NO EXACT ROW-COUNT GUARDS. Prod counts (answers 698, contexts 609, stances 105, topics 21,
-- topic_categories 21, quote_verdicts 9, categories 8, user_compasses 4) are recorded above as
-- documentation only. Hardcoding them would break any dev or branch database with different data.
-- Instead STEP 2 snapshots every table's count immediately before the rename and re-checks it
-- immediately after, which asserts the invariant that actually matters -- a rename moves no rows --
-- in any environment.
--
-- Idempotent: STEP 2 short-circuits when the rename has already happened, and refuses loudly if
-- BOTH schema names somehow exist. A re-run is a no-op that still passes every guard.

BEGIN;

-- =============================================================================
-- STEP 1 -- PRE-FLIGHT: nothing outside the schema may depend on it.
--
-- Re-verifies at apply time what was checked by hand before the out-of-band rename. Skips cleanly
-- when `compass` is already gone, so a re-run does not abort on a missing schema.
-- =============================================================================
DO $$
DECLARE
  n_fks integer; n_views integer; n_funcs integer; n_cron integer;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'compass') THEN
    RETURN;  -- already renamed, or never present; STEP 2 reports which
  END IF;

  -- Inbound foreign keys from outside the schema.
  SELECT count(*) INTO n_fks
    FROM pg_constraint
   WHERE contype = 'f'
     AND confrelid IN (SELECT c.oid FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                        WHERE n.nspname = 'compass')
     AND conrelid NOT IN (SELECT c.oid FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                           WHERE n.nspname = 'compass');
  IF n_fks <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % foreign key(s) from outside compass point into it (expected 0). A rename would '
      'not break them, but their existence means this schema is not actually dormant.', n_fks;
  END IF;

  -- Views / matviews outside the schema that read from it.
  SELECT count(*) INTO n_views
    FROM pg_depend d
    JOIN pg_rewrite r ON r.oid = d.objid
    JOIN pg_class   v ON v.oid = r.ev_class
   WHERE d.refobjid IN (SELECT c.oid FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                         WHERE n.nspname = 'compass')
     AND v.relkind IN ('v', 'm')
     AND v.relnamespace <> 'compass'::regnamespace;
  IF n_views <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % view(s)/matview(s) outside compass depend on it (expected 0). A rename would '
      'silently repoint or break them.', n_views;
  END IF;

  -- Function/procedure bodies naming the schema. `\mcompass\.` is a word-boundary match on
  -- "compass" followed by a literal dot, so it does NOT match `compass_deprecated.` (underscore is
  -- a word character) nor `inform.compass_topics`.
  SELECT count(*) INTO n_funcs
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
     AND p.prokind IN ('f', 'p')
     AND p.prosrc ~ '\mcompass\.';
  IF n_funcs <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % function(s)/procedure(s) reference compass.<table> in their body (expected 0). '
      'A rename would break them at next call, not at apply time.', n_funcs;
  END IF;

  -- Scheduled jobs naming the schema. pg_cron is not installed everywhere, hence the to_regclass
  -- probe and dynamic SQL -- a static reference would fail to parse where the extension is absent.
  IF to_regclass('cron.job') IS NOT NULL THEN
    EXECUTE 'SELECT count(*) FROM cron.job WHERE command ~ ''\mcompass\.'''
       INTO n_cron;
    IF n_cron <> 0 THEN
      RAISE EXCEPTION
        'Aborting: % pg_cron job(s) reference compass.<table> (expected 0). A rename would break '
        'them silently on their next scheduled run.', n_cron;
    END IF;
  END IF;
END $$;

-- =============================================================================
-- STEP 2 -- THE RENAME, with a row-for-row check across it.
--
-- Snapshots every table's count before the rename and re-checks after, so the "a rename moves no
-- rows" invariant is asserted rather than assumed, in whatever environment this runs.
-- =============================================================================
DO $$
DECLARE
  r          record;
  n_before   bigint;
  n_after    bigint;
  n_tables   integer;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'compass') THEN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'compass_deprecated') THEN
      RAISE NOTICE
        'compass has already been renamed to compass_deprecated (expected on prod, where this ran '
        'out-of-band on 2026-08-17). Nothing to do.';
    ELSE
      RAISE NOTICE
        'Neither compass nor compass_deprecated exists; the legacy schema was never present in '
        'this database. Nothing to do.';
    END IF;
    RETURN;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'compass_deprecated') THEN
    RAISE EXCEPTION
      'Aborting: both compass and compass_deprecated exist. Refusing to guess which one holds the '
      'legacy data or to merge them. Resolve by hand.';
  END IF;

  CREATE TEMP TABLE _compass_rename_counts (tbl text PRIMARY KEY, n bigint) ON COMMIT DROP;

  FOR r IN
    SELECT c.relname
      FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'compass' AND c.relkind = 'r'
     ORDER BY c.relname
  LOOP
    EXECUTE format('SELECT count(*) FROM compass.%I', r.relname) INTO n_before;
    INSERT INTO _compass_rename_counts VALUES (r.relname, n_before);
  END LOOP;

  -- EXECUTE rather than a bare statement so this file parses cleanly even where `compass` is absent.
  EXECUTE 'ALTER SCHEMA compass RENAME TO compass_deprecated';

  FOR r IN SELECT tbl, n FROM _compass_rename_counts ORDER BY tbl LOOP
    EXECUTE format('SELECT count(*) FROM compass_deprecated.%I', r.tbl) INTO n_after;
    IF n_after <> r.n THEN
      RAISE EXCEPTION
        'Aborting: compass_deprecated.% holds % row(s) after the rename but held % before. A '
        'rename must not move rows.', r.tbl, n_after, r.n;
    END IF;
  END LOOP;

  SELECT count(*) INTO n_tables FROM _compass_rename_counts;
  IF n_tables = 0 THEN
    RAISE EXCEPTION
      'Aborting: schema compass contained no ordinary tables. That does not match the expected '
      'legacy layout (8 tables); refusing to rename something unrecognised.';
  END IF;

  RAISE NOTICE
    'Renamed compass -> compass_deprecated; % table(s) verified row-for-row across the rename.',
    n_tables;
END $$;

-- =============================================================================
-- STEP 3 -- POST: the old name is free and the new one holds the data.
-- =============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'compass') THEN
    RAISE EXCEPTION 'Aborting: schema compass still exists after the rename.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'compass_deprecated') THEN
    RAISE NOTICE
      'compass_deprecated does not exist; the legacy schema was never present in this database.';
  END IF;
END $$;

-- =============================================================================
-- STEP 4 -- POST: the LIVE Compass tables are untouched.
--
-- The entire risk of this migration is acting on the wrong Compass table set, so assert the live
-- one is present and populated. `inform.*` is never named by the DDL above; this is a tripwire.
-- =============================================================================
DO $$
DECLARE n_topics bigint; n_stances bigint;
BEGIN
  IF to_regclass('inform.compass_topics') IS NULL
     OR to_regclass('inform.compass_stances') IS NULL THEN
    RAISE EXCEPTION
      'Aborting: inform.compass_topics and/or inform.compass_stances is missing. These are the '
      'LIVE Compass tables and must exist, untouched, after this migration.';
  END IF;

  SELECT count(*) INTO n_topics  FROM inform.compass_topics;
  SELECT count(*) INTO n_stances FROM inform.compass_stances;

  IF n_topics = 0 OR n_stances = 0 THEN
    RAISE EXCEPTION
      'Aborting: the live Compass tables came back empty (inform.compass_topics = %, '
      'inform.compass_stances = %). Expected both populated (prod: 44 and 220).',
      n_topics, n_stances;
  END IF;
END $$;

COMMIT;
