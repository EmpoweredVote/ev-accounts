-- ============================================================================
-- Migration 391: Cynthia F. Friedman Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Cynthia F. Friedman (MA State Senator, 25D16).
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
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Cynthia F. Friedman (25D16, external_id=-210016)
-- Politician UUID: 248f76d7-e76a-49e5-88b7-dc43a3131329

-- ----- Cynthia F. Friedman / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Cynthia F. Friedman has been a strong supporter of reproductive rights, voting for the ROE Act and subsequent abortion protection legislation. She backed the 2022 shield law protecting Massachusetts providers following the Dobbs decision. As a Democrat representing the Burlington-Woburn area, she has aligned with the progressive majority in protecting abortion access as a fundamental healthcare right.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CFF0', 'https://ballotpedia.org/Cynthia_Friedman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia F. Friedman / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cynthia F. Friedman supported the 2021 Massachusetts Climate Act and has backed clean energy development. Her district in the outer Boston suburban ring has many commuters and homeowners interested in energy efficiency and clean energy. She has supported solar energy programs, offshore wind development, and the state's clean energy transition. She approaches climate action pragmatically, balancing environmental goals with economic impacts on residents.$$,
        ARRAY['https://malegislature.gov/Bills/192/S9', 'https://malegislature.gov/Legislators/Profile/CFF0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia F. Friedman / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Cynthia F. Friedman has supported economic development investments for her district, which includes Route 128 corridor communities. She has backed life sciences, tech industry, and clean energy economic development. She supported the state's economic development bills and has worked to bring state investment to her suburban district, including workforce training and small business support.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CFF0', 'https://ballotpedia.org/Cynthia_Friedman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia F. Friedman / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cynthia F. Friedman has supported healthcare access expansion, mental health reform, and substance use treatment. She has backed MassHealth expansions and behavioral health legislation. She has focused on opioid recovery resources and mental health services as key priorities for her district communities. She supports the state's universal healthcare model and has backed incremental improvements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CFF0', 'https://ballotpedia.org/Cynthia_Friedman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia F. Friedman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cynthia F. Friedman backed the Affordable Homes Act and the MBTA Communities zoning requirements. Her district includes suburban communities where housing affordability is an acute concern and zoning reform has been politically sensitive. She has supported state mandates for multi-family housing near transit while also working with local communities to manage growth. She balances production needs with local concerns.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CFF0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia F. Friedman / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cynthia F. Friedman supported the Work and Family Mobility Act and has backed generally immigrant-friendly policies. Her district includes communities with diverse immigrant populations, including tech workers and longtime immigrant families. She has supported immigrant integration programs while also voicing concern about fiscal impacts of the emergency shelter system expansion.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/CFF0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia F. Friedman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cynthia F. Friedman supported the Fair Share Amendment and has backed progressive tax policies. She has supported using Fair Share revenue for education and transportation investments that benefit her district. Her approach on taxes is moderately progressive, supporting investments in public services while being attentive to impacts on middle-class homeowners in her suburban communities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CFF0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia F. Friedman / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Cynthia F. Friedman has advocated for MBTA improvements for her district, including the Lowell Line and bus rapid transit connections. She has backed transit funding as a way to reduce traffic congestion and greenhouse gas emissions. She supports both transit investment and highway maintenance for her suburban district where most residents commute by car.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CFF0', 'https://ballotpedia.org/Cynthia_Friedman']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia F. Friedman / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('248f76d7-e76a-49e5-88b7-dc43a3131329',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Cynthia F. Friedman backed the VOTES Act making early voting and vote-by-mail permanent and has supported voting rights expansion. She has aligned with the Democratic majority on measures to make voting more accessible, including automatic voter registration. She supports removing barriers to voting participation for residents across her district.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/CFF0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 9 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '248f76d7-e76a-49e5-88b7-dc43a3131329';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '248f76d7-e76a-49e5-88b7-dc43a3131329'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '248f76d7-e76a-49e5-88b7-dc43a3131329'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
