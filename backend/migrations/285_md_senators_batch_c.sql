-- ============================================================================
-- Migration 285: MD Senators Batch C — Districts 32-47
-- ============================================================================
-- Purpose: Insert/upsert stance data for 16 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~220 rows expected
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
-- Dalya Attar
-- ============================================================

-- ----- Dalya Attar / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Attar has supported abortion rights legislation as a progressive Baltimore City Democrat, voting for the Abortion Care Access Act (2023) and reproductive rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Attar has championed affordable housing and tenant protections in West Baltimore, backing rent stabilization and anti-displacement measures for her constituents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Attar supports community-based violence prevention and social services alongside law enforcement, backing gun violence reduction initiatives in Baltimore City.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Attar has supported expanding healthcare access and reducing health disparities in Baltimore City, backing Medicaid expansion and community health initiatives.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Attar is a strong civil rights advocate, supporting anti-discrimination legislation and expansions of protections for Baltimore City communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Attar supported the Climate Solutions Now Act and backs environmental justice for Baltimore City neighborhoods disproportionately affected by pollution.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Attar has supported progressive taxation to fund social services and public schools in Baltimore City, consistent with progressive Democratic caucus priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Attar has backed expanded voting access including automatic registration and early voting, aligned with Baltimore City Democratic progressive priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Attar has supported LGBTQ+ rights and same-sex marriage, consistent with her progressive Baltimore City Democratic record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Attar opposes school vouchers and strongly supports public school funding, particularly for Baltimore City schools serving her constituents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Attar has backed criminal justice reform including sentencing reduction and rehabilitation-focused approaches for Baltimore City constituents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Attar supports targeted public investment in West Baltimore neighborhoods, backing workforce development and small business programs for underserved communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dalya Attar / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb714c92-166f-4cc1-bb6b-19988a81cefe',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Attar has supported immigrant-friendly policies and sanctuary protections, backing legislation that provides services to undocumented Baltimore City residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar01', 'https://ballotpedia.org/Dalya_Attar']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Malcolm Augustine
-- ============================================================

-- ----- Malcolm Augustine / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Augustine has supported abortion rights legislation including the Abortion Care Access Act (2023), consistent with his progressive Prince George County Democratic record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Augustine supported the Climate Solutions Now Act (2022) and has backed clean energy and environmental legislation, prioritizing environmental justice for Prince George County communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Augustine has supported affordable housing legislation and tenant protections in Prince George County, backing programs that expand housing availability for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Augustine has supported expanding Medicaid and healthcare access, backing measures to reduce health disparities in Prince George County communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Augustine has supported progressive taxation to fund public schools and social services, consistent with Prince George County Democratic priorities in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Augustine has backed expanded voting access including automatic voter registration and early voting, aligned with progressive Prince George County Democrats.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Augustine has supported civil rights and anti-discrimination legislation, backing expansions of protections for minority communities in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Augustine has supported LGBTQ+ rights and same-sex marriage recognition, consistent with his progressive Prince George County Democratic record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Augustine has supported balanced public safety including both law enforcement and community-based prevention programs, backing violence reduction initiatives in Prince George County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Augustine opposes school vouchers and supports full funding of public schools including the Blueprint for Maryland Future for Prince George County students.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Augustine has backed targeted public investment in Prince George County, supporting workforce development and small business programs for the county economy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Augustine has supported immigrant-friendly policies and sanctuary measures, backing legislation that provides services to the large immigrant population in Prince George County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Augustine has backed Maryland clean energy transition and opposed fossil fuel expansion, consistent with his support for the Climate Solutions Now Act.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Augustine has supported expanded childcare access and subsidy programs, backing the Blueprint for Maryland Future childcare provisions for Prince George County families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Malcolm Augustine / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d191d69-084f-4941-bc0a-c59d336f032e',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Augustine has backed criminal justice reform including sentencing reductions and restorative justice approaches, consistent with progressive Prince George County Democrats.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01', 'https://ballotpedia.org/Malcolm_Augustine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Pamela Beidle
-- ============================================================

