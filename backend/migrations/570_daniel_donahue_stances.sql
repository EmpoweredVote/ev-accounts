-- ============================================================================
-- Migration 570: Daniel M. Donahue Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Daniel M. Donahue (MA State
--   Representative, 16th Worcester District, HD-155). Democrat.
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

-- Daniel M. Donahue (HD-155, external_id=-210195, id=71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b)
-- Democrat representing the 16th Worcester District (Worcester area)

-- ----- Daniel M. Donahue / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Donahue has co-sponsored healthcare expansion legislation in the MA House, supporting MassHealth coverage expansion and mental health parity bills. He has backed healthcare access improvements for Worcester residents and supported the MA Democratic caucus position on expanding state healthcare coverage in the 194th General Court.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DMD1/Bills', 'https://malegislature.gov/Legislators/Profile/DMD1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel M. Donahue / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Donahue voted for the ROE Act (H.4998, 2020) which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. This vote placed him with the pro-choice majority in the MA Democratic House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/DMD1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel M. Donahue / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Donahue supported the Fair Share Amendment (Question 1, 2022) adding a 4% surtax on income over $1 million to fund education and transportation. Representing a working-class Worcester district, he backed progressive revenue measures to fund public services and infrastructure improvements for his constituents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DMD1', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel M. Donahue / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Donahue voted for the Police Reform Act (H.4011, 2020) establishing statewide police certification, banning chokeholds, and limiting qualified immunity. He has supported accountability-oriented policing reforms alongside community safety priorities for Worcester's urban neighborhoods.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/DMD1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel M. Donahue / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Donahue supported the Affordable Homes Act (H.5034) and affordable housing production legislation. He has backed increased housing access for working families in Worcester and supported the MA Democratic caucus housing agenda to address the statewide housing crisis with affordability requirements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DMD1/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel M. Donahue / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Donahue supported the Massachusetts climate roadmap (H.4264, 2021) and clean energy legislation in the 194th General Court. He has backed climate action and clean energy transition consistent with the MA Democratic caucus, supporting reduced emissions and renewable energy development for Worcester and central Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DMD1/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel M. Donahue / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Donahue supported the VOTES Act (H.5001, 2022) making early voting permanent and expanding mail-in voting in Massachusetts. He backed expanded voting access measures consistent with the MA Democratic caucus position.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/DMD1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel M. Donahue / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Donahue supported the Work and Family Mobility Act (H.3256, 2022) providing driver's licenses to undocumented immigrants, voting with the Democratic majority. He has backed pro-immigrant legislation in the MA House consistent with Worcester's diverse immigrant population.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/DMD1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel M. Donahue / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Donahue has supported economic development initiatives for Worcester, including small business support and workforce development programs. He has co-sponsored economic development legislation in the 194th General Court focused on community investment and job creation in Worcester's urban core, including support for the innovation district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DMD1/Bills', 'https://malegislature.gov/Legislators/Profile/DMD1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 9 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
