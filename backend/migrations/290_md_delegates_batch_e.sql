-- ============================================================================
-- Migration 290: MD Delegates Batch E — Districts 28-33
-- ============================================================================
-- Purpose: Insert/upsert stance data for 18 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~176 rows expected
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
-- Heather Bagnall
-- ============================================================

-- ----- Heather Bagnall / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Bagnall has been a strong supporter of abortion access legislation including co-sponsoring the Abortion Care Access Act (HB 1171 2023) and consistently voting to protect reproductive healthcare rights in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Bagnall has co-sponsored healthcare expansion legislation including Medicaid coverage measures and prescription drug affordability bills serving on health committees in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Bagnall has supported the Climate Solutions Now Act and Maryland's renewable energy agenda prioritizing clean energy investment and emissions reduction targets for the state.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Bagnall has supported affordable housing production and tenant protection legislation addressing affordability challenges in HD-33C communities in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Bagnall has supported automatic voter registration and expanded voting access as part of the House Democratic caucus agenda on election access in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Bagnall has supported progressive revenue legislation to fund the Blueprint for Maryland's Future and healthcare expansion programs serving her diverse Anne Arundel County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Bagnall has opposed private school voucher programs and supported full public school funding through the Blueprint for Maryland's Future for HD-33C communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Bagnall has co-sponsored civil rights and anti-discrimination legislation in the Maryland House and has supported police accountability reform measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Bagnall has supported targeted economic development for Anne Arundel County including workforce development and small business assistance programs in the Annapolis-area communities she represents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Bagnall has co-sponsored childcare affordability legislation and supported pre-K expansion under the Blueprint for Maryland's Future for families in her district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Bagnall has supported police accountability reforms and investment in mental health and community-based public safety programs while maintaining support for well-funded law enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Bagnall / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41749b94-11b8-4047-8421-95db0900d4b2',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Bagnall has supported LGBTQ+ civil rights and same-sex marriage protections as part of her progressive legislative agenda in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall?tab=2026RS-legislation', 'https://ballotpedia.org/Heather_Bagnall']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- J. Sandy Bartlett
-- ============================================================

-- ----- J. Sandy Bartlett / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Bartlett has supported abortion access legislation in Maryland including co-sponsoring the Abortion Care Access Act and consistently voting to protect and expand reproductive healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Bartlett has been a consistent champion of healthcare access legislation including Medicaid expansion and prescription drug cost reduction measures serving on health-related committees.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Bartlett has supported the Climate Solutions Now Act and clean energy investment legislation prioritizing Maryland's transition to renewable energy to address climate change.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Bartlett has supported affordable housing measures including rent stabilization and affordable housing production incentives to address housing costs in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Bartlett has supported automatic voter registration and expanded voting access legislation as part of the Democratic caucus agenda in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Bartlett has supported progressive revenue measures to fund education and healthcare including the Blueprint for Maryland's Future funding legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Bartlett has opposed school voucher programs and has been an advocate for public school funding and the implementation of the Blueprint for Maryland's Future in Anne Arundel schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Bartlett has co-sponsored civil rights and anti-discrimination legislation in the Maryland House and supported police accountability reform measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Bartlett has supported workforce development and targeted economic development legislation for Anne Arundel County including programs supporting defense contractor transitions and technology sector growth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Bartlett has co-sponsored childcare affordability legislation and supported pre-K expansion under the Blueprint for Maryland's Future for Anne Arundel County families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J. Sandy Bartlett / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d818044-a989-47e1-b6cf-d482ebad0600',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Bartlett has supported police accountability reforms and investment in mental health and social services as part of a balanced public safety approach in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bartlett04?tab=2026RS-legislation', 'https://ballotpedia.org/Sandy_Bartlett']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Dylan Behler
-- ============================================================

