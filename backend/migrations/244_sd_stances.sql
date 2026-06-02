-- ============================================================================
-- Migration 244: San Diego Officials Stances — 11 Politicians
-- ============================================================================
-- Purpose: Insert/upsert stance data for 11 San Diego city officials.
--
-- Politicians: Todd Gloria (Mayor), Heather Ferbert (City Attorney),
--              Joe LaCava (D1), Jennifer Campbell (D2), Stephen Whitburn (D3),
--              Henry L. Foster III (D4), Marni von Wilpert (D5), Kent Lee (D6),
--              Raul Campillo (D7), Vivian Moreno (D8), Sean Elo-Rivera (D9)
--
-- Stance count: 164 rows (politician_answers + politician_context pairs)
--
-- Topic scope: 42 topics (all 43 live topics except data-centers)
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                               af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                          666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                       92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                              c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                        7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                           0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                         f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- deportation                            44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development                   eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                           a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development                 fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                             e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                           4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response                  6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                                669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                            4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                          c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-access-to-justice             9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-bail-pretrial                 1fab5edf-6151-4da0-9704-a7f2113ba54c
-- judicial-criminal-justice              9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-government-deference          e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-interpretation                448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- judicial-police-accountability         7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-prosecution-priorities        abb99d95-cbb1-4617-8f8b-f220ef6028ca
-- judicial-transparency                  6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment                      1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                      b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                           cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                         ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach                 e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                          48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                      6b9ba6d9-1001-43f5-b073-4d37130696fd
-- rent-regulation                        c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning                     d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                      c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                        00b95a6a-75db-4521-b523-3326bba938de
-- social-security                        87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                                683c8084-2281-4920-a07c-18439b2dd413
-- taxes                                  f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                         d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities              ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                        24e9212c-b011-422a-865c-093e35050901
-- voting-rights                          d1792200-1d3b-4955-a0b7-0e6980d7a7b2

-- Politician UUID reference (essentials.politicians):
-- Todd Gloria                    a975b943-f3e0-492a-bd26-9f5993a5c094
-- Heather Ferbert                0d81c306-514e-455c-988e-b0d04f7e0897
-- Joe LaCava                     1e93b635-3706-4268-91e2-97abae0c54a0
-- Jennifer Campbell              c6d7ea83-d6ee-4d08-a183-effd36f6a2cc
-- Stephen Whitburn               f86591f9-4341-4e3a-a9cb-f284887ccf74
-- Henry L. Foster III            296b5d71-954a-46db-8055-17299abb86fa
-- Marni von Wilpert              c3f1fad4-46cd-4f2f-8723-d7a3f99dca65
-- Kent Lee                       3fb56c85-f8b7-4732-88e1-f79b56750428
-- Raul Campillo                  84ba4a09-a90f-4ad4-9fa3-995961bd839c
-- Vivian Moreno                  0b16443e-fec4-4f33-abbc-eb1331e3b42d
-- Sean Elo-Rivera                dc3d8a98-07ce-4797-bc84-957a72fd854f

BEGIN;

-- ============================================================
-- Todd Gloria (Mayor)
-- ============================================================

-- ----- Todd Gloria / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Gloria signed the Unsafe Camping Ordinance in June 2023 prohibiting tent encampments in public spaces when shelter beds are available and stated there has to be consequences for illegal behavior in the city. He paired enforcement with shelter expansion: as of 2025 the city had 2512 sheltered individuals a 14% decrease in homelessness year-over-year and 1468 housing exits. The ordinance allows enforcement only when adequate shelter is available consistent with scale 3.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/homelessness']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Gloria established the Homelessness Strategies and Solutions Department and funded the Coordinated Street Outreach Program. The city operates Safe Parking and Safe Sleeping programs alongside outreach. 4959 unsheltered individuals were engaged by street-based case managers in 2025 and 1468 exited to housing. He pairs outreach and shelter investment with enforcement.$$,
ARRAY['https://www.sandiego.gov/homelessness', 'https://en.wikipedia.org/wiki/Todd_Gloria']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Gloria passed Housing Action Package 1.0 and signed the Second Housing Action Package into law in January 2024 implementing zoning reforms. His Assembly bill AB-2372 expanded density bonuses near transit with 20% affordable unit requirements and reduced parking caps to 0.1 per affordable unit. These actions reflect building significant affordable units and expanding housing investment.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180AB2372', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180AB1193']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Gloria authored AB-2372 creating floor area ratio bonuses for multifamily housing in transit areas and urban infill zones requiring only 20% affordable units and capping parking at 0.5 spaces per unit. The city planning page confirms San Diego is advancing plans to implement state law encouraging more homes near transit and updating the Land Development Code. These actions reflect broadly upzoning near transit and streamlining approvals with reduced parking requirements.$$,
ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180AB2372', 'https://www.sandiego.gov/planning', 'https://en.wikipedia.org/wiki/Todd_Gloria']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$San Diego Police Department explicitly states SDPD officers do not ask about immigration status do not participate in immigration enforcement task forces and do not assist with immigration arrests per California SB 54. Mayor Gloria featured an executive order on Community Safety and Immigrant Rights as a highlighted policy on his official mayoral page. The SDPD page confirms supervisors are dispatched to ensure SDPD activities remain within state law limits when federal agents are present.$$,
ARRAY['https://www.sandiego.gov/police/immigration', 'https://www.sandiego.gov/mayor', 'https://en.wikipedia.org/wiki/Todd_Gloria']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '44905f3b-e105-4f6c-afc7-5d223813dbac',
$$SDPD policy under Mayor Gloria explicitly prohibits officers from asking about immigration status participating in ICE task forces or assisting with immigration arrests per California SB 54. Officers may respond to emergency situations involving state criminal matters but depart once state law responsibility concludes. This reflects deporting only serious violent criminals while protecting most undocumented immigrants.$$,
ARRAY['https://www.sandiego.gov/police/immigration', 'https://en.wikipedia.org/wiki/Todd_Gloria']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Mayor Gloria signed an executive order on Community Safety and Immigrant Rights prominently featured on sandiego.gov/mayor. SDPD does not cooperate with ICE beyond California SB 54 requirements. Gloria authored AB-2788 prohibiting utilities from sharing customer data with immigration authorities without a court warrant and AB-1285 ensuring immigration status does not disqualify parents from child custody.$$,
ARRAY['https://www.sandiego.gov/police/immigration', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201920200AB2788', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201920200AB1285']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Gloria authored the draft San Diego Climate Action Plan as interim mayor and promoted it during his Assembly campaign per Wikipedia. The sandiego.gov planning page confirms the city launched Our Climate Our Future as a core planning priority implementing the Climate Action Plan. His direct authorship of the CAP and continued implementation as mayor aligns with rapidly transitioning to clean energy and phasing out fossil fuels.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/planning']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Gloria authored the San Diego Climate Action Plan as interim mayor per Wikipedia committing the city to significant fossil fuel reduction. The city planning page confirms Our Climate Our Future and Climate Action Plan implementation as core planning programs. His authorship of the CAP and ongoing implementation as mayor aligns with stopping new permits for fossil fuel use and phasing existing use toward clean energy alternatives.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/planning']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$The San Diego transportation page confirms the city maintains a Better by Bike program and bicycle infrastructure alongside road maintenance. The planning page confirms San Diego is advancing transit-oriented development. Gloria authored AB-2372 explicitly capping parking at 0.5 spaces per unit near transit and 0.1 per affordable unit which is a pro-transit design choice consistent with investing equally in roads and multimodal options including bike lanes.$$,
ARRAY['https://www.sandiego.gov/transportation', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180AB2372', 'https://en.wikipedia.org/wiki/Todd_Gloria']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
$$Gloria is the first openly gay mayor of San Diego per Wikipedia. He served as chairman of the San Diego LGBT Community Center and vice chair of the California Legislative LGBT Caucus. He has consistently supported full federal protections for same-sex marriage and LGBTQ rights in all legislative capacities and his election represented a historic milestone for same-sex marriage equality.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
$$Gloria authored AB-2119 in 2018 as Assembly member requiring foster care agencies to provide gender-affirming healthcare to transgender youth and mandating access to gender-affirming medical care including interventions addressing secondary sex characteristics. He served as vice chair of the California Legislative LGBT Caucus. His pro-transgender legislative record aligns with allowing all transgender athletes to compete on teams matching their gender identity.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180AB2119']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Gloria established the Office of Race and Equity as mayor per Wikipedia. He authored AB-2119 requiring gender-affirming healthcare for transgender foster youth. As Assembly Majority Whip he supported civil rights legislation across multiple sessions. The planning page confirms an equity-focused planning approach. His record reflects strengthening civil rights enforcement and addressing systemic discrimination through institutional mechanisms.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180AB2119']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Gloria proposed 2021 policing reforms including funding for the Commission on Police Practices and restrictions on military-grade weapons per Wikipedia. He revised SDPD consent search policies in August 2021 to make civil rights clearer. His FY2023 budget increased street maintenance by $27.6M while maintaining police and fire funding. He balanced public safety investment without defunding police while adding oversight mechanisms consistent with scale 3.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/police/immigration']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$The San Diego planning page confirms the city is implementing the Climate Action Plan as a core planning program including Our Climate Our Future. Gloria authored the CAP as interim mayor per Wikipedia. The Land Development Code update and transit-oriented development policies impose environmental requirements on new developments. These actions align with requiring significant environmental review and offsetting environmental impacts.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/planning', 'https://www.sandiego.gov/environmental-services']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$The San Diego planning page confirms the city is advancing plans to implement state law encouraging more homes near transit and updating the Land Development Code to reduce barriers. Gloria signed the Housing Action Package and Second Housing Action Package streamlining permitting per Wikipedia. His approach actively reduces regulatory barriers and permits more development consistent with streamlining permitting reducing fees and actively recruiting development.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/planning']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Heather Ferbert (City Attorney)
-- ============================================================

