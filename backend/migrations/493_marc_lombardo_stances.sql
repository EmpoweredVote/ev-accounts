-- ============================================================================
-- Migration 493: Marc T. Lombardo Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Marc T. Lombardo (MA House HD-78,
--   22nd Middlesex District). External ID: -210118.
--   Lombardo is a Republican; no AOM progressive co-sponsorships.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 0 rows in DB — all stances inserted fresh.
--
-- Evidence sources: malegislature.gov sponsored bills (H.1839, H.1840, H.2897,
--   H.2898, H.3162, H.3163, H.3164, H.3728, H.513); committee assignments.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Marc T. Lombardo (HD-78, external_id=-210118)
-- Politician UUID: e2c3e1a7-78b2-4c90-a136-c0a22c3f3e48

-- ----- Marc T. Lombardo / judicial-criminal-justice -----
-- H.1840 (courthouse safety), H.1839 (disorderly persons penalty), H.2897 (public safety death benefits), H.2898 (prosecutors retirement)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2c3e1a7-78b2-4c90-a136-c0a22c3f3e48',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2c3e1a7-78b2-4c90-a136-c0a22c3f3e48',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Lombardo filed H.1840 (enhance safety and security in courthouses), H.1839 (increase penalty for disorderly persons), H.2897 (public safety employee death benefits), and H.2898 (retirement rights for criminal prosecutors). These four bills collectively reflect a law-enforcement-supportive, punitive approach to criminal justice — consistent with conservative positions prioritizing public safety and police/prosecutor protections over criminal justice reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1840', 'https://malegislature.gov/Bills/194/H1839', 'https://malegislature.gov/Bills/194/H2897', 'https://malegislature.gov/Bills/194/H2898'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marc T. Lombardo / taxes -----
-- H.3163 (income tax deduction for municipal fees), H.3162 (property tax exemption for surviving spouse of blind persons)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2c3e1a7-78b2-4c90-a136-c0a22c3f3e48',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2c3e1a7-78b2-4c90-a136-c0a22c3f3e48',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lombardo filed H.3163 to create an income tax deduction for municipal and school fees, and H.3162 to extend a property tax exemption to surviving spouses of blind persons. These bills reflect a focus on tax reduction and targeted exemptions, consistent with a conservative approach that prioritizes reducing individual and household tax burdens.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3163', 'https://malegislature.gov/Bills/194/H3162'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be 2):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'e2c3e1a7-78b2-4c90-a136-c0a22c3f3e48';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'e2c3e1a7-78b2-4c90-a136-c0a22c3f3e48'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'e2c3e1a7-78b2-4c90-a136-c0a22c3f3e48'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