-- ----- Dylan Behler / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Behler has supported abortion access legislation in Maryland including voting in favor of the Abortion Care Access Act and reproductive healthcare expansion measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan Behler / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Behler has co-sponsored healthcare affordability legislation including measures to control prescription drug costs and expand Medicaid coverage for Anne Arundel County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan Behler / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Behler has supported the Climate Solutions Now Act and clean energy legislation prioritizing Maryland's transition to renewable energy and reducing carbon emissions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan Behler / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Behler has supported affordable housing legislation and zoning reform measures to address housing affordability challenges in Anne Arundel County including transit-oriented development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan Behler / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Behler has supported voting access expansion measures including automatic voter registration and has voted against restrictive voter identification requirements in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan Behler / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Behler has co-sponsored progressive revenue legislation to fund the Blueprint for Maryland's Future education reforms and healthcare expansion programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan Behler / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Behler has opposed school voucher legislation and supported fully funding public education through the Blueprint for Maryland's Future in Anne Arundel County schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan Behler / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Behler has supported anti-discrimination legislation and police accountability reforms in Maryland consistent with the progressive wing of the House Democratic caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan Behler / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Behler has supported public-private economic development in Anne Arundel County including workforce development programs and small business assistance measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan Behler / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f45bad5-b856-4d8e-b3d9-8c03623e030a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Behler has supported childcare affordability legislation including pre-K expansion and childcare subsidy programs under the Blueprint for Maryland's Future framework.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/behler?tab=2026RS-legislation', 'https://ballotpedia.org/Dylan_Behler']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mark S. Chang
-- ============================================================

-- ----- Mark S. Chang / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Chang has supported abortion access legislation in Maryland including voting for the Abortion Care Access Act and co-sponsoring reproductive healthcare bills consistent with the House Democratic caucus position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Chang has co-sponsored healthcare affordability legislation including prescription drug pricing reform and Medicaid expansion measures to improve healthcare access for Anne Arundel County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Chang has supported the Climate Solutions Now Act and clean energy investment as part of Maryland's climate agenda prioritizing emissions reduction and the transition to renewable energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Chang has supported affordable housing production legislation and renter protection measures addressing affordability challenges in Anne Arundel County's competitive housing market.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Chang has supported voting access expansion legislation including automatic voter registration and opposed restrictive voter ID measures as part of the House Democratic caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Chang has supported progressive taxation to fund public education and healthcare including Blueprint for Maryland's Future revenue measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Chang has opposed school voucher programs and supported full public school funding as essential to quality education in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Chang has co-sponsored civil rights and anti-discrimination legislation in the Maryland House and has been active on AAPI community issues and anti-hate crime measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Chang has supported targeted economic development legislation including technology sector growth and small business assistance programs for Anne Arundel County communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Chang has co-sponsored childcare affordability and pre-K expansion bills as part of his support for the Blueprint for Maryland's Future education reform agenda.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark S. Chang / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a409af4-8568-42c3-bb72-7bb7500c96ce',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Chang has supported AI regulation and transparency requirements citing the need to protect consumers and workers from harmful AI applications while supporting innovation in Maryland's technology sector.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation', 'https://ballotpedia.org/Mark_Chang']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Brian Chisholm
-- ============================================================

-- ----- Brian Chisholm / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Chisholm is a Republican from Anne Arundel County who has voted against abortion access legislation in Maryland and has publicly opposed the Abortion Care Access Act on pro-life grounds.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Chisholm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Chisholm / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Chisholm has opposed aggressive climate mandates in Maryland voting against key provisions of the Climate Solutions Now Act citing excessive costs to residents and small businesses.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Chisholm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Chisholm / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Chisholm has opposed rapid fossil fuel phase-out mandates and supported balanced energy policy that maintains affordable options for Maryland consumers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Chisholm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Chisholm / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Chisholm has consistently opposed tax increases on businesses and high earners co-sponsoring Republican tax relief proposals to reduce the burden on Maryland families and job creators.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Chisholm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Chisholm / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Chisholm has supported school choice legislation including private school scholarship programs and has been a consistent advocate for alternatives to public schools in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Chisholm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Chisholm / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Chisholm has supported voter ID requirements and opposed automatic voter registration expansions as part of the House Republican election security platform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Chisholm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Chisholm / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Chisholm has supported stricter immigration enforcement and opposed sanctuary policies in Maryland consistent with Anne Arundel County Republican voter priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Chisholm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Chisholm / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Chisholm has strongly favored deregulation and tax cuts to drive private sector economic growth in Maryland opposing government-directed economic development programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Chisholm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Chisholm / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Chisholm has emphasized law enforcement and prosecution as the primary tools of public safety and opposed efforts to reduce police funding or divert resources to social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Chisholm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Brian M. Crosby
-- ============================================================

