-- CA_0381_contributions_copy_setup.sql
-- Sets up a SLOW, BATCHED copy of transparent_motivations.contributions into contributions_new.
-- Creates the empty new table, a trigger that mirrors every later write into it, and a function that copies
-- the existing rows a few MB at a time. It copies no existing rows itself.
--
-- Created 2026-11-14 with Chris Andrews. Steward slot CA_0381. ev-cto decision 0038, Part D step 3.
-- Plan: ev-cto tasks/2026-11-13-disk-io-d2-copy-plan.md.
--
-- WHY BATCHED. The first version of this slot copied every row in one transaction. Run on 2026-11-13 at
-- 20:37 UTC, on a day whose disk-IO budget was already spent, the database stopped responding at ~20:40 and
-- the platform restarted it at 20:46 (log: "database system was not properly shut down"). The site had no
-- database for ~6 minutes. Nothing was kept. On the Small compute size one large copy cannot run at full
-- speed, so this version copies at a fixed slow rate, under a nightly cap, in short transactions.
--
-- HOW IT STAYS CORRECT WHILE IT RUNS FOR DAYS
--   * contributions_mirror_to_new (AFTER INSERT/UPDATE/DELETE on contributions) repeats every write on
--     contributions_new from the moment this commits. Its typed columns come from raw_record, not from NEW:
--     rows older than CA_0380 have them NULL.
--   * contributions_copy_tick() copies the next block range of the OLD table's heap (a TID range scan reads
--     only those pages). It holds a SHARE lock on contributions for the few seconds a batch takes, so no
--     writer can change or delete a row between the batch reading it and writing it. It inserts with
--     ON CONFLICT (id) DO NOTHING: a row the mirror already wrote is newer than the batch's copy.
--   * target_block is the heap size measured under this file's lock, before the trigger exists. Rows written
--     later live beyond it or are covered by the mirror. VACUUM never moves a row between blocks.
--   * FEC raw_record is not copied (every key a reader uses is a column, PR #1434). _ca0381_row_ok RAISEs on
--     the first row whose cast columns disagree with the JSON text.
--
-- RATE. Each tick copies p_pages heap blocks (default 1000 = 8 MB of heap plus its TOAST, ~12,000 rows).
-- It refuses outside 19:00-02:59 UTC, and once the night's measured IO on the two tables (heap+TOAST blocks
-- read from the old table, plus growth of the new one) reaches p_night_cap_mb. Run it every minute from
-- pg_cron or a client; a tick that finds another tick running returns at once.
--
-- STATE: contributions_copy_state (one row) and contributions_copy_log. postgres only, RLS on, no grants.
--
-- UNDO (any time before the swap): drop trigger contributions_mirror_to_new on contributions;
--   drop function contributions_mirror_to_new(), contributions_copy_tick(int,int),
--   _ca0381_row_ok(jsonb, contribution_typed); drop table contributions_new, contributions_copy_state,
--   contributions_copy_log. Creates only; overwrites no stored value.
--
-- STATUS: APPLIED to production 2026-11-14 02:37 UTC (psql as postgres). Rehearsed first, with ten tamper
--   controls each stopped by its own gate. target_block at apply: 2,454,994.
--   Scheduled the same night (not part of this transaction), founder-approved:
--     SELECT cron.schedule('ca0381-contributions-copy', '* 19-23,0-2 * * *',
--       $c$SELECT CASE WHEN now() >= timestamptz '2026-11-14 19:00:00+00'
--            THEN transparent_motivations.contributions_copy_tick(1000, 6000)
--            ELSE 'not started: begins 2026-11-14 19:00 UTC' END$c$);   -- jobid 38
--   Pause: SELECT cron.alter_job(38, active => false);  Progress: SELECT * FROM contributions_copy_state;
--   The swap file unschedules job 38 and drops everything listed under UNDO except contributions_new.

BEGIN;
SET LOCAL statement_timeout = '120s';
SET LOCAL lock_timeout = '3s';

-- Blocks writers until COMMIT (seconds); reads continue. Taken first so target_block and the trigger agree.
LOCK TABLE transparent_motivations.contributions IN SHARE ROW EXCLUSIVE MODE;

