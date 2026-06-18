-- ============================================================================
-- Migration 416: Christopher R. Flanagan Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Christopher R. Flanagan
--   (MA State Representative, 1st Barnstable District, HD-01).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, active as of 2026-06-11):
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

-- Politician UUID: 516feaaa-7086-4382-8cfa-9463f508dd74 (external_id: -210041)

BEGIN;

-- ----- Christopher R. Flanagan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Flanagan serves on the Joint Committee on Climate Action and Sustainability, reflecting a professional commitment to climate legislation. His 1st Barnstable District on Cape Cod is directly threatened by sea level rise and coastal erosion, giving him strong constituent motivation to back climate action. He has co-sponsored water infrastructure and coastal resilience legislation (H.944) addressing environmental challenges in his district. His committee assignment and district interests align with climate action as a legislative priority.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CRF1', 'https://malegislature.gov/Bills/194/H944']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher R. Flanagan / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Flanagan represents the 1st Barnstable District on Cape Cod, where local environmental protection of coastal water quality, ponds, bays, and the Cape Cod aquifer is a defining constituent concern. He co-sponsored H.944 (An Act relative to funding water infrastructure and addressing economic target areas), directly addressing local water quality and infrastructure. His seat on the Committee on Climate Action and Sustainability further demonstrates active engagement with environmental protection legislation at the state level.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CRF1', 'https://malegislature.gov/Bills/194/H944']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher R. Flanagan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Flanagan has filed multiple housing-related bills in the 194th session. H.101 (An Act establishing free broadband internet access in public housing) supports affordable housing residents. H.3164 (An Act to ensure fair taxation of affordable housing) addresses tax equity for affordable housing developments. H.3191 (An Act relative to condominiums) addresses condominium regulations. His Cape Cod district faces acute housing affordability challenges from vacation home demand and seasonal rentals displacing year-round residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H101', 'https://malegislature.gov/Bills/194/H3164', 'https://malegislature.gov/Bills/194/H3191']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher R. Flanagan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Flanagan has filed targeted tax relief bills including H.3163 (An Act to create an income tax deduction for municipal and school fees), H.3162 (An Act extending a property tax exemption to the surviving spouse of blind persons), and H.3164 (An Act to ensure fair taxation of affordable housing). These bills reflect a constituent-service-oriented approach to tax policy -- targeted relief for specific populations rather than broad structural reform. This moderate tax posture is consistent with his district's mix of working families and property-owning constituents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3163', 'https://malegislature.gov/Bills/194/H3162', 'https://malegislature.gov/Bills/194/H3164']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher R. Flanagan / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Flanagan sponsored H.2499 (An Act pertaining to women's health at midlife and public, medical and workplace awareness of the transitional stage of menopause and related chronic conditions), demonstrating an active interest in expanding healthcare access and awareness. He also sponsored H.2064 (An Act relative to bereavement leave for the loss of a child), supporting family health policy. These bills reflect a pro-access healthcare stance consistent with his Democratic affiliation and Cape Cod district's healthcare needs.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2499', 'https://malegislature.gov/Bills/194/H2064']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher R. Flanagan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Flanagan has sponsored both public safety protection bills and law enforcement support measures. H.2897 (An Act relative to public safety employee death benefits) supports law enforcement families. H.1840 (An Act to enhance safety and security in courthouses) and H.1839 (An Act relative to the penalty for disorderly persons) reflect a traditional public safety orientation. These bills indicate a moderate law-and-order approach rather than a reform-first posture, balanced with constituent safety concerns in his Cape Cod district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2897', 'https://malegislature.gov/Bills/194/H1840', 'https://malegislature.gov/Bills/194/H1839']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher R. Flanagan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Flanagan has been active on school transportation equity, filing H.513 (An Act requiring equitable funding for non-regional school districts with high transportation costs) and H.4011 (An Act eliminating predatory transportation pricing of school districts). These bills address transportation funding fairness for Cape Cod school districts that face higher transportation costs due to the region's geography. His engagement on transportation equity reflects constituent needs in a car-dependent, rural-suburban district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H513', 'https://malegislature.gov/Bills/194/H4011']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher R. Flanagan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('516feaaa-7086-4382-8cfa-9463f508dd74',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Flanagan sponsored H.101 (An Act establishing free broadband internet access in public housing), reflecting support for digital equity as an economic development tool. He co-sponsored H.944 (An Act relative to funding water infrastructure and addressing economic target areas), targeting economic development funding toward underserved communities. H.3382 (An Act promoting governmental efficiency) also reflects a cost-effective governance interest. These bills reflect a moderate pro-development stance focused on public investment and infrastructure.$$,
        ARRAY['https://malegislature.gov/Bills/194/H101', 'https://malegislature.gov/Bills/194/H944']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '516feaaa-7086-4382-8cfa-9463f508dd74';
--
-- Context pairing (must return 0 -- every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '516feaaa-7086-4382-8cfa-9463f508dd74'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 -- every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '516feaaa-7086-4382-8cfa-9463f508dd74'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
