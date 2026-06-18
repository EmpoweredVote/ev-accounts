-- ============================================================================
-- Migration 531: Dennis C. Gallagher Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Dennis C. Gallagher (MA State Rep,
--          8th Plymouth District, HD-116, external_id=-210156).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Dennis C. Gallagher (HD-116, external_id=-210156, id=17035eb6-e7d3-4372-9b96-0741adb57468) --

-- ----- Dennis C. Gallagher / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17035eb6-e7d3-4372-9b96-0741adb57468',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17035eb6-e7d3-4372-9b96-0741adb57468',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Gallagher sponsored H.4578 ("An Act authorizing Bridgewater town charter amendment for gender neutral language"), modernizing official town documents to use inclusive language. As a Democrat representing Bridgewater, this reflects support for inclusive government language reforms as a civil rights measure.$$,
        ARRAY['https://malegislature.gov/Bills/194/H4578']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dennis C. Gallagher / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('17035eb6-e7d3-4372-9b96-0741adb57468',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('17035eb6-e7d3-4372-9b96-0741adb57468',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Gallagher sponsored H.3997 ("An Act establishing the suburban infrastructure fund to help municipalities pay for improvements and upgrades to town-owned roads, bridges and sidewalks"), which reflects a government-investment approach to local economic development through public infrastructure funding.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3997']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '17035eb6-e7d3-4372-9b96-0741adb57468';
-- unpaired=0; uncited=0
