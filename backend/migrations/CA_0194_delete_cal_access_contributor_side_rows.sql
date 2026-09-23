-- CA_0194_delete_cal_access_contributor_side_rows.sql
-- Delete every Cal-Access "contribution" that was stored from the CONTRIBUTOR's side, so the corrected ingest
-- (calAccessAdapter.ts, same PR) starts from an empty cal_access slate.
--
-- THE DEFECT: calAccessAdapter matched RCPT_CD.CMTE_ID to the politician's committee id. CMTE_ID is the committee id
-- of the CONTRIBUTOR (filled only when the contributor is itself a committee). Who RECEIVED a receipt is the filer of
-- the filing it is reported on: RCPT_CD.FILING_ID -> FILER_FILINGS_CD.FILER_ID. So every stored row was money the
-- politician's committee GAVE to another committee, shown as money given TO the politician. Measured 2026-09-23:
--   - all 2,901 cal_access rows have raw_record CMTE_ID = their own politician_source's committee id, and in a
--     25-row random sample every donor name is the politician's own committee ("Tony Thurmond for Superintendent
--     2018" giving $5,000 to Tony Thurmond; "Newsom for California Governor 2022" giving $1,000 to Gavin Newsom);
--   - Newsom's 2022 governor committee (1414018) held 87 rows / $13.3M; read from the recipient side the same
--     committee received 28,602 contributions / $23.0M (Form 460 Schedules A and C, latest amendment);
--   - across the 619 confirmed cal_access links the contributor-side match yields 8,898 rows, the recipient-side
--     match 189,193.
-- Evidence file: the SOS bulk export https://campaignfinance.cdn.sos.ca.gov/dbwebexport.zip (1.58 GB, last-modified
-- 2026-09-23 08:54:59 GMT, ETag "f7b658794c03f8214d06b2ee5d91829d-151"), downloaded 2026-09-23, not committed.
--
-- WHY DELETE BEFORE THE FIRST CORRECTED INGEST (not after): contributions upsert ON CONFLICT (data_source,
-- source_transaction_id) and never rewrite politician_source_id. A contributor-side row whose recipient is ALSO a
-- confirmed filer carries the same source_transaction_id as the correct recipient-side row: e.g. 2931809_0_1, Fiona
-- Ma's LT GOV 2026 committee giving $50,000 to her own legal defense fund, stored under the LT GOV link (1457360).
-- Left in place, it would keep the correct row attributed to the giver.
--
-- SCOPE (pinned by count, dollars and an md5 of the sorted ids — a changed population fails the pre-flight):
--   2,901 transparent_motivations.contributions rows, data_source = 'cal_access', $29,027,437.57, on 181
--   politician_sources (104 people; 13 of the rows sit on links that are no longer 'confirmed'). The predicate is
--   the defect itself: raw_record CMTE_ID = the source's own external_id, and no FILER_ID key (rows written by the
--   corrected adapter carry FILER_ID, so a re-run can never touch them).
--   325 contribution_summary_agg rows for cal_access sources ($29,027,438), which summarise exactly those rows and
--   are left with no contributions. runIngestion rebuilds them on the next ingest.
-- NOT TOUCHED: ingestion_runs (history of the old runs stays); politician_sources (every link keeps its status);
-- data_source_metadata (the stored ETag is '' so the next run downloads in full); judicial.donations (226 cal_access
-- rows for 3 judges with the same defect, written by a separate manual path; decided separately).
-- donor_names_search (materialized view) drops the donor names at its next scheduled refresh (pg_cron job 8).
--
-- No FK references contributions (measured 2026-09-23). No migration runner exists; this file records SQL applied
-- by hand (pure DML).
-- STATUS: NOT APPLIED. Awaiting operator approval (Chris Andrews).
--
-- ROLLBACK: none in SQL — the deleted rows were wrong. They can be rebuilt only by running the pre-2026-09-23
--   adapter, which is the defect. The pre-flight md5 below identifies exactly what was removed.
-- IDEMPOTENT: a re-run finds 0 matching rows, deletes nothing, and every gate passes.

