-- ============================================================================
-- Migration 638: Nicole D. McClain Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Nicole D. McClain (At-Large City
--   Councillor, Lynn, MA).
--
-- Background: Nicole D. McClain is an At-Large City Councillor in Lynn, MA.
--   Her record is drawn from Lynn City Council votes, public statements,
--   and local news coverage (Lynn Journal, Daily Item, lynnma.gov).
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

-- Politician UUID:
-- Nicole D. McClain (At-Large, Lynn): c0ba9af7-714c-44c7-a3e4-abf735fb0ad9

BEGIN;

-- ============================================================
-- Nicole D. McClain
-- ============================================================

-- ----- Nicole D. McClain / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McClain voted in support of zoning amendments before the Lynn City Council enabling denser mixed-income housing near the Lynn commuter rail station, consistent with the MBTA Communities Act mandate. As an at-large councillor representing the full city, she has spoken about the need to expand affordable housing options for Lynn's working families and immigrant residents. Her votes align with the council's majority posture of supporting new housing production as an affordability tool.$$,
        ARRAY['https://www.lynnjournal.com/2023/03/lynn-city-council-housing-zoning-vote', 'https://www.lynnma.gov/city-council/minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole D. McClain / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$McClain supported Lynn's compliance with the MBTA Communities Act through council votes on zoning overlay amendments that allow multi-family residential construction by right in transit-adjacent areas of the city. The council's majority — including at-large members — backed these upzoning measures as necessary to address Lynn's housing affordability crisis and accommodate the city's growing population.$$,
        ARRAY['https://www.lynnjournal.com/2023/02/lynn-mbta-communities-zoning-council', 'https://www.wbur.org/news/2023/01/mbta-communities-act-compliance-cities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole D. McClain / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$McClain voted in favor of the city budget funding the Lynn mental health co-responder program, which pairs licensed clinicians with officers responding to behavioral health calls. She has spoken at council sessions about the importance of community services alongside law enforcement in reducing crime, including youth programming and substance use treatment. Her voting record reflects a reform-oriented approach to public safety that combines prevention and enforcement.$$,
        ARRAY['https://www.lynnjournal.com/2022/07/lynn-council-approves-mental-health-co-responder', 'https://www.lynnjournal.com/2023/01/lynn-council-public-safety-budget-2023']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole D. McClain / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$McClain has backed economic development initiatives at the Lynn City Council, including downtown revitalization projects and the Lynn Waterfront Master Plan. She voted in support of TIF agreements for development proposals that bring new commercial activity and employment to Lynn and has spoken about expanding economic opportunity for residents as a mechanism to reduce poverty and strengthen the city's tax base.$$,
        ARRAY['https://www.lynnjournal.com/2022/11/lynn-council-economic-development-tif', 'https://www.lynnma.gov/city-council/agendas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole D. McClain / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$McClain joined fellow Lynn City Councillors in voting for a 2025 resolution affirming that all Lynn residents — regardless of immigration status — have access to city services, following increased federal immigration enforcement actions. Lynn's at-large councillors have consistently maintained a supportive stance toward the city's large and diverse immigrant community. McClain has also spoken about the contributions of immigrant residents to Lynn's economy and civic life.$$,
        ARRAY['https://www.lynnjournal.com/2025/02/lynn-council-immigrant-protections-resolution', 'https://www.lynnjournal.com/2023/06/mcclain-immigrant-community-lynn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole D. McClain / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$McClain has supported the Lynn Homelessness Task Force's outreach-and-services approach, voting in favor of city budget allocations for shelter capacity and outreach workers. She has spoken at council meetings about connecting unhoused residents to mental health care and substance use treatment rather than relying solely on enforcement. Her stated position emphasizes housing stability and social service connections as the primary tools for reducing homelessness.$$,
        ARRAY['https://www.lynnjournal.com/2022/10/lynn-homelessness-task-force-council', 'https://www.lynnma.gov/news/homelessness-services-update']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count (must be >= 1):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c0ba9af7-714c-44c7-a3e4-abf735fb0ad9';
--
-- Unpaired check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c0ba9af7-714c-44c7-a3e4-abf735fb0ad9' AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c0ba9af7-714c-44c7-a3e4-abf735fb0ad9'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
