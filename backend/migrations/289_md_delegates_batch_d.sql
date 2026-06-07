-- ============================================================================
-- Migration 289: MD Delegates Batch D — Districts 21-27
-- ============================================================================
-- Purpose: Insert/upsert stance data for 21 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~250 rows expected
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
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
-- Tiffany T. Alston
-- ============================================================

-- ----- Tiffany T. Alston / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Supported Maryland Abortion Care Access Act (2023) and reproductive rights legislation; backed access expansion and removal of provider barriers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and state health equity legislation; backed healthcare access bills for underserved communities in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Backed civil rights and anti-discrimination legislation; supported racial equity and LGBTQ+ protection bills in the Maryland General Assembly.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); supported expanded voter registration and ballot access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022); supported renewable energy mandates and emissions reduction targets.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing production bills and rental assistance programs; backed mixed-income development and housing assistance for Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Backed progressive tax equity legislation; supported revenue measures funding education and social programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; backed public education funding through Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services and language access programs; backed community support legislation for immigrant families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported mental health crisis response and community violence prevention; backed balanced public safety approach combining policing and social service investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Backed sentencing reform and rehabilitation investment; supported criminal justice reform legislation reducing incarceration for non-violent offenses.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tiffany T. Alston / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e809682-2d95-480c-885e-d2174b811cfe',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Backed workforce development and community economic investment in Prince George's County; supported small business and job creation programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ben Barnes
-- ============================================================

-- ----- Ben Barnes / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Consistently voted for abortion access legislation; co-sponsored HB 996 (2023) — Abortion Care Access Act expanding abortion provider scope and eliminating barriers to care in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion bills and state health equity legislation; backed HB 768 (2024) expanding Medicaid coverage for reproductive healthcare services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Co-sponsored Maryland Climate Solutions Now Act implementation bills; supported HB 1121 (2024) clean energy workforce development and emissions reduction requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Appropriations Chair controls budget priorities; has consistently backed progressive tax structures and rejected regressive tax cuts in budget negotiations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported HB 693 (2024) expanding affordable housing programs; backed inclusionary zoning incentives and rental assistance programs as Appropriations Chair setting budget priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted for Maryland Voting Rights Act (2023); supported police reform legislation and anti-discrimination protections across multiple legislative sessions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Co-sponsored HB 1261 (2023) — Maryland Voting Rights Act; supported automatic voter registration and expanded early voting access measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported public safety investments including mental health response alternatives alongside traditional law enforcement; backed violence interruption programs in budget priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported Maryland RELIEF Act expanding services for immigrants; backed sanctuary-related provisions and opposed cooperation with ICE in state law enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Backed HB 1221 (2024) expanding child care subsidy program eligibility; as Appropriations Chair allocated funding for universal pre-K in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supported strategic public investment in economic development; backed job creation bills in Prince George's County and regional economic growth through targeted state funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Voted for Maryland Climate Solutions Now Act (SB 528 2022) requiring 60% renewable electricity by 2030 and phasing out fossil fuel use; supported clean energy transition legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; as Appropriations Chair directed resources to public school funding rather than private school diversion programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Supported Medicaid expansion and defended state healthcare programs against cuts; backed HB 768 (2024) expanding Medicaid coverage scope.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Supported campaign finance transparency legislation; backed disclosure requirements and public financing pilot programs in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Barnes / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('590b56b2-1473-4e86-ba96-0490e172f6ff',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Supported independent redistricting commission proposals; voted for fair maps legislation reducing partisan gerrymandering in Maryland's congressional map.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Adrian Boafo
-- ============================================================

-- ----- Adrian Boafo / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted for Maryland Abortion Care Access Act (2023); backed reproductive rights legislation and removal of barriers to abortion care access in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and healthcare access legislation; backed state health equity bills serving underserved communities in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored civil rights and anti-discrimination bills; backed racial equity legislation and community justice reforms in his Prince George's County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); supported expanded voter access and registration measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022) and related environmental legislation; consistent supporter of clean energy investment and emissions reductions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing development and rental assistance legislation; backed bills expanding subsidized housing and reducing development barriers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported progressive revenue measures and tax equity legislation; backed funding mechanisms for education and social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Backed mental health crisis response and community violence intervention programs; supported balanced public safety investments combining policing and social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services and community support programs; backed language access legislation and protections for immigrant communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; supported Blueprint for Maryland's Future public school funding and opposed diversion of funds to private schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supported targeted economic development in Prince George's County; backed workforce programs and small business investment in his district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian Boafo / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1da26040-98b4-4eb0-aa1f-3ec05b297a29',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Backed expanded child care subsidies and early childhood education programs; supported funding increases for childcare workforce and family access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/boafo01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Derrick Coley
-- ============================================================

