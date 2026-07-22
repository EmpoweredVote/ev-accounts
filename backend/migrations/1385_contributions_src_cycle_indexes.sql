-- Migration 1385: campaign-finance query indexes on transparent_motivations.contributions
--
-- WHY: P1 prod incident 2026-07-22 (see .planning/todos/2026-07-22-URGENT-prod-db-
--   campaign-finance-slowdown.md). The 26.9M-row contributions table had only a
--   single-column btree on politician_source_id, so every campaign-finance query
--   (campaignFinanceService.ts) bitmap-scanned ALL of a filer's rows across every cycle
--   and filtered election_cycle in the heap. Mega-raisers (Warnock ~1.5M rows) turned
--   getPacContributions / getSummary into ~60s scans that saturated the db.ts pool
--   (max:10) -> compass/auth/finance all stalled. 54 filers have >100k rows.
--
-- These two indexes were applied LIVE on prod during the incident (via CREATE INDEX
--   CONCURRENTLY); this migration promotes them into the repo for reproducibility
--   (fresh environments, staging clones, the Jan-2027 promotion rebuild).
--
--   1) idx_contrib_src_cycle       — composite (politician_source_id, election_cycle).
--        Backs the live-scan path (confidence filter / not-yet-backfilled filers) and the
--        getContributions total_count query. Warnock totals cost 47,404 -> 11,604.
--   2) idx_contrib_src_cycle_pac   — PARTIAL, same columns, WHERE entity_type IN ('PAC','PTY').
--        Backs getPacContributions, which runs live on EVERY summary request (even the
--        pre-agg fast path, campaignFinanceService.ts getSummaryFromAgg). This was the
--        actual pool-killer: cost 47,404 -> 120 (~390x). The partial predicate must match
--        the query filter (c.raw_record->>'entity_type' IN ('PAC','PTY')) exactly for the
--        planner to use it; ->> and the literal IN-list are IMMUTABLE, so it is index-legal.
--
-- CRITICAL: this migration uses CREATE INDEX CONCURRENTLY so re-applying it to a POPULATED
--   database never takes a table lock. CONCURRENTLY CANNOT run inside a transaction block,
--   so this file has NO BEGIN/COMMIT. Apply it OUTSIDE a transaction:
--       psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/1385_contributions_src_cycle_indexes.sql
--   Do NOT run with psql --single-transaction (-1) and do NOT feed it through a runner that
--   wraps each migration in one pool.query()/transaction — CONCURRENTLY will error there.
--   On a large heap the build is slow (~5-15 min each; a full scan + a second validation
--   scan) and a failed/interrupted CONCURRENTLY build can leave an INVALID index — after
--   applying, verify pg_index.indisvalid for both (see verify block at the bottom) and DROP
--   + retry any that is not valid.
--
-- Idempotent: IF NOT EXISTS guards make this a no-op on prod (where both already exist) and
--   safe to re-run.

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contrib_src_cycle
  ON transparent_motivations.contributions (politician_source_id, election_cycle);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_contrib_src_cycle_pac
  ON transparent_motivations.contributions (politician_source_id, election_cycle)
  WHERE raw_record->>'entity_type' IN ('PAC', 'PTY');

-- Verify (run separately; expects both rows indisvalid = t):
--   SELECT indexrelid::regclass, indisvalid, indisready
--   FROM pg_index
--   WHERE indexrelid IN ('transparent_motivations.idx_contrib_src_cycle'::regclass,
--                        'transparent_motivations.idx_contrib_src_cycle_pac'::regclass);
