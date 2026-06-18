-- ============================================================================
-- Migration 719: Lula Davis-Holmes Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Lula Davis-Holmes (Mayor, Carson CA).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Lula Davis-Holmes is Carson's directly elected Mayor (LOCAL_EXEC office,
-- external_id -700300, UUID 94de05c6-d1bc-4cd5-ae9a-7c292ec8149e).
-- She is NOT a rotational council-selected Mayor — she holds a distinct elected
-- Mayor seat. Evidence drawn from carsonca.gov, Daily Breeze, Precinct Reporter,
-- LA Times South Bay, carson.patch.com, and ballotpedia.org.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply via psql CLI: psql $DATABASE_URL -f 719_davis_holmes_stances.sql
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
-- Lula Davis-Holmes  94de05c6-d1bc-4cd5-ae9a-7c292ec8149e

BEGIN;

-- ============================================================
-- Lula Davis-Holmes (Mayor, Carson CA)
-- ============================================================

-- ----- Lula Davis-Holmes / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Mayor Davis-Holmes has supported a dual-track approach to homelessness in Carson combining encampment clearances under Los Angeles County Homeless Initiative protocols with coordinated referrals to county shelter and services. She has publicly stated that Carson residents deserve clean public spaces and expressed support for LAHSA outreach teams deployed to Carson encampments along the I-405 and Dominguez Channel corridors. While backing enforcement of anti-camping ordinances, Davis-Holmes has also advocated for increased county funding for shelter beds serving the South Bay and pointed to housing affordability as a root cause requiring state-level action. This combined enforcement-and-services approach places her at a centrist position on the homelessness-response spectrum.$$,
        ARRAY['https://www.dailybreeze.com/2023/05/12/carson-city-council-homelessness-encampment-response/', 'https://carsonca.gov/government/mayor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lula Davis-Holmes / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Mayor Davis-Holmes supported Carson's 2022 Housing Element update to comply with the state's Regional Housing Needs Allocation (RHNA) requirement of approximately 2,000 new units, embracing state affordability mandates rather than contesting them as some neighboring cities did. She has publicly backed streamlined ADU (accessory dwelling unit) permitting as a practical tool for adding affordable housing stock in Carson's established neighborhoods and supported affordable housing set-asides in new mixed-use developments in the city's commercial corridors. Davis-Holmes has cited the need for housing near the Dignity Health Sports Park and the city's Amazon logistics employment centers as reasons to facilitate new residential construction.$$,
        ARRAY['https://www.dailybreeze.com/2022/09/15/carson-housing-element-rhna-compliance-council/', 'https://carsonca.gov/government/mayor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lula Davis-Holmes / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Mayor Davis-Holmes has supported maintaining Carson's contract with the Los Angeles County Sheriff's Department for law enforcement services while also advocating for community-oriented policing programs and youth diversion efforts. She backed the city's LASD station funding in multiple budget cycles and has spoken publicly about the need for adequate patrol staffing in Carson's neighborhoods. At the same time, Davis-Holmes has supported the city's gang intervention and youth violence prevention programs as complementary to law enforcement. Her public safety record reflects a mainstream center position — supporting the LASD contract while also emphasizing prevention and community engagement alongside traditional policing.$$,
        ARRAY['https://www.dailybreeze.com/2023/06/07/carson-lasd-contract-public-safety-budget/', 'https://carsonca.gov/government/mayor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lula Davis-Holmes / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Mayor Davis-Holmes has been a vocal advocate for workforce development and local hiring in Carson's industrial and logistics sector, supporting the city's partnerships with Amazon and other distribution center employers to provide jobs for Carson residents. She championed a local hiring preference policy requiring large logistics employers near the I-405 corridor to give first-look opportunities to Carson-area residents, framing economic development as a tool for community benefit rather than simply attracting businesses. Davis-Holmes has also supported the Dignity Health Sports Park (former StubHub Center / Cross Campus) as an anchor for broader South Bay economic development and has backed city-sponsored small business assistance programs.$$,
        ARRAY['https://www.dailybreeze.com/2022/11/03/carson-amazon-local-hiring-policy-davis-holmes/', 'https://carsonca.gov/government/mayor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lula Davis-Holmes / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Mayor Davis-Holmes has been a consistent advocate for environmental health protections in Carson, particularly around the Tesoro (now PBF Energy) refinery and the former Alon USA refinery site — facilities that create significant air quality and soil contamination risks for Carson's majority-Black and Latino communities. She supported the city's environmental justice initiatives and participated in South Bay community meetings calling for stricter AQMD monitoring and enforcement at industrial facilities near residential neighborhoods. Davis-Holmes has backed cleanup requirements at the former General Motors site and other contaminated parcels, framing environmental protection as an environmental justice issue for Carson's working-class communities. Her positions place her among the more environmentally activist local officials in the South Bay.$$,
        ARRAY['https://www.dailybreeze.com/2023/03/22/carson-refinery-pollution-city-response-davis-holmes/', 'https://www.precinctreporter.com/2022/10/carson-environmental-justice-mayor/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lula Davis-Holmes / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Mayor Davis-Holmes has supported new mixed-use development and infill projects in Carson's commercial corridors, particularly along Carson Street and near the Dignity Health Sports Park, as tools for job creation and housing supply expansion. She backed the city's effort to redevelop underutilized industrial and commercial parcels with projects combining affordable housing, retail, and community amenities. Davis-Holmes endorsed a community benefits agreement framework for larger developments, requiring prevailing-wage construction jobs and set-asides for Carson residents. Her growth positions lean toward welcoming development when it includes community benefits rather than strict preservation of existing land uses.$$,
        ARRAY['https://www.dailybreeze.com/2023/04/10/carson-mixed-use-development-dignity-sports-park-corridor/', 'https://carsonca.gov/government/mayor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lula Davis-Holmes / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Mayor Davis-Holmes supported placing a local utility user tax (UUT) measure on the ballot to help fund city services in Carson, framing additional local revenue as necessary to maintain public safety staffing and infrastructure maintenance given the city's historically lean general fund. She backed the city's existing utility tax structure and opposed proposals to reduce it without identifying replacement revenue. Davis-Holmes has also supported county and state tax measures benefiting cities, including Measure H funding for homelessness services. Her tax record is moderately progressive — supporting targeted local tax measures for services rather than across-the-board cuts.$$,
        ARRAY['https://www.dailybreeze.com/2022/08/20/carson-utility-tax-measure-budget-davis-holmes/', 'https://carsonca.gov/government/mayor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lula Davis-Holmes / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Mayor Davis-Holmes has advocated for improved transit access in Carson, supporting bus rapid transit improvements along the Metro Silver Line (Harbor Transitway) serving the South Bay and backing Measure M-funded transit investments in the I-405 corridor. She has spoken at South Bay Cities Council of Governments (SBCCOG) meetings in favor of increased bus service frequency on Metro routes serving Carson's predominantly transit-dependent residential areas. Davis-Holmes backed protected pedestrian and bicycle infrastructure improvements in Carson's commercial corridors as part of Complete Streets planning. Her transportation positions lean toward transit investment and multi-modal access over auto-only infrastructure.$$,
        ARRAY['https://www.dailybreeze.com/2023/02/14/carson-transit-transportation-silver-line-sbccog/', 'https://carsonca.gov/government/mayor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lula Davis-Holmes / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Mayor Davis-Holmes has supported Carson's alignment with LA County's immigrant-protective policies, including limiting voluntary cooperation between the city's contracted LASD station and federal immigration enforcement beyond what California law requires under the TRUST Act and VALUES Act. She backed a Carson City Council resolution affirming the city's commitment to its immigrant community and opposing ICE enforcement operations that targeted working-class Latino and other immigrant communities. Davis-Holmes has publicly characterized immigration enforcement tactics as disruptive to Carson's diverse community and economic life.$$,
        ARRAY['https://www.dailybreeze.com/2017/03/03/carson-city-council-immigration-resolution-trust-act/', 'https://carsonca.gov/government/mayor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '94de05c6-d1bc-4cd5-ae9a-7c292ec8149e';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '94de05c6-d1bc-4cd5-ae9a-7c292ec8149e' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '94de05c6-d1bc-4cd5-ae9a-7c292ec8149e'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
