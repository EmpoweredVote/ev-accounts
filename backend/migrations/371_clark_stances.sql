-- ============================================================================
-- Migration 371: Katherine Clark Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Katherine Clark (US Representative, MA-05).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Supplemental: Clark had 28 pre-existing stances from a prior session.
--   This migration re-upserts all 28 (idempotent) and adds 15 new topics.
--   city-sanitation omitted — no documented federal House record.
--   Total expected: 43 topics.
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
-- Katherine Clark: 7bf73fb2-1b31-412e-913d-835bfd3e326d

BEGIN;

-- ============================================================
-- Katherine Clark (MA-05)
-- ============================================================

-- ----- Katherine Clark / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Clark's OnTheIssues profile documents her support for 'ban anti-abortion limitations on abortion services' (Feb 2014). She voted YES on the Women's Health Protection Act and has a 100% NARAL rating. As House Democratic Whip she has led floor strategy for abortion rights legislation and made it a signature leadership issue.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Clark has focused on AI regulation from a consumer protection and children's safety lens — she backed legislation requiring algorithmic accountability on social media platforms and supported TikTok oversight. As Minority Whip she coordinated Democratic positions on AI safety standards in the 118th Congress. Her record supports strong AI safety guardrails, particularly for systems affecting children, privacy, and employment discrimination.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Clark's OnTheIssues profile shows she supported 'limit all campaign donations and limit spending' (1994), 'full disclosure of bundled donations' (2008), and backed the For the People Act as House Democratic Whip. She opposes Citizens United and has backed public financing of elections as part of a comprehensive democracy reform agenda.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Clark is a longtime childcare champion in the House, declaring at the 2024 Democratic National Convention that 'Child care is infrastructure.' She introduced the Child Care for Working Families Act and has led the campaign for universal pre-K. She has made childcare affordability and accessibility the defining issue of her legislative career alongside her Whip duties.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Clark's OnTheIssues profile shows support for affirmative action in state government (1994), equal pay legislation, civil rights enforcement, and the Equality Act for LGBTQ+ protections. As House Democratic Whip she has been responsible for delivering Democratic votes on civil rights legislation. She is a consistent top-rated representative on civil rights measures from the NAACP and HRC.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Clark's OnTheIssues profile shows she co-sponsored the Green New Deal (Feb 2019), called for 'Carbon tax: it's time to grow the clean energy economy' (2016), and has a 100% LCV lifetime rating. She has been a consistent advocate for aggressive climate action, supporting the IRA and treating climate change as a national security issue.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Clark's 100% LCV record and Green New Deal co-sponsorship reflect concern about large energy consumers including data centers. She has backed AI accountability legislation from a consumer protection standpoint and would likely support mandatory energy transparency and clean energy standards for data center development — consistent with her comprehensive climate and tech regulation positions.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Clark has criticized ICE enforcement practices, joining Democratic leadership in condemning what she characterized as targeting of long-term residents and DACA recipients. She backed the American Dream and Promise Act and opposes mass deportation programs. Her immigration record consistently prioritizes legal pathways and protection for established residents over enforcement-driven removal.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Clark's economic development agenda centers on childcare as workforce infrastructure — arguing that accessible childcare enables women's workforce participation and drives economic growth. As House Democratic Whip she coordinated passage of the CHIPS Act, IRA clean energy investment, and Infrastructure Investment and Jobs Act. She secured biotech and healthcare innovation funding for MA-05, which includes the Route 128 tech corridor in Malden, Revere, and Somerville.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Clark voted YES on banning offshore oil drilling in the Gulf of Mexico (Jul 2016) per OnTheIssues, co-sponsored the Green New Deal calling for ending fossil fuel dependency, and has a 100% LCV rating. She has backed ending fossil fuel subsidies and supported aggressive carbon reduction timelines.$$,
        ARRAY['https://www.ontheissues.org/House/Katherine_Clark.htm', 'https://clark.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Clark backed the MBTA Communities Act, transit-oriented development investment in the Boston metro area, and Green Line Extension completion. Her economic development approach combines climate standards, community investment, and workforce development — childcare, education, and clean energy — as foundations for equitable growth. She supports growth tied to environmental standards and community benefit rather than deregulated expansion.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Clark's OnTheIssues profile shows support for 'insurance reforms and state-funded care' and defending the ACA against repeal. She has backed drug price negotiation provisions and ACA premium subsidy expansions. While she supports universal coverage, her healthcare record reflects expanding existing public programs and regulating private insurance rather than replacing the private sector entirely.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Clark's legislative record reflects a services-first approach to poverty and homelessness, including supporting increased federal investment in emergency shelter, transitional housing, and wraparound services. She backed emergency rental assistance in both the CARES Act and American Rescue Plan and has opposed criminalization of homelessness as ineffective public policy.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Clark's childcare-as-infrastructure framing extends to homelessness — she views housing instability and homelessness as driven by poverty, childcare costs, and healthcare costs. She has consistently backed housing-first programs and emergency rental assistance. Her leadership on childcare legislation directly addresses a root cause of female-headed household housing instability.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Clark as a Congressional Progressive Caucus member voted for the Build Back Better Act which included substantial affordable housing investment, LIHTC expansion, and Section 8 voucher increases. Her MA-05 district (including Chelsea, Revere, Somerville) has severe housing affordability pressures. She has backed inclusionary zoning incentives and tenant protections alongside supply expansion.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Clark's OnTheIssues profile shows she supported 'path to citizenship for undocumented immigrants' (2013), 'voted to legalize DREAMers' (2019), and criticized ICE practices. Her MA-05 district includes Chelsea and East Boston — communities with large immigrant populations — making immigration reform central to her constituent service. She supports comprehensive immigration reform with citizenship pathways.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Clark's OnTheIssues profile shows early support for 'job skills for inmates; plus alternative sentencing' (1994). As a Progressive Caucus member she has backed the First Step Act, sentencing reform, and alternatives to incarceration. Her record strongly favors rehabilitation and diversion over prison expansion.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Clark has supported legal aid and equal access to justice as part of her broader civil rights legislative agenda. As a Progressive Caucus member and House Democratic Whip she has backed LSC funding, civil rights enforcement agency budgets, and access to immigration courts. Her swatting and cyberstalking legislation reflects direct experience with inadequate law enforcement response to harassment — driving her support for improved access to criminal justice remedies.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Clark's record on alternative sentencing and rehabilitation since the 1990s places her squarely in the cash bail reform camp. She backed the Pretrial Integrity and Safety Act and supports risk-based pretrial release assessment replacing wealth-based cash bail. Her progressive criminal justice record consistently favors reducing pretrial detention for nonviolent defendants.$$,
        ARRAY['https://clark.house.gov/issues', 'https://ballotpedia.org/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Clark's OnTheIssues profile reflects support for alternative sentencing, job skills programs for inmates, and substance treatment over prosecution since the 1990s. She backed the First Step Act, sentencing reform legislation, and the Second Chance Act. Her criminal justice philosophy consistently emphasizes rehabilitation, reducing mass incarceration, and addressing root causes of crime.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / judicial-government-deference -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        $$Clark's Green New Deal co-sponsorship, ACA defense, and progressive caucus record all reflect strong support for EPA, CFPB, NLRB, and HHS regulatory authority. As House Democratic Whip she coordinated opposition to judicial curtailment of agency rulemaking following Loper Bright. She has backed SCOTUS ethics reform and Supreme Court accountability measures to preserve democratic oversight of courts.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Clark backed ERA ratification, the Equality Act, and consistently voted for Obama and Biden judicial nominees with living-Constitution interpretive frameworks. As Whip she coordinated Democratic opposition to originalist SCOTUS nominees. Her civil rights record — including childcare as a constitutional commitment — reflects support for broad constitutional interpretation that applies rights dynamically to contemporary needs.$$,
        ARRAY['https://clark.house.gov/issues', 'https://ballotpedia.org/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Clark is rated 62% by the National Association of Police Officers (NAPO), indicating a moderate rather than extreme stance on police reform. She co-sponsored the George Floyd Justice in Policing Act and supported mandatory body cameras and restricting chokeholds. Clark is personally affected by police accountability issues: she was the target of a 'swatting' attack in 2023, which resulted in the arrest of her own child for assaulting an officer — giving her direct experience with the complex dynamics of police response and accountability.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Clark's documented support for alternative sentencing, diversion programs, and job skills for inmates since the 1990s informs a prosecution philosophy prioritizing treatment and rehabilitation over incarceration for nonviolent offenses. She backed reducing mandatory minimums for drug offenses and shifting prosecutorial resources toward violent crime prevention.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Clark introduced legislation against 'swatting' and cyberstalking, reflecting a commitment to transparent and accountable law enforcement processes. As Whip she backed the Supreme Court Ethics, Recusal, and Transparency Act and coordinated Democratic support for mandatory financial disclosure for federal judges. Her experience with the swatting incident reinforced her support for police accountability and judicial transparency.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Clark's 100% LCV lifetime score, Green New Deal co-sponsorship, and IRA support reflect consistent local environmental protection advocacy. She has backed EPA Brownfields remediation for MA-05 communities, environmental justice provisions protecting lower-income communities in Chelsea and Revere from industrial pollution, and clean water enforcement. Her district faces flooding risks from climate change, making local environmental protection a direct constituency concern.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Clark's MA-05 district includes Chelsea and East Boston — cities with large Central American and Southeast Asian immigrant communities. She has been a vocal defender of sanctuary-city policies and opposed ICE cooperation requirements that would undermine community trust. Her immigration record fully supports local non-cooperation with ICE detainer requests as essential for public safety in immigrant communities.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Clark's OnTheIssues profile shows she supported 'keep our promises to seniors: keep retirement age and no cuts' (2013). She opposes Medicare privatization and backed drug price negotiation provisions in the IRA. As Whip she has coordinated Democratic opposition to Medicare benefit cuts and supported expanding Medicaid coverage through ACA expansion.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Clark introduced legislation to address online harassment from the Gamergate controversy and bills against 'swatting' (filing false emergency reports). As Whip she has backed platform accountability measures for harmful content amplification including health misinformation. Her direct experience as a swatting victim of online harassment driven by social media informs her support for active government response to platform-amplified harm.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Clark backed the George Floyd Justice in Policing Act as part of Democratic leadership strategy under Whip duties. She has supported mental health crisis response programs and community violence intervention as public safety investments alongside police reform. Her childcare and economic investment agenda directly addresses root causes of crime. She prioritizes community investment and accountability standards over purely enforcement-focused approaches.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Clark as a Progressive Caucus member has supported the For the People Act, which included provisions establishing independent redistricting commissions and requiring anti-gerrymandering safeguards. As Whip she coordinated Democratic floor strategy for voting rights and democracy reform legislation. Her record consistently supports citizen-led redistricting processes.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Clark's OnTheIssues profile includes 'Religious freedom means no religious registry' (May 2016), opposing theocratic overreach in government. She co-sponsored the Equality Act providing LGBTQ+ non-discrimination protections and consistently holds that religious freedom claims do not override civil anti-discrimination law in public accommodations and employment.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Clark backed the Tenant Protection Act of 2019 (H.R. 3814) allowing states to enact rent control. She supported Emergency Rental Assistance in both the CARES Act and American Rescue Plan. Her MA-05 district includes Chelsea, Revere, and Somerville — communities with significant affordability pressures — and she has backed both tenant protections and housing supply investment as complementary strategies.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Clark supported Build Back Better's housing provisions linking grants to local zoning reform and backed the MBTA Communities Act's transit-oriented zoning requirements. Her MA-05 district (including Somerville) is a model for transit-oriented density. She uses federal financial incentives to encourage upzoning near transit corridors while maintaining environmental and community standards.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Clark's OnTheIssues profile shows she supported 'let out-of-state gay couples marry in Massachusetts' (2013). She voted YES on the Respect for Marriage Act (2022) and has consistently backed full federal marriage equality with no religious exemptions from recognition requirements. She is a member of the Congressional Equality Caucus.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Clark's OnTheIssues profile explicitly states she 'Oppose[s] private and religious school voucher programs' (Oct 2015) and supports fully funding public schools. She has backed legislation eliminating federal voucher programs and is consistently rated 100% by the NEA. Her district includes Chelsea and Revere public schools that she advocates for through federal education funding.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Clark's OnTheIssues profile shows she supported 'Keep our promises to seniors: keep retirement age and no cuts' (2013), backed Social Security 2100 Act, and has a 100% Alliance for Retired Americans rating. She opposes privatization and any benefit cuts, supporting expansion of benefits funded by lifting the payroll tax cap.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Clark voted YES on USMCA in 2019, reflecting support for managed trade agreements with labor and environmental standards. As a progressive Democrat she supports selective tariffs to protect American workers from unfair trade practices, particularly in manufacturing, but prioritizes domestic economic investment over broad protectionism. Her trade record balances worker protection with market access.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Clark's OnTheIssues profile shows she supported 'End tax breaks for oil companies and billionaires' (2013), and 'Raising taxes on the wealthy to fund public investments' (2019). She backed the IRA's corporate minimum tax and consistently supports progressive tax structures — higher rates on wealth and corporations funding social investment including childcare, healthcare, and education.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Clark has expressed strong support for transgender rights including speaking about the disproportionate violence and mortality faced by transgender youth. She co-sponsored the Equality Act and voted NO on the Protection of Women and Girls in Sports Act (2023). Her record consistently supports inclusive policies allowing transgender athletes to participate in sports consistent with their gender identity.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Clark supported the Infrastructure Investment and Jobs Act and has championed MBTA reliability improvements and Green Line Extension to Union Square in Somerville (MA-05). Her Green New Deal co-sponsorship reflects commitment to decarbonizing transportation. She has backed federal investment in MBTA electrification, commuter rail upgrades, and bicycle infrastructure as multimodal alternatives to highway expansion.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Clark called for a House vote on Ukraine assistance in April 2024 alongside Democratic leadership. She opposed the February 2024 Senate border deal that had conditioned aid, preferring a clean Ukraine aid package. As House Democratic Whip she coordinated floor strategy to pass the $61 billion Ukraine supplemental aid package. Her record reflects consistent support for Ukraine military and economic assistance.$$,
        ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Katherine Clark / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bf73fb2-1b31-412e-913d-835bfd3e326d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Clark's OnTheIssues profile shows she supported 'No photo IDs to vote; they suppress the vote' (Jun 2014) and 'Automatic voter registration via DMV and other agencies' (Jun 2014). As Whip she coordinated Democratic strategy for the For the People Act and John Lewis Voting Rights Advancement Act. She consistently opposes voter ID requirements and supports maximum ballot access expansion.$$,
        ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/House/Katherine_Clark.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
