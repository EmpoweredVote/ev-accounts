-- ============================================================================
-- Migration 291: MD Delegates Batch F — Districts 34-40
-- ============================================================================
-- Purpose: Insert/upsert stance data for 21 politicians.
--
-- Topic scope: Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.
--
-- Post-state: ~189 rows expected
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
-- Gabriel Acevero
-- ============================================================

-- ----- Gabriel Acevero / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Acevero sponsored the Maryland Use of Force Statute - Failure to Prevent Excessive Force Misdemeanor and Criminal Procedure - No-Knock Search Warrants ban — both police accountability measures prioritizing community safety over enforcement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01', 'https://ballotpedia.org/Gabriel_Acevero']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Acevero sponsored legislation banning no-knock search warrants and creating misdemeanor liability for failure to prevent excessive force or render first aid — among the strongest police accountability positions in the MD House.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Acevero co-sponsored the Public Safety - Immigration Enforcement Agreements - Prohibition bill banning local police cooperation with ICE — a sanctuary-aligned immigration stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Acevero sponsored the Taxation - Ultra-High-Net-Worth Individual Surtax and Wealth Tax bill — one of the most progressive tax proposals in the MD House — targeting billionaires with a wealth tax.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Acevero co-sponsored the Affordable Solar Act expanding solar energy access and renewable energy credits — plus the Sales and Use Tax - Exemptions for Data Centers - Repeal indicating support for removing corporate energy subsidies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Acevero's sponsorship of solar expansion bills and opposition to fossil fuel subsidies (Data Centers Tax Exemption Repeal) places him strongly in favor of fossil fuel phase-out.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Acevero co-sponsored Maryland Medical Assistance Program expansions including coverage for individuals with developmental disabilities and orthoses/prostheses — expanding Medicaid coverage.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Acevero co-sponsored Maryland Medical Assistance Program - Individuals With Intellectual and Developmental Disabilities - Provider Reimbursement — expanding Medicaid services.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$As a progressive caucus member Acevero supports expanded voting access; his bill sponsorships reflect strong opposition to voting restrictions and support for automatic voter registration.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Acevero sponsored the Public Safety - Maryland Police Training and Standards Commission - Prohibition Against Certain Affiliation by Police Officers and Custodial Interrogation of Minors - Exonerated 5 Act — strong civil rights focus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Acevero sponsored the Custodial Interrogation of Minors - Admissibility of Statements (Exonerated 5 Act) and Criminal Law - Drug Paraphernalia Prohibitions - Repeal — strongly rehabilitation and restorative justice focused.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Acevero co-sponsored the Primary and Secondary Education - Maintenance of Effort Modernization Act and education funding bills — strongly supporting public education and childcare investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Acevero consistently opposes school vouchers as a progressive caucus Democrat who champions public school funding equity.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Acevero voted with the Democratic majority on redistricting and his progressive caucus membership reflects strong support for independent redistricting commissions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriel Acevero / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Acevero co-sponsored the Land Use - Permitting - Development Rights (Maryland Housing Certainty Act) supporting housing development streamlining while maintaining community input.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/acevero01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Christopher T. Adams
-- ============================================================

-- ----- Christopher T. Adams / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Adams co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Elections - In-Person Voting - Proof of Identity bill — both restrictive voting access measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01', 'https://ballotpedia.org/Christopher_Adams_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher T. Adams / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Adams co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher T. Adams / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Adams co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act — a Republican redistricting reform opposing Democratic-drawn maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher T. Adams / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Adams co-sponsored the Juvenile Justice Restoration Act (more punitive juvenile sentencing) and the Department of Juvenile Services - Employees - Prohibited Convictions (Juvenile Offender Protection Act).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher T. Adams / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Adams co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting solar farm siting — reflecting skepticism of aggressive renewable energy mandates in a rural Eastern Shore district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher T. Adams / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Adams sponsored the Economic Development - Rural Readiness Program and Rural Maryland Capacity Building Fund — rural business support focused — and Labor and Employment - Noncompete Clauses - Employer Relocation deregulatory measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher T. Adams / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1eada938-f28c-46b9-bd21-df241656cd2b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Adams co-sponsored the Public Safety - Police Accountability - Investigation Records bill and Juvenile Justice Restoration Act — overall favoring law enforcement-first approaches.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/adams01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Marlon Amprey
-- ============================================================

