-- CA_0398_contributions_swap.sql
-- Puts the copied table live. transparent_motivations.contributions_new (7.6 GB, FEC raw_record left out) becomes
-- transparent_motivations.contributions; the old 34.6 GB table becomes contributions_old, closed to every app role,
-- and waits for Step 5 (DROP, founder approval). Also rebuilds donor_names_search on the new table, adds the trigger
-- that keeps FEC raw JSON out of new rows, and removes the copy machinery (CA_0381, CA_0387, CA_0389).
--
-- Created 2026-11-19 with Chris Andrews. Steward slot CA_0398. ev-cto decision 0038, Part D step 3 (swap).
-- Preconditions met 2026-11-18: copy done 2026-11-17 23:04 UTC (29.7M rows); the five CA_0389 indexes built
-- 19:02-20:21 UTC, all valid, none failed.
--
-- RUN IN THE QUIET WINDOW (19:00-02:59 UTC, not the 1st). The first statement builds donor_names_search from the new
-- table: one read of ~7.6 GB, ~2-3 minutes, no lock that blocks anyone. Only then does the swap lock the tables.
--
-- THE LOCK. One ACCESS EXCLUSIVE lock on contributions and contributions_new (and the old donor_names_search, by its
-- DROP), taken with a 3 s lock_timeout and retried up to 20 times (5 s apart) inside the transaction. While waiting or holding it,
-- reads and writes of those tables wait. It is held from the swap to COMMIT: the renames plus the checks below,
-- about a second. ANALYZE runs after COMMIT, outside the lock.
--
-- WHAT CHANGES (old -> new):
--   contributions (34.6 GB)               -> renamed contributions_old; constraint contributions_pkey ->
--                                            contributions_old_pkey; idx_contribution_dedup,
--                                            idx_contrib_src_cycle, idx_contributions_donor_name_btree,
--                                            -> same name + _old, except
--                                            idx_transparent_motivations_contributions_politician_source_id
--                                            -> idx_contributions_politician_source_id_old (63-char limit). Its other five indexes keep their names and go
--                                            with it at Step 5. Trigger contributions_mirror_to_new dropped.
--                                            Grants overwritten: anon=r, authenticated=r, ev_api=arwd -> none.
--   contributions_new                      -> renamed contributions; ca381_contributions_pkey -> contributions_pkey;
--                                            ca389_* -> the final names in contributions_index_build.final_name.
--                                            Its grants, RLS and "public read" policy are already the old table's.
--   donor_names_search (on old table)      -> dropped; rebuilt from the new table with the same definition, the
--                                            same two indexes, owner ev_api, no other grants (as before).
--                                            pg_cron job 8 (refresh-donor-names-search) refreshes it by name and
--                                            keeps working.
--   NEW contributions_strip_fec_raw         BEFORE INSERT OR UPDATE trigger: sets raw_record to NULL on FEC rows.
--                                            Fires after contributions_fill_typed (triggers fire in name order),
--                                            so the typed columns are filled from the JSON first. Importers still
--                                            send FEC raw_record until Step 6; without this, new FEC rows would
--                                            grow the JSON back.
--   pg_cron job 39 (ca0389-contributions-new-indexes) unscheduled.
--   Dropped: functions contributions_copy_tick, contributions_index_tick, contributions_mirror_to_new,
--            _ca0381_row_ok; tables contributions_copy_state, contributions_copy_log, contributions_index_build.
--            Their record: copy 2026-11-14..17 (CA_0381 header); builds ord 1-5 finished 19:02:29, 19:21:22,
--            19:41:35, 20:01:32, 20:21:10 UTC 2026-11-18 (149, 82, 96, 92, 70 s; 1156, 200, 203, 279, 49 MB).
--
-- 🔴 AFTER APPLYING: restart the ev-accounts backend before 06:00 UTC. fecAdapter.supersessionUsesTypedColumns()
--   caches its answer for the life of the process. A process that ran the FEC job before the swap has cached
--   "false" and would keep running the JSON query, which matches no rows on the new table: amended filings would
--   stop retiring the rows they replace (no data lost, but duplicates would build up) until the next restart.
--
-- CHECKS. Before the lock: every copy/index precondition, the disk brake, and a 0.1% sample of each table found
--   in the other with equal values. After the swap, before COMMIT: index set and validity, triggers, grants/RLS/
--   policy on both tables, the matview's definition (equal to the old one), dependency, owner, indexes and row
--   count, pg_cron, removed objects, and a live probe (FEC insert -> JSON stripped and typed columns filled; FEC
--   update -> same; cal_access insert -> JSON kept) rolled back inside the transaction.
--   GUC ca0398.rehearsal = 'on' (rehearsal only) lets the matview be built WITH NO DATA and skips its row count.
--
-- UNDO before Step 5: in one transaction, rename contributions -> contributions_new, contributions_old ->
--   contributions (and the constraint/index names back), re-grant anon/authenticated SELECT and ev_api
--   SELECT/INSERT/UPDATE/DELETE on it, rebuild donor_names_search on it. Rows written after the swap exist only in
--   the new table and would need copying back. The copy machinery is not restored.
--
-- STATUS: APPLIED 2026-11-19 19:15:00-19:17:44 UTC (apply.sh, psql as postgres): sample ok (old 28,798 / new 28,911 sampled rows), swapped on attempt 1, post-verify ok, ANALYZE done, exit 0. After: contributions 9.7 GB, contributions_old 34 GB (kept until Step 5), donor_names_search populated (~2.57M rows est.), CA_0389 cron job gone, DB 66 GB, no restart. ev-accounts-api redeployed 19:18 (dep-dbvkmrifngtc73cjc5f0). Earlier: WRITTEN 2026-11-19. Rehearsed 2026-11-19 ~16:05 UTC (psql as postgres, COMMIT -> ROLLBACK,
--   matview WITH NO DATA under ca0398.rehearsal): sample ~30k rows each way, 0 bad; swapped on attempt 1; post-verify
--   ok; everything after the sample, lock included, took < 0.5 s; rollback confirmed (contributions_new, job 39 and
--   no strip function after). Seven controls, each stopped by its own gate: old grants left -> old-still-open;
--   matview on the old table -> mv-definition + mv-dependency; job 39 left -> cron; no-op strip -> probe-fec-insert +
--   probe-fec-update; one index not renamed -> live-indexes + temp-names-left; sample expecting FEC JSON kept ->
--   sample check (28,997 bad); rehearsal GUC off -> mv-not-populated. Untested by a control: the matview row-count
--   gate (the rehearsal builds it empty).

