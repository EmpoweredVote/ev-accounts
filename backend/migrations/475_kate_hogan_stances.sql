-- ============================================================================
-- Migration 475: Kate Hogan Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kate Hogan
--          (MA State Rep, 3rd Middlesex District, HD-60).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics): See migration 456 for full reference block.

-- NOTE: The DB contains 16 pre-existing rows for Hogan from a prior AOM
-- "did not co-sponsor" agent run. All 16 rows have value=3.0 and "did not
-- co-sponsor" reasoning, which violates D-01 (no evidence = no value).
-- Research on this migration found no positive evidence (no AOM co-sponsorships,
-- no relevant sponsored bills in 194th General Court, no committee assignments
-- with direct compass-topic relevance). Blank spokes are the correct outcome
-- per D-01. The pre-existing 3.0 neutral default rows are out-of-scope to
-- delete in this migration and are tracked as a known issue.
--
-- Research conducted: malegislature.gov/Legislators/Profile/KHH1 — former chair
-- of Joint Committee on Public Health; no co-sponsorships on any progressive
-- bills tracked by AOM. No positive evidence found for any compass topic.

BEGIN;

-- No evidence found for any active compass topic — blank spokes intentional.
-- All pre-existing DB rows for this politician are 3.0 neutral defaults from
-- a prior agent run and do not meet the D-01 evidence standard.

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (pre-existing rows remain; expect 16 from prior run — not added here):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'e96eddbe-4a4a-4499-8102-636f0cfac10e';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'e96eddbe-4a4a-4499-8102-636f0cfac10e'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'e96eddbe-4a4a-4499-8102-636f0cfac10e'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
