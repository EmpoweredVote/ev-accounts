-- ============================================================================
-- Migration 496: Marjorie C. Decker Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Marjorie C. Decker (MA House HD-81,
--   25th Middlesex District, Cambridge). External ID: -210121.
--   Decker has served since 2003; progressive Cambridge Democrat with extensive
--   public record on housing, healthcare, criminal justice, and climate.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
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

-- Marjorie C. Decker (HD-81, external_id=-210121)
-- Politician UUID: 2b1a645a-72ce-4c0f-80ec-17565a2d6d10

-- ----- Marjorie C. Decker / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Decker co-sponsored the ROE Act (H.3320), which codifies and expands abortion rights in Massachusetts, ensuring abortion remains legal even if Roe v. Wade were overturned federally. She received endorsements from NARAL Pro-Choice Massachusetts and has consistently voted for abortion access legislation throughout her tenure in the House. Her Cambridge district and progressive record reflect strong support for reproductive rights.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Decker has co-sponsored campaign finance reform legislation including bills to increase transparency in political spending and limit corporate influence in MA elections. Her ActOnMass scorecard and Beacon Hill Roll Call record show consistent votes for disclosure requirements and restrictions on dark money in state elections.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://www.beaconhillrollcall.com/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Decker co-sponsored the Affordable and Accessible Child Care for All Act and related bills to expand universal pre-K and subsidize childcare costs for working families in Massachusetts. As a Cambridge representative she has been a consistent advocate for publicly funded childcare infrastructure and has voted for early education funding increases in the House budget.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Legislators/Profile/MCD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Decker has championed civil rights legislation throughout her 20+ year career, including the Pregnant Workers Fairness Act, anti-discrimination protections, and legislation protecting LGBTQ residents. She has co-sponsored bills to strengthen the MA Civil Rights Act and expand protections against workplace and housing discrimination. ActOnMass rates her as a progressive champion on civil rights issues.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Legislators/Profile/MCD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Decker co-sponsored the 100% Renewable Energy Act and voted in favor of the 2021 climate roadmap bill (H.4264) committing Massachusetts to net-zero emissions by 2050. She has consistently supported offshore wind investment, clean energy incentives, and legislation to accelerate the transition away from fossil fuels. Her district includes environmentally active Cambridge residents and she has attended climate advocacy events hosted by 350 Massachusetts.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Decker has co-sponsored the Stop Wage Theft Act and Fair Scheduling Act, reflecting strong support for worker-protective economic policies. She has also supported minimum wage increases and small business development programs for underserved communities in Cambridge. Her record shows a preference for regulated, worker-centered economic development rather than tax-incentive-driven growth.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://actonmass.org/bills/stop-wage-theft/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Decker has voted to accelerate the phase-out of fossil fuels in Massachusetts, supporting legislation to ban new gas infrastructure in buildings and transition to clean energy. She co-sponsored the 100% Renewable Energy Act and has supported bills to end fossil fuel subsidies and expand building electrification requirements. Cambridge has adopted aggressive local climate policies that align with her legislative positions.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://actonmass.org/bills/100-renewable-energy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Decker co-sponsored the Medicare for All Massachusetts Act (H.1279), which would create a single-payer system providing universal healthcare coverage. She has consistently voted for Medicaid expansion, mental health parity legislation, and bills to lower prescription drug costs. Her ActOnMass healthcare scorecard reflects a strong progressive record on expanding access to care.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Decker has co-sponsored bills to fund permanent supportive housing and wraparound social services for people experiencing homelessness, reflecting a Housing First approach. She has opposed punitive measures that criminalize homelessness and supported mental health and substance use treatment funding as essential components of any homelessness response strategy.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Legislators/Profile/MCD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Decker has been a leading advocate for affordable housing in Massachusetts, co-sponsoring multiple bills to expand public housing funding, inclusionary zoning, and tenant protections. She represents Cambridge — one of the most expensive rental markets in the US — and has supported lifting the statewide ban on rent control, funding low-income housing tax credits, and expanding first-generation homebuyer programs.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://actonmass.org/bills/rent-control/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Decker co-sponsored the Safe Communities Act, which would limit Massachusetts cooperation with federal immigration enforcement and protect immigrant communities from deportation. She has supported in-state tuition for undocumented students (the DREAM Act) and drivers' licenses for all residents regardless of immigration status. Her Cambridge district has a large immigrant population and she has consistently championed immigrant rights legislation.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://actonmass.org/bills/safe-communities-act/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Decker voted for the 2018 Massachusetts criminal justice reform omnibus bill, which reduced mandatory minimum sentences, raised the felony threshold, and expanded diversion programs. She has co-sponsored bills to expand expungement of criminal records and end solitary confinement in Massachusetts prisons. She supported the 2020 Police Accountability Act that created new oversight mechanisms for law enforcement.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Bills/191/S2700'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Decker co-sponsored the Medicare for All Massachusetts Act and has consistently voted to protect and expand MassHealth (the state Medicaid program). She has supported legislation to expand MassHealth eligibility and restore coverage for services that had been cut. Her support for single-payer healthcare at the state level reflects a commitment to universal coverage through government health programs.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Decker voted for the 2020 Police Reform and Accountability Act (H.4990), which created the Peace Officer Standards and Training (POST) Commission to decertify problematic officers and established new use-of-force restrictions. She has supported community-based violence intervention programs as complements to traditional policing and backed legislation to invest in mental health crisis response alternatives.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Bills/191/H4990'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Decker is one of the leading advocates for repealing the 1994 statewide ban on rent control in Massachusetts, co-sponsoring the Rent Stabilization Act repeatedly. Cambridge — which had rent control until 1994 — is her district, and her constituents are directly affected by housing cost pressures. She has testified in favor of giving cities the local option to implement rent stabilization.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://actonmass.org/bills/rent-control/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Decker supported the MBTA Communities zoning reform requiring denser housing near transit stations, reflecting support for increased density in urban areas. However, she has also championed tenant protections and community input in planning decisions, balancing density goals with displacement prevention. Her position favors more housing production in transit-oriented locations combined with strong affordability requirements.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Decker has consistently supported LGBTQ equality, including marriage equality, and has voted against any effort to overturn or restrict same-sex marriage rights in Massachusetts. She represents Cambridge, the first US city to have a same-sex marriage ceremony when it became legal in 2004, and her legislative record reflects full support for marriage equality.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Legislators/Profile/MCD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Decker has strongly opposed school voucher and charter school expansion measures, voting against the 2016 ballot question (Question 2) that would have lifted the cap on charter schools in Massachusetts. She co-sponsored legislation to strengthen public school oversight and has supported teacher unions and fully-funded public education. Her record reflects opposition to diverting public school funding to private or charter alternatives.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://www.ballotpedia.org/Massachusetts_Authorization_of_Additional_Charter_Schools_and_Charter_School_Expansion,_Initiative_Petition_(2016)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Decker voted in favor of the 2022 Massachusetts Millionaires Tax (Question 1 / the Fair Share Amendment), which added a 4% surtax on annual income over $1 million. She has consistently supported progressive tax policy including higher rates on high earners and corporations to fund public services. Her ActOnMass scorecard reflects votes for tax-the-wealthy bills throughout her tenure.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Decker has consistently supported transgender rights legislation, including protections allowing transgender students to participate in school sports consistent with their gender identity. She opposed efforts to restrict trans student participation and voted for comprehensive trans protections under the 2016 MA Transgender Anti-Discrimination Act. Her progressive Cambridge district and legislative record reflect full inclusion for transgender athletes.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Legislators/Profile/MCD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marjorie C. Decker / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Decker voted for and co-sponsored the 2022 VOTES Act, which made early voting and vote-by-mail permanent in Massachusetts after the COVID-era expansion. She has also supported automatic voter registration and same-day registration bills. Her record reflects consistent support for measures to expand voter access and participation.$$,
        ARRAY['https://actonmass.org/legislators/marjorie-decker/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '2b1a645a-72ce-4c0f-80ec-17565a2d6d10';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '2b1a645a-72ce-4c0f-80ec-17565a2d6d10'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '2b1a645a-72ce-4c0f-80ec-17565a2d6d10'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
