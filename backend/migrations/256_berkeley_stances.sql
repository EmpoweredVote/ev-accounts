-- ============================================================================
-- Migration 256: Berkeley Officials Stances -- 10 Politicians
-- ============================================================================
-- Purpose: Insert/upsert stance data for 10 Berkeley city officials.
--
-- Politicians: Adena Ishii (Mayor), Jenny Wong (City Auditor),
--              Rashi Kesarwani (D1), Terry Taplin (D2), Ben Bartlett (D3),
--              Igor Tregub (D4), Shoshana O'Keefe (D5), Brent Blackaby (D6),
--              Cecilia Lunaparra (D7), Mark Humbert (D8)
--
-- Stance count: 128 rows
-- Topic scope: 42 topics (all 43 live topics except data-centers)
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, data-centers excluded):
-- abortion                           af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                      666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                   92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                          c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                    7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                       0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                     f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- deportation                        44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development               eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                       a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development             fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                         e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                       4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response              6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                            669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                        4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                      c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-access-to-justice         9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-bail-pretrial             1fab5edf-6151-4da0-9704-a7f2113ba54c
-- judicial-criminal-justice          9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-government-deference      e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-interpretation            448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- judicial-police-accountability     7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-prosecution-priorities    abb99d95-cbb1-4617-8f8b-f220ef6028ca
-- judicial-transparency              6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment                  1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                  b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                       cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                     ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach             e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                      48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                  6b9ba6d9-1001-43f5-b073-4d37130696fd
-- rent-regulation                    c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning                 d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                  c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                    00b95a6a-75db-4521-b523-3326bba938de
-- social-security                    87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                            683c8084-2281-4920-a07c-18439b2dd413
-- taxes                              f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                     d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities          ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                    24e9212c-b011-422a-865c-093e35050901
-- voting-rights                      d1792200-1d3b-4955-a0b7-0e6980d7a7b2

-- Politician UUID reference (essentials.politicians):
-- Adena Ishii                965de422-660e-4e24-9fe6-717cc0313403
-- Jenny Wong                 3342ae40-cc86-43e5-8581-3237b6aa8f08
-- Rashi Kesarwani            d2013613-769f-4374-809e-a018dbc1e683
-- Terry Taplin               bcdb549a-48bf-400f-9d23-c93e2e71007c
-- Ben Bartlett               eaab41f8-71c8-47db-bd0b-62da46b5607b
-- Igor Tregub                9f9a35a9-0226-45f0-9fd8-ef46163f7245
-- Shoshana O'Keefe           8cc1c412-fe14-4bc6-b1e2-02d95997fd47
-- Brent Blackaby             424eb63b-9976-4059-8049-365c09719cc6
-- Cecilia Lunaparra          116aace8-9440-498b-bf1d-ebb196727c85
-- Mark Humbert               7833be90-c693-40b8-a309-61ee77b4ba03

BEGIN;

-- ============================================================
-- Adena Ishii (Mayor)
-- ============================================================

