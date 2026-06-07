-- ============================================================================
-- Migration 287: MD Delegates Batch B — Districts 8-13
-- ============================================================================
-- Purpose: Insert/upsert stance data for 18 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~191 rows expected
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
-- Nick Allen
-- ============================================================

-- ----- Nick Allen / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Allen co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) expanding abortion access in Maryland and supported repeal of waiting periods and gestational limits — a strongly pro-choice position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Allen / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Allen co-sponsored HB 550 (Climate Solutions Now Act implementation bills) and supported Maryland's offshore wind expansion — strongly favors aggressive climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Allen / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Allen supported HB 1210 (Maryland Health Care for All) and co-sponsored legislation expanding Medicaid coverage — strongly supports government-led healthcare expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Allen / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Allen co-sponsored HB 693 (Renters' Rights and Stabilization Act) and supported expanded affordable housing mandates while supporting mixed-income development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Allen / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Allen supported HB 499 (Blueprint for Maryland's Future Financing) and income-based tax reforms increasing taxes on high earners to fund education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Allen / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Allen co-sponsored HB 1 (Next Steps for Maryland Voting Act) expanding automatic voter registration and early voting — strongly supports voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Allen / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Allen co-sponsored HB 1180 (CROWN Act) prohibiting discrimination based on hairstyle and other civil rights expansions — strong champion of civil rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Allen / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Allen supports same-sex marriage and LGBTQ+ protections; co-sponsored HB 283 (Protecting Youth in Health Care Act) protecting trans youth healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Allen / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Allen supported the Blueprint for Maryland's Future which prioritizes public school investment and opposed diversion of public funds to private schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Allen / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1f58b34-76ee-43ce-b152-4843c42f4f79',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Allen supported Maryland's independent redistricting reform efforts and opposed partisan gerrymandering — supports nonpartisan commission approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/allen04', 'https://ballotpedia.org/Nick_Allen_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Harry Bhandari
-- ============================================================

-- ----- Harry Bhandari / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Bhandari co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently voted in favor of abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harry Bhandari / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Bhandari supported Maryland's Climate Solutions Now Act and offshore wind legislation — consistent supporter of aggressive clean energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harry Bhandari / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Bhandari co-sponsored legislation expanding Medicaid and healthcare access in Maryland; supported public option expansion efforts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harry Bhandari / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Bhandari supported SB 15 (DREAM Act protections) and opposed cooperation with federal immigration enforcement — strongly supports immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harry Bhandari / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Bhandari supported progressive tax measures including Blueprint for Maryland's Future funding through higher income taxes on top earners.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harry Bhandari / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Bhandari co-sponsored the CROWN Act and anti-discrimination legislation; has championed civil rights for minority communities in Baltimore County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harry Bhandari / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Bhandari strongly supports LGBTQ+ rights including same-sex marriage and gender-affirming care protections for minors.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harry Bhandari / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Bhandari co-sponsored HB 1 (Next Steps for Maryland Voting Act) expanding automatic registration and early voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harry Bhandari / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Bhandari supported expanded affordable housing mandates and tenant protections including Just Cause eviction protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harry Bhandari / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6d95657c-6c46-4aab-886f-f9688adc7b33',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Bhandari supported the Blueprint for Maryland's Future — strong advocate for public school investment and against private school voucher diversion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01', 'https://ballotpedia.org/Harry_Bhandari']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jon S. Cardin
-- ============================================================

-- ----- Jon S. Cardin / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Cardin co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has been a strong supporter of abortion access throughout his career in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cardin supported the Climate Solutions Now Act and offshore wind legislation — consistent supporter of aggressive climate action and clean energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cardin supported Medicaid expansion and healthcare access legislation — favors significant expansion of public coverage with mixed system approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Cardin has been a strong advocate for campaign finance reform including disclosure requirements — publicly opposed Citizens United and dark money in politics.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cardin co-sponsored civil rights legislation including anti-discrimination protections — strong supporter of civil rights expansion in Baltimore County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Cardin supported expanded voting access legislation including automatic registration and early voting — strong supporter of voting rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Cardin supports same-sex marriage and LGBTQ+ protections — has consistently voted for LGBTQ+ rights legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cardin supported progressive tax reform to fund public services and the Blueprint for Maryland's Future education initiative.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Cardin supported the Blueprint for Maryland's Future — favors public school investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Cardin has supported independent redistricting reform and opposed partisan gerrymandering in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon S. Cardin / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631dac5c-fb86-41f5-a82d-5963164a9142',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cardin supported affordable housing legislation and tenant protections — favors mixed-income development with affordability requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01', 'https://ballotpedia.org/Jon_Cardin']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jessica Feldmark
-- ============================================================

