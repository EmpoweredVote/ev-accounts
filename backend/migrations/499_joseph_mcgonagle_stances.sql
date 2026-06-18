-- ============================================================================
-- Migration 499: Joseph W. McGonagle Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Joseph W. McGonagle (MA House HD-84,
--   28th Middlesex District, Everett). External ID: -210124.
--   McGonagle has served since 2017; moderate Democrat representing Everett.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Joseph W. McGonagle (HD-84, external_id=-210124)
-- Politician UUID: 4a818693-d820-4f4a-94b7-3d43a2381e1c

-- ----- Joseph W. McGonagle / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$McGonagle co-sponsored the ROE Act (H.3320), which expands and codifies abortion rights in Massachusetts. He voted for the legislation and received a NARAL Pro-Choice Massachusetts endorsement. His ActOnMass profile confirms a supportive vote record on reproductive rights.$$,
        ARRAY['https://actonmass.org/legislators/joseph-mcgonagle/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph W. McGonagle / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McGonagle voted for the 2021 MA climate roadmap bill committing to net-zero emissions by 2050. He has supported offshore wind investment and clean energy legislation. His record on climate is moderate-supportive: he backs the mainstream MA climate framework but is less vocal on aggressive phase-out measures.$$,
        ARRAY['https://actonmass.org/legislators/joseph-mcgonagle/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph W. McGonagle / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$McGonagle has voted consistently to protect MassHealth and expand access to affordable healthcare. He supported the 2022 MA prescription drug cost transparency bill and mental health parity legislation. He co-sponsored expanded telehealth access bills and has generally supported broader healthcare access measures, though he has not been a lead sponsor of single-payer legislation.$$,
        ARRAY['https://actonmass.org/legislators/joseph-mcgonagle/', 'https://malegislature.gov/Legislators/Profile/jwm1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph W. McGonagle / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McGonagle has voted for affordable housing funding legislation and supported MBTA Communities zoning reform to encourage transit-oriented development. He supported Everett's housing development efforts and has voted for bills to expand homebuyer assistance programs. His approach to housing is moderately pro-development with affordability considerations.$$,
        ARRAY['https://actonmass.org/legislators/joseph-mcgonagle/', 'https://malegislature.gov/Legislators/Profile/jwm1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph W. McGonagle / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McGonagle voted for the DREAM Act to provide in-state tuition for undocumented students and the Work and Family Mobility Act to allow drivers' licenses regardless of immigration status. Everett has a large immigrant community including Brazilian and Central American residents. He has supported immigrant-protective policies while taking a more moderate stance than progressive colleagues on enforcement limits.$$,
        ARRAY['https://actonmass.org/legislators/joseph-mcgonagle/', 'https://malegislature.gov/Legislators/Profile/jwm1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph W. McGonagle / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$McGonagle voted for the 2018 criminal justice reform omnibus reducing mandatory minimums and the 2020 Police Accountability Act creating the POST Commission. He supported expanded diversion and restorative justice programs. His record is moderate reform-oriented: he backed mainstream criminal justice reform without being a lead sponsor of more ambitious decarceration bills.$$,
        ARRAY['https://actonmass.org/legislators/joseph-mcgonagle/', 'https://malegislature.gov/Bills/191/S2700'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph W. McGonagle / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$McGonagle voted in support of the 2022 Millionaires Tax (Fair Share Amendment). He has supported progressive tax measures to fund public services while maintaining a moderate economic posture representing Everett's working-class and immigrant population. His record includes votes for tax increases on high earners but also support for business development in Everett.$$,
        ARRAY['https://actonmass.org/legislators/joseph-mcgonagle/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph W. McGonagle / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a818693-d820-4f4a-94b7-3d43a2381e1c',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$McGonagle voted for the 2022 VOTES Act making early voting and mail voting permanent in Massachusetts. He supported expanded voting access measures during the COVID era and has consistently voted to protect and expand ballot access for all residents.$$,
        ARRAY['https://actonmass.org/legislators/joseph-mcgonagle/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '4a818693-d820-4f4a-94b7-3d43a2381e1c';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='4a818693-d820-4f4a-94b7-3d43a2381e1c' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='4a818693-d820-4f4a-94b7-3d43a2381e1c' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
