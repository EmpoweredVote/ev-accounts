-- CA_0255_summary_agg_gross_and_refund_columns.sql
-- Give transparent_motivations.contribution_summary_agg a GROSS receipts column and a separate REFUND column, so the
-- campaign-finance summary can report "raised" as gross and returned contributions on their own line.
--
-- WHY: total_amount is SUM(amount) over every itemized row, and a returned contribution is a NEGATIVE row. So the
-- non-FEC headline (and the itemized fallback for FEC) was a NET figure: refunds counted against "raised". Measured
-- 2026-09-24 (prod, read-only): 2,095 of 5,011 agg pairs hold negative rows (123,182 rows, -$43,042,927.25), and 7 of
-- 4,428 active person-cycles read net NEGATIVE. The visible case: Gavin Newsom's only confirmed committee with data
-- (cal_access 1414018, NEWSOM FOR CALIFORNIA GOVERNOR 2022) has exactly two 2024-cycle rows, both returned
-- contributions on filing 2834446 (-$104.40, -$234.36), and the summary opens on that cycle as "raised -$338.76".
-- Operator decision (Chris Andrews, 2026-09-24): "raised" means gross; refunds get their own line. The default cycle
-- and the visibility of <= 0 cycles are NOT changed.
--
-- WHAT: three NULLABLE columns. NULL means "this row was last refreshed by the old (net) code".
--   gross_amount     SUM(amount) over rows with amount > 0
--   refunded_amount  -SUM(amount) over rows with amount < 0, stored POSITIVE
--   refund_count     number of rows with amount < 0
-- total_amount keeps its meaning (the NET sum, = gross_amount - refunded_amount) so nothing that reads it changes.
--
-- NO BACKFILL HERE. The refresher (refreshSummaryAgg) writes the new columns, and from the same release it also computes
-- contribution_count, individual_total, pac_total, sector_breakdown and top_donors over amount > 0 rows only — that
-- needs the TypeScript sector classifier, so it cannot be done in SQL. After the backend deploys, run:
--   npx tsx scripts/030-backfill-summary-agg.ts --gross-missing
-- which recomputes every row whose gross_amount IS NULL. Until then the read path treats NULL as the old behaviour
-- (gross := total_amount, refunded := 0), which is exactly today's output: no regression during the window.
--
-- ADD COLUMN with no default is a catalog-only change: no table rewrite, a brief ACCESS EXCLUSIVE lock.
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews). Dry run (BEGIN ... ROLLBACK) passed first and the
--   columns were confirmed absent after it; verified after the apply: 3 nullable columns present, 5,011 rows untouched
--   (gross_amount NULL on all of them until the --gross-missing backfill).
--
-- ROLLBACK: ALTER TABLE transparent_motivations.contribution_summary_agg
--             DROP COLUMN IF EXISTS gross_amount, DROP COLUMN IF EXISTS refunded_amount, DROP COLUMN IF EXISTS refund_count;
--   (Safe only while the backend that reads them is not deployed, or after reverting it.)
-- IDEMPOTENT: ADD COLUMN IF NOT EXISTS; COMMENT ON is a re-settable no-op; the gate below still passes on re-run.

BEGIN;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT count(*) AS total, COALESCE(sum(total_amount), 0) AS net_sum
  FROM transparent_motivations.contribution_summary_agg;

ALTER TABLE transparent_motivations.contribution_summary_agg
  ADD COLUMN IF NOT EXISTS gross_amount    numeric(16,2),
  ADD COLUMN IF NOT EXISTS refunded_amount numeric(16,2),
  ADD COLUMN IF NOT EXISTS refund_count    bigint;

COMMENT ON COLUMN transparent_motivations.contribution_summary_agg.gross_amount IS
  'SUM(amount) over rows with amount > 0: gross itemized receipts (CA_0255). NULL = row last refreshed by the pre-CA_0255 net code; the read path then uses total_amount.';
COMMENT ON COLUMN transparent_motivations.contribution_summary_agg.refunded_amount IS
  'Returned contributions: -SUM(amount) over rows with amount < 0, stored positive (CA_0255). NULL = not yet refreshed.';
COMMENT ON COLUMN transparent_motivations.contribution_summary_agg.refund_count IS
  'Number of rows with amount < 0 (CA_0255). NULL = not yet refreshed.';
COMMENT ON COLUMN transparent_motivations.contribution_summary_agg.total_amount IS
  'NET sum of every ingested itemized row for this source+cycle (refunds are negative rows), = gross_amount - refunded_amount. Not the headline: see gross_amount (CA_0255).';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record; v_sum numeric;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM information_schema.columns
   WHERE table_schema = 'transparent_motivations' AND table_name = 'contribution_summary_agg'
     AND column_name IN ('gross_amount', 'refunded_amount', 'refund_count') AND is_nullable = 'YES';
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 nullable columns present', v_n; END IF;

  -- no existing row was touched: no backfill
  SELECT count(*), COALESCE(sum(total_amount), 0) INTO v_n, v_sum FROM transparent_motivations.contribution_summary_agg;
  IF v_n <> b.total THEN RAISE EXCEPTION 'POST: row count moved from % to %', b.total, v_n; END IF;
  IF v_sum <> b.net_sum THEN RAISE EXCEPTION 'POST: total_amount sum moved from % to %', b.net_sum, v_sum; END IF;

  RAISE NOTICE 'CA_0255 applied: gross_amount / refunded_amount / refund_count added; % rows untouched (NULL until the refresher runs)', b.total;
END $$;

COMMIT;
