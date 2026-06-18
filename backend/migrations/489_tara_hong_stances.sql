-- ============================================================================
-- Migration 489: Tara T. Hong Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Tara T. Hong (MA House HD-74,
--   18th Middlesex District). External ID: -210114.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Tara T. Hong (HD-74, external_id=-210114)
-- Politician UUID: 18477533-2ddf-47dd-8fc3-8eb8e65ccb2f

-- ----- Tara T. Hong / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Hong serves on the Joint Committee on Community Development and Small Businesses. She also filed H.733, "An Act relative to educator pay," addressing compensation equity in public education. These roles reflect engagement with worker-protective and community development economic policies.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/TTH1/Committees', 'https://malegislature.gov/Bills/194/H733'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tara T. Hong / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Hong serves on the Joint Committee on Environment and Natural Resources — a direct assignment to the primary environment committee in the MA Legislature. This committee assignment demonstrates direct engagement with local environmental protection legislation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/TTH1/Committees', 'https://malegislature.gov/Committees/Detail/J21'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tara T. Hong / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Hong filed H.1526, "An Act establishing a rent stabilization commission," which would create a state body to study and recommend rent stabilization policies for Massachusetts. This bill directly reflects support for rent regulation as a tool for housing affordability.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1526'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tara T. Hong / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hong filed H.3129, "An Act aligning the long-term capital gains tax rate with the short-term capital gains tax rate," which would raise the long-term capital gains tax in Massachusetts to match the short-term rate. This bill reflects a progressive tax position, reducing preferential treatment for investment income over earned income.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3129'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tara T. Hong / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18477533-2ddf-47dd-8fc3-8eb8e65ccb2f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hong serves on the Joint Committee on Election Laws, which oversees voting rights and election legislation in Massachusetts. She also filed H.603, "An Act relative to enhancing civic education in Massachusetts public schools," promoting civic engagement. Her Election Laws committee role demonstrates direct engagement with voting rights policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/TTH1/Committees', 'https://malegislature.gov/Committees/Detail/J15', 'https://malegislature.gov/Bills/194/H603'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be 5):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '18477533-2ddf-47dd-8fc3-8eb8e65ccb2f';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '18477533-2ddf-47dd-8fc3-8eb8e65ccb2f'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
