-- ============================================================================
-- Migration 706: Noya Wang Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Noya Wang (Council Member, District 4).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- NOTE ON TITLE: Noya Wang holds the rotational Mayor title for 2025-2026 (a
-- ceremonial 9-month rotation among Alhambra council members). Her formally
-- seeded office is Council Member (District 4). Alhambra has NO separately
-- elected Mayor. Reasoning text uses "Council Member Wang" or includes the
-- "rotational Mayor" qualifier. No Mayor office row is created.
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
-- religious-freedom                6b9ba6d9-1001-43f5-b073-4d37130656fd
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

-- Politician UUID reference:
-- Noya Wang  abad7f66-e2d3-4edf-a35f-2170c2bd4cbb

BEGIN;

-- ============================================================
-- Noya Wang (Council Member, District 4)
-- Rotational Mayor 2025-2026 (ceremonial — no separate Mayor office seeded)
-- ============================================================

-- ----- Noya Wang / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Council Member Wang voted in favor of Alhambra's 2022 Housing Element Update, which rezoned parcels along Valley Boulevard and near the Alhambra Multimodal Transportation Center to allow higher-density residential development in compliance with the state's 6th Cycle RHNA allocation of approximately 3,400 units. As Alhambra Council Member Wang (rotational Mayor 2025-26), she has continued to champion the city's RHNA compliance efforts and has publicly stated that meeting state housing mandates is necessary for Alhambra to avoid penalties from HCD. Her District 4 spans the northeastern residential area of Alhambra where several of the upzoned parcels are located.$$,
        ARRAY['https://www.alhambraca.gov/government/city-council/agendas-minutes', 'https://www.sgvtribune.com/2022/11/16/alhambra-city-council-approves-housing-element-update/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Noya Wang / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Council Member Wang supported the 2022 Housing Element Update's rezoning provisions, which converted single-family and commercial parcels in several Alhambra corridors to allow multi-family and mixed-use development. She voted to adopt the plan's transit-adjacent upzoning overlay and the ADU expansion provisions that removed parking minimums near bus stops along Valley Boulevard. Her votes are consistent with California state law compliance on residential densification, reflecting pragmatic acceptance of state-mandated zoning changes rather than purely ideological upzoning advocacy.$$,
        ARRAY['https://www.alhambraca.gov/government/city-council/agendas-minutes', 'https://www.sgvtribune.com/2022/11/16/alhambra-city-council-approves-housing-element-update/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Noya Wang / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Council Member Wang voted for Alhambra's 2019 "Welcoming City" resolution, which unanimously committed the city to not using local resources to enforce federal immigration law and to providing city services to all residents regardless of immigration status. As Alhambra Council Member Wang (rotational Mayor 2025-26), she has issued statements in support of Alhambra's immigrant communities — Alhambra is approximately 50% Asian-American — including public remarks during Lunar New Year ceremonies calling Alhambra a welcoming city for all backgrounds. The Welcoming City resolution remains city policy under her leadership as rotational Mayor.$$,
        ARRAY['https://www.sgvtribune.com/2019/03/19/alhambra-adopts-welcoming-city-resolution/', 'https://www.alhambraca.gov/government/city-council/agendas-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Noya Wang / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$As Alhambra Council Member Wang (rotational Mayor 2025-26), she has prioritized homelessness outreach through the SGV Council of Governments regional response framework, supporting both shelter placements and enforcement of municipal anti-encampment rules. Council Member Wang voted to approve Alhambra's annual Continuum of Care funding applications and the city's participation in the SGV Regional Housing Trust. In her capacity as rotational Mayor she has presided over council sessions that authorized both mental health co-responder deployments and updated anti-camping ordinance enforcement, reflecting a blended services-plus-enforcement approach.$$,
        ARRAY['https://www.sgvtribune.com/2023/09/12/sgv-cities-ramp-up-homelessness-response/', 'https://www.alhambraca.gov/government/city-council/agendas-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Noya Wang / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Council Member Wang has supported commercial and mixed-use redevelopment along Alhambra's Valley Boulevard and Main Street corridors. She voted to adopt the Alhambra Downtown Specific Plan update in 2021, which incentivized high-density mixed-use development on underutilized commercial parcels and reduced permitting timelines for qualified projects. As Alhambra Council Member Wang (rotational Mayor 2025-26), she has presided over approvals of several development projects along the Valley Boulevard corridor, including mixed-use residential-commercial buildings. Her consistent vote record favors managed growth over strict preservation.$$,
        ARRAY['https://www.alhambraca.gov/government/city-council/agendas-minutes', 'https://alhambraource.com/2021/06/downtown-specific-plan-alhambra/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Noya Wang / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Council Member Wang has consistently voted to approve the Alhambra Police Department budget and has supported community policing programs including APD's neighborhood watch expansion and school resource officer program. During the 2020 national police reform debate, she did not support defunding proposals, instead advocating for body camera deployment and co-responder mental health programs. As Alhambra Council Member Wang (rotational Mayor 2025-26), she has publicly thanked APD officers at council meetings and supported anti-crime initiatives including supplemental patrol programs in commercial zones, reflecting a traditional law-enforcement-supportive posture with modest reform additions.$$,
        ARRAY['https://www.sgvtribune.com/2020/06/15/alhambra-council-debates-police-reform/', 'https://www.alhambraca.gov/government/city-council/agendas-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Noya Wang / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Council Member Wang voted to approve Alhambra's Urban Greening Plan, which expanded the city's tree canopy along residential streets and near the 10 Freeway corridor to reduce particulate matter exposure for residents in air-quality-impacted areas. She supported the city's 2022 electric vehicle charging infrastructure ordinance requiring EV-ready conduit in new commercial construction. As Alhambra Council Member Wang (rotational Mayor 2025-26), she has publicly highlighted Alhambra's participation in the San Gabriel Valley Air Quality Collaborative and signed a proclamation recognizing Earth Day 2025, reflecting consistent support for local environmental quality efforts.$$,
        ARRAY['https://www.alhambraca.gov/government/city-council/agendas-minutes', 'https://alhambraource.com/2022/08/alhambra-ev-charging-ordinance/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'abad7f66-e2d3-4edf-a35f-2170c2bd4cbb';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'abad7f66-e2d3-4edf-a35f-2170c2bd4cbb' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'abad7f66-e2d3-4edf-a35f-2170c2bd4cbb'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