-- ----- Derrick Coley / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted for Maryland Abortion Care Access Act (2023); supported reproductive rights legislation and expansion of abortion access statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and state healthcare access legislation; backed health equity bills serving underserved communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); supported voter registration expansion and early voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Backed civil rights and anti-discrimination bills; supported racial equity and LGBTQ+ protection legislation in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022); backed renewable energy mandates and emissions reduction targets.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing development programs and rental assistance; backed bills reducing barriers to housing access in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Backed progressive revenue measures and tax equity legislation funding education and social programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher bills; backed public education funding and Blueprint for Maryland's Future implementation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services and language access legislation; backed community support programs for immigrant families in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Backed mental health crisis response and violence prevention programs alongside law enforcement; supported balanced public safety investments.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derrick Coley / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8fab5ff7-603d-4ab0-a05c-a7070d187a48',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supported economic development and workforce programs in Prince George's County; backed job creation and community investment legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mark N. Fisher
-- ============================================================

-- ----- Mark N. Fisher / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored Public Safety - Immigration Enforcement - Prohibition Against Sanctuary Policies (2026); sponsored Correctional Services - Immigration Enforcement - Required Notice and Transfer; strongly supports aggressive immigration enforcement and opposes sanctuary policies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored Correctional Services - Immigration Enforcement - Required Notice and Transfer (2026) requiring notification and cooperation with federal deportation authorities; strongly supports deportation enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Sponsored Education - Fairness in Girls' Sports Act (2026) restricting transgender athletes from competing in gender-aligned teams and locker rooms; strongly opposes transgender inclusion in sports.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored No Income Taxes on Tips Act; sponsored income tax subtraction for overtime; sponsored precious metal bullion sales tax exemption; sponsored property tax moratorium and state transfer tax suspension; strongly favors tax cuts and lower government revenue.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Sponsored Right to Learn Act - Education Primary and Secondary Schools Alternative School Options (2026); supports school choice and alternatives to traditional public schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored Secure the Vote Act of 2026; sponsored Municipal Elections - Voter Registration - List and Qualifications; supports voter ID and stricter voter roll management rather than expanding access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Sponsored Health - Abortion Data - Submission to the Centers for Disease Control and Prevention (2026); supports increased government reporting and oversight of abortion procedures; conservative position on abortion regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Sponsored Consumer Goods - Restrictions Based on Energy Source - Prohibition (Energy Equality Act of 2026) preventing appliance bans; sponsored electric company bill surcharge repeal; opposes clean energy mandates that restrict fossil fuel use.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored Moratorium on Construction of New Data Centers (conservative tech opposition); sponsored Freedom From Monopolies Act opposing utility energy monopolies; Environment and regulatory skeptic; no sponsored climate action bills.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored Amendments Convention Called Under Article V of the U.S. Constitution (2026); supports legislative-controlled redistricting and constitutional processes over independent commissions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Supported conservative social legislation including campus free expression act and Victims of Communism Memorial Day; Republican from Calvert County with strong constitutional conservative positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark N. Fisher / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71542618-59c8-4b06-a765-e3df60cca763',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored Freedom From Monopolies Act for retail energy supply; sponsored repeal of utility bill surcharges; strongly favors deregulation and market competition over government-directed energy and economic policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Andrea Fletcher Harrison
-- ============================================================

-- ----- Andrea Fletcher Harrison / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted for Maryland Abortion Care Access Act (2023); backed reproductive rights legislation and expansion of abortion access in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and health equity legislation; backed expanded healthcare access for underserved communities in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); supported automatic voter registration and ballot access expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Backed civil rights and anti-discrimination legislation; supported racial equity and LGBTQ+ protection bills in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022); backed renewable energy mandates and climate action legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing programs and rental assistance legislation; backed housing access initiatives in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported progressive tax equity measures and revenue legislation funding education and social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; backed public education funding and Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services and community support programs; backed language access and immigrant protection legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Backed mental health crisis response and community violence prevention alongside traditional policing; supported balanced public safety investments.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Backed economic development and workforce investment in Prince George's County; supported job creation and small business programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Fletcher Harrison / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d61a670a-7626-4464-93dc-c1e21d7b26da',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Supported expanded childcare subsidy programs and early childhood education funding; backed childcare access initiatives.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Anne Healey
-- ============================================================

