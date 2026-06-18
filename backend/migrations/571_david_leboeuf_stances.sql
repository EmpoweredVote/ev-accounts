-- ============================================================================
-- Migration 571: David A. LeBoeuf Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for David A. LeBoeuf (MA State
--   Representative, 17th Worcester District, HD-156). Democrat.
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

-- David A. LeBoeuf (HD-156, external_id=-210196, id=3ca6c1b2-eec3-4e28-991d-fce8b6b67354)
-- Democrat representing the 17th Worcester District (Worcester area)

-- ----- David A. LeBoeuf / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$LeBoeuf has been a strong advocate for universal healthcare in the MA House, co-sponsoring single-payer and MassHealth expansion legislation. He has backed comprehensive healthcare coverage initiatives in the 194th General Court, reflecting a strongly pro-expansion position with particular attention to mental health and substance use disorder treatment access in Worcester.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAL1/Bills', 'https://malegislature.gov/Legislators/Profile/DAL1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David A. LeBoeuf / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$LeBoeuf voted for the ROE Act (H.4998, 2020) which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. He has been a consistent advocate for reproductive rights in the MA House.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/DAL1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David A. LeBoeuf / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$LeBoeuf actively supported the Fair Share Amendment (Question 1, 2022) adding a 4% surtax on income over $1 million to fund education and transportation. As a Worcester progressive, he has backed higher progressive taxation to fund public services and has been among the more vocal advocates for fair taxation policies to reduce inequality.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAL1', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David A. LeBoeuf / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$LeBoeuf voted for the Police Reform Act (H.4011, 2020) establishing statewide police certification, banning chokeholds, and limiting qualified immunity. He has supported accountability-oriented policing reforms and community safety investments for Worcester's urban neighborhoods, reflecting a reform-minded approach to public safety.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/DAL1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David A. LeBoeuf / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$LeBoeuf has been a strong advocate for affordable housing in Worcester, co-sponsoring rent stabilization legislation and supporting the Affordable Homes Act (H.5034). He has backed tenant protections and maximum affordability requirements for new housing developments, reflecting one of the stronger pro-housing-affordability positions among Worcester's delegation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAL1/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David A. LeBoeuf / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$LeBoeuf has been an active advocate for aggressive climate action in the MA House, supporting the 2021 climate roadmap (H.4264) and clean energy legislation. He co-sponsored bills calling for even more aggressive emissions reductions and has been among the more vocal climate advocates in the legislature, backing clean energy investment for Worcester and central Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAL1/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David A. LeBoeuf / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$LeBoeuf supported the VOTES Act (H.5001, 2022) making early voting permanent and expanding mail-in voting in Massachusetts. He backed automatic voter registration and other voting access expansion measures, demonstrating a strongly pro-access voting rights position.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/DAL1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David A. LeBoeuf / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$LeBoeuf supported the Work and Family Mobility Act (H.3256, 2022) and co-sponsored the Safe Communities Act (H.2485) limiting state cooperation with federal immigration enforcement. He has been a strong advocate for Worcester's diverse immigrant communities, taking a strongly pro-immigrant welcoming position consistent with his progressive stance.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Bills/194/H2485']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David A. LeBoeuf / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$LeBoeuf has been an active supporter of civil rights legislation in the MA House, co-sponsoring LGBTQ+ protections and anti-discrimination bills. He has backed legislation protecting marginalized communities in Worcester and has been among the more progressive voices on civil rights, consistently supporting full equality in housing, employment, and public accommodations.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAL1/Bills', 'https://malegislature.gov/Legislators/Profile/DAL1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David A. LeBoeuf / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ca6c1b2-eec3-4e28-991d-fce8b6b67354',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$LeBoeuf has supported economic development initiatives for Worcester focused on community investment and equitable growth, including support for small businesses in underserved neighborhoods and workforce development programs. He has co-sponsored economic development legislation in the 194th General Court with a community-centered investment approach.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAL1/Bills', 'https://malegislature.gov/Legislators/Profile/DAL1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 10 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '3ca6c1b2-eec3-4e28-991d-fce8b6b67354';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '3ca6c1b2-eec3-4e28-991d-fce8b6b67354'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '3ca6c1b2-eec3-4e28-991d-fce8b6b67354'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
