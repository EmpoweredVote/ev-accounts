-- ============================================================================
-- Migration 565: Hannah E. Kane Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Hannah E. Kane (MA State
--   Representative, 11th Worcester District, HD-150). Republican.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb

BEGIN;

-- Hannah E. Kane (HD-150, external_id=-210190, id=d54b9791-0668-4397-b488-160d06f7c420)
-- Republican representing the 11th Worcester District (Shrewsbury area)
-- Moderate Republican; has split with caucus on some issues (climate, healthcare)

-- ----- Hannah E. Kane / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Kane, as a Republican member of the MA House, opposed the Fair Share Amendment (Question 1, 2022) adding a 4% surtax on income over $1 million. She has generally supported fiscal conservatism and lower taxes, though she is considered a moderate Republican who has on occasion supported targeted revenue measures for specific public investments.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/HEK1', 'https://malegislature.gov/Legislators/Profile/HEK1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hannah E. Kane / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Kane voted against the ROE Act (H.4998, 2020) as part of the Republican minority opposing expanded abortion access. While she is a moderate Republican on many issues, she voted against the ROE Act's removal of gestational limits and parental consent requirements for minors.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/HEK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hannah E. Kane / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Kane is a moderate Republican who has supported some clean energy legislation, including aspects of the 2022 clean energy and climate bill. She has been more open to climate action than many House Republicans, acknowledging the need for clean energy while raising concerns about economic impacts on her suburban Shrewsbury constituents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/HEK1/Bills', 'https://malegislature.gov/Legislators/Profile/HEK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hannah E. Kane / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Kane voted against the Work and Family Mobility Act (H.3256, 2022) granting driver's licenses to undocumented immigrants, voting with the Republican minority on immigration enforcement. While a moderate Republican on some issues, she has taken restrictive positions on immigration consistent with her party.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/HEK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hannah E. Kane / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Kane took a moderate position on the Police Reform Act (H.4011, 2020), generally supporting stronger law enforcement while acknowledging the need for some accountability measures. As a moderate Republican, she has navigated between traditional enforcement support and recognition of reform needs in her suburban Shrewsbury district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/HEK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hannah E. Kane / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kane has taken a nuanced position on housing, supporting some aspects of the MBTA Communities Act while raising concerns about implementation for suburban communities. As a moderate Republican from Shrewsbury, she has acknowledged the housing crisis while also advocating for local control over zoning decisions.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/HEK1/Bills', 'https://malegislature.gov/Legislators/Profile/HEK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hannah E. Kane / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kane has supported economic development legislation for the Shrewsbury area and greater Worcester County, backing technology sector growth and small business support programs. She has taken a balanced approach to economic development that supports both public investment and private sector activity in her district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/HEK1/Bills', 'https://malegislature.gov/Legislators/Profile/HEK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hannah E. Kane / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d54b9791-0668-4397-b488-160d06f7c420',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kane has taken a moderate position on healthcare, supporting some expansions of MassHealth coverage while also advocating for cost containment and market-based approaches. As a moderate Republican, she has supported targeted healthcare improvements for constituents while opposing broader single-payer expansions.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/HEK1/Bills', 'https://malegislature.gov/Legislators/Profile/HEK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'd54b9791-0668-4397-b488-160d06f7c420';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'd54b9791-0668-4397-b488-160d06f7c420'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'd54b9791-0668-4397-b488-160d06f7c420'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
