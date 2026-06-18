-- ============================================================================
-- Migration 491: Bradley H. Jones Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Bradley H. Jones (MA House HD-76,
--   20th Middlesex District). External ID: -210116.
--   Jones is the House Republican Minority Leader.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 12 rows in DB, 10 at 4.0 (evidence-backed conservative
--   positions), climate-change=3.0 and fossil-fuels=3.0 (evidence-backed neutral).
--   This migration adds data-centers as a new topic with evidence.
--   Existing rows are left untouched as they already have reasoning and sources.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Bradley H. Jones (HD-76, external_id=-210116)
-- Politician UUID: a6e1a867-1e4e-449f-bb10-4f55449762bf

-- ----- Bradley H. Jones / data-centers -----
-- New topic: sponsored H.83 to study AI data center load growth impact on MA grid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6e1a867-1e4e-449f-bb10-4f55449762bf',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6e1a867-1e4e-449f-bb10-4f55449762bf',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Jones filed H.83, "An Act to study the impact of artificial intelligence and data centers on the Commonwealth's electric load growth," establishing a commission to evaluate the grid impact of AI data center expansion in Massachusetts. His approach is study-first rather than either permissive or restrictive — reflecting a cautious, technology-neutral stance on data center development.$$,
        ARRAY['https://malegislature.gov/Bills/194/H83'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be 13 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a6e1a867-1e4e-449f-bb10-4f55449762bf';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a6e1a867-1e4e-449f-bb10-4f55449762bf'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a6e1a867-1e4e-449f-bb10-4f55449762bf'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