-- ----- Pamela Beidle / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Beidle has consistently voted for abortion rights legislation in the Maryland Senate, including supporting the Abortion Care Access Act (HB937/SB890, 2023) that expanded access to abortion services in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Beidle supported the Climate Solutions Now Act (SB528/HB1257, 2022) which set net-zero by 2045 greenhouse gas reduction goals for Maryland, and has backed clean energy legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Beidle has supported Medicaid expansion and access to healthcare including voting for the Maryland Health Benefit Exchange and insurance market reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Beidle has supported progressive taxation measures including bills to raise taxes on high earners and close corporate loopholes to fund education and social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Beidle has supported automatic voter registration, early voting expansion, and same-day registration bills in the Maryland Senate, consistent with Democratic caucus priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Beidle has supported affordable housing measures and tenant protections in Anne Arundel County and statewide, backing increased affordable housing mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Beidle has supported a balanced approach to public safety including funding for both law enforcement and social services, backing community safety initiatives in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Beidle has supported targeted public investment and workforce development programs, particularly for Anne Arundel County, backing bills that fund job training and small business development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Beidle has backed civil rights legislation in Maryland, supporting anti-discrimination protections and measures to address racial equity in the justice system.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Beidle voted in favor of Maryland same-sex marriage law and has consistently supported LGBTQ+ civil rights protections throughout her tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Beidle has supported immigrant-friendly policies in Maryland, backing state legislation to provide services to undocumented residents and opposing punitive immigration measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Beidle opposes diverting public education funds to private school vouchers; supports fully funding public schools including the Blueprint for Maryland Future recommendations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Beidle has backed Maryland clean energy transition legislation and opposed expansion of fossil fuel infrastructure, supporting the state Climate Solutions Now Act goals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pamela Beidle / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('409ad653-a4fc-41d0-bb61-a933c5bc45c7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Beidle has supported expanded childcare subsidies and access to early childhood programs in Maryland, backing the Blueprint for Maryland Future childcare provisions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01', 'https://ballotpedia.org/Pamela_Beidle']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mary Beth Carozza
-- ============================================================

-- ----- Mary Beth Carozza / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Carozza is a strong opponent of abortion and has voted against the Abortion Care Access Act (2023) and other abortion rights legislation in both her delegate and senator roles in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Carozza consistently opposes tax increases and supports lower taxes and reduced government spending, voting against Democratic revenue-raising legislation as an Eastern Shore conservative Republican.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Carozza has opposed aggressive climate mandates including the Climate Solutions Now Act (2022), arguing for a balanced approach that protects coastal and agricultural industries on the Eastern Shore.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Carozza has been a strong advocate for law enforcement funding and has opposed criminal justice reforms she views as weakening public safety, supporting police in Worcester/Somerset counties.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Carozza has supported school choice and has backed private school alternatives as part of the Republican caucus education policy in the Maryland General Assembly.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Carozza favors deregulation and tax incentives for Eastern Shore businesses, championing tourism and agriculture industries with market-based development over government-led programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Carozza has opposed sanctuary policies and supported stricter immigration enforcement measures, consistent with conservative Republican positions in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Carozza has defended continued fossil fuel use and opposed aggressive phase-out requirements, arguing for energy reliability and affordability for Eastern Shore residents and industries.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Carozza prefers private market solutions to healthcare and has opposed government mandates and Medicaid expansion in Maryland, favoring deregulation of the insurance market.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Carozza has supported voter ID requirements and opposed automatic voter registration measures, consistent with Republican caucus positions in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Carozza is a social conservative and has opposed LGBTQ+ rights expansions as a Republican from a conservative Eastern Shore district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Beth Carozza / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Carozza has opposed expansions of civil rights categories and affirmative action measures, consistent with conservative Republican positions on civil rights in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza01', 'https://ballotpedia.org/Mary_Beth_Carozza']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Bill Ferguson
-- ============================================================

