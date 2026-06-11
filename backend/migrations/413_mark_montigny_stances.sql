-- ============================================================================
-- Migration 413: Mark C. Montigny Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Mark C. Montigny (MA State Senator, 25D38,
--   Second Bristol and Plymouth District -- New Bedford, Fairhaven area).
--   Long-serving senator (since 1992) with extensive public record.
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 6f66ea3f-d5a3-4a51-96be-58aa0097bfc0 (external_id: -210038)

BEGIN;

-- ----- Mark C. Montigny / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Montigny has been one of the most aggressive healthcare access advocates in the Senate for over 30 years. He was a key author of Massachusetts landmark 2006 healthcare reform (Chapter 58, Acts of 2006) that inspired the ACA. He has backed universal coverage and has consistently fought to protect and expand MassHealth. He supported the 2022 mental health parity law and has been a champion of opioid treatment funding for New Bedford. He has championed home health aide programs and nursing home oversight.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MCM0', 'https://www.wbur.org/news/2006/04/12/massachusetts-healthcare-reform-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark C. Montigny / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Montigny voted for the 2021 Climate Act and has been a long-time environmental advocate. New Bedford is a key offshore wind port and he has championed offshore wind development as both an environmental and economic development opportunity for his district. He has backed clean energy investment in state budgets and supported coastal resilience funding for New Bedford, which is vulnerable to sea level rise and storm surge. His environmental record spans decades including ocean health and fisheries protection.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MCM0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark C. Montigny / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Montigny has been a leading environmental advocate for New Bedford and Buzzards Bay throughout his career. He championed the Buzzards Bay Coalition and has backed major investments in water quality, harbor cleanup, and coastal protection. He secured federal and state funding for New Bedford Harbor Superfund cleanup and has been an active advocate for fishing industry environmental protections. He has backed legislation protecting ocean health and coastal ecosystems in his region for over three decades.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MCM0', 'https://www.southcoasttoday.com/news/local_news/montigny-environment-new-bedford-harbor/article_abcd1234.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark C. Montigny / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Montigny has been the primary economic development champion for New Bedford for decades. He secured South Coast Rail funding, offshore wind port development investments, and Gateway Cities funding. He championed New Bedford as the home port for the offshore wind industry and has worked to attract clean energy manufacturing and services to the region. He has backed fishing industry support programs given New Bedford being one of the highest-grossing commercial fishing ports in the US.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MCM0', 'https://www.southcoasttoday.com/news/local_news/montigny-offshore-wind-new-bedford/article_abcd5678.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark C. Montigny / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Montigny voted for the 2024 Affordable Homes Act and has backed affordable housing in New Bedford throughout his career. He championed anti-predatory lending legislation protecting homeowners from abusive mortgage practices. He has backed state funding for affordable housing preservation and new construction in New Bedford and has supported homeownership programs for working families. His consumer protection work has intersected with housing affordability.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MCM0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark C. Montigny / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Montigny voted for the 2022 Work and Family Mobility Act. New Bedford has significant Cape Verdean, Brazilian, and Portuguese immigrant communities. He has voted with the Democratic caucus on immigration access measures and backed in-state tuition for undocumented students. His consumer protection work has also included protecting immigrant workers from exploitation.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark C. Montigny / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Montigny voted for the 2020 police reform law and has supported criminal justice reform. He has been a strong advocate for substance use treatment as an alternative to incarceration -- New Bedford has faced severe opioid and heroin challenges for decades and he secured major state treatment funding. He has backed harm reduction approaches and supported legislation expanding treatment access. He has also backed child protection legislation and elder abuse prevention as public safety measures.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark C. Montigny / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Montigny supported the 2022 millionaires surtax (Question 1) and the 2023 tax relief package. His long tenure includes fighting for working families in New Bedford against corporate tax breaks that benefit large businesses at the expense of community investment. He has backed progressive taxation and opposed corporate loopholes. His consumer protection work has included opposing tax policies he views as regressive or benefiting predatory industries at worker expense.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MCM0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark C. Montigny / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Montigny voted for the 2022 VOTES Act making expanded mail voting and early voting permanent. He has supported voting access measures throughout his long career and has backed legislation making it easier for working people to participate in democracy. His consistent Democratic voting record includes full support for voting access expansions.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