-- ----- Marlon Amprey / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Amprey co-sponsored the Public Safety - Immigration Enforcement Agreements - Prohibition bill banning local police cooperation with ICE — a sanctuary-aligned immigration stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01', 'https://ballotpedia.org/Marlon_Amprey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marlon Amprey / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Amprey sponsored the State Government - Prison Education Delivery Reform Commission and Adult Prison School Board Model Development Committee — emphasizing education and rehabilitation for incarcerated individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marlon Amprey / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Amprey co-sponsored the Election Districts - General Assembly and Representatives in Congress bill — participating in Democratic-led redistricting supporting the majority's map.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marlon Amprey / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Amprey co-sponsored the Affordable Solar Act expanding solar energy access and renewable energy credits — a clean energy expansion measure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marlon Amprey / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Amprey's co-sponsorship of the Affordable Solar Act and Investor-Owned Electric Companies - Cost Recovery Limitations reflects support for transitioning away from fossil fuels.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marlon Amprey / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Amprey sponsored the Digital Asset and Blockchain Technology Task Force and Financial Institutions - Payment Stablecoin Services legislation — supporting innovation-driven economic development in Baltimore.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marlon Amprey / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Amprey co-sponsored Investor-Owned Electric Companies - Cost Recovery - Limitations and promoted economic development through targeted public investment — consistent with Democratic progressive tax and investment positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marlon Amprey / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Amprey co-sponsored Public Safety - Immigration Enforcement Agreements Prohibition and the prison education commission — reflecting a holistic public health and social services approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marlon Amprey / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Amprey sponsored the Qualifying Nonprofit Organizations - Incarcerated Individual Training and Reentry Grant Fund and State Government - Prison Education Commission — strongly reentry and civil rights focused.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marlon Amprey / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62bed8b6-beb2-4c41-b234-dc6427bfc9c0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Amprey co-sponsored Election Districts redistricting legislation aligned with Democratic majority; as a Baltimore City Democrat he strongly supports expanded voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/amprey01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- H. Kevin Anderson
-- ============================================================

-- ----- H. Kevin Anderson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Anderson co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Elections - In-Person Voting - Proof of Identity bill — both restrictive voting access measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01', 'https://ballotpedia.org/Kevin_Anderson_(Maryland_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- H. Kevin Anderson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Anderson co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- H. Kevin Anderson / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Anderson co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act opposing Democratic-drawn district maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- H. Kevin Anderson / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Anderson co-sponsored the Juvenile Justice Restoration Act and First Degree Murder - Diminution Credits - Prohibition — both punishment-focused criminal justice bills.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- H. Kevin Anderson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Anderson co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting solar farm placement and co-sponsored the Electric Companies - Customer Bill Surcharge - Repeal opposing energy surcharges for clean energy funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- H. Kevin Anderson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Anderson co-sponsored the Electric Companies and Gas Companies - Customer Bill Surcharge - Repeal — a bill removing clean energy surcharges on utility bills — indicating support for conventional energy over mandated clean energy funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- H. Kevin Anderson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Anderson co-sponsored the Public Safety - Immigration Enforcement - Immigration Enforcement Agreements bill (supporting local-federal immigration enforcement cooperation) — an enforcement-focused immigration position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- H. Kevin Anderson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d17104a7-8a35-4bcd-8879-76ceb997df6a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Anderson sponsored the Education - Student Behavior - Parent and Guardian Notice and Required Counseling (Parent and Guardian Accountability Act) — an enforcement-first approach to school discipline and public safety.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/anderson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Steven J. Arentz
-- ============================================================

-- ----- Steven J. Arentz / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Arentz co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Elections - In-Person Voting - Proof of Identity bill — both measures restricting voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01', 'https://ballotpedia.org/Steven_Arentz']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven J. Arentz / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Arentz co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven J. Arentz / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Arentz co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act — a Republican bill reforming Maryland's Democratic-controlled redistricting process.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven J. Arentz / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Arentz co-sponsored the Juvenile Justice Restoration Act (more punitive juvenile sentencing) and First Degree Murder - Diminution Credits - Prohibition eliminating early release credits — a punishment-focused criminal justice approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven J. Arentz / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Arentz co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting where solar farms can be built — indicating skepticism of aggressive renewable mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven J. Arentz / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Arentz sponsored the Retail Supply of Electricity and Gas - Regulation and Consumer Protection and Property Tax Credit for Disabled Veterans bills — tax relief oriented legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven J. Arentz / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Arentz co-sponsored First Degree Murder - Diminution Credits - Prohibition and the Juvenile Justice Restoration Act — indicating a law enforcement and punishment-first approach to public safety.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/arentz01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Barry Beauchamp
-- ============================================================

-- ----- Barry Beauchamp / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Beauchamp co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Secure the Vote Act of 2026 — both measures tightening voting access requirements.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01', 'https://ballotpedia.org/Barry_Beauchamp']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Beauchamp / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Beauchamp co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Beauchamp / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Beauchamp co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act — opposing Democratic-drawn maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Beauchamp / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Beauchamp co-sponsored the Juvenile Justice Restoration Act and First Degree Murder - Diminution Credits - Prohibition and Department of Juvenile Services - Employees - Prohibited Convictions — punishment-focused criminal justice positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Beauchamp / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Beauchamp co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting solar farm placement.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Beauchamp / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Beauchamp co-sponsored the Corporate Income Tax - Rate Reduction (Economic Competitiveness Act of 2026) and Property Tax - Residential Real Property - Moratorium on Assessment Increases — tax-cut-focused legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Beauchamp / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Beauchamp co-sponsored the Health Occupations - Cross-Sex Hormone Therapy for Minors bill restricting gender-affirming care for minors — strongly conservative on LGBTQ+ issues including transgender athletes.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Beauchamp / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Beauchamp co-sponsored the Secure the Vote Act and citizenship verification bills reflecting restrictionist immigration enforcement priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Beauchamp / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$As a rural Eastern Shore Republican Beauchamp opposed renewable energy mandates and co-sponsored legislation restricting solar farm expansion — consistent with support for conventional energy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/beauchamp01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jefferson L. Ghrist
-- ============================================================

