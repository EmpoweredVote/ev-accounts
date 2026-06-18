-- ============================================================================
-- Migration 566: Meghan Kilcoyne Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Meghan Kilcoyne (MA State
--   Representative, 12th Worcester District, HD-151). Democrat.
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

-- Meghan Kilcoyne (HD-151, external_id=-210191, id=074555d9-2806-4f78-bce9-1958d61742c6)
-- Democrat representing the 12th Worcester District (Clinton/Sterling area)

-- ----- Meghan Kilcoyne / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kilcoyne has co-sponsored healthcare access legislation in the MA House, supporting expanded MassHealth coverage and mental health services. She has backed healthcare expansion initiatives in the 194th General Court consistent with the MA Democratic caucus position, with particular attention to healthcare access in rural Worcester County communities like Clinton and Sterling.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/M_K1/Bills', 'https://malegislature.gov/Legislators/Profile/M_K1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Meghan Kilcoyne / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Kilcoyne voted for the ROE Act (H.4998, 2020) which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. This vote placed her among the pro-choice majority in the MA Democratic House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/M_K1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Meghan Kilcoyne / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Kilcoyne supported the Fair Share Amendment (Question 1, 2022) which added a 4% surtax on income over $1 million to fund education and transportation. Representing a working-class district in the Clinton-Sterling area, she backed progressive revenue measures to fund public services while reducing the burden on working families.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/M_K1', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Meghan Kilcoyne / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Kilcoyne voted for the Police Reform Act (H.4011, 2020) which established statewide police certification, banned chokeholds, and limited qualified immunity. This reform vote reflects support for accountability-oriented policing reforms alongside community safety priorities.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/M_K1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Meghan Kilcoyne / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kilcoyne supported the Affordable Homes Act (H.5034) and MBTA Communities Act to expand housing production in Massachusetts. She has backed affordable housing legislation to address the housing crisis in Worcester County, with emphasis on housing access for working families in smaller communities like Clinton and Sterling.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/M_K1/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Meghan Kilcoyne / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Kilcoyne supported the Massachusetts climate roadmap (H.4264, 2021) and clean energy legislation in the 194th General Court. She has backed climate action and clean energy transition consistent with the MA Democratic caucus, supporting reduced emissions and renewable energy development in central Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/M_K1/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Meghan Kilcoyne / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Kilcoyne supported the VOTES Act (H.5001, 2022) making early voting permanent and expanding mail-in voting in Massachusetts. She backed expanded voting access measures in the legislature, demonstrating a pro-access position on voting rights consistent with the MA Democratic caucus.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/M_K1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Meghan Kilcoyne / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Kilcoyne supported the Work and Family Mobility Act (H.3256, 2022) providing driver's licenses to undocumented immigrants, voting with the Democratic majority. She has backed pro-immigrant legislation in the MA House including the Safe Communities Act limiting state cooperation with federal immigration enforcement.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/M_K1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Meghan Kilcoyne / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('074555d9-2806-4f78-bce9-1958d61742c6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kilcoyne has focused on economic development for the Clinton-Sterling area, supporting small business assistance, broadband access expansion, and workforce development programs for rural Worcester County. She has co-sponsored economic development legislation in the 194th General Court aimed at revitalizing smaller communities in central Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/M_K1/Bills', 'https://malegislature.gov/Legislators/Profile/M_K1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 9 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '074555d9-2806-4f78-bce9-1958d61742c6';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '074555d9-2806-4f78-bce9-1958d61742c6'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '074555d9-2806-4f78-bce9-1958d61742c6'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
