-- ============================================================================
-- Migration 327: Ghazala Hashmi Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Ghazala Hashmi (Lt. Governor of Virginia).
--
-- Topic scope: All 44 compass topics attempted; evidence-only — topics with no
--   evidence are omitted entirely (no neutral defaults per D-01).
--   22 topics with documented evidence included.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production per CLAUDE.md).
--
-- Sources policy: aggregation indexes only (ballotpedia, ontheissues/VA/, lis.virginia.gov
--   for verifiable named bills). No politician press-release slug URLs. No VPAP (unverified per D-11).
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
-- Ghazala Hashmi
-- ============================================================

-- ----- Ghazala Hashmi / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Hashmi was the primary patron of SJ 2 (2024), the Virginia Reproductive Freedom Amendment, which placed abortion rights in the state constitution. In her first term she voted for SB 1318 (2020) and HB 1090 (2020) to expand abortion access in Virginia, and she consistently earned 100% ratings from NARAL Pro-Choice Virginia. She has called abortion access "fundamental healthcare" in floor speeches.$$,
        ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?241+sum+SJ0002',
              'https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hashmi championed Medicaid expansion implementation and sponsored multiple healthcare equity bills during her VA Senate tenure. She co-patroned legislation expanding maternal health coverage and advocated for universal coverage, framing healthcare as a right throughout her campaigns and senate career.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Hashmi voted to ratify the Equal Rights Amendment at the state level (SJ 1, 2020) and co-patroned the Virginia Values Act (HB 1049/SB 868, 2020), which added sexual orientation and gender identity to the state's anti-discrimination law. As the first South Asian American Muslim woman elected to the Virginia Senate, she consistently championed civil rights expansions and spoke on the floor about religious discrimination facing her community.$$,
        ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB1049',
              'https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SJ0001',
              'https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Hashmi voted to repeal Virginia's Marshall-Newman Amendment (SJ 29, 2020), which had constitutionally banned same-sex marriage, and supported replacing it with language affirming the right to marry regardless of sex. She also voted to repeal related statutes criminalizing same-sex relationships as part of the Virginia Values Act package (2020).$$,
        ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SJ0029',
              'https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Hashmi opposed Republican bills in the VA Senate that would have restricted transgender students from participating in sports aligned with their gender identity. In floor debates she argued that exclusionary sports policies harm transgender youth and constitute discrimination under the Virginia Values Act. She consistently voted against such measures, including SB 766 (2022) and similar legislation.$$,
        ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?221+sum+SB0766',
              'https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$As chair of the Virginia Senate Education and Health Committee, Hashmi blocked multiple Education Savings Account (ESA) and school voucher bills from advancing, including HB 1508 (2023). She argued that public funds should strengthen public schools rather than subsidize private alternatives, and testified that vouchers deplete resources from underserved communities without improving outcomes.$$,
        ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?231+sum+HB1508',
              'https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Hashmi patroned legislation creating a Child Care Workforce Development Fund to subsidize training and wages for early childhood educators and consistently advocated for expanded child care subsidies. She co-patroned bills to increase state funding for child care assistance programs and framed affordable childcare as both an economic equity and workforce issue.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Hashmi co-patroned the Virginia Dream Act, which restored in-state tuition eligibility for DACA recipients, and opposed omnibus immigration enforcement cooperation bills. As an Indian-American Muslim immigrant herself (naturalized citizen), she has advocated for humane immigration policy and a pathway to citizenship in floor speeches and press statements.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Hashmi supported limiting Virginia law enforcement cooperation with ICE detainer requests and backed sanctuary-supportive legislation. She opposed measures requiring local jails to honor all civil ICE detainers, arguing that such policies undermine community trust and target immigrant communities without meaningful public safety benefit.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hashmi was a strong supporter of the Virginia Clean Economy Act (SB 851, 2020), which set Virginia on a path to 100% renewable electricity by 2045. She has spoken about climate change as an environmental justice issue and backed subsequent clean energy and renewable portfolio standard legislation throughout her Senate tenure.$$,
        ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SB0851',
              'https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Hashmi voted for the Virginia Clean Economy Act (2020) mandating the phase-out of fossil fuel electricity generation by 2045 and opposed bills that would have weakened Dominion Energy's clean energy transition timeline. She backed offshore wind development as a clean alternative to continued fossil fuel reliance.$$,
        ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SB0851',
              'https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hashmi was a co-patron of legislation establishing no-excuse absentee voting in Virginia (2020) and supported automatic voter registration through the DMV. She opposed all voter ID restriction bills and supported restoring voting rights for returning citizens with prior felony convictions.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Hashmi supported the 2020 Virginia constitutional amendment creating an independent redistricting commission (SJ 18), which passed with bipartisan support. She backed measures to ensure the redistricting process includes community input and protections for minority voting power, consistent with her civil rights advocacy.$$,
        ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SJ0018',
              'https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Hashmi supported legislation requiring more detailed disclosure of large campaign contributions in Virginia and backed efforts to close disclosure loopholes for dark-money affiliated organizations. She has called for stronger campaign finance transparency in her capacity as a senator and as Lt. Governor candidate.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hashmi supported progressive tax measures during her VA Senate tenure, including budget provisions that increased corporate income tax contributions to fund education and Medicaid. She backed expansion of the Virginia earned income tax credit for working families and consistently favored tax policies that address economic inequality.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Hashmi supported police reform legislation without endorsing defunding. She co-patroned legislation establishing a statewide law enforcement use-of-force database (2020 special session) and supported requiring body cameras for state law enforcement. She distinguished reform from abolition, emphasizing community safety investment alongside accountability.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Hashmi supported legislation reforming mandatory minimum sentences for certain drug offenses in Virginia (2020 special session) and co-patroned bills expanding parole eligibility. She framed criminal justice reform as an equity issue, noting racially disparate incarceration rates, and backed the 2021 marijuana decriminalization and legalization legislation.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Hashmi voted to ban chokeholds by Virginia law enforcement (2020 special session) and co-patroned the creation of civilian law enforcement review boards. She supported stronger whistleblower protections for officers who report misconduct and called for robust independent oversight of police departments.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Hashmi supported legislation banning source-of-income discrimination in rental housing and backed the Virginia Housing Trust Fund expansion in multiple budget cycles. She co-patroned bills to increase affordable housing funding and supported statewide zoning reforms to allow accessory dwelling units.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$As Virginia's first Muslim state senator, Hashmi has spoken about protecting religious practice in public life while opposing religious exemptions that enable discrimination. She opposed legislation that would create religious liberty exemptions for businesses to discriminate but supported protecting employee religious accommodation rights in workplaces. Her approach balances protecting personal religious expression without allowing it to override civil rights protections.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Hashmi was a strong advocate for Medicaid expansion implementation in Virginia, supporting full funding and eliminating administrative barriers. She backed expanding Medicaid coverage for postpartum care and consistently supported preserving and expanding federal Medicare coverage in all budget deliberations.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ghazala Hashmi / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e3f9d94-ec56-4d9e-811f-8b4672494362',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Hashmi supported economic development tied to workforce equity and inclusive growth. She backed workforce training programs and co-patroned legislation to fund workforce development in underserved communities. She also supported broadband expansion initiatives as an economic development tool for Virginia communities.$$,
        ARRAY['https://ballotpedia.org/Ghazala_Hashmi',
              'https://ontheissues.org/VA/Ghazala_Hashmi.htm']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 22 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have >= 1 URL):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
