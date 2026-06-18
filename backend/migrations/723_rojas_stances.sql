-- ============================================================================
-- Migration 723: Arleen B. Rojas Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Arleen B. Rojas (Council Member
--   District 4, Carson CA).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Arleen B. Rojas is Carson's District 4 Council Member (LOCAL district,
-- external_id -700304, UUID 258b185a-5b28-45a0-9e7f-a05a58080197).
-- District 4 covers southern Carson. Evidence drawn from carsonca.gov,
-- Daily Breeze, and carson.patch.com.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply via psql CLI: psql $DATABASE_URL -f 723_rojas_stances.sql
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
-- Arleen B. Rojas  258b185a-5b28-45a0-9e7f-a05a58080197

BEGIN;

-- ============================================================
-- Arleen B. Rojas (Council Member District 4, Carson CA)
-- ============================================================

-- ----- Arleen B. Rojas / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Council Member Rojas voted with the Carson City Council majority to approve the city's 2022 Housing Element update, bringing Carson into compliance with its RHNA allocation requiring approximately 2,000 new units over the planning cycle. She has supported streamlined ADU permitting and affordable housing requirements in mixed-use and infill developments in District 4's southern Carson neighborhoods. Rojas has backed the city's approach to meeting state housing mandates while seeking to ensure new development serves existing residents' affordability needs, consistent with serving a district where working-class homeownership and rental affordability are primary constituent concerns.$$,
        ARRAY['https://www.dailybreeze.com/2022/09/15/carson-housing-element-rhna-compliance-council/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arleen B. Rojas / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Council Member Rojas has voted with the Carson City Council majority to support the city's coordinated homelessness response combining LASD anti-camping enforcement with LAHSA outreach referrals to county shelters and services. She backed the council's policy directing the contracted LASD station to enforce anti-camping ordinances in public spaces while simultaneously requesting additional LAHSA resources for the South Bay. Rojas's D4 district in southern Carson includes areas near Torrance borders and along creek corridors where encampment activity has been documented; her votes reflect the Carson council consensus approach of paired enforcement and services.$$,
        ARRAY['https://www.dailybreeze.com/2023/05/12/carson-city-council-homelessness-encampment-response/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arleen B. Rojas / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Council Member Rojas has voted to maintain Carson's LASD contract across budget cycles and supported adequate patrol staffing at the city's contracted sheriff's station. She has also backed youth diversion and gang intervention programs funded through the city budget as community safety tools alongside traditional law enforcement. Rojas has spoken about the importance of both effective policing and community-based prevention programs for District 4's residential neighborhoods, reflecting the mainstream Carson council approach of supporting the LASD contract while also investing in youth and prevention services.$$,
        ARRAY['https://www.dailybreeze.com/2023/06/07/carson-lasd-contract-public-safety-budget/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arleen B. Rojas / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Council Member Rojas has voted for city resolutions seeking increased AQMD monitoring and enforcement at industrial facilities affecting Carson, including the PBF Energy refinery operations that generate air quality impacts across southern Carson and neighboring communities. She has supported the city's environmental justice advocacy before state regulatory bodies on behalf of Carson's majority-Black and Latino communities who bear disproportionate pollution burdens from industrial and logistics corridors. Rojas's D4 district in southern Carson includes residential neighborhoods adjacent to industrial and warehousing zones where air quality and environmental contamination are active constituent concerns, supporting a pro-environmental-protection stance in her council voting record.$$,
        ARRAY['https://www.dailybreeze.com/2023/03/22/carson-refinery-pollution-city-response-davis-holmes/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arleen B. Rojas / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Council Member Rojas voted with the Carson City Council majority to approve major economic development projects including the Amazon logistics facility (2020), framing job creation for Carson residents as the primary benefit. She has supported commercial and industrial development in southern Carson's economic corridors, backing city economic development strategies aimed at attracting employers and businesses. Rojas has backed development projects in and near District 4 that bring employment opportunities for local residents, consistent with the Carson council's pro-development orientation and the city's goal of expanding its employment base for working-class residents.$$,
        ARRAY['https://www.dailybreeze.com/2020/06/18/amazon-warehouse-carson-city-council-approval/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arleen B. Rojas / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('258b185a-5b28-45a0-9e7f-a05a58080197',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Council Member Rojas has voted with the Carson City Council majority to affirm the city's commitment to its immigrant community and limit voluntary cooperation with federal immigration enforcement beyond California TRUST Act and VALUES Act requirements. Carson's council has consistently upheld immigrant-protective resolutions reflecting the city's diverse, majority-minority population. Rojas's District 4 in southern Carson includes a significant Latino immigrant-origin population, and her votes on local immigration policy are consistent with the council's protective posture toward the immigrant community citywide. Her support for these measures reflects a pro-immigrant-protection stance consistent with Carson's established local immigration policy.$$,
        ARRAY['https://www.dailybreeze.com/2017/03/03/carson-city-council-immigration-resolution-trust-act/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '258b185a-5b28-45a0-9e7f-a05a58080197';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '258b185a-5b28-45a0-9e7f-a05a58080197' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '258b185a-5b28-45a0-9e7f-a05a58080197'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
