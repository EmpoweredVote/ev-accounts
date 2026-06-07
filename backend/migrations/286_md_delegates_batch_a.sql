-- ============================================================================
-- Migration 286: MD Delegates Batch A — Districts 1-7
-- ============================================================================
-- Purpose: Insert/upsert stance data for 21 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~186 rows expected
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
-- Lauren Arikan
-- ============================================================

-- ----- Lauren Arikan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Arikan co-sponsored the Women's Freedom From Coercion Act prohibiting causing ingestion of an abortion-inducing drug without consent — strongly opposing abortion access in line with House Republican caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Arikan / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Arikan co-sponsored the Fairness in Girls' Sports Act designating athletic teams and locker rooms based on biological sex — strongly opposing transgender inclusion in women's sports.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Arikan / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Arikan co-sponsored the cross-sex hormone therapy for minors restriction and Fairness in Girls' Sports Act — strongly opposing expansions of LGBTQ+ civil rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Arikan / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Arikan co-sponsored immigration enforcement agreements (supporting ICE cooperation) and the sanctuary policy prohibition and correctional services immigration enforcement notification — strongly supporting deportation enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Arikan / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Arikan co-sponsored the Energy Equality Act prohibiting energy source restrictions and electric/gas surcharge repeal and Freedom From Monopolies Act — strongly supporting fossil fuel access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Arikan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Arikan co-sponsored the No Income Taxes on Tips Act and Corporate Income Tax Rate Reduction and income tax retirement income and overtime subtractions — strongly supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Arikan / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Arikan co-sponsored the Secure the Vote Act of 2026 — supporting voter ID and election security requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Arikan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Arikan co-sponsored police accountability investigation records restrictions while also supporting law enforcement — primarily favoring law enforcement over accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lauren Arikan / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a04e5b9-d532-4e80-bbca-6677a35620e5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Arikan co-sponsored limitations on juvenile confinement and restrictive housing (progressive) but also correctional diminution restrictions — mixed signals suggesting pragmatic case-by-case approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Terry L. Baker
-- ============================================================

-- ----- Terry L. Baker / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Baker sponsored the Women's Freedom From Coercion Act (HB) prohibiting causing ingestion of an abortion-inducing drug without consent — indicating anti-abortion stance and aligning with House Republican caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry L. Baker / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Baker sponsored repeal of Maryland's Building Energy Performance Standards and co-sponsored Energy Performance Standards exemptions and the Energy Equality Act of 2026 prohibiting energy source restrictions — strongly opposing climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry L. Baker / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Baker co-sponsored prohibition on electric companies collecting environmental surcharges and sponsored the Energy Equality Act of 2026 prohibiting consumer goods restrictions based on energy source — strongly supporting fossil fuel access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry L. Baker / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Baker co-sponsored the Education Savings Account Program and the Opting in on Opportunity Act certifying scholarship granting organizations — strongly supporting private school choice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry L. Baker / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Baker co-sponsored SAVE Our Elections Act (citizenship verification for voter registration) and in-person voting proof of identity requirements and the Secure the Vote Act of 2026 — strongly supporting voter ID laws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry L. Baker / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Baker co-sponsored both the sanctuary policy prohibition bill and correctional services immigration enforcement with required notice and transfer legislation — strongly supporting deportation enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry L. Baker / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Baker co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting and apportionment commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry L. Baker / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Baker co-sponsored the Corporate Income Tax Rate Reduction (Economic Competitiveness Act of 2026) — supporting tax cuts for businesses.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry L. Baker / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Baker co-sponsored prohibition on diminution credits for first-degree murder and criminal procedure restrictions on postconviction release for crimes resulting in death of young victims — punishment-first criminal justice stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry L. Baker / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Baker co-sponsored the sanctuary policy prohibition and immigration enforcement notification bills alongside Juvenile Offender Protection Act — law enforcement-first approach to public safety.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Christopher Eric Bouchat
-- ============================================================

