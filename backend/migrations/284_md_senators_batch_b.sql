-- ============================================================================
-- Migration 284: MD Senators Batch B — Districts 16-31
-- ============================================================================
-- Purpose: Insert/upsert stance data for 16 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~258 rows expected
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
-- Jack Bailey
-- ============================================================

-- ----- Jack Bailey / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Bailey is a Republican representing St. Mary's County and Calvert County. He voted NO on the Abortion Care Access Act and opposes abortion rights legislation. He is a consistent pro-life vote in the MD Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Bailey, as a Southern Maryland Republican, has taken more conservative positions on LGBTQ-related legislation including same-sex marriage. He voted against LGBTQ anti-discrimination measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Bailey has championed religious freedom protections for faith-based organizations and individuals. He supports robust conscience protections for religious institutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Bailey represents a district dependent on agriculture and fossil fuel-adjacent industries. He has been skeptical of aggressive climate legislation and voted against aspects of Maryland's Climate Solutions Now Act.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Bailey represents Southern Maryland with significant natural gas and oil industry presence. He has supported energy production and opposed aggressive fossil fuel phase-out requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Bailey consistently votes against tax increases. He opposed Blueprint for Maryland's Future funding mechanisms that raised taxes and has argued for lower business taxes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Bailey has expressed support for school choice including voucher programs that give families alternatives to public schools. He represents a district with significant private and religious schooling.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Bailey supports stricter immigration enforcement. He has backed measures to require E-Verify for employers and opposed sanctuary policies in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Bailey has supported voter ID requirements and opposed some ballot access expansion measures, reflecting Republican priorities on election security.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Bailey supports strong law enforcement and traditional public safety approaches. He was more cautious about some police reform measures while supporting community policing.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Bailey has mixed views on healthcare expansion. While supporting access in rural areas, he has opposed Medicaid expansion funded by tax increases.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Bailey supports economic development through tax incentives and deregulation. He backs business-friendly policies for small businesses in his rural district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack Bailey / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Bailey represents the Chesapeake Bay watershed and supports some environmental protections for the Bay. However, he balances these with concerns about regulatory burdens on farmers and businesses.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01', 'https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Joanne C. Benson
-- ============================================================

-- ----- Joanne C. Benson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Benson is Senate President Pro Tempore and a longtime Prince George's County Democrat. She voted YES on the Abortion Care Access Act and consistently supports reproductive healthcare legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Benson has championed civil rights throughout her career as one of the longest-serving African American women in the Maryland Senate. She supports racial equity, LGBTQ protections, and anti-discrimination measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Benson is a strong healthcare access advocate. She backed Medicaid expansion, prescription drug affordability legislation, and healthcare safety net programs for Prince George's County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Benson has supported affordable housing legislation in Prince George's County. She backed tenant protection measures and affordable housing funding throughout her tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Benson backed the Blueprint for Maryland's Future including childcare investment and pre-K expansion. She supports comprehensive early childhood education for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Benson supports progressive taxation to fund public education and services. She voted for the Blueprint for Maryland's Future funding mechanisms and progressive tax reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Benson strongly supports voting rights including automatic voter registration and early voting. She has consistently backed measures to expand ballot access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Benson represents a district with a significant immigrant community. She supports immigrant protections and comprehensive immigration reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Benson backed Maryland's Climate Solutions Now Act and supports environmental justice for communities disproportionately affected by pollution in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Benson is a strong opponent of school vouchers. As a principal champion of the Blueprint for Maryland's Future, she opposes diverting public school funds to private institutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Benson supports a balanced public safety approach emphasizing prevention, mental health resources, and accountability alongside enforcement. She backed the Maryland Police Accountability Act.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Benson supported the Maryland Police Accountability Act of 2021 and police reform legislation including officer discipline reforms and civilian oversight.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Benson supports same-sex marriage and LGBTQ equality. She voted for LGBTQ non-discrimination legislation and has backed marriage equality throughout her career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joanne C. Benson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Benson supports economic development investment in Prince George's County including job training programs and infrastructure investment for underserved communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson', 'https://ballotpedia.org/Joanne_Benson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Nick Charles
-- ============================================================