DO $$
BEGIN
  IF pg_database_size(current_database()) > 57::bigint * 1024 * 1024 * 1024 THEN
    RAISE EXCEPTION 'CA_0381: database is % — over the 57 GB gate', pg_size_pretty(pg_database_size(current_database()));
  END IF;
  IF to_regclass('transparent_motivations.contributions_new') IS NOT NULL OR to_regclass('transparent_motivations.contributions_old') IS NOT NULL
     OR to_regclass('transparent_motivations.contributions_copy_state') IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0381: contributions_new, contributions_old or contributions_copy_state already exists';
  END IF;
END $$;

-- 1. The new table: columns, defaults, NOT NULLs, CHECKs; primary key; RLS, policy and the old table's grants.
CREATE TABLE transparent_motivations.contributions_new
  (LIKE transparent_motivations.contributions INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING STORAGE INCLUDING GENERATED);
ALTER TABLE transparent_motivations.contributions_new ADD CONSTRAINT ca381_contributions_pkey PRIMARY KEY (id);
ALTER TABLE transparent_motivations.contributions_new ENABLE ROW LEVEL SECURITY;
CREATE POLICY "contributions: public read" ON transparent_motivations.contributions_new FOR SELECT TO anon, authenticated USING (true);
REVOKE ALL ON transparent_motivations.contributions_new FROM PUBLIC, anon, authenticated, service_role, ev_api;
GRANT SELECT ON transparent_motivations.contributions_new TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON transparent_motivations.contributions_new TO ev_api;
CREATE TRIGGER contributions_fill_typed BEFORE INSERT OR UPDATE ON transparent_motivations.contributions_new
  FOR EACH ROW EXECUTE FUNCTION transparent_motivations.contributions_fill_typed();

-- 2. Copy state. postgres only.
CREATE TABLE transparent_motivations.contributions_copy_state (
  one          boolean PRIMARY KEY DEFAULT true CHECK (one),
  target_block integer NOT NULL,
  next_block   integer NOT NULL DEFAULT 0,
  rows_copied  bigint  NOT NULL DEFAULT 0,
  night        date,
  night_read_base bigint,
  night_new_base  bigint,
  night_io_mb  numeric NOT NULL DEFAULT 0,
  last_tick    timestamptz,
  last_note    text,
  done_at      timestamptz
);
CREATE TABLE transparent_motivations.contributions_copy_log (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tick_at     timestamptz NOT NULL DEFAULT now(),
  from_block  integer NOT NULL,
  to_block    integer NOT NULL,
  rows_copied integer NOT NULL,
  night_io_mb numeric NOT NULL,
  seconds     numeric NOT NULL
);
ALTER TABLE transparent_motivations.contributions_copy_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE transparent_motivations.contributions_copy_log   ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON transparent_motivations.contributions_copy_state, transparent_motivations.contributions_copy_log FROM PUBLIC, anon, authenticated, service_role, ev_api;

INSERT INTO transparent_motivations.contributions_copy_state (target_block)
  SELECT (pg_relation_size('transparent_motivations.contributions') / current_setting('block_size')::int)::int;

-- 3. Row check: the cast columns must equal the JSON text they came from.
CREATE FUNCTION transparent_motivations._ca0381_row_ok(r jsonb, t transparent_motivations.contribution_typed)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE AS $f$
BEGIN
  IF r IS NULL THEN RETURN true; END IF;
  IF (r->>'report_year') IS DISTINCT FROM t.fec_report_year::text THEN
    RAISE EXCEPTION 'CA_0381 row check: report_year % became %', r->>'report_year', t.fec_report_year;
  END IF;
  IF (r->>'file_number') IS DISTINCT FROM t.fec_file_number::text THEN
    RAISE EXCEPTION 'CA_0381 row check: file_number % became %', r->>'file_number', t.fec_file_number;
  END IF;
  IF (r->>'is_individual') IS DISTINCT FROM t.src_is_individual::text THEN
    RAISE EXCEPTION 'CA_0381 row check: is_individual % became %', r->>'is_individual', t.src_is_individual;
  END IF;
  RETURN true;
END $f$;
REVOKE ALL ON FUNCTION transparent_motivations._ca0381_row_ok(jsonb, transparent_motivations.contribution_typed) FROM PUBLIC, anon, authenticated;

