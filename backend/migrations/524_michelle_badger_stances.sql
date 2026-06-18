-- ============================================================================
-- Migration 524: Michelle L. Badger Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michelle L. Badger (MA State Rep,
--          1st Plymouth District, HD-109, external_id=-210149).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Michelle L. Badger (HD-109, external_id=-210149, id=29af459c-8142-487d-bb51-2224983faca3) --

-- ----- Michelle L. Badger / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29af459c-8142-487d-bb51-2224983faca3',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29af459c-8142-487d-bb51-2224983faca3',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Badger, representing Plymouth (site of Pilgrim Nuclear Power Station), has been active on nuclear environmental issues: H.2488 (monitoring dry casks of spent nuclear fuel), H.2661 (public health standards around aging nuclear plants), and H.4040 (preventing discharge of radioactive materials). She also sponsored H.3996 (Massachusetts Solar Access Law). Her record shows strong local environmental protection particularly around nuclear waste and clean energy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2488', 'https://malegislature.gov/Bills/194/H2661', 'https://malegislature.gov/Bills/194/H3996']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle L. Badger / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29af459c-8142-487d-bb51-2224983faca3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29af459c-8142-487d-bb51-2224983faca3',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Badger sponsored H.4696 (establishing a board of registration for licensed mental health counselors — improving access to regulated mental health care) and H.3025 (long-term care insurance tax credit). Her healthcare bills reflect a mix of regulatory expansion and tax-incentive approaches to improving healthcare access, consistent with moderate Democratic positions.$$,
        ARRAY['https://malegislature.gov/Bills/194/H4696', 'https://malegislature.gov/Bills/194/H3025']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '29af459c-8142-487d-bb51-2224983faca3';
-- unpaired=0; uncited=0
