-- ============================================================================
-- Migration 523: Tommy Vitolo Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Tommy Vitolo (MA State Rep,
--          15th Norfolk District, HD-108, external_id=-210148).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Tommy Vitolo (HD-108, external_id=-210148, id=001147b2-5c07-499e-85b9-bae224fdc73a) --

-- ----- Tommy Vitolo / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('001147b2-5c07-499e-85b9-bae224fdc73a',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('001147b2-5c07-499e-85b9-bae224fdc73a',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Vitolo sponsored H.2153 (expanding employer commuter transit benefits), H.3804 (improving pedestrian safety), H.3806 (roadway safety), and H.3580 (net-zero neighborhoods — sustainable transport/energy). Representing Brookline, he consistently sponsors legislation promoting transit, pedestrian infrastructure, and reduced car dependency over highway expansion.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2153', 'https://malegislature.gov/Bills/194/H3804', 'https://malegislature.gov/Bills/194/H3580']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tommy Vitolo / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('001147b2-5c07-499e-85b9-bae224fdc73a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('001147b2-5c07-499e-85b9-bae224fdc73a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Vitolo sponsored H.3580 ("An Act creating pathways toward net-zero neighborhoods") and H.3581 (supporting electrical load aggregation programs), directly targeting decarbonization of the built environment. These bills align with Massachusetts's net-zero climate goals and reflect Vitolo's strong commitment to aggressive climate action at the local and state level.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3580', 'https://malegislature.gov/Bills/194/H3581']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tommy Vitolo / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('001147b2-5c07-499e-85b9-bae224fdc73a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('001147b2-5c07-499e-85b9-bae224fdc73a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Vitolo sponsored H.1067 ("An Act advancing water access equity through utility reporting requirement") and H.3274 (establishing a local option gas tax to fund environmental/transportation initiatives). His focus on utility transparency and local environmental funding mechanisms reflects a robust local environmental protection stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1067', 'https://malegislature.gov/Bills/194/H3274']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tommy Vitolo / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('001147b2-5c07-499e-85b9-bae224fdc73a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('001147b2-5c07-499e-85b9-bae224fdc73a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Vitolo sponsored H.2561 ("An Act respecting autonomy in name choice for newly married partners"), which removes gendered assumptions in name-change law after marriage — a gender-equity civil rights measure. He also sponsored H.2044 (repealing petit treason, an archaic common law doctrine). These bills reflect commitment to expanding civil rights and modernizing discriminatory legal vestiges.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2561', 'https://malegislature.gov/Bills/194/H2044']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '001147b2-5c07-499e-85b9-bae224fdc73a';
-- unpaired=0; uncited=0
