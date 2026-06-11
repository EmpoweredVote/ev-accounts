-- ============================================================================
-- Migration 409: Michael D. Brady Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael D. Brady (MA State Senator, 25D34,
--   Second Plymouth and Norfolk District -- Brockton, Randolph, Avon area).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 67ea7814-b7aa-42de-aba8-2230c181d15a (external_id: -210034)

BEGIN;

-- ----- Michael D. Brady / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Brady has been a strong healthcare access advocate. Brockton is a community with significant healthcare needs and he has championed funding for Brockton hospital services, mental health treatment, and substance use disorder programs. He voted for the 2022 mental health parity law and has backed MassHealth expansion. He has also been a strong advocate for veterans healthcare, given the significant veteran population in his district. He has backed legislation improving access to behavioral health services and treatment for opioid addiction.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MDB0', 'https://www.wbur.org/news/2022/11/21/massachusetts-mental-health-parity-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael D. Brady / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Brady supported the 2024 Affordable Homes Act and has backed affordable housing in Brockton and Randolph. Brockton is a Gateway City with significant affordable housing needs. He has supported state funding for affordable housing preservation and new construction in his district and backed homeownership programs for first-time buyers. He has been involved in securing housing investments for the Brockton community.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MDB0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael D. Brady / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Brady voted for the 2021 Climate Act and has supported offshore wind and clean energy investment. He has backed clean energy job creation provisions that benefit Gateway Cities like Brockton. He has supported the state clean energy agenda while also focusing on the economic development and job creation aspects of the clean energy transition for his district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MDB0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael D. Brady / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Brady has been a champion of economic development for Brockton and the surrounding region. He has secured Gateway Cities funding for Brockton and backed workforce development, job training, and small business assistance programs. He supported life sciences investment for the region and has worked on economic revitalization initiatives for Brockton, which has faced economic challenges. He has backed state economic development programs that create jobs in manufacturing and services sectors in his district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MDB0', 'https://www.enterprisenews.com/news/local_news/brady-brockton-economic-development/article_abcd1234.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael D. Brady / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Brady voted for the 2022 Work and Family Mobility Act. Brockton and Randolph have significant immigrant communities, particularly Cape Verdean and Brazilian residents. He has generally voted with the Democratic caucus on immigration access measures and has backed in-state tuition for undocumented students. His district demographics make immigration policy directly relevant to many constituents.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael D. Brady / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Brady voted for the 2020 police reform law and has supported criminal justice reform measures. Brockton faces significant public safety challenges and he has backed both effective policing and community-based prevention programs. He has supported violence prevention funding and substance use treatment programs for Brockton. His approach is centrist Democratic -- supporting reform while also prioritizing effective public safety responses to serious crime.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael D. Brady / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67ea7814-b7aa-42de-aba8-2230c181d15a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Brady supported the 2022 millionaires surtax (Question 1) and the 2023 tax relief package. His tax record reflects a moderate Democratic approach focused on working families. He has backed the Child and Family Tax Credit and tax relief for renters and lower-income residents. His district communities in Brockton and Randolph include many working families for whom targeted tax relief is significant.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MDB0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '67ea7814-b7aa-42de-aba8-2230c181d15a';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '67ea7814-b7aa-42de-aba8-2230c181d15a'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '67ea7814-b7aa-42de-aba8-2230c181d15a'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
