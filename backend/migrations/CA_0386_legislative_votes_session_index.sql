-- Migration CA_0386: index essentials.legislative_votes by session
--
-- WHY: ev-cto decision 0038 (Disk IO budget on the Small compute size). No index on
--   essentials.legislative_votes leads with session_id. The indexes are the pkey (id),
--   idx_essentials_legislative_votes_politician_id (politician_id) and the unique idx_leg_vote
--   (politician_id, bill_id, session_id, external_vote_id). Postgres 17 has no skip scan, so a
--   `WHERE session_id = $1` filter walks all of idx_leg_vote (1.5 GB) before it touches a row:
--     - federalVotesRefresh.ts (`source = 'legiscan' AND session_id = $1`), weekly, Sundays 14:00 UTC
--       in ev-jobs-legiscan;
--     - research counts by session: on 2026-11-13 a count of WA 2023-24 ran 117 s and read
--       187,145 blocks (1.5 GB) per pg_stat_statements.
--   Measured 2026-11-13 (pg_class, pg_stats, 1% TABLESAMPLE): ~10.1M rows, heap 2.9 GB, 77 sessions.
--   Each session's rows sit together on disk: WA 2023-24 on 1.5% of heap pages, the 119th Congress
--   on 3%, TX 2025-26 on 5%. So with this index a session lookup reads a few percent of the heap
--   instead of the whole 1.5 GB index first.
--   No production query filters by bill_id alone, so no bill_id index.
--
-- WHAT: idx_leg_votes_session — (session_id). Expected size ~0.1-0.15 GB (77 distinct values,
--   btree deduplication).
--
-- BUILD COST: CONCURRENTLY scans the 2.9 GB heap twice (~6 GB read once). Built in the
--   19:00-02:59 UTC quiet window. Pays back in about a month from the weekly refresh alone.
--
-- CRITICAL: CREATE INDEX CONCURRENTLY cannot run inside a transaction block, so this file has
--   NO BEGIN/COMMIT. Apply it OUTSIDE a transaction (same rule as CA_0316, CA_0321):
--       psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CA_0386_legislative_votes_session_index.sql
--   Do NOT use psql -1 / --single-transaction. An interrupted CONCURRENTLY build leaves an
--   INVALID index; the gate at the bottom fails on that — DROP INDEX CONCURRENTLY it and re-run.
--
-- Idempotent: IF NOT EXISTS; ANALYZE is harmless to repeat.

SET statement_timeout = 0;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_leg_votes_session
  ON essentials.legislative_votes (session_id);

ANALYZE essentials.legislative_votes;

RESET statement_timeout;

-- Post-verify gate: the index exists and is VALID.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_index i
     WHERE i.indisvalid
       AND i.indexrelid = to_regclass('essentials.idx_leg_votes_session')
  ) THEN
    RAISE EXCEPTION 'CA_0386: idx_leg_votes_session missing or INVALID. DROP INDEX CONCURRENTLY it and re-run.';
  END IF;
END $$;
