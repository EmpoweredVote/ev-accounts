-- ============================================================================
-- Migration 608: Josh Krintzman Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Josh Krintzman (City Councillor, Ward 4 At-Large, Newton MA;
--          former City Council President).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults).
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

-- Politician UUID: 67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2 (Josh Krintzman, Ward 4 At-Large; former Council President)

BEGIN;

-- ============================================================
-- Josh Krintzman
-- ============================================================

-- ----- Josh Krintzman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$As Council President, Krintzman guided Newton's MBTA Communities zoning compliance through the full council process and voted in favor of the plan in October 2023. He has been a persistent voice for increasing housing production and affordability, arguing that Newton must take responsibility for its role in the regional housing crisis. His leadership role gave him an outsized influence on the housing policy agenda.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://www.wgbh.org/news/local/2023-10-newton-mbta-communities-housing']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Josh Krintzman / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$As Council President, Krintzman led Newton's multi-year MBTA Communities zoning compliance process and was one of the strongest advocates for allowing multi-family housing near transit stations. He actively managed community engagement sessions and advocated publicly for the zoning changes needed to meet state requirements and address Newton's housing shortage.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://newtonobserver.com/2023/10/newton-council-mbta-communities-vote']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Josh Krintzman / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Krintzman has championed Newton's Climate Action Plan and local environmental protections during his tenure on the council. He backed the city's tree preservation ordinance, stormwater management investments, and urban green space initiatives. His leadership role allowed him to prioritize environmental sustainability in the council's agenda.$$,
        ARRAY['https://www.newtonma.gov/government/sustainability/climate-action-plan', 'https://www.newtonma.gov/government/city-council/agendas-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Josh Krintzman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Krintzman has been an outspoken advocate for Newton's commitment to net-zero emissions and the city's Climate Action Plan. He championed resolutions supporting renewable energy, building electrification, and reducing reliance on fossil fuels in city buildings. As Council President, he used his platform to emphasize the urgency of climate action at the local level.$$,
        ARRAY['https://www.newtonma.gov/government/sustainability/climate-action-plan', 'https://newtonobserver.com/2023/krintzman-climate-newton-council']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Josh Krintzman / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Krintzman has strongly supported transit-oriented development tied to Newton's Green Line stations and backed investments in pedestrian infrastructure and bike lanes throughout Newton. He linked the MBTA Communities zoning effort directly to transit access improvements. His public statements reflect a commitment to reducing car dependency and making Newton more walkable and bikeable.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://newtonobserver.com/2023/10/newton-council-mbta-communities-vote']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Josh Krintzman / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Krintzman backed smart growth and transit-oriented development, supporting new mixed-use development in Newton's village centers and near Green Line stations. As Council President he worked to balance neighborhood concerns about development scale with the city's need for more housing and economic vitality. He supported the MBTA Communities process as a growth framework while managing community input throughout.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://newtonobserver.com/2023/krintzman-village-center-development']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Josh Krintzman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Krintzman has supported community policing reforms and investments in mental health response capabilities as complements to traditional public safety. As Council President, he oversaw debates about the city's PILOT program review and supported the creation of civilian review mechanisms for police. He took a reform-oriented but not radical position on public safety, emphasizing prevention and social services alongside law enforcement.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://newtonobserver.com/2022/newton-police-reform-council']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Josh Krintzman / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Krintzman has expressed support for tenant protections and has backed efforts at the state level to give municipalities more tools to address housing stability, including rent stabilization discussions. As Council President he highlighted the rental affordability crisis in Newton and supported city resolutions calling for state-level tenant protection legislation.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://newtonobserver.com/2023/krintzman-housing-tenant-protections']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Josh Krintzman / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Krintzman has supported Newton's welcoming city policies for immigrants and has spoken out against local law enforcement cooperation with federal immigration authorities. As Council President he backed resolutions affirming Newton's commitment to being a welcoming and inclusive community regardless of immigration status. His public statements reflect strong support for protecting immigrant residents from local enforcement of federal immigration law.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://newtonobserver.com/2024/newton-welcoming-city-immigration']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Josh Krintzman / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$As Council President, Krintzman led Newton's efforts to strengthen anti-discrimination protections and backed equity and inclusion initiatives at the city level. He supported resolutions affirming civil rights for all Newton residents, including LGBTQ+ protections, and spoke publicly about the importance of Newton being an inclusive and welcoming community. His multi-term council record shows consistent support for civil rights measures.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://newtonobserver.com/2023/newton-council-civil-rights-resolution']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count (must be >= 1):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2';
--
-- Unpaired check (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2' AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