-- ----- Heather Ferbert / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$As Chief Deputy City Attorney, Ferbert explicitly strengthened San Diego's abortion protections following the Supreme Court's Dobbs decision and worked to make women's health clinics safer and more accessible. Her campaign site lists women's rights (including reproductive rights) as a core issue, and Wikipedia confirms she protected abortion access in her prior role. She supports keeping abortion legal and accessible with active enforcement rather than seeking to restrict access.$$,
ARRAY['https://heatherferbert.com/about', 'https://en.wikipedia.org/wiki/Heather_Ferbert']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Ferbert's City Attorney office operates Your Safe Place serving domestic violence, elder abuse, sexual assault, and sex trafficking survivors; her ACE Unit pursues discrimination cases; and she explicitly committed to protecting LGBTQ individuals, racial minorities, and people with disabilities from discrimination on her issues page. She participates in Pride Parades and community civil rights events. Her office pursues civil enforcement against illegal operations targeting vulnerable populations.$$,
ARRAY['https://heatherferbert.com/issues', 'https://www.sandiego.gov/city-attorney/about', 'https://en.wikipedia.org/wiki/Heather_Ferbert']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Ferbert's ACE (Affirmative Civil Enforcement) Unit pursues nuisance enforcement actions including shutting down illegal massage parlors and unauthorized operations in public-facing spaces. Her office enforces the unsafe camping ordinance. Her approach reflects maintaining current sanitation services and enforcing anti-dumping and nuisance laws for businesses rather than significantly expanding sanitation staffing or privatizing services.$$,
ARRAY['https://www.sandiego.gov/city-attorney', 'https://www.sandiego.gov/city-attorney/news']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$As Chief Deputy City Attorney, Ferbert authored San Diego's 2023 Unsafe Camping Ban ordinance — the legislation enabling police to remove homeless encampments when shelter beds are available. Wikipedia confirms: 'she and a city attorney team ... wrote the city's ... unsafe camping ban in 2023.' Her primary homelessness tool is enforcement-based prohibition of public encampments with a shelter availability condition, placing her at value 4.$$,
ARRAY['https://en.wikipedia.org/wiki/Heather_Ferbert', 'https://heatherferbert.com/about', 'https://heatherferbert.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Ferbert's campaign platform calls for implementing CARE Court for mental health treatment alongside enforcement of encampment cleanup laws, paired with shelter assistance. Her issues page describes opening emergency homeless shelters and offering shelter as a companion to enforcement. This balanced enforcement-plus-services approach with behavioral health integration places her at value 3.$$,
ARRAY['https://heatherferbert.com/issues', 'https://heatherferbert.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '669cac97-66a6-4087-b036-936fbe62efb3',
$$As Chief Deputy City Attorney, Ferbert authored San Diego's temporary eviction moratorium in 2022 protecting tenants during the housing crisis, and launched the Housing Protection Unit (HPU) to enforce housing laws and preserve affordable housing. In February 2026 her office defended the city's inclusionary housing ordinance in federal court. She lists housing access as a top career priority and her campaign identifies the HPU as a signature accomplishment.$$,
ARRAY['https://en.wikipedia.org/wiki/Heather_Ferbert', 'https://heatherferbert.com/about', 'https://www.sandiego.gov/city-attorney/news']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '9d45acaf-1ba4-4cb8-95e1-5ed985223b91', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
$$Ferbert established Your Safe Place — a family justice center providing free legal services and advocacy to survivors of domestic violence, elder abuse, sexual assault, and sex trafficking — and launched the Housing Protection Unit offering free enforcement for tenants facing unlawful evictions. These programs provide free civil legal representation and enforcement for people who cannot otherwise access the justice system.$$,
ARRAY['https://www.sandiego.gov/city-attorney/about', 'https://heatherferbert.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
$$Ferbert's prosecution priorities include fentanyl dealers, real estate fraud, worker misclassification, illegal marijuana retailers, and antitrust violations by fire truck manufacturers. She pairs prosecution with CARE Court implementation for mental health and behavioral health integration for homeless defendants. Her approach combines active prosecution with diversion programs for treatment-responsive cases rather than pure incarceration or full decriminalization.$$,
ARRAY['https://www.sandiego.gov/city-attorney/news', 'https://heatherferbert.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'abb99d95-cbb1-4617-8f8b-f220ef6028ca', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
$$The City Attorney's 2025-2026 enforcement actions document selective prosecution: fentanyl dealers, worker misclassification (Campbell's lawsuit Feb 2026), antitrust (fire truck manufacturers Apr 2026), illegal marijuana retailers (Apr 2026), and illegal massage parlors (May 2026). Ferbert also aggressively pursues consumer protection and environmental enforcement through the ACE Unit rather than a pure crime-focused or pure civil-rights-only approach.$$,
ARRAY['https://www.sandiego.gov/city-attorney/news', 'https://heatherferbert.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Ferbert's campaign platform commits to 'pursuing corporate polluters and enforcing sustainable development practices' through the ACE (Affirmative Civil Enforcement) Unit. Her issues page states she will 'Protect the Environment' by pursuing corporate polluters aggressively — an active civil enforcement posture against environmental violations rather than a passive regulatory stance.$$,
ARRAY['https://heatherferbert.com/issues', 'https://www.sandiego.gov/city-attorney/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Ferbert's office combines aggressive prosecution (fentanyl, illegal firearms, ghost guns) with behavioral health diversion via CARE Court and Your Safe Place services for at-risk populations. She expanded the Gun Violence Prevention Unit removing thousands of firearms through red flag law enforcement. Her platform reflects maintaining and strengthening existing law enforcement tools while adding crisis response mechanisms — not defunding, not maximum expansion.$$,
ARRAY['https://heatherferbert.com/public-safety', 'https://www.sandiego.gov/city-attorney/about', 'https://heatherferbert.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Ferbert authored the 2022 temporary eviction moratorium protecting tenants during the housing crisis, and the Housing Protection Unit she launched enforces tenant rights through active civil litigation on behalf of renters facing unlawful evictions and code violations. These actions reflect strengthening existing tenant protections and extending civil enforcement to more landlord-tenant disputes.$$,
ARRAY['https://en.wikipedia.org/wiki/Heather_Ferbert', 'https://heatherferbert.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
$$Ferbert's civil rights enforcement record explicitly includes protection of LGBTQ individuals from discrimination, and she participates in San Diego Pride Parade events per her official city attorney page. Her Your Safe Place center serves LGBTQ+ survivors of domestic violence and sex trafficking. She is a Democrat who has consistently enforced civil rights for LGBTQ individuals, consistent with supporting same-sex marriage nationwide while protecting some religious organizational autonomy.$$,
ARRAY['https://www.sandiego.gov/city-attorney/about', 'https://heatherferbert.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Joe LaCava (District 1)
-- ============================================================

-- ----- Joe LaCava / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$In June 2025 LaCava joined climate and youth activists backing California state pollution legislation targeting oil companies. He stated: 'I stand with our region's climate advocates and youth leaders to demand what's long overdue: polluters paying their fair share.' He chairs the Environment Committee and in April 2026 the Rules Committee moved to affirm commitment to reducing greenhouse gases on Earth Day under his leadership.$$,
ARRAY['https://timesofsandiego.com/politics/2025/06/05/climate-youth-activists-back-make-polluters-play-legislation/', 'https://www.sandiego.gov/citycouncil/cd1']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$LaCava publicly backed state legislation requiring polluters to fund climate damage repair stating 'If you profit from causing environmental damage you should be responsible for the cost of repair.' He chairs the Environment Committee and his April 2026 Earth Day GHG reduction commitment reflects active environmental stewardship.$$,
ARRAY['https://timesofsandiego.com/politics/2025/06/05/climate-youth-activists-back-make-polluters-play-legislation/', 'https://www.sandiego.gov/citycouncil/cd1']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$LaCava joined climate activists in June 2025 backing California legislation to hold major oil companies financially accountable for environmental damage. His statement — 'If you profit from causing environmental damage you should be responsible for the cost of repair' — indicates support for stopping new permits and imposing costs on fossil fuel producers rather than expanding extraction.$$,
ARRAY['https://timesofsandiego.com/politics/2025/06/05/climate-youth-activists-back-make-polluters-play-legislation/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', '669cac97-66a6-4087-b036-936fbe62efb3',
$$LaCava voted to approve the University Community Plan Update stating it represents 'our City's continuing efforts to deliver housing as we reimagine our neighborhoods.' However in July 2024 he opposed city loans for the Rose Creek affordable housing project — stating 'Council may not have the authority to interfere with the permitting of this Prop.-D busting project but we are under no obligation to use taxpayer dollars to support it' — due to it exceeding the coastal 30-foot height limit. Mixed record: supports density plans within existing zoning but resists exceptions to voter-approved height limits.$$,
ARRAY['https://timesofsandiego.com/politics/2024/07/31/city-council-oks-new-plans-guiding-housing-job-growth-in-hillcrest-and-university-city/', 'https://timesofsandiego.com/politics/2024/07/29/councilman-lacava-opposes-loans-for-rose-creek-affordable-housing-over-height-limit/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$LaCava supported the July 2024 Hillcrest and University City housing and job growth plans stating they represent 'our City's continuing efforts to deliver housing as we reimagine our neighborhoods to meet the needs of all San Diegans.' His website emphasizes a 'sensible housing policy' priority and 'back-to-basics philosophy' of investing proactively in infrastructure while respecting existing community plans.$$,
ARRAY['https://timesofsandiego.com/politics/2024/07/31/city-council-oks-new-plans-guiding-housing-job-growth-in-hillcrest-and-university-city/', 'https://joelacava.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$LaCava advanced the SeaWorld San Diego drone show proposal in April 2026 as 'part of ongoing community collaboration' reflecting targeted economic development with community input. His 'back-to-basics philosophy' focuses on services within finite revenue rather than maximum incentives or no incentives.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd1']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$In November 2025 LaCava stated government is 'very limited in terms of what we can do to generate new revenues' and must 'navigate with what revenues the city has at its disposal.' He chairs the Rules Committee which voted 3-2 in January 2026 to kill a vacation rental tax proposal. His 'finite revenue sources' philosophy consistently opposes new taxes.$$,
ARRAY['https://timesofsandiego.com/politics/2025/11/18/council-president-joe-lacava-discusses-city-fees-budget-deficits/', 'https://timesofsandiego.com/politics/2026/01/28/committee-kills-short-term-vacation-rental-tax/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$LaCava's campaign website lists 'supporting our police firefighters and lifeguards' as a top priority and in November 2025 he stated that public safety is 'our number one job.' He initiated recruitment for a Commission on Police Practices executive director in July 2025 supporting the voter-mandated independent oversight board alongside traditional law enforcement funding.$$,
ARRAY['https://joelacava.com', 'https://timesofsandiego.com/politics/2025/11/18/council-president-joe-lacava-discusses-city-fees-budget-deficits/', 'https://timesofsandiego.com/politics/2025/07/14/san-diego-seeks-executive-director-commissioners-police-oversight-board/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$In January 2025 LaCava stated: 'We cannot do this work alone. The County the other 17 cities the state and our federal government must step up to share the work of homelessness behavioral health housing and more.' He appeared with Mayor Gloria at a June 2023 press event supporting the ordinance limiting homeless camps requiring shelter availability before enforcement — consistent with allowing enforcement only when adequate shelter beds are available.$$,
ARRAY['https://timesofsandiego.com/politics/2025/01/15/gloria-opts-for-humble-surroundings-for-state-of-the-city-address-in-midst-of-budget-crisis/', 'https://timesofsandiego.com/politics/2023/06/07/mayor-gloria-urges-council-to-pass-ordinance-limiting-homeless-camps/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$LaCava's District 1 (La Jolla/Pacific Beach coastal) shows mixed transportation priorities: he delayed the community parking district elimination plan in October 2025 to gather more information suggesting caution on removing auto-oriented infrastructure while also co-signing a letter demanding I-5 accountability. His website cites street paving and traffic safety improvements as achievements suggesting balanced investment in roads alongside multimodal review.$$,
ARRAY['https://timesofsandiego.com/politics/2025/10/08/coastal-residents-oppose-city-plan-community-parking-districts/', 'https://timesofsandiego.com/politics/2025/12/17/lawmakers-letter-series-i-5-shutdowns/', 'https://joelacava.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jennifer Campbell (District 2)
-- ============================================================

-- ----- Jennifer Campbell / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Campbell voted 7-2 in July 2024 to postpone the mega-shelter lease vote citing concerns that the City Attorney's Office did not get to do a line-by-line lease analysis before the vote; she did not dissent from the camping ban and her newsletter identifies homelessness as a top-three budget priority focused on solutions rather than a shelter-first or prevention-first framing. Her votes align with allowing enforcement when adequate shelter beds are available but requiring city legal due diligence.$$,
ARRAY['https://voiceofsandiego.org/2024/07/23/city-council-punts-on-mega-shelter-vote', 'https://app.indigov.com/pub/outreach/19e20f69-1be3-4410-875b-f233edabe55b']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Campbell's April 2026 newsletter lists homelessness as one of the top three District 2 budget priorities alongside neighborhood infrastructure and public safety, supporting a balanced approach of services and enforcement. Her 2024 mega-shelter vote reflected concern for proper legal and financial safeguards rather than ideological opposition to shelter investment, aligning with investing in outreach and services while enforcing reasonable public space rules.$$,
ARRAY['https://app.indigov.com/pub/outreach/19e20f69-1be3-4410-875b-f233edabe55b', 'https://voiceofsandiego.org/2024/07/23/city-council-punts-on-mega-shelter-vote']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Campbell reversed her campaign promise to protect San Diego's 30-foot coastal height restriction by co-sponsoring a memo supporting a ballot measure allowing developers to exceed the limit in the Midway neighborhood. This pro-development position triggered a 2021 recall campaign. She also supported AB 2525 to facilitate Mission Bay commercial development. Her record reflects broad support for allowing multifamily and mixed-use development in key areas.$$,
ARRAY['https://en.wikipedia.org/wiki/Jennifer_Campbell_(politician)', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB2525', 'https://www.sandiego.gov/citycouncil/cd2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Campbell co-sponsored the reversal of San Diego's 30-foot coastal height limit in the Midway neighborhood and supported AB 2525 to enable commercial development at Mission Bay without surplus land housing constraints. These actions drew a 2021 recall campaign from constituents who felt she prioritized developers over community character. Her record supports streamlined permitting and active recruitment of development in her coastal district.$$,
ARRAY['https://en.wikipedia.org/wiki/Jennifer_Campbell_(politician)', 'https://www.sandiego.gov/citycouncil/cd2', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB2525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Campbell serves as Vice Chair of the San Diego City Council Environment Committee and holds board seats on the San Diego Air Pollution Control District and SANDAG Shoreline Preservation Working Group plus the San Diego River Conservancy. These appointments reflect strong institutional commitment to environmental oversight including air quality regulation and coastal and watershed protection consistent with protecting parks and requiring developers to offset environmental impact.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd2', 'https://www.sandiego.gov/sustainability/climate-action-plan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Campbell serves as Vice Chair of the Environment Committee and sits on the APCD board placing her within San Diego's 2022 Climate Action Plan framework of net zero by 2035. However her pro-development votes on the height limit and AB 2525 indicate she balances climate goals with economic growth rather than taking an aggressive decarbonization stance. She has not called for a climate emergency declaration or fossil fuel bans.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd2', 'https://www.sandiego.gov/sustainability/climate-action-plan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Campbell's APCD board membership signals awareness of air quality and emissions issues in San Diego. As a city council member she has not taken explicit positions on fossil fuel extraction permits beyond her role overseeing air quality via the APCD. Her pro-development and balanced growth record suggests she maintains current production levels with existing environmental oversight rather than expanding or banning fossil fuel activities.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Campbell sits on the Economic Development and Intergovernmental Relations Committee and supported AB 2525 to enable targeted commercial development at Mission Bay. Her record favors strategic targeted economic development tied to specific district assets rather than blanket corporate subsidies consistent with targeted incentives with community benefit requirements and job quality standards.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd2', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB2525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Campbell serves as the Alternate Representative to the MTS Board of Directors reflecting engagement with regional transit. She represents a predominantly car-dependent coastal district including Clairemont and Mission Beach and has not taken positions strongly favoring transit-only or car-only investment. Her MTS alternate role alongside her coastal district profile suggests a balanced road-and-multimodal approach.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Campbell chairs the Community and Neighborhood Services Committee which oversees sanitation and neighborhood cleanliness programs. Her April 2026 newsletter promotes constituent services including the Get It Done App for non-emergency concerns. No evidence of a strong position toward significant sanitation expansion or full privatization; her committee chair role reflects a service maintenance and anti-dumping enforcement posture.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd2', 'https://app.indigov.com/pub/outreach/19e20f69-1be3-4410-875b-f233edabe55b']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Campbell sits on the Public Safety Committee and her April 2026 newsletter highlights San Diego's 6.3% crime reduction in 2025 crediting smart technology for improved prevention and crime-solving. She does not express positions on reallocating police budgets to social services but also does not call for significant police expansion. Her committee role and messaging reflect maintenance of current police staffing with targeted technology investments.$$,
ARRAY['https://app.indigov.com/pub/outreach/19e20f69-1be3-4410-875b-f233edabe55b', 'https://www.sandiego.gov/citycouncil/cd2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Campbell was characterized as having a too-lenient attitude toward short-term vacation rentals — a criticism central to the 2021 recall campaign against her. Her pro-development and market-oriented posture in a high-tourism coastal district reflects permitting market rents broadly with limited tenant protection focus. She has not sponsored rent control or stabilization measures during her tenure.$$,
ARRAY['https://en.wikipedia.org/wiki/Jennifer_Campbell_(politician)', 'https://www.sandiego.gov/citycouncil/cd2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Campbell supported AB 2525 which requires San Diego to deposit either 10% or 30% of Mission Bay land disposition value into an affordable housing fund reflecting a moderate housing stance: market development is allowed but with affordability mitigation. Her pro-development record on the height limit flip is partially offset by required housing contributions placing her in a middle position between public investment advocacy and full market-rate development.$$,
ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB2525', 'https://en.wikipedia.org/wiki/Jennifer_Campbell_(politician)', 'https://www.sandiego.gov/citycouncil/cd2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Campbell was not a co-sponsor of the January 2026 resolution by von Wilpert, Elo-Rivera, and Moreno opposing ICE enforcement tactics. She has not made public statements calling for full ICE cooperation or explicitly opposing it. Her moderate Democratic profile and absence from the anti-ICE resolution sponsorship suggests she follows federal law as required without using city resources for proactive immigration enforcement in either direction.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Campbell / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c6d7ea83-d6ee-4d08-a183-effd36f6a2cc', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Campbell's April 2026 newsletter actively celebrates LGBTQ+ leadership through the Victory Fund and Diversionary Theatre's 40th anniversary promotes HIV prevention fundraising through Dining Out for Life and she issued a statement condemning a hate crime shooting targeting an Islamic center in Clairemont as alarming and unacceptable. These actions reflect consistent work to address discrimination and strengthen civil rights in her district.$$,
ARRAY['https://app.indigov.com/pub/outreach/19e20f69-1be3-4410-875b-f233edabe55b', 'https://www.sandiego.gov/citycouncil/cd2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Stephen Whitburn (District 3)
-- ============================================================

-- ----- Stephen Whitburn / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Whitburn introduced the 2023 encampment ban ordinance allowing police to remove homeless encampments from public property when city shelter beds are available. The measure passed 5-4 and became a model for statewide California legislation. Introducing enforcement-first ordinance with shelter condition places him at value 4 — prohibit encampments with graduated warnings while requiring shelter options.$$,
ARRAY['https://en.wikipedia.org/wiki/Stephen_Whitburn', 'https://www.sandiego.gov/citycouncil/cd3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Whitburn / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Whitburn's 2023 encampment ordinance conditions removals on shelter availability — enforcement is allowed only when adequate beds exist. He pairs enforcement with a shelter-bed requirement rather than pure criminalization or pure housing-first. This conditional enforcement with citation-to-services diversion places him at value 3.$$,
ARRAY['https://en.wikipedia.org/wiki/Stephen_Whitburn', 'https://www.sandiego.gov/citycouncil/cd3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Whitburn / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Whitburn supports income-restricted housing and streamlined regulations to lower housing development costs. He received endorsements from YIMBY Democrats of San Diego in his 2024 re-election campaign. This reflects investing significantly in affordable units and expanding programs while remaining within the current system.$$,
ARRAY['https://en.wikipedia.org/wiki/Stephen_Whitburn', 'https://www.sandiego.gov/citycouncil/cd3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Whitburn / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Whitburn earned the YIMBY Democrats of San Diego endorsement in 2024 a group that advocates for upzoning broadly to allow multifamily by right and streamlined approvals with reduced parking requirements. His voting record and stated housing support align with upzoning multifamily and reducing parking requirements broadly.$$,
ARRAY['https://en.wikipedia.org/wiki/Stephen_Whitburn', 'https://www.sandiego.gov/citycouncil/cd3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Whitburn / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Whitburn chairs both the San Diego Metropolitan Transit System Board of Directors (re-elected 2025) and the Active Transportation and Infrastructure Committee. He opposed the Balboa Park paid parking program in 2025 voting against it and calling for repeal then negotiating a 2026 settlement that rolled it back. These roles and votes show prioritizing pedestrian infrastructure cycling networks and public transit over car-centric investment.$$,
ARRAY['https://en.wikipedia.org/wiki/Stephen_Whitburn', 'https://www.sandiego.gov/citycouncil/cd3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Whitburn / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
$$Whitburn is a former nonprofit director supporting LGBTQ equality (identified in his official bio on voiceofsandiego.org as former director of an organization supporting LGBTQ rights) representing Hillcrest the center of San Diego's LGBTQ community. He is a Democrat in a district where LGBTQ rights are a core constituency concern. No evidence of any restriction on same-sex marriage.$$,
ARRAY['https://en.wikipedia.org/wiki/Stephen_Whitburn', 'https://voiceofsandiego.org/people/stephen-whitburn/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Whitburn / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Whitburn secured unanimous San Diego City Council support in July 2025 for AB 1127 legislation targeting untraceable DIY machine guns. This reflects a gun violence prevention stance while maintaining current police staffing — not a defund position and not a maximum expansion position.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Whitburn / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Whitburn holds YIMBY housing views favoring density and streamlined approvals but opposed the Balboa Park paid parking expansion in 2025 and negotiated its rollback in 2026 showing concern for existing community character and services. This balance — pro-density housing but protective of established community resources — places him at value 3.$$,
ARRAY['https://en.wikipedia.org/wiki/Stephen_Whitburn', 'https://www.sandiego.gov/citycouncil/cd3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Whitburn / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Whitburn negotiated a 2026 settlement that resulted in reduced trash collection fees alongside the rollback of Balboa Park paid parking. His approach reflects maintaining sanitation services while opposing fee increases on residents and enforcing anti-dumping for businesses — consistent with value 3.$$,
ARRAY['https://en.wikipedia.org/wiki/Stephen_Whitburn', 'https://www.sandiego.gov/citycouncil/cd3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Henry L. Foster III (District 4)
-- ============================================================

-- ----- Henry L. Foster III / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Foster's campaign platform explicitly includes road repairs, community cleanups, and graffiti abatement as core infrastructure priorities. This reflects a maintain-current-services approach with community cleanup enforcement rather than major sanitation expansion or privatization.$$,
ARRAY['https://henryfoster4sd.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Before serving on council Foster directed over $5 billion in city contracts through San Diego's Equal Opportunity Contracting Program, a concrete anti-discrimination institutional mechanism. On council he pressed for Community Equity Funds to assist flood-affected residents in his majority-minority district, reflecting active work to address systemic discrimination and direct resources to underserved communities.$$,
ARRAY['https://henryfoster4sd.com/issues', 'https://voiceofsandiego.org/2024/06/09/city-council-wants-equity-money-restored-in-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Foster serves as Vice Chair of the Active Transportation & Infrastructure Committee and as MTS Board alternate, actively promoting transit and non-motorized transportation that reduces emissions. He supported restoring funding for a study examining whether San Diego could take over its electric grid from SDG&E, aligning with a transition-to-renewable-energy posture and phasing down fossil fuel utility dependence.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd4', 'https://voiceofsandiego.org/2024/06/09/city-council-wants-equity-money-restored-in-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Foster chairs the Budget & Government Efficiency Committee and sits on the Economic Development & Intergovernmental Relations Committee. His platform calls for supporting local small businesses and community-based organizations through workforce training, apprenticeships, and local hiring pipelines — targeted incentives with workforce-quality requirements rather than maximum subsidies for any employer.$$,
ARRAY['https://henryfoster4sd.com/issues', 'https://www.sandiego.gov/citycouncil/cd4']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Foster supported restoring funding for a municipal electric grid takeover study, which would accelerate San Diego's transition away from fossil fuel-dependent SDG&E operations. His Active Transportation Committee work promotes reducing reliance on fossil-fuel vehicles. His record aligns with stopping new fossil fuel expansion through the city's energy procurement and transportation policy.$$,
ARRAY['https://voiceofsandiego.org/2024/06/09/city-council-wants-equity-money-restored-in-budget/', 'https://www.sandiego.gov/citycouncil/cd4']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Foster has secured over $100 million for parks, streets, and youth programs in District 4, reflecting proactive infrastructure investment alongside development. His platform calls for sustainable community-driven development with equity considerations, suggesting he supports responsible expansion with infrastructure investment ahead of growth rather than either imposing growth limits or removing all regulatory barriers.$$,
ARRAY['https://henryfoster4sd.com/issues', 'https://henryfoster4sd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Foster's platform calls for cross-government solutions to homelessness including permanent supportive housing and wraparound services. No direct evidence of his specific vote on the 2023 camping ban was found in fetched sources. His platform language emphasizes solutions and services over primary enforcement, and he represents a majority-minority district with high rates of poverty and housing insecurity.$$,
ARRAY['https://henryfoster4sd.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Foster's campaign platform explicitly calls for permanent supportive housing and wraparound services as the primary homelessness response strategy, a housing-first-adjacent approach. His platform emphasizes cross-governmental coordination and services as the primary tool for addressing homelessness rather than enforcement.$$,
ARRAY['https://henryfoster4sd.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Foster's platform explicitly prioritizes developing long-term sustainable affordable housing for all San Diegans and investing in assistance programs for first-time homebuyers and rent-burdened residents. He represents a high-renter, lower-income district and has secured over $100 million in neighborhood investment. His housing stance reflects significant affordable housing investment and rental assistance programs.$$,
ARRAY['https://henryfoster4sd.com/issues', 'https://henryfoster4sd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$As Vice Chair of Active Transportation & Infrastructure and MTS Board alternate, Foster actively promotes transit and non-motorized transportation modes that reduce environmental impact. District 4 includes environmental justice communities where pollution impacts are disproportionate, and Foster advocated for Community Equity Funds tied to climate justice for underserved neighborhoods.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd4', 'https://voiceofsandiego.org/2024/06/09/city-council-wants-equity-money-restored-in-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Foster is a Democrat endorsed by the SD County Democratic Party, AFL-CIO, SEIU, AFSCME, and other major progressive unions, representing a diverse majority-minority district with a significant immigrant population. San Diego's sanctuary-city posture under SB 54 limits SDPD cooperation with ICE, and no evidence was found that Foster broke from this council consensus. His coalition and district demographics align with complying only with court-ordered detainers while protecting immigrant communities.$$,
ARRAY['https://henryfoster4sd.com/endorsements', 'https://www.sandiego.gov/citycouncil/cd4']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Foster's platform calls for improving public safety through environmental design (streetlight repair, graffiti abatement), providing youth with creative outlets and mentorship, improving community relations with first responders, and job placement programs. This is a balanced approach adding youth and community programs alongside existing police staffing rather than defunding or major police budget expansion.$$,
ARRAY['https://henryfoster4sd.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Foster's platform specifically calls for investing in assistance programs for rent-burdened residents, and he is endorsed by SEIU Local 221 and AFL-CIO — unions that strongly support tenant protections. He represents a high-renter, lower-income district with significant affordability challenges. His platform and endorsement pattern align with strengthening existing rent stabilization and extending renter assistance.$$,
ARRAY['https://henryfoster4sd.com/issues', 'https://henryfoster4sd.com/endorsements']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Foster's platform emphasizes affordable housing development without explicitly calling for broad upzoning or opposing density increases. He represents a majority-minority district with high housing need and focuses on community-driven sustainable development, suggesting a balanced approach allowing some density increases with community input rather than citywide upzoning or strict neighborhood protection.$$,
ARRAY['https://henryfoster4sd.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry L. Foster III / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Foster serves as Vice Chair of the Active Transportation & Infrastructure Committee and as the Alternate Representative to the MTS Board of Directors. This dual role in active transportation planning and regional transit governance reflects strong investment in multimodal and transit-oriented transportation priorities, consistent with investing equally in roads and multimodal options.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd4']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Marni von Wilpert (District 5)
-- ============================================================

-- ----- Marni von Wilpert / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Von Wilpert co-authored San Diego's Reproductive Freedom Resolution following the Supreme Court's Dobbs decision and her campaign commits to codify Roe into federal law and oppose nationwide abortion bans. Her issues page states she 'passed a law in San Diego to protect abortion rights' and she explicitly opposes reversing federal abortion protections. This reflects keeping abortion legal and accessible through the second trimester with rare exceptions.$$,
ARRAY['https://marnivonwilpert.com/issues/', 'https://marnivonwilpert.com/about/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '666bf03d-81fc-4138-ab15-69ae734c9023',
$$Von Wilpert's campaign website states she advocates for 'regulatory clarity for the safe development of emerging technologies' — language consistent with requiring basic safety testing before AI deployment while preventing a full regulatory ban. She cosponsored the CLARITY Act and GENIUS Act at the federal level, both light-oversight frameworks, suggesting a middle-ground safety testing approach rather than heavy regulation or hands-off self-regulation.$$,
ARRAY['https://marnivonwilpert.com/about/', 'https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '92730f69-ae57-401c-8ad1-2d07834a895d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '92730f69-ae57-401c-8ad1-2d07834a895d',
$$Von Wilpert's issues page explicitly opposes dark money and Citizens United and supports banning members of Congress from trading stocks. The 'For the People Act' she supports would strictly limit corporate donations and dark money groups and require full disclosure of political donations.$$,
ARRAY['https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Von Wilpert created the first police officer childcare center nationally as part of her public safety work per her about page, demonstrating concrete action expanding childcare access for working families. Her labor attorney background and CTA endorsement align with expanding subsidies and provider support to make childcare affordable for working and middle-income families.$$,
ARRAY['https://marnivonwilpert.com/about/', 'https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Von Wilpert has supported continued discussions about reforming San Diego's Peoples Ordinance regarding trash collection and her council record focuses on anti-dumping enforcement and neighborhood cleanliness. No evidence of advocating for significant sanitation expansion or privatization; her posture reflects maintaining current services while enforcing anti-dumping laws.$$,
ARRAY['https://voiceofsandiego.org/2021/10/wow-trash-talk-picked-up-huh/', 'https://www.sandiego.gov/citycouncil/cd5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Von Wilpert founded a legal clinic with the Mississippi Center for Justice earlier in her career and was endorsed by the LGBTQ+ Victory Fund. She is openly LGBTQ+ and authored San Diego's Reproductive Freedom Resolution. Her issues page explicitly commits to LGBTQ+ equality via the Equality Act and opposing gender-affirming care bans, reflecting active civil rights enforcement and addressing systemic discrimination.$$,
ARRAY['https://marnivonwilpert.com/issues/', 'https://en.wikipedia.org/wiki/Marni_von_Wilpert']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Von Wilpert's campaign commits to reversing Trump-era environmental rollbacks and transitioning to 'cleaner, more affordable energy.' She opposes offshore oil drilling on the California coast and supports Styrofoam bans and EV charging expansion in San Diego. Her about page confirms she championed zero-emissions initiatives as a city council member.$$,
ARRAY['https://marnivonwilpert.com/issues/', 'https://marnivonwilpert.com/about/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '44905f3b-e105-4f6c-afc7-5d223813dbac',
$$Von Wilpert co-authored the February 2026 San Diego City Council resolution condemning ICE enforcement tactics and authorizing legal action against the Trump administration. She stated: 'These aren't just words or concepts... They are the guaranteed rights of all people in this country, regardless of immigration status.' She supports Dreamers and legal pathways, reflecting a posture of deporting only serious violent criminals while protecting broader immigrant communities.$$,
ARRAY['https://timesofsandiego.com/politics/2026/02/02/sd-councilmembers-pass-resolution-condemning-excessive-ice-tactics/', 'https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Von Wilpert serves on the SANDAG committees and the Airport Authority Board as Infrastructure Committee Chair and led the $3.8 billion Terminal 1 redevelopment project. Her campaign platform emphasizes teacher housing grants and targeted investments rather than maximum corporate incentives or zero incentives, reflecting targeted economic development with community benefit considerations.$$,
ARRAY['https://marnivonwilpert.com/about/', 'https://www.sandiego.gov/citycouncil/cd5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Von Wilpert explicitly opposes offshore oil drilling on the California coast and prosecuted polluters as Deputy City Attorney. Her campaign commits to reversing Trump environmental rollbacks and transitioning to cleaner energy, consistent with stopping new fossil fuel permits and phasing down existing extraction.$$,
ARRAY['https://marnivonwilpert.com/issues/', 'https://marnivonwilpert.com/about/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Von Wilpert serves on SANDAG committees overseeing regional growth planning and the Airport Authority Board overseeing major infrastructure expansion. Her housing work focuses on cutting red tape for affordable housing near employment centers. Her profile reflects a proactive infrastructure investment approach — investing in infrastructure to support responsible expansion — consistent with value 3.$$,
ARRAY['https://marnivonwilpert.com/about/', 'https://www.sandiego.gov/citycouncil/cd5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Von Wilpert's issues page supports protecting and expanding the ACA, restoring ACA tax credits, including a public option alongside private insurance, expanding Medicare's power to negotiate prescription drug prices, and expanding coverage to dental, hearing, vision, and mental healthcare. This is a public option plus regulated private insurance stance, consistent with value 2.$$,
ARRAY['https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Von Wilpert proposed an amendment to the 2023 Unsafe Camping Ordinance delaying its effect until 30 days after the first safe sleeping lot opened on 20th and B Streets, to allow non-law enforcement social workers to be the first contact with homeless people. This enforcement-with-services-condition approach — paired with her Conservatorship and Treatment Unit initiative — reflects allowing enforcement when adequate shelter is available while requiring service-first contact.$$,
ARRAY['https://timesofsandiego.com/politics/2023/06/27/unsafe-camping-ordinance-banning-homeless-in-tents-to-be-signed-into-law-this-week/', 'https://www.sandiego.gov/citycouncil/cd5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Von Wilpert's primary homelessness initiative is the Conservatorship and Treatment Unit — a service-and-enforcement pairing that leads with social worker outreach before law enforcement contact and invests in shelter capacity and behavioral health treatment. Her 2023 camping ban amendment required a functioning safe sleeping lot as a prerequisite to enforcement, consistent with investing in shelter and outreach while enforcing reasonable public space rules.$$,
ARRAY['https://timesofsandiego.com/politics/2023/06/27/unsafe-camping-ordinance-banning-homeless-in-tents-to-be-signed-into-law-this-week/', 'https://www.sandiego.gov/citycouncil/cd5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Von Wilpert launched first-of-its-kind affordable housing downpayment grants for teachers and has worked to cut red tape to build more affordable housing. She voted unanimously with the council on the Affordable Housing Preservation Ordinance in February 2025. Her record reflects building significant affordable units and expanding programs and assistance — consistent with value 2.$$,
ARRAY['https://marnivonwilpert.com/about/', 'https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Von Wilpert's campaign supports 'meaningful reform that keeps our borders secure and provides legal pathways to citizenship' for long-term residents and Dreamers and opposes what she calls 'un-American, unconstitutional attacks.' She co-authored the February 2026 ICE resolution and quoted: 'They are the guaranteed rights of all people in this country, regardless of immigration status.' This reflects significantly expanding legal pathways with immigrant protections.$$,
ARRAY['https://marnivonwilpert.com/issues/', 'https://timesofsandiego.com/politics/2026/02/02/sd-councilmembers-pass-resolution-condemning-excessive-ice-tactics/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
$$Von Wilpert's background as a labor attorney and champion of CARE Court and conservatorship diversion reflects a preference for treatment alternatives and pretrial diversion over building new jail capacity. Her homelessness Conservatorship and Treatment Unit channels people into treatment rather than incarceration, consistent with reducing the incarcerated population through diversion and treatment alternatives.$$,
ARRAY['https://marnivonwilpert.com/about/', 'https://www.sandiego.gov/citycouncil/cd5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Von Wilpert serves on the San Dieguito River Valley Regional Open Space JPA and the Los Penasquitos Canyon Preserve — two direct institutional roles in watershed protection and open space preservation. Her campaign opposes offshore oil drilling and she authored the Styrofoam ban. These roles and actions reflect protecting existing parks and tree canopy strictly and requiring environmental review before development.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd5', 'https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Von Wilpert co-authored the February 2026 San Diego City Council resolution unanimously condemning ICE enforcement tactics and authorizing the City Attorney to pursue legal action. She stated: 'ICE's actions in Minneapolis and across the country undermine our shared American values of life, liberty, and due process. Conducting operations that terrorize communities based on how someone looks or sounds is both inhumane and unlawful.' This reflects complying only with court-ordered detainers while protecting undocumented crime victims and witnesses.$$,
ARRAY['https://timesofsandiego.com/politics/2026/02/02/sd-councilmembers-pass-resolution-condemning-excessive-ice-tactics/', 'https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
$$Von Wilpert's issues page calls for expanding Medicare's power to negotiate prescription drug prices, capping out-of-pocket costs, and expanding coverage to dental, hearing, vision, and mental healthcare — incremental expansions of the current program rather than Medicare for All or privatization. This reflects lowering effective Medicare costs and modestly expanding coverage.$$,
ARRAY['https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Von Wilpert chairs the Public Safety Committee and has fully funded the police department, renovated the Northeastern Division Station, and created the first police officer childcare center nationally. She also champions the Conservatorship and Treatment Unit pairing enforcement with behavioral health diversion. Her record reflects maintaining current police staffing while adding crisis response teams — not defunding, not maximum expansion.$$,
ARRAY['https://marnivonwilpert.com/about/', 'https://www.sandiego.gov/citycouncil/cd5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '48cc9585-ec22-4f53-8d42-6839828dd36f',
$$Von Wilpert supports the 'For the People Act' per her issues page, which would establish independent redistricting commissions with equal representation, removing partisan legislative control over redistricting. This reflects supporting independent redistricting commissions with equal representation from both major parties.$$,
ARRAY['https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Von Wilpert has streamlined housing permits and cut red tape to build more affordable housing near employment centers. Her campaign platform and city record emphasize reducing regulatory barriers for affordable housing development. This reflects an upzone-and-streamline posture — allowing multifamily by right and reducing approvals barriers — consistent with value 4.$$,
ARRAY['https://marnivonwilpert.com/about/', 'https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
$$Von Wilpert is openly LGBTQ+, publicly shared her coming-out story on National Coming Out Day, and was endorsed by the LGBTQ+ Victory Fund. She explicitly supports the Equality Act — federal legislation requiring full federal LGBTQ+ protections — on her issues page. This reflects requiring all states to recognize same-sex marriages with full federal benefits and protections.$$,
ARRAY['https://marnivonwilpert.com/issues/', 'https://en.wikipedia.org/wiki/Marni_von_Wilpert']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '00b95a6a-75db-4521-b523-3326bba938de',
$$Von Wilpert is endorsed by the California Teachers Association — one of the most prominent anti-voucher organizations in the country — and her labor attorney background reflects strong support for public institutions. Her campaign platform emphasizes cutting red tape for public affordable housing and investing in public institutions rather than diverting funds to private alternatives.$$,
ARRAY['https://en.wikipedia.org/wiki/Marni_von_Wilpert', 'https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '87d20824-a6e9-407b-983c-65440084a0ab',
$$Von Wilpert's issues page explicitly states she will 'oppose any cuts or privatization, and ensure the program is strengthened for current and future retirees.' This reflects modestly increasing Social Security benefits while opposing cuts — consistent with value 2.$$,
ARRAY['https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '683c8084-2281-4920-a07c-18439b2dd413', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '683c8084-2281-4920-a07c-18439b2dd413',
$$Von Wilpert's issues page explicitly calls for repealing Trump tariffs, reflecting a strong preference for reducing most tariffs and pursuing more open trade rather than protective tariff regimes.$$,
ARRAY['https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Von Wilpert is endorsed by the California Federation of Labor Unions (AFL-CIO) and California Teachers Association and has a background as an NLRB labor attorney. Her campaign platform supports workers' rights, wage increases, and the PRO Act. Her positions on housing grants for teachers and worker protections reflect a modestly progressive tax posture consistent with increasing taxes on high earners while maintaining rates for middle-class families.$$,
ARRAY['https://marnivonwilpert.com/issues/', 'https://en.wikipedia.org/wiki/Marni_von_Wilpert']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
$$Von Wilpert is openly LGBTQ+ and endorsed by the LGBTQ+ Victory Fund. Her issues page explicitly opposes gender-affirming care bans and 'book bans targeting LGBTQ+ voices.' She supports the Equality Act which prohibits discrimination based on gender identity in all public accommodations including sports. This reflects allowing transgender athletes to compete on teams matching their gender identity after completing basic transition documentation.$$,
ARRAY['https://marnivonwilpert.com/issues/', 'https://en.wikipedia.org/wiki/Marni_von_Wilpert']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Von Wilpert serves on the Active Transportation and Infrastructure Committee and is the alternate on San Diego Community Power and multiple SANDAG committees. Her role on the Active Transportation committee reflects active investment in pedestrian infrastructure and cycling networks alongside public transit — consistent with investing equally in roads and multimodal options and requiring bike lanes and sidewalks on new road projects.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', '24e9212c-b011-422a-865c-093e35050901',
$$Von Wilpert's issues page explicitly supports Ukraine aid and NATO, stating she supports helping Ukraine defend itself. She is running for Congress on a platform that includes foreign policy support for Ukraine and commitment to the transatlantic alliance.$$,
ARRAY['https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marni von Wilpert / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Von Wilpert's issues page explicitly supports the John Lewis Voting Rights Act and the 'For the People Act,' which would expand early voting and make mail-in voting available to all voters without requiring an excuse, alongside automatic voter registration. This reflects expanding early voting and mail-in voting access broadly.$$,
ARRAY['https://marnivonwilpert.com/issues/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kent Lee (District 6)
-- ============================================================

-- ----- Kent Lee / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Lee voted NO on the June 2023 unsafe camping ordinance (5-4 vote), joining Council President Elo-Rivera, Montgomery Steppe, and Moreno in opposition to the ban. He voted against both the June 13 and June 27 2023 votes, opposing enforcement-first approaches to homelessness.$$,
ARRAY['https://timesofsandiego.com/politics/2023/06/27/unsafe-camping-ordinance-banning-homeless-in-tents-to-be-signed-into-law-this-week/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Lee / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Lee voted against the 2023 unsafe camping ordinance both times it came to a vote (June 13 and June 27 2023), siding with the four members who opposed criminalization over services. His stated top three priorities are housing attainability and addressing homelessness through expanded options rather than enforcement.$$,
ARRAY['https://timesofsandiego.com/politics/2023/06/27/unsafe-camping-ordinance-banning-homeless-in-tents-to-be-signed-into-law-this-week/', 'https://en.wikipedia.org/wiki/Kent_Lee_(politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Lee / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Lee identified housing attainability as one of his top three stated priorities. He serves on the North County Transit District board consistent with transit-oriented housing development. His district office news page confirms participation in a joint FY2027 budget priority memorandum with Districts 4 8 and 9 focused on housing and infrastructure investment.$$,
ARRAY['https://en.wikipedia.org/wiki/Kent_Lee_(politician)', 'https://sandiego.gov/citycouncil/cd6/news']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Lee / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Lee serves as a non-voting board member of the North County Transit District (NCTD) managing regional rail and bus services and lists infrastructure and transit as one of his three core priorities. This reflects an emphasis on public transit investment over car-only infrastructure.$$,
ARRAY['https://en.wikipedia.org/wiki/Kent_Lee_(politician)', 'https://sandiego.gov/citycouncil/cd6']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Lee / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Lee submitted an RFI memo on December 11 2025 regarding an ALPR (Automated License Plate Reader) technology contract, indicating interest in law enforcement surveillance tools. He co-authored the FY2027 budget priority memorandum with Districts 4 8 and 9 in May 2026 which includes public safety funding. No defund or significant expansion language found.$$,
ARRAY['https://sandiego.gov/citycouncil/cd6/news']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Raul Campillo (District 7)
-- ============================================================

-- ----- Raul Campillo / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Campillo voted YES on the June 2023 Unsafe Camping Ordinance (passed 5-4) allowing police to remove homeless encampments when shelter beds are available. He separately advocates for safe sleeping and safe vehicle parking sites, stating that every safe parking lot in San Diego has been a success and represents a smart fiscal investment — pairing enforcement with supportive alternatives.$$,
ARRAY['https://en.wikipedia.org/wiki/Raul_Campillo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Campillo voted yes on the 2023 camping ban requiring shelter availability before enforcement and advocates for safe sleeping sites and safe vehicle parking programs as alternatives to encampments, describing them as a smart fiscal investment. His CD7 policy page lists behavioral health treatment expansion as a core priority alongside shelter-based approaches.$$,
ARRAY['https://en.wikipedia.org/wiki/Raul_Campillo', 'https://www.sandiego.gov/citycouncil/cd7/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Campillo's CD7 policy page lists affordable housing as one of his core priorities. Wikipedia notes he was removed from the Land Use and Housing Committee by the council majority, with Campillo attributing the removal to his rigorous questioning of city staff on controversial housing issues — suggesting active engagement on housing access rather than a passive stance.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd7/policy', 'https://en.wikipedia.org/wiki/Raul_Campillo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Campillo championed expanded naloxone access in San Diego, motivated by the personal loss of his brother to an opioid overdose, per Wikipedia. His CD7 policy page lists behavioral health treatment expansion as a core district priority, reflecting a public-health-focused approach to healthcare access beyond the minimum safety net.$$,
ARRAY['https://en.wikipedia.org/wiki/Raul_Campillo', 'https://www.sandiego.gov/citycouncil/cd7/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Campillo serves as Vice Chair of the Public Safety Committee per the CD7 policy page. Per Wikipedia he amended an ordinance enabling SDPD collaboration with federal task forces on firearms and child trafficking, supports ALPR cameras with restrictions on out-of-state data sharing, and championed expanded naloxone access. His record reflects maintaining current police capacity while adding targeted community health measures.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd7/policy', 'https://en.wikipedia.org/wiki/Raul_Campillo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Campillo sponsored a March 2026 ballot measure to codify free parking at San Diego beaches and bays in city code, stating: 'I brought this item forward in hopes of making sure the city does not repeat the same mistake we saw with the proposed parking fees at Balboa Park.' His CD7 page lists maintaining free beach/bay parking and reducing special event parking rates as active focus areas alongside e-bike safety and road repaving.$$,
ARRAY['https://timesofsandiego.com/politics/2026/03/18/campillo-ballot-proposal-to-keep-beach-bay-parking-free-advances/', 'https://www.sandiego.gov/citycouncil/cd7/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Campillo chairs the Economic Development and Intergovernmental Relations Committee per the CD7 policy page. In a February 2023 op-ed he supported advancing the Cottages at the Cays resort proposal with community vetting, arguing elected leaders must ensure equitable public access while creating good-paying jobs — a targeted incentives approach with community benefit considerations.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd7/policy', 'https://timesofsandiego.com/politics/2023/02/12/vacationing-families-deserve-an-affordable-place-to-stay-on-san-diego-bay/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Campillo serves on the San Diego River Conservancy board and chairs the Mission Trails Regional Park Task Force per the CD7 policy page — two direct institutional roles in watershed protection and regional park stewardship. These appointments reflect active engagement in protecting existing parks and natural corridors beyond minimum regulatory requirements.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd7/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Campillo is listed among San Diego city officials implementing the 2022 Climate Action Plan per the city's sustainability page, which sets a community-wide goal of net zero by 2035 and 100% clean power. His CD7 policy page references climate equity funding as a budget priority, reflecting support for investing in clean energy transition rather than a purely market-driven approach.$$,
ARRAY['https://www.sandiego.gov/sustainability/climate-action-plan', 'https://www.sandiego.gov/citycouncil/cd7/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Campillo vocally opposed San Diego's first trash collection fee in a century, characterizing it as a bait-and-switch when costs reached $43/month instead of the promised $29 maximum, and proposed mandatory fee disclosure requirements per Wikipedia. His opposition was framed as a transparency and accountability issue — closing a loophole — rather than ideological opposition to all taxation.$$,
ARRAY['https://en.wikipedia.org/wiki/Raul_Campillo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Campillo cast the sole dissenting vote (8-1) in April/May 2025 against the ordinance banning algorithmic rent-setting software that prohibits use of AI systems like RealPage to coordinate rental price increases. He was the only council member to oppose this tenant-protection regulation, suggesting a preference for market-rate rent-setting with limited government intervention.$$,
ARRAY['https://timesofsandiego.com/politics/2025/04/15/city-council-bans-use-of-software-blamed-for-raising-rent-based-on-algorithms/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raul Campillo / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '666bf03d-81fc-4138-ab15-69ae734c9023', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', '666bf03d-81fc-4138-ab15-69ae734c9023',
$$Campillo cast the sole dissenting vote (8-1) against San Diego's 2025 ordinance banning algorithmic rent-setting software that uses proprietary data to coordinate price increases. As the only council member to oppose the AI regulation ban, his vote reflects a preference for allowing AI companies to self-regulate rather than government banning specific AI applications.$$,
ARRAY['https://timesofsandiego.com/politics/2025/04/15/city-council-bans-use-of-software-blamed-for-raising-rent-based-on-algorithms/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Vivian Moreno (District 8)
-- ============================================================

-- ----- Vivian Moreno / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Moreno voted NO on the June 2023 Unsafe Camping Ordinance (passed 5-4) that permits police to remove homeless encampments when shelter beds are available, joining Elo-Rivera, Montgomery Steppe, and Lee in opposition. Wikipedia confirms her dissent. Her campaign site highlights co-opening Benson Place with Father Joe's Villages — 82 units of supportive housing — as a primary homelessness accomplishment, reflecting a prevention and housing-first posture over enforcement.$$,
ARRAY['https://en.wikipedia.org/wiki/Vivian_Moreno', 'https://www.vivianmorenosd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Moreno co-opened Benson Place (82 supportive housing units) with Father Joe's Villages and established the Housing Stability Fund ($3.57M providing up to $500/month rental subsidies) as her primary homelessness response tools. Her campaign site frames her approach around housing, services, and community investment, consistent with prioritizing shelter and outreach over enforcement as the primary strategy.$$,
ARRAY['https://www.vivianmorenosd.com', 'https://en.wikipedia.org/wiki/Vivian_Moreno']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Moreno authored the Affordable Housing Preservation Ordinance (passed unanimously Feb 2025) requiring owners of deed-restricted affordable housing to notify the city before selling, giving the city opportunity to purchase and preserve units built with public money. She distributed $218M in emergency rental assistance to 18,000 families and established the $3.57M Housing Stability Fund. She stated: 'This ordinance will keep San Diegans from losing the affordable homes they live in.'$$,
ARRAY['https://timesofsandiego.com/politics/2025/02/03/san-diego-city-council-passes-ordinance-to-preserve-affordable-housing/', 'https://www.vivianmorenosd.com', 'https://en.wikipedia.org/wiki/Vivian_Moreno']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Moreno opposed Proposition 10 in 2018 — the ballot measure that would have expanded local rent control authority in California — per Wikipedia. She has consistently stated support for increasing housing construction supply rather than rent control as the solution to housing affordability. Her BOMA Public Official of the Year 2020 award from the Building Owners and Managers Association reflects a pro-landlord, supply-side housing stance.$$,
ARRAY['https://en.wikipedia.org/wiki/Vivian_Moreno', 'https://www.vivianmorenosd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Moreno chairs the Land Use and Housing Committee and was named BOMA Public Official of the Year in January 2020, an award given by the Building Owners and Managers Association for her support of pro-housing development code reforms and market-oriented zoning approaches. Wikipedia confirms she chairs the Land Use and Housing Committee. Her record reflects allowing multifamily housing by right and streamlining approvals in alignment with California housing law.$$,
ARRAY['https://en.wikipedia.org/wiki/Vivian_Moreno', 'https://www.sandiego.gov/citycouncil/cd8']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Moreno co-sponsored the January 2026 council resolution opposing aggressive ICE enforcement tactics and authorizing the City Attorney to pursue legal action against the Trump administration's DHS and ICE. She stated: 'The actions taken by ICE are simply inhumane, unconstitutional and are not welcome in San Diego. This has led to drastic terror in our communities and lack of public's trust in state and local government.' Her position reflects refusing ICE detainers and prohibiting city cooperation with federal immigration enforcement.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '44905f3b-e105-4f6c-afc7-5d223813dbac',
$$Moreno co-sponsored the January 2026 anti-ICE resolution authorizing the City Attorney to file legal challenges against federal immigration enforcement tactics, and called ICE raids 'violent' and 'inhumane.' Her district — Barrio Logan and Otay Mesa — is a border community with substantial immigrant population. Her posture aligns with deporting only serious violent criminals while protecting broader undocumented communities.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/', 'https://en.wikipedia.org/wiki/Vivian_Moreno']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Moreno co-sponsored the January 2026 resolution opposing ICE enforcement tactics, called the federal raids 'inhumane and unconstitutional,' and represents a border district with deep ties to immigrant communities. Her district office is located near the US-Mexico border and her campaign site highlights South Bay community investment. She aligns with expanding legal protections and pathways for immigrant residents.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/', 'https://www.vivianmorenosd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Moreno co-proposed the Climate Equity Fund with Mayor Gloria in 2021 — the first dedicated fund in San Diego investing in historically disadvantaged communities to combat climate change. The measure passed unanimously 9-0 and directed $12M+ to District 8 environmental projects. Wikipedia confirms her authorship of this initiative as a core climate policy accomplishment, reflecting strong support for rapid transition to clean energy with an equity lens.$$,
ARRAY['https://en.wikipedia.org/wiki/Vivian_Moreno', 'https://www.vivianmorenosd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Moreno's Climate Equity Fund (2021) supports green infrastructure and parks investment in disadvantaged communities as part of San Diego's transition away from fossil fuels. Her MTS Board representation promotes transit infrastructure as a non-fossil-fuel mobility alternative. She has not supported expanding fossil fuel extraction and her record aligns with stopping new fossil fuel permits as part of the city's Climate Action Plan framework.$$,
ARRAY['https://en.wikipedia.org/wiki/Vivian_Moreno', 'https://www.sandiego.gov/citycouncil/cd8']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$In January 2019 Moreno called for San Diego to join the California Attorney General's lawsuit against the federal government over Tijuana River Valley sewage contamination running into Pacific Ocean beaches — an immediate environmental intervention in her district. She also championed the Barrio Logan Community Plan reforms limiting industrial pollution near residences. She serves on the Otay Valley Regional Park Policy Committee, reflecting continued park and watershed stewardship.$$,
ARRAY['https://timesofsandiego.com/politics/2019/01/28/mayor-councilmember-moreno-call-for-san-diego-to-join-tijuana-pollution-suit/', 'https://en.wikipedia.org/wiki/Vivian_Moreno', 'https://www.sandiego.gov/citycouncil/cd8']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Moreno chairs the Otay Mesa Enhanced Infrastructure Financing District Public Financing Authority and serves as First Alternate on the SANDAG Board of Directors — roles focused on targeted infrastructure-based economic development tied to specific district assets. Her campaign site highlights securing $141M in infrastructure improvements and $40K+ for the Chicano Park Museum. Her approach reflects targeted incentives with community benefit requirements rather than blanket corporate subsidies.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd8', 'https://www.vivianmorenosd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Moreno chairs the Land Use and Housing Committee and chairs the Otay Mesa EIFD which funds infrastructure alongside development in the border region. She secured $141M for infrastructure improvements including parks, roads, and emergency services, reflecting a proactive investment-ahead-of-growth stance rather than either imposing growth limits or removing all regulatory barriers.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd8', 'https://www.vivianmorenosd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Moreno's campaign site documents organizing 45+ dumpster drop-off events removing 230+ tons of debris across District 8, and she led the effort to amend the Municipal Code enabling city intervention on unpaved roads and alleys. Her accomplishments emphasize maintaining current sanitation services and enforcing anti-dumping laws for residents while expanding cleanup capacity in underserved neighborhoods.$$,
ARRAY['https://www.vivianmorenosd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Moreno serves as a full Representative on the San Diego MTS Board of Directors and is a member of the Bayshore Bikeway Working Group (SANDAG), reflecting active investment in public transit and cycling infrastructure. Her district includes transit-dependent communities and she secured road and pedestrian safety infrastructure for District 8, consistent with investing equally in roads and multimodal options.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd8']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Moreno authored the Climate Equity Fund (2021) explicitly targeting disadvantaged communities disproportionately affected by climate change and industrial pollution. She championed the Barrio Logan Community Plan limiting industrial pollution near homes in an environmental justice community. The $218M in rental assistance distributed during the pandemic was directed to 18,000 families, a majority of whom were in lower-income District 8 communities.$$,
ARRAY['https://en.wikipedia.org/wiki/Vivian_Moreno', 'https://www.vivianmorenosd.com']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Moreno's campaign site highlights securing $3.3M for Otay Mesa Fire Station 49 and leading code reforms enabling city intervention on unpaved roads and alleys for public safety. She has not advocated for defunding police or significantly expanding the police budget; her public safety record is infrastructure and service focused. Her vote against the 2023 camping ban reflects concern for vulnerable populations rather than opposition to all enforcement.$$,
ARRAY['https://www.vivianmorenosd.com', 'https://en.wikipedia.org/wiki/Vivian_Moreno']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vivian Moreno / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '6674d87e-999d-433a-aab7-3f626f59fd5f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b16443e-fec4-4f33-abbc-eb1331e3b42d', '6674d87e-999d-433a-aab7-3f626f59fd5f',
$$Moreno chairs the Audit Committee on the San Diego City Council, which provides independent oversight and accountability review of city departments and fiscal management. The Chair role on an audit committee reflects a strong commitment to government transparency and accountability, consistent with requiring disclosure and civilian oversight mechanisms.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd8']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Sean Elo-Rivera (District 9)
-- ============================================================

-- ----- Sean Elo-Rivera / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Elo-Rivera voted NO on the June 2023 Unsafe Camping Ordinance (passed 5-4), expressing concern it could harm vulnerable populations including seniors and people with disabilities. He stated: 'I hope I am wrong and the law will be enforced in a way that limits harm on people experiencing homelessness.' His opposition reflects a prevention-and-housing-first posture over enforcement.$$,
ARRAY['https://en.wikipedia.org/wiki/Sean_Elo-Rivera', 'https://timesofsandiego.com/politics/2023/06/14/senate-minority-leader-jones-calls-on-legislature-to-copy-new-san-diego-homeless-ordinance/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Elo-Rivera's authored Residential Tenant Protections Ordinance (2023) was explicitly framed as homelessness prevention — he stated 'Reducing evictions...can help reduce the number of residents falling into homelessness.' He voted against the camping-ban enforcement-first approach and consistently frames housing stability and services as the primary homelessness response strategy.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd9/policy', 'https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Elo-Rivera authored the Residential Tenant Protections Ordinance (passed 8-1, May 2023) expanding tenant protections and restricting no-fault evictions beyond AB 1482 standards. He introduced a June 2026 ballot measure taxing vacant non-primary homes to free up housing supply. In 2025 he authored the Residential Tenant Utility Charges Ordinance passed unanimously to prevent landlord overcharges on city utilities.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd9/policy', 'https://en.wikipedia.org/wiki/Sean_Elo-Rivera', 'https://timesofsandiego.com/politics/2025/06/09/san-diego-city-council-oks-ordinance-to-shield-renters-from-utility-overcharges/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Elo-Rivera authored the ban on algorithmic rent-setting software (passed 8-1, April/May 2025), prohibiting use of AI tools like RealPage that coordinate rental price increases, saving renters an estimated $185/month. He also authored the Residential Tenant Utility Charges Ordinance (2025) banning landlord overcharges on utilities, and earlier the 8-1 Residential Tenant Protections Ordinance (2023).$$,
ARRAY['https://timesofsandiego.com/politics/2025/04/15/city-council-bans-use-of-software-blamed-for-raising-rent-based-on-algorithms/', 'https://www.sandiego.gov/citycouncil/cd9/policy', 'https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Elo-Rivera supports ADU incentives and pro-density housing policies and serves as SANDAG vice chair overseeing regional growth planning. His housing focus is on affordable production and tenant protection rather than restricting density. His overall posture reflects allowing multifamily by right and streamlining approvals in alignment with California housing law, without opposing density increases.$$,
ARRAY['https://en.wikipedia.org/wiki/Sean_Elo-Rivera', 'https://timesofsandiego.com/politics/2023/01/13/sandag-board-elects-nora-vargas-as-new-chair-sean-elo-rivera-as-vice-chair/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Elo-Rivera co-sponsored the January 2026 resolution opposing 'excessive' ICE enforcement tactics alongside Councilmembers von Wilpert and Moreno. He stated: 'The violent, dehumanizing tactics being used by federal immigration agents are a betrayal of our values and a threat to our communities. These unconstitutional actions are not about safety; they are about fear and control.' The resolution authorized the City Attorney to pursue legal action against the Trump administration.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '44905f3b-e105-4f6c-afc7-5d223813dbac',
$$Elo-Rivera co-sponsored the January 2026 resolution opposing aggressive ICE enforcement tactics, authorized legal action opposing federal immigration enforcement operations, and stated that federal immigration agents' tactics are 'a betrayal of our values.' He unveiled a Refugee and Immigrant Culture Hub in December 2024. His actions reflect a posture of deporting only serious violent criminals while protecting broader immigrant communities.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/', 'https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Elo-Rivera co-sponsored the January 2026 anti-ICE resolution and addressed the crowd at the December 2024 unveiling of San Diego's Refugee and Immigrant Culture Hub near City Heights, a facility serving immigrant communities. His statement on ICE tactics — 'In San Diego, we believe in dignity, due process, and the right to feel safe' — reflects strong support for expanded legal status and immigrant community protection.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/', 'https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$As Council President in July 2022 Elo-Rivera said the Climate Action Plan targeting 100% renewable energy by 2030 and net-zero by 2035 was 'a very solid one' and stressed that the city must focus on 'actually taking action' with adequate planning and funding. He emphasized closing the implementation gap that caused the 2015 CAP to fail, reflecting strong support for rapid clean energy transition.$$,
ARRAY['https://timesofsandiego.com/politics/2022/07/14/council-president-elo-rivera-says-climate-action-plan-must-stress-implementation/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Elo-Rivera championed implementation of San Diego's Climate Action Plan targeting 100% renewable energy by 2030, which requires phasing out fossil fuel dependence in city energy procurement and transportation. His transportation work (Safe Streets Resolution, $25M Imperial Ave Bikeway) promotes non-fossil-fuel mobility. His posture is consistent with stopping new fossil fuel permits as part of the CAP's clean energy transition.$$,
ARRAY['https://timesofsandiego.com/politics/2022/07/14/council-president-elo-rivera-says-climate-action-plan-must-stress-implementation/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Elo-Rivera championed a second-homes vacancy tax ($5k/bedroom per year on non-primary homes vacant over half the year) as a 2026 ballot measure. He also championed a vacation rental tax and the $25/hour hospitality minimum wage (passed 2025), which he supported. He framed the cost-of-living committee he chaired as addressing affordability through taxes and worker wages.$$,
ARRAY['https://en.wikipedia.org/wiki/Sean_Elo-Rivera', 'https://timesofsandiego.com/tag/sean-elo-rivera/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Elo-Rivera co-authored the Safe Streets Resolution (September 2024) with Councilmember Whitburn making street safety the city's highest transportation priority and directing a review of municipal codes to reduce traffic deaths. He also championed the $25 million Imperial Avenue Bikeway groundbreaking in District 9 (June 2024), explicitly prioritizing pedestrian and cycling infrastructure alongside transit.$$,
ARRAY['https://timesofsandiego.com/politics/2024/09/16/whitburn-elo-rivera-pass-resolution-to-raise-priority-of-san-diego-street-safety/', 'https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Elo-Rivera introduced the Kumeyaay Land Acknowledgment Resolution (June 2024) in collaboration with the Kanap Kuahan Coalition, formally recognizing San Diego as unceded Kumeyaay land. He also championed the appointment of 25 permanent members to the Commission on Police Practices (August 2023), an independent oversight body for the SDPD. These actions reflect consistent work to address systemic discrimination and strengthen civil rights.$$,
ARRAY['https://timesofsandiego.com/politics/2024/06/10/san-diego-city-council-passes-resolution-to-honor-kumeyaay-land/', 'https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Elo-Rivera voted NO on the 2023 camping ban enforcement approach and championed the Commission on Police Practices with 25 permanent members (August 2023) as an independent SDPD oversight body. He co-authored the Safe Streets Resolution prioritizing pedestrian and cyclist safety over car-centric infrastructure. His approach shifts a portion of public safety investment toward oversight, prevention, and non-enforcement interventions.$$,
ARRAY['https://en.wikipedia.org/wiki/Sean_Elo-Rivera', 'https://timesofsandiego.com/politics/2024/09/16/whitburn-elo-rivera-pass-resolution-to-raise-priority-of-san-diego-street-safety/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '666bf03d-81fc-4138-ab15-69ae734c9023',
$$Elo-Rivera authored the ordinance banning algorithmic rent-setting software (passed 8-1, April/May 2025), prohibiting use of AI systems like RealPage that use proprietary data to coordinate rental price increases. He stated renters may pay $185/month more due to this practice. The ban prohibits 'the use, sale or licensing of software that allows price fixing based on proprietary data' — a targeted close regulation of AI systems posing documented consumer harm.$$,
ARRAY['https://timesofsandiego.com/politics/2025/04/15/city-council-bans-use-of-software-blamed-for-raising-rent-based-on-algorithms/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Elo-Rivera chaired the City Council's Cost of Living Committee which led major policy fights in 2025 on wages, rent, and consumer pricing. He championed the $25 hospitality minimum wage and targeted consumer protection ordinances. His approach emphasizes worker-focused targeted policies with community benefit requirements rather than blanket corporate subsidies or removing all regulatory barriers.$$,
ARRAY['https://timesofsandiego.com/politics/2025/12/20/san-diegos-cost-of-living-committee-led-big-policy-fights-in-2025-the-city-council-is-ending-it/', 'https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Elo-Rivera co-sponsored Measure B in 2022 authorizing San Diego to charge residents for solid waste collection, which was subsequently challenged in court by homeowners. The measure reflects a maintain-current-services-with-cost-sharing approach to sanitation rather than major expansion or privatization.$$,
ARRAY['https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Elo-Rivera was elected SANDAG Vice Chair in January 2023 overseeing regional growth planning across San Diego County. His tenure reflects a proactive infrastructure investment approach — investing in transit (Imperial Ave Bikeway, Safe Streets) and affordable housing ahead of growth rather than either imposing growth limits or removing all regulatory barriers.$$,
ARRAY['https://timesofsandiego.com/politics/2023/01/13/sandag-board-elects-nora-vargas-as-new-chair-sean-elo-rivera-as-vice-chair/', 'https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Elo-Rivera / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '7bad33eb-e93e-4d94-8822-97212d49bde5', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dc3d8a98-07ce-4797-bc84-957a72fd854f', '7bad33eb-e93e-4d94-8822-97212d49bde5',
$$Elo-Rivera championed the appointment of 25 permanent members to San Diego's Commission on Police Practices in August 2023, creating an independent civilian oversight body for the SDPD. The commission was designed to review officer conduct and provide accountability independent of the police department. This reflects a strong posture of civilian oversight and police accountability reform.$$,
ARRAY['https://en.wikipedia.org/wiki/Sean_Elo-Rivera']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
