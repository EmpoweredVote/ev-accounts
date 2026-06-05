-- Migration 191: Add source_type to transparent_motivations.politician_sources
--
-- Adds a source_type column to distinguish candidate committees (the default)
-- from independent expenditure / outside-spending committees that are active
-- in a politician's race but don't receive contributions on the politician's behalf.
--
-- Values:
--   'candidate_committee' (DEFAULT) — direct fundraising for the politician
--   'ie_committee'                  — outside-spending PAC linked to politician's race
--
-- Backfill is implicit via DEFAULT — all pre-existing rows become 'candidate_committee'.
--
-- Index: idx_politician_sources_source_type — for efficient filtering on ie_committee
-- in the outside_spending aggregation queries in campaignFinanceService.ts.
--
-- Idempotency: all DDL statements check IF NOT EXISTS / are safe to re-run.
-- CRITICAL: wrap in single transaction.

BEGIN;

ALTER TABLE transparent_motivations.politician_sources
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'candidate_committee';

ALTER TABLE transparent_motivations.politician_sources
  DROP CONSTRAINT IF EXISTS politician_sources_source_type_check;

ALTER TABLE transparent_motivations.politician_sources
  ADD CONSTRAINT politician_sources_source_type_check
  CHECK (source_type IN ('candidate_committee', 'ie_committee'));

CREATE INDEX IF NOT EXISTS idx_politician_sources_source_type
  ON transparent_motivations.politician_sources(source_type);

COMMIT;
