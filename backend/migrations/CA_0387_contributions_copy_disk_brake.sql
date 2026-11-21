-- CA_0387_contributions_copy_disk_brake.sql
-- Adds a disk brake to transparent_motivations.contributions_copy_tick (CA_0381), so the batched copy of
-- contributions stops before the database nears the disk limit.
--
-- Created 2026-11-16 with Chris Andrews. Steward slot CA_0387. ev-cto decision 0038, Part D step 3.
--
-- WHY. The CTO weekly review (2026-11-16) flagged that both copies of the table use disk until the swap, and a
-- full disk would stop every write. The copy also ran too slowly: the 6 GB nightly cap was reached after
-- 17 minutes of work, so the job sat idle most of each night. The founder chose (2026-11-16) to run a batch
-- every 20 seconds with a 50 GB nightly cap, which needs this brake first. Projection: copy done ~2026-11-18,
-- database ~71-72 GB at the end of the copy.
--
-- WHAT. Replaces the function body only (same signature, so pg_cron job 38 keeps calling it). The one change:
-- before anything else, a tick returns 'disk brake' when pg_database_size >= 72 GB (73,728 MB). The rest of
-- the body is CA_0381's, unchanged. Overwritten value: the previous body is CA_0381's, in that file.
--
-- Schedule change applied with this file (not part of the transaction):
--   SELECT cron.alter_job(38, schedule => '20 seconds',
--     command => 'SELECT transparent_motivations.contributions_copy_tick(1000, 50000)');
--
-- UNDO: re-run CA_0381's CREATE FUNCTION contributions_copy_tick as CREATE OR REPLACE.
--
-- STATUS: APPLIED to production 2026-11-16 14:06 UTC (psql as postgres), after a rolled-back rehearsal and a
--   control with the brake disabled (stopped by "the disk brake did not fire"). Job 38 changed the same minute.

BEGIN;
SET LOCAL statement_timeout = '60s';
SET LOCAL lock_timeout = '3s';

CREATE OR REPLACE FUNCTION transparent_motivations.contributions_copy_tick(p_pages integer DEFAULT 1000, p_night_cap_mb integer DEFAULT 6000)
RETURNS text LANGUAGE plpgsql
SET search_path TO 'pg_catalog', 'transparent_motivations'
AS $k$
DECLARE
  st transparent_motivations.contributions_copy_state;
  hr int := extract(hour FROM now() AT TIME ZONE 'utc')::int;
  nite date := ((now() AT TIME ZONE 'utc') - interval '19 hours')::date;
  cur_read bigint; cur_new bigint; io_mb numeric;
  f int; t_ int; n int; t0 timestamptz := clock_timestamp();
  db_mb bigint;
