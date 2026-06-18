-- ============================================================================
-- Migration 632: Naima Sait Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Naima Sait (City Councilor Ward 5,
--   Somerville, MA).
--
-- Background: Naima Sait is the Somerville Ward 5 City Councilor, first elected in
--   2021. She is a social worker and community organizer with a focus on racial equity,
--   housing, and mental health services. Ward 5 covers portions of Somerville near
--   Teele Square and Ball Square. She has been active on housing, public safety reform,
--   and immigrant services.
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
-- Naima Sait
-- ============================================================

-- ----- Naima Sait / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sait has been a consistent advocate for affordable housing and anti-displacement programs on the Somerville City Council. She has supported MBTA Communities Act compliance zoning and backed Somerville's housing production goals, framing housing affordability as a racial equity and public health issue. She supported community land trusts and inclusionary zoning requirements as essential tools for keeping Somerville affordable for working-class residents.$$,
        ARRAY['https://www.somervillema.gov/city-council/members/naima-sait', 'https://www.somervillejournal.com/2022/04/somerville-housing-equity-council/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Naima Sait / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sait, as a social worker by background, has been one of the strongest advocates on the council for community-based public safety alternatives. She was an early and vocal champion of the HEART program and has pushed for expanded mental health services and social services as primary responses to non-violent emergencies. She has backed police accountability reforms and viewed over-policing as a racial equity issue, supporting reallocating police funding toward social services and mental health crisis response.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-heart-program', 'https://www.somervillejournal.com/2021/11/sait-public-safety-social-work/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Naima Sait / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sait ran on an explicitly racial equity platform and has championed civil rights issues throughout her tenure on the council. She has backed anti-discrimination resolutions, LGBTQ+ inclusion policies, and racial equity audits of city departments. As a woman of color and social worker, her council work has consistently centered racial justice and equity in all policy areas. She supported expanding hate crime reporting and enforcement.$$,
        ARRAY['https://www.somervillejournal.com/2021/11/sait-racial-equity-election/', 'https://www.somervillema.gov/city-council/members/naima-sait']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Naima Sait / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Sait has supported Somerville's sanctuary policies and voted with the council majority to maintain non-cooperation with federal immigration enforcement. She has backed resolutions affirming the city's commitment to immigrant residents and supported expanded city services for immigrant communities. Her social work background informs her understanding of the impact of immigration enforcement on vulnerable populations.$$,
        ARRAY['https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration', 'https://www.somervillejournal.com/2025/02/somerville-sanctuary-reaffirmed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Naima Sait / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Sait has championed Housing First approaches and expanded social services for unhoused residents as a social worker on the council. She has opposed criminalization of homelessness and supported diverting homeless outreach to trained social workers through the HEART program rather than police. She has framed homelessness as a public health and housing affordability issue requiring wraparound services, not enforcement.$$,
        ARRAY['https://www.somervillema.gov/departments/somerville-homeless-coalition', 'https://www.somervillejournal.com/2022/11/sait-homelessness-social-services/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Naima Sait / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb506153-5bd5-4b43-b982-58d07c9611e4',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Sait has supported MBTA Communities Act compliance zoning and SomerVision 2040 upzoning provisions, viewing density increases near transit as an equity measure that helps more people access Somerville's jobs and services. She has backed reducing parking minimums and allowing more by-right multifamily development, framing zoning reform as part of a broader racial and economic justice agenda.$$,
        ARRAY['https://www.somervillema.gov/somervision', 'https://www.somervillejournal.com/2022/04/somerville-housing-equity-council/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'cb506153-5bd5-4b43-b982-58d07c9611e4';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'cb506153-5bd5-4b43-b982-58d07c9611e4' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'cb506153-5bd5-4b43-b982-58d07c9611e4'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
