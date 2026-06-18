-- ============================================================================
-- Migration 433: Christopher M. Markey Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Christopher M. Markey
--   (MA State Representative, 9th Bristol District, HD-18, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- NOTE: Pre-existing rows exist for 12 topics from a prior agent run.
--   Several pre-existing rows have value=3.0 "did not co-sponsor" neutral defaults
--   which are out of scope to fix per scope boundary rules. This migration UPSERTS
--   topics where direct evidence exists, improving or adding to the record.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 2270da0d-09e7-40b4-858f-fe25bc822916 (external_id: -210058)

BEGIN;

-- ----- Christopher M. Markey / civil-rights -----
-- Evidence: Co-sponsored the Healthy Youth Act (LGBTQ+-inclusive sex ed) per AOM tracker.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2270da0d-09e7-40b4-858f-fe25bc822916',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2270da0d-09e7-40b4-858f-fe25bc822916',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Markey co-sponsored the Healthy Youth Act per the Act on Mass tracker, which mandates LGBTQ+-inclusive comprehensive sex education in Massachusetts public schools. He also sponsored H.264 on supported decision-making agreements for people with disabilities. These co-sponsorships reflect a pro-civil-rights stance covering LGBTQ+ inclusion and disability rights. Despite Markey's generally moderate positioning on some issues (notably abortion), his explicit co-sponsorship of the Healthy Youth Act demonstrates active support for LGBTQ+ civil rights in education.$$,
        ARRAY['https://actonmass.org/legislators/christopher-markey/', 'https://malegislature.gov/Bills/194/H264', 'https://malegislature.gov/Legislators/Profile/CMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher M. Markey / public-safety-approach -----
-- Evidence: Running for Bristol County DA in 2026 emphasizing prosecution-first approach;
--   sponsored H.1865 (enhanced penalties for high-speed chases), H.1869 (prosecution of
--   juveniles solicited to commit murder); Joint Committee on the Judiciary.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2270da0d-09e7-40b4-858f-fe25bc822916',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2270da0d-09e7-40b4-858f-fe25bc822916',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Markey is running for Bristol County District Attorney in 2026, positioning himself as a traditional prosecutor focused on crime enforcement. He sponsored H.1865 (enhanced penalties for causing high-speed chases), H.1869 (prosecution of adults who solicit juveniles under 18 to commit murder), and H.1868 (addressing defendant failure to appear at trial). His Joint Committee on the Judiciary assignment combined with his DA candidacy and prosecution-oriented bill portfolio reflects a law-enforcement-first approach to public safety.$$,
        ARRAY['https://actonmass.org/legislators/christopher-markey/', 'https://malegislature.gov/Bills/194/H1865', 'https://malegislature.gov/Bills/194/H1869', 'https://malegislature.gov/Legislators/Profile/CMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher M. Markey / healthcare -----
-- Evidence: Joint Committee on Mental Health, Substance Use and Recovery;
--   sponsored H.1387 (reimbursement for acute hospitals serving low-income patients).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2270da0d-09e7-40b4-858f-fe25bc822916',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2270da0d-09e7-40b4-858f-fe25bc822916',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Markey serves on the Joint Committee on Mental Health, Substance Use and Recovery, directly engaging with healthcare access for some of Massachusetts' most vulnerable populations. He sponsored H.1387 for reimbursement for acute hospitals serving low-income patients, improving financial stability for safety-net hospitals. His 9th Bristol District (Dartmouth area) has significant substance use and mental health challenges. His committee assignment and hospital access legislation reflect active engagement with expanding healthcare access for underserved communities.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1387', 'https://malegislature.gov/Legislators/Profile/CMM1', 'https://actonmass.org/legislators/christopher-markey/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '2270da0d-09e7-40b4-858f-fe25bc822916';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '2270da0d-09e7-40b4-858f-fe25bc822916'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '2270da0d-09e7-40b4-858f-fe25bc822916'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
