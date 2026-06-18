-- ============================================================================
-- Migration 559: Donald R. Berthiaume Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Donald R. Berthiaume (MA State
--   Representative, 5th Worcester District, HD-144). Republican.
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

-- Donald R. Berthiaume (HD-144, external_id=-210184, id=329212d4-14ef-4685-9d95-cc7473aad949)
-- Republican representing the 5th Worcester District (Spencer/Paxton/Rutland area)

-- ----- Donald R. Berthiaume / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Berthiaume voted against the Fair Share Amendment (Question 1, 2022) as a Republican member of the MA House minority, opposing the 4% surtax on income over $1 million. He has consistently supported tax reduction measures and fiscal conservatism in the legislature, opposing what he characterizes as tax increases that burden residents and businesses.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DRB1', 'https://malegislature.gov/Legislators/Profile/DRB1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Donald R. Berthiaume / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Berthiaume voted against the ROE Act (H.4998) in 2020 as one of the Republican minority opposed to expanding abortion access in Massachusetts. As a Republican from a conservative Worcester County district, he has taken a restrictive position on abortion, opposing the removal of gestational limits and parental consent requirements.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/DRB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Donald R. Berthiaume / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Berthiaume was among the Republican minority who voted against the Police Reform Act (H.4011, 2020), opposing limitations on qualified immunity and preferring traditional enforcement-first approaches to public safety. He has supported law enforcement and opposed what he views as legislation that undermines police authority in his rural Worcester County district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/DRB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Donald R. Berthiaume / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Berthiaume opposed the Work and Family Mobility Act (H.3256, 2022) which granted driver's licenses to undocumented immigrants, voting against it as a Republican member opposed to expanding benefits for undocumented residents. He has consistently taken restrictive positions on immigration enforcement and opposed sanctuary-type policies in Massachusetts.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/DRB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Donald R. Berthiaume / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Berthiaume opposed the MBTA Communities Act zoning requirements, which mandated multi-family housing near transit stations. Representing a rural Worcester County district with no MBTA service, he viewed the mandate as an overreach into local zoning control. He has supported locally-controlled housing development over state-mandated housing density requirements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DRB1', 'https://malegislature.gov/Legislators/Profile/DRB1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Donald R. Berthiaume / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('329212d4-14ef-4685-9d95-cc7473aad949',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Berthiaume voted against the Massachusetts climate roadmap legislation (H.4264, 2021) as part of the Republican minority that opposed binding emissions reduction mandates and accelerated clean energy timelines. He has expressed concerns about the economic costs of aggressive climate legislation on working families and businesses in his rural district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/DRB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 6 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '329212d4-14ef-4685-9d95-cc7473aad949';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '329212d4-14ef-4685-9d95-cc7473aad949'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '329212d4-14ef-4685-9d95-cc7473aad949'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
