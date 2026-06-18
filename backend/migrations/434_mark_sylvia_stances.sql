-- ============================================================================
-- Migration 434: Mark D. Sylvia Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Mark D. Sylvia
--   (MA State Representative, 10th Bristol District, HD-19, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 8658e02a-1456-45ba-96bb-19ff438d8e1b (external_id: -210059)

BEGIN;

-- ----- Mark D. Sylvia / climate-change -----
-- Evidence: Member of House Committee on Climate Action and Sustainability;
--   sponsored H.450 (solar customer protections), H.3256 (agricultural land for renewable energy).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8658e02a-1456-45ba-96bb-19ff438d8e1b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8658e02a-1456-45ba-96bb-19ff438d8e1b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sylvia serves on the House Committee on Climate Action and Sustainability, the legislature's primary climate policy body. He sponsored H.450 for protections for solar customers (clean energy), H.3256 for legislation relative to the separation of agricultural land for renewable energy purposes (expanding solar/wind on farmland), and serves on the Joint Committee on Environment and Natural Resources. His 10th Bristol District (Fairhaven area) is a coastal community highly vulnerable to sea level rise and climate impacts, giving him direct constituent motivation for climate action.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MDS1', 'https://malegislature.gov/Bills/194/H450', 'https://malegislature.gov/Bills/194/H3256', 'https://malegislature.gov/Committees/House/H37']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark D. Sylvia / local-environment -----
-- Evidence: Joint Committee on Environment and Natural Resources;
--   sponsored H.1058 (cranberry water use transfer program), H.3256 (agricultural/renewable).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8658e02a-1456-45ba-96bb-19ff438d8e1b',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8658e02a-1456-45ba-96bb-19ff438d8e1b',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sylvia serves on the Joint Committee on Environment and Natural Resources, the primary legislative body for local environmental protection. He sponsored H.1058 on a cranberry water use transfer program (protecting freshwater aquifers in Plymouth County cranberry growing regions), and H.3256 on separating agricultural land for renewable energy. Fairhaven is a coastal community with Buzzards Bay, which has long faced industrial contamination concerns (New Bedford Harbor Superfund site nearby). His committee role and water protection legislation reflect active local environmental protection priorities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MDS1', 'https://malegislature.gov/Bills/194/H1058', 'https://malegislature.gov/Committees/Joint/J13']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark D. Sylvia / fossil-fuels -----
-- Evidence: Sponsored H.450 (solar customer protections); H.3256 (agricultural land for
--   renewable energy purposes); House Committee on Climate Action and Sustainability.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8658e02a-1456-45ba-96bb-19ff438d8e1b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8658e02a-1456-45ba-96bb-19ff438d8e1b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Sylvia's sponsorship of H.450 protecting solar customers and H.3256 enabling renewable energy development on agricultural land reflects a pro-renewable energy position that implicitly supports transitioning away from fossil fuels. His membership on the House Committee on Climate Action and Sustainability further reinforces his pro-clean-energy stance. Fairhaven's coastal location makes it particularly vulnerable to sea level rise from climate change, giving his district strong motivation to reduce fossil fuel reliance. His renewable energy bill portfolio indicates support for an accelerated energy transition.$$,
        ARRAY['https://malegislature.gov/Bills/194/H450', 'https://malegislature.gov/Bills/194/H3256', 'https://malegislature.gov/Legislators/Profile/MDS1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8658e02a-1456-45ba-96bb-19ff438d8e1b';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '8658e02a-1456-45ba-96bb-19ff438d8e1b'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '8658e02a-1456-45ba-96bb-19ff438d8e1b'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
