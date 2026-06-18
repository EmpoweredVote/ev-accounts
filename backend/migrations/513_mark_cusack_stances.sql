-- ============================================================================
-- Migration 513: Mark J. Cusack Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Mark J. Cusack (MA House HD-98,
--   5th Norfolk District, Braintree). External ID: -210138.
--   Cusack has served since 2013; Democrat from Braintree, serving on
--   Committee on Elder Affairs among others.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Mark J. Cusack (HD-98, external_id=-210138)
-- Politician UUID: 99206e70-8173-4d6c-803c-1ae2d1109e30

-- ----- Mark J. Cusack / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Cusack voted for the ROE Act final passage to codify abortion rights in Massachusetts. As a moderate South Shore Democrat, he has voted with the majority on reproductive rights bills though he has not been a lead sponsor. His record reflects support for existing legal abortion access in Massachusetts.$$,
        ARRAY['https://actonmass.org/legislators/mark-cusack/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark J. Cusack / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cusack voted for the 2021 MA climate roadmap committing to net-zero emissions by 2050. He has supported clean energy investment and offshore wind development. His South Shore coastal district is vulnerable to climate impacts and he has backed the state's climate goals while being attentive to constituent concerns about energy costs.$$,
        ARRAY['https://actonmass.org/legislators/mark-cusack/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark J. Cusack / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cusack has served on health-related committees and voted to protect MassHealth and expand healthcare access. He has supported mental health parity legislation and elder care funding. His record reflects mainstream Democratic support for the state's healthcare framework with particular attention to elder health services.$$,
        ARRAY['https://actonmass.org/legislators/mark-cusack/', 'https://malegislature.gov/Legislators/Profile/MJC1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark J. Cusack / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cusack voted for affordable housing funding and MBTA Communities zoning reform. He has supported senior housing programs and programs to help first-generation homebuyers. His record reflects moderate Democratic housing positions supporting production and affordability.$$,
        ARRAY['https://actonmass.org/legislators/mark-cusack/', 'https://malegislature.gov/Legislators/Profile/MJC1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark J. Cusack / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cusack voted for the Work and Family Mobility Act (drivers' licenses for all residents) and the DREAM Act. His record reflects mainstream Democratic immigration positions supporting legal pathways and immigrant integration services. He represents a district with a smaller immigrant population than urban Middlesex or Suffolk communities.$$,
        ARRAY['https://actonmass.org/legislators/mark-cusack/', 'https://malegislature.gov/Legislators/Profile/MJC1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark J. Cusack / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cusack voted for the 2022 Millionaires Tax (Fair Share Amendment). His tax record reflects moderate Democratic positions supporting progressive taxation for public services while being attentive to middle-class constituents in his suburban Braintree district.$$,
        ARRAY['https://actonmass.org/legislators/mark-cusack/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark J. Cusack / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99206e70-8173-4d6c-803c-1ae2d1109e30',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Cusack voted for the 2022 VOTES Act making early voting and mail voting permanent. He has supported mainstream voting access expansion measures during his tenure.$$,
        ARRAY['https://actonmass.org/legislators/mark-cusack/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '99206e70-8173-4d6c-803c-1ae2d1109e30';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='99206e70-8173-4d6c-803c-1ae2d1109e30' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='99206e70-8173-4d6c-803c-1ae2d1109e30' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
