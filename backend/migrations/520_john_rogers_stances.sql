-- ============================================================================
-- Migration 520: John H. Rogers Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for John H. Rogers (MA State Rep,
--          12th Norfolk District, HD-105, external_id=-210145).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- John H. Rogers (HD-105, external_id=-210145, id=730f6bce-4d8c-4ad0-897b-f687971a4d87) --

-- ----- John H. Rogers / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('730f6bce-4d8c-4ad0-897b-f687971a4d87',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('730f6bce-4d8c-4ad0-897b-f687971a4d87',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Rogers has been a persistent advocate for preserving local hospital access in Norwood, sponsoring H.2524 ("An Act protecting Norwood healthcare access"), H.2525 (establishing a Norwood hospital working group), and H.3410 (authorizing UMass Memorial to build and operate a hospital in Norwood). These bills reflect a strong commitment to maintaining and expanding public healthcare infrastructure in his community.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2524', 'https://malegislature.gov/Bills/194/H2525', 'https://malegislature.gov/Bills/194/H3410']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John H. Rogers / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('730f6bce-4d8c-4ad0-897b-f687971a4d87',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('730f6bce-4d8c-4ad0-897b-f687971a4d87',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Rogers sponsored H.683 (inflation adjustments for education aid), H.3228 (tuition tax credit), and H.3229 (increasing community preservation revenue). His bills reflect a government-investment approach to economic development through education funding and community reinvestment rather than tax reduction or deregulation.$$,
        ARRAY['https://malegislature.gov/Bills/194/H683', 'https://malegislature.gov/Bills/194/H3228', 'https://malegislature.gov/Bills/194/H3229']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '730f6bce-4d8c-4ad0-897b-f687971a4d87';
-- unpaired=0; uncited=0
