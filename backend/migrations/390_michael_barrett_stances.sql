-- ============================================================================
-- Migration 390: Michael J. Barrett Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael J. Barrett (MA State Senator, 25D15).
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
-- data-centers                     4559b513-0fd8-4ed1-babd-f3b554162f40
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Michael J. Barrett (25D15, external_id=-210015)
-- Politician UUID: 60e4da77-0c2b-4ca4-8d02-a4210bd91d90

-- ----- Michael J. Barrett / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Michael J. Barrett has been a strong supporter of reproductive rights and voted for the ROE Act and subsequent abortion protection legislation in Massachusetts. As a veteran legislator from the affluent Lexington-Concord area, he has consistently supported abortion access as a fundamental healthcare right. He backed the shield law protecting Massachusetts providers following the Dobbs decision.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJB0', 'https://ballotpedia.org/Michael_Barrett_(Massachusetts)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Barrett / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Michael J. Barrett has been one of the leading climate champions in the Massachusetts legislature for over a decade. He served as chair of the Joint Committee on Telecommunications, Utilities, and Energy and was a key architect of clean energy legislation. He championed the Global Warming Solutions Act in 2008 and subsequent climate legislation. He was instrumental in crafting the 2021 Next-Generation Climate Roadmap Act. His district in the Route 128 tech corridor has many residents who strongly support climate action.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJB0', 'https://malegislature.gov/Bills/192/S9']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Barrett / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Michael J. Barrett has supported clean energy economic development, life sciences investment, and workforce development. His district is a major innovation economy hub and he has backed state investments in technology, biotech, and clean energy industries. He supports economic development with strong environmental and labor standards.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJB0', 'https://ballotpedia.org/Michael_Barrett_(Massachusetts)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Barrett / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Michael J. Barrett has been a leading advocate for phasing out fossil fuels in Massachusetts. He has backed restrictions on new natural gas hookups in buildings, the transition from oil heating to heat pumps, and reducing the state's dependence on natural gas for electricity generation. As the Senate's top energy committee chair for many years, he championed policies shifting away from fossil fuels toward renewables.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJB0', 'https://malegislature.gov/Bills/192/S9']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Barrett / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Michael J. Barrett has supported healthcare access expansion and cost containment. He has backed MassHealth expansions, mental health reform, and prescription drug cost legislation. As a veteran legislator, he has participated in multiple healthcare policy initiatives in Massachusetts and supports the state's universal coverage model as a foundation for further improvements.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJB0', 'https://ballotpedia.org/Michael_Barrett_(Massachusetts)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Barrett / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Michael J. Barrett backed the Affordable Homes Act and has supported housing production and zoning reform. His district includes Lexington and Concord, towns with very limited affordable housing, and he has backed state requirements for municipalities in his district to allow more multi-family housing. He has supported both production of new units and protection of existing affordable housing.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJB0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Barrett / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Michael J. Barrett supported the Work and Family Mobility Act and has backed immigrant-friendly policies. His affluent suburban district has diverse immigrant populations including tech workers and their families. He has supported immigrant integration and has backed protections for DACA recipients and undocumented residents in Massachusetts.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/MJB0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Barrett / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Michael J. Barrett supported the Fair Share Amendment and has backed progressive tax policies for Massachusetts. He has been willing to support tax investments in clean energy, education, and transportation. His district includes high-income communities and he has been a consistent voice for progressive taxation as a mechanism to fund public goods.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJB0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Barrett / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Michael J. Barrett has been a strong advocate for public transit investment, particularly the MBTA commuter rail serving his district (Fitchburg Line through Concord and Lexington area). He has backed significant state investment in the MBTA, electrification of commuter rail, and transit-oriented development. He has linked transportation investment with climate goals, supporting a shift from car dependency to public transit.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJB0', 'https://ballotpedia.org/Michael_Barrett_(Massachusetts)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Barrett / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Michael J. Barrett backed the VOTES Act and has supported voting rights expansion in Massachusetts. He has aligned with the Democratic majority on expanding early voting, vote-by-mail, and automatic voter registration. He has been a consistent supporter of making elections more accessible for all residents.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/MJB0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 10 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '60e4da77-0c2b-4ca4-8d02-a4210bd91d90';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '60e4da77-0c2b-4ca4-8d02-a4210bd91d90'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '60e4da77-0c2b-4ca4-8d02-a4210bd91d90'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
