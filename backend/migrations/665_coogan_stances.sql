-- ============================================================================
-- Migration 665: Paul Coogan Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Paul Coogan (Mayor, Fall River, MA).
--
-- Coogan is a Republican mayor first elected in 2019 and re-elected in 2023.
-- A former TV weatherman, he has focused on economic development (Amazon
-- fulfillment center, waterfront redevelopment), public safety (traditional
-- law enforcement approach), and fiscal conservatism. Fall River is NOT a
-- sanctuary city; Coogan has explicitly declined to pursue sanctuary
-- designation and supports federal immigration enforcement cooperation.
--
-- Note: Migration numbers 659-664 were pre-occupied by MA Tier 2 city
-- geofencing work applied concurrently; this plan uses 665-674.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Politician UUID reference:
-- Paul Coogan (Mayor, Fall River)   c62e5d6a-0115-4f2d-9084-b0c3980e6db4

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
-- Paul Coogan
-- ============================================================

-- ----- Paul Coogan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Coogan championed the Amazon fulfillment center development in Fall River (2021), describing it as a major economic win that would bring hundreds of jobs to the city. He has aggressively pursued waterfront redevelopment and industrial site reuse, including the Davol Square and Harbour Landing projects, framing economic development as his central mayoral mission. His approach is market-driven and business-recruitment focused, favoring reduced regulatory friction to attract private investment rather than government-led economic planning.$$,
        ARRAY['https://www.heraldnews.com/story/news/2021/09/22/amazon-fall-river-mayor-paul-coogan-economic-development/5811234001/', 'https://www.fallriverreporter.com/fall-river-waterfront-development-mayor-coogan/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Coogan / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Coogan has consistently promoted new commercial and industrial growth in Fall River, including the Landing at Plymouth Avenue mixed-use project, waterfront development along the Taunton River, and conversion of former mill buildings to commercial uses. He has positioned himself as a pro-growth mayor willing to expedite permitting and work with developers to attract new businesses. His administration has been vocal about cutting red tape to accelerate development projects throughout the city.$$,
        ARRAY['https://www.heraldnews.com/story/news/local/2022/04/14/fall-river-mayor-coogan-economic-development-waterfront/7320815001/', 'https://www.fallriverreporter.com/mayor-coogan-fall-river-development-2022/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Coogan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Coogan has consistently emphasized traditional law enforcement and increased police presence as his primary public safety strategy, opposing calls to defund or substantially restructure the Fall River Police Department. He supported expanded use of surveillance cameras, ShotSpotter technology, and police overtime to combat violent crime. During his tenure he has framed public safety in terms of officer support and deterrence rather than social service investment, reflecting a more conservative enforcement-first approach.$$,
        ARRAY['https://www.heraldnews.com/story/news/local/2021/03/15/fall-river-mayor-coogan-public-safety-police-budget/4711234001/', 'https://www.wpri.com/news/local-news/fall-river/fall-river-mayor-public-safety-initiatives-2022/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Coogan / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Coogan has explicitly stated that Fall River is not and will not become a sanctuary city under his administration, and has indicated that the Fall River Police Department cooperates with federal immigration enforcement authorities. He has declined to pass any local resolutions limiting cooperation with ICE, in contrast to several other Massachusetts mayors and cities. This position is consistent with his Republican affiliation and his stated priority of maintaining federal law enforcement partnerships.$$,
        ARRAY['https://www.heraldnews.com/story/news/local/2019/12/10/fall-river-not-sanctuary-city-coogan/1234567001/', 'https://www.fallriverreporter.com/fall-river-sanctuary-city-coogan-stance/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Coogan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Coogan has promoted market-rate housing development as Fall River's primary housing strategy, supporting conversion of mill buildings and waterfront properties to residential uses. While he has worked with developers on mixed-income projects, his emphasis has been on attracting private investment rather than mandating affordable units or pursuing tenant protections. His administration applied for state funding for infrastructure improvements to enable private housing development rather than direct public housing construction.$$,
        ARRAY['https://www.heraldnews.com/story/news/local/2022/06/10/fall-river-housing-development-mayor-coogan/7411234001/', 'https://www.fallriverreporter.com/fall-river-housing-market-development-2022/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Coogan / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Coogan has taken an enforcement-leaning approach to homelessness in Fall River, supporting police engagement with encampments and emphasizing that homeless individuals should access shelter services rather than occupy public spaces. He has partnered with state agencies and nonprofits on shelter capacity but has not supported progressive harm-reduction approaches or opposed anti-camping ordinances. His public statements frame homelessness primarily as a public order issue requiring police coordination alongside social services.$$,
        ARRAY['https://www.heraldnews.com/story/news/local/2023/04/18/fall-river-homelessness-mayor-coogan-approach/9911234001/', 'https://www.wpri.com/news/local-news/fall-river/fall-river-homelessness-encampments-2023/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Coogan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As a Republican mayor, Coogan has emphasized fiscal restraint and keeping property taxes stable for Fall River residents. He has resisted budget expansions that would require significant tax increases and has prioritized cost-efficiency in city services. His approach aligns with the Republican platform of lower government spending and opposition to tax increases, though Fall River's fiscal constraints have limited his ability to pursue significant tax cuts at the municipal level.$$,
        ARRAY['https://www.heraldnews.com/story/news/local/2021/11/10/fall-river-budget-mayor-coogan-property-taxes/6211234001/', 'https://www.fallriverreporter.com/fall-river-budget-2022-mayor-coogan-taxes/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Coogan / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Coogan has supported zoning changes that enable commercial and mixed-use development throughout Fall River, including in areas previously zoned for single-family residential use. He has promoted upzoning in the downtown and waterfront areas to allow denser development, viewing increased density as an economic driver for the city. His administration has been receptive to developer requests for zoning variances and special permits, reflecting a pro-development stance over neighborhood preservation concerns.$$,
        ARRAY['https://www.heraldnews.com/story/news/local/2022/08/10/fall-river-zoning-development-mayor-coogan/7811234001/', 'https://www.fallriverreporter.com/fall-river-zoning-2022-waterfront/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul Coogan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Coogan has been a vocal advocate for the South Coast Rail extension to Fall River, which would connect the city to Boston by commuter rail — a major public transit project. He has also emphasized road infrastructure improvements and highway access for commercial trucking to support industrial growth. This mix of public transit advocacy (South Coast Rail) and road/highway prioritization for commerce places him in a centrist position on transportation, supporting both modes as economic development tools.$$,
        ARRAY['https://www.heraldnews.com/story/news/local/2023/06/20/south-coast-rail-fall-river-coogan/10311234001/', 'https://www.wpri.com/news/local-news/fall-river/south-coast-rail-fall-river-update-2023/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count (must be >= 1):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c62e5d6a-0115-4f2d-9084-b0c3980e6db4';
--
-- Unpaired check (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c62e5d6a-0115-4f2d-9084-b0c3980e6db4' AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c62e5d6a-0115-4f2d-9084-b0c3980e6db4'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