-- 4. The mirror.
CREATE FUNCTION transparent_motivations.contributions_mirror_to_new()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'pg_catalog', 'transparent_motivations'
AS $m$
DECLARE
  t transparent_motivations.contribution_typed;
BEGIN
  -- CA_0381: keeps contributions_new current until the swap drops this.
  IF TG_OP = 'DELETE' THEN
    DELETE FROM transparent_motivations.contributions_new WHERE id = OLD.id;
    RETURN OLD;
  END IF;
  IF TG_OP = 'UPDATE' AND NEW.id IS DISTINCT FROM OLD.id THEN
    DELETE FROM transparent_motivations.contributions_new WHERE id = OLD.id;
  END IF;
  t := transparent_motivations.contribution_typed_fields(NEW.raw_record);
  INSERT INTO transparent_motivations.contributions_new (id, donor_id, committee_id, politician_source_id, amount, contribution_date, election_cycle, confidence_level, data_source, source_transaction_id, raw_record, created_at, updated_at, donor_name_normalized, src_contributor_name, src_con_name, src_tran_naml, src_tran_namf, src_contributorname, src_ctrib_naml, src_ctrib_namf, donor_employer, donor_occupation, donor_city, donor_state, src_type, src_entity_type, src_entity_cd, src_contributortype, src_recordtypedescription, src_is_individual, src_contributor_committee_id, src_schedule, src_con_desc, fec_committee_id, fec_report_year, fec_report_type, fec_file_number, fec_file_number_present, fec_memo_code, fec_transaction_id, fec_amendment_indicator)
  VALUES (NEW.id,
          NEW.donor_id,
          NEW.committee_id,
          NEW.politician_source_id,
          NEW.amount,
          NEW.contribution_date,
          NEW.election_cycle,
          NEW.confidence_level,
          NEW.data_source,
          NEW.source_transaction_id,
          CASE WHEN NEW.data_source = 'fec' THEN NULL ELSE NEW.raw_record END,
          NEW.created_at,
          NEW.updated_at,
          NEW.donor_name_normalized,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_contributor_name ELSE t.src_contributor_name END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_con_name ELSE t.src_con_name END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_tran_naml ELSE t.src_tran_naml END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_tran_namf ELSE t.src_tran_namf END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_contributorname ELSE t.src_contributorname END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_ctrib_naml ELSE t.src_ctrib_naml END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_ctrib_namf ELSE t.src_ctrib_namf END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.donor_employer ELSE t.donor_employer END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.donor_occupation ELSE t.donor_occupation END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.donor_city ELSE t.donor_city END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.donor_state ELSE t.donor_state END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_type ELSE t.src_type END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_entity_type ELSE t.src_entity_type END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_entity_cd ELSE t.src_entity_cd END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_contributortype ELSE t.src_contributortype END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_recordtypedescription ELSE t.src_recordtypedescription END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_is_individual ELSE t.src_is_individual END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_contributor_committee_id ELSE t.src_contributor_committee_id END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_schedule ELSE t.src_schedule END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.src_con_desc ELSE t.src_con_desc END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.fec_committee_id ELSE t.fec_committee_id END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.fec_report_year ELSE t.fec_report_year END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.fec_report_type ELSE t.fec_report_type END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.fec_file_number ELSE t.fec_file_number END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.fec_file_number_present ELSE t.fec_file_number_present END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.fec_memo_code ELSE t.fec_memo_code END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.fec_transaction_id ELSE t.fec_transaction_id END,
          CASE WHEN NEW.raw_record IS NULL THEN NEW.fec_amendment_indicator ELSE t.fec_amendment_indicator END)
  ON CONFLICT (id) DO UPDATE SET
    donor_id = EXCLUDED.donor_id,
    committee_id = EXCLUDED.committee_id,
    politician_source_id = EXCLUDED.politician_source_id,
    amount = EXCLUDED.amount,
    contribution_date = EXCLUDED.contribution_date,
    election_cycle = EXCLUDED.election_cycle,
    confidence_level = EXCLUDED.confidence_level,
    data_source = EXCLUDED.data_source,
    source_transaction_id = EXCLUDED.source_transaction_id,
    raw_record = EXCLUDED.raw_record,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at,
    donor_name_normalized = EXCLUDED.donor_name_normalized,
    src_contributor_name = EXCLUDED.src_contributor_name,
    src_con_name = EXCLUDED.src_con_name,
    src_tran_naml = EXCLUDED.src_tran_naml,
    src_tran_namf = EXCLUDED.src_tran_namf,
    src_contributorname = EXCLUDED.src_contributorname,
    src_ctrib_naml = EXCLUDED.src_ctrib_naml,
    src_ctrib_namf = EXCLUDED.src_ctrib_namf,
    donor_employer = EXCLUDED.donor_employer,
    donor_occupation = EXCLUDED.donor_occupation,
    donor_city = EXCLUDED.donor_city,
    donor_state = EXCLUDED.donor_state,
    src_type = EXCLUDED.src_type,
    src_entity_type = EXCLUDED.src_entity_type,
    src_entity_cd = EXCLUDED.src_entity_cd,
    src_contributortype = EXCLUDED.src_contributortype,
    src_recordtypedescription = EXCLUDED.src_recordtypedescription,
    src_is_individual = EXCLUDED.src_is_individual,
    src_contributor_committee_id = EXCLUDED.src_contributor_committee_id,
    src_schedule = EXCLUDED.src_schedule,
    src_con_desc = EXCLUDED.src_con_desc,
    fec_committee_id = EXCLUDED.fec_committee_id,
    fec_report_year = EXCLUDED.fec_report_year,
    fec_report_type = EXCLUDED.fec_report_type,
    fec_file_number = EXCLUDED.fec_file_number,
    fec_file_number_present = EXCLUDED.fec_file_number_present,
    fec_memo_code = EXCLUDED.fec_memo_code,
    fec_transaction_id = EXCLUDED.fec_transaction_id,
    fec_amendment_indicator = EXCLUDED.fec_amendment_indicator;
  RETURN NEW;
