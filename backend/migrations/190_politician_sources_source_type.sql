-- Migration 190: Add source_type column to transparent_motivations.politician_sources
--
-- Purpose: Distinguishes candidate committee sources from independent expenditure (IE)
-- committee sources. Enables the Outside Spending data layer for LA City races.
--
-- Values:
--   candidate_committee — the politician's own fundraising committee (default, all pre-existing rows)
--   ie_committee        — an independent expenditure / PAC committee that spent in this race
--
-- Backfill: DEFAULT 'candidate_committee' backfills all existing rows implicitly.
-- No explicit UPDATE is needed.
--
-- Index: idx_politician_sources_source_type added for fast ie_committee filter in service queries.
--
-- Idempotency: Migration is wrapped in a transaction. Re-applying to a DB where the column
-- already exists will error on the ADD COLUMN statement (expected — apply only once).

BEGIN;

ALTER TABLE transparent_motivations.politician_sources
  ADD COLUMN source_type text NOT NULL DEFAULT 'candidate_committee';

ALTER TABLE transparent_motivations.politician_sources
  ADD CONSTRAINT politician_sources_source_type_check
  CHECK (source_type IN ('candidate_committee', 'ie_committee'));

CREATE INDEX IF NOT EXISTS idx_politician_sources_source_type
  ON transparent_motivations.politician_sources(source_type);

COMMIT;