-- ----- Christopher Eric Bouchat / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Bouchat sponsored the Sexual Offender Accountability and Victim Protection Act limiting parole for violent criminals and co-sponsored criminal procedure postconviction release restrictions — strongly favoring punishment over rehabilitation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Eric Bouchat / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Bouchat co-sponsored the SAVE Our Elections Act (citizenship verification for voter registration) and in-person voting proof of identity and the Secure the Vote Act of 2026 — strongly supporting voter ID laws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Eric Bouchat / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Bouchat co-sponsored income tax and sales/use tax rate reductions — strongly supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Eric Bouchat / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Bouchat co-sponsored the Vehicle Emissions Inspection Program repeal and solar energy construction restrictions in priority preservation areas — opposing climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Eric Bouchat / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Bouchat co-sponsored the Opting in on Opportunity Act certifying scholarship granting organizations — supporting private school choice programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Eric Bouchat / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Bouchat sponsored a redistricting bill favoring single-member districts rather than the independent commission approach co-sponsored by most Western MD Republicans — indicating a different structural preference for redistricting.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Eric Bouchat / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Bouchat sponsored legislation restricting parole for violent criminals and fentanyl distribution death penalty enhancement — strongly favoring law enforcement and prosecution over social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Eric Bouchat / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Bouchat co-sponsored the Freedom From Monopolies Act for retail electricity and gas supply — supporting deregulated fossil fuel energy markets.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Eric Bouchat / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c12bb600-318a-4541-bcdd-8260f1ba172e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Bouchat is a Republican from Carroll County who votes with the House Republican caucus on anti-abortion legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bouchat01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jason C. Buckel
-- ============================================================

-- ----- Jason C. Buckel / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Buckel is a Republican from Allegany County (Western MD) who consistently votes with the House Republican caucus on anti-abortion legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Buckel / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Buckel sponsored income tax standard deduction alteration and the Corporate Income Tax Rate Reduction (Economic Competitiveness Act of 2026) — strongly supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Buckel / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Buckel co-sponsored repeal of the Vehicle Emissions Inspection Program and prohibition on electric company environmental surcharges — opposing state climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Buckel / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Buckel co-sponsored prohibition on electric companies collecting environmental surcharges and natural gas connection discount legislation — supporting fossil fuel access over clean energy mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Buckel / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Buckel co-sponsored voter registration citizenship verification (SAVE Our Elections Act of 2026) and in-person voting proof of identity requirements — strongly supporting voter ID and opposing automatic registration.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Buckel / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Buckel co-sponsored the Opting in on Opportunity Act certifying scholarship granting organizations — supporting private school choice programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Buckel / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Buckel co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting and apportionment commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Buckel / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Buckel co-sponsored a bill prohibiting diminution credits for first-degree murder convictions — a punishment-first criminal justice approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Buckel / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Buckel co-sponsored a bill restricting public disclosure of police accountability investigation records for complaints that were unfounded or resulted in no charges — opposing expansive police accountability transparency.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason C. Buckel / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Buckel sponsored the Corporate Income Tax Rate Reduction Act of 2026 and Higher Education Transformative Economic Efficiency framework — favoring deregulation and tax incentives for business growth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/buckel01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Barrie S. Ciliberti
-- ============================================================

-- ----- Barrie S. Ciliberti / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ciliberti sponsored the Health Abortion Ultrasound and Wait Time bill imposing restrictions and co-sponsored the Women's Freedom From Coercion Act — strongly opposing abortion access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barrie S. Ciliberti / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ciliberti co-sponsored Building Energy Performance Standards repeal and sponsored the Vehicle Emissions Inspection Program testing alterations — strongly opposing climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barrie S. Ciliberti / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ciliberti co-sponsored prohibition on electric companies collecting environmental surcharges and the Renewable Energy Portfolio Standard nuclear renaming — supporting fossil fuel access over clean energy transitions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barrie S. Ciliberti / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Ciliberti co-sponsored the scholarship granting organizations certification bill (Opting in on Opportunity Act) — supporting private school choice programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barrie S. Ciliberti / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ciliberti co-sponsored the SAVE Our Elections Act (citizenship verification for voter registration) and in-person voting proof of identity and the Secure the Vote Act of 2026 — strongly supporting voter ID laws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barrie S. Ciliberti / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ciliberti co-sponsored the Corporate Income Tax Rate Reduction (Economic Competitiveness Act) and sponsored multiple property tax credit adjustments — supporting tax cuts for businesses and homeowners.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barrie S. Ciliberti / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Ciliberti co-sponsored the Juvenile Justice Restoration Act and Juvenile Offender Protection Act and Public Safety Police Accountability investigation records restriction — punishment-oriented criminal justice stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barrie S. Ciliberti / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Ciliberti is a Republican who benefits from current partisan redistricting and has not co-sponsored the Fair Districts for Maryland Act unlike some Western MD colleagues — preferring legislative control of redistricting.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ciliberti01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kris Fair
-- ============================================================