-- ----- Brian M. Crosby / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Crosby has supported abortion access legislation in the Maryland House including co-sponsoring the Abortion Care Access Act (HB 1171 2023) and opposing gestational limits.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Crosby']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Crosby / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Crosby has supported healthcare expansion legislation including Medicaid coverage expansions and healthcare affordability measures for St. Mary's County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Crosby']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Crosby / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Crosby has supported the Climate Solutions Now Act and clean energy investment while balancing concerns about economic impacts on the military-dependent economy of Southern Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Crosby']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Crosby / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Crosby has supported affordable housing measures including legislation to expand housing production and tenant protections in Southern Maryland communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Crosby']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Crosby / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Crosby has supported voting access expansion legislation consistent with the Maryland Democratic caucus position on automatic registration and early voting.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Crosby']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Crosby / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Crosby has generally supported progressive revenue measures to fund Blueprint education requirements while being mindful of economic conditions in his military-heavy district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Crosby']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Crosby / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Crosby has opposed school voucher legislation that would divert public school funding and has supported fully funding the Blueprint for Maryland's Future in St. Mary's County schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Crosby']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Crosby / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Crosby has championed economic diversification for Southern Maryland including supporting development near the Patuxent River Naval Air Station and technology sector investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Crosby']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Crosby / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('898845f9-cb93-4162-b0ed-6842eacda5d6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Crosby has supported civil rights and anti-discrimination legislation in the Maryland House consistent with the House Democratic caucus agenda.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation', 'https://ballotpedia.org/Brian_Crosby']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Debra Davis
-- ============================================================

-- ----- Debra Davis / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Davis has been a consistent supporter of abortion access in Maryland. She co-sponsored HB 1171 (2023) the Abortion Care Access Act expanding access to reproductive healthcare services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Debra Davis / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Davis has co-sponsored multiple healthcare expansion bills including HB 1196 expanding Medicaid coverage and supporting universal coverage frameworks for Maryland residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Debra Davis / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Davis has supported affordable housing legislation in Maryland including measures to expand rental assistance and affordable housing production in Prince George's and Charles counties.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Debra Davis / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Davis has supported Maryland's climate agenda including the Climate Solutions Now Act implementation and bills targeting greenhouse gas reductions in the state.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Debra Davis / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Davis has co-sponsored voting expansion legislation including same-day registration and automatic voter registration measures in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Debra Davis / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Davis has supported progressive tax measures in Maryland including legislation to increase the top marginal income tax rate on high earners.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Debra Davis / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Davis has supported increased public school funding and pre-K expansion through the Blueprint for Maryland's Future as a member of the House Education Committee.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Debra Davis / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$As a strong public school advocate Davis has consistently opposed school voucher and private school scholarship programs that divert public funds.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Debra Davis / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Davis has been a vocal champion of civil rights legislation and has co-sponsored police accountability measures and anti-discrimination bills in the Maryland General Assembly.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Debra Davis / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Davis has supported targeted economic development legislation including workforce training programs and small business assistance for Southern Maryland communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis01?tab=2026RS-legislation', 'https://ballotpedia.org/Debra_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Seth A. Howard
-- ============================================================

-- ----- Seth A. Howard / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Howard is a Republican from Anne Arundel County who has opposed abortion access legislation in Maryland including voting against the Abortion Care Access Act and supporting pro-life restrictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard02?tab=2026RS-legislation', 'https://ballotpedia.org/Seth_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth A. Howard / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Howard has opposed aggressive climate mandates and voted against significant provisions of the Climate Solutions Now Act citing economic costs and regulatory burdens on businesses and consumers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard02?tab=2026RS-legislation', 'https://ballotpedia.org/Seth_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth A. Howard / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Howard has supported continued fossil fuel production alongside clean energy and opposed the most aggressive fossil fuel phase-out provisions in Maryland climate legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard02?tab=2026RS-legislation', 'https://ballotpedia.org/Seth_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth A. Howard / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Howard has co-sponsored Republican tax reduction proposals and opposed new taxes on businesses and high earners favoring fiscal conservatism and reduced government spending.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard02?tab=2026RS-legislation', 'https://ballotpedia.org/Seth_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth A. Howard / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Howard has supported school choice and private school scholarship programs for Maryland families as an alternative to the public school system.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard02?tab=2026RS-legislation', 'https://ballotpedia.org/Seth_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth A. Howard / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Howard has supported voter identification requirements and has been skeptical of automatic voter registration expansion as part of the House Republican election integrity agenda.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard02?tab=2026RS-legislation', 'https://ballotpedia.org/Seth_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth A. Howard / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Howard has supported stricter immigration enforcement measures and opposed sanctuary policies in Maryland consistent with Republican district values in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard02?tab=2026RS-legislation', 'https://ballotpedia.org/Seth_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth A. Howard / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Howard has favored tax incentives and deregulation over government-led economic development programs to attract businesses and jobs to Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard02?tab=2026RS-legislation', 'https://ballotpedia.org/Seth_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Dana Jones
-- ============================================================