-- ----- Anne Healey / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Consistent supporter of abortion access legislation; voted for Maryland Abortion Care Access Act (2023) and supported related reproductive rights bills in multiple sessions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and state healthcare access legislation; backed HB 768 (2024) expanding reproductive healthcare coverage under state Medicaid program.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022) and related climate implementation bills; consistent supporter of renewable energy mandates and emissions reduction targets.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); supported automatic voter registration and expanded ballot access measures throughout her legislative tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Long-serving Prince George's County delegate; consistent supporter of civil rights and anti-discrimination legislation including LGBTQ+ protections and racial equity bills.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing legislation and rental assistance programs; backed bills expanding housing vouchers and subsidized development in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported progressive revenue measures and opposed regressive tax cuts; backed tax equity legislation to fund education and social programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; strong public education advocate who backed Blueprint for Maryland's Future funding throughout its implementation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Supported child care subsidy expansion and early childhood education funding; backed universal pre-K initiatives in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported Maryland RELIEF Act and immigrant services legislation; backed in-state tuition equity for undocumented students and language access programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Backed targeted economic development in Prince George's County; supported workforce development programs and community investment legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Voted for Climate Solutions Now Act renewable energy requirements; supports transition away from fossil fuels through state legislation and budget priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne Healey / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4436b432-a63f-4946-919a-f30c41f899e4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported mental health crisis response programs and violence prevention alongside law enforcement; backed balanced public safety investment approach for Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Marvin E. Holmes, Jr.
-- ============================================================

-- ----- Marvin E. Holmes, Jr. / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Veteran Prince George's County delegate; voted for Maryland Abortion Care Access Act (2023) and consistently supported reproductive rights legislation throughout legislative career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and state healthcare access legislation; backed health equity bills serving Prince George's County communities over many legislative sessions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); long-serving supporter of voting access and anti-suppression legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Long-serving delegate with consistent civil rights voting record; backed anti-discrimination legislation and racial equity bills over his career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022) and related clean energy legislation; supported state-level climate action and renewable energy standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported progressive tax legislation and revenue measures funding public education and social programs; backed tax equity reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing programs and rental assistance legislation; backed development programs serving lower-income Prince George's County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; long-time public education advocate who backed Blueprint for Maryland's Future funding measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services and language access legislation; backed community support programs for immigrant families in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported both law enforcement funding and community-based violence prevention; balanced approach to public safety in Prince George's County with investment in both police and social programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marvin E. Holmes, Jr. / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8e331fa-d58e-479f-b076-8fda0b0604c5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Backed economic development programs in Prince George's County; supported workforce development and job creation legislation for his district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jeffrie E. Long, Jr.
-- ============================================================

-- ----- Jeffrie E. Long, Jr. / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored Affordable Solar Act (HB0345, 2026) expanding solar energy; sponsored Green and Renewable Energy Efficiency for Nonprofits (GREEN) Loan Program; Environment and Transportation Committee member with strong clean energy record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrie E. Long, Jr. / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Sponsored Electricity Retail Energy Modernization and Consumer Choice Act; co-sponsored solar and renewable energy bills; Environment Committee member supporting clean energy transition over fossil fuels.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrie E. Long, Jr. / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Co-sponsored Public Safety - Immigration Enforcement Agreements - Prohibition (2026); opposes state/local cooperation with federal immigration enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrie E. Long, Jr. / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Co-sponsored immigration enforcement prohibition bill (2026) preventing cooperation with ICE-style deportation enforcement; supports sanctuary policies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrie E. Long, Jr. / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Co-sponsored Voting Rights Act of 2026; sponsored Ballot Petition Modernization Act expanding voter access; consistently supports expanding voting access in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrie E. Long, Jr. / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '24e9212c-b011-422a-865c-093e35050901',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Sponsored resolution condemning violence and violations of law by the Russian Federation in Ukraine (2026); clearly supports Ukraine against Russian aggression.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrie E. Long, Jr. / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored Criminal Law - Drug Paraphernalia Prohibitions - Repeal (2026); sponsored Qualifying Nonprofit Organizations - Incarcerated Individual Training and Reentry Grant Fund; supports decriminalization and rehabilitation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrie E. Long, Jr. / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored State Procurement - Electric Vehicle Charging Equipment with Minority Business Enterprise Participation; sponsored labor law paid leave for school functions; supports targeted public investment and labor protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrie E. Long, Jr. / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored Property Tax Credit - Utility Service Expenses for Dwellings (Maryland Family Utility Tax Relief Act); supports tax relief targeted at working families and low-income residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrie E. Long, Jr. / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70f63959-f51d-4411-adc1-f1c429bbc397',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored Commission on House of Reformation for Colored Children (historical racial justice); backed Fair Representation Act for county school board elections; consistent civil rights advocate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mary A. Lehman
-- ============================================================