-- ----- Jefferson L. Ghrist / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ghrist co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Elections - In-Person Voting - Proof of Identity bill — both restrictive voting measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01', 'https://ballotpedia.org/Jefferson_Ghrist']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jefferson L. Ghrist / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Ghrist co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jefferson L. Ghrist / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Ghrist co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act opposing the Democratic-drawn district map.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jefferson L. Ghrist / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Ghrist co-sponsored the Juvenile Justice Restoration Act (more punitive juvenile sentencing) and the Department of Juvenile Services - Employees - Prohibited Convictions (Juvenile Offender Protection Act).$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jefferson L. Ghrist / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ghrist co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting solar farm siting — and sponsored Renewable Energy Portfolio Standard - Waste-to-Energy inclusion suggesting preference for less aggressive clean energy policy.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jefferson L. Ghrist / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ghrist sponsored the Renewable Energy Portfolio Standard - Waste-to-Energy bill — broadening eligible energy sources beyond solar/wind — and opposed aggressive solar expansion restrictions indicating support for conventional energy sources.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jefferson L. Ghrist / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Ghrist sponsored Water Pollution Control - Discharge Permits - Animal Feeding Operations — an agricultural-leaning environmental bill — and the Department of the Environment - Waivers for Living Shorelines bill relaxing some shoreline regulations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jefferson L. Ghrist / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eca530ff-628d-417d-a3dc-b858dc7c2376',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ghrist sponsored the Economic Development - Rural Readiness Program and Rural Maryland Capacity Building Fund - Establishment and Agriculture - Hemp Manufacturing License bills — rural business deregulation focused.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ghrist01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mike Griffith
-- ============================================================

-- ----- Mike Griffith / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Griffith sponsored the Income Tax - Itemized Deductions - Charitable Donations bill and military retirement income subtraction modification — tax-cut-oriented legislation consistent with Republican preference for tax reduction.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02', 'https://ballotpedia.org/Mike_Griffith_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Griffith / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Griffith co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Elections - In-Person Voting - Proof of Identity bill — both restrictive voting access measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Griffith / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Griffith co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Griffith / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Griffith sponsored the Juvenile Sex Offender Registry - Qualifying Offenses and Access bill expanding the registry — an enforcement-first approach to criminal justice — and sought compensation repeal for erroneously convicted persons.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Griffith / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Griffith co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act — a Republican-led redistricting reform effort opposing Democratic-drawn maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Griffith / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Griffith co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting solar farm siting — reflecting skepticism of aggressive renewable energy expansion.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Griffith / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Griffith sponsored Local School Systems - School Safety - Grant Allocations and the Juvenile Sex Offender Registry expansion — emphasizing enforcement-based public safety approaches.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Griffith / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c789b27-d50c-4822-95ff-409ecb7db08a',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Griffith's military retirement income subtraction modifications indicate support for maintaining public pension benefits for veterans — a moderate position on social support programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/griffith02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Wayne A. Hartman
-- ============================================================

-- ----- Wayne A. Hartman / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hartman co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Elections - In-Person Voting - Proof of Identity bill — both restrictive voting measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01', 'https://ballotpedia.org/Wayne_Hartman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wayne A. Hartman / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Hartman co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wayne A. Hartman / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Hartman co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act — opposing Democratic-controlled redistricting.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wayne A. Hartman / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Hartman co-sponsored the Juvenile Justice Restoration Act and First Degree Murder - Diminution Credits - Prohibition — both punishment-focused criminal justice bills.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wayne A. Hartman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hartman co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting solar farm siting and sponsored Environment - Building Energy Performance Standards - Repeal — removing building energy efficiency mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wayne A. Hartman / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Hartman sponsored Environment - Building Energy Performance Standards - Repeal — eliminating building energy efficiency standards — and opposed renewable energy mandates; strongly aligned with conventional energy interests.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wayne A. Hartman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hartman sponsored the Corporate Income Tax - Rate Reduction (Economic Competitiveness Act of 2026) and Income Tax - Standard Deduction - Alteration and Sales and Use Tax - Tax-Free Day - Veterans' Day — consistent tax-cut-focused legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wayne A. Hartman / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Hartman sponsored Environment - Building Energy Performance Standards - Repeal and Water Pollution Control - Discharge Permits - Animal Feeding Operations — both favor relaxing environmental regulations.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hartman01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kevin B. Hornberger
-- ============================================================