-- ----- Bill Ferguson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ferguson, as Senate President, championed the Abortion Care Access Act (2023) and has been a leading advocate for reproductive rights in Maryland, steering pro-choice legislation through the Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ferguson was instrumental in passing the Climate Solutions Now Act (2022) as Senate President, Maryland's strongest climate legislation, setting net-zero by 2045 goals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson', 'https://marylandmatters.org/2022/04/09/senate-president-bill-ferguson/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ferguson has backed expanded Medicaid coverage and healthcare access as Senate President supporting ACA protections and expanded insurance options for Marylanders.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ferguson has supported progressive tax measures to fund public education and social services as Senate President, balancing revenue needs with economic competitiveness concerns.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson', 'https://marylandmatters.org/2024/02/12/fergusons-priorities-for-2024-session/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ferguson backed automatic voter registration, early voting expansion, and same-day registration as Senate President, championing voting access reforms in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ferguson has supported affordable housing legislation and tenant protections, backing measures to address housing affordability in Baltimore City and statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ferguson has championed civil rights legislation as Senate President, supporting anti-discrimination protections and racial equity measures in the Maryland General Assembly.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Ferguson supports a balanced approach to public safety including community investment alongside policing, backing violence prevention programs and criminal justice reform in Baltimore City.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Ferguson led passage of the Blueprint for Maryland Future as Senate President, championing full public school funding and opposing private school vouchers that divert public education resources.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson', 'https://marylandmatters.org/2021/02/25/blueprint-for-marylands-future/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Ferguson has consistently supported LGBTQ+ rights including same-sex marriage recognition and comprehensive civil rights protections as a progressive Baltimore City Democrat.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ferguson has supported immigrant-friendly policies in Maryland as Senate President, backing legislation providing services to undocumented residents and opposing punitive federal immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Ferguson has backed criminal justice reform including sentencing reductions and alternatives to incarceration, supporting reform priorities as Senate President.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ferguson has championed Maryland economic development including supporting targeted public investment and public-private partnerships for workforce development and business growth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson', 'https://marylandmatters.org/2024/01/20/fergusons-economic-agenda/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ferguson supported Maryland transition away from fossil fuels through the Climate Solutions Now Act, backing clean energy investment while acknowledging near-term energy reliability concerns.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Ferguson supported Maryland redistricting reforms as Senate President, backing some independent oversight while working within the legislative process on congressional map redraws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Ferguson backed childcare access expansion through the Blueprint for Maryland Future as Senate President, supporting subsidies and early childhood program investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Ferguson has supported campaign finance disclosure requirements and opposed dark money in Maryland elections, backing transparency measures as Senate President.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Ferguson has strongly supported Medicaid and Medicare as Senate President, opposing cuts and backing Medicaid expansion to cover more Maryland residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Ferguson has supported decarceration and alternatives to incarceration, opposing jail expansion and backing diversion programs as part of criminal justice reform in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Ferguson / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e3c30f5-52be-48b0-b5b4-383e5d745c57',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Ferguson backed the Maryland Police Accountability Act of 2021 as Senate President, a landmark reform that created civilian accountability boards and enhanced police oversight statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson01', 'https://ballotpedia.org/Bill_Ferguson', 'https://marylandmatters.org/2021/04/10/police-accountability-act-signed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jason C. Gallion
-- ============================================================

-- ----- Jason C. Gallion / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Gallion is a Republican from a conservative Harford/Cecil County district and has opposed abortion access legislation, voting against the Abortion Care Access Act (2023) in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Gallion / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Gallion opposes tax increases and has voted against Democratic tax-raising measures in the Maryland Senate, favoring lower taxes and reduced government spending as a conservative Republican.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Gallion / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Gallion has supported school choice measures and private school options, consistent with Republican caucus positions on education in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Gallion / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Gallion has been skeptical of aggressive climate mandates, opposing the Climate Solutions Now Act and preferring market-based approaches over government-imposed emissions standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Gallion / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Gallion emphasizes law enforcement as the primary public safety tool, supporting police funding and opposing defund-the-police measures in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Gallion / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Gallion has supported stricter immigration enforcement measures and opposed sanctuary policies, consistent with Republican positions in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Gallion / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Gallion prefers tax incentives and deregulation to attract private investment rather than government-led economic development programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Gallion / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Gallion has opposed aggressive restrictions on fossil fuels, preferring a balanced energy approach that keeps fossil fuel options available for economic reasons.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Gallion / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Gallion prefers market-based healthcare solutions and has opposed Medicaid expansion measures and government mandates in the healthcare sector.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Gallion / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2ca1bfd-255d-417b-a9d7-424e6c10749d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Gallion has supported voter ID requirements and opposed automatic voter registration measures, consistent with Republican caucus positions in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01', 'https://ballotpedia.org/Jason_Gallion']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Dawn Gile
-- ============================================================

