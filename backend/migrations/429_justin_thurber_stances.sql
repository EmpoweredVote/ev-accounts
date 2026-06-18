-- ============================================================================
-- Migration 429: Justin Thurber Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Justin Thurber
--   (MA State Representative, 5th Bristol District, HD-14, Republican).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: a485b386-65a5-4c6c-aaa1-a441facd45fc (external_id: -210054)

BEGIN;

-- ----- Justin Thurber / climate-change -----
-- Evidence: Member of House Committee on Climate Action and Sustainability.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a485b386-65a5-4c6c-aaa1-a441facd45fc',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a485b386-65a5-4c6c-aaa1-a441facd45fc',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Thurber serves on the House Committee on Climate Action and Sustainability, a notable assignment for a Republican. This committee focuses on climate legislation, clean energy transition, and greenhouse gas reduction policy. His 5th Bristol District (Somerset area) includes the site of the former Brayton Point coal power plant, one of the largest coal plant closures in New England, giving him direct constituent experience with energy transition impacts. He also filed H.3574 to further regulate the carbon dioxide cap and trade program, signaling engagement with climate policy mechanisms. His committee membership and climate-related legislation reflect active engagement with climate action.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/J_T2', 'https://malegislature.gov/Bills/194/H3574', 'https://malegislature.gov/Committees/House/H37']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Justin Thurber / abortion -----
-- Evidence: H.2011 "legislation to regulate health decisions" with emergency preamble
--   explicitly invoking "sanctity of bodily autonomy in medical settings."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a485b386-65a5-4c6c-aaa1-a441facd45fc',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a485b386-65a5-4c6c-aaa1-a441facd45fc',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Thurber filed H.2011, legislation titled "to regulate health decisions" with an emergency preamble explicitly declaring the purpose is to "ensure the sanctity of bodily autonomy in medical settings." This bill language reflects a pro-bodily-autonomy position on health decisions, including reproductive rights. As a Republican who explicitly invoked bodily autonomy principles in emergency preamble language, Thurber is positioned as a moderate on reproductive rights compared to the national Republican Party platform. His 5th Bristol District includes constituents across the political spectrum.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2011', 'https://malegislature.gov/Legislators/Profile/J_T2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a485b386-65a5-4c6c-aaa1-a441facd45fc';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a485b386-65a5-4c6c-aaa1-a441facd45fc'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a485b386-65a5-4c6c-aaa1-a441facd45fc'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
