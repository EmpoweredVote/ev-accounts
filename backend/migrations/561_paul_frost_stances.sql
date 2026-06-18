-- ============================================================================
-- Migration 561: Paul K. Frost Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Paul K. Frost (MA State
--   Representative, 7th Worcester District, HD-146). Republican.
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

-- Paul K. Frost (HD-146, external_id=-210186, id=799c1cea-4020-4c50-b7d1-1e9aac867529)
-- Republican representing the 7th Worcester District (Auburn/Millbury area)

-- ----- Paul K. Frost / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Frost, as a Republican member of the MA House minority, opposed the Fair Share Amendment (Question 1, 2022) adding a 4% surtax on income over $1 million. He has consistently advocated for lower taxes and fiscal conservatism, opposing tax increases that he views as harmful to small businesses and residents in the Auburn-Millbury area.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PKF1', 'https://malegislature.gov/Legislators/Profile/PKF1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul K. Frost / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Frost voted against the ROE Act (H.4998, 2020) as part of the Republican minority opposing expansion of abortion access, including removal of the 24-week gestational limit for non-viable pregnancies. He has maintained a restrictive position on abortion consistent with the MA Republican caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/PKF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul K. Frost / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Frost voted against the Work and Family Mobility Act (H.3256, 2022) providing driver's licenses to undocumented immigrants, opposing expanded benefits for undocumented residents. He has taken restrictive positions on immigration enforcement and opposed policies limiting cooperation with federal immigration authorities.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/PKF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul K. Frost / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Frost voted against the Police Reform Act (H.4011, 2020) as part of the Republican minority, opposing qualified immunity restrictions and police certification mandates. He has supported law enforcement priorities and opposed legislation limiting police authority, reflecting the MA Republican caucus's enforcement-first approach to public safety.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/PKF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul K. Frost / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Frost voted against the Massachusetts climate roadmap (H.4264, 2021) as part of the Republican minority opposing binding emissions reductions and accelerated clean energy mandates. He has expressed concerns about economic impacts of climate legislation on businesses and residents in central Worcester County.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/PKF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul K. Frost / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('799c1cea-4020-4c50-b7d1-1e9aac867529',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Frost opposed the MBTA Communities Act zoning requirements, which mandated multi-family housing near transit stations. As a Republican from a suburban Worcester County district, he has supported local zoning control and opposed state mandates requiring municipalities to change local housing policies.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PKF1', 'https://malegislature.gov/Legislators/Profile/PKF1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 6 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '799c1cea-4020-4c50-b7d1-1e9aac867529';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '799c1cea-4020-4c50-b7d1-1e9aac867529'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '799c1cea-4020-4c50-b7d1-1e9aac867529'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
