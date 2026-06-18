-- ============================================================================
-- Migration 569: Mary S. Keefe Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Mary S. Keefe (MA State
--   Representative, 15th Worcester District, HD-154). Democrat.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
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

-- Mary S. Keefe (HD-154, external_id=-210194, id=a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c)
-- Democrat representing the 15th Worcester District (Worcester area)

-- ----- Mary S. Keefe / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Keefe has been a strong advocate for healthcare access in Worcester, serving on health-related committees and co-sponsoring legislation expanding MassHealth coverage and mental health services. She has backed single-payer healthcare concepts and universal coverage legislation in the 194th General Court, reflecting a strongly pro-expansion position on state healthcare.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MSK1/Bills', 'https://malegislature.gov/Legislators/Profile/MSK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary S. Keefe / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Keefe voted for the ROE Act (H.4998, 2020) which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. She has been a consistent advocate for reproductive rights in the MA House.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/MSK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary S. Keefe / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Keefe actively supported the Fair Share Amendment (Question 1, 2022) adding a 4% surtax on income over $1 million. Representing a working-class Worcester district, she has been a strong advocate for progressive taxation to fund public education, healthcare, and transportation infrastructure, consistently backing higher taxes on wealthy residents and corporations.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MSK1', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary S. Keefe / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Keefe voted for the Police Reform Act (H.4011, 2020) establishing statewide police certification, banning chokeholds, and limiting qualified immunity. She has supported accountability-oriented policing reforms alongside community safety investments for Worcester's urban communities.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/MSK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary S. Keefe / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Keefe has been a strong advocate for affordable housing and tenant protections in Worcester, co-sponsoring rent stabilization legislation and supporting the Affordable Homes Act (H.5034). She has backed maximum housing affordability production requirements and tenant protections, reflecting a strongly pro-affordability position.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MSK1/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary S. Keefe / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Keefe supported the Massachusetts climate roadmap (H.4264, 2021) and has been an active advocate for clean energy transition in the MA House. She backed the 2022 clean energy legislation and has supported aggressive emissions reductions, offshore wind expansion, and clean energy investment for Worcester and central Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MSK1/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary S. Keefe / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Keefe supported the VOTES Act (H.5001, 2022) making early voting permanent and expanding mail-in voting in Massachusetts. She has backed automatic voter registration and other voting access expansion measures, demonstrating a strongly pro-access position on voting rights.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/MSK1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary S. Keefe / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Keefe supported the Work and Family Mobility Act (H.3256, 2022) providing driver's licenses to undocumented immigrants and has co-sponsored the Safe Communities Act limiting state cooperation with federal immigration enforcement. She has been a strong advocate for Worcester's diverse immigrant communities, taking a strongly welcoming immigration position.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Bills/194/H2485']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary S. Keefe / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Keefe has been an active supporter of civil rights legislation in the MA House, co-sponsoring anti-discrimination bills and LGBTQ+ protections. She backed the 2016 MA Transgender Equal Rights bill and has consistently supported legislation protecting marginalized communities from discrimination, reflecting a strongly pro-civil-rights position from her Worcester district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MSK1/Bills', 'https://malegislature.gov/Legislators/Profile/MSK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary S. Keefe / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Keefe has supported economic development initiatives for Worcester, including support for the biotech corridor, university partnerships, and small business development programs. She has co-sponsored economic development legislation in the 194th General Court focused on community investment and job creation in Worcester's urban neighborhoods.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MSK1/Bills', 'https://malegislature.gov/Legislators/Profile/MSK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 10 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
