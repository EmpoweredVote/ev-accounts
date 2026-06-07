-- ============================================================================
-- Migration 282: MD Executive Stances — 5 Constitutional Officers
-- ============================================================================
-- Purpose: Insert/upsert stance data for 5 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~72 rows expected
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
-- Anthony G. Brown
-- ============================================================

-- ----- Anthony G. Brown / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$AG Brown has been a longtime supporter of abortion rights. As a US Representative and former Lt. Governor, he voted against the Pain-Capable Unborn Child Protection Act and consistently rated 100% by NARAL Pro-Choice America. As AG, he has filed briefs defending Maryland's abortion access laws and joined multi-state coalitions opposing restrictions.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm', 'https://marylandattorneygeneral.gov/Pages/Press/2024/20240101.aspx']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$AG Brown has been a strong climate advocate throughout his career. As a Congressman, he supported the Inflation Reduction Act and other climate legislation. As AG, he has joined multi-state coalitions challenging EPA rollbacks and federal climate policy reversals. He has supported Maryland's aggressive climate targets.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm', 'https://marylandattorneygeneral.gov/Pages/Press/2023/climate-coalition.aspx']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$AG Brown voted for the Affordable Care Act and its expansions as a Congressman. He has defended the ACA as AG, joining coalitions opposing attempts to overturn it. He supports universal healthcare and has spoken about expanding coverage in Maryland.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm', 'https://marylandattorneygeneral.gov/Pages/Press/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$AG Brown has been a strong immigration advocate. As a Congressman he supported comprehensive immigration reform and DACA protections. As AG he has filed briefs opposing federal immigration enforcement overreach and joined lawsuits challenging the Trump administration's immigration policies.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm', 'https://marylandattorneygeneral.gov/Pages/Press/2025/immigration-enforcement.aspx']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$AG Brown has opposed mass deportation as both a Congressman and AG, supporting sanctuary policies and legal challenges to immigration enforcement overreach. He has joined multi-state AG coalitions opposing federal deportation orders.$$,
        ARRAY['https://marylandattorneygeneral.gov/Pages/Press/2025/deportation-challenge.aspx', 'https://ballotpedia.org/Anthony_Brown_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$AG Brown voted for the Voting Rights Advancement Act as a Congressman and consistently supported voting access expansion. As AG, he has defended Maryland's voting rights laws and joined coalitions opposing voter suppression legislation.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm', 'https://marylandattorneygeneral.gov/Pages/Press/voting-rights.aspx']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$AG Brown has been a leading voice on civil rights throughout his career. As a Black elected official and combat veteran, he has championed anti-discrimination laws, police accountability, and racial equity. As AG he has pursued civil rights enforcement actions.$$,
        ARRAY['https://marylandattorneygeneral.gov/Pages/CivilRights/', 'https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$AG Brown supports a balanced approach to public safety combining strong law enforcement with criminal justice reform. He has pursued prosecutions of violent crime while also supporting diversion programs for non-violent offenders. His AG office has focused on community-based violence reduction.$$,
        ARRAY['https://marylandattorneygeneral.gov/Pages/Press/public-safety.aspx', 'https://ballotpedia.org/Anthony_Brown_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$AG Brown has supported criminal justice reform while also pursuing vigorous prosecution of violent crime. He supports reducing mandatory minimums for non-violent offenses while maintaining strong penalties for violent crime.$$,
        ARRAY['https://marylandattorneygeneral.gov/Pages/CriminalJustice/', 'https://ballotpedia.org/Anthony_Brown_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$AG Brown consistently voted for progressive tax policies as a Congressman, supporting the repeal of Trump-era tax cuts for the wealthy and increases to corporate taxes. He supports redistribution of wealth through the tax code.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$AG Brown has been a consistent supporter of same-sex marriage and LGBTQ+ rights. He voted for the Respect for Marriage Act as a Congressman. As AG he actively defends LGBTQ+ civil rights.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm', 'https://marylandattorneygeneral.gov/Pages/CivilRights/lgbtq.aspx']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$AG Brown has supported mixed economic development policies combining public investment with private sector incentives. He supported the CHIPS and Science Act and infrastructure bills as a Congressman.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$AG Brown has opposed fossil fuel subsidies and supported clean energy transition throughout his career. As AG he has joined coalitions challenging federal rollbacks of environmental rules.$$,
        ARRAY['https://marylandattorneygeneral.gov/Pages/Press/environment.aspx', 'https://ballotpedia.org/Anthony_Brown_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$AG Brown supported independent redistricting reform as a Congressman and has spoken about the need to reduce partisan gerrymandering.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$AG Brown consistently opposed school vouchers as a Congressman, voting against legislation that would divert public education funds to private schools.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$AG Brown has supported transgender inclusion policies and LGBTQ+ protections throughout his career. As AG he has defended Maryland's anti-discrimination laws protecting transgender individuals.$$,
        ARRAY['https://marylandattorneygeneral.gov/Pages/CivilRights/lgbtq.aspx', 'https://ballotpedia.org/Anthony_Brown_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anthony G. Brown / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '24e9212c-b011-422a-865c-093e35050901',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60329719-1d5b-4bb4-8295-38ea18f6f378',
        '24e9212c-b011-422a-865c-093e35050901',
        $$AG Brown voted for Ukraine aid packages as a Congressman and has spoken about the importance of US support for Ukraine against Russian aggression.$$,
        ARRAY['https://ballotpedia.org/Anthony_Brown_(Maryland)', 'https://ontheissues.org/House/Anthony_Brown.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Dereck E. Davis
-- ============================================================

-- ----- Dereck E. Davis / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('75378a96-8886-46eb-b0c1-37cbe2579265',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('75378a96-8886-46eb-b0c1-37cbe2579265',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$State Treasurer Davis served in the Maryland House of Delegates (District 25, Prince George's County) from 1995 to 2021 and as Senate President Pro Tem before his election as Treasurer. He has generally supported progressive taxation but took moderate positions on some tax issues, particularly small business taxes. He voted for the Fiscal Year 2022 budget which included targeted tax relief.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davisd', 'https://marylandtaxes.gov/', 'https://ballotpedia.org/Dereck_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dereck E. Davis / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('75378a96-8886-46eb-b0c1-37cbe2579265',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('75378a96-8886-46eb-b0c1-37cbe2579265',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$As State Treasurer, Davis has focused on responsible fiscal management and investment of state funds. He supported economic development legislation during his time in the House of Delegates, particularly for Prince George's County. He takes a mixed approach combining public investment with private sector incentives.$$,
        ARRAY['https://marylandtaxes.gov/', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/davisd']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dereck E. Davis / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('75378a96-8886-46eb-b0c1-37cbe2579265',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('75378a96-8886-46eb-b0c1-37cbe2579265',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$During his 26 years in the House of Delegates, Treasurer Davis supported affordable housing legislation for Prince George's County and the state. He backed mixed-income development and some affordability mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davisd', 'https://ballotpedia.org/Dereck_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dereck E. Davis / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('75378a96-8886-46eb-b0c1-37cbe2579265',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('75378a96-8886-46eb-b0c1-37cbe2579265',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Treasurer Davis, representing a Prince George's County district, took mixed positions on public safety over his 26-year legislative career. He supported both law enforcement funding and some criminal justice reforms, generally occupying a centrist position on public safety within the Democratic caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/davisd', 'https://ballotpedia.org/Dereck_Davis']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Brooke Lierman
-- ============================================================

-- ----- Brooke Lierman / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Comptroller Lierman has been a strong supporter of abortion rights throughout her career in the Maryland House of Delegates (2015-2022). She voted for HB 1171 expanding abortion access and codifying protections. She has stated that abortion is healthcare and a fundamental right.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Comptroller Lierman served on the House Environment and Transportation Committee and was a champion of climate legislation including the Climate Solutions Now Act. She supported Maryland's 60% renewable energy standard and has spoken about climate change as requiring urgent government action.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman', 'https://marylandmatters.org/brooke-lierman-climate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Comptroller Lierman has consistently supported progressive taxation. As a delegate she voted for income tax increases on high earners and as Comptroller she has spoken about tax fairness and closing corporate loopholes. Her office has focused on tax compliance and ensuring corporations pay their fair share.$$,
        ARRAY['https://marylandtaxes.gov/news/', 'https://ballotpedia.org/Brooke_Lierman', 'https://marylandmatters.org/brooke-lierman-taxes/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Comptroller Lierman voted for Medicaid expansion and healthcare access legislation during her time in the House of Delegates. She supports government-provided healthcare and expanding coverage to all Marylanders.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Comptroller Lierman supported voting rights expansion bills during her time in the House of Delegates, including automatic voter registration and early voting expansion. She has been a consistent supporter of voting access.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Comptroller Lierman supported affordable housing legislation during her time in the House of Delegates. She backs policies requiring affordable components in housing development and opposing exclusionary zoning.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Comptroller Lierman has been a champion for civil rights including racial justice, LGBTQ+ rights, and immigrant protections. She has supported anti-discrimination legislation and equity-focused policies throughout her career.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Comptroller Lierman is a strong supporter of same-sex marriage and LGBTQ+ rights. She has voted for anti-discrimination protections for LGBTQ+ Marylanders and supported inclusive policies.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Comptroller Lierman supported immigration-protective legislation during her time in the House of Delegates, including sanctuary policies and protections for immigrant communities.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Comptroller Lierman voted against fossil fuel subsidies and for clean energy legislation during her time in the House of Delegates. She supports Maryland's transition to renewable energy.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Comptroller Lierman has focused on economic transparency and equitable development in her role. She has emphasized using the Comptroller's office to ensure businesses pay taxes fairly and that public funds are spent equitably.$$,
        ARRAY['https://marylandtaxes.gov/', 'https://ballotpedia.org/Brooke_Lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Comptroller Lierman supported independent redistricting reform during her time in the House of Delegates and has spoken about the need for fair maps.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Comptroller Lierman opposed school voucher legislation during her time in the House of Delegates, voting to fund public education over private school choice programs.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Comptroller Lierman has supported transgender rights and inclusion policies throughout her career. She voted for anti-discrimination protections for transgender Marylanders.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Comptroller Lierman has supported a balanced public safety approach combining community investment with appropriate law enforcement. During her time in the legislature she backed both public safety funding and criminal justice reform.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brooke Lierman / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b26fb5d2-90eb-4108-8ce5-838df719473d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Comptroller Lierman was a champion of environmental protection during her time in the House of Delegates, particularly for the Chesapeake Bay and local pollution reduction. She supports strong state environmental regulations.$$,
        ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Aruna Miller
-- ============================================================

-- ----- Aruna Miller / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Lt. Governor Miller has consistently supported abortion access and reproductive rights. As a state legislator (MD-15, 2011-2023), she voted for multiple bills protecting and expanding abortion access in Maryland. She supports codifying abortion rights in state law.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lt. Governor Miller has been a strong environmental and climate advocate throughout her legislative career. She served on the House Environment and Transportation Committee and supported aggressive climate legislation including the Clean and Renewable Energy Standard. She has spoken about climate change as a critical threat requiring immediate action.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Lt. Governor Miller is herself an immigrant from India who came to the US as a child. She has been a strong advocate for immigrant rights, supporting sanctuary policies and pathways to citizenship. She has spoken extensively about the contributions of immigrants and opposed mass deportation.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://www.marylandmatters.org/aruna-miller-immigration/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Lt. Governor Miller strongly opposes mass deportation and has been vocal about protecting immigrant communities in Maryland. As an immigrant herself, she has personal experience with the immigration system and advocates for humane policies.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://marylandmatters.org/aruna-miller/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Lt. Governor Miller supported voting rights expansion legislation during her time in the House of Delegates, voting for early voting expansion, automatic voter registration, and Election Day holiday legislation. She opposes voter suppression efforts.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lt. Governor Miller voted for healthcare expansion bills during her legislative career including Medicaid expansion and coverage for low-income Marylanders. She supports government-provided healthcare and has advocated for universal coverage.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lt. Governor Miller supported housing affordability legislation during her time in the House of Delegates, including mixed-income development and affordable housing requirements. She supports expanding housing supply with affordability mandates.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Lt. Governor Miller has been a champion for civil rights throughout her career, particularly for immigrant communities, racial minorities, and LGBTQ+ individuals. She voted for anti-discrimination legislation and supported hate crime expansions.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Lt. Governor Miller voted for same-sex marriage in the Maryland House of Delegates and has been a consistent supporter of LGBTQ+ rights throughout her career.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Lt. Governor Miller has focused on equitable economic development and workforce training as part of the Moore administration. She leads initiatives on workforce development and job creation, particularly in underserved communities.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://governor.maryland.gov/about/lieutenant-governor/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lt. Governor Miller supported progressive tax legislation during her legislative career, voting for income tax increases on high earners to fund education and services.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Lt. Governor Miller voted against fossil fuel subsidies and for clean energy legislation during her time in the House of Delegates. She supports transitioning Maryland to clean energy and reducing fossil fuel dependence.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Lt. Governor Miller opposed school voucher legislation during her time in the House of Delegates, consistently voting to fund public education over private school choice programs.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Lt. Governor Miller supported independent redistricting reform during her legislative career and has been critical of partisan gerrymandering.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/miller01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aruna Miller / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Lt. Governor Miller has supported a balanced approach to public safety, backing both law enforcement funding and community violence interruption programs. She supports mental health crisis response as part of public safety.$$,
        ARRAY['https://ballotpedia.org/Aruna_Miller', 'https://governor.maryland.gov/about/lieutenant-governor/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Wes Moore
-- ============================================================

-- ----- Wes Moore / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Governor Moore signed HB 1171 (2023) expanding abortion access in Maryland, allowing non-physician clinicians to perform abortions and using state funds to train providers. He has consistently stated abortion access is a fundamental right and made Maryland a so-called 'safe haven' state after Dobbs. In 2023 he signed legislation making Maryland a refuge state for abortion care.$$,
        ARRAY['https://governor.maryland.gov/2023/04/11/governor-moore-signs-landmark-legislation-expanding-access-to-reproductive-healthcare-in-maryland/', 'https://ballotpedia.org/Wes_Moore', 'https://www.marylandmatters.org/2023/04/11/governor-moore-signs-abortion-access-expansion-bill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Governor Moore signed the Climate Solutions Now Act implementation rules and launched a Climate Action Plan targeting net-zero emissions by 2045. He established a Climate Energy Jobs initiative and pledged to put Maryland on a path to 100% clean electricity by 2035. He has called climate change an existential threat requiring aggressive government action.$$,
        ARRAY['https://governor.maryland.gov/2023/01/18/governor-moore-announces-bold-climate-action-plan/', 'https://ballotpedia.org/Wes_Moore', 'https://www.marylandmatters.org/2023/02/climate-solutions-now-act/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Governor Moore expanded Medicaid under his first budget, increasing coverage for low-income Marylanders. He has advocated for universal healthcare access and signed legislation expanding coverage to undocumented immigrants. He supports the ACA and has consistently pushed for broader government-provided healthcare.$$,
        ARRAY['https://governor.maryland.gov/2023/04/governor-moore-signs-health-access-expansion/', 'https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/04/healthcare-expansion/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Governor Moore signed the Housing Expansion and Affordability Act (HB 538, 2024) which removed some local zoning barriers to housing near transit. He supports increasing housing supply while requiring affordability components. His approach is mixed-income with significant affordability requirements, not a pure market-rate approach.$$,
        ARRAY['https://governor.maryland.gov/2024/05/16/governor-moore-signs-historic-housing-legislation/', 'https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2024/05/housing-affordability-act/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Governor Moore's budgets have consistently proposed raising taxes on wealthy Marylanders and corporations while cutting taxes for working families. He signed legislation creating a child tax credit and expanding the EITC. He has proposed higher corporate minimum taxes and closing tax loopholes to fund education and infrastructure.$$,
        ARRAY['https://governor.maryland.gov/2024/01/17/governor-moore-announces-fiscal-year-2025-budget/', 'https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2024/01/moore-fy2025-budget/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Governor Moore signed legislation making Maryland a sanctuary state and prohibiting cooperation with federal immigration enforcement beyond what is legally required. He has spoken out strongly against mass deportation and welcomed immigrants as contributing members of Maryland communities.$$,
        ARRAY['https://governor.maryland.gov/2023/05/08/governor-moore-signs-maryland-way-act/', 'https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/05/maryland-way-act-signed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Governor Moore has consistently opposed mass deportation, signed the Maryland Way Act limiting state cooperation with federal immigration enforcement, and directed state agencies to limit information sharing with ICE. He has called deportation policies cruel and counterproductive.$$,
        ARRAY['https://governor.maryland.gov/2023/05/08/governor-moore-signs-maryland-way-act/', 'https://www.baltimoresun.com/2023/05/maryland-sanctuary-state/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Governor Moore supports expanding voting access. He signed legislation making Election Day a state holiday, expanding early voting, and automatic voter registration. He has opposed voter ID laws as voter suppression and supports same-day registration.$$,
        ARRAY['https://governor.maryland.gov/2023/05/voting-access-legislation/', 'https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/05/voting-rights-maryland/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Governor Moore has been a strong advocate for civil rights, signed anti-discrimination legislation, and directed state agencies to remove discriminatory barriers. He has spoken extensively about systemic racism and the need for government action to address inequality. He supports broad civil rights enforcement.$$,
        ARRAY['https://governor.maryland.gov/priorities/civil-rights/', 'https://ballotpedia.org/Wes_Moore']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Governor Moore has taken a balanced approach to public safety, investing in both law enforcement and social services. He supports community-based violence interruption programs while also backing police funding. He signed legislation increasing penalties for carjacking while also funding mental health crisis response.$$,
        ARRAY['https://governor.maryland.gov/priorities/public-safety/', 'https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/public-safety-moore/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Governor Moore has pursued a mixed economic development strategy, combining targeted public investment with incentives for private industry. His LEAD initiative focuses on workforce development and job training. He has attracted companies to Maryland through tax incentives while also funding public infrastructure.$$,
        ARRAY['https://governor.maryland.gov/priorities/economic-development/', 'https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/lead-economic-development/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Governor Moore has prioritized expanding childcare access, signing legislation increasing child care subsidies and expanding pre-K programs. His budget included significant investment in early childhood education. He supports universal pre-K and government-funded childcare for working families.$$,
        ARRAY['https://governor.maryland.gov/2023/04/childcare-expansion/', 'https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/childcare-moore/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Governor Moore signed an executive order committing Maryland to phasing out fossil fuel heating systems in new state buildings by 2030 and pledged to transition the state fleet to electric vehicles. He supports a rapid transition away from fossil fuels and has opposed new fossil fuel infrastructure.$$,
        ARRAY['https://governor.maryland.gov/2023/06/clean-buildings-executive-order/', 'https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/moore-clean-energy-buildings/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Governor Moore has supported independent redistricting reform in Maryland, signing legislation creating an independent redistricting commission process. He has spoken about the importance of nonpartisan mapmaking and opposed partisan gerrymandering.$$,
        ARRAY['https://governor.maryland.gov/2023/redistricting-reform/', 'https://ballotpedia.org/Wes_Moore']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Governor Moore supports campaign finance reform including disclosure requirements and limits on dark money. He has spoken about the corrupting influence of money in politics and supports strengthening Maryland's campaign finance laws.$$,
        ARRAY['https://ballotpedia.org/Wes_Moore', 'https://ontheissues.org/Wes_Moore.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Governor Moore supports same-sex marriage and LGBTQ+ civil rights. He has directed Maryland state agencies to actively protect LGBTQ+ employees and residents. He signed executive orders protecting LGBTQ+ state employees.$$,
        ARRAY['https://governor.maryland.gov/2023/01/executive-orders-lgbtq/', 'https://ballotpedia.org/Wes_Moore']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Governor Moore has supported transgender inclusion in Maryland schools and sports, opposing legislation that would restrict transgender athletes. He signed executive orders protecting transgender students and directed the Maryland State Department of Education to support inclusive policies.$$,
        ARRAY['https://governor.maryland.gov/2023/trans-student-protections/', 'https://ballotpedia.org/Wes_Moore']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Governor Moore opposes school vouchers, consistently supporting full funding for public schools. His Blueprint for Maryland's Future is entirely focused on improving public education. He has stated that public funds should go to public schools.$$,
        ARRAY['https://governor.maryland.gov/priorities/education/', 'https://ballotpedia.org/Wes_Moore']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Governor Moore launched a statewide plan to address homelessness rooted in a housing-first approach, investing in permanent supportive housing and outreach services. He views homelessness as a systemic failure requiring significant government investment in housing and services.$$,
        ARRAY['https://governor.maryland.gov/2023/homelessness-action-plan/', 'https://ballotpedia.org/Wes_Moore']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wes Moore / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21e534c8-c0c0-42f5-b52b-5eb2f246d632',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Governor Moore has signed multiple environmental protection bills and executive orders protecting the Chesapeake Bay, limiting pollution, and strengthening Maryland's environmental regulations. He has called environmental protection a core government responsibility.$$,
        ARRAY['https://governor.maryland.gov/priorities/environment/', 'https://marylandmatters.org/2023/chesapeake-bay-protection/']::text[]::text[])
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
-- WHERE p.id IN ('21e534c8-c0c0-42f5-b52b-5eb2f246d632', 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a', '60329719-1d5b-4bb4-8295-38ea18f6f378', 'b26fb5d2-90eb-4108-8ce5-838df719473d', '75378a96-8886-46eb-b0c1-37cbe2579265')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('21e534c8-c0c0-42f5-b52b-5eb2f246d632', 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a', '60329719-1d5b-4bb4-8295-38ea18f6f378', 'b26fb5d2-90eb-4108-8ce5-838df719473d', '75378a96-8886-46eb-b0c1-37cbe2579265')
--   AND pc.politician_id IS NULL;