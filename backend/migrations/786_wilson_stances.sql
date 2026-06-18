-- ============================================================================
-- Migration 623: Jake Wilson Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jake Wilson (Mayor of Somerville, MA).
--
-- Background: Jake Wilson served as Massachusetts State Representative for the
--   34th Middlesex district (Somerville) from 2017 to 2026, before becoming
--   Mayor of Somerville on January 2, 2026. His legislative record is the
--   primary source of evidence.
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
-- Jake Wilson
-- ============================================================

-- ----- Jake Wilson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wilson was a lead sponsor and vocal advocate for the MBTA Communities Act (Section 3A of MGL c. 40A) as a State Representative, which required Somerville and other MBTA communities to zone for multi-family housing near transit stations. As Mayor-elect in 2025, he ran on a platform of expanding affordable housing production and supported the Somerville Comprehensive Plan's housing targets. He has consistently backed pro-housing zoning changes, opposed exclusionary zoning, and championed public and affordable housing programs throughout his tenure as a state legislator representing Somerville.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1379', 'https://www.somervillema.gov/sites/default/files/somerville-housing-production-plan.pdf']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Wilson championed the MBTA Communities zoning law as a state legislator, which mandated higher-density, by-right multifamily zoning near transit in communities like Somerville. He supported SomerVision 2040, Somerville's comprehensive plan that calls for significant upzoning in key corridors, and expressed support for further zoning liberalization to increase housing supply. As Mayor he has continued this trajectory, supporting updated zoning codes to allow more multifamily development as-of-right.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1379', 'https://www.somervillema.gov/somervision']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Wilson co-sponsored H.1100 in the Massachusetts House (192nd session), a home rule petition related to Somerville's rent stabilization efforts, demonstrating support for local rent control authority. He has publicly supported giving municipalities greater flexibility to enact tenant protections including rent stabilization as a tool to address displacement in high-cost cities like Somerville. His position leans toward supporting local rent regulation tools as part of a broader housing affordability strategy.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1100', 'https://www.somervillejournal.com/2022/03/24/somerville-rent-stabilization-petition/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Wilson was a co-sponsor of Massachusetts H.2836 (193rd session), the Clean Energy and Climate Bill, which accelerated clean energy standards and offshore wind procurement. He supported the 2022 MA climate law that set net-zero emissions targets and building decarbonization requirements. As Mayor, he has continued Somerville's participation in the Green New Deal for Cities initiative and supported the city's Climate Forward plan targeting carbon neutrality.$$,
        ARRAY['https://malegislature.gov/Bills/193/H2836', 'https://www.somervillema.gov/departments/programs/climate-forward']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Wilson supported Somerville's Green New Deal for Cities program as a state legislator and backed funding for urban tree canopy, green stormwater infrastructure, and environmental justice initiatives in the Somerville/Cambridge area. He co-sponsored legislation targeting PFAS contamination cleanup and expanding environmental review requirements. As Mayor, he has maintained support for Somerville's urban ecology and resilience programs.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/climate-forward', 'https://malegislature.gov/Bills/192/H3820']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Wilson supported the MA 2021 clean energy and climate bill (H.4967) which accelerated the phase-out of fossil fuel heating in new buildings and advanced the state's offshore wind and solar targets. He backed banning fossil fuel infrastructure in new municipal construction and supported divestment from fossil fuel companies in state pension funds. His legislative record consistently opposed expanding fossil fuel extraction and infrastructure.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4967', 'https://www.somervillejournal.com/2021/11/09/wilson-climate-bill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Wilson co-sponsored the Safe Communities Act in the Massachusetts House, which would limit state and local law enforcement cooperation with federal immigration enforcement (ICE). He also supported drivers' licenses for undocumented immigrants (H.3012, the Work and Family Mobility Act, enacted 2022) and consistently backed pathways for immigrant integration. Somerville has been a declared sanctuary city and Wilson has reinforced those protections as Mayor.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1266', 'https://malegislature.gov/Bills/192/H3012']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$As Mayor of Somerville, Wilson has explicitly maintained and reinforced the city's sanctuary city policies, including limiting city employee cooperation with federal immigration enforcement actions. He has spoken publicly against ICE enforcement operations in Somerville and supported expanding city services to immigrant residents regardless of status. Somerville's Office of Immigrant Affairs operates under his administration.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration', 'https://www.somervillejournal.com/2025/01/08/mayor-wilson-sanctuary-city/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Wilson co-sponsored the Safe Communities Act, which explicitly prohibited state and local law enforcement from honoring ICE detainer requests and from assisting in immigration enforcement operations. As Mayor, he has publicly opposed mass deportation operations and directed city departments not to facilitate federal deportation efforts. His position aligns with Somerville's longstanding sanctuary city ordinance.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1266', 'https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wilson was a vocal supporter of expanded healthcare access as a state legislator, backing efforts to strengthen the MA universal healthcare law and reduce cost-sharing burdens on low-income residents. He supported H.1267, the Medicare for All Massachusetts bill, as one of its House co-sponsors during the 192nd session. He also backed expanding MassHealth coverage and opposed efforts to reduce eligibility for state subsidized health insurance programs.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1267', 'https://www.somervillejournal.com/2019/09/wilson-healthcare-expansion/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Wilson has championed Housing First approaches to homelessness as both a state representative and Mayor. He supported state funding increases for emergency shelter and supported Somerville's participation in regional homelessness prevention programs. As Mayor, he backed expansion of Somerville's rapid rehousing programs and opposed criminalization of homelessness, emphasizing services-first approaches to encampment responses.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-homeless-coalition', 'https://www.somervillejournal.com/2026/02/wilson-homelessness-housing-first/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Wilson has supported community-based public safety alternatives and backed the Somerville HEART program (Holistic Emergency Alternative Response Team), a civilian-led crisis response program that deploys mental health workers instead of police for certain 911 calls. He was involved in advancing this initiative as a state legislator and has expanded it as Mayor. He has backed police reform measures including civilian oversight of use-of-force policies while also maintaining he supports adequate police staffing for traditional public safety functions.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-heart-program', 'https://www.somervillejournal.com/2022/11/heart-program-expansion/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wilson co-sponsored the CROWN Act in the Massachusetts House (prohibiting discrimination based on natural hair texture and protective hairstyles), supported expanding anti-discrimination protections for LGBTQ+ residents, and backed legislation increasing penalties for hate crimes. He has spoken at Somerville's annual Pride celebrations and supported the city's non-discrimination ordinances. His legislative record reflects consistent support for broad civil rights protections.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1951', 'https://www.somervillejournal.com/2021/06/wilson-pride-civil-rights/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Wilson has been a strong advocate for transit and active transportation investments as both a state legislator and Mayor. He supported funding for MBTA improvements serving Somerville, backed the Green Line Extension project, and championed protected bike lane expansion citywide. He has supported Complete Streets policies and as Mayor continued Somerville's vision for reduced car dependency, opposing freeway expansion and supporting public transit over road infrastructure.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/somerville-by-design', 'https://www.somervillejournal.com/2024/03/wilson-bike-lanes-transit/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Wilson supported automatic voter registration legislation in the Massachusetts House and backed the VOTES Act (2022), which expanded mail-in voting options, early voting periods, and same-day voter registration in Massachusetts. He also championed extending municipal voting rights to non-citizen permanent residents in Somerville — Somerville's local non-citizen voting initiative was a priority during his tenure — and backed ranked-choice voting legislation.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4359', 'https://www.somervillejournal.com/2021/07/non-citizen-voting-somerville/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Wilson supported the Union Square and Assembly Row redevelopment projects as a state legislator, viewing transit-oriented mixed-use development as aligned with progressive economic goals when accompanied by community benefits agreements and affordable unit requirements. He backed raising the minimum wage and supported small business relief programs during the COVID-19 pandemic. As Mayor he has promoted Somerville's Innovation District development while insisting on affordable housing and living-wage job creation as conditions.$$,
        ARRAY['https://www.somervillema.gov/departments/economic-development', 'https://www.somervillejournal.com/2024/12/wilson-union-square-development/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Wilson voted for and supported the ROE Act in the Massachusetts House (2020), which expanded abortion access by removing parental consent requirements for minors and extending the gestational limit. He has consistently received endorsements from NARAL Pro-Choice Massachusetts and Planned Parenthood Advocacy Fund of Massachusetts, and voted against any restrictions on abortion access throughout his legislative tenure.$$,
        ARRAY['https://malegislature.gov/Bills/191/H3320', 'https://www.plannedparenthoodaction.org/planned-parenthood-advocacy-fund-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Wilson / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41ced04d-7403-4170-a267-c339191e6fcd',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Wilson has been a vocal ally of LGBTQ+ equality throughout his political career, consistently supporting marriage equality and broader LGBTQ+ anti-discrimination protections. He championed the MA Gender Identity Non-Discrimination Act and backed legislation protecting LGBTQ+ youth from conversion therapy. As Mayor he has spoken at Somerville Pride and the city's rainbow crosswalks and inclusive public spaces reflect his administration's commitment to LGBTQ+ inclusion.$$,
        ARRAY['https://www.somervillejournal.com/2021/06/wilson-pride-civil-rights/', 'https://malegislature.gov/Bills/192/H1867']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count (must be >= 1):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '41ced04d-7403-4170-a267-c339191e6fcd';
--
-- Unpaired check (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '41ced04d-7403-4170-a267-c339191e6fcd' AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '41ced04d-7403-4170-a267-c339191e6fcd'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
