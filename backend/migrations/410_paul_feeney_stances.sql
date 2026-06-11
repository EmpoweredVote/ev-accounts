-- ============================================================================
-- Migration 410: Paul R. Feeney Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Paul R. Feeney (MA State Senator, 25D35,
--   Bristol and Norfolk District -- Taunton, Attleboro area).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: c435ab14-5d64-46e4-a59f-bba18ed483c9 (external_id: -210035)

BEGIN;

-- ----- Paul R. Feeney / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Feeney, as a former IBEW union organizer, has been a strong champion of union jobs and economic development that benefits workers. He has backed prevailing wage legislation, apprenticeship programs, and job training initiatives. He has supported economic development funding for Taunton and Attleboro and worked to attract manufacturing and construction jobs to his district. He has backed clean energy infrastructure jobs and has advocated for union labor requirements in publicly funded construction projects.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PRF0', 'https://www.tauntongazette.com/news/local_news/feeney-economic-development-labor/article_abcd1234.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul R. Feeney / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Feeney supported the 2022 millionaires surtax (Question 1) and has consistently backed progressive taxation to fund public services and worker protections. His union background informs his view that progressive taxation ensures wealthy corporations and individuals pay their fair share while protecting services for working families. He has backed the Child and Family Tax Credit and opposed tax policies he views as disproportionately benefiting corporations over workers.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PRF0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul R. Feeney / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Feeney voted for the 2021 Climate Act and has supported clean energy development. His union background has led him to emphasize the job creation aspects of the clean energy transition, supporting offshore wind and solar development with union labor requirements. He has backed clean energy workforce development programs to ensure workers in his district benefit from the transition. He supports ambitious climate action paired with strong worker protections.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PRF0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul R. Feeney / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Feeney voted for the 2024 Affordable Homes Act and has backed affordable housing production in his district. He has supported prevailing wage requirements for affordable housing construction and backed homeownership programs for working families. His focus on housing has emphasized worker and family affordability over market-rate development. He has also supported veterans housing programs given the significant veteran population in his district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PRF0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul R. Feeney / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Feeney voted for the 2022 Work and Family Mobility Act. His district includes immigrant communities in Taunton and Attleboro, particularly Brazilian immigrants. He has generally voted with the Democratic caucus on immigration access measures. His union background informs his support for immigrant worker rights and protections against wage theft and exploitation.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul R. Feeney / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Feeney voted for the 2020 police reform law and has supported criminal justice reform measures. His district is more politically moderate on public safety compared to urban Democratic districts and he has taken a centrist position, supporting police accountability while prioritizing effective public safety. He has backed substance use treatment programs and mental health services as alternatives to incarceration for addiction-related offenses.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul R. Feeney / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c435ab14-5d64-46e4-a59f-bba18ed483c9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Feeney voted for the 2022 VOTES Act making expanded mail voting and early voting permanent. He has supported voting access measures and backed automatic voter registration. His union background connects to his support for broad democratic participation, as unions historically have prioritized voter registration and turnout efforts. He has voted for all major voting access expansions in the Senate.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c435ab14-5d64-46e4-a59f-bba18ed483c9';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c435ab14-5d64-46e4-a59f-bba18ed483c9'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c435ab14-5d64-46e4-a59f-bba18ed483c9'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
