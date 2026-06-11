-- ============================================================================
-- Migration 359: Maura Healey Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Maura Healey (Governor of Massachusetts).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production per CLAUDE.md).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- data-centers                     4559b513-0fd8-4ed1-babd-f3b554162f40
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
-- Maura Healey
-- ============================================================

-- ----- Maura Healey / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$As Massachusetts AG, Healey filed SCOTUS amicus briefs defending Roe v. Wade and joined multi-state coalitions opposing federal abortion restrictions. She championed the 2020 ROE Act that codified abortion access in MA state law. As Governor, she signed legislation expanding abortion access and reproductive healthcare funding, and publicly pledged to protect abortion access from federal rollback.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-signs-legislation-to-expand-reproductive-healthcare-access', 'https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Governor Healey issued an executive order in 2023 directing state agencies to develop AI use policies and consumer protections around AI. She has supported responsible AI development guidelines while also promoting Massachusetts as an AI innovation hub. Her administration has emphasized guardrails against AI-driven discrimination and fraud rather than heavy-handed restrictions.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-signs-executive-order-on-artificial-intelligence', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$As MA AG, Healey aggressively enforced campaign finance disclosure laws and prosecuted violations. She supported the DISCLOSE Act at the federal level and backed stricter limits on dark money in elections. As Governor, she advocated for public financing of campaigns and greater transparency in political spending, consistent with her record of prioritizing clean elections.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/orgs/office-of-the-attorney-general']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Governor Healey made childcare a signature priority, signing a major childcare workforce bill in 2023 and allocating hundreds of millions in state funding to expand access. She created a new Office of Early Education and Care within her administration and proposed universal pre-K expansion. She has called the childcare crisis an economic issue that holds back workers, especially women.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-signs-legislation-to-strengthen-the-early-education-and-care-workforce', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Maura Healey built her career on civil rights enforcement. As AG, she pursued landmark LGBTQ+ discrimination cases, filed voting rights amicus briefs with the Supreme Court, and led national coalitions defending civil rights laws. As the first openly lesbian governor in US history, she signed executive orders protecting LGBTQ+ residents, people of color, and immigrants from discrimination.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/executive-orders/no-627-reaffirming-the-commonwealths-commitment-to-civil-rights']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Governor Healey is one of the most aggressive climate leaders among US governors. She signed legislation committing Massachusetts to net-zero by 2050 with a 2030 milestone, set offshore wind expansion as a top economic priority, and joined the US Climate Alliance. As AG, she sued Exxon for climate deception and joined multi-state coalitions challenging EPA rollbacks. Her Clean Energy and Climate Plan targets 80% GHG reduction by 2050.$$,
        ARRAY['https://www.mass.gov/info-details/massachusetts-clean-energy-and-climate-plan', 'https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/news/governor-healey-launches-offshore-wind-initiative']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Governor Healey has promoted data center investment as part of Massachusetts's tech economy but has also flagged energy consumption concerns. Her administration has required data center projects to meet energy efficiency standards and has evaluated their impact on the state's grid and climate goals. She has treated data centers as an economic-environmental tradeoff to be managed rather than taking a strongly permissive or restrictive stance.$$,
        ARRAY['https://www.mass.gov/info-details/massachusetts-clean-energy-and-climate-plan', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$As MA AG, Healey joined multi-state lawsuits challenging the Trump administration's travel ban, family separation policy, and immigration enforcement actions, arguing they were unconstitutional and violated due process. As Governor, she has opposed deportation of long-term MA residents and families, signed orders to limit state cooperation with ICE civil immigration enforcement, and defended Massachusetts as a welcoming state for immigrants.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/news/governor-healey-issues-executive-order-protecting-immigrants']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Governor Healey launched a major economic development initiative in 2023, including a $400M life sciences bond bill and a new Office of Economic Development focused on clean energy jobs. She prioritized workforce development and expanding the innovation economy to underserved communities. Her approach emphasizes public-private partnerships and targeted investments in clean energy, biotech, and advanced manufacturing.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-signs-legislation-to-support-economic-development', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Governor Healey has consistently opposed fossil fuel expansion. As AG, she sued Exxon for climate fraud and misleading the public about fossil fuel risks. As Governor, she signed legislation requiring gas utilities to plan for a transition away from natural gas and advancing electrification. She has opposed new fossil fuel infrastructure and made offshore wind her signature economic and climate initiative.$$,
        ARRAY['https://www.mass.gov/info-details/massachusetts-clean-energy-and-climate-plan', 'https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Governor Healey has broadly supported economic growth and development with an emphasis on affordability and sustainability. She promoted enforcement of the Housing Choice Act, economic development funding for underserved communities, and clean energy industry growth. While supportive of development, she has required affordable housing components and environmental review for major projects.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.mass.gov/news/governor-healey-signs-legislation-to-support-economic-development']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Governor Healey has been a strong supporter of universal healthcare access. As AG, she defended the ACA against Republican repeal efforts and filed briefs supporting Medicaid expansion. As Governor, she expanded MassHealth (Medicaid) eligibility, signed behavioral health parity legislation, and has advocated for a pathway to universal coverage. She has consistently supported Massachusetts as a model for the nation on healthcare access.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/news/governor-healey-expands-masshealth-coverage']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Governor Healey has opposed criminalizing homelessness, instead focusing on housing-first solutions and shelter access. Massachusetts has a statutory right to shelter, and Healey has worked to maintain and expand shelter capacity. She declared a housing emergency in 2023 and directed resources to prevent homelessness through rental assistance and rapid rehousing programs.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-declares-housing-emergency', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Governor Healey has pursued a services-first approach to homelessness, emphasizing shelter capacity, mental health services, and housing placement over enforcement. She signed legislation expanding homeless shelter funding and rapid rehousing, worked with municipalities on permanent supportive housing, and opposed sweeps-only approaches. Her administration established an Emergency Assistance program supporting homeless families.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-declares-housing-emergency', 'https://ballotpedia.org/Maura_Healey', 'https://www.mass.gov/orgs/executive-office-of-housing-and-livable-communities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Housing is Healey's signature domestic issue as Governor. She signed the Affordable Homes Act (2024), the largest housing investment in Massachusetts history at $5.1B, targeting 65,000 new housing units. She enforced the MBTA Communities Act requiring transit-area zoning for multifamily housing, taking legal action against resistant towns. She created a new Executive Office of Housing and Livable Communities.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-signs-affordable-homes-act', 'https://www.mass.gov/info-details/mbta-communities-act', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Governor Healey has been a consistent advocate for immigrant rights. As AG, she filed briefs against the Trump travel ban, family separation, and DACA rescission. As Governor, she signed executive orders protecting immigrants from state-level immigration enforcement, supported in-state tuition for undocumented students, and allocated funding for immigrant legal services. She opposes deportation of long-term MA residents.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/news/governor-healey-issues-executive-order-protecting-immigrants']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Governor Healey signed an executive order in 2023 directing state agencies and law enforcement not to cooperate with ICE civil immigration detainers, effectively making Massachusetts a welcoming state for undocumented residents. She has funded community organizations supporting immigrants and allocated resources for immigration legal services, mirroring her record as AG opposing federal immigration enforcement actions.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-issues-executive-order-protecting-immigrants', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Governor Healey has strongly supported Medicaid expansion and Medicare preservation. As AG, she joined multi-state coalitions defending the ACA's Medicaid expansion provisions. As Governor, she expanded MassHealth eligibility, extended postpartum Medicaid coverage, and opposed federal Medicaid funding cuts. She has called for expanding Medicare to cover more services as a path to universal coverage.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/news/governor-healey-expands-masshealth-coverage']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$As MA AG, Healey pursued deceptive practices cases against corporations spreading false health and safety information and supported social media transparency requirements. As Governor, she has spoken about combating election misinformation and signed cybersecurity legislation. Her approach emphasizes accountability for platforms and actors who deliberately spread harmful false information.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Governor Healey has supported police accountability reform while maintaining law enforcement investment. As AG, she backed the 2020 MA police reform law establishing an independent oversight commission. As Governor, she has supported diversion programs, mental health crisis response alternatives, and community policing reforms. She has opposed defunding police while advocating for accountability and investment in community-based public safety solutions.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Healey was AG during the 2021 Massachusetts redistricting process and supported the independent redistricting commission model. She called for maps that ensure fair minority representation in line with the Voting Rights Act. As a candidate and then Governor, she has supported nonpartisan redistricting criteria to reduce gerrymandering.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Governor Healey has supported local rent stabilization authority as part of the broader housing package. The Affordable Homes Act she signed included provisions enabling municipalities to adopt local rent stabilization policies. She has framed rent regulation as one tool among many, supporting tenant protections alongside major supply-side investments in new housing.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-signs-affordable-homes-act', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Healey has been the most aggressive governor in Massachusetts history on upzoning and housing production. She enforced the MBTA Communities Act, requiring 177 transit-area communities to allow multifamily housing as-of-right, and threatened withholding of state funding from non-compliant towns. The Affordable Homes Act removed restrictive zoning barriers, and she created new tools for dense housing development near transit.$$,
        ARRAY['https://www.mass.gov/info-details/mbta-communities-act', 'https://www.mass.gov/news/governor-healey-signs-affordable-homes-act', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Maura Healey is a historic LGBTQ+ champion and the first openly lesbian governor in US history. As AG, she filed landmark civil rights cases protecting same-sex couples and LGBTQ+ individuals from discrimination. She supported the Defense of Marriage Act challenge and filed briefs in the Supreme Court Obergefell case. As Governor, she has signed executive orders protecting LGBTQ+ rights and opposed any rollback of marriage equality.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/executive-orders/no-627-reaffirming-the-commonwealths-commitment-to-civil-rights']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Governor Healey supported the 2022 ballot question preserving MCAS high-stakes testing and has backed public schools as the primary investment priority. She has opposed a universal school choice/voucher program while supporting some charter school expansion and alternative education pathways. She places strong emphasis on public school investment while allowing limited charter options, positioning her center-right on this axis.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Governor Healey has consistently supported Social Security expansion. She backed the Social Security 2100 Act, which would expand benefits and strengthen long-term solvency. As AG, she joined amicus briefs defending Social Security benefit protections. She has opposed any cuts to Social Security and Medicare and has called for removing the earnings cap on Social Security contributions to strengthen the program.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '683c8084-2281-4920-a07c-18439b2dd413',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Governor Healey has spoken out against tariffs that harm the Massachusetts economy, particularly in sectors like clean energy equipment, biotech supply chains, and agriculture. She has called for trade policies that protect American workers without raising costs on consumers and has joined other governors in urging the federal government to exempt certain goods from tariffs impacting state economies.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.mass.gov/news/governor-healey-issues-statement-on-federal-tariff-impacts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Governor Healey signed the MA tax relief bill in 2023, providing $1B in tax cuts including expanded estate tax thresholds, childcare tax credits, and rental deductions. She has supported progressive tax policies including the 2022 millionaire's surtax. Her approach is moderate-progressive: supports surtax on high incomes while also providing middle-class relief, avoiding both major tax hikes and major cuts.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-signs-tax-relief-bill', 'https://ballotpedia.org/Maura_Healey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Governor Healey is a strong advocate for transgender inclusion in sports. As the first openly lesbian governor, she has publicly opposed laws banning transgender athletes from competing in their identified gender and has signed executive orders protecting transgender students' rights in schools, including in athletics. She has called state bans on trans athletes discriminatory and has pledged to defend transgender students from federal restrictions.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/executive-orders/no-627-reaffirming-the-commonwealths-commitment-to-civil-rights']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Governor Healey has made MBTA reform and public transit investment a top priority. She appointed a new MBTA General Manager, committed $8B+ in capital investment to the T, signed legislation to improve accountability, and pushed back against federal threats to MBTA funding. She supports transit-first transportation policy, electrification of transit fleets, and expanding rail service across Massachusetts.$$,
        ARRAY['https://www.mass.gov/orgs/massachusetts-bay-transportation-authority', 'https://ballotpedia.org/Maura_Healey', 'https://www.mass.gov/news/governor-healey-announces-mbta-capital-investment-plan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '24e9212c-b011-422a-865c-093e35050901',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Governor Healey has been a strong supporter of US aid to Ukraine. She signed Massachusetts solidarity resolutions with Ukraine, supported sanctions on Russia, and advocated for continued US military and economic assistance to Ukraine. As a member of the National Governors Association, she signed joint statements supporting Ukraine's sovereignty and opposing Russian aggression.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.mass.gov/news/governor-healey-statement-on-ukraine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Maura Healey / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voting rights was a signature issue for Healey as AG and Governor. As AG, she led a national coalition of 20+ attorneys general filing amicus briefs in VRA cases before the Supreme Court, challenging voter ID laws and polling place restrictions. As Governor, she signed automatic voter registration legislation and expanded early voting. She has called restrictive voting laws unconstitutional and consistently fought to expand ballot access.$$,
        ARRAY['https://ballotpedia.org/Maura_Healey', 'https://ontheissues.org/Governor/Maura_Healey.htm', 'https://www.mass.gov/news/governor-healey-signs-voting-rights-legislation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 32 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
