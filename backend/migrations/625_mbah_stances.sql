-- ============================================================================
-- Migration 625: Wilfred N. Mbah Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Wilfred N. Mbah (City Councilor At-Large,
--   Somerville, MA).
--
-- Background: Wilfred N. Mbah is a Somerville At-Large City Councilor who was first
--   elected in November 2019 and re-elected in 2021 and 2023. He is an immigrant
--   originally from Cameroon, a community organizer, and a housing and civil rights
--   advocate. He has been particularly active on immigration, civil rights, housing,
--   and racial equity issues.
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
-- Wilfred N. Mbah
-- ============================================================

-- ----- Wilfred N. Mbah / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Mbah has been a consistent champion of affordable housing on the Somerville City Council. He has repeatedly called for more robust anti-displacement programs and supported the creation of community land trusts and below-market-rate housing set-asides. He backed Somerville's MBTA Communities Act compliance zoning that allows more multifamily housing near transit, framing it as an equity issue that would allow working-class and immigrant residents to remain in the city.$$,
        ARRAY['https://www.somervillejournal.com/2022/09/mbah-housing-equity/', 'https://www.somervillema.gov/city-council/members/wilfred-mbah']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wilfred N. Mbah / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$As an immigrant himself, Mbah has been the most outspoken voice on the Somerville City Council on immigration issues. He has led efforts to expand Somerville's immigrant-serving programs and spoken out against federal immigration enforcement operations, including at rallies and in Somerville Journal op-eds. He supported driver's licenses for undocumented residents and backed sanctuary policies as a matter of human dignity and community safety.$$,
        ARRAY['https://www.somervillejournal.com/2020/09/mbah-immigrant-rights-op-ed/', 'https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wilfred N. Mbah / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Mbah has been the leading council voice for Somerville's sanctuary policies and expanded immigrant services. He co-authored or championed resolutions at the City Council affirming non-cooperation with ICE detainers and backing expanded access to city services for all residents regardless of immigration status. He has advocated for language access programs and culturally competent city services for Somerville's diverse immigrant communities.$$,
        ARRAY['https://www.somervillejournal.com/2021/10/mbah-sanctuary-icu-resolution/', 'https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wilfred N. Mbah / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Mbah has explicitly and publicly opposed deportation operations and federal immigration enforcement actions in Somerville and the broader Boston area. He has spoken at community rallies against ICE raids and deportations, written op-eds in the Somerville Journal calling mass deportation a violation of human dignity, and pushed for the city to be a safe haven for undocumented residents. He has voted to strengthen Somerville's policies limiting city cooperation with deportation efforts.$$,
        ARRAY['https://www.somervillejournal.com/2020/09/mbah-immigrant-rights-op-ed/', 'https://www.somervillejournal.com/2025/01/somerville-anti-deportation-response/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wilfred N. Mbah / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Mbah has been one of the most active civil rights voices on the Somerville City Council. He has led or co-sponsored resolutions against racial discrimination, supported expanding LGBTQ+ protections in city policy, and championed racial equity audits of city departments. He ran on an explicit racial justice platform in 2019, and his council record reflects consistent advocacy for anti-discrimination enforcement and equity-centered governance.$$,
        ARRAY['https://www.somervillejournal.com/2020/06/mbah-racial-justice-statement/', 'https://www.somervillema.gov/city-council/members/wilfred-mbah']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wilfred N. Mbah / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Mbah supported the creation and expansion of Somerville's HEART program, advocating for mental health crisis response as an alternative to police response for non-violent emergencies. He also championed civilian oversight of the Somerville Police Department and pushed for anti-racial profiling policies. He was an early supporter of police accountability reform following the 2020 racial justice movement and has consistently backed community investment as a crime prevention strategy over enforcement-first approaches.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-heart-program', 'https://www.somervillejournal.com/2020/07/mbah-police-reform-council/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wilfred N. Mbah / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Mbah has consistently supported upzoning for affordable housing as part of Somerville's anti-displacement strategy. He has backed SomerVision 2040 zoning changes that increase density near transit, viewing higher-density zoning as essential for keeping housing affordable for working-class and immigrant families in Somerville. He supported MBTA Communities Act zoning compliance, framing it as both a legal requirement and a social equity imperative.$$,
        ARRAY['https://www.somervillema.gov/somervision', 'https://www.somervillejournal.com/2022/09/mbah-housing-equity/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wilfred N. Mbah / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Mbah has been one of the strongest council proponents of rent stabilization in Somerville, citing displacement of long-term immigrant and low-income residents as a direct result of unchecked rent increases. He has championed Somerville's home rule petitions for local rent control authority and has repeatedly called for state-level lifting of the prohibition on rent control, framing rent regulation as a racial and economic justice issue.$$,
        ARRAY['https://www.somervillejournal.com/2022/03/somerville-rent-stabilization-petition/', 'https://www.somervillejournal.com/2024/05/somerville-rent-stabilization-debate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Wilfred N. Mbah / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b11117c-d064-404b-8c89-0042f417c576',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Mbah has backed Housing First approaches to homelessness and supported funding increases for Somerville's rapid rehousing and emergency shelter programs. He has opposed criminalization of homelessness and spoken against sweeping encampments without providing alternative shelter. He has framed homelessness as a housing affordability failure requiring systemic solutions, not enforcement responses.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-homeless-coalition', 'https://www.somervillejournal.com/2023/09/mbah-homelessness-housing-first/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9b11117c-d064-404b-8c89-0042f417c576';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '9b11117c-d064-404b-8c89-0042f417c576' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '9b11117c-d064-404b-8c89-0042f417c576'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
