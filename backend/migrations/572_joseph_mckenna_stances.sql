-- ============================================================================
-- Migration 572: Joseph D. McKenna Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Joseph D. McKenna (MA State
--   Representative, 18th Worcester District, HD-157). Republican.
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

-- Joseph D. McKenna (HD-157, external_id=-210197, id=2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a)
-- Republican representing the 18th Worcester District (Webster/Oxford/Dudley area)

-- ----- Joseph D. McKenna / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$McKenna, as a Republican member of the MA House minority, opposed the Fair Share Amendment (Question 1, 2022) adding a 4% surtax on income over $1 million. He has consistently advocated for lower taxes and fiscal conservatism, opposing tax increases he characterizes as harmful to businesses and working families in his southern Worcester County district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JDM1', 'https://malegislature.gov/Legislators/Profile/JDM1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph D. McKenna / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$McKenna voted against the ROE Act (H.4998, 2020) as part of the Republican minority opposing expansion of abortion access and removal of the 24-week gestational limit. He has maintained a restrictive position on abortion consistent with the MA Republican House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/JDM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph D. McKenna / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McKenna voted against the Work and Family Mobility Act (H.3256, 2022) granting driver's licenses to undocumented immigrants. He has taken restrictive positions on immigration enforcement, opposing policies that limit cooperation with federal immigration authorities, consistent with the MA Republican caucus.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/JDM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph D. McKenna / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$McKenna voted against the Police Reform Act (H.4011, 2020) as part of the Republican minority opposing limitations on qualified immunity and new police certification requirements. He has prioritized law enforcement support and opposed legislation restricting police authority in his district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/JDM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph D. McKenna / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McKenna voted against the Massachusetts climate roadmap (H.4264, 2021) as part of the Republican minority opposing binding emissions reduction mandates. He has raised concerns about economic costs of aggressive climate legislation on businesses and residents in his rural southern Worcester County district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/JDM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph D. McKenna / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McKenna opposed the MBTA Communities Act zoning mandates requiring multi-family housing near transit stations, supporting local control over housing development. As a Republican from a largely rural/suburban district in southern Worcester County, he has backed locally-determined housing decisions rather than state-imposed density requirements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JDM1', 'https://malegislature.gov/Legislators/Profile/JDM1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 6 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
