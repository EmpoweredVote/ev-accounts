-- ============================================================================
-- Migration 502: Michael S. Day Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael S. Day (MA House HD-87,
--   31st Middlesex District, Stoneham/Woburn). External ID: -210127.
--   Day has served since 2014; Democrat, member of Committee on Ways and Means,
--   involved in veterans affairs and public safety.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Michael S. Day (HD-87, external_id=-210127)
-- Politician UUID: ff5cc07a-b904-4365-bcac-027bb50e8a8e

-- ----- Michael S. Day / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Day co-sponsored the ROE Act (H.3320) to codify and expand abortion access in Massachusetts. He has voted consistently for reproductive rights legislation during his tenure and received NARAL Pro-Choice Massachusetts support.$$,
        ARRAY['https://actonmass.org/legislators/michael-day/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael S. Day / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Day voted for the 2021 MA climate roadmap committing to net-zero emissions by 2050. He has supported clean energy investment and building efficiency programs. His record reflects mainstream Democratic support for state climate goals.$$,
        ARRAY['https://actonmass.org/legislators/michael-day/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael S. Day / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Day serves on the Committee on Ways and Means and has been involved in economic development legislation. He has supported workforce development programs, small business assistance, and economic recovery efforts. His record reflects moderate-Democratic economic development positions balancing business needs with worker protections.$$,
        ARRAY['https://actonmass.org/legislators/michael-day/', 'https://malegislature.gov/Legislators/Profile/MSD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael S. Day / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Day has supported MassHealth expansion and mental health parity legislation. As a member of the Ways and Means Committee he has been involved in healthcare budget decisions. He voted for prescription drug cost transparency and expanded telehealth access. His record reflects moderate Democratic positions on healthcare access.$$,
        ARRAY['https://actonmass.org/legislators/michael-day/', 'https://malegislature.gov/Legislators/Profile/MSD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael S. Day / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Day voted for affordable housing funding legislation and the MBTA Communities zoning act. His suburban district faces housing affordability pressures and he has backed increased housing production. His housing positions reflect mainstream Democratic support for production combined with affordability goals.$$,
        ARRAY['https://actonmass.org/legislators/michael-day/', 'https://malegislature.gov/Legislators/Profile/MSD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael S. Day / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Day voted for the 2022 Millionaires Tax (Fair Share Amendment) as a member of Ways and Means. As a committee member he has been involved in tax and revenue discussions in the legislature. His tax record reflects standard moderate-Democratic positions.$$,
        ARRAY['https://actonmass.org/legislators/michael-day/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael S. Day / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff5cc07a-b904-4365-bcac-027bb50e8a8e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Day voted for the 2022 VOTES Act making early voting and mail voting permanent in Massachusetts. He has supported ballot access expansion during his tenure and backed the COVID-era voting reforms that the VOTES Act codified permanently.$$,
        ARRAY['https://actonmass.org/legislators/michael-day/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ff5cc07a-b904-4365-bcac-027bb50e8a8e';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='ff5cc07a-b904-4365-bcac-027bb50e8a8e' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='ff5cc07a-b904-4365-bcac-027bb50e8a8e' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