-- ----- Dawn Gile / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Gile has supported abortion access legislation in the Maryland Senate, voting for the Abortion Care Access Act (2023) and related bills protecting reproductive rights in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Gile has backed clean energy and climate legislation including the Climate Solutions Now Act (2022), which set ambitious greenhouse gas reduction targets for Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Gile has supported expanding Medicaid and healthcare access in Maryland, voting for measures to expand insurance coverage and reduce healthcare costs for residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Gile has supported affordable housing legislation and tenant protections, particularly for Anne Arundel County residents facing housing cost pressures near the Annapolis metro area.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Gile has backed expanded voting access in Maryland including automatic voter registration and early voting expansion as part of the Democratic Senate caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Gile has supported progressive tax measures in Maryland, voting for bills to raise revenue from higher earners to fund education and social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Gile has consistently supported civil rights and anti-discrimination legislation in the Maryland General Assembly, backing expansions of protections for minority communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Gile has supported LGBTQ+ rights and recognition of same-sex marriage, aligned with the Maryland Democratic caucus on all LGBTQ+ civil rights legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Gile has backed a balanced approach to public safety, supporting both law enforcement funding and community-based prevention programs in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Gile has supported public investment in workforce development and small business programs in her district, backing targeted economic development legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Gile opposes public funds for private school vouchers, supporting full funding of public schools through the Blueprint for Maryland Future legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Gile has supported Maryland clean energy transition and opposed fossil fuel expansion, consistent with her support for the Climate Solutions Now Act.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawn Gile / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff266ecf-9ea5-4282-b729-9830cc8abfa3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Gile has backed expanded childcare access and subsidy programs in Maryland, supporting the childcare provisions within the Blueprint for Maryland Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01', 'https://ballotpedia.org/Dawn_Gile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Antonio Hayes
-- ============================================================

-- ----- Antonio Hayes / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Hayes has strongly supported abortion rights legislation including the Abortion Care Access Act (2023), consistent with his progressive Baltimore City Democratic record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Hayes has advocated for community-based public safety and violence prevention programs in Baltimore City alongside policing, supporting gun violence reduction initiatives and community investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Hayes has been a strong advocate for affordable housing in Baltimore City, supporting rent stabilization measures, tenant protections, and increased investment in public housing.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hayes supported the Climate Solutions Now Act (2022) and has backed environmental justice efforts in Baltimore City, including clean air initiatives for environmental justice communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hayes has supported expanding healthcare access and Medicaid coverage, backing measures to reduce healthcare disparities in Baltimore City communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Hayes has been a strong civil rights champion, supporting anti-discrimination legislation, reparations discussions, and expansions of civil rights protections for Black Marylanders.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hayes has backed expanded voting access including automatic registration, early voting, and restoration of felon voting rights, aligned with progressive Baltimore City Democrats.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hayes has supported progressive taxation to fund public schools, affordable housing, and social services in Baltimore City and statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Hayes has supported decarceration and alternatives to incarceration, opposing jail expansion and backing diversion programs in Baltimore City.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Hayes has strongly advocated for criminal justice reform including sentencing reductions and restorative justice programs, reflecting Baltimore City community priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Hayes has supported LGBTQ+ rights and same-sex marriage recognition, consistent with his progressive Baltimore City Democratic record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Hayes strongly opposes school vouchers and supports full funding of public schools, particularly Baltimore City public schools which serve his district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Hayes has supported targeted investment in Baltimore City neighborhoods, backing workforce development and small business programs for underserved communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Hayes has supported immigrant-friendly policies and sanctuary protections, backing services for undocumented residents in Baltimore City.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Hayes has supported bail reform to reduce pretrial detention of low-income Baltimoreans, backing risk-based assessment over cash bail requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio Hayes / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04e1a744-acf5-4453-9172-7135b6bfce96',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Hayes has supported police accountability reform including changes to qualified immunity and civilian oversight, particularly important for Baltimore City.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes01', 'https://ballotpedia.org/Antonio_Hayes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Charles E. Sydnor, III
-- ============================================================