-- ----- Nick Charles / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Charles represents Prince George's County District 25 and is a consistent pro-choice vote. He voted YES on the Abortion Care Access Act and supports reproductive healthcare legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Charles consistently supports civil rights legislation including racial equity measures, LGBTQ protections, and anti-discrimination laws in his Prince George's County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Charles supports expanding healthcare access in Prince George's County. He backed Medicaid expansion and healthcare affordability legislation for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Charles has supported affordable housing legislation and tenant protections addressing housing affordability challenges in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Charles backed Maryland's Climate Solutions Now Act and environmental justice measures for communities of color disproportionately affected by pollution.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Charles supports transitioning away from fossil fuels. He voted for Maryland's renewable energy standards and clean energy legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Charles represents a district with a large immigrant community. He supports immigrant protections and comprehensive immigration reform, opposing harsh enforcement measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Charles is a consistent supporter of voting rights including automatic voter registration and early voting expansion to increase ballot access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Charles supports progressive taxation to fund public services and education. He backed the Blueprint for Maryland's Future funding structure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Charles opposes school vouchers. He backed the Blueprint for Maryland's Future and supports strong public education investment in his district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Charles supported childcare investment in the Blueprint for Maryland's Future. He supports pre-K expansion and childcare subsidies for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Charles supports community-centered public safety combining prevention, mental health resources, and police accountability alongside enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Charles backed the Maryland Police Accountability Act of 2021 and police reform measures including oversight boards and officer discipline reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Charles supports same-sex marriage and LGBTQ equality. He voted for LGBTQ non-discrimination legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Charles / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cf190bac-9369-4175-bd4b-8ba776697d9c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Charles supports economic development investment in Prince George's County including workforce training and small business support in his district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02', 'https://ballotpedia.org/Nick_Charles']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Arthur Ellis
-- ============================================================

-- ----- Arthur Ellis / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ellis represents Charles County District 28 and voted YES on the Abortion Care Access Act. He is a consistent pro-choice vote in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ellis consistently supports civil rights legislation including racial equity measures and LGBTQ protections. He represents a diverse Southern Maryland district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ellis supports expanding healthcare access for Charles County residents. He backed Medicaid expansion and healthcare affordability legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ellis has supported affordable housing legislation. He backed measures to increase housing affordability in Charles County's growing suburban communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ellis backed Maryland's Climate Solutions Now Act and environmental protections for the Chesapeake Bay region which is critically important to Southern Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Ellis is a strong advocate for Chesapeake Bay protection and clean water standards. His Southern Maryland district directly depends on the health of the Bay ecosystem.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ellis supports transitioning away from fossil fuels and backed Maryland's renewable energy standards and climate legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ellis represents a district with some immigrant communities. He supports immigrant protections and comprehensive immigration reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ellis consistently backs voting rights including automatic voter registration and early voting expansion to increase ballot access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ellis supports progressive taxation to fund public services and education. He backed the Blueprint for Maryland's Future and public investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Ellis opposes school vouchers. He backs strong public education investment through the Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Ellis supported childcare investment and pre-K expansion in the Blueprint for Maryland's Future, helping working families in Charles County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Ellis supports same-sex marriage and LGBTQ equality. He voted for LGBTQ non-discrimination legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Ellis supports a balanced public safety approach combining prevention programs and enforcement. He backed police accountability legislation while supporting community policing.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Arthur Ellis / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4754dede-4a3b-4280-a8b1-7497530107f7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ellis supports economic development in Charles County including workforce training and attracting businesses to his growing suburban district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01', 'https://ballotpedia.org/Arthur_Ellis_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kevin M. Harris
-- ============================================================

-- ----- Kevin M. Harris / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Harris represents Prince George's County District 27 and voted YES on the Abortion Care Access Act. He is a consistent pro-choice vote in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Harris consistently supports civil rights legislation including racial equity measures and LGBTQ protections. He is a strong advocate for his diverse Prince George's County constituents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Harris supports expanding healthcare access in Prince George's County. He backed Medicaid expansion and healthcare affordability legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Harris has supported affordable housing legislation and anti-displacement measures for renters in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Harris backed Maryland's Climate Solutions Now Act and environmental justice measures addressing pollution burdens in communities of color.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Harris represents a district with significant immigrant communities. He supports immigrant protections and comprehensive immigration reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Harris is a consistent voting rights supporter backing automatic voter registration and early voting expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Harris supports progressive taxation to fund public services. He backed the Blueprint for Maryland's Future funding structure and progressive tax reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Harris opposes school vouchers. He backed the Blueprint for Maryland's Future and supports strong public education investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Harris supported childcare investment in the Blueprint for Maryland's Future. He backs pre-K expansion and childcare subsidies for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Harris supports a community-centered public safety approach including prevention, mental health resources, and accountability. He backed the Maryland Police Accountability Act.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Harris backed the Maryland Police Accountability Act of 2021 and police reform measures. He supports civilian oversight boards and officer accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Harris supports same-sex marriage and LGBTQ equality. He voted for LGBTQ non-discrimination legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Harris supports economic development investment in Prince George's County including workforce training and job creation for underserved communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin M. Harris / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Harris supports environmental justice for communities of color disproportionately affected by pollution in Prince George's County. He backed Chesapeake Bay protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03', 'https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Shaneka Henson
-- ============================================================

