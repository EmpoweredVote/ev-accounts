-- ============================================================================
-- Migration 512: James M. Murphy Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for James M. Murphy (MA House HD-97,
--   4th Norfolk District, Weymouth). External ID: -210137.
--   Murphy has served since 2001; Democrat from Weymouth.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- James M. Murphy (HD-97, external_id=-210137)
-- Politician UUID: 755d18f8-8c99-4d41-93eb-4f154d9bb7a9

-- ----- James M. Murphy / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Murphy voted for the ROE Act's final passage, supporting codification of abortion rights in Massachusetts law. As a moderate Democrat from a more conservative South Shore district, he has voted with the Democratic majority on abortion rights while not being among the bill's primary sponsors. His record reflects support for existing legal abortion access.$$,
        ARRAY['https://actonmass.org/legislators/james-murphy/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James M. Murphy / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Murphy voted for the 2021 MA climate roadmap committing to net-zero emissions by 2050. His coastal South Shore district gives him particular awareness of climate impacts including sea-level rise and storm surge. He supports the state's climate framework while being attentive to economic impacts on working-class constituents.$$,
        ARRAY['https://actonmass.org/legislators/james-murphy/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James M. Murphy / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Murphy has voted to protect MassHealth and support expanded healthcare access. He supported mental health parity and prescription drug cost transparency legislation. His healthcare record reflects mainstream Democratic support for the state's near-universal healthcare framework.$$,
        ARRAY['https://actonmass.org/legislators/james-murphy/', 'https://malegislature.gov/Legislators/Profile/JMM1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James M. Murphy / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Murphy has a moderate housing record. He voted for some affordable housing funding bills but has been more cautious than progressive colleagues on aggressive zoning mandates and tenant protections. His Weymouth district includes homeowners with mixed views on housing development, reflecting the centrist approach to housing policy common among South Shore Democrats.$$,
        ARRAY['https://actonmass.org/legislators/james-murphy/', 'https://malegislature.gov/Legislators/Profile/JMM1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James M. Murphy / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Murphy voted for the 2022 Millionaires Tax (Fair Share Amendment). His tax record over two decades reflects moderate Democratic positions: supporting targeted progressive measures while being attentive to the concerns of working-class and middle-class constituents in his South Shore district about overall tax burdens.$$,
        ARRAY['https://actonmass.org/legislators/james-murphy/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James M. Murphy / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('755d18f8-8c99-4d41-93eb-4f154d9bb7a9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Murphy voted for the 2022 VOTES Act making early voting and mail voting permanent. He has supported mainstream voting access expansion measures during his long tenure including the adoption of early voting in Massachusetts.$$,
        ARRAY['https://actonmass.org/legislators/james-murphy/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '755d18f8-8c99-4d41-93eb-4f154d9bb7a9';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='755d18f8-8c99-4d41-93eb-4f154d9bb7a9' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='755d18f8-8c99-4d41-93eb-4f154d9bb7a9' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
