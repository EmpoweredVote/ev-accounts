-- ============================================================================
-- Migration 368: Jim McGovern Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jim McGovern (US Representative, MA-02).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Supplemental: McGovern had 30 pre-existing stances from a prior session.
--   This migration re-upserts all 30 (idempotent) and adds 14 new topics.
--   city-sanitation omitted — no documented federal House record.
--   Total expected: 44 topics.
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

-- Politician UUID:
-- Jim McGovern: ee4081d5-fc3e-4a8c-b39e-481ae20135d5

BEGIN;

-- ============================================================
-- Jim McGovern (MA-02)
-- ============================================================

-- ----- Jim McGovern / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$McGovern has a 100% NARAL Pro-Choice America rating and has stated he believes people should have access to safe and legal abortion. He voted YES on the Women's Health Protection Act and opposed the Stupak-Pitts Amendment. He is one of Congress's strongest defenders of abortion rights without restriction.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://ballotpedia.org/Jim_McGovern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$McGovern opposes unregulated government use of facial recognition due to "algorithmic bias, especially against communities of color." He has introduced the Facial Recognition and Biometric Technology Moratorium Act and opposed deployment of AI surveillance systems without safeguards. His tech regulation positions favor strong civil liberties protections over unfettered AI deployment.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$McGovern co-sponsored the Government By the People Act establishing public small-donor matching vouchers for all House candidates and co-sponsored the For The People Act (H.R. 1) requiring campaign finance disclosure. He has explicitly stated Citizens United "corrupted our democracy" and advocates for a constitutional amendment to overturn it. He consistently rates 100% from pro-reform organizations.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$As a Congressional Progressive Caucus member and consistent supporter of social investment programs, McGovern backed Build Back Better's universal pre-K provisions and the Child and Dependent Care Tax Credit expansion. He has supported universal childcare legislation as part of his anti-hunger and anti-poverty agenda.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$McGovern received a 100% NAACP rating on affirmative action, 87% from ACLU on civil rights, co-sponsored the Equality Act for LGBTQ+ non-discrimination, and the ERA. He is consistently among the most progressive voices in the House on civil rights enforcement and anti-discrimination law.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://ballotpedia.org/Jim_McGovern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McGovern received a 100% League of Conservation Voters rating and explicitly endorsed the Green New Deal. He called climate change "an existential threat" and has connected food insecurity to climate disruption. His record supports aggressive federal climate action including net-zero targets and clean energy investment.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$McGovern's 100% LCV record and Green New Deal endorsement imply strong concern about data center energy consumption. He has supported energy transparency requirements for large commercial energy users and his AI regulation positions (facial recognition moratorium) reflect interest in ensuring tech infrastructure meets environmental and civil rights standards.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$McGovern has a 0% rating from FAIR (indicating the most open immigration stance), opposed the Secure Communities program allowing ICE detainer requests from local jails, and supports a clean DREAM Act without preconditions. He has consistently opposed mass deportation policies and backed protection for long-term residents regardless of status.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$McGovern has focused economic development on food security and anti-poverty investment — he has championed SNAP expansion, the National School Lunch Program, and rural food access as economic development priorities. He backed the Inflation Reduction Act and CHIPS Act for clean energy and manufacturing job creation, and secured Worcester district infrastructure and broadband investment through the Infrastructure Investment and Jobs Act.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://en.wikipedia.org/wiki/Jim_McGovern_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$McGovern has a 100% LCV rating and endorsed the Green New Deal calling to end fossil fuel dependency. He has opposed new fossil fuel extraction permits and supported transitioning entirely to clean energy within 10 years. He has not taken a "moderate" position on fossil fuels — he consistently advocates ending federal subsidies and new permits for fossil fuel projects.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$McGovern's approach to growth combines environmental sustainability with community investment — he backs transit-oriented development, clean energy manufacturing, and SNAP-funded food system development as growth levers. He has supported the MBTA Communities Act and infrastructure-led development for Worcester and Central MA, consistently requiring environmental review and community benefit for large development projects.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://en.wikipedia.org/wiki/Jim_McGovern_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$McGovern is a member of the Medicare for All Caucus and has stated healthcare should be "a right, not a privilege." He co-sponsored H.R. 1976 (Medicare for All Act) and the Expanded and Improved Medicare for All Act. He opposes private insurance's role in essential care and has consistently backed single-payer as the long-term goal.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$McGovern supports harm reduction approaches and redirecting resources toward services rather than criminalization of homelessness. His food security and poverty-focused legislative record — championing SNAP, the HEROES Act emergency food provisions, and housing voucher expansions — reflects a comprehensive service-first approach to housing instability.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$McGovern has consistently prioritized housing-first and services-first homelessness response. He backed American Rescue Plan emergency rental assistance, supported expanding HUD Section 8 vouchers, and championed trauma-informed care models for unsheltered individuals. His SNAP and food insecurity work directly addresses a root cause of housing instability, positioning him firmly in the housing-and-services-over-enforcement camp.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McGovern has consistently supported affordable housing programs and opposed deregulation approaches. He backed the Housing Is Infrastructure Act, Section 8 expansions, and housing voucher increases in the American Rescue Plan. His anti-poverty focus connects housing affordability to food security and economic justice.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McGovern has a 0% rating from FAIR, supports pathway to citizenship for all undocumented immigrants, opposes border wall funding, and backed DACA. He has advocated for humane immigration courts, legal aid for asylum seekers, and eliminating mandatory detention. His record consistently reflects the most open immigration position in the House.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$McGovern voted YES on the Second Chance Act (2007) expanding reentry services and the First Step Act. He supports sentencing reform and alternatives to incarceration over prison expansion. He has backed the SAFE Justice Act and rehabilitation-focused approaches, favoring reduced incarceration over new jail or prison construction.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$McGovern co-sponsored the George Floyd Justice in Policing Act, LGBTQ anti-discrimination protections, and Legal Services Corporation funding increases. He has consistently backed civil legal aid for low-income individuals and opposed mandatory arbitration clauses. His 87% ACLU record reflects robust support for equal access to the justice system.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://ballotpedia.org/Jim_McGovern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$McGovern supported the Pretrial Integrity and Safety Act, which establishes evidence-based risk assessment rather than cash bail for pretrial release. His overall criminal justice record strongly favors reform of the cash bail system to eliminate wealth-based pretrial detention, consistent with his 87% ACLU and progressive caucus positions.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$McGovern supports a fair-chance rehabilitation-focused criminal justice philosophy. He backed the Second Chance Act, First Step Act, the SAFE Justice Act, and legislation ending solitary confinement for juveniles. He opposes mandatory minimums and three-strikes laws, and consistently votes for diversion and treatment rather than increased incarceration.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / judicial-government-deference -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        $$McGovern has consistently defended the regulatory capacity of agencies like the EPA, USDA, and FDA — all relevant to his food security and environmental priorities. His 100% LCV and progressive record reflect consistent opposition to judicial curtailment of agency rulemaking power (such as the Loper Bright decision). He supported expanding Supreme Court accountability measures and has backed USDA enforcement authority for nutrition programs.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://en.wikipedia.org/wiki/Jim_McGovern_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$McGovern has been one of the most vocal advocates for Supreme Court reform in Congress — he introduced the Supreme Court Ethics, Recusal, and Transparency Act and supported the concept of court expansion to correct what he sees as illegitimate appointments. His record reflects strong support for a living-Constitution interpretive framework and judicial accountability, opposing originalism.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://en.wikipedia.org/wiki/Jim_McGovern_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$McGovern co-sponsored the George Floyd Justice in Policing Act (2021), which limits qualified immunity for officers, mandates body cameras, and bans chokeholds. He strongly supports civilian oversight boards and independent accountability mechanisms. He has explicitly backed stronger enforcement of civil rights against police misconduct.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$McGovern consistently favors diversion over prosecution: he supported drug courts, opposed mandatory minimum sentences for drug offenses, and backed decriminalization of marijuana possession. He has consistently voted to reduce incarceration for non-violent offenses and shift prosecutorial resources away from low-level drug crimes toward violent crime.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$McGovern voted YES on protecting federal employee whistleblowers, opposed retroactive telecom immunity to preserve court oversight, and introduced the Supreme Court Ethics, Recusal, and Transparency Act requiring financial disclosure for justices. He has been among the most active House members advocating for mandatory judicial ethics enforcement.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$McGovern's 100% LCV lifetime score and Green New Deal endorsement reflect strong local environmental protection advocacy. He has backed EPA Brownfields remediation funding for Worcester area contaminated sites, clean water enforcement, and environmental justice provisions ensuring low-income communities are protected from pollution. He supports aggressive local air and water quality standards.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$McGovern's 0% FAIR score and opposition to Secure Communities reflect full support for sanctuary-city non-cooperation with ICE detainer requests. He has explicitly defended cities that limit local law enforcement involvement in federal immigration enforcement. His MA-02 district (including Worcester) has a significant immigrant community and he has backed state-level sanctuary protections.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$McGovern is a member of the Medicare for All Caucus and strongly opposes privatization of Medicare, voted against the Ryan Budget, and supports expanding eligibility to cover all Americans. He has explicitly called for a single-payer healthcare system with no role for private insurance in essential coverage.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$McGovern supports active government response to misinformation, acknowledging social media "spreading misinformation on an industrial scale." As Rules Committee chair he supported H.R. 1, which includes election information standards. He has backed platform accountability legislation and stronger FTC oversight of algorithmic amplification of false health and political information.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://en.wikipedia.org/wiki/Jim_McGovern_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$McGovern has backed community-based violence intervention programs and mental health crisis response as public safety tools alongside police reform. He supported George Floyd Justice in Policing Act and community investment bills addressing root causes of crime. His record prioritizes social services, mental health, and economic stability as primary public safety investments.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$McGovern co-sponsored the For the People Act (H.R. 1), which requires states to establish independent redistricting commissions and prohibits extreme partisan gerrymandering. As Rules Committee chairman he advanced anti-gerrymandering legislation and backed the John Lewis Voting Rights Act to restore federal oversight of states with discriminatory election histories.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$McGovern voted YES on the Employment Non-Discrimination Act barring job discrimination based on sexual orientation and religion, and co-sponsored the Equality Act. He holds that religious freedom rights do not override civil anti-discrimination law. He opposes religious exemptions from LGBTQ+ non-discrimination requirements.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$McGovern has backed the Tenant Protection Act of 2019, which would allow local and state governments to enact rent control and stabilization. He supported the Emergency Rental Assistance program and HUD enforcement of fair housing regulations against rent discrimination. His housing record consistently prioritizes tenant protections over landlord deregulation.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://en.wikipedia.org/wiki/Jim_McGovern_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$McGovern supported Build Back Better's housing provisions that tied federal grants to local zoning reform allowing multi-family development. He has backed YIMBY-style federal incentives conditioning transportation funding on upzoning near transit. His record uses federal leverage to push local governments toward allowing denser, more affordable housing development.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://en.wikipedia.org/wiki/Jim_McGovern_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$McGovern voted NO on constitutional amendments defining marriage as between one man and one woman in 2004 and 2006, voted YES on the Respect for Marriage Act (2022) codifying federal same-sex marriage recognition, and has been a consistent LGBTQ+ rights supporter. He supports full federal marriage equality and non-discrimination protections.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$McGovern explicitly stated he will "Oppose private and religious school voucher programs" and receives 100% from the NEA. He has opposed DC opportunity scholarships and every school voucher proposal in Congress, viewing vouchers as a threat to public school funding and democratic accountability in education.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$McGovern has stated to "Reject privatization; do not raise the retirement age" and received a 100% rating from Alliance for Retired Americans. He has co-sponsored Social Security 2100 Act and the Social Security Expansion Act. He consistently opposes any benefit cuts and backs expanding benefits by lifting the payroll tax cap.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$McGovern opposed most free trade agreements (voted NO on CAFTA, US-Singapore FTA, US-Chile FTA, Peru FTA) on labor and environmental grounds. He supports selective tariffs as tools against unfair trade practices, particularly regarding food dumping and currency manipulation. His position balances anti-corporate-globalization with strategic trade rather than blanket protectionism.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://en.wikipedia.org/wiki/Jim_McGovern_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$McGovern stated support for a "minimum tax rate of 30% for those earning over $1 million" (2012), received 100% from Citizens for Tax Justice, and has consistently backed progressive corporate and income tax increases. He opposed all Bush and Trump tax cuts and backs fully funding anti-poverty programs through wealth taxation.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$McGovern voted YES on an amendment ratifying Obama's executive order barring federal contractor discrimination based on gender identity, co-sponsored the Equality Act, and consistently supports transgender rights. He voted NO on the Protection of Women and Girls in Sports Act (2023), supporting inclusive policies for transgender athletes to compete consistent with their gender identity.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$McGovern supported the Infrastructure Investment and Jobs Act and has championed rail, transit, and cycling investment over highway expansion. He secured funding for Worcester's Union Station rail improvements, WRTA bus service expansion, and regional trail systems. His Green New Deal endorsement explicitly prioritizes public transit decarbonization and infrastructure-led transportation transformation.$$,
        ARRAY['https://mcgovern.house.gov/issues', 'https://en.wikipedia.org/wiki/Jim_McGovern_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        '24e9212c-b011-422a-865c-093e35050901',
        $$McGovern visited Kyiv with Speaker Pelosi in April 2022 and pledged military aid support. However, in 2023 he co-signed a letter calling for a ceasefire and diplomatic resolution in Ukraine. His position shifted toward supporting aid paired with diplomatic pressure rather than unconditional military escalation, placing him at 2 — support with conditions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jim_McGovern_(politician)', 'https://www.ontheissues.org/House/Jim_McGovern.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jim McGovern / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$McGovern co-sponsored bills for automatic voter registration, same-day registration, a 15-day minimum early voting window, no-excuse mail-in ballots, and the For the People Act. As Rules Committee chairman he advanced the John Lewis Voting Rights Advancement Act. He consistently opposes voter ID laws and supports maximum ballot access.$$,
        ARRAY['https://www.ontheissues.org/House/Jim_McGovern.htm', 'https://mcgovern.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ee4081d5-fc3e-4a8c-b39e-481ae20135d5';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ee4081d5-fc3e-4a8c-b39e-481ae20135d5'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ee4081d5-fc3e-4a8c-b39e-481ae20135d5'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