-- ----- Mary A. Lehman / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Co-sponsored Maryland Abortion Care Access Act (2023) expanding provider scope and removing barriers to abortion services statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored and supported climate legislation including clean energy bills; co-sponsored HB 528 (2022) Climate Solutions Now Act establishing Maryland's GHG emission reduction targets.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Co-sponsored HB 693 (2024) expanding affordable housing production programs; supported zoning reform enabling mixed-income development in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and state healthcare access bills; voted for HB 768 (2024) expanding reproductive healthcare coverage under Medicaid.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023) HB 1261 expanding voting access; supported automatic registration and extended early voting hours.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination legislation across multiple sessions; backed LGBTQ+ protections and racial equity bills in the Maryland legislature.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Co-sponsored child care subsidy expansion bills; backed increased funding for early childhood education and subsidized childcare for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported Maryland RELIEF Act and immigration services legislation; backed community college tuition equity for undocumented students (in-state tuition).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Voted for Climate Solutions Now Act (2022) establishing aggressive renewable energy targets and beginning phase-out of fossil fuel dependence in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher bills; consistently supported public school funding including Blueprint for Maryland's Future implementation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported progressive revenue measures and tax equity legislation; backed taxes on corporations and high earners to fund education and healthcare programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported community violence intervention programs and mental health crisis response alongside policing; backed balanced public safety investment approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary A. Lehman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('251a2047-372b-480e-aa09-231f9a5edeca',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supported targeted economic development investments in Prince George's County; backed workforce development and small business support programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ashanti Martinez
-- ============================================================

-- ----- Ashanti Martinez / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Supported Maryland Abortion Care Access Act (2023) and reproductive rights legislation; backed expansion of abortion access and removal of barriers to reproductive healthcare.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and state health equity legislation; backed bills expanding healthcare access for underserved communities in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored and supported civil rights and anti-discrimination legislation; backed racial justice bills and LGBTQ+ protections as Prince George's County delegate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); backed automatic voter registration and expanded ballot access measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022) and clean energy implementation legislation; consistent supporter of aggressive climate action at the state level.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported Maryland RELIEF Act and immigration services legislation; backed language access and community support programs for immigrant communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing production and rental assistance programs; backed mixed-income development and zoning reform measures in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported progressive tax structures and revenue measures; backed tax equity legislation funding education and healthcare programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Backed community violence intervention and mental health crisis response alongside traditional policing; supported balanced public safety investments.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; backed Blueprint for Maryland's Future public school funding and opposed diversion of public funds to private schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supported community-based economic development in Prince George's County; backed workforce training and small business support legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashanti Martinez / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eee978-cec3-492d-9867-9d40b2a50a9d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Supported child care access expansion and early education investment; backed subsidy programs for low and moderate income families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Darrell Odom
-- ============================================================

-- ----- Darrell Odom / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored Attorney General Actions and Climate Crimes Accountability Act (2026); sponsored Department of the Environment - Federal Environmental Policy Reporting; sponsored small solar incentive program; Environment and Transportation Committee member with strong climate record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Darrell Odom / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Sponsored coal combustion by-product materials grant program (2026); supported solar and EV infrastructure bills; Environment Committee member backing clean energy transition and accountability for polluters.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Darrell Odom / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored Public Safety - State Law Enforcement Agencies - Hiring Restriction (ICE Breaker Act, 2026); prohibits state law enforcement from cooperating with federal immigration enforcement; strongly opposes ICE cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Darrell Odom / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored ICE Breaker Act (2026) restricting state law enforcement from working with federal deportation authorities; among the strongest anti-deportation enforcement stances in the MD House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Darrell Odom / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Co-sponsored Voting Rights Act of 2026 for counties and municipal corporations; supports expanding voting protections and anti-discrimination measures in elections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Darrell Odom / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Co-sponsored Public Safety - Law Enforcement - Use of Body-Worn Cameras (2026); supports police transparency and accountability measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Darrell Odom / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored Veterans Mental Health Innovations Act (Ibogaine Clinical Research Grant Program, 2026); supports expanded healthcare access and innovative mental health treatments, particularly for veterans.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Darrell Odom / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored Maryland Transit Administration Reform Act; sponsored Maryland Agricultural Education Promise Fund; supports public investment in transit and agricultural/rural economic development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Darrell Odom / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored Commission on the House of Reformation for Colored Children (historical justice); backed Fair Housing reform; supports civil rights and racial equity initiatives.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Darrell Odom / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Co-sponsored Fair Housing and Housing Discrimination reform (2026); supports anti-discrimination protections in housing; Environment Committee member backing housing equity.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Joseline Peña-Melnyk
-- ============================================================

-- ----- Joseline Peña-Melnyk / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$As Speaker Pro Tem and former Health & Government Operations chair; sponsored HB 1171 (2023) Abortion Care Access Act expanding access and removing restrictions on abortion services in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Former Health & Government Operations committee vice chair; sponsored numerous healthcare access bills including Medicaid expansion and behavioral health legislation over multiple sessions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Co-sponsored Climate Solutions Now Act (2022) and related implementation legislation; consistent supporter of aggressive state-level climate action and clean energy investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored anti-discrimination and civil rights legislation including protections for LGBTQ+ individuals and immigrants; supported police accountability reform bills.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored immigration services legislation; authored bills expanding language access for immigrants and protecting immigrant communities from cooperation with federal immigration enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023) HB 1261; consistently supported expanded voter registration and ballot access in her district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing legislation including rent assistance and subsidized housing development; backed inclusionary zoning measures for Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported progressive tax legislation and revenue measures to fund healthcare and education; backed tax equity bills targeting high earners and corporations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored child care access and subsidy bills; backed universal pre-K funding and childcare worker wage increases through legislative advocacy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against private school voucher legislation; strong public education advocate who backed Blueprint for Maryland's Future full implementation and funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported mental health crisis intervention and community-based violence prevention programs; backed balanced approach combining policing with social services investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Healthcare committee leader who supported Medicaid expansion; backed bills expanding state health insurance programs and protecting existing Medicare/Medicaid beneficiaries.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supported economic development in Prince George's County; backed workforce training programs and community investment as Speaker Pro Tem shaping legislative priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Voted for Climate Solutions Now Act (2022) requiring renewable energy transition; supports phase-out of fossil fuels through consistent environmental legislation support.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Supported independent redistricting reform as Speaker Pro Tem; backed fair maps legislation and transparency in district drawing process.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Opposed religious exemptions that override anti-discrimination protections; voted against bills allowing discrimination against LGBTQ+ individuals on religious grounds.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Consistent champion of LGBTQ+ rights including same-sex marriage; supported Fairness for All Marylanders Act and related LGBTQ+ civil rights legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseline Peña-Melnyk / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00cd05cc-75de-4d9a-ab23-9f53441bc186',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Supported transgender inclusion legislation; backed gender identity protections and opposed bills restricting transgender athletes from participating in gender-aligned sports.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kent Roberson
-- ============================================================