BEGIN;
SET LOCAL statement_timeout = '30min';
SET LOCAL lock_timeout = '3s';

-- 1. Preconditions and the sample check (no blocking lock).
DO $$
DECLARE
  typed_keys text[];
  n_old int; n_bad_old int; n_new int; n_bad_new int;
  db_mb bigint := pg_database_size(current_database()) / 1048576;
BEGIN
  IF db_mb >= 73728 THEN
    RAISE EXCEPTION 'CA_0398: disk brake, database is % MB', db_mb;
  END IF;
  IF (SELECT done_at FROM transparent_motivations.contributions_copy_state) IS NULL THEN
    RAISE EXCEPTION 'CA_0398: the copy is not finished';
  END IF;
  IF EXISTS (SELECT 1 FROM transparent_motivations.contributions_index_build
              WHERE finished_at IS NULL OR failed_at IS NOT NULL)
     OR (SELECT count(*) FROM transparent_motivations.contributions_index_build) <> 5 THEN
    RAISE EXCEPTION 'CA_0398: the CA_0389 index builds are not all finished';
  END IF;
  IF EXISTS (SELECT 1 FROM transparent_motivations.contributions_index_build b
               LEFT JOIN pg_class c ON c.relname = b.name AND c.relnamespace = 'transparent_motivations'::regnamespace
               LEFT JOIN pg_index i ON i.indexrelid = c.oid
              WHERE i.indexrelid IS NULL OR NOT i.indisvalid OR NOT i.indisready
                 OR i.indrelid <> 'transparent_motivations.contributions_new'::regclass) THEN
    RAISE EXCEPTION 'CA_0398: a ca389_ index is missing or not valid';
  END IF;
  IF to_regclass('transparent_motivations.idx_contrib_fec_supersession_typed') IS NOT NULL
     OR to_regclass('transparent_motivations.contributions_old') IS NOT NULL
     OR to_regclass('transparent_motivations.donor_names_search_ca398') IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0398: a target name already exists';
  END IF;

  SELECT array_agg(a.attname::text) INTO typed_keys
    FROM pg_attribute a
   WHERE a.attrelid = (SELECT typrelid FROM pg_type WHERE oid = 'transparent_motivations.contribution_typed'::regtype)
     AND a.attnum > 0 AND NOT a.attisdropped;

  -- old -> new: present, same base values, typed columns = the mapping of the old JSON, FEC JSON dropped.
  SELECT count(*),
         count(*) FILTER (WHERE n.id IS NULL
            OR (to_jsonb(o) - typed_keys - 'raw_record') <> (to_jsonb(n) - typed_keys - 'raw_record')
            OR NOT (to_jsonb(n) @> coalesce(to_jsonb(transparent_motivations.contribution_typed_fields(o.raw_record)), '{}'))
            OR n.raw_record IS DISTINCT FROM (CASE WHEN o.data_source = 'fec' THEN NULL ELSE o.raw_record END))
    INTO n_old, n_bad_old
    FROM transparent_motivations.contributions o TABLESAMPLE SYSTEM (0.1)
    LEFT JOIN transparent_motivations.contributions_new n ON n.id = o.id;

  -- new -> old: nothing in the new table that the old one lacks.
  SELECT count(*), count(*) FILTER (WHERE o.id IS NULL)
    INTO n_new, n_bad_new
    FROM transparent_motivations.contributions_new n TABLESAMPLE SYSTEM (0.1)
    LEFT JOIN transparent_motivations.contributions o ON o.id = n.id;

  IF n_old < 1000 OR n_new < 1000 OR n_bad_old > 0 OR n_bad_new > 0 THEN
    RAISE EXCEPTION 'CA_0398: sample check failed (old % rows, % bad; new % rows, % missing in old)',
      n_old, n_bad_old, n_new, n_bad_new;
  END IF;
  RAISE NOTICE 'CA_0398: sample ok (old % rows, new % rows)', n_old, n_new;

  PERFORM set_config('ca0398.old_oid', 'transparent_motivations.contributions'::regclass::oid::text, true);
  PERFORM set_config('ca0398.new_oid', 'transparent_motivations.contributions_new'::regclass::oid::text, true);
  PERFORM set_config('ca0398.old_def', pg_get_viewdef('transparent_motivations.donor_names_search'::regclass, true), true);
  PERFORM set_config('ca0398.old_mv_rows',
    (SELECT count(*) FROM transparent_motivations.donor_names_search)::text, true);