-- ----- Adena Ishii / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Ishii reaffirmed Berkeley's sanctuary city status unanimously one day after Trump's second inauguration, stating 'we will not be doing that' regarding ICE assistance; led passage of a codified sanctuary ordinance in September 2025; co-sponsored a resolution rejecting ALPR contract expansion over ICE data access concerns; co-authored a resolution decrying ICE deportations without due process (Jan 2026).$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/adena-ishii', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-21-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-27-2026']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Ishii stated directly 'I absolutely believe that we need to get rid of exclusionary zoning in the city'; co-sponsored the PITCH upzoning initiative to allow up to 8 stories/85 feet along Telegraph Avenue; voted Yes on the SB 684 housing subdivision ordinance; co-sponsored a density bonus program for condominium development; backed building housing on BART station sites.$$,
ARRAY['https://48hills.org/2025/01/how-fawning-media-helped-berkeleys-new-mayor-win-the-election/', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-10-2026', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-14-2026']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '669cac97-66a6-4087-b036-936fbe62efb3', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Ishii ran on a platform of building more affordable housing and received endorsements from East Bay YIMBY and the Housing Action Coalition; as mayor she supported Homekey+ applications for supportive affordable housing at People's Park and North Berkeley BART; she supports public investment in affordable housing and building on transit corridors.$$,
ARRAY['https://en.wikipedia.org/wiki/Adena_Ishii', 'https://48hills.org/2024/12/how-a-yimby-candidate-with-little-experience-became-berkeleys-next-mayor/', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-19-2026']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Ishii chairs the Alameda County Mayors' Conference homelessness working group and the official city page notes she is 'leading efforts on homelessness and housing both locally and regionally'; her campaign prioritized mental health resources and housing solutions over enforcement; she supported Homekey+ supportive housing with services, with no evidence of sponsoring camping bans or criminalization.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/adena-ishii', 'https://en.wikipedia.org/wiki/Adena_Ishii', 'https://newsroom.haas.berkeley.edu/magazine/spring-2025/the-can-do-mayor/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Ishii chairs the Alameda County Mayors' Conference homelessness working group; her campaign focused on housing and mental health resources as the primary response to homelessness; she supported Homekey+ applications for permanent supportive housing at People's Park and North Berkeley BART rather than enforcement-first approaches.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/adena-ishii', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-19-2026', 'https://en.wikipedia.org/wiki/Adena_Ishii']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Ishii told the Green Party she wanted to go 'Full Steam Ahead on Reimagining Public Safety' — the 2020 council-approved plan to eventually shift police budgets toward civilian response programs; she co-sponsored completion of Police Accountability Board regulations; she opposed ALPR surveillance expansion; she is leading recruitment of a Police Accountability Director — reflecting a co-responder model rather than pure police expansion or defunding.$$,
ARRAY['https://48hills.org/2025/01/how-fawning-media-helped-berkeleys-new-mayor-win-the-election/', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-october-14-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-9-2026']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Ishii serves on the Alameda County Transportation Commission and the city's Transportation/Environment/Sustainability committee; she urged Governor Newsom to approve Bay Area public transit funding (September 2025); she co-sponsored a letter thanking the MTC for adopting a Transit-Oriented Communities Policy and supports housing development around BART stations.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/adena-ishii', 'https://mayoradenaishii.com/from-the-mayors-desk', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-24-2026']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Ishii co-sponsored a resolution supporting the 2026 Joint Megafire Prevention Package in the California Legislature; she chairs the Transportation/Environment/Sustainability committee and organized Earth Month events including a home electrification fair and climate fair; she does not appear to have declared a climate emergency or called for banning all fossil fuel activities.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-28-2026', 'https://mayoradenaishii.com/earth-month', 'https://berkeleyca.gov/your-government/city-council/council-roster/adena-ishii']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Ishii co-sponsored the Megafire Prevention Package and chairs the Transportation/Environment/Sustainability committee; her overall approach as a pro-development YIMBY mayor is to allow significant new housing development while maintaining environmental regulations — consistent with applying environmental standards while giving developers reasonable flexibility.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-28-2026', 'https://berkeleyca.gov/your-government/city-council/council-roster/adena-ishii', 'https://48hills.org/2024/12/how-a-yimby-candidate-with-little-experience-became-berkeleys-next-mayor/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Ishii co-sponsored the PITCH upzoning initiative allowing 8-story buildings along Telegraph Avenue; co-sponsored density bonus programs for new condos; voted Yes on SB 684 housing subdivision ordinance; supports building on BART station sites; as a YIMBY-endorsed mayor she has actively pursued streamlined development approvals rather than growth limits.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-10-2026', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-14-2026', 'https://48hills.org/2024/12/how-a-yimby-candidate-with-little-experience-became-berkeleys-next-mayor/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adena Ishii / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965de422-660e-4e24-9fe6-717cc0313403', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Ishii co-chaired the Berkeley Unified School District Reparations Task Force before becoming mayor; as mayor she co-sponsored resolutions opposing immigrant detainment without due process and decrying ICE violence; she reaffirmed sanctuary city protections; she is leading recruitment of a Police Accountability Director and pushed completion of Police Accountability Board regulations.$$,
ARRAY['https://48hills.org/2024/12/how-a-yimby-candidate-with-little-experience-became-berkeleys-next-mayor/', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-27-2026', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-9-2026']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jenny Wong (City Auditor)
-- ============================================================

-- ----- Jenny Wong / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '6674d87e-999d-433a-aab7-3f626f59fd5f', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '6674d87e-999d-433a-aab7-3f626f59fd5f',
$$Wong's defining role as City Auditor is independent government transparency: she has 'worked to make audits and departments' responses more transparent and accessible to the community,' established Berkeley's first city employee whistleblower program, and publishes a public dashboard tracking whether departments implement audit recommendations. Four of her audit reports won national awards from the Association of Local Government Auditors.$$,
ARRAY['https://www.jennyforauditor.com', 'https://berkeleyca.gov/auditor']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jenny Wong / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '7bad33eb-e93e-4d94-8822-97212d49bde5', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '7bad33eb-e93e-4d94-8822-97212d49bde5',
$$Wong's office conducted an independent performance audit of Berkeley Police Department operations — an external accountability review outside the police chain of command — consistent with the stance that an accountability office works for the public and investigates independently. As City Auditor she reviews police operations for efficiency and compliance rather than defending city departments.$$,
ARRAY['https://www.jennyforauditor.com', 'https://berkeleyca.gov/auditor']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jenny Wong / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Wong's office audited Berkeley's Homeless Response Team and found it needed better planning, tracking, and community outreach to improve effectiveness — a services-improvement orientation focused on program outcomes rather than enforcement. Her audit framing treats homelessness as a city services delivery problem requiring better coordination, not a public-order enforcement problem.$$,
ARRAY['https://berkeleyca.gov/auditor', 'https://www.jennyforauditor.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jenny Wong / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Wong's Homeless Response Team audit called for improved planning, tracking, and community outreach as the path to better outcomes — signaling a services-delivery orientation rather than criminalization. Her audit explicitly reviewed whether homeless programs were achieving objectives, not whether enforcement powers should be expanded.$$,
ARRAY['https://berkeleyca.gov/auditor', 'https://www.jennyforauditor.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jenny Wong / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Wong audited Berkeley Police Department operations from an independent accountability perspective, reviewing efficiency and compliance rather than advocating for budget expansion. Her office operates outside the police chain of command and has produced accountability-oriented findings. This is consistent with a co-responder/accountability model rather than a pure police-budget-expansion stance.$$,
ARRAY['https://www.jennyforauditor.com', 'https://berkeleyca.gov/auditor']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jenny Wong / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$The Berkeley City Auditor's mandate — as stated on the official city page — is to assess whether city services are provided 'efficiently, effectively, and equitably.' Wong's office applies this equity lens to all city programs including public safety. Her audit work is oriented toward holding the city accountable for equitable service delivery rather than limiting civil rights enforcement.$$,
ARRAY['https://berkeleyca.gov/auditor', 'https://www.jennyforauditor.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jenny Wong / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Berkeley is a sanctuary city and Wong operates within that city framework as an elected city officer. Her office has not challenged sanctuary protections; her audit work focuses on procedural compliance and equitable service delivery. As City Auditor she would audit compliance with city ordinances including sanctuary policies, consistent with honoring court-ordered processes but not proactive ICE cooperation.$$,
ARRAY['https://berkeleyca.gov/auditor', 'https://www.jennyforauditor.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jenny Wong / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3342ae40-cc86-43e5-8581-3237b6aa8f08', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Wong's fiscal condition audit warned of a structural deficit posing risk to Berkeley's financial sustainability — signaling fiscal caution about city commitments rather than a strong pro-growth or anti-growth stance. Her contracting audit found non-competitive processes, favoring accountability and proper process in development approvals. No evidence of growth limits or aggressive permitting reform advocacy.$$,
ARRAY['https://berkeleyca.gov/auditor', 'https://www.jennyforauditor.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Rashi Kesarwani (Council Member (District 1))
-- ============================================================

-- ----- Rashi Kesarwani / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '669cac97-66a6-4087-b036-936fbe62efb3', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Kesarwani champions building more affordable and market-rate homes at all income levels: she secured a $4.9M Encampment Resolution Grant to convert a Super 8 Motel to transitional housing, championed the Golden Bear Inn Homekey conversion (43 studios for homeless individuals at 30% AMI), and led the BART transit-oriented development effort with a 35% affordable housing minimum goal. She frames her record as 'saying yes to more homes' across categories.$$,
ARRAY['https://rashikesarwani.com', 'https://rashikesarwani.com/north-berkeley-bart', 'https://rashikesarwani.com/2023/07/summer-news-city-budget-staffing-addressing-encampments-bart-updates']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Kesarwani authored the encampment closure policy that allows closures for fire or imminent health hazards when shelter is offered, stating it is 'not progressive to allow people to live in unsafe conditions.' She secured a court order to close Harrison Street encampments citing a Leptospirosis outbreak. Her approach explicitly requires shelter offers before closure ('codifies our commitment to offering shelter whenever practicable') but does permit enforcement when safety conditions are met.$$,
ARRAY['https://rashikesarwani.com/2024/09/sept-news-encampment-policy-action-alert-n-berkeley-bart-funding-update-more', 'https://rashikesarwani.com/2026/01/jan-news-public-health-alert-lepto-at-harrison-encampments', 'https://rashikesarwani.com/2025/06/june-news-judge-authorizes-ohlone-encampment-closure-middle-housing-mtg']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Kesarwani authored and implemented an encampment closure policy conditioned on shelter availability, stating 'Permanent housing is the solution to homelessness' while also permitting enforcement at encampments posing fire or health hazards. She activated the Emergency Operations Center to close Harrison encampments during a Leptospirosis outbreak (Jan 2026). She supports shelter offers and housing-first language but allows enforcement when safety thresholds are met.$$,
ARRAY['https://rashikesarwani.com/2024/09/sept-news-encampment-policy-action-alert-n-berkeley-bart-funding-update-more', 'https://rashikesarwani.com/2026/01/jan-news-public-health-alert-lepto-at-harrison-encampments', 'https://rashikesarwani.com/2023/07/summer-news-city-budget-staffing-addressing-encampments-bart-updates']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Kesarwani supports expanded tenant protections: her middle housing ordinance mandates relocation assistance, right of return, and comparable rent for displaced tenants, and she listed a Rent Stabilization Ordinance and Eviction for Good Cause Ordinance ballot measure in her 2022 newsletter as an active Council item. She operates within Berkeley's existing strong rent control framework and has not opposed it.$$,
ARRAY['https://rashikesarwani.com/2022/07/summer-news-marina-pier-state-funding-possible-ballot-measures-housing-element-more', 'https://rashikesarwani.com/2025/06/june-news-judge-authorizes-ohlone-encampment-closure-middle-housing-mtg']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Kesarwani authored Berkeley's middle housing ordinance to allow duplexes, fourplexes, triplexes, and cottage courts citywide, explicitly arguing that single-family zoning 'historically functioned as a segregation tool.' She supported BART transit-oriented development up to 7 stories, streamlined ADU permitting with a dedicated ADU planner, and a housing element that rezones high-resource low-density corridors. She asks 'why not allow our zoning code to also embrace housing diversity?'$$,
ARRAY['https://rashikesarwani.com/2025/04/april-news-middle-housing-mtg-postponed-ohlone-park-mtg-more', 'https://rashikesarwani.com/2024/10/oct-news-middle-housing-community-mtg-update-on-homeless-encampment-policy-more', 'https://rashikesarwani.com/2024/04/april-news-san-pablo-safety-upgrades-gilman-district-street-fair-bike-race-more']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Kesarwani explicitly aligned the Hopkins Corridor transportation project with Berkeley's Climate Action Plan and Vision Zero; she championed bus and bike lanes on San Pablo Avenue, free transit passes for new BART residents, reduced parking at transit stations, and BART transit-oriented housing to reduce car dependence. She served on the council in 2019 when Berkeley passed the nation's first natural gas ban for new buildings.$$,
ARRAY['https://rashikesarwani.com/2022/12/dec-news-hopkins-corridor-virtual-meeting-on-dec-12-more', 'https://rashikesarwani.com/2022/08/aug-news-answering-bart-faqs-cesar-chavez-park-hopkins-corridor-more', 'https://rashikesarwani.com/2023/03/march-news-san-pablo-ave-corridor-meeting-street-paving-gilman-district-street-fair-more']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Kesarwani advocates for equitable tree canopy distribution (championing a 1200-1800 new street tree program targeting West Berkeley's deficit), Ohlone Greenway safety upgrades with path widening and lighting, and required CEQA review for BART development. She applies consistent environmental standards while giving developers reasonable implementation flexibility within the design standards process.$$,
ARRAY['https://rashikesarwani.com/2022/04/april-news-bart-housing-next-steps-homekey-award-trees-more', 'https://rashikesarwani.com/2023/08/aug-updates-ohlone-greenway-redesign-and-n-berkeley-bart-public-safety-meetings', 'https://rashikesarwani.com/north-berkeley-bart']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Kesarwani strongly prioritizes multimodal infrastructure: she co-authored bus and bike lanes on San Pablo Avenue (the county's second-busiest bus corridor), supported a bicycle overcrossing at Gilman interchange, expanded the Ohlone Greenway, championed Hopkins Street Vision Zero improvements for cyclists and pedestrians, and reduced parking at BART from 700 to 200 spaces while requiring free transit passes for all new BART development residents.$$,
ARRAY['https://rashikesarwani.com/2023/03/march-news-san-pablo-ave-corridor-meeting-street-paving-gilman-district-street-fair-more', 'https://rashikesarwani.com/2022/10/fall-news-n-berkeley-bart-developer-public-presentations-more', 'https://rashikesarwani.com/2022/12/dec-news-hopkins-corridor-virtual-meeting-on-dec-12-more']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Kesarwani's September 2025 newsletter announces Berkeley's unanimous sanctuary city ordinance that 'prohibits city personnel from disclosing protected personal information to federal immigration enforcement' and her October 2025 newsletter states the City's position: 'The City will not assist ICE (U.S. Immigration and Customs Enforcement) in immigration enforcement.' She highlighted local immigrant legal organizations providing removal defense.$$,
ARRAY['https://rashikesarwani.com/2025/09/sept-news-sanctuary-city-ordinance-new-bathrooms-more', 'https://rashikesarwani.com/2025/10/oct-news-possible-ice-deployment-in-bay-area-nov-special-election-more']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Kesarwani supports both police staffing investments and civilian alternative programs: she advocates for restoring police positions ('152 sworn officers, a historic low'), implemented ALPR cameras and security cameras for crime solving, while also supporting a Specialized Care Unit for mental health crises, civilian traffic enforcement, gun violence intervention programs, and a fully staffed Office of Race, Equity, and Diversity. Her newsletter states 'We need a thoughtful, deliberate approach' combining police tools with redesigned public safety systems.$$,
ARRAY['https://rashikesarwani.com/2022/05/action-alert-council-to-make-important-public-safety-decisions-tonight', 'https://rashikesarwani.com/2021/12/action-alert-support-public-safety-tomorrow-in-mid-year-budget-update', 'https://rashikesarwani.com/2026/05/may-news-public-safety-technology-special-mtg-tomorrow-may-7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Kesarwani proactively invests in infrastructure to support responsible expansion: she more than doubled Berkeley's annual street paving budget from $7M to $17M, championed ADU streamlining and middle housing, and supported BART transit-oriented development — while maintaining community design standards, CEQA review, and negotiating a Memorandum of Agreement with BART to enforce local design guidelines on developers. She does not impose growth limits but does not remove all regulatory barriers.$$,
ARRAY['https://rashikesarwani.com/2023/12/winter-news-final-bart-mtg-street-paving-ac-transit-routes', 'https://rashikesarwani.com/north-berkeley-bart', 'https://rashikesarwani.com/2025/04/april-news-middle-housing-mtg-postponed-ohlone-park-mtg-more']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Kesarwani explicitly frames single-family zoning as a tool of racial and class segregation and argues her middle housing ordinance advances 'diversity, equity, and inclusion'; she advocates for equitable housing distribution 'affirmatively further[ing] fair housing' rather than concentrating development in historically redlined neighborhoods; she champions Office of Race, Equity, and Diversity funding and supports equitable tree canopy distribution targeting historically underserved West Berkeley.$$,
ARRAY['https://rashikesarwani.com/2025/04/april-news-middle-housing-mtg-postponed-ohlone-park-mtg-more', 'https://rashikesarwani.com/2022/07/summer-news-marina-pier-state-funding-possible-ballot-measures-housing-element-more', 'https://rashikesarwani.com/2022/05/action-alert-council-to-make-important-public-safety-decisions-tonight']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Kesarwani supports targeted economic development with community benefit requirements: she pursued $44M in state/federal funding for San Pablo Avenue safety improvements, supported the Gilman District business corridor, and secured BART development with a Memorandum of Agreement requiring design standards compliance and community benefits. She does not offer broad corporate tax abatements but actively pursues infrastructure investment to attract economic activity.$$,
ARRAY['https://rashikesarwani.com/2024/04/april-news-san-pablo-safety-upgrades-gilman-district-street-fair-bike-race-more', 'https://rashikesarwani.com/2022/10/fall-news-n-berkeley-bart-developer-public-presentations-more']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rashi Kesarwani / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2013613-769f-4374-809e-a018dbc1e683', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Kesarwani lists 'Clean Public Spaces' as a top issue priority; she co-wrote a 2019 Berkeleyside op-ed titled 'We need a clean and healthy Berkeley for all'; she funded the Downtown Streets Team expansion to Gilman District for twice-weekly cleaning services; and she pursues encampment closures partly on public health grounds (Leptospirosis outbreak). She treats poor sanitation conditions as a services failure requiring active city response.$$,
ARRAY['https://rashikesarwani.com', 'https://rashikesarwani.com/2022/07/summer-news-marina-pier-state-funding-possible-ballot-measures-housing-element-more', 'https://rashikesarwani.com/2026/01/jan-news-public-health-alert-lepto-at-harrison-encampments']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Terry Taplin (Council Member (District 2))
-- ============================================================

-- ----- Terry Taplin / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '669cac97-66a6-4087-b036-936fbe62efb3', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Taplin introduced a resolution recognizing 'housing as a human right' in Berkeley and proposed an Affordable Housing Overlay permitting 'up to an additional 6 stories as-of-right for 100% affordable housing in some neighborhoods.' His homelessness response page notes Berkeley has opened or funded over 790 housing units and he advocates substantial public investment combined with prevention services and case management.$$,
ARRAY['https://www.terrytaplin.com/affordable-housing', 'https://www.terrytaplin.com/legislation', 'https://www.terrytaplin.com/comprehensive-homeless-response']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Taplin frames enforcement as contingent on shelter availability, stating 'City ordinances regulating encampments and RVs are unenforceable in the absence of shelter options.' He focuses on shelter-plus-services over criminalization and directs constituents to the Specialized Care Unit for outreach. He supports decriminalizing public camping absent adequate shelter and invests in permanent supportive housing.$$,
ARRAY['https://www.terrytaplin.com/priorities/homelessness', 'https://www.terrytaplin.com/comprehensive-homeless-response', 'https://www.terrytaplin.com/housing']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Taplin's comprehensive homeless response prioritizes permanent and interim housing, shelter, and wraparound services including 'staffing, housing navigation, case management, hygiene facilities, security, and wraparound care including mental health and recovery support.' He describes homelessness as solvable through coordinated leadership and sustained financial commitment rather than enforcement-first approaches.$$,
ARRAY['https://www.terrytaplin.com/comprehensive-homeless-response', 'https://www.terrytaplin.com/priorities/homelessness']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Taplin served on the Berkeley Rent Stabilization Board before joining the council and supports strengthening tenant protections. On a Rent Board ballot measure he voted against provisions that would strip ADU owner-occupant protections approved by voters under Measure Q, stating constituents felt it would 'pull the rug out from under them.' He 'generally favor[s] removing obsolete statutory loopholes' that weaken rent control coverage and supports requiring replacement units for demolished rent-controlled housing.$$,
ARRAY['https://www.terrytaplin.com/post/statement-on-berkeley-rent-board-proposed-ballot-measure', 'https://www.terrytaplin.com/housing']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Taplin proposed an Affordable Housing Overlay allowing 'up to an additional 6 stories as-of-right for 100% affordable housing in some neighborhoods, one additional story as-of-right in single-family neighborhoods' — significantly upzoning single-family areas for affordable development. Modeled on Cambridge, MA and AB 1763, this is a pro-density reform that broadly expands multifamily rights by-right, consistent with streamlining approvals and reducing barriers for affordable housing.$$,
ARRAY['https://www.terrytaplin.com/affordable-housing', 'https://www.terrytaplin.com/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Taplin advocates a Vision 2050 framework for 'climate-smart, technologically-advanced, integrated and efficient infrastructure' and states that 'California cannot meet its climate goals without curbing growth in single-occupancy vehicle activity.' He chairs Berkeley's Facilities, Infrastructure, Transportation, Environment, and Sustainability Committee and frames transportation — responsible for 60% of Berkeley's emissions — as the central climate battleground.$$,
ARRAY['https://www.terrytaplin.com/priorities/vision-2050', 'https://www.terrytaplin.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Taplin introduced the Equitable Safe Streets and Climate Justice Resolution to adopt the NACTO Urban Street Design Guide as the default engineering standard for city streets and designated the Ninth Street Greenway as a linear city park. He applies consistent environmental and safety standards to infrastructure projects while supporting significant new affordable housing development — giving developers flexibility on implementation within those standards.$$,
ARRAY['https://www.terrytaplin.com/legislation', 'https://www.terrytaplin.com/priorities/vision-2050']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Taplin identifies himself as a 'green transportation' and 'mobility and environmental justice activist' who chairs the Transportation, Environment, and Sustainability Committee. He supports the 51B Bus Rapid Transit and University/Shattuck Corridor improvements, introduced the Equitable Safe Streets and Climate Justice Resolution adopting NACTO design standards, and states California cannot meet climate goals without curbing single-occupancy vehicles. He emphasizes 'significant investments in road safety identified in our Bicycle Plan and Pedestrian Plan' and a Vision Zero approach.$$,
ARRAY['https://www.terrytaplin.com', 'https://www.terrytaplin.com/priorities/vision-2050', 'https://www.terrytaplin.com/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Taplin states 'Police officers are not social workers or mental health specialists' and believes the city should 'reorient our city's response to violence in a proactive way that centers social services and crisis response.' He advocates for the Specialized Care Unit and other community-based solutions alongside the police department and convened stakeholder meetings to examine violence prevention programs. He supports police accountability and zero tolerance for racism in policing while maintaining police staffing.$$,
ARRAY['https://www.terrytaplin.com/public-safety', 'https://www.terrytaplin.com/priorities/community-safety']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Berkeley is a sanctuary city and the council voted unanimously to codify sanctuary protections. Taplin is a sitting progressive council member with no evidence of opposing sanctuary policies; Berkeley's sanctuary ordinance prohibits city personnel from sharing immigration information with federal enforcement agencies. His public safety page emphasizes equity and anti-racism in law enforcement consistent with full sanctuary protection.$$,
ARRAY['https://www.terrytaplin.com', 'https://www.terrytaplin.com/priorities/community-safety']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '0bc588c6-39e1-4084-b5de-cac909b8b762', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Taplin states there must be 'zero tolerance for racism, bigotry, and hate anywhere in our city, let alone among the first responders' and champions 'ending the era of racist policing.' He proposed workforce development services for the recently incarcerated and basic income pilots through the Office of Racial Equity, introduced a 'housing as a human right' resolution, and advocates for equitable distribution of transportation safety improvements prioritizing 'the most disadvantaged in our community.'$$,
ARRAY['https://www.terrytaplin.com/post/cm-taplin-statement-on-police-misconduct-allegations', 'https://www.terrytaplin.com/legislation', 'https://www.terrytaplin.com/priorities/vision-2050']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Terry Taplin / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdb549a-48bf-400f-9d23-c93e2e71007c', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Taplin proactively supports new housing development through targeted zoning reforms (Affordable Housing Overlay, density bonuses) and supports state/regional collaboration to expand housing supply. However his approach links density increases to affordability requirements rather than removing all regulatory barriers — he supports responsible expansion with affordability conditions rather than pure market-rate deregulation.$$,
ARRAY['https://www.terrytaplin.com/affordable-housing', 'https://www.terrytaplin.com/comprehensive-homeless-response', 'https://www.terrytaplin.com/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ben Bartlett (Council Member (District 3))
-- ============================================================

-- ----- Ben Bartlett / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '669cac97-66a6-4087-b036-936fbe62efb3', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Bartlett led creation of Berkeley's Step Up Housing — 39 modular prefabricated units with wraparound services for unhoused residents — and chaired the ADU task force; campaign reports over 1,000 affordable homes created during his tenure and 90% reduction in Ellis Act evictions. He sits on both the Land Use/Housing/Economic Development and Housing Authority/City Council joint committees. Strong public investment in affordable housing but not full public ownership.$$,
ARRAY['https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett', 'https://www.ben2024.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Bartlett's campaign reports homelessness down 45% during his tenure through the Step Up Housing initiative — 39 modular units with onsite care and health technology integration — and the Specialized Care Unit dispatching healthcare workers instead of police to mental health and homelessness-related calls. His approach is service-and-housing-first rather than enforcement-first; no evidence of camping ban sponsorship.$$,
ARRAY['https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett', 'https://www.ben2024.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Bartlett authored the Specialized Care Unit (dispatches healthcare workers instead of police for mental health and unhoused resident calls) and developed Step Up Housing as a supportive housing model with wrap-around services. His forward agenda includes expanding the Specialized Care Unit to 24/7 service. No evidence of sponsoring camping bans; his documented approach prioritizes services and shelter over enforcement.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Bartlett's campaign credits him with strengthening tenant protections and reducing Ellis Act evictions by 90% citywide. He sits on Berkeley's Land Use, Housing & Economic Development Committee and supports Berkeley's existing rent stabilization framework. His record reflects the strongest end of tenant protection advocacy — active reduction of evictions and rent increases — consistent with expanded rent control and strong just-cause protections.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Bartlett authored the George Floyd Community Safety Act (police reform ordinance), created BerkDOT (moving traffic enforcement from police to unarmed civilian workers), and established the Specialized Care Unit (healthcare workers dispatched instead of police for mental health calls). He strengthened civilian oversight via a Police Review Commission Charter Amendment. His campaign explicitly describes redirecting police functions to civilian programs — consistent with significantly redirecting police budget toward social services.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Berkeley is a sanctuary city. Bartlett's campaign credits making Berkeley a 'Cannabis Sanctuary City' with racial equity policies. No evidence of ICE cooperation or detainer compliance. He sits on Berkeley's Health, Life Enrichment, Equity & Community Committee and his overall record of racial equity advocacy is consistent with full sanctuary protections — refusing ICE detainers and protecting immigrant information.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Bartlett championed Berkeley's natural gas ban in new construction, EV charging infrastructure, plastic bag ban, and toxic paper receipts ban. His forward agenda includes the Berkeley Green New Deal. He authored a Disaster Preparedness Fire Plan and endorsed by Sierra Club and 350 Bay Area Action. Strong climate action record but not declaring a full emergency or banning all carbon-emitting activities.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.ben2024.com/endorsements', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Bartlett championed Berkeley's plastic bag ban, banned single-use plastics and toxic paper receipts, advocated natural gas ban in new construction, and lists the Adeline Greenway Park in his forward agenda. He served as Vice-Chair of the Zero Waste Commission. Endorsed by Sierra Club and 350 Bay Area Action. Strong environmental protection record requiring developers to meet significant environmental standards.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett', 'https://www.ben2024.com/endorsements']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Bartlett championed bike lanes on Adeline Street, the MLK Street redesign for pedestrian and cyclist safety, and the Vision Zero Initiative. He served on Berkeley's Transportation Commission working on EV infrastructure. His BerkDOT program also involved redesigning how traffic enforcement operates. His campaign emphasizes pedestrian and cycling infrastructure alongside road safety — consistent with equal investment in roads and multimodal options.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Bartlett led Berkeley's ADU task force to streamline accessory dwelling unit permitting — a significant upzoning of single-family lots — and supports the Ashby BART Transit Village, a major transit-oriented mixed-use development. His committee assignments include Land Use/Housing/Economic Development and 4x4 Joint Task Force on Housing, and his record reflects a pro-density stance focused on adding housing supply through streamlined permitting.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '0bc588c6-39e1-4084-b5de-cac909b8b762', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Bartlett's campaign credits him with supporting reparations initiatives, creating BenDex (racial equity in city contracting), making Berkeley a Cannabis Sanctuary City with racial equity priorities, enacting Paid Family Leave, and championing equity and inclusion as a '5th generation Berkeley native.' He frames his entire legislative record around racial equity and economic justice for disadvantaged communities, consistent with the most progressive civil rights stance including reparations support.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
$$Bartlett authored the George Floyd Community Safety Act (police reform), created BerkDOT (redirecting traffic enforcement from police to civilian workers), established the Specialized Care Unit (civilian mental health response instead of police), and invested $3M in gun violence prevention programs through community-based approaches. His record reflects redirecting incarceration-adjacent funding into community-based mental health, addiction, and restorative programs.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Bartlett led the ADU task force and supports the Ashby BART Transit Village — proactive infrastructure-ahead-of-growth approach. He is on the Housing Authority/City Council joint committee and the 4x4 Housing Task Force. His campaign emphasizes creating homes and growing affordable supply while maintaining community benefit requirements (cannabis equity, racial equity contracting). He does not impose growth limits but also does not remove all regulatory barriers.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ben Bartlett / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eaab41f8-71c8-47db-bd0b-62da46b5607b', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Bartlett created BenDex (racial equity in city contracting), the Micro Bond Community Finance initiative, cannabis equity licensing policies, and advocates for South Berkeley Community Fund, storefront activation grants, and small business support. This is targeted economic development with community benefit and equity requirements rather than broad corporate incentives or no incentives.$$,
ARRAY['https://www.ben2024.com/issues', 'https://www.berkeleyca.gov/your-government/city-council/council-roster/ben-bartlett']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Igor Tregub (Council Member (District 4))
-- ============================================================

-- ----- Igor Tregub / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Tregub served 8 years on the Berkeley Rent Stabilization Board and as a council member has actively expanded tenant protections: he authored a referral (Item 15, March 2025) to close the on-site manager exemption loophole for multi-family properties to strengthen rent board coverage, and voted yes on an ordinance prohibiting algorithmic rent-setting devices (March 2025). He also referred a study of transfer tax exemptions to incentivize affordable housing conversions by nonprofits and community land trusts.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-11-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-25-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Tregub co-sponsored a $200,000 deportation defense legal and education fund referral (April 29, 2025) alongside the mayor and two other council members. The full Berkeley City Council voted in January 2025 to reaffirm Berkeley's sanctuary city status — refusing to assist ICE — and later unanimously codified a sanctuary ordinance prohibiting city personnel from sharing immigration status information with federal agencies.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-21-2025', 'https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Tregub chaired the 35,000-member Sierra Club San Francisco Bay Chapter (the youngest and first immigrant to hold the role) and serves as Co-Vice Chair of Sierra Club California. As a council member he co-sponsored a resolution supporting a feasibility study for Golden State Energy — a nonprofit public utility to replace PG&E (February 2025) — and co-sponsored the Zero NOx Emission Buildings ordinance requiring all new construction to be gas-free (October 2024). His career at Reimagine Power focuses on renewable energy advocacy.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-february-11-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-october-15-2024']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'a22215c3-6693-4bc2-b248-01aebba14570', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Tregub's entire career and civic record is oriented toward eliminating fossil fuel infrastructure. As Sierra Club SF Bay Chapter chair he led the region's most prominent environmental organization. He co-sponsored the Golden State Energy resolution (February 2025) to study replacing PG&E — an investor-owned gas utility — with a public nonprofit model prioritizing renewable energy. He co-sponsored the Zero NOx Emission Buildings ordinance banning fossil gas in new construction. His employer Reimagine Power advocates for renewable energy legislative reform.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-february-11-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-october-15-2024']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Tregub authored two pedestrian safety budget referrals in November 2024: $50,000 for a traffic study and pedestrian improvements at Shattuck/Delaware, and $30,000 for an Accessible Pedestrian Signal at Sacramento/Allston. He supported council consent items funding Southwest Berkeley Bike Boulevards ($4 million) and the Adeline Street Quick-Build active transportation project ($1 million) in October 2024, and a Bay Trail Extension grant ($4 million) in October 2024. His Sierra Club background and energy career emphasize reducing car dependence.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-november-12-2024', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-october-15-2024', 'https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', '669cac97-66a6-4087-b036-936fbe62efb3', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Tregub serves on Berkeley's Land Use, Housing & Economic Development Committee and the 4x4 Joint Task Force on Housing. He authored a referral to study transfer tax exemptions for 100% affordable housing projects owned by nonprofits and community land trusts (March 2025) and supported Homekey+ applications for permanent supportive housing (veterans housing, September 2024). He supports significant public investment in affordable housing — not full public ownership — combined with market production.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-11-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-10-2024']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Tregub serves on the Health, Life Enrichment, Equity & Community Committee which oversees homeless services. The Berkeley City Council's encampment policy (adopted September 24, 2024, which Tregub voted on) requires offering interim housing before closing encampments with narrow public-safety exceptions — a shelter-first approach. A November 2024 Peace and Justice Commission resolution opposing criminalization of poverty was on the agenda; the City Manager noted existing policy already embodied these protections.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-24-2024', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-november-12-2024', 'https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Tregub's council positions support shelter and services over criminalization: the Berkeley encampment policy he voted on (September 2024) conditions enforcement on availability of interim housing and has narrow public-safety exceptions. The council's approach — which Tregub operates within — directs funding to housing and mental health services as the primary response rather than citing or arresting unhoused people for sleeping outside when shelter is unavailable.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-24-2024', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-november-12-2024', 'https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Tregub voted yes on Berkeley's Middle Housing Ordinance (first reading, April 29, 2025; BESO companion passed unanimously April 15, 2025) amending the Zoning Ordinance to allow middle housing in areas currently zoned R-1, R-1A, R-2, R-2A, and MU-R — the city's low-density residential districts. This allows duplexes, fourplexes, and cottage courts broadly across single-family neighborhoods, effective September 1, 2025.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-15-2025', 'https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Tregub supports proactive housing production through targeted zoning reforms (Middle Housing Ordinance, affordable housing overlay studies) and serves on the Land Use, Housing & Economic Development Committee. His approach combines supporting new development with affordability requirements and tenant protections — he studied transfer tax exemptions for nonprofit affordable housing and sponsored pedestrian infrastructure investments. He is not imposing growth limits but is not removing all regulatory barriers.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-11-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Tregub co-authored a council resolution supporting California Proposition 6 (November 2024) — the constitutional amendment to abolish forced prison labor — signaling a criminal justice reform orientation. He supported Police Accountability Board appointments and his council profile emphasizes mental health services through his committee on Health, Life Enrichment, Equity & Community. No evidence of police defunding sponsorship; he reflects a co-responder/accountability model rather than pure police budget expansion.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-october-15-2024', 'https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Igor Tregub / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9a35a9-0226-45f0-9fd8-ef46163f7245', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$As chair of the Sierra Club San Francisco Bay Chapter (35,000 members) and Co-Vice Chair of Sierra Club California, Tregub brings a strong environmental protection orientation to city governance. He co-sponsored the Zero NOx Emission Buildings ordinance (October 2024) and the Building Emissions Saving Ordinance amendments (BESO). His career at Reimagine Power focuses on renewable energy infrastructure. He supports significant environmental review requirements while also backing housing development with environmental conditions.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-october-15-2024', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-15-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Shoshana O'Keefe (Council Member (District 5))
-- ============================================================

-- ----- Shoshana O'Keefe / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$O'Keefe co-sponsored the second reading of Berkeley's Sanctuary City Contracting Ordinance (Dec 2, 2025) — a binding municipal code update codifying sanctuary policy into procurement rules; Berkeley's sanctuary city ordinance passed first reading in September 2025 and O'Keefe is on the record supporting its implementation. The sanctuary city reaffirmation was on the January 21, 2025 agenda that O'Keefe participated in as a newly seated member.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-9-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-21-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$O'Keefe voted YES on Berkeley's algorithmic rent-setting ban (March 25, 2025 — 8-1, only Humbert opposed), prohibiting landlords from using pricing algorithms to set rents or manage occupancy; she also co-sponsored a March 11, 2025 referral studying a transfer tax exemption for 100% affordable housing owned by nonprofits or community land trusts, signaling strong pro-tenant and pro-affordable-housing orientation.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-25-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-11-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '669cac97-66a6-4087-b036-936fbe62efb3', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '669cac97-66a6-4087-b036-936fbe62efb3',
$$O'Keefe authored a May 20, 2025 council item directing the city to find locations for 24/7 staffed shelters and co-sponsored a transfer tax exemption study for 100% affordable housing; she abstained (rather than voting yes) on ADU ordinance amendments in September 2025, suggesting some caution on market-rate density increases but support for affordable housing production specifically.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-20-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-11-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-9-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$O'Keefe authored Item 29 (May 20, 2025) directing the City Manager to identify locations for 24/7 staffed shelters — indoor/outdoor camping areas, safe RV and car park zones, and congregate or non-congregate shelters — while assessing geographic equity and partnering with Alameda County. Her co-sponsorship of the Urban Compassion Project (Dec 2, 2025) further reflects a services-investment orientation toward homelessness.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-20-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$O'Keefe authored the alternative housing options item (May 20, 2025) expanding shelter types and capacity — not criminalization. Her approach emphasizes services and geographic equity; the item calls for assessing resource gaps and funding opportunities (Measure W, Prop 1) rather than enforcement. She also co-sponsored the Urban Compassion Project which provides community support services for homeless residents (Dec 2025).$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-20-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$O'Keefe co-sponsored the NACTO street design standards study and traffic diverters safety review (Feb 11, 2025); co-sponsored the automated speed enforcement pilot to reduce traffic violence (Apr 29, 2025); the traffic diverters item explicitly referenced a traffic violence memorial as context, demonstrating a pedestrian-safety-first orientation. Berkeley's SAFE STREETS (Measure FF) framework she operates within prioritizes multimodal safety over car throughput.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-february-11-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$O'Keefe co-sponsored a resolution supporting free and safe passage of whales, sea turtles, and other marine animals consistent with California's Vision Zero marine mortality target (Feb 25, 2025); she co-sponsored the EMBER Implementation Plan and Vegetation Management Working Group for fire safety and habitat management (June 17, 2025). These demonstrate consistent environmental protection positions across marine and fire-ecology issues.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-february-25-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-17-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$O'Keefe co-sponsored environmental resolutions (marine life protection, fire vegetation management) consistent with climate awareness; she co-sponsored Measure FF SAFE STREETS implementation supporting active transportation. However, no evidence of a climate emergency declaration, fossil fuel bans, or aggressive decarbonization advocacy. Her co-sponsorship of fire vegetation management reflects climate adaptation rather than aggressive mitigation — consistent with investing in resilience while maintaining current energy frameworks.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-february-25-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-17-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$O'Keefe abstained (rather than voting yes) on Berkeley's ADU ordinance amendments in September 2025 — the first reading passed 7-0 with O'Keefe and Blackaby abstaining. This suggests she is not a strong density advocate; she does not appear to have sponsored or co-sponsored any upzoning initiatives. Her housing focus is specifically on affordable/income-restricted units rather than market-rate density, placing her in a middle position on residential zoning.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-9-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-11-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$O'Keefe abstained on ADU ordinance amendments (Sep 9, 2025) and has not sponsored any broad upzoning or streamlined permitting items. Her development-related actions focus on affordable housing specifically (transfer tax exemption for nonprofits/CLTs) and parks improvements (Thousand Oaks Park playground). This reflects a proactive but targeted approach — supporting affordable housing production while not actively pushing market-rate permitting reform.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-9-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-11-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-15-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$O'Keefe co-sponsored the ROBOCOP ordinance (Oct 14, 2025) restricting motion-activated surveillance devices that emit sound in public spaces — a privacy protection measure. Berkeley's surveillance technology framework (BMC 2.99) was accepted by council on consent during her tenure. She co-sponsored automated speed enforcement and NACTO standards. No evidence of police budget expansion advocacy or defunding sponsorship — reflects current funding with added accountability mechanisms.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-october-14-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-february-11-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$O'Keefe co-sponsored Berkeley's Sanctuary City Contracting Ordinance (Dec 2, 2025) protecting immigrant workers in city contracting; she co-sponsored the Holocaust Remembrance Day resolution (Apr 15, 2025) committing to combat antisemitism and bigotry. Berkeley's anti-discrimination framework is strong and O'Keefe operates consistently within it. No evidence of equity mandates or reparations advocacy from her specifically.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-15-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$O'Keefe co-sponsored the Vibrant Storefront Policy (Dec 2, 2025) — a downtown revitalization referral to the City Manager and City Attorney — focused on activating vacant commercial storefronts. She co-sponsored Item 16 on a First Year Free Storefront Program (March 2025). Her economic development positions target small business and local commercial activation rather than large corporate incentives or pure market-based approaches.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-11-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shoshana O'Keefe / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$No direct evidence of O'Keefe sponsoring sanitation-specific ordinances. Berkeley maintains regular sanitation services and the council operates within a city-manager framework for most departmental services. Her homelessness shelter proposal (May 20, 2025) which addresses encampments and RV sites indirectly relates to sanitation by moving people into staffed sites. Insufficient direct evidence for a higher or lower score.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-20-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Brent Blackaby (Council Member (District 6))
-- ============================================================

-- ----- Brent Blackaby / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Blackaby authored a Budget Referral allocating $200,000 for Deportation Defense Legal and Education Funds (Item 21, April 29, 2025), co-sponsored by the Mayor and two other council members; adopted unanimously. Berkeley is a sanctuary city and Blackaby's authorship of active anti-deportation funding demonstrates the strongest form of local sanctuary policy.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '44905f3b-e105-4f6c-afc7-5d223813dbac', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '44905f3b-e105-4f6c-afc7-5d223813dbac',
$$Blackaby authored a $200,000 Budget Referral for Deportation Defense Legal and Education Funds (April 29, 2025), explicitly to fund legal defense and education for people facing deportation. This is the strongest possible local stance against deportation — actively funding legal resistance to federal deportation efforts.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Blackaby voted AYE on the ordinance prohibiting algorithmic rent-setting devices (Ord. 7,956-N.S.) at both first reading (March 11, 2025; 8-1 vote) and second reading (March 25, 2025). He also voted AYE on the Inclusionary Housing Ordinance In-Lieu Fee (March 11, 2025, All Ayes) strengthening affordable housing requirements. These reflect strong tenant protection positions within Berkeley's existing rent stabilization framework.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-11%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-25%20Annotated%20Agenda%20-%20Council.pdf']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '669cac97-66a6-4087-b036-936fbe62efb3', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Blackaby voted AYE on a 166-unit dense mixed-income housing development at 3000 Shattuck Ave including 17 very-low-income units (March 25, 2025), voted AYE on Inclusionary Housing In-Lieu Fee amendments (March 11, 2025), serves on the 4x4 Joint Task Force Committee on Housing, and co-seconded the 2025-2030 Consolidated Plan motion allocating CDBG/ESG/HOME funds including rapid rehousing (April 29, 2025). Affordable housing was a top campaign priority.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-25%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Blackaby authored two council items prioritizing pedestrian safety and active transportation: (1) AB-645 Automated Speed Enforcement Pilot for Berkeley (Item 23, April 29, 2025) to reduce traffic violence, and (2) Adding ADA expertise to the SAFE STREETS Citizen Oversight Committee (Item 22, April 29, 2025) to prioritize seniors and disabled community members in transportation infrastructure. He also co-sponsored Bay Area Public Transit funding (Item 25, April 29, 2025). Streets and transportation was a campaign priority.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Blackaby authored an urgency resolution supporting AB-389 Personal Income Tax Credits for Fire-Resistant Home Improvements (April 29, 2025) — a climate adaptation measure for wildfire resilience. He serves on the East Bay Wildfire Coalition board and listed wildfire safety as a campaign priority. He voted AYE on the Building Emissions Saving Ordinance (BESO) amendments for small residential buildings (March 25, 2025, All Ayes). Consistent climate/resilience focus but no evidence of emergency declarations or fossil fuel bans.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-25%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Blackaby serves on the East Bay Wildfire Coalition board, authored wildfire-resilience tax credit legislation (AB-389, April 2025), and voted AYE on the Building Emissions Saving Ordinance (BESO) amendments for small residential buildings (March 25, 2025). These reflect consistent environmental protection positions across fire ecology and building emissions. He voted AYE on a 166-unit housing development with CEQA compliance at 3000 Shattuck — balancing development with environmental standards.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-25%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Blackaby chairs the Public Safety Policy Committee and served on the Berkeley Police Accountability Board — reflecting a balanced approach combining institutional police oversight with maintaining public safety services. He voted AYE to take no action on a resolution condemning police brutality and less-lethal weapons (April 29, 2025; following his own committee's negative recommendation). He co-founded Make Our Schools Safe (MOSS) and campaigned on crime and public safety as a priority, consistent with a co-responder model rather than defunding or strong expansion.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Blackaby listed homelessness as a top campaign priority but no specific encampment-enforcement or housing-first legislation appears authored by him in the reviewed council meetings (Feb–Apr 2025). Berkeley's encampment policy requires shelter offers before closures — a framework Blackaby operates within as chair of the Public Safety Committee. The middle position (outreach + services + reasonable public space enforcement) reflects his committee oversight role without evidence of a more extreme position in either direction.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby', 'https://berkeleyca.gov/your-government/city-council/council-committees/policy-committee-public-safety']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Blackaby campaigned on addressing homelessness as a pressing challenge but authored no specific legislation on housing-first or encampment policy in the reviewed period. He serves on the Public Safety Committee which oversees homelessness-related public space issues. His overall record — strong on deportation defense and tenant protections but measured on police accountability — is consistent with a centrist progressive position on homelessness services vs. enforcement.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby', 'https://berkeleyca.gov/your-government/city-council/council-committees/policy-committee-public-safety']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Blackaby voted AYE to uphold the Zoning Adjustments Board's approval of a 10-story 166-unit housing development at 3000 Shattuck Ave (March 25, 2025; voted with Kesarwani, Humbert, Ishii vs. Taplin, Bartlett — a notable pro-density split), and voted AYE on Inclusionary Housing and EV charging zoning amendments. His campaign listed affordable housing as a top priority consistent with supporting density where affordability is included.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-25%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Blackaby authored the $200,000 Deportation Defense Legal and Education Fund (April 29, 2025) protecting immigrant residents' civil rights, and voted AYE on the urgency resolution condemning Islamophobia and reaffirming support for the Muslim community (March 11, 2025, All Ayes). His background in progressive digital politics for Democratic candidates including Senators Warren and Boxer reflects a consistent civil rights orientation. Served on Berkeley Police Accountability Board.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-11%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Blackaby voted AYE on a 166-unit high-density housing development (March 25, 2025) and on inclusionary housing fee amendments — supporting responsible expansion with affordability conditions. He serves on the 4x4 Housing Task Force. Affordable housing and infrastructure (streets, school safety) were campaign priorities consistent with proactive investment in infrastructure ahead of growth rather than growth limits or fully removing regulatory barriers.$$,
ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-25%20Annotated%20Agenda%20-%20Council.pdf', 'https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brent Blackaby / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('424eb63b-9976-4059-8049-365c09719cc6', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Blackaby serves on the East Bay Public Bank board — a community-investment institution that lends public dollars to local governments, nonprofits, unions, and community groups rather than offering corporate tax incentives. He authored ADA infrastructure improvements to transportation oversight. This reflects targeted community investment with public benefit requirements rather than broad corporate subsidies or a pure market approach.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/brent-blackaby', 'https://www.publicbankeastbay.org']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Cecilia Lunaparra (Council Member (District 7))
-- ============================================================

-- ----- Cecilia Lunaparra / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Lunaparra co-sponsored Berkeley's sanctuary city reaffirmation and ICE non-cooperation resolution (Jan 21, 2025), co-sponsored the referral to codify sanctuary policy into a formal ordinance (Apr 15, 2025), authored the Sanctuary City Contracting Ordinance updates (second reading Dec 2, 2025) to align city procurement rules with the new sanctuary ordinance, and co-sponsored a $200,000 deportation defense legal and education fund (Apr 29, 2025).$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-21-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-15-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '44905f3b-e105-4f6c-afc7-5d223813dbac', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '44905f3b-e105-4f6c-afc7-5d223813dbac',
$$Lunaparra co-sponsored a $200,000 budget referral for Deportation Defense Legal and Education Funds (Apr 29, 2025), explicitly to fund legal defense and education for people facing deportation by federal immigration enforcement. She also authored the Sanctuary City Contracting Ordinance (Dec 2, 2025) which strengthens protections for immigrant workers in city contracts.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Lunaparra was the sole NO vote on the Encampment Policy Resolution (first reading, Sep 24, 2024) — an 8-1 vote — that authorized faster removal of encampments in designated areas. She subsequently co-sponsored an item directing the City Manager to identify locations for 24/7 staffed shelter sites as the alternative response (May 20, 2025). Her record reflects a housing-first orientation that opposes criminalization of public sleeping in favor of shelter and services investment.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-24-2024', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-20-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Lunaparra co-sponsored a $25,000 budget referral to fund Street Spirit's drop-in center and vendor coordination program for unhoused residents (Apr 29, 2025) and co-sponsored directing the City Manager to identify locations for 24/7 staffed shelter sites with wraparound services (May 20, 2025). Her voting record shows consistent preference for services and shelter investment as the primary response to homelessness over enforcement.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-20-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Lunaparra authored a resolution affirming Berkeley's support for permanent 24/7 protected bicycle and pedestrian access to the Richmond-San Rafael Bridge Trail (Dec 10, 2024); co-sponsored a $400,000 referral for a Class IV protected bike facility on Oxford/Fulton Streets (Jun 3, 2025); authored a $1.25 million curb-marking and daylighting infrastructure referral for pedestrian safety at intersections (Jan 21, 2025); co-sponsored Bay Area public transit funding (Apr 29, 2025); and co-sponsored Vision Zero reaffirmation (Jun 17, 2025). Transportation policy is listed as a primary focus area on her official city bio.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-10-2024', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-3-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-21-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Lunaparra co-sponsored a resolution supporting the Polluters Pay Climate Superfund Act (AB 1243/SB 684, Jun 3, 2025) to hold fossil fuel corporations accountable for climate damages in California; co-sponsored a marine animal safe passage resolution aligned with California's Vision Zero marine mortality target (Feb 25, 2025); and opposed AB 942 which would have modified net energy metering customer-generator tariffs. She previously chaired Berkeley's Environment and Climate Commission before joining the council.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-3-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-february-25-2025', 'https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'a22215c3-6693-4bc2-b248-01aebba14570', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Lunaparra co-sponsored the Polluters Pay Climate Superfund Act support resolution (AB 1243/SB 684, Jun 3, 2025) specifically targeting fossil fuel corporations for accountability over climate damages. She co-sponsored Berkeley's opposition to AB 942 which affected net energy metering for customer-generators — opposing a bill seen as weakening renewable energy incentives. She previously chaired the Environment and Climate Commission.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-3-2025', 'https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Lunaparra chaired Berkeley's Environment and Climate Commission before joining the council; co-sponsored the Polluters Pay Climate Superfund Act support resolution (Jun 3, 2025); co-sponsored a marine animal safe passage resolution (Feb 25, 2025); and opposed AB 942 (net energy metering rollback). Her committee assignments include Facilities, Infrastructure, Transportation, Environment and Sustainability. Her environmental record reflects strong protection positions and requiring developers and corporations to offset environmental impacts.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-3-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-february-25-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Lunaparra co-authored (passed 8-1) the ordinance prohibiting the sale or use of pricing algorithms to set rents or manage occupancy levels for residential dwelling units (first reading March 11, 2025; second reading/adoption March 25, 2025), creating new Chapter 13.63 of the Berkeley Municipal Code. Only Councilmember Humbert voted no. This is a significant expansion of tenant protections beyond Berkeley's existing rent stabilization framework.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-25-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-18-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Lunaparra co-sponsored the ADU Separate Sale Ordinance amendments (Dec 2, 2025) implementing AB 1033 to allow separate sale of ADUs as condominiums — increasing housing supply by allowing ADU owners to sell units independently; she also co-sponsored ADU Conversion Ordinance amendments (Oct 28, 2025) and serves on the Land Use, Housing & Economic Development Committee and the 4x4 Joint Task Force on Housing. Her record reflects support for incremental density increases to add housing supply.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-october-28-2025', 'https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '669cac97-66a6-4087-b036-936fbe62efb3', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Lunaparra serves on the Land Use, Housing & Economic Development Committee and the 4x4 Joint Task Force on Housing; co-sponsored ADU ordinance amendments enabling separate sale of ADUs as condominiums (Dec 2, 2025); co-sponsored 24/7 staffed shelter site identification for unhoused residents (May 20, 2025); and co-sponsored the Street Spirit drop-in center funding ($25K, Apr 29, 2025). Her housing focus combines rental tenant protections (algorithmic rent ban) with increasing supply via ADU reforms.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-20-2025', 'https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Lunaparra co-sponsored the family/relationship structure discrimination prohibition ordinance (May 21, 2024) adding Chapter 13.22 to the Berkeley Municipal Code; co-sponsored the $200,000 deportation defense fund (Apr 29, 2025); authored the Sanctuary City Contracting Ordinance protecting immigrant workers (Dec 2, 2025); and co-sponsored the Pride on the Plaza event (Jun 25, 2024) as an openly queer woman of color. Her official bio describes her as an advocate for 'progressive legislation and an equitable urban realm.'$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-21-2024', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025', 'https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Lunaparra's official bio lists policing policy as a primary focus area; she was the sole NO vote on the encampment enforcement ordinance (Sep 24, 2024) that enabled faster removals — preferring shelter and services over criminalization. Her background as a student activist and Zoning Adjustments Board commissioner, and her committee assignments on Facilities/Infrastructure/Transportation, are consistent with a public safety approach that prioritizes unarmed service responses over police expansion.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-24-2024', 'https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Lunaparra serves on the Land Use, Housing & Economic Development Committee and is on the Ava Community Energy Authority JPB — a joint powers board focused on community energy rather than corporate incentive packages. She co-sponsored the Oxford/Fulton Class IV bike facility ($400K referral) and curb infrastructure investments reflecting targeted public infrastructure investment. No evidence of large corporate tax abatements or broad economic incentive advocacy.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-3-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Lunaparra serves on the Land Use, Housing & Economic Development Committee and 4x4 Joint Task Force on Housing; she co-sponsored ADU ordinance amendments (Oct–Dec 2025) to enable more housing supply; as a new council member focused on housing and transportation she supports infrastructure investment ahead of growth. She is not actively sponsoring growth limits or requiring voter approval for developments, but is not removing all regulatory barriers either.$$,
ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Lunaparra's District 7 covers the Southside/Telegraph Avenue area near UC Berkeley campus, which has significant street cleanliness challenges. She was the sole NO vote on the encampment enforcement ordinance (Sep 24, 2024) which suggests she does not treat public space cleanliness primarily through enforcement. Her homelessness approach (shelter + services) implies treating sanitation through services rather than punitive action. No evidence of major sanitation-specific legislation.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-september-24-2024', 'https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
$$Lunaparra is described on her official city bio as 'the first openly queer woman of color' to serve on the Berkeley City Council. Her sponsorship of the Pride on the Plaza cultural event (Jun 25, 2024) and the family/relationship structure discrimination prohibition ordinance (May 21, 2024) are consistent with full legal equality for same-sex couples and LGBTQ+ individuals.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-june-25-2024', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-21-2024', 'https://berkeleyca.gov/your-government/city-council/council-roster/cecilia-lunaparra']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cecilia Lunaparra / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('116aace8-9440-498b-bf1d-ebb196727c85', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Lunaparra authored the Sanctuary City Contracting Ordinance updates (Dec 2, 2025), co-sponsored the $200,000 deportation defense fund (Apr 29, 2025), co-sponsored sanctuary city reaffirmation (Jan 21, 2025), and co-sponsored the codification of sanctuary policies into a formal ordinance (Apr 15, 2025). Her record reflects the most welcoming possible local stance — actively protecting and funding legal defense for immigrants.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-december-2-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-january-21-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mark Humbert (Council Member (District 8))
-- ============================================================

-- ----- Mark Humbert / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Humbert cast the sole NO vote (8-1) on Berkeley's ordinance prohibiting algorithmic rent-setting devices (Ord. 7,956-N.S., March 2025). His corridors zoning FAQ explicitly argues that market-rate housing supply — not regulation — is the primary tool for reducing rents, citing a 'filtering' effect and citing Berkeley data showing rent declines after downtown upzoning. He opposes the core rent control paradigm favored by the rest of the council.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-25-2025', 'https://markhumbert.com/corridors-zoning-update-faq/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Humbert voted AYE on Berkeley's Middle Housing Ordinance (unanimously adopted July 8, 2025) to end exclusionary single-family zoning; his corridors zoning FAQ advocates for market-rate and affordable housing supply as complements rather than substitutes; he opposes parking mandates and ballot-box zoning. He supports a 'tailored approach' limiting Elmwood upzoning to 3 specific sites at 2-3 story heights — pro-supply but more measured than colleagues who backed 7-story base heights.$$,
ARRAY['https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=b2576ae242', 'https://markhumbert.com/corridors-zoning-update-faq/', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-25-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', '669cac97-66a6-4087-b036-936fbe62efb3', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Humbert's corridors zoning FAQ explicitly supports housing supply growth — 'market-rate housing and affordable housing are complements, not substitutes' — cites Berkeley data showing rent declines after upzoning, and endorses the filtering theory that new units free up older affordable stock. He co-authored the corridors upzoning effort, backed middle housing, and opposes parking requirements for new construction. His approach centers market-rate production alongside inclusionary requirements.$$,
ARRAY['https://markhumbert.com/corridors-zoning-update-faq/', 'https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=9a603dd31c', 'https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=cc19367bb3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Humbert authored the traffic diverter study referral (Feb 11, 2025) requesting NACTO street design standard review; co-sponsored a $1.25M daylighting/curb-safety infrastructure referral (Jan 21, 2025); co-sponsored Berkeley's automated speed enforcement pilot (Apr 29, 2025); stated the 'inherent danger that cars pose to people walking and biking' requires urgent steps toward pedestrian/bike safety; backed AC Transit Line 22 realignment. Pedestrian safety is a stated top priority.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-february-11-2025', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025', 'https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=b02f34202c']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Humbert explicitly supports expanding police surveillance infrastructure: he endorsed the March 2025 transition to Flock Safety ALPRs and expansion of camera locations, stating the 'highly-effective' ALPR system is a key crime deterrent; his September 2025 newsletter states 'steadfast support for BPD's work and Council's efforts to ensure they have the resources and tools they need'; he also backs 'targeted use of unmanned aerial vehicles (UAVs).' He supports civil liberties conditions on surveillance but not redirecting police budget to social services.$$,
ARRAY['https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=d8580589ff', 'https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=81f6ea8dc0', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-18-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Humbert co-sponsored SB 692 (May 20, 2025) — a California bill streamlining removal of inoperable and nuisance vehicles — which lowers barriers for removing vehicles used as dwellings; this is paired with support for shelter expansion (the May 2025 council item identifying 24/7 shelter sites, which Humbert voted for). He uses Homeless Outreach & Treatment Team referrals in his newsletters. His approach combines enforcement tools with services rather than housing-first-only.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-20-2025', 'https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=b2576ae242']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Humbert lists 'addressing our homelessness and affordable housing crises' as a top stated priority; his newsletters consistently provide contact info for the Homeless Outreach & Treatment Team (HOTT) and direct constituents toward services. He supports shelter expansion alongside his housing supply approach. However he co-sponsored SB 692 which facilitates removal of vehicle-dwellers, and no housing-first-only legislation authored. Services + measured enforcement reflects a centrist position.$$,
ARRAY['https://www.markhumbert.com', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-may-20-2025', 'https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=b02f34202c']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Humbert voted AYE on Building Emissions Saving Ordinance amendments (Mar 25, 2025, all ayes), supported EMBER wildfire preparedness ordinance (June 2025), voted AYE on the building decarbonization evaluation item (May 20, 2025, all ayes), and his zoning FAQ cites reduced vehicle miles traveled near transit as a climate benefit. No evidence of fossil fuel ban advocacy, climate emergency declarations, or aggressive decarbonization championing beyond what the full council supported.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-25-2025', 'https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=e0ac7db6dc', 'https://markhumbert.com/corridors-zoning-update-faq/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Humbert supported EMBER wildfire preparedness regulations (VHFSZ buffer zones, fire-resistant construction requirements, vegetation management), voted AYE on Building Emissions Saving Ordinance amendments, and co-sponsored the Measure FF safe streets committee update. He applies consistent environmental standards while supporting housing development — the EMBER wildfire ordinance imposes significant requirements on hillside properties. No evidence of weakening environmental protections.$$,
ARRAY['https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=e0ac7db6dc', 'https://berkeleyca.gov/city-council-regular-meeting-eagenda-march-25-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Humbert is pro-development and pro-upzoning: he authored the corridors zoning update FAQ promoting new mixed-use housing along College Avenue, opposed parking mandates and ballot-box zoning restrictions, co-sponsored middle housing (unanimously adopted July 8, 2025), and explicitly argues that 'increases in housing supply reduce rents.' He opposes excessive process delays and calls ballot-measure zoning an 'urban planning worst practice.' Growth is welcome but within moderate height and design standards.$$,
ARRAY['https://markhumbert.com/corridors-zoning-update-faq/', 'https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=b2576ae242', 'https://us5.campaign-archive.com/?u=c5729e636ecda4dda2c067096&id=9a603dd31c']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Humbert / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7833be90-c693-40b8-a309-61ee77b4ba03', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Humbert co-sponsored the CalFresh Fruit and Vegetable EBT supplemental benefit program (Apr 29, 2025) to support food access for low-income residents; supports small businesses in the Elmwood (Music in Elmwood Festival, First Year Free Storefront awareness, small business as one of his three stated priorities); advocates mixed-use housing along commercial corridors. Targeted local economic support rather than corporate incentives or no intervention.$$,
ARRAY['https://berkeleyca.gov/city-council-regular-meeting-eagenda-april-29-2025', 'https://www.markhumbert.com', 'https://markhumbert.com/corridors-zoning-update-faq/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;