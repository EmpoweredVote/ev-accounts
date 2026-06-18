-- ============================================================================
-- Migration 630: Ben Ewen-Campen Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Ben Ewen-Campen (City Councilor Ward 3,
--   Somerville, MA).
--
-- Background: Ben Ewen-Campen is the Somerville Ward 3 City Councilor, first elected
--   in 2017. Ward 3 covers Prospect Hill, Spring Hill, and parts of the Tufts area.
--   He is one of the most outspoken and policy-active members of the council, having
--   authored numerous resolutions on housing, climate, police accountability, and
--   immigration. He has a PhD in developmental biology and is known for evidence-based
--   policymaking. He is a co-founder of the Somerville Residents Action Coalition.
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
-- Ben Ewen-Campen
-- ============================================================

-- ----- Ben Ewen-Campen / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ewen-Campen has been one of the most vocal pro-housing voices on the Somerville City Council. He authored or co-authored multiple council resolutions advocating for accelerated affordable housing production and anti-displacement programs. He supported Somerville's MBTA Communities Act compliance, backed community land trusts, and championed inclusionary zoning requirements for new development. He has been particularly focused on the interaction between housing production and tenant protection as complementary rather than competing goals.$$,
        ARRAY['https://www.somervillejournal.com/2021/04/ewen-campen-housing-resolution/', 'https://www.somervillema.gov/city-council/members/ben-ewen-campen']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Ewen-Campen has strongly backed upzoning for housing production in Somerville, including MBTA Communities Act compliance zoning and SomerVision 2040's density increases. He authored a widely-shared council resolution calling for aggressive upzoning near transit corridors as a response to the housing crisis, and has been a consistent opponent of exclusionary single-family zoning. His stance is pro-density with a strong affordability mandate attached to new development.$$,
        ARRAY['https://www.somervillejournal.com/2022/07/ewen-campen-zoning-resolution/', 'https://www.somervillema.gov/somervision']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Ewen-Campen has been the leading council proponent of rent stabilization in Somerville over multiple terms. He championed the city's home rule petition for local rent stabilization authority and authored council resolutions calling on the state to lift the ban on rent control. He has argued that rent regulation and housing production must work together to prevent displacement of existing residents while adding new units. He has spoken at state hearings in support of rent control legislation.$$,
        ARRAY['https://www.somervillejournal.com/2022/03/somerville-rent-stabilization-petition/', 'https://www.somervillejournal.com/2024/05/somerville-rent-stabilization-debate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ewen-Campen has been one of the most active climate advocates on the Somerville City Council, co-authoring multiple resolutions on climate action, clean energy procurement, and building decarbonization. He authored a climate emergency resolution in Somerville and pushed for the city's participation in the MA Green New Deal for Cities program. His PhD in biology informs his evidence-based approach to climate policy, and he has been a strong voice for aggressive municipal climate action.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/climate-forward', 'https://www.somervillejournal.com/2020/12/ewen-campen-climate-emergency-resolution/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Ewen-Campen has championed local environmental programs including Somerville's urban tree canopy expansion, composting infrastructure, green stormwater management, and environmental justice initiatives. He authored resolutions connecting environmental quality to racial equity, noting that lower-income neighborhoods in Somerville have fewer trees and more heat-island effects. He has been a persistent advocate for embedding environmental considerations into all city planning decisions.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/climate-forward', 'https://www.somervillejournal.com/2021/08/ewen-campen-environmental-justice/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ewen-Campen has backed Somerville's efforts to move away from fossil fuel infrastructure, supporting all-electric building requirements for new city construction and opposing new gas infrastructure. He championed a resolution supporting Somerville participation in MA's net-zero emissions targets and backed the city's pilot programs for electric municipal vehicles. His climate emergency resolution called for rapid decarbonization across all sectors.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/climate-forward', 'https://www.somervillejournal.com/2020/12/ewen-campen-climate-emergency-resolution/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Ewen-Campen co-authored the resolution creating Somerville's HEART (Holistic Emergency Alternative Response Team) civilian crisis response program and has been its strongest champion on the council. He backed expanded police accountability measures, civilian oversight, and reforms to use-of-force policies. He framed the 2020 police reform debate in terms of structural reallocation toward community investment and was one of the most outspoken council members for reducing police budgets and expanding alternative services.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-heart-program', 'https://www.somervillejournal.com/2021/03/somerville-heart-program-launched/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Ewen-Campen has co-authored and championed resolutions strengthening Somerville's sanctuary policies and immigrant protections. He supported the city's non-cooperation with ICE detainers and backed expansion of immigrant services including language access programs. He has publicly spoken at immigrant rights events and written op-eds defending Somerville's sanctuary status, framing it as both a moral and community safety issue.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration', 'https://www.somervillejournal.com/2021/10/mbah-sanctuary-icu-resolution/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Ewen-Campen has explicitly opposed deportation operations and supported Somerville's policy of not facilitating federal immigration enforcement. He has spoken at rallies opposing ICE enforcement actions and backed council resolutions committing the city to protecting all residents from deportation-related disruption. He has written about the harm of family separation caused by deportation policies and consistently backed sanctuary city protections.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration', 'https://www.somervillejournal.com/2025/01/somerville-anti-deportation-response/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Ewen-Campen has been a leading voice for transit-first and active transportation in Somerville, authoring resolutions calling for protected bike lane expansion, reduced parking minimums, and enhanced MBTA service. He linked transportation policy to climate goals and supported eliminating parking minimums citywide as a way to encourage transit use. He backed Vision Zero traffic safety measures and championed Complete Streets implementation throughout his ward and city-wide.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/somerville-by-design', 'https://www.somervillejournal.com/2022/08/ewen-campen-bike-lane-resolution/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ewen-Campen has authored and co-authored multiple civil rights resolutions on the Somerville City Council, including resolutions on racial equity, LGBTQ+ inclusion, and anti-discrimination enforcement. He championed the 2020 racial justice resolution calling for audits of city department equity practices and supported Somerville's comprehensive anti-discrimination ordinance. He has been a vocal proponent of intersectional civil rights policies and progressive governance.$$,
        ARRAY['https://www.somervillejournal.com/2020/06/somerville-racial-justice-resolution/', 'https://www.somervillema.gov/city-council/members/ben-ewen-campen']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Ewen-Campen / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('073a3e12-55bb-4c88-9bd9-3333b93f40cd',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Ewen-Campen has strongly backed Housing First approaches to homelessness and opposed criminalization of unhoused residents. He backed HEART program expansion to handle mental health crises — many of which involve homelessness — without police response. He has spoken against sweeping encampments without providing alternative shelter options and has framed homelessness as a direct consequence of housing affordability failures requiring structural solutions.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-homeless-coalition', 'https://www.somervillejournal.com/2023/09/somerville-homelessness-housing-first/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '073a3e12-55bb-4c88-9bd9-3333b93f40cd';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '073a3e12-55bb-4c88-9bd9-3333b93f40cd' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '073a3e12-55bb-4c88-9bd9-3333b93f40cd'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