-- ----- Kevin B. Hornberger / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hornberger sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) — a restrictive voting access measure requiring citizenship proof.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01', 'https://ballotpedia.org/Kevin_Hornberger']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin B. Hornberger / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Hornberger sponsored the SAVE Our Elections Act requiring citizenship verification for voter registration — aligning with restrictionist immigration enforcement positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin B. Hornberger / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Hornberger sponsored the State Constitutional Convention - Question on Ballot - Passage by Majority of Votes Cast — a structural reform to change how MD constitutional amendments pass — reflecting conservative structural reform interests.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin B. Hornberger / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Hornberger sponsored the Handgun Permits - Special Endorsement for Security Clearance Holders bill — reflecting a gun rights / Second Amendment-adjacent stance consistent with conservative values on personal liberty.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin B. Hornberger / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hornberger sponsored the Homeowners' Property Tax Credit - Eligibility and Calculation Alterations and Year-Round Application bills — property tax relief focused legislation consistent with Republican tax reduction priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin B. Hornberger / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hornberger sponsored the Vehicle Laws - Vehicle Emissions Inspection Program - Modifications bill modifying emissions testing requirements — reflecting skepticism of strict environmental mandates in an Eastern Shore Republican district.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin B. Hornberger / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Hornberger sponsored the Consumer Protection - Right to Repair - Motor Vehicles and Farm Equipment bill — a rural-economy focused deregulatory measure — and other business-friendly legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin B. Hornberger / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('96a6d696-50fd-4393-a0f6-19e69dc15716',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Hornberger sponsored the Certified Peer Recovery Specialists - Coverage Under Medicaid bill — supporting addiction treatment services — indicating a moderate rather than pure punishment-only approach to criminal justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hornberger01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Thomas S. Hutchinson
-- ============================================================

-- ----- Thomas S. Hutchinson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hutchinson co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) — a restrictive voting measure requiring citizenship proof.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01', 'https://ballotpedia.org/Thomas_Hutchinson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas S. Hutchinson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hutchinson sponsored multiple healthcare bills including Health Insurance - Graduate-Level Clinical Interns Required Reimbursement and Maryland Department of Health - Hospice Room and Board Medicaid study — moderate incremental healthcare positions.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas S. Hutchinson / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Hutchinson co-sponsored the Juvenile Justice Restoration Act and the Task Force on Responsible Use of Natural Psychedelic Substances — mixed but overall tilting toward conservative criminal justice approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas S. Hutchinson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hutchinson co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting solar farm placement — reflecting skepticism of aggressive renewable mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas S. Hutchinson / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Hutchinson sponsored Water Pollution Control - Discharge Permits - Animal Feeding Operations — an agricultural-priority environmental bill — reflecting Eastern Shore rural constituents' interests over strict environmental mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas S. Hutchinson / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Hutchinson co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act opposing Democratic-drawn maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas S. Hutchinson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fb1fe811-b340-42d3-88ee-97b5364117cd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Hutchinson's Workgroup on Seafood Marketing and rural economic bills reflect support for traditional Eastern Shore industries with targeted government support.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/hutchinson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jay A. Jacobs
-- ============================================================

-- ----- Jay A. Jacobs / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Jacobs co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Elections - In-Person Voting - Proof of Identity bill — both restrictive voting access measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j', 'https://ballotpedia.org/Jay_Jacobs_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay A. Jacobs / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Jacobs co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay A. Jacobs / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Jacobs co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act — reflecting Republican opposition to Democratic-controlled redistricting in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay A. Jacobs / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Jacobs co-sponsored the Juvenile Justice Restoration Act and First Degree Murder - Diminution Credits - Prohibition — both punishment-focused criminal justice measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay A. Jacobs / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Jacobs co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting where solar farms can be built — reflecting skepticism of aggressive renewable mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay A. Jacobs / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Jacobs sponsored multiple Chesapeake Bay and oyster/shellfish management bills — the Chesapeake Bay Enhancement Program and Oysters - Rotational Harvest Pilot Program — showing moderate local environment stewardship without aggressive regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay A. Jacobs / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Jacobs sponsored the Consumer Protection - Agricultural Equipment Warranties bill and the On-Farm Organics Diversion and Recycling Grant Program — rural deregulation and agricultural business support.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay A. Jacobs / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Jacobs co-sponsored the Sales and Use Tax - Precious Metal Bullion or Coins - Exemption bill — a tax exemption measure consistent with Republican tax-reduction priorities.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jacobs%20j']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Steve Johnson
-- ============================================================