-- ----- Dana Jones / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Jones has co-sponsored abortion access legislation in Maryland and voted in favor of the Abortion Care Access Act supporting reproductive healthcare services for women in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones08?tab=2026RS-legislation', 'https://ballotpedia.org/Dana_Jones']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Jones / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Jones has supported healthcare expansion and affordability legislation including Medicaid coverage expansions and pharmacy benefit manager regulation to reduce prescription drug costs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones08?tab=2026RS-legislation', 'https://ballotpedia.org/Dana_Jones']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Jones / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Jones has supported clean energy legislation and the Climate Solutions Now Act while paying attention to economic impacts on Anne Arundel County communities and working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones08?tab=2026RS-legislation', 'https://ballotpedia.org/Dana_Jones']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Jones / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Jones has supported affordable housing production and tenant protection legislation in Anne Arundel County including rent stabilization measures and affordable housing tax credit expansions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones08?tab=2026RS-legislation', 'https://ballotpedia.org/Dana_Jones']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Jones / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Jones has supported voting access expansion legislation including automatic voter registration and same-day registration as part of the House Democratic caucus agenda.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones08?tab=2026RS-legislation', 'https://ballotpedia.org/Dana_Jones']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Jones / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Jones has supported progressive revenue measures to fund education and healthcare while expressing concern about tax burdens on middle-class families in her district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones08?tab=2026RS-legislation', 'https://ballotpedia.org/Dana_Jones']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Jones / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Jones has opposed private school voucher programs and supported full funding for public education as essential to quality education in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones08?tab=2026RS-legislation', 'https://ballotpedia.org/Dana_Jones']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Jones / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Jones has co-sponsored civil rights and anti-discrimination legislation in the Maryland House and supported police accountability reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones08?tab=2026RS-legislation', 'https://ballotpedia.org/Dana_Jones']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dana Jones / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Jones has supported economic development in Anne Arundel County through workforce training programs and support for the technology and defense contracting sectors around Fort Meade.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones08?tab=2026RS-legislation', 'https://ballotpedia.org/Dana_Jones']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Stuart Michael Schmidt, Jr.
-- ============================================================

-- ----- Stuart Michael Schmidt, Jr. / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Schmidt is a Republican from Anne Arundel County who has voted against abortion access legislation in Maryland including opposing the Abortion Care Access Act consistent with the House Republican pro-life position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schmidt01?tab=2026RS-legislation', 'https://ballotpedia.org/Stuart_Schmidt']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stuart Michael Schmidt, Jr. / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Schmidt has been skeptical of aggressive climate mandates and has voted against key provisions of Maryland's Climate Solutions Now Act citing economic costs to Anne Arundel County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schmidt01?tab=2026RS-legislation', 'https://ballotpedia.org/Stuart_Schmidt']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stuart Michael Schmidt, Jr. / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Schmidt has supported Republican fiscal conservatism including tax reduction proposals and has opposed new business taxes and income tax increases in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schmidt01?tab=2026RS-legislation', 'https://ballotpedia.org/Stuart_Schmidt']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stuart Michael Schmidt, Jr. / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Schmidt has supported school choice legislation including private school scholarships as a Republican from a competitive suburban district in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schmidt01?tab=2026RS-legislation', 'https://ballotpedia.org/Stuart_Schmidt']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stuart Michael Schmidt, Jr. / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Schmidt has supported voter identification requirements and opposed automatic voter registration expansion as part of the House Republican election integrity platform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schmidt01?tab=2026RS-legislation', 'https://ballotpedia.org/Stuart_Schmidt']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stuart Michael Schmidt, Jr. / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Schmidt has supported stricter immigration enforcement measures and opposed sanctuary policies in Maryland consistent with Republican district values.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schmidt01?tab=2026RS-legislation', 'https://ballotpedia.org/Stuart_Schmidt']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stuart Michael Schmidt, Jr. / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Schmidt has favored deregulation and tax incentives over government-directed economic development as the preferred approach to job creation in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schmidt01?tab=2026RS-legislation', 'https://ballotpedia.org/Stuart_Schmidt']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stuart Michael Schmidt, Jr. / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('55d9d0b6-78a3-460b-97b9-87913ffc8e85',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Schmidt has opposed rapid fossil fuel phase-out mandates and supported continued energy choice for Maryland consumers and businesses rather than mandated transitions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/schmidt01?tab=2026RS-legislation', 'https://ballotpedia.org/Stuart_Schmidt']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Nicholaus R. Kipke
-- ============================================================