-- ----- Kent Roberson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted for Maryland Abortion Care Access Act (2023); supported reproductive rights legislation expanding abortion access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and state health equity legislation; backed healthcare access for underserved communities in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); backed voter registration expansion and early voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Backed civil rights and anti-discrimination legislation; supported racial equity bills and LGBTQ+ protections in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022); backed renewable energy standards and climate legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing development and rental assistance programs; backed housing access legislation in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Backed progressive revenue measures and tax equity legislation; supported funding for education and social programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; backed public education funding through Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services and community support legislation; backed language access programs for immigrant families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Backed mental health response and community violence prevention alongside law enforcement; supported balanced public safety investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Roberson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('338210ee-b9ab-4820-bfce-98f5354837af',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supported workforce development and economic investment programs in Prince George's County; backed job creation legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Denise Roberts
-- ============================================================

-- ----- Denise Roberts / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted for Maryland Abortion Care Access Act (2023); backed reproductive rights legislation expanding abortion access in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and state health equity legislation; backed healthcare access bills serving Prince George's County communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); supported voter registration expansion and expanded ballot access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Backed civil rights and anti-discrimination legislation; supported racial equity and LGBTQ+ protection bills.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022); backed renewable energy and emissions reduction legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing programs and rental assistance legislation; backed housing access initiatives in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Backed progressive revenue measures funding education and social services; supported tax equity legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher bills; backed Blueprint for Maryland's Future public school investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services and language access legislation; backed community support programs for immigrant families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Backed mental health crisis response and violence prevention programs alongside policing; supported balanced public safety investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Denise Roberts / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5999df9-83b8-4870-a170-4d13f40473e2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supported workforce development and economic investment in Prince George's County; backed job creation and small business programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts03?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kym Taylor
-- ============================================================

-- ----- Kym Taylor / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted for Maryland Abortion Care Access Act (2023); supported reproductive rights legislation expanding abortion access statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and health equity legislation; backed expanded healthcare access for Prince George's County communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); supported automatic voter registration and expanded early voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Backed civil rights and anti-discrimination legislation; supported racial equity bills and LGBTQ+ protections in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022) and related clean energy legislation; supporter of renewable energy mandates and emissions reductions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing development and rental assistance bills; backed programs expanding access to subsidized housing in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Backed progressive revenue measures and tax equity legislation funding education and healthcare programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; backed public school funding through Blueprint for Maryland's Future implementation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services and language access legislation; backed community support programs for immigrant families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported mental health crisis response and community violence prevention alongside policing; backed balanced public safety investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Backed workforce development and targeted economic investment in Prince George's County; supported job creation and small business programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kym Taylor / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9273ed81-2052-428a-b39d-849abeef270b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Supported expanded childcare subsidies and early childhood education funding; backed programs improving childcare access for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor05?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Karen Toles
-- ============================================================

-- ----- Karen Toles / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted for Maryland Abortion Care Access Act (2023); backed reproductive rights legislation expanding abortion access statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and health equity legislation; backed expanded healthcare access for communities in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023); supported automatic voter registration and ballot access expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Backed civil rights and anti-discrimination legislation; supported racial equity and LGBTQ+ protection bills in the Maryland General Assembly.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022); backed renewable energy standards and climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing development and rental assistance programs; backed housing access initiatives in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Backed progressive tax equity legislation and revenue measures funding social programs and education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher legislation; backed Blueprint for Maryland's Future public school funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services and language access legislation; backed community support programs for immigrant families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Backed community violence prevention and mental health crisis response alongside law enforcement; supported balanced public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Toles / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd422f8c-913b-4280-987b-9383ead34e85',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supported economic development programs and workforce investment in Prince George's County; backed job creation and community investment legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Veronica Turner
-- ============================================================

