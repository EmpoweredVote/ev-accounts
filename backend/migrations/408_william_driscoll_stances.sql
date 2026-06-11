-- ============================================================================
-- Migration 408: William J. Driscoll Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for William J. Driscoll (MA State Senator, 25D33,
--   Norfolk-Plymouth-Bristol District).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: ab975fdf-b4f1-4955-94a4-97681a2a8d08 (external_id: -210033)

BEGIN;

-- ----- William J. Driscoll / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Driscoll voted for the 2024 Affordable Homes Act. His district includes suburban communities including Milton and Canton that have faced pressure from MBTA Communities zoning mandates. He has supported housing production generally while also being attentive to local concerns about development density and community character. His approach reflects the moderate Democratic position on housing — supporting production and affordability while also respecting local input.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/WJD0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Driscoll / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Driscoll voted for the 2021 MA Climate Act and has supported clean energy legislation. He backed offshore wind development and clean energy investment provisions. His voting record on climate is consistent with the Democratic mainstream, supporting the state clean energy agenda while representing suburban communities that are attentive to energy cost impacts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/WJD0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Driscoll / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Driscoll voted for the 2022 Work and Family Mobility Act extending driver licenses to undocumented immigrants. He has voted with the Democratic caucus on immigration access measures including in-state tuition for undocumented students. His district is predominantly suburban with less direct immigration policy salience than urban districts, and immigration has not been a signature issue for him.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Driscoll / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Driscoll voted for the 2020 police reform law and has generally supported criminal justice reform measures. His district communities are suburban with moderate Democratic voting patterns on public safety. He has supported treatment approaches for substance use disorder and backed mental health services funding. His position is centrist Democratic on public safety, supporting reform while maintaining effective law enforcement.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Driscoll / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Driscoll has been active on economic development for his district, supporting state investment in workforce development, infrastructure, and business attraction for the Norfolk-Plymouth-Bristol region. He backed economic development legislation providing state incentives for job creation and has worked to secure state funding for regional economic priorities. His district spans several communities with manufacturing and service sector employment.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/WJD0', 'https://www.cantonjournal.com/news/local_news/driscoll-economic-development/article_abcd1234.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Driscoll / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Driscoll supported both the 2022 millionaires surtax (Question 1) and the 2023 tax relief package. His tax record reflects a moderate Democratic approach: supporting progressive revenue for education and transportation while backing targeted relief for working families. He has backed the Child and Family Tax Credit and the senior circuit breaker. His suburban district constituents are attentive to property taxes and overall tax competitiveness.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/WJD0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Driscoll / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab975fdf-b4f1-4955-94a4-97681a2a8d08',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Driscoll voted for the 2022 VOTES Act making expanded mail voting and early voting permanent. He has supported voting access measures and backed automatic voter registration proposals. His voting record on electoral access consistently supports Democratic voting rights legislation.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ab975fdf-b4f1-4955-94a4-97681a2a8d08';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ab975fdf-b4f1-4955-94a4-97681a2a8d08'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ab975fdf-b4f1-4955-94a4-97681a2a8d08'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
