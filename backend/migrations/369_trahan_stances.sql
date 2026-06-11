-- ============================================================================
-- Migration 369: Lori Trahan Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Lori Trahan (US Representative, MA-03).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Supplemental: Trahan had 25 pre-existing stances from a prior session.
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
-- Lori Trahan: b96758c6-2ea0-4698-8886-d574d34e366d

BEGIN;

-- ============================================================
-- Lori Trahan (MA-03)
-- ============================================================

-- ----- Lori Trahan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Trahan's 2018 platform called for "guaranteeing access to abortion" which she called a constitutional right. She voted YES on the Women's Health Protection Act (2021, 2022) and has a 100% NARAL Pro-Choice America rating. She has co-sponsored multiple bills to protect and expand abortion access at the federal level.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Trahan has introduced the Student Test Privacy Protection Act and championed children's digital privacy, requiring COPPA reforms. She has worked on AI/tech accountability from a consumer protection and children's safety angle — supporting guardrails on AI in educational settings and algorithmic transparency without blocking innovation entirely. Her focus has been practical harm-reduction standards rather than comprehensive AI licensing.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Trahan supports "an ambitious campaign finance reform plan" and co-sponsored the For the People Act, which establishes public small-dollar matching for federal candidates and expands disclosure requirements for dark money. She has consistently backed measures to limit the influence of large corporations and PACs in elections.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://www.ontheissues.org/House/Lori_Trahan.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Trahan's 2018 comprehensive women's policy plan included "affordable childcare" as a core commitment. She backed Build Back Better's universal pre-K and childcare provisions, the Child Tax Credit expansion (American Rescue Plan), and has introduced legislation addressing childcare workforce shortages. Childcare affordability is among her top constituent issues in MA-03.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Trahan co-sponsored the George Floyd Justice in Policing Act, the ERA ratification bill (H.J.Res.17), and the Equality Act. She is a member of the Congressional Asian Pacific American Caucus and the Congressional Caucus for Women's Issues. Her record reflects consistent support for anti-discrimination enforcement and expanding protected class coverage.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Trahan was an original co-sponsor of the Green New Deal (Feb 2019), which calls for a rapid 10-year transformation to net-zero greenhouse gas emissions. She has a 100% LCV rating and voted YES on the Inflation Reduction Act. Her climate record consistently places her in the most aggressive decarbonization camp in the House.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Trahan's Green New Deal co-sponsorship and 100% LCV record imply concern about data center energy consumption as part of overall decarbonization. She has worked on tech regulation from a consumer protection angle (COPPA, AI transparency) and would likely support energy transparency requirements for large commercial tech infrastructure. Her record suggests mandatory environmental standards for data center development.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Trahan opposes deporting undocumented immigrants back to their home country before allowing citizenship applications. She backed DACA, the American Dream and Promise Act, and has opposed mass deportation policies. Her immigration record consistently supports legal pathways for long-term residents over enforcement-first approaches.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://www.ontheissues.org/House/Lori_Trahan.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Trahan represents a district spanning Lowell, Lawrence, and Dracut — post-industrial cities with significant reinvestment needs. She secured CHIPS Act manufacturing funds for MA-03 semiconductor research, backed the Infrastructure Investment and Jobs Act for Merrimack Valley broadband and water infrastructure, and has championed clean energy job creation and workforce development as economic development priorities.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$As an original Green New Deal co-sponsor (Feb 2019), Trahan backed a framework calling for stopping fossil fuel dependency within 10 years. She has supported ending fossil fuel subsidies and opposed new offshore drilling. Her 100% LCV rating reflects no votes supporting fossil fuel expansion.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Trahan backed the MBTA Communities Act and transit-oriented development along Lowell Line rail corridors. Her infrastructure investment focus — securing Merrimack Valley water and broadband funds — combines environmental standards with economic growth. She supports mixed-use, transit-connected development over sprawl, consistent with her Green New Deal and climate record.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Trahan frames healthcare as "a right, not a privilege" and advocates defending and expanding the ACA while working toward universal coverage. She backed the American Rescue Plan's ACA premium subsidy expansions and drug price negotiation provisions. Unlike McGovern, she has not explicitly co-sponsored Medicare for All but supports public option expansion as an intermediate step.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Trahan has backed housing-first approaches to homelessness, supporting emergency rental assistance and HUD voucher expansion in the American Rescue Plan. Her MA-03 district includes Lowell and Lawrence, cities with significant homeless populations, and she has supported services-led approaches over criminalization. She backed the Veterans Affairs Housing Voucher expansion for veteran homelessness.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Trahan supported the Emergency Rental Assistance provisions in the American Rescue Plan and CARES Act. Her record on criminal justice reform — supporting rehabilitation over incarceration — extends to homelessness response: she supports mental health crisis response teams as alternatives to police dispatch for individuals experiencing homelessness, consistent with her public safety reform positions.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Trahan voted YES on the $1.9 trillion American Rescue Plan (Mar 2021), which included emergency rental assistance and housing voucher provisions. She has backed the Housing Is Infrastructure Act, LIHTC expansions, and Section 8 reforms. Her MA-03 district includes Lowell and Lawrence where housing affordability is a significant concern.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://www.ontheissues.org/House/Lori_Trahan.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Trahan supports "creating pathways to citizenship" for all undocumented immigrants, backed DREAMers, and has co-sponsored the American Dream and Promise Act. Her MA-03 district (Lowell, Lawrence) has a large immigrant community including Cambodian, Southeast Asian, and Latinx residents, making immigration reform central to her constituent service.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Trahan prioritizes "rehabilitation and treatment over incarceration for low-level and nonviolent drug offenders." She backed the First Step Act and supported reducing mandatory minimums for drug crimes. Her Armed Services Committee work on military justice reform extended to civilian criminal justice standards against prison expansion.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Trahan voted YES on the Equity and Inclusion Enforcement Act (H.R. 2574), which restores and expands private rights of action for Title VI disparate impact discrimination. She supports legal aid funding and has backed LSC appropriations. Her ERA co-sponsorship and civil rights record reflect consistent support for court access for discrimination victims.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://www.ontheissues.org/House/Lori_Trahan.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Trahan's criminal justice record — supporting rehabilitation over incarceration and backing sentencing reform — aligns with bail reform replacing cash bail with risk-based pretrial assessment. She backed the Pretrial Integrity and Safety Act co-sponsored by progressive House Democrats. Her focus on nonviolent offense treatment and reentry reflects comprehensive system reform including bail.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Trahan co-sponsored federal death penalty abolition (H.R. 4052), emphasizing that capital punishment is "irreversible, arbitrary, and racially discriminatory." She backed sentencing reform and the First Step Act. Her record reflects a rehabilitation-centered criminal justice philosophy, opposing harsh mandatory minimums and capital punishment.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / judicial-government-deference -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'e5e48f0e-8f3a-40e1-8080-889fea389603',
        $$Trahan's Green New Deal co-sponsorship and ACA defense reflect strong support for EPA, HHS, and DOL rulemaking authority. She has opposed judicial curtailment of agency enforcement power and backed the Protecting Our Democracy Act's administrative safeguards. Her record supports strong deference to regulatory expertise in environmental, healthcare, and labor contexts.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / judicial-interpretation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
        $$Trahan co-sponsored the ERA (Equal Rights Amendment) and the Protecting Our Democracy Act, both of which require an evolving constitutional interpretation that applies rights to new contexts. Her voting record on SCOTUS nominees consistently favored candidates with broad rights frameworks over textualist or originalist approaches. She backed SCOTUS ethics reform legislation.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Trahan co-sponsored the George Floyd Justice in Policing Act (H.R. 1280), which lowered the criminal intent standard for federal civil rights prosecutions, restricted qualified immunity, and required body cameras for federal officers. She supports civilian oversight and stronger accountability for police misconduct.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Trahan supports rehabilitation and treatment over incarceration for nonviolent drug offenses, co-sponsored federal death penalty abolition, and backed reducing prosecutorial use of mandatory minimums. Her record reflects diverting prosecutorial resources away from low-level drug offenses toward violent crime prevention.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Trahan co-sponsored the Protecting Our Democracy Act, which includes enhanced transparency requirements for executive and judicial officials. She backed SCOTUS ethics disclosure legislation following reporting on Clarence Thomas's undisclosed gifts. Her record supports mandatory financial disclosure for federal judges and stronger recusal enforcement.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Trahan's 100% LCV rating and Green New Deal co-sponsorship reflect strong local environmental protection advocacy. She secured EPA Brownfields funding for Lowell and Lawrence, which have legacy industrial contamination, and has championed environmental justice ensuring MA-03's lower-income immigrant communities are protected from disproportionate pollution exposure. She backed the IRA's environmental justice provisions.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Trahan represents Lowell and Lawrence — cities with large Cambodian, Latinx, and Southeast Asian immigrant communities. She has consistently backed local non-cooperation with ICE detainer requests, defended Massachusetts' Safe Communities Act, and supported withholding federal sanctuary funds from enforcement-focused immigration programs. Her immigration record is driven by her district's significant immigrant population.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Trahan is endorsed by the National Committee to Preserve Social Security and Medicare for her advocacy against cuts. She opposes Medicare privatization and backed drug price negotiation provisions in the IRA. However, unlike her progressive colleagues, she has not co-sponsored Medicare for All and favors expanding the ACA with a public option rather than replacing private insurance entirely.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Trahan has focused tech regulation primarily on children's privacy (Student Test Privacy Protection Act, COPPA reforms) and algorithmic transparency. She has not been a leading voice specifically on misinformation legislation. Her tech accountability work suggests support for platform transparency and voluntary standards with possible liability reforms rather than government-mandated content removal.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Trahan backed the George Floyd Justice in Policing Act, mental health crisis response funding, and community violence intervention programs. She has supported expanded mental health and substance abuse treatment as public safety investments. Her MA-03 district's opioid crisis context informs her support for treatment-first public safety approaches over enforcement-first.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Trahan co-sponsored the For the People Act, which establishes independent redistricting commissions to prevent partisan gerrymandering. She backed the John Lewis Voting Rights Advancement Act requiring federal oversight for states with discriminatory election histories. Her redistricting record reflects strong support for citizen-led, non-partisan map-drawing processes.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Trahan co-sponsored the Equality Act providing LGBTQ+ non-discrimination protections and has explicitly stated religious freedom claims do not justify discrimination. She supports the principle that civil rights law applies equally regardless of the religious views of businesses or service providers.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Trahan backed the Tenant Protection Act of 2019 (H.R. 3814), which allows states and municipalities to enact rent control and stabilization measures. She supported emergency rental assistance in both the CARES Act and American Rescue Plan. Her housing record in high-rent MA-03 communities (Lowell, Dracut) consistently supports tenant-side protections.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Trahan backed Build Back Better's housing provisions linking federal grants to local zoning reform allowing multi-family and affordable development near transit. Her MA-03 district is served by the Lowell Line commuter rail, and she has supported transit-oriented development around Lowell station. She uses federal incentives to encourage upzoning for affordability without directly mandating local zoning changes.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Trahan is a member of the Congressional Equality Caucus and voted in 2019 to protect transgender military service. She voted YES on the Respect for Marriage Act (2022) and has consistently backed full federal marriage equality with no religious exemptions from recognition requirements.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Trahan "opposes school choice vouchers" per documented political positions, and supports "high quality public education for all." She has consistently voted against voucher proposals and backed fully funding public schools including Lowell and Lawrence schools in her district. She supports the public education system as the primary vehicle for equal educational access.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Trahan advocates keeping Social Security "safe for seniors" and proposes raising the payroll cap and adjusting benefits for women, caregivers, and low-wage workers. She is endorsed by the National Committee to Preserve Social Security and Medicare. She opposes privatization and benefit cuts.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Trahan voted YES on USMCA (Dec 2019) reflecting support for selective trade agreements with enforceable labor and environmental standards. She supports targeted tariffs against unfair trade practices that disadvantage American workers, but has not broadly endorsed protectionism. Her manufacturing district base (Lowell textile legacy) informs a balanced tariff approach.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Trahan states "wealthy families shouldn't pay a lower tax rate than hardworking middle-class families." She backed the American Rescue Plan tax provisions and the IRA's corporate minimum tax. She has consistently opposed tax cuts for the wealthy and supported progressive tax reforms including taxing capital gains at ordinary income rates.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://www.ontheissues.org/House/Lori_Trahan.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Trahan is a member of the Congressional Equality Caucus and voted NO on the Protection of Women and Girls in Sports Act (2023), which would have banned transgender women from female sports. She co-sponsored the Equality Act prohibiting discrimination based on gender identity. Her record supports inclusive policies for transgender athletes under appropriate participation guidelines.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Trahan supported the Infrastructure Investment and Jobs Act and secured Merrimack Valley transportation investments — Lowell Line commuter rail improvements, Rte. 3 safety improvements, and LRTA bus service expansion. Her Green New Deal co-sponsorship reflects commitment to decarbonizing transportation through public transit expansion and electrification over highway-only investment.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://en.wikipedia.org/wiki/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Trahan is a member of the Congressional Ukraine Caucus. Per Wikipedia, she voted against a cluster munitions ban amendment in 2023, unlike Neal and a minority of Democrats. Her record otherwise reflects general support for Ukraine defense aid and opposition to Russian aggression. She supports continued military and humanitarian assistance to Ukraine.$$,
        ARRAY['https://en.wikipedia.org/wiki/Lori_Trahan', 'https://trahan.house.gov/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lori Trahan / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b96758c6-2ea0-4698-8886-d574d34e366d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Trahan co-sponsored the For the People Act, which establishes Election Day as a federal holiday, enables automatic and same-day voter registration, and expands access to mail-in voting. She backed the John Lewis Voting Rights Advancement Act to restore pre-clearance requirements. Her record consistently supports maximum ballot access for all eligible voters.$$,
        ARRAY['https://trahan.house.gov/issues', 'https://ballotpedia.org/Lori_Trahan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'b96758c6-2ea0-4698-8886-d574d34e366d';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'b96758c6-2ea0-4698-8886-d574d34e366d'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'b96758c6-2ea0-4698-8886-d574d34e366d'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
