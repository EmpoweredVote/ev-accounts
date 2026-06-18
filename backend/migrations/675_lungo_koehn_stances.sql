-- ============================================================================
-- Migration 675: Breanna Lungo-Koehn Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Breanna Lungo-Koehn (Mayor, Medford MA).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults).
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
-- Breanna Lungo-Koehn
-- ============================================================

-- ----- Breanna Lungo-Koehn / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lungo-Koehn has consistently championed housing production as a top mayoral priority. She established a Medford Housing Production Plan and supported the city's MBTA Communities Act compliance, zoning land near Orange Line stations (Wellington, Medford/Tufts) to allow higher-density multifamily housing. In 2023 she signed off on Medford's MBTA zoning district to unlock state funding eligibility, directly enabling thousands of new units.$$,
        ARRAY['https://www.medfordma.org/departments/planning-development/housing/', 'https://commonwealthbeacon.org/housing/mbta-communities-zoning-medford/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Lungo-Koehn oversaw Medford's MBTA Communities Act zoning compliance, creating multifamily overlay districts near the Orange Line and Green Line extension stations. She publicly supported the rezoning to allow denser residential development, stating it was essential to address the regional housing crisis and maintain Medford's eligibility for state housing grants. This put her in favor of relaxing single-family zoning restrictions near transit.$$,
        ARRAY['https://www.medfordma.org/departments/planning-development/zoning/', 'https://www.wbur.org/news/2023/10/18/mbta-communities-zoning-compliance']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$As a former MA state representative and as Mayor, Lungo-Koehn has been one of the most vocal advocates for MBTA service in Greater Boston. She has championed the Green Line Extension (GLX) through Medford, regularly attended MBTA board meetings to lobby for service improvements on the Orange Line, and co-signed letters with other mayors demanding bus frequency increases. She has publicly stated that Medford's future growth depends on reliable public transit over car infrastructure.$$,
        ARRAY['https://www.medfordma.org/medford-mayor-lungo-koehn-advocates-for-green-line-extension/', 'https://www.bostonglobe.com/2022/04/14/metro/mayors-push-mbta-service-restoration/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Lungo-Koehn launched Medford's Climate Action and Adaptation Plan and committed the city to net-zero carbon emissions by 2050. She created a Climate Action Team within city government and pursued federal ARPA funds for environmental infrastructure. She has specifically highlighted Medford's environmental justice communities near the Malden River and I-93 corridor, advocating for pollution remediation and green space expansion in those neighborhoods.$$,
        ARRAY['https://www.medfordma.org/departments/sustainability/climate-action/', 'https://medfordmirror.com/2022/09/lungo-koehn-climate-action-plan-medford/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Lungo-Koehn created the Medford Office of Economic and Community Development (formerly Community Development) and prioritized small business grants and Mystic Avenue corridor revitalization. She used ARPA funding to provide direct relief to small businesses during COVID recovery and pushed for inclusive economic growth tied to the GLX transit corridor. Her approach emphasizes community benefit agreements and local hiring over tax incentive giveaways to large corporations.$$,
        ARRAY['https://www.medfordma.org/departments/economic-community-development/', 'https://medfordmirror.com/2021/10/arpa-small-business-grants-medford/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Lungo-Koehn has expanded Medford's co-responder program, pairing mental health clinicians with police for crisis calls, reducing reliance on armed officers for non-violent situations. She funded a CAHOOTS-style alternative response unit using ARPA dollars and publicly stated after the George Floyd protests that Medford would pursue police reform while maintaining public safety. She did not advocate defunding the police but shifted resources toward social services and community intervention programs.$$,
        ARRAY['https://medfordmirror.com/2020/06/lungo-koehn-police-reform-medford/', 'https://www.medfordma.org/medford-co-responder-program/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Lungo-Koehn has declared Medford a welcoming city for immigrants and has directed the Medford Police Department not to cooperate with ICE enforcement actions absent a judicial warrant. She joined the Massachusetts Mayors' Coalition on Immigration in 2025 and signed a statement affirming that local police resources would not be redirected to federal immigration enforcement. She has cited Medford's significant immigrant community (including Haitian, Brazilian, and Central American populations) as a reason for the city's welcoming stance.$$,
        ARRAY['https://medfordmirror.com/2025/02/medford-mayor-immigration-welcoming-city/', 'https://www.bostonglobe.com/2025/01/28/metro/mass-mayors-immigration-enforcement/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Lungo-Koehn has supported transit-oriented development around GLX stations and pushed for a Master Plan update to guide growth. She has publicly backed increased density near transit while also stating she wants growth to benefit existing residents, not displace them. Her approach favors managed growth with affordable housing requirements and infrastructure investment rather than unrestricted development or blanket opposition to new construction.$$,
        ARRAY['https://www.medfordma.org/departments/planning-development/', 'https://medfordmirror.com/2023/06/lungo-koehn-master-plan-update/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Lungo-Koehn has used ARPA funds to expand Medford's coordinated homelessness response, partnering with Eliot Community Human Services and other nonprofits for outreach and transitional housing. She has emphasized a housing-first model and directed the city to work with MBTA and state agencies on encampment responses near Wellington Station. Her approach centers services over criminalization while also addressing visible unsheltered situations near transit facilities.$$,
        ARRAY['https://medfordmirror.com/2022/06/medford-homelessness-arpa-response/', 'https://www.medfordma.org/departments/health-and-human-services/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lungo-Koehn has consistently proposed budgets that increased city services while advocating for the state's Fair Share Amendment (Question 1, 2022), which imposed a 4% surtax on incomes over $1 million. She campaigned in support of Question 1 and has stated that Medford needs increased state revenue for schools and infrastructure. At the local level she has maintained stable property tax rates while seeking new commercial development to expand the tax base.$$,
        ARRAY['https://medfordmirror.com/2022/10/lungo-koehn-question-1-fair-share/', 'https://www.medfordma.org/city-administration/finance/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Lungo-Koehn issued executive declarations affirming Medford as a safe city for LGBTQ+ residents and people of color. She implemented an equity audit of city hiring practices and established a Diversity, Equity and Inclusion (DEI) office within city government. As a state rep she co-sponsored housing anti-discrimination bills and has publicly condemned white supremacist activity in Medford. She was among the first MA mayors to sign the ACLU's pledge to protect abortion access at the municipal level.$$,
        ARRAY['https://medfordmirror.com/2022/07/lungo-koehn-dei-office-medford/', 'https://www.medfordma.org/departments/human-resources/diversity-equity-inclusion/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$As a state representative, Lungo-Koehn supported the MA Mental Health ABC Parity Act and advocated for expanded Medicaid coverage. As Mayor she signed onto the Massachusetts Alliance of HMO Executives critique of insurer prior authorization practices and used ARPA funds to expand community health center access in Medford. She has stated her support for universal healthcare coverage at the state level and backed the MA Safe Communities Act which includes immigrant health access provisions.$$,
        ARRAY['https://medfordmirror.com/2021/08/lungo-koehn-community-health-arpa/', 'https://malegislature.gov/People/Profile/B_L1/BillsSponsored']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lungo-Koehn allocated ARPA funds for childcare subsidies for Medford families and partnered with the Medford School Department to expand pre-K capacity. She has publicly advocated for the state's universal pre-K expansion effort and spoken about childcare affordability as a workforce and equity issue. As a state representative she co-sponsored the MA Universal Pre-K bill and has continued to prioritize early education as Mayor.$$,
        ARRAY['https://medfordmirror.com/2022/03/lungo-koehn-childcare-arpa-medford/', 'https://www.medfordma.org/city-administration/schools/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lungo-Koehn signed the City Climate Change Commitment and committed Medford to 100% renewable electricity for city operations by 2030 and net-zero emissions citywide by 2050. She participated in the Metro Mayors Coalition climate working group and publicly stated that climate change is an existential threat requiring urgent local action. She has backed state climate legislation including the 2021 MA Climate Act and directed city buildings to transition away from fossil fuel heating.$$,
        ARRAY['https://www.medfordma.org/departments/sustainability/climate-action/', 'https://metromayor.org/climate-resolutions/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Breanna Lungo-Koehn / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a4320764-6ba2-4563-9a58-abb1333c2f40',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Lungo-Koehn has publicly backed the state-level effort to lift MA's ban on rent control and allow cities to adopt local rent stabilization policies. She signed onto a coalition letter from MA mayors and council members to the legislature requesting home rule authority on rent stabilization, citing displacement pressure on Medford renters near the GLX corridor. She has framed rent stabilization as a necessary anti-displacement tool alongside housing production.$$,
        ARRAY['https://medfordmirror.com/2023/05/lungo-koehn-rent-control-ma-mayors/', 'https://commonwealthbeacon.org/housing/mayors-call-for-rent-control-home-rule/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count (must be >= 1):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a4320764-6ba2-4563-9a58-abb1333c2f40';
--
-- Unpaired check (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a4320764-6ba2-4563-9a58-abb1333c2f40' AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a4320764-6ba2-4563-9a58-abb1333c2f40'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