END
$m$;
REVOKE ALL ON FUNCTION transparent_motivations.contributions_mirror_to_new() FROM PUBLIC, anon, authenticated;
CREATE TRIGGER contributions_mirror_to_new AFTER INSERT OR UPDATE OR DELETE ON transparent_motivations.contributions
  FOR EACH ROW EXECUTE FUNCTION transparent_motivations.contributions_mirror_to_new();

-- 5. One batch.
CREATE FUNCTION transparent_motivations.contributions_copy_tick(p_pages integer DEFAULT 1000, p_night_cap_mb integer DEFAULT 6000)
RETURNS text LANGUAGE plpgsql
SET search_path TO 'pg_catalog', 'transparent_motivations'
AS $k$
DECLARE
  st transparent_motivations.contributions_copy_state;
  hr int := extract(hour FROM now() AT TIME ZONE 'utc')::int;
  nite date := ((now() AT TIME ZONE 'utc') - interval '19 hours')::date;
  cur_read bigint; cur_new bigint; io_mb numeric;
  f int; t_ int; n int; t0 timestamptz := clock_timestamp();
BEGIN
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
REVOKE ALL ON FUNCTION transparent_motivations.contributions_copy_tick(integer, integer) FROM PUBLIC, anon, authenticated, service_role, ev_api;

