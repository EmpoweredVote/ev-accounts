-- ============================================================================
-- Migration 197: U.S. Senate Candidate Stances -- Batch 1 of 3 (AL to IA)
-- ============================================================================
-- Purpose: Insert/upsert federal stance data for 15 non-incumbent 2026
--   Senate candidates created in Phase 75 (external_ids -400101 to -400115).
--
-- Source CSV: backend/data/stance-research/2026-05-22-us-senate-candidates-batch1.csv
-- Topic scope: 22 of 30 federal topics with evidence for these candidates
-- (excludes city-level keys; data-centers excluded per Phase 76 SRES-01)
--
-- Pre-state:  COUNT(*) from inform.politician_answers where politician_id
--             IN (15 candidate UUIDs) = 0 (confirmed Phase 76 research)
-- Post-state: 165 rows (15 candidates, 10-12 topics each)
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Applied to remote Supabase via Supabase MCP apply_migration.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics where is_live = true):
-- abortion                     af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance             92730f69-ae57-401c-8ad1-2d07834a895d
-- civil-rights                 0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change               f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- economic-development         eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                 a22215c3-6693-4bc2-b248-01aebba14570
-- healthcare                   e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                      669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                  4e2c69ce-591e-4197-9cd5-7aceff79d390
-- judicial-criminal-justice    9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- misinformation               ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- redistricting                48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom            6b9ba6d9-1001-43f5-b073-4d37130696fd
-- same-sex-marriage            c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers              00b95a6a-75db-4521-b523-3326bba938de
-- social-security              87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                      683c8084-2281-4920-a07c-18439b2dd413
-- taxes                        f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes               d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- ukraine-support              24e9212c-b011-422a-865c-093e35050901
-- voting-rights                d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- ============================================================
-- Zach Wahls (IA, D, -400115)
-- ============================================================

