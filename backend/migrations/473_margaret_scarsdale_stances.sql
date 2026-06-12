-- ============================================================================
-- Migration 473: Margaret R. Scarsdale Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Margaret R. Scarsdale
--          (MA State Rep, 1st Middlesex District, HD-58).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics): See migration 456 for full reference block.

BEGIN;

-- ============================================================================
-- Margaret R. Scarsdale (HD-58, external_id=-210098)
-- UUID: a0dc1cc3-efcf-4109-9f9b-4d8b36452361
-- District: 1st Middlesex (Pepperell/Groton/Townsend area)
-- Democrat; first elected 2022.
-- ============================================================================

-- No evidence found for any active compass topic — blank spokes intentional.
-- Research conducted: malegislature.gov/Legislators/Profile/MRS1 (no sponsored bills
-- or committee assignments with compass-topic relevance found in the 194th General Court).
-- AOM tracker showed no co-sponsorship record for this rep.
-- Scarsdale is a newer rep with minimal public legislative footprint; blank spokes
-- are correct per D-01 (no evidence = no value).

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (expect 0 — blank migration intentional):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a0dc1cc3-efcf-4109-9f9b-4d8b36452361';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a0dc1cc3-efcf-4109-9f9b-4d8b36452361'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a0dc1cc3-efcf-4109-9f9b-4d8b36452361'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
