-- ============================================================================
-- Migration 417: Kip A. Diggs Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kip A. Diggs
--   (MA State Representative, 2nd Barnstable District, HD-02).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- New topic vs 111-PATTERNS.md: data-centers = 4559b513-0fd8-4ed1-babd-f3b554162f40
-- Politician UUID: 2386732f-e3af-4b76-8c34-1c8ff7fa2f4d (external_id: -210042)

BEGIN;

-- ----- Kip A. Diggs / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Diggs serves on the Joint Committee on Health Care Financing, placing him directly in the legislative process for healthcare access and coverage policy in Massachusetts. His membership demonstrates active engagement with expanding healthcare access, prescription drug pricing, and Medicaid/MassHealth policy. He represents the 2nd Barnstable District on Cape Cod, a region where seasonal workers and fishing industry employees often lack employer-sponsored coverage, giving him strong constituent motivation to support expanded access.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD1', 'https://malegislature.gov/Committees/Joint/J22']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kip A. Diggs / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Diggs serves on the Joint Committee on Housing, directly involved in crafting housing policy for Massachusetts. His 2nd Barnstable District on Cape Cod faces one of the most severe housing affordability crises in the state, driven by vacation home demand and seasonal rental markets that displace year-round residents and workers. He backed the 2024 Affordable Homes Act and has championed workforce housing production to ensure that teachers, healthcare workers, and fishing industry employees can afford to live on the Cape.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD1', 'https://malegislature.gov/Committees/Joint/J27']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kip A. Diggs / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Diggs serves on the Joint Committee on Racial Equity, Civil Rights, and Inclusion, one of the legislature's dedicated civil rights committees. This committee assignment reflects a direct professional commitment to advancing anti-discrimination legislation, racial justice, and civil rights protections. As a Democrat representing a diverse Cape Cod district with significant Brazilian and Cape Verdean immigrant communities, he has strong constituent-based reasons to support civil rights protections and anti-discrimination measures.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD1', 'https://malegislature.gov/Committees/Joint/J37']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kip A. Diggs / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Diggs' 2nd Barnstable District on Cape Cod faces direct threats from sea level rise, coastal erosion, and ocean warming -- among the most climate-exposed districts in Massachusetts. His 2022 reelection campaign highlighted wind energy as a key issue for the district alongside challenger Susanne Conley (R), reflecting the salience of clean energy for Cape Cod voters. As a Democrat representing a coastal district, he has supported Massachusetts climate legislation and offshore wind development to address the regional climate threats his constituents face.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD1', 'https://www.capecodtimes.com/search/?q=Kip+Diggs']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kip A. Diggs / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2386732f-e3af-4b76-8c34-1c8ff7fa2f4d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$As Assistant Vice Chair of the Ways and Means Committee, Diggs plays a key role in shaping the state budget including economic development appropriations. His role gives him significant influence over state spending priorities and job-creation programs. He has supported investment in broadband infrastructure (co-signing H.101) as an economic development tool and has engaged on workforce development and economic opportunity for Cape Cod residents. His Ways and Means leadership position reflects a focus on fiscal stewardship alongside economic growth.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD1', 'https://malegislature.gov/Committees/Joint/J44']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 5 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '2386732f-e3af-4b76-8c34-1c8ff7fa2f4d';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '2386732f-e3af-4b76-8c34-1c8ff7fa2f4d'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