-- ----- Kris Fair / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Fair sponsored multiple civil rights bills including Confederate naming prohibitions and the gender-affirming care insurance coverage requirement — strongly supporting civil rights and LGBTQ+ protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kris Fair / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Fair sponsored the Voting Rights Act of 2026 for counties/municipalities and election absentee ballot reforms — strongly supporting expanded voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kris Fair / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Fair co-sponsored legislation prohibiting immigration enforcement agreements — strongly opposing deportation-focused policies and supporting sanctuary protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kris Fair / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Fair sponsored a workgroup on supporting transgender and gender diverse students — strongly supporting transgender inclusion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kris Fair / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Fair sponsored homeless individuals fee and examination exemptions and co-sponsored homeless shelter certification — supporting housing-first and service-oriented approaches to homelessness.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kris Fair / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Fair sponsored legislation targeting election misinformation$$,
        ARRAY['disinformation', 'and deepfakes — supporting platform/government action against political misinformation.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kris Fair / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Fair sponsored the Comprehensive Community Safety Funding Act — supporting investment in non-police public safety alternatives alongside enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kris Fair / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Fair sponsored the Maryland HEALTH Fund establishment and gender-affirming care insurance coverage requirements — supporting government expansion of healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kris Fair / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Fair sponsored the Maryland New Markets Development Program and Rural Readiness Program — supporting targeted public investment in community and rural economic development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jim Hinebaugh, Jr.
-- ============================================================

-- ----- Jim Hinebaugh, Jr. / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Hinebaugh is a Republican from heavily conservative Garrett County and consistently votes with House Republicans on anti-abortion measures. He has not publicly broken with his caucus on reproductive rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Hinebaugh, Jr. / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hinebaugh sponsored HB legislation to repeal Maryland's Building Energy Performance Standards and co-sponsored bills exempting buildings from energy use intensity targets — strongly opposing state climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Hinebaugh, Jr. / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Hinebaugh sponsored a bill prohibiting electric companies from collecting environmental surcharges or fees and co-sponsored natural gas discount/payment plan legislation — favoring fossil fuel access over clean energy transitions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Hinebaugh, Jr. / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Hinebaugh sponsored HB establishing an Education Savings Account Program (school vouchers) and co-sponsored the Opting in on Opportunity Act certifying scholarship granting organizations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Hinebaugh, Jr. / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hinebaugh sponsored voter registration citizenship verification legislation (SAVE Our Elections Act of 2026) and in-person voting proof of identity requirements — strongly supporting voter ID and opposing automatic registration.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Hinebaugh, Jr. / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Hinebaugh sponsored HB prohibiting sanctuary policies in Maryland — strongly supporting immigration enforcement and opposing sanctuary protections for undocumented immigrants.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Hinebaugh, Jr. / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Hinebaugh co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting and apportionment commission — supporting nonpartisan redistricting.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Hinebaugh, Jr. / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Hinebaugh sponsored a bill prohibiting diminution credits for first-degree murder convictions — a strong punishment-first approach to criminal justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Hinebaugh, Jr. / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Hinebaugh sponsored the Juvenile Offender Protection Act restricting certain convictions for Department of Juvenile Services employees and supported prohibition of sanctuary policies — law enforcement-first approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Hinebaugh, Jr. / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3817ad52-3f43-4bd3-8525-e7dcd0816153',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hinebaugh is a Republican from Western Maryland who consistently supports tax reduction measures and co-sponsored various fee prohibition bills including environmental surcharge bans.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hinebaugh01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Robin L. Grammer, Jr.
-- ============================================================

-- ----- Robin L. Grammer, Jr. / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Grammer sponsored the Fairness in Girls' Sports Act designating interscholastic teams based on sex at birth and co-sponsored cross-sex hormone therapy for minors restrictions — strongly opposing transgender inclusion in sports.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robin L. Grammer, Jr. / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Grammer sponsored expansive firearms rights legislation but also opposed cross-sex hormone therapy for minors — a mixed record that primarily favors restricting rather than expanding civil rights for LGBTQ+ individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robin L. Grammer, Jr. / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Grammer co-sponsored the sanctuary policy prohibition bill — strongly supporting immigration enforcement and opposing sanctuary protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robin L. Grammer, Jr. / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Grammer co-sponsored the Energy Equality Act (prohibiting energy source restrictions on consumer goods) and electric/gas customer bill surcharge repeal — strongly supporting fossil fuel access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robin L. Grammer, Jr. / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Grammer co-sponsored the Corporate Income Tax Rate Reduction and sponsored No Income Taxes on Tips Act — strongly supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robin L. Grammer, Jr. / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Grammer co-sponsored the Secure the Vote Act of 2026 — supporting voter ID and election integrity restrictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robin L. Grammer, Jr. / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Grammer sponsored no-knock search warrant repeal (civil libertarian) and correctional diminution of sentence but also supported juvenile sex offender registry expansion — mixed criminal justice record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robin L. Grammer, Jr. / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Grammer co-sponsored police accountability investigation records restriction and sponsored law enforcement quota prohibition — generally supporting law enforcement with some accountability nuances.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robin L. Grammer, Jr. / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Grammer sponsored the Property Rights Protection Act repealing eminent domain and condemnation authority — strongly opposing government intervention in property markets.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robin L. Grammer, Jr. / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0608cc7a-72ed-4d24-b966-3eee82075bf1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Grammer sponsored a bill requiring abortion data submission to the CDC — consistent with Republican restrictive abortion stance monitoring abortion statistics for potential restriction use.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kenneth Kerr
-- ============================================================

-- ----- Kenneth Kerr / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Kerr sponsored the Pregnancy Outcome Protection Act prohibiting certain actions related to pregnancy loss — supporting reproductive protections consistent with a pro-choice Democratic position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth Kerr / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        '24e9212c-b011-422a-865c-093e35050901',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Kerr sponsored the Anti-Nuclear Proliferation Resolution (Back from the Brink Act) — calling for nuclear disarmament and de-escalation in line with a peace-oriented foreign policy strongly supporting diplomatic approaches.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth Kerr / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Kerr co-sponsored the Lower Bills and Local Power Act of 2026 reforming electricity transmission and expanding energy storage — supporting clean energy transition over fossil fuel continuation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth Kerr / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kerr co-sponsored the Maryland Transit and Housing Opportunity Act on transit-oriented development — supporting increased density near transit while maintaining some affordability standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth Kerr / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Kerr co-sponsored drug and alcohol treatment programs discharge standards and predetermination review for occupational licensing with criminal history — supporting rehabilitation and second chances.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth Kerr / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kerr sponsored HIV prevention and treatment (Rapid Testing and Preventive Care Act) and the Public Health Reform Act — supporting expanded government healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth Kerr / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Kerr co-sponsored homeless individuals fee and examination exemptions — supporting service-oriented approaches to homelessness.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth Kerr / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kerr sponsored Department of Social and Economic Mobility for individuals with disabilities and co-sponsored Rural Readiness Program — supporting targeted public investment in vulnerable communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Robert B. Long
-- ============================================================

-- ----- Robert B. Long / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Long co-sponsored the SAVE Our Elections Act (citizenship verification for voter registration) and in-person voting proof of identity and the Secure the Vote Act of 2026 — strongly supporting voter ID laws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robert B. Long / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Long co-sponsored the Opting in on Opportunity Act certifying scholarship granting organizations — supporting private school choice programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robert B. Long / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Long co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robert B. Long / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Long co-sponsored income tax standard deduction alteration and multiple Baltimore County property tax credit bills — supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robert B. Long / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Long co-sponsored Building Energy Performance Standards repeal — opposing state climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robert B. Long / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Long co-sponsored prohibition on electric company environmental surcharges and the Freedom From Monopolies Act for retail electricity and gas — supporting fossil fuel market access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robert B. Long / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Long co-sponsored prohibition on diminution credits for first-degree murder and criminal procedure postconviction release restrictions — punishment-first criminal justice stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robert B. Long / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Long is a Republican from Baltimore County (District 6) who votes with the House Republican caucus on anti-abortion legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robert B. Long / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eadb65c9-74b6-40c3-b9e7-159c5734c59f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Long sponsored a moratorium on property assessment increases and multiple first-time homebuyer exemptions — favoring market-oriented housing approaches with targeted tax relief rather than affordable mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/long01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ric Metzgar
-- ============================================================

-- ----- Ric Metzgar / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Metzgar sponsored the Heartbeat Bill (Public Health - Abortion Heartbeat Bill) — strongly opposing abortion access in a near-total ban approach based on fetal heartbeat detection.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ric Metzgar / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Metzgar sponsored the Ten Commandments Monument Display Act at the State House and school chaplain volunteer aide legislation — strongly supporting expansive religious expression in government settings.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ric Metzgar / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Metzgar co-sponsored Building Energy Performance Standards repeal — strongly opposing state climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ric Metzgar / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Metzgar co-sponsored prohibition on electric company environmental surcharges and the Freedom From Monopolies Act for retail electricity and gas — supporting fossil fuel market access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ric Metzgar / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Metzgar co-sponsored the Secure the Vote Act of 2026 and in-person voting proof of identity — supporting voter ID and election integrity restrictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ric Metzgar / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Metzgar co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ric Metzgar / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Metzgar co-sponsored the Corporate Income Tax Rate Reduction (Economic Competitiveness Act of 2026) — supporting business tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ric Metzgar / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ba85b633-32cf-4617-923c-3a325f39894e',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Metzgar co-sponsored the first-degree murder diminution credit prohibition and Juvenile Justice Restoration Act but also co-sponsored the Incarcerated Individual Apprenticeship Pilot Program — primarily punishment-focused with some rehabilitation support.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- April Miller
-- ============================================================

-- ----- April Miller / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Miller co-sponsored the SAVE Our Elections Act (citizenship verification for voter registration) and in-person voting proof of identity — supporting voter ID requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Miller / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Miller co-sponsored the Opting in on Opportunity Act certifying scholarship granting organizations — supporting private school choice programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Miller / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Miller co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting commission — supporting nonpartisan redistricting.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Miller / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Miller co-sponsored the income tax standard deduction alteration — supporting tax cuts for individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Miller / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Miller co-sponsored the Juvenile Justice Restoration Act and Juvenile Offender Protection Act — supporting enforcement-oriented juvenile justice approaches.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Miller / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Miller is a Republican from Frederick County who votes with the House Republican caucus on anti-abortion measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Miller / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b389687f-817b-4fda-8770-a888029f4629',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Miller co-sponsored solar energy construction restrictions in priority preservation areas — indicating some skepticism toward aggressive solar/clean energy expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller03']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ryan Nawrocki
-- ============================================================