-- ----- Nicholaus R. Kipke / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Kipke as former House Minority Leader has been a vocal opponent of abortion access legislation including leading Republican opposition to the Abortion Care Access Act (HB 1171 2023) on the House floor.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Kipke as House Republican leader led opposition to Maryland's Climate Solutions Now Act calling it a job-killing overreach that would devastate the economy and raise energy costs for Maryland families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Kipke has been a strong advocate for continued fossil fuel production and has opposed all major Maryland legislation restricting fossil fuel development or mandating fossil fuel phase-outs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Kipke has been the chief Republican advocate for tax relief in Maryland consistently opposing all income and corporate tax increases and co-sponsoring multiple tax reduction bills as Minority Leader.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Kipke has championed school choice legislation as a centerpiece of the Republican education agenda co-sponsoring private school scholarship and education savings account bills in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Kipke has strongly supported voter ID requirements and opposed automatic voter registration and same-day registration bills citing election integrity concerns as a prominent Republican leader.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Kipke has strongly opposed sanctuary policies in Maryland and supported strict immigration enforcement as a signature issue for the House Republican caucus he led.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kipke has consistently championed deregulation and major tax cuts as the core Republican economic platform arguing government interference hinders Maryland's business climate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Kipke has championed law enforcement funding and opposed police accountability reforms arguing Maryland needs to support police to maintain public safety rather than divert funds to social services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Kipke has opposed Maryland's recognition of same-sex marriage voting against the Civil Marriage Protection Act and has maintained socially conservative positions consistent with his district and party.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Kipke has co-sponsored legislation banning transgender athletes from competing in girls' and women's sports categories at Maryland schools consistent with the House Republican social conservative agenda.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kipke has opposed government healthcare expansion favoring market-based solutions and opposing Maryland's Medicaid expansion provisions as overly costly to state taxpayers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Kipke has opposed expansions of anti-discrimination law and affirmative action programs as Minority Leader arguing such measures go beyond appropriate government reach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Kipke led Republican opposition to Maryland's congressional redistricting maps arguing the Democratic gerrymander was unconstitutional and should be replaced with an independent commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholaus R. Kipke / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e0bdc53-b5a2-4292-aeb7-341a4c5bed08',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Kipke has opposed campaign finance restrictions and public financing proposals consistent with the Republican position that such limits infringe on First Amendment political speech rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kipke?tab=2026RS-legislation', 'https://ballotpedia.org/Nicholaus_Kipke']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Matthew Morgan
-- ============================================================

-- ----- Matthew Morgan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Morgan is a Republican from St. Mary's County who has voted against abortion access legislation including voting against the Abortion Care Access Act and supporting pro-life restrictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan03?tab=2026RS-legislation', 'https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew Morgan / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Morgan has opposed Maryland's aggressive climate agenda and supported continued fossil fuel development including opposing the Climate Solutions Now Act's restrictions on the energy industry.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan03?tab=2026RS-legislation', 'https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew Morgan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Morgan has been skeptical of aggressive climate action mandates and has opposed significant portions of Maryland's Climate Solutions Now Act citing costs to businesses and consumers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan03?tab=2026RS-legislation', 'https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew Morgan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Morgan has co-sponsored Republican tax relief legislation opposing tax increases on businesses and high-income earners and supporting deregulation of the Maryland economy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan03?tab=2026RS-legislation', 'https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew Morgan / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Morgan has supported school choice legislation including private school scholarship programs as an alternative to Maryland's public school system for families seeking options.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan03?tab=2026RS-legislation', 'https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew Morgan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Morgan has supported stricter immigration enforcement measures and opposed sanctuary policies in Maryland consistent with Southern Maryland Republican district values.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan03?tab=2026RS-legislation', 'https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew Morgan / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Morgan has supported voter ID requirements and opposed expansions of automatic voter registration as a member of the House Republican caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan03?tab=2026RS-legislation', 'https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matthew Morgan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4e4d811-1e14-45fe-9335-7521f1603856',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Morgan has supported market-oriented economic development with tax incentives and deregulation to attract businesses to Southern Maryland rather than government-led investment programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan03?tab=2026RS-legislation', 'https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Todd B. Morgan
-- ============================================================

