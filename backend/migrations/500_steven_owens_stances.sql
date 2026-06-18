-- ============================================================================
-- Migration 500: Steven C. Owens Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Steven C. Owens (MA House HD-85,
--   29th Middlesex District). External ID: -210125.
--   Owens represents a suburban district; Democrat elected in recent cycles.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Steven C. Owens (HD-85, external_id=-210125)
-- Politician UUID: 1d78debb-efd5-45e8-9204-06aab3076b2a

-- ----- Steven C. Owens / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Owens co-sponsored the ROE Act to codify and expand abortion rights in Massachusetts. His ActOnMass scorecard confirms supportive votes on reproductive rights legislation during his tenure.$$,
        ARRAY['https://actonmass.org/legislators/steven-owens/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven C. Owens / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Owens voted for the 2021 MA climate roadmap bill committing to net-zero emissions by 2050. He has supported clean energy legislation including offshore wind investment and building efficiency programs. His suburban district contains significant conservation land and his record shows consistent support for environmental protection.$$,
        ARRAY['https://actonmass.org/legislators/steven-owens/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven C. Owens / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Owens has voted consistently to protect MassHealth and expand affordable healthcare access. He supported mental health parity legislation and prescription drug cost transparency bills. His record reflects mainstream Democratic support for healthcare access without leading single-payer initiatives.$$,
        ARRAY['https://actonmass.org/legislators/steven-owens/', 'https://malegislature.gov/Legislators/Profile/SCO1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven C. Owens / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Owens supported MBTA Communities zoning reform requiring transit-oriented development and has voted for affordable housing funding bills. His suburban district faces housing affordability pressures and he has backed increased housing production with affordability requirements. He has not been a primary sponsor of tenant protection or rent control legislation.$$,
        ARRAY['https://actonmass.org/legislators/steven-owens/', 'https://malegislature.gov/Legislators/Profile/SCO1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven C. Owens / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Owens voted for the 2022 Millionaires Tax (Fair Share Amendment), supporting the 4% surtax on income over $1 million to fund education and transportation. His voting record on tax policy reflects mainstream Democratic positions supporting progressive taxation to fund public services.$$,
        ARRAY['https://actonmass.org/legislators/steven-owens/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven C. Owens / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1d78debb-efd5-45e8-9204-06aab3076b2a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Owens voted for the 2022 VOTES Act making early voting and vote-by-mail permanent in Massachusetts. He has supported expanded ballot access and participated in legislative efforts to increase voter participation in his district.$$,
        ARRAY['https://actonmass.org/legislators/steven-owens/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '1d78debb-efd5-45e8-9204-06aab3076b2a';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='1d78debb-efd5-45e8-9204-06aab3076b2a' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='1d78debb-efd5-45e8-9204-06aab3076b2a' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
