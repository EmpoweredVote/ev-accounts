-- ============================================================================
-- Migration 526: Joan Meschino Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Joan Meschino (MA State Rep,
--          3rd Plymouth District, HD-111, external_id=-210151).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Joan Meschino (HD-111, external_id=-210151, id=502890e3-ad59-4d40-88a4-3cdee03f025e) --

-- ----- Joan Meschino / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('502890e3-ad59-4d40-88a4-3cdee03f025e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('502890e3-ad59-4d40-88a4-3cdee03f025e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Meschino sponsored H.1004 ("An Act promoting climate safe buildings"), which requires new construction to meet climate resilience standards, and H.3448 ("An Act setting deadlines to electrify school buses and public fleets"). These bills directly address climate mitigation through building standards and transportation electrification mandates.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1004', 'https://malegislature.gov/Bills/194/H3448']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan Meschino / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('502890e3-ad59-4d40-88a4-3cdee03f025e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('502890e3-ad59-4d40-88a4-3cdee03f025e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Meschino sponsored H.1003 (drought management for adequate water supplies), H.1005 (investing in natural and working lands), and H.1006 (nature-based climate solutions incentives). Her local environmental legislation focuses on ecosystem preservation, water security, and using natural systems as climate adaptation tools.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1003', 'https://malegislature.gov/Bills/194/H1005', 'https://malegislature.gov/Bills/194/H1006']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan Meschino / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('502890e3-ad59-4d40-88a4-3cdee03f025e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('502890e3-ad59-4d40-88a4-3cdee03f025e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Meschino sponsored H.1889 ("An Act to eliminate disparate impact") addressing racial disparities in child welfare, H.246 (bias-free child removals from families), H.270 (consideration of a child's racial/ethnic/cultural/linguistic identity in foster care), and H.271 (preventing discrimination against foster parents based on irrelevant convictions). She has a concentrated focus on racial equity in family and child welfare systems.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1889', 'https://malegislature.gov/Bills/194/H246', 'https://malegislature.gov/Bills/194/H270']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joan Meschino / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('502890e3-ad59-4d40-88a4-3cdee03f025e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('502890e3-ad59-4d40-88a4-3cdee03f025e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Meschino sponsored H.2499 ("An Act pertaining to women's health at midlife and public, medical and workplace awareness of the transitional stage of menopause"), focusing on women's healthcare access and workplace accommodations. Her healthcare bills reflect targeted access expansion rather than comprehensive reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2499', 'https://malegislature.gov/Bills/194/H2313']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '502890e3-ad59-4d40-88a4-3cdee03f025e';
-- unpaired=0; uncited=0