-- ----- Ryan Nawrocki / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Nawrocki co-sponsored the Fairness in Girls' Sports Act designating interscholastic teams and locker rooms based on sex — strongly opposing transgender inclusion in athletics.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Nawrocki / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Nawrocki co-sponsored the cross-sex hormone therapy for minors restriction and Fairness in Girls' Sports Act — opposing LGBTQ+ civil rights expansions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Nawrocki / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Nawrocki co-sponsored both the sanctuary policy prohibition and correctional services immigration enforcement notification bills — strongly supporting deportation enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Nawrocki / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Nawrocki co-sponsored the Energy Equality Act prohibiting energy source restrictions and electric/gas surcharge repeal and the Freedom From Monopolies Act — strongly supporting fossil fuel market access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Nawrocki / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Nawrocki sponsored the No Income Taxes on Tips Act and co-sponsored income tax retirement income subtraction and state transfer tax temporary suspension — strongly supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Nawrocki / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Nawrocki co-sponsored the Secure the Vote Act of 2026 — supporting voter ID and election security restrictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Nawrocki / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Nawrocki co-sponsored abortion data submission to the CDC legislation — consistent with anti-abortion monitoring stance of House Republican caucus in Baltimore County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Nawrocki / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Nawrocki co-sponsored correctional services diminution of confinement legislation — supporting some sentencing reduction mechanisms while primarily voting with Republican caucus on criminal justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan Nawrocki / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5224e0c-0761-4ca7-a889-ed44517e2b91',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Nawrocki sponsored the Right to Learn Act (alternative school options) — supporting school choice though not specifically voucher legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jesse T. Pippy
-- ============================================================