BEGIN
  -- CA_0387 disk brake: stop before the database grows past the cap (default 72 GB of the 81 GB disk limit).
  -- ca0387.disk_cap_mb overrides it for one session; the post-verify uses that to prove the brake fires.
  db_mb := pg_database_size(current_database()) / 1048576;
  IF db_mb >= coalesce(nullif(current_setting('ca0387.disk_cap_mb', true), '')::bigint, 73728) THEN
    UPDATE transparent_motivations.contributions_copy_state
       SET last_tick = now(), last_note = format('disk brake: database %s MB', db_mb);
    RETURN format('disk brake: database is %s MB', db_mb);
  END IF;
  IF NOT (hr >= 19 OR hr < 3) THEN RETURN 'outside the 19:00-02:59 UTC window'; END IF;
  IF NOT pg_try_advisory_xact_lock(381381) THEN RETURN 'another tick is running'; END IF;
  SELECT * INTO st FROM transparent_motivations.contributions_copy_state FOR UPDATE;
  IF st.done_at IS NOT NULL THEN RETURN 'done'; END IF;

  -- The night's IO so far: blocks read from the old table (heap + TOAST) and growth of the new one.
  SELECT (coalesce(heap_blks_read, 0) + coalesce(toast_blks_read, 0)) * current_setting('block_size')::bigint
    INTO cur_read FROM pg_statio_all_tables WHERE relid = 'transparent_motivations.contributions'::regclass;
  cur_new := pg_total_relation_size('transparent_motivations.contributions_new');
  IF st.night IS DISTINCT FROM nite OR cur_read < st.night_read_base THEN   -- new night, or stats were reset
    st.night := nite; st.night_read_base := cur_read; st.night_new_base := cur_new;
  END IF;
  io_mb := coalesce(round(((cur_read - st.night_read_base) + (cur_new - st.night_new_base)) / 1048576.0, 1), 0);
  IF io_mb >= p_night_cap_mb THEN
    UPDATE transparent_motivations.contributions_copy_state SET night = st.night, night_read_base = st.night_read_base,
      night_new_base = st.night_new_base, night_io_mb = io_mb, last_tick = now(), last_note = 'night cap reached';
    RETURN format('night cap reached: %s MB of %s', io_mb, p_night_cap_mb);
  END IF;

  PERFORM set_config('lock_timeout', '2s', true);
  BEGIN
    LOCK TABLE transparent_motivations.contributions IN SHARE MODE;
  EXCEPTION WHEN lock_not_available THEN
    UPDATE transparent_motivations.contributions_copy_state SET last_tick = now(), last_note = 'a writer held the table; skipped';
    RETURN 'skipped: a writer held the table';
  END;

  f := st.next_block;
  t_ := least(st.next_block + p_pages, st.target_block);
  INSERT INTO transparent_motivations.contributions_new (id, donor_id, committee_id, politician_source_id, amount, contribution_date, election_cycle, confidence_level, data_source, source_transaction_id, raw_record, created_at, updated_at, donor_name_normalized, src_contributor_name, src_con_name, src_tran_naml, src_tran_namf, src_contributorname, src_ctrib_naml, src_ctrib_namf, donor_employer, donor_occupation, donor_city, donor_state, src_type, src_entity_type, src_entity_cd, src_contributortype, src_recordtypedescription, src_is_individual, src_contributor_committee_id, src_schedule, src_con_desc, fec_committee_id, fec_report_year, fec_report_type, fec_file_number, fec_file_number_present, fec_memo_code, fec_transaction_id, fec_amendment_indicator)
  SELECT c.id,
         c.donor_id,
         c.committee_id,
         c.politician_source_id,
         c.amount,
         c.contribution_date,
         c.election_cycle,
         c.confidence_level,
         c.data_source,
         c.source_transaction_id,
         CASE WHEN c.data_source = 'fec' THEN NULL ELSE c.raw_record END,
         c.created_at,
         c.updated_at,
         c.donor_name_normalized,
         CASE WHEN c.raw_record IS NULL THEN c.src_contributor_name ELSE t.src_contributor_name END,
         CASE WHEN c.raw_record IS NULL THEN c.src_con_name ELSE t.src_con_name END,
         CASE WHEN c.raw_record IS NULL THEN c.src_tran_naml ELSE t.src_tran_naml END,
         CASE WHEN c.raw_record IS NULL THEN c.src_tran_namf ELSE t.src_tran_namf END,
         CASE WHEN c.raw_record IS NULL THEN c.src_contributorname ELSE t.src_contributorname END,
         CASE WHEN c.raw_record IS NULL THEN c.src_ctrib_naml ELSE t.src_ctrib_naml END,
         CASE WHEN c.raw_record IS NULL THEN c.src_ctrib_namf ELSE t.src_ctrib_namf END,
         CASE WHEN c.raw_record IS NULL THEN c.donor_employer ELSE t.donor_employer END,
         CASE WHEN c.raw_record IS NULL THEN c.donor_occupation ELSE t.donor_occupation END,
         CASE WHEN c.raw_record IS NULL THEN c.donor_city ELSE t.donor_city END,
         CASE WHEN c.raw_record IS NULL THEN c.donor_state ELSE t.donor_state END,
         CASE WHEN c.raw_record IS NULL THEN c.src_type ELSE t.src_type END,
         CASE WHEN c.raw_record IS NULL THEN c.src_entity_type ELSE t.src_entity_type END,
         CASE WHEN c.raw_record IS NULL THEN c.src_entity_cd ELSE t.src_entity_cd END,
         CASE WHEN c.raw_record IS NULL THEN c.src_contributortype ELSE t.src_contributortype END,
         CASE WHEN c.raw_record IS NULL THEN c.src_recordtypedescription ELSE t.src_recordtypedescription END,
         CASE WHEN c.raw_record IS NULL THEN c.src_is_individual ELSE t.src_is_individual END,
         CASE WHEN c.raw_record IS NULL THEN c.src_contributor_committee_id ELSE t.src_contributor_committee_id END,
         CASE WHEN c.raw_record IS NULL THEN c.src_schedule ELSE t.src_schedule END,
         CASE WHEN c.raw_record IS NULL THEN c.src_con_desc ELSE t.src_con_desc END,
         CASE WHEN c.raw_record IS NULL THEN c.fec_committee_id ELSE t.fec_committee_id END,
         CASE WHEN c.raw_record IS NULL THEN c.fec_report_year ELSE t.fec_report_year END,
         CASE WHEN c.raw_record IS NULL THEN c.fec_report_type ELSE t.fec_report_type END,
         CASE WHEN c.raw_record IS NULL THEN c.fec_file_number ELSE t.fec_file_number END,
         CASE WHEN c.raw_record IS NULL THEN c.fec_file_number_present ELSE t.fec_file_number_present END,
         CASE WHEN c.raw_record IS NULL THEN c.fec_memo_code ELSE t.fec_memo_code END,
         CASE WHEN c.raw_record IS NULL THEN c.fec_transaction_id ELSE t.fec_transaction_id END,
         CASE WHEN c.raw_record IS NULL THEN c.fec_amendment_indicator ELSE t.fec_amendment_indicator END
    FROM transparent_motivations.contributions c
    CROSS JOIN LATERAL transparent_motivations.contribution_typed_fields(c.raw_record) t
   WHERE c.ctid >= format('(%s,0)', f)::tid AND c.ctid < format('(%s,0)', t_)::tid
     AND transparent_motivations._ca0381_row_ok(c.raw_record, t)
  ON CONFLICT (id) DO NOTHING;
  GET DIAGNOSTICS n = ROW_COUNT;

  UPDATE transparent_motivations.contributions_copy_state SET next_block = t_, rows_copied = rows_copied + n,
    night = st.night, night_read_base = st.night_read_base, night_new_base = st.night_new_base,
    night_io_mb = io_mb, last_tick = now(), last_note = NULL,
    done_at = CASE WHEN t_ >= st.target_block THEN now() END;
  INSERT INTO transparent_motivations.contributions_copy_log (from_block, to_block, rows_copied, night_io_mb, seconds)
    VALUES (f, t_, n, io_mb, round(extract(epoch FROM clock_timestamp() - t0)::numeric, 2));
  RETURN format('blocks %s-%s of %s: %s rows, night IO %s MB', f, t_, st.target_block, n, io_mb);
