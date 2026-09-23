-- CA_0196_delete_judicial_cal_access_contributor_side_rows.sql
-- Delete every judicial.donations row that was stored from the CONTRIBUTOR's side, so the judicial ingest
-- (scripts/run-judicial-cal-access-smoketest.ts, re-run with the corrected adapter) starts from an empty slate.
-- The same defect as CA_0194, in the table CA_0194 deliberately left alone.
--
-- THE DEFECT: until PR #659 (2026-09-23) calAccessAdapter matched RCPT_CD.CMTE_ID to the filer id it was given.
-- CMTE_ID is the committee id of the CONTRIBUTOR. Who RECEIVED a receipt is the filer of the filing it is reported
-- on: RCPT_CD.FILING_ID -> FILER_FILINGS_CD.FILER_ID. The only judicial run (2026-07-21, 226 rows for the 3 seeded
-- judges) went through the old adapter, so every row is money the judge's own committee PAID, shown as money given
-- TO the judge. Measured 2026-09-23 (read-only):
--   - 226 of 226 rows have raw_record CMTE_ID = their own judge's cal_access_filer_id, and none has a FILER_ID key;
--   - 226 of 226 are FORM_TYPE F401A (REC_TYPE RCPT): receipts on the Form 401 of a slate-mailer organisation,
--     i.e. the judge's committee paying for slate-mailer placement. No row is a Form 460 contribution;
--   - the donor names are the judges' own committees, 13 spellings in all: "Dayan Mathai for Superior Court Judge
--     2014" (Mathai, 79 rows / $391,542.91), "Susan Jung Townsend for Judge 2016" (Townsend, 77 / $468,051.54),
--     "Michel for Judge 2018" (Michel, 70 / $354,990.00). 4 of Mathai's rows name "Ranalli for Supervisor in 2014,
--     Landslide Communications as agent" yet carry Mathai's committee id in CMTE_ID: the slate-mailer filer's own
--     entry. The predicate below is the id, not the name;
--   - read from the recipient side (Form 460 Schedules A and C, latest amendment — the corrected adapter) the same
--     3 committees received 1,040 contributions / $1,171,107.47: Mathai 477 / $522,459.58, Townsend 348 /
--     $546,093.45, Michel 215 / $102,554.44. 0 of those 1,040 source_transaction_ids equal one of the 226.
-- Evidence file: the SOS bulk export https://campaignfinance.cdn.sos.ca.gov/dbwebexport.zip (1.58 GB, the
-- 2026-09-23 copy that CA_0194 cites, ETag "f7b658794c03f8214d06b2ee5d91829d-151"), not committed.
--
-- WHO READS THESE ROWS: nobody outside the ingest. Measured 2026-09-23: no route, service, view, function or cron job
-- reads judicial.donations (the ingest script counts it); no frontend references it; schema `judicial` is not in
-- PostgREST's pgrst.db_schemas; anon and authenticated hold no grant on it (ev_api holds SELECT, INSERT). The judge
-- pages read essentials.judge_details / judicial_evaluations / judicial_metrics, not this table. So no user has
-- seen these figures; the damage was to the data a later phase (attorney matching, judicial.matches) would build on.
--
-- WHY DELETE BEFORE THE CORRECTED RE-RUN: writeJudicialDonations upserts ON CONFLICT (data_source,
-- source_transaction_id) and only touches updated_at, so it never removes or rewrites a stored row. Left in place,
-- the 226 would sit beside the corrected rows and be summed with them. The ingest script now refuses to write while
-- any cal_access row without a FILER_ID key remains.
--
-- SCOPE (pinned by count, dollars and an md5 of the sorted ids — a changed population fails the pre-flight):
--   226 judicial.donations rows, data_source = 'cal_access', $1,214,584.45, on 3 judges
--   (c319b8b1-a8df-4c14-8eb7-d66e167c1a1c Mathai, 9a5c3f8f-5b1a-4843-b482-bd122dccb79f Townsend,
--   30926923-1331-49e8-a4d1-5f8e13beb726 Michel). The predicate is the defect itself: raw_record CMTE_ID is one of
--   the row's own judge's cal_access_filer_ids, and no FILER_ID key (rows written by the corrected adapter carry
--   FILER_ID, so a re-run can never touch them).
-- NOT TOUCHED: judicial.judges (every judge keeps its filer ids); judicial.matches (0 rows; the pre-flight proves
-- none references the population, and its FK would refuse the delete if one did).
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: NOT APPLIED. Awaiting operator approval (Chris Andrews).
--
-- ROLLBACK: none in SQL — the deleted rows were wrong. They can be rebuilt only by running the pre-#659 adapter,
--   which is the defect. The pre-flight md5 below identifies exactly what was removed.
-- IDEMPOTENT: a re-run finds 0 matching rows, deletes nothing, and every gate passes.

