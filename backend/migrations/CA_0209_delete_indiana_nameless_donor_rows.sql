-- CA_0209_delete_indiana_nameless_donor_rows.sql
-- Delete every Indiana contribution written by the pre-2026-09-24 indianaAdapter, so the corrected ingest
-- (indianaAdapter.ts, same PR) starts from an empty slate for the adapter's rows.
--
-- THE DEFECT: indianaAdapter read the donor from a `ContributorName` column. The bulk export
-- (https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/<year>_ContributionData.csv.zip) calls it
-- `Name` — likewise `Type` for ContributionType and `Received_By` for ReceivedBy. So every stored row has a blank
-- donor (donor_name_normalized 'anonymous'), and because the donor is part of source_transaction_id
-- (FileNumber|date|donor|amount), different donors who gave the same amount on the same day became ONE row.
-- Measured 2026-09-23 against the live 2025 and 2026 files (2025: 1,848,401 bytes, ETag "5062eab5f4dd1:0",
-- last-modified 2026-06-25; 2026: 831,992 bytes, ETag "a18dfc211840dd1:0", last-modified 2026-09-09; downloaded
-- with operator permission, not committed):
--   - all 5,446 adapter-written rows carry ContributorName = '' and a key of the form '3299|2026-03-07||500.00';
--   - the 2026 file holds 10,419 rows for confirmed Indiana committees; keyed without the donor they are 6,503
--     rows, keyed with it 10,380 (and 10,419 once a repeated identical gift gets its own |#n key).
--
-- WHY DELETE BEFORE THE FIRST CORRECTED INGEST (not after): the corrected keys include the donor, so none of these
-- rows would ever conflict with a corrected row. Left in place they would be counted TWICE beside the correct
-- rows — the same money, once as 'anonymous' and once under the donor's name.
--
-- SCOPE (pinned by count, dollars and an md5 of the sorted ids — a changed population fails the pre-flight):
--   5,446 transparent_motivations.contributions rows, data_source = 'indiana', $5,552,806.15, on 159
--   politician_sources, all 'confirmed', all source_system = 'indiana'. The predicate is the defect itself: a
--   FileNumber key (written by the adapter), ContributorName = '', and no SourceFileYear key (every row the
--   corrected adapter writes carries SourceFileYear, so a re-run can never touch them).
--   159 contribution_summary_agg rows for those sources ($5,552,806.15), which summarise exactly those rows and are
--   left with no contributions. runIngestion rebuilds them on the next ingest.
-- NOT TOUCHED: the other 164 data_source = 'indiana' rows ($75,587.43, confidence HIGH, raw_record {"type": "pac"}
--   and no FileNumber), which sit on 14 sources that are not source_system = 'indiana' and were written by another
--   path; ingestion_runs (history of the old runs stays); politician_sources (every link keeps its status);
--   unresolved_contributions (2,620 rows queued on 2026-05-01 from committees now 'not_applicable'; the corrected
--   adapter no longer queues those, and whether to clear them is a separate call).
-- donor_names_search (materialized view) drops the rows at its next scheduled refresh (pg_cron job 8).
--
-- No FK references contributions (measured 2026-09-23 for CA_0194). No migration runner exists; this file records
-- SQL applied by hand (pure DML).
-- STATUS: NOT APPLIED. Apply only with operator approval, after the PR that carries the corrected adapter merges,
--   and immediately before its first ingest (`node dist/jobs/run.js indiana`). Between the two, the Essentials
--   finance panel of the 159 sources shows no Indiana data.
--
-- ROLLBACK: none in SQL — the deleted rows were wrong (blank donors, merged gifts). They can be rebuilt only by
--   running the pre-2026-09-24 adapter, which is the defect. The pre-flight md5 below identifies what was removed.
-- IDEMPOTENT: a re-run finds 0 matching rows, deletes nothing, and every gate passes.

BEGIN;

-- The population, by its defining predicate. contributions holds ~28M rows: the scan goes through the
-- (data_source, source_transaction_id) unique index, never the whole table.
CREATE TEMP TABLE _gone ON COMMIT DROP AS
SELECT c.id, c.politician_source_id, c.election_cycle, c.amount
  FROM transparent_motivations.contributions c
 WHERE c.data_source = 'indiana'
   AND c.raw_record ? 'FileNumber'
   AND c.raw_record ->> 'ContributorName' = ''
   AND NOT (c.raw_record ? 'SourceFileYear');

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM transparent_motivations.contributions
         WHERE data_source = 'indiana' AND raw_record ? 'SourceFileYear') AS corrected_rows,
       (SELECT count(*) FROM transparent_motivations.contributions
         WHERE data_source = 'indiana' AND NOT (raw_record ? 'FileNumber')) AS other_path_rows,
       (SELECT count(*) FROM transparent_motivations.contributions WHERE data_source = 'indiana') AS indiana_rows;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_md5 text; v_sum numeric; v_srcs int; v_bad int; b record;
