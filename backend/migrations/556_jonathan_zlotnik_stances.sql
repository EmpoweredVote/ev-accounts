-- ============================================================================
-- Migration 556: Jonathan D. Zlotnik Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jonathan D. Zlotnik (MA State
--   Representative, 2nd Worcester District, HD-141).
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

-- Jonathan D. Zlotnik (HD-141, external_id=-210181, id=869ba820-3138-473c-b70d-383e67f5797d)

-- ----- Jonathan D. Zlotnik / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Zlotnik has consistently co-sponsored legislation expanding healthcare access in Massachusetts, including H.1691 (An Act improving access to mental health services) and bills expanding MassHealth coverage. He has supported universal healthcare coverage initiatives in the 194th General Court, reflecting a strong pro-expansion position on state healthcare policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JDZ1/Bills', 'https://malegislature.gov/Bills/194/H1691']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jonathan D. Zlotnik / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Zlotnik supported the MBTA Communities Act and has co-sponsored affordable housing legislation addressing the housing crisis in Worcester County. He backed the Affordable Homes Act (H.5034) which created new housing production programs, reflecting a pro-affordable-housing stance with emphasis on rural and working-class communities in the 2nd Worcester District.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JDZ1/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jonathan D. Zlotnik / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Zlotnik co-sponsored the 2021 Massachusetts climate roadmap legislation (H.4264) that set binding emissions reductions targets and expanded offshore wind procurement. He has supported clean energy transition bills in the 194th General Court, indicating strong support for state-level climate action consistent with the Massachusetts Democratic caucus position.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JDZ1/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jonathan D. Zlotnik / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Zlotnik voted for the ROE Act (H.4998) in 2020, which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. This vote placed him among the pro-choice majority in the MA House.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/JDZ1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jonathan D. Zlotnik / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Zlotnik supported the Fair Share Amendment (Question 1, 2022) which added a 4% surtax on income over $1 million to fund education and transportation. As a House member representing a working-class Worcester district, he backed progressive revenue measures to fund public services while opposing tax cuts that would benefit higher-income residents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JDZ1', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jonathan D. Zlotnik / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Zlotnik co-sponsored H.2485, the Safe Communities Act, which would limit state and local law enforcement cooperation with federal immigration enforcement and protect immigrant communities from deportation. He has supported pro-immigrant legislation in the 194th General Court, reflecting a protective stance toward immigrant residents of his district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2485', 'https://malegislature.gov/Legislators/Profile/JDZ1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jonathan D. Zlotnik / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Zlotnik voted for the Police Reform Act (H.4011/S.2820, 2020) which created a statewide certification system for police officers, banned chokeholds, and limited qualified immunity in Massachusetts. This landmark reform vote demonstrates support for accountability-oriented policing reforms over traditional enforcement-first approaches.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/JDZ1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jonathan D. Zlotnik / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Zlotnik supported the VOTES Act (H.5001, 2022) which made early voting permanent and expanded mail-in voting in Massachusetts. He backed automatic voter registration and same-day voter registration initiatives in the legislature, demonstrating a strong pro-access voting rights position.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/JDZ1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jonathan D. Zlotnik / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('869ba820-3138-473c-b70d-383e67f5797d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Zlotnik has focused on economic development for rural Worcester County, co-sponsoring legislation supporting small businesses and workforce training programs in Gardner and surrounding communities. He authored H.1505 addressing economic development needs in underserved rural areas of the Commonwealth, reflecting a community-investment approach to economic policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JDZ1/Bills', 'https://malegislature.gov/Bills/194/H1505']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '869ba820-3138-473c-b70d-383e67f5797d';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '869ba820-3138-473c-b70d-383e67f5797d'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '869ba820-3138-473c-b70d-383e67f5797d'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
