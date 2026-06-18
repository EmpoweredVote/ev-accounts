-- ============================================================================
-- Migration 378: Adam Gomez Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Adam Gomez (MA State Senator, 25D03).
--   Note: Full name in DB is Adam Gómez (with accent); file uses ASCII name.
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

-- Adam Gomez (25D03, external_id=-210003)
-- Politician UUID: 78ae3786-e71e-4dc4-8b84-0ab28b555632
-- Note: DB name is Adam Gómez (accented); file uses ASCII

-- ----- Adam Gomez / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Adam Gomez has been a strong supporter of abortion rights in Massachusetts. He voted for the ROE Act in 2020 and backed subsequent legislation to protect abortion access. As a progressive Democrat representing Springfield, he has spoken out against restrictions on reproductive healthcare and supported the 2022 legislation shielding Massachusetts abortion providers from out-of-state legal actions following the Dobbs decision.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/A_G0', 'https://ballotpedia.org/Adam_Gomez']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam Gomez / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Adam Gomez is a progressive Latino senator representing Springfield, one of Massachusetts' most diverse cities, and has been a vocal advocate for civil rights. He has backed LGBTQ+ anti-discrimination protections, racial justice legislation, and criminal justice reform. He supported the 2020 Police Reform Act (An Act Relative to Justice, Equity, and Accountability in Law Enforcement) which established certification standards for police and created an oversight board.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/A_G0', 'https://malegislature.gov/Bills/191/H4886']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam Gomez / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Adam Gomez voted for the 2021 Massachusetts Climate Act establishing a net-zero emissions target by 2050. He has emphasized environmental justice, noting that communities like Springfield bear a disproportionate burden of pollution from highways and industrial facilities. He has backed clean energy expansion and supported policies that link climate action with environmental justice for low-income and minority communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/S9', 'https://malegislature.gov/Legislators/Profile/A_G0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam Gomez / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Adam Gomez has focused on economic development and job creation for Springfield, one of Massachusetts' most economically challenged cities with a large Puerto Rican community. He has advocated for workforce development programs, small business support, and community investment. He backs economic development with a strong equity lens, prioritizing investment in historically marginalized communities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/A_G0', 'https://ballotpedia.org/Adam_Gomez']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam Gomez / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Adam Gomez has strongly supported expanding healthcare access in Massachusetts, particularly for underserved communities in Springfield. He has backed MassHealth expansions, mental health parity legislation, and community health center funding. Springfield has significant health disparities, and Gomez has worked to address root causes including access to affordable care, language accessibility, and coverage for undocumented residents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/A_G0', 'https://ballotpedia.org/Adam_Gomez']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam Gomez / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Adam Gomez has been a strong advocate for affordable housing in the Springfield area. He backed the 2024 Affordable Homes Act, which includes significant investment in public housing, rental assistance, and housing for low-income residents. He has also supported tenant protections including anti-displacement measures. Springfield has a high rental housing market with many working poor families, making affordable housing a core issue.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/A_G0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam Gomez / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Adam Gomez, as a Puerto Rican senator representing a city with a large Latino immigrant population, has been a strong advocate for immigrant rights. He supported the Work and Family Mobility Act allowing undocumented immigrants to obtain driver's licenses and has backed policies to limit local law enforcement cooperation with federal immigration enforcement (ICE detainer limits). He has also supported expanding healthcare access to undocumented residents.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/A_G0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam Gomez / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Adam Gomez has supported criminal justice reform and police accountability legislation, including the 2020 Police Reform Act that created officer certification and an oversight board. He has advocated for alternatives to incarceration and addressing root causes of crime in Springfield such as poverty and lack of opportunity. He has backed community-based violence prevention programs and mental health intervention as complements to traditional law enforcement.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/A_G0', 'https://malegislature.gov/Bills/191/H4886']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam Gomez / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Adam Gomez supported the Fair Share Amendment (Question 1, 2022), the 4% millionaire surtax funding education and transportation. He has championed progressive taxation to fund investments in communities like Springfield that have historically been underfunded. He has backed property tax relief for low-income homeowners and tax credits targeting working families in his district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/A_G0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam Gomez / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78ae3786-e71e-4dc4-8b84-0ab28b555632',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Adam Gomez has supported voting rights expansion in Massachusetts, including the VOTES Act making early voting and vote-by-mail permanent. He has also backed legislation to allow municipalities to permit non-citizen resident voting in local elections. As a representative of a largely working-class, minority district, he has emphasized removing barriers to voting for his constituents.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/A_G0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 10 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '78ae3786-e71e-4dc4-8b84-0ab28b555632';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '78ae3786-e71e-4dc4-8b84-0ab28b555632'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '78ae3786-e71e-4dc4-8b84-0ab28b555632'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
