-- ============================================================================
-- Migration 454: Francisco E. Paulino Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Francisco E. Paulino (MA State Rep,
--   HD-39, 16th Essex District, Methuen).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 77ceaab2-846e-4bc8-b09d-faff40ddbc60 (external_id=-210079)

BEGIN;

-- ----- Francisco E. Paulino / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Paulino serves on the House Committee on Climate Action and Sustainability in the 194th General Court — a standing committee dedicated to advancing climate policy, clean energy, and environmental sustainability in Massachusetts. His committee membership reflects an active institutional role in shaping the Commonwealth's response to climate change.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/FEP1/Committees', 'https://malegislature.gov/Legislators/Profile/FEP1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Francisco E. Paulino / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Paulino co-sponsored Age of Criminal Majority to 21 legislation as tracked by Act on Mass (green checkmark) — a bill to raise the age of adult criminal culpability, recognizing the developmental differences of young adults in the justice system. He also sponsored H.1929 to expand juvenile court justice access, reflecting a consistent criminal justice reform orientation. His H.1928 on accomplice and joint venture liability further reflects attention to fair criminal sentencing.$$,
        ARRAY['https://actonmass.org/legislators/francisco-paulino/', 'https://malegislature.gov/Bills/194/H1929', 'https://malegislature.gov/Bills/194/H1928']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Francisco E. Paulino / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Paulino sponsored H.3208 to establish a sales tax on digital advertising services in Massachusetts — a targeted tax on large technology companies' advertising revenue to generate state revenue. He serves on the Joint Committee on Revenue, giving him a direct role in shaping Massachusetts tax policy. His digital advertising tax reflects a progressive approach to taxing technology platforms.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3208', 'https://malegislature.gov/Legislators/Profile/FEP1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Francisco E. Paulino / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Paulino sponsored H.2677 to establish a minority recruitment and selection program — directly addressing economic equity for underrepresented communities in workforce development. He also sponsored H.2074 protecting wages of employees who receive wages through electronic wage cards (a worker protection against exploitative fee structures) and H.451 relative to professional licensure and citizenship (removing citizenship barriers to professional licensing). These bills reflect economic development and equity priorities for his Methuen district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2677', 'https://malegislature.gov/Bills/194/H2074', 'https://malegislature.gov/Bills/194/H451']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Francisco E. Paulino / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('77ceaab2-846e-4bc8-b09d-faff40ddbc60',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Paulino sponsored H.1931 to enhance protections against child exploitation and misuse of emerging technology — a direct AI and emerging technology safety bill focused on protecting children from deepfakes and AI-generated exploitation material. He also sponsored H.1280 regulating insurance coverage for the testing and deployment of autonomous vehicles. These two bills reflect engagement with AI and emerging technology policy from a public safety and consumer protection angle.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1931', 'https://malegislature.gov/Bills/194/H1280']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '77ceaab2-846e-4bc8-b09d-faff40ddbc60';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '77ceaab2-846e-4bc8-b09d-faff40ddbc60'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '77ceaab2-846e-4bc8-b09d-faff40ddbc60'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
