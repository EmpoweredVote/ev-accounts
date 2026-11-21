-- CA_0389_contributions_new_indexes.sql
-- Builds the secondary indexes on transparent_motivations.contributions_new, ONE AT A TIME, from pg_cron, in the
-- 19:00-02:59 UTC window. This file builds no index itself: it adds a list of five index statements and a function
-- that runs the next one, at most one every 15 minutes.
--
-- Created 2026-11-18 with Chris Andrews. Steward slot CA_0389. ev-cto decision 0038, Part D step 3.
-- The batched copy (CA_0381, CA_0387) finished 2026-11-17 23:04 UTC: 29.7M rows, 7.6 GB.
--
-- WHY ONE AT A TIME. Each CREATE INDEX reads the whole 7.6 GB table at full disk speed and cannot be slowed. The
-- single-transaction copy on 2026-11-13 took the database down because it ran flat out; spacing the five builds
-- 15 minutes apart keeps each burst short and gives the disk time between them.
--
-- WHICH INDEXES (old table's index -> decision, with its scans over the 5 days since the 2026-11-13 restart):
--   contributions_pkey                      already built (CA_0381, ca381_contributions_pkey)
--   idx_contribution_dedup        1,881,968 BUILD  (the importers' ON CONFLICT (data_source, source_transaction_id))
--   idx_..._politician_source_id     90,409 BUILD
--   idx_contrib_src_cycle            88,065 BUILD
--   idx_contrib_fec_supersession     11,223 BUILD on the typed columns, as idx_contrib_fec_supersession_typed
--   idx_contributions_donor_name_btree    0 BUILD  (searchDonors joins contributions on donor_name_normalized =)
--   idx_contributions_donor_name_trgm     0 SKIP   donor search fuzzy-matches the donor_names_search matview,
--                                                  which has its own trigram index; nothing uses trigram operators
--                                                  on contributions (campaignFinanceService.searchDonors)
--   idx_..._donor_id / _committee_id      0 SKIP   both columns are 100% NULL
--   idx_contrib_src_cycle_pac             0 SKIP   never used (JSON-path predicate)
--
-- TEMPORARY NAMES (ca389_*). The swap renames them. 🔴 idx_contrib_fec_supersession_typed must NOT exist before
-- the swap: fecAdapter.supersessionUsesTypedColumns() switches to the typed query as soon as that NAME exists,
-- and before the swap it would run that query against the old table, whose typed columns are mostly NULL.
--
-- Each build takes a SHARE lock on contributions_new for its 1-3 minutes, which also holds any write to
-- contributions (the mirror trigger writes into contributions_new). Nothing writes in the window.
--
-- pg_cron (applied with this file, not in its transaction; founder-approved 2026-11-18):
--   SELECT cron.unschedule(38);   -- the copy job: contributions_copy_state.done_at is set
--   SELECT cron.schedule('ca0389-contributions-new-indexes', '*/5 * * * *',
--     $c$SET statement_timeout = '30min'; SET maintenance_work_mem = '256MB';
--        SELECT transparent_motivations.contributions_index_tick()$c$);
--
-- A build that errors is recorded (failed_at, error) and every later tick stops; nothing retries on its own.
--
-- UNDO: unschedule the job; drop function contributions_index_tick(); drop table contributions_index_build;
--   drop index any ca389_* index. Creates only; overwrites no stored value.
--
-- STATUS: APPLIED to production 2026-11-18 15:01 UTC (psql as postgres), after a rolled-back rehearsal and three
--   tamper controls (live index name, brake disabled, grant to authenticated), each stopped by its own gate.
--   Founder approved applying and the pg_cron change 2026-11-18. Copy job 38 unscheduled; index job is jobid 39.
--   First run 15:05 UTC succeeded (outside the window, built nothing). Builds start 19:00 UTC.

BEGIN;
SET LOCAL statement_timeout = '60s';
SET LOCAL lock_timeout = '3s';

DO $$
BEGIN
  IF (SELECT done_at FROM transparent_motivations.contributions_copy_state) IS NULL THEN
    RAISE EXCEPTION 'CA_0389: the copy is not finished (contributions_copy_state.done_at is NULL)';
  END IF;
  IF to_regclass('transparent_motivations.contributions_index_build') IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0389: contributions_index_build already exists';
  END IF;
  IF to_regclass('transparent_motivations.idx_contrib_fec_supersession_typed') IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0389: idx_contrib_fec_supersession_typed already exists';
  END IF;
END $$;

CREATE TABLE transparent_motivations.contributions_index_build (
  ord         integer PRIMARY KEY,
  name        text NOT NULL UNIQUE,
  final_name  text NOT NULL UNIQUE,
  ddl         text NOT NULL,
  finished_at timestamptz,
  seconds     numeric,
  size_mb     numeric,
  failed_at   timestamptz,
  error       text
);
ALTER TABLE transparent_motivations.contributions_index_build ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON transparent_motivations.contributions_index_build FROM PUBLIC, anon, authenticated, service_role, ev_api;

INSERT INTO transparent_motivations.contributions_index_build (ord, name, final_name, ddl) VALUES
 (1, 'ca389_contribution_dedup', 'idx_contribution_dedup',
  'CREATE UNIQUE INDEX ca389_contribution_dedup ON transparent_motivations.contributions_new USING btree (data_source, source_transaction_id)'),
 (2, 'ca389_contributions_politician_source_id', 'idx_transparent_motivations_contributions_politician_source_id',
  'CREATE INDEX ca389_contributions_politician_source_id ON transparent_motivations.contributions_new USING btree (politician_source_id)'),
 (3, 'ca389_contrib_src_cycle', 'idx_contrib_src_cycle',
  'CREATE INDEX ca389_contrib_src_cycle ON transparent_motivations.contributions_new USING btree (politician_source_id, election_cycle)'),
 (4, 'ca389_contributions_donor_name_btree', 'idx_contributions_donor_name_btree',
  'CREATE INDEX ca389_contributions_donor_name_btree ON transparent_motivations.contributions_new USING btree (donor_name_normalized)'),
 (5, 'ca389_contrib_fec_supersession_typed', 'idx_contrib_fec_supersession_typed',
  'CREATE INDEX ca389_contrib_fec_supersession_typed ON transparent_motivations.contributions_new USING btree (politician_source_id, fec_committee_id, fec_report_type, fec_report_year) WHERE (((data_source)::text = ''fec''::text) AND fec_file_number_present)');

CREATE FUNCTION transparent_motivations.contributions_index_tick()
RETURNS text LANGUAGE plpgsql
SET search_path TO 'pg_catalog', 'transparent_motivations'
AS $k$
DECLARE
  hr int := extract(hour FROM now() AT TIME ZONE 'utc')::int;
  db_mb bigint := pg_database_size(current_database()) / 1048576;
  b transparent_motivations.contributions_index_build;
  t0 timestamptz := clock_timestamp();
BEGIN
  -- Disk brake first (same 72 GB as CA_0387); ca0387.disk_cap_mb overrides it for one session.
  IF db_mb >= coalesce(nullif(current_setting('ca0387.disk_cap_mb', true), '')::bigint, 73728) THEN
    RETURN format('disk brake: database is %s MB', db_mb);
  END IF;
  IF NOT (hr >= 19 OR hr < 3) THEN RETURN 'outside the 19:00-02:59 UTC window'; END IF;
  IF NOT pg_try_advisory_xact_lock(389389) THEN RETURN 'another build is running'; END IF;
  -- A failed build stops everything: retrying would re-read the whole table every 5 minutes.
  IF EXISTS (SELECT 1 FROM transparent_motivations.contributions_index_build WHERE failed_at IS NOT NULL) THEN
    RETURN 'stopped: a build failed (see contributions_index_build.error)';
  END IF;
  IF EXISTS (SELECT 1 FROM transparent_motivations.contributions_index_build
              WHERE finished_at > now() - interval '15 minutes') THEN
    RETURN 'waiting: the last build finished under 15 minutes ago';
  END IF;
  SELECT * INTO b FROM transparent_motivations.contributions_index_build
   WHERE finished_at IS NULL ORDER BY ord LIMIT 1;
  IF b.ord IS NULL THEN RETURN 'done: all indexes built'; END IF;
  IF to_regclass('transparent_motivations.' || b.name) IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0389: % already exists but is not recorded as built', b.name;
  END IF;

  PERFORM set_config('lock_timeout', '5s', true);
  BEGIN
    EXECUTE b.ddl;
  EXCEPTION WHEN OTHERS THEN
    UPDATE transparent_motivations.contributions_index_build
       SET failed_at = clock_timestamp(), error = SQLSTATE || ': ' || SQLERRM WHERE ord = b.ord;
    RETURN format('FAILED %s: %s', b.name, SQLERRM);
  END;

  UPDATE transparent_motivations.contributions_index_build
     SET finished_at = clock_timestamp(),
         seconds = round(extract(epoch FROM clock_timestamp() - t0)::numeric, 1),
         size_mb = round(pg_relation_size(('transparent_motivations.' || b.name)::regclass) / 1048576.0, 1)
   WHERE ord = b.ord;
  RETURN format('built %s in %s s', b.name, round(extract(epoch FROM clock_timestamp() - t0)::numeric, 1));
END
$k$;
REVOKE ALL ON FUNCTION transparent_motivations.contributions_index_tick() FROM PUBLIC, anon, authenticated, service_role, ev_api;

-- Post-verify.
DO $$
DECLARE res text;
BEGIN
  IF (SELECT count(*) FROM transparent_motivations.contributions_index_build WHERE finished_at IS NULL) <> 5 THEN
    RAISE EXCEPTION 'CA_0389: expected 5 pending index builds';
  END IF;
  -- Every statement builds on contributions_new under its own temporary name, and none uses the live name the
  -- FEC importer watches for.
  IF EXISTS (SELECT 1 FROM transparent_motivations.contributions_index_build
              WHERE ddl NOT LIKE 'CREATE %INDEX ' || name || ' ON transparent_motivations.contributions_new %'
                 OR name NOT LIKE 'ca389\_%') THEN
    RAISE EXCEPTION 'CA_0389: an index statement does not build a ca389_ index on contributions_new';
  END IF;
  IF EXISTS (SELECT 1 FROM transparent_motivations.contributions_index_build
              WHERE ddl LIKE '%idx\_contrib\_fec\_supersession\_typed%') THEN
    RAISE EXCEPTION 'CA_0389: a statement would create idx_contrib_fec_supersession_typed before the swap';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_class c CROSS JOIN LATERAL aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a
              WHERE c.oid = 'transparent_motivations.contributions_index_build'::regclass AND a.grantee <> c.relowner)
     OR NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'transparent_motivations.contributions_index_build'::regclass) THEN
    RAISE EXCEPTION 'CA_0389: contributions_index_build is open to a role other than its owner, or RLS is off';
  END IF;
  IF has_function_privilege('anon', 'transparent_motivations.contributions_index_tick()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'transparent_motivations.contributions_index_tick()', 'EXECUTE')
     OR has_function_privilege('ev_api', 'transparent_motivations.contributions_index_tick()', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0389: the index function is executable by an API role';
  END IF;
  -- Positive control: with the disk cap at 1 MB the brake fires and nothing is built.
  BEGIN
    PERFORM set_config('ca0387.disk_cap_mb', '1', true);
    res := transparent_motivations.contributions_index_tick();
    IF res NOT LIKE 'disk brake:%' THEN RAISE EXCEPTION 'CA_0389: the disk brake did not fire (got %)', res; END IF;
    RAISE EXCEPTION 'CA_0389 brake rollback';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'CA_0389 brake rollback' THEN RAISE; END IF;
  END;
  PERFORM set_config('ca0387.disk_cap_mb', '', true);
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname LIKE 'ca389\_%' AND relkind = 'i') THEN
    RAISE EXCEPTION 'CA_0389: an index was built during the post-verify';
  END IF;
  RAISE LOG 'CA_0389 post-verify passed';
END $$;

COMMIT;