-- ----- Jesse T. Pippy / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Pippy is a Republican who has honored conservative activist Charlie Kirk and consistently votes with the House Republican caucus on anti-abortion legislation in Frederick County District 4.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse T. Pippy / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Pippy co-sponsored Building Energy Performance Standards repeal and Vehicle Emissions Inspection Program repeal and solar energy construction restrictions in preservation areas — strongly opposing climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse T. Pippy / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Pippy co-sponsored prohibition on electric company environmental surcharges and the Energy Savings Act of 2026 reforming retail electricity supply — supporting fossil fuel access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse T. Pippy / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Pippy co-sponsored the SAVE Our Elections Act (citizenship verification for voter registration) and in-person voting proof of identity and the Secure the Vote Act of 2026 — strongly supporting voter ID laws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse T. Pippy / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Pippy co-sponsored the Opting in on Opportunity Act certifying scholarship granting organizations — supporting private school choice programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse T. Pippy / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Pippy co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse T. Pippy / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Pippy co-sponsored income tax standard deduction alteration and the Corporate Income Tax Rate Reduction (Economic Competitiveness Act of 2026) — strongly supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse T. Pippy / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Pippy co-sponsored prohibition on diminution credits for first-degree murder and the Juvenile Justice Restoration Act and Juvenile Offender Protection Act — punishment-first criminal justice stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse T. Pippy / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Pippy sponsored a resolution honoring conservative activist Charlie Kirk — indicating alignment with conservative positions that limit civil rights expansions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jesse T. Pippy / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Pippy sponsored firearm waiting period exceptions for law enforcement and co-sponsored drug distribution death penalty enhancement bill — law enforcement-centered approach to public safety.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pippy01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- April Rose
-- ============================================================

