-- ============================================================================
-- Migration 457: Susannah L. Whipps Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Susannah L. Whipps (MA State Rep, 2nd Franklin District, HD-42).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, 44 active as of 2026-06-11):
-- See migration 456 for full reference block.

BEGIN;

-- ============================================================================
-- Susannah L. Whipps (HD-42, external_id=-210082)
-- UUID: 9081c52c-92ea-4a75-84b1-96305fafd333
-- District: 2nd Franklin (Athol/Orange area)
-- Unenrolled (independent); moderate; committees: Aging, Higher Education, Mental Health/Substance Use.
-- Thin legislative record on compass topics; evidence only for 3 topics.
-- ============================================================================

-- ----- Susannah L. Whipps / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9081c52c-92ea-4a75-84b1-96305fafd333',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9081c52c-92ea-4a75-84b1-96305fafd333',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Whipps serves on the Joint Committee on Mental Health, Substance Use and Recovery, which shapes state policy on behavioral health access, substance use treatment, and mental health services. She also sponsored H.752, "An Act strengthening transitional planning and increasing accountability for persons with disabilities and their families," reflecting support for expanding healthcare and support systems for vulnerable populations.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SLG1/Committees', 'https://malegislature.gov/Bills/194/H752']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susannah L. Whipps / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9081c52c-92ea-4a75-84b1-96305fafd333',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9081c52c-92ea-4a75-84b1-96305fafd333',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Whipps sponsored H.4228, "An Act providing for rent regulation and control of evictions in manufactured housing parks in the town of Athol," which specifically enables rent stabilization protections for residents of manufactured housing parks in her district. This direct sponsorship of local rent regulation legislation is clear evidence of support for tenant protections in her community.$$,
        ARRAY['https://malegislature.gov/Bills/194/H4228']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Susannah L. Whipps / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9081c52c-92ea-4a75-84b1-96305fafd333',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9081c52c-92ea-4a75-84b1-96305fafd333',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Whipps sponsored H.3814, "An Act increasing the penalties for criminal conduct in passing a stopped school bus," which emphasizes traditional enforcement-focused public safety measures protecting children. At the same time, her role on the Mental Health and Substance Use Recovery committee shows support for treatment-based approaches. The combined evidence suggests a centrist position balancing enforcement and treatment.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3814', 'https://malegislature.gov/Legislators/Profile/SLG1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 3 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9081c52c-92ea-4a75-84b1-96305fafd333';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '9081c52c-92ea-4a75-84b1-96305fafd333'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '9081c52c-92ea-4a75-84b1-96305fafd333'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
