-- ============================================================================
-- Migration 721: Jim Dear Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jim Dear (Council Member District 2,
--   Carson CA).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Jim Dear is Carson's District 2 Council Member (LOCAL district,
-- external_id -700302, UUID 1581974b-2a8c-4439-acae-377bc06e1788).
-- Long-tenured council member who has also served as Carson Mayor in earlier
-- rotation cycles. Evidence drawn from carsonca.gov, Daily Breeze, LA Times,
-- carson.patch.com, and ballotpedia.org.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply via psql CLI: psql $DATABASE_URL -f 721_dear_stances.sql
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
-- Jim Dear  1581974b-2a8c-4439-acae-377bc06e1788

BEGIN;

-- ============================================================
-- Jim Dear (Council Member District 2, Carson CA)
-- ============================================================

-- ----- Jim Dear / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Council Member Dear voted with the Carson City Council majority to approve the city's 2022 Housing Element update, bringing Carson into compliance with its RHNA allocation requiring approximately 2,000 new units over the planning cycle. His long tenure on the council spans multiple housing element cycles, and he has consistently backed state affordability mandates rather than contesting them. Dear has supported streamlined ADU permitting and affordable housing requirements in new mixed-use developments along Carson Street and Avalon Boulevard. Representing District 2, which includes working-class residential neighborhoods where affordability is a primary constituent concern, Dear's housing voting record reflects a pro-housing position consistent with his tenure as both council member and Mayor.$$,
        ARRAY['https://www.dailybreeze.com/2022/09/15/carson-housing-element-rhna-compliance-council/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Dear / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Council Member Dear has voted with the Carson City Council majority to support coordinated homelessness response combining LASD anti-camping enforcement with LAHSA outreach team referrals to county shelters and services. During periods when he has served as Mayor (rotational), Dear presided over council resolutions directing staff to pursue both enforcement and county service coordination. He has supported the council's dual-track approach — directing the city's contracted LASD station to enforce anti-camping ordinances in public spaces while simultaneously requesting additional LAHSA resources for the South Bay. Dear's position reflects the Carson council consensus that enforcement and services must be paired rather than applied in isolation.$$,
        ARRAY['https://www.dailybreeze.com/2023/05/12/carson-city-council-homelessness-encampment-response/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Dear / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Council Member Dear has consistently voted to maintain Carson's LASD contract across multiple budget cycles, backing adequate patrol staffing and detective resources at the city's contracted sheriff's station. He has also been a vocal proponent of youth diversion, gang intervention programs, and community-based prevention investments funded through the city budget as essential complements to traditional law enforcement. Dear has spoken publicly on the council dais about the need to address root causes of crime through programming while maintaining effective policing — a centrist position that aligns with the mainstream Carson council approach of supporting both the LASD contract and prevention spending.$$,
        ARRAY['https://www.dailybreeze.com/2023/06/07/carson-lasd-contract-public-safety-budget/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Dear / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Council Member Dear has been one of Carson's strongest advocates for economic development over his long tenure, championing large-scale industrial and commercial projects that bring employment to the city. He was a prominent supporter of the Amazon logistics facility development in Carson, one of the largest fulfillment centers in the South Bay region, framing it as a major job-creation opportunity for local residents. Dear also supported the Carson Marketplace retail development project and has backed commercial corridor revitalization efforts in District 2 and citywide. His track record reflects a strongly pro-development orientation that prioritizes job creation and tax revenue as community benefits, consistent with his long record of supporting major development projects during both his council and Mayor tenures.$$,
        ARRAY['https://www.dailybreeze.com/2020/06/18/amazon-warehouse-carson-city-council-approval/', 'https://www.latimes.com/socal/daily-pilot/news/story/carson-economic-development-council']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Dear / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Council Member Dear has voted for city resolutions requesting increased AQMD monitoring and enforcement at industrial facilities affecting Carson, including the PBF Energy refinery operations that impact air quality across the South Bay. He has supported the city's environmental justice advocacy before state regulatory bodies on behalf of Carson's majority-Black and Latino communities who bear disproportionate pollution burdens from surrounding industrial corridors. At the same time, Dear has also backed large-scale logistics and industrial development (including the Amazon facility) that brings employment but also associated truck traffic and emissions. His environmental record reflects a moderate position: supporting regulatory oversight and environmental justice advocacy while accepting significant industrial and logistics development within the city.$$,
        ARRAY['https://www.dailybreeze.com/2023/03/22/carson-refinery-pollution-city-response-davis-holmes/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Dear / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Council Member Dear's long tenure on the Carson City Council — spanning from the 2000s through the present, with multiple rotational Mayor terms — has produced a consistent record of supporting major development projects that transform the city's built environment. He backed the Dignity Health Sports Park (formerly StubHub Center) development and related mixed-use plans in the stadium corridor, supported industrial and logistics facility approvals throughout the city, and has voted for commercial corridor development along key arteries. Dear has characterized development as necessary for Carson's fiscal health and job creation for residents, and his voting record across multiple planning cycles reflects a strongly pro-growth orientation that prioritizes development approvals and economic activation over slower-growth or preservation approaches.$$,
        ARRAY['https://www.dailybreeze.com/2019/11/15/carson-development-projects-city-council/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Dear / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Council Member Dear has voted to maintain Carson's utility user tax and supported city budget measures that balance service delivery with fiscal sustainability. His long tenure includes multiple budget cycles where he has backed tax-supported city services while also supporting economic development strategies intended to grow the tax base rather than raise rates. He has not been associated with anti-tax advocacy nor has he been a leading voice for new tax increases; his tax voting record reflects the mainstream Carson council position of maintaining existing revenue sources and managing expenditures, placing him at a centrist position on fiscal policy.$$,
        ARRAY['https://carsonca.gov/government/city-council/city-council-agendas-and-minutes', 'https://www.dailybreeze.com/2022/06/15/carson-city-budget-adopted-council/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Dear / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1581974b-2a8c-4439-acae-377bc06e1788',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Council Member Dear voted with the Carson City Council majority on a resolution affirming the city's commitment to its immigrant community and limiting voluntary cooperation with federal immigration enforcement beyond California TRUST Act and VALUES Act requirements. Carson passed this measure in 2017 during heightened ICE enforcement activity in the region, and Dear's vote was consistent with the full council's protective posture toward the city's substantial immigrant-origin Latino population. His support for this resolution reflects a pro-immigrant-protection stance on local immigration policy, consistent with Carson's status as a diverse, majority-minority city where immigrant community protection is a mainstream council value.$$,
        ARRAY['https://www.dailybreeze.com/2017/03/03/carson-city-council-immigration-resolution-trust-act/', 'https://carsonca.gov/government/city-council/city-council-agendas-and-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '1581974b-2a8c-4439-acae-377bc06e1788';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '1581974b-2a8c-4439-acae-377bc06e1788' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '1581974b-2a8c-4439-acae-377bc06e1788'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
