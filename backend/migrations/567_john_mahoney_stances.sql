-- ============================================================================
-- Migration 567: John J. Mahoney Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for John J. Mahoney (MA State
--   Representative, 13th Worcester District, HD-152). Democrat.
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

-- John J. Mahoney (HD-152, external_id=-210192, id=50838d91-2ce4-4aa6-8950-b87579860a4b)
-- Democrat representing the 13th Worcester District (Worcester area)
-- Long-serving veteran Worcester legislator

-- ----- John J. Mahoney / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Mahoney has been a consistent supporter of healthcare expansion in Massachusetts throughout his long legislative career. He has co-sponsored legislation expanding MassHealth coverage, mental health parity, and healthcare access improvements for Worcester residents. He has backed the MA Democratic caucus position on healthcare expansion in the 194th General Court.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJM2/Bills', 'https://malegislature.gov/Legislators/Profile/JJM2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Mahoney / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Mahoney voted for the ROE Act (H.4998, 2020) which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. This vote placed him among the pro-choice majority in the MA Democratic House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/JJM2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Mahoney / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Mahoney supported the Fair Share Amendment (Question 1, 2022) adding a 4% surtax on income over $1 million to fund education and transportation. Representing Worcester, a working-class city, he backed progressive revenue measures to fund public services and infrastructure improvements, consistent with his long record of supporting investment in Worcester.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJM2', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Mahoney / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Mahoney voted for the Police Reform Act (H.4011, 2020) establishing statewide police certification, banning chokeholds, and limiting qualified immunity. A Worcester veteran legislator, he supported accountability reforms while also prioritizing community safety, reflecting a balance between reform and public safety needs in an urban district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/JJM2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Mahoney / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Mahoney has supported the Affordable Homes Act (H.5034) and affordable housing production legislation to address Worcester's housing needs. He has backed increased housing production with affordability requirements and supported the MA Democratic caucus housing agenda to address the statewide housing crisis.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJM2/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Mahoney / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Mahoney supported the Massachusetts climate roadmap (H.4264, 2021) and clean energy legislation in the 194th General Court. He has backed climate action and clean energy transition consistent with the MA Democratic caucus position, supporting renewable energy development for Worcester and central Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJM2/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Mahoney / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Mahoney supported the VOTES Act (H.5001, 2022) making early voting permanent and expanding mail-in voting in Massachusetts. He backed expanded voting access measures consistent with the MA Democratic caucus position on democratic participation and voter access.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/JJM2/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Mahoney / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Mahoney supported the Work and Family Mobility Act (H.3256, 2022) providing driver's licenses to undocumented immigrants, voting with the Democratic majority. He has backed pro-immigrant legislation in the MA House, supporting Worcester's diverse immigrant communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/JJM2/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Mahoney / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50838d91-2ce4-4aa6-8950-b87579860a4b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Mahoney has been a champion for Worcester economic development throughout his legislative career, supporting biotech corridor development, WPI and Clark University research partnerships, and manufacturing revitalization in central Massachusetts. He has co-sponsored economic development legislation in the 194th General Court with a focus on revitalizing Worcester's urban core.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJM2/Bills', 'https://malegislature.gov/Legislators/Profile/JJM2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 9 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '50838d91-2ce4-4aa6-8950-b87579860a4b';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '50838d91-2ce4-4aa6-8950-b87579860a4b'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '50838d91-2ce4-4aa6-8950-b87579860a4b'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
