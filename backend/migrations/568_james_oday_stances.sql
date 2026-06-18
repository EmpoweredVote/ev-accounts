-- ============================================================================
-- Migration 568: James J. O'Day Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for James J. O'Day (MA State
--   Representative, 14th Worcester District, HD-153). Democrat.
--   Note: Apostrophe in last name; file uses oday.
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

-- James J. O'Day (HD-153, external_id=-210193, id=9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf)
-- Democrat representing the 14th Worcester District (West Boylston/Holden area)

-- ----- James J. O'Day / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$O'Day has co-sponsored healthcare expansion legislation in the MA House, supporting MassHealth expansion and mental health parity initiatives. He has backed healthcare access improvements for residents of his suburban Worcester County district and supported the MA Democratic caucus position on expanding state healthcare coverage in the 194th General Court.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJO1/Bills', 'https://malegislature.gov/Legislators/Profile/JJO1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James J. O'Day / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$O'Day voted for the ROE Act (H.4998, 2020) which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. This vote placed him with the pro-choice majority in the MA Democratic House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/JJO1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James J. O'Day / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$O'Day supported the Fair Share Amendment (Question 1, 2022) which added a 4% surtax on income over $1 million to fund education and transportation. He backed progressive revenue measures to fund public services and infrastructure in his suburban Worcester County district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJO1', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James J. O'Day / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$O'Day voted for the Police Reform Act (H.4011, 2020) which established statewide police certification, banned chokeholds, and limited qualified immunity in Massachusetts. This reform vote reflects support for accountability-oriented policing reforms alongside community safety needs in his suburban Worcester County district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/JJO1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James J. O'Day / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$O'Day supported the Affordable Homes Act (H.5034) and affordable housing production legislation. He has backed increased housing access for working families in his district and supported the MA Democratic caucus housing agenda to address the statewide housing crisis.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJO1/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James J. O'Day / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$O'Day supported the Massachusetts climate roadmap (H.4264, 2021) and clean energy legislation in the 194th General Court. He has backed climate action and clean energy transition consistent with the MA Democratic caucus, supporting reduced emissions and renewable energy development.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJO1/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James J. O'Day / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$O'Day supported the VOTES Act (H.5001, 2022) making early voting permanent and expanding mail-in voting in Massachusetts. He backed expanded voting access measures consistent with the MA Democratic caucus position on democratic participation.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/JJO1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James J. O'Day / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$O'Day supported the Work and Family Mobility Act (H.3256, 2022) providing driver's licenses to undocumented immigrants, voting with the Democratic majority. He has backed pro-immigrant legislation in the MA House consistent with his district's diverse communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/JJO1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
