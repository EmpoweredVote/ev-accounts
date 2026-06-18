-- ============================================================================
-- Migration 562: Michael J. Soter Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael J. Soter (MA State
--   Representative, 8th Worcester District, HD-147). Republican.
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
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Michael J. Soter (HD-147, external_id=-210187, id=51e50b38-dbb2-4131-91bb-23c24bf6d741)
-- Republican representing the 8th Worcester District (Bellingham/Blackstone/Mendon area)

-- ----- Michael J. Soter / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Soter, as a Republican member of the MA House minority, opposed the Fair Share Amendment (Question 1, 2022) which added a 4% surtax on income over $1 million. He has consistently advocated for lower taxes and fiscal conservatism, opposing what he characterizes as tax increases harmful to businesses and working families in his Worcester County district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJS3', 'https://malegislature.gov/Legislators/Profile/MJS3/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Soter / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Soter voted against the ROE Act (H.4998, 2020) as part of the Republican minority opposing expansion of abortion access and removal of the 24-week gestational limit for non-viable pregnancies. He has consistently maintained a restrictive position on abortion in line with the MA Republican House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/MJS3']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Soter / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Soter voted against the Work and Family Mobility Act (H.3256, 2022) which granted driver's licenses to undocumented immigrants. He has taken restrictive positions on immigration, opposing policies that limit cooperation with federal immigration enforcement, and is aligned with the MA Republican caucus on immigration enforcement priorities.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/MJS3']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Soter / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Soter voted against the Police Reform Act (H.4011, 2020) as part of the Republican minority opposing limitations on qualified immunity and police certification mandates. He has prioritized law enforcement support and opposed legislation restricting police authority in his district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/MJS3']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Soter / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Soter voted against the Massachusetts climate roadmap legislation (H.4264, 2021) as part of the Republican minority opposing binding emissions reduction mandates and accelerated clean energy requirements. He has raised concerns about economic costs to businesses and residents from aggressive climate regulations.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/MJS3']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Soter / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51e50b38-dbb2-4131-91bb-23c24bf6d741',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Soter opposed the MBTA Communities Act zoning mandates requiring multi-family housing near transit stations, viewing the state mandate as an intrusion into local zoning authority. He has supported locally-controlled housing development decisions rather than state-imposed density requirements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJS3', 'https://malegislature.gov/Legislators/Profile/MJS3/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 6 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '51e50b38-dbb2-4131-91bb-23c24bf6d741';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '51e50b38-dbb2-4131-91bb-23c24bf6d741'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '51e50b38-dbb2-4131-91bb-23c24bf6d741'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
