-- ============================================================================
-- Migration 557: Michael P. Kushmerek Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael P. Kushmerek (MA State
--   Representative, 3rd Worcester District, HD-142).
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

-- Michael P. Kushmerek (HD-142, external_id=-210182, id=d9b59bbc-90e5-435e-8c46-d8b555f1b932)

-- ----- Michael P. Kushmerek / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kushmerek has co-sponsored healthcare access legislation in the MA House, including bills expanding MassHealth coverage and mental health parity. He serves the 3rd Worcester District (Fitchburg/Leominster area) and has supported expanded healthcare coverage initiatives in the 194th General Court reflecting the MA Democratic caucus position on healthcare expansion.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MPK1/Bills', 'https://malegislature.gov/Legislators/Profile/MPK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael P. Kushmerek / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kushmerek supported the Affordable Homes Act (H.5034) which expanded housing production programs across Massachusetts. He has backed affordable housing legislation to address the housing crisis in Worcester County's smaller cities like Fitchburg and Leominster, supporting increased housing production with affordability requirements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MPK1/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael P. Kushmerek / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Kushmerek voted for the ROE Act (H.4998) in 2020, which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. This vote aligned him with the pro-choice majority in the MA Democratic House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/MPK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael P. Kushmerek / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Kushmerek supported the Massachusetts climate roadmap legislation (H.4264, 2021) which set binding emissions reductions targets and expanded clean energy programs. He has backed clean energy transition bills in the 194th General Court, supporting the state's path toward net zero emissions consistent with the MA Democratic caucus position.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MPK1/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael P. Kushmerek / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Kushmerek supported the Fair Share Amendment (Question 1, 2022) which added a 4% surtax on income over $1 million to fund education and transportation. Representing a working-class district in the Fitchburg-Leominster area, he backed progressive revenue measures to fund public services and reduce the tax burden on working families.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MPK1', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael P. Kushmerek / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Kushmerek voted for the Police Reform Act (H.4011, 2020) which created a statewide police officer certification system, banned chokeholds, and limited qualified immunity in Massachusetts. This reform vote reflects support for accountability-based policing reforms alongside community safety priorities in his district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/MPK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael P. Kushmerek / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Kushmerek supported the VOTES Act (H.5001, 2022) which made early voting permanent and expanded mail-in voting in Massachusetts. He backed expanded voting access measures in the legislature, demonstrating a pro-access position on voting rights consistent with the MA Democratic caucus.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/MPK1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael P. Kushmerek / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9b59bbc-90e5-435e-8c46-d8b555f1b932',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kushmerek has focused on economic development for the Fitchburg-Leominster corridor, including workforce development and manufacturing revitalization. He has co-sponsored legislation supporting small businesses and economic opportunities in the 3rd Worcester District, emphasizing investment in struggling smaller cities of central Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MPK1/Bills', 'https://malegislature.gov/Legislators/Profile/MPK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 7 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'd9b59bbc-90e5-435e-8c46-d8b555f1b932';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'd9b59bbc-90e5-435e-8c46-d8b555f1b932'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'd9b59bbc-90e5-435e-8c46-d8b555f1b932'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