-- ----- April Rose / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Rose co-sponsored the SAVE Our Elections Act (citizenship verification for voter registration) and in-person voting proof of identity — strongly supporting voter ID laws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Rose / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Rose co-sponsored the Opting in on Opportunity Act certifying scholarship granting organizations — supporting private school choice programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Rose / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Rose co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Rose / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Rose co-sponsored the Corporate Income Tax Rate Reduction (Economic Competitiveness Act of 2026) — supporting business tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Rose / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Rose co-sponsored solar energy construction restrictions in priority preservation areas — indicating skepticism toward unrestricted renewable energy expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Rose / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Rose co-sponsored natural gas connection discount legislation and the Energy Savings Act of 2026 for retail electricity and gas — supporting fossil fuel access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Rose / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Rose co-sponsored prohibition on diminution credits for first-degree murder and the Juvenile Justice Restoration Act — punishment-first criminal justice stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- April Rose / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5967c703-2583-466f-a438-c3ac182111d5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Rose is a Republican from Carroll County who votes with the House Republican caucus on anti-abortion legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rose01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Matthew J. Schindler
-- ============================================================

-- ----- Matthew J. Schindler / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Schindler sponsored multiple bills prohibiting government real property from bearing Confederate names and established a commission to study the same — supporting civil rights and opposing Confederate memorialization.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schindler01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew J. Schindler / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Schindler sponsored legislation providing incarcerated individuals with identification documents (driver's licenses$$,
        ARRAY['birth certificates) and an apprenticeship pilot program for incarcerated individuals — supporting rehabilitation over punishment.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/schindler01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew J. Schindler / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Schindler sponsored collective bargaining legislation for local government employees and heat protection for greenhouse workers — strongly supporting worker protections and labor rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schindler01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew J. Schindler / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Schindler co-sponsored AI health insurance accountability legislation requiring human evaluation for insurance decisions — supporting consumer health protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schindler01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew J. Schindler / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Schindler sponsored minimum mandatory standards for immigration detention facilities and private detention facility zoning requirements — supporting humane treatment for detainees over mass enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schindler01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew J. Schindler / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Schindler co-sponsored the Maryland Housing Certainty Act on development rights and land use permitting — supporting measured housing development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schindler01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew J. Schindler / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Schindler sponsored municipalities body-worn camera legislation and a law enforcement face covering prohibition alongside drug distribution penalties — balanced approach to public safety.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schindler01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Karen Simpson
-- ============================================================

-- ----- Karen Simpson / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Simpson sponsored repeal of drug paraphernalia prohibitions and limitations on juvenile confinement and restrictive housing and the Exonerated 5 Act (limiting admissibility of custodial interrogations of minors) — strongly favoring rehabilitation and opposing punitive approaches.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Simpson / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Simpson co-sponsored both the immigration enforcement agreements prohibition bill and the Community Trust Act prohibiting correctional services from cooperating with immigration enforcement — strongly opposing deportation enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Simpson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Simpson sponsored the Youth Delinquency Prevention Fund and police training on autism and dementia (LEAD Act) — supporting social services and training alongside enforcement as a public safety approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Simpson / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Simpson co-sponsored homeless individuals fee and examination exemptions — supporting service-oriented approaches to homelessness.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Simpson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Simpson co-sponsored the Maryland Transit and Housing Opportunity Act on transit-oriented development — supporting increased density near transit to address housing needs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Simpson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Simpson sponsored the African American Heritage Preservation Program alterations and Exonerated 5 Act and Survivor Reporting Reform Act — strongly championing civil rights and racial justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Simpson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5946ad0c-ddf5-4674-840e-6968105042cd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Simpson co-sponsored the Collective Bargaining - Public Employees legislation on strike rights — supporting labor protections and worker rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kathy Szeliga
-- ============================================================

-- ----- Kathy Szeliga / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Szeliga co-sponsored the Fairness in Girls' Sports Act designating athletic teams and locker rooms based on biological sex — strongly opposing transgender inclusion in women's sports.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Szeliga / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Szeliga co-sponsored the cross-sex hormone therapy for minors restriction and Fairness in Girls' Sports Act — strongly opposing expansions of LGBTQ+ civil rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Szeliga / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Szeliga sponsored immigration enforcement agreements (supporting ICE cooperation) and co-sponsored both the sanctuary policy prohibition and correctional services immigration enforcement notification — strongly supporting deportation enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Szeliga / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Szeliga co-sponsored the Energy Equality Act prohibiting energy source restrictions and electric/gas surcharge repeal — strongly supporting fossil fuel access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Szeliga / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Szeliga co-sponsored the No Income Taxes on Tips Act and Corporate Income Tax Rate Reduction and income tax overtime and retirement income subtractions — strongly supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Szeliga / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Szeliga co-sponsored the Secure the Vote Act of 2026 — supporting voter ID and election security requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Szeliga / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Szeliga co-sponsored abortion data submission to the CDC legislation — consistent with anti-abortion monitoring and restrictive stance of the House Republican caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Szeliga / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Szeliga sponsored multiple healthcare regulatory bills (nursing home requirements$$,
        ARRAY['pharmacy agreements', 'insurer provider panels) — favoring market-based healthcare regulation rather than government expansion of coverage.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Szeliga / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0945acd2-cb51-49ad-a22f-6043d2e61520',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Szeliga co-sponsored the Right to Learn Act providing alternative school options — supporting school choice without specifically endorsing voucher programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Chris Tomlinson
-- ============================================================

-- ----- Chris Tomlinson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Tomlinson co-sponsored the SAVE Our Elections Act (citizenship verification for voter registration) and in-person voting proof of identity — strongly supporting voter ID laws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Tomlinson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Tomlinson co-sponsored the Opting in on Opportunity Act certifying scholarship granting organizations — supporting private school choice programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Tomlinson / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Tomlinson co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Tomlinson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Tomlinson co-sponsored the Corporate Income Tax Rate Reduction (Economic Competitiveness Act of 2026) and multiple income tax credit and subtraction modifications — supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Tomlinson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Tomlinson co-sponsored the Vehicle Emissions Inspection Program repeal and solar energy construction restrictions in preservation areas — opposing climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Tomlinson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Tomlinson sponsored repeal of electric and gas company customer bill surcharges — opposing clean energy surcharges and supporting fossil fuel market access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Tomlinson / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Tomlinson co-sponsored prohibition on diminution credits for first-degree murder and the Sexual Offender Accountability and Victim Protection Act limiting parole — strongly favoring punishment over rehabilitation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Tomlinson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Tomlinson co-sponsored fentanyl/heroin distribution death penalty legislation and parole limitation for violent criminals — strongly favoring prosecution and incarceration.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Tomlinson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Tomlinson is a Republican from Carroll County who votes with the House Republican caucus on anti-abortion legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/tomlinson01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- William Valentine
-- ============================================================

-- ----- William Valentine / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Valentine co-sponsored the Women's Freedom From Coercion Act prohibiting causing ingestion of an abortion-inducing drug without consent — aligning with House Republican anti-abortion caucus from Washington/Frederick Counties.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William Valentine / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Valentine sponsored income tax and sales/use tax rate reductions and income tax standard deduction alteration and co-sponsored the Corporate Income Tax Rate Reduction — strongly supporting tax cuts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William Valentine / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Valentine co-sponsored Building Energy Performance Standards repeal and Vehicle Emissions Inspection Program repeal and the Energy Equality Act of 2026 — strongly opposing climate mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William Valentine / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Valentine co-sponsored the Energy Equality Act (prohibiting energy source restrictions on consumer goods) and electric company environmental surcharge prohibition and natural gas discount legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William Valentine / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Valentine co-sponsored the SAVE Our Elections Act (citizenship verification)$$,
        ARRAY['in-person voting proof of identity', 'absentee ballot signature verification', 'and the Secure the Vote Act of 2026.']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William Valentine / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Valentine co-sponsored the sanctuary policy prohibition and correctional services immigration enforcement notification bills — strongly supporting deportation enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William Valentine / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Valentine co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William Valentine / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Valentine co-sponsored the Education Savings Account Program and the scholarship granting organizations certification bill — supporting private school choice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William Valentine / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Valentine co-sponsored prohibition on diminution credits for first-degree murder and criminal procedure restrictions on postconviction release for crimes resulting in death of young victims.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William Valentine / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cdf746c1-8311-416b-9ad3-2684a83b6992',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Valentine co-sponsored sanctuary policy prohibition$$,
        ARRAY['immigration enforcement notification', 'Juvenile Offender Protection Act — law enforcement-first approach to public safety.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- William J. Wivell
-- ============================================================

-- ----- William J. Wivell / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Wivell co-sponsored income tax and sales/use tax rate reductions and income tax standard deduction alteration — strongly supporting tax cuts for individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Wivell / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Wivell co-sponsored Building Energy Performance Standards repeal and exemptions$$,
        ARRAY['Vehicle Emissions Inspection Program repeal', 'and the Energy Equality Act of 2026 — strongly opposing climate mandates.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Wivell / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Wivell co-sponsored the Energy Equality Act prohibiting energy source restrictions and electric company environmental surcharge prohibition and sponsored legislation related to the Regional Greenhouse Gas Initiative changes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Wivell / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Wivell co-sponsored the SAVE Our Elections Act (citizenship verification for voter registration)$$,
        ARRAY['in-person voting proof of identity', 'and the Secure the Vote Act of 2026 — strongly supporting voter ID laws.', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Wivell / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Wivell co-sponsored the sanctuary policy prohibition and correctional services immigration enforcement with required notice and transfer — strongly supporting deportation enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Wivell / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Wivell co-sponsored the Fair Districts for Maryland Act establishing an independent redistricting and apportionment commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Wivell / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Wivell co-sponsored the Education Savings Account Program and the scholarship granting organizations certification bill — supporting private school choice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Wivell / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Wivell co-sponsored prohibition on diminution credits for first-degree murder and criminal procedure restrictions on postconviction release for crimes resulting in death of young victims.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Wivell / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wivell sponsored legislation on accessory dwelling units with a historic district exemption — acknowledging some need for housing flexibility while protecting historic areas.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William J. Wivell / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Wivell is a Republican from Washington County who votes with the House Republican caucus on anti-abortion legislation in the MD General Assembly.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wivell01', 'https://ballotpedia.org/Maryland_House_of_Delegates']::text[]::text[])
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
-- WHERE p.id IN ('3817ad52-3f43-4bd3-8525-e7dcd0816153', '5260bd6f-e70a-46f1-aa7d-49eaf22192cf', 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66', 'cdf746c1-8311-416b-9ad3-2684a83b6992', 'df6fe96f-7795-4934-9acc-2b9f8f0aa8f7', '18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5', 'dfb9ae21-4605-4c58-94e8-84b1eb1a30c1', 'c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255', '5946ad0c-ddf5-4674-840e-6968105042cd', '00a1eaeb-157c-42f8-a6e5-9a9d02decbe9', 'b389687f-817b-4fda-8770-a888029f4629', 'ce2fc441-abd5-4d8f-9c56-114e31c4d43c', 'c12bb600-318a-4541-bcdd-8260f1ba172e', '5967c703-2583-466f-a438-c3ac182111d5', '6e5ac4b7-73fd-497d-a4e9-7d5124c3d904', '0608cc7a-72ed-4d24-b966-3eee82075bf1', 'eadb65c9-74b6-40c3-b9e7-159c5734c59f', 'ba85b633-32cf-4617-923c-3a325f39894e', 'f5224e0c-0761-4ca7-a889-ed44517e2b91', '0945acd2-cb51-49ad-a22f-6043d2e61520', '6a04e5b9-d532-4e80-bbca-6677a35620e5')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('3817ad52-3f43-4bd3-8525-e7dcd0816153', '5260bd6f-e70a-46f1-aa7d-49eaf22192cf', 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66', 'cdf746c1-8311-416b-9ad3-2684a83b6992', 'df6fe96f-7795-4934-9acc-2b9f8f0aa8f7', '18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5', 'dfb9ae21-4605-4c58-94e8-84b1eb1a30c1', 'c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255', '5946ad0c-ddf5-4674-840e-6968105042cd', '00a1eaeb-157c-42f8-a6e5-9a9d02decbe9', 'b389687f-817b-4fda-8770-a888029f4629', 'ce2fc441-abd5-4d8f-9c56-114e31c4d43c', 'c12bb600-318a-4541-bcdd-8260f1ba172e', '5967c703-2583-466f-a438-c3ac182111d5', '6e5ac4b7-73fd-497d-a4e9-7d5124c3d904', '0608cc7a-72ed-4d24-b966-3eee82075bf1', 'eadb65c9-74b6-40c3-b9e7-159c5734c59f', 'ba85b633-32cf-4617-923c-3a325f39894e', 'f5224e0c-0761-4ca7-a889-ed44517e2b91', '0945acd2-cb51-49ad-a22f-6043d2e61520', '6a04e5b9-d532-4e80-bbca-6677a35620e5')
--   AND pc.politician_id IS NULL;