-- Migration CA_0316: indexes that stop three hot queries from re-reading whole tables
--
-- WHY: Supabase warned on 2026-10-20 that project kxsdzaojfaibhuzmclfq is depleting its daily
--   Disk IO budget (ev-cto watchlist #90). pg_stat_statements (since 2026-05-20) ranked by
--   shared_blks_read + temp_blks_written put these at the top:
--
--   1) fecAdapter.retireSupersededFilings — the "WITH slice AS (...)" per-line supersession
--        DELETE. 145,450 calls, 415M blocks read (~3.3 TB), 36.8M temp blocks written.
--        It is called once per (committee, report_year, report_type) filing in a batch, and
--        each call reaches its slice through the single-column politician_source_id index, so
--        it fetches EVERY row the filer has (one filer: 684,657 heap rows to keep 27,165)
--        and filters the JSONB keys in the heap. Measured on 43d674b8 / C00696526 / 2026 Q2:
--        11.0 s, 125,277 blocks read, 18 MB sort spill.
--   2) treasury-tracker scripts/stampBudgetAxes.mjs — PostgREST page reads of treasury.budgets
--        ORDER BY data_source NULLS FIRST, fiscal_year, id with LIMIT/OFFSET. No index matches
--        the order, so EVERY 1,000-row page seq-scans the 241 MB heap and external-sorts it
--        (~85 MB spill). 13,574 calls, 37.0M blocks read, 67.4M temp blocks written.
--   3) treasury-tracker scripts/stampAuditGrade.mjs — same shape, ORDER BY data_source NULLS
--        FIRST, id. 5,270 calls, 24.7M read, 45.0M temp written.
--
-- WHAT:
--   idx_contrib_fec_supersession — PARTIAL expression index matching the slice predicate
--     exactly: politician_source_id, then the three JSONB keys the query compares. The WHERE
--     clause must match the query's literals (data_source = 'fec' AND raw_record ? 'file_number')
--     for the planner to use it; ->>, ? and the text->int cast are all IMMUTABLE, so this is
--     index-legal. Only FEC rows that carry file_number (~21% of the table at build time) are
--     indexed, so it stays far smaller than a full-table index. The paired code change
--     (fecAdapter.ts: `WITH slice AS MATERIALIZED`) keeps the window sort narrow enough to run
--     in memory.
--     ⚠ The report_year cast means a non-integer report_year on any indexed row would FAIL the
--       build. A 0.2% sample (12,176 file_number rows) found none, and the query already casts it.
--   idx_budgets_data_source_fy_id — (data_source NULLS FIRST, fiscal_year, id): the exact
--     stampBudgetAxes order, and every column it selects, so it can be an index-only scan.
--   idx_budgets_data_source_id — (data_source NULLS FIRST, id) INCLUDE the four other columns
--     stampAuditGrade selects. NULLS FIRST is required: a default (NULLS LAST) btree cannot
--     return ASC NULLS FIRST order, and the planner would sort again.
--
-- BUILD COST: the contributions index is one full pass over the 32 GB heap plus CONCURRENTLY's
--   validation pass. 1385 measured ~5-15 min per index on this table; budget for ~15-25 min of
--   heavy disk reads and run it in a quiet hour. The two budgets indexes take seconds.
--
-- CRITICAL: CREATE INDEX CONCURRENTLY cannot run inside a transaction block, so this file has
--   NO BEGIN/COMMIT. Apply it OUTSIDE a transaction (same rule as 1385):
--       psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CA_0316_disk_io_supersession_and_budgets_sort_indexes.sql
--   Do NOT use psql -1 / --single-transaction. An interrupted CONCURRENTLY build leaves an
--   INVALID index; the gate at the bottom fails on that — DROP INDEX CONCURRENTLY it and re-run.
--   No dry-run wrapper is possible for the same reason; the IF NOT EXISTS guards make re-runs safe.
--
-- Idempotent: IF NOT EXISTS on every index; ANALYZE is harmless to repeat.

-- The postgres role carries a statement_timeout; a 15+ minute build would hit it. Session-only.
SET statement_timeout = 0;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contrib_fec_supersession
  ON transparent_motivations.contributions (
       politician_source_id,
       (raw_record->>'committee_id'),
       (raw_record->>'report_type'),
       ((raw_record->>'report_year')::int)
     )
  WHERE data_source = 'fec' AND raw_record ? 'file_number';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_budgets_data_source_fy_id
  ON treasury.budgets (data_source NULLS FIRST, fiscal_year, id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_budgets_data_source_id
  ON treasury.budgets (data_source NULLS FIRST, id)
  INCLUDE (source_url, audit_grade, municipality_id, fiscal_year);

-- Expression indexes get their own statistics only from ANALYZE. Without them the planner
-- estimates the slice at 1 row (it is 27,165 on the largest filer). Sampled, not a full scan.
ANALYZE transparent_motivations.contributions;
-- Index-only scans on budgets need the visibility map set; this table is 241 MB.
VACUUM (ANALYZE) treasury.budgets;

RESET statement_timeout;

-- Post-verify gate: all three indexes exist and are VALID.
DO $$
DECLARE
  n_valid int;
BEGIN
  SELECT count(*) INTO n_valid
    FROM pg_index i
   WHERE i.indisvalid
     AND i.indexrelid IN (
           to_regclass('transparent_motivations.idx_contrib_fec_supersession'),
           to_regclass('treasury.idx_budgets_data_source_fy_id'),
           to_regclass('treasury.idx_budgets_data_source_id'));
  IF n_valid <> 3 THEN
    RAISE EXCEPTION 'CA_0316: expected 3 valid indexes, found %. DROP INDEX CONCURRENTLY any INVALID one and re-run.', n_valid;
  END IF;
END $$;
