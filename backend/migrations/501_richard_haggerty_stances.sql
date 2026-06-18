-- ============================================================================
-- Migration 501: Richard M. Haggerty Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Richard M. Haggerty (MA House HD-86,
--   30th Middlesex District, Woburn area). External ID: -210126.
--   Haggerty is a Democrat; represents a suburban district north of Boston.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Richard M. Haggerty (HD-86, external_id=-210126)
-- Politician UUID: 2d3def44-9916-469d-8f8f-b098ad896768

-- ----- Richard M. Haggerty / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Haggerty co-sponsored the ROE Act (H.3320), which codifies and expands abortion rights in Massachusetts beyond what Roe v. Wade required. He voted in favor of the legislation and his ActOnMass scorecard reflects consistent support for reproductive rights.$$,
        ARRAY['https://actonmass.org/legislators/richard-haggerty/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard M. Haggerty / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Haggerty voted for the 2021 MA climate roadmap committing the state to net-zero emissions by 2050. He has supported clean energy investment, offshore wind, and building efficiency programs. His votes reflect mainstream Democratic support for the state's climate framework.$$,
        ARRAY['https://actonmass.org/legislators/richard-haggerty/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard M. Haggerty / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Haggerty has supported MassHealth expansion and affordable healthcare access legislation. He voted for prescription drug cost transparency bills and mental health parity legislation. His record reflects moderate-progressive support for expanded healthcare access as a mainstream MA House Democrat.$$,
        ARRAY['https://actonmass.org/legislators/richard-haggerty/', 'https://malegislature.gov/Legislators/Profile/RMH1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard M. Haggerty / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Haggerty voted for affordable housing funding legislation and supported MBTA Communities zoning reform. His district includes Woburn, which has seen housing price increases, and he has backed policies to increase housing production with affordability components. His record reflects moderate-Democratic housing policy positions.$$,
        ARRAY['https://actonmass.org/legislators/richard-haggerty/', 'https://malegislature.gov/Legislators/Profile/RMH1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard M. Haggerty / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Haggerty voted for the Work and Family Mobility Act (drivers' licenses for all residents regardless of immigration status) and the DREAM Act. His record reflects mainstream Democratic immigration positions: supporting legal pathways and immigrant integration while not sponsoring the most restrictive enforcement limitation bills.$$,
        ARRAY['https://actonmass.org/legislators/richard-haggerty/', 'https://malegislature.gov/Legislators/Profile/RMH1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard M. Haggerty / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Haggerty voted for the 2022 Millionaires Tax (Fair Share Amendment). His tax record reflects standard Democratic positions supporting progressive taxation to fund public services while balancing concerns about economic competitiveness in his suburban district.$$,
        ARRAY['https://actonmass.org/legislators/richard-haggerty/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard M. Haggerty / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2d3def44-9916-469d-8f8f-b098ad896768',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Haggerty voted for the 2022 VOTES Act making early voting and mail voting permanent in Massachusetts. He has supported expanded ballot access and voting convenience measures during his tenure.$$,
        ARRAY['https://actonmass.org/legislators/richard-haggerty/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '2d3def44-9916-469d-8f8f-b098ad896768';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='2d3def44-9916-469d-8f8f-b098ad896768' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='2d3def44-9916-469d-8f8f-b098ad896768' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
