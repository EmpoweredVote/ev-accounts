-- ============================================================================
-- Migration 432: Steven J. Ouellette Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Steven J. Ouellette
--   (MA State Representative, 8th Bristol District, HD-17, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: a4e6e14a-46f7-4574-94c6-5b7edd484d91 (external_id: -210057)

BEGIN;

-- ----- Steven J. Ouellette / ai-regulation -----
-- Evidence: Member of Joint Committee on Advanced Information Technology, the Internet
--   and Cybersecurity; one of the legislature's key tech/AI policy committees.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4e6e14a-46f7-4574-94c6-5b7edd484d91',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4e6e14a-46f7-4574-94c6-5b7edd484d91',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Ouellette serves on the Joint Committee on Advanced Information Technology, the Internet and Cybersecurity, the Massachusetts legislature's primary body overseeing technology policy, AI regulation, data privacy, and cybersecurity legislation. His committee assignment reflects active engagement with the regulation of emerging technologies. As a Democrat on this committee, he is positioned to support consumer-protective technology regulation and AI accountability measures. His 8th Bristol District (Westport area) includes residents and businesses impacted by emerging technology policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SJO1', 'https://malegislature.gov/Committees/Joint/J1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a4e6e14a-46f7-4574-94c6-5b7edd484d91';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a4e6e14a-46f7-4574-94c6-5b7edd484d91'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a4e6e14a-46f7-4574-94c6-5b7edd484d91'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
