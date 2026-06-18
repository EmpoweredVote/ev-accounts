-- ============================================================================
-- Migration 329: Mark Warner Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Mark Warner (US Senator from Virginia).
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
-- Mark Warner
-- ============================================================

-- ----- Mark Warner / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Warner cosponsored the Women's Health Protection Act (S.1975, 117th Congress) to codify abortion access into federal law. OnTheIssues documents his consistent stance: 'access safe, legal abortion without restrictions' and 'ban anti-abortion service limitations.' He supports Planned Parenthood funding (confirmed pro-Planned Parenthood per CC survey, Sep 2020) and opposes restrictions on federal family planning funding. His record is consistently and strongly pro-choice across his full Senate tenure.$$,
        ARRAY['https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://www.congress.gov/bill/117th-congress/senate-bill/1975/cosponsors']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Warner led the RESTRICT Act (S.686, 118th Congress, introduced March 7, 2023) as primary sponsor — bipartisan legislation requiring the Commerce Department to identify and mitigate foreign-controlled technology threats like TikTok. He co-led the 2024 PAFACA (Protecting Americans from Foreign Adversary Controlled Applications Act, H.R.7521), which became law April 24, 2024. As Senate Intelligence Committee Chair 2021-2024, he held hearings on AI election deepfakes and co-sponsored the Protect Elections from Deceptive AI Act (S.2770, 118th Congress). His record is strongly in favor of proactive government guardrails on AI and foreign-controlled platforms.$$,
        ARRAY['https://www.congress.gov/bill/118th-congress/senate-bill/686',
              'https://www.congress.gov/bill/118th-congress/house-bill/7521/text',
              'https://www.congress.gov/bill/118th-congress/senate-bill/2770',
              'https://thehill.com/policy/technology/4528868-senate-intel-chiefs-express-support-for-house-passed-bill-that-could-ban-tiktok/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Warner cosponsored the DISCLOSE Act (S.443, 117th Congress) to require disclosure of independent campaign expenditures following Citizens United. OnTheIssues documents his longstanding position: 'no PAC contributions; yes full disclosure' (Nov 1996) and 'require full disclosure of independent expenditures' (Jul 2012). He supports a small-donor matching fund system and consistently calls out unlimited dark money in politics. His record is fully pro-reform and pro-transparency.$$,
        ARRAY['https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://www.congress.gov/bill/117th-congress/senate-bill/443']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Warner cosponsored the Equality Act (S.1006, 115th Congress, May 2017; and S.1503, 119th Congress 2025) to prohibit discrimination based on sexual orientation and gender identity. He sponsored S.1114 (115th Congress, 2017) to nullify a Trump executive order laying the foundation for LGBTQ discrimination under religious freedom pretext. He voted to extend hate crimes to include sexual orientation (Nov 2001). His record is one of consistent, proactive support for federal civil rights expansion.$$,
        ARRAY['https://www.congress.gov/bill/115th-congress/senate-bill/1006/cosponsors',
              'https://www.congress.gov/bill/119th-congress/senate-bill/1503/cosponsors',
              'https://ontheissues.org/Senate/Mark_Warner.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Warner voted for the Inflation Reduction Act (H.R.5376, Senate Vote #325, Aug 7, 2022) — the largest climate investment in US history at $430B+ in clean energy spending. He co-introduced the Build Green Act and Buy Green Act, provisions of which were incorporated into the IRA. However, OnTheIssues documents an 'all-of-the-above' energy approach: as Governor he negotiated a Clean Air Act settlement rather than a coal phase-out, and he has supported offshore drilling with revenue-sharing conditions. He consistently votes for climate action while maintaining a moderate energy-industry posture.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2022/s325',
              'https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://ontheissues.org/International/Mark_Warner_Energy_+_Oil.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Warner opposes mass deportation and has raised alarms about ICE overreach. In 2025 he stated 'This brutal crackdown has to end' and said he 'cannot and will not vote to fund DHS while this administration continues these violent federal takeovers.' He also expressed being 'greatly afraid' ICE could be used for voter intimidation. His overall record is strongly protective of due process and opposed to mass deportation, though his centrist instinct keeps him at 2 rather than the pure anti-enforcement end.$$,
        ARRAY['https://thehill.com/homenews/senate/5683745-warner-resists-ice-funding-freeze/',
              'https://thehill.com/homenews/senate/5724623-trump-nationalize-voting-ice-concern/',
              'https://thehill.com/homenews/5178047-senator-mark-warner-trump-immigration/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Warner is a self-made tech billionaire with a venture capital and cellular telecom background who promoted business-friendly economic development as Virginia Governor. OnTheIssues rates him 83% by UFCW (pro-labor) alongside a record of promoting minority- and women-owned business contracting and bipartisan business engagement. He co-sponsored the CHIPS Act and supported the Bipartisan Infrastructure Law. His economic positioning is genuinely centrist — pro-labor in Senate votes but with a consistent pro-business-development orientation from his pre-political career.$$,
        ARRAY['https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://www.govtrack.us/congress/members/mark_warner/412321']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Warner's fossil fuel record is mixed. As Governor he negotiated a 2003 Clean Air Act settlement requiring Dominion Resources to reduce coal plant emissions — but OnTheIssues labels him a 'pro-coal Democrat' with an 'all-of-the-above' energy approach. He opposes ANWR drilling but has supported offshore drilling if states receive revenue shares (2017). He voted for the IRA (2022) which advances clean energy but also included natural gas provisions. His record occupies the moderate middle — neither a phase-out advocate nor a deregulation supporter.$$,
        ARRAY['https://ontheissues.org/International/Mark_Warner_Energy_+_Oil.htm',
              'https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://www.washingtonpost.com/local/virginia-politics/virginia-lawmakers-split-over-off-shore-drilling/2017/04/28/ff7504a6-2b80-11e7-be51-b3fc6ff7faee_story.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Warner voted for the ACA and opposed all repeal attempts, including voting no on the American Health Care Act (Senate Vote #167, July 25, 2017). He supported the $900B COVID relief bill (Dec 2020) and $1.9T ARPA (Mar 2021). He supports ACA Medicaid expansion, extended marketplace subsidies via the IRA, and Medicare drug price negotiation. He does not support single-payer or Medicare for All — his position is expand access via ACA and public options rather than replace the private system.$$,
        ARRAY['https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://www.govtrack.us/congress/votes/115-2017/s167',
              'https://www.washingtonpost.com/local/va-politics/gade-warner-debate-healthcare/2020/10/13/87a0aa92-0cf1-11eb-8a35-237ef1eb2ef7_story.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Warner cosponsored the Neighborhood Homes Investment Act (S.657, 118th Congress, July 27, 2023) — bipartisan legislation to incentivize affordable housing development in distressed communities. He serves on the Senate Banking, Housing, and Urban Affairs Committee and has focused on affordable housing investment. OnTheIssues notes he 'eliminated the Family Rule restricting unrelated couples from purchasing homes' as Governor. His record leans toward housing as a public concern requiring investment, though no rent control or strong tenant-rights legislation is on his federal record.$$,
        ARRAY['https://www.congress.gov/bill/118th-congress/senate-bill/657/cosponsors',
              'https://ontheissues.org/Senate/Mark_Warner.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Warner was part of the bipartisan Gang of Eight that introduced S.744 (Border Security, Economic Opportunity, and Immigration Modernization Act, 2013) — comprehensive reform including a path to citizenship, which passed the Senate 68-32. He cosponsored a path to citizenship for DREAMers (Sep 2020), sponsored bills to increase high-skill and family-based visa caps (Apr 2019), and sponsored legislation blocking religion-based immigration bans (May 2021). His record is pro-reform and pro-comprehensive immigration, with a moderate bipartisan temperament rather than open-borders advocacy.$$,
        ARRAY['https://www.congress.gov/bill/113th-congress/senate-bill/744',
              'https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://www.washingtonpost.com/news/post-politics/wp/2014/06/26/timeline-the-rise-and-fall-of-immigration-reform/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Warner voted for the First Step Act (2018), which passed 87-12 — bipartisan sentencing reform and recidivism reduction legislation. OnTheIssues records his stated priority as 'reduce recidivism & mass incarceration' (Dec 2018). He cosponsored the Justice in Policing Act (S.3912, 116th Congress, Sep 2020). He is rated 64% by police associations, reflecting a reform-oriented stance without abolitionist positioning — consistently supporting alternatives to incarceration over harsh mandatory minimums.$$,
        ARRAY['https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://www.congress.gov/bill/116th-congress/senate-bill/3912',
              'https://www.washingtonpost.com/politics/senate-overwhelmingly-backs-overhaul-of-criminal-justice-system/2018/12/18/89efffb6-02e7-11e9-9122-82e98f91ee6f_story.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Warner cosponsored the Justice in Policing Act (S.3912, Sep 2020), which would have banned chokeholds, established a national police misconduct registry, and limited qualified immunity. OnTheIssues notes he was endorsed by the Virginia Police Benevolent Association in 2008 and rated 64% by NAPO (National Association of Police Organizations) as of Dec 2014. He supports reform and accountability measures but also backs law enforcement funding — a reform-oriented without-extreme-accountability position.$$,
        ARRAY['https://www.congress.gov/bill/116th-congress/senate-bill/3912',
              'https://ontheissues.org/Senate/Mark_Warner.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Warner opposes privatizing Medicare and Social Security (OnTheIssues, Oct 2014) and stated he is 'warding off cuts to our most important social programs like Social Security and Medicare.' He voted for the IRA (2022), which includes landmark Medicare drug price negotiation provisions. He voted for the $900B COVID relief and $1.9T ARPA. He has sponsored Medicare-related access bills and consistently opposes Medicaid block-granting or cuts. His position is clearly protect and expand, though he has not advocated Medicare for All.$$,
        ARRAY['https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://www.govtrack.us/congress/votes/117-2022/s325',
              'https://www.congress.gov/member/mark-warner/W000805']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Warner co-led the RESTRICT Act (S.686, 2023) targeting foreign-controlled information technology threats. He cosponsored the Protect Elections from Deceptive AI Act (S.2770, 118th Congress) to ban AI-generated deepfake political ads. As Senate Intelligence Committee Chair he held hearings on AI election deepfakes and pressed major tech companies with Sen. Klobuchar to act against election disinformation (2024). He also called for Facebook, Twitter, and Google to safeguard against election disinformation (2020). His record strongly favors government action and platform accountability.$$,
        ARRAY['https://www.congress.gov/bill/118th-congress/senate-bill/686',
              'https://www.congress.gov/bill/118th-congress/senate-bill/2770',
              'https://thehill.com/policy/technology/4884807-klobuchar-warner-press-tech-leaders-to-take-action-against-election-related-disinformation/',
              'https://thehill.com/policy/technology/519863-warner-calls-for-facebook-twitter-and-google-to-safeguard-against/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$The Freedom to Vote Act (S.2747, 117th Congress), co-sponsored by Warner, includes federal anti-gerrymandering provisions and criteria for congressional redistricting. Warner publicly condemned a Virginia Supreme Court ruling that struck down a voter-approved redistricting plan, stating 'justice was not served in Virginia' and calling it a ruling 'against the will of the majority of voters.' His record is clearly pro-independent commission and anti-partisan gerrymandering.$$,
        ARRAY['https://www.congress.gov/bill/117th-congress/senate-bill/2747',
              'https://thehill.com/regulation/court-battles/5870541-warner-slams-court-ruling-on-virginia-redistricting-justice-was-not-served/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Warner cosponsored the Equality Act (S.1006, 115th Congress 2017; S.1503, 119th Congress 2025) — legislation that explicitly limits religious freedom exemptions from civil rights protections for LGBTQ individuals. He sponsored S.1114 (115th Congress, 2017) to nullify a Trump executive order 'laying a foundation for discrimination against LGBTQ individuals, women, religious minorities, and others under the pretext of religious freedom.' His record is consistently anti-discrimination over broad religious exemption.$$,
        ARRAY['https://www.congress.gov/bill/115th-congress/senate-bill/1006/cosponsors',
              'https://www.congress.gov/bill/115th-congress/senate-bill/1114',
              'https://www.congress.gov/bill/119th-congress/senate-bill/1503/text']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Warner voted for the Respect for Marriage Act (H.R.8404, Senate Vote #362, Nov 29, 2022), which passed 61-36 and federally protects same-sex and interracial marriages. After the vote, Warner and Sen. Kaine called on Virginia lawmakers to repeal the state's constitutional same-sex marriage ban. He publicly evolved to supporting same-sex marriage by 2013, and cosponsored the Equality Act multiple times to protect LGBTQ individuals from discrimination. His record is fully supportive of marriage equality.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2022/s362',
              'https://www.washingtonpost.com/politics/2022/11/29/respect-for-marriage-act-senate-vote/',
              'https://thehill.com/homenews/state-watch/3846466-virginias-senators-urge-state-legislature-to-repeal-same-sex-marriage-ban/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Warner explicitly opposes privatizing Social Security (OnTheIssues, Oct 2014), has called his opponents 'the major cheerleader' for Bush's failed privatization effort, and stated he is 'warding off cuts to our most important social programs like Social Security and Medicare.' He supports keeping the inheritance/estate tax. However, he also called for a bipartisan commission on entitlements with binding outcomes (Oct 2008) — a moderating factor that places him at 2 rather than a pure protect-at-all-costs position.$$,
        ARRAY['https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://www.ontheissues.org/Celeb/Mark_Warner_Social_Security.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '683c8084-2281-4920-a07c-18439b2dd413',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Warner cosponsored the Trade Review Act of 2025, requiring Congress to approve Trump's tariffs on trading partners — a direct check on unilateral tariff authority. He characterized Trump's 'America First' policy as 'quickly becoming America alone.' OnTheIssues documents consistent free-trade positions: supports NAFTA, GATT, WTO, and USMCA implementation; Export-Import Bank reauthorization (2014). He has taken targeted anti-China trade positions (Xinjiang forced-labor import ban) but his baseline is free trade with targeted exceptions.$$,
        ARRAY['https://thehill.com/homenews/senate/5236142-congress-tariff-bill-trump/',
              'https://thehill.com/homenews/senate/5222354-mark-warner-trump-america-first-policy/',
              'https://ontheissues.org/Senate/Mark_Warner.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Warner voted NO on the Tax Cuts and Jobs Act (Senate Votes #303 and #323, Dec 2017), which cut top corporate and individual rates. OnTheIssues documents his support for 'rolling back top-tier tax breaks' and 'undo tax cuts' (CC survey Sep 2020). He voted for the IRA (2022) which included a 15% corporate minimum tax and IRS funding restoration. As Virginia Governor he pushed a $1.4B tax increase to close a $6B budget shortfall. His record is clearly pro-progressive taxation, though he has not advocated for a wealth tax.$$,
        ARRAY['https://www.govtrack.us/congress/votes/115-2017/s303',
              'https://www.govtrack.us/congress/votes/115-2017/s323',
              'https://ontheissues.org/Senate/Mark_Warner.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Warner voted for the Bipartisan Infrastructure Law (2021), which included $89B for public transit — the largest federal transit investment in history. He specifically worked to preserve the bill's transit title in bipartisan negotiations and secured reauthorization funding for the Washington DC Metro system. He co-introduced the Build Green Act and Buy Green Act, which included provisions for electrifying school and transit buses, incorporated into the IRA. His record shows active investment in public transit and multimodal infrastructure.$$,
        ARRAY['https://www.congress.gov/event/117th-congress/senate-event/LC72808/text',
              'https://thehill.com/policy/energy-environment/566003-five-key-energy-components-of-the-bipartisan-infrastructure-bill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '24e9212c-b011-422a-865c-093e35050901',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Warner is among the most vocal Ukraine aid supporters in the Senate. As Senate Intelligence Committee Chair, he called congressional failure to pass Ukraine aid a 'tremendous gift' to Putin. He co-led Senate efforts to pass the 2024 foreign aid package (Senate voted 80-19 to advance it, signed April 24, 2024) — the Ukraine Security Supplemental Appropriations Act (H.R.8035) including billions in military funding. He stated military equipment would be 'in transit to Ukraine by next week' after passage and has supported all Ukraine supplemental appropriations from 2022 onward.$$,
        ARRAY['https://thehill.com/homenews/senate/4371927-warner-failure-to-pass-ukraine-aid-gift-putin/',
              'https://thehill.com/homenews/senate/4609587-warner-military-equipment-will-be-in-transit-to-ukraine-by-next-week-if-biden-signs-bill/',
              'https://www.congress.gov/bill/118th-congress/house-bill/8035/text']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Warner / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('85d27350-e1b6-45b8-aee3-509ca88c5af4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Warner cosponsored the Freedom to Vote Act (S.2747, 117th Congress) — comprehensive voting rights legislation including automatic voter registration, election security, and anti-gerrymandering provisions. He sponsored a voter registration expansion bill and an election holiday bill (Apr 2019, Mar 2021). He has expressed alarm about Trump using ICE for voter intimidation (2025). OnTheIssues confirms he 'champions voter registration expansion and election holiday.' His record is consistently at the strong expand-access end of the spectrum.$$,
        ARRAY['https://www.congress.gov/bill/117th-congress/senate-bill/2747',
              'https://ontheissues.org/Senate/Mark_Warner.htm',
              'https://thehill.com/homenews/senate/5726357-warner-donald-trump-election-effort-midterms/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 15 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '85d27350-e1b6-45b8-aee3-509ca88c5af4';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '85d27350-e1b6-45b8-aee3-509ca88c5af4'
--   AND pc.politician_id IS NULL;
--
-- Uncited context rows (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '85d27350-e1b6-45b8-aee3-509ca88c5af4'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
