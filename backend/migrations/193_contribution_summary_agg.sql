-- Migration 193: transparent_motivations.contribution_summary_agg
--
-- Pre-aggregated per-(politician_source_id, election_cycle) summary so the public
-- profile read path (getSummary) never scans the multi-GB contributions table.
-- Populated at ingest (runIngestion -> refreshSummaryAggForSource) and backfilled
-- once for existing pairs (scripts/030-backfill-summary-agg.ts). quick-030 Task 4.
--
-- NOTE ON SCOPE (deviation from plan's 'fec_summary_agg' name): the table is keyed by
-- politician_source_id, and each politician_source has exactly one data_source, so the
-- table is source-agnostic by construction. Aggregating every source (not only FEC)
-- keeps getSummary a single uniform agg-driven path — correct for the (rare) politician
-- served by both FEC and state/local sources. Non-FEC pairs are tiny, so this is free.
--
-- total_raised is NOT stored here: the headline stays the authoritative FEC receipts
-- figure (getAuthoritativeFecTotal, unchanged from 029). This table only accelerates the
-- itemized count / individual-vs-pac split / sector rollup / top-donor list.
--
-- Idempotency: CREATE ... IF NOT EXISTS. Safe to re-apply.

BEGIN;

CREATE TABLE IF NOT EXISTS transparent_motivations.contribution_summary_agg (
  politician_source_id uuid          NOT NULL,
  election_cycle       varchar(10)   NOT NULL,
  data_source          text          NOT NULL DEFAULT '',
  contribution_count   bigint        NOT NULL DEFAULT 0,
  total_amount         numeric(16,2) NOT NULL DEFAULT 0,   -- sum of ingested itemized rows for this source+cycle
  individual_total     numeric(16,2) NOT NULL DEFAULT 0,
  pac_total            numeric(16,2) NOT NULL DEFAULT 0,
  confidence_min       smallint      NOT NULL DEFAULT 1,   -- 1 HIGH, 2 MEDIUM, 3 ESTIMATED, 4 unknown
  sector_breakdown     jsonb         NOT NULL DEFAULT '[]'::jsonb, -- [{sector,total,count}] all sectors, desc
  top_donors           jsonb         NOT NULL DEFAULT '[]'::jsonb, -- top 40 [{name,donor_type,employer,occupation,sector,total_amount,contribution_count,confidence_level}]
  refreshed_at         timestamptz   NOT NULL DEFAULT now(),
  PRIMARY KEY (politician_source_id, election_cycle)
);

COMMENT ON TABLE transparent_motivations.contribution_summary_agg IS
  'Pre-aggregated per-(source,cycle) summary powering getSummary so profile reads never scan contributions (quick-030 Task 4). total_raised is NOT here — headline stays authoritative FEC receipts.';

-- getSummary joins by politician_source_id (via politician_sources on essentials_politician_id).
CREATE INDEX IF NOT EXISTS idx_contribution_summary_agg_source
  ON transparent_motivations.contribution_summary_agg (politician_source_id);

COMMIT;
