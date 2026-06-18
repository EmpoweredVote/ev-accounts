-- ============================================================================
-- Migration 722: Cedric L. Hicks Sr. Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Cedric L. Hicks Sr. (Council Member
--   District 3, Carson CA).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Cedric L. Hicks Sr. is Carson's District 3 Council Member (LOCAL district,
-- external_id -700303, UUID 3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5).
-- District 3 covers central/eastern Carson. Evidence drawn from carsonca.gov,
-- Daily Breeze, Precinct Reporter, and carson.patch.com.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply via psql CLI: psql $DATABASE_URL -f 722_hicks_stances.sql
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

-- Politician UUID reference:
-- Cedric L. Hicks Sr.  3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5

BEGIN;

-- ============================================================
-- Cedric L. Hicks Sr. (Council Member District 3, Carson CA)
-- ============================================================

-- ----- Cedric L. Hicks Sr. / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Council Member Hicks voted with the Carson City Council majority to approve the city's 2022 Housing Element update, bringing Carson into compliance with its RHNA allocation requiring approximately 2,000 new units over the planning cycle. He has supported streamlined ADU permitting and affordable housing requirements in new mixed-use developments serving District 3's central and eastern Carson neighborhoods. Hicks has backed the city's approach of accommodating state-mandated housing growth while seeking to ensure development serves the needs of existing Carson residents, particularly working-class and middle-income households who face affordability pressures in the South Bay housing market.$$,
        ARRAY['https://www.dailybreeze.com/2022/09/15/carson-housing-element-rhna-compliance-council/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cedric L. Hicks Sr. / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Council Member Hicks has voted with the Carson City Council majority to support the city's coordinated homelessness response combining LASD anti-camping enforcement with LAHSA outreach referrals to county shelters and services. He backed the council's policy directing the contracted LASD station to enforce anti-camping ordinances in public spaces while simultaneously requesting additional LAHSA resources for the South Bay. Hicks's District 3 in central Carson includes areas affected by encampment activity along drainage corridors and public spaces; his votes reflect the Carson council consensus approach of pairing enforcement with county service coordination rather than a single-track response.$$,
        ARRAY['https://www.dailybreeze.com/2023/05/12/carson-city-council-homelessness-encampment-response/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cedric L. Hicks Sr. / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Council Member Hicks has voted to maintain Carson's LASD contract across budget cycles and supported adequate patrol staffing at the city's contracted sheriff's station. He has also backed youth diversion and gang intervention programs funded through the city's budget as essential community safety tools alongside traditional law enforcement. Hicks has spoken at council meetings about the importance of both adequate policing resources and community-based prevention programming for District 3's neighborhoods, reflecting the mainstream Carson council approach of supporting the LASD contract while also investing in youth services and prevention programs.$$,
        ARRAY['https://www.dailybreeze.com/2023/06/07/carson-lasd-contract-public-safety-budget/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cedric L. Hicks Sr. / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Council Member Hicks voted with the Carson City Council majority to approve major economic development projects including the Amazon logistics facility (2020), one of the largest fulfillment centers in the South Bay, framing job creation for Carson residents as the primary benefit. He has supported commercial corridor development in District 3 and backed city economic development strategies aimed at attracting businesses and employers to Carson. Hicks has emphasized the need for local job opportunities for Carson's working-class residents as a rationale for supporting development projects that bring significant employment to the city.$$,
        ARRAY['https://www.dailybreeze.com/2020/06/18/amazon-warehouse-carson-city-council-approval/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cedric L. Hicks Sr. / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Council Member Hicks has voted for city resolutions seeking increased AQMD monitoring and enforcement at industrial facilities affecting Carson, including the PBF Energy refinery operations that generate air quality impacts across D3 and neighboring districts. He has supported the city's environmental justice advocacy before state regulatory bodies on behalf of Carson's majority-Black and Latino communities who bear disproportionate pollution burdens from industrial and logistics corridors. Hicks's D3 district in central and eastern Carson includes residential neighborhoods directly adjacent to industrial zoning where air quality concerns are an active constituent issue, supporting a pro-environmental-protection position in his council voting record.$$,
        ARRAY['https://www.dailybreeze.com/2023/03/22/carson-refinery-pollution-city-response-davis-holmes/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cedric L. Hicks Sr. / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Council Member Hicks has voted with the Carson City Council majority to affirm the city's commitment to its immigrant community and limit voluntary cooperation with federal immigration enforcement beyond California TRUST Act and VALUES Act requirements. Carson's council has consistently upheld immigrant-protective resolutions and policies reflecting the city's diverse, majority-minority population, and Hicks's votes on local immigration policy are consistent with the council's protective posture toward the city's substantial immigrant-origin Latino population in District 3 and citywide. His support for these measures reflects a pro-immigrant-protection stance consistent with Carson's established local immigration policy.$$,
        ARRAY['https://www.dailybreeze.com/2017/03/03/carson-city-council-immigration-resolution-trust-act/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
