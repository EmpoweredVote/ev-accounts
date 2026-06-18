-- ============================================================================
-- Migration 509: Bruce J. Ayers Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Bruce J. Ayers (MA House HD-94,
--   1st Norfolk District, Quincy area). External ID: -210134.
--   Ayers has served since 2015; Democrat from the Quincy area of Norfolk County.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Bruce J. Ayers (HD-94, external_id=-210134)
-- Politician UUID: 3582a053-ee20-4391-904f-3905a2d13a52

-- ----- Bruce J. Ayers / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ayers co-sponsored the ROE Act (H.3320) and has voted consistently for reproductive rights legislation. His ActOnMass scorecard confirms supportive votes on reproductive rights bills throughout his tenure.$$,
        ARRAY['https://actonmass.org/legislators/bruce-ayers/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bruce J. Ayers / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ayers voted for the 2021 MA climate roadmap committing to net-zero emissions by 2050. He has supported clean energy legislation and offshore wind investment. His coastal South Shore district is particularly vulnerable to climate change impacts. His record reflects mainstream Democratic support for state climate goals.$$,
        ARRAY['https://actonmass.org/legislators/bruce-ayers/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bruce J. Ayers / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ayers has voted to protect MassHealth and support expanded healthcare access. He supported mental health parity legislation and prescription drug cost transparency. His record reflects moderate Democratic positions supporting the state's healthcare framework.$$,
        ARRAY['https://actonmass.org/legislators/bruce-ayers/', 'https://malegislature.gov/Legislators/Profile/BJA1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bruce J. Ayers / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ayers voted for affordable housing funding and MBTA Communities zoning reform. His South Shore suburban district faces housing affordability pressures and he has backed policies to increase housing supply with affordability components. His record reflects mainstream Democratic housing positions.$$,
        ARRAY['https://actonmass.org/legislators/bruce-ayers/', 'https://malegislature.gov/Legislators/Profile/BJA1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bruce J. Ayers / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ayers voted for the 2022 Millionaires Tax (Fair Share Amendment). His tax record reflects standard Democratic positions supporting progressive taxation to fund public services including education and transportation in his district.$$,
        ARRAY['https://actonmass.org/legislators/bruce-ayers/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bruce J. Ayers / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3582a053-ee20-4391-904f-3905a2d13a52',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ayers voted for the 2022 VOTES Act making early voting and mail voting permanent in Massachusetts. He has supported voter access expansion and backed the COVID-era voting reforms that the VOTES Act codified.$$,
        ARRAY['https://actonmass.org/legislators/bruce-ayers/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '3582a053-ee20-4391-904f-3905a2d13a52';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='3582a053-ee20-4391-904f-3905a2d13a52' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='3582a053-ee20-4391-904f-3905a2d13a52' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
