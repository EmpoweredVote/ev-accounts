-- ============================================================================
-- Migration 360: Kim Driscoll Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kim Driscoll (Lieutenant Governor of Massachusetts).
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
-- Kim Driscoll: e687c089-f00d-464c-aa37-3b021a3aba2c (external_id = -200003)

BEGIN;

-- ============================================================
-- Kim Driscoll
-- Lieutenant Governor of Massachusetts
-- Salem Mayor 2006-2023; LG since January 2023
-- ============================================================

-- ----- Kim Driscoll / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Driscoll ran on the Healey-Driscoll ticket which made abortion rights a centerpiece of the 2022 campaign, pledging to protect and expand access following the Dobbs decision. As LG, she supported Governor Healey's executive order protecting Massachusetts as a sanctuary state for abortion seekers from other states. The Healey-Driscoll administration supported legislation expanding reproductive healthcare access signed in 2023.$$,
        ARRAY['https://www.wbur.org/news/2022/09/06/2022-massachusetts-democratic-lieutenant-governor-primary-result', 'https://www.mass.gov/news/governor-healey-signs-legislation-to-expand-reproductive-healthcare-access']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Driscoll's 2022 LG campaign emphasized small-dollar fundraising and rejected corporate PAC money aligned with the Healey campaign's reform ethos. The Healey-Driscoll platform called for stricter campaign finance transparency and limits on dark money in state elections. Driscoll's 17-year Salem mayoral tenure included multiple clean-government reform efforts at the municipal level.$$,
        ARRAY['https://www.wbur.org/news/2022/09/06/2022-massachusetts-democratic-lieutenant-governor-primary-result', 'https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$As Salem Mayor, Driscoll expanded childcare and early education access in the city, including school-based programs. The Healey-Driscoll campaign platform prioritized affordable childcare as an economic growth issue, arguing that childcare costs prevent parents — especially mothers — from participating in the workforce. Driscoll has highlighted childcare as a workforce development priority in her LG role.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.nbcboston.com/news/local/dem-delegates-endorse-healey-qualify-chang-diaz-for-ballot/2739254/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Driscoll has been a consistent civil rights advocate throughout her career. As Salem Mayor she oversaw diversity and inclusion initiatives in city hiring and services. The Healey-Driscoll administration has issued executive orders reaffirming Massachusetts's commitment to civil rights protections, including protections for LGBTQ+ residents and communities of color. Driscoll has championed equity in economic development during her mayoral and LG tenures.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.mass.gov/executive-orders/no-627-reaffirming-the-commonwealths-commitment-to-civil-rights']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Driscoll made Salem one of Massachusetts's "Green Communities" during her mayoral tenure, qualifying the city for renewable energy and efficiency grants from the state. She oversaw the replacement of Salem's 1940s coal-fired power plant with a smaller, cleaner natural gas facility as part of waterfront redevelopment, and installed EV charging stations in Salem in 2013. The Healey-Driscoll administration has continued aggressive climate action including signing climate change legislation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.mass.gov/info-details/massachusetts-clean-energy-and-climate-plan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Driscoll led a $1 billion waterfront transformation in Salem during her mayoral tenure, attracting private investment while preserving public access and environmental quality. She secured federal grants for the Salem-Boston commuter ferry and built commercial redevelopment along the waterfront. As LG, Driscoll has focused on workforce development and small business growth, emphasizing equitable economic development that benefits working families alongside business interests.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://commonwealthmagazine.org/politics/002-salem-mayor-kim-driscoll/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Driscoll oversaw the transition of the Salem Harbor coal plant to natural gas as a step toward cleaner energy, while supporting long-term renewable energy goals. The Healey-Driscoll administration has committed to Massachusetts's goal of net-zero emissions by 2050 and has supported expanded offshore wind development. Driscoll supports phasing out fossil fuel dependence but acknowledged the Salem natural gas plant as a transitional measure rather than a long-term solution.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.mass.gov/info-details/massachusetts-clean-energy-and-climate-plan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$As Salem Mayor, Driscoll actively encouraged economic growth and urban redevelopment, transforming Salem's waterfront and downtown while maintaining historic character and environmental standards. She balanced pro-growth policies with community benefits requirements and environmental review. The Healey-Driscoll administration has supported mixed-income housing growth and transit-oriented development as components of the state's housing strategy.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://commonwealthmagazine.org/politics/002-salem-mayor-kim-driscoll/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Driscoll campaigned on expanding healthcare access as part of the Healey-Driscoll platform, supporting MassHealth expansion and universal coverage goals. As Salem Mayor she supported city employee healthcare benefits and community health initiatives. The Healey-Driscoll administration has expanded MassHealth coverage and maintained Massachusetts's near-universal coverage model, and Driscoll has advocated for mental health parity and behavioral health investment.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-expands-masshealth-coverage', 'https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Housing was a signature issue for Driscoll as Salem Mayor — she oversaw significant residential development including affordable housing projects and transit-oriented development near the Salem MBTA station. The Healey-Driscoll administration signed the $5.1 billion Affordable Homes Act in 2024, the largest housing investment in Massachusetts history, which Driscoll championed as LG. She has called the housing shortage the state's most pressing economic challenge.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-signs-affordable-homes-act', 'https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$As Salem Mayor, Driscoll was an early supporter of immigrant-friendly policies, including not directing city resources toward federal immigration enforcement. Salem's immigrant community — including a large Latino population — grew significantly during her tenure. The Healey-Driscoll administration issued executive orders in 2025 protecting Massachusetts immigrants from federal deportation enforcement, and Driscoll has been a vocal advocate for immigrant families.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-issues-executive-order-protecting-immigrants', 'https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Driscoll has been a strong opponent of mass deportation. As Salem Mayor she maintained the city's welcoming posture toward immigrants and refused to use city resources for ICE enforcement cooperation. As LG she supported the Healey administration's executive order protecting immigrants in Massachusetts from federal mass deportation operations, and has publicly decried federal immigration enforcement targeting Massachusetts residents.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-issues-executive-order-protecting-immigrants', 'https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Driscoll built Salem's environmental record during her mayoral tenure: Green Community designation, mandatory city-wide recycling program (2013), EV charging stations (2013), Salem Harbor coal plant decommissioning, and waterfront environmental cleanup. She championed these local environmental improvements as models for other Massachusetts cities. The Healey-Driscoll administration has supported expanded state environmental programs at the local level.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.mass.gov/info-details/green-communities-designation-grants']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Driscoll's Salem maintained a welcoming local stance toward immigrants throughout her tenure — the city did not direct police resources toward immigration enforcement and provided city services regardless of status. Salem's immigrant community flourished during her 17 years as mayor. As LG, she has supported state-level policies restricting local cooperation with federal immigration enforcement and defended sanctuary city policies as consistent with Massachusetts values.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.mass.gov/news/governor-healey-issues-executive-order-protecting-immigrants']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Driscoll has consistently supported Medicare and Medicaid (MassHealth) expansion. The Healey-Driscoll administration has defended MassHealth against federal funding cuts and expanded coverage. As Salem Mayor, Driscoll supported the city's senior services programs funded through state and federal assistance. She has opposed cuts to social safety net programs and supported the Affordable Care Act and Medicaid expansion as foundations of Massachusetts's near-universal healthcare coverage.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-expands-masshealth-coverage', 'https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$As Salem Mayor, Driscoll maintained robust public safety services while also investing in social services and community programming. She oversaw Salem's police and fire departments without major reform controversies, reflecting a balanced approach that invests in both traditional public safety and prevention. The Healey-Driscoll administration has supported police accountability reforms while maintaining strong support for law enforcement, consistent with a reform-minded but not defund approach.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://commonwealthmagazine.org/politics/002-salem-mayor-kim-driscoll/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$As Salem Mayor, Driscoll updated zoning to allow mixed-use and higher-density development near the MBTA station and waterfront, reflecting a pro-housing zoning stance. She supported transit-oriented development and increased residential density in appropriate areas while maintaining neighborhood character elsewhere. The Healey-Driscoll administration has supported the MBTA Communities Act, which requires municipalities to allow multi-family housing near transit, consistent with Driscoll's local zoning record.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.mass.gov/info-details/mbta-communities-act']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Driscoll is a strong supporter of same-sex marriage and LGBTQ+ rights. Massachusetts legalized same-sex marriage in 2004 before Driscoll became mayor; throughout her tenure she has been a consistent LGBTQ+ ally. The Healey-Driscoll campaign highlighted LGBTQ+ rights protections, and as LG Driscoll has supported the administration's executive orders protecting LGBTQ+ residents and opposing federal rollbacks of marriage equality and other protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.mass.gov/executive-orders/no-627-reaffirming-the-commonwealths-commitment-to-civil-rights']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Driscoll has consistently opposed school voucher programs that would redirect public school funding to private schools. As Salem Mayor she prioritized investment in Salem Public Schools and opposed voucher proposals. The Healey-Driscoll administration has opposed school voucher and education savings account proposals, consistent with the Democratic Party's strong public education stance and Massachusetts's charter school cap policy.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.nbcboston.com/news/local/dem-delegates-endorse-healey-qualify-chang-diaz-for-ballot/2739254/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Driscoll and the Healey administration have expressed concern about the economic impact of broad tariffs on Massachusetts businesses, particularly in the tech, biotech, and higher education sectors. As a former mayor who managed a city economy reliant on commerce and tourism, Driscoll has opposed broad protectionist tariffs that harm consumers and businesses. The Healey administration has joined other Democratic governors opposing sweeping federal tariff policies.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.mass.gov/orgs/office-of-the-governor']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Driscoll supported the Healey administration's tax relief legislation signed in 2023, which cut taxes for families, renters, and businesses while maintaining investment in public services. As Salem Mayor she managed property taxes prudently, avoiding large tax increases while funding city services. The Healey-Driscoll administration's tax approach — targeted relief for working families plus millionaires' surtax revenue for education and transportation — reflects Driscoll's balanced tax philosophy.$$,
        ARRAY['https://www.mass.gov/news/governor-healey-signs-tax-relief-bill', 'https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Driscoll and the Healey-Driscoll administration have consistently supported transgender athletes' right to participate in sports consistent with their gender identity. Massachusetts's existing state anti-discrimination law (Chapter 272) covers gender identity in public accommodations including sports. The administration has opposed federal efforts to ban transgender athletes and has reaffirmed Massachusetts's commitment to LGBTQ+ non-discrimination.$$,
        ARRAY['https://www.mass.gov/executive-orders/no-627-reaffirming-the-commonwealths-commitment-to-civil-rights', 'https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Driscoll has been a strong public transportation advocate throughout her career. As Salem Mayor she secured a $2.1 million federal grant for the Salem-Boston commuter ferry and oversaw the 2014 MBTA Salem station ribbon-cutting. She championed transit-oriented development near the Salem commuter rail station. The Healey-Driscoll administration has prioritized MBTA investment and supported expanded multimodal transportation funding.$$,
        ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll', 'https://www.mass.gov/info-details/mbta-communities-act']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kim Driscoll / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e687c089-f00d-464c-aa37-3b021a3aba2c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Driscoll has supported expanded voting access throughout her career. The Healey-Driscoll administration has maintained Massachusetts's vote-by-mail and early voting expansions enacted during COVID and supported legislation to make them permanent. Driscoll has advocated for automatic voter registration and opposed voter ID laws that disenfranchise voters. As Salem Mayor she ensured city polling places were accessible and convenient.$$,
        ARRAY['https://www.wbur.org/news/2022/09/06/2022-massachusetts-democratic-lieutenant-governor-primary-result', 'https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