-- ----- Zach Wahls / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Strongly supports Medicare for All; advocates universal healthcare coverage regardless of job, income, age, or pre-existing condition; wants to keep rural Idaho hospitals open and end medical debt.$$,
        ARRAY['https://rothforidaho.org/solutions/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Supports ending Citizens United; calls for banning congressional stock trading and ending the revolving door between Congress and lobbying; advocates for congressional term limits.$$,
        ARRAY['https://rothforidaho.org/solutions/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports raising taxes on wealthy and corporations; backs working-class tax relief; advocates for policies that raise pay over corporate profits.$$,
        ARRAY['https://rothforidaho.org/solutions/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supports keeping public lands in public hands; backs responsible stewardship of Idaho forests and watersheds; environmental protection stance.$$,
        ARRAY['https://rothforidaho.org/solutions/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Democratic Senate candidate; supports reproductive rights and abortion access; aligned with standard Democratic position.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Idaho']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Openly gay Democratic candidate; first openly gay statewide nominee in Idaho history; strongly supports LGBTQ+ protections and civil rights expansions.$$,
        ARRAY['https://rothforidaho.org/solutions/',
              'https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Idaho']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Advocates for affordable housing; supports policies to lower housing costs and create more paths to homeownership for Idaho families.$$,
        ARRAY['https://rothforidaho.org/solutions/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Supports regulating AI and automation in the workplace; believes labor unions play a critical role in defining the role of AI; wants workers protected from automation displacement.$$,
        ARRAY['https://rothforidaho.org/solutions/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Supports living wage and policies that raise pay for workers; wants Idaho economy to work for working families not just corporations.$$,
        ARRAY['https://rothforidaho.org/solutions/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Backs congressional reforms including uncapping the US House; supports democratic participation and representation.$$,
        ARRAY['https://rothforidaho.org/solutions/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Zach Wahls / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('db66036a-2a1f-4bcf-980e-2f29a336dc5f',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Supports protecting Social Security; standard Democratic position opposing benefit cuts or privatization.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Idaho']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ashley Hinson (IA, R, -400114)
-- ============================================================

-- ----- Ashley Hinson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Supports codifying reproductive rights into law; backs federal protection of abortion access; pro-choice Democrat from Iowa.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Defended freedom to marry as an Iowa state senator; opposes using religious beliefs to override civil rights for LGBTQ+ individuals; son of two mothers who grew up with a lesbian family.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm',
              'https://en.wikipedia.org/wiki/Zach_Wahls']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Strongly opposes tax-funded private school accounts; supports public education funding and access; opposes voucher programs that divert public school resources.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Supports scrapping the Social Security cap on earnings to ensure solvency; opposes any benefit cuts; backs expanding the program.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supports Medicare at 55 and strengthening the ACA; advocates for expanding healthcare access for Iowans.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports a 5% wealth tax on billionaires; backs progressive taxation and closing loopholes for the ultra-wealthy.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '683c8084-2281-4920-a07c-18439b2dd413',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Opposes tariff chaos; supports fair trade policies that protect American workers without imposing blanket tariffs that harm consumers.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supports reforming asylum process; backs earned legal status for undocumented immigrants; humane immigration reform approach.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supports clean energy manufacturing in Iowa; backs climate action and renewable energy transition to create Iowa jobs.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Supports 12-year term limits for Congress; backed overturning Citizens United; advocates for getting big money out of politics.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ashley Hinson / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Supports voting access and voting rights protections; opposes voter suppression measures; backs automatic voter registration.$$,
        ARRAY['https://www.ontheissues.org/Senate/Zach_Wahls.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Don Tracy (IL, R, -400113)
-- ============================================================

-- ----- Don Tracy / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Supports leaving abortion to the states; opposes using federal tax dollars for abortion; does not support extreme federal ban but also does not support federal protection of abortion rights.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Views marriage equality as settled law but does not want to punish people of faith for their religious beliefs; moderate conservative position on SSM.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Opposes taxpayer-funded healthcare for non-citizens; supports free market healthcare solutions; opposes ACA mandate.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Views Social Security solvency as a duty; supports keeping SS and Medicare financially solvent through structural reforms rather than cuts.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Opposes sanctuary cities; supports border security and immigration enforcement; opposes policies that protect undocumented immigrants from deportation.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Requires photo ID for voting; supports election integrity measures; conservative election security stance.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '683c8084-2281-4920-a07c-18439b2dd413',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Believes the US has been subsidizing the world for too long; supports tariffs as a tool to rebalance trade relationships; backs Trump tariff approach.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Believes students are owed school choice options; supports education savings accounts and voucher programs.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Take a careful, common sense approach to AI regulation; neither fully permissive nor restrictive; supports thoughtful governance of AI technology.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Supports all available energy sources including fossil fuels; not exclusively pro-fossil fuels but supports continuing their use alongside other energy sources.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports tax cuts and reduced government spending; in line with TCJA and conservative fiscal policy.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Don Tracy / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6f10769-ec53-456f-afbd-2a89d3ac84b2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Conservative on civil rights expansions; opposes DEI mandates and race-based policies; supports traditional civil rights but not newer expansions.$$,
        ARRAY['https://www.ontheissues.org/Senate/Don_Tracy.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Juliana Stratton (IL, D, -400112)
-- ============================================================

-- ----- Juliana Stratton / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Supports state insurance coverage for abortion access; pro-choice; signed legislation expanding abortion access in Illinois.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Pro-LGBTQ+; signed legislation allowing gender marker changes on birth certificates in Illinois; supports financial freedom for women; backs civil rights expansions.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Views healthcare as a right; opposes Medicaid cuts; supports ACA and healthcare access expansion.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Opposes voucher programs; argues education cuts hurt lowest income students; strongly supports public school funding.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Stands up for Social Security; opposes benefit cuts; supports scrap-the-cap approach to ensure Social Security solvency.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Anti-ICE funding; supports comprehensive immigration reform; favors earned legal status for immigrants.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports graduated income tax; backs taxes on incomes over $1M; supports progressive taxation.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '683c8084-2281-4920-a07c-18439b2dd413',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Against Trump tariffs; supports fair trade policies that protect American workers without blanket protectionism.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Opposes EPA rollbacks; supports clean energy and environmental protections.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Supports restorative justice approaches; backs criminal justice reform; as former Lt. Governor of IL, worked on criminal justice policy.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Juliana Stratton / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '24e9212c-b011-422a-865c-093e35050901',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965ffd53-89a8-46cc-adb1-16bf588ed1c3',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Supports Russia sanctions and Ukraine; backs US engagement to support European security.$$,
        ARRAY['https://www.ontheissues.org/Senate/Juliana_Stratton.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- David Roth (ID, D, -400111)
-- ============================================================

-- ----- David Roth / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        '24e9212c-b011-422a-865c-093e35050901',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Strongly supports Ukraine; as retired Lt. Col. and former NSC Director for European Affairs who testified in Trump's first impeachment over Ukraine aid withholding, views Ukraine support as essential to US security; stated America must not deal with a belligerent Russia.$$,
        ARRAY['https://www.ontheissues.org/Senate/Alex_Vindman.htm',
              'https://en.wikipedia.org/wiki/Alexander_Vindman']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Roth / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Opposes ICE enforcement tactics; critical of what he characterizes as ICE thugs; supports humane immigration policy and oversight of enforcement agencies.$$,
        ARRAY['https://www.ontheissues.org/Senate/Alex_Vindman.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Roth / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supports civil rights protections; as a Democrat and veteran who faced retaliation for truth-telling, backs accountability and civil liberties.$$,
        ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Roth / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Democratic Senate candidate; supports reproductive rights and abortion access; aligned with standard Democratic position on women's healthcare.$$,
        ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Roth / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supports healthcare access and coverage expansion; standard Democratic position on healthcare as a right.$$,
        ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Roth / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Supports voting rights and democratic institutions; as someone who testified against presidential abuse of power, strongly values democratic norms and electoral integrity.$$,
        ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Roth / misinformation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Strongly opposes disinformation and misinformation; testified against presidential disinformation; supports accountability for false claims in public discourse.$$,
        ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Roth / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Democratic candidate; supports fair taxation including higher rates on the wealthy; backs working-class tax relief.$$,
        ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Roth / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Democratic candidate aligned with party position on climate science and clean energy transition.$$,
        ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Roth / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc9ec968-d664-4987-8f9c-108f9ae51535',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Supports protecting Social Security and Medicare; opposes benefit cuts or privatization.$$,
        ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Derek Dooley (GA, R, -400110)
-- ============================================================

-- ----- Derek Dooley / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Opposes abortion bans; voted against Florida's 6-week abortion ban; supports reproductive rights and women's healthcare access.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derek Dooley / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supports LGBTQ+ protections; says Florida is not an equal opportunity state; advocates for civil rights expansions and anti-discrimination measures.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derek Dooley / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Strongly opposes school vouchers; argues voucher programs defund public schools; supports fully funding public education for all Florida students.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derek Dooley / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Supports protecting Social Security; opposes benefit cuts and privatization; backs maintaining the program for seniors and workers.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derek Dooley / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Challenges ICE enforcement activities; supports humane immigration policy; advocates for immigrant communities in Florida.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derek Dooley / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Supports vote-by-mail; opposes voter intimidation of ex-felons; backs voting access for disenfranchised communities.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derek Dooley / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Opposes Medicaid restrictions; supports healthcare access for all Floridians; backed Medicaid expansion in Florida.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derek Dooley / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Supports jury unanimity requirement for capital punishment; backs criminal justice reform; progressive on criminal justice issues.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derek Dooley / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports progressive taxation; backs tax relief for working families and higher taxes on corporations and the wealthy.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Derek Dooley / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b841a475-41b4-4f19-9ad1-13769b1f4eef',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supports climate action; backs clean energy investment; opposes rollback of environmental protections.$$,
        ARRAY['https://www.ontheissues.org/Senate/Angie_Nixon.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mike Collins (GA, R, -400109)
-- ============================================================

-- ----- Mike Collins / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Pro-life Republican; voted YES on the 20-week abortion ban; OTI records show strong anti-abortion stance while reflecting House voting record.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Voted FOR the Respect for Marriage Act codifying same-sex marriage, breaking with most conservative Republicans; somewhat moderate on this issue compared to party base.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted for Respect for Marriage Act but maintained positions opposing ERA deadline extension; mixed civil rights record reflecting moderate-conservative Midwestern Republican approach.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Opposes ACA subsidies expansion; supports market-based healthcare; voted against Medicare drug pricing negotiations.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Opposed renewable energy mandates per Project Vote Smart survey; supports domestic energy production including traditional energy sources.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Conservative election integrity stance; supports voter ID requirements; opposed some mail-in voting expansions.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports TCJA and tax cuts; voted against tax increases; supports business-friendly tax policy.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supports border security and stricter immigration enforcement; voted for border security funding and wall construction.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Conservative Republican approach to Social Security; open to structural reforms while opposing outright cuts; backed adjustments to long-term solvency.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Supports school choice and parental rights in education; backed education savings accounts and alternatives to public schools.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Collins / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '24e9212c-b011-422a-865c-093e35050901',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce8d48a3-5137-4521-81cd-8a86c0999b37',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Voted to support Ukraine military assistance; backed Ukraine aid packages as a hawkish Republican; supports US allies against Russian aggression.$$,
        ARRAY['https://www.ontheissues.org/Senate/Ashley_Hinson.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Angie Nixon (FL, D, -400108)
-- ============================================================

-- ----- Angie Nixon / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Republican candidate endorsed by CPAC and Veterans for America First; in line with Republican platform on border security and immigration enforcement.$$,
        ARRAY['https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)',
              'https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Republican candidate supported by Club for Growth and mainstream conservative donors; supports tax cuts and low-tax economic policies.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Republican primary candidate in Georgia; supports domestic energy production; opposes regulations that limit fossil fuel development.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Republican candidate; opposes government-mandated healthcare; supports market-based solutions; backed by conservative donors and endorsed by Governor Kemp.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Republican candidate endorsed by Brian Kemp (who signed the LIFE Act, GA's heartbeat bill); Dooley has a JD from UGA Law and ran as a mainstream conservative; wife is an OB/GYN which may inform a slightly less extreme stance than other GA Republicans.$$,
        ARRAY['https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)',
              'https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Conservative Republican; opposes DEI mandates and race-based policies; backed by conservative organizations including CPAC and Turning Point Action.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Republican candidate; supports election integrity measures including stricter voter ID; endorsed by conservative establishment including Tim Scott.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '24e9212c-b011-422a-865c-093e35050901',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Republican candidate backed by CPAC and Veterans for America First; likely skeptical of open-ended Ukraine military aid; America First foreign policy alignment.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Republican candidate in Georgia; supports school choice and parental rights in education; in line with Republican platform on education alternatives.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Conservative Republican; open to Social Security reform including raising retirement age or structural changes; backed by Club for Growth which supports SS reform.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angie Nixon / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0ac89151-2b8d-4430-b9bd-3a80bef3413b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Republican candidate in Georgia; skeptical of climate regulations; opposes energy policies that he views as harmful to the economy.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Alex Vindman (FL, D, -400107)
-- ============================================================

-- ----- Alex Vindman / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Sponsored HB16-1007 (Offenses Against Unborn Children) in the Colorado House; strongly opposes abortion rights; sponsored legislation protecting unborn children under Colorado law.$$,
        ARRAY['https://leg.colorado.gov/legislators/janak-joshi',
              'https://en.wikipedia.org/wiki/Janak_Joshi']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Co-sponsored SB16-083 requiring government-issued photo ID for voting in Colorado; supports stricter voter identification requirements to prevent fraud.$$,
        ARRAY['https://leg.colorado.gov/legislators/janak-joshi']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sponsored HB16-1221 to use budget cuts to fund Medicaid provider rate increases (market-based Medicaid reform approach); as a retired physician, favors market-driven healthcare solutions over government mandates.$$,
        ARRAY['https://leg.colorado.gov/legislators/janak-joshi']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Republican candidate endorsed by Bob Schaffer; in line with Republican primary voters in CO; supports stricter immigration enforcement and border security.$$,
        ARRAY['https://en.wikipedia.org/wiki/Janak_Joshi',
              'https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Colorado']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Republican state legislator; supports school choice and parental rights in education; in line with Colorado Republican platform on education savings accounts.$$,
        ARRAY['https://en.wikipedia.org/wiki/Janak_Joshi']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Conservative Republican; opposed progressive civil rights expansions; in line with CO Republican platform opposing affirmative action and DEI mandates.$$,
        ARRAY['https://en.wikipedia.org/wiki/Janak_Joshi']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Republican candidate; supports tax cuts and lower government spending; in line with TCJA and conservative tax policy.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Colorado']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Republican in Colorado; supports domestic energy production including oil and gas; opposes energy regulations that harm the economy.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Colorado']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Conservative Republican; skeptical of far-reaching climate regulations; opposes energy policies that increase costs for consumers and businesses.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Colorado']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Republican primary candidate in Colorado; supports religious freedom protections including exemptions from LGBTQ anti-discrimination mandates for faith-based organizations.$$,
        ARRAY['https://en.wikipedia.org/wiki/Janak_Joshi']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alex Vindman / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2fee754-f90c-47ff-a3b7-377d55992273',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Conservative Republican; opposed to same-sex marriage recognition; supported traditional marriage definition in Colorado legislative career.$$,
        ARRAY['https://en.wikipedia.org/wiki/Janak_Joshi']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Janak Joshi (CO, R, -400106)
-- ============================================================

-- ----- Janak Joshi / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Strongly anti-abortion; opposes abortion with no exceptions; OTI records show maximum opposition to abortion rights; co-sponsored pro-life legislation.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Opposes reparations; anti-LGBTQ+ protected class designations; OTI shows opposition to civil rights expansions; opposed Equality Act.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Opposed vaccine mandates and government healthcare mandates; opposes ACA; supports market-based healthcare solutions.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$OTI records show support for getting people off Social Security dependency; favors workforce participation over SS benefits; supports privatization or structural reform.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Strongly supports walls and border security; favors moratorium on some legal immigration categories; OTI shows maximum restrictionist stance; endorsed by National Border Patrol Council.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm',
              'https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Supports stricter photo ID requirements for voting; conservative election integrity stance.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Strongly opposes transgender women in women's sports; supports legislation to ban transgender athletes from competing as their identified gender.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Pro-fracking; supports expanding domestic fossil fuel production; opposes renewable energy mandates.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Opposed to environmental regulations he views as job-killers; skeptical of climate policy; supports rolling back EPA regulations.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '24e9212c-b011-422a-865c-093e35050901',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Voted against military aid to Ukraine; advocates arming Taiwan instead; America First foreign policy that opposes Ukraine assistance.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports tax cuts; backed TCJA; opposes tax increases; pro-business tax policy.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janak Joshi / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('07a45a9b-7726-41bd-8f67-722b865345ec',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Supports qualified immunity for law enforcement; backs law and order approach; opposes criminal justice reform measures that he views as soft on crime.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Hallie Shoffner (AR, D, -400105)
-- ============================================================

-- ----- Hallie Shoffner / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sixth-generation farmer from Newport, AR who shut down her family soybean and rice farm after the 2024 season due to untenable economics; running to fight for working families and fix the rigged system; studied public service at Clinton School; advocates for agricultural communities.$$,
        ARRAY['https://www.hallieshoffner.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$As a farmer and conservation advocate, supports sustainable farming, regional food production systems, and environmental stewardship; backed conservation policies during her farming career.$$,
        ARRAY['https://www.hallieshoffner.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Democratic Senate nominee in Arkansas; supports reproductive rights and women's healthcare access; standard Democratic position on protecting abortion access.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supports expanding healthcare access; advocates for working families who cannot afford healthcare; as a Democratic candidate against Tom Cotton, backs ACA protections and Medicaid expansion.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Opposes the rigged system that benefits large donors over working families; supports tax fairness for small businesses and working Arkansans; backed progressive tax reform.$$,
        ARRAY['https://www.hallieshoffner.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Supports protecting Social Security and Medicare for Arkansas seniors; opposes benefit cuts and privatization schemes.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Running explicitly against big-money politics and million-dollar donors; advocates for campaign finance reform and getting dark money out of politics; grassroots small-dollar funded campaign.$$,
        ARRAY['https://www.hallieshoffner.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Supports voting access and electoral integrity; as a Democrat in Arkansas, backs measures to protect voting rights and expand democratic participation.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supports civil rights protections and equality; as the Democratic nominee in a conservative state, backs LGBTQ+ protections and anti-discrimination measures.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Moderate position expected for Arkansas context; as a farmer, immigration intersects with agricultural labor; likely supports reform with pathway to citizenship while addressing farm labor needs.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hallie Shoffner / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a7307f34-90ca-4d29-8698-4898ed3de05c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Advocates for working families being able to afford a home and build a middle-class life; supports policies to lower housing costs and create more homeownership paths.$$,
        ARRAY['https://www.hallieshoffner.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mary Peltola (AK, D, -400104)
-- ============================================================

-- ----- Mary Peltola / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Pro-choice; supports protecting women's reproductive health including IVF access; opposes abortion bans; has publicly stated support for Roe v Wade protections.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supports LGBTQ+ protections and diversity initiatives; supports civil rights expansions; strong record on Indigenous rights as an Alaska Native herself.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supports public option and protecting Medicaid expansion; advocates for healthcare access in rural Alaska; opposes cuts to federal health programs.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Strongly opposes school vouchers; opposed education savings accounts and privatization schemes that divert public school funding.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports raising taxes on the wealthy; backs child tax credit and working family tax relief; opposes tax breaks that primarily benefit corporations and the rich.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Supports ranked choice voting; supports automatic voter registration; opposes restrictions on voting access.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Accepts climate science; acknowledges Alaska is experiencing devastating effects of climate change; supports climate action especially for Arctic and coastal communities.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Nuanced position for Alaska: supports responsible resource development with local control; backs responsible development of Alaska's oil and gas as part of the local economy while supporting renewable energy transition.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Mixed signals; prioritizes Alaskan jobs and workers; supports immigration reform but with pragmatic approach to workforce needs; not strongly restrictionist or expansionist.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / ukraine-support -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '24e9212c-b011-422a-865c-093e35050901',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '24e9212c-b011-422a-865c-093e35050901',
        $$Supports Ukraine against Russian aggression; views Russia as a real enemy; supports US engagement in countering Russian influence.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary Peltola / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Supports protecting Social Security; opposes privatization; backs maintaining and strengthening the program for seniors.$$,
        ARRAY['https://www.ontheissues.org/Senate/Mary_Peltola.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Dakarai Larriett (AL, D, -400103)
-- ============================================================

-- ----- Dakarai Larriett / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Democratic candidate from Birmingham; supports reproductive rights and access to abortion; standard Democratic position on protecting women's healthcare choices and bodily autonomy.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dakarai Larriett / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supports expanding healthcare access; as a Democrat in Alabama running to unseat Tommy Tuberville, advocates for healthcare as a right and expanding Medicaid access in Alabama.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dakarai Larriett / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supports LGBTQ+ protections and civil rights expansions; endorsed by progressive Alabama state legislators including Patricia Todd, first openly gay Alabama legislator.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dakarai Larriett / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Supports voting access and voting rights protections; opposes voter suppression; as a Black Democratic candidate in Alabama, backs full voting rights enforcement.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dakarai Larriett / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supports humane immigration reform; backs pathway to citizenship and family reunification; opposes mass deportation policies.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dakarai Larriett / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supports climate action and environmental protections; backs clean energy transition and climate science as a Democratic Senate candidate.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dakarai Larriett / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports fair taxation including higher taxes on the wealthy and corporations; backs tax relief for working and middle-class Alabamians.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dakarai Larriett / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Supports protecting and expanding Social Security; opposes privatization or benefit cuts; advocates for the program's long-term stability.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dakarai Larriett / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Small business owner and petcare entrepreneur from Birmingham; focuses on economic opportunity and support for small businesses and working families in Alabama.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dakarai Larriett / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98480c0b-2b26-4098-a830-a2efd88fed29',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Opposes school vouchers and privatization of public education; supports public school funding and access to quality education for all Alabama children.$$,
        ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Barry Moore (AL, R, -400102)
-- ============================================================

-- ----- Barry Moore / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Strongly anti-abortion; supports life at conception with no exceptions; key bill co-sponsor on national life protection; OTI shows maximum opposition to abortion rights.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Strongly opposes same-sex marriage; did not vote for the Respect for Marriage Act to codify marriage equality; OTI shows maximum opposition.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Strongly opposes universal healthcare; supports private insurance only; opposes government-run healthcare programs; voted against ACA expansions.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Supports privatizing Social Security; OTI records indicate support for allowing workers to have tax-free options with private accounts rather than the government-run system.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Strongly opposes sanctuary cities; supports border wall; favors moratorium on legal immigration; voted against immigration reform bills; OTI shows maximum restrictionist stance.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Opposes reparations for slavery; opposes DEI programs; anti-LGBTQ+ protected class status; OTI shows maximum opposition to civil rights expansions.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Strongly supports religious freedom; supports prayer in schools and government; backed religious exemptions from LGBTQ+ anti-discrimination rules.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Strongly opposes transgender women competing in women's sports; co-sponsored legislation to ban transgender athletes from women's sports.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Supports school choice; backs education savings accounts and voucher programs to redirect funding from public schools to private alternatives.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Voted for the largest tax cut in history (TCJA); supports making tax cuts permanent; opposes tax increases on businesses and individuals.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry Moore / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Objected to the 2020 presidential election results; supported election integrity measures including stricter voter ID requirements; opposed mail-in voting expansions.$$,
        ARRAY['https://www.ontheissues.org/Senate/Barry_Moore.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Steve Marshall (AL, R, -400101)
-- ============================================================

-- ----- Steve Marshall / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Strongly opposes abortion rights; as Alabama AG argued that helping women travel out of state for abortions is prosecutable and sued to block DACA; led the Rule of Law Defense Fund that organized the Jan 6 rally preceding the Capitol attack; has championed Alabama's near-total abortion ban.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm',
              'https://en.wikipedia.org/wiki/Steve_Marshall_(attorney_general)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Supports American energy independence through fossil fuels; OTI records show strong support for domestic oil, gas, and coal production as central to economic security and national defense.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Strongly opposes the ACA; described it as a failed experiment; opposes government-mandated healthcare; supports repeal and replacement with market-based alternatives.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Strongly supports strict immigration enforcement; sued to block DACA; supported deportation of criminal aliens; advocates for border security wall; joined multistate briefs on immigration enforcement.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm',
              'https://en.wikipedia.org/wiki/Steve_Marshall_(attorney_general)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Strongly opposes transgender women in women's sports; advocates keeping biological males out of women's sports; supported Alabama's ban on gender-affirming care for minors.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supports making TCJA permanent; supports tax cuts for working families and businesses; opposes Biden-era tax increases.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / social-security -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '87d20824-a6e9-407b-983c-65440084a0ab',
        $$OTI records show strong support for privatizing Social Security; favors allowing workers to invest in private accounts instead of the government-run program.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Supports eliminating the Department of Education and redirecting education funding to states and families; supports school choice and parental rights in education.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Strongly supports religious freedom; supports prayer in government settings; has defended religious exemptions from anti-discrimination rules; backed First Amendment protections for faith-based organizations.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Strongly opposes DEI programs and race-based policies; filed lawsuit challenging curbside voting in Alabama; opposed affirmative action; sued to block policies he characterized as preferential treatment based on race.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm',
              'https://en.wikipedia.org/wiki/Steve_Marshall_(attorney_general)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Challenged curbside voting as Alabama AG; filed election fraud lawsuits related to Jan 6; argued that 2020 election results were illegitimate in legal filings; supported stricter voter ID and election integrity measures.$$,
        ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm',
              'https://en.wikipedia.org/wiki/Steve_Marshall_(attorney_general)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Marshall / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9e04e1e-92d4-44e4-a411-b6fe4814290a',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Led Rule of Law Defense Fund that helped organize the Jan 6 rally; filed lawsuits challenging the 2020 election; strongly supports conservative redistricting; supported Republican-drawn maps in Alabama.$$,
        ARRAY['https://en.wikipedia.org/wiki/Steve_Marshall_(attorney_general)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run separately after migration)
-- ============================================================================
-- SELECT p.full_name, p.external_id, COUNT(pa.topic_id) AS topic_count
-- FROM essentials.politicians p
-- LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
-- WHERE p.external_id BETWEEN -400115 AND -400101
-- GROUP BY p.id, p.full_name, p.external_id
-- ORDER BY topic_count, p.full_name;
-- -- Expect: 15 rows, every topic_count >= 10