-- ----- Shaneka Henson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Henson represents Anne Arundel County District 30 (including Annapolis) and voted YES on the Abortion Care Access Act. She is a consistent pro-choice vote in the Maryland Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Henson is a strong civil rights advocate representing a diverse Anne Arundel County district including Annapolis. She backs racial equity legislation, LGBTQ protections, and anti-discrimination measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Henson supports expanding healthcare access. She backed Medicaid expansion and healthcare affordability legislation for Anne Arundel County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Henson has supported affordable housing legislation addressing significant affordability challenges in the Annapolis area. She backed tenant protections and affordable housing funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Henson backed Maryland's Climate Solutions Now Act and supports strong climate action. Her Annapolis district on the Chesapeake Bay gives her a direct stake in climate impacts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Henson represents the Annapolis area on the Chesapeake Bay and is a strong advocate for Bay protection, clean water standards, and stormwater management.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Henson supports transitioning away from fossil fuels and voted for Maryland's climate and renewable energy legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Henson supports same-sex marriage and LGBTQ equality. She voted for LGBTQ non-discrimination legislation and supports transgender rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Henson consistently backs voting rights including automatic voter registration and early voting expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Henson supports progressive taxation to fund public services and education. She backed the Blueprint for Maryland's Future funding structure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Henson opposes school vouchers. She backs strong public education investment through the Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Henson supported childcare investment in the Blueprint for Maryland's Future. She backs pre-K expansion and childcare subsidies for working families in her district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Henson backed the Maryland Police Accountability Act of 2021 and police reform measures including oversight boards and officer discipline standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Henson supports a balanced public safety approach combining prevention, mental health resources, and community policing alongside accountability measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Henson supports economic development for Annapolis and Anne Arundel County including small business support and workforce development programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Henson supports immigrant protections and comprehensive immigration reform. Her district includes immigrant communities in the Annapolis area.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shaneka Henson / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05c9b5b9-cb2b-4387-ab6b-350b69553fac',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Henson has supported independent redistricting reform to reduce partisan gerrymandering in Maryland legislative districts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02', 'https://ballotpedia.org/Shaneka_Henson']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- William C. Smith, Jr.
-- ============================================================

-- ----- William C. Smith, Jr. / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Smith chairs the Senate Judicial Proceedings Committee, overseeing criminal law reform. He has supported sentencing reform, second chance legislation, and reentry programs for formerly incarcerated individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://mgaleg.maryland.gov/mgawebsite/Committees/Details/jpr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$As Judicial Proceedings Committee chair, Smith has advanced pretrial detention reform. He supported legislation to shift Maryland toward risk-based assessments over cash bail for nonviolent offenders.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://mgaleg.maryland.gov/mgawebsite/Committees/Details/jpr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Smith steered the Maryland Police Accountability Act of 2021 through Judicial Proceedings. He supported officer discipline reforms, civilian oversight boards, and body camera requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://mgaleg.maryland.gov/mgawebsite/Committees/Details/jpr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Smith has used the Judicial Proceedings chair role to prioritize balanced prosecution approaches, supporting reforms to reduce mass incarceration while maintaining public safety.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://mgaleg.maryland.gov/mgawebsite/Committees/Details/jpr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Smith represents Montgomery County District 20 and is a consistent pro-choice vote. He voted YES on the Abortion Care Access Act and backed reproductive healthcare legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Smith consistently supports civil rights legislation including LGBTQ protections, racial equity measures, and anti-discrimination laws. He has championed these issues through his committee chair position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Smith supports same-sex marriage and LGBTQ equality. He backed Maryland's marriage equality legislation and LGBTQ anti-discrimination measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Smith has supported transgender student rights including inclusive school sports policies, opposing restrictive bills targeting trans youth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Smith backed the Climate Solutions Now Act and supports aggressive climate action. His Montgomery County district expects strong environmental leadership.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Smith supports transitioning away from fossil fuels. He voted for Maryland's clean energy standards and the Climate Solutions Now Act's carbon reduction requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Smith supports universal healthcare access. He backs Medicaid expansion and prescription drug cost control legislation. His committee has processed healthcare-related criminal justice reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Smith supports affordable housing expansion in Montgomery County. He backed legislation to increase housing supply and protect tenants in the high-cost DC suburbs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Smith supports progressive taxation. He backed the Blueprint for Maryland's Future funding and higher corporate tax rates to fund public investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Smith is a consistent supporter of voting rights expansion. He backed automatic voter registration, early voting, and ballot access improvements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Smith represents a district with many immigrant families. He supports comprehensive immigration reform and state immigrant protections, opposing harsh enforcement measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Smith's Judicial Proceedings chair position enables a balanced public safety approach. He views public safety as including both enforcement and prevention, supporting reform while maintaining accountability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://mgaleg.maryland.gov/mgawebsite/Committees/Details/jpr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Smith opposes private school vouchers. He is a public education supporter who backed the Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Smith backed childcare investment as part of the Blueprint for Maryland's Future. He supports universal pre-K and childcare subsidy programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Smith has supported independent redistricting reform efforts to reduce partisan gerrymandering in Maryland's legislative districts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Smith, Jr. / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Smith supports economic development through public investment and innovation. He backs workforce development programs and small business support in Montgomery County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02', 'https://ballotpedia.org/William_C._Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Cheryl C. Kagan
-- ============================================================