-- ----- Jessica Feldmark / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Feldmark co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently supported abortion access legislation throughout her Maryland House tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica Feldmark / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Feldmark supported the Climate Solutions Now Act and Howard County renewable energy initiatives — favors aggressive climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica Feldmark / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Feldmark supported Medicaid expansion and healthcare access legislation — favors significant expansion of public health coverage.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica Feldmark / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Feldmark has been active on Howard County housing policy — supports affordable housing mandates and mixed-income development with community input.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica Feldmark / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Feldmark co-sponsored civil rights legislation including anti-discrimination protections in Howard County — strong supporter of civil rights expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica Feldmark / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Feldmark supported expanded voting access legislation including automatic registration and early voting — strong supporter of voting rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica Feldmark / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Feldmark strongly supports same-sex marriage and LGBTQ+ protections including protections for transgender youth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica Feldmark / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Feldmark supported progressive tax reform funding Blueprint for Maryland's Future through higher taxes on high earners.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica Feldmark / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Feldmark supported the Blueprint for Maryland's Future — strong advocate for public school investment over private school vouchers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica Feldmark / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Feldmark has championed public-private partnerships for economic development in Howard County while supporting worker protections and targeted public investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01', 'https://ballotpedia.org/Jessica_Feldmark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Pam Lanman Guzzone
-- ============================================================

-- ----- Pam Lanman Guzzone / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Lanman Guzzone co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently supported abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Lanman Guzzone / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lanman Guzzone supported the Climate Solutions Now Act and Maryland's clean energy transition — consistently favors aggressive climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Lanman Guzzone / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lanman Guzzone supported Medicaid expansion and healthcare access legislation — favors significant public health coverage expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Lanman Guzzone / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lanman Guzzone has been active on Howard County housing policy — supports affordable housing mandates and mixed-income development with community input.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Lanman Guzzone / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Lanman Guzzone co-sponsored civil rights legislation including anti-discrimination protections — strong supporter of civil rights expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Lanman Guzzone / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Lanman Guzzone supported expanded voting access legislation — favors automatic registration and early voting expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Lanman Guzzone / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Lanman Guzzone strongly supports same-sex marriage and LGBTQ+ protections including trans youth healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Lanman Guzzone / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lanman Guzzone supported progressive tax reform to fund public services and Blueprint for Maryland's Future education investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Lanman Guzzone / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Lanman Guzzone supported Blueprint for Maryland's Future — favors public school investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pam Lanman Guzzone / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('589ed7af-602a-4ec9-8072-448b05446772',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lanman Guzzone supported childcare subsidy expansion legislation to improve access for working families in Howard County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone03', 'https://ballotpedia.org/Pam_Guzzone']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Terri L. Hill
-- ============================================================

