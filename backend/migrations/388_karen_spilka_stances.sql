-- ============================================================================
-- Migration 388: Karen E. Spilka Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Karen E. Spilka (MA State Senator, 25D13).
--   Note: Spilka is Senate President — richer record; target 8-12 stances.
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

-- Karen E. Spilka (25D13, external_id=-210013)
-- Politician UUID: 167d272b-fc1b-4a72-a44d-dfa1a9a42fcf
-- Note: Senate President since 2018 — rich legislative record

-- ----- Karen E. Spilka / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Karen E. Spilka, as Senate President, has been a powerful champion for reproductive rights in Massachusetts. She shepherded the ROE Act through the Senate in 2020 and, after the Dobbs decision, fast-tracked the shield law protecting Massachusetts abortion providers and patients from out-of-state legal actions. She has framed abortion access as a fundamental right and has used her leadership position to ensure Massachusetts remains a safe haven for reproductive healthcare. She personally lobbied for the measures and publicly signed them into law.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://www.boston.com/news/politics/2022/07/29/massachusetts-abortion-shield-law-signed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Karen E. Spilka has supported campaign finance transparency measures and some limits on contributions. As Senate President, she oversaw passage of campaign finance disclosure improvements. However, her position leading the institution means she has been more restrained than back-benchers on the most aggressive reforms. She supports transparency and reasonable limits while managing the complex political dynamics of leading a diverse caucus.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://ballotpedia.org/Karen_Spilka']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Karen E. Spilka has made childcare a signature legislative priority. Under her leadership, the Senate passed the Commonwealth Cares for Children (C3) stabilization grant program, the largest investment in early education in Massachusetts history. She has championed universal pre-K, expanded childcare subsidies, and increased compensation for childcare workers. She has framed high-quality affordable childcare as essential for both families and economic productivity.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://www.wbur.org/news/2021/06/09/senate-early-education-care-proposal']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Karen E. Spilka has been a strong advocate for climate action as Senate President. She championed the 2021 Next-Generation Climate Roadmap Act, the most ambitious climate legislation in Massachusetts history, setting net-zero emissions by 2050. She has backed offshore wind development, building electrification, and clean energy investments. Under her leadership, the Senate became the chamber leading on climate policy in Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://malegislature.gov/Bills/192/S9']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Karen E. Spilka has championed economic development legislation as Senate President, including the 2022 Economic Development and Housing bills. She has backed life sciences investment, tech industry growth, clean energy economy development, and support for small businesses. She served as Chair of the Ways and Means Committee before becoming Senate President and has a strong record on fiscal management and economic investment.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://ballotpedia.org/Karen_Spilka']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Karen E. Spilka has been a healthcare champion as Senate President, prioritizing behavioral health reform, substance use treatment, and mental health parity. Under her leadership, the Senate passed comprehensive behavioral health legislation in 2023, one of the most significant mental health investments in state history. She has also backed Medicaid expansions, maternal health equity, and prescription drug cost reform. She has spoken publicly about her own family's experiences with mental health challenges.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://www.wbur.org/news/2023/01/mental-health-legislation-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Karen E. Spilka has made housing a signature priority of her Senate presidency. She championed the 2024 Affordable Homes Act, one of the largest housing investments in Massachusetts history ($5.1 billion), and the 2023 MBTA Communities zoning law requiring transit-adjacent municipalities to allow multi-family housing. She has advocated for both housing production and affordability protections. The Affordable Homes Act passed in large part due to her legislative leadership.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://www.bostonglobe.com/2024/08/01/metro/affordable-homes-act-signed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Karen E. Spilka backed the Work and Family Mobility Act and has supported immigrant-friendly policies in Massachusetts. She has also had to manage the fiscal pressures of the emergency shelter system expansion, taking a more measured public approach on migrant shelter spending while maintaining support for the underlying policy of providing shelter. Her position as Senate President requires balancing progressive values with fiscal responsibility on this politically complex issue.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/KES0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Karen E. Spilka supported the 2020 Police Reform Act and has backed mental health diversion programs and alternatives to incarceration. As Senate President, she has managed the Senate's comprehensive behavioral health legislation which includes significant investments in mental health crisis response as an alternative to law enforcement. She has taken a balanced approach on public safety, supporting both accountability and resources for law enforcement.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://malegislature.gov/Bills/191/H4886']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Karen E. Spilka was a strong supporter of the Fair Share Amendment (Question 1, 2022) and has backed the use of new revenue for education and transportation investments. As former Ways and Means Chair and Senate President, she has been deeply involved in state fiscal policy, consistently supporting progressive revenue measures. She has championed using Fair Share funds for childcare, early education, and transportation improvements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KES0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen E. Spilka / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Karen E. Spilka championed the VOTES Act under her Senate presidency, permanently establishing early voting, vote-by-mail, and same-day registration in Massachusetts. She prioritized passage of the VOTES Act and signed it with Governor Baker in 2022, calling it historic. She has consistently supported expanding voting access and removing barriers to participation.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://www.wbur.org/news/2022/04/06/votes-act-signed-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 12 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