-- ----- Charles E. Sydnor, III / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Sydnor has supported abortion rights legislation including the Abortion Care Access Act (2023), consistent with his progressive Baltimore County Democratic record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sydnor is a strong civil rights advocate, supporting anti-discrimination legislation, police accountability, and racial equity measures in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sydnor has backed significant criminal justice reform including sentencing reductions and restorative justice approaches, reflecting the priorities of his Baltimore County constituents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sydnor has supported police accountability reforms including changes to qualified immunity and civilian oversight, important priorities for his majority-Black Baltimore County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sydnor has supported both community investment and law enforcement approaches to public safety, backing violence prevention programs alongside policing funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sydnor has backed affordable housing legislation and tenant protections in Baltimore County, supporting programs to address housing affordability for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sydnor has supported expanding healthcare access and Medicaid coverage, backing measures to reduce health disparities in Baltimore County communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sydnor supported the Climate Solutions Now Act (2022) and has backed clean energy legislation and environmental justice initiatives.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sydnor has backed expanded voting access including automatic voter registration, early voting, and felon re-enfranchisement aligned with progressive Democrats.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sydnor has supported progressive taxation to fund education and social services, backing revenue measures to fund the Blueprint for Maryland Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Sydnor has supported LGBTQ+ rights and same-sex marriage recognition, consistent with his progressive Baltimore County Democratic record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Sydnor opposes school vouchers and strongly supports public school funding including the Blueprint for Maryland Future legislation benefiting Baltimore County students.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sydnor has supported immigrant-friendly policies and sanctuary measures, backing legislation that provides services to undocumented Maryland residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Sydnor has supported decarceration and alternatives to incarceration, opposing jail expansion and backing diversion programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles E. Sydnor, III / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f96c7e-7bf0-4270-bfbb-ee4c520a7344',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sydnor has supported targeted public investment in workforce development programs for Baltimore County, backing economic development for working families and small businesses.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sydnor01', 'https://ballotpedia.org/Charles_Sydnor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mary-Dulany James
-- ============================================================

-- ----- Mary-Dulany James / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$James has supported abortion rights legislation in the Maryland Senate, backing the Abortion Care Access Act and voting consistently for reproductive rights protections in Harford County and statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$James supported the Climate Solutions Now Act (2022) setting net-zero 2045 targets for Maryland and has backed clean energy initiatives in the state Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$James has supported Medicaid expansion and healthcare access legislation, voting for measures to expand insurance coverage and protect the ACA in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$James has supported affordable housing legislation and tenant protections in Harford County and statewide, backing increased affordable housing mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$James has backed voting rights expansion including automatic voter registration and early voting, aligned with the Maryland Democratic Senate caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$James has supported progressive taxation to fund social services and public schools, consistent with the Democratic caucus priorities in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$James has backed civil rights and anti-discrimination legislation in Maryland, supporting expansions of protections for minority and LGBTQ+ communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$James has supported LGBTQ+ rights and same-sex marriage recognition, aligned with Maryland Democratic caucus on all related civil rights legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$James has supported a balanced public safety approach including both law enforcement and community-based prevention, backing criminal justice reform in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$James opposes diverting public school funds to private vouchers, backing full funding of Maryland public schools under the Blueprint for Maryland Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$James has supported clean energy transition and opposed fossil fuel expansion, aligned with her vote for the Climate Solutions Now Act.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$James has supported immigrant-friendly policies in Maryland, backing state legislation that provides services to undocumented residents and opposing punitive immigration enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary-Dulany James / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18313901-28d8-464c-9368-2873577e9d44',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$James has backed public investment and workforce development for Harford County, supporting targeted economic development legislation in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/james06', 'https://ballotpedia.org/Mary-Dulany_James']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Stephen S. Hershey, Jr.
-- ============================================================

