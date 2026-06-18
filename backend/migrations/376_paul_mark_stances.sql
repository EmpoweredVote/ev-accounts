-- ============================================================================
-- Migration 376: Paul W. Mark Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Paul W. Mark (MA State Senator, 25D01).
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

-- Paul W. Mark (25D01, external_id=-210001)
-- Politician UUID: f530be83-6f1b-4b04-a8c4-3a83dc35099f

-- ----- Paul W. Mark / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Paul W. Mark has consistently voted to protect and expand abortion access in Massachusetts. He supported the ROE Act in 2020, which expanded abortion rights in the state, and has backed subsequent reproductive rights legislation. As a senator from a district that includes both urban and rural communities, he has emphasized that abortion access is a fundamental healthcare right. He co-sponsored legislation to ensure abortion remains accessible even if federal protections are rolled back.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PWM0', 'https://malegislature.gov/Bills/192/S1209']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Paul W. Mark has supported campaign finance reform measures, favoring stricter limits on money in politics. He has backed transparency measures requiring disclosure of campaign contributions and has expressed concern about the influence of corporate money on elections. His district in western Massachusetts includes many working-class communities, and he has advocated for campaign finance rules that limit the influence of wealthy donors and corporate PACs.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PWM0', 'https://ballotpedia.org/Paul_Mark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Paul W. Mark has been a strong advocate for climate action in Massachusetts. He supported the 2021 Climate Act (An Act Creating a Next-Generation Roadmap for Massachusetts Climate Policy), which set ambitious emissions reduction targets. His district in western MA includes rural areas and farmland particularly vulnerable to climate change impacts, and he has championed clean energy transition and environmental protection. He has backed solar energy expansion and clean energy incentives for rural communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/S9', 'https://malegislature.gov/Legislators/Profile/PWM0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Paul W. Mark has focused on economic development for his rural western Massachusetts district, which has faced economic challenges and population decline. He has advocated for rural broadband expansion, workforce development programs, and support for small businesses. While supportive of economic growth, he emphasizes community-centered development that protects working families and the environment rather than prioritizing corporate interests.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PWM0', 'https://ballotpedia.org/Paul_Mark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Paul W. Mark has supported Massachusetts' transition away from fossil fuels as part of the state's climate policy. He voted in favor of the 2021 Next-Generation Climate Roadmap Act, which set a goal of net-zero emissions by 2050 and includes measures to phase down fossil fuel use. He has supported renewable energy development over new fossil fuel infrastructure investment.$$,
        ARRAY['https://malegislature.gov/Bills/192/S9', 'https://malegislature.gov/Legislators/Profile/PWM0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Paul W. Mark has been a strong advocate for expanding healthcare access in Massachusetts. He has supported MassHealth expansion and measures to ensure rural healthcare access, which is a critical concern in his western Massachusetts district where hospital closures and provider shortages have been ongoing issues. He has backed legislation to strengthen healthcare worker protections and expand mental health services.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PWM0', 'https://ballotpedia.org/Paul_Mark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Paul W. Mark has supported affordable housing initiatives for his rural district, where housing costs relative to income are a burden on working families. He backed the 2024 Affordable Homes Act, one of the largest housing investments in Massachusetts history, which included funding for public housing, rental assistance, and homeownership programs. He has emphasized housing solutions that prioritize existing residents and working families over luxury development.$$,
        ARRAY['https://malegislature.gov/Bills/193/SD3030', 'https://malegislature.gov/Legislators/Profile/PWM0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Paul W. Mark has generally supported immigrant-friendly policies in Massachusetts. His district includes a growing immigrant population in communities like Pittsfield and Holyoke. He has supported the Work and Family Mobility Act, which allowed undocumented immigrants to obtain driver's licenses, and has backed policies to protect immigrant communities from federal immigration enforcement overreach.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/PWM0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Paul W. Mark supported the Fair Share Amendment (Question 1, 2022), which added a 4% surtax on income over $1 million to fund education and transportation. He has advocated for progressive taxation that asks more of the wealthy while protecting working and middle-class families. He represents a district with below-average incomes relative to the state, making tax fairness a key issue for his constituents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PWM0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Paul W. Mark has focused on transportation equity for his rural district, which lacks access to MBTA public transit and relies heavily on cars and regional bus services. He has advocated for investments in regional transit (PVTA, BRTA) and rural road infrastructure. He has backed broadband expansion as a transportation-related connectivity issue and has sought state funding for rural road and bridge improvements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PWM0', 'https://ballotpedia.org/Paul_Mark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul W. Mark / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f530be83-6f1b-4b04-a8c4-3a83dc35099f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Paul W. Mark has supported voting rights expansion in Massachusetts. He backed the VOTES Act, which made early voting and vote-by-mail permanent in Massachusetts, codifying the emergency measures enacted during the COVID-19 pandemic. He has supported automatic voter registration and other measures to increase electoral participation, particularly for rural and working-class voters who may face barriers to participation.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/PWM0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 11 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'f530be83-6f1b-4b04-a8c4-3a83dc35099f';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'f530be83-6f1b-4b04-a8c4-3a83dc35099f'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'f530be83-6f1b-4b04-a8c4-3a83dc35099f'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