END
$k$;

-- Post-verify.
DO $$
DECLARE res text; st_before text; st_after text;
BEGIN
  IF pg_get_functiondef('transparent_motivations.contributions_copy_tick(integer,integer)'::regprocedure) NOT LIKE '%disk brake%' THEN
    RAISE EXCEPTION 'CA_0387: contributions_copy_tick has no disk brake';
  END IF;
  IF has_function_privilege('anon', 'transparent_motivations.contributions_copy_tick(integer,integer)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'transparent_motivations.contributions_copy_tick(integer,integer)', 'EXECUTE')
     OR has_function_privilege('ev_api', 'transparent_motivations.contributions_copy_tick(integer,integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0387: the copy function is executable by an API role';
  END IF;
  -- Positive control: with the cap set to 1 MB the brake must fire and copy nothing.
  SELECT format('%s/%s', next_block, rows_copied) INTO st_before FROM transparent_motivations.contributions_copy_state;
  BEGIN
    PERFORM set_config('ca0387.disk_cap_mb', '1', true);
    res := transparent_motivations.contributions_copy_tick(1000, 50000);
    IF res NOT LIKE 'disk brake:%' THEN RAISE EXCEPTION 'CA_0387: the disk brake did not fire (got %)', res; END IF;
    RAISE EXCEPTION 'CA_0387 brake rollback';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'CA_0387 brake rollback' THEN RAISE; END IF;
  END;
  PERFORM set_config('ca0387.disk_cap_mb', '', true);
  SELECT format('%s/%s', next_block, rows_copied) INTO st_after FROM transparent_motivations.contributions_copy_state;
  IF st_after <> st_before THEN RAISE EXCEPTION 'CA_0387: copy state moved during the brake test'; END IF;
  RAISE LOG 'CA_0387 post-verify passed';
END $$;

COMMIT;