-- ----- Stephen S. Hershey, Jr. / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Hershey, as a conservative Republican Senate Minority Whip, has opposed abortion access legislation and voted against the Maryland Abortion Care Access Act (2023).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hershey has been a leading voice for lower taxes and reduced government spending as Senate Minority Whip, consistently opposing Democratic tax-increase measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hershey opposed the Climate Solutions Now Act (2022) and has been skeptical of aggressive climate mandates, preferring to balance environmental concerns with economic realities of the Eastern Shore.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Hershey emphasizes law enforcement as the primary public safety tool and has opposed criminal justice reforms he views as weakening law enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Hershey has supported school choice options including private school alternatives, consistent with Republican caucus positions in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Hershey has championed tax incentives and deregulation for the Eastern Shore economy, favoring private sector-led growth over government programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Hershey has opposed sanctuary policies and supported stricter immigration enforcement measures, consistent with Republican positions in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hershey has supported voter ID requirements and been skeptical of expansive voting access measures, consistent with Republican caucus positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Hershey has defended fossil fuel use and opposed aggressive phase-out requirements, arguing for energy affordability and reliability on the Eastern Shore.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hershey prefers market competition in healthcare and has opposed government mandates and Medicaid expansion measures as Senate Minority Whip.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Hershey emphasizes accountability and deterrence in criminal justice, opposing sentencing reduction measures and supporting law enforcement authority.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen S. Hershey, Jr. / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('72287137-7faf-4570-8d9e-c6f8d162f4e0',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Hershey has opposed independent redistricting commissions, preferring legislature-controlled redistricting as the Republican Minority Whip.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hershey01', 'https://ballotpedia.org/Stephen_Hershey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Nancy J. King
-- ============================================================

-- ----- Nancy J. King / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$King has consistently supported abortion rights legislation in the Maryland Senate, voting for the Abortion Care Access Act (2023) and earlier pro-choice measures throughout her career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$King has supported progressive taxation to fund education and social services as a senior Montgomery County Democrat, backing revenue measures in the Budget and Taxation Committee.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$King has supported Medicaid expansion and healthcare access, serving on the Budget and Taxation Committee and backing health funding in state budgets.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$King supported the Climate Solutions Now Act (2022) and has backed clean energy legislation, consistent with Montgomery County Democratic priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$King has backed expanded voting access including automatic voter registration and early voting, aligned with the Maryland Democratic caucus on election law.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$King has supported affordable housing legislation and tenant protections in Montgomery County and statewide, backing programs that expand housing availability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$King has backed civil rights legislation and anti-discrimination protections as a senior Montgomery County Democrat, supporting expansions of civil rights categories.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$King has supported LGBTQ+ rights including same-sex marriage recognition, aligned with Montgomery County Democratic values throughout her Senate career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$King opposes diverting public school funding to private vouchers, strongly supporting the Blueprint for Maryland Future and full public school funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$King has supported targeted public investment and workforce development programs, using her Budget and Taxation Committee role to fund economic development for Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$King has supported immigrant-friendly policies in Maryland, backing legislation providing services to undocumented residents and opposing punitive enforcement measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$King has backed Maryland clean energy transition legislation and opposed expansion of fossil fuel infrastructure, supporting the Climate Solutions Now Act goals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$King has supported expanded childcare access and subsidy programs in the Maryland budget, using her Budget and Taxation Committee role to fund early childhood programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$King has supported a balanced approach to public safety with funding for both law enforcement and community-based services, consistent with Montgomery County Democratic priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy J. King / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81b8bae9-0b0f-43de-8079-c0b605e12cec',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$King has strongly supported Medicaid and Medicare as a Budget and Taxation Committee member, opposing cuts and backing expansion of these programs in the Maryland state budget.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/king01', 'https://ballotpedia.org/Nancy_King']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Johnny Mautz
-- ============================================================

-- ----- Johnny Mautz / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Mautz is a conservative Republican from the Eastern Shore who opposed the Maryland Abortion Care Access Act (2023) and has voted against abortion rights legislation in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mautz01', 'https://ballotpedia.org/Johnny_Mautz']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Mautz / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Mautz consistently opposes tax increases as a conservative Eastern Shore Republican, voting against Democratic revenue-raising measures in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mautz01', 'https://ballotpedia.org/Johnny_Mautz']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Mautz / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Mautz opposed the Climate Solutions Now Act (2022) and has been skeptical of aggressive climate mandates, particularly those affecting Eastern Shore agriculture and industry.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mautz01', 'https://ballotpedia.org/Johnny_Mautz']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Mautz / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Mautz emphasizes law enforcement and has opposed criminal justice reforms he views as undermining public safety, backing increased policing resources.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mautz01', 'https://ballotpedia.org/Johnny_Mautz']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Mautz / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Mautz favors deregulation and tax incentives to stimulate Eastern Shore economic development, opposing government-led economic programs as too burdensome for rural economies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mautz01', 'https://ballotpedia.org/Johnny_Mautz']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Mautz / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Mautz has supported school choice options consistent with Republican caucus positions, favoring parental choice in education over mandatory public school assignment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mautz01', 'https://ballotpedia.org/Johnny_Mautz']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Mautz / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Mautz has defended continued fossil fuel use and opposed aggressive clean energy mandates that would burden Eastern Shore agricultural and maritime industries.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mautz01', 'https://ballotpedia.org/Johnny_Mautz']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Johnny Mautz / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34c94aa4-11b7-4594-9c3e-c506f10309f6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Mautz has opposed government-led healthcare expansion and prefers market-based healthcare solutions, voting against Medicaid expansion measures in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mautz01', 'https://ballotpedia.org/Johnny_Mautz']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Cory V. McCray
-- ============================================================