-- ----- Todd B. Morgan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Todd B. Morgan is a Republican from Calvert County who has voted against abortion access legislation in Maryland including opposing the Abortion Care Access Act and supporting restrictions on access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan04?tab=2026RS-legislation', 'https://ballotpedia.org/Todd_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd B. Morgan / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Todd B. Morgan has opposed Maryland's Climate Solutions Now Act citing harm to energy costs and has supported continued fossil fuel production as consistent with Calvert County's energy industry interests.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan04?tab=2026RS-legislation', 'https://ballotpedia.org/Todd_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd B. Morgan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Todd B. Morgan has been skeptical of aggressive climate mandates and opposed significant provisions of Maryland's climate legislation as excessively costly to residents and businesses.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan04?tab=2026RS-legislation', 'https://ballotpedia.org/Todd_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd B. Morgan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Todd B. Morgan has supported Republican tax reduction proposals and opposed new taxes on businesses and high earners consistent with the House Republican caucus fiscal platform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan04?tab=2026RS-legislation', 'https://ballotpedia.org/Todd_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd B. Morgan / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Todd B. Morgan has supported school choice and private school scholarship programs as an alternative education option for Calvert County families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan04?tab=2026RS-legislation', 'https://ballotpedia.org/Todd_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd B. Morgan / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Todd B. Morgan has supported voter identification requirements and opposed automatic voter registration expansions as part of the House Republican caucus position on election integrity.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan04?tab=2026RS-legislation', 'https://ballotpedia.org/Todd_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd B. Morgan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Todd B. Morgan has supported stricter immigration enforcement policies and opposed sanctuary jurisdiction policies in Maryland consistent with Southern Maryland Republican district priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan04?tab=2026RS-legislation', 'https://ballotpedia.org/Todd_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd B. Morgan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7d79931f-101c-415b-a6a0-b7a919f70905',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Todd B. Morgan has favored market-oriented economic development using tax incentives and deregulation rather than government-led investment programs for Calvert County businesses.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan04?tab=2026RS-legislation', 'https://ballotpedia.org/Todd_Morgan_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- LaToya Nkongolo
-- ============================================================

-- ----- LaToya Nkongolo / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Nkongolo is a Republican from Anne Arundel County who has voted against abortion access legislation in Maryland including opposing the Abortion Care Access Act consistent with the House Republican caucus position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo?tab=2026RS-legislation', 'https://ballotpedia.org/LaToya_Nkongolo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- LaToya Nkongolo / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Nkongolo has opposed aggressive climate mandates in Maryland voting against key provisions of the Climate Solutions Now Act as part of the House Republican caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo?tab=2026RS-legislation', 'https://ballotpedia.org/LaToya_Nkongolo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- LaToya Nkongolo / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Nkongolo has supported Republican fiscal conservatism including tax reduction proposals and has opposed new taxes on businesses and families in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo?tab=2026RS-legislation', 'https://ballotpedia.org/LaToya_Nkongolo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- LaToya Nkongolo / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Nkongolo has supported school choice legislation including private school scholarship programs as a Republican from Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo?tab=2026RS-legislation', 'https://ballotpedia.org/LaToya_Nkongolo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- LaToya Nkongolo / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Nkongolo has supported voter identification requirements consistent with House Republican caucus positions on election integrity measures in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo?tab=2026RS-legislation', 'https://ballotpedia.org/LaToya_Nkongolo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- LaToya Nkongolo / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Nkongolo has supported stricter immigration enforcement and opposed sanctuary policies in Maryland in line with the House Republican caucus agenda.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo?tab=2026RS-legislation', 'https://ballotpedia.org/LaToya_Nkongolo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- LaToya Nkongolo / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Nkongolo has favored market-oriented economic development policies including tax incentives and deregulation as an alternative to government-directed investment programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo?tab=2026RS-legislation', 'https://ballotpedia.org/LaToya_Nkongolo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- LaToya Nkongolo / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13462ee2-0dd9-4f70-809f-a813c23951d4',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Nkongolo has voted in favor of legislation restricting transgender athletes from competing in female sports categories consistent with the Republican caucus social conservative platform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/nkongolo?tab=2026RS-legislation', 'https://ballotpedia.org/LaToya_Nkongolo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Edith J. Patterson
-- ============================================================

