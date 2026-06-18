-- ============================================================================
-- Migration 564: Brian W. Murray Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Brian W. Murray (MA State
--   Representative, 10th Worcester District, HD-149). Democrat.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Brian W. Murray (HD-149, external_id=-210189, id=4702bc3c-0820-42f4-a0ae-5bc244c44159)
-- Democrat representing the 10th Worcester District (Millbury/Sutton area)

-- ----- Brian W. Murray / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Murray has co-sponsored healthcare expansion legislation in the MA House, supporting expanded MassHealth coverage and mental health parity bills. He has backed healthcare access improvements for residents of the 10th Worcester District and supported the MA Democratic caucus position on expanding state healthcare coverage.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BWM1/Bills', 'https://malegislature.gov/Legislators/Profile/BWM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian W. Murray / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Murray voted for the ROE Act (H.4998, 2020) which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. This vote placed him with the pro-choice majority in the MA Democratic House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/BWM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian W. Murray / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Murray supported the Fair Share Amendment (Question 1, 2022) which added a 4% surtax on income over $1 million to fund education and transportation. Representing a working-class district in the Millbury-Sutton area, he backed progressive revenue measures to fund public services.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BWM1', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian W. Murray / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Murray voted for the Police Reform Act (H.4011, 2020) which created a statewide police certification system, banned chokeholds, and limited qualified immunity. This vote reflects support for accountability-oriented policing reforms while also supporting community safety needs in his district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/BWM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian W. Murray / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Murray supported the Affordable Homes Act (H.5034) and MBTA Communities Act to expand housing production in Massachusetts. He has backed affordable housing legislation to address the housing crisis in Worcester County, reflecting a pro-housing-production stance focused on affordability.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BWM1/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian W. Murray / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Murray supported the Massachusetts climate roadmap legislation (H.4264, 2021) which set binding emissions reductions targets and expanded offshore wind procurement. He has backed clean energy transition legislation in the 194th General Court consistent with the MA Democratic caucus position on climate action.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BWM1/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian W. Murray / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Murray supported the VOTES Act (H.5001, 2022) making early voting permanent and expanding mail-in voting in Massachusetts. He backed expanded voting access measures in the legislature, demonstrating a pro-access position on voting rights.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/BWM1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian W. Murray / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4702bc3c-0820-42f4-a0ae-5bc244c44159',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Murray has focused on economic development for suburban Worcester County communities, supporting small business assistance and workforce development programs. He has co-sponsored economic development legislation aimed at creating jobs and supporting local businesses in the Millbury-Sutton corridor.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BWM1/Bills', 'https://malegislature.gov/Legislators/Profile/BWM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '4702bc3c-0820-42f4-a0ae-5bc244c44159';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '4702bc3c-0820-42f4-a0ae-5bc244c44159'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '4702bc3c-0820-42f4-a0ae-5bc244c44159'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
