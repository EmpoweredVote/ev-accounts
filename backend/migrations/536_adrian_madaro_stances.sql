-- ============================================================================
-- Migration 536: Adrian C. Madaro Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Adrian C. Madaro (MA State Rep,
--          1st Suffolk District, HD-121, external_id=-210161).
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

BEGIN;

-- Adrian C. Madaro (HD-121, external_id=-210161, id=290ee018-6e9e-4a8c-9561-385cf5ef3d73) --

-- ----- Adrian C. Madaro / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Madaro co-sponsored H.1239 (An Act establishing Medicare for all in Massachusetts), supporting universal single-payer healthcare coverage for all residents. He has also sponsored H.1600 (mental health parity) and H.1724 (behavioral health workforce development). As Chair of the Joint Committee on Mental Health, Substance Use and Recovery, he has championed expanding mental health access as a core healthcare priority.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1239', 'https://malegislature.gov/Bills/194/H1724', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Madaro co-sponsored H.3369 (An Act relative to the Safe Communities Act), which restricts local law enforcement cooperation with ICE and prohibits police from inquiring about immigration status. He has been a leading immigrant rights advocate in the Legislature, representing East Boston — one of the most immigrant-dense communities in Massachusetts. He has spoken publicly for sanctuary policies and immigrant integration services.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Madaro co-sponsored H.3369 (Safe Communities Act), preventing local police from enforcing federal immigration law or sharing resident information with ICE. His district includes East Boston's large immigrant population from Central America and beyond; he has consistently advocated for local immigrant protection policies including access to city services regardless of status.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Madaro is a lead co-sponsor of the Safe Communities Act (H.3369), which limits state and local cooperation with federal deportation actions. He has vocally opposed ICE raids in East Boston and publicly advocated for ending deportations of long-term residents with community ties. His record consistently supports halting deportations beyond violent criminal convictions and creating legal pathways for undocumented residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Madaro co-sponsored H.2983 (100% Clean Energy by 2045) and the 2021 Climate Act amendments requiring net-zero emissions. He is a consistent advocate for environmental justice in East Boston, which faces elevated climate risks from Logan Airport flight paths, highway pollution, and coastal flooding. His co-sponsorship of environmental justice legislation (H.4264) links climate action to equity for communities of color.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2983', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Madaro co-sponsored 100% Clean Energy legislation (H.2983) and environmental justice bills that call for reducing fossil fuel infrastructure. He represents East Boston, which hosts a significant jet fuel facility at Logan Airport, creating local community tension with fossil fuel infrastructure. His environmental justice work demonstrates strong support for phasing out fossil fuels through an equity lens.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2983', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Madaro authored and championed the Massachusetts Environmental Justice Policy Act (H.4264/S.2820), signed into law in 2021, which requires state agencies to consider disproportionate environmental burdens on low-income communities of color. East Boston — his district — is a designated Environmental Justice community facing air quality impacts from Logan Airport, the highway system, and industrial facilities. He has been the Legislature's leading voice on environmental justice.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Madaro co-sponsored H.2093 (An Act relative to justice, equity and outcomes for youth) and the Safe Communities Act (H.3369). As a Dominican-American representing a majority-immigrant district, he has been a consistent voice for civil rights protections for immigrants, people of color, and LGBTQ+ residents. He supported the Healthy Youth Act (LGBTQ+ inclusive sex education) and immigration reform measures.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Madaro co-sponsored H.1318 (An Act to strengthen emergency housing assistance) and has advocated for affordable housing production for East Boston's working-class immigrant community. He supported the Affordable Homes Act provisions while focusing on anti-displacement protections for existing residents. His housing approach prioritizes tenant stability and affordable production over market-rate development.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1318', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Madaro co-sponsored H.1795 (An Act establishing a moratorium on new prison and jail construction), redirecting incarceration spending to community health, housing, and addiction services. As Chair of the Joint Committee on Mental Health, Substance Use and Recovery, he has consistently supported diversion programs over incarceration for substance use and mental health-related offenses.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1795', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Madaro co-sponsored H.1239 (Medicare for All in Massachusetts), which would expand Medicaid/Medicare to all residents. He has also supported expanding MassHealth (MA Medicaid) benefits and opposed cuts to safety-net programs. His focus on healthcare access for immigrant communities — who rely heavily on state Medicaid — demonstrates strong support for expanding and protecting these programs.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1239', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Madaro co-sponsored the ROE Act (H.3320), which expanded abortion access in Massachusetts including removing the 24-week limit with broad exceptions and expanding access for minors. He voted for the 2020 ROE Act. As a progressive representative from East Boston, he has maintained consistent support for comprehensive reproductive rights access.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Madaro co-sponsored the Healthy Youth Act (H.410), which mandates LGBTQ+-inclusive sex education in public schools. He has been a consistent supporter of LGBTQ+ civil rights throughout his tenure and represents a district that includes LGBTQ+ residents and advocacy organizations. His overall civil rights record demonstrates full support for same-sex marriage and equality.$$,
        ARRAY['https://malegislature.gov/Bills/194/H410', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Madaro sponsored H.3799 (An Act relative to public transit access in environmental justice communities) and H.2746 (MBTA modernization). East Boston relies heavily on the Blue Line, Silver Line, and water ferry with limited highway access — he has consistently advocated for transit investment over highway expansion. He supported fare-free transit pilot programs and opposed toll increases on the Sumner/Callahan tunnels that burden East Boston residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3799', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Madaro voted for the 2020 Police Reform Act (H.4835), which established civilian oversight, restricted no-knock warrants, and limited qualified immunity for officers. As Chair of the Mental Health committee, he has advocated for expanding community-based crisis response as an alternative to police for mental health calls. His approach combines accountability reforms with investment in non-police public safety alternatives.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Madaro sponsored H.1318 (emergency housing assistance) and has consistently advocated for expanded shelter and services for unhoused residents. As Chair of the Mental Health, Substance Use and Recovery committee, he has championed harm reduction and overdose prevention services, which are closely linked to homelessness response. He supported right-to-shelter protections for families and expanded state investment in transitional housing.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1318', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrian C. Madaro / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('290ee018-6e9e-4a8c-9561-385cf5ef3d73',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Madaro co-sponsored H.3044 (An Act fully funding public higher education — the Cherish Act), reflecting strong commitment to public education institutions. He has opposed voucher-based diversion of public education funds and supported increased Chapter 70 funding for public schools in his district, including BPS East Boston schools. No evidence of any support for vouchers or private school funding mechanisms.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3044', 'https://malegislature.gov/Legislators/Profile/ACM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '290ee018-6e9e-4a8c-9561-385cf5ef3d73';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '290ee018-6e9e-4a8c-9561-385cf5ef3d73'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '290ee018-6e9e-4a8c-9561-385cf5ef3d73'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
