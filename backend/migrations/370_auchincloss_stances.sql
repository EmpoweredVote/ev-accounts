-- ============================================================================
-- Migration 370: Jake Auchincloss Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jake Auchincloss (US Representative, MA-04).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Supplemental: Auchincloss had 25 pre-existing stances from a prior session.
--   This migration re-upserts all 25 (idempotent) and adds 18 new topics.
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
-- Jake Auchincloss: 41945b74-325e-4fa2-9cc9-edd11ead9ed3

BEGIN;

-- ============================================================
-- Jake Auchincloss (MA-04)
-- ============================================================

-- ----- Jake Auchincloss / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Auchincloss stated a pro-choice stance in his 2020 campaign (PVS survey) and is a member of the Congressional LGBTQ+ Equality Caucus. He voted YES on the Women's Health Protection Act and opposes abortion restrictions. His overall record reflects consistent support for abortion access, though he has focused primarily on reproductive health through healthcare legislation rather than making it a signature issue.$$,
        ARRAY['https://ballotpedia.org/Jake_Auchincloss', 'https://auchincloss.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Auchincloss authored legislation to raise the internet age of adulthood to 16 and co-sponsored the bipartisan TikTok forced-sale law. As a member of the House Intelligence Committee (and Foreign Affairs), he has focused on AI's national security implications, backing the AI Advancement and Reliability Act and supporting targeted safety standards — particularly for AI systems with national security and children's safety risks.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Auchincloss stated a pro-campaign finance reform position in his 2020 campaign and sponsored the Protecting Our Democracy Act (December 2021), which includes provisions to limit dark money and increase electoral transparency. He has backed the For the People Act's campaign finance disclosure provisions as a New Democrat.$$,
        ARRAY['https://ballotpedia.org/Jake_Auchincloss', 'https://auchincloss.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Auchincloss supported the Child Tax Credit expansion in the American Rescue Plan and backed Build Back Better's childcare provisions, though he has emphasized childcare through market and workforce lenses more than universal entitlement framing. As a moderate New Democrat, he backs significant childcare investment targeted at affordability but has not been a leading advocate for universal government-provided childcare.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Auchincloss sponsored the Equal Rights Amendment ratification bill (March 2021) and stricter police accountability rules. He is a member of the Congressional LGBTQ+ Equality Caucus and has backed anti-discrimination legislation including the Equality Act. His civil rights record reflects consistent support for expanding protected classes and federal enforcement.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Auchincloss holds a 97% lifetime LCV score and supports greenhouse gas restrictions and renewable energy. He is on the House Energy and Commerce Subcommittee. However, as a New Democrat he backed the IRA's market-based clean energy incentives rather than the Green New Deal mandate approach. His climate position is strong but more technology-neutral and market-friendly than progressives.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/', 'https://auchincloss.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Auchincloss represents Newton and the I-128 tech corridor — home to many tech companies. His abundance agenda and pro-innovation stance suggest support for data center growth with energy efficiency standards rather than moratoriums. He has backed AI advancement legislation and views tech infrastructure as essential for US competitiveness, while supporting clean energy mandates that would apply to data centers alongside other large energy users.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Auchincloss has a stated pro-immigrant stance and sponsored legislation disallowing religion-based immigration bans (April 2021). As a New Democrat centrist, he supports secure borders with legal immigration reform — including a pathway for DREAMers — but has been more willing than progressive colleagues to accept enforcement mechanisms paired with legalization. His position is moderate: deport recent illegal border crossers, protect long-term undocumented residents.$$,
        ARRAY['https://ballotpedia.org/Jake_Auchincloss', 'https://auchincloss.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Auchincloss represents the Route 128/495 tech corridor and champions an "abundance agenda" emphasizing tech innovation, CHIPS Act manufacturing investment, and clean energy as economic development pillars. He secured SBIR grants, biotech commercialization funding, and defense technology investment for MA-04. His economic development approach emphasizes public-private partnership and innovation ecosystem investment over traditional industrial subsidies.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Auchincloss holds a 97% LCV lifetime score and supports pro-renewable energy policies. As a New Democrat who backed the IRA market-based clean energy incentives, he supports transitioning away from fossil fuels through investment and pricing mechanisms rather than outright bans. His position favors maintaining current regulatory standards while using market signals to phase out fossil fuels over time.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/', 'https://auchincloss.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Auchincloss explicitly advocates an "abundance agenda" — a pro-growth framework supporting infrastructure investment, housing supply expansion, and technology development as paths to shared prosperity. He is a YIMBY Caucus member who supported the Infrastructure Investment and Jobs Act and transit-oriented development. His growth vision combines density, innovation, and sustainability.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Auchincloss stated a pro-ACA/ObamaCare position in his 2020 campaign and serves on the House Energy and Commerce Subcommittee dealing with health policy. He supports expanding the ACA and drug price negotiation. As a New Democrat he does not co-sponsor Medicare for All but has backed public option expansion and pharmaceutical price reform.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Auchincloss's abundance agenda and YIMBY housing positions reflect a supply-side approach to homelessness — increasing housing production to reduce homelessness rather than primarily through services or criminalization. He backed American Rescue Plan emergency rental assistance. His moderate position favors housing-first combined with market-rate supply expansion and targeted services for the chronically homeless.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Auchincloss backed American Rescue Plan rental assistance and HUD housing vouchers. As a YIMBY moderate, his homelessness response blends housing production (supply-side) with targeted services — he supports emergency shelter and mental health services alongside market-driven housing construction. He does not advocate for either pure criminalization or pure decriminalization, favoring evidence-based shelter and treatment programs.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Auchincloss is a member of the Congressional YIMBY Caucus and promotes an abundance agenda favoring supply-side solutions: upzoning, permitting reform, and removing exclusionary zoning barriers. He backed the HOMES Act and federal incentives for jurisdictions that increase housing permits. His approach prioritizes increasing overall housing supply over tenant protection mandates.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Auchincloss stated a pro-immigrant stance in his 2020 campaign and sponsored legislation prohibiting religion-based immigration bans. He supports DACA protections, pathways to citizenship, and increased legal immigration. As a New Democrat he also accepts some border enforcement paired with legal reform — a comprehensive immigration bill rather than enforcement-only or open borders.$$,
        ARRAY['https://ballotpedia.org/Jake_Auchincloss', 'https://auchincloss.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Auchincloss sponsored legislation enacting stricter police accountability rules (March 2021) and voted against the view that safety requires increasing incarceration. He backed sentencing reform and the First Step Act. His record favors rehabilitation and diversion for non-violent offenses over prison expansion, while maintaining strong enforcement for violent crime.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Auchincloss sponsored the Equal Rights Amendment ratification (March 2021) and police accountability legislation (March 2021), reflecting support for expanded civil rights enforcement. He backed Legal Services Corporation funding and has supported access to counsel expansions. His civil rights voting record reflects support for removing barriers to court access for discrimination victims.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Auchincloss has supported bail reform moving away from cash bail for nonviolent offenses, consistent with his First Step Act support and rehabilitation-focused record. As a moderate, he also backs preventive detention for violent and high-risk defendants — supporting a risk-based pretrial system that retains judicial discretion for dangerous defendants rather than abolishing pretrial detention entirely.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Auchincloss sponsored police accountability legislation (March 2021) and explicitly stated opposition to the view that safety requires increasing incarceration. He backed sentencing reform and supported the First Step Act. His moderate criminal justice position favors evidence-based reforms including reducing mandatory minimums for nonviolent offenses while maintaining strong accountability for violent crime.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / judicial-government-deference -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        $$Auchincloss has not taken prominent positions on Chevron deference or agency rulemaking authority specifically. As a New Democrat he supports effective regulation but also champions innovation and permitting reform that sometimes conflicts with maximum agency deference. His record on healthcare and environmental regulation suggests support for agency authority, but his pro-market orientation places him more in the center on judicial deference to regulatory agencies.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Auchincloss backed the ERA, civil rights expansion legislation, and the Protecting Our Democracy Act — all reflecting a constitutional interpretation that extends rights to new contexts. He certified the 2020 election results against originalist-aligned challenges. His judicial nominees voting record reflects preference for judges with expansive rights frameworks over strict textualism.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Auchincloss directly sponsored legislation enacting stricter rules for police accountability (March 2021), demonstrating a concrete legislative commitment to reform. He co-sponsored the George Floyd Justice in Policing Act and supported body camera mandates and restricting chokeholds. He does not support defunding police but advocates for professional accountability standards.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Auchincloss sponsors police accountability legislation and opposes punitive-first approaches, but as a moderate New Democrat he has not explicitly advocated for deprioritizing enforcement of any specific crime category. His record suggests balanced prosecution priorities — reducing mandatory minimums for nonviolent offenses while maintaining vigorous prosecution of violent and property crimes.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Auchincloss sponsored the Protecting Our Democracy Act (December 2021), certified the 2020 election results, and supported Supreme Court ethics disclosure legislation. He has backed transparency requirements for judicial financial disclosures following reporting on Clarence Thomas. His record reflects support for mandatory ethics and disclosure standards for federal judges.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Auchincloss's 97% LCV lifetime score reflects consistent support for local environmental protection. He has backed EPA enforcement authority, clean water standards, and environmental justice provisions in the IRA. His MA-04 district (Newton, Brookline, Fall River) includes communities concerned about local air quality and water protection, and he has championed clean energy investment at the local level.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/', 'https://auchincloss.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Auchincloss backed the American Dream and Promise Act and DACA protections, and has supported limiting local law enforcement cooperation with ICE detainer requests. His immigration record positions him closer to sanctuary-city principles — prioritizing community trust over immigration enforcement at the local level — while accepting federal border enforcement as a separate matter.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Auchincloss supports the Affordable Care Act and improving current healthcare programs. He initially opposed H.R. 3 prescription drug pricing provisions as potentially limiting pharmaceutical innovation — a New Democrat position — before voting for the final bill. He does not co-sponsor Medicare for All but supports strengthening the existing public-private system and lowering the Medicare eligibility age.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Auchincloss authored legislation to raise the internet age of adulthood to 16, co-sponsored the bipartisan TikTok forced-sale law, and focused on tech platform accountability for harmful content. His AI and tech regulation work reflects support for targeted platform accountability measures addressing national security and children's risks — relevant to misinformation spread by AI-generated content and foreign state actors.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Auchincloss backed police accountability reform (George Floyd Act co-sponsor) while explicitly rejecting "defund the police." As a Marine veteran and moderate Democrat, he supports both accountability measures and adequate police funding. His public safety approach combines professional standards enforcement, community investment, and maintaining law enforcement capacity — placing him in the center between progressive reform and status quo.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Auchincloss sponsored the Protecting Our Democracy Act (December 2021), which included provisions to safeguard democratic processes including redistricting reforms. He backed the For the People Act's independent redistricting commission requirements and the John Lewis Voting Rights Act. His record reflects support for non-partisan redistricting over partisan gerrymandering.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Auchincloss sponsored legislation prohibiting immigration bans based on religion (April 2021) and is a member of the Congressional LGBTQ+ Equality Caucus. He co-sponsored the Equality Act, which does not include religious exemptions from anti-discrimination requirements. His record holds that civil rights law supersedes religious freedom claims in public accommodations and employment.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Auchincloss is a YIMBY Caucus member who prioritizes housing supply expansion over demand-side rent controls. He backed emergency rental assistance (American Rescue Plan) as a crisis measure. His abundance agenda positions him as favoring building more housing to address affordability rather than rent control, which he views as potentially reducing supply. He does not publicly champion rent regulation but supported temporary emergency assistance.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Auchincloss is the most prominent YIMBY in the MA delegation — he has explicitly advocated for ending single-family-only zoning, backed the HOMES Act using federal grants to incentivize local upzoning, and championed transit-oriented development. His abundance agenda explicitly names exclusionary zoning as a barrier to housing affordability and economic mobility that should be reformed federally.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Auchincloss is a member of the Congressional LGBTQ+ Equality Caucus, which advocates for full federal recognition and benefits for same-sex married couples. He voted YES on the Respect for Marriage Act (2022) codifying federal same-sex marriage recognition. He consistently supports full marriage equality with no religious exemptions from federal recognition.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Auchincloss has voted against federal private school voucher proposals and supported NEA-aligned education investment. His abundance agenda emphasizes public school funding and universal pre-K investment rather than voucher-based private alternatives. He has not been a champion of charter school expansion and prioritizes funding for traditional public schools in Newton and the rest of MA-04.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Auchincloss supports Social Security and has opposed benefit cuts. As a New Democrat and fiscal moderate, he has acknowledged the program's long-term solvency challenges and signaled openness to bipartisan reform — but only if it protects current beneficiaries. He does not endorse privatization or raising the retirement age, but his fiscal moderation places him closer to the center than progressive colleagues who oppose any adjustments.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '683c8084-2281-4920-a07c-18439b2dd413',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Auchincloss stated an explicitly anti-tariffs position in his 2020 campaign and advocates supply-side economics emphasizing free trade and innovation. He has criticized Trump-era and Biden-era tariffs as inflationary and counterproductive to US competitiveness. His abundance agenda includes reducing trade barriers and expanding market access as economic growth drivers.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Auchincloss supports higher taxes to balance the federal budget, citing President Clinton balanced budgets as the model. He backed the IRA's corporate minimum tax and has supported progressive tax reforms. However, as a New Democrat he has been more cautious about tax increases that could affect innovation-driven businesses and investment in his tech-corridor district.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Auchincloss is a member of the Congressional LGBTQ+ Equality Caucus and voted NO on the Protection of Women and Girls in Sports Act (2023). He co-sponsored the Equality Act prohibiting discrimination based on gender identity in all public accommodations including sports. His record supports inclusive policies allowing transgender athletes to compete consistent with their gender identity.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Auchincloss supported the Infrastructure Investment and Jobs Act and secured MBTA Green Line Extension and commuter rail investments for MA-04 (Newton, Brookline area). His abundance agenda includes transit-oriented development investment and electrification of transportation infrastructure. He has backed federal grants for MBTA reliability improvements and electric bus procurement.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Auchincloss is a member of the Congressional Ukraine Caucus and voted 100% with President Biden (FiveThirtyEight), who consistently requested Ukraine aid packages. He has been a vocal supporter of Ukraine military and economic assistance, framing it as essential US national security investment. He voted YES on Ukraine supplemental aid packages and opposed efforts to condition or reduce aid.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://en.wikipedia.org/wiki/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Auchincloss / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41945b74-325e-4fa2-9cc9-edd11ead9ed3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Auchincloss sponsored voter registration and access expansion legislation (February 2021), certified the 2020 election results against challenges, and backed the For the People Act and John Lewis Voting Rights Advancement Act. He opposes voter suppression measures and supports automatic voter registration and expanded early voting access.$$,
        ARRAY['https://auchincloss.house.gov/issues', 'https://ballotpedia.org/Jake_Auchincloss']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '41945b74-325e-4fa2-9cc9-edd11ead9ed3';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '41945b74-325e-4fa2-9cc9-edd11ead9ed3'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '41945b74-325e-4fa2-9cc9-edd11ead9ed3'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