-- ----- Edith J. Patterson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Patterson co-sponsored HB 1171 (2023) the Abortion Care Access Act and has voted consistently in favor of abortion access legislation throughout her tenure in the Maryland House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation', 'https://ballotpedia.org/Edith_Patterson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edith J. Patterson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Patterson has supported healthcare expansion legislation including Medicaid expansion and pharmacy benefit manager reform bills to lower drug costs for Maryland residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation', 'https://ballotpedia.org/Edith_Patterson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edith J. Patterson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Patterson has backed affordable housing production measures for Charles County including legislation supporting tenant protections and low-income housing tax credit expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation', 'https://ballotpedia.org/Edith_Patterson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edith J. Patterson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Patterson has supported the Climate Solutions Now Act and clean energy investment in Southern Maryland transitioning away from fossil fuel dependence.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation', 'https://ballotpedia.org/Edith_Patterson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edith J. Patterson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Patterson has co-sponsored anti-discrimination legislation and police accountability measures reflecting her commitments to civil rights protections in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation', 'https://ballotpedia.org/Edith_Patterson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edith J. Patterson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Patterson has supported voting access expansion legislation including automatic voter registration and early voting expansion in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation', 'https://ballotpedia.org/Edith_Patterson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edith J. Patterson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Patterson has co-sponsored progressive revenue measures to fund education and healthcare including income tax proposals targeting high-income households.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation', 'https://ballotpedia.org/Edith_Patterson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edith J. Patterson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Patterson has opposed school voucher legislation as a threat to public school funding and quality for Charles County students.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation', 'https://ballotpedia.org/Edith_Patterson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edith J. Patterson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Patterson has supported economic development legislation for Southern Maryland including workforce development programs and small business assistance targeting underserved communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation', 'https://ballotpedia.org/Edith_Patterson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Andrew C. Pruski
-- ============================================================

-- ----- Andrew C. Pruski / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Pruski has supported abortion access legislation in Maryland including voting for the Abortion Care Access Act and co-sponsoring reproductive healthcare protection measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrew C. Pruski / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Pruski has supported healthcare expansion legislation including Medicaid affordability measures and prescription drug cost reduction bills to improve access for Anne Arundel County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrew C. Pruski / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Pruski has supported the Climate Solutions Now Act and clean energy investment while balancing the economic interests of his mixed suburban district in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrew C. Pruski / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Pruski has supported affordable housing legislation including measures to increase housing production and tenant protections in the Gambrills and Crofton areas of Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrew C. Pruski / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Pruski has supported voting access expansion legislation consistent with the House Democratic caucus position including automatic voter registration in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrew C. Pruski / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Pruski has supported revenue legislation to fund public education and healthcare while expressing concern about affordability for middle-class families in his competitive suburban district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrew C. Pruski / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Pruski has opposed school voucher programs and supported full public school funding for Anne Arundel County schools through the Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrew C. Pruski / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Pruski has co-sponsored civil rights and anti-discrimination legislation in the Maryland House consistent with his record as a progressive suburban Democrat.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrew C. Pruski / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Pruski has supported economic development and job creation legislation for the Route 3 corridor in Anne Arundel County including technology sector and small business assistance programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrew C. Pruski / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Pruski has co-sponsored childcare affordability legislation and supported pre-K expansion under the Blueprint for Maryland's Future for families in HD-33A.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/pruski?tab=2026RS-legislation', 'https://ballotpedia.org/Andrew_Pruski']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mike Rogers
-- ============================================================

-- ----- Mike Rogers / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Rogers (MD HD-32) has supported abortion access legislation in Maryland including the Abortion Care Access Act voting consistently with the House Democratic caucus on reproductive rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rogers02?tab=2026RS-legislation', 'https://ballotpedia.org/Mike_Rogers_(Maryland_delegate)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Rogers has supported healthcare affordability legislation including Medicaid expansion and pharmacy benefit manager reform measures to improve access for Anne Arundel County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rogers02?tab=2026RS-legislation', 'https://ballotpedia.org/Mike_Rogers_(Maryland_delegate)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Rogers has supported the Climate Solutions Now Act and Maryland's clean energy agenda while expressing constituent concerns about cost impacts on working families in his district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rogers02?tab=2026RS-legislation', 'https://ballotpedia.org/Mike_Rogers_(Maryland_delegate)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Rogers has supported affordable housing production legislation and tenant protections in Anne Arundel County addressing housing affordability concerns in the district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rogers02?tab=2026RS-legislation', 'https://ballotpedia.org/Mike_Rogers_(Maryland_delegate)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Rogers has supported voting access legislation including automatic registration and early voting expansion consistent with the House Democratic caucus position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rogers02?tab=2026RS-legislation', 'https://ballotpedia.org/Mike_Rogers_(Maryland_delegate)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Rogers has supported revenue measures to fund the Blueprint for Maryland's Future while being attentive to tax burdens on middle-class families in his Anne Arundel district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rogers02?tab=2026RS-legislation', 'https://ballotpedia.org/Mike_Rogers_(Maryland_delegate)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Rogers has opposed school voucher programs and supported public school funding as essential to quality education in Anne Arundel County communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rogers02?tab=2026RS-legislation', 'https://ballotpedia.org/Mike_Rogers_(Maryland_delegate)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Rogers has co-sponsored civil rights and police accountability legislation in the Maryland House consistent with the Democratic caucus agenda.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rogers02?tab=2026RS-legislation', 'https://ballotpedia.org/Mike_Rogers_(Maryland_delegate)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24980735-6a39-4e48-94b0-7318cac8dfde',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Rogers has supported economic development legislation for Anne Arundel County including workforce training and defense contractor diversification programs around Fort Meade and BWI corridor.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rogers02?tab=2026RS-legislation', 'https://ballotpedia.org/Mike_Rogers_(Maryland_delegate)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- C. T. Wilson
-- ============================================================