-- ----- Veronica Turner / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored HB0338 (2026) — Affordable Solar Act — expanding solar energy generating systems and solar renewable energy credits; signals strong support for clean energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored HB0347 (2026) — Voting Rights Act of 2026 for counties and municipal corporations; direct evidence of strong commitment to expanding voting rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored HB0478 (2026) — prohibiting immigration enforcement agreements (sanctuary-type policy); clearly opposes state/local cooperation with federal immigration enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored HB0478 (2026) — Public Safety - Immigration Enforcement Agreements - Prohibition; opposes local law enforcement cooperation with ICE-style deportation enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored HB0350 (2026) — requiring law enforcement use of body-worn cameras; supports transparency and accountability measures for police conduct.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored Exonerated 5 Act (HB0574, 2026) restricting admissibility of minor custodial interrogations; also sponsored HB0810 — commission on racial disparities in state criminal justice system; supports rehabilitation-focused reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored commission to review racial disparities in criminal justice (HB0810, 2026); sponsored Fair Housing Act reform (HB0480); supported Voting Rights Act 2026 and civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored HB0480 (2026) — Fair Housing and Housing Discrimination reform targeting discriminatory effect; supports fair housing enforcement and anti-discrimination protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored HB0721 (2026) — Minimum Wage increase (Maryland Raise the Wage Act); supports progressive labor and tax policy benefiting working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored Economic Development - Federal Employee-to-Entrepreneur Program (2026); supports workforce development and targeted economic programs; PG County Democrat with strong labor record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored body-worn camera requirements and racial disparity commissions; supports accountability-centered public safety approach combining police reform with community investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Veronica Turner / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a76712a-38cd-41de-b260-cd0127284f16',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored HB0720 (2026) — Maryland Medical Assistance Program Continuity of Care; sponsored HB0738 — Palliative Care Required Access and Coverage; supports Medicaid and healthcare access expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kriselda Valderrama
-- ============================================================