-- ----- Cheryl C. Kagan / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Kagan is nationally recognized for election law expertise and chairs or serves on Maryland's Election Law committee. She has championed automatic voter registration, early voting expansion, and ballot access improvements throughout her career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Kagan has been a leading voice for independent redistricting reform in Maryland to combat partisan gerrymandering. She introduced legislation to create an independent redistricting commission.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Kagan has addressed election misinformation through her election law work, supporting legislation to combat false information about voting procedures and electoral processes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Kagan has been a consistent advocate for campaign finance transparency and reform, supporting disclosure requirements and limits on dark money in Maryland elections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Kagan represents Montgomery County District 17 and is a strong pro-choice supporter. She voted YES on the Abortion Care Access Act and co-sponsored reproductive rights legislation in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Kagan has consistently backed civil rights legislation throughout her career. She supports LGBTQ protections, racial equity measures, and anti-discrimination laws.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Kagan supported marriage equality in Maryland during the 2012 ballot initiative and has voted for LGBTQ non-discrimination legislation throughout her Senate tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Kagan supports inclusive policies for transgender athletes. She voted for Maryland legislation protecting transgender student rights in schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kagan strongly supports healthcare access expansion. She votes for Medicaid expansion and healthcare affordability legislation representing a predominantly healthcare-aware Montgomery County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Kagan backed the Climate Solutions Now Act and consistently votes for climate legislation as a Montgomery County Democrat. She supports renewable energy transition and emissions reduction mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Kagan opposes fossil fuel expansion and supports transitioning Maryland to clean energy. She voted for the Climate Solutions Now Act's carbon reduction requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kagan has supported housing affordability legislation including efforts to increase affordable housing in Montgomery County's high-cost real estate market.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Kagan supports progressive taxation to fund public services. She backs higher taxes on corporations and wealthy individuals to fund education and healthcare.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Kagan supports childcare access and early childhood education investment. She backed the Blueprint for Maryland's Future which includes significant pre-K and childcare funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kagan supports economic development through public investment and supports workforce development programs that benefit Montgomery County's technology and government contractor economy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Kagan represents a district with significant immigrant communities including many federal workers. She supports comprehensive immigration reform and opposes harsh immigration enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Kagan opposes school vouchers that divert public funds to private schools. She is a strong supporter of Maryland's public education system and the Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cheryl C. Kagan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Kagan supports a community-centered approach to public safety, including criminal justice reforms and addressing root causes of crime through investment in communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01', 'https://ballotpedia.org/Cheryl_C._Kagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Benjamin F. Kramer
-- ============================================================

-- ----- Benjamin F. Kramer / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Kramer represents Montgomery County District 19 and is a reliable pro-choice vote. He voted YES on the Abortion Care Access Act and co-sponsored reproductive health legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Kramer backed Maryland's Climate Solutions Now Act and consistently supports climate action legislation. He is a Montgomery County Democrat with a strong environmental record.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Kramer supports transitioning away from fossil fuels. He voted for Maryland's clean energy standards and climate legislation requiring emissions reductions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Kramer has supported Chesapeake Bay protection, clean water standards, and local environmental legislation. He serves on committees overseeing environmental policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kramer consistently votes for healthcare access expansion including Medicaid expansion, prescription drug cost controls, and healthcare affordability measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Kramer supports expanding Medicaid and protecting Medicare. He has backed healthcare safety net programs serving vulnerable populations in his district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kramer has supported housing affordability legislation in Maryland. He backed measures to increase affordable housing supply and tenant protections in Montgomery County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Kramer supports progressive taxation to fund public education and services. He voted for the Blueprint for Maryland's Future funding mechanisms including higher corporate and income taxes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Kramer opposes private school vouchers. He is a strong public education advocate who backed the Blueprint for Maryland's Future and opposes diverting public school funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Kramer supported childcare funding in the Blueprint for Maryland's Future. He backs universal pre-K access and childcare subsidies for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Kramer is a consistent supporter of voting rights including automatic voter registration, early voting, and absentee ballot access. He opposes voter ID restrictions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Kramer backs civil rights legislation including anti-discrimination measures, LGBTQ protections, and racial equity policies. He represents a diverse Montgomery County district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Kramer supports same-sex marriage and LGBTQ equality. He voted for marriage equality and LGBTQ non-discrimination legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Kramer supports immigrant-friendly policies. His district includes many immigrant families and federal workers. He opposes harsh deportation policies and supports a path to legal status.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Kramer supports community-centered public safety including prevention, mental health resources, and police accountability measures. He backed Maryland's 2021 Police Accountability Act.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin F. Kramer / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7a2d1548-3268-4767-97a8-bb8b142d5a33',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kramer supports economic development through public investment in infrastructure, education, and workforce development. He backs tech sector growth and small business support.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02', 'https://ballotpedia.org/Benjamin_Kramer']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Sara Love
-- ============================================================