-- ----- Terri L. Hill / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Hill co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) — as a physician she has been particularly vocal about reproductive healthcare as medical care$$,
        ARRAY['not politics.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hill is a practicing physician and has been Maryland's leading advocate for healthcare expansion including Medicaid expansion and co-sponsored legislation supporting Maryland Health Care for All.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hill supported the Climate Solutions Now Act and environmental health legislation — recognizes climate as a public health issue and favors aggressive action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Hill co-sponsored the CROWN Act and civil rights expansion legislation — strong supporter of anti-discrimination protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hill supported expanded voting access legislation including automatic registration and early voting expansion — strong supporter of voting rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Hill supports same-sex marriage and LGBTQ+ protections including gender-affirming healthcare access — has spoken publicly about trans youth healthcare as medical care.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hill supported progressive tax reform to fund public services including Blueprint for Maryland's Future and healthcare expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Hill supported the Blueprint for Maryland's Future — strongly favors public school investment over private school voucher diversion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Hill supported affordable housing mandates and tenant protections in Howard County — favors mixed-income development with significant affordability requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$As a physician Hill has been a leading advocate for expanding Medicare and Medicaid — strongly opposes any cuts to these programs and supports expanding eligibility.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terri L. Hill / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f6a237a0-34ff-4a93-b05a-335ec38b6da3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Hill has advocated for expanded childcare access as a healthcare and economic development issue — supported subsidized childcare legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill04', 'https://ballotpedia.org/Terri_Hill']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jennifer White Holland
-- ============================================================

-- ----- Jennifer White Holland / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$White Holland co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has been a consistent supporter of abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer White Holland / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$White Holland supported the Climate Solutions Now Act and Maryland's clean energy transition legislation — favors aggressive climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer White Holland / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$White Holland supported Medicaid expansion and healthcare access legislation — favors significant public coverage expansion with mixed system.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer White Holland / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$White Holland supported affordable housing mandates and tenant protections — favors mixed-income development with strong affordability requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer White Holland / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$White Holland co-sponsored civil rights legislation including anti-discrimination protections — strong supporter of civil rights in Baltimore County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer White Holland / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$White Holland supported expanded voting access legislation including early voting expansion and automatic registration.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer White Holland / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$White Holland strongly supports same-sex marriage and LGBTQ+ protections including gender-affirming care protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer White Holland / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$White Holland supported progressive tax reforms funding Blueprint for Maryland's Future through higher taxes on high earners.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer White Holland / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$White Holland supported Blueprint for Maryland's Future — favors public school investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer White Holland / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d80816fc-da1d-48f4-95c9-467f8831933c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$White Holland supported the Maryland Police Accountability Act reforms while also supporting community investment — favors balanced public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/holland03', 'https://ballotpedia.org/Jennifer_White_Holland']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Adrienne A. Jones
-- ============================================================

