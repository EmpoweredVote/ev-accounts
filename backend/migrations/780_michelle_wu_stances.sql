-- ============================================================================
-- Migration 577: Michelle Wu Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michelle Wu
--   (Mayor, City of Boston, LOCAL_EXEC, external_id -2507000001).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--   Judicial topics omitted: no evidence of judicial philosophy for a city mayor.
--   Federal-level topics omitted (tariffs, ukraine-support, social-security,
--   medicare/aid, data-centers, ai-regulation, misinformation): no city-level record.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
--
-- Pre-flight result (Task 1): 162 pre-existing rows across 14 Boston officials
--   from a prior session. ON CONFLICT DO UPDATE handles correctly.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, active as of 2026-06-13, count=44):
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

-- Politician UUID: d63def16-7510-4745-83d8-01901e450429 (external_id: -2507000001)

BEGIN;

-- ----- Michelle Wu / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Wu urged Massachusetts lawmakers to adopt the Roe Act in 2019 to codify Roe v. Wade protections and has stated she supports protecting access to abortion care. Her position aligns with keeping abortion legal and accessible at least through the second trimester — she has not publicly advocated for full public funding at all stages of pregnancy, nor supported restrictions below standard trimesters. Value 2 best matches her documented record.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Wu has backed transparency measures for corporate tax breaks and political spending through her city council record. While she has accepted Super PAC support from labor unions, her legislative record favors strict limits on corporate political donations and dark money — not just disclosure. Her overall position aligns with value 2: strictly limiting corporate donations and dark money groups.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://commonwealthbeacon.org/politics/super-pac-aligned-with-mayor-wu-receives-six-figure-donation/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Wu created the Cabinet for Worker Empowerment in September 2022 tasked with establishing a childcare trust fund, expanded developer contributions to childcare, launched the Essential Worker Childcare Fund and Stimulus and Stability Fund for childcare centers, and expanded Universal Pre-K programming. The Office of Early Childhood is accelerating a universal pre-K system. Her record is consistent with value 2: significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/early-childhood', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$The Wu administration has invested in sanitation improvements with an equity lens, prioritizing historically underserved neighborhoods. Her environmental justice framing across climate, heat resilience, and community clean air programs reflects a commitment to equalizing service levels across neighborhoods. Wu launched the Boston Residential Organic Composting Program and set zero-waste goals aligned with her climate agenda. This aligns with value 2: increasing sanitation investment and prioritizing underserved neighborhoods to equalize cleanliness citywide.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu', 'https://www.boston.gov/environment']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wu signed the Affirmatively Furthering Fair Housing policy in January 2022 (making Boston the largest U.S. city with such a policy), assembled a diverse cabinet across racial backgrounds, organized an Electeds of Color affinity group, awarded the largest non-construction contract in city history to a Black-owned business, and co-authored anti-discrimination ordinances protecting transgender employees. Her record reflects strengthening civil rights enforcement and addressing systemic discrimination — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Wu signed a fossil fuel divestment ordinance in November 2021 divesting $65 million from fossil fuel companies, signed an executive order in July 2023 halting fossil fuels in new municipal buildings, and set goals of 100% renewable energy citywide by 2030 and carbon neutrality by 2040. She implemented BERDO requiring large buildings to reach net-zero by 2050 and established the Boston Climate Council. This is a rapid renewable-energy-transition agenda aligned with value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/environment', 'https://www.boston.gov/departments/environment/berdo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Wu explicitly stated she does not support mass deportation, calling it devastating for the economy and for millions of people running small businesses and attending schools. She defended the Boston Trust Act, which limits police referrals to criminal detainers only — not civil immigration status. Her position is consistent with value 2: only deport people convicted of serious violent crimes, protecting everyone else.$$,
        ARRAY['https://commonwealthbeacon.org/politics/are-you-out-of-your-mind-five-moments-from-mayor-michelle-wus-immigration-testimony/', 'https://en.wikipedia.org/wiki/Michelle_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Boston's economic development under Wu emphasizes supplier diversity, small business support, and community wealth-building over large corporate tax abatements. Wu called for government transparency around corporate tax breaks as city councilor and introduced an ordinance to that effect in 2019. The city's economic development department explicitly focuses on equitable procurement and local entrepreneur programs — consistent with value 2: small business support and avoiding large corporate subsidies.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/economic-development', 'https://www.boston.gov/departments/small-business']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Wu signed an executive order in July 2023 halting fossil fuels in all new municipal buildings, proposed a Home Rule Petition for a municipal fossil fuel ban in new buildings, and signed a $65 million fossil fuel divestment ordinance in November 2021. At every level of city authority available to her, she has moved to stop new fossil fuel investment and infrastructure — consistent with value 2: stop issuing new permits and funding for fossil fuels.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/environment']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Wu has pursued proactive infrastructure investment alongside housing production — expanding affordable housing, transit-oriented development, and the Boston Planning Advisory Council to plan ahead of growth. She has not imposed growth limits or required voter approval for developments, nor has she removed all regulatory barriers. Her approach of planning proactively and investing in infrastructure to support responsible expansion is consistent with value 3.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/transportation/go-boston-2030', 'https://www.boston.gov/departments/neighborhood-development']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wu co-authored a city ordinance guaranteeing comprehensive healthcare including gender-affirming care to transgender city employees, and has consistently backed expanded coverage through public programs and regulated private insurance. She has not called for a fully public single-payer system, but her public record reflects support for ensuring everyone has affordable coverage through a mix of public programs and regulated private insurance — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Wu moved hundreds of unhoused individuals from Mass and Cass to temporary housing in her early months as mayor, connecting them to services rather than using criminal penalties. Boston secured $4 million in state funding for Mass and Cass services. Her approach focuses on outreach, shelter, and housing placements rather than criminalization — consistent with value 2: decriminalizing public sleeping while investing in shelter capacity and voluntary service connections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/homelessness', 'https://www.nbcboston.com/tag/michelle-wu/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Wu's approach to homelessness centers on connecting people to services and shelter rather than enforcement. She cleared the Mass and Cass encampment only after providing housing placements to displaced individuals, and secured state and federal funds for outreach and shelter services. The Boston Public Health Commission operates over 40 programs including emergency shelter and recovery services. Her primary strategy is expanding shelter and services — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/homelessness', 'https://www.boston.gov/departments/boston-public-health-commission']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wu has pursued rent stabilization through a Home Rule Petition (March 2023), established Inclusionary Zoning requiring 15-17% affordable units in market-rate developments of 7+ units (effective October 2024), created the Boston Acquisition Fund to preserve affordable multi-family housing, and signed an executive order eliminating parking minimums for affordable developments. Her approach combines rent caps, inclusionary requirements, and publicly funded affordable housing — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/housing/rent-stabilization', 'https://www.boston.gov/departments/neighborhood-development']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Wu is the nation's most prominent sanctuary-city defender: she has upheld the Boston Trust Act (which lets all immigrants use public services without immigration-status inquiry), testified before Congress defending these policies in March 2025, and issued an executive order in June 2025 affirming due process rights regardless of status. She stated the city does not ask about immigration status when delivering services — consistent with value 2: keep legal immigration open and let most residents use public services regardless of status.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://commonwealthbeacon.org/politics/are-you-out-of-your-mind-five-moments-from-mayor-michelle-wus-immigration-testimony/', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Wu introduced an ordinance as city councilor in June 2020 establishing an unarmed community safety crisis response system as an alternative to policing and incarceration. Her administration has invested in mental health co-responders, diversion programs, and addiction treatment rather than building new jail capacity. Her record aligns with value 2: reducing incarceration through pretrial diversion and treatment alternatives rather than expanding jail capacity.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Wu signed an executive order eliminating parking minimums for affordable developments, implemented BERDO requiring building emissions reductions, doubled annual tree planting, launched a Heat Resilience for Boston plan targeting environmental justice communities, and passed a wetlands protection ordinance. Developers operating in Boston face significant environmental review and offset requirements. This reflects value 2: protecting parks and tree canopy and requiring developers to fully offset environmental impacts.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/environment', 'https://www.boston.gov/departments/environment/berdo']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$The Boston Trust Act — which Wu has vigorously defended in court and before Congress — prohibits Boston police from honoring civil ICE detainers and from inquiring about or sharing immigration status with federal authorities. Her June 2025 executive order reinforced these protections. She stated police cooperate only on criminal detainers, not civil immigration enforcement. This is value 1: refuse all civil ICE detainers and prohibit city employees from sharing immigration status.$$,
        ARRAY['https://commonwealthbeacon.org/politics/are-you-out-of-your-mind-five-moments-from-mayor-michelle-wus-immigration-testimony/', 'https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Wu vetoed a $5 million police budget cut in June 2023 calling it 'illusory,' appointed Police Commissioner Michael Cox, negotiated accountability reforms in the police contract (officers lose arbitration appeals for certain convictions, public pay transparency), and achieved record-low gun violence. As councilor she introduced an unarmed community safety crisis response ordinance in June 2020. Her approach keeps current police staffing while adding crisis response teams — value 3.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Wu co-authored an ordinance prohibiting city contracting with health insurers that discriminate based on gender identity and has consistently protected LGBTQ employees from discrimination. Her record reflects protecting religious freedom while ensuring it does not override anti-discrimination protections in employment and city services — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Wu submitted a Home Rule Petition in March 2023 seeking state permission for rent stabilization (capping annual rent increases), established a Rent Stabilization Advisory Committee in March 2022, and endorsed the state ballot measure for rent control in February 2026. She has also strengthened tenant protections through the Boston Acquisition Fund preserving affordable multi-family homes. Her position is to strengthen existing rent stabilization and extend its coverage — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/housing/rent-stabilization']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Wu signed an executive order eliminating parking minimums for affordable developments with 60%+ income-restricted units, implemented Inclusionary Zoning requiring 15-17% affordable units in 7+ unit market-rate developments, and explored ADUs through the Housing Innovation Lab. However, she has not pursued broad upzoning or elimination of single-family zoning citywide. Her approach allows multifamily and mixed-use development alongside affordable requirements, while maintaining most residential zone protections — value 3.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/neighborhood-development', 'https://www.boston.gov/housing/housing-innovation-lab']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Wu co-authored an ordinance in June 2014 guaranteeing comprehensive healthcare including gender-affirming care to transgender city employees, and has been a consistent public advocate for full LGBTQ equality. Her record and public statements support full federal recognition of same-sex marriages with complete protections and benefits — value 1.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Wu has been a consistent and vocal public school advocate who funded summer jobs for all BPS students, expanded Universal Pre-K in public school settings, and made museums free for school-age children through public investment. She has not supported diverting public education funds to private institutions through vouchers. Her platform explicitly centers fully funding public schools — value 1.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Wu pursued a temporary property tax shift to protect middle-class homeowners from spikes caused by declining commercial property values, stating residents would face consequences if the legislature did not act. As city councilor she introduced ordinances for corporate tax transparency. Her fiscal approach prioritizes protecting lower- and middle-income residents through tax policy — moderately aligned with value 2: modestly raising or shifting taxes on commercial and high-value properties to fund existing services.$$,
        ARRAY['https://commonwealthbeacon.org/government/state-government/spilka-hosts-opposing-camps-on-wus-property-tax-shift-proposal/', 'https://en.wikipedia.org/wiki/Michelle_Wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Wu co-authored an ordinance in June 2014 guaranteeing healthcare including gender reassignment surgery and hormone therapy to transgender city employees, with no restrictions on eligibility based on biological sex assignment. Her record reflects full inclusion of transgender individuals in all public programs and institutions — consistent with value 1: allow all transgender athletes to compete on teams matching their gender identity without restrictions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Wu championed fare-free public transit (Routes 23, 28, 29 made free in 2022), proposed eliminating MBTA fares entirely in a 2019 op-ed, oversaw Vision Zero's 'people-first approach' targeting pedestrians and cyclists, reduced parking requirements for affordable developments, funded Better Bike Lanes and Neighborhood Slow Streets citywide, and Go Boston 2030 targets a 50% reduction in drive-alone commuting. This record is firmly at value 1: prioritize pedestrian infrastructure, cycling, and public transit while reducing parking requirements.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/transportation/vision-zero', 'https://www.boston.gov/departments/transportation/go-boston-2030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (must be >= 10):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'd63def16-7510-4745-83d8-01901e450429';
--
-- Unpaired check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'd63def16-7510-4745-83d8-01901e450429'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'd63def16-7510-4745-83d8-01901e450429'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
