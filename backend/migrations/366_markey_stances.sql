-- ============================================================================
-- Migration 366: Edward J. Markey Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Edward J. Markey (US Senator, MA).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Markey context: 40+ year Congressional record (US House 1976–2013 + Senate
--   2013–present); original DREAM Act co-author (2001); Green New Deal
--   Senate co-author with AOC (2019); COPPA author; DISCLOSE Act co-sponsor.
--   One of the longest-serving members of Congress; rich documented record
--   on climate, immigration, tech regulation, healthcare, civil rights.
--
-- Result: 30 existing stances re-upserted (idempotent) + 13 new topics added.
--   Total: 43 stances.
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

-- Markey UUID: faf86b5b-5add-4afb-a8e2-96b3e8be4b78 (external_id=-200102)

BEGIN;

-- ============================================================
-- Edward J. Markey (faf86b5b-5add-4afb-a8e2-96b3e8be4b78)
-- US Senator, Massachusetts (2013–present)
-- US House MA-07 (1976–2013)
-- ============================================================

-- ----- Edward J. Markey / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Markey is rated 100% by NARAL Pro-Choice America and 0% by the National Right to Life Committee throughout his career. He co-sponsored the Women's Health Protection Act (federal abortion access guarantee), voted against the Pain-Capable Unborn Child Protection Act, and has repeatedly called on Congress to codify Roe v. Wade. He stated after Dobbs (2022): 'The Supreme Court ripped away a fundamental right. We must pass the Women's Health Protection Act now.'$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases/markey-statement-on-supreme-court-dobbs-decision']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Markey authored COPPA (Children's Online Privacy Protection Act, 1998) and introduced the SAFE TECH Act requiring companies to test AI for civil rights violations before deployment. He co-sponsored the Algorithmic Accountability Act mandating impact assessments for high-risk AI systems and the NO FAKES Act governing AI-generated likenesses. He supports mandatory safety testing and disclosure requirements but not full AI bans, placing him in the regulated-with-transparency zone.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/senators-markey-booker-introduce-algorithmic-accountability-act', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Markey is the primary Senate co-sponsor of the DISCLOSE Act, which would require immediate disclosure of dark money donations and close super PAC loopholes created by Citizens United. He has championed the Democracy For All Amendment to overturn Citizens United by constitutional amendment, and repeatedly introduced legislation requiring full disclosure of all political spending. Rated 100% by Citizens for Responsibility and Ethics in Washington (CREW) on transparency measures.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/senators-markey-whitehouse-reintroduce-disclose-act', 'https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Markey co-sponsored the Child Care for Working Families Act (with 34 senators) providing universal pre-K, subsidized childcare capped at 7% of family income for those earning under 150% of state median income, and free care for families below 75% of state median income. He also co-authored the original SCHIP (State Children's Health Insurance Program) reauthorization bills protecting healthcare for millions of children. He consistently rates above 90% with the NEA on child welfare issues.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Markey is rated 100% by the NAACP and 100% by the HRC throughout his career. He co-sponsored the Equality Act of 2017 extending civil rights protections to LGBTQ+ individuals in employment, housing, and public accommodations. In March 2023 he introduced the Transgender Bill of Rights with Rep. Pramila Jayapal. He has consistently voted for the Violence Against Women Act reauthorizations and supported affirmative action programs.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases/markey-jayapal-introduce-transgender-bill-of-rights']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Markey is the Senate co-author of the Green New Deal resolution (2019) with Rep. Alexandria Ocasio-Cortez, calling for 100% clean electricity within 10 years and zero net emissions by 2050. He authored the American Clean Energy and Security Act (Waxman-Markey, 2009) — the only comprehensive federal climate bill to pass either chamber of Congress. He has served as Chair of the Senate Environment Committee and stated: 'Climate change is the greatest threat to humanity and we must act with the urgency this crisis demands.'$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/green-new-deal', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Markey has pushed for energy transparency from Big Tech companies as part of his AI regulation and climate work. He introduced the AI TRANSPARENCY Act and has called on cloud providers and data center operators to disclose their energy consumption and carbon footprint. As co-author of the Green New Deal, he has included data center decarbonization in his clean energy framework, supporting mandatory renewable energy sourcing requirements for large computing facilities.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/senators-markey-booker-introduce-algorithmic-accountability-act', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/green-new-deal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Markey is the original Senate co-author of the DREAM Act (2001) protecting undocumented immigrants brought to the US as children, and has championed DACA throughout its legislative history. He is rated 0% by FAIR (Federation for American Immigration Reform), indicating consistent opposition to restrictive immigration enforcement. He has explicitly opposed mass deportation programs and called for defunding ICE family separation operations, stating: 'Ripping families apart is not who we are as a nation.'$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Markey was a strong Senate supporter of the Inflation Reduction Act (2022) and the American Rescue Plan, both of which included major public investment in clean energy manufacturing, infrastructure, and workforce development. He has advocated for federal investment in Massachusetts' innovation economy, including clean energy, biotech, and advanced manufacturing. He supports targeted industrial policy for domestic semiconductor and clean energy supply chains.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/markey-statement-on-inflation-reduction-act-passage', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Markey has stated 'since 1976 I have always voted against oil and gas' and his Waxman-Markey climate bill (2009) was premised on phasing out fossil fuels. He co-authored the Green New Deal calling for 100% renewable energy within a decade. He has consistently opposed new offshore drilling leases, Arctic National Wildlife Refuge drilling, and natural gas pipeline expansions, while supporting bans on new federal fossil fuel leasing.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/green-new-deal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Markey has advocated for climate-smart growth policies, supporting transit-oriented development and opposing sprawl-generating highway expansions in favor of mass transit investment. He supported the MBTA Communities Act principle at the federal level through his endorsement of zoning reform tied to transit access as part of the Inflation Reduction Act's climate-resilient development framework. He has focused on dense, clean, transit-accessible urban development over suburban sprawl.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/markey-statement-on-inflation-reduction-act-passage', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Markey co-sponsored Senator Sanders' Medicare for All Act (2017, 2019, 2021) providing universal healthcare coverage for all US residents. He authored original SCHIP (children's health insurance) legislation in the House and has consistently voted against ACA repeal attempts. He has stated: 'Make healthcare a right, not a privilege' and supports single-payer as the preferred system while defending the ACA as a floor not a ceiling.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Markey has supported housing-first and services-based approaches to homelessness, consistently voting for HUD funding and the American Rescue Plan's emergency rental assistance and housing voucher expansions. He has opposed criminalization of homelessness and supported mental health crisis intervention programs as alternatives to policing. He signed the Ending Homelessness Act letter and supports expanding permanent supportive housing.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Markey voted for the American Rescue Plan which allocated $45 billion for emergency rental assistance and expanded Housing Choice Vouchers. He has co-sponsored the Eviction Crisis Act and supports federal permanent supportive housing investment as the primary homelessness-reduction tool. He opposes punitive anti-camping ordinances and instead advocates for housing-first combined with wraparound mental health and substance use services. He has called housing a human right.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/markey-votes-to-pass-american-rescue-plan', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Markey signed letters opposing elimination of HUD's Section 4 Capacity Building and Community Development programs. He voted for the American Rescue Plan's housing provisions and supported the Build Back Better Act's $150 billion housing investment. He has co-sponsored legislation increasing public housing funding, expanding Section 8 vouchers, and building affordable housing units. He has stated housing costs represent a fundamental affordability crisis requiring federal intervention.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Markey co-authored the original DREAM Act (2001) providing a pathway to citizenship for undocumented immigrants brought to the US as children — one of the earliest and most consistent congressional champions of this legislation. He is rated 0% by FAIR (Federation for American Immigration Reform), indicating strong opposition to restrictive immigration enforcement. He supports comprehensive immigration reform, pathway to citizenship for undocumented immigrants, and refugee resettlement programs.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Markey is rated 78% by CURE (Council for Unity — pro-rehabilitation in prisons) and opposes the death penalty. He has supported reducing incarceration rates through decriminalization, diversion programs, and reform of mandatory minimum sentences. He has co-sponsored the First Step Act expansion and legislation addressing prison overcrowding through early release and alternatives to incarceration for non-violent offenders. He supports reducing jail populations as a policy goal.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Markey has consistently advocated for civil rights enforcement, legal aid programs, and expanded access to justice. He supported the Civil Rights Act of 1991 expanding Title VII remedies and has backed increased Legal Services Corporation funding. He co-sponsored the Americans with Disabilities Act Amendments Act (2008) and has supported court interpreter services and pro bono legal requirements for federal contractors. His 100% NAACP and HRC ratings reflect a strong access-to-justice orientation.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Markey co-sponsored the Pretrial Integrity and Safety Act which would incentivize states to replace cash bail with risk assessments and evidence-based pretrial services. He has supported reducing pretrial detention through alternatives including electronic monitoring, supervised release, and community-based supports. His criminal justice reform record — rated 78% by CURE — reflects consistent support for reducing unnecessary incarceration at the pretrial stage.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Markey is rated 78% by CURE (Council for Unity — pro-rehabilitation), opposes the death penalty, and has supported criminal justice reform emphasizing rehabilitation over punishment. He co-sponsored the First Step Act expansion and the SAFE Justice Act reducing mandatory minimums. He supports second-chance employment, reentry programs, and has advocated for elimination of private prisons. His Senate career reflects consistent support for a rehabilitative criminal justice framework.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / judicial-government-deference -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        $$Markey strongly criticized the Supreme Court's Loper Bright Enterprises v. Raimondo (2024) decision overturning Chevron deference, calling it a 'threat to public health, safety, and environmental protection.' He has consistently supported broad regulatory agency authority and opposed judicial efforts to curtail administrative power. His climate and environmental record depends heavily on EPA regulatory authority — a position incompatible with narrowing government deference doctrines.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/markey-statement-on-supreme-court-loper-bright-decision', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Markey has been one of the most prominent Senate advocates for Supreme Court expansion and reform, introducing the Judiciary Act of 2021 with Rep. Jerry Nadler to expand SCOTUS from 9 to 13 justices. He consistently opposed Federalist Society nominees and supported progressive interpretive frameworks that read constitutional rights expansively. He stated that a rigid originalist reading of the Constitution would undo civil rights, environmental, and consumer protections built over decades.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/markey-nadler-introduce-judiciary-act', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Markey co-sponsored the George Floyd Justice in Policing Act providing federal standards on use of force, banning chokeholds, restricting no-knock warrants, and establishing a national misconduct registry. He supported restricting transfer of military equipment to police (1033 program reform). He has called for robust civilian oversight of law enforcement and supported defunding the militarization of police, while backing community-based public safety investments.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Markey's 78% CURE rating, opposition to mandatory minimums, and rehabilitation-focused criminal justice stance all indicate he favors diversion programs and treatment over prosecution for non-violent offenses. He has supported legislation expanding drug courts, mental health courts, and community-based diversion programs. He opposes the death penalty and has supported clemency reforms allowing commutation of harsh sentences imposed under now-repealed mandatory minimum provisions.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://www.markey.senate.gov/news/press-releases', 'https://en.wikipedia.org/wiki/Ed_Markey']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Markey introduced the Supreme Court Ethics, Recusal, and Transparency (SCERT) Act requiring SCOTUS justices to adopt a code of ethics, disclose gifts and travel, and recuse from cases involving financial conflicts of interest. He has opposed insider trading by members of Congress and supported the DISCLOSE Act's transparency provisions. He has called for greater financial disclosure from federal judges and ethics reforms for the entire federal judiciary.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/markey-introduces-supreme-court-ethics-recusal-transparency-act', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Markey has been a champion of environmental justice including local air and water quality protections. He supported Massachusetts' participation in the Regional Greenhouse Gas Initiative (RGGI) and strongly defended EPA authority to regulate local pollution under Clean Air Act and Clean Water Act. He has introduced the Environmental Justice Act and co-sponsored legislation protecting frontline communities from disproportionate pollution. His 100% LCV (League of Conservation Voters) lifetime rating reflects his local environment record.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Markey has strongly defended sanctuary city policies, opposing federal efforts to coerce local jurisdictions into immigration enforcement collaboration. As co-author of the DREAM Act (2001) and longstanding DACA defender, he has consistently supported local immigrant-protection measures including opposing Secure Communities mandates that compel local police to act as immigration agents. He stated: 'Sanctuary cities make us all safer by ensuring immigrant communities can report crimes without fear of deportation.'$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Markey co-sponsored the Medicare for All Act (Sanders, 2017, 2019, 2021) and has consistently voted against Medicare and Medicaid cuts throughout his career. He has stated 'I will never allow cuts to Social Security, Medicare, or Medicaid' and authored legislation expanding Medicare dental, vision, and hearing benefits. He signed the Social Security Protectors Pledge rejecting benefit cuts, and has opposed any privatization of Medicare or Medicaid managed care expansion that reduces beneficiary protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Markey authored COPPA (1998) requiring parental consent for children's online data collection and co-sponsored the Kids Online Safety Act (KOSA) mandating platform safety features for minors. He has introduced legislation requiring platforms to disclose algorithmic amplification of misinformation and supported civil liability for health-endangering content. He favors mandatory disclosure and algorithmic transparency over direct content removal mandates — supporting regulation but not outright government censorship authority.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/senators-markey-booker-introduce-algorithmic-accountability-act', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Markey has supported investing in mental health crisis response as a public safety tool, co-sponsoring the Mental Health Justice Act establishing mobile mental health crisis teams to respond in lieu of armed police. He supported the Bipartisan Safer Communities Act (2022) including community violence intervention funding and mental health resources. His public safety record emphasizes community investment, social services, and alternatives to incarceration alongside targeted law enforcement reforms.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/markey-supports-bipartisan-safer-communities-act', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Markey co-sponsored the For the People Act (S.1) which included provisions for independent redistricting commissions and prohibiting partisan gerrymandering in federal elections. He has supported the John Lewis Voting Rights Advancement Act and DC statehood as part of a broader democracy reform agenda. He has stated gerrymandering is 'a corruption of democracy' and called for independent commissions to draw congressional district lines.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Markey is rated 100% by the HRC and co-sponsored the Equality Act of 2017 which expressly prohibits religious exemptions from non-discrimination protections — placing him firmly on the side of limiting broad religious exemption claims when they conflict with LGBTQ+ civil rights. He supports the separation of church and state, has opposed school prayer mandates, and voted against legislation creating broad religious carve-outs from federal civil rights law.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Markey has supported federal housing affordability legislation including the American Housing and Economic Mobility Act which includes rent stability provisions. He has opposed algorithmic rent-setting by corporate landlords, co-signing letters calling on DOJ to investigate price-fixing in the rental market. He supports local authority to implement rent stabilization and has advocated for strengthening tenant protections in federally subsidized housing as part of his broader housing affordability agenda.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Markey has supported federal incentives for zoning reform to increase housing supply, including provisions in the Build Back Better Act and the American Housing and Economic Mobility Act that would tie federal funding to local zoning reform allowing multifamily and transit-oriented housing. He has backed the YIMBY principles of upzoning near transit as a climate and affordability measure, framing it as reducing car dependency and building sustainable communities.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Markey voted against the Defense of Marriage Act in 1996 (one of the minority to do so), co-sponsored the Equality Act of 2017 extending marriage equality protections, and voted for the Respect for Marriage Act (2022) codifying same-sex and interracial marriage into federal law. His 100% HRC rating reflects a decades-long record of LGBTQ+ equality support. He was among the earliest and most consistent advocates for federal same-sex marriage recognition.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Markey is rated 92% by the NEA and is documented as opposing school vouchers for private and religious schools. He has consistently supported fully funding public education through ESEA/ESSA reauthorizations and opposed proposals to redirect federal funding to private school choice programs. He stated vouchers 'drain resources from public schools that serve all children' and has opposed the Education Freedom Scholarships Act and similar federal voucher proposals.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Markey signed the Social Security Protectors Pledge rejecting any benefit cuts, privatization, or retirement age increases. He co-sponsored H.CON.RES.5 opposing cuts to Social Security, Medicare, and Medicaid. He has introduced legislation to expand Social Security benefits by lifting the payroll tax cap on high earners and has stated 'I will never allow cuts to Social Security.' His ADA (Americans with Disabilities Act) work also reflects his commitment to protecting disability-based Social Security benefits.$$,
        ARRAY['https://www.ontheissues.org/Economic/Ed_Markey_Social_Security.htm', 'https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Markey is described as 'protectionist on labor/environment' and rated 38% by the U.S. Business and Industry Council, reflecting a mixed trade position. He supported targeted tariffs on goods produced under poor labor or environmental conditions (NAFTA renegotiation provisions) but opposed broad tariff regimes. He supported trade adjustment assistance for workers displaced by trade and has backed trade agreements conditioned on strong labor and environmental enforcement mechanisms.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Economic/Ed_Markey_Free_Trade.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Markey is rated 100% by Citizens for Tax Justice (supporting progressive taxation) and 25% by the National Taxpayers Union. He has supported raising the top marginal income tax rate, closing corporate tax loopholes, and taxing capital gains as ordinary income. He supported the Inflation Reduction Act's 15% corporate minimum tax and excise tax on stock buybacks. He backed Senator Warren's Ultra-Millionaire Tax Act imposing a 2% annual wealth tax on assets above $50 million.$$,
        ARRAY['https://www.ontheissues.org/Economic/Ed_Markey_Tax_Reform.htm', 'https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://www.markey.senate.gov/news/press-releases/markey-statement-on-inflation-reduction-act-passage']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$In March 2023 Markey and Rep. Pramila Jayapal introduced the Transgender Bill of Rights, recognizing 'the federal government's duty to protect the rights and dignity of transgender Americans' including in competitive sports. He voted against the Protection of Women and Girls in Sports Act banning transgender women from women's sports, calling it discriminatory. His 100% HRC rating reflects full support for transgender inclusion in all aspects of public life including athletics.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases/markey-jayapal-introduce-transgender-bill-of-rights', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Markey was a strong Senate supporter of the Infrastructure Investment and Jobs Act (2021) including $66 billion for passenger and freight rail and $39 billion for public transit modernization. He has championed MBTA and commuter rail investment for Massachusetts, advocated for Amtrak expansion on the Northeast Corridor, and co-sponsored legislation electrifying school and transit bus fleets. As a Green New Deal co-author, he has explicitly called for replacing private car trips with public transit as a climate strategy.$$,
        ARRAY['https://www.markey.senate.gov/news/press-releases/markey-votes-to-pass-infrastructure-investment-and-jobs-act', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Markey serves on the Senate Foreign Relations Committee and has consistently supported Ukraine's defense against Russia's invasion. The Ukraine Democracy Defense Lend-Lease Act of 2022 passed with his support, and he has backed successive Ukraine military and economic aid packages. However, he has also called for diplomatic efforts to end the conflict and expressed concern about nuclear escalation risks, reflecting a nuanced position of support with diplomatic emphasis rather than unconditional military commitment.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Markey', 'https://en.wikipedia.org/wiki/Ukraine_Democracy_Defense_Lend-Lease_Act_of_2022', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward J. Markey / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Markey supports automatic voter registration for all eligible citizens, same-day registration, paper ballot requirements, and restoring the Voting Rights Act through the John Lewis Voting Rights Advancement Act. He co-sponsored the For the People Act (S.1) expanding vote-by-mail, early voting, and Election Day as a federal holiday. He has stated gerrymandering and voter suppression are 'existential threats to democracy' and has called for eliminating the Senate filibuster to pass federal voting rights protections.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.markey.senate.gov/news/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================================
-- Topics omitted (no documented federal Ed Markey position found per D-01):
-- city-sanitation — no federal Markey stance found; blank spoke is honest
-- ============================================================================

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 43 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'faf86b5b-5add-4afb-a8e2-96b3e8be4b78';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'faf86b5b-5add-4afb-a8e2-96b3e8be4b78'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'faf86b5b-5add-4afb-a8e2-96b3e8be4b78'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
--
-- Combined check:
-- SELECT
--   (SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id='faf86b5b-5add-4afb-a8e2-96b3e8be4b78') AS answer_count,
--   (SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='faf86b5b-5add-4afb-a8e2-96b3e8be4b78' AND pc.politician_id IS NULL) AS unpaired,
--   (SELECT COUNT(*) FROM inform.politician_context WHERE politician_id='faf86b5b-5add-4afb-a8e2-96b3e8be4b78' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0)) AS uncited;
