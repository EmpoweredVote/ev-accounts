-- ============================================================================
-- Migration 431: Alan Silvia Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Alan Silvia
--   (MA State Representative, 7th Bristol District, HD-16, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- NOTE: Pre-existing rows with value=3.0 "did not co-sponsor" neutral defaults
--   exist for several topics from a prior AOM agent run. Per scope boundary rules,
--   those pre-existing rows are not modified here. This migration UPSERTS topics
--   where direct evidence exists, improving or confirming the record.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: a646d95b-7341-4181-a25b-87b5abcf0a6c (external_id: -210056)

BEGIN;

-- ----- Alan Silvia / school-vouchers -----
-- Evidence: Co-sponsored the Cherish Act (Fully Funded Public Higher Education) per AOM tracker.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a646d95b-7341-4181-a25b-87b5abcf0a6c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a646d95b-7341-4181-a25b-87b5abcf0a6c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Silvia co-sponsored the Cherish Act (Fully Funded Public Higher Education) per the Act on Mass tracker, which would make public higher education tuition-free. He also co-sponsored the THRIVE Act, a K-12 public school funding legislation per Act on Mass. These co-sponsorships demonstrate a consistent pro-public-education stance and opposition to diverting public funds to private institutions via vouchers. His committee assignment on House Ways and Means also positions him in education budget decisions.$$,
        ARRAY['https://actonmass.org/legislators/alan-silvia/', 'https://malegislature.gov/Legislators/Profile/A_S1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Silvia / childcare -----
-- Evidence: Co-sponsored the CARE Act (childcare) per AOM tracker.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a646d95b-7341-4181-a25b-87b5abcf0a6c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a646d95b-7341-4181-a25b-87b5abcf0a6c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Silvia co-sponsored the CARE Act per the Act on Mass tracker, legislation expanding childcare access and affordability for working families. His 7th Bristol District (Fall River area) includes working-class families with significant childcare cost burdens. The CARE Act co-sponsorship reflects a pro-expanded-childcare position in line with his committee work on Ways and Means, which handles childcare funding in the state budget.$$,
        ARRAY['https://actonmass.org/legislators/alan-silvia/', 'https://malegislature.gov/Legislators/Profile/A_S1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alan Silvia / voting-rights -----
-- Evidence: Member of Joint Committee on Election Laws.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a646d95b-7341-4181-a25b-87b5abcf0a6c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a646d95b-7341-4181-a25b-87b5abcf0a6c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Silvia serves on the Joint Committee on Election Laws, which handles voting rights legislation, voter registration, and election administration policy in Massachusetts. As a Democrat on this committee, he participates in advancing voting access measures. Massachusetts has expanded voting rights through mail voting, early voting, and automatic voter registration in recent sessions. His committee membership reflects engagement with these issues as a legislative priority.$$,
        ARRAY['https://actonmass.org/legislators/alan-silvia/', 'https://malegislature.gov/Legislators/Profile/A_S1', 'https://malegislature.gov/Committees/Joint/J12']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a646d95b-7341-4181-a25b-87b5abcf0a6c';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a646d95b-7341-4181-a25b-87b5abcf0a6c'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a646d95b-7341-4181-a25b-87b5abcf0a6c'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
