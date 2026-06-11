-- ============================================================================
-- Migration 365: Elizabeth Warren Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Elizabeth Warren (US Senator, MA).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Warren context: 12-year Senate career (2013–present) + 2020 presidential run;
--   former Harvard Law professor; CFPB architect; rich documented record on
--   consumer protection, healthcare, taxes, banking regulation, climate,
--   immigration, social security, and constitutional reform.
--
-- Result: 30 existing stances re-upserted (idempotent) + 11 new topics added.
--   Total target: 41 stances.
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

-- Warren UUID: dd08c9de-076d-40ee-ab27-9298bbb72d1a (external_id=-200101)

BEGIN;

-- ============================================================
-- Elizabeth Warren (dd08c9de-076d-40ee-ab27-9298bbb72d1a)
-- US Senator, Massachusetts (2013–present)
-- ============================================================

-- ----- Elizabeth Warren / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Warren has been a staunch pro-choice advocate and co-sponsored federal legislation protecting abortion access. After Dobbs (2022) she called for unblocking federal resources for reproductive health services. She opposes Supreme Court nominees who oppose legal abortion and supports public abortion funding. Her 2024 statement included: 'We need access to abortion, to contraception, to IVF.'$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Warren has called for Big Tech accountability and algorithm transparency, co-sponsoring legislation requiring disclosure of algorithmic risks and investigating AI harms. She has urged the FTC to investigate AI companies and called for safety standards before AI deployment. Her pattern of regulating Big Tech (breakup legislation, consumer protection) combined with calls for AI company accountability places her at requiring safety testing and banning high-risk uses, though no evidence of full ban-level regulation.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Warren introduced the Anti-Corruption and Public Integrity Act establishing lifetime lobbying bans, stock ownership restrictions, and enhanced disclosure requirements. Her 2020 presidential campaign refused PAC money and donations over $200 from executives in banking, tech, fossil fuels, and pharmaceuticals. She supports public financing of campaigns via voter vouchers, stating 'the elephant in the room is how campaigns are financed.'$$,
        ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren', 'https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Warren has championed universal childcare for ages 0–5, proposing a federal program capping family contributions at 7% of income with free care for families under 200% of the poverty line. She proposed real federal investments to fight child poverty through childcare funding, stating this as a core 2020 platform plank funded by her wealth tax proposal.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Warren has stated 'every policy, not just those involving housing or higher education, should be examined in terms of current racial realities.' She supports reparations commissions for African Americans and Native Americans, the Equality Act, and aggressive enforcement against wage discrimination and housing discrimination. Her approach emphasizes strengthening civil rights enforcement and addressing systemic discrimination rather than mandating equity quotas in all institutions.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren', 'https://www.ontheissues.org/domestic/Elizabeth_Warren_Civil_Rights.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Warren co-sponsored the Green New Deal and has called climate 'the existential crisis for the world.' She supports 50% clean electricity by 2030 and ending nuclear energy by 2035, while banning all new offshore and public lands drilling. Her Climate Risk Disclosure Act requires corporate climate impact reporting and she believes investing in clean energy serves 'health, environmental security, national security, and economic security.'$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Warren has raised concerns about the enormous energy consumption of large-scale AI infrastructure and data centers, linking it to her broader climate and corporate accountability agenda. She has called for mandatory disclosure of environmental impacts from large technology operations and supported proposals to require data centers powered by clean energy. Her Climate Risk Disclosure Act framework extends to requiring corporations including tech companies to report energy use and emissions.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases/warren-leads-senators-in-calling-on-big-tech-to-disclose-energy-use-and-emissions', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Warren supports a pathway to citizenship for all undocumented immigrants and has called for abolishing ICE, stating 'we cannot be a nation that puts children in cages.' She protects DACA recipients and opposes Secure Communities enforcement. Her position is that deportation should be limited to serious criminal convictions while the undocumented population broadly receives legal status and a path to citizenship.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Warren has been a leading advocate for government-led economic development, supporting the American Jobs Plan, Build Back Better Act, and Green New Deal as vehicles for large-scale federal investment in clean energy, manufacturing, and workforce development. She supported the Inflation Reduction Act's $369 billion in clean energy investments as a model for industrial policy. She opposes relying on private markets alone and has argued that strategic federal investment is essential to revitalize American manufacturing and compete globally.$$,
        ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren', 'https://www.warren.senate.gov/newsroom/press-releases/warren-applauds-passage-of-inflation-reduction-act']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Warren advocates stopping all new offshore and public lands drilling, and opposes fossil fuel subsidies. She has called for ending nuclear energy by 2035 and co-sponsored the Green New Deal targeting 50% clean electricity by 2030. Her 'Blue New Deal' protects oceans from offshore drilling. This reflects stopping new fossil fuel permits without banning all existing extraction.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Warren has championed government-directed economic growth, proposing her 'Economic Patriotism' agenda requiring corporations receiving federal benefits to invest in US workers. Her 2020 platform included a $2 trillion 10-year plan for clean energy investment and domestic manufacturing revitalization. She supports active industrial policy using government purchasing power, research funding, and trade conditions to shape economic development rather than leaving outcomes to market forces alone.$$,
        ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren', 'https://www.warren.senate.gov/newsroom/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Warren co-sponsored Medicare for All in the Senate, stating 'for-profit insurance is not working for Americans' and that there is 'no God-given right to suck billions in healthcare profit.' She proposes that the wealthy pay more and the middle class pays less under her plan, and opposes Medicare vouchers or privatization entirely. She supports government drug manufacturing during price spikes.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Warren supports building 3.2 million affordable housing units to address homelessness root causes and backs the Housing First philosophy. She addresses housing discrimination through race-conscious law and views homelessness as a result of systemic housing failure. Her investment-focused approach and decriminalization tendencies align with investing in shelter capacity over criminalization.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Warren backed the American Rescue Plan's $5 billion Emergency Housing Voucher program and has consistently supported the Housing First model as the evidence-based response to homelessness. She co-sponsored the Ending Homelessness Act to fund emergency shelter and transitional housing, and has opposed sweeps and criminalization approaches in favor of treatment and supportive housing. Her position is that homelessness is a housing supply and affordability crisis requiring public investment, not law enforcement response.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases', 'https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Warren supports building 3.2 million affordable housing units through government partnerships, addressing racial redlining effects through race-conscious law, and preventing rental discrimination. Her estate tax increases would fund affordable housing, and she supports rental market reform. She advocates for government as an active partner in housing construction and affordability, not just regulatory reform.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Warren supports a pathway to citizenship for all undocumented immigrants, DACA protections, the DREAM Act, and legal representation for deported children. She has called for expanding legal immigration including visa overstays and providing lawyers for asylum seekers. She has called the border wall 'about hate and division' and supports restoring Central America aid to reduce migration pressure.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Warren has stated the criminal justice system requires 'complete restructuring' and called racist policing 'structural, not one bad apple.' She supports reducing mass incarceration and recidivism through diversion programs, with a focus on alternatives to incarceration for non-violent offenses. Her approach prioritizes diversion, bail reform, and treatment alternatives over building new capacity.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Warren has called the criminal justice system 'racist front to back' and supports structural reforms to ensure courts are accessible to all Americans, not just the wealthy. Her consumer financial protection work and support for legal aid programs reflect a philosophy that courts must be accessible, with some standards but not a maze for ordinary people.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Warren has co-sponsored the Pretrial Integrity and Safety Act and the No Money Bail Act, which would end cash bail for federal offenses and incentivize states to eliminate money bail. She has argued that cash bail criminalizes poverty and disproportionately harms low-income defendants who cannot afford release while awaiting trial. Her criminal justice reform platform consistently includes pre-trial detention reform as a structural inequity requiring legislative correction.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases', 'https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Warren advocates criminal justice reform focused on reducing recidivism, addressing systemic inequities, and prioritizing rehabilitation over punishment. She supports diversion programs and has written that the system requires complete restructuring. Her approach emphasizes giving people a fair chance to make things right through treatment and community accountability rather than purely punitive responses.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / judicial-government-deference -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        $$Warren sharply criticized the Supreme Court's 2024 Loper Bright decision overruling Chevron deference, calling it a 'breathtaking power grab' that 'strips away Congress's power to protect people.' She argued that expert federal agencies are better positioned than generalist judges to interpret complex technical regulations. Warren has long supported strong federal regulatory authority and has defended the CFPB's independence and rule-making power against court challenges seeking to limit agency discretion.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases/warren-statement-on-supreme-court-overturning-chevron-deference', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Warren has stated that judges should interpret the Constitution 'for all of us' and has been a vocal critic of conservative judicial philosophy that limits constitutional protections to historical practice. She supported expanding the Supreme Court to correct what she called an 'illegitimate' conservative supermajority. As a former Harvard Law professor, she has consistently backed justices like Sotomayor and Kagan who apply the Constitution's text and history to modern conditions rather than treating founding-era practices as a ceiling.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Warren has stated 'racist policing isn't one bad apple; it's structural,' supporting systemic accountability reforms. She backs independent investigation of misconduct and calls for ending stop-and-frisk practices targeted at communities of color. Her approach reflects settling valid claims quickly and pursuing real accountability rather than reflexively defending government employees.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Warren's criminal justice platform emphasizes diversion programs, rehabilitation, and reducing mass incarceration through alternatives to prosecution. She supports treatment-based alternatives for non-violent offenses and has called for complete criminal justice restructuring. This reflects a philosophy of using diversion when community safety is not at risk, reserving prosecution for cases requiring it.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Warren introduced the Anti-Corruption and Public Integrity Act with broad disclosure requirements and supports government accountability standards. She has been a consistent advocate for public transparency in government institutions and financial markets. Her default is openness — sealing records or closing proceedings requires a compelling reason.$$,
        ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren', 'https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Warren has championed local environmental protections including coastal resilience, her 'Blue New Deal' protecting MA ocean ecosystems from offshore drilling, and investment in EPA enforcement capacity. She has advocated for the Regional Greenhouse Gas Initiative and for protecting National Wildlife Refuges and public lands. Her climate agenda explicitly links federal investment to strengthening local environmental quality and resilience.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Warren has been a strong defender of sanctuary cities, opposing federal threats to withhold funding from jurisdictions that limit cooperation with immigration enforcement. She supports municipal decisions to protect undocumented residents from deportation absent criminal convictions and has called for restoring local police–community trust by ending Secure Communities-style cooperation mandates. Her position supports local governments having broad discretion to decline federal immigration enforcement partnerships.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases', 'https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Warren co-sponsored Medicare for All, explicitly opposing Medicare vouchers, privatization, or any 'risky changes.' She opposes Medicaid reduction and has called for expanding coverage broadly. Her 2020 platform included expanding Medicare to cover all Americans with no privatization of Medicare or Medicaid.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Warren has co-sponsored algorithm accountability legislation requiring platforms to disclose how their algorithms promote content, and has called for Big Tech companies to be held accountable for harms caused by their platforms. Her approach emphasizes mandatory transparency in algorithmic promotion of content rather than voluntary standards or content removal mandates.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Warren has called for restructuring policing to focus on community accountability and redirecting resources to mental health, addiction treatment, and social services that prevent crime. She supports mental health co-responders for crisis calls rather than armed police and has advocated for community-based violence intervention programs. Her position is that expanding social support systems is the most effective long-term public safety strategy, alongside targeted law enforcement for serious crimes.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://www.warren.senate.gov/newsroom/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Warren has co-sponsored the For the People Act and has called for a constitutional amendment protecting voting rights. She supports automatic voter registration for all citizens and abolishing the Electoral College. Her government reform platform supports independent redistricting commissions with no elected official involvement as part of her broader anti-corruption agenda.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Warren has said 'religious freedom means no religious registry' and stated she would not impose a religious test on immigrants. When asked about faith-based opposition to same-sex marriage, she replied 'Then just marry one woman. I'm cool with that,' rejecting religious exemptions from anti-discrimination law. She supports protecting religious freedom while ensuring it does not override anti-discrimination protections.$$,
        ARRAY['https://www.ontheissues.org/domestic/Elizabeth_Warren_Civil_Rights.htm', 'https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Warren co-sponsored the Homes Act and the American Housing and Economic Mobility Act, which include rent relief provisions and anti-gouging measures. She has supported national emergency rent assistance and called for preventing algorithmic rent-setting collusion by large corporate landlords. Warren has stated that housing is a human right and backed legislation that would allow localities to implement rent stabilization policies without state preemption.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases/warren-unveils-bold-new-plan-to-end-americas-housing-crisis', 'https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Warren's American Housing and Economic Mobility Act includes incentives for localities to eliminate exclusionary single-family zoning and allow multifamily construction. She has stated that restrictive zoning is a primary driver of the housing shortage and supports conditioning federal transportation and housing funds on local zoning reform. Her position is that localities must open up development to address the housing crisis, while preserving community input on neighborhood character.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases/warren-unveils-bold-new-plan-to-end-americas-housing-crisis', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Warren voted for the Respect for Marriage Act (2022) codifying same-sex marriage into federal law. When asked about faith-based opposition to same-sex marriage she replied: 'Then just marry one woman. I'm cool with that' — rejecting organizational exemptions. She opposes defining marriage as between one man and one woman and backed repeal of DOMA.$$,
        ARRAY['https://en.wikipedia.org/wiki/Elizabeth_Warren', 'https://www.ontheissues.org/domestic/Elizabeth_Warren_Civil_Rights.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Warren opposes charter schools and strongly supports public education, stating her Secretary of Education 'will be a public school teacher.' Though a 2003 book she co-authored raised voucher ideas, she has explicitly reversed this position. She backs fully funding public schools and opposes diverting taxpayer money to private institutions.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Warren has proposed adding $200/month to all Social Security recipients, creating a caretaking credits payment floor, and removing the income cap on payroll taxes. She has sponsored legislation keeping the CPI for benefits (rejecting chained CPI cuts) and earned a 100% rating from the Alliance for Retired Americans for her pro-Trust Fund stance. She opposes any privatization.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Warren stated she is 'not afraid of tariffs' and wants 'a trade policy that puts American workers first,' characterizing tariffs as 'one part of reworking our trade policy overall.' She opposed the Trans-Pacific Partnership for lacking transparency and favoring corporations over workers. Her position is selective use of tariffs to protect key industries and workers, not maximum tariffs on all imports nor elimination of all tariffs.$$,
        ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren', 'https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Warren has proposed a 2% annual wealth tax on assets over $50M and 3% over $1B, a 7% tax on corporate profits over $100M, increased estate taxes, and the Buffett Rule restoring higher top income tax rates. She has stated 'the wealthy have rigged the tax code' and called the 2017 Tax Cuts and Jobs Act 'immoral.' Her Ultra-Millionaire Tax and corporate minimum tax are among the most ambitious progressive tax proposals in Congress.$$,
        ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren', 'https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Warren has been a consistent advocate for transgender rights, stating the transgender community 'has been marginalized in every way possible' and co-sponsoring the Equality Act providing comprehensive LGBTQ anti-discrimination protections. She supports allowing transgender athletes to compete on teams matching their gender identity and has broadly opposed policies restricting transgender participation in public life.$$,
        ARRAY['https://www.ontheissues.org/domestic/Elizabeth_Warren_Civil_Rights.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Warren voted for the Infrastructure Investment and Jobs Act (2021), securing $1.2 trillion in federal transportation and infrastructure investment. She has advocated for prioritizing public transit, Amtrak expansion, and clean transit alternatives over highway expansion, calling for climate-aligned transportation investments. Her Green New Deal co-sponsorship includes transforming the transportation sector toward electrification and public transit as a climate solution.$$,
        ARRAY['https://www.warren.senate.gov/newsroom/press-releases', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Warren visited Kyiv in August 2023 with Senators Blumenthal and Graham, met President Zelenskyy, and stated 'We are a partner for Ukraine as they fight for democracy.' She said 'the Ukrainian people will lose this war if we fail to provide assistance' and in January 2025 criticized a defense nominee for allegedly withholding Ukraine aid. This reflects support for continuing current levels of military and economic aid.$$,
        ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren', 'https://www.warren.senate.gov/newsroom/press-releases']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elizabeth Warren / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dd08c9de-076d-40ee-ab27-9298bbb72d1a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Warren has called for a constitutional amendment protecting voting rights, automatic voter registration for all citizens, and paper ballot requirements. She co-sponsored statehood for Washington D.C. and the For the People Act. She criticizes voter suppression efforts and opposes strict photo ID requirements that disenfranchise voters, reflecting a platform of expanding early voting and mail-in voting access broadly.$$,
        ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm', 'https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 41 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'dd08c9de-076d-40ee-ab27-9298bbb72d1a';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'dd08c9de-076d-40ee-ab27-9298bbb72d1a'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'dd08c9de-076d-40ee-ab27-9298bbb72d1a'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
--
-- Topics omitted (no evidence found): city-sanitation, homelessness (already in 30)
-- Omitted: city-sanitation (no federal Warren record found)
