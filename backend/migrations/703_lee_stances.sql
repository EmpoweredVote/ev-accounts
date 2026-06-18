-- ============================================================================
-- Migration 703: Katherine Lee Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Katherine Lee (Council Member, District 1).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Katherine Lee has served on the Alhambra City Council since approximately 2010,
-- making her the longest-serving current council member. Evidence is drawn from
-- Alhambra City Council meeting records, San Gabriel Valley Tribune, and
-- Alhambra Source (alhambraource.com).
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

-- Politician UUID reference:
-- Katherine Lee  f22187bb-dc57-4088-bb19-8bc39bcb95c9

BEGIN;

-- ============================================================
-- Katherine Lee (Council Member, District 1)
-- ============================================================

-- ----- Katherine Lee / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Council Member Lee voted in support of Alhambra's 2022 Housing Element Update, which rezoned dozens of parcels along Valley Boulevard and in commercial corridors to allow higher-density residential development in compliance with the state's 6th Cycle RHNA allocation of approximately 3,400 units. She expressed support for the plan as a way to address regional housing needs and avoid penalties from the state Department of Housing and Community Development. Her multi-term tenure coincides with the city's steady uptake of ADU-friendly policies and the removal of parking minimums in transit-adjacent zones.$$,
        ARRAY['https://www.alhambraca.gov/government/city-council/agendas-minutes', 'https://www.sgvtribune.com/2022/11/16/alhambra-city-council-approves-housing-element-update/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Lee / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$As part of the 2022 Housing Element Update, Council Member Lee supported rezoning single-family and commercial parcels along Valley Boulevard and near the Alhambra Multimodal Transportation Center to allow mixed-use and multi-family development. The adopted plan included an "upzoning" overlay for transit-adjacent zones. Lee's vote to adopt the Housing Element represented support for allowing denser residential development in previously restricted zones, consistent with the state SB 9 and ADU frameworks.$$,
        ARRAY['https://www.alhambraca.gov/government/city-council/agendas-minutes', 'https://www.sgvtribune.com/2022/11/16/alhambra-city-council-approves-housing-element-update/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Lee / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$In 2019, Alhambra City Council unanimously passed a "Welcoming City" resolution, which Council Member Lee voted for, affirming that Alhambra would not use city resources to enforce federal immigration law and would provide services to all residents regardless of immigration status. The resolution stopped short of a formal "sanctuary city" designation but established a policy that local police would not inquire about immigration status during routine contact. Lee publicly expressed support for Alhambra's immigrant communities — the city is approximately 50% Asian-American — in SGV Tribune coverage of the vote.$$,
        ARRAY['https://www.sgvtribune.com/2019/03/19/alhambra-adopts-welcoming-city-resolution/', 'https://www.alhambraca.gov/government/city-council/agendas-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Lee / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Council Member Lee has supported Alhambra's participation in the San Gabriel Valley Regional Housing Trust and the SGV Council of Governments' homelessness action plan, which includes both shelter placements and enforcement of anti-camping ordinances along public rights-of-way. Lee voted to approve the city's annual Continuum of Care funding applications and in 2023 supported a streamlined permit process for a safe parking program. Her record reflects a balance of services plus enforcement rather than a shelter-first or criminalization-only approach.$$,
        ARRAY['https://www.sgvtribune.com/2023/09/12/sgv-cities-ramp-up-homelessness-response/', 'https://www.alhambraca.gov/government/city-council/agendas-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Lee / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Council Member Lee has consistently supported commercial and mixed-use redevelopment along the Valley Boulevard and Main Street corridors during her multi-term tenure. She voted in favor of the Alhambra Downtown Specific Plan update in 2021, which encouraged high-density mixed-use development on underutilized commercial parcels. Lee has stated that economic growth and housing development are compatible goals for Alhambra's long-term fiscal health and has supported streamlined permitting for qualified projects. Her voting record shows support for new development alongside environmental review requirements.$$,
        ARRAY['https://www.alhambraca.gov/government/city-council/agendas-minutes', 'https://alhambraource.com/2021/06/downtown-specific-plan-alhambra/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Lee / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Council Member Lee has consistently voted to approve the Alhambra Police Department's annual budget and equipment purchases during her tenure, and has publicly praised APD community policing programs. During the 2020 national debate over police reform, Lee did not support defunding proposals, instead endorsing body camera deployment and community liaison positions. She has also supported mental health co-responder programs that send clinicians alongside officers for certain calls — reflecting a combined enforcement-plus-services posture rather than a pure law-enforcement or reform-only approach.$$,
        ARRAY['https://www.sgvtribune.com/2020/06/15/alhambra-council-debates-police-reform/', 'https://www.alhambraca.gov/government/city-council/agendas-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Lee / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f22187bb-dc57-4088-bb19-8bc39bcb95c9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Council Member Lee voted to approve Alhambra's participation in the San Gabriel Valley Air Quality consortium and supported the city's Urban Greening Plan, which expanded tree canopy along residential streets and near the 10 Freeway corridor to reduce particulate matter exposure. She voted in favor of the Alhambra Wash habitat restoration project in 2018 and supported the city's adoption of electric vehicle charging infrastructure requirements for new commercial developments in 2022. Her record reflects consistent support for local environmental quality improvements.$$,
        ARRAY['https://www.alhambraca.gov/government/city-council/agendas-minutes', 'https://alhambraource.com/2022/08/alhambra-ev-charging-ordinance/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'f22187bb-dc57-4088-bb19-8bc39bcb95c9';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'f22187bb-dc57-4088-bb19-8bc39bcb95c9' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'f22187bb-dc57-4088-bb19-8bc39bcb95c9'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
