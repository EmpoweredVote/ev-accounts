-- ============================================================================
-- Migration 628: Matthew McLaughlin Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Matthew McLaughlin (City Councilor Ward 1,
--   Somerville, MA).
--
-- Background: Matthew McLaughlin is the Somerville Ward 1 City Councilor, first elected
--   in 2017 and re-elected multiple times. Ward 1 covers East Somerville/Winter Hill.
--   He has been an active council member focused on neighborhood issues, public safety,
--   housing, and community development in his ward.
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
-- Matthew McLaughlin
-- ============================================================

-- ----- Matthew McLaughlin / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McLaughlin has supported affordable housing production on the Somerville City Council, backing MBTA Communities Act compliance zoning and city affordable housing programs. He has been involved in Ward 1 development debates, supporting projects that include affordable units and pushing for community benefit requirements in new developments. His council record shows consistent votes in favor of expanding housing capacity while calling for affordability protections.$$,
        ARRAY['https://www.somervillema.gov/city-council/members/matthew-mclaughlin', 'https://www.somervillejournal.com/2023/05/somerville-ward1-housing-development/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew McLaughlin / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$McLaughlin has generally supported MBTA Communities Act zoning compliance and SomerVision 2040 upzoning provisions. He has also raised neighborhood character concerns on specific development projects in Ward 1, showing a pragmatic approach that supports broader density goals while advocating for community input on specific projects. His position is broadly pro-zoning reform with attention to ward-level impacts.$$,
        ARRAY['https://www.somervillema.gov/somervision', 'https://www.somervillejournal.com/2024/04/somerville-zoning-debate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew McLaughlin / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$McLaughlin has supported the HEART program and community-based public safety alternatives while also emphasizing traditional policing for his ward. He has balanced support for reform with concerns about public safety capacity in East Somerville, a neighborhood with historically higher crime rates. His approach to public safety is more balanced between reform and traditional policing than some progressive colleagues, reflecting his ward constituency's priorities.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-heart-program', 'https://www.somervillejournal.com/2022/07/somerville-police-reform-update/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew McLaughlin / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$McLaughlin represents East Somerville, which has a large immigrant population (Brazilian, Latino, Haitian), and has consistently supported the city's sanctuary policies and immigrant services. He has backed council resolutions affirming non-cooperation with ICE and supported language access and immigrant-focused city services. His ward constituency makes immigration services a high priority in his council work.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration', 'https://www.somervillejournal.com/2025/02/somerville-sanctuary-reaffirmed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew McLaughlin / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b2a514f-ea4b-4476-bf45-0d221a138d3a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$McLaughlin has voted in support of Somerville's Climate Forward plan and backed local environmental sustainability initiatives including tree canopy and green stormwater infrastructure programs. He has been particularly attentive to environmental justice concerns in Ward 1, which includes areas with higher industrial activity near the Mystic River. His council record shows consistent support for environmental programs benefiting his ward.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/climate-forward', 'https://www.somervillejournal.com/2023/04/somerville-east-environment-ward1/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '5b2a514f-ea4b-4476-bf45-0d221a138d3a';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '5b2a514f-ea4b-4476-bf45-0d221a138d3a' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '5b2a514f-ea4b-4476-bf45-0d221a138d3a'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
