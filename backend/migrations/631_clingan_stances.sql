-- ============================================================================
-- Migration 631: Jesse Clingan Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jesse Clingan (City Councilor Ward 4,
--   Somerville, MA).
--
-- Background: Jesse Clingan is the Somerville Ward 4 City Councilor, first elected
--   in 2017. Ward 4 covers Winter Hill and portions of Somerville near Davis Square.
--   He has been active on housing, zoning, and community development issues and has
--   been an engaged participant in Somerville's comprehensive planning and zoning
--   debates.
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

-- ============================================================
-- Jesse Clingan
-- ============================================================

-- ----- Jesse Clingan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Clingan has been an active participant in Somerville's housing debates, backing affordable housing production initiatives and MBTA Communities Act compliance zoning. He has supported SomerVision 2040's housing production goals and spoken in favor of community land trusts and anti-displacement programs. His council participation in housing discussions reflects a consistent progressive housing position aligned with the Somerville council majority.$$,
        ARRAY['https://www.somervillema.gov/city-council/members/jesse-clingan', 'https://www.somervillema.gov/somervision']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse Clingan / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Clingan has engaged closely with Somerville's zoning reform debates, supporting upzoning for housing production in transit-served corridors. He backed SomerVision 2040 zoning changes and MBTA Communities Act compliance measures. His participation in council zoning debates has been consistently pro-density with an emphasis on pairing increased capacity with affordable unit requirements.$$,
        ARRAY['https://www.somervillema.gov/somervision', 'https://www.somervillejournal.com/2024/04/somerville-zoning-debate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse Clingan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Clingan has supported the HEART program and community-based public safety alternatives on the Somerville City Council, backing mental health crisis response and police accountability measures. He has voted with the council majority on reform-oriented public safety measures while maintaining a balanced approach that also recognizes traditional policing needs in his ward. His stance reflects support for reform with continued police capacity for serious crime response.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-heart-program', 'https://www.somervillejournal.com/2022/07/somerville-police-reform-update/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse Clingan / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Clingan has supported Somerville's sanctuary city policies and voted with the council to maintain non-cooperation with federal immigration enforcement. He backed resolutions affirming Somerville's commitment to immigrant residents following heightened federal enforcement activity in 2025, and has supported expanded immigrant services for Ward 4 residents.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration', 'https://www.somervillejournal.com/2025/02/somerville-sanctuary-reaffirmed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse Clingan / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Clingan has voted in support of Somerville's Climate Forward plan and backed local environmental initiatives including urban tree canopy and green infrastructure programs. His council voting record on environmental sustainability measures has been consistently supportive of the city's climate action agenda.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/climate-forward', 'https://www.somervillejournal.com/2023/06/somerville-climate-forward-update/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '13f3e9dc-67fc-4115-99a5-77c4647f1b3c';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '13f3e9dc-67fc-4115-99a5-77c4647f1b3c' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '13f3e9dc-67fc-4115-99a5-77c4647f1b3c'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