-- ----- Adrienne A. Jones / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Speaker Jones championed HB 1171 (Pregnant Person's Freedom Act of 2024) and co-sponsored the Abortion Care Access Act — has made abortion access a legislative priority as Speaker.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$As Speaker Jones championed the Climate Solutions Now Act (2022) making Maryland the first state to require net-zero emissions by 2045 — the strongest climate law in Maryland history.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Jones co-sponsored Maryland Health Care for All and led efforts to expand Medicaid — has prioritized healthcare access throughout her speakership.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Jones co-sponsored and championed the Next Steps for Maryland Voting Act expanding automatic registration — consistently strong supporter of voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Jones was the first Black Speaker in Maryland history and has championed civil rights legislation including the CROWN Act; sponsored the George Floyd Act on police reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Jones sponsored the Maryland Police Accountability Act of 2021 (George Floyd Act) creating civilian oversight boards — favors community investment and police accountability over enforcement-first approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Jones supported the Second Chance Act and juvenile justice reform legislation — consistently favors rehabilitation over incarceration as Speaker.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Jones championed Blueprint for Maryland's Future funding through progressive tax reform — supported higher taxes on high earners and corporations to fund education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Jones supported affordable housing legislation and tenant protections — favors significant affordable mandates with mixed-income development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Jones strongly supports same-sex marriage and has championed LGBTQ+ protections in Maryland including protections for transgender youth healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Jones led passage of the Blueprint for Maryland's Future — a landmark public school investment law; consistently opposes public funds going to private school vouchers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Jones supported campaign finance disclosure requirements and publicly opposed the influence of dark money in Maryland politics.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Jones supported Maryland's Trust Act limiting local law enforcement cooperation with ICE — strongly supports immigrant rights and sanctuary protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Jones supported Maryland's Fair Maps initiative and has advocated for greater transparency in the redistricting process.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Jones co-sponsored childcare expansion legislation and supported Blueprint for Maryland's Future pre-K funding — strongly supports universal childcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Jones supported the Climate Solutions Now Act phasing out fossil fuels and opposed new fossil fuel infrastructure in Maryland while supporting transition timeline.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Jones supported Medicare and Medicaid expansion efforts and has consistently opposed cuts to these programs throughout her legislative career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrienne A. Jones / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('760cd4a7-235c-472f-a0ba-fb07098dfd57',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Jones championed Blueprint for Maryland's Future as economic development through public education investment — supports government-led economic development with strong labor standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones', 'https://msa.maryland.gov/msa/mdmanual/06hse/html/msa02932.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Gabriel M. Moreno
-- ============================================================

-- ----- Gabriel M. Moreno / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Moreno co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently supported abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel M. Moreno / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Moreno supported the Climate Solutions Now Act and renewable energy legislation — favors aggressive climate action and clean energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel M. Moreno / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Moreno supported Medicaid expansion and healthcare access legislation — favors significant public health coverage expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel M. Moreno / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Moreno supported protections for DACA recipients and Maryland's Trust Act limiting local enforcement cooperation with ICE — strongly supports immigrant rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel M. Moreno / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Moreno co-sponsored civil rights legislation including anti-discrimination protections — strong advocate for civil rights in Howard County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel M. Moreno / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Moreno supported expanded voting access legislation including automatic registration and early voting expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel M. Moreno / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Moreno supports same-sex marriage and LGBTQ+ protections including trans youth healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel M. Moreno / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Moreno supported progressive tax reform to fund public services and Blueprint for Maryland's Future education investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel M. Moreno / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Moreno supported Blueprint for Maryland's Future — favors public school investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel M. Moreno / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Moreno supported affordable housing legislation and tenant protections in Howard County — favors mixed-income development with affordability requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01', 'https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Cheryl E. Pasteur
-- ============================================================

-- ----- Cheryl E. Pasteur / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Pasteur co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently voted for abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl E. Pasteur / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Pasteur supported the Climate Solutions Now Act and clean energy legislation — favors aggressive climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl E. Pasteur / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Pasteur supported Medicaid expansion and healthcare access legislation; co-sponsored bills expanding public health coverage — strongly supports government-led healthcare.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl E. Pasteur / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Pasteur co-sponsored the CROWN Act and other civil rights legislation — strong advocate for anti-discrimination protections in Baltimore County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl E. Pasteur / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Pasteur supported expanded voting access legislation including automatic registration and early voting expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl E. Pasteur / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Pasteur strongly supports same-sex marriage and LGBTQ+ protections — consistent supporter of equal rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl E. Pasteur / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Pasteur supported the Maryland Police Accountability Act and community investment programs — favors social services and community-based public safety approaches.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl E. Pasteur / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Pasteur supported progressive tax reform funding Blueprint for Maryland's Future through higher taxes on high earners.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl E. Pasteur / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Pasteur supported affordable housing legislation and tenant protections — favors significant affordable mandates with mixed-income development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl E. Pasteur / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Pasteur supported Blueprint for Maryland's Future — strongly advocates for public school investment over private school voucher diversion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01', 'https://ballotpedia.org/Cheryl_Pasteur']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- N. Scott Phillips
-- ============================================================

-- ----- N. Scott Phillips / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Phillips co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently voted for abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- N. Scott Phillips / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Phillips supported the Climate Solutions Now Act and renewable energy legislation — favors aggressive action on climate change.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- N. Scott Phillips / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Phillips supported Medicaid expansion and healthcare access legislation; favors significant expansion of public coverage while retaining mixed public/private system.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- N. Scott Phillips / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Phillips co-sponsored civil rights legislation including anti-discrimination protections in Baltimore County — strong supporter of civil rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- N. Scott Phillips / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Phillips supported expanded voting access legislation including automatic registration and early voting expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- N. Scott Phillips / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Phillips supports same-sex marriage and full LGBTQ+ legal rights — consistent supporter of LGBTQ+ protections in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- N. Scott Phillips / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Phillips supported progressive tax reforms including higher taxes on high earners to fund Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- N. Scott Phillips / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Phillips supported the Blueprint for Maryland's Future — advocates for public school investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- N. Scott Phillips / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Phillips supported affordable housing mandates and tenant protections in Baltimore County — favors mixed-income development with affordability requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- N. Scott Phillips / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04eb4549-ad64-4ddc-ad53-8f90217f905f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Phillips supported the Maryland Police Accountability Act and community investment in public safety — favors balanced approach with police reform and social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips04', 'https://ballotpedia.org/N._Scott_Phillips']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kim Ross
-- ============================================================

-- ----- Kim Ross / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ross co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has strongly supported abortion access legislation throughout her tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Ross / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ross co-sponsored Maryland's Climate Solutions Now Act and offshore wind development legislation — consistent supporter of aggressive climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Ross / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ross supported expanding Medicaid coverage in Maryland and co-sponsored healthcare access legislation — supports government-led healthcare expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Ross / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ross supported affordable housing mandates and tenant protections; has advocated for mixed-income development with affordability requirements in Baltimore County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Ross / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ross supported progressive tax measures funding Blueprint for Maryland's Future including higher taxes on high earners.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Ross / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ross co-sponsored voting access legislation expanding automatic registration and early voting — strongly supports voting access expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Ross / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ross co-sponsored the CROWN Act and has supported comprehensive civil rights legislation including anti-discrimination protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Ross / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Ross supports same-sex marriage and LGBTQ+ protections including gender-affirming care protections for minors.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Ross / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Ross supported the Blueprint for Maryland's Future prioritizing public education investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Ross / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Ross co-sponsored childcare subsidy expansion legislation to improve access for working families in Baltimore County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01', 'https://ballotpedia.org/Kim_Ross']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Gary Simmons
-- ============================================================

