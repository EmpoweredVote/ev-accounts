-- ============================================================================
-- Migration 288: MD Delegates Batch C — Districts 14-20
-- ============================================================================
-- Purpose: Insert/upsert stance data for 21 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~301 rows expected
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
-- Julie Palakovich Carr
-- ============================================================

-- ----- Julie Palakovich Carr / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sponsored/co-sponsored HB1057 (Education - Artificial Intelligence - Guidelines, Professional Development, and Collaborative (Artificial Intelligence Ready Schools Act)) on algorithmic/automated systems regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1057?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0561 (Maryland Child Care Credential Program - Extension of Funding) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0561?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB0572 (Attorney General Actions and Climate Crimes Accountability Fund (Climate Crimes Accountability Act)) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0572?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB1124 (Commercial Law - Consumer Protections - Health Care Financing) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1124?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sponsored/co-sponsored HB0818 (Higher Education - Foster Care Recipients and Homeless Youth - Tuition Exemption and Associated Benefits) supporting housing-first homelessness solutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0818?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0434 (Residential Leases - Use of Algorithmic Device by Landlord to Determine Rent, Occupancy, and Lease Terms - Prohibition) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0434?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0935 (Correctional Services - Comprehensive Rehabilitative Prerelease Services - Female Incarcerated Individuals) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0935?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0155 (Public Safety - Law Enforcement Officers - Prohibition on Face Coverings) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0155?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB1131 (Public Health - Pregnancy Loss - Prohibited Actions (Pregnancy Outcome Protection Act)) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1131?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB0553 (Public Safety - Elevator Inspection Certificates - Searchable Database) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0553?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0363 (Local Government - Grant for Recipients of State Child Tax Credit - Authorization) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0363?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Palakovich Carr / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70d58d4b-4203-4fc2-b36f-32e6231c4339',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0157 (Election Law - Campaign Finance - Exploratory Committees) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0157?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/palakovich01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Lorig Charkoudian
-- ============================================================

-- ----- Lorig Charkoudian / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored/co-sponsored HB0465 (Civil Actions - Immunity - Disclosure of Allegations of Sexually Assaultive Behavior (Stop Silencing Survivors Act)) supporting campaign finance reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored/co-sponsored HB0332 (Civil Actions - Violation of Constitutional Rights (No Kings Act)) advancing civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0332?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB0345 (Public Utilities - Solar Energy Generating Systems and Solar Renewable Energy Credits (Affordable Solar Act)) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0188 (Unemployment Insurance Modernization Act of 2026) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0188?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0085 (Corporations and Associations - Cooperative Limited Equity Housing Corporations - Establishment) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0085?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0429 (On-Farm Organics Diversion and Recycling Grant Program - Established) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0429?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0155 (Public Safety - Law Enforcement Officers - Prohibition on Face Coverings) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0155?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB0220 (Environment - Water - Individual Submeters) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0220?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB0410 (Public Health - Food Labeling - Requirements) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0410?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Sponsored/co-sponsored HB0149 (Fire Prevention - Assistant Fire Marshals, Residential Rental High-Rise Property Fire Safety Equipment, and Fire Alarm System Technicians) supporting rent regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0149?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lorig Charkoudian / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0484 (Corporate Income Tax - Addition Modification - Direct-to-Consumer Pharmaceutical Advertising) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0484?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/charkoudian01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Charlotte Crutchfield
-- ============================================================

