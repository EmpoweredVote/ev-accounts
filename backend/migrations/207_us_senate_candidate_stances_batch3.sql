-- ============================================================================
-- Migration 207: U.S. Senate Candidate Stances — Batch 3 of 3 (MS → WY)
-- ============================================================================
-- Purpose: Insert/upsert federal stance data for 15 non-incumbent 2026
--   Senate candidates.
--
-- Topic scope: 30 federal-applicable topics (excludes city-level keys; data-centers excluded)
--
-- Post-state: ~274 rows expected
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
-- Kurt Alme
-- ============================================================

-- ----- Kurt Alme / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Alme received an endorsement from a leading national pro-life organization (noted in his campaign news section, May 2026), indicating strong anti-abortion positioning consistent with a full ban or near-ban approach. He ran with explicit pro-life branding and no public statements supporting abortion access.$$,
        ARRAY['https://almeforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Alme signed the Taxpayer Protection Pledge (noted in campaign news), committing to oppose all income tax increases. As Montana Budget Director under Gov. Gianforte (2021), he championed a $60 million tax cut package and advocated reducing Montana's top income tax rate to 5% to compete with neighboring states. These actions place him as a consistent tax-cutter favoring broad rate reductions.$$,
        ARRAY['https://almeforsenate.com/', 'https://montanafreepress.org/2021/02/11/gianforte-administration-calls-for-tax-cuts-to-lure-out-of-state-entrepreneurs/', 'https://montanafreepress.org/2021/09/07/montana-budget-director-kurt-alme-resigns/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Alme was twice nominated by President Trump as U.S. Attorney for Montana (2017-2021 and 2025-present) and received Trump's 2026 Senate endorsement, indicating alignment with the administration's immigration enforcement agenda. He has not publicly broken with Trump's restrictionist immigration stance and his campaign frames him as a MAGA-aligned conservative.$$,
        ARRAY['https://almeforsenate.com/', 'https://montanafreepress.org/2026/05/19/montana-us-senate-candidates-largely-unknown-to-voters/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$As a two-time Trump-appointed U.S. Attorney and Trump-endorsed Senate candidate, Alme is aligned with the administration's aggressive deportation posture. No public statements distinguish him from the administration's enforcement-first approach, and his endorsement by Trump and Sen. Daines (described as MAGA-backed by Montana Democrats) reinforces this alignment.$$,
        ARRAY['https://almeforsenate.com/', 'https://montanafreepress.org/2026/05/19/montana-us-senate-candidates-largely-unknown-to-voters/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Alme received endorsement from the Montana Stockgrowers Association PAC and ran as a Trump-endorsed conservative in an energy-producing state. His campaign shows no support for limiting fossil fuel extraction; Montana's conservative political environment and his alignment with the Gianforte-Trump axis strongly indicates support for maximizing fossil fuel production and removing regulatory barriers.$$,
        ARRAY['https://almeforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$No public statements from Alme support climate action. His alignment with Trump (who withdrew from the Paris Agreement and rolled back EPA regulations) and his endorsement record from energy and agricultural interests are consistent with rejecting climate change policy and prioritizing economic growth over emissions reduction.$$,
        ARRAY['https://almeforsenate.com/', 'https://montanafreepress.org/2026/04/17/republican-independent-candidates-outraise-democrats-in-federal-races/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Alme's campaign materials emphasize his deep Christian faith through his leadership roles at National Christian Foundation, St. John's Lutheran Ministries, and Yellowstone Boys and Girls Ranch Foundation. His pro-life endorsement and NRA alignment are consistent with the social conservative bloc that strongly favors broad religious freedom protections and faith-based exemptions from civil rights laws.$$,
        ARRAY['https://almeforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Alme has no public statements supporting same-sex marriage. His deep alignment with Trump's social conservative platform, his pro-life organizational endorsements, and his prominent Christian faith community involvement (National Christian Foundation, church boards) are all consistent with opposition to same-sex marriage and a traditional definition of marriage.$$,
        ARRAY['https://almeforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$As Trump's endorsed Senate candidate and a former Gianforte administration official, Alme is aligned with Republican efforts to repeal or replace the ACA. His Taxpayer Protection Pledge and tax-cutting record suggest strong opposition to government-administered healthcare. He has made no public statements supporting public healthcare options or expanded government coverage.$$,
        ARRAY['https://almeforsenate.com/', 'https://montanafreepress.org/2021/02/11/gianforte-administration-calls-for-tax-cuts-to-lure-out-of-state-entrepreneurs/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Alme has made no specific public statements on transgender athletes. As a socially conservative, Trump-endorsed Republican candidate, he is positioned to support restrictions on transgender participation in sports consistent with Republican platform positions, though no direct quote or bill sponsorship is on record.$$,
        ARRAY['https://almeforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Alme has made no specific public statements on voting rights. As a Trump-aligned Republican running in Montana, he is positioned with the GOP consensus favoring stricter voter ID and opposing expansions of mail-in voting, though no direct on-record statements or bill positions are available.$$,
        ARRAY['https://almeforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Alme's Taxpayer Protection Pledge and his record as a tax-cutter aligning with fiscal conservatism suggest support for containing or partially privatizing Social Security rather than expanding it. The campaign has not issued specific SS position statements, but his fiscal conservative posture and Trump endorsement place him closer to benefit restraint and private account options.$$,
        ARRAY['https://almeforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kurt Alme / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Alme is endorsed by Trump, who imposed sweeping tariffs, and has not publicly criticized the tariff agenda. The Montana Stockgrowers Association endorsement introduces some tension (agricultural exporters are tariff-sensitive) but his overall Trump alignment places him supporting higher tariffs on unfair-trading countries rather than free trade.$$,
        ARRAY['https://almeforsenate.com/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Rachel Fetty Anderson
-- ============================================================

-- ----- Rachel Fetty Anderson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supports investing in Medicare, Medicaid, and Tricare to ensure universal access to care, stating 'American taxpayers pay enough taxes to receive the best healthcare.' Calls for eliminating profit-driven corporations that deny physician-recommended care. Stops short of explicit single-payer endorsement, framing the goal as expanding existing public programs.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues', 'https://www.fettyandersonforsenate.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Her issues page states 'All adult humans have the same human rights regardless of the nature of their reproductive capacity' and calls for ensuring 'women and gender minorities receive complete reproductive healthcare' with full 'adult autonomy over medical choices and providers.' Supports age-appropriate reproductive education and special protections for pregnant children, a firmly pro-choice stance framed in human rights language.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Encourages solar, wind, and water power development but explicitly 'recognizes coal's role in energy portfolio' — a significant concession to West Virginia's coal economy. Calls for holding companies accountable for environmental costs rather than banning extraction. This balanced position reflects WV political realities while still pushing for transition.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$States 'Our air, water, forests, mountains and wildlife are irreplaceable' and calls for restoring and extending environmental protections, addressing WV's water and soil contamination, and demanding reparations from polluters. Supports renewable energy development while acknowledging fossil fuel transition challenges. Aligns with investing in clean energy while gradually reducing reliance on fossil fuels.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Calls for increasing marginal tax rates for earners over $500,000 annually, eliminating the 'Buy, Borrow, Die' tax loophole, and equitable distribution of tax burden across individuals, corporations, and nonprofits. States 'No one should be able to live like a king on money they borrow.' Targets high earners while protecting middle-class workers, consistent with a modest progressive tax increase stance.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues', 'https://www.fettyandersonforsenate.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$As Morgantown City Council Deputy Mayor, voted unanimously (7-0) to pass the CROWN Act banning racial discrimination based on hair styles, stating 'It's a privilege to be able to be in the position of doing the next right thing to make everyone in our community feel loved and cared for and welcomed.' Her platform states constitutional rights 'belong only to people and ALL people.' Supports strengthening civil rights enforcement.$$,
        ARRAY['https://wvpublic.org/story/government/more-work-to-do-morgantown-becomes-first-w-va-municipality-to-ban-racial-discrimination-based-on-hair-styles-textures/', 'https://www.fettyandersonforsenate.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Her human rights platform states 'Your humanity is sufficient to guarantee that the government and its actors must treat you humanely' and that 'All persons deserve due process, resources, and constitutional rights.' Calls for Congress to 'block, defund, and impeach officials violating human rights.' Framing of universal human dignity implies opposition to mass deportation, though she does not explicitly address immigration levels.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Her platform explicitly states 'All persons deserve due process, resources, and constitutional rights' and that 'humanity alone guarantees constitutional protections.' She calls for Congress to block officials who violate human rights, indicating opposition to mass deportation without due process. No explicit endorsement of deportation of any class of immigrants.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Her platform calls for requiring disclosure of all gifts, investments, profits, and benefits over $50 from the same source to elected officials, with clawback of undisclosed assets into Treasury. Calls for auditing Defense Department spending and foreign/corporate payments to officials. Frames corruption and undisclosed money as a core concern of her candidacy.$$,
        ARRAY['https://www.fettyandersonforsenate.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Her platform calls for providing support for 'families, caregivers, and workers caring for infants, children, elders, and disabled/ill loved ones.' Her issues page states 'Infants, children and young people are the true heart and future of the United States' and prioritizes investing in child health, safety, welfare, and education through development and trauma-aware safety nets. Aligns with expanding subsidies and caregiver support.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues', 'https://www.fettyandersonforsenate.com/platform']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Calls for improving 'roads, bridges, parks, spillways, streets' and developing 'equitable infrastructure to support industry and job creation.' References her volunteer work with 211 focusing on housing and food insecurity services. Does not lay out an explicit federal housing program, making this a moderate stance of targeted investment rather than a federal guarantee or market-only approach.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues', 'https://www.fettyandersonforsenate.com/about']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Her human rights platform calls for 'All persons deserve due process, resources, and constitutional rights,' and her volunteer background includes housing advocacy through 211 and Caritas House. Frames housing and homelessness as a human rights issue rather than an enforcement problem. Aligns with decriminalizing public homelessness and investing in shelter/services.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues', 'https://www.fettyandersonforsenate.com/about']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Her platform emphasizes that 'humanity is sufficient to guarantee humane treatment by government' and calls for outreach and resources for all persons regardless of circumstances. Her service record with Caritas House (a homeless services organization) and 211 indicates prioritizing outreach, shelter, and services over enforcement as the city's primary homelessness strategy.$$,
        ARRAY['https://www.fettyandersonforsenate.com/about', 'https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Her international relations platform states she will 'maintain alliances with democracies sharing American values and respecting human rights' and 'establish mutual aid and economic partnerships with aligned nations,' prioritizing 'trustworthiness and reliability as partners.' This language clearly supports continued aid to Ukraine as a democratic ally against Russian aggression.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Her agriculture platform calls for protecting farmers from 'market instability, foreign land takeovers, and industry monopolization,' which implies selective trade protection for agriculture. She also rejects 'energy sources requiring military operations to acquire resources,' suggesting some protectionist/self-sufficiency instincts. No explicit tariff policy stated, placing her at a moderate selective-tariff position.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Explicitly states 'Divestment from children, workers and creatives in pursuit of technology is unforgivable' and calls for rejecting 'speculative technologies designed to reduce workforce size.' Her technology platform demands prosecution of those permitting technology abuses and clawback of benefits for contractors. She frames AI as a threat to human labor and creative workers, aligning with closely monitoring and restricting AI deployment.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Her free speech platform supports journalists and a free press, holds government accountable for suppressing First Amendment rights, and calls for stopping 'corrupt media manipulation and unfair FCC licensing distribution.' She emphasizes constitutional speech protections but also criticizes platform manipulation. This suggests voluntary standards and structural reform (FCC) rather than government content removal mandates.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Her free speech platform calls for 'ending religious text establishment in schools,' reflecting a strict church-state separation stance. At the same time, her human rights framing is universal — protecting all people's rights. This balances protection of individual religious practice against government endorsement, consistent with a moderate stance of equal treatment under law rather than either strict prohibition or broad religious exemptions.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Her issues page states she will 'prioritize public education with developmentally appropriate curricula' and focuses investment on 'fundamental skills, civic knowledge, and scientific principles' within the public system. She frames children's education as a government responsibility without any mention of private school choice. Consistent with restricting vouchers to low-income families lacking adequate options at most.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$As Morgantown City Council Deputy Mayor, led creation of the city's civilian police review board (voted unanimously in 2021), stating 'the most critical piece is that we will, as a community be contributing to this discussion about how policing will work in our community.' Also supported lessening marijuana possession penalties. Aligns with maintaining current police staffing while shifting non-violent calls to alternative responders.$$,
        ARRAY['https://wvpublic.org/story/government/morgantown-creates-civilian-police-review-board/', 'https://wvpublic.org/story/wvpb-news/morgantown-lessens-penalties-for-possessing-small-amounts-of-marijuana/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Led Morgantown's civilian police review board creation and supported reduced marijuana possession penalties, showing criminal justice reform orientation. Her human rights platform emphasizes due process for all persons and constitutional protections regardless of status. Her legal career representing domestic violence victims, children, and government benefit recipients reflects a public-interest, reform-oriented approach to the justice system.$$,
        ARRAY['https://wvpublic.org/story/government/morgantown-creates-civilian-police-review-board/', 'https://www.fettyandersonforsenate.com/issues', 'https://www.fettyandersonforsenate.com/about']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Her economy platform calls for investing in 'education, infrastructure, research, and development for job creation' and opposing privatization of utilities, while also rejecting 'speculative technologies designed to reduce workforce size.' Supports low-interest loans and buyback programs for struggling farmers. Favors targeted public investment over broad corporate incentives, suggesting a middle path on economic development rather than either pure market or heavy subsidies.$$,
        ARRAY['https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Fetty Anderson / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Explicitly calls for investing in Medicare, Medicaid, and Tricare with universal access as a goal, and eliminating profit-based incentives that deny care. Her platform states this as a core commitment: 'Implement universal healthcare (Medicare, Medicaid, Tricare for all).' This language supports lowering Medicare eligibility age and expanding Medicaid significantly, though she does not use the phrase 'Medicare for All' explicitly.$$,
        ARRAY['https://www.fettyandersonforsenate.com/platform', 'https://www.fettyandersonforsenate.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Annie Andrews
-- ============================================================

-- ----- Annie Andrews / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Andrews supports a public healthcare option alongside private insurance, stating on iSideWith: 'Yes, but allow people to use private insurance' while adding that 'a mandatory single payer system would be better.' As a pediatric physician she has made healthcare access a central campaign issue.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Andrews is pro-choice and supports keeping abortion legal and accessible, stating that 'providing birth control, sex education, and more social services will help reduce the number of abortions.' She supports continued Planned Parenthood funding for 'cancer screening, prenatal services, and adoption referrals' as well as abortion care.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/healthcare']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Andrews supports government oversight of AI for ethical use and opposes AI diagnosing patients 'without human oversight' due to accountability concerns. She also opposes using AI for criminal justice decisions, reflecting a stance in favor of basic safety requirements before deployment rather than heavy-handed regulation.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Andrews supports limiting donor contributions and opposes allowing corporations to donate to political campaigns, while supporting donations from unions and nonprofits. She also backs congressional stock trading bans and opposes foreign lobbyists raising money for U.S. elections.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Andrews supports federal funding for universal pre-K, free school meals for all students, and mandatory paid family and sick leave. These positions reflect a platform of significantly expanding subsidies and program access for low- and middle-income families.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Andrews supports affirmative action programs, maintaining DEI initiatives, adding gender identity to civil rights laws, and requiring federal racial sensitivity training. She states we 'cannot end racism until we acknowledge institutions, laws, and history are inherently racist,' supporting strengthened civil rights enforcement against systemic discrimination.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/social']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Andrews supports increasing environmental regulations to prevent climate change and 'provide more incentives for alternative energy.' She opposes U.S. withdrawal from the Paris Climate Agreement and opposes oil and gas drilling expansion, favoring a rapid transition to renewables.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Andrews supports deporting only immigrants convicted of serious crimes, 'as long as it is safe for them to return to their country.' She opposes allowing local law enforcement to detain undocumented immigrants for minor offenses and supports sanctuary city federal funding.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/immigration']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Andrews opposes expanding oil drilling, stating 'No, and provide more incentives for alternative energy,' and specifically opposes drilling in the Alaska Wildlife Refuge. She supports keeping the U.S. in the Paris Climate Agreement and investing in wind and other renewable alternatives.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Andrews supports allowing homeless encampments in public spaces alongside 'more social programs to provide free food, clothing, and medicine,' and backs increased funding for homeless shelters. Her approach prioritizes services and housing access rather than criminalization.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Andrews backs expanding shelter capacity and social services as the primary homelessness strategy, supporting increased government funding for shelters and social programs. She favors decriminalizing public sleeping while connecting people to services, consistent with an expand-shelter-first approach.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Andrews supports government incentives for affordable housing construction, rent control policies, and increased funding for homeless shelters. She also supports restricting foreign purchases of U.S. real estate, favoring a multi-pronged government role in addressing housing affordability.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Andrews supports 'a simple path to citizenship for immigrants with no criminal record,' birthright citizenship, sanctuary city funding, and in-state tuition for undocumented immigrants who pay taxes. She opposes a border wall, Muslim immigration bans, and increased border restrictions, reflecting a significantly expanded legal pathway platform.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/immigration']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Andrews supports redirecting police funding to social programs, restorative justice alternatives to incarceration, and opposes private prisons. She also opposes qualified immunity and backs drug decriminalization and supervised consumption sites, reflecting a platform of shrinking incarceration in favor of community-based approaches.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Andrews opposes the death penalty, opposes qualified immunity stating officers should have 'increased personal liability for misconduct,' opposes private prisons, supports restorative justice programs, and backs body cameras for police. She also supports banning civil asset forfeiture without conviction.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Andrews supports increased federal Medicaid funding for low-income individuals, Medicare drug price negotiation authority, opposes Medicaid work requirements, and opposes privatizing VA healthcare. She favors expanding and strengthening both programs rather than any privatization.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/healthcare']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Andrews opposes government regulation of social media content, noting platforms are 'private companies,' and supports free speech online. She also opposes banning political deepfakes through government regulation but does support banning AI-generated deepfakes in political ads — a mixed stance that leans toward protecting speech from government censorship.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Andrews supports redirecting police funding to social programs and opposes police militarization, stating she prefers 'professionally trained security guards' over armed teachers. She backs mandatory body cameras, opposes qualified immunity, and supports defunding police in favor of community investment.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Andrews supports having 'the redrawing of Congressional districts be controlled by an independent, non-partisan commission' with no elected officials involved, the strongest anti-gerrymandering position on the scale.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/domestic-policy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Andrews opposes businesses denying service based on religious beliefs and opposes the Religious Freedom Act, holding that religious freedom should not override anti-discrimination protections in employment and housing. She supports strict separation of religion from civil rights enforcement.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/social']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Andrews unequivocally supports same-sex marriage being legal nationwide and equal adoption rights for gay couples, and supports adding gender identity to federal anti-discrimination laws. She opposes any religious exemptions that would allow denial of services to same-sex couples.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/social']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Andrews explicitly opposes school vouchers, stating 'No, we should focus on improving public schools.' She supports universal pre-K and free college tuition through public funding, rejecting any diversion of taxpayer money to private or religious schools.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Andrews opposes raising the Social Security retirement age and supports protecting and modestly expanding program benefits. Her broader economic platform of taxing the wealthy more heavily aligns with raising taxes on higher earners to strengthen Social Security rather than cutting it.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/domestic-policy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Andrews supports significantly raising taxes on wealthy individuals, raising corporate tax rates, increasing capital gains taxes on investment profits, and taxing companies that replace workers with AI. Her platform consistently targets upper-income earners and corporations for increased taxation.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Andrews supports allowing transgender athletes to compete on teams matching their gender identity without restrictions, answering 'Yes' to allowing trans athletes to compete against athletes differing from their assigned sex at birth. She also supports gender transition treatments for minors.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/social']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '24e9212c-b011-422a-865c-093e35050901',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Andrews supports using 'military forces to defend Ukraine from a Russian invasion' and backs providing 'military supplies and funding to Ukraine.' She also supports Ukraine joining NATO, reflecting a commitment to significantly increasing support until Ukrainian defense succeeds.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Andrews supports automatic voter registration and backs voter ID requirements only if 'every 18 year old receives one at no cost,' favoring expanded early voting and accessible registration. She supports abolishing the Electoral College in favor of the popular vote.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies', 'https://www.isidewith.com/candidates/annie-andrews/policies/domestic-policy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Annie Andrews / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('238222f5-e5e0-4331-8540-ee904bbacb8a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Andrews supports government spending on infrastructure and public services as an economic development tool, while backing targeted incentives for businesses with community benefit requirements. Her platform does not advocate blanket corporate subsidies but supports selective investment aligned with job quality and community benefit.$$,
        ARRAY['https://www.isidewith.com/candidates/annie-andrews/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Seth Bodnar
-- ============================================================

-- ----- Seth Bodnar / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$In his MTPR Q&A (May 2026), Bodnar criticized recent legislation that caused 30,000 Montanans to lose healthcare and warned of rural hospital closures, calling for addressing prescription drug prices and inefficiencies while working across partisan lines. He supports accessible and affordable healthcare but frames it as cost-control within the existing system rather than a public option or single-payer approach.$$,
        ARRAY['https://www.mtpr.org/montana-news/2026-05-01/seth-bodnar-interview']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$In his MTPR Q&A (May 2026), Bodnar stated: 'we need strong borders in this country. You can't be a nation state without enforcing your immigration laws.' He supports enforcement but opposes inhumane treatment. He criticized allowing bipartisan reform proposals to stall for partisan advantage. This places him in a moderately restrictionist position — significantly tighter than Democrats but with humanitarian guardrails.$$,
        ARRAY['https://www.mtpr.org/montana-news/2026-05-01/seth-bodnar-interview']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Bodnar explicitly supports enforcing immigration laws and strong borders (MTPR, May 2026), but opposed enforcement methods that 'treat our fellow human beings like animals' or 'trample on the individual liberties of citizens.' This suggests support for active deportation of recent border crossers while seeking humane procedures — closer to the enforcement-first camp than the limit-deportations camp.$$,
        ARRAY['https://www.mtpr.org/montana-news/2026-05-01/seth-bodnar-interview']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Bodnar's campaign website lists 'energy security' as a priority under Safety and Security, and notes trade policies benefiting Montana farmers and businesses. As a centrist independent in a fossil-fuel-producing state, he has not called for banning or restricting drilling, but also has not explicitly called for maximizing extraction. His centrist framing and fundraising support from the League of Conservation Voters Action Fund (noted in campaign finance reporting) suggests a moderate balanced position.$$,
        ARRAY['https://sethformontana.com/values', 'https://montanafreepress.org/2026/04/17/republican-independent-candidates-outraise-democrats-in-federal-races/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Bodnar has not made explicit climate policy statements. His campaign received funding from the League of Conservation Voters Action Fund (per Montana Free Press campaign finance reporting, April 2026), suggesting some alignment with environmental priorities. However, his emphasis on energy security and centrist framing places him in a market-driven transition camp rather than aggressive climate mandates.$$,
        ARRAY['https://montanafreepress.org/2026/04/17/republican-independent-candidates-outraise-democrats-in-federal-races/', 'https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Bodnar's campaign notes support for 'trade policies benefiting Montana farmers and businesses.' He is a centrist independent who has not endorsed Trump's sweeping tariff agenda nor called for free trade elimination of all tariffs. His emphasis on Montana agricultural interests suggests selective tariff use to protect key industries rather than blanket protectionism or free trade absolutism.$$,
        ARRAY['https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Bodnar has not taken explicit positions on federal tax rates. His campaign messaging emphasizes economic opportunity for working families and criticizes Washington's dysfunction, without committing to raising or cutting taxes. His independent centrist positioning and focus on fiscal responsibility over ideology suggests a maintain-current-rates-and-close-loopholes approach.$$,
        ARRAY['https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Bodnar has not made any public statements on abortion. His campaign explicitly opposes 'government intrusion' in 'personal decisions' including 'medical care,' which could suggest opposition to abortion bans. However, he also emphasizes 'individual liberty and collective responsibility,' and has not staked out a specific trimester or access position. Insufficient evidence to place him away from center; his opposition to government intrusion in medical decisions is the best available signal.$$,
        ARRAY['https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Bodnar's campaign themes of 'individual liberty and collective responsibility' suggest a balancing approach: protecting personal religious practice while not allowing it to override others' civil rights. No specific statements on religious exemptions or faith-based hiring are on record. His independent, bipartisan positioning is consistent with a moderate balance standard.$$,
        ARRAY['https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Bodnar's campaign states opposition to 'government intrusion' in personal decisions 'including the bedroom,' which is a direct signal supporting same-sex marriage rights. He has not called for any restriction or rollback, and his centrist-independent positioning with Democratic donor support further suggests he supports nationwide same-sex marriage with some organizational exemption space.$$,
        ARRAY['https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Bodnar's 'Reform Our Broken Politics' pillar calls for less partisan dysfunction but does not specifically address campaign finance limits or dark money. His campaign has accepted both independent expenditure support and diverse donor bases. No specific position on public financing, donation limits, or disclosure requirements is on record.$$,
        ARRAY['https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Bodnar has not made public statements on voting rights, voter ID requirements, or mail-in voting. His 'Reform Our Broken Politics' platform suggests interest in electoral integrity without specifying a direction. His independent status and rejection of partisan framing places him most plausibly in a standardized-ID-with-free-access centrist position, though no direct evidence is available.$$,
        ARRAY['https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Bodnar states that working families should achieve a 'dignified retirement' (campaign website). No specific Social Security positions are on record. His centrist independent stance and economic messaging suggest small adjustments to maintain stability rather than privatization or major expansion.$$,
        ARRAY['https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Bodnar / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '24e9212c-b011-422a-865c-093e35050901',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6c3620e-1ac1-460c-acb4-74854d59b334',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Bodnar's military background (Green Beret, U.S. Army) and oath-to-Constitution framing suggest support for U.S. security commitments but no specific statements on Ukraine aid levels are on record. His 'putting Montana first' framing and focus on domestic priorities suggests caution about open-ended foreign commitments without specifying a hard limit, placing him near a humanitarian-aid-and-diplomacy centrist position.$$,
        ARRAY['https://sethformontana.com/values']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Sherrod Brown
-- ============================================================

-- ----- Sherrod Brown / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Brown earned a 100% NARAL rating and 0% NRLC rating across his Senate tenure (2007-2025). He voted to block anti-abortion legislation consistently and stated 'Trust women to make their own healthcare decisions' (Oct 2018). He supports abortion access and public funding for family planning at all stages.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Brown opposed repealing the ACA and voted for it in 2009. He co-sponsored the Expanded and Improved Medicare for All Act in 2006 as a House member but as senator advocated allowing those 55+ to buy into Medicare rather than full single-payer. He supports a public option alongside regulated private insurance. Rated 100% by APHA.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Brown is one of the Senate's most ardent critics of unfair foreign trade and opposed NAFTA, CAFTA, and most free trade agreements. He supported Trump's 2018 washing machine tariffs and stated 'I've seen tariffs can work if they're well thought through' (May 2025). He favors tariffs on countries that manipulate currency and trade unfairly, but focuses on worker protection rather than blanket protectionism.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Brown stated 'Billionaires need to start paying their fair share' (Aug 2024), opposed the 2017 Tax Cuts and Jobs Act as benefiting the wealthy, and championed expanding the child tax credit. Rated 100% by CTJ (progressive taxation) and 27% by NTU (Big Spender). He favors modestly increasing taxes on high earners.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Brown chaired the Senate Finance Subcommittee on Social Security and consistently opposed privatization, stating 'No full nor partial privatization of Social Security' (Oct 2018). He also opposed raising the retirement age. Rated 100% by ARA. He favors expanding benefits and raising taxes on higher earners to fund the program.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Brown supported capping insulin at $35 via the IRA, advocated allowing Medicare drug price negotiation, and proposed a Medicare buy-in at age 55. He co-sponsored the American Miners Act (2019) to protect miner pensions. He opposes reducing senior benefits but has not pushed to fully expand Medicare to all ages.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Brown called for 'Aggressive action to combat climate change' (Aug 2024), supports a 25% renewable energy goal, and earned a 95% LCV rating. He opposes drilling in ANWR and supports transitioning manufacturers to clean energy with a $30 billion initiative. His record reflects rapid clean energy transition while managing fossil fuel-dependent communities.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Brown opposes offshore drilling and ANWR extraction but as an Ohio Democrat representing a fossil-fuel-adjacent industrial state has not called for an outright ban on new permits. He focuses on transitioning industries rather than immediate prohibition, consistent with stopping new permits but maintaining some existing production.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Brown supports DACA and a path to legal status for DREAMers. He stated 'Support DACA program: legal status for DREAMers' (Oct 2018) and called for better-resourced border patrol with expedited asylum processing (Aug 2024). Rated 0% by FAIR and 25% by USBC, reflecting openness to legal immigration pathways.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Brown has consistently opposed mass deportation and supported DREAMer protections, indicating he would deport only those who commit serious crimes while providing legal status to long-term residents. His 0% FAIR rating reflects opposition to enforcement-only immigration approaches.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Brown supports expanding early voting and mail-in voting, opposes photo ID voting requirements, and supports automatic voter registration and D.C. statehood. He stated 'Expand early voting & voting by mail' (Aug 2024). He favors broad access expansion but has not explicitly called for online voting.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Brown voted against the Ohio constitutional amendment banning same-sex marriage, voted against DOMA in 1996 (one of few House members to do so), and voted for the Respect for Marriage Act (2022) codifying federal same-sex marriage rights. Rated 100% by HRC. He supports full federal recognition and benefits.$$,
        ARRAY['https://en.wikipedia.org/wiki/Sherrod_Brown', 'https://www.ontheissues.org/Senate/Sherrod_Brown.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Brown earned a 94% NAACP rating for pro-affirmative-action stances and stated 'Ban discrimination on sexual orientation & gender identity' (Aug 2024). He voted for Don't Ask Don't Tell repeal (2010) and has backed ENDA and the Equality Act. Supports strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Brown sponsored legislation requiring corporate PAC donor disclosure and pledged to reject corporate PAC donations during his 2020 presidential exploration. After his 2018 reelection he received limited corporate PAC funding. He supports strict limits on dark money and full disclosure of independent expenditures.$$,
        ARRAY['https://en.wikipedia.org/wiki/Sherrod_Brown', 'https://www.ontheissues.org/Senate/Sherrod_Brown.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Brown introduced the Stop Predatory Investing Act (2023) targeting corporate bulk home purchases that drive up rents, and the 'Yes in God's Backyard' Act (2024) expanding housing via religious institution land. His record reflects support for millions in affordable units and expanded rental assistance through legislative action.$$,
        ARRAY['https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Brown met with Ukrainian PM Denys Shmyhal in 2024 and voted with Democrats to support Ukraine aid packages during his Senate tenure. He has not called for dramatic escalation beyond current aid levels, consistent with maintaining current military and economic support to help Ukraine defend itself.$$,
        ARRAY['https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Brown co-sponsored and supported the For the People Act (2021) which would have required states to establish independent nonpartisan redistricting commissions. His 98% Biden voting alignment score confirms consistent support for Democratic electoral reform priorities.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sherrod Brown / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('56603da5-e7ad-48a9-8c77-259513869ed4',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Brown voted for the American Rescue Plan Act (2021) which included the expanded Child Tax Credit providing significant childcare relief to families, and voted for Build Back Better-type investments in childcare. He favors significant expansion of subsidies and support for providers for low- and middle-income families.$$,
        ARRAY['https://www.ontheissues.org/Senate/Sherrod_Brown.htm', 'https://en.wikipedia.org/wiki/Sherrod_Brown']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- James Byrd
-- ============================================================

-- ----- James Byrd / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Byrd criticizes Trump-era tariffs for harming Wyoming agriculture, stating: 'How could you call yourself supporting Wyoming agriculture when you support the tariffs that caused the Chinese to stop buying grain and beef?' He does not call for eliminating tariffs wholesale, but opposes broad tariff policies that trigger retaliatory losses in agricultural export markets — consistent with a selective, pro-trade-partner approach.$$,
        ARRAY['https://wyofile.com/former-wyoming-rep-james-byrd-announces-bid-for-u-s-senate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Byrd / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Byrd explicitly supports maintaining Wyoming's existing fossil fuel industry during an energy transition while simultaneously advocating for renewable expansion. He backs nuclear, solar, and wind as Wyoming's path to becoming 'the leader in the world' in innovative energy, but couples this with protecting current fossil fuel jobs and operations — aligning with maintaining current production levels under existing environmental regulations.$$,
        ARRAY['https://wyofile.com/former-wyoming-rep-james-byrd-announces-bid-for-u-s-senate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Byrd / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Byrd advocates for Wyoming to become a leader in nuclear, solar, and wind energy, citing France's uniform nuclear development as a model. He views carbon capture as a 'distraction' from necessary energy transitions, suggesting he prioritizes clean energy investment. However, he simultaneously supports protecting existing fossil fuel operations, placing him squarely in the 'invest in clean energy while gradually reducing reliance on fossil fuels' category.$$,
        ARRAY['https://wyofile.com/former-wyoming-rep-james-byrd-announces-bid-for-u-s-senate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Byrd / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Byrd expresses concern about rural hospital closures creating cascading community decline — warning that when hospitals close, schools close and populations shrink — and is skeptical of the Rural Health Transformation Program's rollout. He has not publicly stated support for a public option or single-payer system, nor has he called for leaving healthcare to private markets; his focus on rural access suggests a moderate regulatory stance.$$,
        ARRAY['https://wyofile.com/former-wyoming-rep-james-byrd-announces-bid-for-u-s-senate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Byrd / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8869b74-2a0c-40b7-93b4-40f32eec7108',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Byrd explicitly opposes the expansion of charter schools and homeschooling, stating they 'only give you substandard graduates who can't even get into highly qualified and highly competitive colleges.' He also opposes dismantling the federal Department of Education. This reflects a strong priority for public school funding while opposing voucher programs that divert resources to private alternatives.$$,
        ARRAY['https://wyofile.com/former-wyoming-rep-james-byrd-announces-bid-for-u-s-senate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Scott Colom
-- ============================================================

-- ----- Scott Colom / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Colom has made healthcare his central campaign issue, explicitly pledging to cancel Medicaid cuts and protect the ACA. He stated 'My number one priority is that we are going to prioritize accessible and affordable health care all across Mississippi' and criticized Hyde-Smith for 'voting to cut health care for 142,000 of our neighbors to give a tax cut to people already making $600,000 a year.' Supports expanding Medicaid to prevent rural hospital closures. Favors a public option approach rather than full single-payer.$$,
        ARRAY['https://scottcolom.com/sixteen-years-after-passage-of-affordable-care-act-cindy-hyde-smith-has-made-mississippis-health-care-crisis-worse/', 'https://scottcolom.com/outside-bankrupt-delta-hospital-colom-warns-hyde-smiths-vote-threatens-rural-hospitals-across-mississippi/', 'https://scottcolom.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Colom explicitly opposes the Medicaid cuts in the One Big Beautiful Bill Act, stating 'Senator Cindy Hyde-Smith voted to give people making $600,000 a year a permanent 3% tax cut...To pay for that tax cut, she voted to cut a billion dollars for Medicaid.' He has pledged to cancel healthcare cuts affecting 140,000+ Mississippians and has made protecting Medicaid funding for rural hospitals central to his campaign. Supports improving current programs rather than full expansion to everyone.$$,
        ARRAY['https://scottcolom.com/outside-bankrupt-delta-hospital-colom-warns-hyde-smiths-vote-threatens-rural-hospitals-across-mississippi/', 'https://scottcolom.com/sixteen-years-after-passage-of-affordable-care-act-cindy-hyde-smith-has-made-mississippis-health-care-crisis-worse/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Colom has consistently attacked tax cuts for high earners, stating Hyde-Smith voted to give 'people making $600,000 a year a permanent 3% tax cut' while cutting healthcare for 142,000 Mississippians. He argues on Tax Day that 'every working Mississippian is expected to do their part.' His critique of the billionaire tax break framing aligns with a position of modestly increasing taxes on high earners while maintaining current rates for middle-class families.$$,
        ARRAY['https://scottcolom.com/by-the-numbers-what-the-hyde-smith-backed-billionaire-tax-break-is-costing-mississippi-families-and-communities/', 'https://scottcolom.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$In response to a Supreme Court ruling gutting the Voting Rights Act, Colom stated 'Today's Supreme Court ruling makes one of America's most important civil rights statutes significantly harder to enforce' and invoked Fannie Lou Hamer's legacy fighting for Mississippi voting rights. His statement 'The right to vote in this state was won at a cost, and I know Mississippians have never backed down from a fight worth having' signals strong support for expanding voting access. Aligns with expanding early voting and mail-in voting access.$$,
        ARRAY['https://scottcolom.com/district-attorney-colom-responds-to-supreme-court-ruling-gutting-the-voting-rights-act/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Colom opposes blanket tariffs that harm Mississippi farmers and raise consumer costs, characterizing Hyde-Smith's endorsement of tariffs as out of touch. His campaign statement notes tariffs are 'driving supply chain pressures that increase input costs for Mississippi farmers and ranchers.' However, he does not advocate eliminating all tariffs or free trade broadly; his position is selective opposition to tariffs that harm Mississippi agriculture — aligning with using tariffs selectively to protect key industries while opposing those that hurt domestic farmers.$$,
        ARRAY['https://scottcolom.com/colom-hyde-smiths-dismissive-grocery-cost-comments-an-insult-to-mississippi-families/', 'https://scottcolom.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$As DA, Colom dropped murder charges against Eddie Lee Howard (who spent 23 years on death row based on debunked bite-mark evidence) and supported releasing Steven Jessie Harris after 11 years of detention without trial — demonstrating a commitment to addressing systemic failures in the justice system. He signed a letter with other district attorneys opposing the criminalization of gender-affirming surgery. His endorsements from the Congressional Black Caucus PAC and focus on Voting Rights Act enforcement signal support for strengthening civil rights protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Scott_Colom', 'https://scottcolom.com/endorsements/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Colom directly criticized Hyde-Smith's acceptance of campaign contributions from fertilizer companies under DOJ investigation, stating 'It's hard to claim you fight for Mississippi farmers while you're cashing checks from the very companies the Justice Department says ripped them off.' His campaign explicitly calls out dark money and corporate donor influence on elected officials. He received endorsements from labor unions and progressive PACs rather than corporate sources, signaling support for limiting corporate donations.$$,
        ARRAY['https://scottcolom.com/breaking-hyde-smith-took-campaign-contributions-from-fertilizer-companies-now-under-doj-investigation-as-mississippi-farmers-faced-soaring-costs/', 'https://scottcolom.com/endorsements/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$As District Attorney, Colom demonstrated a reform-minded approach to criminal justice: he dropped wrongful conviction cases relying on debunked forensic evidence (Eddie Lee Howard), supported releasing a defendant held 11 years without trial, and directed resources toward mental health alternatives for certain defendants. He also secured convictions in cold cases and violent crimes, emphasizing accountability for serious offenses while showing willingness to address systemic failures — aligning with reducing pretrial detention and diversion approaches rather than pure incarceration expansion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Scott_Colom', 'https://scottcolom.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Colom's campaign emphasizes lowering costs for working families and opposing cuts to programs that benefit ordinary Mississippians, which implies opposition to Social Security cuts or privatization. However, he has not made explicit public statements about expanding Social Security benefits or removing the income cap on payroll taxes. His economic platform focuses primarily on healthcare and jobs rather than Social Security specifics. Placing at 3 (small adjustments to keep it stable) as the most evidence-consistent position without documented explicit advocacy for expansion or cuts.$$,
        ARRAY['https://scottcolom.com', 'https://scottcolom.com/victory-district-attorney-scott-colom-wins-democratic-senate-primary-advances-to-face-cindy-hyde-smith-in-november-were-going-in-a-new-direction/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Colom has made no explicit public statements on immigration policy. As a Mississippi Democrat running in a heavily conservative state, he emphasizes bipartisan cooperation and focuses his campaign on economic issues (healthcare, jobs, costs). His stated willingness to 'work with anyone, Republican or Democrat' and focus on 'bringing good jobs home' without immigration specifics suggests a centrist approach. Scoring 3 (maintain current levels while streamlining the legal process) as the most consistent position given no documented stance deviation from mainstream.$$,
        ARRAY['https://scottcolom.com', 'https://scottcolom.com/victory-district-attorney-scott-colom-wins-democratic-senate-primary-advances-to-face-cindy-hyde-smith-in-november-were-going-in-a-new-direction/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Colom has no documented explicit stance on same-sex marriage. However, he signed a letter with other district attorneys opposing the criminalization of gender-affirming surgery, demonstrating support for LGBTQ+ legal protections. He has received endorsements from progressive organizations including the Collective PAC. As a Democrat running statewide in Mississippi, he has not taken a public position on this issue — but his DA actions and progressive endorsements suggest alignment with allowing same-sex marriage nationwide while protecting some organizations' right to decline participation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Scott_Colom', 'https://scottcolom.com/endorsements/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Colom's campaign does not include explicit housing policy positions. His economic platform focuses on healthcare costs, wages, and job creation. He has referenced the Jackson water crisis in criticizing Hyde-Smith's infrastructure vote, suggesting support for federal investment in basic infrastructure. His support for the American Rescue Plan Act (noting Hyde-Smith voted against its funds for Mississippi) implies general support for targeted federal assistance. Scoring 3 (tax incentives for affordable housing) as the most evidence-consistent position without a documented specific stance.$$,
        ARRAY['https://scottcolom.com/victory-district-attorney-scott-colom-wins-democratic-senate-primary-advances-to-face-cindy-hyde-smith-in-november-were-going-in-a-new-direction/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Scott Colom / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '24e9212c-b011-422a-865c-093e35050901',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fd59af4-eca7-4cdc-9082-178278ce3dc8',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Colom has made no documented public statements on Ukraine-Russia policy. His campaign focuses exclusively on domestic Mississippi issues including healthcare, jobs, and costs. His stated desire to be 'the Mississippi Senator' rather than a partisan ideologue, and his emphasis on bringing home resources, suggests a pragmatic rather than interventionist foreign policy posture. Scoring 3 (limited humanitarian aid while encouraging diplomacy) as a reasonable centrist default consistent with his documented pragmatic approach, though no direct evidence exists.$$,
        ARRAY['https://scottcolom.com', 'https://scottcolom.com/victory-district-attorney-scott-colom-wins-democratic-senate-primary-advances-to-face-cindy-hyde-smith-in-november-were-going-in-a-new-direction/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Roy Cooper
-- ============================================================

-- ----- Roy Cooper / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Cooper vetoed the 12-week abortion ban (SB20, May 2023), which was overridden by the NC legislature, and has consistently opposed government intrusion in reproductive healthcare decisions. He stated the 2019 born-alive bill was 'an unnecessary interference between doctors and their patients.' His position supports abortion access through at least the second trimester with exceptions, aligning with value 2.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://www.ncleg.gov/BillLookUp/2023/SB20', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$No specific AI regulation position found in Cooper's gubernatorial record or 2026 campaign materials. As a moderate Democratic governor focused on economic development (he recruited major tech employers to NC), he has shown neither a deregulatory extreme nor a heavy-regulatory stance on emerging technology. Scored centrist given the absence of direct evidence.$$,
        ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Cooper's 1996 policy stances included support for limiting PAC and corporate campaign contributions, and his VoteMatch profile identifies him as favoring limits on campaign spending. His Christian Coalition rating of 27% (1999 state legislative era) and populist-leaning liberal classification on VoteMatch reflect opposition to unlimited money in politics.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cooper fought to repeal HB2 (the bathroom bill) as both Attorney General and Governor, refused to defend it in court, and created a task force on racial equity in criminal justice in 2020. He also championed equal pay for women and supported the Second Chance Act to expunge misdemeanor convictions. Consistent progressive record on civil rights enforcement.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cooper set executive goals to cut greenhouse gas emissions 40% by 2025 and 70% by 2030, called North Carolina a leader in the clean energy economy, and vetoed efforts to weaken environmental regulations in July 2020. He pursued clean energy investment and renewable energy transition as a central gubernatorial priority.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Cooper vetoed legislation in August 2019 that would have required NC sheriffs to cooperate with ICE detainers, and has consistently supported protecting DREAMers from deportation. He supports a framework that deports only those who have committed serious crimes while providing legal pathways for long-term residents.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Cooper pursued clean energy goals and opposed weakening environmental regulations, but North Carolina's energy mix under his tenure included continued fossil fuel use and he did not pursue an explicit drilling ban or permit moratorium. His approach balanced environmental investment with existing energy production, placing him at centrist maintenance of current levels with environmental oversight.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cooper's signature domestic achievement was signing Medicaid expansion into law in March 2023 after years of Republican obstruction, making over 600,000 low-income North Carolinians eligible. He stated 'When we get Medicaid expansion done it will save lives' and consistently pushed for accepting federal Medicaid dollars throughout his tenure.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Cooper's approach as governor included Medicaid expansion (which directly addresses healthcare access for homeless populations), support for behavioral health services, and opposition to criminalization-first approaches to poverty. His 2020 COVID response included emergency housing protections. No explicit bill banning public camping was signed; he favors services and shelter capacity expansion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cooper invested $8 billion in school building and renovation as a proxy for community infrastructure investment, supported workforce housing as part of economic development, and his Medicaid expansion addresses a key driver of housing instability. His 2019 policy positions explicitly supported expanding housing assistance programs consistent with value 2.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cooper vetoed the bill requiring sheriffs to cooperate with ICE (Aug 2019), supported DREAMers, and opposed anti-immigration enforcement measures at the state level. His 2015 support for a 'pause' in Syrian refugee immigration shows he is not at the open-borders extreme, but his overall record strongly supports legal pathways and reduced enforcement burden on immigrants.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Signing Medicaid expansion in 2023 is the clearest evidence of Cooper's position: he strongly supports expanding Medicaid to cover more low-income residents. He fought for this for his entire two terms against Republican opposition, making it the centerpiece of his healthcare legacy.$$,
        ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper', 'https://www.ontheissues.org/Roy_Cooper.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$No specific legislation or clear gubernatorial stance on social media misinformation or algorithmic regulation found in Cooper's record. His general alignment with Democratic mainstream and support for democratic norms suggests support for voluntary standards and fact-checking, but no direct policy action was documented. Scored centrist.$$,
        ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Cooper called for a special redistricting session in 2017 after the Supreme Court found NC legislative maps unconstitutional due to racial gerrymandering, and the legislature refused to hold it. He consistently opposed partisan gerrymandering and supported independent or bipartisan redistricting oversight throughout his tenure.$$,
        ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Cooper opposed HB2 on both anti-discrimination and economic grounds (corporate boycotts cost NC billions), and negotiated its partial repeal. His gubernatorial record reflects a balance: protecting anti-discrimination law while not pursuing aggressive restrictions on religious organizations. He is not at the strict separation extreme, nor does he favor broad religious exemptions from civil rights law.$$,
        ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper', 'https://www.ontheissues.org/Roy_Cooper.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Cooper stated in 2015 that same-sex marriage opt-outs by state officials were 'likely unconstitutional,' refused to defend HB2 in court as Attorney General, and has been a consistent supporter of LGBTQ equality including full marriage rights. His VoteMatch profile classifies him as strongly pro-civil rights, and he has never supported restricting same-sex marriage.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Cooper declared a 'public school emergency' in 2023 opposing Republican proposals to expand school choice scholarship programs, and vetoed a school voucher expansion bill in September 2024. He proposed a 9.1% teacher pay increase and pledged $8 billion for school building investment, making elimination of voucher programs that divert taxpayer money a defining issue of his governorship.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Cooper's populist-liberal profile and opposition to tax breaks for corporations and the wealthy, combined with his record on expanding social safety net programs (Medicaid expansion), strongly indicate opposition to Social Security privatization and support for modest expansion financed by higher contributions from high earners. No explicit privatization or benefit-cut position found.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$No specific tariff or trade policy position found in Cooper's gubernatorial record, where trade policy is primarily a federal issue. As a pro-economic-development governor who actively recruited international manufacturers to NC, he pragmatically supported trade relationships without taking a strong protectionist or free-trade absolutist stance.$$,
        ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cooper stated 'Don't need more tax breaks for corporations or wealthy,' argued that 2013 Republican tax reforms helped only the rich and corporations, and vetoed the 2017 state budget citing problematic income tax cut provisions. His 2026 campaign centers on making things cost less for the middle class and addressing wealth concentration, consistent with raising taxes on high earners.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://roycooper.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Cooper vetoed HB574, the Fairness in Women's Sports Act, on July 5, 2023, opposing the ban on transgender girls competing on girls' sports teams. The veto was overridden by the legislature on August 16, 2023. His veto reflects support for allowing transgender athletes to compete on teams matching their gender identity after basic transition documentation.$$,
        ARRAY['https://www.ncleg.gov/BillLookUp/2023/HB574', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Cooper stated in April 2023 that 'North Carolina stands with people of Ukraine,' reflecting support for US aid to Ukraine. As governor without a direct vote on aid packages, his stated position aligns with continuing current levels of military and economic support for Ukraine's defense.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roy Cooper / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f7429f7-1ecd-4f44-abce-03c72d5cf664',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Cooper stated 'Voter ID is a solution for no problem' in 2020, vetoed the partisan election board restructuring bill (2017), and consistently opposed Republican efforts to restrict ballot access in North Carolina. He supports expanded early voting, mail-in voting access, and automatic registration consistent with value 2.$$,
        ARRAY['https://www.ontheissues.org/Roy_Cooper.htm', 'https://en.wikipedia.org/wiki/Roy_Cooper']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Harriet Hageman
-- ============================================================

-- ----- Harriet Hageman / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$When asked under what circumstances abortion should be allowed, Hageman stated: "I do not believe that there are circumstances where abortion should be allowed." She also strongly opposes federal funding for abortion providers including Planned Parenthood (2022 AFA iVoterGuide).$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Abortion.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Hageman strongly disagrees that sexual orientation or gender identity should be protected classes in non-discrimination law. She opposes reparations, stating "I do not know anyone who is racist," and rejects Critical Race Theory, dismissing the idea that U.S. institutions are fundamentally racist (2022 AFA iVoterGuide).$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Civil_Rights.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hageman's LCV lifetime score is 1% (0% in 2023, 0% in 2025), reflecting opposition to virtually every measure addressing climate action, clean energy, and pollution limits. She opposes stricter environmental regulations, stating they "cost too many jobs and hurt the economy," and praised the Supreme Court's Chevron decision limiting EPA authority.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/moc/harriet-hageman', 'https://www.ontheissues.org/House/Harriet_Hageman_Energy_+_Oil.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Hageman has declared: "We need to fight for and protect coal, oil and gas, our agricultural industries." She strongly supports fracking, opposes environmental restrictions on fossil fuel production, and introduced legislation to block BLM resource management plans that restricted oil, gas, and coal leasing in Wyoming. Her LCV score is 0% in 2023 and 2025.$$,
        ARRAY['https://wyofile.com/hageman-blasts-administrative-state-enviro-agencies/', 'https://wyofile.com/in-new-leadership-post-hageman-takes-fresh-aim-at-federal-land-grizzly-policies/', 'https://www.lcv.org/congressional-scorecard/moc/harriet-hageman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hageman opposes any new taxpayer-funded healthcare programs beyond existing Medicare and Medicaid, stating: "The more power we give the government over such things like healthcare the less free we will be." She has not proposed a public option or single-payer system and opposes government mandates in healthcare decisions.$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Health_Care.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Hageman strongly supports physically securing the southern border and opposes chain migration, stating: "All immigration should be limited to legal immigration." She strongly agrees that federal funding should be withheld from sanctuary cities, and voted for the Laken Riley Act in 2025 mandating detention of undocumented immigrants charged with certain crimes.$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Immigration.htm', 'https://wyofile.com/hageman-cuts-short-casper-town-hall-after-contentious-exchanges-over-ice-killings/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Hageman supported the Laken Riley Act and defended Trump's mass deportation approach at town halls. When pressed about due process concerns in the Kilmar Abrego Garcia case (a deportee returned to El Salvador in error), she defended the administration's refusal to comply with the Supreme Court's unanimous order to facilitate his return, arguing the case had received adequate process.$$,
        ARRAY['https://wyofile.com/truth-is-a-casualty-of-hagemans-town-halls/', 'https://wyofile.com/hageman-cuts-short-casper-town-hall-after-contentious-exchanges-over-ice-killings/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hageman supports making the Trump tax cuts for individuals and businesses permanent and advocates simplifying the tax code by cutting rates. She strongly disagrees with income redistribution, stating it is not "needed to lessen the gap between the wealthy and working classes," and strongly agrees the government should cut spending to reduce the national debt (2022 AFA iVoterGuide).$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Tax_Reform.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hageman calls for mandatory photo ID to vote, eliminating drop boxes, returning to in-person-only voting, shortening Wyoming's voting period from 6 weeks to 1-2 weeks, and prohibiting NGO funds in the electoral process. She also advocates for robust poll-watching and prosecution of voter fraud to the fullest extent of the law.$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Government_Reform.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Hageman strongly agrees that religious liberty deserves the highest legal protection, stating: "The individual is paramount in our constitutional Republic, and an individual's right to freely and openly exercise their religion is critical to our future." She argues the government has taken "an outright hostile stance against people of faith" and criticized COVID pandemic restrictions on religious gatherings as "a blatant violation of the First Amendment."$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Principles_+_Values.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Hageman is classified as Hard-Core Conservative by OnTheIssues' VoteMatch assessment, which includes strong opposition to same-sex marriage among its criteria. She opposes protected-class status for sexual orientation and gender identity, and her 0% HRC-equivalent record and alignment with social-conservative positions indicate opposition to federal recognition of same-sex marriage.$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman.htm', 'https://www.ontheissues.org/House/Harriet_Hageman_Civil_Rights.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Hageman strongly disagrees that gender identity should be a protected class. At a March 2025 town hall, when asked about protecting transgender and non-binary individuals, she responded: "I don't even know what that means." Her opposition to gender identity protections and her Hard-Core Conservative VoteMatch classification make her opposed to allowing transgender athletes to compete on teams matching their gender identity.$$,
        ARRAY['https://wyofile.com/crowd-jeers-hageman-at-tense-laramie-town-hall-she-calls-them-hysterical/', 'https://www.ontheissues.org/House/Harriet_Hageman_Civil_Rights.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '24e9212c-b011-422a-865c-093e35050901',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Hageman voted against Ukrainian aid funding in the 118th Congress (confirmed by WyoFile reporting). On NATO, she voted with Marjorie Taylor Greene to cut $433 million in NATO infrastructure funding, saying: "NATO is failing. The USA has been shouldering more than our share for decades." She endorsed Trump's non-interventionist position during her 2022 campaign, positioning herself against Ukraine military support.$$,
        ARRAY['https://wyofile.com/rep-hageman-undermined-nato-with-her-misguided-vote/', 'https://wyofile.com/after-criticizing-warmonger-liz-cheney-hageman-backs-u-s-intervention-in-iran/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Hageman supports prohibiting private and NGO funds in the electoral process, citing Mark Zuckerberg's foundation as an example of inappropriate private influence on elections. While this aligns with some campaign finance reform rhetoric, her broader position opposes federal regulation and she has not supported public financing of campaigns.$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Government_Reform.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Hageman strongly supports law enforcement, stating she is a "strong supporter of our police officers" and strongly disagrees with redirecting police funding to mental health and community programs. She supports qualified immunity for police acting pursuant to department policy and opposes any defund-police approach.$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Crime.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Hageman opposes expanding Medicare or Medicaid beyond their current scope, stating "No new taxpayer-funded programs beyond Medicare/Medicaid." She has not proposed lowering the Medicare eligibility age or significantly expanding Medicaid, and her general stance on limiting government programs suggests she would oppose major new Medicare expansions, though she has not called for privatization.$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Health_Care.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$At the March 2025 Laramie town hall, Hageman indicated support for replacing federal education formula-funding with flexible block grants to states. Her broader philosophy of reducing federal involvement in education aligns with school choice and voucher expansion, though she stopped short of endorsing universal vouchers explicitly.$$,
        ARRAY['https://wyofile.com/crowd-jeers-hageman-at-tense-laramie-town-hall-she-calls-them-hysterical/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Hageman strongly supports police and opposes criminal justice reform. She strongly disagrees with redirecting police funding to mental health and community programs, and supports qualified immunity for officers. She also supports robust enforcement of voter fraud laws, and opposes what she characterizes as politically motivated use of the justice system (while defending Trump's legal posture).$$,
        ARRAY['https://www.ontheissues.org/House/Harriet_Hageman_Crime.htm', 'https://wyofile.com/how-low-will-hageman-go-to-defend-her-political-savior/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Hageman, a constitutional attorney and Judiciary Committee member, holds that the Founders intended only the Legislative Branch to make law. She praised the Supreme Court's Chevron decision eliminating judicial deference to agency interpretations, and consistently attacks administrative agencies for making rules that should require legislative action. Her Judiciary Committee work focuses on the Subcommittee on the Administrative State, Regulatory Reform, and Antitrust.$$,
        ARRAY['https://en.wikipedia.org/wiki/Harriet_Hageman', 'https://wyofile.com/hageman-blasts-administrative-state-enviro-agencies/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Harriet Hageman / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2f59e14-a81d-45fe-86c0-c992a63d86cd',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Hageman has argued that the FBI and government agencies have no legal authority to pressure social media platforms, stating: "Neither you or the FBI have any legal authority to circumvent the First Amendment by using a surrogate to do your dirty work." She views government involvement in content moderation as unconstitutional overreach and opposed any federal social media regulation.$$,
        ARRAY['https://wyofile.com/how-low-will-hageman-go-to-defend-her-political-savior/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kevin Hern
-- ============================================================

-- ----- Kevin Hern / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Hern stated 'All life is sacred and begins at conception' (Oct 2018) and sponsored legislation protecting infants who survive abortion (Feb 2019). He opposes abortion in virtually all circumstances and supports only exceptions for maternal life at most, consistent with a near-total ban position.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hern stated 'Replace ObamaCare with free-market driven healthcare' (Oct 2018), opposes extending ACA tax credits, and supports Health Savings Accounts and self-insurance as the primary alternatives to government-managed coverage. His position favors leaving healthcare to private markets.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hern stated 'Repeal 16th Amendment; strategically move to Flat Tax' (Sep 2018), consistently signed anti-tax pledges, and as Republican Study Committee Chair pushed for deep spending cuts. He opposes all tax increases and advocates a flat tax rate for all Americans regardless of income.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Hern stated 'Look at ways to privatize' Social Security (Sep 2018) and as RSC Chair promoted the annual RSC Budget which consistently includes transitioning Social Security to private investment accounts. He favors shifting away from the current system toward individual-controlled accounts.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Hern opposes the ACA and supports market-based healthcare alternatives. His RSC Budget chairmanship included proposals to partially privatize Medicare through premium support and reduce Medicaid by block-granting it to states. He favors reducing federal involvement while maintaining limited coverage for those who cannot afford private care.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Hern stated 'Marriage is a sacrament between a man and a woman' (Oct 2018) and voted against the Respect for Marriage Act codifying federal same-sex marriage rights. He advocates for defining marriage exclusively as between one man and one woman.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Hern stated 'Enforce existing immigration laws & secure borders' and 'Build the border wall, not sanctuary cities' (Sep 2018). He requires undocumented immigrants to 'return to their country of origin before they are eligible for citizenship,' opposing any in-country pathway. He has voted against all refugee and border leniency measures.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Hern supports enforcing immigration laws against all undocumented immigrants but emphasizes exit-and-reenter legalization pathway rather than immediate mass deportation without any process. He opposes sanctuary cities and favors deportation prioritized by criminal history.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hern stated 'Regulating climate change is not a government responsibility' (Sep 2018) and voted against rural renewable energy assistance. He opposes government climate regulation and his record reflects rejecting climate change policy in favor of economic growth and energy development.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Hern opposes all government climate regulation and voted against assisting rural electric renewable energy (Sep 2020). He supports removing environmental restrictions on energy production. His stated position that climate regulation is not a government responsibility implies maximizing fossil fuel extraction.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hern voted against the For the People Act both times it was introduced (2019, 2021), opposing automatic voter registration, same-day registration, expanded mail-in voting, and early voting. He also voted to overturn 2020 election results and signed an amicus brief for Texas v. Pennsylvania, and opposed the January 6 commission.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Hern voted against the For the People Act provisions requiring disclosure of independent campaign expenditures and presidential tax returns. His stated position as a business-first Republican opposes restrictions on political donations and spending.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Hern voted against the For the People Act's requirement that states establish independent nonpartisan redistricting commissions. His position favors allowing state legislatures to control redistricting without outside interference.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Hern voted against private lawsuits for school race discrimination (Sep 2020), opposed the Equal Rights Amendment ratification extension, and opposes affirmative action. He advocates 'limited government established by Judeo-Christian values' with no support for race-based government programs or equity mandates.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Hern advocates for 'limited government established by Judeo-Christian values' and his positions on marriage and civil rights consistently prioritize religious organizational autonomy over anti-discrimination protections. He supports broad faith-based exemptions from civil rights laws.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Hern as RSC Chair supported legislation restricting transgender athletes to compete only on teams matching their biological sex. As a hard-core social conservative who opposes same-sex marriage and LGBTQ+ anti-discrimination protections, he supports a complete ban on transgender athletes in women's sports.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '24e9212c-b011-422a-865c-093e35050901',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Hern voted against the Fiscal Responsibility Act (2023) which included Ukraine aid, and has been aligned with the RSC's skeptical position on open-ended Ukraine commitments. His foreign policy record reflects support for reducing U.S. involvement and domestic spending prioritization over continued Ukraine aid at current levels.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Hern supported USMCA for improved North American trade and as a Trump-aligned Republican backed the administration's tariff posture on unfair trading partners including China. He favors tariffs as a tool against countries that don't trade fairly while maintaining core trade relationships.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Hern has opposed public school race discrimination lawsuits and as RSC Chair championed parental rights in education. The RSC's education platform under Hern's leadership (2023-2025) promoted universal school choice and education savings accounts, aligning with universal vouchers following the student to any school.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Hern / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b1114b75-8ca1-494e-9251-e8faa84ff408',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Hern is a business-first Republican who opposes government regulatory burdens on industry. His general philosophy of 'reduce business regulations; economic growth will follow' and his opposition to net neutrality regulation signal opposition to government interference in AI development, favoring industry self-regulation.$$,
        ARRAY['https://www.ontheissues.org/Senate/Kevin_Hern.htm', 'https://en.wikipedia.org/wiki/Kevin_Hern']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Dan Osborn
-- ============================================================

-- ----- Dan Osborn / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Osborn opposes insurance companies making healthcare decisions and Big Pharma subsidies, but has not endorsed a single-payer system or public option. His populist stance targets the healthcare industry rather than structural system change, aligning with cost regulation under the current insurance framework.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Osborn stated he does not support national measures to ban abortion and has said 'Since Roe v. Wade has been overturned, abortions are on the rise and women are dying,' indicating he supports access within Roe limits. He describes himself as personally pro-life but opposes a federal ban, placing him in the allow-first-trimester / health-exceptions range.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Osborn supports Congress reclaiming tariff authority from the executive branch and backs trade protections for American workers. As a union organizer he has championed protecting domestic manufacturing and workers from unfair trade, but his Nov 2025 position focuses on congressional control rather than blanket high tariffs, placing him between selective protectionism and increased tariffs.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Osborn advocates closing tax loopholes for multinational corporations and supports progressive taxation with lower rates on small businesses and overtime workers. He opposes allowing overtime wages to trigger higher brackets. His stance is to raise taxes on large corporations and high earners while protecting working-class tax burdens.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Osborn explicitly supports removing the contribution cap on Social Security (lifting the payroll tax ceiling so high earners contribute on all income) and proposes moving the full retirement age back to 65. Removing the cap is the signature revenue mechanism for significantly expanding Social Security, aligning with stance 1.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Osborn views illegal immigration as detrimental to workers and supports increased border security including building a border wall. He also supports reforming the immigration system and exploring ways to legalize long-term non-criminal undocumented residents, which prevents a 5 rating. His primary frame is border enforcement with limited humanitarian carveout.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Osborn supports removing people without legal status but has expressed openness to legalizing long-term non-criminal undocumented residents. He also stated ICE should be held to consistent standards with other law enforcement agencies (Feb 2026), suggesting he supports deportation as a tool but with process constraints. He is not calling for immediate mass removal.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Osborn's environmental position is 'keep our air breathable and our water and land clean' (Oct 2024) — a general environmental protection stance without endorsing rapid fossil fuel phase-out, carbon bans, or a Green New Deal framework. He favors investment in clean energy while not committing to aggressive timelines.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$No specific stance on new drilling permits found, but Osborn's environmental position focuses on clean air and water protection rather than expanding or immediately restricting fossil fuel extraction. As a Nebraska union worker he is attentive to energy sector jobs. He is scored at the centrist maintain-current-levels position given the absence of strong evidence in either direction.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Osborn has not taken a clear public stance on voter ID, mail-in voting, or voting access expansion. His focus on getting big money out of politics and term limits reflects concern for democratic integrity, but no specific voting rights position has been recorded. Scored as centrist/no clear position.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Osborn has stated 'People's private lives are no business but their own' (Jul 2024) and takes a libertarian view on social issues, opposing government interference in private matters. He has not advocated for restricting same-sex marriage and his general stance supports LGBTQ individuals' right to privacy, aligning with allowing same-sex marriage while protecting some religious organizations' autonomy.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Osborn supports civil liberties and personal freedom ('people's private lives are no business but their own') but has not endorsed reparations, specific affirmative action programs, or expanded federal civil rights enforcement. His labor and workers' rights focus addresses economic inequality but his civil rights stance is more libertarian than progressive-activist.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Osborn's primary stated goal if elected is to 'get big money out of American politics.' He refuses endorsements from political parties and runs as an independent specifically to avoid big-money influence. This aligns with strictly limiting corporate donations and dark money, though he has not specifically called for publicly funded campaigns.$$,
        ARRAY['https://en.wikipedia.org/wiki/Dan_Osborn', 'https://www.ontheissues.org/Senate/Dan_Osborn.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Osborn explicitly opposes voucher programs for private schools (May 2024). OnTheIssues scores him as strongly opposing school vouchers, consistent with his union-worker constituency and public institution support.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Osborn's healthcare populism — opposing Big Pharma subsidies and insurance company control — combined with his Social Security expansion stance suggests support for lowering Medicare eligibility age and expanding Medicaid. He has not explicitly called for Medicare-for-All, aligning with stance 2 (lower Medicare age / expand Medicaid significantly).$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Osborn explicitly supports ensuring adequate resources for law enforcement and first responders. He has not endorsed defunding or redirecting police budgets to social services. His populist-conservative stance on public safety aligns with increasing police staffing and resources.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm', 'https://en.wikipedia.org/wiki/Dan_Osborn']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dan Osborn / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('79e1e32f-9b0d-4f8f-86f3-679185424596',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$No specific stance on redistricting or gerrymandering found. As an independent candidate who explicitly rejects both parties, Osborn would likely favor nonpartisan approaches, but no recorded position exists. Scored as no clear evidence.$$,
        ARRAY['https://www.ontheissues.org/Senate/Dan_Osborn.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Chris Pappas
-- ============================================================

-- ----- Chris Pappas / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Pappas favors expanding Medicaid, Medicare, and the ACA and supports keeping the ACA's individual mandate, but has not endorsed Medicare for All. He supports expanding coverage through regulated private insurance and public programs — consistent with offering a public option alongside private plans.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm', 'https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Pappas supported publicly funded abortions (Jul 2018), supported passing federal legislation to restore abortion rights after Roe's overturn (Jun 2022), and is a member of the House Pro-Choice Caucus. His support for public funding of abortion aligns with stance 1 (legal, accessible, and publicly funded).$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm', 'https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Pappas supported the USMCA trade deal with labor and environmental safeguards (Jan 2020), advocating for improved North American trade. He has not called for blanket tariff elimination or aggressive tariff increases, placing him in selective use of trade policy to protect key industries while maintaining open trade frameworks.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Pappas favors reversing the 2017 federal income tax cuts and raising taxes on high earners to balance the budget. He believes lower corporate taxes don't promote growth and supports progressive tax reform. This aligns with modestly increasing taxes on high earners while maintaining current rates for middle-class families.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Pappas is the first openly gay man to represent New Hampshire in Congress and co-chairs the Congressional Equality Caucus. He co-sponsored the Equality Act and is a consistent advocate for full federal LGBTQ+ equality including same-sex marriage recognition with full federal benefits and protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)', 'https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Pappas sponsored the Equal Rights Amendment ratification bill, co-sponsored the Equality Act, protested the transgender military service ban, and opposed religious travel restrictions via the NO BAN Act. He consistently supports strengthening civil rights enforcement and addressing systemic discrimination against LGBTQ people and religious minorities.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm', 'https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Pappas supports funding renewable energy (wind and solar), backing greenhouse gas emission regulation, and called on the EPA to maintain and strengthen the Clean Water Act. He supports rapid investment in clean energy and reducing fossil fuel reliance, though he has not endorsed an immediate phase-out or emergency declaration.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Pappas supports funding renewable energy and greenhouse gas regulation, and voted to assist rural electric renewable energy (Sep 2020). He has not supported expanding fossil fuel drilling permits and his overall clean energy stance suggests stopping or limiting new fossil fuel permits while transitioning to renewables.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Pappas opposed photo ID voting requirements, sponsored a voter registration expansion bill (Feb 2021), sponsored Washington D.C. statehood, backed an election day holiday, and expanded voting access. He sponsored the 'Protecting Our Democracy' legislation (Oct 2021), aligning with expanding early voting and making mail-in voting widely available.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm', 'https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Pappas voted for the Laken Riley Act in 2025 (with Republicans and 45 other Democrats), calling it necessary federal law enforcement tools. He also supports a path to citizenship for long-term residents and increased high-skill and family-based visa caps, placing him at centrist — maintaining current levels while streamlining legal processes.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)', 'https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Pappas voted for the Laken Riley Act (2025) providing federal law enforcement with tools to detain and deport immigrants who commit crimes. He supports pathways to citizenship for long-term non-criminal residents. This centrist position prioritizes deporting recent border crossers and criminals while allowing long-term residents to apply for legal status.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)', 'https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Pappas explicitly opposes cuts to Social Security and Medicare for tax cuts (Jan 2020). He has supported expanding Medicare and Medicaid coverage, suggesting modest benefit increases. His centrist Democratic approach aligns with increasing benefits modestly while raising taxes on higher earners to strengthen the program.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Pappas favors expanding Medicaid and Medicare as part of his broader healthcare expansion platform, opposing cuts to either program. He supports lowering barriers to coverage and expanding who qualifies for Medicaid, consistent with significantly lowering the Medicare age and expanding Medicaid.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm', 'https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Pappas supports regulating campaign donations from corporations and opposes unrestricted money in politics. He sponsored or supported transparency and democracy protection legislation. OnTheIssues rates him as favoring campaign finance regulation, aligning with strictly limiting corporate donations and dark money groups.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Pappas explicitly opposes private school vouchers (Jul 2018) and favors federal education standards for public schools. He has voted against programs that divert taxpayer money from public to private institutions.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Pappas protested the transgender military service ban at the State of the Union (Feb 2019) and co-chairs the Equality Caucus. As an LGBTQ rights champion he has consistently opposed restrictions on transgender participation in public life, suggesting support for trans athletes competing on teams matching gender identity after basic transition documentation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)', 'https://www.ontheissues.org/House/Chris_Pappas.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Pappas opposed religious travel restrictions via the NO BAN Act (Mar 2020), co-sponsored the Equality Act which limits religious exemptions from anti-discrimination law, and supports LGBTQ protections. His record favors protecting religious freedom while ensuring it does not override anti-discrimination protections in employment and housing.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm', 'https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chris Pappas / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4f51d46-c361-4b17-bd63-7932a01ee2c3',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Pappas sponsored the 'Protecting Our Democracy' legislation (Oct 2021) which addresses redistricting and election integrity issues, and sponsored the D.C. Statehood bill. He has consistently voted to strengthen democratic institutions and reduce partisan manipulation of elections.$$,
        ARRAY['https://www.ontheissues.org/House/Chris_Pappas.htm', 'https://en.wikipedia.org/wiki/Chris_Pappas_(American_politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- David Brock Smith
-- ============================================================

-- ----- David Brock Smith / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Smith is pro-life and opposes government funding for Planned Parenthood. He considers frozen embryos as children and opposes abortion access, aligning with a complete anti-abortion position without documented exceptions.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/social', 'https://ballotpedia.org/David_Brock_Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Smith supports regulating AI for ethical use and backs banning AI-generated deepfakes unless clearly labeled, indicating support for targeted safety oversight rather than either a hands-off or heavy regulatory approach.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies', 'https://www.isidewith.com/candidates/david-brock-smith/policies/domestic-policy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Smith considers campaign contribution limits a violation of free speech and supports allowing corporations and unions to donate to political parties. He opposes foreign lobbyists raising money but broadly supports unrestricted domestic campaign spending.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/electoral', 'http://davidbrocksmithfororegon.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Smith opposes universal pre-K federal funding and rejects government-subsidized childcare programs. His broader platform opposes expanding government social spending, leaving childcare to families and private markets.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/education', 'http://davidbrocksmithfororegon.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Smith opposes affirmative action and supports eliminating diversity, equity, and inclusion initiatives in favor of merit-based hiring. He also opposes adding gender identity to anti-discrimination laws and rejects mandatory diversity training in schools and workplaces.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/social', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Smith opposes increased environmental regulations to address climate change and supports U.S. withdrawal from the Paris Climate Agreement. His campaign and iSideWith profile show consistent opposition to climate policy mandates, favoring economic growth over emissions restrictions.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/environmental', 'http://davidbrocksmithfororegon.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Smith supports deporting immigrants convicted of serious crimes and allows local law enforcement to detain undocumented immigrants even for minor offenses. He opposes amnesty for working undocumented immigrants but focuses enforcement on criminal history rather than universal immediate deportation.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/immigration', 'https://ballotpedia.org/David_Brock_Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Smith supports expanding offshore oil drilling, drilling in the Alaska Wildlife Refuge, and lifting the moratorium on LNG export licenses. He also supports hydraulic fracking and opposes environmental restrictions on fossil fuel extraction.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/environmental', 'http://davidbrocksmithfororegon.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Smith opposes both the Affordable Care Act and single-payer healthcare, favoring market-based solutions. He does support government negotiation of Medicare drug prices and opposes denying coverage for pre-existing conditions, stopping short of full privatization.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/healthcare', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Smith's campaign site explicitly opposes permanent street camping and criticizes current homelessness spending as ineffective. He advocates for drug and mental health treatment with accountability for repeat offenders, favoring enforcement and treatment requirements over decriminalization.$$,
        ARRAY['http://davidbrocksmithfororegon.com/issues', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Smith opposes permanent street camping and favors enforcement of anti-camping rules alongside required drug and mental health treatment. His campaign criticizes homelessness spending as ineffective under a 'far-left agenda,' indicating enforcement as the primary tool alongside services.$$,
        ARRAY['http://davidbrocksmithfororegon.com/issues', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Smith supports affordable housing incentives and backs bans on corporate and foreign real estate investment, suggesting a market-friendly but interventionist mix. His campaign also promotes locally sourced timber for housing production, reflecting a private-sector-led approach rather than government housing programs.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies', 'http://davidbrocksmithfororegon.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Smith supports building a southern border wall, declaring a national emergency at the border, mandatory E-Verify, and defunding sanctuary cities. He opposes birthright citizenship for children of undocumented immigrants and any amnesty for working undocumented residents.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/immigration', 'https://ballotpedia.org/David_Brock_Smith', 'http://davidbrocksmithfororegon.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Smith supports accountability for repeat offenders and backs police use of military-grade equipment, with strong support for law enforcement capacity. His campaign site calls for consequences-based approaches to crime rather than diversion or alternatives to incarceration.$$,
        ARRAY['http://davidbrocksmithfororegon.com/issues', 'https://www.isidewith.com/candidates/david-brock-smith/policies/domestic-policy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Smith opposes increasing Medicaid funding for low-income individuals, requires work for Medicaid eligibility, and favors more privatization of veterans' healthcare. He does not support expanding Medicare coverage or lowering the eligibility age.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/healthcare', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Smith opposes government social media regulation to prevent misinformation, reflecting a strong free-speech posture. He does support banning AI-generated deepfakes unless clearly labeled, but his general stance tilts toward preventing government content censorship.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/domestic-policy', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Smith's campaign site lists strong support for law enforcement and 'accountability for repeat offenders' as a top priority. He opposes defunding the police and supports police use of military-grade equipment, backing increased law enforcement capacity over social service redirection.$$,
        ARRAY['http://davidbrocksmithfororegon.com/issues', 'https://www.isidewith.com/candidates/david-brock-smith/policies/domestic-policy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Smith supports independent redistricting commissions, a notable departure from typical Republican positions favoring legislative control. This is documented on his iSideWith profile, suggesting he backs the independent commission model for drawing district maps.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/domestic-policy', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Smith supports businesses denying service based on religious beliefs and backs religious exemptions from civil laws. He also opposes separating church and state references from government property and opposes taxing religious institutions.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/social', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Smith explicitly opposes same-sex marriage, stating marriage should be defined as between a man and a woman. He also opposes equal adoption rights for same-sex couples.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/social', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Smith supports school voucher programs allowing students to attend private schools at public expense, and backs charter schools. He opposes Common Core and favors education decisions at the state and local level, with vouchers as a key school choice mechanism.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/education', 'http://davidbrocksmithfororegon.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Smith opposes raising Social Security payroll taxes on high earners and supports transitioning government pensions to private investment accounts. He favors reducing government social spending generally, aligning with a partial-privatization direction rather than expansion.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/economic', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Smith supports increasing tariffs on imports from China and backs tax breaks to retain domestic manufacturing jobs. He favors selective protectionist tariffs as a trade enforcement tool rather than either free trade or blanket maximum tariffs.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/economic', 'http://davidbrocksmithfororegon.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Smith opposes raising taxes on wealthy individuals and corporations, supports lowering corporate tax rates, and favors government spending cuts. He also supports eliminating taxes on tips and suspending gasoline taxes, reflecting broad conservative tax-cutting positions short of a flat tax.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/economic', 'http://davidbrocksmithfororegon.com/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Smith opposes transgender athletes competing on teams matching their gender identity rather than their biological sex assigned at birth. He also supports government recognition of only two biological sexes and opposes adding gender identity to anti-discrimination laws.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/social', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '24e9212c-b011-422a-865c-093e35050901',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Smith explicitly opposes providing military supplies and funding to Ukraine and opposes Ukraine joining NATO. This is documented in his iSideWith foreign policy profile, placing him in the non-interventionist, anti-Ukraine-aid wing of the Republican Party.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/foreign-policy', 'https://www.isidewith.com/candidates/david-brock-smith/policies']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Brock Smith / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae7e8d67-e8a4-49a7-bb5c-715c99168374',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Smith supports requiring photo ID to vote, opposes automatic mail-in voting for all voters, and opposes automatic voter registration. He also signed a December 2020 letter urging Oregon's Attorney General to support the Texas lawsuit contesting the 2020 presidential election results.$$,
        ARRAY['https://www.isidewith.com/candidates/david-brock-smith/policies/electoral', 'https://ballotpedia.org/David_Brock_Smith']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- John Sununu
-- ============================================================

-- ----- John Sununu / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Rated 0% by NARAL and 100% by the National Right to Life Committee during his Senate term, reflecting a consistent anti-abortion voting record. Has not publicly called for a total ban but has opposed abortion access through legislative votes, aligning with a position that restricts abortion to limited circumstances.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$No specific AI regulation position is on record from his Senate tenure (2003-2009), predating the current AI era. His general pro-market, anti-regulation philosophy (Club for Growth 100% rating 2005-2006) suggests a preference for light oversight, but his record on technology — opposing Internet access taxes, supporting earmark transparency — indicates some appetite for targeted government standards. Scored as centrist given insufficient direct evidence.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Sponsored earmark transparency legislation and is on record defending the Senate filibuster, but his 83% US Chamber of Commerce rating and overall conservative voting record indicate opposition to strict limits on political spending. No explicit support for public financing or strict campaign contribution limits found.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm', 'https://en.wikipedia.org/wiki/John_E._Sununu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Rated 14% by the NAACP (anti-affirmative action) and 13% by the ACLU during his Senate tenure, supporting conservative positions including an anti-flag desecration amendment. Voted with Republican caucus 84.4% of the time on civil rights-related roll calls, opposing race-based government programs.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$His climate record is genuinely mixed: he voted against the 2003 Climate Stewardship Act but was lead Republican co-sponsor of the 2007 Clean Air Planning Act (cap-and-trade) and supported the 2008 bipartisan Clean Energy Stimulus Act. LCV rated him 42%, placing him as a moderate who accepts climate science but opposes aggressive mandates.$$,
        ARRAY['https://en.wikipedia.org/wiki/John_E._Sununu', 'https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Strongly opposed amnesty for undocumented immigrants and voted against the McCain-Kennedy comprehensive immigration reform bill in July 2007. Called for banning undocumented immigrants from federal benefits and opposing sanctuary cities, placing him clearly in the deport-by-legal-status camp, though no mass-deportation rhetoric was documented.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm', 'https://en.wikipedia.org/wiki/John_E._Sununu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Favored expanded domestic energy exploration including Outer Continental Shelf oil and gas leasing, rated only 17% by the Clean Air Future coalition for opposing energy independence mandates. Co-sponsored a 2005 Clean Air Act vote against EPA de-listing of coal, suggesting he supports conventional fossil fuel extraction with modest pollution controls.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Rated 12% by the American Public Health Association (anti-public health record) and supports expanding Medical Savings Accounts, reflecting a market-based approach. Opposed government-run health programs but stopped short of calling for eliminating all public programs; in his 2025 campaign announcement he pledged to protect Medicare and Social Security.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Voted against the McCain-Kennedy immigration reform bill (2007), declared English the official US language, opposed sanctuary cities, and called for limiting H-visa access. Rated 58% by the US Border Control on open borders policy. Consistently restrictionist on legal and illegal immigration.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm', 'https://en.wikipedia.org/wiki/John_E._Sununu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$ARA (American Retirement Association) rated him 20% — a strongly anti-senior record — during his Senate tenure, consistent with his support for partial privatization of Social Security and market-based healthcare approaches. His 2025 campaign pledge to protect Medicare suggests rhetorical moderation, but his voting record aligns with reducing program scope.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$No direct statement on independent redistricting commissions found in his Senate record or 2026 campaign materials. His 84.4% Republican voting alignment and opposition to government reform measures suggests he favors legislative control of redistricting consistent with conservative Republican positions, though no explicit position was located.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Rated 100% by the Christian Coalition, supporting school prayer provisions and traditional family values. His record reflects strong support for religious exemptions and faith-based organizational autonomy, consistent with a values-conservative who prioritizes religious free exercise over anti-discrimination application.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$HRC rated him 33% — mixed on gay rights — reflecting a nuanced record. He notably voted against the Federal Marriage Amendment in 2006, showing resistance to a federal constitutional ban, but did not support same-sex marriage equality. This places him at value-4: recognizing some civil protections while reserving marriage for opposite-sex couples by statute.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm', 'https://en.wikipedia.org/wiki/John_E._Sununu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Explicitly supports private-school vouchers and charter schools per OnTheIssues, rated 27% by the NEA (anti-public education votes). Supports school prayer provisions as well, reflecting a strong school-choice conservative stance, though not at the most extreme end of eliminating all public school funding.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Proposed creating personal retirement accounts within Social Security — the partial privatization approach — and the ARA rated him 20%. His 2025 campaign announcement included a pledge to protect Social Security, but his Senate-era voting record strongly favors market-based reforms over program expansion.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$CATO Institute rated him 83% on free trade — strongly pro-free trade — during his Senate tenure, opposing protectionist tariffs. However, as a 2026 Republican primary candidate in a Trump-aligned environment, he has not publicly repudiated Trump-era tariff policies. His historical record is clearly free-trade oriented.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Rated 85% by the National Taxpayers Union (Taxpayer's Friend), 0% by Citizens for Tax Justice (opposes progressive taxation), and earned the Americans for Tax Reform 'Friend of the Taxpayer' award. Called for phasing out the estate tax and opposed all Internet access taxes. Consistent broad tax-cut record, though not at the flat-tax extreme.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$No specific recorded position on transgender athletes during his 2003-2009 Senate tenure; the issue was not yet legislatively prominent. His 100% Christian Coalition rating and socially conservative record strongly indicate support for biological-sex-based sports eligibility, consistent with current Republican Party positions. Scored 4 based on his overall socially conservative profile.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '24e9212c-b011-422a-865c-093e35050901',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        '24e9212c-b011-422a-865c-093e35050901',
        $$No specific 2026 Ukraine position found. His Senate-era record showed a humanitarian interventionist streak (supported UN peacekeeping in Darfur, Burma sanctions, Armenia genocide resolution) and he is not aligned with the isolationist wing of the GOP. However, his 2025-2026 campaign has not produced a clear Ukraine aid commitment, warranting a centrist/diplomatic score.$$,
        ARRAY['https://en.wikipedia.org/wiki/John_E._Sununu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Sununu / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$No explicit statements on voting ID requirements or mail-in voting in his current campaign materials. His general conservative record (84.4% Republican voting alignment, 13% ACLU rating) and libertarian-leaning conservatism suggest support for voter ID and election integrity measures consistent with Republican mainstream positions, though he did show independence on civil liberties issues like the PATRIOT Act filibuster.$$,
        ARRAY['https://www.ontheissues.org/senate/john_sununu.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Michael Whatley
-- ============================================================

-- ----- Michael Whatley / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Whatley is a strong social conservative aligned with the NC GOP and Trump Republican orthodoxy. As NCGOP chair he promoted the party's anti-abortion platform and endorsed candidates opposing abortion access. No exceptions position is consistent with the state party platform he led.$$,
        ARRAY['https://michaelwhatley.com', 'https://en.wikipedia.org/wiki/Michael_Whatley']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Whatley's campaign website explicitly states he supports 'tax cuts for the middle class as well as no taxes on tips, overtime, and Social Security,' mirroring Trump's 2024 tax agenda. This aligns with broad tax-reduction across income levels rather than a flat tax.$$,
        ARRAY['https://michaelwhatley.com', 'https://en.wikipedia.org/wiki/Michael_Whatley']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Whatley spent more than a decade as Executive Vice President of the Consumer Energy Alliance, a fossil fuel industry lobbying group, and worked as a Deputy Assistant Secretary at the DOE under George W. Bush promoting energy development. His career history signals strong support for expanded fossil fuel extraction and removal of environmental restrictions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley', 'https://www.consumerenergyalliance.org']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$The Consumer Energy Alliance, where Whatley served as EVP for over a decade, opposes policies that prioritize emissions reduction at the cost of economic growth and advocates for expanded fossil fuel use. Whatley has not publicly endorsed climate action and his entire professional background is rooted in the fossil fuel advocacy space.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley', 'https://www.consumerenergyalliance.org']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$As RNC Chairman and NC GOP Chair, Whatley consistently promoted Trump's immigration restrictionist agenda including border wall funding, deportation, and an end to sanctuary cities. His RNC operation was built around election integrity and border security as defining Republican issues.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley', 'https://michaelwhatley.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$As RNC Chair under Trump, Whatley actively supported the administration's mass deportation agenda and promoted border enforcement as a central party priority. No statements distinguish between long-term residents and recent border crossers in his public record.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley', 'https://michaelwhatley.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Following the 2020 election, Whatley asserted there were 'voting irregularities' and 'election counting irregularities' and refused to blame Trump for January 6. As RNC co-chair and chair, he led the party's Election Integrity Committee and has been a central figure in efforts to restrict mail-in voting and push stricter ID requirements.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Whatley is a conservative Christian (holds theology degree) who aligned with the NC GOP platform opposing same-sex marriage. The NCGOP under his chairmanship maintained the party's traditional marriage position and opposed LGBTQ+ protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Whatley's campaign themes center on lower costs and market-based solutions. As a Trump-aligned Republican and former energy lobbyist, his record reflects alignment with the GOP position of repealing and replacing the ACA with private market alternatives rather than government-driven coverage expansion.$$,
        ARRAY['https://michaelwhatley.com', 'https://en.wikipedia.org/wiki/Michael_Whatley']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Whatley is a Trump loyalist who ran the RNC under Trump and developed the Trump Farm Plan supporting tariffs on unfair trading partners. His energy background favors protecting domestic production, consistent with using tariffs to counter unfair foreign trade practices.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley', 'https://michaelwhatley.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '24e9212c-b011-422a-865c-093e35050901',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Whatley is closely aligned with Trump's foreign policy positions, which have leaned toward reducing Ukraine aid and skepticism of continued military commitments. As RNC Chair under Trump he promoted the party's shift toward America-first skepticism of Ukraine support.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Whatley holds a master's degree in theology and is a conservative Christian whose political career is rooted in the NC GOP and Trump movement. He strongly supports broad religious liberty protections and religious organizations' autonomy, consistent with the Republican Study Committee and Heritage Foundation framework.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley', 'https://michaelwhatley.com']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$As RNC Chair and a Trump-aligned social conservative, Whatley promoted the party platform opposing transgender athlete participation in women's sports. No statements carve out any exceptions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Whatley served as RNC Chair and is closely aligned with Republican positions opposing campaign finance restrictions, including those on independent expenditures. His party role requires fundraising from large donors and PACs without disclosure restrictions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Whatley / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('867caca5-ab41-4e1b-b051-4a2cd95a335e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Whatley leads the Trump GOP operation which opposes affirmative action, diversity programs, and race-based government initiatives. He has censured Republican senators who crossed party lines and promotes the NCGOP and RNC platform opposing equity mandates and federal civil rights expansions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley']::text[]::text[])
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
-- WHERE p.id IN ('4fd59af4-eca7-4cdc-9082-178278ce3dc8', '0f8bb5ea-8d89-4cfb-9291-04b54c128b82', 'b6c3620e-1ac1-460c-acb4-74854d59b334', '79e1e32f-9b0d-4f8f-86f3-679185424596', 'a4f51d46-c361-4b17-bd63-7932a01ee2c3', 'ffb0dcac-385a-4df3-a441-cdbd0e713c1d', '1f7429f7-1ecd-4f44-abce-03c72d5cf664', '867caca5-ab41-4e1b-b051-4a2cd95a335e', '56603da5-e7ad-48a9-8c77-259513869ed4', 'b1114b75-8ca1-494e-9251-e8faa84ff408', 'ae7e8d67-e8a4-49a7-bb5c-715c99168374', '238222f5-e5e0-4331-8540-ee904bbacb8a', '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6', 'e2f59e14-a81d-45fe-86c0-c992a63d86cd', 'f8869b74-2a0c-40b7-93b4-40f32eec7108')
-- GROUP BY p.id, p.full_name ORDER BY topic_count;
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN ('4fd59af4-eca7-4cdc-9082-178278ce3dc8', '0f8bb5ea-8d89-4cfb-9291-04b54c128b82', 'b6c3620e-1ac1-460c-acb4-74854d59b334', '79e1e32f-9b0d-4f8f-86f3-679185424596', 'a4f51d46-c361-4b17-bd63-7932a01ee2c3', 'ffb0dcac-385a-4df3-a441-cdbd0e713c1d', '1f7429f7-1ecd-4f44-abce-03c72d5cf664', '867caca5-ab41-4e1b-b051-4a2cd95a335e', '56603da5-e7ad-48a9-8c77-259513869ed4', 'b1114b75-8ca1-494e-9251-e8faa84ff408', 'ae7e8d67-e8a4-49a7-bb5c-715c99168374', '238222f5-e5e0-4331-8540-ee904bbacb8a', '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6', 'e2f59e14-a81d-45fe-86c0-c992a63d86cd', 'f8869b74-2a0c-40b7-93b4-40f32eec7108')
--   AND pc.politician_id IS NULL;