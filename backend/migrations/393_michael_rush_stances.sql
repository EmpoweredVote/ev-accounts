-- ============================================================================
-- Migration 393: Michael F. Rush Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael F. Rush (MA State Senator, 25D18).
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

-- Michael F. Rush (25D18, external_id=-210018)
-- Politician UUID: 62764b2a-5b54-4edb-9c69-06320cbebbad

-- ----- Michael F. Rush / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Michael F. Rush has supported abortion rights legislation in Massachusetts including the 2022 shield law and voted for relevant bills, though he is from a more conservative part of the Democratic caucus representing the West Roxbury-Hyde Park area of Boston and Norfolk County suburbs. He has been part of the majority voting to protect abortion access while being less vocal on the issue than some progressive colleagues. His district includes communities with more traditional Catholic Democratic voters.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MFR0', 'https://ballotpedia.org/Michael_Rush_(Massachusetts)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael F. Rush / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Michael F. Rush supported the 2021 Massachusetts Climate Act. He has backed clean energy development and the state's transition away from fossil fuels, though with attention to ratepayer costs. His district spans Norfolk County suburbs and parts of Boston, and he has focused on practical climate policy implementation while managing energy affordability concerns.$$,
        ARRAY['https://malegislature.gov/Bills/192/S9', 'https://malegislature.gov/Legislators/Profile/MFR0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael F. Rush / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Michael F. Rush has been a practical advocate for economic development in his district, which spans Norfolk County suburbs and the West Roxbury area of Boston. He has backed business development, workforce training, and state investments in infrastructure and transportation. He served on the Joint Committee on Economic Development and has taken a balanced approach to economic growth.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MFR0', 'https://ballotpedia.org/Michael_Rush_(Massachusetts)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael F. Rush / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Michael F. Rush has supported healthcare access and has been particularly focused on mental health services and substance use treatment. He has backed MassHealth expansions and behavioral health legislation. He has focused on opioid recovery resources for his district communities that have been affected by the opioid crisis. He supports the state's universal healthcare framework.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MFR0', 'https://ballotpedia.org/Michael_Rush_(Massachusetts)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael F. Rush / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Michael F. Rush backed the Affordable Homes Act and has supported housing production for his district. He has been mindful of community concerns about density and development pace, taking a moderate approach that supports housing growth while respecting local planning. His district includes communities like West Roxbury that have historically been resistant to dense development.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MFR0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael F. Rush / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Michael F. Rush supported the Work and Family Mobility Act and has backed generally immigrant-friendly policies. He has expressed some concern about the fiscal burden of the emergency shelter system expansion on the state budget. His district has a mix of immigrant communities and long-established neighborhoods, and he has taken a pragmatic approach balancing support for immigrants with fiscal concerns.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/MFR0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael F. Rush / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Michael F. Rush has taken a moderate approach on public safety, supporting the 2020 Police Reform Act while also emphasizing the importance of law enforcement resources for his communities. He represents areas including West Roxbury that have strong law enforcement connections, and he has balanced support for accountability measures with strong backing for police departments. He has also backed mental health diversion programs.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MFR0', 'https://malegislature.gov/Bills/191/H4886']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael F. Rush / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Michael F. Rush supported the Fair Share Amendment and has backed progressive tax policies. He has supported using tax revenue for public investments in education and infrastructure. His approach is moderately progressive, supporting necessary revenue measures while being attentive to the impact on middle-class families in his district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MFR0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael F. Rush / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Michael F. Rush has advocated for transportation improvements for his district, including MBTA commuter rail service and Green Line extension. He has backed transit investment while also supporting highway maintenance for his suburban communities. He has supported MBTA reform and investment to improve service reliability. His district spans from the Boston neighborhoods to Norfolk County suburbs with mixed transit-auto commute patterns.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MFR0', 'https://ballotpedia.org/Michael_Rush_(Massachusetts)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael F. Rush / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62764b2a-5b54-4edb-9c69-06320cbebbad',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Michael F. Rush backed the VOTES Act making early voting and vote-by-mail permanent and has supported voting rights expansion in Massachusetts. He has aligned with the Democratic majority on measures to expand voter access and participation. He supports removing barriers to voting for working families in his district.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/MFR0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 11 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '62764b2a-5b54-4edb-9c69-06320cbebbad';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '62764b2a-5b54-4edb-9c69-06320cbebbad'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '62764b2a-5b54-4edb-9c69-06320cbebbad'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
