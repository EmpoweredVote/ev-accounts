-- ============================================================================
-- Migration 422: John Barrett Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for John Barrett, III
--   (MA State Representative, 1st Berkshire District, HD-07, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: ecddb344-846b-4b7d-b712-3a7db8b47ef6 (external_id: -210047)
-- Note: John Barrett, III is a Democrat representing 1st Berkshire District (North Adams).
-- He was Mayor of North Adams for 18 years before being elected to the legislature.
-- His single committee assignment (House Committee on Operations, Facilities and Security)
-- is a housekeeping committee, not a policy indicator. His legislative record is sparse;
-- his public record is primarily as mayor.

BEGIN;

-- ----- John Barrett / economic-development -----
-- Evidence: 18-year tenure as Mayor of North Adams, focused heavily on economic revitalization
--   of a post-industrial Berkshire County city; MASS MoCA anchor development strategy.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecddb344-846b-4b7d-b712-3a7db8b47ef6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecddb344-846b-4b7d-b712-3a7db8b47ef6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Barrett served as Mayor of North Adams for 18 years before winning the 1st Berkshire District seat. As mayor, he was the architect of the MASS MoCA strategy — converting a former industrial complex into the largest contemporary art museum in the United States, which became a signature economic development project for post-industrial Berkshire County. His career reflects a strong focus on public investment, arts-based economic development, and revitalizing economically distressed communities. He brings this economic development priority to the legislature.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/J_B1', 'https://www.masslive.com/berkshires/2022/11/north-adams-mayor-john-barrett-iii-wins-seat-in-state-house-for-1st-berkshire-district.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ecddb344-846b-4b7d-b712-3a7db8b47ef6';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ecddb344-846b-4b7d-b712-3a7db8b47ef6'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ecddb344-846b-4b7d-b712-3a7db8b47ef6'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
