-- ============================================================================
-- Migration 427: Lisa M. Field Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Lisa M. Field
--   (MA State Representative, 3rd Bristol District, HD-12, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: acf7819a-3e36-4d17-8828-3238adb894b0 (external_id: -210052)

BEGIN;

-- ----- Lisa M. Field / healthcare -----
-- Evidence: Joint Committee on Aging and Independence (healthcare/social services for seniors);
--   Joint Committee on Children, Families and Persons with Disabilities.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('acf7819a-3e36-4d17-8828-3238adb894b0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('acf7819a-3e36-4d17-8828-3238adb894b0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Field serves on both the Joint Committee on Aging and Independence (which covers elder care, senior healthcare access, and long-term care policy) and the Joint Committee on Children, Families and Persons with Disabilities (which covers healthcare access for vulnerable populations). These dual assignments reflect a strong focus on healthcare access for those who most need it. Her 3rd Bristol District (Taunton area) includes elderly and disabled residents who rely on state healthcare programs. Her committee portfolio indicates a pro-access, pro-coverage stance on healthcare.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LMF1', 'https://malegislature.gov/Committees/Joint/J2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lisa M. Field / childcare -----
-- Evidence: Joint Committee on Children, Families and Persons with Disabilities.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('acf7819a-3e36-4d17-8828-3238adb894b0',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('acf7819a-3e36-4d17-8828-3238adb894b0',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Field serves on the Joint Committee on Children, Families and Persons with Disabilities, which directly handles childcare subsidy, early education, and family support legislation. Her membership reflects active engagement with childcare access policy. As a Democrat representing the 3rd Bristol District, she has constituent-based motivation to support expanded childcare programs for working families in Bristol County.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LMF1', 'https://malegislature.gov/Committees/Joint/J4']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'acf7819a-3e36-4d17-8828-3238adb894b0';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'acf7819a-3e36-4d17-8828-3238adb894b0'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'acf7819a-3e36-4d17-8828-3238adb894b0'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
