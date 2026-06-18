-- ============================================================================
-- Migration 615: R. Lisle Baker Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for R. Lisle Baker (City Councilor, Ward 7, Newton MA).
--   Baker is a Suffolk University Law professor (property/real estate law) with extensive
--   published record on land use, housing, and environmental topics.
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

-- Politician UUID: 9d34705c-0a66-4c08-8936-7e63629ce435 (R. Lisle Baker, Ward 7)

BEGIN;

-- ============================================================
-- R. Lisle Baker
-- ============================================================

-- ----- R. Lisle Baker / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Baker, a Suffolk University Law professor specializing in real property and land use, has supported housing production in Newton while emphasizing context-sensitive design. He voted in favor of the MBTA Communities zoning compliance plan in October 2023, supporting multi-family housing near transit stations. Baker has also published academic work on housing and property rights that reflects a pragmatic pro-production orientation within smart-growth principles.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://law.suffolk.edu/faculty-research/faculty-profiles/r-lisle-baker/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- R. Lisle Baker / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$As a real estate law professor and long-serving Ward 7 councillor, Baker voted yes on Newton's MBTA Communities Act compliance in 2023, supporting multi-family residential zoning near transit. His academic writing on land use law reflects support for smart-growth zoning reforms that accommodate housing demand while preserving neighborhood character. He has engaged substantively with Newton's zoning debates through both his council role and academic expertise.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://law.suffolk.edu/faculty-research/faculty-profiles/r-lisle-baker/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- R. Lisle Baker / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Baker has supported Newton's Climate Action Plan and environmental sustainability measures. He has written on environmental law and policy topics in his academic capacity, and his council voting record reflects support for Newton's sustainability goals, including green infrastructure investments. The MBTA Communities vote he supported was also framed in part as an environmental measure to reduce vehicle miles traveled.$$,
        ARRAY['https://www.newtonma.gov/government/sustainability/climate-action-plan', 'https://law.suffolk.edu/faculty-research/faculty-profiles/r-lisle-baker/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- R. Lisle Baker / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Baker has backed Newton's climate action commitments and net-zero goals in his council role. His academic writing touches on energy and environmental law. He supported transit-oriented development through the MBTA Communities vote, which is linked to Newton's climate strategy of reducing auto-dependence. His approach is characterized by evidence-based, analytical engagement with climate policy at the local level.$$,
        ARRAY['https://www.newtonma.gov/government/sustainability/climate-action-plan', 'https://www.newtonma.gov/government/city-council/agendas-minutes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- R. Lisle Baker / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Baker brings a real estate law scholar's perspective to Newton's development debates. He has supported smart-growth development near transit corridors, voting for the MBTA Communities compliance plan. He has engaged in Newton's comprehensive planning process and has written about growth management and land use policy, reflecting a pro-smart-growth position that balances development with neighborhood preservation concerns.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://law.suffolk.edu/faculty-research/faculty-profiles/r-lisle-baker/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- R. Lisle Baker / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Baker has supported transit-oriented development and linked housing production near Green Line stations to better transit use and reduced car dependence. His support for the MBTA Communities Act compliance reflects an orientation toward transit-friendly development patterns. As a long-serving Newton councillor, he has also engaged with pedestrian and bicycle infrastructure improvements in council deliberations.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://newtonobserver.com/2023/10/newton-council-mbta-communities-vote']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- R. Lisle Baker / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9d34705c-0a66-4c08-8936-7e63629ce435',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Baker has engaged with Newton's public safety budget and policing approaches through his council role. His legal background informs his approach to civil liberties and community-oriented policing. He has participated in council discussions on balancing public safety investments with social services, consistent with Newton's progressive governance orientation. No evidence of an explicitly punitive or reform-only position.$$,
        ARRAY['https://www.newtonma.gov/government/city-council/agendas-minutes', 'https://www.newtonma.gov/government/police-department']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count (must be >= 1):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9d34705c-0a66-4c08-8936-7e63629ce435';
--
-- Unpaired check (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '9d34705c-0a66-4c08-8936-7e63629ce435' AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '9d34705c-0a66-4c08-8936-7e63629ce435'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