-- ----- Charlotte Crutchfield / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored/co-sponsored HB0465 (Civil Actions - Immunity - Disclosure of Allegations of Sexually Assaultive Behavior (Stop Silencing Survivors Act)) supporting campaign finance reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0396 (Residential Child Care Programs - Education of Children and Training of Child and Youth Care Practitioners) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0396?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored/co-sponsored HB0884 (University of Maryland Eastern Shore - Land-Grant Institution - Funding (Land-Grant Equity and Accountability Act)) advancing civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0884?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0890 (Family Law - Child Abuse and Neglect Investigations (&quot;Know Before They Knock&quot; Family Right to Notice Act)) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0890?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB1205 (Education - Minimum Wage for Education Support Professionals) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1205?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB1118 (Health, Health Insurance, and Health Occupations - Perinatal Behavioral Health Conditions) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1118?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sponsored/co-sponsored HB1353 (Homeless Individuals - Fee and Examination Exemptions) supporting housing-first homelessness solutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1353?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0523 (Real Property - Residential Foreclosures - Commencement Restrictions) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0523?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0890 (Family Law - Child Abuse and Neglect Investigations (&quot;Know Before They Knock&quot; Family Right to Notice Act)) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0890?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Sponsored/co-sponsored HB0438 (Adult Prison School Board Model Development Committee) on correctional policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0438?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0935 (Correctional Services - Comprehensive Rehabilitative Prerelease Services - Female Incarcerated Individuals) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0935?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0155 (Public Safety - Law Enforcement Officers - Prohibition on Face Coverings) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0155?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB0941 (Public Health - Public Buildings - Hygiene Products) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0941?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Sponsored/co-sponsored HB0412 (Child Support - Suspension of Driver's Licenses) supporting retirement/Social Security.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0412?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0761 (Income Tax - Subtraction Modification for Military Retirement Income (Keep Our Heroes Home Act)) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0761?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charlotte Crutchfield / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98d6a17e-59dc-4d11-a342-869603862f10',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0115 (Election Law - Individuals Released From State Correctional Facilities - Automatic Restoration of Voter Registration) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0115?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/crutchfield01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Bonnie Cullison
-- ============================================================

-- ----- Bonnie Cullison / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored/co-sponsored HB0442 (Professional Liability Insurance Coverage - Nursing Homes, Assisted Living Facilities, Nurse Midwives, and Licensed Certified Midwives - Disclosure (Nyeli Rose Lewis Act of 2026)) supporting campaign finance reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0442?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0954 (State Finance and Procurement - Retention Proceeds) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0954?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB0498 (Certificate of Need - Intermediate Health Care Facilities) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0498?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0935 (Correctional Services - Comprehensive Rehabilitative Prerelease Services - Female Incarcerated Individuals) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0935?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB1470 (Medical Assistance Programs - Drug Dispensing - Cost-of-Dispensing Survey) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1470?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB1181 (Family Law - Children in Out-of-Home Placement - Voluntary Placement Agreements) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1181?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Sponsored/co-sponsored HB0989 (State Assistance for the Elderly - Study on Calculation of Income) supporting retirement/Social Security.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0989?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '683c8084-2281-4920-a07c-18439b2dd413',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Sponsored/co-sponsored HB0413 (Maryland-Ireland Trade Commission - Membership and Termination - Altered and Extended) on federal trade/financial policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0413?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bonnie Cullison / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17c22fec-63a4-4f5d-8607-0c364ddffd71',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0484 (Corporate Income Tax - Addition Modification - Direct-to-Consumer Pharmaceutical Advertising) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0484?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cullison']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Linda Foley
-- ============================================================

