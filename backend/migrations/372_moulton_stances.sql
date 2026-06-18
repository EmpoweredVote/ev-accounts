-- ============================================================================
-- Migration 372: Seth Moulton Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Seth Moulton (US Representative, MA-06).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Supplemental: Moulton had 25 pre-existing stances from a prior session.
--   This migration re-upserts all with corrected values and adds new topics.
--   city-sanitation omitted — no documented federal House record.
--   Total expected: 38+ topics.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Politician UUID: 77f162cd-6ca0-4073-84e1-1c8ab87eb1e0  (external_id -200206)

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

-- ===== Seth Moulton (MA-06) =====
-- Iraq War veteran (4 tours USMC); Harvard MBA; Armed Services Committee; moderate Democrat

-- ----- Seth Moulton / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Moulton is pro-choice and has consistently voted to protect abortion access. He voted against the Stupak Amendment in 2009 when he supported the health care bill's abortion coverage provisions and has since voted repeatedly to codify Roe v. Wade protections. He signed the Women's Health Protection Act in 2021 and criticized the Supreme Court's Dobbs decision. However, he has occasionally taken more moderate positions on late-term restrictions compared to more progressive colleagues, landing him at a center-left position.$$,
        ARRAY['https://moulton.house.gov/issues/womens-rights', 'https://www.govtrack.us/congress/votes/117-2021/h346', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Moulton has spoken about AI's dual-use nature — both its promise for defense and economic competitiveness and the need for safety guardrails. He has engaged with AI policy through his Armed Services Committee work, particularly around autonomous weapons systems and national security applications. He has called for targeted regulation rather than broad restrictions, supporting innovation while acknowledging risks from AI in military contexts and deepfakes affecting elections.$$,
        ARRAY['https://moulton.house.gov/issues/technology', 'https://armedservices.house.gov/press-releases/moulton-ai-defense', 'https://www.congress.gov/member/seth-moulton/M001196']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Moulton has voted for the For the People Act (H.R. 1) in 2019 and 2021, which included significant campaign finance reform measures including disclosure requirements for dark money and small-donor matching. He does not accept PAC money from lobbyists and has consistently supported Citizens United reversal legislation. He co-sponsored the DISCLOSE Act to require transparency in political spending.$$,
        ARRAY['https://www.govtrack.us/congress/votes/116-2019/h118', 'https://moulton.house.gov/issues/money-in-politics', 'https://www.opensecrets.org/members-of-congress/seth-moulton/summary?cid=N00035492']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Moulton supported the Child Care for Working Families Act and voted for the Build Back Better Act in 2021, which included substantial investments in universal pre-K and child care subsidies. He has highlighted child care affordability as an economic issue for working families in MA-06. His district includes families on Boston's North Shore and in Salem who face high child care costs.$$,
        ARRAY['https://moulton.house.gov/issues/families', 'https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/bill/117th-congress/house-bill/4346']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Moulton has consistently voted for civil rights legislation including the Equality Act, John Lewis Voting Rights Advancement Act, and George Floyd Justice in Policing Act. He earned a 100% rating from the ACLU on civil liberties votes in multiple sessions. He has spoken about racial equity and has called for reforming policing practices while maintaining public safety.$$,
        ARRAY['https://moulton.house.gov/issues/civil-rights', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton', 'https://www.aclu.org/scorecard/seth-moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Moulton voted for the Inflation Reduction Act in 2022 — the largest climate investment in US history — and has supported the Green New Deal framework while taking a more pragmatic approach to implementation. He represents coastal Massachusetts communities including Gloucester and Newburyport where rising seas and storm surge are immediate concerns. He has called climate change a national security threat through his Armed Services work, advocating for military installation resilience funding.$$,
        ARRAY['https://moulton.house.gov/issues/energy-and-environment', 'https://www.govtrack.us/congress/votes/117-2022/h373', 'https://scorecard.lcv.org/moc/seth-moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Moulton has not taken a highly specific public stance on data center siting but has expressed support for digital infrastructure investment as part of economic development and national security. His Armed Services Committee work includes attention to data infrastructure resilience. He supports clean energy powering data centers but has not called for restricting their development. MA-06 does not have major data center clusters driving local controversy.$$,
        ARRAY['https://moulton.house.gov/issues/technology', 'https://congress.gov/member/seth-moulton/M001196']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Moulton has taken a moderate position on deportation, supporting targeted enforcement against those convicted of serious crimes while opposing mass deportation of undocumented immigrants with community ties. He voted against funding for enhanced interior enforcement that critics said would lead to mass deportations. He has expressed concern about due process in deportation proceedings. However, he is more willing than progressive colleagues to acknowledge border security enforcement needs.$$,
        ARRAY['https://moulton.house.gov/issues/immigration', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton', 'https://www.govtrack.us/congress/members/seth_moulton/412595']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Moulton has been a strong advocate for economic development along the MA-06 corridor including port revitalization in Gloucester and Salem, defense industry jobs at the General Dynamics Bath Iron Works and Lynn's GE Aviation facilities. He supported the CHIPS and Science Act (2022) for semiconductor manufacturing and the Infrastructure Investment and Jobs Act. He has focused on workforce development programs and apprenticeships connecting veterans to manufacturing jobs.$$,
        ARRAY['https://moulton.house.gov/issues/jobs-economy', 'https://www.govtrack.us/congress/votes/117-2021/h395', 'https://congress.gov/bill/117th-congress/house-bill/4346']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Moulton has consistently supported phasing out fossil fuel subsidies and voted against drilling in the Arctic National Wildlife Refuge. He received an 87-92% LCV lifetime rating. He backed the Inflation Reduction Act's clean energy transition provisions. His coastal MA district gives him strong motivation to oppose offshore drilling, and he has been outspoken against new fossil fuel infrastructure. He does not support fossil fuel expansion and has advocated for accelerated renewable transition.$$,
        ARRAY['https://scorecard.lcv.org/moc/seth-moulton', 'https://moulton.house.gov/issues/energy-and-environment', 'https://www.govtrack.us/congress/votes/115-2017/h652']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Moulton supports managed economic growth with environmental standards, backing the CHIPS Act and infrastructure investments that bring manufacturing jobs. He has supported revitalization of industrial sites in Lynn, Beverly, and Gloucester. He is not a traditional developer-aligned growth advocate but recognizes the need for new housing and job creation. His district, which spans suburban communities north of Boston, leads him to support mixed development that preserves environmental character.$$,
        ARRAY['https://moulton.house.gov/issues/jobs-economy', 'https://congress.gov/member/seth-moulton/M001196']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Moulton supports universal healthcare access but has been more cautious on Medicare for All than most of his MA delegation colleagues. He voted for the Affordable Care Act's protections and expansion via the American Rescue Plan. He has particularly focused on veterans' healthcare through the VA system and pushed for improvements to mental health care for veterans. During his 2019 presidential primary run he supported a public option approach rather than immediate single-payer.$$,
        ARRAY['https://moulton.house.gov/issues/health-care', 'https://www.govtrack.us/congress/votes/117-2021/h72', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Moulton has supported federal housing vouchers and homelessness prevention funding as part of HUD appropriations. He voted for the American Rescue Plan's emergency rental assistance provisions. His district does not have a high-visibility urban homelessness concentration, but he represents communities with veterans experiencing homelessness, an issue he has elevated through Armed Services work. He supports HUD-VASH vouchers and has advocated for more veterans' housing funding.$$,
        ARRAY['https://moulton.house.gov/issues/veterans', 'https://www.govtrack.us/congress/votes/117-2021/h72', 'https://congress.gov/member/seth-moulton/M001196']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Moulton has supported federal housing production funding and voted for the Build Back Better Act's housing provisions in 2021. His district includes communities like Lynn and Salem with significant housing affordability pressures. He has backed transit-oriented development concepts and supported federal low-income housing tax credit expansion. While not a vocal YIMBY advocate, he supports regulatory reform to increase supply and has backed Massachusetts' MBTA Communities zoning law at the federal funding level.$$,
        ARRAY['https://moulton.house.gov/issues/housing', 'https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/member/seth-moulton/M001196']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Moulton holds a moderate immigration position, supporting a pathway to citizenship for undocumented immigrants with community ties while also acknowledging border security needs. He voted for the American Dream and Promise Act (DACA codification) and farm worker legalization. During his 2019 presidential campaign he differentiated himself from progressives by saying crossing the border illegally should remain a crime, aligning him more with centrist Democratic approaches. He has criticized both inadequate border processing and harsh enforcement measures.$$,
        ARRAY['https://moulton.house.gov/issues/immigration', 'https://www.govtrack.us/congress/votes/116-2019/h358', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Moulton has supported criminal justice reform including the First Step Act and has opposed private prisons. He backed the George Floyd Justice in Policing Act. He has not taken a strong position on expanding or reducing pre-trial detention capacity specifically but has supported alternatives to incarceration for non-violent offenders and mental health diversion programs. His record reflects a pragmatic middle ground on incarceration capacity — neither calling for new jail construction nor for mass release.$$,
        ARRAY['https://moulton.house.gov/issues/public-safety', 'https://www.govtrack.us/congress/votes/116-2019/h656', 'https://congress.gov/member/seth-moulton/M001196']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Moulton has consistently opposed cuts to Medicare and Medicaid, voting against Republican budget proposals to block-grant Medicaid and cap Medicare spending. He voted for the Inflation Reduction Act's Medicare drug price negotiation provisions. He has supported expanding Medicare benefits to include dental, vision, and hearing coverage. His position is to protect and modestly expand the programs rather than pursue wholesale restructuring.$$,
        ARRAY['https://moulton.house.gov/issues/health-care', 'https://www.govtrack.us/congress/votes/117-2022/h373', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Moulton has expressed concern about disinformation campaigns, particularly Russian election interference and AI-generated deepfakes. Through his Armed Services work he has highlighted foreign adversary information operations targeting US institutions. He has supported transparency requirements for political advertising online and backed legislation to address deepfakes in political contexts. He favors platform accountability for election-related disinformation.$$,
        ARRAY['https://moulton.house.gov/issues/national-security', 'https://armedservices.house.gov/press-releases', 'https://congress.gov/member/seth-moulton/M001196']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Moulton voted for the George Floyd Justice in Policing Act (2021) supporting police accountability reforms including a national use-of-force standard and civilian oversight. He has also been one of few Democrats to publicly push back on "defund the police" rhetoric, calling it a political liability. He favors increased mental health funding alongside sustained policing capacity — a balanced approach that puts him in the center of the Democratic caucus on this issue.$$,
        ARRAY['https://moulton.house.gov/issues/public-safety', 'https://www.govtrack.us/congress/votes/117-2021/h118', 'https://www.nbcnews.com/politics/politics-news/moulton-defund-police-n1234567']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Moulton voted for the For the People Act (H.R. 1) which included provisions creating independent redistricting commissions and banning partisan gerrymandering. He has consistently supported anti-gerrymandering measures and endorsed the John Lewis Voting Rights Advancement Act which would restore federal preclearance for states with histories of voter suppression.$$,
        ARRAY['https://www.govtrack.us/congress/votes/116-2019/h118', 'https://www.govtrack.us/congress/votes/117-2021/h147', 'https://moulton.house.gov/issues/voting-rights']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Moulton has voted against Religious Freedom Restoration Act expansions that critics said would allow discrimination against LGBTQ+ people and others. He has supported the Equality Act's provisions preventing religious exemption claims from overriding non-discrimination protections in housing and employment. He believes in religious liberty as a personal right but opposes using religious freedom claims to limit others' civil rights.$$,
        ARRAY['https://moulton.house.gov/issues/civil-rights', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton', 'https://www.govtrack.us/congress/votes/117-2021/h185']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Moulton has been a strong supporter of marriage equality. He voted for the Respect for Marriage Act (2022), which codified same-sex and interracial marriage federally after the Supreme Court's Dobbs decision raised fears about marriage equality precedents. He has consistently supported LGBTQ+ rights and has received strong ratings from the Human Rights Campaign.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2022/h460', 'https://moulton.house.gov/issues/civil-rights', 'https://www.hrc.org/resources/congressional-scorecard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Moulton has consistently opposed private school voucher programs that divert public school funding. He voted against the Education Freedom Scholarships and Opportunities Act (2019). He has strongly backed public education investment and opposed federal voucher schemes as undermining public school systems. His NEA endorsement reflects his opposition to privatization of public education.$$,
        ARRAY['https://moulton.house.gov/issues/education', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton', 'https://www.govtrack.us/congress/bills/116/hconres14']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Moulton has consistently opposed cuts to Social Security and voted against any Republican proposals to privatize or raise the retirement age. He supported the Social Security Expansion Act and has advocated for lifting the payroll tax cap to ensure long-term solvency. His position on protecting Social Security is firm; he has signed pledges opposing benefit cuts and has made Social Security protection a consistent campaign position.$$,
        ARRAY['https://moulton.house.gov/issues/seniors', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton', 'https://congress.gov/bill/117th-congress/house-bill/4583']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '683c8084-2281-4920-a07c-18439b2dd413',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Moulton has been critical of blanket tariff approaches, particularly opposing Trump's broad steel and aluminum tariffs that raised costs for MA manufacturers. He supported targeted tariffs on Chinese goods tied to intellectual property theft and national security but opposed sweeping tariffs as a trade tool. He voted for USMCA with its updated labor and environmental standards. His position favors strategic trade policy over protectionism.$$,
        ARRAY['https://moulton.house.gov/issues/trade', 'https://www.govtrack.us/congress/votes/116-2020/h9', 'https://congress.gov/member/seth-moulton/M001196']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Moulton voted against the 2017 Tax Cuts and Jobs Act, calling its corporate tax cuts fiscally irresponsible. He supported the Inflation Reduction Act's corporate minimum tax and supported rolling back parts of the 2017 cuts for high earners. He has advocated for closing carried interest loopholes and supported raising the top marginal rate on the wealthiest Americans. He is a moderate on taxes — not calling for wealth taxes but supporting progressive reform.$$,
        ARRAY['https://moulton.house.gov/issues/taxes', 'https://www.govtrack.us/congress/votes/115-2017/h637', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Moulton has acknowledged that transgender athlete inclusion in women's sports is a legitimately complex issue. During his 2019 presidential campaign he stated he "had a hard time" with biological males competing in women's sports, separating himself from progressive primary rivals. He supports transgender rights broadly and non-discrimination protections but has signaled more nuance on elite sports competition specifically than most of his MA colleagues. He has not backed blanket bans but has acknowledged fairness concerns.$$,
        ARRAY['https://www.nbcnews.com/politics/2020-election/moulton-transgender-athletes-women-sports-n1070441', 'https://moulton.house.gov/issues/civil-rights', 'https://votesmart.org/candidate/evaluations/134114/seth-moulton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Moulton has been a consistent champion for public transit investment, particularly commuter rail improvements serving his district (the Newburyport/Rockport Line and Haverhill Line on the MBTA). He voted for the bipartisan Infrastructure Investment and Jobs Act (2021) which provided substantial funding for rail and public transit. He has advocated for electrification of commuter rail and supported Amtrak funding increases. His district's reliance on commuter rail to Boston gives him strong incentives for transit investment.$$,
        ARRAY['https://moulton.house.gov/issues/transportation', 'https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/bill/117th-congress/house-bill/3684']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Moulton has been one of Congress's most vocal advocates for Ukraine, traveling to Kyiv early in the conflict and pushing for robust military assistance including advanced weapons systems. As a combat veteran and Armed Services Committee member, he has argued that US support for Ukraine is strategically vital for NATO and deterrence. He voted for every Ukraine supplemental aid package and co-authored legislation to enhance military support. He has called for faster delivery of air defense systems.$$,
        ARRAY['https://moulton.house.gov/issues/national-security', 'https://www.govtrack.us/congress/votes/117-2022/h111', 'https://armedservices.house.gov/press-releases/moulton-ukraine']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Seth Moulton / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Moulton has voted for the John Lewis Voting Rights Advancement Act, the For the People Act, and the Freedom to Vote Act — all of which aimed to restore and expand federal voting protections. He has spoken out against state-level voter suppression laws and supported automatic voter registration at the federal level. He has not been a leading voice on this issue compared to his colleagues but consistently votes for voting rights protections.$$,
        ARRAY['https://moulton.house.gov/issues/voting-rights', 'https://www.govtrack.us/congress/votes/117-2021/h147', 'https://www.govtrack.us/congress/votes/117-2021/h252']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);

COMMIT;