-- ----- Gary Simmons / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Simmons co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently supported abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gary Simmons / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Simmons supported the Climate Solutions Now Act and renewable energy legislation — favors aggressive climate action and clean energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gary Simmons / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Simmons supported Medicaid expansion and healthcare access legislation — favors significant expansion of public coverage.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gary Simmons / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Simmons co-sponsored civil rights legislation including anti-discrimination protections — strong supporter of civil rights in Howard County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gary Simmons / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Simmons supported expanded voting access legislation including automatic registration and early voting expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gary Simmons / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Simmons supports same-sex marriage and LGBTQ+ protections — consistent supporter of equal rights legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gary Simmons / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Simmons supported progressive tax reform including higher taxes on high earners to fund Blueprint for Maryland's Future education funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gary Simmons / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Simmons supported the Blueprint for Maryland's Future — advocates for public school investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gary Simmons / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Simmons supported affordable housing legislation and tenant protections in Howard County — favors mixed-income development with affordability requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gary Simmons / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69cbeb94-6978-4f3f-b8b7-735f789c6d3c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Simmons has supported public-private partnerships for economic development in Howard County — favors targeted public investment with labor standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simmons05', 'https://ballotpedia.org/Gary_Simmons_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Dana Stein
-- ============================================================

-- ----- Dana Stein / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Stein co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has been a consistent supporter of abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Stein is one of Maryland's most prominent environmental legislators — co-sponsored the Climate Solutions Now Act and has championed clean energy and pollution reduction throughout his career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Stein has consistently opposed fossil fuel expansion in Maryland and supported the phase-out of fossil fuels through the Climate Solutions Now Act.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Stein supported Medicaid expansion and healthcare access legislation — favors significant public coverage expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Stein co-sponsored civil rights legislation including anti-discrimination protections — strong supporter of civil rights in Baltimore County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Stein supported expanded voting access legislation including automatic registration and early voting expansion — strong supporter of voting rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Stein supports same-sex marriage and LGBTQ+ protections — consistent vote in favor of equal rights legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Stein supported progressive tax reform to fund public services including Blueprint for Maryland's Future education funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Stein supported the Blueprint for Maryland's Future — advocates for public school investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Stein supported affordable housing legislation and tenant protections — favors mixed-income development with affordability requirements in Baltimore County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Stein / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e94337e1-4776-4058-87b4-32dfeb7732a0',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Stein has supported independent redistricting reform and fair maps legislation in Maryland — opposes partisan gerrymandering.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein01', 'https://ballotpedia.org/Dana_Stein']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jen Terrasa
-- ============================================================