-- ----- Steve Johnson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Steve Johnson co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) requiring citizenship verification for voter registration — a restrictive voting measure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01', 'https://ballotpedia.org/Steve_Johnson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Johnson / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Johnson co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act — a Republican-backed redistricting bill aimed at reforming the Democratic-controlled redistricting process in Maryland.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Johnson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Johnson co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) — which authorizes private school scholarship granting organizations funded by tax credits.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Johnson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Johnson sponsored health-related bills focused on optometry board revisions and physician parity — procedural rather than expansionary — consistent with Republican preference for private market healthcare.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Johnson / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Johnson sponsored Criminal Law bills tightening penalties including Criminal Law - Interference of Custody Orders and Schedule III Controlled Dangerous Substances — indicating a punishment-focused approach to criminal justice.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Johnson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$As a Republican member sponsoring criminal law penalty bills and opposing major police accountability reforms Johnson emphasizes law enforcement as the primary public safety tool.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Johnson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Johnson co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill — a restrictive measure limiting solar farm siting — and has not sponsored climate action legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Johnson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dbb1c600-c87b-449c-bd3b-1c236287c00f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$As an Eastern Shore Republican Johnson opposes strict fossil fuel regulations; co-sponsoring the Solar Energy - Priority Preservation Areas bill reflects skepticism of aggressive renewable mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Andre V. Johnson, Jr.
-- ============================================================

-- ----- Andre V. Johnson, Jr. / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Johnson sponsored the Green and Renewable Energy Efficiency for Nonprofits (GREEN) Loan Program — supporting clean energy financing — and co-sponsored the Affordable Solar Act expanding solar energy access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02', 'https://ballotpedia.org/Andre_Johnson_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andre V. Johnson, Jr. / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Johnson sponsored a Maryland Energy Administration study on land-based wind energy and backed the Affordable Solar Act for solar renewable energy credits signaling preference for clean energy transition over fossil fuels.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andre V. Johnson, Jr. / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Johnson co-sponsored the Public Safety - Immigration Enforcement Agreements - Prohibition bill — opposing local police cooperation with federal immigration enforcement — indicating a pro-immigrant stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andre V. Johnson, Jr. / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Co-sponsoring legislation to prohibit immigration enforcement agreements between state/local police and ICE reflects opposition to deportation-focused enforcement policies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andre V. Johnson, Jr. / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Johnson sponsored a bill on Police Accountability investigation records and a correctional services bill on restrictive housing for intellectually disabled individuals reflecting a balanced approach to public safety reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andre V. Johnson, Jr. / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sponsoring legislation on Correctional Services - Immigration Detention Facilities and restricting housing for individuals with disabilities reflects rehabilitation-focused criminal justice values.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andre V. Johnson, Jr. / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Johnson co-sponsored the Attorney General Actions and Climate Crimes Accountability Act and backed renewable energy funding mechanisms — consistent with Democratic support for progressive taxation and public investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andre V. Johnson, Jr. / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Johnson represents a Democratic district and co-sponsored the election automation restoration bills; his broader Democratic legislative record supports expanded voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andre V. Johnson, Jr. / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Co-sponsoring the Affordable Solar Act and correctional healthcare improvements — plus Democratic caucus alignment — reflects support for expanded government healthcare coverage.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andre V. Johnson, Jr. / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b592e432-6411-48b3-bca3-d5596d0d81e9',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$As a Maryland House Democrat Johnson supports the Democratic majority's redistricting approach; his district assignment reflects legislatively drawn districts.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Frank M. Conaway, Jr.
-- ============================================================

-- ----- Frank M. Conaway, Jr. / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Conaway sponsored Criminal Law - Theft - Mail and Packages (Porch Piracy Act of 2026) adding new theft-related penalties and Criminal Procedure - Theft - Notification of Victims — a mixed enforcement and victim-rights approach rather than purely rehabilitative or punitive.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/conaway', 'https://ballotpedia.org/Frank_Conaway']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank M. Conaway, Jr. / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Conaway's primary focus on property crime enforcement (mail theft) and Law Enforcement - Use of Facial Recognition Technology regulations reflects a pragmatic public safety approach balancing enforcement with civil liberties.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/conaway']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank M. Conaway, Jr. / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Conaway sponsored Law Enforcement - Use of Facial Recognition Technology - Images Captured in Dwelling Interior — limiting surveillance technology — reflecting civil liberties concerns consistent with Democratic civil rights values.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/conaway']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank M. Conaway, Jr. / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Conaway sponsored Real Property - Wrongful Detainer Actions bills protecting tenants and Real Property - Actions for Wrongful Detainer - Required Postings — tenant-protective housing legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/conaway']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank M. Conaway, Jr. / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Conaway as a Baltimore City Democrat represents a majority-Black district and has consistently supported expanded voting access in alignment with his Democratic caucus.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/conaway']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank M. Conaway, Jr. / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Conaway sponsored Correctional Services - Incarcerated Individuals - Menstrual Hygiene bill ensuring basic healthcare for incarcerated women — and the Family and Law Enforcement Protection Act.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/conaway']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank M. Conaway, Jr. / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94855fb3-0e08-45ac-8c67-ba668ef67c4b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Conaway sponsored the County Boards of Education - College Preparatory Programs - Fees bill reducing financial barriers to education — aligned with Democratic support for educational access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/conaway']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Lesley J. Lopez
-- ============================================================

