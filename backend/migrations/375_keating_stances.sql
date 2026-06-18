-- ============================================================================
-- Migration 375: Bill Keating Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Bill Keating (US House MA-09).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
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
-- Bill Keating (US House MA-09)
-- UUID: 0d97085c-eca6-4530-9fc7-512ca05487b9
-- ============================================================

-- ----- Bill Keating / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Keating is strongly pro-choice — rated 0% by Massachusetts Citizens for Life and 100% by NARAL Pro-Choice Massachusetts. He voted against the Protect Life Act and No Taxpayer Funding for Abortion Act and stated funding abortion prevents discrimination against lower-income women. His record supports legal abortion access through at least the second trimester with funding access.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Keating created a "My Voice Voucher" small-donor campaign finance system, requires full disclosure of independent expenditures, supported banning Congressional insider trading, and forced Massachusetts Senate President to accept term limits. His record strongly favors limiting corporate and dark money.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Keating endorsed marriage equality, sponsored Equal Rights Amendment ratification, backed Violence Against Women Act reauthorization, advocates enforcing anti-discrimination protections based on gender, sexual orientation, and race, and sponsored facial recognition technology oversight to combat racial bias.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Keating scored 96% lifetime and 100% in 2025 from the LCV, voted against Continental Shelf and Gulf of Mexico offshore drilling, and supports Cape Wind and offshore renewable energy. He backs EPA greenhouse gas regulation and renewable energy tax credits — reflecting gradual clean-energy transition rather than an emergency carbon ban.$$,
        ARRAY['https://www.lcv.org/congressional-scorecard/members-of-congress/?state=MA&chamber=House', 'https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Keating "opposes amnesty; enforce our laws; secure our borders" but voted to legalize DREAMers via military service and sponsored legislation blocking religion-based immigration bans. His mixed enforcement-with-pathways record aligns with prioritizing deportation of recent border crossers while allowing established long-term residents to seek legal status.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Keating voted NO on opening the Outer Continental Shelf to oil drilling and YES on banning Gulf of Mexico offshore drilling. His 96% lifetime LCV score and consistent environmental record place him closer to stopping new fossil fuel permits rather than maintaining current production levels.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm', 'https://www.lcv.org/congressional-scorecard/members-of-congress/?state=MA&chamber=House']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Keating opposes Medicare privatization and the Ryan Budget, supports ACA expansion including Prevention and Public Health funding, and has sponsored Alzheimer's care benefit expansions. His record reflects support for affordable coverage through public programs plus regulated private insurance.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Keating "opposes amnesty; enforce our laws; secure our borders" but supports visa programs enabling foreign workers to remain, voted to legalize DREAMers via military service, and sponsored a bill blocking religion-based immigration bans. His record balances enforcement with maintaining current legal immigration levels and pathways for certain groups.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Keating sponsored stricter police accountability rules and supported the January 6 investigation commission. His record on criminal justice emphasizes accountability for specific high-harm offenders (pill mills, predators) while backing structural reforms — reflecting a diversion and accountability approach over jail expansion.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Keating strongly opposes Medicare privatization and the Ryan Budget, supports ACA expansion, and defends Medicare and Medicaid against benefit cuts. His record aligns with expanding Medicare coverage and lowering thresholds, stopping short of full Medicare for All.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Keating is classified as a "Hard-Core Liberal" on OnTheIssues, supported the January 6 investigation commission, certified the 2020 election, and consistently backs democratic accountability measures, suggesting support for independent redistricting commissions with bipartisan representation.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Keating promised "nationwide anti-discrimination laws and marriage rights for gays and lesbians" and strongly backed ending Don't Ask Don't Tell. In March 2025 he verbally sparred with the House Foreign Affairs Committee chair over misgendering Rep. Sarah McBride, demonstrating strong commitment to requiring all states to recognize same-sex marriages with full federal protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Bill_Keating_(politician)', 'https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Keating clearly stated "Oppose private and religious school voucher programs" (Oct 2015), voted NO on DC opportunity scholarship program, and is rated 100% by the National Education Association. His position is to fully fund public schools and eliminate vouchers.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Keating stated in 2010 it is a "bad idea to privatize; or to raise retirement age," sponsored a bill keeping the standard CPI for benefits (rejecting chained CPI), and is rated 100% pro-Trust Fund by senior advocates. His record reflects opposing cuts while supporting modest benefit improvements.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Keating supports imposing tariffs against currency-manipulating countries and backed USMCA, while rated 38% by free-trade advocates. His record indicates a selective tariffs approach to protect American industries and respond to unfair traders rather than broad protectionism or pure free trade.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Keating advocates raising estate taxes to 1990s levels and notes that reducing tax rates "balloons deficits and cuts programs." His 100% AFL-CIO rating and progressive economic record reflect support for modestly increasing taxes on high earners.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$In March 2025, Keating verbally sparred with the House Foreign Affairs Committee chair over misgendering freshman Democratic representative Sarah McBride, demonstrating strong support for transgender rights and inclusion. His overall pro-LGBTQ+ record and defense of transgender colleagues supports transgender athletes competing on teams matching their gender identity after basic documentation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Bill_Keating_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Keating serves on the House Foreign Affairs Committee as Ranking Member of the Europe, Eurasia and Emerging Threats Subcommittee, making Ukraine policy a central part of his work. As a committed multilateralist focused on European security, his role and record suggest consistent support for current levels of Ukraine military and economic aid.$$,
        ARRAY['https://en.wikipedia.org/wiki/Bill_Keating_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bill Keating / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d97085c-eca6-4530-9fc7-512ca05487b9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Keating supports automatic voter registration, making Election Day a national holiday, requires full disclosure of independent campaign expenditures, and backed DC statehood. His record reflects expanding early voting and no-excuse mail-in ballot access.$$,
        ARRAY['https://www.ontheissues.org/ma/Bill_Keating.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 19 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '0d97085c-eca6-4530-9fc7-512ca05487b9';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '0d97085c-eca6-4530-9fc7-512ca05487b9'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '0d97085c-eca6-4530-9fc7-512ca05487b9'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
