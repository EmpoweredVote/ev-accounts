-- ============================================================================
-- Migration 444: Hannah L. Bowen Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Hannah L. Bowen (MA State Rep, HD-29,
--   6th Essex District, Beverly).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: b651cf67-37b4-4cbf-afcd-088010247788 (external_id=-210069)

BEGIN;

-- ----- Hannah L. Bowen / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b651cf67-37b4-4cbf-afcd-088010247788',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b651cf67-37b4-4cbf-afcd-088010247788',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Bowen co-sponsored H.4568 for legislation to expand access to the Family Self-Sufficiency Program — a HUD program that helps housing assistance recipients build assets toward homeownership and economic independence. She also serves on the Joint Committee on Housing, a direct legislative focus on housing policy. Her committee role and sponsored bill reflect a priority for expanding housing access for lower-income families.$$,
        ARRAY['https://malegislature.gov/Bills/194/H4568', 'https://malegislature.gov/Legislators/Profile/HLB1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hannah L. Bowen / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b651cf67-37b4-4cbf-afcd-088010247788',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b651cf67-37b4-4cbf-afcd-088010247788',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Bowen serves on the Joint Committee on Transportation in the 194th General Court, indicating a sustained focus on transportation policy. Representing Beverly on the North Shore, where commuter rail and road connectivity to Boston are significant issues, her committee assignment reflects transportation as a legislative priority.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/HLB1/Committees', 'https://malegislature.gov/Legislators/Profile/HLB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hannah L. Bowen / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b651cf67-37b4-4cbf-afcd-088010247788',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b651cf67-37b4-4cbf-afcd-088010247788',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Bowen serves on the Joint Committee on Labor and Workforce Development, reflecting a focus on worker economic development, job training, and workforce policy. She also co-sponsored H.4568 on the Family Self-Sufficiency Program, a workforce development and asset-building initiative for housing assistance recipients. Her committee role links labor and economic development as complementary legislative priorities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/HLB1/Committees', 'https://malegislature.gov/Bills/194/H4568']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'b651cf67-37b4-4cbf-afcd-088010247788';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'b651cf67-37b4-4cbf-afcd-088010247788'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'b651cf67-37b4-4cbf-afcd-088010247788'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