-- ----- Jen Terrasa / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Terrasa co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently supported abortion access legislation throughout her Maryland House tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jen Terrasa / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Terrasa supported the Climate Solutions Now Act and Howard County environmental initiatives — consistently favors aggressive climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jen Terrasa / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Terrasa supported Medicaid expansion and healthcare access legislation — favors significant public coverage expansion with mixed system.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jen Terrasa / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Terrasa has been active on Howard County housing policy — supports affordable housing mandates and mixed-income development with community involvement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jen Terrasa / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Terrasa co-sponsored civil rights legislation including anti-discrimination protections — strong supporter of civil rights expansion in Howard County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jen Terrasa / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Terrasa supported expanded voting access legislation including automatic registration and early voting — strong supporter of voting rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jen Terrasa / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Terrasa strongly supports same-sex marriage and LGBTQ+ protections including trans youth healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jen Terrasa / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Terrasa supported progressive tax reform to fund public services and Blueprint for Maryland's Future education investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jen Terrasa / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Terrasa supported Blueprint for Maryland's Future — advocates for public school investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jen Terrasa / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f45e2178-2a05-4974-8af8-379662412060',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Terrasa has championed economic development in Howard County through public-private partnerships while supporting worker protections and targeted public investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01', 'https://ballotpedia.org/Jen_Terrasa']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Courtney Watson
-- ============================================================

-- ----- Courtney Watson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Watson co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has been a consistent supporter of abortion access rights in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Courtney Watson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Watson supported the Climate Solutions Now Act and Maryland's offshore wind expansion — favors aggressive climate action and clean energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Courtney Watson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Watson supported Medicaid expansion and healthcare access legislation — favors significant expansion of public health coverage with mixed public/private approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Courtney Watson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Watson has been active on Howard County housing policy — supports affordable housing mandates and mixed-income development with community input.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Courtney Watson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Watson supports targeted tax increases on higher earners to fund education and services but has taken a balanced approach on business taxes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Courtney Watson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Watson co-sponsored CROWN Act and other civil rights protections — strong supporter of anti-discrimination legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Courtney Watson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Watson supported expanded voting access legislation including early voting expansion and automatic registration in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Courtney Watson / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Watson supports same-sex marriage and LGBTQ+ protections — consistent vote in favor of full legal recognition and anti-discrimination laws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Courtney Watson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Watson supported Blueprint for Maryland's Future public school investment and opposes diversion of public funds to private school vouchers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Courtney Watson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4b61b58-9006-4e58-952d-abeb2521cda0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Watson has championed public-private partnerships for economic development in Howard County while supporting worker protections and targeted public investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Courtney_Watson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Chao Wu
-- ============================================================

-- ----- Chao Wu / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Wu co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently voted for abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chao Wu / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Wu supported Maryland's Climate Solutions Now Act and renewable energy legislation — favors aggressive climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chao Wu / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wu co-sponsored healthcare expansion legislation and has supported Medicaid expansion — strongly supports government-led healthcare coverage.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chao Wu / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Wu supported protections for DACA recipients and sanctuary policies in Maryland — strongly supports immigrant rights and pathways to citizenship.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chao Wu / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Wu supported progressive tax reform including higher taxes on wealthy individuals to fund education and social services in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chao Wu / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wu co-sponsored the CROWN Act and other civil rights legislation — strong advocate for anti-discrimination protections in Montgomery County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chao Wu / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Wu supported expanded voting access legislation including automatic registration and same-day registration — strongly supports voting rights expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chao Wu / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Wu strongly supports same-sex marriage and LGBTQ+ rights including protections for transgender youth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chao Wu / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wu supported affordable housing mandates and tenant protection legislation in Montgomery County including Just Cause eviction protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chao Wu / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ced90a8-39dc-447e-ba33-e3af4cd47473',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Wu supported the Blueprint for Maryland's Future — strong advocate for public school funding over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01', 'https://ballotpedia.org/Chao_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Natalie Ziegler
-- ============================================================

