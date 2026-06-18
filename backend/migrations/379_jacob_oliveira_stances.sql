-- ============================================================================
-- Migration 379: Jacob R. Oliveira Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jacob R. Oliveira (MA State Senator, 25D04).
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

-- Jacob R. Oliveira (25D04, external_id=-210004)
-- Politician UUID: ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5

-- ----- Jacob R. Oliveira / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Jacob R. Oliveira has voted in favor of abortion rights legislation in Massachusetts. He supported bills to protect abortion access and has backed protections for patients and providers following the Dobbs decision. As a Democratic senator from a district spanning parts of Hampden, Hampshire, and Worcester counties, he aligns with the progressive majority in protecting reproductive healthcare access.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JRO0', 'https://ballotpedia.org/Jacob_Oliveira']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jacob R. Oliveira / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Jacob R. Oliveira supported the 2021 Next-Generation Climate Roadmap Act establishing net-zero emissions targets for Massachusetts. His district spans mixed urban and rural communities, and he has backed clean energy development as an economic opportunity for the region. He supports climate action with a pragmatic focus on economic development and job creation alongside environmental goals.$$,
        ARRAY['https://malegislature.gov/Bills/192/S9', 'https://malegislature.gov/Legislators/Profile/JRO0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jacob R. Oliveira / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Jacob R. Oliveira has been a strong advocate for economic development in his tri-county district. He has supported workforce development legislation, small business investment, and programs to revitalize communities in the Springfield metro and Worcester area periphery. He has backed infrastructure investments and vocational education funding to create economic opportunity.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JRO0', 'https://ballotpedia.org/Jacob_Oliveira']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jacob R. Oliveira / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Jacob R. Oliveira has supported expanding healthcare access and has been particularly focused on mental health services and substance use disorder treatment in his district. He has backed MassHealth expansions and behavioral health reforms. His district communities have been significantly affected by the opioid crisis, and he has championed treatment-focused approaches over incarceration.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JRO0', 'https://ballotpedia.org/Jacob_Oliveira']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jacob R. Oliveira / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Jacob R. Oliveira has supported the 2024 Affordable Homes Act and housing production legislation in Massachusetts. His district includes both urban communities with housing cost burdens and rural areas with aging housing stock. He has backed increased state investment in affordable housing and infrastructure to support housing development across his tri-county district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JRO0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jacob R. Oliveira / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Jacob R. Oliveira supported the Work and Family Mobility Act allowing undocumented immigrants to get driver's licenses. He has backed immigrant-friendly policies consistent with his Democratic caucus. His district includes Latino communities, particularly in Holyoke and Palmer areas, and he has supported language access services and immigrant integration programs.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/JRO0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jacob R. Oliveira / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Jacob R. Oliveira supported the Fair Share Amendment (Question 1, 2022) and has backed using tax revenue to fund education, transportation, and healthcare services. He has emphasized that tax investments must deliver results for residents in his economically diverse district. His approach is progressive but with attention to the economic competitiveness needs of businesses in his region.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JRO0', 'https://ballotpedia.org/Jacob_Oliveira']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jacob R. Oliveira / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Jacob R. Oliveira backed the VOTES Act making early voting and vote-by-mail permanent in Massachusetts. He has supported measures to expand voter access and make it easier for working families in his district to participate in elections. He has aligned with the Democratic majority on voting rights protections.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/JRO0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
