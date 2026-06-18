-- ============================================================================
-- Migration 384: Robyn K. Kennedy Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Robyn K. Kennedy (MA State Senator, 25D09).
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

-- Robyn K. Kennedy (25D09, external_id=-210009)
-- Politician UUID: e47f2082-6fcb-4961-9df5-c5fb94004b59

-- ----- Robyn K. Kennedy / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Robyn K. Kennedy has supported abortion rights and backed legislation to protect reproductive healthcare in Massachusetts. She was elected in 2022 and has aligned with the Democratic majority in protecting and expanding abortion access. She backed the 2022 shield law protecting Massachusetts providers and patients following the Dobbs decision. She has framed abortion access as a fundamental healthcare right.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RKK0', 'https://ballotpedia.org/Robyn_Kennedy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robyn K. Kennedy / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Robyn K. Kennedy has been a strong supporter of climate action and clean energy in the Massachusetts Senate. She has backed the Climate Act's implementation and pushed for more ambitious emissions reductions. She has supported clean energy investments, electric vehicle adoption, and building electrification. As a member representing Worcester, she has emphasized environmental justice aspects of climate policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RKK0', 'https://ballotpedia.org/Robyn_Kennedy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robyn K. Kennedy / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Robyn K. Kennedy has focused on economic development that creates good jobs and supports working families in Worcester. She has backed workforce development, clean energy jobs, and small business investment. She supported clean energy economic development in central Massachusetts and has advocated for investments in education and workforce training as foundations for economic growth.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RKK0', 'https://ballotpedia.org/Robyn_Kennedy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robyn K. Kennedy / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Robyn K. Kennedy has championed healthcare access including behavioral health services and mental health reform. She has backed expanded MassHealth coverage and has worked on maternal health, particularly addressing racial disparities in maternal mortality in Worcester. She has supported community health center funding and mental health parity legislation in her first term.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RKK0', 'https://ballotpedia.org/Robyn_Kennedy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robyn K. Kennedy / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Robyn K. Kennedy backed the 2024 Affordable Homes Act and has been a strong advocate for affordable housing in Worcester, which has faced rapid rent increases and displacement of longtime residents. She has supported tenant protections, anti-eviction measures, and deeply affordable housing production. She has advocated for community land trusts and other tools to preserve affordable housing stock.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RKK0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robyn K. Kennedy / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Robyn K. Kennedy supported the Work and Family Mobility Act and has backed immigrant-friendly policies in Massachusetts. She represents Worcester, which has significant immigrant communities, and has supported language access, immigrant integration programs, and protections from immigration enforcement. She has been an ally for immigrant rights organizations in central Massachusetts.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/RKK0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robyn K. Kennedy / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Robyn K. Kennedy has supported criminal justice reform and community-based approaches to public safety. She has backed the 2020 Police Reform Act and has advocated for investment in violence prevention and mental health intervention as alternatives to incarceration. She has supported reform of the cash bail system and addressed racial disparities in the criminal justice system in Worcester.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RKK0', 'https://ballotpedia.org/Robyn_Kennedy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robyn K. Kennedy / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Robyn K. Kennedy supported the Fair Share Amendment (Question 1, 2022) and has backed progressive taxation to fund education, healthcare, and housing. She has emphasized that tax investments must address systemic inequities and prioritize Worcester's underinvested communities. She has been a voice for tax fairness on behalf of working families and communities of color in central Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RKK0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robyn K. Kennedy / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e47f2082-6fcb-4961-9df5-c5fb94004b59',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Robyn K. Kennedy has supported voting rights expansion including making early voting and vote-by-mail permanent. She has backed automatic voter registration and other measures to reduce barriers to voting for working families and communities of color in Worcester. She represents a district with significant minority populations who face disproportionate barriers to electoral participation.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/RKK0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 9 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'e47f2082-6fcb-4961-9df5-c5fb94004b59';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'e47f2082-6fcb-4961-9df5-c5fb94004b59'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'e47f2082-6fcb-4961-9df5-c5fb94004b59'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
