-- ============================================================================
-- Migration 465: Shirley A. Arriaga Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Shirley A. Arriaga (MA State Rep, 8th Hampden District, HD-50).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics): See migration 456 for full reference block.

BEGIN;

-- ============================================================================
-- Shirley A. Arriaga (HD-50, external_id=-210090)
-- UUID: 8995a410-276d-4a84-87f2-b097c1535f90
-- District: 8th Hampden (Chicopee area)
-- Democrat; committees: Public Health, Higher Education, Ways and Means.
-- ============================================================================

-- ----- Shirley A. Arriaga / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Arriaga sponsored H.799, "An Act decoupling the municipal census from voter registration," which separates the voter registration process from the annual municipal census — making it easier for residents to register and reducing administrative barriers to voting. This pro-access voting rights measure reflects support for expanding voter participation.$$,
        ARRAY['https://malegislature.gov/Bills/194/H799']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shirley A. Arriaga / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Arriaga sponsored H.2244, "An Act relative to making the charter of the city of Chicopee gender neutral," which removes gendered language from local government documentation — a gender equity measure. She also sponsored H.507, "An Act relative to the enforcement of anti-bullying policies in our schools," expanding protections for students from harassment. Both bills reflect a pattern of expanding civil rights and inclusion.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2244', 'https://malegislature.gov/Bills/194/H507']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shirley A. Arriaga / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Arriaga serves on the Joint Committee on Public Health and sponsored H.4048, "An Act to reduce infection rate post surgery," targeting hospital-acquired infection reduction — a patient safety measure improving healthcare quality. Her Public Health committee role further supports active engagement in healthcare policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H4048', 'https://malegislature.gov/Legislators/Profile/SBA1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shirley A. Arriaga / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Arriaga sponsored H.4015, "An Act promoting housing stability for older adults across the Commonwealth," which expands a short-term housing bridge pilot program to prevent homelessness among older adults — targeting a high-risk population. This bill reflects a pro-expansion approach to housing stability and support services.$$,
        ARRAY['https://malegislature.gov/Bills/194/H4015']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shirley A. Arriaga / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8995a410-276d-4a84-87f2-b097c1535f90',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Arriaga sponsored H.2065, "An Act relative to a four-day work week pilot program," which would allow state agencies and potentially private employers to pilot a shorter work week — a labor-quality-of-life measure. This reflects a labor-friendly, worker-centered approach to economic development.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2065']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 5 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8995a410-276d-4a84-87f2-b097c1535f90';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '8995a410-276d-4a84-87f2-b097c1535f90'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '8995a410-276d-4a84-87f2-b097c1535f90'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