-- ----- Sara Love / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Love represents Montgomery County District 16 and consistently supports abortion rights. She voted YES on SB 798 (2023 Abortion Care Access Act) and co-sponsored reproductive health legislation. Her district is strongly pro-choice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Love serves on the Senate Environment and Transportation Committee and champions climate action. She supported Maryland's Climate Solutions Now Act and consistently votes for clean energy and emissions reduction legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Committees/Details/esm01', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$As an Environment and Transportation Committee member, Love votes against fossil fuel expansion. She supports transitioning away from fossil fuels and backed the Climate Solutions Now Act's carbon reduction mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Love has supported legislation to expand housing access and affordability in the Montgomery County/DC suburbs. She voted for zoning reform and affordable housing funding bills in the 2023-2025 sessions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Love represents an urban/suburban district with significant renter populations. She has supported tenant protections and rent stabilization policies during her Senate tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Love has supported zoning reform to allow more housing density and mixed-use development in Montgomery County, consistent with her housing access priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Love strongly supports expanding healthcare access. She voted for Medicaid expansion measures and healthcare affordability legislation. Montgomery County includes large healthcare worker constituencies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Love supports protecting and expanding Medicaid. She voted YES on SB 539 (2023) expanding Medicaid access and has consistently backed healthcare safety net programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Love supports progressive tax policy. She backs higher taxes on corporations and high earners to fund public services, consistent with her Montgomery County Democratic district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Love is a strong supporter of voting access and election integrity from the pro-voter perspective. She backed automatic voter registration and mail voting expansion in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Love consistently backs civil rights legislation including anti-discrimination measures. She serves a diverse Montgomery County district and supports LGBTQ protections and racial equity bills.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Love supports same-sex marriage and LGBTQ equality. As a Montgomery County Democrat, she voted for LGBTQ anti-discrimination legislation and consistently supports marriage equality.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Love supports inclusive policies for transgender athletes. She backed Maryland legislation protecting transgender student rights and opposed restrictive bills targeting trans youth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Love represents a district with significant immigrant populations. She supports comprehensive immigration reform and opposes harsh enforcement-only approaches.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Love supports a balanced public safety approach emphasizing prevention and community investment alongside enforcement. She has backed criminal justice reform while supporting community policing.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Love supports economic development through public investment in education and workforce development. She backed economic development legislation benefiting Montgomery County businesses and workers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Love has been a champion for childcare access and affordability. She supported the Blueprint for Maryland's Future which includes childcare investments and pre-K expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$As Environment and Transportation Committee member, Love is a strong local environmental advocate. She backs Chesapeake Bay protections, stormwater management, and clean air measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Committees/Details/esm01', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Love supported independent redistricting reform to reduce partisan gerrymandering in Maryland. She backed efforts to create more transparent and fair district mapping processes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sara Love / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d2cd24-170a-4f87-8fde-84216fe62806',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Love opposes school vouchers that divert public school funding to private institutions. She is a strong supporter of Maryland's public school system and the Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02', 'https://ballotpedia.org/Sara_Love']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- C. Anthony Muse
-- ============================================================

