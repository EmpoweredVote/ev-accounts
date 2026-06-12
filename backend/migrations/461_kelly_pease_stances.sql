-- ============================================================================
-- Migration 461: Kelly W. Pease Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kelly W. Pease (MA State Rep, 4th Hampden District, HD-46).
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
-- Kelly W. Pease (HD-46, external_id=-210086)
-- UUID: 296406bb-cc2a-4214-978f-d30333d62939
-- District: 4th Hampden (Westfield area)
-- Republican; committees: Ways and Means, Higher Education, Bonding/Capital.
-- ============================================================================

-- ----- Kelly W. Pease / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296406bb-cc2a-4214-978f-d30333d62939',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296406bb-cc2a-4214-978f-d30333d62939',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Pease sponsored H.662, "An Act to prohibit age discrimination in public schools," which extends anti-discrimination protections to students based on age in educational settings. She also sponsored H.659, "An Act relative to equity and inclusion in education," and H.660, "An Act concerning equitable state summative assessments of students," both focused on educational equity. These bills reflect genuine support for anti-discrimination and equity principles in education.$$,
        ARRAY['https://malegislature.gov/Bills/194/H662', 'https://malegislature.gov/Bills/194/H659', 'https://malegislature.gov/Bills/194/H661']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kelly W. Pease / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296406bb-cc2a-4214-978f-d30333d62939',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296406bb-cc2a-4214-978f-d30333d62939',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Pease serves on the House Committee on Ways and Means and Joint Committee on Ways and Means, giving her a central role in shaping the state budget and economic policy. Her Republican affiliation and committee roles reflect a business-friendly, fiscally conservative approach to economic development, emphasizing market solutions over government-directed investment.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KWP1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 2 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '296406bb-cc2a-4214-978f-d30333d62939';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '296406bb-cc2a-4214-978f-d30333d62939'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '296406bb-cc2a-4214-978f-d30333d62939'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