BEGIN
  SELECT * INTO b FROM _before;
  SELECT count(*), md5(string_agg(id::text, ',' ORDER BY id)), coalesce(sum(amount), 0), count(DISTINCT politician_source_id)
    INTO v_n, v_md5, v_sum, v_srcs FROM _gone;

  IF v_n = 0 THEN
    RAISE NOTICE 'PRE: no nameless-donor indiana rows left (a re-run); nothing to delete';
  ELSIF v_n <> 5446 OR v_md5 <> '5f73241ba88626287e11dc663641bfa6' OR v_sum <> 5552806.15 OR v_srcs <> 159 THEN
    RAISE EXCEPTION 'PRE: the population changed: % rows on % sources, $%, md5 % (expected 5446 on 159, $5552806.15, 5f73241ba88626287e11dc663641bfa6)',
      v_n, v_srcs, v_sum, v_md5;
  END IF;

  -- Every population row has the nameless key the defect produced, and sits on an Indiana link.
  SELECT count(*) INTO v_bad
    FROM _gone g
    JOIN transparent_motivations.contributions c ON c.id = g.id
    JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
   WHERE ps.source_system <> 'indiana'
      OR c.source_transaction_id !~ '^[0-9]+\|[0-9]{4}-[0-9]{2}-[0-9]{2}\|\|';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'PRE: % population rows are not nameless-key rows on an indiana link', v_bad;
  END IF;

  -- Every indiana row is in the population, was written by the corrected adapter, or is one of the other path's
  -- rows (no FileNumber). Anything else is a fourth kind of row nobody has looked at.
  IF b.indiana_rows <> v_n + b.corrected_rows + b.other_path_rows THEN
    RAISE EXCEPTION 'PRE: % indiana rows = % nameless + % corrected + % other-path + % unexplained',
      b.indiana_rows, v_n, b.corrected_rows, b.other_path_rows,
      b.indiana_rows - v_n - b.corrected_rows - b.other_path_rows;
  END IF;
END $$;

-- ─── Delete the nameless rows, then the summaries they leave empty ───────────────────────────────
DELETE FROM transparent_motivations.contributions c
 USING _gone g
 WHERE c.id = g.id;

DELETE FROM transparent_motivations.contribution_summary_agg a
 USING transparent_motivations.politician_sources ps
 WHERE ps.id = a.politician_source_id
   AND ps.source_system = 'indiana'
   AND NOT EXISTS (SELECT 1 FROM transparent_motivations.contributions c
                    WHERE c.politician_source_id = a.politician_source_id
                      AND c.election_cycle = a.election_cycle);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n
    FROM transparent_motivations.contributions
   WHERE data_source = 'indiana' AND raw_record ? 'FileNumber' AND raw_record ->> 'ContributorName' = ''
     AND NOT (raw_record ? 'SourceFileYear');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % nameless-donor indiana rows remain', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE data_source = 'indiana' AND raw_record ? 'SourceFileYear';
  IF v_n <> b.corrected_rows THEN
    RAISE EXCEPTION 'POST: corrected indiana rows moved: % -> %', b.corrected_rows, v_n;
  END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE data_source = 'indiana' AND NOT (raw_record ? 'FileNumber');
  IF v_n <> b.other_path_rows THEN
    RAISE EXCEPTION 'POST: other-path indiana rows moved: % -> %', b.other_path_rows, v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM transparent_motivations.contribution_summary_agg a
    JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
   WHERE ps.source_system = 'indiana'
     AND NOT EXISTS (SELECT 1 FROM transparent_motivations.contributions c
                      WHERE c.politician_source_id = a.politician_source_id AND c.election_cycle = a.election_cycle);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % indiana summary rows summarise nothing', v_n; END IF;

  RAISE NOTICE 'POST OK: nameless rows 0; corrected rows % and other-path rows % unchanged', b.corrected_rows, b.other_path_rows;
END $$;

COMMIT;
