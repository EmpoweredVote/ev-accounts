-- ============================================================================
-- Migration 395: Barry R. Finegold Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Barry R. Finegold (MA State Senator, 25D20).
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
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Barry R. Finegold (25D20, external_id=-210020)
-- Politician UUID: 15f59b0c-f71c-4199-b195-7b653a05a310

-- ----- Barry R. Finegold / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Barry R. Finegold has been a consistent supporter of reproductive rights in Massachusetts. He backed the ROE Act and subsequent abortion protection legislation, and supported the 2022 shield law protecting Massachusetts abortion providers following the Dobbs decision. As a longtime Democratic legislator from the Andover-Tewksbury area, he has aligned with the majority caucus on protecting abortion access as a fundamental healthcare right.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BRF0', 'https://ballotpedia.org/Barry_Finegold']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry R. Finegold / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Barry R. Finegold supported the 2021 Massachusetts Climate Act and has backed clean energy development. He represents a district including Andover and Tewksbury where residents are concerned about energy costs and clean energy transitions. He has supported offshore wind, solar programs, and energy efficiency initiatives, approaching climate policy with attention to ratepayer impacts in his suburban communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/S9', 'https://malegislature.gov/Legislators/Profile/BRF0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry R. Finegold / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Barry R. Finegold has been a strong advocate for economic development in the Merrimack Valley. He has backed state investment in Route 128/495 corridor businesses, life sciences, and clean energy industries. He served as Senate Chair of the Joint Committee on Cannabis Policy and has worked to develop economic opportunities in Andover, Tewksbury, Wilmington, and Lawrence. He has supported workforce development and small business investment.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BRF0', 'https://ballotpedia.org/Barry_Finegold']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry R. Finegold / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Barry R. Finegold has supported healthcare access and mental health services. He has backed expanded MassHealth, behavioral health reform, and substance use treatment. He has focused on healthcare cost containment and supported the state's universal coverage model. His district communities have been impacted by the opioid crisis, and he has backed funding for addiction treatment and recovery services.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BRF0', 'https://ballotpedia.org/Barry_Finegold']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry R. Finegold / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Barry R. Finegold backed the Affordable Homes Act and has supported housing production legislation. He represents communities in the Merrimack Valley where housing affordability is a growing concern. He has taken a balanced approach supporting MBTA Communities zoning requirements and affordable housing production while working with local communities on implementation. He has backed senior housing and workforce housing programs in his district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BRF0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry R. Finegold / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Barry R. Finegold supported the Work and Family Mobility Act and has backed generally immigrant-supportive policies. His district, which borders Lawrence, has significant immigrant communities. He has taken a pragmatic approach supporting immigrant integration while also expressing concern about fiscal impacts of the emergency shelter system expansion. He has backed language access and immigrant workforce development programs.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/BRF0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry R. Finegold / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Barry R. Finegold backed the 2020 Police Reform Act and has supported criminal justice reform while also championing resources for law enforcement in his communities. He has taken a moderate approach balancing police accountability with strong support for public safety. He has backed mental health diversion programs, violence prevention, and drug court alternatives, while also supporting law enforcement funding for his suburban district communities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BRF0', 'https://malegislature.gov/Bills/191/H4886']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry R. Finegold / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Barry R. Finegold supported the Fair Share Amendment and has backed progressive tax policies. He has supported revenue for education, transportation, and public safety. His approach is moderately progressive, supporting investments in public services while being attentive to the impact on middle-class homeowners in his Merrimack Valley district communities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BRF0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry R. Finegold / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Barry R. Finegold has been a strong advocate for Merrimack Valley transportation improvements. He has backed the Haverhill/Reading Line commuter rail improvements, Route 93 and I-495 highway maintenance, and regional transit for his district. He has supported MBTA investment, electrification of commuter rail, and balanced transportation spending serving both transit riders and the many car-dependent commuters in his district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BRF0', 'https://ballotpedia.org/Barry_Finegold']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barry R. Finegold / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15f59b0c-f71c-4199-b195-7b653a05a310',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Barry R. Finegold backed the VOTES Act making early voting and vote-by-mail permanent in Massachusetts. He has supported voting rights expansion and has aligned with the Democratic majority on measures to make elections more accessible, including automatic voter registration. He supports removing barriers to voting participation for all eligible voters in his district.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/BRF0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 11 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '15f59b0c-f71c-4199-b195-7b653a05a310';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '15f59b0c-f71c-4199-b195-7b653a05a310'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '15f59b0c-f71c-4199-b195-7b653a05a310'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