-- ----- Lesley J. Lopez / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Lopez sponsored Hospitals - Emergency Pregnancy-Related Medical Conditions - Procedures (protecting emergency abortion access) and Public Health and Health Insurance - Access to Abortion Care - Reporting Requirements — strongly pro-abortion access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01', 'https://ballotpedia.org/Lesley_Lopez_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lopez sponsored Public Health - Pregnancy Loss - Prohibited Actions (Pregnancy Outcome Protection Act) and Health Occupations - Pharmacists - Vaccination Orders expanding pharmacy-administered vaccines — supporting expanded healthcare access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Lopez sponsored the Maryland Enforcement Limits and Transparency (MELT) Act — a bill limiting state agency cooperation with federal immigration enforcement — a pro-immigrant stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$The MELT Act and similar Lopez-sponsored legislation signal opposition to mass deportation and ICE cooperation by state agencies.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Lopez sponsored the Voting Rights Act of 2026 - Counties and Municipal Corporations — a broad voting rights expansion protecting minority voters from discriminatory local election practices.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Lopez sponsored the Center for Firearm Violence Prevention and Intervention Resources bill — a public health approach to gun violence prevention rather than solely policing.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lopez sponsored State Government - Procedures - Permitting Efficiency for Housing Development Projects — supporting housing development streamlining to address affordability.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lopez's sponsorship of the Maryland Enforcement Limits Act and Voting Rights Act reflect alignment with Democratic progressives who support robust public investment funded by progressive taxation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Lopez sponsored Maryland Medical Assistance Program - Provider Agencies - Wages and Leave for Personal Care Aides — expanding Medicaid-funded worker benefits in long-term care.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Lopez sponsored the Employment Discrimination - Caregiver Status bill protecting caregivers from employment discrimination — expanding civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lesley J. Lopez / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fa68ca4-00b5-4518-a692-d12447d7fec3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lopez sponsored the State Assistance for the Elderly - Study on Calculation of Income and senior care bills — supporting public investment in care infrastructure.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/lopez01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Susan K. McComas
-- ============================================================

-- ----- Susan K. McComas / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$McComas sponsored Public Health - Abortion - Informed Consent legislation adding disclosure requirements before abortion procedures — a restrictivist approach to reproductive rights.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas', 'https://ballotpedia.org/Susan_McComas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan K. McComas / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$McComas sponsored both the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Elections - In-Person Voting - Proof of Identity bill — both restrictive voting access measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan K. McComas / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$McComas co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan K. McComas / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$McComas sponsored health insurance bills covering scalp cooling systems and a women's health care data report — bipartisan procedural measures suggesting moderate rather than strongly anti-government approach to healthcare.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan K. McComas / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$McComas sponsored the Juvenile Justice Restoration Act — a Republican bill restoring more punitive juvenile sentencing — and Criminal Law - Benefits Exploitation indicating punishment-focused criminal justice values.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan K. McComas / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$McComas co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act — reflecting Republican opposition to Maryland's Democratic-drawn congressional map.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan K. McComas / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McComas co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting solar farm placement — reflecting skepticism of aggressive renewable energy mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan K. McComas / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$McComas sponsored the Election Law - Candidate Truthfulness - Oath bill addressing political honesty — procedural rather than structural campaign finance reform suggesting a moderate position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susan K. McComas / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('58d0ff82-631f-475f-889a-9a4ebb39fc07',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McComas co-sponsored the SAVE Our Elections Act requiring citizenship verification — aligning with restrictionist immigration enforcement values.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccomas']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Teresa E. Reilly
-- ============================================================

-- ----- Teresa E. Reilly / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Reilly co-sponsored the Election Law - Voter Registration Eligibility - U.S. Citizenship Verification (SAVE Our Elections Act of 2026) and the Elections - In-Person Voting - Proof of Identity bill — both restrictive voting access measures.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01', 'https://ballotpedia.org/Teresa_Reilly_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa E. Reilly / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Reilly co-sponsored the Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act) supporting tax-credit-funded private school scholarships.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa E. Reilly / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Reilly co-sponsored the Solar Energy - Construction of Generating Stations in Priority Preservation Areas and Study bill restricting solar farm placement — and sponsored Public Utilities - Energy Generation and Transmission reflecting skepticism of aggressive clean energy mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa E. Reilly / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Reilly sponsored Public Utilities - Energy Generation and Transmission — focused on existing energy infrastructure — consistent with Eastern Shore Republican support for conventional energy production.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa E. Reilly / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Reilly co-sponsored the Legislative and Congressional Redistricting - Fair Districts for Maryland Act — a Republican redistricting reform opposing Democratic-drawn maps.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa E. Reilly / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Reilly co-sponsored the Juvenile Justice Restoration Act — a Republican-led bill seeking more punitive juvenile sentencing — indicating a punishment-focused approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa E. Reilly / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Reilly co-sponsored Health Insurance - Scalp Cooling Systems - Required Coverage (insurance mandate) and Maryland Medical Assistance Program - Orthoses/Prostheses coverage — bipartisan healthcare access bills suggesting moderate position.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa E. Reilly / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('547841f2-3476-4e83-9344-0cac984d44e8',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Reilly sponsored Water Pollution Control - Discharge Permits - Animal Feeding Operations — an agricultural-leaning environmental bill that softens discharge rules — reflecting rural Eastern Shore priorities over aggressive local environmental regulation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/reilly01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Sheree Sample-Hughes
-- ============================================================

