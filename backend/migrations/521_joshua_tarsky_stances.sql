-- ============================================================================
-- Migration 521: Joshua Tarsky Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Joshua Tarsky (MA State Rep,
--          13th Norfolk District, HD-106, external_id=-210146).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Joshua Tarsky (HD-106, external_id=-210146, id=de311b87-1026-4f61-8e42-110b90491160) --

-- ----- Joshua Tarsky / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de311b87-1026-4f61-8e42-110b90491160',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de311b87-1026-4f61-8e42-110b90491160',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Tarsky sponsored H.716 (improving mental health in schools), H.1462 (supporting college students in recovery), and H.2237 (allowing minors to consent to substance use treatment). These bills reflect a strong commitment to expanding mental health and substance use care access, especially for young people — a consistent pattern of treating healthcare as a public good requiring government expansion.$$,
        ARRAY['https://malegislature.gov/Bills/194/H716', 'https://malegislature.gov/Bills/194/H1462', 'https://malegislature.gov/Bills/194/H2237']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joshua Tarsky / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de311b87-1026-4f61-8e42-110b90491160',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de311b87-1026-4f61-8e42-110b90491160',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Tarsky sponsored H.2010 ("An Act repealing the criminalization of blasphemy"), seeking to remove an archaic Massachusetts law that criminalizes religious speech. This civil liberties bill demonstrates a strong free-speech and civil rights orientation. He also sponsored H.718 (reducing out-of-school suspensions), reflecting concern for equitable treatment of students in the school discipline system.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2010', 'https://malegislature.gov/Bills/194/H718']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'de311b87-1026-4f61-8e42-110b90491160';
-- unpaired=0; uncited=0