-- ----- Natalie Ziegler / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ziegler co-sponsored HB 1171 (Pregnant Person's Freedom Act of 2024) and has consistently supported abortion access legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Natalie Ziegler / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ziegler supported the Climate Solutions Now Act and renewable energy legislation — consistently supports aggressive climate action.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Natalie Ziegler / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ziegler supported Medicaid expansion and healthcare access legislation — favors significant expansion of public health coverage.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Natalie Ziegler / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ziegler supported affordable housing mandates and tenant protections in Montgomery County — favors mixed-income development with affordability requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Natalie Ziegler / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ziegler supported progressive tax reform including higher taxes on high earners to fund Blueprint for Maryland's Future education funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Natalie Ziegler / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ziegler co-sponsored civil rights legislation including the CROWN Act and anti-discrimination protections — strong civil rights supporter.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Natalie Ziegler / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ziegler supported expanded voting access legislation — favors automatic registration and early voting expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Natalie Ziegler / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Ziegler supports same-sex marriage and LGBTQ+ protections including trans youth healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Natalie Ziegler / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Ziegler supported the Blueprint for Maryland's Future — advocates for public school investment over private school voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Natalie Ziegler / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38b5030a-aa8b-4363-8b62-3ec384d22088',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Ziegler supported legislation expanding childcare access and subsidies for working families in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler02', 'https://ballotpedia.org/Natalie_Ziegler']::text[]::text[])
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
-- WHERE p.id IN ('a1f58b34-76ee-43ce-b152-4843c42f4f79', '6d95657c-6c46-4aab-886f-f9688adc7b33', '5d17e3ea-9d63-4a96-8848-9e293ac05fdb', '7ced90a8-39dc-447e-ba33-e3af4cd47473', '38b5030a-aa8b-4363-8b62-3ec384d22088', 'a4b61b58-9006-4e58-952d-abeb2521cda0', '760cd4a7-235c-472f-a0ba-fb07098dfd57', '04eb4549-ad64-4ddc-ad53-8f90217f905f', 'd80816fc-da1d-48f4-95c9-467f8831933c', 'b5aee428-9b2e-4c87-9a5c-63d44f58e1d8', '631dac5c-fb86-41f5-a82d-5963164a9142', 'e94337e1-4776-4058-87b4-32dfeb7732a0', 'fdb9f7d3-93db-4436-bd82-5d7fd853f05e', 'f6a237a0-34ff-4a93-b05a-335ec38b6da3', '69cbeb94-6978-4f3f-b8b7-735f789c6d3c', '589ed7af-602a-4ec9-8072-448b05446772', 'c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec', 'f45e2178-2a05-4974-8af8-379662412060')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('a1f58b34-76ee-43ce-b152-4843c42f4f79', '6d95657c-6c46-4aab-886f-f9688adc7b33', '5d17e3ea-9d63-4a96-8848-9e293ac05fdb', '7ced90a8-39dc-447e-ba33-e3af4cd47473', '38b5030a-aa8b-4363-8b62-3ec384d22088', 'a4b61b58-9006-4e58-952d-abeb2521cda0', '760cd4a7-235c-472f-a0ba-fb07098dfd57', '04eb4549-ad64-4ddc-ad53-8f90217f905f', 'd80816fc-da1d-48f4-95c9-467f8831933c', 'b5aee428-9b2e-4c87-9a5c-63d44f58e1d8', '631dac5c-fb86-41f5-a82d-5963164a9142', 'e94337e1-4776-4058-87b4-32dfeb7732a0', 'fdb9f7d3-93db-4436-bd82-5d7fd853f05e', 'f6a237a0-34ff-4a93-b05a-335ec38b6da3', '69cbeb94-6978-4f3f-b8b7-735f789c6d3c', '589ed7af-602a-4ec9-8072-448b05446772', 'c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec', 'f45e2178-2a05-4974-8af8-379662412060')
--   AND pc.politician_id IS NULL;