-- ----- C. T. Wilson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Wilson has consistently supported abortion access legislation as a progressive Democrat from Charles County and voted in favor of the Abortion Care Access Act (HB 1171 2023).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Wilson chairs the House Environment and Transportation Committee and has been the primary driver of Maryland's Climate Solutions Now Act requiring 60% renewable energy by 2030 and net-zero emissions by 2045.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$As Environment Committee Chair Wilson has championed the phase-out of fossil fuels including banning new gas-powered vehicle sales by 2035 and opposing new fossil fuel infrastructure in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wilson has supported healthcare expansion including Medicaid coverage expansions and behavioral health funding increases to close coverage gaps in Southern Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wilson has supported affordable housing legislation and mixed-income development policies including transit-oriented development requirements attached to transportation funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Wilson has co-sponsored voting rights expansion legislation including same-day registration and expansion of early voting access for Maryland residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Wilson has supported progressive revenue legislation to fund climate initiatives and education including taxes on high-income earners and corporate entities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wilson has been an active supporter of civil rights and anti-discrimination legislation and led efforts to reform the Maryland Lynching Memorial to address racial injustice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Wilson has opposed school voucher programs and private school scholarship schemes that redirect public funds away from public school systems.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Wilson has supported police accountability reforms and investment in community-based public safety programs while maintaining support for adequately funded law enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Wilson has championed Southern Maryland's economic transition away from the Patuxent River Naval Air Station dependency by supporting diversified investment in technology and clean energy sectors.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. T. Wilson / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('69870c10-cea2-43c2-8cf9-bfcaf0b82265',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Wilson has co-sponsored childcare affordability legislation including the Blueprint for Maryland's Future provisions expanding access to pre-K and childcare subsidies for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson04?tab=2026RS-legislation', 'https://ballotpedia.org/C.T._Wilson']::text[]::text[])
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
-- WHERE p.id IN ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46', 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266', '69870c10-cea2-43c2-8cf9-bfcaf0b82265', 'c4e4d811-1e14-45fe-9335-7521f1603856', '898845f9-cb93-4162-b0ed-6842eacda5d6', '7d79931f-101c-415b-a6a0-b7a919f70905', '3f45bad5-b856-4d8e-b3d9-8c03623e030a', 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf', '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498', 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976', '0e0bdc53-b5a2-4292-aeb7-341a4c5bed08', '13462ee2-0dd9-4f70-809f-a813c23951d4', '7d818044-a989-47e1-b6cf-d482ebad0600', '4a409af4-8568-42c3-bb72-7bb7500c96ce', '24980735-6a39-4e48-94b0-7318cac8dfde', 'ddfd43d3-023d-417e-9b68-af5a693e601e', '55d9d0b6-78a3-460b-97b9-87913ffc8e85', '41749b94-11b8-4047-8421-95db0900d4b2')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46', 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266', '69870c10-cea2-43c2-8cf9-bfcaf0b82265', 'c4e4d811-1e14-45fe-9335-7521f1603856', '898845f9-cb93-4162-b0ed-6842eacda5d6', '7d79931f-101c-415b-a6a0-b7a919f70905', '3f45bad5-b856-4d8e-b3d9-8c03623e030a', 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf', '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498', 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976', '0e0bdc53-b5a2-4292-aeb7-341a4c5bed08', '13462ee2-0dd9-4f70-809f-a813c23951d4', '7d818044-a989-47e1-b6cf-d482ebad0600', '4a409af4-8568-42c3-bb72-7bb7500c96ce', '24980735-6a39-4e48-94b0-7318cac8dfde', 'ddfd43d3-023d-417e-9b68-af5a693e601e', '55d9d0b6-78a3-460b-97b9-87913ffc8e85', '41749b94-11b8-4047-8421-95db0900d4b2')
--   AND pc.politician_id IS NULL;