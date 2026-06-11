-- ============================================================================
-- Migration 402: Patricia D. Jehlen Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Patricia D. Jehlen (MA State Senator, 25D27,
--   Second Middlesex District — Somerville, part of Medford).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: d40a0eda-36fc-4032-8382-20c76a36d6a6 (external_id: -210027)

BEGIN;

-- ----- Patricia D. Jehlen / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Jehlen has been a pioneering civil rights champion throughout her career. She co-sponsored the 2016 Transgender Public Accommodations Act and has supported LGBTQ+ rights legislation since before it was politically mainstream. She was instrumental in the passage of the 2004 same-sex marriage legislation and has backed every subsequent LGBTQ+ rights expansion. She has also been a strong advocate for racial equity, disability rights, and anti-discrimination protections across all categories.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0', 'https://www.masslive.com/politics/2016/07/massachusetts-transgender-rights-anti-discrimination-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia D. Jehlen / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Jehlen was a leading supporter of marriage equality in Massachusetts. She voted in the constitutional convention against a constitutional amendment that would have banned same-sex marriage in 2004 and 2007. She has long championed equal marriage rights and has been a vocal opponent of any attempts to restrict same-sex couples from full marriage equality. She backed federal legislation to codify same-sex marriage and celebrated the Obergefell decision.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0', 'https://www.baywindows.com/jehlen-same-sex-marriage-history/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia D. Jehlen / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Jehlen has been a strong housing justice advocate representing Somerville, one of the most expensive housing markets in the country. She has backed affordable housing production, anti-displacement protections, and tenant protections. She supported the 2024 Affordable Homes Act and has backed state funding for affordable housing in her district. She has championed right-to-counsel for tenants facing eviction and has backed inclusionary zoning requirements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia D. Jehlen / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Jehlen has been a long-standing advocate for rent stabilization in Massachusetts. She has filed and co-sponsored rent stabilization legislation repeatedly over the years. Somerville, which she represents, implemented rent stabilization after the city gained authority through home rule. She has championed the state-level legislation that would allow municipalities to adopt rent stabilization and has been a persistent advocate for this tool to prevent displacement of long-term residents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0', 'https://www.wbur.org/news/2023/02/15/massachusetts-rent-stabilization-legislation-senate']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia D. Jehlen / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Jehlen voted for the 2022 Work and Family Mobility Act and has been a long-standing immigrant rights advocate. She backed the Safe Communities Act limiting state cooperation with ICE and has consistently supported legislation expanding access to state services for immigrants regardless of status. She has championed in-state tuition for undocumented students and backed comprehensive immigration reform at the state level. Somerville has significant immigrant communities and she has been a strong ally.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia D. Jehlen / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Jehlen has been a strong healthcare access advocate who has championed the expansion of MassHealth and supported universal coverage approaches. She has backed the 2022 mental health parity law and legislation to improve access to mental healthcare for all residents. She has been a consistent advocate for reproductive healthcare access and supported measures protecting abortion rights. She has backed legislation improving access to gender-affirming care for transgender individuals.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0', 'https://www.wbur.org/news/2022/11/21/massachusetts-mental-health-parity-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia D. Jehlen / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Jehlen has been a long-standing champion of reproductive rights. She voted for the 2020 ROE Act expanding abortion access in Massachusetts and removing restrictions including the parental consent requirement for minors. She has backed legislation strengthening protections for abortion providers and patients. After the Dobbs decision she has been outspoken in calling for strengthening Massachusetts as a reproductive healthcare sanctuary and has backed legislation to protect providers and patients from out-of-state prosecution.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2090', 'https://www.wbur.org/news/2020/12/28/roe-act-signed-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia D. Jehlen / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Jehlen voted for the 2021 Climate Act and has consistently supported aggressive climate action. She backed building electrification mandates, accelerated offshore wind procurement, and clean energy investments. She represents one of the most climate-conscious districts in the state (Somerville) and has been a strong advocate for ambitious emissions reductions. She has supported renewable energy programs and backed climate justice provisions.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia D. Jehlen / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Jehlen voted for the 2020 police reform law and has been a consistent advocate for significant criminal justice reform. She supported abolishing solitary confinement and has backed major sentencing reform legislation. She was an early supporter of pretrial release reform reducing reliance on cash bail. She has backed community-based violence interruption and mental health crisis response alternatives. Her record reflects the most reform-oriented end of the Democratic caucus on criminal justice.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia D. Jehlen / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d40a0eda-36fc-4032-8382-20c76a36d6a6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Jehlen strongly supported the 2022 millionaires surtax (Question 1) and has consistently backed progressive taxation. She has voted for budgets prioritizing social services, housing, and education funded through progressive revenue. She has backed the Child and Family Tax Credit and tax relief targeted at low- and middle-income residents. She has been a consistent opponent of across-the-board tax cuts that she argues disproportionately benefit the wealthy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