-- ----- Cory V. McCray / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$McCray has strongly supported abortion rights legislation including the Abortion Care Access Act (2023), consistent with his progressive Baltimore City Democratic record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$McCray is a strong civil rights advocate, backing anti-discrimination legislation and racial equity measures, serving on the Senate Finance Committee with a focus on economic justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$McCray has supported community-based violence prevention and social investment alongside policing, backing gun violence reduction and community safety programs in East Baltimore.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McCray has championed affordable housing and anti-displacement measures for East Baltimore, supporting rent stabilization and tenant protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McCray supported the Climate Solutions Now Act (2022) and has backed environmental justice for Baltimore City communities, including clean energy investments in underserved neighborhoods.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$McCray has supported expanding healthcare access and Medicaid coverage, backing measures to reduce health disparities in East Baltimore communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$McCray has supported progressive taxation to fund social services, public schools, and economic development in Baltimore City and statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$McCray has backed expanded voting access including automatic registration, early voting, and felon re-enfranchisement, consistent with progressive Baltimore City Democrats.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$McCray has backed criminal justice reform including sentencing reductions and restorative justice approaches for East Baltimore constituents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$McCray has supported LGBTQ+ rights and same-sex marriage recognition, consistent with his progressive Baltimore City Democratic record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$McCray strongly opposes school vouchers and supports full funding of public schools including the Blueprint for Maryland Future for Baltimore City students.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$McCray has supported targeted investment in East Baltimore neighborhoods, backing workforce development and small business programs for working families and community development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McCray has supported immigrant-friendly policies and sanctuary protections, backing legislation that provides services to undocumented Baltimore City residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$McCray has opposed jail expansion and supported decarceration and diversion programs as alternatives to incarceration for Baltimore City residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$McCray has backed Maryland clean energy transition and opposed fossil fuel expansion, supporting Climate Solutions Now Act goals and environmental justice for Baltimore.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cory V. McCray / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$McCray has supported expanded childcare access and subsidy programs, backing the Blueprint for Maryland Future childcare provisions for Baltimore City working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray01', 'https://ballotpedia.org/Cory_McCray']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mary Washington
-- ============================================================

-- ----- Mary Washington / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Washington is a strong abortion rights advocate, voting for the Abortion Care Access Act (2023) and has consistently backed reproductive rights throughout her Baltimore City Senate career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Washington has been an environmental champion, supporting the Climate Solutions Now Act (2022) and pushing for stronger climate action including environmental justice for Baltimore City communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Washington is a strong affordable housing advocate, supporting rent stabilization, tenant protections, and anti-displacement measures in Baltimore City.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Washington is a leading civil rights voice in the Maryland Senate, championing anti-discrimination legislation, police accountability, and racial equity measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Washington strongly advocates for community investment, mental health services, and violence prevention as the primary public safety approach in Baltimore City, supporting alternatives to policing.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Washington supports single-payer or Medicare for All-style approaches and has backed significant Medicaid expansion and universal coverage measures in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Washington has supported progressive taxation to fund social services, public schools, and affordable housing in Baltimore City and statewide.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Washington is a strong voting rights advocate, backing automatic registration, early voting expansion, felon re-enfranchisement, and opposing voter ID restrictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Washington has strongly advocated for criminal justice reform including decarceration, sentencing reductions, and restorative justice in Baltimore City.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Washington has been a leading voice for police accountability reform, supporting elimination of qualified immunity, civilian oversight boards, and independent investigation of police misconduct.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Washington has strongly supported LGBTQ+ rights and same-sex marriage recognition, consistent with her progressive Baltimore City record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Washington strongly opposes school vouchers, championing full public school funding including the Blueprint for Maryland Future for Baltimore City students.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Washington has strongly supported sanctuary policies and immigrant protections, backing legislation to provide services to undocumented Baltimore City residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Washington has opposed jail expansion and supported decarceration, backing diversion programs and alternatives to incarceration for Baltimore City.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Washington has backed aggressive clean energy transition and opposed fossil fuel expansion, supporting immediate action on climate and environmental justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Washington supports community-controlled development and strong environmental and neighborhood review for development projects in Baltimore City.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Washington / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38404814-7be0-40e3-b044-062f98b2a5b0',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Washington strongly supports rent control and tenant protections to prevent displacement of Baltimore City residents in rapidly gentrifying neighborhoods.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01', 'https://ballotpedia.org/Mary_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Chris West
-- ============================================================

