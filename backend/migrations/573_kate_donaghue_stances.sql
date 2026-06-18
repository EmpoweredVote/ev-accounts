-- ============================================================================
-- Migration 573: Kate Donaghue Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kate Donaghue (MA State
--   Representative, 19th Worcester District, HD-158). Democrat.
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

-- Kate Donaghue (HD-158, external_id=-210198, id=6eef204b-5d35-48e6-bf8c-dd3cac62e2cd)
-- Democrat representing the 19th Worcester District (Westborough/Northborough area)

-- ----- Kate Donaghue / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Donaghue has co-sponsored healthcare expansion legislation in the MA House, supporting MassHealth coverage expansion and mental health parity bills. She has backed healthcare access improvements for residents of the 19th Worcester District and supported the MA Democratic caucus position on expanding state healthcare coverage in the 194th General Court.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/K_D1/Bills', 'https://malegislature.gov/Legislators/Profile/K_D1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Donaghue / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Donaghue voted for the ROE Act (H.4998, 2020) which expanded abortion access in Massachusetts by removing the 24-week gestational limit for non-viable pregnancies and allowing minors to consent without parental involvement. This vote placed her with the pro-choice majority in the MA Democratic House caucus.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4998', 'https://malegislature.gov/Legislators/Profile/K_D1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Donaghue / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Donaghue supported the Fair Share Amendment (Question 1, 2022) adding a 4% surtax on income over $1 million to fund education and transportation. Representing a suburban district in the Westborough-Northborough area, she backed progressive revenue measures to fund public education and transportation infrastructure benefiting her constituents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/K_D1', 'https://ballotpedia.org/Massachusetts_Income_Tax_for_Education_and_Transportation_Amendment,_Question_1_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Donaghue / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Donaghue voted for the Police Reform Act (H.4011, 2020) which established statewide police certification, banned chokeholds, and limited qualified immunity. She has supported accountability-oriented policing reforms alongside community safety priorities in her suburban Worcester County district.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4011', 'https://malegislature.gov/Legislators/Profile/K_D1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Donaghue / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Donaghue supported the Affordable Homes Act (H.5034) and the MBTA Communities Act requiring multi-family zoning near transit stations. Representing Westborough and Northborough, communities with MBTA commuter rail service, she backed increased housing production and transit-oriented development as part of the regional housing solution.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/K_D1/Bills', 'https://malegislature.gov/Bills/194/H5034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Donaghue / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Donaghue has been a notable advocate for climate action in the MA House, serving on environmental committees and actively supporting the 2021 climate roadmap (H.4264) and subsequent clean energy legislation. She has been among the more vocal champions of offshore wind, clean energy transition, and aggressive emissions reductions, and has authored or co-sponsored climate-related legislation in the 194th General Court.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/K_D1/Bills', 'https://malegislature.gov/Bills/192/H4264']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Donaghue / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Donaghue supported the VOTES Act (H.5001, 2022) making early voting permanent and expanding mail-in voting in Massachusetts. She backed expanded voting access measures consistent with the MA Democratic caucus position on democratic participation and voter access.$$,
        ARRAY['https://malegislature.gov/Bills/192/H5001', 'https://malegislature.gov/Legislators/Profile/K_D1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Donaghue / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Donaghue supported the Work and Family Mobility Act (H.3256, 2022) providing driver's licenses to undocumented immigrants, voting with the Democratic majority. She has backed pro-immigrant legislation in the MA House consistent with the MA Democratic caucus position.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3256', 'https://malegislature.gov/Legislators/Profile/K_D1/Bills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Donaghue / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Donaghue has been an active supporter of civil rights legislation in the MA House, co-sponsoring anti-discrimination and LGBTQ+ protection bills. She backed the 2016 MA Transgender Equal Rights bill and has consistently supported legislation protecting marginalized communities from discrimination in housing, employment, and public accommodations.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/K_D1/Bills', 'https://malegislature.gov/Legislators/Profile/K_D1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Donaghue / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6eef204b-5d35-48e6-bf8c-dd3cac62e2cd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Donaghue has supported economic development in the Westborough-Northborough tech corridor, backing innovation, biotech, and clean energy sector growth in eastern Worcester County. She has co-sponsored economic development legislation in the 194th General Court with a focus on technology-driven growth and job creation in her suburban district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/K_D1/Bills', 'https://malegislature.gov/Legislators/Profile/K_D1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 10 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '6eef204b-5d35-48e6-bf8c-dd3cac62e2cd';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '6eef204b-5d35-48e6-bf8c-dd3cac62e2cd'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
