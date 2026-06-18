-- ============================================================================
-- Migration 330: Tim Kaine Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Tim Kaine (US Senator from Virginia).
--
-- Topic scope: All 44 compass topics attempted; evidence-only — topics with no
--   evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production per CLAUDE.md).
--
-- Sources policy: aggregation indexes only (ballotpedia, ontheissues, govtrack, congress.gov).
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
-- Tim Kaine
-- ============================================================

-- ----- Tim Kaine / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Kaine's political/voting record is strongly pro-access despite his personal Catholic opposition to abortion. After Dobbs he co-introduced bipartisan legislation to codify abortion rights (with Collins, Murkowski, and Sinema, 2022). He voted for the Women's Health Protection Act (failed cloture vote, May 11, 2022). Pro-abortion-rights groups supported his selection as VP nominee. His legislative posture consistently defends access and opposes restrictions, regardless of personal faith.$$,
        ARRAY['https://thehill.com/homenews/senate/3604462-tim-kaines-role-on-abortion-bill-sparks-progressive-concerns/',
              'https://thehill.com/homenews/3851564-senators-reintroduce-bipartisan-bill-to-codify-roe/',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Kaine participated in a HELP subcommittee hearing on AI and workforce preparation — 'Reading the Room: Preparing Workers for AI' (September 25, 2024) — focused on worker-protective AI regulation. The PREPARED for AI Act (S.4495, 118th Congress), an AI accountability and oversight bill, was advanced in committee during Kaine's tenure on HELP. His focus on worker impacts suggests he leans toward proactive guardrails rather than pure industry self-governance, though no floor vote or primary sponsorship was found.$$,
        ARRAY['https://www.congress.gov/event/118th-congress/senate-event/LC73719/text',
              'https://www.congress.gov/bill/118th-congress/senate-bill/4495/all-actions']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Kaine co-sponsored S.1 (For the People Act of 2021, March 17, 2021), which included sweeping campaign finance disclosure and small-donor matching provisions. He also helped negotiate the Freedom to Vote Act (S.2747, 117th Congress) as a narrowed alternative. He has publicly called Citizens United destructive to democracy. His record consistently supports transparency requirements and limits on dark money in elections.$$,
        ARRAY['https://www.congress.gov/bill/117th-congress/senate-bill/1/cosponsors',
              'https://www.congress.gov/bill/117th-congress/senate-bill/2747',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Kaine has been an original cosponsor of the Child Care for Working Families Act in multiple Congresses: S.1354 (118th, cosponsored April 27, 2023) and S.2295 (119th, cosponsored July 15, 2025). The bill subsidizes childcare for low- and moderate-income families based on a sliding-scale income formula. He also advocated for the childcare provisions in Build Back Better (2021) as a HELP Committee member. His record reflects sustained support for publicly-funded childcare expansion.$$,
        ARRAY['https://www.congress.gov/bill/118th-congress/senate-bill/1354/cosponsors',
              'https://www.congress.gov/bill/119th-congress/senate-bill/2295/cosponsors']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Kaine cosponsored the Equality Act in the 118th Congress (S.5, 2023-2024) and 119th Congress (S.1503, 2025-2026), prohibiting discrimination on the basis of sex, gender identity, and sexual orientation. He has supported the George Floyd Justice in Policing Act and worked on bipartisan resolutions to advance LGBTQ equality. During his 2016 VP vetting he was described by civil rights lawyers as the strongest fair-housing advocate on a national ticket since Walter Mondale.$$,
        ARRAY['https://www.congress.gov/bill/118th-congress/senate-bill/5/text',
              'https://www.congress.gov/bill/119th-congress/senate-bill/1503/text',
              'https://rollcall.com/2019/06/21/is-tim-kaine-a-swiftie-senator-signs-musicians-petition-to-pass-equality-act/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Kaine voted for the Inflation Reduction Act (H.R.5376, Senate vote #325, August 7, 2022) — the largest U.S. climate investment in history. As Virginia governor he championed renewable energy goals (25% renewable by 2025). He wrote a Washington Post op-ed calling on Obama to block the Keystone XL pipeline (2013). He has consistently opposed EPA budget cuts and supported clean energy transition legislation throughout his Senate career.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2022/s325',
              'https://www.washingtonpost.com/opinions/tim-kaine-keystone-xl-pipeline-should-be-stopped/2013/06/20/5c160bb4-d852-11e2-a9f2-42ee3912ae0e_story.html',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$In 2025 Kaine forced Senate votes to compel the Trump administration to disclose human rights conditions in six countries to which migrants were deported without being citizens of those countries. He has said ICE and CBP should not invade homes without warrants, should wear body cameras, and not wear masks. He opposed the Muslim travel ban and Syrian refugee ban. His 2025-2026 record consistently challenges mass deportation operations and demands due process protections.$$,
        ARRAY['https://www.washingtonpost.com/politics/2025/08/01/kaine-democrats-force-votes-trump/',
              'https://thehill.com/homenews/senate/5773976-kaine-miller-dhs-control/',
              'https://thehill.com/homenews/senate/5774045-kaine-ice-cbp-funding/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kaine reversed his earlier support for right-to-work in 2016 to oppose it, aligning with labor union priorities. He sponsors labor and employment bills on the HELP Committee and supports collective bargaining for public employees. As governor he pursued public-private partnerships for economic growth. He has supported the PRO Act direction through HELP Committee work. His record is center-left — consistently pro-worker in Senate votes while maintaining a practical approach to business development.$$,
        ARRAY['https://thehill.com/blogs/pundits-blog/labor/295436-kaine-suddenly-abandons-right-to-work-and-majority-of-americans/',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Kaine's fossil fuel record is genuinely mixed. He wrote a 2013 op-ed opposing Keystone XL and voted for the IRA's clean energy provisions. However, he has self-described as 'a pro-pipeline senator,' explicitly supported fracking for natural gas expansion, and co-championed offshore oil and gas development in the Atlantic as both governor and senator. In 2023 he introduced an amendment to strip Manchin's Mountain Valley Pipeline provision from the debt ceiling bill but cited procedural concerns. Environmental groups have specifically faulted him for being too favorable to fracking. His record occupies the moderate middle.$$,
        ARRAY['https://www.washingtonpost.com/opinions/tim-kaine-keystone-xl-pipeline-should-be-stopped/2013/06/20/5c160bb4-d852-11e2-a9f2-42ee3912ae0e_story.html',
              'https://thehill.com/policy/energy-environment/4030235-kaine-introduces-amendment-to-strip-manchin-backed-pipeline-from-debt-ceiling-bill/',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kaine has been a consistent ACA defender and supporter of expanding it with a public option. As a HELP Committee member he advocated for Medicare drug price negotiation (enacted in IRA 2022) and Medicaid expansion. He voted against all Republican ACA repeal bills and supported the Build Back Better ACA subsidy extensions. He has stated healthcare must not be a privilege and opposed any bill that did not address skyrocketing exchange premiums. His record is clearly pro-access without reaching single-payer advocacy.$$,
        ARRAY['https://ontheissues.org/Senate/Tim_Kaine.htm',
              'https://www.govtrack.us/congress/votes/117-2022/s325']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kaine cosponsored the LIFT Homebuyers Act (S.2797, 2021) and the Downpayment Toward Equity Act of 2025 (S.967) for first-generation homebuyers. During the 2016 campaign he highlighted mortgage redlining and housing discrimination. His focus is primarily on homeownership access and supply-side affordability. Less direct record on rent stabilization or tenant protections at the federal level, placing him between strong housing-as-right advocacy and market-only approaches.$$,
        ARRAY['https://www.congress.gov/bill/117th-congress/senate-bill/2797/text',
              'https://www.congress.gov/bill/119th-congress/senate-bill/967/text',
              'https://www.washingtonpost.com/news/wonk/wp/2016/08/12/tim-kaine-just-called-out-donald-trumps-history-of-housing-discrimination/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Kaine was an early Senate supporter of the Gang of Eight comprehensive immigration reform bill (S.744, 2013), delivering a floor speech entirely in Spanish to highlight the bill's importance. He has consistently supported the DREAM Act and DACA protections. He opposed the Muslim travel ban and Syrian refugee bans. His 2025 record shows strong opposition to Trump's enforcement-first posture. His comprehensive reform stance and path-to-citizenship support place him firmly at the welcoming end of the scale.$$,
        ARRAY['https://www.congress.gov/bill/113th-congress/senate-bill/744',
              'https://www.washingtonpost.com/politics/tim-kaine-voices-support-for-immigration-bill-on-senate-floor-entirely-in-spanish/2013/06/11/8a146ece-d2a9-11e2-a73e-826d299ff459_story.html',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$As Virginia governor Kaine released non-violent inmates early and mandated police body cameras. He has acknowledged racial biases in criminal justice and supported reducing mass incarceration. His earlier record as Richmond Mayor included support for Project Exile (mandatory minimums) — a position he later acknowledged had disparate impact on Black Americans, reflecting evolution toward reform. He opposes the death penalty and supported the George Floyd Justice in Policing Act (H.R.1280, passed House March 2021).$$,
        ARRAY['https://ontheissues.org/Senate/Tim_Kaine.htm',
              'https://www.congress.gov/bill/117th-congress/house-bill/1280']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Kaine voted NO on confirming Brett Kavanaugh (Senate vote #223, October 6, 2018) and NO on Amy Coney Barrett's confirmation (2020) — both strong originalists/textualists. He voted YES on Ketanji Brown Jackson (2022), who represents a more expansive interpretive approach. His confirmation vote pattern reflects preference for nominees with a broader view of constitutional rights, though he is not a prominent public advocate for any specific judicial philosophy.$$,
        ARRAY['https://www.govtrack.us/congress/votes/115-2018/s223',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Kaine supported the George Floyd Justice in Policing Act (H.R.1280, 117th Congress), which would limit qualified immunity, ban chokeholds and no-knock warrants, and establish anti-racial-profiling standards. As Virginia governor he required police body cameras statewide. In 2025 he explicitly demanded ICE and CBP wear body cameras and obtain warrants before entering homes. His record consistently supports strong accountability mechanisms for law enforcement at every level of government.$$,
        ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/1280',
              'https://thehill.com/homenews/senate/5774045-kaine-ice-cbp-funding/',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Kaine has said Congress should defund ICE and CBP pending reform, and has demanded these agencies obtain warrants before entering homes and wear body cameras (The Hill, June 2026). In 2025 he forced Senate votes on deportation conditions to countries migrants are not citizens of. His current posture is fully sanctuary-leaning with strong opposition to ICE enforcement practices, demanding accountability and warrant requirements that mirror sanctuary city policies.$$,
        ARRAY['https://thehill.com/homenews/senate/5774045-kaine-ice-cbp-funding/',
              'https://thehill.com/homenews/senate/5773976-kaine-miller-dhs-control/',
              'https://www.washingtonpost.com/politics/2025/08/01/kaine-democrats-force-votes-trump/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Kaine opposes Social Security and Medicare privatization and cuts, stating he would 'never, ever risk Social Security with privatization.' He voted for the IRA's Medicare drug price negotiation provisions (2022). With Sen. Cassidy he explored a bipartisan Social Security solvency mechanism focused on preserving benefits rather than cutting them. He vocally opposed Trump administration statements about Social Security cuts in 2024. OnTheIssues records a 100% rating from Americans Retire Alliance for pro-Trust Fund positions.$$,
        ARRAY['https://thehill.com/homenews/senate/5390675-social-security-trust-fund-investment-proposal/',
              'https://ontheissues.org/Senate/Tim_Kaine.htm',
              'https://thehill.com/homenews/senate/4527467-democrats-go-on-offense-as-trump-floats-social-security-cuts/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Kaine has been a leading Senate voice on gun safety since the 2007 Virginia Tech shooting, during which he was governor. He closed the background check loophole after VA Tech, cosponsored the Background Check Expansion Act (S.529, 117th Congress) and the Assault Weapons Ban of 2021 (S.736), and participated in the 2016 Senate floor sit-in for gun legislation. He introduced the 'Virginia Plan' gun safety bill with Warner in April 2021 (Washington Post, April 15, 2021). His approach consistently prioritizes root-cause prevention over enforcement-only responses to public safety.$$,
        ARRAY['https://www.congress.gov/bill/117th-congress/senate-bill/736/cosponsors',
              'https://www.congress.gov/bill/117th-congress/senate-bill/529/all-info',
              'https://www.washingtonpost.com/local/virginia-politics/kaine-warner-guns-virginia/2021/04/15/76d03c20-9e0d-11eb-8005-bffc3a39f6d3_story.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Kaine cosponsored S.1 (For the People Act of 2021, March 17, 2021), which required states to establish independent redistricting commissions for congressional maps. He also helped negotiate the Freedom to Vote Act (S.2747), a narrower bill with redistricting reform provisions. He wrote a Washington Post op-ed in September 2021 tying the January 6 attack to the need for voting and redistricting reform. His record is consistently anti-gerrymandering and pro-independent commission.$$,
        ARRAY['https://www.congress.gov/bill/117th-congress/senate-bill/1/cosponsors',
              'https://www.washingtonpost.com/opinions/2021/09/17/tim-kaine-jan-6-attack-protect-voting-rights/',
              'https://www.congress.gov/bill/117th-congress/senate-bill/2747']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Kaine cosponsored the Equality Act in the 118th (S.5) and 119th Congresses (S.1503), which explicitly limits religious exemptions as a defense against anti-discrimination protections for LGBTQ people. While personally Catholic, he has consistently voted to prioritize anti-discrimination protections over broad religious exemptions. He also vocally opposed Betsy DeVos's education agenda, which included religious school carve-outs from accountability requirements. His record places him firmly at the anti-discrimination end of this axis.$$,
        ARRAY['https://www.congress.gov/bill/118th-congress/senate-bill/5/text',
              'https://www.congress.gov/bill/119th-congress/senate-bill/1503/text',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Kaine announced support for same-sex marriage during his 2012 Senate race — ahead of many Democrats at that time. He voted for the Respect for Marriage Act (H.R.8404, Senate vote #362, November 29, 2022), which codified marriage equality in federal law. He and Warner called on Virginia's legislature to repeal the state's constitutional ban on same-sex marriage. In January 2017 he presided over a same-sex wedding on Inauguration Night, and has stated he believes the Catholic Church will ultimately change its teaching on the issue.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2022/s362',
              'https://thehill.com/homenews/state-watch/3846466-virginias-senators-urge-state-legislature-to-repeal-same-sex-marriage-ban/',
              'https://rollcall.com/2017/01/23/kaine-spent-inauguration-night-presiding-over-same-sex-wedding/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Kaine cosponsored the Keep Public Funds in Public Schools Act (S.4297, 119th Congress, April 2026), which directly opposes diverting public funds to private and religious schools. He vocally opposed Betsy DeVos's nomination as Education Secretary in 2017, citing Virginia's history of school segregation and 'Massive Resistance' to oppose voucher-style schemes. As governor he championed public higher education funding. His record is consistently and strongly anti-voucher.$$,
        ARRAY['https://www.congress.gov/bill/119th-congress/senate-bill/4297/cosponsors',
              'https://www.washingtonpost.com/news/education/wp/2017/01/31/in-opposing-trumps-education-pick-kaine-cites-virginias-ugly-history-on-school-segregation/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Kaine opposes privatization of Social Security, stating he would 'never, ever risk Social Security with privatization.' He has proposed lifting the Social Security payroll tax cap above $128,000 to strengthen the Trust Fund. With Sen. Cassidy he explored a bipartisan solvency mechanism focused on preserving benefits rather than cutting them. He vocally opposed Trump administration statements about Social Security cuts in 2024. OnTheIssues records a 100% rating from the Americans Retire Alliance for pro-Trust Fund positions.$$,
        ARRAY['https://ontheissues.org/Senate/Tim_Kaine.htm',
              'https://thehill.com/homenews/senate/5390675-social-security-trust-fund-investment-proposal/',
              'https://thehill.com/homenews/senate/4527467-democrats-go-on-offense-as-trump-floats-social-security-cuts/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '683c8084-2281-4920-a07c-18439b2dd413',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Kaine has been the Senate's most active anti-tariff legislator since 2025. He introduced a bipartisan joint resolution (with Rand Paul) that passed the Senate 51-48 in April 2025 to end Trump's Canada tariffs. He co-introduced a similar resolution on Brazil tariffs that passed 52-48 (October 2025). He introduced the Reclaim Trade Powers Act (S.4049, March 2026) to restore congressional authority over tariffs. He also voted for TPP and USMCA. His position is strongly free-trade and anti-unilateral executive tariffs.$$,
        ARRAY['https://rollcall.com/2025/04/02/four-republicans-help-democrats-pass-measure-to-end-canadian-tariffs/',
              'https://www.washingtonpost.com/opinions/2025/03/27/trump-kaine-tariffs-canada/',
              'https://www.washingtonpost.com/opinions/2025/10/29/kaine-paul-senate-votes-trump-tariffs/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Kaine consistently supports higher taxes on the wealthy. He opposed extending Bush-era tax cuts for top earners, proposed lifting the Social Security payroll tax cap, and criticized 'budget-busting tax cuts' and corporate loopholes. He voted for the Inflation Reduction Act (2022), which included a 15% minimum corporate tax and a stock buyback tax. He has stated the Trump 2017 tax plan repeated the failed approach of the 2000s tax cuts that contributed to the Great Recession.$$,
        ARRAY['https://ontheissues.org/Senate/Tim_Kaine.htm',
              'https://www.govtrack.us/congress/votes/117-2022/s325']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$All Senate Democrats voted as a bloc to block the Protection of Women and Girls in Sports Act (failed 51-45, March 2025) and a subsequent amendment in March 2026 (failed 49-41 party-line vote). Kaine was part of that Democratic bloc in both votes. He is a cosponsor of the Equality Act (S.1503, 119th Congress), which prohibits discrimination based on gender identity and implicitly protects trans participation. No evidence of Kaine breaking with Democrats on trans-inclusive sports legislation.$$,
        ARRAY['https://www.washingtonpost.com/education/2025/03/03/senate-vote-transgender-athletes-womens-sports/',
              'https://www.washingtonpost.com/politics/2026/03/21/senate-trump-transgender-sports/',
              'https://www.congress.gov/bill/119th-congress/senate-bill/1503/text']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Kaine voted for the Infrastructure Investment and Jobs Act (H.R.3684, Senate vote #314, August 10, 2021), which provided $22 billion for Amtrak and over $102 billion for passenger rail, plus major public transit funding. As Virginia governor he championed transit-oriented development and rail expansion in the Washington metro region. He has advocated for expanded transit as both a climate and an economic equity tool. His IIJA vote and Virginia transit record firmly establish his multimodal transit priority.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2021/s314',
              'https://www.congress.gov/bill/117th-congress/house-bill/3684',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '24e9212c-b011-422a-865c-093e35050901',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Kaine is one of the Senate's strongest Ukraine supporters. He voted for the $95 billion Ukraine-Israel-Taiwan supplemental aid package (Senate vote, April 23, 2024, 79-18). As a Senate Foreign Relations Committee member he championed Ukraine aid legislation and co-sponsored war powers measures to maintain congressional oversight. In November 2024 he was pushing for additional lame-duck Ukraine funding before the Trump transition. His record consistently places him among Democrats' most vocal Ukraine advocates.$$,
        ARRAY['https://www.washingtonpost.com/politics/2024/04/23/senate-vote-foreign-aid-ukraine-israel/',
              'https://thehill.com/policy/international/4989155-senate-democrat-sees-a-chance-of-more-ukraine-funding-in-lame-duck-session/',
              'https://rollcall.com/2024/04/23/aid-finally-set-to-flow-as-senate-clears-95-3b-emergency-bill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tim Kaine / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8cffe7a0-b56c-42fe-adbf-f57d63589973',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Kaine cosponsored S.4 (John R. Lewis Voting Rights Advancement Act, 117th Congress), S.1 (For the People Act, 2021), and the Freedom to Vote Act (S.2747). He wrote a Washington Post op-ed in September 2021 calling on Congress to pass voting rights legislation in response to January 6. He opposes photo ID requirements, supports early voting expansion, automatic voter registration, and Election Day as a federal holiday. He has called voter suppression 'the worst kind of political corruption.'$$,
        ARRAY['https://www.congress.gov/bill/117th-congress/senate-bill/4/text',
              'https://www.washingtonpost.com/opinions/2021/09/17/tim-kaine-jan-6-attack-protect-voting-rights/',
              'https://ontheissues.org/Senate/Tim_Kaine.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 15 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8cffe7a0-b56c-42fe-adbf-f57d63589973';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '8cffe7a0-b56c-42fe-adbf-f57d63589973'
--   AND pc.politician_id IS NULL;
--
-- Uncited context rows (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '8cffe7a0-b56c-42fe-adbf-f57d63589973'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
--
-- VA-STANCES-02 closure (both senators must have >= 15 stances):
-- SELECT external_id, COUNT(*) AS stance_count
-- FROM inform.politician_answers pa
-- JOIN essentials.politicians p ON p.id = pa.politician_id
-- WHERE p.external_id IN (-400079, -400080)
-- GROUP BY external_id ORDER BY external_id;