-- ----- C. Anthony Muse / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Muse is a Democratic pastor in Prince George's County who has shown more conservative leanings on social issues. While a Democrat, his religious background influences his positions on reproductive legislation, and he has been known to cross over on some abortion-related votes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Muse, as a pastor and Democrat, has expressed more conservative views on same-sex marriage than his Democratic colleagues. He has been noted for crossing party lines on LGBTQ-related legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Muse is an ordained minister who has championed religious freedom in the Maryland Senate. He has supported protections for religious institutions and faith-based organizations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Muse supports civil rights and racial equity legislation. As an African American senator representing a predominantly Black district in Prince George's County, he is a strong advocate for racial justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Muse supports expanding healthcare access for Prince George's County residents. He backed Medicaid expansion and healthcare affordability measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Muse has supported affordable housing legislation and community investment in Prince George's County, addressing housing needs of his working-class constituents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Muse represents a district with a large immigrant community. He generally supports immigrant protections and comprehensive immigration reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Muse supports progressive taxation to fund public services and education. He backed the Blueprint for Maryland's Future and public investment in his district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Muse supported childcare investment including early childhood education programs. He backs family support services for working parents in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Muse consistently backs voting rights expansion including automatic voter registration and ballot access measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '00b95a6a-75db-4521-b523-3326bba938de',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Muse's position on school vouchers is less clear-cut than most Democrats — his faith-based background gives him more sympathy for faith-based school funding arguments, though he generally supports public education.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Muse supports strong public safety in Prince George's County including community policing and crime prevention programs. He takes a balanced approach to public safety and criminal justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Muse supports economic development investment in Prince George's County including job creation and community reinvestment programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- C. Anthony Muse / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('47823046-7dea-4a4f-a11b-0c5890539891',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Muse backed Maryland's Climate Solutions Now Act and supports environmental protections for Prince George's County communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01', 'https://ballotpedia.org/C._Anthony_Muse']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jim Rosapepe
-- ============================================================

-- ----- Jim Rosapepe / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Rosapepe is a longtime economic development champion representing Prince George's County District 21. As a former US Ambassador to Romania and technology entrepreneur, he focuses on tech sector growth, innovation economy, and workforce development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Rosapepe backed Maryland's Climate Solutions Now Act and supports clean energy transition. He has championed climate action as part of his broader economic development agenda.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Rosapepe supports transitioning from fossil fuels to clean energy. He backed Maryland's Renewable Portfolio Standard expansion and climate legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Rosapepe supports expanding healthcare access including Medicaid expansion. He backs healthcare affordability for Prince George's County residents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Rosapepe represents Prince George's County with a large immigrant population including many Latino families. He supports comprehensive immigration reform and immigrant protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Rosapepe is a Prince George's County Democrat who voted YES on the Abortion Care Access Act and supports reproductive healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Rosapepe supports progressive taxation to fund public investment. He backed the Blueprint for Maryland's Future funding mechanisms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Rosapepe has supported housing affordability legislation in Prince George's County. He backed measures to increase affordable housing supply and mixed-income development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Rosapepe is a consistent voting rights supporter including automatic voter registration and early voting expansion. As a former Democratic leader, he strongly backs voter access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Rosapepe has consistently backed civil rights including LGBTQ protections, racial equity measures, and anti-discrimination laws throughout his legislative career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Rosapepe supported marriage equality in Maryland and has backed LGBTQ non-discrimination legislation throughout his career.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Rosapepe opposes school vouchers. He is a strong public education supporter who backed the Blueprint for Maryland's Future and community school investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Rosapepe supported childcare investment including the Blueprint for Maryland's Future pre-K expansion to help working families in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Rosapepe supports a balanced public safety approach combining enforcement with prevention and mental health resources. He backed police accountability reforms.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Rosapepe, as a tech sector veteran, has engaged with AI regulation questions. He supports thoughtful oversight of AI systems while fostering innovation in Maryland's tech economy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim Rosapepe / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '24e9212c-b011-422a-865c-093e35050901',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c400214-f007-4a8d-92fe-5f5d23b3838e',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Rosapepe served as US Ambassador to Romania under President Clinton, giving him strong Eastern European security awareness. He supports US assistance to Ukraine defending against Russian aggression.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe', 'https://ballotpedia.org/Jim_Rosapepe']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Bryan W. Simonaire
-- ============================================================

-- ----- Bryan W. Simonaire / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Simonaire is a longtime Republican from Anne Arundel County who voted NO on the Abortion Care Access Act and consistently opposes abortion rights legislation. He is a strong pro-life vote in the MD Senate.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Simonaire, as a conservative Republican, has opposed same-sex marriage and LGBTQ anti-discrimination measures. He voted against LGBTQ-inclusive legislation during his Senate tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Simonaire has been a champion of religious freedom legislation in Maryland, supporting conscience protections for faith-based organizations and individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Simonaire has expressed skepticism about aggressive climate regulation. He voted against aspects of the Climate Solutions Now Act, citing economic impacts on businesses and households.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Simonaire has supported existing energy industries in Anne Arundel County and opposed aggressive fossil fuel phase-out requirements that would burden businesses and consumers.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Simonaire is a consistent tax opponent. As former Minority Whip, he has led opposition to tax increases including Blueprint for Maryland's Future funding mechanisms and corporate tax hikes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Simonaire has expressed support for school choice including private school voucher programs. He backs giving families alternatives to public schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Simonaire supports stricter immigration enforcement. He has backed measures like E-Verify requirements and opposed sanctuary jurisdictions in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Simonaire has supported voter ID requirements and opposed some ballot access expansion measures. He prioritizes election security over ballot access expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Simonaire supports strong law enforcement and traditional public safety. He was cautious about some 2021 police accountability reforms, citing concerns about officer morale and safety.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Simonaire supports some healthcare access improvements in rural and suburban settings but has opposed Medicaid expansion funded by tax increases. He prefers market-based healthcare solutions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Simonaire supports economic development through tax incentives, deregulation, and business-friendly policies. He advocates for small business growth in Anne Arundel County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Simonaire represents an Anne Arundel County district on the Chesapeake Bay. He supports Bay protection while balancing concerns about regulatory burdens on farmers and waterfront property owners.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Simonaire has been a critic of independent redistricting proposals that he views as taking redistricting power from the legislature. He prefers legislative control over district maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bryan W. Simonaire / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Simonaire has opposed transgender-inclusive athletic policies. He supported or co-sponsored legislation restricting transgender athletes from competing in women's sports categories.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire', 'https://ballotpedia.org/Bryan_Simonaire']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jeff Waldstreicher
-- ============================================================

-- ----- Jeff Waldstreicher / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Waldstreicher is a strong pro-choice advocate representing Montgomery County District 18. He voted YES on the Abortion Care Access Act (SB 798, 2023) and co-sponsored reproductive rights legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Waldstreicher serves on the Judicial Proceedings Committee and has supported criminal justice reform measures including sentencing reform and second-chance opportunities for formerly incarcerated individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://mgaleg.maryland.gov/mgawebsite/Committees/Details/jpr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$As a Judicial Proceedings Committee member, Waldstreicher has voted to reform Maryland's cash bail system to reduce pretrial detention for nonviolent offenders.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://mgaleg.maryland.gov/mgawebsite/Committees/Details/jpr01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Waldstreicher backed the Maryland Police Accountability Act (2021) and supported subsequent police reform legislation including body camera requirements and oversight measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Waldstreicher consistently champions civil rights including LGBTQ protections, racial equity legislation, and anti-discrimination measures throughout his Senate tenure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Waldstreicher has been a vocal supporter of same-sex marriage and LGBTQ equality. He voted for LGBTQ non-discrimination legislation and opposed anti-trans bills.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Waldstreicher strongly supports transgender student rights including fair access to school sports. He opposed restrictions on transgender athletes in Maryland legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Waldstreicher backed the Climate Solutions Now Act and consistently votes for aggressive climate action. He is a strong proponent of clean energy transition in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Waldstreicher is among the strongest opponents of fossil fuel expansion in the MD Senate. He voted for aggressive phase-out timelines and has opposed new fossil fuel infrastructure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Waldstreicher is a strong advocate for universal healthcare access. He backed Medicaid expansion and has supported legislation to reduce prescription drug costs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Waldstreicher has been a leading advocate for housing affordability in Montgomery County. He sponsored legislation to increase affordable housing supply and backed tenant protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Waldstreicher supports rent stabilization measures to protect tenants in the high-cost Montgomery County housing market. He has backed local government authority to implement rent control.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Waldstreicher supports progressive tax reform including higher taxes on corporations and wealthy individuals to fund the Blueprint for Maryland's Future education investments.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Waldstreicher is a consistent supporter of voting rights expansion including automatic voter registration, early voting, and ballot access for all eligible voters.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Waldstreicher supports campaign finance reform and transparency. He has backed disclosure requirements for dark money spending in Maryland elections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Waldstreicher is a strong opponent of school vouchers that divert public school funding to private institutions. He champions Maryland's public school system including the Blueprint for Maryland's Future.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Waldstreicher represents a district with many immigrants and federal workers. He strongly supports comprehensive immigration reform and state-level immigrant protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Waldstreicher has backed significant childcare access legislation and early childhood education investment. He supported the Blueprint for Maryland's Future pre-K expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Waldstreicher supports economic development through public investment and innovation economy support. He backs workforce training and technology sector growth in Montgomery County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeff Waldstreicher / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da75c207-bb23-477e-b3c0-7c462394b570',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Waldstreicher supports a holistic public safety approach including criminal justice reform and community investment. He backed police accountability legislation while supporting community policing.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1', 'https://ballotpedia.org/Jeff_Waldstreicher']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Alonzo T. Washington
-- ============================================================

-- ----- Alonzo T. Washington / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Washington represents Prince George's County District 22 and is a consistent pro-choice vote. He voted YES on the Abortion Care Access Act and supports reproductive healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Washington has consistently supported civil rights legislation including racial equity measures, LGBTQ protections, and anti-discrimination laws. As an African American senator in PG County, he prioritizes racial justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Washington has supported criminal justice reforms including sentencing reform and reducing mass incarceration. He backed legislation creating pathways for formerly incarcerated individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Washington supported the Maryland Police Accountability Act of 2021 and backed subsequent police reform measures. As a Prince George's County senator, accountability in policing is a top priority.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Washington strongly supports expanding healthcare access in Prince George's County. He backed Medicaid expansion and healthcare affordability legislation for working families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Washington represents a district with significant housing affordability challenges. He has backed affordable housing funding, tenant protections, and anti-displacement measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Washington represents a district with a large immigrant community including Central American families. He supports comprehensive immigration reform and immigrant protections in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Washington has backed Maryland's Climate Solutions Now Act and environmental justice measures that address disproportionate pollution burdens in communities of color.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Washington supports progressive taxation to fund public services in underserved communities. He backed the Blueprint for Maryland's Future funding structure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Washington opposes school vouchers. He backs strong public school investment through the Blueprint for Maryland's Future and opposes diverting public funds to private schools.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Washington supported childcare investment in the Blueprint for Maryland's Future, recognizing childcare access as critical for working families in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Washington is a strong voting rights advocate. He backed automatic voter registration, early voting expansion, and ballot access for all eligible voters.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Washington supports community-centered public safety including prevention programs, mental health resources, and police accountability. He represents communities with both safety needs and police reform concerns.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Washington supports economic development through public investment in Prince George's County. He backs job creation programs and workforce development for historically underinvested communities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alonzo T. Washington / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Washington has backed environmental justice measures addressing disproportionate pollution burdens in PG County communities. He supports Chesapeake Bay protection and clean air standards.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02', 'https://ballotpedia.org/Alonzo_Washington']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ron Watson
-- ============================================================

-- ----- Ron Watson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Watson represents Prince George's County District 23 and is a consistent pro-choice vote. He voted YES on the Abortion Care Access Act and supports reproductive healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Watson consistently supports civil rights legislation including racial equity measures and LGBTQ protections. He is a strong voice for his diverse Prince George's County constituents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Watson backs healthcare access expansion including Medicaid expansion and healthcare affordability for working families in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Watson has supported affordable housing legislation and tenant protections in Prince George's County, addressing significant affordability challenges.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Watson backed Maryland's Climate Solutions Now Act and supports clean energy transition. He supports environmental justice measures for communities of color in PG County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Watson supports transitioning away from fossil fuels and backed Maryland's renewable energy standards. He voted for clean energy legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Watson supports progressive taxation to fund public services. He backed the Blueprint for Maryland's Future funding and higher corporate taxes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Watson represents a district with significant immigrant communities. He supports immigrant protections and comprehensive immigration reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Watson is a consistent supporter of voting rights including automatic voter registration and early voting expansion in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Watson opposes school vouchers. He backed the Blueprint for Maryland's Future and supports strong public school investment in Prince George's County.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Watson supported childcare investment in the Blueprint for Maryland's Future, recognizing childcare as essential for working families in his district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Watson supports community-centered public safety including prevention programs, mental health resources, and police accountability alongside enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Watson backed the Maryland Police Accountability Act of 2021. He supports civilian oversight and officer accountability measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Watson supports economic development through public investment in Prince George's County. He backs job creation and workforce development programs for his constituents.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ron Watson / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9aef8bfb-8e0c-4f00-9898-c738abe4970c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Watson supports same-sex marriage and LGBTQ equality. He voted for LGBTQ non-discrimination legislation and marriage equality.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04', 'https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]::text[])
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
-- WHERE p.id IN ('c5d2cd24-170a-4f87-8fde-84216fe62806', 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1', 'da75c207-bb23-477e-b3c0-7c462394b570', '7a2d1548-3268-4767-97a8-bb8b142d5a33', 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc', '9c400214-f007-4a8d-92fe-5f5d23b3838e', '8c8b0896-dfd0-4d3c-8492-e594d93b78ca', '9aef8bfb-8e0c-4f00-9898-c738abe4970c', '4a7dc8a6-2138-4472-8197-8b878034f029', 'cf190bac-9369-4175-bd4b-8ba776697d9c', '47823046-7dea-4a4f-a11b-0c5890539891', '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1', '4754dede-4a3b-4280-a8b1-7497530107f7', '0abc8345-1fbb-4994-b39c-c3c4f4eefc9f', '05c9b5b9-cb2b-4387-ab6b-350b69553fac', '4aa50ee7-aeed-48ae-96e7-142bd9ac731b')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('c5d2cd24-170a-4f87-8fde-84216fe62806', 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1', 'da75c207-bb23-477e-b3c0-7c462394b570', '7a2d1548-3268-4767-97a8-bb8b142d5a33', 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc', '9c400214-f007-4a8d-92fe-5f5d23b3838e', '8c8b0896-dfd0-4d3c-8492-e594d93b78ca', '9aef8bfb-8e0c-4f00-9898-c738abe4970c', '4a7dc8a6-2138-4472-8197-8b878034f029', 'cf190bac-9369-4175-bd4b-8ba776697d9c', '47823046-7dea-4a4f-a11b-0c5890539891', '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1', '4754dede-4a3b-4280-a8b1-7497530107f7', '0abc8345-1fbb-4994-b39c-c3c4f4eefc9f', '05c9b5b9-cb2b-4387-ab6b-350b69553fac', '4aa50ee7-aeed-48ae-96e7-142bd9ac731b')
--   AND pc.politician_id IS NULL;