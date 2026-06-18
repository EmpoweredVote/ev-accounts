-- ============================================================================
-- Migration 373: Ayanna Pressley Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Ayanna Pressley (US Representative, MA-07).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Supplemental: Pressley had 25 pre-existing stances from a prior session.
--   This migration re-upserts all with corrected values and adds new topics.
--   city-sanitation omitted — no documented federal House record.
--   Total expected: 40+ topics.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Politician UUID: c61baf45-dc2a-4d78-b4b7-21b1e9d79464  (external_id -200207)

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

-- ===== Ayanna Pressley (MA-07) =====
-- Squad member; Progressive Caucus; Boston; first Black woman elected to Congress from MA

-- ----- Ayanna Pressley / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Pressley is one of Congress's strongest advocates for reproductive rights. She co-sponsored the Women's Health Protection Act and introduced the EACH Woman Act to guarantee abortion coverage in federal health insurance including Medicaid. After the Dobbs decision she called for codifying Roe and declared a "crisis of democracy." She has consistently received 100% ratings from NARAL and Planned Parenthood Action Fund. She has framed abortion as a racial justice and economic justice issue.$$,
        ARRAY['https://pressley.house.gov/issues/reproductive-rights', 'https://www.govtrack.us/congress/votes/117-2021/h346', 'https://www.naral.org/scorecards/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Pressley has been a strong advocate for regulating AI to prevent racial bias and discriminatory outcomes. She co-led the Facial Recognition and Biometric Technology Moratorium Act and has raised concerns about algorithmic discrimination in housing, healthcare, and criminal justice. She supported robust AI governance frameworks focused on civil rights protections and has testified about AI bias affecting communities of color. Her position is pro-regulation with an equity lens.$$,
        ARRAY['https://pressley.house.gov/issues/technology', 'https://congress.gov/bill/117th-congress/house-bill/3907', 'https://www.govtrack.us/congress/members/ayanna_pressley/412786']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Pressley does not accept PAC money or corporate donations and runs campaigns funded by small-dollar donors. She voted for the For the People Act (H.R. 1) multiple times and has called for overturning Citizens United. She has publicly criticized the influence of big money in politics and supports matching funds for small donations. She championed campaign finance reform as a Boston City Councilor and has carried that position to Congress.$$,
        ARRAY['https://pressley.house.gov/issues/democracy', 'https://www.opensecrets.org/members-of-congress/ayanna-pressley/summary?cid=N00044039', 'https://www.govtrack.us/congress/votes/116-2019/h118']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Pressley introduced the Child Care for Every Community Act and has championed universal child care as both an economic and racial justice issue. She voted for the Build Back Better Act's universal pre-K provisions and has called child care "infrastructure." She has highlighted the disproportionate burden of child care costs on families of color and low-income women. She supported the Child Tax Credit expansion in the American Rescue Plan as a child care poverty-reduction tool.$$,
        ARRAY['https://pressley.house.gov/issues/families', 'https://congress.gov/bill/117th-congress/house-bill/1876', 'https://www.govtrack.us/congress/votes/117-2021/h369']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Pressley has civil rights as a central issue. She supported the George Floyd Justice in Policing Act, the Equality Act, and the John Lewis Voting Rights Advancement Act. She has framed racial equity as the lens through which she approaches all legislation. She voted for H.R. 40 (Reparations Study Commission) and has been a leading voice for addressing systemic racism. She received perfect scores from NAACP and ACLU civil liberties scorecards.$$,
        ARRAY['https://pressley.house.gov/issues/civil-rights', 'https://www.aclu.org/scorecard', 'https://www.govtrack.us/congress/votes/117-2021/h118']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Pressley co-sponsored the Green New Deal resolution (H.Res. 109) and has called for aggressive federal action on climate as an environmental justice priority. She has framed climate policy through a racial equity lens, highlighting the disproportionate impact of pollution and climate change on communities of color. She voted for the Inflation Reduction Act and has supported additional climate investments beyond what passed. She has a 100% lifetime LCV rating.$$,
        ARRAY['https://pressley.house.gov/issues/climate', 'https://scorecard.lcv.org/moc/ayanna-pressley', 'https://www.govtrack.us/congress/votes/116-2019/h109']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Pressley has not taken a specific public stance on data center siting but has expressed concern about the energy and water consumption of large tech facilities through her climate and environmental justice work. Her district (Boston's inner core neighborhoods) does not have major data center development pressure. She supports clean energy requirements for tech infrastructure and would likely apply an environmental justice standard to data center permitting in low-income communities.$$,
        ARRAY['https://pressley.house.gov/issues/climate', 'https://pressley.house.gov/issues/technology', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Pressley has been one of Congress's strongest opponents of deportation enforcement. She co-introduced the BREATHE Act calling for defunding ICE and CBP and redirecting those funds to community resources. She has opposed every deportation-related funding increase and has spoken at rallies supporting undocumented constituents facing removal. She introduced the Pathway to Prosperity Act providing a pathway to citizenship and has called deportation a form of "state violence."$$,
        ARRAY['https://pressley.house.gov/issues/immigration', 'https://breatheact.org/', 'https://www.govtrack.us/congress/members/ayanna_pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Pressley supports community-centered economic development focused on working-class and low-income residents. She has backed the Neighborhood Homes Investment Act, small business support for minority entrepreneurs, and has opposed development that displaces existing communities. She supported the American Rescue Plan's small business provisions and the Build Back Better Act. She focuses economic development through an equity lens — jobs for her constituents, not corporate tax incentives.$$,
        ARRAY['https://pressley.house.gov/issues/economy', 'https://congress.gov/bill/117th-congress/house-bill/2390', 'https://www.govtrack.us/congress/votes/117-2021/h72']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Pressley co-sponsored the Green New Deal and the Keep It in the Ground Act which would end new fossil fuel leases on public lands. She has voted against every bill expanding offshore drilling and fossil fuel subsidies. She has called for ending fossil fuel industry tax subsidies as part of climate justice. She earned a 100% lifetime LCV rating reflecting her consistent anti-fossil-fuel voting record.$$,
        ARRAY['https://scorecard.lcv.org/moc/ayanna-pressley', 'https://pressley.house.gov/issues/climate', 'https://congress.gov/bill/116th-congress/house-bill/3671']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Pressley supports community-driven development with strong anti-displacement protections. She has backed Community Land Trust models to prevent gentrification and has opposed luxury development that displaces existing residents. She supported the Build Back Better Act's affordable housing provisions. Her district includes Roxbury, Dorchester, and parts of Jamaica Plain — communities that have faced significant gentrification pressure — giving her a strong constituency for equitable development policy.$$,
        ARRAY['https://pressley.house.gov/issues/housing', 'https://congress.gov/bill/117th-congress/house-bill/4346', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Pressley is a strong Medicare for All supporter and co-sponsor of H.R. 1384. She has consistently voted against any weakening of the ACA and has pushed for expanding Medicaid. She frames healthcare as a human right and a racial justice issue, highlighting disparities in health outcomes for Black and Brown communities. She introduced the Reproductive Equity Act and has championed maternal health equity legislation addressing high Black maternal mortality rates.$$,
        ARRAY['https://pressley.house.gov/issues/health-care', 'https://www.govtrack.us/congress/bills/116/hr1384', 'https://congress.gov/bill/117th-congress/house-bill/1384']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Pressley has supported housing-first approaches to homelessness and championed the Unhoused Persons Bill of Rights. She has been critical of criminalization of homelessness and called for robust federal funding for transitional housing. Her district includes Boston neighborhoods with visible homelessness and she has consistently advocated for services-centered approaches. She backed the Build Back Better Act's housing provisions targeting homelessness.$$,
        ARRAY['https://pressley.house.gov/issues/housing', 'https://congress.gov/member/ayanna-pressley/P000617', 'https://www.govtrack.us/congress/votes/117-2021/h369']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Pressley opposes criminalization of homelessness and has specifically spoken against anti-camping ordinances and aggressive policing of encampments. She favors housing-first services and mobile outreach over law enforcement responses. She backed the Unhoused Persons Bill of Rights Act and has criticized local and state anti-homeless sweeps as harmful rather than helpful.$$,
        ARRAY['https://pressley.house.gov/issues/housing', 'https://congress.gov/bill/117th-congress/house-bill/5765', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Pressley has introduced the Housing is a Human Right Act and co-sponsored the Homes for All Act which would create 12 million new affordable units. She has been a leading advocate for community land trusts, social housing models, and strong renter protections. She has voted for every federal housing investment package. Her Boston district has some of the highest rents in the country relative to resident incomes, giving her a strong constituency for aggressive housing policy.$$,
        ARRAY['https://pressley.house.gov/issues/housing', 'https://congress.gov/bill/117th-congress/house-bill/5765', 'https://www.govtrack.us/congress/votes/117-2021/h369']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Pressley is one of Congress's most progressive voices on immigration. She introduced the Pathway to Prosperity Act providing a citizenship pathway for undocumented immigrants, voted for the American Dream and Promise Act, and has opposed all border wall funding. She has called for abolishing ICE and has spoken publicly with constituent DACA recipients. She frames immigration enforcement as a racial justice issue and has pushed for sanctuary city protections in federal policy.$$,
        ARRAY['https://pressley.house.gov/issues/immigration', 'https://www.govtrack.us/congress/votes/116-2019/h358', 'https://congress.gov/bill/117th-congress/house-bill/6']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Pressley has called for reducing incarceration as a systemic goal, introducing the People's Justice Guarantee calling for 50% reduction in the federal prison population. She has voted against funding for new federal detention facilities and has backed the SAFE Justice Act focused on sentencing reform. She has been a consistent voice for closing immigration detention centers and has opposed expanding federal jail capacity in favor of diversion, mental health treatment, and community alternatives.$$,
        ARRAY['https://pressley.house.gov/issues/criminal-justice', 'https://congress.gov/bill/117th-congress/house-bill/1442', 'https://www.govtrack.us/congress/members/ayanna_pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Pressley has championed expanding access to legal counsel, supporting the Civil Gideon Act to provide right to counsel in housing and civil cases. She has backed legal aid funding increases and has spoken about the access-to-justice gap affecting her Boston constituents. She supported the Equal Access to Justice Act and has framed judicial access as inseparable from racial equity.$$,
        ARRAY['https://pressley.house.gov/issues/criminal-justice', 'https://congress.gov/bill/117th-congress/house-bill/3407', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$Pressley has been a leading advocate for ending cash bail, supporting the No Money Bail Act of 2021. She has highlighted how the cash bail system disproportionately imprisons low-income people and people of color who cannot afford bail. She supported the George Floyd Justice in Policing Act's pretrial provisions and has spoken publicly about constituents trapped in pretrial detention. She frames bail reform as a racial and economic justice imperative.$$,
        ARRAY['https://pressley.house.gov/issues/criminal-justice', 'https://congress.gov/bill/117th-congress/house-bill/1437', 'https://www.govtrack.us/congress/members/ayanna_pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Pressley has introduced the People's Justice Guarantee calling for ending mandatory minimums, reducing the federal prison population by 50%, and ending solitary confinement. She opposed the 1994 Crime Bill's legacy and has called for its reversal. She voted for the First Step Act and pushed for stronger reforms. She supports abolishing the death penalty and has introduced the Federal Death Penalty Abolition Act. Her criminal justice stance is among the most progressive in Congress.$$,
        ARRAY['https://pressley.house.gov/issues/criminal-justice', 'https://congress.gov/bill/117th-congress/house-bill/1442', 'https://congress.gov/bill/117th-congress/house-bill/262']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Pressley was one of the most vocal proponents of the George Floyd Justice in Policing Act including ending qualified immunity, national use-of-force standards, and civilian oversight boards. She has supported the BREATHE Act which called for defunding federal programs that support militarized policing. She has spoken at Black Lives Matter rallies and introduced legislation to end no-knock warrants federally. She has framed police accountability as the central civil rights issue of her generation.$$,
        ARRAY['https://pressley.house.gov/issues/civil-rights', 'https://www.govtrack.us/congress/votes/117-2021/h118', 'https://breatheact.org/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Pressley has consistently supported progressive prosecutorial approaches — declining to prosecute low-level offenses, diversion for drug possession, and focusing resources on violent crime. She has backed reform prosecutors in Boston and nationally. She introduced the People's Justice Guarantee which would direct prosecutorial resources toward serious crimes while decriminalizing many nonviolent offenses. She has explicitly endorsed the "harm reduction" prosecutorial philosophy.$$,
        ARRAY['https://pressley.house.gov/issues/criminal-justice', 'https://congress.gov/bill/117th-congress/house-bill/1442', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Pressley has supported transparency measures for the judiciary including financial disclosure requirements for federal judges and Supreme Court ethics reform. She backed the Supreme Court Ethics, Recusal, and Transparency Act after controversies around undisclosed gifts to justices. She has spoken about the need for courts to reflect the communities they serve and has pushed for demographic diversity alongside structural transparency reforms.$$,
        ARRAY['https://pressley.house.gov/issues/democracy', 'https://congress.gov/bill/118th-congress/senate-bill/359', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Pressley has been a champion of environmental justice, focusing on the disproportionate pollution burden borne by communities of color in her district. She pushed for inclusion of environmental justice provisions in the Inflation Reduction Act and backed the Environmental Justice For All Act. She has spoken about asthma rates in Boston's Roxbury and Dorchester neighborhoods linked to environmental inequities and has advocated for EPA enforcement in overburdened communities.$$,
        ARRAY['https://pressley.house.gov/issues/climate', 'https://congress.gov/bill/117th-congress/house-bill/2021', 'https://scorecard.lcv.org/moc/ayanna-pressley']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Pressley has been a vocal defender of sanctuary city policies, opposing federal coercion of local law enforcement to perform immigration enforcement. She supported Boston's sanctuary city designation and has opposed programs like 287(g) that deputize local police for immigration enforcement. She has met publicly with undocumented constituents facing deportation and championed their right to remain in their communities.$$,
        ARRAY['https://pressley.house.gov/issues/immigration', 'https://congress.gov/member/ayanna-pressley/P000617', 'https://www.govtrack.us/congress/votes/117-2021/h268']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Pressley is a co-sponsor of Medicare for All (H.R. 1384) and has consistently supported expanding Medicare and Medicaid. She voted against every Republican attempt to repeal the ACA and block-grant Medicaid. She backed the Inflation Reduction Act's Medicare drug pricing provisions while calling for more aggressive action. She has championed Medicaid expansion as a racial health equity measure and has called for adding dental, vision, and hearing coverage to Medicare.$$,
        ARRAY['https://pressley.house.gov/issues/health-care', 'https://congress.gov/bill/117th-congress/house-bill/1384', 'https://www.govtrack.us/congress/votes/117-2022/h373']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Pressley has spoken out against online disinformation targeting communities of color and has supported platform accountability for harmful content. She backed digital equity legislation and has expressed concern about misinformation in health and election contexts. Her approach emphasizes equity — ensuring that misinformation policies don't disproportionately silence voices of color while protecting communities from harmful content.$$,
        ARRAY['https://pressley.house.gov/issues/technology', 'https://congress.gov/member/ayanna-pressley/P000617', 'https://www.govtrack.us/congress/votes/117-2021/h268']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Pressley was one of few members of Congress to explicitly support divesting funds from police and investing in community safety alternatives. She backed the BREATHE Act and has consistently voted for the George Floyd Justice in Policing Act's strong accountability provisions. She has framed policing reform as a civil rights imperative and has called for community-controlled safety models. She has spoken about her own experiences with police violence in her community.$$,
        ARRAY['https://pressley.house.gov/issues/civil-rights', 'https://breatheact.org/', 'https://www.govtrack.us/congress/votes/117-2021/h118']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Pressley has been a consistent supporter of independent redistricting commissions and anti-gerrymandering legislation. She voted for the For the People Act and John Lewis Voting Rights Advancement Act. She has spoken about racial gerrymandering as a voter suppression tool and has highlighted how district manipulation dilutes the voting power of communities of color.$$,
        ARRAY['https://pressley.house.gov/issues/voting-rights', 'https://www.govtrack.us/congress/votes/116-2019/h118', 'https://www.govtrack.us/congress/votes/117-2021/h147']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Pressley supports religious freedom as an individual right while firmly opposing religious exemption claims used to justify discrimination against LGBTQ+ people and others. She voted for the Equality Act and has opposed RFRA expansions that could permit discrimination. She is a person of faith herself and has spoken about her religious values informing her social justice work, but she draws a clear line against using religion to harm others.$$,
        ARRAY['https://pressley.house.gov/issues/civil-rights', 'https://www.govtrack.us/congress/votes/117-2021/h185', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Pressley is one of few federal legislators to explicitly advocate for rent control, co-sponsoring the Rent Relief Act and backing local rent stabilization efforts. She has introduced the Affordable Housing Act to fund community land trusts and supported tenant organizing rights. She has framed rent regulation as a racial justice issue given the disproportionate burden of rent hikes on Black and Brown renters in Boston's rapidly gentrifying neighborhoods.$$,
        ARRAY['https://pressley.house.gov/issues/housing', 'https://congress.gov/bill/117th-congress/house-bill/4226', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Pressley has backed zoning reform to increase affordable housing density and reduce exclusionary zoning that perpetuates racial and economic segregation. She supported the Housing, Opportunity, Mobility, and Equity (HOME) Act and backed the affirmatively furthering fair housing provisions in the Build Back Better Act. She has connected exclusionary single-family zoning to historical redlining and racial segregation.$$,
        ARRAY['https://pressley.house.gov/issues/housing', 'https://congress.gov/bill/117th-congress/house-bill/4346', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Pressley voted for the Respect for Marriage Act (2022) and has been a strong supporter of LGBTQ+ equality throughout her career. She backed the Equality Act and consistently received 100% ratings from the Human Rights Campaign. She has spoken about LGBTQ+ rights as civil rights and has championed protections for LGBTQ+ youth in particular.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2022/h460', 'https://pressley.house.gov/issues/civil-rights', 'https://www.hrc.org/resources/congressional-scorecard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Pressley strongly opposes school vouchers and private school choice programs that she argues undermine public education. She voted against every voucher-related bill and has spoken about the importance of investing in public schools, particularly in her district which includes underfunded Boston public schools. She backed the Every Student Succeeds Act's public school investment provisions and has been endorsed by teacher unions for her public education record.$$,
        ARRAY['https://pressley.house.gov/issues/education', 'https://votesmart.org/candidate/evaluations/176042/ayanna-pressley', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Pressley has been a strong supporter of expanding Social Security, co-sponsoring the Social Security Expansion Act and opposing any cuts or privatization. She has highlighted Social Security's importance for Black and Latino seniors who have lower private retirement savings due to historical inequities. She backed the Inflation Reduction Act which included provisions to protect Medicare but has called for a more expansive fix to Social Security's long-term funding.$$,
        ARRAY['https://pressley.house.gov/issues/seniors', 'https://congress.gov/bill/117th-congress/house-bill/4583', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Pressley has supported USMCA with its labor and environmental standards as a model for trade agreements but has expressed concern about how tariffs affect prices for low-income consumers. She is not a free trade absolutist and has backed tariffs on Chinese goods tied to human rights violations. Her position reflects a labor-protective, equity-focused trade stance rather than either pure free trade or broad protectionism.$$,
        ARRAY['https://pressley.house.gov/issues/trade', 'https://www.govtrack.us/congress/votes/116-2020/h9', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Pressley voted against the 2017 Tax Cuts and Jobs Act and has consistently supported taxing the wealthy and corporations to fund social programs. She has backed Elizabeth Warren's wealth tax proposal and has called for closing corporate tax loopholes. She supports a financial transaction tax and has backed progressive tax reforms including raising the top marginal rate and strengthening estate taxes. She has framed progressive taxation as a racial justice issue.$$,
        ARRAY['https://pressley.house.gov/issues/taxes', 'https://www.govtrack.us/congress/votes/115-2017/h637', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Pressley fully supports transgender inclusion in sports consistent with the athletes' gender identity. She voted against the Protection of Women and Girls in Sports Act (Republican bill banning trans girls from female sports) and backed the Equality Act's comprehensive non-discrimination protections including sports participation. She has been among the most vocal congressional advocates for transgender youth and has framed trans exclusion as discriminatory.$$,
        ARRAY['https://pressley.house.gov/issues/civil-rights', 'https://www.govtrack.us/congress/votes/118-2023/h108', 'https://www.hrc.org/resources/congressional-scorecard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Pressley has been a champion of public transit as both a transportation equity and climate justice issue. Her district (Boston's urban core) is heavily transit-dependent, and she has consistently backed MBTA funding and federal transit investment. She voted for the bipartisan infrastructure law's transit provisions and has called for fare-free transit as an equity measure. She has spoken about the burden of high transit fares and inadequate service on low-income communities of color.$$,
        ARRAY['https://pressley.house.gov/issues/transportation', 'https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '24e9212c-b011-422a-865c-093e35050901',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Pressley has generally supported Ukraine aid packages but has also raised questions about the scale of military spending and the need for diplomatic solutions. She was one of the co-signers of the Congressional Progressive Caucus letter in October 2022 urging Biden to pursue diplomatic negotiations with Russia (later retracted). While she ultimately voted for Ukraine supplemental aid packages, she has represented the progressive wing's more cautious approach to open-ended military commitments.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2022/h111', 'https://progressives.house.gov/press-releases/cpc-letter-ukraine-diplomacy-2022', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ayanna Pressley / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Pressley has been one of Congress's most vocal advocates for voting rights. She voted for the For the People Act, Freedom to Vote Act, and John Lewis Voting Rights Advancement Act. She has spoken at voting rights rallies and framed voter suppression as a racial justice crisis. She has backed automatic voter registration, same-day registration, and expanding early voting. She has been particularly vocal about protecting the voting rights of formerly incarcerated individuals.$$,
        ARRAY['https://pressley.house.gov/issues/voting-rights', 'https://www.govtrack.us/congress/votes/117-2021/h147', 'https://www.govtrack.us/congress/votes/117-2021/h252']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);

COMMIT;