BEGIN;

-- The population, by its defining predicate. `jsonb ? NULL` is NULL, so a row with no CMTE_ID key is not selected
-- here — it is then unexplained, and the pre-flight's accounting check fails on it.
CREATE TEMP TABLE _gone ON COMMIT DROP AS
SELECT d.id, d.judge_id, d.amount
  FROM judicial.donations d
  JOIN judicial.judges j ON j.id = d.judge_id
 WHERE d.data_source = 'cal_access'
   AND NOT (d.raw_record ? 'FILER_ID')
   AND COALESCE(j.external_ids -> 'cal_access_filer_ids', '[]'::jsonb) ? (d.raw_record ->> 'CMTE_ID');

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM judicial.donations
         WHERE data_source = 'cal_access' AND raw_record ? 'FILER_ID') AS recipient_side_rows,
       (SELECT count(*) FROM judicial.donations) AS all_rows;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_md5 text; v_sum numeric; v_matched int; b record;
BEGIN
  SELECT * INTO b FROM _before;
  SELECT count(*), md5(string_agg(id::text, ',' ORDER BY id)), coalesce(sum(amount), 0) INTO v_n, v_md5, v_sum FROM _gone;

  IF v_n = 0 THEN
    RAISE NOTICE 'PRE: no contributor-side judicial cal_access rows left (a re-run); nothing to delete';
  ELSIF v_n <> 226 OR v_md5 <> '292c18927e762b7eff1eb3f316da79aa' OR v_sum <> 1214584.45 THEN
    RAISE EXCEPTION 'PRE: the population changed: % rows, $%, md5 % (expected 226, $1214584.45, 292c18927e762b7eff1eb3f316da79aa)',
      v_n, v_sum, v_md5;
  END IF;

  -- Every row is either in the population or was written by the corrected adapter (data_source is CHECKed to
  -- 'cal_access'). Anything else is a third kind of row nobody has looked at.
  IF b.all_rows <> v_n + b.recipient_side_rows THEN
    RAISE EXCEPTION 'PRE: % judicial.donations rows = % contributor-side + % recipient-side + % unexplained',
      b.all_rows, v_n, b.recipient_side_rows, b.all_rows - v_n - b.recipient_side_rows;
  END IF;

  SELECT count(*) INTO v_matched FROM judicial.matches m JOIN _gone g ON g.id = m.donation_id;
  IF v_matched <> 0 THEN
    RAISE EXCEPTION 'PRE: % judicial.matches row(s) reference a contributor-side donation; decide those first', v_matched;
  END IF;
END $$;

-- ─── Delete the contributor-side rows ────────────────────────────────────────────────────────────
DELETE FROM judicial.donations d
 USING _gone g
 WHERE d.id = g.id;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n
    FROM judicial.donations d
    JOIN judicial.judges j ON j.id = d.judge_id
   WHERE d.data_source = 'cal_access'
     AND NOT (d.raw_record ? 'FILER_ID')
     AND COALESCE(j.external_ids -> 'cal_access_filer_ids', '[]'::jsonb) ? (d.raw_record ->> 'CMTE_ID');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % contributor-side judicial cal_access rows remain', v_n; END IF;

  SELECT count(*) INTO v_n FROM judicial.donations WHERE data_source = 'cal_access' AND raw_record ? 'FILER_ID';
  IF v_n <> b.recipient_side_rows THEN
    RAISE EXCEPTION 'POST: recipient-side judicial cal_access rows moved: % -> %', b.recipient_side_rows, v_n;
  END IF;

  SELECT count(*) INTO v_n FROM judicial.donations;
  IF v_n <> b.recipient_side_rows THEN
    RAISE EXCEPTION 'POST: % judicial.donations rows remain, expected only the % recipient-side rows', v_n, b.recipient_side_rows;
  END IF;

  RAISE NOTICE 'POST OK: contributor-side rows 0; judicial.donations holds % recipient-side row(s)', b.recipient_side_rows;
END $$;

COMMIT;
