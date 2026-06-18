-- ============================================================================
-- Migration 425: Michael S. Chaisson Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael S. Chaisson
--   (MA State Representative, 1st Bristol District, HD-10, Republican).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 69a4aaa2-5265-45e0-87c7-8cea22b2dc18 (external_id: -210050)

BEGIN;

-- ----- Michael S. Chaisson / economic-development -----
-- Evidence: Joint Committee on Community Development and Small Businesses;
--   Joint Committee on Financial Services; Ways and Means.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Chaisson serves on the Joint Committee on Community Development and Small Businesses and the Joint Committee on Financial Services, reflecting active engagement with economic development, small business support, and financial sector regulation. As a Republican on Ways and Means, he engages on fiscal policy and appropriations. His 1st Bristol District (Attleboro area) is a mixed suburban/manufacturing district where small business and economic development are key constituent priorities. His committee profile suggests a business-friendly, market-oriented approach to economic development.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MSC1', 'https://malegislature.gov/Committees/Joint/J7']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '69a4aaa2-5265-45e0-87c7-8cea22b2dc18';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '69a4aaa2-5265-45e0-87c7-8cea22b2dc18'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '69a4aaa2-5265-45e0-87c7-8cea22b2dc18'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
