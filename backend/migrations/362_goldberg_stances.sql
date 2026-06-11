-- ============================================================================
-- Migration 362: Deborah B. Goldberg Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Deborah B. Goldberg (Treasurer of Massachusetts).
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
-- Deborah B. Goldberg: eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5 (external_id = -200005)

BEGIN;

-- ============================================================
-- Deborah B. Goldberg
-- Treasurer and Receiver-General of Massachusetts
-- MA Treasurer since January 2015 (re-elected 2018, 2022)
-- Previously Brookline Board of Selectmen (1998-2004)
-- ============================================================

-- ----- Deborah B. Goldberg / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Goldberg has been a consistent advocate for reproductive rights throughout her political career. She received endorsement from EMILY's List in her 2014 treasurer campaign, which specifically backs pro-choice women candidates. As Treasurer, she has supported the Healey administration's policies protecting abortion access in Massachusetts after the Dobbs decision. Goldberg has framed abortion access as both a healthcare right and an economic issue — reproductive autonomy being essential for women's financial security.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://emilyslist.org/news/entry/emilys-list-endorses-deb-goldberg-for-massachusetts-treasurer/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Goldberg has been involved with the Jewish Alliance for Law and Social Action (JALSA), which focuses on civil rights, economic justice, and social equity. As Treasurer, she has supported policies ensuring state financial contracts and pension investments comply with non-discrimination standards. She was the first Jewish woman elected to statewide office in Massachusetts and has been a consistent Democratic Party supporter of civil rights protections. The Treasurer's office under Goldberg has prioritized ESG (Environmental, Social, Governance) factors in state investment decisions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.mass.gov/orgs/office-of-state-treasurer-and-receiver-general-deborah-b-goldberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Goldberg has directed the Massachusetts state pension fund (PRIT) to incorporate climate risk analysis into investment decisions and has supported divesting from certain fossil fuel holdings. As a member of the State Board of Investment, she has championed sustainable investing principles. Goldberg supported the Healey administration's climate agenda and worked to align state financial tools with Massachusetts's net-zero emissions goals. She has spoken about climate risk as a material financial risk that fiduciaries must consider.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.mass.gov/orgs/office-of-state-treasurer-and-receiver-general-deborah-b-goldberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Goldberg comes from a family business background (Stop & Shop founders) and has emphasized balanced economic development throughout her career. As Treasurer she oversees the MA state lottery (which funds local aid), the pension fund (PRIT), and financial tools for economic development. She has supported small business programs, workforce development, and community development financial institutions (CDFIs) as instruments for equitable economic growth. Goldberg advocates for economic development that builds shared prosperity rather than concentrating wealth.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.southcoasttoday.com/news/20181031/goldberg-touts-old-fashioned-business-ethic-in-treasurers-race']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Goldberg has supported healthcare access as a core Massachusetts value. As Treasurer, she manages the Group Insurance Commission (GIC) that provides health insurance to state employees and retirees — ensuring high-quality, affordable coverage. She has supported the ACA and Massachusetts's near-universal coverage model. Goldberg has also been involved with the Greater Boston Food Bank, reflecting her commitment to social determinants of health including food security for Massachusetts residents.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.mass.gov/orgs/office-of-state-treasurer-and-receiver-general-deborah-b-goldberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Goldberg has supported affordable housing through the Treasurer's financial tools, including MassHousing and the Community Development Finance Agency (CDFA). As Treasurer she has championed first-time homebuyer programs and down payment assistance as pathways to homeownership and wealth building. She supported the Healey administration's Affordable Homes Act. Goldberg's Brookline selectman background included navigating local housing debates. The Treasurer's office administers various housing finance programs critical to Massachusetts's affordable housing stock.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.mass.gov/orgs/office-of-state-treasurer-and-receiver-general-deborah-b-goldberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Goldberg's family history — immigrants who built the Stop & Shop grocery chain — informs her support for immigrant communities. She has supported state financial programs that help immigrant entrepreneurs and workers. As Treasurer, she has backed the Healey administration's welcoming immigration policies and opposed federal efforts to target Massachusetts's immigrant communities. Goldberg has also supported financial inclusion programs helping unbanked and underbanked populations, including many immigrants.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.mass.gov/orgs/office-of-state-treasurer-and-receiver-general-deborah-b-goldberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Goldberg has been a strong defender of Medicare and Social Security programs, particularly given her focus on financial security for Massachusetts retirees. As Treasurer, she oversees the state pension system (PRIT) affecting hundreds of thousands of public employees and retirees, and has been sensitive to the intersection of public pensions with federal retirement programs. She has opposed federal proposals to cut Medicare or privatize Social Security as threats to the retirement security of Massachusetts workers and seniors.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.mass.gov/orgs/office-of-state-treasurer-and-receiver-general-deborah-b-goldberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Goldberg has supported same-sex marriage and LGBTQ+ rights throughout her career as a Massachusetts Democrat. As Treasurer she has ensured equal treatment for same-sex couples in all state financial programs and benefits administered by her office. She participated in the Massachusetts Democratic Party community which has been strongly pro-equality since the state's 2003-2004 same-sex marriage legalization. Goldberg's EMILY's List endorsement reflects alignment with full LGBTQ+ equality.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://emilyslist.org/news/entry/emilys-list-endorses-deb-goldberg-for-massachusetts-treasurer/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Social Security protection is central to Goldberg's policy focus as Treasurer. She manages PRIT (the public employee pension fund) and understands retirement security deeply. She has consistently opposed any privatization or significant cuts to Social Security, arguing these would devastate retirees who depend on both Social Security and state pensions. Goldberg has advocated for expanding Social Security benefits and protecting COLA adjustments as essential for retirement security for Massachusetts workers and seniors.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.mass.gov/orgs/office-of-state-treasurer-and-receiver-general-deborah-b-goldberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Goldberg's business background (Stop & Shop grocery chain origins) gives her firsthand understanding of trade and supply chain economics. As Treasurer overseeing state fiscal health, she has expressed concern about the economic impact of broad tariffs on Massachusetts businesses, consumers, and state tax revenues. The grocery retail sector that defined her family's history is directly affected by food import tariffs. She has supported the Healey administration's opposition to sweeping federal tariff policies damaging to the Massachusetts economy.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.southcoasttoday.com/news/20181031/goldberg-touts-old-fashioned-business-ethic-in-treasurers-race']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Goldberg campaigned on building the state's rainy day fund and sound fiscal management — a balanced approach that prioritizes long-term fiscal health over short-term tax cuts. She pledged to grow the rainy day fund as Treasurer in 2015. As a Massachusetts Democrat she has supported the Fair Share Amendment (millionaires surtax) passed by voters in 2022, which raised taxes on incomes above $1M to fund education and transportation. Goldberg's approach is fiscally responsible with progressive elements — targeted relief for working families while maintaining investment capacity.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.masslive.com/politics/index.ssf/2015/01/state_treasurer_deborah_goldbe.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah B. Goldberg / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Goldberg has supported expanded voting access as a Massachusetts Democrat. While the Treasurer's office does not have direct jurisdiction over elections (that falls to the SoS), Goldberg has publicly supported vote-by-mail, early voting, and automatic voter registration as policies that strengthen democracy. She has backed Democratic Party positions on voting rights and opposed voter ID measures that disenfranchise voters, particularly targeting communities of color and low-income voters who are disproportionately affected.$$,
        ARRAY['https://en.wikipedia.org/wiki/Deb_Goldberg', 'https://www.mass.gov/orgs/office-of-state-treasurer-and-receiver-general-deborah-b-goldberg']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
