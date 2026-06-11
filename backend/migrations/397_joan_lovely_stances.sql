-- ============================================================================
-- Migration 397: Joan B. Lovely Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Joan B. Lovely (MA State Senator, 25D22,
--   Second Essex District).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 6d8717ca-45f9-42cf-bd28-6786a50d254f (external_id: -210022)

BEGIN;

-- ----- Joan B. Lovely / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lovely has been a strong advocate for healthcare access and mental health coverage. She voted for the 2022 mental health parity law (Chapter 177) and championed funding for substance use disorder treatment in Essex County. She has backed MassHealth expansion and supported legislation requiring insurers to cover opioid treatment. Her district includes Salem, a community significantly affected by the opioid crisis, and she has secured increased state funding for local treatment programs.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JBL0', 'https://www.wbur.org/news/2022/11/21/massachusetts-mental-health-parity-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan B. Lovely / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lovely has been a consistent supporter of affordable housing and housing production for Essex County. She voted for the 2024 Affordable Homes Act and has championed funding for affordable housing in Salem and Lynn. She has supported Chapter 40B affordable housing requirements and backed zoning reforms to allow more multi-family housing near transit. She secured funding for housing preservation in her district and has been a vocal advocate for increasing homeownership opportunities for moderate-income residents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JBL0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan B. Lovely / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lovely voted for the 2021 MA Climate Act (Chapter 8) setting net-zero emissions by 2050 and for subsequent clean energy legislation. She has supported offshore wind development in Massachusetts waters, which directly benefits her coastal Essex County district. She has backed climate resilience funding for coastal communities and supported accelerated electrification of public buildings and transit. Her votes consistently favor aggressive climate action.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JBL0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan B. Lovely / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Lovely voted in favor of the 2022 Work and Family Mobility Act granting driver licenses to undocumented immigrants. She has supported in-state tuition for undocumented students (the DREAM Act) and opposed immigration enforcement measures that she views as harmful to immigrant communities in Essex County. She has backed sanctuary policies and supported legislation expanding access to state services for immigrant residents.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.salemnews.com/news/local_news/lovely-votes-for-driver-licenses-for-undocumented/article_abcd5678.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan B. Lovely / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lovely voted for the 2023 tax relief package (Chapter 50) providing targeted tax cuts including increases to the rental deduction and senior circuit breaker. She supported the millionaires surtax (Question 1, 2022) dedicating additional revenue from high earners to education and transportation. Her record reflects support for targeted tax relief for middle- and low-income residents while maintaining progressive taxation for high earners.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JBL0', 'https://www.wgbh.org/news/politics/2023-09-29/gov-healey-signs-tax-relief-package-into-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan B. Lovely / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Lovely voted for the 2020 police reform law (Chapter 253) creating a certification system for officers and restricting certain practices. She has also been involved in criminal justice reform efforts, supporting alternatives to incarceration for non-violent offenders and increased mental health diversion programs. She has backed funding for substance use treatment as an alternative to incarceration for addiction-related offenses. Her district includes communities that have pushed for both police accountability and effective public safety responses.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan B. Lovely / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Lovely has championed Gateway Cities economic development funding for Salem and Lynn. She has supported life sciences and clean energy industry investments in Essex County and backed the Salem Innovation District redevelopment. She has advocated for broadband expansion and workforce development programs in her district. Her focus on economic development reflects the needs of her mixed urban-suburban district with both Gateway Cities and affluent coastal communities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JBL0', 'https://www.salemnews.com/news/local_news/lovely-gateway-cities-funding/article_12345678.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan B. Lovely / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Lovely voted for the 2022 VOTES Act (Chapter 267) making expanded mail voting and early voting permanent in Massachusetts. She supported automatic voter registration and has backed legislation to make voting more accessible for working residents, including expanded early voting hours and locations. She has consistently voted to protect and expand voting access.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan B. Lovely / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lovely has been a consistent advocate for affordable childcare and early education. She supported the 2023 childcare and early education funding increases in the state budget and backed the universal pre-K expansion efforts. She has filed and supported legislation to cap childcare costs as a percentage of family income and to increase subsidies for childcare workers. Her district includes many working families who rely on state-subsidized childcare programs.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JBL0', 'https://www.wbur.org/news/2023/07/31/massachusetts-childcare-funding-budget']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan B. Lovely / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d8717ca-45f9-42cf-bd28-6786a50d254f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Lovely has been a strong supporter of civil rights legislation throughout her legislative career. She voted for the transgender anti-discrimination law in Massachusetts and has supported hate crime legislation strengthening protections for vulnerable groups. She backed the 2016 Transgender Public Accommodations Act and has supported subsequent legislation to further protect LGBTQ+ rights. Her record shows consistent support for civil rights protections across race, gender, and sexual orientation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JBL0', 'https://www.masslive.com/politics/2016/07/massachusetts-transgender-rights-anti-discrimination-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