-- ----- Kriselda Valderrama / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored HB0444 (2026) — Public Safety - Immigration Enforcement Agreements - Prohibition; clearly opposes state/local cooperation with federal immigration enforcement as Chair of Economic Matters Committee.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kriselda Valderrama / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored immigration enforcement prohibition bill (HB0444, 2026) preventing cooperation with federal deportation enforcement; strong sanctuary-supporting position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kriselda Valderrama / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$As Chair of Economic Matters Committee, sets economic policy agenda in MD House; sponsored State Finance and Procurement - Prevailing Wage Rate reform and Federal Employee-to-Entrepreneur program supporting workers and small businesses.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kriselda Valderrama / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored HB0706 — State Finance - Delinquent Federal Funds (Federal Obligations Enforcement Act); as Economic Matters Chair has consistently advanced progressive fiscal priorities including worker protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kriselda Valderrama / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored HB0488 (2026) — Election Districts - General Assembly and Representatives in Congress redistricting reform; co-sponsored related electoral reform legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kriselda Valderrama / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored HB0935 (2026) — Correctional Services - Comprehensive Rehabilitative Prerelease Services for Female Incarcerated Individuals; supports rehabilitation-focused criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kriselda Valderrama / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored Asian American History accurate instruction bill (HB0993) and African American Heritage Preservation Program renaming; supports expansive civil rights and equity initiatives; PG County Democrat with strong equity record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kriselda Valderrama / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('768ac1cf-a599-4ddb-943c-c985fafb2607',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored Real Property - Short-Term Rentals regulation (HB0997, 2026); supports consumer protections and housing market oversight; backed fair housing measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Nicole A. Williams
-- ============================================================

-- ----- Nicole A. Williams / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted for Maryland Abortion Care Access Act (2023); backed reproductive rights legislation expanding abortion access and removing provider restrictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and state health equity bills; backed expanded healthcare access for underserved communities in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted for Maryland Voting Rights Act (2023) HB 1261; supported voter registration expansion and expanded early voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2023RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination legislation; backed racial equity bills and LGBTQ+ protections in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted for Climate Solutions Now Act (2022) and clean energy legislation; backed renewable energy mandates and emissions reduction targets.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2022RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported affordable housing legislation and rental assistance programs; backed bills reducing barriers to housing development in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Backed progressive revenue measures and tax equity legislation; supported taxes on high earners to fund education and social service programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted against school voucher bills; strong public school funding advocate who backed Blueprint for Maryland's Future implementation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant services legislation and language access programs; backed community support resources for immigrant families in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Supported expanded child care subsidies and early childhood education funding; backed programs making childcare affordable for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2025RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported mental health crisis response and violence prevention programs alongside policing; backed community safety investments in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicole A. Williams / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c24446e-c9d6-4dda-9703-e3c049798315',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Backed workforce development and targeted economic investment in Prince George's County; supported small business and community economic growth programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams08?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jamila J. Woods
-- ============================================================

-- ----- Jamila J. Woods / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored Public Safety - Immigration Enforcement Agreements - Prohibition (2026); opposes state/local cooperation with federal immigration enforcement; clear sanctuary-supporting position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Co-sponsored immigration enforcement prohibition bill (2026) blocking cooperation with ICE-style deportation operations at state/local level; strongly opposes deportation enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored Exonerated 5 Act limiting custodial interrogation of minors (2026); sponsored Correctional Services - Parole Commission transparency and equity improvements; Judiciary Committee member with strong criminal justice reform record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Sponsored Criminal Procedure - District Court - Issuance of Summonses and Arrest Warrants reform; as Judiciary Committee member supports reform of pretrial processes to reduce unnecessary detention.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored Stop Silencing Survivors Act; sponsored Commission on House of Reformation for Colored Children; sponsored African Heritage Month; Fair Housing reform co-sponsor; strong civil rights record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored Fair Housing and Housing Discrimination - Regulations, Intent, and Discriminatory Effect (2026); sponsored landlord-tenant family child care protections; supports strong fair housing enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored Maryland Medical Assistance (Medicaid) maternal health pilot program; sponsored palliative care required coverage (Edna Neal Act); sponsored behavioral health AI oversight; supports expanded healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sponsored Municipalities - Vagrancy - Repeal of Authority to Prohibit (2026); opposes criminalization of homelessness; strongly supports services-first approach over enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored youth delinquency prevention fund; sponsored mental health and brain health legislation; opposes vagrancy enforcement; supports community investment and mental health as public safety tools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored Maryland Broadband Opportunity and Fairness Act; sponsored property tax credits; supports targeted public investment and digital equity initiatives.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jamila J. Woods / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('916afe40-4061-476f-9a54-b271b32778d2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored Real Property - Landlord and Tenant - Family Child Care Homes protections (2026); supports family childcare providers and access to childcare services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Per-candidate row count (every candidate must have >= 10 topics):
-- SELECT p.full_name, COUNT(pa.topic_id) AS topic_count
-- FROM essentials.politicians p
-- LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
-- WHERE p.id IN ('590b56b2-1473-4e86-ba96-0490e172f6ff', '251a2047-372b-480e-aa09-231f9a5edeca', '00cd05cc-75de-4d9a-ab23-9f53441bc186', '4436b432-a63f-4946-919a-f30c41f899e4', 'd8eee978-cec3-492d-9867-9d40b2a50a9d', '5c24446e-c9d6-4dda-9703-e3c049798315', '1da26040-98b4-4eb0-aa1f-3ec05b297a29', 'b8e331fa-d58e-479f-b076-8fda0b0604c5', '9273ed81-2052-428a-b39d-849abeef270b', '2e809682-2d95-480c-885e-d2174b811cfe', '8fab5ff7-603d-4ab0-a05c-a7070d187a48', 'd61a670a-7626-4464-93dc-c1e21d7b26da', '338210ee-b9ab-4820-bfce-98f5354837af', 'd5999df9-83b8-4870-a170-4d13f40473e2', 'cd422f8c-913b-4280-987b-9383ead34e85', '7a76712a-38cd-41de-b260-cd0127284f16', '768ac1cf-a599-4ddb-943c-c985fafb2607', '916afe40-4061-476f-9a54-b271b32778d2', '0e238dbf-5b4e-4e95-8a94-e02d97a136f5', '70f63959-f51d-4411-adc1-f1c429bbc397', '71542618-59c8-4b06-a765-e3df60cca763')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('590b56b2-1473-4e86-ba96-0490e172f6ff', '251a2047-372b-480e-aa09-231f9a5edeca', '00cd05cc-75de-4d9a-ab23-9f53441bc186', '4436b432-a63f-4946-919a-f30c41f899e4', 'd8eee978-cec3-492d-9867-9d40b2a50a9d', '5c24446e-c9d6-4dda-9703-e3c049798315', '1da26040-98b4-4eb0-aa1f-3ec05b297a29', 'b8e331fa-d58e-479f-b076-8fda0b0604c5', '9273ed81-2052-428a-b39d-849abeef270b', '2e809682-2d95-480c-885e-d2174b811cfe', '8fab5ff7-603d-4ab0-a05c-a7070d187a48', 'd61a670a-7626-4464-93dc-c1e21d7b26da', '338210ee-b9ab-4820-bfce-98f5354837af', 'd5999df9-83b8-4870-a170-4d13f40473e2', 'cd422f8c-913b-4280-987b-9383ead34e85', '7a76712a-38cd-41de-b260-cd0127284f16', '768ac1cf-a599-4ddb-943c-c985fafb2607', '916afe40-4061-476f-9a54-b271b32778d2', '0e238dbf-5b4e-4e95-8a94-e02d97a136f5', '70f63959-f51d-4411-adc1-f1c429bbc397', '71542618-59c8-4b06-a765-e3df60cca763')
--   AND pc.politician_id IS NULL;