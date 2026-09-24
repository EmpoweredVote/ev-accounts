-- CA_0277_summary_agg_gross_refund_not_null.sql
-- Make transparent_motivations.contribution_summary_agg.gross_amount, refunded_amount and refund_count NOT NULL.
--
-- WHY: CA_0255 added the three columns NULLABLE on purpose. NULL meant "this row was last written by the pre-CA_0255
-- net code", and the read path treated it as the old behaviour until the backfill ran. That window is over:
--   - the --gross-missing backfill recomputed all 5,011 rows on 2026-09-24 (0 failed), and a re-check found 0 NULLs;
--   - every writer is on the new code. refreshSummaryAgg is the only INSERT/UPDATE of the table, and on 2026-09-24
--     ev-accounts-api and the four ingest crons (ev-jobs-cal-access, -fec-burst, -la-county-netfile, -ocpf) were all
--     live on 03322fe8, which carries it.
-- A NULL from now on can only mean a writer that skipped the columns. NOT NULL makes that write fail loudly instead
-- of storing a row the reader would have to guess about.
--
-- WHAT: SET NOT NULL on the three columns, and COMMENT ON to drop the "NULL = not yet refreshed" wording.
--   - NO DEFAULT. A default of 0 would let a writer that forgot the columns store "gross $0, no refunds" silently —
--     the exact defect this column set exists to prevent.
--   - The same release removes the reader's NULL fallback in getSummaryFromAgg.
--
-- SET NOT NULL scans the table once under ACCESS EXCLUSIVE; at 5,011 rows that is instant.
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: APPLIED to prod 2026-09-24 (requested by Chris Andrews). Dry run (BEGIN ... ROLLBACK) passed first and the
--   columns were confirmed still nullable after it; verified after the apply: all 3 NOT NULL, no default, 5,011 rows untouched.
--
-- ROLLBACK: ALTER TABLE transparent_motivations.contribution_summary_agg
--             ALTER COLUMN gross_amount DROP NOT NULL, ALTER COLUMN refunded_amount DROP NOT NULL,
--             ALTER COLUMN refund_count DROP NOT NULL;
-- IDEMPOTENT: SET NOT NULL on a NOT NULL column is a no-op; COMMENT ON is re-settable; the gates pass on re-run.

BEGIN;

-- ─── Pre-check: fail with a readable message rather than a bare constraint error ─────────────────
DO $$
DECLARE v_null int;
BEGIN
  SELECT count(*) INTO v_null FROM transparent_motivations.contribution_summary_agg
   WHERE gross_amount IS NULL OR refunded_amount IS NULL OR refund_count IS NULL;
  IF v_null > 0 THEN
    RAISE EXCEPTION 'PRE: % agg rows still have a NULL gross/refund column — run scripts/030-backfill-summary-agg.ts --gross-missing first', v_null;
  END IF;
END $$;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT count(*) AS total, sum(gross_amount) AS gross, sum(refunded_amount) AS refunded, sum(refund_count) AS refunds
  FROM transparent_motivations.contribution_summary_agg;

ALTER TABLE transparent_motivations.contribution_summary_agg
  ALTER COLUMN gross_amount    SET NOT NULL,
  ALTER COLUMN refunded_amount SET NOT NULL,
  ALTER COLUMN refund_count    SET NOT NULL;

COMMENT ON COLUMN transparent_motivations.contribution_summary_agg.gross_amount IS
  'SUM(amount) over rows that are not refunds (amount >= 0): gross itemized receipts (CA_0255; NOT NULL since CA_0277).';
COMMENT ON COLUMN transparent_motivations.contribution_summary_agg.refunded_amount IS
  'Returned contributions: -SUM(amount) over rows with amount < 0, stored positive (CA_0255; NOT NULL since CA_0277).';
COMMENT ON COLUMN transparent_motivations.contribution_summary_agg.refund_count IS
  'Number of rows with amount < 0 (CA_0255; NOT NULL since CA_0277).';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record; a record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM information_schema.columns
   WHERE table_schema = 'transparent_motivations' AND table_name = 'contribution_summary_agg'
     AND column_name IN ('gross_amount', 'refunded_amount', 'refund_count')
     AND is_nullable = 'NO' AND column_default IS NULL;
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 columns are NOT NULL with no default', v_n; END IF;

  -- no row was touched
  SELECT count(*) AS total, sum(gross_amount) AS gross, sum(refunded_amount) AS refunded, sum(refund_count) AS refunds
    INTO a FROM transparent_motivations.contribution_summary_agg;
  IF a.total <> b.total OR a.gross <> b.gross OR a.refunded <> b.refunded OR a.refunds <> b.refunds THEN
    RAISE EXCEPTION 'POST: data moved: before %, after %', b, a;
  END IF;

  RAISE NOTICE 'CA_0277 applied: gross_amount / refunded_amount / refund_count NOT NULL; % rows untouched', b.total;
END $$;

COMMIT;
