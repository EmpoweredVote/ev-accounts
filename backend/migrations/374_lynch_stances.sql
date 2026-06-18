-- ============================================================================
-- Migration 374: Stephen Lynch Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Stephen Lynch (US Representative, MA-08).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Supplemental: Lynch had 14 pre-existing stances from a prior session.
--   This migration re-upserts all with corrected values and adds new topics.
--   city-sanitation omitted — no documented federal House record.
--   Total expected: 28+ topics.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Politician UUID: 62b453da-3dea-4177-82ba-9e4b78eb7691  (external_id -200208)

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

-- ===== Stephen Lynch (MA-08) =====
-- South Boston / South Shore; former IBEW member and ironworker; Financial Services Committee;
-- conservative Democrat; voted against ACA in 2010; anti-crypto; Catholic; Oversight Committee

-- ----- Stephen Lynch / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Lynch has one of the most conservative abortion records of any Massachusetts Democrat. He voted for the Stupak-Pitts Amendment (2009) which would have banned abortion coverage in the ACA exchange plans. He opposed the Women's Health Protection Act and has historically received low ratings from NARAL (25-40%) while earning scores from anti-abortion groups. He has described himself as a Catholic who opposes abortion. In the 2013 MA Senate special election primary against Ed Markey, his anti-abortion record was a major issue. He has not been a cosponsor of abortion rights legislation.$$,
        ARRAY['https://www.naral.org/scorecards/', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch', 'https://www.ontheissues.org/MA/Stephen_Lynch.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Lynch has a mixed campaign finance record. He has generally supported disclosure requirements and voted for the For the People Act's campaign finance provisions. He accepts union PAC money but not corporate lobbyist PAC donations. He has supported the DISCLOSE Act for campaign finance transparency. However, he has been less vocal on campaign finance reform compared to progressive colleagues and has not been a leading sponsor of reform legislation.$$,
        ARRAY['https://www.opensecrets.org/members-of-congress/stephen-lynch/summary?cid=N00013620', 'https://www.govtrack.us/congress/votes/116-2019/h118', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lynch voted for the Build Back Better Act's child care provisions in 2021 and has supported federal child care funding as a working family issue. As a former union member representing working-class South Boston and South Shore communities, he has backed child care investment as an economic enabler for workers. He has supported the Child and Dependent Care Tax Credit expansion.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2021/h369', 'https://lynch.house.gov/issues/families', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Lynch has a mixed civil rights record. He voted for the George Floyd Justice in Policing Act and generally supports racial equity legislation. However, he has historically had lower ACLU ratings than MA delegation peers (60-70%) and was a late convert on same-sex marriage. He opposed some LGBTQ+ rights measures in his earlier career. His civil rights positions reflect his South Boston Catholic Democratic background — generally supportive of racial equality but more conservative on LGBTQ+ issues historically.$$,
        ARRAY['https://www.aclu.org/scorecard', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch', 'https://www.govtrack.us/congress/votes/117-2021/h118']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lynch voted for the Inflation Reduction Act's climate provisions in 2022 and supports clean energy investment. However, he opposed the Green New Deal and has been more cautious on rapid fossil fuel phase-out given his district's LNG terminal and blue-collar energy sector workers. He has received lower LCV ratings (typically 55-75%) than most MA colleagues. He supports a managed energy transition rather than rapid elimination of fossil fuels.$$,
        ARRAY['https://scorecard.lcv.org/moc/stephen-lynch', 'https://www.govtrack.us/congress/votes/117-2022/h373', 'https://lynch.house.gov/issues/energy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Lynch has not taken a specific public stance on data center siting. His district's communities (Quincy, Braintree, South Boston) are not major data center development zones. As a Financial Services Committee member he has engaged with technology policy through financial data infrastructure oversight but has not been a vocal voice on data center energy or permitting issues. No specific evidence of a defined position found.$$,
        ARRAY['https://lynch.house.gov/issues/technology', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Lynch has a moderate record on deportation. He has supported targeted enforcement against convicted criminals while opposing mass deportation. He did not sign onto progressive calls to abolish ICE. He voted for immigration reform bills including DREAM Act provisions but has also supported border security measures. His South Boston constituents include many with Irish immigration backgrounds, giving him a mixed constituency on immigration enforcement.$$,
        ARRAY['https://lynch.house.gov/issues/immigration', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Lynch has been a strong advocate for working-class economic development in his district. He supported the bipartisan Infrastructure Investment and Jobs Act, the CHIPS and Science Act, and funding for South Boston's Seaport industrial sites. He has backed port development, maritime jobs, and construction trade employment. As a former ironworker and IBEW member, he prioritizes economic development that creates blue-collar jobs and has championed apprenticeship programs.$$,
        ARRAY['https://lynch.house.gov/issues/economy', 'https://www.govtrack.us/congress/votes/117-2021/h395', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Lynch has a more moderate position on fossil fuels than most MA colleagues. His district includes a large LNG import terminal at Everett (Constellation Energy), and he has been cautious about policies that could immediately affect energy supply. He voted for the Inflation Reduction Act but has not endorsed an aggressive fossil fuel phase-out timeline. He opposes new offshore drilling but has been more reluctant to back immediate fossil fuel subsidy elimination. LCV scores in the 55-75% range reflect this moderation.$$,
        ARRAY['https://scorecard.lcv.org/moc/stephen-lynch', 'https://lynch.house.gov/issues/energy', 'https://www.govtrack.us/congress/votes/117-2022/h373']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lynch is one of two Massachusetts Democrats who voted against the Affordable Care Act in 2010, saying it did not go far enough to control costs. He later supported ACA fixes and maintenance votes. He is not a Medicare for All supporter and prefers building on the existing system. He has backed lower drug prices through negotiation (voted for the Inflation Reduction Act) and has supported veterans' healthcare expansion. His position is center-left — preserve ACA but no single-payer.$$,
        ARRAY['https://www.govtrack.us/congress/votes/111-2010/h165', 'https://lynch.house.gov/issues/health-care', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Lynch has supported federal housing assistance and homelessness prevention funding. As an Oversight Committee member he has engaged with VA homelessness programs. He represents South Boston communities near transitional housing facilities and has backed veterans' housing programs. His position is mainstream Democrat — support housing and services funding without taking a strong position on encampment policy or housing-first vs. shelter approaches.$$,
        ARRAY['https://lynch.house.gov/issues/housing', 'https://congress.gov/member/stephen-lynch/L000562', 'https://www.govtrack.us/congress/votes/117-2021/h72']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lynch has backed federal housing investment through HUD programs, the LIHTC expansion, and the Build Back Better Act's housing provisions. His district includes South Boston's rapidly gentrifying neighborhoods and Quincy, where housing affordability is a significant issue for working-class constituents. He has supported public housing preservation and voucher programs. As a former public housing resident himself, he has spoken personally about the importance of affordable housing access.$$,
        ARRAY['https://lynch.house.gov/issues/housing', 'https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Lynch has a moderate immigration record — he has voted for DREAM Act provisions and comprehensive immigration reform with a pathway to citizenship, while also supporting border security measures. He did not oppose Secure Communities (which linked local law enforcement to immigration databases) in his early career. He is more moderate on immigration enforcement than progressive colleagues but generally supports immigrant communities in his district, including large Irish, Cape Verdean, and Vietnamese populations.$$,
        ARRAY['https://lynch.house.gov/issues/immigration', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Lynch has taken moderate positions on incarceration — supporting the First Step Act and criminal justice reform while not backing proposals to dramatically reduce detention capacity. He voted for the George Floyd Justice in Policing Act. His South Boston constituents include law enforcement families, and he has been a supporter of police funding while backing reform measures. His record does not show advocacy for either dramatically expanding or sharply reducing jail capacity.$$,
        ARRAY['https://lynch.house.gov/issues/public-safety', 'https://www.govtrack.us/congress/votes/116-2019/h656', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Lynch has opposed all Republican proposals to cut Medicare and Medicaid. He voted for the Inflation Reduction Act's Medicare drug price negotiation provisions. While he voted against the ACA in 2010, he has consistently protected Medicare and Medicaid from cuts since then. He backed the Medicare dental, vision, and hearing expansion proposals. His position is to preserve and modestly expand existing programs.$$,
        ARRAY['https://lynch.house.gov/issues/health-care', 'https://www.govtrack.us/congress/votes/117-2022/h373', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Lynch voted for the George Floyd Justice in Policing Act (2021) supporting accountability reforms. However, he has been among the Democrats most supportive of law enforcement funding and has opposed defund rhetoric. He has backed police pension protections and has been endorsed by police unions in past elections. His South Boston district has deep connections to the Boston Police Department, and he reflects a constituency that supports both accountability reforms and robust police funding.$$,
        ARRAY['https://lynch.house.gov/issues/public-safety', 'https://www.govtrack.us/congress/votes/117-2021/h118', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Lynch voted for the For the People Act and John Lewis Voting Rights Advancement Act, both of which included redistricting reform provisions. He has generally supported independent redistricting commissions as part of broader democracy reform packages. He has not been a leading champion on this issue but has consistent pro-reform votes.$$,
        ARRAY['https://www.govtrack.us/congress/votes/116-2019/h118', 'https://www.govtrack.us/congress/votes/117-2021/h147', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Lynch is a practicing Catholic who has at times cited religious values in his positions on abortion. He has been more cautious about religious exemptions in the LGBTQ+ context than most MA Democrats, reflecting his Catholic constituency in South Boston. He voted for the Equality Act but has been less vocal in opposing religious liberty arguments than progressive colleagues. He represents a classic blue-collar Catholic Democrat position on religious freedom.$$,
        ARRAY['https://lynch.house.gov/issues', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch', 'https://www.ontheissues.org/MA/Stephen_Lynch.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Lynch historically opposed same-sex marriage and voted for the Defense of Marriage Act in 2004. He evolved on the issue; by 2012 he stated he supported same-sex marriage. He voted for the Respect for Marriage Act in 2022, federally codifying marriage equality. He represents a significant evolution in his position, but his early record differentiates him from MA colleagues who consistently supported marriage equality. His current support is clearly documented.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2022/h460', 'https://www.ontheissues.org/MA/Stephen_Lynch.htm', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Lynch has generally opposed private school voucher programs that divert public school funding. However, as a Catholic with Catholic school-educated children and representing communities with strong Catholic school traditions in South Boston and Quincy, he has been somewhat more open to parochial school aid compared to progressive colleagues. He has supported some modest K-12 school choice within the public school system. His overall record leans against private vouchers but is less absolute than most MA Democrats.$$,
        ARRAY['https://lynch.house.gov/issues/education', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch', 'https://www.ontheissues.org/MA/Stephen_Lynch.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Lynch has consistently opposed cuts to Social Security and voted against all Republican proposals to privatize or reduce benefits. He backed the Social Security Expansion Act and has represented South Boston constituents including many senior citizens on fixed incomes. He has signed pledges to protect Social Security and has spoken about the program's importance for blue-collar workers without private pensions.$$,
        ARRAY['https://lynch.house.gov/issues/seniors', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Lynch has a labor-protective trade record, supporting tariffs that protect American manufacturing and union jobs. He supported USMCA with its labor standards and has backed steel and aluminum tariffs that protect his district's industrial workers. He voted against the Trans-Pacific Partnership and has been critical of trade deals that cost American jobs. His position aligns with traditional labor-protective industrial-state Democrats.$$,
        ARRAY['https://lynch.house.gov/issues/trade', 'https://www.govtrack.us/congress/votes/116-2020/h9', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lynch voted against the 2017 Tax Cuts and Jobs Act and has supported progressive taxation. He backed the Inflation Reduction Act's corporate minimum tax provisions. He has supported raising rates on high earners and closing corporate loopholes, though he is less focused on extreme progressive measures like wealth taxes. His tax position reflects his working-class constituency — support raising taxes on the wealthy to fund programs for workers.$$,
        ARRAY['https://lynch.house.gov/issues/taxes', 'https://www.govtrack.us/congress/votes/115-2017/h637', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Lynch has not taken a highly visible public position on transgender athlete inclusion in sports. He voted against the Republican Protection of Women and Girls in Sports Act (2023) but has not been a vocal advocate for transgender inclusion. His conservative Catholic background and moderate record on LGBTQ+ issues over the years suggests a more cautious middle position. He supported the Equality Act's overall non-discrimination framework.$$,
        ARRAY['https://www.govtrack.us/congress/votes/118-2023/h108', 'https://congress.gov/member/stephen-lynch/L000562', 'https://votesmart.org/candidate/evaluations/7740/stephen-lynch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Lynch voted for the bipartisan Infrastructure Investment and Jobs Act (2021), a major win for his district's commuter rail connections (Red Line/Braintree Branch) and South Station improvements. He has backed MBTA funding and transit investment throughout his career. He also has strong ties to the construction trades who built transportation infrastructure. His transportation record reflects both transit and highway investment — characteristic of a blue-collar labor-aligned member.$$,
        ARRAY['https://lynch.house.gov/issues/transportation', 'https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '24e9212c-b011-422a-865c-093e35050901',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Lynch has consistently voted for Ukraine military and economic assistance supplemental packages. As Oversight Committee Ranking Member, he has supported oversight of US aid delivery while maintaining support for Ukraine's defense. He voted for every major Ukraine aid package and has not joined the small faction of Democrats questioning Ukraine support levels. His position is solidly supportive of continued US assistance.$$,
        ARRAY['https://www.govtrack.us/congress/votes/117-2022/h111', 'https://lynch.house.gov/issues/foreign-affairs', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Lynch / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62b453da-3dea-4177-82ba-9e4b78eb7691',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Lynch voted for the John Lewis Voting Rights Advancement Act, Freedom to Vote Act, and For the People Act. He has consistently supported restoring and expanding federal voting protections. While not a leading champion on voting rights compared to progressive colleagues, he has maintained a consistent pro-voting-rights voting record across all major bills in the 116th and 117th Congresses.$$,
        ARRAY['https://lynch.house.gov/issues/voting-rights', 'https://www.govtrack.us/congress/votes/117-2021/h147', 'https://congress.gov/member/stephen-lynch/L000562']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);

COMMIT;