-- ----- Sheree Sample-Hughes / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sample-Hughes sponsored Maryland Medical Assistance Program - Psychiatric Rehabilitation Program Services - Reimbursement (Youth Psychiatric Rehabilitation Parity Act of 2026) expanding Medicaid mental health coverage for youth.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01', 'https://ballotpedia.org/Sheree_Sample-Hughes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Sample-Hughes sponsored Nursing Homes and Assisted Living Facilities - Notification of Investigations and Health Care Quality Improvement Initiative — protecting Medicaid recipients in long-term care.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sample-Hughes sponsored the Election Law - Individuals Released From State Correctional Facilities - Automatic Restoration of Voter Registration — expanding voting rights to formerly incarcerated individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sample-Hughes sponsored the Maryland Use of Force Statute - Failure to Prevent Excessive Force or Render First Aid - Misdemeanor — a police accountability measure prioritizing community safety reform.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sample-Hughes co-sponsored the Consumer Goods - Restrictions Based on Energy Source - Prohibition (Energy Equality Act) and supported public assistance programs; her voting record reflects broad Democratic support for immigration pathways.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sample-Hughes voted with the Democratic majority on climate legislation; as Speaker Pro Tem she is aligned with the House Democratic climate agenda supporting clean energy transition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sample-Hughes sponsored the Correctional Services - Incarcerated Individuals - Identification Cards and the Division of Correction - Volunteer Services Program — supporting reentry and rehabilitation for incarcerated individuals.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$As a House Democrat and Speaker Pro Tem Sample-Hughes has consistently opposed school voucher legislation; her caucus position and sponsorship of public education bills reflects opposition to private school diversion of public funds.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sample-Hughes sponsored the County Boards of Education - Student Transportation - Sunset Repeal and Study and supports public education access — consistent with Democratic support for childcare and pre-K investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Sample-Hughes as a Maryland House Democrat and Speaker Pro Tem supported the 2022 expanded abortion access legislation; her Democratic leadership position is strongly pro-abortion access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sample-Hughes sponsored the Economic Development - Rural Readiness Program and Rural Maryland Capacity Building Fund - Establishment — targeted public investment in rural Eastern Shore economic development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$As a Democratic House leader Sample-Hughes is aligned with the MD Democratic caucus position supporting transgender inclusion in sports with guidelines.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sample-Hughes sponsored the State Government - Henrietta Lacks Commission - Establishment — a civil rights and racial justice focused bill — reflecting strong commitment to civil rights protections.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sheree Sample-Hughes / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a1c2b55c-df7d-487c-ad90-7f7e2c2e6951',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sample-Hughes's focus on community development and rural economic programs reflects support for affordable housing investment in the Eastern Shore.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/sample01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Melissa Wells
-- ============================================================

-- ----- Melissa Wells / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Wells co-sponsored the Public Safety - Immigration Enforcement Agreements - Prohibition bill banning local police cooperation with ICE — a sanctuary-aligned immigration stance.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02', 'https://ballotpedia.org/Melissa_Wells_(Maryland)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melissa Wells / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Wells sponsored the Election Law - Individuals Released From State Correctional Facilities - Automatic Restoration of Voter Registration and the Election Law - Curbside Voting - Pilot Program — strongly pro-expanded voting access.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melissa Wells / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Wells sponsored the Correctional Services - Private Detention Facilities - Zoning Requirement and the Incarcerated Individual Apprenticeship Pilot Program — rehabilitation and reentry focused criminal justice approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melissa Wells / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wells sponsored the State Center - Development - Contract and Plan Requirements bill and Public Works Contracts - Apprenticeship Requirements — supporting workforce and affordable housing development in Baltimore.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melissa Wells / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wells sponsored the Public Health - Baltimore City Mobile Infant and Maternal Health Pilot Program — a maternal health public investment initiative — and co-sponsored Public Safety - Immigration Enforcement Agreements Prohibition.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melissa Wells / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Wells sponsored the Child Care Scholarship Program - Freeze in Enrollment - Exceptions and Waitlist bill protecting access to subsidized childcare for low-income families.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melissa Wells / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Wells co-sponsored the Election Districts - General Assembly and Representatives in Congress bill — participating in Democratic-led redistricting supporting the majority's map.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melissa Wells / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wells sponsored the State Government - Henrietta Lacks Commission - Establishment and Commission on the House of Reformation and Instruction for Colored Children — racial justice and civil rights focused legislation.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melissa Wells / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Wells sponsored University of Maryland Eastern Shore - Land-Grant Institution - Funding (Land-Grant Equity and Accountability Act) and the Maryland Transit Administration - Fifth Bus Division Facility Construction — public investment in economic development.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melissa Wells / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7217c1b4-6fae-447d-9566-f2513319fa94',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Wells as a Baltimore City Democrat consistently opposes school voucher programs and has sponsored public education access bills.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wells02']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Greg Wims
-- ============================================================

