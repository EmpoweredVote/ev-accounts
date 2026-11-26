-- Migration CA_PENDING_local_record_votes_roll_call_index: index essentials.legislative_votes by roll_call_id
--
-- WHY: the council-record writer deletes stale votes with `DELETE ... WHERE roll_call_id = $1`, and the weekly
--   control joins votes to roll calls on roll_call_id. Without an index each of those scans the ~10M-row table.
--   (Sibling: CA_0386, the session_id index, same table.)
-- WHAT: idx_leg_votes_roll_call_id on (roll_call_id). Almost every row is NULL (only council-record rows are set),
--   so the index is tiny.
--
-- CRITICAL: CREATE INDEX CONCURRENTLY cannot run inside a transaction block, so this file has NO BEGIN/COMMIT.
--   Apply it OUTSIDE a transaction (same rule as CA_0316, CA_0321, CA_0386):
--       psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CA_PENDING_local_record_votes_roll_call_index.sql
--   Do NOT use psql -1 / --single-transaction. An interrupted CONCURRENTLY build leaves an INVALID index; the gate
--   at the bottom fails on that: DROP INDEX CONCURRENTLY it and re-run.
-- Needs CA_PENDING_local_record_votes_columns.sql applied first. Not applied by this commit.
-- Slot: named CA_PENDING until a CA number is reserved.
--
-- Idempotent: IF NOT EXISTS.

SET statement_timeout = 0;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_leg_votes_roll_call_id
  ON essentials.legislative_votes (roll_call_id);

RESET statement_timeout;

-- Post-verify gate: the index exists and is VALID.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_index i
     WHERE i.indisvalid
       AND i.indexrelid = to_regclass('essentials.idx_leg_votes_roll_call_id')
  ) THEN
    RAISE EXCEPTION 'idx_leg_votes_roll_call_id missing or INVALID. DROP INDEX CONCURRENTLY it and re-run.';
  END IF;
END $$;