-- Post-verify.
DO $$
DECLARE
  new_t oid := 'transparent_motivations.contributions_new'::regclass;
  old_t oid := 'transparent_motivations.contributions'::regclass;
  acl_new text; acl_old text; st transparent_motivations.contributions_copy_state;
  probe_id uuid; plain_id uuid; got record; old_typed text; res text; n bigint; bad bigint;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_index i JOIN pg_class ic ON ic.oid = i.indexrelid
                  WHERE i.indrelid = new_t AND ic.relname = 'ca381_contributions_pkey' AND i.indisprimary AND i.indisvalid) THEN
    RAISE EXCEPTION 'CA_0381: primary key missing on contributions_new';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = new_t) THEN RAISE EXCEPTION 'CA_0381: RLS off'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'transparent_motivations' AND tablename = 'contributions_new'
                  AND policyname = 'contributions: public read' AND cmd = 'SELECT' AND qual = 'true') THEN
    RAISE EXCEPTION 'CA_0381: public-read policy missing';
  END IF;
  SELECT string_agg(a::text, ',' ORDER BY a::text) INTO acl_new FROM unnest((SELECT relacl FROM pg_class WHERE oid = new_t)) a;
  SELECT string_agg(a::text, ',' ORDER BY a::text) INTO acl_old FROM unnest((SELECT relacl FROM pg_class WHERE oid = old_t)) a;
  IF acl_new IS DISTINCT FROM acl_old THEN RAISE EXCEPTION 'CA_0381: grants differ. new % / old %', acl_new, acl_old; END IF;
  IF (SELECT relowner FROM pg_class WHERE oid = new_t) <> (SELECT relowner FROM pg_class WHERE oid = old_t) THEN
    RAISE EXCEPTION 'CA_0381: owner differs';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgrelid = new_t AND tgname = 'contributions_fill_typed' AND tgenabled = 'O') THEN
    RAISE EXCEPTION 'CA_0381: fill trigger missing on contributions_new';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgrelid = old_t AND tgname = 'contributions_mirror_to_new' AND tgenabled = 'O') THEN
    RAISE EXCEPTION 'CA_0381: mirror trigger missing on contributions';
  END IF;
  -- State tables: RLS on and no role but the owner may touch them.
  IF EXISTS (SELECT 1 FROM pg_class c CROSS JOIN LATERAL aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a
              WHERE c.oid IN ('transparent_motivations.contributions_copy_state'::regclass, 'transparent_motivations.contributions_copy_log'::regclass)
                AND a.grantee <> c.relowner) THEN
    RAISE EXCEPTION 'CA_0381: a role other than the owner holds a grant on the copy state tables';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_class WHERE oid IN ('transparent_motivations.contributions_copy_state'::regclass,
              'transparent_motivations.contributions_copy_log'::regclass) AND NOT relrowsecurity) THEN
    RAISE EXCEPTION 'CA_0381: RLS off on a copy state table';
  END IF;
  IF has_function_privilege('anon', 'transparent_motivations.contributions_copy_tick(integer,integer)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'transparent_motivations.contributions_copy_tick(integer,integer)', 'EXECUTE')
     OR has_function_privilege('ev_api', 'transparent_motivations.contributions_copy_tick(integer,integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0381: the copy function is executable by an API role';
  END IF;
  SELECT * INTO st FROM transparent_motivations.contributions_copy_state;
  IF st.target_block <> (pg_relation_size(old_t) / current_setting('block_size')::int) OR st.next_block <> 0 THEN
    RAISE EXCEPTION 'CA_0381: copy state target % / next % do not match the table', st.target_block, st.next_block;
  END IF;

  -- The mirror and one batch, tested live inside a savepoint that is always rolled back.
  -- probe: raw_record changes. plain: only updated_at changes, on a row whose typed columns are NULL in the
  -- old table, so the mirror must compute them itself.
  SELECT c.id INTO probe_id FROM transparent_motivations.contributions c TABLESAMPLE SYSTEM (0.01) WHERE c.data_source = 'fec' LIMIT 1;
  SELECT c.id INTO plain_id FROM transparent_motivations.contributions c TABLESAMPLE SYSTEM (0.01)
   WHERE c.data_source = 'fec' AND c.src_contributor_name IS NULL AND c.raw_record ? 'contributor_name'
     AND c.id <> probe_id LIMIT 1;
  IF probe_id IS NULL OR plain_id IS NULL THEN RAISE EXCEPTION 'CA_0381: no FEC rows to test the mirror on'; END IF;
  BEGIN
    UPDATE transparent_motivations.contributions SET raw_record = raw_record || '{"contributor_name":"CA_0381 MIRROR PROBE"}'::jsonb
     WHERE id = probe_id;
    SELECT src_contributor_name, raw_record INTO got FROM transparent_motivations.contributions_new WHERE id = probe_id;
    IF got.src_contributor_name IS DISTINCT FROM 'CA_0381 MIRROR PROBE' OR got.raw_record IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0381: mirror did not carry an UPDATE (name %, raw kept %)', got.src_contributor_name, got.raw_record IS NOT NULL;
    END IF;
    UPDATE transparent_motivations.contributions SET updated_at = updated_at WHERE id = plain_id;
    SELECT n2.src_contributor_name INTO old_typed FROM transparent_motivations.contributions_new n2 WHERE n2.id = plain_id;
    IF old_typed IS DISTINCT FROM (SELECT raw_record->>'contributor_name' FROM transparent_motivations.contributions WHERE id = plain_id) THEN
      RAISE EXCEPTION 'CA_0381: mirror lost the typed columns on a plain UPDATE of an older row (got %)', old_typed;
    END IF;
    DELETE FROM transparent_motivations.contributions WHERE id = probe_id;
    IF EXISTS (SELECT 1 FROM transparent_motivations.contributions_new WHERE id = probe_id) THEN
      RAISE EXCEPTION 'CA_0381: mirror did not carry a DELETE';
    END IF;
    RAISE EXCEPTION 'CA_0381 probe rollback';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'CA_0381 probe rollback' THEN RAISE; END IF;
  END;
  IF NOT EXISTS (SELECT 1 FROM transparent_motivations.contributions WHERE id = probe_id) THEN
    RAISE EXCEPTION 'CA_0381: the mirror probe was not rolled back';
  END IF;

  -- One 50-block batch (run in the quiet window only; outside it the tick refuses, and so does this test).
  BEGIN
    res := transparent_motivations.contributions_copy_tick(50, 1000000);
    IF res NOT LIKE 'blocks 0-50 %' THEN RAISE EXCEPTION 'CA_0381: test batch did not copy: %', res; END IF;
    SELECT count(*) INTO n FROM transparent_motivations.contributions_new;
    IF n = 0 OR n <> (SELECT rows_copied FROM transparent_motivations.contributions_copy_state) THEN
      RAISE EXCEPTION 'CA_0381: test batch copied % rows, state says %', n, (SELECT rows_copied FROM transparent_motivations.contributions_copy_state);
    END IF;
    -- Every copied row equals its source: same base columns, and each typed column equals the JSON key read.
    SELECT count(*) INTO bad FROM transparent_motivations.contributions_new nw JOIN transparent_motivations.contributions o ON o.id = nw.id
     WHERE (nw.amount, nw.contribution_date, nw.data_source, nw.politician_source_id, nw.donor_name_normalized, nw.source_transaction_id)
             IS DISTINCT FROM (o.amount, o.contribution_date, o.data_source, o.politician_source_id, o.donor_name_normalized, o.source_transaction_id)
        OR (o.raw_record IS NOT NULL AND (
              nw.src_contributor_name IS DISTINCT FROM o.raw_record->>'contributor_name'
           OR nw.fec_committee_id     IS DISTINCT FROM o.raw_record->>'committee_id'
           OR nw.fec_report_year::text IS DISTINCT FROM o.raw_record->>'report_year'
           OR nw.donor_employer IS DISTINCT FROM coalesce(o.raw_record->>'contributor_employer', o.raw_record->>'con_empr')))
        OR (o.data_source = 'fec' AND nw.raw_record IS NOT NULL)
        OR (o.data_source <> 'fec' AND nw.raw_record IS DISTINCT FROM o.raw_record);
    IF bad > 0 THEN RAISE EXCEPTION 'CA_0381: % copied rows differ from their source', bad; END IF;
    -- The batch must have held the table against writers.
    IF NOT EXISTS (SELECT 1 FROM pg_locks WHERE relation = old_t AND pid = pg_backend_pid() AND mode = 'ShareLock' AND granted) THEN
      RAISE EXCEPTION 'CA_0381: the batch did not take its SHARE lock on contributions';
    END IF;
    RAISE EXCEPTION 'CA_0381 batch rollback';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'CA_0381 batch rollback' THEN RAISE; END IF;
  END;
  IF EXISTS (SELECT 1 FROM transparent_motivations.contributions_new) OR (SELECT next_block FROM transparent_motivations.contributions_copy_state) <> 0 THEN
    RAISE EXCEPTION 'CA_0381: the test batch was not rolled back';
  END IF;
  RAISE LOG 'CA_0381 post-verify passed: target % blocks', st.target_block;
END $$;

COMMIT;
