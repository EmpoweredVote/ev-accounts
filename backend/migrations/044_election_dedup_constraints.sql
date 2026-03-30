-- =============================================================================
-- Migration 044: Election dedup constraints — unique constraints on elections and races
--
-- PURPOSE: Enable idempotent import re-runs (D-03 from Phase 98 RESEARCH.md).
--
-- Without these constraints, running importElectionData.ts twice would create
-- duplicate election and race records. With ON CONFLICT upsert semantics in the
-- import script, these constraints ensure re-runs update existing rows rather
-- than inserting duplicates.
--
-- CONSTRAINT DESIGN:
--
-- elections(name, election_date, state):
--   - An election is uniquely identified by its name, date, and state combination.
--   - e.g., ("2026 Indiana Primary", "2026-05-05", "IN") must be unique.
--   - Allows same-named elections in different states or years.
--   - state can be NULL (multi-state federal elections); NULL != NULL in SQL so
--     this is handled via the NULLs DISTINCT default behavior (each NULL state
--     is considered distinct — acceptable for multi-state elections).
--
-- races(election_id, position_name, primary_party):
--   - A race is a specific position within an election. For primary elections,
--     the same position name appears once per party primary (e.g., "State Senate
--     District 40" appears as both a Republican Primary race and a Democratic
--     Primary race). primary_party differentiates them.
--   - For general/retention/special elections, primary_party is NULL. PostgreSQL
--     UNIQUE constraints treat NULL as distinct by default (NULLs NOT DISTINCT
--     is Postgres 15+). To ensure only one general race per position per election,
--     we use a partial unique index for the NULL case (see Step 2b).
--
-- All changes use EXCEPTION-based idempotency pattern since ALTER TABLE ADD
-- CONSTRAINT does not support IF NOT EXISTS syntax.
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Add unique constraint to essentials.elections
--
-- Prevents duplicate election records on import re-run.
-- Composite on (name, election_date, state) — uniquely identifies an election
-- event within a state/year combination.
-- =============================================================================

DO $$
BEGIN
  ALTER TABLE essentials.elections
    ADD CONSTRAINT elections_name_date_state_unique
    UNIQUE (name, election_date, state);
EXCEPTION
  WHEN duplicate_object THEN
    RAISE NOTICE 'Constraint elections_name_date_state_unique already exists, skipping.';
END;
$$;

-- =============================================================================
-- Step 2: Add unique constraint to essentials.races
--
-- A race is unique within an election by position name + primary_party.
-- For primary elections: party-scoped races are distinct (same position can
-- appear as both "Republican Primary" and "Democratic Primary" race).
-- For general/retention/special: primary_party is NULL; see Step 2b for
-- the partial unique index covering the NULL case.
-- =============================================================================

DO $$
BEGIN
  ALTER TABLE essentials.races
    ADD CONSTRAINT races_election_position_party_unique
    UNIQUE (election_id, position_name, primary_party);
EXCEPTION
  WHEN duplicate_object THEN
    RAISE NOTICE 'Constraint races_election_position_party_unique already exists, skipping.';
END;
$$;

-- =============================================================================
-- Step 2b: Partial unique index for general/retention races (primary_party IS NULL)
--
-- Standard UNIQUE constraints in PostgreSQL treat NULL values as distinct,
-- meaning two rows with (same election_id, same position_name, NULL) would
-- NOT violate the constraint above. This partial index enforces uniqueness
-- specifically for non-primary races where primary_party IS NULL.
--
-- This ensures that "Mayor" in the 2026 general election has only one race row,
-- even across multiple import re-runs.
-- =============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_races_election_position_no_party
  ON essentials.races (election_id, position_name)
  WHERE primary_party IS NULL;

-- =============================================================================
-- Step 3: Verification (commented out — for manual verification only)
--
-- After running this migration, confirm constraints exist:
--
-- SELECT conname, contype FROM pg_constraint
-- WHERE conname IN (
--   'elections_name_date_state_unique',
--   'races_election_position_party_unique'
-- );
--
-- SELECT indexname FROM pg_indexes
-- WHERE indexname = 'idx_races_election_position_no_party';
--
-- Expected: Both constraints and the partial index should be returned.
-- =============================================================================

COMMIT;
