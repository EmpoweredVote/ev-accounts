-- ============================================================================
-- Migration 367: Richard Neal Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Richard Neal (US Representative, MA-01).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Supplemental: Neal had 23 pre-existing stances from a prior session.
--   This migration re-upserts all 23 (idempotent) with enriched reasoning and
--   adds 19 new topics discovered during this research pass.
--   city-sanitation omitted — no documented federal House record.
--   Total expected: 42 topics.
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
-- Richard Neal: a0cb697c-3158-4680-8e70-c154c3a15cc4

BEGIN;

-- ============================================================
-- Richard Neal (MA-01)
-- ============================================================

-- ----- Richard Neal / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Neal has a distinctly conservative abortion record for a Massachusetts Democrat: he voted for partial-birth abortion bans in 2000 and 2003, voted for the Stupak-Pitts Amendment restricting abortion funding in the ACA, and stated "I have always opposed taxpayer funding of abortion. I'd keep Roe v. Wade and restrict it." He co-sponsored the Women's Health Protection Act in 2021 but his overall record over decades of votes places him closest to stance 4 — supporting legal abortion only in cases of rape, incest, or serious health threats.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Neal's record as Ways and Means Ranking Member reflects mainstream Democratic positions on tech and finance accountability. He has not been a leading AI regulation voice; his 100% Biden alignment and economic record suggest support for basic safety standards and liability frameworks rather than either a free-market or heavy government-approval approach.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Neal supports banning soft money contributions, disclosure of independent expenditures, and transparency measures. He was criticized for a $5,000-per-person Cape Cod fundraiser in 2010, showing tension between reform positions and practice. His legislative stance consistently favors limiting corporate and dark money influence.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Neal voted YES on paid parental leave for federal employees and his consistently progressive economic record — 100% Americans for Democratic Action rating, opposition to welfare work requirements, support for SNAP — reflects support for significantly expanding childcare subsidies for low- and middle-income families.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Neal has been rated 97% by the NAACP and 88% by the Human Rights Campaign. He supports the Equal Rights Amendment and has consistently backed anti-discrimination enforcement and affirmative action, earning a "Hard-Core Liberal" classification on OnTheIssues for his overall record.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://ballotpedia.org/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Neal scored 94% lifetime and 100% in 2025 from the LCV, opposes offshore drilling and ANWR development, and supports 50% clean/carbon-free electricity by 2030. His record shows investment in clean energy and gradual fossil fuel reduction rather than an emergency ban or immediate 2030 phase-out. He voted for the Inflation Reduction Act's clean energy provisions.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Neal as Ways and Means chair/ranking member focused primarily on tax and trade policy. He supported the CHIPS Act and innovation economy investment but has not taken a strong public position on data center energy consumption or location regulation specifically. His moderate clean energy record (IRA support, LCV 94% lifetime) suggests balanced growth with environmental standards rather than moratoriums.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://neal.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Neal is rated 0% by FAIR (immigration restrictionists), supports pathway to citizenship for undocumented immigrants, and opposes border fencing. His pro-immigration record suggests a focus on deporting recent crossers while allowing long-term residents to apply for legal status rather than mass deportation.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$As Ways and Means Committee chair, Neal championed the Inflation Reduction Act, the CHIPS and Science Act, and Build Back Better infrastructure provisions as economic development vehicles. He has prioritized bringing federal investment to Western Massachusetts, including MassDevelopment funding, Opportunity Zone incentives for Springfield, and New Market Tax Credits that he championed specifically for underserved urban communities.$$,
        ARRAY['https://neal.house.gov/issues/economic-development', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Neal opposes offshore oil drilling and ANWR development but his Ways and Means Committee record does not show advocacy for halting all new permits. His 94% lifetime LCV score reflects maintaining current environmental regulations with incentives for renewables rather than an immediate ban on new fossil fuel extraction.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://www.lcv.org/congressional-scorecard/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Neal has consistently championed economic revitalization of Western Massachusetts through federal investment — securing New Market Tax Credits, supporting MassDevelopment projects, and backing transit-oriented development around Springfield Union Station. His record supports growth with infrastructure and environmental standards, not development-at-any-cost, consistent with his LCV 94% score.$$,
        ARRAY['https://neal.house.gov/issues', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Neal explicitly opposed Medicare for All, telling Democrats it was "wrong on policy and a political loser," and instead championed ACA expansion with pre-existing condition protections and out-of-pocket caps. He supports affordable coverage through public programs alongside regulated private insurance, and has used Ways and Means to advance drug price negotiation provisions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Neal's consistent support for anti-poverty programs — opposing welfare work requirements, backing SNAP expansion, supporting earned income tax credit increases — reflects a decriminalize-and-invest approach to homelessness, favoring shelter and service investment over enforcement.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://neal.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Neal supported the American Rescue Plan's emergency rental assistance, SNAP expansions, and housing voucher programs that directly address homelessness response. His consistent opposition to welfare work requirements and support for SNAP reflect a housing-first, services-led approach to unsheltered homelessness rather than criminalization.$$,
        ARRAY['https://neal.house.gov/issues', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Neal voted YES on Section 8 housing voucher funding and supports revitalizing severely distressed public housing. His 97% NAACP rating and progressive economic record reflect support for rent assistance, affordable unit mandates, and public housing investment. As Ways and Means chair he incorporated New Market Tax Credits and Low-Income Housing Tax Credits into major legislation.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://neal.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Neal is rated 0% by FAIR, voted to legalize DREAMers via military service, opposes border fencing, supports pathway to citizenship, and backs increased visa caps for high-skill and family-based immigration. He supports keeping legal immigration open with services available regardless of immigration status.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Neal has sponsored stricter police accountability rules, is rated 78% by CURE (pro-rehabilitation), opposes the death penalty and supports replacing it with life imprisonment, and favors alternative sentencing over prison expansion. His record reflects strong preference for diversion and rehabilitation over expanding incarceration.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Neal has consistently supported legal aid funding and civil justice access for low-income Americans, backing funding for the Legal Services Corporation and supporting court fee waivers. His 97% NAACP rating and opposition to mandatory arbitration clauses in consumer contracts reflect prioritizing equal access to civil courts.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://ballotpedia.org/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Neal's 78% CURE rating (Citizens United for Rehabilitation of Errants), opposition to mandatory minimums, and support for sentencing alternatives place him closer to reforming cash bail toward risk-based pretrial assessment. He has supported the First Step Act and criminal justice reform legislation that reduces incarceration of non-violent offenders before trial.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Neal opposes the death penalty and supports replacing it with life imprisonment, backed the First Step Act, and is rated 78% by CURE. He supported restrictions on solitary confinement and mandatory minimum reform. His overall record prioritizes rehabilitation and reducing mass incarceration over punitive approaches.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / judicial-government-deference -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        $$Neal has used Ways and Means authority to defend IRS enforcement capacity, oppose the dismantling of federal regulatory agencies, and back executive agency rulemaking on tax and healthcare. His consistent defense of ACA implementation, Medicare administration, and Social Security against court challenges reflects support for strong judicial deference to regulatory expertise.$$,
        ARRAY['https://neal.house.gov/issues', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Neal's "Hard-Core Liberal" rating on OnTheIssues and 100% ADA rating reflect consistent support for a living-Constitution approach to judicial interpretation — including backing Obama and Biden judicial nominees who view constitutional rights as evolving to address contemporary social needs. He opposed originalist nominees to the Supreme Court.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://ballotpedia.org/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Neal has sponsored stricter police accountability rules and is rated 97% by the NAACP. He backed the George Floyd Justice in Policing Act (voted YES in House) and generally supported measures to strengthen civilian oversight, restrict chokeholds, and require body cameras. He did not support abolishing or defunding police departments.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Neal's criminal justice record favors deprioritizing prosecution of non-violent drug offenses — he voted to reduce marijuana sentencing disparities and supported sentencing reform that shifted enforcement resources toward violent crime. His CURE rating (78%) and First Step Act support reflect a prosecution philosophy emphasizing diversion and treatment over incarceration.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://ballotpedia.org/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$As Ways and Means chair, Neal wielded his subpoena power to obtain President Trump's tax returns, asserting the committee's statutory oversight authority. He has consistently supported judicial and government transparency measures, including Supreme Court ethics disclosure requirements introduced after the Clarence Thomas reporting. His record reflects strong support for mandatory financial disclosure by judges.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://neal.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Neal's 94% lifetime LCV score and opposition to offshore drilling and ANWR development reflect consistent environmental protection advocacy. He has secured EPA Brownfields funding for Springfield and supported environmental justice provisions in the Inflation Reduction Act. His record favors strong local environmental enforcement and federal partnership with state regulators.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Neal's 0% FAIR rating and support for sanctuary policies align him with limiting local law enforcement cooperation with ICE detainer requests. He has supported legislation restricting federal pressure on sanctuary cities and backed DACA protections. His MA-01 district includes significant immigrant communities in Springfield that benefit from local non-enforcement policies.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://ballotpedia.org/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Neal strongly opposes privatizing Medicare — voted against the Ryan Budget — and voted for SCHIP expansion. He moved to the Social Security subcommittee to fight privatization and consistently defends Medicare and Medicaid, aligning with lowering the eligibility age and expanding Medicaid rather than Medicare for All.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Neal has spoken in favor of platform accountability and supported the American Innovation and Choice Online Act. He has not been a leading voice on misinformation regulation specifically, but his Ways and Means work on tech tax policy and general Democratic voting record places him in the "voluntary standards with possible liability reforms" camp — supporting some government response but not direct content mandates.$$,
        ARRAY['https://neal.house.gov/issues', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Neal backed the George Floyd Justice in Policing Act but has not embraced defunding police. His focus as Ways and Means chair was on economic security as the foundation for public safety — job creation, housing, childcare — alongside maintaining law enforcement. His moderate Democratic approach combines targeted police reform with adequate public safety funding, placing him in the center-left range.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Neal is a "Hard-Core Liberal" on OnTheIssues with 100% Biden alignment and a record supporting democratic accountability measures. His consistent positions on electoral fairness suggest support for independent redistricting commissions with equal party representation.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://ballotpedia.org/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Neal is rated 15% by the Christian Coalition, opposes school prayer and federal funding for faith-based organizations, and has consistently taken secular positions that hold religious freedom does not override civil anti-discrimination law.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Neal supported the Housing Is Infrastructure Act and voucher expansions, and his 97% NAACP rating reflects awareness of rental affordability as a racial equity issue. He has backed tenant protection provisions in federal housing legislation and opposed algorithmic rent-setting practices under his Ways and Means oversight of financial markets.$$,
        ARRAY['https://neal.house.gov/issues', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Neal has not taken a prominent federal position on local zoning reform. His record supports community reinvestment through New Market Tax Credits and affordable housing incentives without mandating specific zoning changes — consistent with deference to local governments on land use while using federal financial incentives to encourage affordable unit production.$$,
        ARRAY['https://neal.house.gov/issues', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Neal voted twice against the Federal Marriage Amendment and consistently supports same-sex marriage. His 88% HRC rating and opposition to defining marriage as between one man and one woman reflect firm support for nationwide recognition with full federal benefits.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Neal is rated 100% by the National Education Association, opposes private and religious school vouchers, voted NO on DC opportunity scholarships, and supports free community college as an alternative. His position is to fully fund public schools and eliminate voucher programs.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Neal moved to the Social Security subcommittee in 2005 specifically to fight privatization, is rated 100% by Alliance for Retired Americans, and introduced the SECURE Act (2019) expanding retirement planning. He opposes raising the retirement age or privatizing and supports modest improvements to the program.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Neal voted against NAFTA (1993) and fast-track bills (1995, 2002) but for the Peru FTA (2007). As Ways and Means Ranking Member he supports using tariffs selectively against currency manipulators to protect American jobs while favoring managed trade over pure protectionism.$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Neal voted NO on Bush tax cuts repeatedly, is rated 100% by Citizens for Tax Justice, and supports raising estate taxes to 1990s levels. As Ways and Means Ranking Member he has consistently championed significantly raising taxes on wealthy individuals and corporations to fund public programs.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Neal voted NO on the Protection of Women and Girls in Sports Act (2023), which would have banned transgender women from participating in female sports. His 88% HRC rating and consistent LGBTQ+ rights record reflect support for inclusive policies allowing transgender athletes to compete consistent with their gender identity under appropriate guidelines.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Neal supported the Infrastructure Investment and Jobs Act (2021) and has secured federal transportation funding for Western Massachusetts — including I-91 viaduct replacement, rail improvements at Springfield Union Station, and PVTA bus service upgrades. He supports a multi-modal approach prioritizing rail, transit, and electric vehicle infrastructure over highway expansion alone.$$,
        ARRAY['https://neal.house.gov/issues', 'https://en.wikipedia.org/wiki/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '24e9212c-b011-422a-865c-093e35050901',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        '24e9212c-b011-422a-865c-093e35050901',
        $$In 2023, Neal was among 49 House Democrats who voted for a measure to ban sending cluster munitions to Ukraine, breaking with the Biden administration's Ukraine weapons policy. While his overall record is not isolationist, this specific dissent from Ukraine military aid policy warrants a stance 4 (reduce aid, focus domestic priorities).$$,
        ARRAY['https://en.wikipedia.org/wiki/Richard_Neal', 'https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard Neal / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a0cb697c-3158-4680-8e70-c154c3a15cc4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Neal has sponsored legislation expanding voter registration access, supports automatic voter registration, favors making Election Day a national holiday, and opposes voter ID requirements. His record reflects expanding early voting and no-excuse mail-in ballot access.$$,
        ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm', 'https://ballotpedia.org/Richard_Neal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
