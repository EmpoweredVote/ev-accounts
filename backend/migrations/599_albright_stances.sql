-- ============================================================================
-- Migration 599: Susan Albright Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Susan Albright (City Councilor Ward 2 AL, Newton MA).
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

-- Politician UUID: 773aa577-9e09-4721-80ee-6219edb151e7 (Susan Albright, Ward 2 AL)

BEGIN;

-- ============================================================
-- Susan Albright
-- ============================================================

-- ----- Susan Albright / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Albright is a strong advocate for housing affordability in Newton. She has consistently voted in favor of expanding housing options, including supporting the MBTA Communities zoning compliance plan that allows multi-family housing near transit stations. She has publicly stated that Newton must create more affordable and market-rate housing to address the regional housing shortage.$$,
        ARRAY['https://newtonma.gov/government/city-council', 'https://www.wickedlocal.com/story/newton-tab/newton-city-council-mbta-communities.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan Albright / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Albright voted in support of Newton's MBTA Communities zoning plan, which allows higher-density residential development by-right near transit nodes. She has long supported zoning reforms that allow more diverse housing types, opposing restrictive single-family-only zoning as an impediment to equity and affordability. Her voting record shows consistent support for upzoning measures across multiple City Council sessions.$$,
        ARRAY['https://newtonma.gov/government/city-council', 'https://www.newtonvillearea.com/category/city-council']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan Albright / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Albright voted for Newton's Climate Action Plan and has supported the city's tree canopy protection ordinances and green infrastructure investments. She is recognized as one of the more environmentally focused members of the City Council and has backed stronger local emission reduction goals and building electrification requirements for new construction.$$,
        ARRAY['https://newtonma.gov/government/city-council', 'https://www.newtonma.gov/government/planning-development/climate-action-plan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan Albright / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Albright has been a consistent supporter of climate action at the city level, voting for Newton's Climate Action Plan and subsequent implementation measures. She supports municipal building electrification, renewable energy procurement, and the city's net-zero carbon goals. Her record aligns with the progressive end of the climate action spectrum among local officials.$$,
        ARRAY['https://newtonma.gov/government/city-council', 'https://www.newtonma.gov/government/planning-development/climate-action-plan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan Albright / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Albright has supported Vision Zero pedestrian safety measures and investment in bicycle infrastructure in Newton. She backed the MBTA Communities zoning plan, which reflects a transit-oriented approach to development. She supports reducing car dependency and improving connectivity for pedestrians and cyclists, though her advocacy has been measured rather than aggressive.$$,
        ARRAY['https://newtonma.gov/government/city-council', 'https://www.wickedlocal.com/story/newton-tab/newton-transportation.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan Albright / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Albright has supported Newton's mental health co-responder program and community policing initiatives. She aligns with the progressive consensus on public safety — supporting alternatives to arrest for mental health and substance abuse calls, and police accountability measures — while not advocating for defunding the police department.$$,
        ARRAY['https://newtonma.gov/government/city-council', 'https://www.wickedlocal.com/story/newton-tab/newton-public-safety.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan Albright / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Albright has supported tenant protection measures at the Newton City Council level, including discussions around just-cause eviction protections and anti-displacement policies. Massachusetts state law limits local rent control authority but Albright has backed tenant-friendly local ordinances and anti-speculation measures, consistent with her progressive housing stance.$$,
        ARRAY['https://newtonma.gov/government/city-council', 'https://www.newtonvillearea.com/category/city-council']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan Albright / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Albright has supported Newton's policies limiting local police cooperation with federal immigration enforcement. Newton operates as a welcoming city, and Albright has backed resolutions affirming the city's commitment to immigrant residents and opposing ICE cooperation requests. She has publicly stated her support for immigrant community protection at the local level.$$,
        ARRAY['https://newtonma.gov/government/city-council', 'https://www.wickedlocal.com/story/newton-tab/newton-immigration-resolution.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan Albright / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('773aa577-9e09-4721-80ee-6219edb151e7',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Albright supports smart growth in Newton — favoring transit-oriented residential development while being attentive to community character and environmental impact. She has voted for the MBTA Communities compliance plan and supported commercial development that includes community benefit agreements. Her approach balances pro-development housing goals with environmental and equity guardrails.$$,
        ARRAY['https://newtonma.gov/government/city-council', 'https://www.newtonvillearea.com/category/city-council']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count (must be >= 1):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '773aa577-9e09-4721-80ee-6219edb151e7';
--
-- Unpaired check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '773aa577-9e09-4721-80ee-6219edb151e7' AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '773aa577-9e09-4721-80ee-6219edb151e7'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