END $$;

-- 2. donor_names_search, rebuilt from the new table (same SELECT as the live one). Reads ~7.6 GB.
CREATE MATERIALIZED VIEW transparent_motivations.donor_names_search_ca398 AS
 SELECT c.donor_name_normalized,
    count(*) AS contribution_count
   FROM transparent_motivations.contributions_new c
     JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
  WHERE ps.research_status::text = 'confirmed'::text AND c.donor_name_normalized IS NOT NULL
    AND c.donor_name_normalized <> ''::text
  GROUP BY c.donor_name_normalized
WITH DATA;
CREATE UNIQUE INDEX ca398_donor_names_search_name_uk
  ON transparent_motivations.donor_names_search_ca398 USING btree (donor_name_normalized);
CREATE INDEX ca398_donor_names_search_name_trgm
  ON transparent_motivations.donor_names_search_ca398 USING gin (donor_name_normalized extensions.gin_trgm_ops);
ALTER MATERIALIZED VIEW transparent_motivations.donor_names_search_ca398 OWNER TO ev_api;
REVOKE ALL ON transparent_motivations.donor_names_search_ca398 FROM PUBLIC, anon, authenticated, service_role;

-- 3. The strip function (the trigger is created in the swap).
CREATE FUNCTION transparent_motivations.contributions_strip_fec_raw()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $f$
BEGIN
  -- FEC rows keep only the typed columns (CA_0380), filled from this JSON by contributions_fill_typed, which
  -- fires first. State-source JSON is kept until Step 6 archives it.
  IF new.data_source = 'fec' THEN
    new.raw_record := NULL;
  END IF;
  RETURN new;
