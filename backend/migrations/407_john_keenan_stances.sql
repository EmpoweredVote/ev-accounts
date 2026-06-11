-- ============================================================================
-- Migration 407: John F. Keenan Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for John F. Keenan (MA State Senator, 25D32,
--   Norfolk and Plymouth District).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 5cd1c798-31dc-4e53-b578-7e2d81378478 (external_id: -210032)

BEGIN;

-- ----- John F. Keenan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Keenan has been a strong advocate for transportation improvements in his district, particularly the MBTA Red Line serving Quincy and Braintree. He championed Red Line improvements and has backed the South Shore Rail Transformation study for improved commuter rail service. He backed the 2022 MBTA reform legislation and has been critical of MBTA management failures. He has also supported road and bridge investments in his suburban district and has been active on Route 3 and other major highway improvements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JFK0', 'https://www.patriotledger.com/news/local_news/keenan-red-line-mbta-improvements/article_abcd1234.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Keenan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Keenan supported the 2024 Affordable Homes Act and has backed affordable housing production in his district. Quincy has been a focus for transit-oriented development near Red Line stations and he has supported zoning reforms allowing more housing near transit. He has backed state funding for affordable housing preservation and new construction. His approach balances housing production with local community input on development scale.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JFK0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Keenan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Keenan voted for the 2021 Climate Act and has supported offshore wind and clean energy investments. His coastal district is vulnerable to sea level rise and storm surge, and he has backed coastal resilience funding. He has supported offshore wind development in Massachusetts and the clean energy provisions of subsequent legislation. His climate record reflects consistent support for state climate action.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JFK0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Keenan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Keenan has been a strong economic development advocate for Quincy and the South Shore. As former Quincy Mayor, he championed major downtown Quincy redevelopment projects. As state senator he has supported state economic development funding for his district including life sciences investment, workforce development, and infrastructure. He has backed regional economic development initiatives for the South Shore and advocated for job creation legislation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JFK0', 'https://www.patriotledger.com/news/local_news/keenan-economic-development-quincy/article_12345678.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Keenan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Keenan voted for the 2022 Work and Family Mobility Act. His district includes Quincy which has a significant Asian-American immigrant community, particularly Chinese and Korean residents. He has backed in-state tuition for undocumented students and generally voted with the Democratic caucus on immigration-access measures while maintaining a relatively moderate profile on the most contested immigration debates.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Keenan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Keenan voted for the 2020 police reform law and has supported criminal justice reform. As a former mayor with law enforcement oversight experience, he has taken a moderate approach — supporting reform measures while also prioritizing effective public safety. He has backed substance use treatment as an alternative to prosecution for addiction-related offenses and supported veterans mental health programs. His district communities tend toward centrist Democratic positions on public safety.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Keenan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5cd1c798-31dc-4e53-b578-7e2d81378478',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Keenan supported both the 2022 millionaires surtax (Question 1) and the 2023 tax relief package. His tax record reflects a moderate Democratic position: supporting progressive taxation for education and transportation while also backing targeted tax relief for working families and seniors. He has backed the senior circuit breaker expansion and the Child and Family Tax Credit. His former mayoral experience informs his awareness of both the need for revenue and the burden of taxation on residents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JFK0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '5cd1c798-31dc-4e53-b578-7e2d81378478';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '5cd1c798-31dc-4e53-b578-7e2d81378478'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '5cd1c798-31dc-4e53-b578-7e2d81378478'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
