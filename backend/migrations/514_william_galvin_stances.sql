-- ============================================================================
-- Migration 514: William C. Galvin Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for William C. Galvin (MA House HD-99,
--   6th Norfolk District, Canton/Stoughton). External ID: -210139.
--   Galvin has served since 2007; Democrat from Canton/Stoughton area.
--   NOTE: Different person from William F. Galvin (MA Secretary of State).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- William C. Galvin (HD-99, external_id=-210139)
-- Politician UUID: 78f3bb2d-90e4-4263-925e-6203385bc6eb

-- ----- William C. Galvin / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Galvin voted for the ROE Act's final passage to codify abortion rights in Massachusetts law. As a moderate Democrat from a suburban South Shore district, he voted with the majority on reproductive rights while not being a lead sponsor. His record reflects support for existing legal abortion access.$$,
        ARRAY['https://actonmass.org/legislators/william-galvin/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Galvin / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Galvin voted for the 2021 MA climate roadmap committing to net-zero emissions by 2050. He has supported clean energy investment and offshore wind development. His record reflects mainstream Democratic support for state climate goals.$$,
        ARRAY['https://actonmass.org/legislators/william-galvin/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Galvin / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Galvin has voted to protect MassHealth and expand affordable healthcare access. He supported mental health parity legislation and prescription drug cost measures. His record reflects moderate Democratic support for the state's healthcare framework.$$,
        ARRAY['https://actonmass.org/legislators/william-galvin/', 'https://malegislature.gov/Legislators/Profile/WCG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Galvin / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Galvin has a mixed housing record. He voted for some affordable housing funding programs but his suburban Canton/Stoughton district has concerns about neighborhood density and development. His housing approach reflects the moderate, homeowner-focused Democratic constituency of his South Shore district, balancing housing needs with community concerns about overdevelopment.$$,
        ARRAY['https://actonmass.org/legislators/william-galvin/', 'https://malegislature.gov/Legislators/Profile/WCG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Galvin / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Galvin voted for the Work and Family Mobility Act (drivers' licenses for all residents) and the DREAM Act. His immigration record reflects mainstream Democratic positions supporting legal pathways and immigrant integration. Canton and Stoughton have growing immigrant communities including significant Haitian and Vietnamese populations.$$,
        ARRAY['https://actonmass.org/legislators/william-galvin/', 'https://malegislature.gov/Legislators/Profile/WCG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Galvin / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Galvin voted for the 2022 Millionaires Tax (Fair Share Amendment). His tax record reflects moderate Democratic positions: supporting progressive taxation to fund public services while being attentive to middle-class constituents in his suburban district.$$,
        ARRAY['https://actonmass.org/legislators/william-galvin/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William C. Galvin / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('78f3bb2d-90e4-4263-925e-6203385bc6eb',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Galvin voted for the 2022 VOTES Act making early voting and mail voting permanent. He has supported mainstream voting access expansion measures during his tenure in the House.$$,
        ARRAY['https://actonmass.org/legislators/william-galvin/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '78f3bb2d-90e4-4263-925e-6203385bc6eb';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='78f3bb2d-90e4-4263-925e-6203385bc6eb' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='78f3bb2d-90e4-4263-925e-6203385bc6eb' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