END
$f$;
REVOKE ALL ON FUNCTION transparent_motivations.contributions_strip_fec_raw() FROM PUBLIC, anon, authenticated, ev_api;

-- 4. The swap, under one lock, retried on lock timeout.
DO $$
DECLARE
  attempt int := 0;
  b record;
BEGIN
  LOOP
    attempt := attempt + 1;
    BEGIN
      PERFORM set_config('lock_timeout', '3s', true);
      LOCK TABLE transparent_motivations.contributions, transparent_motivations.contributions_new
        IN ACCESS EXCLUSIVE MODE;
      -- (LOCK TABLE refuses materialized views; DROP takes the matview's lock itself, under the same timeout.)

      DROP TRIGGER contributions_mirror_to_new ON transparent_motivations.contributions;
      DROP MATERIALIZED VIEW transparent_motivations.donor_names_search;

      ALTER TABLE transparent_motivations.contributions RENAME TO contributions_old;
      ALTER TABLE transparent_motivations.contributions_old RENAME CONSTRAINT contributions_pkey TO contributions_old_pkey;
      ALTER INDEX transparent_motivations.idx_contribution_dedup RENAME TO idx_contribution_dedup_old;
      ALTER INDEX transparent_motivations.idx_contrib_src_cycle RENAME TO idx_contrib_src_cycle_old;
      ALTER INDEX transparent_motivations.idx_contributions_donor_name_btree
        RENAME TO idx_contributions_donor_name_btree_old;
      ALTER INDEX transparent_motivations.idx_transparent_motivations_contributions_politician_source_id
        RENAME TO idx_contributions_politician_source_id_old;  -- the long name + _old exceeds 63 characters
      REVOKE ALL ON transparent_motivations.contributions_old FROM PUBLIC, anon, authenticated, service_role, ev_api;

      ALTER TABLE transparent_motivations.contributions_new RENAME TO contributions;
      ALTER TABLE transparent_motivations.contributions RENAME CONSTRAINT ca381_contributions_pkey TO contributions_pkey;
      FOR b IN SELECT name, final_name FROM transparent_motivations.contributions_index_build ORDER BY ord LOOP
        EXECUTE format('ALTER INDEX transparent_motivations.%I RENAME TO %I', b.name, b.final_name);
      END LOOP;

      CREATE TRIGGER contributions_strip_fec_raw
        BEFORE INSERT OR UPDATE ON transparent_motivations.contributions
        FOR EACH ROW EXECUTE FUNCTION transparent_motivations.contributions_strip_fec_raw();

      ALTER MATERIALIZED VIEW transparent_motivations.donor_names_search_ca398 RENAME TO donor_names_search;
      ALTER INDEX transparent_motivations.ca398_donor_names_search_name_uk RENAME TO donor_names_search_name_uk;
      ALTER INDEX transparent_motivations.ca398_donor_names_search_name_trgm RENAME TO donor_names_search_name_trgm;

      EXIT;
    EXCEPTION WHEN lock_not_available THEN
      IF attempt >= 20 THEN
        RAISE EXCEPTION 'CA_0398: could not take the lock after % attempts', attempt;
      END IF;
      RAISE NOTICE 'CA_0398: lock busy (attempt %), retrying in 5 s', attempt;
      PERFORM pg_sleep(5);
    END;
  END LOOP;
  RAISE NOTICE 'CA_0398: swapped on attempt %', attempt;
END $$;

-- 5. Retire the copy machinery.
SELECT cron.unschedule('ca0389-contributions-new-indexes');
DROP FUNCTION transparent_motivations.contributions_copy_tick(integer, integer);
DROP FUNCTION transparent_motivations.contributions_index_tick();
DROP FUNCTION transparent_motivations.contributions_mirror_to_new();
DROP FUNCTION transparent_motivations._ca0381_row_ok(jsonb, transparent_motivations.contribution_typed);
DROP TABLE transparent_motivations.contributions_copy_state;
DROP TABLE transparent_motivations.contributions_copy_log;
DROP TABLE transparent_motivations.contributions_index_build;

NOTIFY pgrst, 'reload schema';

-- 6. Post-verify (still inside the transaction; any failure rolls everything back).
DO $$
DECLARE
  live regclass := 'transparent_motivations.contributions'::regclass;
  old  regclass := 'transparent_motivations.contributions_old'::regclass;
  mv   regclass := 'transparent_motivations.donor_names_search'::regclass;
  rehearsal boolean := coalesce(current_setting('ca0398.rehearsal', true), '') = 'on';
  idx text[];
  trg text[];
  src record;
  probe_id uuid;
  probe_ids uuid[] := '{}';
  r record;
  fails text := '';
BEGIN
  -- tables
  IF live::oid::text <> current_setting('ca0398.new_oid') THEN fails := fails || ' live-is-not-the-copy'; END IF;
  IF old::oid::text  <> current_setting('ca0398.old_oid') THEN fails := fails || ' old-is-not-the-original'; END IF;
  IF pg_total_relation_size(live) > 15::bigint * 1024 * 1024 * 1024 THEN fails := fails || ' live-too-big'; END IF;

  -- indexes on the live table
  SELECT array_agg(c.relname::text ORDER BY c.relname) INTO idx
    FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
   WHERE i.indrelid = live AND i.indisvalid AND i.indisready;
  IF idx IS DISTINCT FROM ARRAY['contributions_pkey', 'idx_contrib_fec_supersession_typed', 'idx_contrib_src_cycle',
       'idx_contribution_dedup', 'idx_contributions_donor_name_btree',
       'idx_transparent_motivations_contributions_politician_source_id'] THEN
    fails := fails || ' live-indexes=' || coalesce(array_to_string(idx, ','), 'none');
  END IF;
  IF pg_get_indexdef('transparent_motivations.idx_contrib_fec_supersession_typed'::regclass) NOT LIKE
       '%(politician_source_id, fec_committee_id, fec_report_type, fec_report_year) WHERE (((data_source)::text = ''fec''::text) AND fec_file_number_present)'
    OR (SELECT indrelid FROM pg_index WHERE indexrelid = 'transparent_motivations.idx_contrib_fec_supersession_typed'::regclass) <> live THEN
    fails := fails || ' supersession-index';
  END IF;
  IF NOT (SELECT indisunique FROM pg_index WHERE indexrelid = 'transparent_motivations.idx_contribution_dedup'::regclass)
    OR (SELECT indrelid FROM pg_index WHERE indexrelid = 'transparent_motivations.idx_contribution_dedup'::regclass) <> live THEN
    fails := fails || ' dedup-index';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_class WHERE relnamespace = 'transparent_motivations'::regnamespace
              AND (relname LIKE 'ca389\_%' OR relname LIKE 'ca381\_%' OR relname LIKE 'ca398\_%')) THEN
    fails := fails || ' temp-names-left';
  END IF;

  -- triggers
  SELECT array_agg(tgname::text ORDER BY tgname) INTO trg
    FROM pg_trigger WHERE tgrelid = live AND NOT tgisinternal AND tgenabled = 'O';
  IF trg IS DISTINCT FROM ARRAY['contributions_fill_typed', 'contributions_strip_fec_raw'] THEN
    fails := fails || ' live-triggers=' || coalesce(array_to_string(trg, ','), 'none');
  END IF;
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgrelid = old AND tgname = 'contributions_mirror_to_new') THEN
    fails := fails || ' mirror-left';
  END IF;

  -- grants, RLS, policy
  IF (SELECT relacl::text FROM pg_class WHERE oid = live)
       <> '{postgres=arwdDxtm/postgres,anon=r/postgres,authenticated=r/postgres,ev_api=arwd/postgres}'
     OR NOT (SELECT relrowsecurity FROM pg_class WHERE oid = live) THEN
    fails := fails || ' live-grants-or-rls';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'transparent_motivations' AND tablename = 'contributions'
                  AND policyname = 'contributions: public read' AND cmd = 'SELECT' AND qual = 'true'
                  AND roles = '{anon,authenticated}') THEN
    fails := fails || ' live-policy';
  END IF;
  IF has_table_privilege('anon', old, 'SELECT') OR has_table_privilege('authenticated', old, 'SELECT')
     OR has_table_privilege('ev_api', old, 'SELECT') OR has_table_privilege('ev_api', old, 'INSERT')
     OR has_table_privilege('service_role', old, 'SELECT') THEN
    fails := fails || ' old-still-open';
  END IF;

  -- donor_names_search
  IF (SELECT relkind FROM pg_class WHERE oid = mv) <> 'm' THEN fails := fails || ' mv-kind'; END IF;
  IF (SELECT relowner::regrole::text FROM pg_class WHERE oid = mv) <> 'ev_api' THEN fails := fails || ' mv-owner'; END IF;
  IF pg_get_viewdef(mv, true) <> current_setting('ca0398.old_def') THEN fails := fails || ' mv-definition'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_depend d JOIN pg_rewrite rw ON rw.oid = d.objid
                  WHERE rw.ev_class = mv AND d.refobjid = live)
     OR EXISTS (SELECT 1 FROM pg_depend d JOIN pg_rewrite rw ON rw.oid = d.objid
                 WHERE d.refobjid = old) THEN
    fails := fails || ' mv-dependency';
  END IF;
  IF pg_get_indexdef('transparent_motivations.donor_names_search_name_uk'::regclass)
       <> 'CREATE UNIQUE INDEX donor_names_search_name_uk ON transparent_motivations.donor_names_search USING btree (donor_name_normalized)'
     OR pg_get_indexdef('transparent_motivations.donor_names_search_name_trgm'::regclass)
       <> 'CREATE INDEX donor_names_search_name_trgm ON transparent_motivations.donor_names_search USING gin (donor_name_normalized extensions.gin_trgm_ops)' THEN
    fails := fails || ' mv-indexes';
  END IF;
  IF has_table_privilege('anon', mv, 'SELECT') OR has_table_privilege('authenticated', mv, 'SELECT')
     OR NOT has_table_privilege('ev_api', mv, 'SELECT') THEN
    fails := fails || ' mv-grants';
  END IF;
  IF NOT rehearsal THEN
    IF NOT (SELECT relispopulated FROM pg_class WHERE oid = mv) THEN
      fails := fails || ' mv-not-populated';
    ELSIF abs((SELECT count(*) FROM transparent_motivations.donor_names_search)
              - current_setting('ca0398.old_mv_rows')::bigint) > current_setting('ca0398.old_mv_rows')::bigint / 50 THEN
      fails := fails || ' mv-row-count';
    END IF;
  END IF;

  -- pg_cron and removed objects
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'ca0389-contributions-new-indexes')
     OR NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'refresh-donor-names-search' AND active
                     AND command LIKE '%REFRESH MATERIALIZED VIEW CONCURRENTLY transparent_motivations.donor_names_search;') THEN
    fails := fails || ' cron';
  END IF;
  IF to_regclass('transparent_motivations.contributions_new') IS NOT NULL
     OR to_regclass('transparent_motivations.contributions_copy_state') IS NOT NULL
     OR to_regclass('transparent_motivations.contributions_copy_log') IS NOT NULL
     OR to_regclass('transparent_motivations.contributions_index_build') IS NOT NULL
     OR EXISTS (SELECT 1 FROM pg_proc WHERE pronamespace = 'transparent_motivations'::regnamespace
                 AND proname IN ('contributions_copy_tick', 'contributions_index_tick',
                                 'contributions_mirror_to_new', '_ca0381_row_ok')) THEN
    fails := fails || ' leftovers';
  END IF;

  -- live probe, undone by the inner exception
  BEGIN
    -- FEC insert: JSON stripped, typed columns filled from it.
    SELECT * INTO src FROM transparent_motivations.contributions_old
     WHERE data_source = 'fec' AND raw_record ? 'file_number' AND raw_record ? 'committee_id' LIMIT 1;
    INSERT INTO transparent_motivations.contributions
      (politician_source_id, amount, contribution_date, election_cycle, confidence_level, data_source,
       source_transaction_id, raw_record, donor_name_normalized)
    VALUES (src.politician_source_id, src.amount, src.contribution_date, src.election_cycle, src.confidence_level,
            'fec', 'ca398-probe-' || gen_random_uuid(), src.raw_record, src.donor_name_normalized)
    RETURNING id INTO probe_id;
    probe_ids := probe_ids || probe_id;
    SELECT * INTO r FROM transparent_motivations.contributions WHERE id = probe_id;
    IF r.raw_record IS NOT NULL OR r.fec_committee_id IS DISTINCT FROM src.raw_record->>'committee_id'
       OR r.fec_file_number_present IS NOT TRUE THEN
      fails := fails || ' probe-fec-insert';
    END IF;

    -- FEC update with new JSON: typed columns follow it, JSON stripped again.
    UPDATE transparent_motivations.contributions
       SET raw_record = src.raw_record || '{"committee_id": "CA398PROBE"}'
     WHERE id = probe_id;
    SELECT * INTO r FROM transparent_motivations.contributions WHERE id = probe_id;
    IF r.raw_record IS NOT NULL OR r.fec_committee_id IS DISTINCT FROM 'CA398PROBE' THEN
      fails := fails || ' probe-fec-update';
    END IF;

    -- State source: JSON kept.
    SELECT * INTO src FROM transparent_motivations.contributions_old
     WHERE data_source = 'cal_access' AND raw_record IS NOT NULL LIMIT 1;
    INSERT INTO transparent_motivations.contributions
      (politician_source_id, amount, contribution_date, election_cycle, confidence_level, data_source,
       source_transaction_id, raw_record, donor_name_normalized)
    VALUES (src.politician_source_id, src.amount, src.contribution_date, src.election_cycle, src.confidence_level,
            'cal_access', 'ca398-probe-' || gen_random_uuid(), src.raw_record, src.donor_name_normalized)
    RETURNING id INTO probe_id;
    probe_ids := probe_ids || probe_id;
    SELECT * INTO r FROM transparent_motivations.contributions WHERE id = probe_id;
    IF r.raw_record IS DISTINCT FROM src.raw_record THEN
      fails := fails || ' probe-state-insert';
    END IF;

    RAISE EXCEPTION USING ERRCODE = 'P0398', MESSAGE = 'undo probe';
  EXCEPTION WHEN SQLSTATE 'P0398' THEN
    NULL;
  END;
  -- by primary key: a LIKE on source_transaction_id would scan the whole table under the lock
  IF cardinality(probe_ids) <> 2
     OR EXISTS (SELECT 1 FROM transparent_motivations.contributions WHERE id = ANY (probe_ids)) THEN
    fails := fails || ' probe-left-rows';
  END IF;

  IF fails <> '' THEN
    RAISE EXCEPTION 'CA_0398 post-verify failed:%', fails;
  END IF;
  RAISE NOTICE 'CA_0398: post-verify ok';
END $$;

COMMIT;

-- 7. Planner statistics for the renamed tables (after COMMIT, outside the lock).
SET statement_timeout = '30min';
ANALYZE transparent_motivations.contributions;
ANALYZE transparent_motivations.donor_names_search;