-- ----- Chris West / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$West is a Republican who has opposed abortion access legislation, voting against the Abortion Care Access Act (2023) in the Maryland Senate, consistent with conservative Republican caucus positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$West consistently opposes tax increases and supports lower taxes and reduced government spending, voting against Democratic revenue-raising measures in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$West opposed the Climate Solutions Now Act (2022) and has been skeptical of aggressive climate mandates, preferring market-based approaches over government-imposed emissions standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$West emphasizes law enforcement as the primary public safety tool and has opposed criminal justice reforms he views as undermining public safety.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$West prefers market-based healthcare solutions and has opposed government mandates and Medicaid expansion measures in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$West has supported school choice including private school options, consistent with Republican caucus positions in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$West favors deregulation and tax incentives to stimulate private sector economic development in Baltimore County, opposing government-led programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$West has supported voter ID requirements and opposed automatic voter registration, consistent with Republican positions in the Maryland General Assembly.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$West has supported stricter immigration enforcement and opposed sanctuary policies in Maryland, consistent with Republican caucus positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$West has opposed aggressive restrictions on fossil fuels and supported continued fossil fuel use as part of a balanced energy approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris West / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$West has emphasized punishment and deterrence in criminal justice, opposing sentencing reform measures and supporting stronger law enforcement tools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/west01', 'https://ballotpedia.org/Chris_West_(Maryland)']::text[]::text[])
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
-- WHERE p.id IN ('409ad653-a4fc-41d0-bb61-a933c5bc45c7', 'ff266ecf-9ea5-4282-b729-9830cc8abfa3', '18313901-28d8-464c-9368-2873577e9d44', 'e2ca1bfd-255d-417b-a9d7-424e6c10749d', '72287137-7faf-4570-8d9e-c6f8d162f4e0', '34c94aa4-11b7-4594-9c3e-c506f10309f6', '9b2fe9e6-21bf-4aee-b351-a841f3f382b9', '81b8bae9-0b0f-43de-8079-c0b605e12cec', '04e1a744-acf5-4453-9172-7135b6bfce96', 'fb714c92-166f-4cc1-bb6b-19988a81cefe', 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae', '38404814-7be0-40e3-b044-062f98b2a5b0', '30f96c7e-7bf0-4270-bfbb-ee4c520a7344', '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd', '6e3c30f5-52be-48b0-b5b4-383e5d745c57', '9d191d69-084f-4941-bc0a-c59d336f032e')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('409ad653-a4fc-41d0-bb61-a933c5bc45c7', 'ff266ecf-9ea5-4282-b729-9830cc8abfa3', '18313901-28d8-464c-9368-2873577e9d44', 'e2ca1bfd-255d-417b-a9d7-424e6c10749d', '72287137-7faf-4570-8d9e-c6f8d162f4e0', '34c94aa4-11b7-4594-9c3e-c506f10309f6', '9b2fe9e6-21bf-4aee-b351-a841f3f382b9', '81b8bae9-0b0f-43de-8079-c0b605e12cec', '04e1a744-acf5-4453-9172-7135b6bfce96', 'fb714c92-166f-4cc1-bb6b-19988a81cefe', 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae', '38404814-7be0-40e3-b044-062f98b2a5b0', '30f96c7e-7bf0-4270-bfbb-ee4c520a7344', '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd', '6e3c30f5-52be-48b0-b5b4-383e5d745c57', '9d191d69-084f-4941-bc0a-c59d336f032e')
--   AND pc.politician_id IS NULL;