-- ============================================================================
-- Migration 380: Joanne M. Comerford Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Joanne M. Comerford (MA State Senator, 25D05).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- data-centers                     4559b513-0fd8-4ed1-babd-f3b554162f40
-- deportation                      44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development           fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                     4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                    c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-access-to-justice       9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-bail-pretrial           1fab5edf-6151-4da0-9704-a7f2113ba54c
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-government-deference    e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-interpretation          448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- judicial-police-accountability   7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-prosecution-priorities  abb99d95-cbb1-4617-8f8b-f220ef6028ca
-- judicial-transparency            6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                   ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                6b9ba6d9-1001-43f5-b073-4d37130696fd
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- social-security                  87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                          683c8084-2281-4920-a07c-18439b2dd413
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                  24e9212c-b011-422a-865c-093e35050901
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Joanne M. Comerford (25D05, external_id=-210005)
-- Politician UUID: 961506eb-3f00-4358-a9a3-1730e7004474

-- ----- Joanne M. Comerford / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Joanne M. Comerford has been a staunch defender of abortion rights. She supported the ROE Act in 2020 and has championed reproductive healthcare as a fundamental right. After the Dobbs decision, she backed legislation to protect Massachusetts abortion providers and patients from out-of-state legal actions and to strengthen the state shield law. She has consistently voted to maintain and expand access to abortion services in Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JMC0', 'https://ballotpedia.org/Joanne_Comerford']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Joanne M. Comerford has been an outspoken advocate for campaign finance reform, supporting measures to reduce the influence of large donors and corporations in elections. She has backed disclosure requirements and limits on campaign contributions. As a progressive who ran community-driven campaigns, she has championed small-dollar fundraising and transparency in campaign financing.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JMC0', 'https://ballotpedia.org/Joanne_Comerford']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Joanne M. Comerford is one of the most vocal climate advocates in the Massachusetts Senate. She has championed the 2021 Climate Act and pushed for even more ambitious climate policies. She has led efforts on clean energy, solar net metering, municipal light plants going green, and community solar access. Her Hampshire-Franklin-Worcester district has significant agricultural and natural lands, and she has incorporated climate resilience for farming communities into her advocacy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JMC0', 'https://malegislature.gov/Bills/192/S9']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Joanne M. Comerford supports community-centered economic development that prioritizes local businesses, worker-owned cooperatives, and sustainable industries. She has backed agricultural economic development and local food systems for her rural district. She supports workforce development and job creation in clean energy sectors while maintaining environmental standards.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JMC0', 'https://ballotpedia.org/Joanne_Comerford']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Joanne M. Comerford has been one of the strongest voices in the Massachusetts Senate against fossil fuel expansion. She has opposed new fossil fuel infrastructure and supported phasing out fossil fuels in favor of clean energy. She has backed bans on new fossil fuel hookups in buildings and supported legislation to accelerate the clean energy transition. She has opposed natural gas expansion projects in western Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JMC0', 'https://malegislature.gov/Bills/192/S9']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Joanne M. Comerford has supported universal healthcare and expanded Medicaid. She has backed MassHealth funding, mental health parity, and rural healthcare access. She has advocated for community health worker programs and expanded behavioral health services. She has also championed food security as a health issue, backing SNAP expansion and local food system investment.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JMC0', 'https://ballotpedia.org/Joanne_Comerford']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Joanne M. Comerford has been a leader on affordable housing legislation, co-sponsoring and championing the 2024 Affordable Homes Act. She has supported tenant protections, anti-displacement policies, and deeply affordable housing funding. Her district includes Northampton and Amherst, college towns facing acute housing affordability crises, and she has advocated for local zoning reform and state investment in affordable housing production.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JMC0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Joanne M. Comerford has been a strong advocate for immigrant rights. She supported the Work and Family Mobility Act and the TRUST Act limiting local law enforcement cooperation with federal immigration authorities. She has also championed access to healthcare and public services for undocumented residents. Her district includes significant immigrant farming communities and she has supported agricultural worker protections.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/JMC0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Joanne M. Comerford is recognized as one of the leading environmental advocates in the Massachusetts Senate. She has championed local environmental protections for the Connecticut River watershed, the Quabbin Reservoir, and agricultural lands in her district. She has backed pesticide reform, clean water protections, open space preservation, and restrictions on new polluting facilities in western Massachusetts communities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JMC0', 'https://ballotpedia.org/Joanne_Comerford']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Joanne M. Comerford was a strong supporter of the Fair Share Amendment (Question 1, 2022) and progressive taxation broadly. She has advocated for using tax revenue to fund public education, healthcare, and climate investments. She has backed closing corporate tax loopholes and ensuring wealthy individuals and corporations pay their fair share. She has been among the more progressive voices on fiscal policy in the Senate.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JMC0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne M. Comerford / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('961506eb-3f00-4358-a9a3-1730e7004474',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Joanne M. Comerford has been a champion of voting rights expansion. She backed the VOTES Act making early voting and vote-by-mail permanent and has advocated for automatic voter registration and same-day voter registration. She has supported legislation to protect voters from misinformation and disinformation about elections. She represents college communities like Amherst where student voting access is a significant issue.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/JMC0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 11 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '961506eb-3f00-4358-a9a3-1730e7004474';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '961506eb-3f00-4358-a9a3-1730e7004474'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '961506eb-3f00-4358-a9a3-1730e7004474'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
