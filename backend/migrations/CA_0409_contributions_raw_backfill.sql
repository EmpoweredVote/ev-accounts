-- CA_0409 — move the stored state-source raw_record into contributions_raw (ev-cto 0038 Part D, Step 6 revised)
--
-- WHAT. For the rows of ONE data_source (setting `ca0409.source`, required) that still carry raw_record and
-- have a source_transaction_id: copy the JSON into contributions_raw (CA_0408) and set
-- contributions.raw_record = NULL, in one statement that reads each row once. Nothing is deleted.
-- Run once per source:
--     psql -v ON_ERROR_STOP=1 -c "SET ca0409.source = 'cal_access'" -f CA_0409_contributions_raw_backfill.sql
--   (in the session: the Supavisor pooler drops PGOPTIONS settings)
-- Re-running a finished source moves 0 rows. FEC rows already carry no JSON (CA_0381/CA_0398).
--
-- WHY PER SOURCE. Rehearsed 2026-11-21 as one statement over all sources: la_county_netfile's 18k rows took
-- 53 s to copy and 19 s to clear (two reads), and the all-source post-verify scanned for 9 minutes. Estimated
-- ~670k rows / ~0.45 GB in all — cal_access ~280k, ocpf ~244k, la_socrata ~74k, indiana ~38k,
-- la_county_netfile ~18k, in_monroe_county_local 168. One source per transaction keeps each run short,
-- and a failure loses only that run.
--
-- HOW. The rows are found through idx_contribution_dedup (leading column data_source) and locked FOR UPDATE;
-- the UPDATE then reaches the same rows by ctid (TID scan), so the heap is read once and the table is never
-- scanned. Setting raw_record to NULL makes contributions_fill_typed and contributions_stash_state_raw both
-- return at once, so the typed columns are untouched.
--
-- Row locks on that source's rows until COMMIT: its imports would wait. Run in the quiet window,
-- 19:00-02:59 UTC, not on the 1st (state imports run ~16:08 and 18:52; ocpf/netfile monthly runs on the 1st).
-- Disk: the side table grows by the JSON moved; the space freed inside contributions is reused, not returned.
--
-- UNDO for a source (until a writer touches its rows), with the trigger dropped first or it moves them back:
--   DROP TRIGGER contributions_stash_state_raw ON transparent_motivations.contributions;
--   UPDATE transparent_motivations.contributions c SET raw_record = r.raw_record
--     FROM transparent_motivations.contributions_raw r
--    WHERE c.data_source = '<source>' AND r.data_source = c.data_source
--      AND r.source_transaction_id = c.source_transaction_id AND c.raw_record IS NULL;
--
-- STATUS: APPLIED 2026-11-21 01:35:18-01:46:17 UTC, one run per source, each post-verify ok (found = copied =
-- cleared): in_monroe_county_local 168, la_county_netfile 18,106, community_verified 0, indiana 41,625,
-- la_socrata 73,312, ocpf 222,987 (4m39s), cal_access 275,530 (4m32s) — 631,728 rows. contributions_raw 493 MB;
-- contributions 10.0 GB; database 33 GB; no restart. Donor read functions for one politician per state source
-- (same script as Step 4) match their 2026-11-19 output except one float-rounding total and Indiana's newer
-- last_sync_at. Rehearsed first with ROLLBACK (168 and 18,106 rows) and three refusal cases (unset, fec, unknown).

BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '40min';

DO $$
DECLARE
  ds text := nullif(current_setting('ca0409.source', true), '');
  allowed text;
  src_n bigint; ins_n bigint; upd_n bigint; side_n bigint;
BEGIN
  -- Pre-check.
  IF ds IS NULL THEN RAISE EXCEPTION 'CA_0409: set ca0409.source to one data_source'; END IF;
  IF ds = 'fec' THEN RAISE EXCEPTION 'CA_0409: fec rows carry no JSON; nothing to move'; END IF;
  SELECT pg_get_constraintdef(oid) INTO allowed FROM pg_constraint
   WHERE conname = 'chk_transparent_motivations_contributions_data_source'
     AND conrelid = 'transparent_motivations.contributions'::regclass;
  IF position(quote_literal(ds) || '::character varying' IN allowed) = 0 THEN
    RAISE EXCEPTION 'CA_0409: % is not an allowed data_source', ds;
  END IF;
  IF to_regclass('transparent_motivations.contributions_raw') IS NULL THEN
    RAISE EXCEPTION 'CA_0409: contributions_raw is missing — apply CA_0408 first';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'contributions_stash_state_raw'
                  AND tgrelid = 'transparent_motivations.contributions'::regclass AND tgenabled = 'O') THEN
    RAISE EXCEPTION 'CA_0409: trigger contributions_stash_state_raw is missing or disabled';
  END IF;

  -- Move: one read of the source's rows, copy, then clear the same rows by ctid.
  WITH src AS MATERIALIZED (
    SELECT c.ctid AS tid, c.data_source, c.source_transaction_id, c.raw_record
      FROM transparent_motivations.contributions c
     WHERE c.data_source = ds
       AND c.source_transaction_id IS NOT NULL
       AND c.raw_record IS NOT NULL
       FOR UPDATE
  ), ins AS (
    INSERT INTO transparent_motivations.contributions_raw AS r
           (data_source, source_transaction_id, raw_record, updated_at)
    SELECT data_source, source_transaction_id, raw_record, now() FROM src
    ON CONFLICT (data_source, source_transaction_id) DO UPDATE
       SET raw_record = excluded.raw_record, updated_at = excluded.updated_at
    RETURNING 1
  ), upd AS (
    UPDATE transparent_motivations.contributions c
       SET raw_record = NULL
     WHERE c.ctid = ANY (ARRAY(SELECT tid FROM src))
    RETURNING 1
  )
  SELECT (SELECT count(*) FROM src), (SELECT count(*) FROM ins), (SELECT count(*) FROM upd)
    INTO src_n, ins_n, upd_n;

  -- Post-verify.
  SELECT count(*) INTO side_n FROM transparent_motivations.contributions_raw WHERE data_source = ds;
  RAISE NOTICE 'CA_0409: % — found %, copied %, cleared %; side table now holds % rows for it',
    ds, src_n, ins_n, upd_n, side_n;
  IF NOT (src_n = ins_n AND ins_n = upd_n) THEN
    RAISE EXCEPTION 'CA_0409: % found %, copied %, cleared % — not committing', ds, src_n, ins_n, upd_n;
  END IF;
  IF side_n < upd_n THEN
    RAISE EXCEPTION 'CA_0409: side table holds % rows for %, fewer than the % moved', side_n, ds, upd_n;
  END IF;
  RAISE NOTICE 'CA_0409: post-verify ok';
END $$;

COMMIT;