-- ----- Greg Wims / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Wims co-sponsored the Voting Rights Act of 2026 - Counties and Municipal Corporations — expanding voting rights protections against discriminatory local election practices.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wims01', 'https://ballotpedia.org/Greg_Wims']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Wims / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Wims sponsored the Concentration of Poverty School Grant Program - Personnel and Per Pupil Grants bill and Education - Minimum Wage for Education Support Professionals — strong support for public education funding.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wims01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Wims / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wims sponsored the Department of Housing and Community Development - Appraisal Gap From Historic Redlining Financial Assistance Program — addressing housing inequality through targeted public investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wims01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Wims / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Wims sponsored the Commercial Law - Broadband Access - Low-Income Consumer Programs (Maryland Broadband Opportunity and Fairness Act) and the Maryland Technology Development Corporation - Long COVID Innovation Grant Program — targeted public investment in economic opportunity.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wims01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Wims / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Wims sponsored Public Safety - Law Enforcement Officers - Prohibition on Face Coverings — a civil liberties-adjacent public safety bill — and his broader Democratic record prioritizes community investment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wims01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Wims / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Wims's sponsorship of incarcerated individual identification and voting rights restoration bills reflects a rehabilitation-first criminal justice approach.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wims01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Wims / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Wims sponsored the State Procurement - Constitutional Violations - Prohibited bill — addressing government accountability — and aligned with Democratic support for progressive taxation to fund public programs.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wims01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Wims / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wims co-sponsored the Voting Rights Act of 2026 and the State Government - Henrietta Lacks Commission establishing a racial equity commission — strong civil rights commitment.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wims01']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Wims / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7e2aa8f-a301-4004-81e9-d1f857c81075',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wims co-sponsored Health Insurance - Scalp Cooling Systems - Required Coverage and Maryland Department of Health - Workgroup on Home- and Community-Based Services — expanding healthcare coverage mandates.$$,
        ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/wims01']::text[]::text[])
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
-- WHERE p.id IN ('b592e432-6411-48b3-bca3-d5596d0d81e9', 'dbb1c600-c87b-449c-bd3b-1c236287c00f', '58d0ff82-631f-475f-889a-9a4ebb39fc07', '0c789b27-d50c-4822-95ff-409ecb7db08a', '547841f2-3476-4e83-9344-0cac984d44e8', '96a6d696-50fd-4393-a0f6-19e69dc15716', 'fee8a413-a3a8-4568-ad9b-db00f94f5ac2', 'eca530ff-628d-417d-a3dc-b858dc7c2376', '8b43dd9c-26c3-48bb-ac60-d95f8a39349a', 'a1c2b55c-df7d-487c-ad90-7f7e2c2e6951', '1eada938-f28c-46b9-bd21-df241656cd2b', 'fb1fe811-b340-42d3-88ee-97b5364117cd', 'd17104a7-8a35-4bcd-8879-76ceb997df6a', 'bc7ee014-a452-4eaf-81e9-2f4c55d3eaea', '1ff2bb96-0e55-4893-8a4c-b675dfbb79f6', 'e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820', '2fa68ca4-00b5-4518-a692-d12447d7fec3', 'b7e2aa8f-a301-4004-81e9-d1f857c81075', '62bed8b6-beb2-4c41-b234-dc6427bfc9c0', '94855fb3-0e08-45ac-8c67-ba668ef67c4b', '7217c1b4-6fae-447d-9566-f2513319fa94')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('b592e432-6411-48b3-bca3-d5596d0d81e9', 'dbb1c600-c87b-449c-bd3b-1c236287c00f', '58d0ff82-631f-475f-889a-9a4ebb39fc07', '0c789b27-d50c-4822-95ff-409ecb7db08a', '547841f2-3476-4e83-9344-0cac984d44e8', '96a6d696-50fd-4393-a0f6-19e69dc15716', 'fee8a413-a3a8-4568-ad9b-db00f94f5ac2', 'eca530ff-628d-417d-a3dc-b858dc7c2376', '8b43dd9c-26c3-48bb-ac60-d95f8a39349a', 'a1c2b55c-df7d-487c-ad90-7f7e2c2e6951', '1eada938-f28c-46b9-bd21-df241656cd2b', 'fb1fe811-b340-42d3-88ee-97b5364117cd', 'd17104a7-8a35-4bcd-8879-76ceb997df6a', 'bc7ee014-a452-4eaf-81e9-2f4c55d3eaea', '1ff2bb96-0e55-4893-8a4c-b675dfbb79f6', 'e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820', '2fa68ca4-00b5-4518-a692-d12447d7fec3', 'b7e2aa8f-a301-4004-81e9-d1f857c81075', '62bed8b6-beb2-4c41-b234-dc6427bfc9c0', '94855fb3-0e08-45ac-8c67-ba668ef67c4b', '7217c1b4-6fae-447d-9566-f2513319fa94')
--   AND pc.politician_id IS NULL;