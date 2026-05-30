-- ============================================================================
-- Migration 198: U.S. Senate Candidate Stances — Batch 2 of 3 (KY → MN)
-- ============================================================================
-- Purpose: Insert/upsert federal stance data for 13 non-incumbent 2026
--   Senate candidates.
--
-- Topic scope: 30 federal-applicable topics (excludes city-level keys; data-centers excluded)
--
-- Post-state: ~276 rows expected
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- deportation                      44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                     4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                    c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-interpretation          448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                   ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                6b9ba6d9-1001-43f5-b073-4d37130696fd
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- social-security                  87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                          683c8084-2281-4920-a07c-18439b2dd413
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- ukraine-support                  24e9212c-b011-422a-865c-093e35050901
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- ============================================================
-- Andy Barr
-- ============================================================

-- ----- Andy Barr / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Barr identifies as strongly pro-life and has co-sponsored the Life at Conception Act seeking 14th Amendment protections from fertilization. He voted for the Pain-Capable Unborn Child Protection Act (20-week ban) and co-sponsored the Born-Alive Abortion Survivors Protection Act. He opposes all federal funding for abortion services.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Abortion.htm', 'https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Barr has called the ACA a '2,700-page job destroyer' and has consistently voted for full repeal. He signed the Contract from America pledging to 'defund, repeal and replace government-run health care' with market-based alternatives including tax credits for private insurance. He opposes any government-run or public option healthcare system.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Health_Care.htm', 'https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Barr voted for the 2017 Tax Cuts and Jobs Act and strongly opposes higher taxes on wealthy individuals. He supports a single-rate (flat) tax system, capital gains reductions, and complete repeal of the death tax 'with no expiration.' He signed the Contract from America backing constitutional limits on tax increases requiring a two-thirds majority.$$,
        ARRAY['https://www.ontheissues.org/Andy_Barr.htm', 'https://www.ontheissues.org/House/Andy_Barr_Budget_+_Economy.htm', 'https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Barr received a 0% rating from the Alliance for Retired Americans, indicating a pro-privatization stance on Social Security. He has supported prioritizing debt payments over Social Security in debt ceiling crises and has generally backed market-based reform over preserving the current guaranteed-benefit structure.$$,
        ARRAY['https://www.ontheissues.org/Andy_Barr.htm', 'https://www.ontheissues.org/House/Andy_Barr_Social_Security.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Barr's consistent support for full ACA repeal and market-based healthcare, combined with his 0% ARA rating indicating opposition to protecting entitlement programs, signals strong support for reducing Medicare and Medicaid. His overall budget philosophy demands spending caps and opposes expanding government health programs.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Health_Care.htm', 'https://www.ontheissues.org/Andy_Barr.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Barr disputes the scientific consensus on climate change, arguing 'Some say the science is settled. That's not true,' and signed the No Climate Tax Pledge. He opposes carbon tax implementation and invited backlash over the Green New Deal's coal impacts. His record reflects rejection of climate policy in favor of economic growth.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andy_Barr_(politician)', 'https://www.ontheissues.org/Andy_Barr.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Barr strongly supports coal production and offshore drilling, signing the No Climate Tax Pledge and opposing any restrictions on fossil fuel extraction. He withdrew an Alexandria Ocasio-Cortez invitation over concerns about the Green New Deal's impact on coal mining. His OTI profile documents strong opposition to green energy prioritization.$$,
        ARRAY['https://www.ontheissues.org/Andy_Barr.htm', 'https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Barr opposes same-sex marriage and backs a constitutional amendment to prohibit it, as documented in his Christian Coalition Voter Guide response. He signed the First Amendment Defense Act allowing faith-based opposition to same-sex unions and opposed the 2015 Supreme Court ruling legalizing same-sex marriage nationwide. He received a zero score from the Human Rights Campaign in the 114th Congress.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Civil_Rights.htm', 'https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Barr signed the First Amendment Defense Act protecting faith-based opposition to same-sex marriage and has consistently prioritized religious liberty over anti-discrimination protections. He opposes requiring religious groups to cover contraception or abortion in insurance and voted against barring federal contractors from discriminating based on sexual orientation.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Civil_Rights.htm', 'https://www.ontheissues.org/Andy_Barr.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Barr supports stricter border security and introduced a constitutional amendment to end birthright citizenship for children of undocumented immigrants. He has opposed pathways to citizenship and voted to prohibit DACA recipients from military service. While he co-sponsored the Fairness for High-Skilled Immigrants Act to increase employment visa caps, his overall record favors significant immigration restriction.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Immigration.htm', 'https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Barr co-sponsored the Deport Convicted Foreign Criminals Act, requiring quarterly congressional reports on uncooperative countries and mandating visa denials. He voted to prohibit DACA recipients from military service and has consistently opposed legal protections for undocumented immigrants, favoring enforcement-first approaches.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Immigration.htm', 'https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Barr received a zero score from the Human Rights Campaign and voted against the Maloney Amendment barring federal contractors from discriminating based on sexual orientation or gender identity. He opposes affirmative action-style policies and has prioritized religious freedom over anti-discrimination protections, with the ACLU comparing his stance to '1960s racism.'$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Civil_Rights.htm', 'https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Barr voted against the For the People Act of 2019, opposing provisions for Election Day as a federal holiday and same-day voter registration, citing fraud concerns aligned with Heritage Foundation arguments. His government reform positions emphasize constitutional accountability over expanding voter access.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Government_Reform.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Barr voted to reauthorize the SOAR Act funding private school vouchers in D.C. and voted for the A-PLUS Amendment allowing states to redirect federal education funds to any lawful educational purpose, including private schooling. He supports these as ways to 'break the link of low-income and low-quality schools' through choice.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Education.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Barr co-sponsored the Sugar Reform Act establishing import tariffs and marketing allotments to protect domestic sugar producers, reflecting selective protectionism for specific industries. The OnTheIssues profile notes he 'opposes expansion' of free trade and 'sponsored sugar quotas and import tariffs,' suggesting a mixed approach rather than blanket free trade or blanket protectionism.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Free_Trade.htm', 'https://www.ontheissues.org/Andy_Barr.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Barr's zero HRC score, consistent opposition to LGBTQ anti-discrimination protections, and strong alignment with social conservative positions indicate strong opposition to allowing transgender athletes to compete according to their gender identity. He has supported legislation prioritizing biological sex classifications in federal contexts.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andy_Barr_(politician)', 'https://www.ontheissues.org/House/Andy_Barr_Civil_Rights.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Barr signed the Contract from America opposing earmarks and supporting fiscal discipline, and his general record aligns with reducing campaign finance restrictions. He has not supported major disclosure or contribution limit legislation and his philosophy favors less government regulation of political speech and spending.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Government_Reform.htm', 'https://www.ontheissues.org/Andy_Barr.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '24e9212c-b011-422a-865c-093e35050901',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Barr has not taken a notably hawkish or isolationist public position on Ukraine aid. As a House Financial Services Committee member focused on domestic fiscal discipline, he has expressed concern about foreign spending, but his specific Ukraine voting record is not prominently documented in available sources.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Barr voted YES on CISPA in 2013 favoring private-government cybersecurity data sharing, and his broader record strongly emphasizes free speech and opposition to government regulation of online content. His conservative alignment suggests strong opposition to government content moderation mandates.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Technology.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andy Barr / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d297f5-5319-4be1-b938-6bcce63368e7',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Barr voted against the For the People Act of 2019, which included provisions for independent nonpartisan redistricting commissions. His government reform positions emphasize state legislative control and oppose federally mandated redistricting reform, aligning with allowing the controlling party to draw maps.$$,
        ARRAY['https://www.ontheissues.org/House/Andy_Barr_Government_Reform.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Charles Booker
-- ============================================================

-- ----- Charles Booker / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Booker has consistently advocated for Medicare for All as a single-payer system across his 2020, 2022, and 2026 campaigns. His personal experience rationing insulin due to cost as a child animates this position. Wikipedia notes he "consistently supports single-payer healthcare in the form of Medicare for All."$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Booker opposes Kentucky's abortion ban and supports enshrining abortion rights into federal law, while acknowledging he holds differing personal beliefs on the issue. He supports Planned Parenthood funding and publicly funded abortion access. His stance is consistently pro-choice but he has acknowledged the complexity of his personal views, placing him at stance 2 rather than 1.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Booker supports the Green New Deal and opposes U.S. withdrawal from the Paris Climate Agreement, and was endorsed by the Sunrise Movement for his climate advocacy. He supports stopping new offshore oil drilling and opposes drilling in the Alaska National Wildlife Refuge.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Booker opposes offshore oil drilling expansion and drilling in the Alaska Wildlife Refuge, and supports increased climate regulations. His endorsement by the Sunrise Movement and Green New Deal support indicate opposition to new fossil fuel permitting, consistent with stance 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Booker supports birthright citizenship, sanctuary city federal funding, in-state tuition for undocumented immigrants, and opposes the border wall. He has called for abolishing ICE and opposes increased border security restrictions, placing him solidly at stance 2 (significantly expand legal immigration and create easy citizenship pathways).$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Booker has called for abolishing ICE and supports healthcare access and in-state tuition for undocumented immigrants. He opposes increased border security restrictions and supports sanctuary cities. His overall posture is to provide legal status broadly rather than pursue mass deportation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Booker supports raising taxes on wealthy individuals, increasing corporate tax rates, and raising capital gains taxes. His 2026 "40 for 40 for 45" plan ties economic security to progressive redistribution, and he supports lifting the Social Security payroll tax cap on high earners. He explicitly opposes spending cuts for debt reduction.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Booker supports lifting the payroll tax income cap for Social Security so high earners pay in on all wages, which would significantly expand the program's funding and allow for expanded benefits. iSideWith records his support for removing the cap for high earners.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies', 'https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Booker's Medicare for All position is an explicit call to expand Medicare to cover everyone regardless of age, replacing private insurance. He has supported this position consistently across his 2020, 2022, and 2026 campaigns and it is his signature healthcare platform.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Booker supports same-sex marriage and equal LGBT adoption rights, and opposes allowing businesses to deny services based on religious objections to same-sex couples. He supports anti-discrimination protections based on gender identity.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies', 'https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$iSideWith records Booker as supporting transgender athletes' participation on teams matching their gender identity without restrictions. He also supports anti-discrimination protections for gender identity broadly.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Booker opposes allowing businesses to deny service to customers based on religious objections (e.g., same-sex couples), and supports keeping religious references out of public spaces. He supports strict church-state separation, placing him at stance 2 — protecting religious freedom while ensuring it does not override anti-discrimination protections.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Booker supports automatic voter registration and expanded mail-in voting. iSideWith records his support for automatic voter registration, and Wikipedia notes his voting rights advocacy as a state legislator and Senate candidate. He opposes voter suppression tactics generally.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Booker supports independent redistricting commissions to combat gerrymandering. iSideWith records this position explicitly, and it aligns with his broader reform agenda opposing money in politics and corruption.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Booker opposes Citizens United v. FEC and supports restrictions on political donations and spending. He emphasized grassroots fundraising — claiming 98% from small donors in 2021 — and supports banning congressional stock trading. He supports donor restrictions rather than full public funding.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Booker supports affirmative action, opposes eliminating DEI programs from federal agencies, and supports anti-discrimination protections for race and gender identity. Wikipedia highlights his participation in Breonna Taylor protests in 2020 and his history as the first African American major party nominee for U.S. Senate in Kentucky. He historically supported reparations for slavery.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Booker supports government incentivization of affordable housing, rent control to limit landlord charges, and restricting foreign real estate investment. His progressive economic platform consistently addresses housing affordability as part of his broader "Hood to the Holler" anti-poverty agenda.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Booker supports increased funding for homeless services and a services-based approach rather than criminalization. iSideWith records his support for increased homeless funding, consistent with his broader progressive platform redirecting funding to social services.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Booker favors expanding shelter capacity and social services as the primary response to homelessness, consistent with his broader position of redirecting police funding toward mental health services. He supports increased funding for homeless services rather than enforcement-first approaches.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Booker opposes private prisons, supports restorative justice alternative programs, opposes civil asset forfeiture without conviction, and supports redirecting police funding toward mental health, addiction, and community services. He opposes the death penalty and solitary confinement for juveniles, reflecting a position of shrinking the incarceration system.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies', 'https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Booker supports systemic criminal justice reform including abolishing qualified immunity for police officers, opposing private prisons and the death penalty, supporting restorative justice programs, and opposing civil asset forfeiture. He supports mandatory body cameras and opposed increasing police budgets in favor of redirecting funds to mental health services.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies', 'https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Booker criticized increasing police budgets and advocated redirecting funds toward mental health services, but he stopped short of explicitly calling to defund police. Wikipedia notes he "criticized increasing police budgets" while preferring mental health investment, placing him at stance 2 — maintaining current police staffing while shifting non-violent calls to mental health co-responders.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Booker explicitly opposes school voucher programs. iSideWith records his opposition to school vouchers, consistent with his support for the Department of Education and universal public school meal programs.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Booker supports universal pre-K funded federally and paid leave for childbirth and family illness. His 2026 "40 for 40 for 45" plan includes 40 hours of paid sick leave for workers, reflecting a significant expansion of childcare and family support subsidies.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '24e9212c-b011-422a-865c-093e35050901',
        $$iSideWith records Booker as supporting military aid to Ukraine and U.S. NATO membership and defense commitments. He supports continued Ukraine defense aid while also supporting decreasing overall U.S. military spending.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Booker supports ethical AI oversight and taxing companies that replace workers with AI, while opposing AI use in criminal justice and mass facial recognition surveillance. iSideWith records him as opposing government regulation of social media (private company issue) but supporting AI ethical oversight — a mixed position leaning toward light oversight rather than heavy regulation.$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$iSideWith records Booker as opposing government regulation of social media as a private company issue, though he supports banning deepfakes in political campaigns. This mixed position — opposing broad government content moderation mandates while supporting targeted narrowly-scoped prohibitions — aligns with stance 4 (protect free speech online and prevent government censorship).$$,
        ARRAY['https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Charles Booker / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5cc94df-2ba3-4057-8abd-5760383b286b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Booker's "Hood to the Holler" platform connects urban and rural economic distress, supporting public investment in communities rather than corporate tax incentives. He supports labor unions, a higher minimum wage, and opposes spending cuts, reflecting a preference for public-investment-driven development over corporate subsidies.$$,
        ARRAY['https://en.wikipedia.org/wiki/Charles_Booker_(American_politician)', 'https://www.isidewith.com/candidates/charles-booker/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Angie Craig
-- ============================================================

-- ----- Angie Craig / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Craig is a member of the House Pro-Choice Caucus and stated 'No one should ever come between a woman and her doctor' (Apr 2020). She supports publicly funded abortions and opposes parental notification requirements for minors. Her record reflects support for legal accessible abortion but stops short of publicly funding abortion at all stages.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Craig.htm', 'https://en.wikipedia.org/wiki/Angie_Craig']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Craig co-sponsored the For the People Act, which she described as enacting 'sweeping changes to reform our campaign finance system,' and introduced a provision prohibiting members of Congress from serving on for-profit corporate boards. She supports regulating indirect campaign contributions from corporations and unions and has raised concerns about corporate PAC spending in political campaigns.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Government_Reform.htm', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Craig voted for the American Rescue Plan Act (Mar 2021) and the $900 billion COVID relief package (Dec 2020), both of which included significant childcare funding expansions and child tax credit increases. She also advocates for establishing national paid family leave to support working families with caregiving responsibilities.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Craig.htm', 'https://en.wikipedia.org/wiki/Angie_Craig']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Craig co-sponsored the Equal Rights Amendment ratification bill (Mar 2021), co-sponsored the George Floyd Justice in Policing Act (passed House 220-212, Mar 2021), and supports protecting sexual preference as a civil right. She won a landmark court ruling enabling LGBTQ+ couples to adopt (Jul 2021), directly advancing civil rights for same-sex families.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Civil_Rights.htm', 'https://en.wikipedia.org/wiki/Angie_Craig', 'https://www.ontheissues.org/House/Angie_Craig_Crime.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Craig earned a 96% lifetime score from the League of Conservation Voters (LCV), including 97% in 2025 and 100% in both 2020 and 2021. She advocates becoming 'a world leader in green innovation,' supports funding renewable energy sources including wind and solar, and backs regulating greenhouse gas emissions.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/moc/angie-craig', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Craig voted for the Laken Riley Act in January 2025 alongside a minority of Democrats, but subsequently expressed regret over that vote. She has consistently supported reform of ICE rather than abolition and backs pathways to legal status for long-term residents, while opposing the use of city and federal resources for sweeping mass deportations. Her mixed record — a crossover vote followed by public reconsideration — places her at the center.$$,
        ARRAY['https://en.wikipedia.org/wiki/Angie_Craig', 'https://www.ontheissues.org/House/Angie_Craig_Immigration.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Craig earned a 96% LCV lifetime score, indicating a strong environmental record, but she explicitly advocates maintaining a 'strong Renewable Fuel Standard' — a policy that protects corn ethanol and benefits her agricultural district in Minnesota. This suggests a moderate position that supports current fossil fuel regulatory standards while promoting renewable energy rather than pursuing new permit bans or immediate elimination of fossil fuel extraction.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/moc/angie-craig', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Craig co-sponsored legislation allowing Medicare to negotiate drug prices and a bill establishing a public option to increase market competition. She introduced the Affordable Insulin Now Act (Feb 2022) to cap out-of-pocket insulin costs at $35/month, which passed the House. She supports the ACA and opposes repeal but has not backed Medicare for All.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Health_Care.htm', 'https://en.wikipedia.org/wiki/Angie_Craig', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Craig voted for the American Rescue Plan Act (Mar 2021) and the $900 billion COVID relief package (Dec 2020), both of which included expanded rental assistance and housing support programs. She focuses on rebuilding Minnesota's middle class, which includes housing affordability as a component of her economic platform, and supports federal investment in affordable housing programs.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Craig.htm', 'https://en.wikipedia.org/wiki/Angie_Craig']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Craig supports 'a path to citizenship for DREAMERS and law-abiding immigrants,' co-sponsored the Fairness for High-Skilled Immigrants Act to increase visa caps, and voted YES on the NO BAN Act to prohibit religion-based immigration restrictions (Apr 2021). She voted for the Laken Riley Act in Jan 2025 but later expressed regret, reflecting a centrist position that supports expanded legal immigration while accepting some enforcement measures.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Immigration.htm', 'https://en.wikipedia.org/wiki/Angie_Craig', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Craig co-sponsored the George Floyd Justice in Policing Act (passed House 220-212, Mar 2021), which lowers the criminal intent standard for federal officer misconduct prosecutions, limits qualified immunity, and grants DOJ subpoena power for pattern-or-practice investigations. She supports police accountability reforms and rebuilding trust between law enforcement and communities through structural changes.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Crime.htm', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Craig stated 'We need to keep Medicare and Social Security fully funded' (Jul 2025) and was endorsed by the National Committee to Preserve Social Security and Medicare (Jun 2022). She co-sponsored legislation allowing Medicare to negotiate drug prices and opposes any privatization of Medicare or reduction of Medicaid coverage, supporting improvements to current programs while controlling costs.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Craig.htm', 'https://www.ontheissues.org/House/Angie_Craig_Health_Care.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Craig voted YES on the Save the Internet Act (net neutrality, Mar 2019) and introduced legislation in 2025 to hold social media companies accountable for enabling drug sales on their platforms. She has not taken a strong documented position on government content moderation mandates or algorithm regulation, placing her in a moderate position favoring voluntary standards and targeted accountability over broad government intervention.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Technology.htm', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Craig co-sponsored legislation requiring 'states to establish independent, nonpartisan redistricting commissions' to conduct congressional redistricting, and voted YES on the For the People Act (2019, 2021), which includes anti-gerrymandering provisions and independent redistricting requirements. Her co-sponsorship of DC statehood and the Protecting Our Democracy Act further demonstrates support for structural democratic reforms.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Government_Reform.htm', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Craig is the first openly gay parent elected to Congress from Minnesota and identified herself as 'First openly LGBTQ mother and grandmother in Congress' (Jan 2025). She voted for the Respect for Marriage Act, which requires federal recognition of same-sex marriages and provides full federal benefits and protections. She won a landmark court ruling enabling LGBTQ+ couples to adopt children.$$,
        ARRAY['https://en.wikipedia.org/wiki/Angie_Craig', 'https://www.ontheissues.org/House/Angie_Craig_Civil_Rights.htm', 'https://angiecraig.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Craig explicitly opposes education vouchers and stated she will 'always prioritize funding for our public schools, students and teachers.' Per OnTheIssues, she 'Opposes vouchers for private schools' (Jul 2018) and voted against voucher expansion measures, prioritizing full public school funding over diverting taxpayer money to private institutions.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Education.htm', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Craig stated 'We need to keep Medicare and Social Security fully funded' (Jul 2025) and opposes privatizing Social Security. She was endorsed by the National Committee to Preserve Social Security and Medicare (Jun 2022), reflecting consistent opposition to private investment accounts or benefit cuts. She supports keeping the program stable without advocating for major expansion of benefits or removal of the income cap.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Craig.htm', 'https://en.wikipedia.org/wiki/Angie_Craig']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Craig stated 'Tariffs are killing my bean and corn producers right now' (Jul 2025) and characterizes haphazard tariff policy as 'compromising our national security,' opposing the use of farmers as political leverage in trade disputes. However, she voted for USMCA (Dec 2019) and supports selective tariffs where warranted, placing her as opposed to blanket tariffs but supportive of targeted trade protections.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Craig opposes making federal income tax cuts permanent and advocates reversing existing federal income tax cuts. She supports raising income taxes to balance the federal budget and backs closing tax loopholes that encourage offshoring jobs, replacing them with tax credits for companies that hire American workers. Her record reflects support for modestly increasing taxes on higher earners while providing relief for the middle class.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Tax_Reform.htm', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Craig is an openly LGBTQ member of Congress and a consistent advocate for LGBTQ+ rights, opposing 'hateful, discriminatory laws' targeting the LGBTQ+ community. While no specific floor vote on a trans athletes bill is documented during her House tenure, her overall LGBTQ rights record — including support for the Equality Act and opposition to anti-trans legislation — indicates she would allow transgender athletes to compete on teams matching their gender identity after basic transition documentation.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Civil_Rights.htm', 'https://en.wikipedia.org/wiki/Angie_Craig', 'https://angiecraig.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Craig voted for Ukraine aid packages as a House member and stated 'We're strongest when we're leading a coalition of countries' (Apr 2020). She has consistently supported American engagement in supporting allies against aggression, voting against unilateral military interventions while backing coalition-led support for Ukraine's defense against Russian invasion. Her record reflects support for current levels of military and economic aid.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Craig.htm', 'https://en.wikipedia.org/wiki/Angie_Craig']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Craig / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Craig co-sponsored and voted YES on the For the People Act (2019 and 2021), which expands voter registration, makes Election Day a federal holiday, limits voter roll purges, and extends early voting and mail-in voting access. She also sponsored a separate voter registration expansion bill (Feb 2021) and supports automatic and same-day registration without strict photo ID requirements.$$,
        ARRAY['https://www.ontheissues.org/House/Angie_Craig_Government_Reform.htm', 'https://www.ontheissues.org/Senate/Angie_Craig.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Abdul El-Sayed
-- ============================================================

-- ----- Abdul El-Sayed / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$El-Sayed is one of the most committed Medicare for All advocates in the 2026 cycle. His campaign website states: 'I will fight to expand Medicare to cover all necessary healthcare, including vision, dental, and hearing, and extend it to every single American.' He co-authored a book titled Medicare for All: A Citizen's Guide and served on Biden's 2020 Unity Task Force for Healthcare.$$,
        ARRAY['https://abdulforsenate.com/priority/medicare-for-all-the-path-to-a-healthier-america/', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed', 'https://www.ontheissues.org/senate/Abdul_El-Sayed.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$El-Sayed explicitly opposes privatization of Medicare and cuts to Medicaid, stating on his campaign website: 'I categorically oppose the privatization of Medicare or the attempt to cut Medicaid or destroy the ACA market.' He advocates expanding Medicare to all Americans with no premiums, copays, or deductibles.$$,
        ARRAY['https://abdulforsenate.com/priority/medicare-for-all-the-path-to-a-healthier-america/', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$El-Sayed is pro-choice and supports Planned Parenthood (OTI, Nov 2017). His campaign website lists codifying reproductive care protections into federal law as a healthcare priority, and his 'Hard-Core Liberal' OnTheIssues rating reflects consistent support for abortion access without restriction.$$,
        ARRAY['https://www.ontheissues.org/senate/Abdul_El-Sayed.htm', 'https://abdulforsenate.com/priority/medicare-for-all-the-path-to-a-healthier-america/', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$El-Sayed states he is 'the only candidate running for U.S. Senate in Michigan that has never taken a dime of corporate money — and never will.' His platform calls for overturning Citizens United, banning SuperPACs and corporate 501(c)4s, and establishing public financing with campaign spending caps.$$,
        ARRAY['https://abdulforsenate.com/priority/money-out-of-politics/', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$El-Sayed proposes taxing capital gains over $1 million at ordinary income rates, an inheritance tax on amounts over $1 million, raising marginal rates on income over $1 million, closing the stepped-up basis loophole, a billionaire wealth tax on fortunes over $1 billion, and removing the Social Security payroll tax cap. This is among the most progressive tax platforms in the 2026 field.$$,
        ARRAY['https://abdulforsenate.com/priority/money-in-your-pocket/', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed', 'https://www.ontheissues.org/senate/Abdul_El-Sayed.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$El-Sayed supports closing the Social Security payroll tax cap as part of his broader tax reform platform, which would expand revenues for the program. His tax platform explicitly includes removing the earnings cap on payroll taxes, aligning with a fully progressive expansion of Social Security.$$,
        ARRAY['https://abdulforsenate.com/priority/money-in-your-pocket/', 'https://www.ontheissues.org/senate/Abdul_El-Sayed.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$El-Sayed's 2018 gubernatorial platform called for achieving 100% renewable energy in Michigan by 2030 and merging state environmental agencies for stronger enforcement. His 2026 campaign lists clean air and water as a core priority alongside environmental justice (he was named Public Official of the Year by Michigan LCV).$$,
        ARRAY['https://en.wikipedia.org/wiki/Abdul_El-Sayed', 'https://abdulforsenate.com/priorities', 'https://www.ontheissues.org/senate/Abdul_El-Sayed.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$El-Sayed's environmental platform centers on clean energy and environmental justice rather than fossil fuel expansion. His 2018 platform called for 100% renewable energy by 2030 and tougher environmental enforcement. His campaign frames clean air and water as fundamental rights, indicating opposition to new fossil fuel permitting without calling for an immediate ban.$$,
        ARRAY['https://en.wikipedia.org/wiki/Abdul_El-Sayed', 'https://www.ontheissues.org/senate/Abdul_El-Sayed.htm', 'https://abdulforsenate.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$El-Sayed supports a pathway to citizenship for undocumented immigrants (OTI, Nov 2017) and supports abolishing ICE, which he calls 'corrupted at its soul' and says 'no longer functions as a legitimate law enforcement agency.' Wikipedia records his position as maintaining border security while opposing ICE specifically.$$,
        ARRAY['https://en.wikipedia.org/wiki/Abdul_El-Sayed', 'https://www.ontheissues.org/senate/Abdul_El-Sayed.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$El-Sayed supports abolishing ICE and opposes mass deportation, while acknowledging he supports 'certain kinds' of border enforcement. OTI records his Mar 2026 quote: 'We can enforce immigration law, ICE isn't about that.' This reflects opposition to broad deportation operations while accepting targeted enforcement of serious crimes.$$,
        ARRAY['https://www.ontheissues.org/senate/Abdul_El-Sayed.htm', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$El-Sayed's platform proposes banning large corporations from owning residential homes, federal legislation against algorithmic rental price-fixing, a federal renter bill of rights, and previously supported repealing Michigan laws blocking local rent control. He frames housing access as a core economic justice issue.$$,
        ARRAY['https://abdulforsenate.com/priority/money-in-your-pocket/', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$El-Sayed explicitly stated 'Get profit motive out of public education' (OTI, Nov 2017) and 'Oppose school vouchers.' This is a strong, unambiguous position against any diversion of public school funding to private institutions.$$,
        ARRAY['https://www.ontheissues.org/senate/Abdul_El-Sayed.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$El-Sayed's economic platform supports 'targeted, smart tariffs' to protect Michigan manufacturing while opposing free trade deals like NAFTA that he says favor elites over workers (OTI, Nov 2017). He is neither a full free-trader nor a blanket protectionist, landing in the selective-use camp.$$,
        ARRAY['https://abdulforsenate.com/priority/money-in-your-pocket/', 'https://www.ontheissues.org/senate/Abdul_El-Sayed.htm', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$El-Sayed's campaign platform calls for automatic voter registration at age 18 and upon moving, no-reason absentee voting, and early in-person voting. His campaign also supports abolishing the filibuster and ending gerrymandering through a federal nonpartisan committee.$$,
        ARRAY['https://abdulforsenate.com/priority/money-out-of-politics/', 'https://www.ontheissues.org/senate/Abdul_El-Sayed.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$El-Sayed's campaign website explicitly calls for 'ending gerrymandering through a federal nonpartisan committee of experts' — aligning with independent citizens' commissions with no elected officials involved.$$,
        ARRAY['https://abdulforsenate.com/priority/money-out-of-politics/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$OTI records El-Sayed as being 'sensitive to women's rights and transgender people's rights' (Mar 2017) and his OnTheIssues rating of 'Hard-Core Liberal' encompasses full LGBTQ+ equality. His platform explicitly lists codifying protections for LGBTQ+ healthcare and rights into federal law.$$,
        ARRAY['https://www.ontheissues.org/senate/Abdul_El-Sayed.htm', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$El-Sayed has stated a commitment to 'strict separation of church and state' (OTI, Nov 2017). As a Muslim American running on a secular platform, he opposes religious exemptions that override civil rights laws, consistent with his 'Hard-Core Liberal' rating.$$,
        ARRAY['https://www.ontheissues.org/senate/Abdul_El-Sayed.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$El-Sayed advocates equal pay and expanded opportunity, is sensitive to women's and transgender rights (OTI), and frames his campaign as fighting systemic inequality and corporate power. His union memberships (SEIU, AFT, UAW) and environmental justice work as Detroit Health Commissioner reflect a systemic approach to civil rights enforcement.$$,
        ARRAY['https://www.ontheissues.org/senate/Abdul_El-Sayed.htm', 'https://en.wikipedia.org/wiki/Abdul_El-Sayed', 'https://abdulforsenate.com/about']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$El-Sayed's healthcare platform opposes the use of AI by insurance companies to override doctors' decisions, and his economic platform opposes unaccountable corporate control of AI development. He does not explicitly call for government content removal mandates, but supports platform accountability and regulation of exploitative algorithms.$$,
        ARRAY['https://abdulforsenate.com/priority/medicare-for-all-the-path-to-a-healthier-america/', 'https://abdulforsenate.com/priority/money-in-your-pocket/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '24e9212c-b011-422a-865c-093e35050901',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '24e9212c-b011-422a-865c-093e35050901',
        $$El-Sayed generally opposes routine U.S. military aid to foreign nations but cited Ukraine as a justified exception. Wikipedia notes he views humanitarian aid and diplomacy as primary tools, placing him in a limited-support camp rather than full military escalation or complete withdrawal.$$,
        ARRAY['https://en.wikipedia.org/wiki/Abdul_El-Sayed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$El-Sayed's campaign platform calls for opposing 'unaccountable corporate control of AI' and supports wage insurance and basic income exploration to address automation. However, his stated approach emphasizes consumer protection and anti-monopoly enforcement rather than government pre-approval of AI systems, consistent with a light oversight model that prioritizes accountability over heavy regulation.$$,
        ARRAY['https://abdulforsenate.com/priority/money-in-your-pocket/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Abdul El-Sayed / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$El-Sayed's campaign lists accessible education and affordable childcare as priorities alongside Medicare for All and housing. His work as Detroit Health Commissioner included expanding public health access for families. His progressive economic platform strongly implies significant public investment in childcare as part of his 'money in your pocket' framework.$$,
        ARRAY['https://abdulforsenate.com/priorities', 'https://abdulforsenate.com/priority/money-in-your-pocket/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Peggy Flanagan
-- ============================================================

-- ----- Peggy Flanagan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Flanagan explicitly supports the Women's Health Protection Act to restore Roe v. Wade federal protections, supports repealing the Hyde Amendment, and supports publicly funded abortion access through Medicaid and ACA coverage. Her campaign priorities page states she is committed to ensuring nationwide reproductive healthcare access including abortion.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Flanagan's campaign priorities explicitly list Medicare for All as her healthcare goal, with transition support for workers. She also supports banning insurance company prior authorization, expanding Medicare/Medicaid for vision/dental/hearing, and allowing Medicare to negotiate all drug prices. Her campaign states: healthcare is a human right.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Flanagan is not accepting corporate PAC money, explicitly states that greedy corporations and special interests have too much influence in Washington, supports banning corporate money in elections, reversing Citizens United, and banning elected officials from lobbying and stock trading.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Flanagan authored several childcare bills as a Minnesota House member and her campaign supports universal childcare. Her priorities page lists universal childcare and expanded Child Tax Credit as core affordability goals, and she championed paid family and medical leave legislation as Lt. Governor.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Flanagan's campaign supports passing the Equality Act to protect LGBTQ2S+ rights and the John Lewis Voting Rights Act to prevent voter suppression. She has a strong record supporting civil rights and anti-discrimination protections, including LGBTQ rights, as both an MN House member and Lt. Governor.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Flanagan's campaign priorities support fighting climate change and climate adaptation investments, investing in wind and solar energy creating union jobs, supporting green hydrogen, and opposing Trump's clean energy rollbacks. She supports a rapid transition to renewables but her platform emphasizes worker transition and union jobs rather than an immediate fossil fuel ban, aligning with stance 2.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Flanagan opposes mass deportation policies and supports a pathway to legal status for long-term undocumented workers. Wikipedia notes she called for a complete overhaul of ICE — not mass deportation — and she has criticized the Laken Riley Act as politically expedient. She supports fair asylum and refugee processes and accountability for Operation Metro Surge.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Flanagan's campaign opposes Trump's clean energy rollbacks and supports wind, solar, and green hydrogen investment as replacements for fossil fuels. Her platform supports sustainable agriculture practices and environmental accountability. While she calls for eliminating tariffs that harm farmers while protecting iron mining — not explicitly ending all new fossil fuel permits — her posture strongly favors renewables over new drilling.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Flanagan's campaign supports The Homes Act to build more affordable housing, banning large corporate landlords and hedge funds from purchasing single-family homes, federal funding to remove lead from pipes and homes, and addressing homelessness through permanent supportive housing.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Flanagan supports significantly expanding legal immigration — including pathways to legal status for long-term undocumented residents, fair asylum and refugee processes, and modernizing the immigration system. While she supports accountability at the border through modernized technology, she opposes mass deportation and the current ICE structure.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Flanagan supports expanding Medicare to cover more people (consistent with her Medicare for All position), expanding Medicaid coverage for vision/dental/hearing, and allowing Medicare to negotiate all prescription drug prices. She explicitly opposes Medicaid cuts and supports lowering the age of Medicare eligibility as part of her healthcare platform.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Flanagan's campaign supports expanding Social Security by removing the income cap on payroll taxes (expanding Social Security income caps to ensure wealthy pay their fair share) and supports eliminating taxation of Social Security benefits. She explicitly opposes any cuts to Social Security.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Flanagan's campaign supports significantly raising taxes on wealthy individuals and corporations, including expanding Social Security income caps, supporting an expanded Child Tax Credit for working/middle-class families, and opposing Trump's tax cuts that benefit the wealthy. She supports a $17 minimum wage tied to inflation and opposes policies that shift burdens to working families.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Flanagan's platform calls for eliminating tariffs that harm Minnesota farmers while protecting Minnesota iron mining — a selective, mixed approach. She supports biofuels investment and a strong Farm Bill but opposes blanket tariffs that hurt agricultural exports. This aligns with a targeted use of tariffs rather than either full free trade or protectionist maximalism.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Flanagan is a strong advocate for full LGBTQ equality, supports passing the Equality Act, and backed Gov. Walz's executive order protecting gender-affirming care. Her campaign supports nationwide reproductive healthcare and LGBTQ2S+ protections. As an MN House member she consistently supported LGBTQ rights legislation.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Flanagan is described as a strong advocate for transgender rights and gender-affirming care for youth and adults, and supported Gov. Walz's executive order protecting access to gender-affirming care. Her campaign supports the Equality Act which would protect transgender individuals in all areas of public life including sports, with no restrictions or requirements mentioned.$$,
        ARRAY['https://en.wikipedia.org/wiki/Peggy_Flanagan', 'https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Flanagan's education platform states the federal government should increase K-12 funding without vouchers, supports reversing Head Start cuts, expanding universal Pre-K, fully funding IDEA, and Full-Service Community Schools. She explicitly rejects voucher programs that divert taxpayer money from public institutions.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Flanagan's campaign supports the John Lewis Voting Rights Act to prevent voter suppression and broadly supports expanding voting access. Her freedom and civil rights platform opposes voter suppression and she has consistently supported voting access measures as both a state legislator and Lt. Governor.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Flanagan's campaign supports rebuilding NATO alliances and supporting Ukraine, and opposes Trump's approach to Russia, calling for a consistent Russia policy. She states she would have supported policies differing from Trump's handling of the conflict, aligning with continuing current levels of military and economic aid to Ukraine.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Flanagan's campaign supports addressing homelessness through permanent supportive housing, and her campaign cites the Minnesota veteran homelessness model as a success to replicate nationally. She supports federal funding for homelessness prevention rather than criminalization, and her housing platform emphasizes building more affordable units.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Flanagan's platform supports permanent supportive housing as the primary strategy for addressing homelessness, citing Minnesota's veteran homelessness model and calling for housing-first approaches. Her campaign supports investing in housing, outreach, and services rather than enforcement-first approaches.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Flanagan's platform supports well-resourced and accountable law enforcement alongside rehabilitation and re-entry programs, banning private prisons, and funding domestic violence survivors. She supports banning assault weapons and high-capacity magazines. This is a mixed approach that supports both law enforcement funding and significant criminal justice reform, consistent with stance 3.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Flanagan's campaign supports rehabilitation and re-entry programs, banning private prisons at the federal level, and investing in mental healthcare. Her platform explicitly emphasizes reducing incarceration through alternatives rather than expanding jail capacity — consistent with reducing the incarcerated population through pretrial diversion and treatment alternatives.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Flanagan supports the John Lewis Voting Rights Act and broader voting rights protections that address gerrymandering and voter suppression. Her civil rights platform emphasizes preventing partisan manipulation of elections and ensuring fair representation, consistent with support for independent or bipartisan redistricting commissions.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Flanagan's support for the Equality Act and LGBTQ2S+ protections indicates she opposes religious exemptions from anti-discrimination law in employment and housing. Her campaign does not emphasize restricting religious expression in public institutions but her LGBTQ and civil rights stances align with ensuring religious freedom does not override anti-discrimination protections.$$,
        ARRAY['https://www.peggyflanagan.com/priorities', 'https://en.wikipedia.org/wiki/Peggy_Flanagan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$No direct stance found on misinformation regulation or platform content moderation. Flanagan's campaign priorities page addresses free speech and freedom of assembly but does not take a specific position on mandating fact-checking or regulating algorithms, suggesting at most voluntary or moderate standards.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Peggy Flanagan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15bd3382-0d8a-4c3e-8ab9-ab324517882d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Flanagan's platform emphasizes clean energy creating union jobs, supporting small businesses and family farms, and opposing politicization of infrastructure spending. She does not take explicit positions on corporate tax incentives or subsidy levels for economic development. Her labor and jobs platform focuses on PRO Act, minimum wage, and apprenticeships — a mixed approach.$$,
        ARRAY['https://www.peggyflanagan.com/priorities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- John Fleming
-- ============================================================

-- ----- John Fleming / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Fleming has called abortion a pernicious evil" and "a national sin$$,
        ARRAY['co-sponsored the Life at Conception Act (2015) and the Sanctity of Human Life Act to recognize personhood from fertilization, and has sought to ban all federal funding for abortion including defunding Planned Parenthood. He does allow narrow exceptions for rape, incest, and life of the mother, which places him at 4.5 rather than a full 5.', 'https://www.ontheissues.org/House/John_Fleming.htm', 'https://www.ontheissues.org/House/John_Fleming_Abortion.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Fleming explicitly opposes universal$$,
        ARRAY['single-payer', 'government-run socialized medicine" and supports full repeal of the ACA', 'calling it a "federal health care takeover." He favors purely market-driven health insurance through competition and health savings accounts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Fleming voted YES on the Paul Ryan Budget, which proposed converting Medicare to a premium-support (partial privatization) model. He received a 3% rating from the Alliance for Retired Americans, indicating a strongly pro-privatization stance on Social Security and Medicare. He has not supported Medicaid expansion.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming.htm', 'https://www.ontheissues.org/House/John_Fleming_Social_Security.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Fleming signed the Americans for Tax Reform Taxpayer Protection Pledge against any net tax increases, co-sponsored the Fair Tax Act (H.R.25) to abolish the IRS and replace income/estate taxes with a 23% national sales tax, and supports permanent repeal of the estate tax. He stated: My position is clear: Abolish the Income Tax.""$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Tax_Reform.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Fleming voted YES on opening the Outer Continental Shelf to expanded oil and gas drilling (2011), signed the No Climate Tax Pledge, voted YES to bar the EPA from regulating greenhouse gases, and co-sponsored H.R.391 to exclude CO2 from the Clean Air Act. He has consistently opposed any restrictions on fossil fuel development and argued against renewable energy subsidies.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Energy_+_Oil.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Fleming signed the No Climate Tax Pledge opposing any climate legislation, voted to bar the EPA from regulating greenhouse gases (2011), co-sponsored legislation to remove CO2 from Clean Air Act coverage, and opposed renewable energy subsidies. He has consistently rejected climate regulation, arguing for new energy technologies over restrictions on carbon emissions.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Energy_+_Oil.htm', 'https://www.ontheissues.org/House/John_Fleming_Environment.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Fleming received an A" rating from ALIPAC (Americans for Legal Immigration) for his anti-amnesty stance$$,
        ARRAY['co-sponsored the Birthright Citizenship Act multiple times (2009-2013) to eliminate birthright citizenship for children of undocumented immigrants', 'and supports mandatory deportation of those in the country illegally', 'removal of all welfare and benefits for undocumented immigrants']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Fleming calls unauthorized immigration an invasion by illegal aliens$$,
        ARRAY['supports securing the border by all means necessary', 'and requires all undocumented immigrants to return home and re-enter through legal channels. He supports deporting those convicted of crimes as a priority and removing all public benefits as an enforcement mechanism, though has not explicitly called for mass immediate deportation of all long-term residents.', 'https://www.ontheissues.org/House/John_Fleming_Immigration.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Fleming co-sponsored the State Marriage Defense Act to prevent federal recognition of same-sex marriages in states that prohibit them, co-sponsored the Marriage and Religious Freedom Act to protect those with religious objections to same-sex marriage, and voted NO on anti-gay hate crime enforcement. His position is that marriage is exclusively between one man and one woman.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Civil_Rights.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Fleming considers religious freedom a Government interest of the highest order" and co-sponsored the Marriage and Religious Freedom Act to protect faith-based objections from any federal adverse action. He supports Ten Commandments displays in government buildings and courts$$,
        ARRAY['school prayer', 'and Christian principles in public life', 'and advocates complete autonomy for religious organizations in how they operate."']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Fleming received a 3% rating from the Alliance for Retired Americans, indicating a strong pro-privatization stance, consistent with his support for the Ryan Budget and market-based reforms across government programs. He has not supported Social Security benefit expansions or payroll tax increases to fund the program.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Social_Security.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Fleming voted against Trade Promotion Authority (fast-track) and the Trade Adjustment Assistance program, and opposed reauthorization of the Export-Import Bank, receiving a 50% rating from USA*Engage for a mixed trade record. His record reflects skepticism of both free-trade deals (opposing TPA) and protectionist spending programs (opposing TAA), placing him at a genuinely centrist position on this axis.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Free_Trade.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Fleming voted NO on reauthorizing the Violence Against Women Act (opposing expanded protections for LGBTQ individuals, immigrants, and Native Americans), voted NO on anti-gay hate crime legislation, opposes affirmative action and expansive federal civil rights enforcement, and received a 0% rating from the UFCW for pro-labor civil rights positions. He supports state-level control over civil rights determinations rather than federal mandates.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Civil_Rights.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Fleming voted YES to reauthorize the DC Opportunity Scholarship program (school vouchers for low-income students), introduced a Constitutional amendment establishing parents' fundamental right to direct children's education, and opposes Common Core and federal involvement in curriculum decisions. His record and philosophy strongly favor education funding following the student to any school of parental choice.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Education.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Fleming voted against shareholder rights to non-binding votes on executive pay, received a 100% rating from the Competitive Enterprise Institute for opposing economic regulation, and consistently supports reduced restrictions on business and political spending. While no explicit campaign finance position was documented, his broader record of opposing regulatory oversight of corporations and political speech is strongly conservative.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Corporations.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Fleming co-sponsored the Internet Freedom Act to prohibit FCC regulation of the Internet and signed the Broadcaster Freedom Act preventing reinstatement of the Fairness Doctrine, reflecting a strong anti-government-censorship position. He voted to terminate NPR funding and opposed net neutrality regulations. His record strongly reflects the stance of banning government involvement in content moderation decisions.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Technology.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Fleming voted NO on mortgage modification bankruptcy rules, voted YES to terminate the Home Affordable Modification Program (HAMP), and his overall fiscal philosophy opposes federal housing assistance programs. He supported the position that failed government housing programs should be eliminated rather than reformed, consistent with leaving housing markets to private developers.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Budget_+_Economy.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Fleming's record on welfare programs emphasizes work requirements and fraud prevention (co-sponsored SNAP photo ID requirement, voted against expanding AmeriCorps/national service). His philosophy favors enforcement and work-based solutions over expanded services, with no documented support for housing-first or decriminalization approaches. He has not advocated for redirecting enforcement budgets toward supportive services.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Welfare_+_Poverty.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Fleming's documented record shows consistent opposition to expanding government social programs, support for eliminating federal spending on welfare-adjacent programs, and a philosophy of leaving childcare to families and private markets. He voted NO on the GIVE Act expanding national service programs and consistently opposed government expansion into social services.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Welfare_+_Poverty.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Fleming / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8be7e981-77a6-4ef7-b8d7-891fd9cc26d8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Fleming co-sponsored the SNAP Verify Act requiring photo ID for food stamps, reflecting support for strict ID verification across government programs. His Tea Party affiliation and strong opposition to Democratic voting-expansion initiatives are well-documented. He has not supported automatic voter registration, expanded early voting, or no-excuse mail voting.$$,
        ARRAY['https://www.ontheissues.org/House/John_Fleming_Welfare_+_Poverty.htm', 'https://www.ontheissues.org/House/John_Fleming.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Julia Letlow
-- ============================================================

-- ----- Julia Letlow / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Letlow is a strongly pro-life Republican endorsed by the National Right to Life Committee. She stated: "I've always been pro-life, and it was through the transforming experience of having my first child that I knew I needed to do more and wanted to speak out for those who have no voice" (Mar 2021). She has consistently opposed abortion rights throughout her House tenure.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow.htm', 'https://www.ontheissues.org/House/Julia_Letlow_Abortion.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Letlow's LCV lifetime score is 4% (0% in 2025), reflecting near-universal opposition to climate and clean energy legislation. She voted against measures on methane fees, offshore wind, clean energy funding, and other climate protections in 2023-2025. She is a member of the Climate Solutions Caucus but her voting record shows no substantive support for climate policy.$$,
        ARRAY['https://www.lcv.org/scorecard/julia-letlow/', 'https://www.ontheissues.org/House/Julia_Letlow.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Letlow's 2024 LCV votes include opposing LNG reforms, attacking oil and gas leasing reforms, and blocking a Delaware River Basin fracking ban. In 2025 she voted to roll back the methane polluter fee and fast-track fossil-fuel power over clean energy. Her 4% lifetime LCV score reflects consistent support for expanding and protecting fossil fuel interests.$$,
        ARRAY['https://www.lcv.org/scorecard/julia-letlow/', 'https://www.ontheissues.org/House/Julia_Letlow.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$OnTheIssues classifies Letlow as favoring expanding ObamaCare modestly, placing her as a moderate on the conservative side rather than a full repeal advocate. She serves on the Appropriations Subcommittee on Labor, Health and Human Services, and has not called for full ACA repeal. She does not support a public option or single-payer system.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow.htm', 'https://en.wikipedia.org/wiki/Julia_Letlow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Letlow strongly opposes pathways to citizenship for undocumented immigrants and criticized Biden border policies, stating: "The new policies coming down from the Biden administration, I think they're hurting our country." She voted NO on the NO BAN Act (HR 1333, Feb 2021) and demanded the Biden administration stop releasing immigration detainees in Louisiana. She advocates for enforcement of legal immigration procedures.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow_Immigration.htm', 'https://www.ontheissues.org/House/Julia_Letlow.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Letlow demanded the Biden administration "stop these releases immediately" regarding immigration detainees released in Louisiana, indicating strong support for deportation enforcement. She strongly opposes pathways to citizenship and advocates for removing those without legal status, prioritizing enforcement. Her record aligns with deporting people without legal status with priority on those with criminal history.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow_Immigration.htm', 'https://en.wikipedia.org/wiki/Julia_Letlow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Letlow is a conservative Republican who broadly supports tax cuts and reduced government spending. She signed onto the Republican Study Committee budget framework supporting extension of the 2017 Tax Cuts and Jobs Act and reducing the tax burden. Her 2025 LCV vote record shows she voted for the reconciliation bill that included tax cut extensions (characterized by LCV as "Raising Energy Costs and Providing Polluter Giveaways to Cut Taxes for Billionaires").$$,
        ARRAY['https://www.lcv.org/scorecard/julia-letlow/', 'https://www.ontheissues.org/House/Julia_Letlow.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$OnTheIssues documents Letlow as "Strongly Opposes easier voter registration." She stated she would have objected to the 2020 presidential election certification. Her position aligns with requiring photo ID and stricter voter rolls rather than expanding mail-in or automatic registration, though she has not publicly called for eliminating mail-in voting entirely.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow.htm', 'https://en.wikipedia.org/wiki/Julia_Letlow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$OnTheIssues explicitly documents that Letlow "Opposes school vouchers/choice programs." She views public education as a poverty-reduction catalyst and has prioritized funding for public schools from K-12 through community colleges. This places her as an unusual Republican who opposes voucher programs.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow.htm', 'https://www.ontheissues.org/House/Julia_Letlow_Education.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$OnTheIssues documents that Letlow "Strongly Favors keeping God in public sphere" and emphasizes her faith as central to her public identity, quoting: "The Lord doesn't waste an experience good or bad." As a devout Christian who described her pro-life stance through her faith, she consistently supports expansive religious freedom protections and opposes restrictions on religious expression in public life.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow.htm', 'https://www.ontheissues.org/House/Julia_Letlow_Abortion.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Letlow is a strongly conservative Republican and devout Christian who opposes same-sex marriage. OnTheIssues documents no recorded support for same-sex marriage, and her strong religious freedom stance and opposition to LGBTQ-inclusive legislation (she voted against the NO BAN Act and other civil rights expansions) indicate she aligns with restricting marriage to opposite-sex couples.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow.htm', 'https://en.wikipedia.org/wiki/Julia_Letlow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Letlow authored the Parents Bill of Rights Act (H.R. 5, passed House Mar 2023), which includes a provision requiring parental consent before schools alter a child's "gender markers, pronouns, or preferred name on school forms." This reflects a position restricting transgender recognition in schools. Her conservative posture on gender issues suggests support for biological-sex-based athletic eligibility, consistent with requiring trans athletes to compete as their birth sex.$$,
        ARRAY['https://www.govinfo.gov/bulkdata/BILLSTATUS/118/hr/BILLSTATUS-118hr5.xml', 'https://en.wikipedia.org/wiki/Julia_Letlow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Letlow voted against the NO BAN Act (HR 1333, Feb 2021), which prohibited religion-based discrimination in immigration decisions. OnTheIssues notes she is neutral on legally requiring hiring of women and minorities. While she advocates for women's representation in government ("Women need a seat at the table"), she does not support mandated racial equity requirements or affirmative action programs.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow.htm', 'https://www.ontheissues.org/House/Julia_Letlow_Civil_Rights.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '24e9212c-b011-422a-865c-093e35050901',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '24e9212c-b011-422a-865c-093e35050901',
        $$OnTheIssues documents that Letlow opposes avoiding foreign entanglements and supported applying the 2002 AUMF to ISIS, indicating she is not an isolationist. However, as a Trump-endorsed conservative aligned with the MAGA wing of the GOP, she has not been a vocal Ukraine aid champion. Her position likely falls in the middle range — providing limited support while favoring diplomatic negotiations rather than open-ended military commitment.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow.htm', 'https://en.wikipedia.org/wiki/Julia_Letlow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Letlow serves on the Appropriations Subcommittee on Labor, Health and Human Services, and has not supported expanding Medicare or Medicaid eligibility. As a conservative Republican representing a rural Louisiana district, she has not called for lowering the Medicare age or significantly expanding Medicaid. Her voting record aligned with conservative efforts to reform rather than expand entitlement programs.$$,
        ARRAY['https://en.wikipedia.org/wiki/Julia_Letlow', 'https://www.ontheissues.org/House/Julia_Letlow.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia Letlow / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c79994ff-9e88-4318-97d9-d06b0ede183f',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$OnTheIssues does not record a specific Social Security stance for Letlow, but as a conservative Republican who supports fiscal restraint and aligns with House Republican budgetary frameworks, she likely favors gradually raising the retirement age and reducing benefits for higher earners to preserve solvency. She has not publicly advocated for privatization nor for expanding benefits.$$,
        ARRAY['https://www.ontheissues.org/House/Julia_Letlow.htm', 'https://en.wikipedia.org/wiki/Julia_Letlow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mallory McMorrow
-- ============================================================

-- ----- Mallory McMorrow / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$McMorrow sponsored Michigan's Reproductive Health Act in 2019 to codify Roe v. Wade at the state level and sponsored Senate Bills 154-155 establishing Michigan's state-level FACE Act protections for reproductive health clinics. She publicly shared her personal D&C experience in 2022, stating 'I might be dead right now' without Roe protections. She also championed repealing Michigan's 1931 abortion ban (Mar 2023).$$,
        ARRAY['https://senatedems.com/mcmorrow/reproductive-health/', 'https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://www.wdet.org/2025/04/08/mallory-mcmorrow-talks-us-senate-bid/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$McMorrow favors a public option — allowing individuals to buy into Medicare or other government health insurance — rather than Medicare for All. Wikipedia records her position as supporting a 'public healthcare option alongside private insurance plans.' She has not endorsed single-payer and describes herself as a pragmatist.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://www.wdet.org/2025/04/08/mallory-mcmorrow-talks-us-senate-bid/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$McMorrow supports a public option model that would allow buy-in to Medicare, expanding access without converting to a single-payer system. Her Michigan Senate newsletter (Jan 2026) addressed bills targeting medical debt relief for Michigan residents, consistent with expanding coverage while preserving private insurance.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://senatedems.com/mcmorrow/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$McMorrow has publicly criticized dark money and corporate influence in politics. While she reached out to AIPAC and has accepted support from some organized groups, she positions herself as focused on grassroots funding and donor transparency. She opposes the outsize role of corporate money but has not called for complete public financing of elections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://www.wdet.org/2025/04/08/mallory-mcmorrow-talks-us-senate-bid/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$McMorrow delivered a viral 2022 floor speech defending LGBTQ+ youth and communities from Republican attacks, stating 'people who are different are not the reason why your health care costs are too high.' She co-sponsored SR-60 to declare Pride Month (2021) and consistently advocates for enforcing civil rights protections without throwing vulnerable groups 'under the bus because of polling.'$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://www.wdet.org/2025/04/08/mallory-mcmorrow-talks-us-senate-bid/', 'https://senatedems.com/mcmorrow/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$McMorrow has consistently supported LGBTQ+ rights throughout her legislative career, co-sponsored Pride Month resolutions, and has delivered high-profile speeches defending LGBTQ+ communities from Republican attacks. Her stated position is that Democrats should protect LGBTQ+ individuals while discussing mainstream concerns.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://www.wdet.org/2025/04/08/mallory-mcmorrow-talks-us-senate-bid/', 'https://senatedems.com/mcmorrow/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$McMorrow sponsored Senate Bill 339 implementing Michigan's Prop 2 ballot tracking system, stating: 'Michiganders spoke loudly in favor of expanded voting rights.' She supported expanded early voting, absentee voting expansion, and ballot access improvements enacted in Michigan's 2022 Prop 2 constitutional amendment.$$,
        ARRAY['https://senatedems.com/mcmorrow/voting-rights/', 'https://en.wikipedia.org/wiki/Mallory_McMorrow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McMorrow serves on the Michigan Senate Energy and Environment Committee and has been involved in environmental protection legislation including dam safety reform. Her March 2026 newsletter referenced harm from Trump administration energy policies. She has supported clean energy investment at the state level consistent with a rapid transition framing.$$,
        ARRAY['https://senatedems.com/mcmorrow/', 'https://senatedems.com/mcmorrow/news/', 'https://en.wikipedia.org/wiki/Mallory_McMorrow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$McMorrow led passage of multiple bills in May 2026 to reduce childcare costs and support providers, including codifying Michigan's Tri-Share childcare cost-sharing program. She has chaired Senate hearings on childcare affordability (March 2026) and identifies childcare as a central economic development priority alongside regional transit.$$,
        ARRAY['https://senatedems.com/mcmorrow/', 'https://senatedems.com/mcmorrow/news/', 'https://en.wikipedia.org/wiki/Mallory_McMorrow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$McMorrow introduced 'Kids Over Clicks' legislation (Jan 2026) to regulate Big Tech algorithms targeting youth, stating platforms have been 'profiting from exploitative, dangerous algorithms at the expense of our kids.' This reflects a position favoring mandated fact-checking and algorithmic transparency rather than pure voluntary self-regulation.$$,
        ARRAY['https://senatedems.com/mcmorrow/news/', 'https://senatedems.com/mcmorrow/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$McMorrow sponsored legislation banning stock buybacks for corporations receiving state tax breaks (May 2026), stating the bill addresses corporate accountability. She advocates modest increases to hold corporations to account while maintaining investment. As a self-described pragmatist, she aligns with modestly increasing corporate taxes while maintaining current rates for middle-class families.$$,
        ARRAY['https://senatedems.com/mcmorrow/news/', 'https://en.wikipedia.org/wiki/Mallory_McMorrow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McMorrow has identified affordable housing as a core economic development priority and advocates community investment in transit and affordable childcare alongside housing. Her Economic and Community Development Committee focuses on building the economy 'from the ground up,' and her newsletter addresses tackling medical debt and cost-of-living challenges for Michigan residents.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://senatedems.com/mcmorrow/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McMorrow has not staked out an explicit comprehensive immigration platform as a state legislator. Her campaign emphasizes pragmatism and mainstream issues. She has not publicly called for abolishing ICE or open immigration, nor has she taken a hard-restrictionist stance. Evidence is insufficient for a strong-confidence score; moderate is assigned based on her overall centrist-progressive positioning.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://www.wdet.org/2025/04/08/mallory-mcmorrow-talks-us-senate-bid/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$McMorrow has consistently opposed diverting public education funding to private institutions, consistent with her Democratic caucus position in Michigan. Her committee work and economic development platform emphasize investing in public infrastructure and public education rather than market-based alternatives.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://senatedems.com/mcmorrow/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$McMorrow's January 2026 newsletter called out 'House Republicans' Cruel Budget Slashing' on social programs. Her platform emphasizes protecting public benefits against cuts rather than privatization. She aligns with modestly protecting and improving Social Security while opposing any shift to private accounts.$$,
        ARRAY['https://senatedems.com/mcmorrow/2026/01/07/house-republicans-cruel-budget-slashing-deemed-unconstitutional/', 'https://en.wikipedia.org/wiki/Mallory_McMorrow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '24e9212c-b011-422a-865c-093e35050901',
        $$McMorrow supports providing military and economic aid to Ukraine at current levels. Wikipedia records she supports 'defensive systems like Iron Dome' and conditioning offensive weapons sales on humanitarian aid resumption (July 2025), reflecting continued support for Ukraine's defense while adding human rights conditions. This is consistent with maintaining current aid levels.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mallory McMorrow / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bdf2b9e-7512-4cc6-93f5-252078fae92c',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$McMorrow is a Michigan state legislator who operates under Michigan's 2018 Proposal 2 independent redistricting commission. Her support for that model — which includes equal representation from both major parties and unaffiliated citizens — is consistent with an independent bipartisan commission approach rather than full independent-only.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mallory_McMorrow', 'https://senatedems.com/mcmorrow/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Seth Moulton
-- ============================================================

-- ----- Seth Moulton / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$OTI records Moulton as strongly pro-choice, supporting public funding of abortions and opposing all restrictions including parental notification requirements (Apr 2019). Opposes restrictions on abortion services entirely.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$No strong documented public position on AI regulation found in available sources. Moulton serves on the House Select Committee on Strategic Competition with China which touches AI policy in a national security context, suggesting awareness of the issue without a clear regulatory stance.$$,
        ARRAY['https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$OTI records Moulton supporting voter voucher-based public financing and stating 'End secret contributions that buy support in Congress' (Sep 2014). He supports strict limits on dark money and public financing of elections.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://www.ontheissues.org/MA/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Moulton is a member of the New Democrat Coalition, a pro-growth moderate bloc, and supports expanded subsidies for childcare access. He supports making community college free (two years) and expanding early childhood programs, though has not endorsed universal publicly funded childcare.$$,
        ARRAY['https://en.wikipedia.org/wiki/Seth_Moulton', 'https://www.ontheissues.org/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wikipedia records Moulton voting for the Equality Act and co-sponsoring the Transgender Bill of Rights (2022-2023). He voted against a Republican amendment restricting 'race-based theories' in DoD schools in August 2023, one of nine Democrats crossing party lines to oppose it.$$,
        ARRAY['https://en.wikipedia.org/wiki/Seth_Moulton', 'https://www.ontheissues.org/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Moulton holds a 96% lifetime LCV score (2025: 94%, 2024: 97%, 2023: 97%). He voted for the Inflation Reduction Act (2022), co-signed a Green New Deal support letter (Dec 2018), and is a member of the Climate Solutions Caucus. He supports nuclear energy and carbon pricing as part of rapid decarbonization.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/moc/seth-moulton', 'https://en.wikipedia.org/wiki/Seth_Moulton', 'https://www.ontheissues.org/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$OTI records Moulton opposing deportation of undocumented immigrants and supporting a citizenship path for those who follow legal procedures (Apr 2019). He personally helped his Iraqi interpreter obtain asylum, demonstrating his opposition to mass removal of long-term residents.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://www.ontheissues.org/MA/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$OTI records Moulton voting to ban offshore oil drilling in the Gulf of Mexico. His 96% LCV lifetime score reflects consistent votes against fossil fuel expansion on federal lands. He voted for the IRA (2022) which included historic clean energy investments.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/moc/seth-moulton', 'https://www.ontheissues.org/Seth_Moulton.htm', 'https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Moulton explicitly opposes Medicare for All, stating 'Don't force people to get rid of their private health plans' (Jun 2019). He supports improving the ACA and expanding coverage through a public option approach, but his opposition to M4A and preference for keeping private insurance places him between stance 2 and 3.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://www.ontheissues.org/MA/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Moulton's criminal justice stance prioritizes decreasing prison populations and rehabilitation over incarceration, and his progressive record suggests support for services-first approaches to homelessness. No explicit criminalization stance found, but his overall progressive social policy record aligns with decriminalization.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Moulton supports affordable housing investments and expanding rental assistance programs consistent with the New Democrat Coalition platform. OTI designates him a 'Hard-Core Liberal' on social and economic issues, and his IRA vote (2022) included housing-related provisions.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$OTI records Moulton supporting a pathway to citizenship for those who follow legal procedures and opposing mass deportation. He personally helped his Iraqi interpreter obtain asylum (Wikipedia). He opposes illegal immigration but supports significantly expanded legal immigration and DACA protections.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$OTI records Moulton prioritizing decreasing prison populations and focusing on rehabilitation over incarceration. He opposes the death penalty, stating 'Death penalty not worth risk of killing one innocent person' (Jun 2019), reflecting a consistent preference for alternatives to incarceration.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://www.ontheissues.org/MA/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Moulton opposes privatizing Medicare and opposes personal retirement accounts for Social Security. He supports expanding mental health parity and veteran care within existing programs. His opposition to Medicare for All while supporting program preservation and improvement aligns with stance 2 (lower Medicare age/expand Medicaid).$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://www.ontheissues.org/MA/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$As a House Democrat, Moulton has supported the For the People Act which includes independent redistricting commission provisions. His overall progressive record and support for voting rights reform is consistent with support for independent bipartisan redistricting commissions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Seth_Moulton', 'https://www.ontheissues.org/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$OTI records Moulton stating 'Marriage equality is civil rights fight of our generation' (Sep 2014). He voted for the Equality Act and co-sponsored the Transgender Bill of Rights. His support for full federal marriage equality and benefits has been consistent throughout his House tenure.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$OTI explicitly records Moulton opposing private and religious school vouchers. He supports making two years of community college free and maintaining Common Core standards, consistent with a strong public school funding preference over voucher diversion.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://www.ontheissues.org/MA/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$OTI records Moulton opposing privatization of Social Security and supporting elimination of the payroll tax cap to address funding gaps. He opposes personal retirement accounts, consistent with modestly expanding the program's funding base while keeping it public.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://www.ontheissues.org/MA/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Wikipedia records Moulton as opposing Trump's tariff approach while preferring a comprehensive trade strategy. OTI records conditional free trade support — he supports trade deals that help American workers and protect intellectual property, and is willing to use tariffs strategically. This places him at the selective-use centrist position.$$,
        ARRAY['https://en.wikipedia.org/wiki/Seth_Moulton', 'https://www.ontheissues.org/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$OTI records Moulton supporting taxing capital gains at the same rate as ordinary income, raising corporate taxes (but below pre-2017 levels), and eliminating tax loopholes benefiting corporations. He supports higher taxes on high earners while maintaining middle-class rates.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://www.ontheissues.org/MA/Seth_Moulton.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Moulton's position is genuinely mixed: he co-sponsored the Transgender Bill of Rights (2022-2023) and voted against the 'Protection of Women and Girls in Sports Act' in January 2025 as 'too extreme,' yet in November 2024 stated 'I don't want them getting run over on a playing field by a male or formerly male athlete.' This combination places him clearly at the centrist case-by-case position.$$,
        ARRAY['https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        '24e9212c-b011-422a-865c-093e35050901',
        $$OTI records Moulton supporting lethal aid to Ukraine and strengthening NATO against Russia. Wikipedia confirms he supports U.S. strikes on Iran (2025) and has consistently backed strengthening alliances. His Armed Services Committee background reinforces continued military aid to Ukraine.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5ccb1f15-f285-470c-b86a-97f9e6b22dff',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$OTI records Moulton supporting automatic voter registration and elimination of the Electoral College. Wikipedia notes he co-sponsored a constitutional amendment extending voting rights to age 16. He supports expanded early voting and mail-in voting access consistent with stance 2.$$,
        ARRAY['https://www.ontheissues.org/Seth_Moulton.htm', 'https://en.wikipedia.org/wiki/Seth_Moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Graham Platner
-- ============================================================

-- ----- Graham Platner / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Platner is an explicit Medicare for All advocate, calling it an 'urgent priority.' He stated: 'We need universal healthcare in this country. We need Medicare for All' and praised VA healthcare as a model — 'Once everybody has healthcare...I'm happy to expend all of my wind talking about these other things.'$$,
        ARRAY['https://dailybulldog.com/features/graham-platner-outlines-campaign-platform-and-addresses-questions-at-town-hall-event/', 'https://abcnews.com/Politics/graham-platner-oysterman-harbormaster-rural-maine-enters-race/story?id=124758156', 'https://www.commondreams.org/news/susan-collins-reelection']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Platner stated abortion access 'needs to be enshrined in law forever and always' and criticized Susan Collins for Supreme Court votes that 'led to overturning Roe v. Wade.' His position is strongly pro-choice through all stages with no stated restrictions, though he has not explicitly endorsed public funding.$$,
        ARRAY['https://dailybulldog.com/features/graham-platner-outlines-campaign-platform-and-addresses-questions-at-town-hall-event/', 'https://www.huffpost.com/entry/maine-senate-graham-platner_n_68b70ec0e4b081a4d93beebb', 'https://en.wikipedia.org/wiki/Graham_Platner']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Platner calls for a 'billionaire minimum tax' and advocates 'aggressive new taxes on the wealthy to fund stronger social benefits,' stating 'vast amounts of wealth and regulatory structures...in no way, shape, or form keep that wealth in check.' He frames dismantling the 'billionaire economy' as his primary Senate mission.$$,
        ARRAY['https://prospect.org/politics/2025-08-26-maines-populist-senate-candidate-graham-platner-new-gilded-age/', 'https://mainebeacon.com/graham-platner-stands-right-in-the-fing-way-of-those-who-come-after-lgbtqia-rights/', 'https://en.wikipedia.org/wiki/Graham_Platner']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Platner explicitly refuses corporate PAC, Super PAC, and AIPAC money, stating 'I'm obviously not going to take corporate PAC money. We're not taking APAC money. We're not doing the super PAC thing.' He has called for a constitutional amendment to ban billionaires from financing elections.$$,
        ARRAY['https://mainebeacon.com/graham-platner-stands-right-in-the-fing-way-of-those-who-come-after-lgbtqia-rights/', 'https://www.bangordailynews.com/2025/08/23/politics/elections/unions-found-susan-collins-challenger-oysterman-graham-platner-joam40zk0w/', 'https://en.wikipedia.org/wiki/Graham_Platner']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Platner stated: 'I believe equality is equality. I believe that the progressive wins that we have made for people to live the lives they want to live and the bodies they want to live in. No steps back on that kind of thing.' He has pledged full federal LGBTQ protections and opposes any rollback.$$,
        ARRAY['https://www.ms.now/msnbc-podcast/why-is-this-happening/oyster-farming-running-senate-graham-platner-podcast-transcript-rcna232367', 'https://mainebeacon.com/graham-platner-stands-right-in-the-fing-way-of-those-who-come-after-lgbtqia-rights/', 'https://en.wikipedia.org/wiki/Graham_Platner']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Platner supports abolishing ICE and prosecuting agents accused of crimes, calling this 'the moderate stance.' He simultaneously supports 'strong border security' and a pathway to citizenship for undocumented immigrants, framing ICE tactics as 'unconscionable' and opposing mass deportations.$$,
        ARRAY['https://en.wikipedia.org/wiki/Graham_Platner', 'https://prospect.org/politics/2025-08-26-maines-populist-senate-candidate-graham-platner-new-gilded-age/', 'https://dailybulldog.com/features/graham-platner-outlines-campaign-platform-and-addresses-questions-at-town-hall-event/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Platner opposes mass deportations, calling ICE enforcement tactics 'masked thugs kidnapping children' and describing ICE enforcement as 'unconscionable.' He supports a pathway to citizenship while opposing deportation of long-term residents, and advocates abolishing ICE as currently structured.$$,
        ARRAY['https://dailybulldog.com/features/graham-platner-outlines-campaign-platform-and-addresses-questions-at-town-hall-event/', 'https://prospect.org/politics/2025-08-26-maines-populist-senate-candidate-graham-platner-new-gilded-age/', 'https://en.wikipedia.org/wiki/Graham_Platner']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Platner's May 2026 'Take Back American Power' plan proposed ending gas and diesel taxes while targeting fossil fuel companies for climate change costs, which Maine Public Radio described as 'demanding corporations pay for climate change.' The plan targeted fossil fuel companies and the ultra-wealthy to fund the transition.$$,
        ARRAY['https://en.wikipedia.org/wiki/Graham_Platner', 'https://zeteo.com/p/meet-the-disillusioned-veteran-who', 'https://mainemorningstar.com/2025/08/20/maine-oysterman-stirring-up-democrats-efforts-to-oust-susan-collins/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Platner's May 2026 energy plan proposed ending the gas and diesel tax as a working-class relief measure while directing costs to fossil fuel corporations rather than consumers. His platform targets the fossil fuel industry for climate costs, consistent with stopping new permits while transitioning the cost burden to producers.$$,
        ARRAY['https://en.wikipedia.org/wiki/Graham_Platner', 'https://zeteo.com/p/meet-the-disillusioned-veteran-who', 'https://prospect.org/politics/2025-08-26-maines-populist-senate-candidate-graham-platner-new-gilded-age/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Platner identifies housing affordability as a core crisis, stating 'Nobody I know around here can afford a house' and that Maine has 'a housing system that is essentially like pricing out every working class person in the state.' He explicitly opposes private equity ownership of single-family homes, calling it something that 'should [be] illegal.'$$,
        ARRAY['https://dailybulldog.com/features/graham-platner-outlines-campaign-platform-and-addresses-questions-at-town-hall-event/', 'https://www.ms.now/msnbc-podcast/why-is-this-happening/oyster-farming-running-senate-graham-platner-podcast-transcript-rcna232367', 'https://www.commondreams.org/news/susan-collins-reelection']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Platner supports expanding Medicare to cover all Americans (Medicare for All), criticizing the 'for-profit insurance system.' He attacked Susan Collins for enabling 'Trump's Medicaid cuts,' indicating strong opposition to any Medicaid reduction and support for expanding both Medicare and Medicaid dramatically.$$,
        ARRAY['https://www.huffpost.com/entry/maine-senate-graham-platner_n_68b70ec0e4b081a4d93beebb', 'https://dailybulldog.com/features/graham-platner-outlines-campaign-platform-and-addresses-questions-at-town-hall-event/', 'https://en.wikipedia.org/wiki/Graham_Platner']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Platner explicitly supports military aid to Ukraine, stating: 'I support the Ukrainians in their fight. They were invaded. They're resisting with all the means that they can. And I personally think that we should provide them with support.' This is a notable exception to his general opposition to U.S. military adventurism.$$,
        ARRAY['https://prospect.org/politics/2025-08-26-maines-populist-senate-candidate-graham-platner-new-gilded-age/', 'https://en.wikipedia.org/wiki/Graham_Platner']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Platner pledges to protect LGBTQIA+ rights, stating he stands 'right in the f***ing way of anyone who's going to try to come after the freedoms of the LGBTQIA+ community.' He opposes racially discriminatory immigration enforcement and supports strengthening civil rights protections.$$,
        ARRAY['https://mainebeacon.com/graham-platner-stands-right-in-the-fing-way-of-those-who-come-after-lgbtqia-rights/', 'https://en.wikipedia.org/wiki/Graham_Platner', 'https://newrepublic.com/article/199682/graham-platner-maine-senate-profile']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Graham Platner / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$At a town hall, Platner criticized property-tax-based school funding as 'guaranteeing unequal outcomes' and advocated federal funding reform for all public schools. His explicit opposition to private equity diverting public funds from community institutions extends to his education philosophy, opposing vouchers that divert taxpayer money to private schools.$$,
        ARRAY['https://dailybulldog.com/features/graham-platner-outlines-campaign-platform-and-addresses-questions-at-town-hall-event/', 'https://en.wikipedia.org/wiki/Graham_Platner']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mike Rogers
-- ============================================================

-- ----- Mike Rogers / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Rogers has a 100% rating from the National Right to Life Committee and 0% from NARAL, reflecting a consistent anti-abortion record across 14 years in Congress (2001–2015). He voted YES on banning partial-birth abortion (2003), restricting interstate transport of minors for abortion (2005), and banning federal health coverage that includes abortion (2011). He co-sponsored the Right to Life Act to grant 'pre-born equal protection under 14th Amendment.' In 2024, he stated the issue 'should be left to the states' and that he would not try to change Michigan's 2022 constitutional amendment.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Abortion.htm', 'https://en.wikipedia.org/wiki/Mike_Rogers_(Michigan_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Rogers' technology voting record consistently favors minimal regulation and opposes government mandates on digital platforms. He co-sponsored the Internet Freedom Act to prevent FCC regulation of internet services, voted YES on cyber-security data-sharing with government (CISPA, 2013), and opposed network neutrality as anti-market. As House Intelligence Committee chair he focused on enabling intelligence-community cybersecurity operations rather than consumer-facing AI regulation. His record strongly favors market-driven governance with targeted national-security carve-outs over broad government oversight.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Technology.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Rogers voted YES to ban soft money to national parties but voted NO on the broader Shays-Meehan campaign finance reform bill (2002). He supported restricting 527 grassroots organizations and requiring lobbyist bundling disclosure, but his overall record opposes comprehensive campaign finance regulation. His 2024 Senate campaign accepted PAC support and he did not endorse stricter limits, aligning with a preference for reduced restrictions with minimal disclosure requirements.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Government_Reform.htm', 'https://www.ontheissues.org/MI/Mike_Rogers.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Rogers received a 33% rating from the NAACP, 13% from the ACLU, and 0% from the Human Rights Campaign. He voted NO on prohibiting job discrimination based on sexual orientation (2007) and NO on the Matthew Shepard hate crimes expansion (2009). He voted YES on the constitutional amendment defining marriage as between a man and a woman (2004, 2006) and opposed affirmative action policies. These ratings and votes reflect a record of limiting federal civil rights enforcement.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Civil_Rights.htm', 'https://www.ontheissues.org/MI/Mike_Rogers.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Rogers received a 5% lifetime rating from the League of Conservation Voters, indicating near-total opposition to climate and clean-energy legislation. He voted YES on barring EPA greenhouse gas regulation (2011) and YES on opening the Outer Continental Shelf to oil drilling (2011). He voted NO on renewable energy incentives, CAFE fuel-efficiency standards, and ANWR protection, and co-sponsored bills to remove EPA regulatory authority over carbon emissions.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Environment.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Rogers has a 100% rating from USBC (US Border Control, sealed-border stance) and 0% from FAIR (which scores toward loosening restrictions). He voted YES on the Secure Fence Act (2006) and supported the Minuteman Project's border-patrol activities. His 2026 campaign materials blame 'open borders' for crime increases and call for expanded enforcement. His record supports systematic deportation prioritized by criminal history, consistent with a value-4 stance.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Immigration.htm', 'https://en.wikipedia.org/wiki/Mike_Rogers_(Michigan_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Rogers voted YES on expanding Outer Continental Shelf drilling (2011), YES on permitting new oil refinery construction, and YES on barring EPA greenhouse gas regulation (2011). He voted NO on removing oil and gas industry subsidies, NO on ANWR drilling restrictions, and received a 17% rating from the Campaign for America's Future for opposing energy-independence initiatives. His record reflects maximum expansion of fossil fuel extraction with removal of environmental restrictions.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Environment.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Rogers received an 11% rating from the American Public Health Association and voted for full repeal of the Affordable Care Act. He co-sponsored ACA repeal legislation and voted to eliminate the Prevention and Public Health Fund. He voted YES on the Ryan Budget transforming Medicare into a voucher/choice system (2011), opposed government drug-price negotiation (2007), and opposed SCHIP expansion three times (2007, 2008, 2009). He called for policies that 'embrace the freedom of the free market' in healthcare.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Health_Care.htm', 'https://en.wikipedia.org/wiki/Mike_Rogers_(Michigan_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Rogers holds a 100% rating from USBC (sealed-border) and voted YES on the Secure Fence Act (2006) and co-sponsored the English Language Unity Act. He voted NO on hospital reporting requirements for undocumented patients and supported extending residency rules for some immigrants pursuing legal status (2001), indicating a border-security-and-enforcement focus rather than a complete moratorium on all immigration. He emphasizes 'targeted legislation which is effective and meaningful' on border security.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Immigration.htm', 'https://en.wikipedia.org/wiki/Mike_Rogers_(Michigan_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Rogers received a 0–7% rating from the Alliance for Retired Americans reflecting support for privatization. He voted YES on the Ryan Budget transforming Medicare into a premium-support/voucher system (2011), voted NO on expanding Medicaid and SCHIP, and voted NO on the 2008 Medicare expansion veto override. He did oppose full privatization to private-only accounts and voted YES on the 2003 Medicare prescription drug benefit (which preserved government structure). His 2026 campaign website pledges to 'protect seniors' Social Security and Medicare benefits,' suggesting a moderating message.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Health_Care.htm', 'https://www.rogersforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Rogers voted NO on network neutrality (2006, 2011) and co-sponsored the Internet Freedom Act to block FCC content regulation. He supported retroactive telecom immunity for warrantless surveillance (2008) and voted YES to terminate NPR funding (2011). He has not supported government content moderation mandates on social media. Wikipedia documents that in his 2024–2026 campaigns he 'advanced baseless election conspiracy theories,' suggesting strong opposition to government involvement in defining or regulating online misinformation.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Technology.htm', 'https://en.wikipedia.org/wiki/Mike_Rogers_(Michigan_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$No direct votes on redistricting reform were found in Rogers' congressional record. He voted against DC Electoral representation, opposed whistleblower protections, and his 92% Christian Coalition / conservative voting pattern aligns with party-controlled redistricting. He has not endorsed independent commissions and his campaign does not address redistricting. Given his hard-core conservative profile and alignment with Republican Party interests, a score of 5 (state legislature without outside interference) is the best fit based on party alignment and absence of any reform-supporting evidence.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Government_Reform.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Rogers received a 92% rating from the Christian Coalition, reflecting strong alignment with religious conservative priorities. He voted YES on constitutional amendments for school prayer (2001), co-sponsored school prayer protections, voted YES on protecting the Pledge of Allegiance (2004), and voted YES on allowing religious organizations equal tax treatment under welfare law. He also voted YES on funding health providers who refuse to provide abortion information (2002), supporting broad religious exemptions from laws that conflict with faith.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Education.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Rogers has a 0% rating from the Human Rights Campaign and voted YES on a constitutional amendment defining marriage as between one man and one woman (2004 and 2006). He voted NO on prohibiting job discrimination based on sexual orientation (2007) and against the Matthew Shepard hate crimes expansion. His record is among the most consistently anti-LGBTQ in the Michigan delegation during his tenure.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Civil_Rights.htm', 'https://www.ontheissues.org/MI/Mike_Rogers.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Rogers voted YES on reauthorizing the DC Opportunity Scholarship Program expanding school choice for low-income students (2011) and backed increased funding for charter schools. He received a 17% rating from the NEA, indicating consistent opposition to public-school-only funding priorities. He supported No Child Left Behind (2001) but opposed large public school spending bills. His record supports expanded voucher eligibility while maintaining some baseline public school funding.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Education.htm', 'https://www.ontheissues.org/MI/Mike_Rogers.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Rogers received 0% from the Alliance for Retired Americans in 2003 and 7% in 2014, with both scores reflecting a pro-privatization/market-based approach to Social Security. He voted YES on raising 401(k) limits and making pensions portable (2001) as alternatives to expanding federal benefits. His record opposes expanding traditional Social Security benefits and supports shifting toward private investment accounts, though he stopped short of explicitly calling for full transition to private accounts. His 2026 campaign pledges to 'protect' Social Security benefits, a softer public message.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Social_Security.htm', 'https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.rogersforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Rogers holds a mixed 39% CATO rating on trade and co-sponsored the Currency Reform for Fair Trade Act imposing tariffs on countries with undervalued currencies, stating it targets nations engaging in 'protracted, large-scale intervention in foreign exchange markets.' He voted YES on CAFTA (2005) and multiple bilateral free trade agreements (Peru, Australia, Singapore, Chile), supporting free trade as a general principle while carving out targeted tariffs for currency manipulation. This selective approach aligns with value 3.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Free_Trade.htm', 'https://www.ontheissues.org/MI/Mike_Rogers.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Rogers signed the Taxpayer Protection Pledge ('no new taxes'), received a 0% rating from Citizens for Tax Justice (opposing progressive taxation), and a 63% NTU rating ('Satisfactory'). He voted YES on making Bush tax cuts permanent (2002), eliminating the estate tax (2001), reducing capital gains and dividend taxes, and eliminating the marriage penalty. He explicitly opposes a European-style VAT and calls for phasing out the 'death tax.' His record is among the most anti-tax in the congressional Republican caucus.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Tax_and_Fiscal_Policy.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Rogers has a 0% HRC rating and voted NO on prohibiting job discrimination based on sexual orientation and gender identity (2007) and NO on the hate crimes expansion covering gender identity (2009). While there were no direct trans-athlete votes during his 2001–2015 tenure (the issue was not yet legislatively prominent), his complete opposition to LGBTQ protections and his 92% Christian Coalition rating indicate a position aligned with banning transgender athletes from competing in categories matching their gender identity.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Civil_Rights.htm', 'https://www.ontheissues.org/MI/Mike_Rogers.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '24e9212c-b011-422a-865c-093e35050901',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Rogers chaired the House Intelligence Committee (2011–2015) and focused on Russian cyber threats and intelligence-sharing, but Ukraine was not a legislative flashpoint during his tenure. Post-Congress, he has not been on record supporting the full-scale Ukraine aid packages voted on in 2024. His 2026 campaign emphasizes 'America first' framing and alignment with Trump, who has sought to reduce or condition Ukraine aid. Given the absence of a strong pro-Ukraine legislative record and his Trump-aligned campaign posture, a value of 3 (limited aid, encourage diplomacy) best reflects available evidence.$$,
        ARRAY['https://www.rogersforsenate.com/', 'https://en.wikipedia.org/wiki/Mike_Rogers_(Michigan_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Rogers voted YES on requiring government-issued photo ID for federal elections, with provisional ballots for those without ID (2006). He voted NO on granting Washington D.C. an Electoral vote and House representation, arguing constitutional amendment was required. He also voted NO on expanding whistleblower protections and supported restricting independent grassroots political committees (527s). His record favors tighter voter-eligibility rules and periodic voter-roll maintenance rather than the most restrictive elimination of mail-in voting.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Government_Reform.htm', 'https://www.ontheissues.org/MI/Mike_Rogers.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Rogers voted NO on Section 8 Housing vouchers (the main federal rental-assistance program) and voted YES on maintaining welfare work requirements, reflecting a preference for market-based solutions to housing over federal assistance programs. His OTI welfare record and 7% AFL-CIO rating indicate consistent opposition to government housing subsidies, aligning with a position of eliminating federal housing programs.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Rogers received an A rating from the NRA and consistently supported law enforcement expansion. He voted YES on prohibiting lawsuits against gun manufacturers (2005), sponsored a national concealed-carry standard, and voted YES on multiple military and intelligence funding expansions. His NAPO rating of 54% (mixed) on police issues is offset by his broader record of prioritizing law enforcement and opposing programs to divert police budgets to social services. His 92% Christian Coalition and 11% SANE ratings reflect a law-enforcement-first orientation.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers.htm', 'https://www.ontheissues.org/MI/Mike_Rogers_Crime.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Rogers / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ace0b96d-8ef8-4aca-8928-6848ae430da6',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Rogers voted YES on the Second Chance Act (2007) supporting reentry grants and job training for ex-offenders, indicating some openness to rehabilitation-focused alternatives. However, he opposed expanding hate-crime protections, supported aggressive enforcement and surveillance, and his 7% AFL-CIO / 92% CEI ratings reflect a strong law-and-order posture. His overall record is best characterized as favoring expanded jail capacity as the primary response to crime, with limited support for diversion only through established reentry programs.$$,
        ARRAY['https://www.ontheissues.org/MI/Mike_Rogers_Crime.htm', 'https://www.ontheissues.org/MI/Mike_Rogers.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Haley Stevens
-- ============================================================

-- ----- Haley Stevens / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Stevens is an outspoken pro-choice Democrat who stated "I will fight for women's reproductive freedom" (Apr 2020). She supports public funding of abortions, opposes parental notification requirements for minors, and backs continued federal funding for Planned Parenthood — aligning with the most expansive access position.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Stevens supports government oversight ensuring ethical AI development, backing requirements that AI systems undergo safety and ethics review before deployment. She also supports making AI-generated political deepfakes illegal and favors taxing companies that replace workers with AI, reflecting support for meaningful but not heavy-handed regulation.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Stevens opposes the Citizens United ruling and supports campaign donation limits to prevent wealthy donor influence. She advocates donation regulation broadly, though she has accepted corporate PAC contributions during her House tenure — her stated position favors strict limits on dark money and corporate spending.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Stevens supports federal subsidized childcare for working families and backed universal pre-K funding. She voted YES on the American Rescue Plan Act (Mar 2021), which included substantial childcare subsidies and the Child and Dependent Care Tax Credit expansion — consistent with a significant expansion of federal childcare support.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Stevens sponsored the Equal Rights Amendment ratification and police accountability legislation (Mar 2021), and backs LGBTQ+ equality protections including adding gender identity to anti-discrimination laws. She opposes eliminating DEI programs in federal agencies and supports programs addressing systemic racial disparities in criminal justice.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Stevens earned a 98% lifetime LCV score (100% in 2023 and 2024), reflecting consistent pro-environment voting. She supports increased environmental regulations to prevent climate change with alternative energy incentives, opposed U.S. withdrawal from the Paris Climate Agreement, and launched the Congressional Plastics Solutions Task Force (Dec 2019).$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/moc/haley-stevens', 'https://www.ontheissues.org/senate/Haley_Stevens.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Stevens' position is mixed: she supports deporting immigrants who commit serious crimes (when safe) and voted for a resolution expressing gratitude to ICE agents while also opposing ICE abolition, preferring to "rein it in." She supports sanctuary cities and opposes local enforcement detaining immigrants for minor offenses — reflecting a centrist enforcement posture.$$,
        ARRAY['https://en.wikipedia.org/wiki/Haley_Stevens', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Stevens earned 100% annual LCV scores in 2021, 2023, and 2024, including votes against fossil fuel expansion. She explicitly opposes expanding offshore oil drilling and oil extraction in the Alaska Wildlife Refuge, and backs greenhouse gas regulation — reflecting a consistent anti-new-fossil-fuel-permits stance aligned with stopping new drilling.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/moc/haley-stevens', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Stevens declares "Health care is a right, not a privilege" and supports a public insurance option alongside private plans, letting ages 55-65 buy into Medicare, and lowering prescription drug costs. She backs the ACA and iSideWith records her endorsing a single-payer system with private insurance options — placing her closer to a robust public option than full M4A.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Stevens supports increased funding for homeless shelters and support services and has backed housing assistance expansion through votes like the American Rescue Plan (Mar 2021). She supports allowing homeless encampments only in designated areas, reflecting investment in services rather than criminalization as the primary approach.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Stevens supports increased shelter funding and services as the primary response to homelessness, while allowing public camping only in designated areas. This places her in a middle position: investing in outreach and shelter capacity while maintaining some public space rules — not a pure enforcement approach nor a pure housing-first decriminalization stance.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Stevens supports government incentives and funding for affordable housing construction and backed the American Rescue Plan's housing provisions. She supports rent control policies to protect tenants and has endorsed expanded rental assistance — consistent with a robust federal role in building affordable supply and protecting renters.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Stevens states "America is a country of immigrants" (Apr 2020) and supports a pathway to citizenship for undocumented immigrants, comprehensive reform with DREAMER solutions, and increased visa caps. She opposes the border wall and sponsored a bill blocking religion-based immigration bans — reflecting significantly expanded legal immigration and a clear path to citizenship.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Stevens supports restorative justice alternatives to incarceration, opposes private prisons, and favors redirecting some police funding to community-based mental health and social programs. She opposes qualified immunity and backs police accountability measures — reflecting a preference for reducing incarceration through diversion and alternatives rather than expanding jail capacity.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Stevens supports letting ages 55-65 buy into Medicare and backed expanded Medicaid funding through the American Rescue Plan (Mar 2021) and the Inflation Reduction Act (Aug 2022). She backs government negotiation of prescription drug prices for seniors and opposes privatizing Medicare — favoring significant expansion of both programs.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Stevens occupies a mixed position: she supports making AI-generated political deepfakes illegal and favors stricter data privacy regulations on corporations, but explicitly opposes government regulation of social media platforms, viewing them as private entities. This combination of targeted intervention (deepfakes, data privacy) with resistance to broader content moderation mandates places her in the middle.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Stevens supports redirecting some police funding to community programs and mental health services while maintaining police presence. She opposes police militarization (military-grade equipment for departments), supports mandatory body cameras, and backs shifting non-violent calls to social workers — consistent with maintaining current police staffing while adding co-responder mental health teams.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Stevens supports independent, non-partisan redistricting commissions to prevent gerrymandering, a position she has stated explicitly. She also sponsored D.C. statehood legislation (which included electoral and representational reform provisions) — both positions align with strong structural reform of how districts are drawn.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Stevens opposes allowing religious beliefs to justify denying services to others, placing civil rights protections above religious exemptions in public accommodations and employment. She supports strict separation of church and state in public institutions — reflecting the position that religious freedom does not override anti-discrimination protections in employment and housing.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Stevens supports same-sex marriage nationwide and equal adoption rights for same-sex couples. She backs adding gender identity to anti-discrimination laws and full LGBTQ+ equality protections — reflecting the most comprehensive federal protection position with no carve-outs for organizations declining participation.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Stevens explicitly opposes government vouchers for private schools. She supports the public school system and the Department of Education (opposing abolition), backs national education standards, and has opposed school choice policies that divert taxpayer dollars from public institutions to private ones.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Stevens opposes Social Security privatization and supports lifting the Social Security income cap on payroll taxes to fund the program. She has consistently backed Social Security protections in her House voting record and explicitly opposed personal investment accounts — aligning with modestly increasing benefits while raising taxes on higher earners.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Stevens' auto industry background (Obama Auto Task Force chief of staff) and CHIPS Act advocacy reflect selective industry protection rather than free trade or blanket tariffs. She supports domestic manufacturing investment and semiconductor production but has not advocated broad tariff walls — her position aligns with targeted tariffs to protect key American industries and jobs.$$,
        ARRAY['https://bridgemi.com/michigan-government/haley-stevens', 'https://www.ontheissues.org/senate/Haley_Stevens.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Stevens supports raising taxes on wealthy individuals and large corporations, increasing capital gains taxes, and reversing the 2017 tax cuts for high earners. She opposes spending cuts and prefers tax increases on the wealthy to fund social programs — OTI rates her as backing higher corporate and individual top-bracket rates without advocating a massive overhaul.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$In March 2023, Stevens voted with House Democrats against the Republican-sponsored ban on transgender athletes competing in women's sports — one of only a few bipartisan-crossover votes that she did not join. She supports transgender athletes competing on teams matching their gender identity, consistent with basic documentation of transition.$$,
        ARRAY['https://en.wikipedia.org/wiki/Haley_Stevens', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Stevens supports U.S. military defense assistance, weapons, and funding for Ukraine against the Russian invasion. She supports NATO membership and has backed Ukraine aid packages during her House tenure. She has characterized Russian actions as requiring a firm allied response — consistent with continuing current levels of military and economic aid.$$,
        ARRAY['https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Haley Stevens / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3957855d-a78c-492d-b3b6-0f680c1f82c8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Stevens sponsored legislation expanding voter registration and access during her House tenure and supports automatic voter registration for all eligible citizens. She supports voter ID with free IDs available to all eligible citizens and backed expanded mail-in voting and early voting access — consistent with broad expansion while maintaining basic identity verification.$$,
        ARRAY['https://www.ontheissues.org/senate/Haley_Stevens.htm', 'https://www.isidewith.com/candidates/haley-stevens']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Royce White
-- ============================================================

-- ----- Royce White / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$White praised the overturning of Roe v. Wade and strongly opposes abortion rights. OnTheIssues records his position as 'Strongly Opposes abortion rights' based on his public statements.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm', 'https://en.wikipedia.org/wiki/Royce_White']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$White explicitly stated 'Open borders in conflict with the value of my citizenship' (Jul 2024) and is strongly anti-globalist, opposing any pathways to citizenship for undocumented immigrants.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$White's strong opposition to open borders and insistence that undocumented immigration conflicts with the value of citizenship indicates support for broad deportation. His anti-immigration populism aligns with an aggressive enforcement posture.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$White prioritizes energy independence over green energy initiatives and has stated 'We pay a price for not being energy independent' (Jul 2025). He frames energy policy in terms of national security and economic strength, rejecting climate-driven policy constraints.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$White strongly advocates for American energy independence, stating 'We control prices by being energy independent' (Oct 2024) and 'Energy security helps our nation function more reliably' (Apr 2025). His platform explicitly prioritizes fossil fuel expansion over green energy.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$White has stated 'I want to cut taxes for as many Americans as possible' (Oct 2024). He broadly opposes government spending, calling the government's model 'death and debt,' indicating strong support for across-the-board tax cuts.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$White explicitly calls for 'a single-day, paper ballot, personal ID requirement' (Apr 2025) and supports strict voter ID and the elimination of early/mail voting. This is a maximally restrictive stance on voting access.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$White opposes mandatory hiring requirements for women and minorities and has characterized the LGBTQ movement as 'the brainchild of radical feminists' (May 2024). He also opposes race-based government programs, aligning with the most conservative position on eliminating affirmative action.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm', 'https://en.wikipedia.org/wiki/Royce_White']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$White's strongly conservative religious worldview ('God, Family, and Country'), explicit criticism of LGBTQ rights, and characterization of the LGBTQ movement as stemming from 'radical feminists' indicate opposition to same-sex marriage.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm', 'https://en.wikipedia.org/wiki/Royce_White']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$White strongly opposes LGBTQ rights broadly and has criticized the 'pervasive effect' of the LGBTQ community on society. His conservative populist platform is firmly opposed to any transgender inclusion in women's sports.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm', 'https://en.wikipedia.org/wiki/Royce_White']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$White stated 'COVID vaccine mandates violate religious freedom' (Jul 2024) and consistently invokes 'God, Family, and Country' as his core governing framework. He strongly supports religious exemptions and faith-based autonomy.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$White strongly opposes globalism and free trade, stating 'Globalism enslaves free people & destroys businesses' (Jul 2024). While he frames this as anti-globalism rather than explicitly endorsing tariffs, his economic nationalism aligns with high tariffs on unfair trading partners.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$White has shown no support for government healthcare programs and opposed COVID vaccine mandates on religious and liberty grounds. His 'America First' populism and opposition to government expansion point to a private-market-only approach to healthcare.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '24e9212c-b011-422a-865c-093e35050901',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '24e9212c-b011-422a-865c-093e35050901',
        $$White's 'America First' nationalism, anti-globalist worldview, and criticism of the military-industrial complex strongly suggest opposition to continued Ukraine aid. He stated that 'ex-military politicians are only interested in the military itself' (Jun 2024), signaling skepticism of foreign military entanglements.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm', 'https://en.wikipedia.org/wiki/Royce_White']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$White supports using antitrust law to break up big tech and social media companies, framing this as opposition to corporate censorship. He stated 'Use anti-trust to break up big tech, social media companies' (Jul 2024) and his populist platform opposes any government role in content moderation.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Royce White / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$White favors school vouchers and school choice, connecting it to his belief that 'Globalists intentionally control our education system' (Jul 2024). His platform calls for curriculum emphasizing American exceptionalism and supports redirecting public funds to private school options.$$,
        ARRAY['https://www.ontheissues.org/Senate/Royce_White.htm']::text[]::text[])
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
-- WHERE p.id IN ('b5cc94df-2ba3-4057-8abd-5760383b286b', 'd6d297f5-5319-4be1-b938-6bcce63368e7', 'c79994ff-9e88-4318-97d9-d06b0ede183f', '8be7e981-77a6-4ef7-b8d7-891fd9cc26d8', '7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7', '5ccb1f15-f285-470c-b86a-97f9e6b22dff', 'ec0cfeae-a512-4ce2-a8f2-a25b00112b9b', '3bdf2b9e-7512-4cc6-93f5-252078fae92c', '3957855d-a78c-492d-b3b6-0f680c1f82c8', 'ace0b96d-8ef8-4aca-8928-6848ae430da6', '15bd3382-0d8a-4c3e-8ab9-ab324517882d', '0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff', 'b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('b5cc94df-2ba3-4057-8abd-5760383b286b', 'd6d297f5-5319-4be1-b938-6bcce63368e7', 'c79994ff-9e88-4318-97d9-d06b0ede183f', '8be7e981-77a6-4ef7-b8d7-891fd9cc26d8', '7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7', '5ccb1f15-f285-470c-b86a-97f9e6b22dff', 'ec0cfeae-a512-4ce2-a8f2-a25b00112b9b', '3bdf2b9e-7512-4cc6-93f5-252078fae92c', '3957855d-a78c-492d-b3b6-0f680c1f82c8', 'ace0b96d-8ef8-4aca-8928-6848ae430da6', '15bd3382-0d8a-4c3e-8ab9-ab324517882d', '0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff', 'b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23')
--   AND pc.politician_id IS NULL;