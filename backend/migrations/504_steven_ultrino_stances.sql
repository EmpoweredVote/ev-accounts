-- ============================================================================
-- Migration 504: Steven Ultrino Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Steven Ultrino (MA House HD-89,
--   33rd Middlesex District, Malden). External ID: -210129.
--   Ultrino has served since 2013; Democrat representing Malden.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Steven Ultrino (HD-89, external_id=-210129)
-- Politician UUID: 0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7

-- ----- Steven Ultrino / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ultrino co-sponsored the ROE Act (H.3320) to codify and expand abortion rights in Massachusetts. He has voted consistently for reproductive rights legislation throughout his tenure and his ActOnMass scorecard confirms pro-choice voting record.$$,
        ARRAY['https://actonmass.org/legislators/steven-ultrino/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven Ultrino / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ultrino voted for the 2021 MA climate roadmap bill committing to net-zero emissions by 2050. He has supported clean energy investment and building efficiency programs. His record reflects mainstream Democratic support for state climate policy.$$,
        ARRAY['https://actonmass.org/legislators/steven-ultrino/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven Ultrino / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ultrino has voted to protect MassHealth and expand affordable healthcare access. He has supported mental health parity legislation and prescription drug cost measures. His record reflects moderate Democratic positions on healthcare access for his Malden district.$$,
        ARRAY['https://actonmass.org/legislators/steven-ultrino/', 'https://malegislature.gov/Legislators/Profile/S_G2'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven Ultrino / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ultrino voted for affordable housing funding and MBTA Communities zoning reform. Malden has seen housing cost increases and he has supported policies to increase housing supply. He has backed affordable housing funding bills and first-time homebuyer assistance programs.$$,
        ARRAY['https://actonmass.org/legislators/steven-ultrino/', 'https://malegislature.gov/Legislators/Profile/S_G2'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven Ultrino / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ultrino voted for the Work and Family Mobility Act (drivers' licenses for all residents) and the DREAM Act for in-state tuition for undocumented students. Malden has a diverse immigrant community and he has supported immigrant integration programs. His record reflects mainstream Democratic immigration policy.$$,
        ARRAY['https://actonmass.org/legislators/steven-ultrino/', 'https://malegislature.gov/Legislators/Profile/S_G2'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven Ultrino / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ultrino voted for the 2022 Millionaires Tax (Fair Share Amendment). His record reflects standard Democratic positions supporting progressive taxation to fund education and transportation infrastructure serving his district.$$,
        ARRAY['https://actonmass.org/legislators/steven-ultrino/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven Ultrino / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ultrino voted for the 2022 VOTES Act making early voting and mail voting permanent in Massachusetts. He has supported voter access expansion and backed the COVID-era voting reforms that the VOTES Act codified.$$,
        ARRAY['https://actonmass.org/legislators/steven-ultrino/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='0cb5bf41-db67-4c4e-b4cf-79c4e4e8dcd7' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
