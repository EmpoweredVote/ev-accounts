-- ============================================================================
-- Migration 424: Leigh S. Davis Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Leigh S. Davis
--   (MA State Representative, 3rd Berkshire District, HD-09, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4 (external_id: -210049)

BEGIN;

-- ----- Leigh S. Davis / climate-change -----
-- Evidence: Member of House Committee on Climate Action and Sustainability.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Davis serves on the House Committee on Climate Action and Sustainability, placing her directly in the legislature's climate policy process. This committee assignment reflects active engagement with climate legislation, clean energy transition, and greenhouse gas reduction policy. Her 3rd Berkshire District (Pittsfield area) has significant climate concerns including air quality from industrial history and vulnerability to extreme weather events. Her committee role indicates a commitment to climate action as a core legislative priority.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LSD1', 'https://malegislature.gov/Committees/House/H37']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Leigh S. Davis / voting-rights -----
-- Evidence: Member of Joint Committee on Election Laws.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Davis serves on the Joint Committee on Election Laws, which handles voting rights legislation, voter registration, and election administration policy in Massachusetts. As a Democrat on this committee, she is positioned to advance voting access expansion. Massachusetts has expanded voting rights in recent years through mail voting, early voting, and automatic voter registration -- all consistent with a pro-access approach. Her committee membership reflects engagement with these issues as a legislative priority.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LSD1', 'https://malegislature.gov/Committees/Joint/J12']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