BEGIN;

-- The population, by its defining predicate. contributions holds ~28M rows: the scan goes through the
-- (data_source, source_transaction_id) unique index, never the whole table.
CREATE TEMP TABLE _gone ON COMMIT DROP AS
SELECT c.id, c.politician_source_id, c.election_cycle, c.amount
  FROM transparent_motivations.contributions c
  JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
 WHERE c.data_source = 'cal_access'
   AND NOT (c.raw_record ? 'FILER_ID')
   AND c.raw_record ->> 'CMTE_ID' = ps.external_id;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM transparent_motivations.contributions
         WHERE data_source = 'cal_access' AND raw_record ? 'FILER_ID') AS recipient_side_rows,
       (SELECT count(*) FROM transparent_motivations.contributions WHERE data_source = 'cal_access') AS cal_access_rows;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_md5 text; v_sum numeric; b record;
BEGIN
  SELECT * INTO b FROM _before;
  SELECT count(*), md5(string_agg(id::text, ',' ORDER BY id)), coalesce(sum(amount), 0) INTO v_n, v_md5, v_sum FROM _gone;

  IF v_n = 0 THEN
    RAISE NOTICE 'PRE: no contributor-side cal_access rows left (a re-run); nothing to delete';
  ELSIF v_n <> 2901 OR v_md5 <> 'd5fe1271b24140dd582218c480a84a31' OR v_sum <> 29027437.57 THEN
    RAISE EXCEPTION 'PRE: the population changed: % rows, $%, md5 % (expected 2901, $29027437.57, d5fe1271b24140dd582218c480a84a31)',
      v_n, v_sum, v_md5;
  END IF;

  -- Every cal_access row is either in the population or was written by the corrected adapter. Anything else is
  -- a third kind of row nobody has looked at.
  IF b.cal_access_rows <> v_n + b.recipient_side_rows THEN
    RAISE EXCEPTION 'PRE: % cal_access rows = % contributor-side + % recipient-side + % unexplained',
      b.cal_access_rows, v_n, b.recipient_side_rows, b.cal_access_rows - v_n - b.recipient_side_rows;
  END IF;
END $$;

-- ─── Delete the contributor-side rows, then the summaries they leave empty ───────────────────────
DELETE FROM transparent_motivations.contributions c
 USING _gone g
 WHERE c.id = g.id;

DELETE FROM transparent_motivations.contribution_summary_agg a
 USING transparent_motivations.politician_sources ps
 WHERE ps.id = a.politician_source_id
   AND ps.source_system = 'cal_access'
   AND NOT EXISTS (SELECT 1 FROM transparent_motivations.contributions c
                    WHERE c.politician_source_id = a.politician_source_id
                      AND c.election_cycle = a.election_cycle);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n
    FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
   WHERE c.data_source = 'cal_access' AND NOT (c.raw_record ? 'FILER_ID') AND c.raw_record ->> 'CMTE_ID' = ps.external_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % contributor-side cal_access rows remain', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE data_source = 'cal_access' AND raw_record ? 'FILER_ID';
  IF v_n <> b.recipient_side_rows THEN
    RAISE EXCEPTION 'POST: recipient-side cal_access rows moved: % -> %', b.recipient_side_rows, v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM transparent_motivations.contribution_summary_agg a
    JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
   WHERE ps.source_system = 'cal_access'
     AND NOT EXISTS (SELECT 1 FROM transparent_motivations.contributions c
                      WHERE c.politician_source_id = a.politician_source_id AND c.election_cycle = a.election_cycle);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % cal_access summary rows summarise nothing', v_n; END IF;

  RAISE NOTICE 'POST OK: contributor-side rows 0; recipient-side rows % unchanged', b.recipient_side_rows;
END $$;

COMMIT;
