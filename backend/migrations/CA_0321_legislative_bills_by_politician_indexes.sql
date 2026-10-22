-- Migration CA_0321: index bills by sponsor and cosponsors by politician
--
-- WHY: GET /api/essentials/politicians/:id/legislative-summary — one of the four calls the
--   Essentials profile page waits on — was bimodal: ~130 ms, or 3-16 s. Render request logs
--   2026-10-21..22: 98 of 296 calls took over 2 s, while the three sibling calls fired in the
--   same instant (politician, elections, judicial-record) stayed fast. So the time was in this
--   one query, not in waiting for a pool connection.
--
--   getBillsByPolitician filtered `sponsor_id = $1 OR EXISTS (cosponsor ...)`. Neither side had
--   an index that leads with the politician:
--     legislative_bills            — no index on sponsor_id at all
--     legislative_bill_cosponsors  — only (bill_id, politician_id), twice (uq_leg_bill_cosponsors
--                                    and idx_cosponsor are duplicates)
--   so every call seq-scanned all 221,885 bills (16,817 pages, ~130 MB) and walked the whole
--   cosponsor index, even for a politician with no bills (Ysabel Jurado, LA City Council D14:
--   0 bills, 91 profile loads, 0.13-16 s). Warm, that is ~100 ms. With shared_buffers at 512 MB
--   beside a 3.6 GB legislative_votes table, and the daily Disk IO budget running low (CA_0316),
--   those pages are often read from disk instead.
--
-- WHAT:
--   idx_leg_bills_sponsor_introduced — (sponsor_id, introduced_at DESC NULLS LAST): the sponsor
--     arm of the new UNION, in the order the profile sorts by.
--   idx_leg_bill_cosponsors_politician — (politician_id, bill_id): the cosponsor arm, as an
--     index-only scan.
--   The paired code change (essentialsLegislativeService.ts, BILL_IDS_FOR_POLITICIAN) rewrites
--   the OR as `b.id IN (sponsored UNION cosponsored)`. Both are needed: measured on session-only
--   copies of the two tables, the indexes alone left the OR form on a seq scan (31 ms warm).
--   With both, Jurado's lookup read 6 pages instead of 8,381 (2 ms vs 80 ms); the heaviest
--   cosponsor (4,685 bills) read 1,042 instead of 8,416.
--
-- BUILD COST: two btree builds over 71 MB heaps; seconds each, plus CONCURRENTLY's second pass.
--
-- CRITICAL: CREATE INDEX CONCURRENTLY cannot run inside a transaction block, so this file has
--   NO BEGIN/COMMIT. Apply it OUTSIDE a transaction (same rule as CA_0316):
--       psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CA_0321_legislative_bills_by_politician_indexes.sql
--   Do NOT use psql -1 / --single-transaction. An interrupted CONCURRENTLY build leaves an
--   INVALID index; the gate at the bottom fails on that — DROP INDEX CONCURRENTLY it and re-run.
--   No dry-run wrapper is possible for the same reason; the IF NOT EXISTS guards make re-runs safe.
--
-- Idempotent: IF NOT EXISTS on every index; ANALYZE is harmless to repeat.

SET statement_timeout = 0;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_leg_bills_sponsor_introduced
  ON essentials.legislative_bills (sponsor_id, introduced_at DESC NULLS LAST);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_leg_bill_cosponsors_politician
  ON essentials.legislative_bill_cosponsors (politician_id, bill_id);

-- The cosponsor arm is meant to be index-only; that needs the visibility map set.
VACUUM (ANALYZE) essentials.legislative_bill_cosponsors;
ANALYZE essentials.legislative_bills;

RESET statement_timeout;

-- Post-verify gate: both indexes exist and are VALID.
DO $$
DECLARE
  n_valid int;
BEGIN
  SELECT count(*) INTO n_valid
    FROM pg_index i
   WHERE i.indisvalid
     AND i.indexrelid IN (
           to_regclass('essentials.idx_leg_bills_sponsor_introduced'),
           to_regclass('essentials.idx_leg_bill_cosponsors_politician'));
  IF n_valid <> 2 THEN
    RAISE EXCEPTION 'CA_0321: expected 2 valid indexes, found %. DROP INDEX CONCURRENTLY any INVALID one and re-run.', n_valid;
  END IF;
END $$;
