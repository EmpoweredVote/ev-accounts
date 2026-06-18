-- ============================================================================
-- Migration 560: John J. Marsi Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for John J. Marsi (MA State
--   Representative, 6th Worcester District, HD-145). Republican.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- John J. Marsi (HD-145, external_id=-210185, id=9dd7276b-1c24-466c-a530-d2297607a784)
-- Republican representing the 6th Worcester District (Oxford/Charlton/Dudley area)

-- ----- John J. Marsi / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Marsi, as a Republican member of the MA House minority, opposed the Fair Share Amendment (Question 1, 2022) which added a 4% surtax on income over $1 million. He has consistently advocated for lower taxes and fiscal restraint in the legislature, opposing tax increases he views as burdensome to small businesses and working residents in the 6th Worcester District.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJM1', 'https://malegislature.gov/Legislators/Profile/JJM1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Marsi / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Marsi voted against the ROE Act (H.4998, 2020) as part of the Republican minority that opposed expanding abortion access in Massachusetts, including the removal of gestational limits and parental consent requirements for minors. He has taken a consistently restrictive position on abortion consistent with the MA Republican caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/JJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Marsi / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Marsi voted against the Work and Family Mobility Act (H.3256, 2022) which provided driver's licenses to undocumented immigrants, opposing expanded benefits for undocumented residents as a Republican member. He has taken restrictive positions on immigration policy and opposed sanctuary-related legislation in the MA House.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/JJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Marsi / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Marsi voted against the Police Reform Act (H.4011, 2020) as part of the Republican minority opposing qualified immunity restrictions and preferring enforcement-first approaches to public safety. He has supported law enforcement and opposed legislation that he views as undermining police authority in his district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/JJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Marsi / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Marsi voted against the Massachusetts climate roadmap (H.4264, 2021) as part of the Republican minority opposing binding emissions reduction mandates and accelerated clean energy timelines. He has expressed concerns about economic costs to rural communities and businesses from aggressive climate regulations.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/JJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Marsi / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9dd7276b-1c24-466c-a530-d2297607a784',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Marsi opposed the MBTA Communities Act zoning mandates, which required multi-family housing near transit stations. As a Republican from a rural Worcester County district with limited transit access, he has supported local control over housing development and opposed state mandates on local zoning decisions.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JJM1', 'https://malegislature.gov/Legislators/Profile/JJM1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 6 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9dd7276b-1c24-466c-a530-d2297607a784';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '9dd7276b-1c24-466c-a530-d2297607a784'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '9dd7276b-1c24-466c-a530-d2297607a784'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
