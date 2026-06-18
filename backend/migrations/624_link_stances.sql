-- ============================================================================
-- Migration 624: Jon Link Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jon Link (City Councilor At-Large, Somerville, MA).
--
-- Background: Jon Link is a Somerville At-Large City Councilor who was first elected
--   in November 2023. He is a progressive community organizer and housing advocate.
--   His public record is primarily through council votes, statements at council meetings,
--   and local media coverage.
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
-- Jon Link
-- ============================================================

-- ----- Jon Link / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Jon Link ran for City Council on an explicitly pro-housing platform, calling for increased affordable housing production, tenant protections, and compliance with the MBTA Communities Act zoning requirements. He has voted in favor of housing production initiatives at the Somerville City Council and publicly supported expanding affordable units and anti-displacement programs citywide. His campaign materials and public statements consistently identify housing affordability as a top priority.$$,
        ARRAY['https://www.somervillejournal.com/2023/11/link-council-election/', 'https://www.somervillema.gov/city-council/members/jon-link']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Link / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Link has supported upzoning in Somerville, including backing SomerVision 2040 implementation measures and MBTA Communities Act compliance zoning changes that allow higher-density multifamily development near transit corridors. He has been a consistent voice for reducing parking minimums and allowing more by-right multifamily development to address the housing shortage, citing affordability and climate goals as motivation for denser zoning.$$,
        ARRAY['https://www.somervillema.gov/somervision', 'https://www.somervillejournal.com/2024/04/link-zoning-transit/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Link / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Link has publicly supported Somerville's efforts to pursue local rent stabilization authority, aligning with the majority of the progressive Somerville City Council on this issue. He has spoken at council meetings in favor of anti-displacement policies and tenant protections, including rent stabilization as one component. His public statements have framed rent regulation as a necessary complement to housing production to protect existing residents.$$,
        ARRAY['https://www.somervillejournal.com/2024/05/somerville-rent-stabilization-debate/', 'https://www.somervillema.gov/city-council/members/jon-link']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Link / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Link has supported Somerville's sanctuary city policies and voted with the council to maintain and strengthen the city's protections for immigrant residents. He has spoken in support of expanded city services for immigrant communities and backed resolutions affirming Somerville's commitment to not cooperating with federal immigration enforcement operations. His public statements have emphasized community safety and inclusion as reasons for these policies.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration', 'https://www.somervillejournal.com/2025/02/somerville-sanctuary-reaffirmed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Link / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Link has supported Somerville's HEART (Holistic Emergency Alternative Response Team) civilian crisis response program and backed expanding mental health services as a public safety alternative. He has expressed support for community-based violence prevention approaches and has backed civilian oversight of policing. His public safety stance emphasizes diverting calls that do not require police response to trained civilian responders while maintaining adequate traditional public safety capacity.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-heart-program', 'https://www.somervillejournal.com/2024/09/heart-expansion-council-vote/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Link / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Link has supported Somerville's Climate Forward plan and voted for environmental resolutions at the city council, including support for urban tree canopy preservation and green infrastructure investments. He has backed the city's composting and zero-waste programs and spoken in favor of environmental justice initiatives targeting heat island mitigation in lower-income Somerville neighborhoods. His council votes have consistently supported expanded environmental programs.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/climate-forward', 'https://www.somervillejournal.com/2024/07/somerville-climate-forward-council/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Link / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8242a03d-6801-4b91-aed9-918a603b4a21',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Link has been a vocal advocate for transit-first and active transportation policies in Somerville, supporting protected bike lanes, pedestrian safety infrastructure, and reduced parking requirements near transit corridors. He ran on a platform emphasizing walkable, bikeable neighborhood design and has voted to support Somerville's Complete Streets and Vision Zero policies. His positions align with reducing car dependency as a climate and quality-of-life priority.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/somerville-by-design', 'https://www.somervillejournal.com/2023/11/link-council-election/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8242a03d-6801-4b91-aed9-918a603b4a21';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '8242a03d-6801-4b91-aed9-918a603b4a21' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '8242a03d-6801-4b91-aed9-918a603b4a21'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
