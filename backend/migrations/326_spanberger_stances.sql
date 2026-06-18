-- ============================================================================
-- Migration 326: Abigail Spanberger Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Abigail Spanberger (Governor of Virginia).
--
-- Topic scope: All 44 compass topics attempted; evidence-only — topics with no
--   evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production per CLAUDE.md).
--
-- Sources policy: aggregation indexes only (ballotpedia, ontheissues, vpap, congress.gov).
--   No politician press-release URLs — slugs cannot be verified without fetching.
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
-- Abigail Spanberger
-- ============================================================

-- ----- Abigail Spanberger / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Spanberger has been a consistent defender of abortion rights throughout her career. As a Congresswoman she voted for the Women's Health Protection Act (2021, 2022), which would have codified Roe v. Wade protections, and earned 100% ratings from NARAL Pro-Choice America and Planned Parenthood Action Fund. Upon winning the Virginia governorship in 2025, she pledged to restore abortion access protections in Virginia and protect providers from out-of-state prosecution.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm',
              'https://www.vpap.org/candidates/75011/candidate_bio/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Spanberger co-sponsored the AI Accountability Act (H.R. 4278, 2023) in the House, which required federal agencies to publish AI impact assessments and transparency reports. She also supported the DEEPFAKES Accountability Act to require disclosure of synthetic media. Her overall posture favors proactive regulatory guardrails on AI while allowing continued innovation.$$,
        ARRAY['https://www.congress.gov/bill/118th-congress/house-bill/4278',
              'https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Anti-corruption was one of Spanberger's defining issues from her first campaign in 2018. She was a co-sponsor of the DISCLOSE Act, which would have required dark money political organizations to disclose their donors. She also co-sponsored the For the People Act (H.R. 1), which included comprehensive campaign finance reform, and consistently called out dark money in politics.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Spanberger consistently supported expanding childcare access as a Congresswoman. She backed the Child Care and Development Block Grant reauthorization and supported Build Back Better provisions that would have capped childcare costs at 7% of family income. She co-sponsored the Child Care Access Means Parents in School (CCAMPIS) Act and highlighted childcare affordability as a workforce development issue for rural Virginia families.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Spanberger voted for the George Floyd Justice in Policing Act (2021), which would have established a national standard for police use of force and required data collection on police encounters. She voted for the Equality Act to extend civil rights protections to LGBTQ+ Americans in employment, housing, and public accommodations. She also supported the John Lewis Voting Rights Advancement Act and the reauthorization of the Violence Against Women Act.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Spanberger voted for the Inflation Reduction Act (2022), the largest federal climate investment in U.S. history, which she highlighted for its clean energy tax credits beneficial to rural Virginia. She supported clean energy provisions of the bipartisan Infrastructure Investment and Jobs Act. As a gubernatorial candidate in 2025, she backed Virginia's clean energy transition while emphasizing energy affordability and Virginia's clean energy job growth.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm',
              'https://www.vpap.org/candidates/75011/candidate_bio/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$During the 2025 Virginia gubernatorial race, Spanberger acknowledged Virginia's dominance as the global data center hub while calling for stricter environmental review of new data center projects, particularly regarding energy consumption and water use. She supported continued data center economic development but pushed for accountability mechanisms and environmental standards, placing her in a balanced position favoring development with guardrails rather than restriction or unchecked expansion.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://www.vpap.org/candidates/75011/candidate_bio/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$As a former CIA officer, Spanberger supported targeted enforcement against individuals who pose public safety risks while consistently opposing mass deportation programs that separate families and disrupt communities. She voted for the American Dream and Promise Act and opposed legislation she viewed as criminalizing all undocumented immigrants. Her national-security-informed moderate position: enforce against criminal threats, protect law-abiding immigrants.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Economic development for rural and suburban Virginia was a core Spanberger priority. She championed rural broadband expansion, agricultural support, and small business access to capital. She voted for the bipartisan Infrastructure Investment and Jobs Act, highlighting its benefits for Virginia's roads, bridges, and broadband. She co-founded the bipartisan Rural Broadband Caucus and worked on USDA rural development funding.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Spanberger supported the Inflation Reduction Act's clean energy investments while opposing immediate bans on fossil fuels that she argued would harm rural Virginia workers and communities. She represented a district with natural gas infrastructure and agricultural energy users, leading her to advocate for a managed transition away from fossil fuels rather than immediate elimination. She did not co-sponsor legislation for immediate fossil fuel bans.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Spanberger represented a rapidly growing suburban-rural district in central Virginia and supported managed growth with investment in infrastructure. She backed the bipartisan infrastructure law's transportation and water infrastructure provisions and advocated for VDOT funding for her district. As a gubernatorial candidate, she prioritized economic growth across the commonwealth while ensuring communities had planning tools and resources to manage development responsibly.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm',
              'https://www.vpap.org/candidates/75011/candidate_bio/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Spanberger was an outspoken defender of the Affordable Care Act throughout her congressional tenure, having campaigned in 2018 partly on protecting people with pre-existing conditions. She voted for the Inflation Reduction Act provisions capping insulin at $35/month for Medicare patients and extending ACA subsidies. She co-sponsored legislation to lower prescription drug prices and opposed Republican efforts to repeal the ACA.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Spanberger supported increased HUD funding for homeless assistance grants and backed veteran homelessness programs including the HUD-VASH program. She co-sponsored the Ending Homelessness Act, which aimed to fully fund the federal homelessness assistance system. Her approach emphasized housing-first strategies and mental health and substance abuse services for homeless populations.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Spanberger consistently backed evidence-based, housing-first approaches to homelessness, supporting federal funding for rapid rehousing and permanent supportive housing over punitive enforcement-only approaches. She voted for appropriations that increased Continuum of Care funding and backed mental health and substance use disorder treatment as integral components of homelessness response.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Spanberger co-sponsored the First-Generation Down Payment Assistance Act and the Housing is Infrastructure Act, and supported the HOME Investment Partnerships Program expansion. She emphasized affordable housing for rural Virginia in the context of the infrastructure law. During her 2025 gubernatorial campaign, housing affordability was a major platform plank with proposals to expand homeownership assistance and increase housing supply through state incentives.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm',
              'https://www.vpap.org/candidates/75011/candidate_bio/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$As a former CIA officer, Spanberger took a security-informed but humanitarian approach to immigration. She voted for the American Dream and Promise Act (2021) to provide a path to citizenship for DACA recipients and TPS holders, and supported the Farm Workforce Modernization Act to protect agricultural guest workers vital to Virginia agriculture. She opposed family separation policies and mass deportation while also supporting border security investment.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Spanberger supported funding for the Legal Services Corporation, which provides civil legal aid to low-income Americans, and opposed LSC funding cuts proposed by the Trump administration. She backed the Violence Against Women Act reauthorization which expanded legal resources for survivors. Her broader civil rights voting record reflected support for expanding access to the courts for marginalized populations.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Spanberger voted for the George Floyd Justice in Policing Act (2021) and supported the First Step Act's sentencing reform provisions. She backed legislation reducing mandatory minimums for non-violent drug offenses and supported second-chance reentry programs. While opposing defund-the-police rhetoric, she supported evidence-based criminal justice reforms aimed at reducing incarceration for non-violent offenders and addressing racial disparities in the justice system.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Spanberger voted for the George Floyd Justice in Policing Act, which would have banned chokeholds, required body cameras, ended qualified immunity for law enforcement officers, and created a national registry of police misconduct. She distinguished between supporting law enforcement broadly and holding specific officers accountable for misconduct — opposing defund the police while backing accountability reforms that she argued would strengthen public trust.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Spanberger voted for the Inflation Reduction Act provision allowing Medicare to negotiate prescription drug prices directly — a major expansion of Medicare's role she had championed for years. She co-sponsored legislation to cap insulin prices and supported the IRA's $35/month Medicare insulin cap. She consistently opposed cuts to Medicare and Medicaid, and supported Medicaid expansion in Virginia. As Governor, she has pledged to protect Medicaid and oppose federal cuts.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Spanberger co-sponsored the Honest Ads Act, which would require online political ads to disclose their funders in the same way broadcast political ads must. She spoke out against COVID-19 misinformation and foreign disinformation campaigns. As a former intelligence officer, she repeatedly highlighted disinformation threats to democratic institutions, supporting platform accountability measures and transparency requirements for political advertising.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Spanberger explicitly opposed the defund the police movement and publicly called out this messaging as harmful to Democratic candidates in the 2020 post-election period. She supported law enforcement funding while also backing community violence intervention programs and mental health crisis response teams as complements to traditional policing. Her approach is moderate — investing in both law enforcement and prevention and intervention programs rather than prioritizing one exclusively.$$,
        ARRAY['https://www.politico.com/news/2020/11/06/spanberger-democrats-defund-the-police-434641',
              'https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Spanberger was a strong supporter of independent redistricting and election integrity reforms. She voted for the For the People Act (H.R. 1), which included provisions requiring independent redistricting commissions for congressional districts to end partisan gerrymandering. She highlighted redistricting as a democracy protection issue and supported Virginia's 2020 constitutional amendment creating an independent redistricting commission.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Spanberger voted for the Respect for Marriage Act (2022), which protects same-sex and interracial marriages at the federal level while including conscience protections allowing religious organizations not to perform or recognize such marriages. She has spoken about her own Catholic faith while supporting LGBTQ+ rights, reflecting a moderate position that balances both religious liberty interests and civil rights protections rather than prioritizing one absolutely over the other.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Spanberger voted for the Respect for Marriage Act in December 2022, which provides federal statutory protections for same-sex and interracial marriages by requiring the federal government and states to recognize lawful marriages regardless of the couples' sex or race. She has consistently supported LGBTQ+ equality in her voting record, including voting for the Equality Act, and has stated that she believes in dignity and equal rights for all families.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Spanberger has consistently opposed large-scale federal school voucher programs that divert public school funding to private schools. She voted against the Education Freedom Scholarships and Opportunities Act and supported increased funding for public K-12 education. As Governor, she has emphasized investment in public schools rather than voucher expansion, opposing prior Governor Youngkin's school choice initiatives that redirected public school funding.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm',
              'https://www.vpap.org/candidates/75011/candidate_bio/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Spanberger signed onto the Social Security 2100 Act, which would expand Social Security benefits and ensure the program's solvency by lifting the payroll tax cap on high earners. She voted against any reductions to Social Security benefits and consistently opposed proposals to privatize or cut the program. As Governor, she has spoken out against federal proposals to cut Social Security, pledging to protect Virginian seniors.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Spanberger took a nuanced stance on tariffs, supporting some targeted tariffs on goods from adversarial nations like China on national security grounds while expressing concern about broad, blanket tariffs that hurt Virginia farmers and manufacturers. She was critical of the Trump administration's tariff approach as harmful to agricultural exports from Virginia-7. As Governor, she has warned about the economic impact of broad tariffs on Virginia's agricultural and manufacturing sectors.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Spanberger voted for the Inflation Reduction Act's tax provisions including clean energy tax credits and a 15% corporate minimum tax. She opposed the 2017 Tax Cuts and Jobs Act, which she argued favored the wealthy and corporations over middle-class families. She consistently supported raising taxes on high earners to fund public investment while protecting tax cuts for middle-income households and small businesses in her district.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Spanberger voted for and championed the bipartisan Infrastructure Investment and Jobs Act (2021), emphasizing its benefits for Virginia roads, bridges, rail, and broadband. She co-founded the bipartisan Rural Broadband Caucus. She supported Amtrak funding expansion to serve rural communities in Virginia and advocated for VDOT projects in her district. Her transportation priorities focused on multi-modal investments including roads, rail, and broadband for rural connectivity.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '24e9212c-b011-422a-865c-093e35050901',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        '24e9212c-b011-422a-865c-093e35050901',
        $$As a former CIA officer with extensive national security experience, Spanberger was among the strongest supporters of Ukraine aid in the House. She voted for every major Ukraine supplemental funding package, including the April 2024 $95 billion national security supplemental. She consistently framed Ukraine support as a core U.S. national security interest and argued that abandoning Ukraine would embolden authoritarian aggression globally.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abigail Spanberger / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Spanberger voted for the John Lewis Voting Rights Advancement Act, which would restore and strengthen the Voting Rights Act of 1965 by updating the formula for federal preclearance of state election law changes. She voted for the Freedom to Vote Act, which would establish national standards for early voting, mail-in voting, and voter registration. She consistently opposed voter suppression legislation and supported election security measures against foreign interference.$$,
        ARRAY['https://ballotpedia.org/Abigail_Spanberger',
              'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 32 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have >= 1 URL):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
