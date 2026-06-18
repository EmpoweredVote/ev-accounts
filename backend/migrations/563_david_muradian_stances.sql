-- ============================================================================
-- Migration 563: David K. Muradian Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for David K. Muradian (MA State
--   Representative, 9th Worcester District, HD-148). Republican.
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

BEGIN;

-- David K. Muradian (HD-148, external_id=-210188, id=891030da-39e2-496f-8a20-72aeb27093ba)
-- Republican representing the 9th Worcester District (Grafton/Upton area)

-- ----- David K. Muradian / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Muradian, as a Republican member of the MA House minority, opposed the Fair Share Amendment (Question 1, 2022) adding a 4% surtax on income over $1 million. He has supported lower taxes and fiscal restraint in the legislature, opposing tax increases he views as harmful to small businesses and residents in suburban Worcester County.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DKM1', 'https://malegislature.gov/Legislators/Profile/DKM1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David K. Muradian / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Muradian voted against the ROE Act (H.4998, 2020) as part of the Republican minority opposing expanded abortion access and removal of the 24-week gestational limit. He has consistently maintained a restrictive position on abortion consistent with the MA Republican House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/DKM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David K. Muradian / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Muradian voted against the Work and Family Mobility Act (H.3256, 2022) granting driver's licenses to undocumented immigrants. He has taken restrictive positions on immigration enforcement, opposing policies that limit cooperation with federal immigration authorities, consistent with the MA Republican caucus.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/DKM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David K. Muradian / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Muradian voted against the Police Reform Act (H.4011, 2020) as part of the Republican minority opposing limitations on qualified immunity and new police certification requirements. He has prioritized law enforcement and public safety through traditional enforcement-first approaches.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/DKM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David K. Muradian / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Muradian voted against the Massachusetts climate roadmap (H.4264, 2021) as part of the Republican minority opposing binding emissions reduction mandates. He has expressed concerns about the economic impact of aggressive climate legislation on businesses and residents in his suburban Worcester County district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/DKM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David K. Muradian / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('891030da-39e2-496f-8a20-72aeb27093ba',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Muradian opposed the MBTA Communities Act zoning mandates requiring multi-family housing near transit stations, supporting local control over zoning decisions. He has advocated for locally-determined housing development and opposed state mandates imposed on suburban communities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DKM1', 'https://malegislature.gov/Legislators/Profile/DKM1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 6 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '891030da-39e2-496f-8a20-72aeb27093ba';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '891030da-39e2-496f-8a20-72aeb27093ba'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '891030da-39e2-496f-8a20-72aeb27093ba'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