-- ----- Linda Foley / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB0817 (Carbon Dioxide Capture, Removal, and Sequestration Projects - Regulations and Standards for Biochar and Wood Vault Technologies) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0817?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0010 (Legal Advertisement or Legal Notice - Publication in Newspaper or Newspaper in General Circulation - Digital Newspapers) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0010?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0461 (Economic Development - Rural Readiness Program and Rural Maryland Capacity Building Fund - Establishment) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0461?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB1435 (Health Insurance - Required Coverage - Hormone-Related Care) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1435?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0523 (Real Property - Residential Foreclosures - Commencement Restrictions) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0523?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0010 (Legal Advertisement or Legal Notice - Publication in Newspaper or Newspaper in General Circulation - Digital Newspapers) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0010?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0022 (Correctional Services - Incarcerated Individuals - Identification Cards, Driver's Licenses, and Birth Certificates) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0022?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0030 (Public Safety - Department of State Police - Police-Initiated Towing - Alterations) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0030?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB1071 (Environment - Stormwater Management for Agritourism) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1071?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB0105 (Public Health - Restaurants - Disclosure of Main Food Allergens) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0105?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB1221 (Public Safety - Short-Term Rental Units - Safety (Jillian and Lindsay Wiener Short-Term Rental Safety Act)) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1221?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Linda Foley / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b80a680a-9f79-4d56-994b-00ce24ec7ef3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0641 (Election Law - Curbside Voting - Pilot Program) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0641?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/foley01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- David Fraser-Hidalgo
-- ============================================================

-- ----- David Fraser-Hidalgo / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB1104 (Residential Solar Energy Systems - Local Inspections and Permitting) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1104?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB1356 (Labor and Employment - Civic and Related Activities - Protection (Maryland Employee Civic Activity and Lawful Expression Protection Act)) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1356?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB1135 (Health Occupations - Pharmacists - Vaccination Orders) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1135?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0523 (Real Property - Residential Foreclosures - Commencement Restrictions) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0523?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0935 (Correctional Services - Comprehensive Rehabilitative Prerelease Services - Female Incarcerated Individuals) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0935?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB0034 (Municipalities - Open Drainage Inlets - Inventory and Improvements (Mason's Law)) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0034?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB1445 (Maryland Medical Assistance Program and Developmental Disabilities Administration - Home- and Community-Based Services Eligibility Determinations (Maryland Protecting People With Disabilities Act)) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1445?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Fraser-Hidalgo / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab8aa19a-42c3-445e-9632-a5c7f05458ee',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0350 (Voting Rights Act of 2026 - Counties and Municipal Corporations) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fraser01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Anne R. Kaiser
-- ============================================================

-- ----- Anne R. Kaiser / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0539 (Child Care Centers - Teacher Qualifications - Alterations) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0539?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB1479 (Labor and Employment - Minimum Wage - Increase (Maryland Raise the Wage Act)) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1479?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB1377 (Prescription Drug Repository Program - Redirecting Safe Prescription Drugs Pilot Program) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1377?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sponsored/co-sponsored HB0818 (Higher Education - Foster Care Recipients and Homeless Youth - Tuition Exemption and Associated Benefits) supporting housing-first homelessness solutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0818?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0753 (Tax Sales - Homeowner Protections - Revisions) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0753?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0450 (Criminal Procedure - Protection of Identity of Victim of Sexual Assault or Stalking) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0450?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB1071 (Environment - Stormwater Management for Agritourism) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1071?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB1389 (Public Health - Female Genital Mutilation) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1389?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB1239 (Public Safety - Critical Infrastructure Protection) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1239?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB1148 (Property Taxes - Tax Sales, Legacy Protection Program, and Tax Credits) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1148?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anne R. Kaiser / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bfd0f15f-abb1-4d28-b1f4-e06875adce16',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0350 (Voting Rights Act of 2026 - Counties and Municipal Corporations) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaiser']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Aaron M. Kaufman
-- ============================================================

-- ----- Aaron M. Kaufman / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sponsored/co-sponsored HB0510 (Motor Vehicles - Automated Speed Enforcement - Improper Registration) on algorithmic/automated systems regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0510?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored/co-sponsored HB0442 (Professional Liability Insurance Coverage - Nursing Homes, Assisted Living Facilities, Nurse Midwives, and Licensed Certified Midwives - Disclosure (Nyeli Rose Lewis Act of 2026)) supporting campaign finance reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0442?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0849 (Child Care Scholarship Program - Freeze in Enrollment - Exceptions and Waitlist) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0849?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB0345 (Public Utilities - Solar Energy Generating Systems and Solar Renewable Energy Credits (Affordable Solar Act)) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0439 (Office of the Deaf and Hard of Hearing and Maryland Advisory Council on Deaf and Hard of Hearing - Renaming) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0439?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB1205 (Education - Minimum Wage for Education Support Professionals) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1205?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB0322 (Maryland Health Care Commission - Membership) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0322?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sponsored/co-sponsored HB0818 (Higher Education - Foster Care Recipients and Homeless Youth - Tuition Exemption and Associated Benefits) supporting housing-first homelessness solutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0818?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0310 (Correctional Services - Restrictive Housing - Individuals With Developmental or Intellectual Disabilities) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0310?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0439 (Office of the Deaf and Hard of Hearing and Maryland Advisory Council on Deaf and Hard of Hearing - Renaming) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0439?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0022 (Correctional Services - Incarcerated Individuals - Identification Cards, Driver's Licenses, and Birth Certificates) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0022?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0634 (Police Training - Autism and Dementia (LEAD Act of 2026)) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0634?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB0092 (Environment - Beverage Containers Connected With Plastic Rings - Restriction on Sale) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0092?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB0440 (Maryland Medical Assistance Program - Individuals With Intellectual and Developmental Disabilities - Provider Reimbursement) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0440?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB0137 (Family Law - Child Custody Evaluators - Qualifications) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0137?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Sponsored/co-sponsored HB0989 (State Assistance for the Elderly - Study on Calculation of Income) supporting retirement/Social Security.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0989?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB1148 (Property Taxes - Tax Sales, Legacy Protection Program, and Tax Credits) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1148?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron M. Kaufman / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc703231-6af8-48c6-8ae6-4a93fc60b18f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0350 (Voting Rights Act of 2026 - Counties and Municipal Corporations) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/kaufman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Marc Korman
-- ============================================================

-- ----- Marc Korman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored HB1161 (Board of Public Works - Climate and Sustainability Information Act), requiring climate information in BPW contract review; also sponsored HB0702 (Maryland Strategic Energy Investment Fund for Co-Op and Condo Energy).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1161?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored HB1081 (Maryland Transit Administration Reform Act) and HB0386 (Metro Funding Modification Act of 2026) supporting transit-connected housing and mobility.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1081?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on redistricting reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) prohibiting local immigration enforcement cooperation with ICE.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) supporting sanctuary policies limiting local ICE cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Sponsored HB0154 (Open Meetings Act - County Boards of Education - Enhanced Requirements / Local Boards of Education Transparency Act) expanding public transparency requirements for school boards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0154?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored HB1081 (Maryland Transit Administration Reform Act) and HB0386 (Metro Funding Modification Act of 2026) supporting public transit infrastructure as economic investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1081?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored HB0870 (Environment - Permit Applications for New Buildings - Notice / Large Buildings for Tomorrow Act) requiring environmental notification for large building permits.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0870?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Co-sponsored HB0155 (Public Safety - Law Enforcement Officers - Prohibition on Face Coverings) on police conduct standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0155?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '683c8084-2281-4920-a07c-18439b2dd413',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Co-sponsored HB0706 (State Finance - Delinquent Federal Funds / Federal Obligations Enforcement Act) requiring state to recover federal funds withheld due to policy disputes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0706?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc Korman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e76d0654-b0c6-43dc-9159-e929e480d070',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored HB1009 (Transfer of Real Property - Recordation Certification and State Transfer Tax / Land Transfer Accountability Act) on real property tax accountability reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1009?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/korman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Bernice Mireku-North
-- ============================================================

-- ----- Bernice Mireku-North / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sponsored/co-sponsored HB1057 (Education - Artificial Intelligence - Guidelines, Professional Development, and Collaborative (Artificial Intelligence Ready Schools Act)) on algorithmic/automated systems regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1057?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0539 (Child Care Centers - Teacher Qualifications - Alterations) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0539?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB1205 (Education - Minimum Wage for Education Support Professionals) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1205?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB1118 (Health, Health Insurance, and Health Occupations - Perinatal Behavioral Health Conditions) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1118?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0894 (Land Use - Transit-Oriented Development - Alterations (Maryland Transit and Housing Opportunity Act)) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0894?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Sponsored/co-sponsored HB0438 (Adult Prison School Board Model Development Committee) on correctional policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0438?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0776 (Juvenile Law - Child in Need of Supervision - Mandatory Petition (NyKayla Strawder Memorial Act)) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0776?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0155 (Public Safety - Law Enforcement Officers - Prohibition on Face Coverings) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0155?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB0092 (Environment - Beverage Containers Connected With Plastic Rings - Restriction on Sale) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0092?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB0410 (Public Health - Food Labeling - Requirements) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0410?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB0605 (Public Safety - Gun Violence Victim Relocation Program - Establishment) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0605?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0745 (Income Tax - Senior Tax Credit - Refundability) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0745?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bernice Mireku-North / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8abee534-5db0-4950-a2b9-d0d1e8088cc7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0350 (Voting Rights Act of 2026 - Counties and Municipal Corporations) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/mireku01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- David Moon
-- ============================================================

-- ----- David Moon / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sponsored/co-sponsored HB0510 (Motor Vehicles - Automated Speed Enforcement - Improper Registration) on algorithmic/automated systems regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0510?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored/co-sponsored HB0351 (Civil Actions - Violation of Constitutional Rights (No Kings Act)) advancing civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0351?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB0897 (Electricity Transmission and Distribution, Energy Storage, and Maryland Strategic Energy Investment Fund (Lower Bills and Local Power Act of 2026)) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0897?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0706 (State Finance - Delinquent Federal Funds (Federal Obligations Enforcement Act)) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0706?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB0637 (Public Health - Recommendations for Immunizations, Screenings, and Preventive Services - Pharmacist Administration and Required Health Insurance Coverage (The Vax Act)) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0637?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0337 (School Construction and Housing - School Zones and Adequate Public Facilities Ordinances) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0337?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0131 (Criminal Procedure - Expungement - Adverse Actions and Removal From Maryland Electronic Courts (MDEC) System) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0131?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0904 (Law Enforcement - Protective Body Armor - Requirements and Reporting) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0904?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB0034 (Municipalities - Open Drainage Inlets - Inventory and Improvements (Mason's Law)) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0034?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB0497 (Family Law - Temporary and Final Protective Orders - Duration) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0497?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0906 (Civil Actions - Punitive Damage Awards - Surcharge) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0906?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Moon / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96876928-53f8-4ed5-b2de-deab3a456d83',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0350 (Voting Rights Act of 2026 - Counties and Municipal Corporations) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/moon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Lily Qi
-- ============================================================

-- ----- Lily Qi / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB0817 (Carbon Dioxide Capture, Removal, and Sequestration Projects - Regulations and Standards for Biochar and Wood Vault Technologies) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0817?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0306 (Vehicle Laws - Manufacturers and Dealers - Prices Listed on Dealer Websites (Jack Fitzgerald Price Transparency Act)) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0306?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0506 (Economic Development - Transformational Project Financing Program - Establishment) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0506?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB0883 (Consumer Protection - Artificial Intelligence - Behavioral Health Care Prohibitions) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0883?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sponsored/co-sponsored HB1353 (Homeless Individuals - Fee and Examination Exemptions) supporting housing-first homelessness solutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1353?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0548 (Land Use - Permitting - Development Rights (Maryland Housing Certainty Act)) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0548?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0306 (Vehicle Laws - Manufacturers and Dealers - Prices Listed on Dealer Websites (Jack Fitzgerald Price Transparency Act)) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0306?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0935 (Correctional Services - Comprehensive Rehabilitative Prerelease Services - Female Incarcerated Individuals) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0935?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB1618 (Department of the Environment - Procedures for Permitting Efficiency - Requirements) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1618?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB1239 (Public Safety - Critical Infrastructure Protection) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1239?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB1128 (Income Tax – Angel Investor Tax Credit for Investments in Emergent Technology) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1128?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lily Qi / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e00e72f9-6b53-46a7-a1e4-74ab7b91d68d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0496 (Election Law - Unaffiliated Voters - Open Primary Elections) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0496?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/qi01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Pam Queen
-- ============================================================

-- ----- Pam Queen / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored/co-sponsored HB1454 (Campaign Finance - Security Expenditures - Authorization) supporting campaign finance reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1454?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Queen / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0849 (Child Care Scholarship Program - Freeze in Enrollment - Exceptions and Waitlist) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0849?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Queen / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB1120 (Professional Licensing Portability - Members of the Foreign Service and Spouses) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1120?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Queen / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0461 (Economic Development - Rural Readiness Program and Rural Maryland Capacity Building Fund - Establishment) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0461?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Queen / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0543 (Real Property - Landlord and Tenant - Family Child Care Homes) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0543?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Queen / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB1120 (Professional Licensing Portability - Members of the Foreign Service and Spouses) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1120?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Queen / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0935 (Correctional Services - Comprehensive Rehabilitative Prerelease Services - Female Incarcerated Individuals) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0935?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Queen / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB1071 (Environment - Stormwater Management for Agritourism) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1071?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Queen / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0478 (Income Tax - Subtraction Modification for Classroom Supplies Purchased by Teachers - Alteration) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0478?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Queen / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a11c027a-ef25-4a09-8df7-e9b7c60bea90',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Sponsored/co-sponsored HB0038 (Financial Institutions - Licensing of Affiliated Insurance Producer-Mortgage Loan Originators - Alterations) on international affairs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0038?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/queen01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Emily Shetty
-- ============================================================

-- ----- Emily Shetty / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Co-sponsored HB1131 (Public Health - Pregnancy Loss - Prohibited Actions / Pregnancy Outcome Protection Act) protecting access to pregnancy loss care; co-sponsored HB1143 (Lung Float Test Ban) limiting medically-unsound intrusion on pregnancy outcomes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1131?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored HB0672 (Maryland Pediatric Cancer Fund), HB0772 (Behavioral Health Rate Methodology Modernization Workgroup), and HB1048 (Chain Restaurants Sodium Warning Icons) expanding healthcare access and wellness awareness.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0672?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored HB0671 (Long-Term Care Ombudsman Mandatory Appropriation) and HB1490 (Temporary Cash Assistance Good Cause Exceptions) expanding safety-net programs for vulnerable populations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0671?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored HB0680 (Children Cabinet Fund - Grants to Local Management Boards) supporting child welfare services and early childhood programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0680?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored HB1458 (State Supplemental SNAP for Refugees and Asylees) expanding food assistance to immigrants; co-sponsored HB0444 (Immigration Enforcement Agreements Prohibition).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1458?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) opposing local law enforcement cooperation with ICE.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on redistricting and election access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Co-sponsored HB0197 (Comprehensive Community Safety Funding Act) supporting community-based public safety investment over policing-only approaches.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0197?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Co-sponsored HB0805 (Building Homes Act) supporting housing production and affordability measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0805?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Co-sponsored HB0465 (Stop Silencing Survivors Act) and HB0311 (Public Schools - Individuals With Disabilities - Accessibility and Emergency Planning) advancing civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Co-sponsored HB0001 (Investor-Owned Electric Companies - Cost Recovery Limitations) limiting utility rate hikes during clean energy transition; co-sponsored HB0578 (Endangered and Threatened Species Regulations).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0001?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Co-sponsored HB0578 (Fish and Wildlife - Endangered and Threatened Species and Migratory Birds) and HB0331 (Maryland Beverage Container Recycling Refund and Litter Reduction Program) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0578?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Emily Shetty / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d1a30768-52e8-4a0d-badc-3e5f2f5792c7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Co-sponsored HB1205 (Education - Minimum Wage for Education Support Professionals) raising wages for school workers; sponsored HB0680 (Children Cabinet Fund grants) for community workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1205?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/shetty01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jared Solomon
-- ============================================================

-- ----- Jared Solomon / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0742 (Growing Family Child Care Opportunities Program - Funding) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0742?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB0437 (Transportation - Major Highway Capacity Expansion Projects and Impact Assessments (Transportation and Climate Alignment Act of 2026)) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0437?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0161 (Property Tax Credit - Retail Service Station Conversions) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0161?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0532 (Employment Standards - Firefighters - Payment of Wages and Payroll Information) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0532?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB1068 (Health Insurance - Special Enrollment Period for Newly Hired Employees of Small Businesses) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1068?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sponsored/co-sponsored HB1353 (Homeless Individuals - Fee and Examination Exemptions) supporting housing-first homelessness solutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1353?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0523 (Real Property - Residential Foreclosures - Commencement Restrictions) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0523?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0161 (Property Tax Credit - Retail Service Station Conversions) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0161?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0022 (Correctional Services - Incarcerated Individuals - Identification Cards, Driver's Licenses, and Birth Certificates) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0022?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0155 (Public Safety - Law Enforcement Officers - Prohibition on Face Coverings) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0155?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB1131 (Public Health - Pregnancy Loss - Prohibited Actions (Pregnancy Outcome Protection Act)) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1131?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB1080 (Income Tax - Addition Modifications - Excluded Opportunity Fund Gains, Foreign-Derived Deduction Eligible Income, and Interest) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1080?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jared Solomon / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf0c64-6254-40a7-b810-8717977759dd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0156 (Election Law - Affiliating With a Party and Voting - Unaffiliated Voters) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0156?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/solomon01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ryan Spiegel
-- ============================================================

-- ----- Ryan Spiegel / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sponsored/co-sponsored HB0510 (Motor Vehicles - Automated Speed Enforcement - Improper Registration) on algorithmic/automated systems regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0510?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored/co-sponsored HB0465 (Civil Actions - Immunity - Disclosure of Allegations of Sexually Assaultive Behavior (Stop Silencing Survivors Act)) supporting campaign finance reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0659 (State Board of Education - Membership - Early Childhood Development Professional) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0659?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB0572 (Attorney General Actions and Climate Crimes Accountability Fund (Climate Crimes Accountability Act)) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0572?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0506 (Economic Development - Transformational Project Financing Program - Establishment) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0506?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB1435 (Health Insurance - Required Coverage - Hormone-Related Care) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1435?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sponsored/co-sponsored HB1353 (Homeless Individuals - Fee and Examination Exemptions) supporting housing-first homelessness solutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1353?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0573 (Fair Housing and Housing Discrimination - Regulations, Intent, and Discriminatory Effect) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0573?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0444 (Public Safety - Immigration Enforcement Agreements - Prohibition) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0450 (Criminal Procedure - Protection of Identity of Victim of Sexual Assault or Stalking) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0450?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0794 (Public Safety - Maryland Police Training and Standards Commission - Prohibition Against Certain Affiliation or Support by Police Officers) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0794?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB1131 (Public Health - Pregnancy Loss - Prohibited Actions (Pregnancy Outcome Protection Act)) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1131?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB1128 (Income Tax – Angel Investor Tax Credit for Investments in Emergent Technology) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1128?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Spiegel / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('203a0228-7a63-4a6a-b26d-fa45ba139472',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0641 (Election Law - Curbside Voting - Pilot Program) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0641?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/spiegel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Vaughn Stewart
-- ============================================================

-- ----- Vaughn Stewart / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB1108 (Labor and Employment - Greenhouse Workers - Collective Bargaining and Heat Protection) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1108?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB1229 (Consumer Protection and Labor and Employment - Food Service Facilities and Minimum Wage) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1229?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0317 (Recipients of Economic Development Assistance or State Contracts - Certification of Compliance With State Labor Laws) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0317?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB0576 (State Archives - Record Services - Fees) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0576?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Sponsored/co-sponsored HB1353 (Homeless Individuals - Fee and Examination Exemptions) supporting housing-first homelessness solutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1353?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0313 (Landlord and Tenant - Residential Housing - Rental Applications and Tenant Screening) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0313?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB1229 (Consumer Protection and Labor and Employment - Food Service Facilities and Minimum Wage) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1229?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Sponsored/co-sponsored HB0309 (Judicial Facilities - Stops, Detentions, and Arrests - Limitations) on correctional policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0309?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB1018 (Correctional Services - Correctional Facilities and Immigration Detention Facilities - Minimum Mandatory Standards) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1018?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0634 (Police Training - Autism and Dementia (LEAD Act of 2026)) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0634?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB0941 (Public Health - Public Buildings - Hygiene Products) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0941?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB0553 (Public Safety - Elevator Inspection Certificates - Searchable Database) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0553?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Sponsored/co-sponsored HB0153 (Residential Rental Apartments - Air-Conditioning Requirement) supporting rent regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0153?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '683c8084-2281-4920-a07c-18439b2dd413',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Sponsored/co-sponsored HB0413 (Maryland-Ireland Trade Commission - Membership and Termination - Altered and Extended) on federal trade/financial policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0413?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0323 (Income Tax - Credit for Income Taxes and Penalties Due to Financial Exploitation) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0323?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vaughn Stewart / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac558ee8-ecae-47b6-a25e-46307521b4af',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0871 (Election Law - Enhanced Automatic Voter Registration System) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0871?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/stewart01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Joe Vogel
-- ============================================================

-- ----- Joe Vogel / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sponsored/co-sponsored HB1057 (Education - Artificial Intelligence - Guidelines, Professional Development, and Collaborative (Artificial Intelligence Ready Schools Act)) on algorithmic/automated systems regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1057?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored/co-sponsored HB0509 (Campaign Finance - Contributions by Gas and Electric Utility Companies - Prohibition) supporting campaign finance reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0509?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0849 (Child Care Scholarship Program - Freeze in Enrollment - Exceptions and Waitlist) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0849?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored/co-sponsored HB0513 (Hate Crimes and Hate Bias - Definitions of Sexual Orientation and Hate Bias Incident) advancing civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0513?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sponsored/co-sponsored HB0345 (Public Utilities - Solar Energy Generating Systems and Solar Renewable Energy Credits (Affordable Solar Act)) supporting climate action and clean energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0148 (Consumer Protection and Labor and Employment - Surveillance-Based Price and Wage Setting - Prohibition) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0148?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0045 (Labor and Employment - Mandatory Meetings on Religious or Political Matters - Employee Attendance and Participation (Maryland Worker Freedom Act)) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0045?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB0222 (County Boards of Education - Opioid Overdose-Reversing Medications - Policy Requirements (Naloxone Access Act)) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0222?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0080 (Landlord and Tenant - Residential Leases - Fee Disclosures) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0080?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0148 (Consumer Protection and Labor and Employment - Surveillance-Based Price and Wage Setting - Prohibition) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0148?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0630 (Correctional Services - Immigration Detention Facilities - Original Design and Construction) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0630?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0634 (Police Training - Autism and Dementia (LEAD Act of 2026)) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0634?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB0202 (Public Health - Social Isolation and Loneliness Pilot Grant Program - Establishment) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0202?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB0134 (Family Law - Incapacitated or Protected Persons - Petition for Visitation) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0134?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0013 (Income Tax - Credit for 9-1-1 Specialist Retirement Income (Supporting Our 9-1-1 Specialists Act)) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0013?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Sponsored/co-sponsored HB0109 (Institutions of Higher Education and Elementary and Secondary Schools - Title VI Coordinators) on international affairs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0109?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Vogel / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('458a60ba-a235-4b36-80bb-8b537375a4ff',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0207 (Election Law - Certificate of Candidacy for Congressional Offices - Stock Trading Activities (Congressional Stock Trading Transparency Act)) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0207?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/vogel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jheanelle K. Wilkins
-- ============================================================

-- ----- Jheanelle K. Wilkins / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sponsored/co-sponsored HB1261 (Consumer Protection - Artificial Intelligence Toys (Artificial Intelligence Toy Safety Act)) on algorithmic/automated systems regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1261?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB0430 (Family Child Care Providers - Reserve Component Members - Substitute Provider) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0430?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sponsored/co-sponsored HB0884 (University of Maryland Eastern Shore - Land-Grant Institution - Funding (Land-Grant Equity and Accountability Act)) advancing civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0884?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0414 (Courts - Jury Service - Disqualification) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0414?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0706 (State Finance - Delinquent Federal Funds (Federal Obligations Enforcement Act)) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0706?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB1118 (Health, Health Insurance, and Health Occupations - Perinatal Behavioral Health Conditions) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1118?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0774 (Landlord and Tenant - Residential Leases and Holdover Tenancies - Local Good Cause Termination (Good Cause Eviction)) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0774?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0414 (Courts - Jury Service - Disqualification) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0414?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Sponsored/co-sponsored HB0438 (Adult Prison School Board Model Development Committee) on correctional policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0438?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0687 (Criminal Procedure - Evidence - Protecting Artists' Creative Expression (PACE Act)) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0687?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0155 (Public Safety - Law Enforcement Officers - Prohibition on Face Coverings) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0155?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB1268 (Environmental Permits - Requirements for Burden Analysis, Issuance and Renewal, and Public Participation (Cumulative Harms for Environmental Restoration for Improving Shared Health - CHERISH Our Communities Act)) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1268?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB1131 (Public Health - Pregnancy Loss - Prohibited Actions (Pregnancy Outcome Protection Act)) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1131?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB0980 (Family Law and Human Services - Guardianship Assistance Program and State Foster Youth Ombudsman - Establishment (Kanaiyah's Law)) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0980?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0542 (Earned Income Tax Credit - Individuals Without Qualifying Children - Eligibility) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0542?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jheanelle K. Wilkins / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf68a5cd-f375-4296-8a87-1828d903baea',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0052 (Election Law - Incarcerated Individuals - Voter Hotline and Voting Eligibility (Voting Rights for All Act)) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0052?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilkins01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Sarah Wolek
-- ============================================================

-- ----- Sarah Wolek / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored/co-sponsored HB0538 (4-Year Institutions of Higher Education - Mandatory Disclosures for New and Prospective Students (Informed Enrollment Act)) supporting campaign finance reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0538?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sponsored/co-sponsored HB1032 (Prekindergarten Programs and Primary and Secondary Schools - Student Privacy Policy Requirements and Discrimination Reporting) supporting childcare/early education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1032?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB0755 (County Boards of Education - Student Personal Electronic Device Use Policy - Establishment (Phones Away for the School Day Act)) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0755?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB0798 (Economic Development - Small, Minority, and Women-Owned Business Accounts - Management Fees (Small Business Increased Access to Capital Act)) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0798?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB0800 (Education - Behavioral Health and Student Well-Being and Human Flourishing (Maryland Student Well-Being and Flourishing Act)) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0800?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0543 (Real Property - Landlord and Tenant - Family Child Care Homes) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0543?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB0755 (County Boards of Education - Student Personal Electronic Device Use Policy - Establishment (Phones Away for the School Day Act)) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0755?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0450 (Criminal Procedure - Protection of Identity of Victim of Sexual Assault or Stalking) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0450?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sponsored/co-sponsored HB0517 (Emission Standards, Ambient Air Quality Standards, and Solid Waste Management - Local Authority) supporting environmental protection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0517?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB1445 (Maryland Medical Assistance Program and Developmental Disabilities Administration - Home- and Community-Based Services Eligibility Determinations (Maryland Protecting People With Disabilities Act)) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1445?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Wolek / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4db476f3-bc84-484c-9440-666028942469',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0478 (Income Tax - Subtraction Modification for Classroom Supplies Purchased by Teachers - Alteration) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0478?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wolek01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Teresa Woorman
-- ============================================================

-- ----- Teresa Woorman / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sponsored/co-sponsored HB0510 (Motor Vehicles - Automated Speed Enforcement - Improper Registration) on algorithmic/automated systems regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0510?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored/co-sponsored HB0442 (Professional Liability Insurance Coverage - Nursing Homes, Assisted Living Facilities, Nurse Midwives, and Licensed Certified Midwives - Disclosure (Nyeli Rose Lewis Act of 2026)) supporting campaign finance reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0442?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sponsored/co-sponsored HB1530 (Higher Education - Undocumented Students - Out-of-State Tuition Exemption Eligibility) opposing immigration enforcement cooperation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1530?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sponsored/co-sponsored HB1205 (Education - Minimum Wage for Education Support Professionals) on economic/workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1205?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored/co-sponsored HB0965 (Office of Health Care Quality Stakeholder Advisory Council - Establishment) expanding healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0965?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sponsored/co-sponsored HB0543 (Real Property - Landlord and Tenant - Family Child Care Homes) supporting housing affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0543?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sponsored/co-sponsored HB1530 (Higher Education - Undocumented Students - Out-of-State Tuition Exemption Eligibility) supporting immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1530?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsored/co-sponsored HB0429 (On-Farm Organics Diversion and Recycling Grant Program - Established) supporting criminal justice reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0429?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Sponsored/co-sponsored HB0155 (Public Safety - Law Enforcement Officers - Prohibition on Face Coverings) on law enforcement accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0155?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sponsored/co-sponsored HB0196 (Public Health - Baby Food Testing and Labeling - Requirements) supporting Medicaid/public health programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0196?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sponsored/co-sponsored HB0003 (Higher Education - Student Financial Assistance - Dependents of State or Local Public Safety Employees (Maryland Fallen Heroes Tuition Benefits Act)) on public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0003?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Sponsored/co-sponsored HB0488 (Election Districts - General Assembly and Representatives in Congress) on election district reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Sponsored/co-sponsored HB0989 (State Assistance for the Elderly - Study on Calculation of Income) supporting retirement/Social Security.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0989?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sponsored/co-sponsored HB0745 (Income Tax - Senior Tax Credit - Refundability) on tax policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0745?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Woorman / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36171e41-704b-4bf9-b300-755afe4ee06f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sponsored/co-sponsored HB0350 (Voting Rights Act of 2026 - Counties and Municipal Corporations) supporting voting rights and access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/woorman01']::text[]::text[])
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
-- WHERE p.id IN ('bfd0f15f-abb1-4d28-b1f4-e06875adce16', '8abee534-5db0-4950-a2b9-d0d1e8088cc7', 'a11c027a-ef25-4a09-8df7-e9b7c60bea90', 'b80a680a-9f79-4d56-994b-00ce24ec7ef3', 'ab8aa19a-42c3-445e-9632-a5c7f05458ee', 'e00e72f9-6b53-46a7-a1e4-74ab7b91d68d', 'e76d0654-b0c6-43dc-9159-e929e480d070', '4db476f3-bc84-484c-9440-666028942469', '36171e41-704b-4bf9-b300-755afe4ee06f', '70d58d4b-4203-4fc2-b36f-32e6231c4339', '203a0228-7a63-4a6a-b26d-fa45ba139472', '458a60ba-a235-4b36-80bb-8b537375a4ff', 'bc703231-6af8-48c6-8ae6-4a93fc60b18f', 'd1a30768-52e8-4a0d-badc-3e5f2f5792c7', 'c0bf0c64-6254-40a7-b810-8717977759dd', '98d6a17e-59dc-4d11-a342-869603862f10', '17c22fec-63a4-4f5d-8607-0c364ddffd71', 'ac558ee8-ecae-47b6-a25e-46307521b4af', '9c5e1ac7-8a39-4c6e-8b20-0788a92f8607', '96876928-53f8-4ed5-b2de-deab3a456d83', 'cf68a5cd-f375-4296-8a87-1828d903baea')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('bfd0f15f-abb1-4d28-b1f4-e06875adce16', '8abee534-5db0-4950-a2b9-d0d1e8088cc7', 'a11c027a-ef25-4a09-8df7-e9b7c60bea90', 'b80a680a-9f79-4d56-994b-00ce24ec7ef3', 'ab8aa19a-42c3-445e-9632-a5c7f05458ee', 'e00e72f9-6b53-46a7-a1e4-74ab7b91d68d', 'e76d0654-b0c6-43dc-9159-e929e480d070', '4db476f3-bc84-484c-9440-666028942469', '36171e41-704b-4bf9-b300-755afe4ee06f', '70d58d4b-4203-4fc2-b36f-32e6231c4339', '203a0228-7a63-4a6a-b26d-fa45ba139472', '458a60ba-a235-4b36-80bb-8b537375a4ff', 'bc703231-6af8-48c6-8ae6-4a93fc60b18f', 'd1a30768-52e8-4a0d-badc-3e5f2f5792c7', 'c0bf0c64-6254-40a7-b810-8717977759dd', '98d6a17e-59dc-4d11-a342-869603862f10', '17c22fec-63a4-4f5d-8607-0c364ddffd71', 'ac558ee8-ecae-47b6-a25e-46307521b4af', '9c5e1ac7-8a39-4c6e-8b20-0788a92f8607', '96876928-53f8-4ed5-b2de-deab3a456d83', 'cf68a5cd-f375-4296-8a87-1828d903baea')
--   AND pc.politician_id IS NULL;