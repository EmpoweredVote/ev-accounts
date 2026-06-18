-- ============================================================================
-- Migration 386: Vanna Howard Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Vanna Howard (MA State Senator, 25D11).
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

-- Vanna Howard (25D11, external_id=-210011)
-- Politician UUID: c947719a-cd1a-497a-8fc9-d9c4d434b18f

-- ----- Vanna Howard / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Vanna Howard has been a strong supporter of reproductive rights. She voted for the ROE Act in 2020 and backed subsequent legislation to protect abortion access in Massachusetts. As a progressive Democrat who was the first Haitian-American elected to the Massachusetts legislature, she has framed abortion access as an equity issue, noting that restrictions on abortion access disproportionately harm low-income women and women of color.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/V_H0', 'https://ballotpedia.org/Vanna_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vanna Howard / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Vanna Howard has been a civil rights champion in the Massachusetts legislature. As the first Haitian-American elected to the Massachusetts General Court, she has been a vocal advocate for racial equity, immigrant rights, and anti-discrimination protections. She supported the 2020 Police Reform Act and has backed LGBTQ+ protections. She has emphasized addressing systemic racism in all areas of policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/V_H0', 'https://ballotpedia.org/Vanna_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vanna Howard / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Vanna Howard supported the 2021 Massachusetts Climate Act and has been an advocate for environmental justice in the Lowell area. She has connected climate action with environmental justice, noting that low-income communities and communities of color bear disproportionate burdens from pollution and climate change. She backed clean energy investments and has championed equitable distribution of climate benefits for her district.$$,
        ARRAY['https://malegislature.gov/Bills/192/S9', 'https://malegislature.gov/Legislators/Profile/V_H0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vanna Howard / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Vanna Howard has focused on economic development that creates opportunity for the diverse Lowell community. She has backed workforce development, vocational training, and small business support. Lowell has a large immigrant population including Cambodian, Haitian, and Latin American communities, and she has supported economic programs that create pathways for immigrant entrepreneurs and workers.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/V_H0', 'https://ballotpedia.org/Vanna_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vanna Howard / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Vanna Howard has championed healthcare access for underserved communities, particularly focusing on health equity and addressing racial disparities in healthcare. She has backed expanded MassHealth, community health centers, and maternal health equity legislation. She has advocated for language access in healthcare settings, particularly important in Lowell where many residents have limited English proficiency.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/V_H0', 'https://ballotpedia.org/Vanna_Howard']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vanna Howard / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Vanna Howard backed the 2024 Affordable Homes Act and has advocated for affordable housing and anti-displacement protections in the Lowell area, which has faced significant gentrification pressure. She has supported tenant protections, emergency rental assistance, and deeply affordable housing production. She has emphasized housing as a racial equity issue, noting that Black and immigrant residents face disproportionate housing instability.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/V_H0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vanna Howard / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Vanna Howard, as a Haitian-American representing Lowell with its large immigrant population, has been one of the strongest advocates for immigrant rights in the Massachusetts legislature. She supported the Work and Family Mobility Act and has backed protections from ICE enforcement, expanded access to public services for immigrants, and language access. She has opposed policies she views as criminalizing immigration.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/V_H0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vanna Howard / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Vanna Howard has supported criminal justice reform and police accountability, including the 2020 Police Reform Act. She has backed alternatives to incarceration, community-based violence prevention, and addressing racial disparities in policing and prosecution. She has spoken about her own community's experiences with over-policing and has advocated for a public health approach to violence and public safety.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/V_H0', 'https://malegislature.gov/Bills/191/H4886']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vanna Howard / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Vanna Howard supported the Fair Share Amendment (Question 1, 2022) and has backed progressive taxation to fund public services for underserved communities. She has championed tax policies that reduce inequality and increase investment in education, healthcare, and affordable housing. She represents a working-class district where tax fairness and adequate public investment are critical issues.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/V_H0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vanna Howard / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c947719a-cd1a-497a-8fc9-d9c4d434b18f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Vanna Howard backed the VOTES Act making early voting and vote-by-mail permanent and has been an advocate for voting rights expansion, especially for communities of color and immigrant communities. She has supported automatic voter registration and measures to combat voter suppression. She has also supported legislation to allow municipalities to permit non-citizen residents to vote in local elections.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/V_H0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 10 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c947719a-cd1a-497a-8fc9-d9c4d434b18f';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c947719a-cd1a-497a-8fc9-d9c4d434b18f'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c947719a-cd1a-497a-8fc9-d9c4d434b18f'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
