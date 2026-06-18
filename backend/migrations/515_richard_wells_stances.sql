-- ============================================================================
-- Migration 515: Richard G. Wells Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Richard G. Wells (MA House HD-100,
--   7th Norfolk District, Norwood/Walpole area). External ID: -210140.
--   Wells has served since 2019; Democrat from the Norwood/Walpole area.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Richard G. Wells (HD-100, external_id=-210140)
-- Politician UUID: a3131d21-f3ad-4483-ac6d-13c9c7ecdd74

-- ----- Richard G. Wells / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Wells co-sponsored the ROE Act (H.3320) and has voted consistently for reproductive rights legislation. He received NARAL Pro-Choice Massachusetts endorsement. His ActOnMass scorecard confirms strong support for abortion access throughout his tenure.$$,
        ARRAY['https://actonmass.org/legislators/richard-wells/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard G. Wells / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Wells voted for the 2021 MA climate roadmap committing to net-zero emissions by 2050. He has supported clean energy investment and building efficiency programs. His record reflects mainstream Democratic support for the state's climate framework.$$,
        ARRAY['https://actonmass.org/legislators/richard-wells/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard G. Wells / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Wells co-sponsored the Stop Wage Theft Act and has supported worker protective economic policies. He has backed minimum wage increases and worker benefits legislation. His record reflects progressive-leaning Democratic positions on economic development, prioritizing worker protections and community investment.$$,
        ARRAY['https://actonmass.org/legislators/richard-wells/', 'https://actonmass.org/bills/stop-wage-theft/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard G. Wells / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wells co-sponsored the Medicare for All Massachusetts Act (H.1279) and has been a consistent advocate for universal healthcare coverage. He has voted for MassHealth expansion, mental health parity, and prescription drug cost legislation. His progressive healthcare record reflects a commitment to universal coverage as a public right.$$,
        ARRAY['https://actonmass.org/legislators/richard-wells/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard G. Wells / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wells voted for affordable housing funding and the MBTA Communities zoning act. He has supported policies to increase housing supply with affordability requirements in his suburban district. His housing record reflects progressive-leaning Democratic positions supporting production with affordability goals.$$,
        ARRAY['https://actonmass.org/legislators/richard-wells/', 'https://malegislature.gov/Legislators/Profile/RGW1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard G. Wells / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Wells voted for the Work and Family Mobility Act (drivers' licenses for all residents) and the DREAM Act. He has supported immigrant rights and integration policies. His immigration record reflects progressive-leaning Democratic positions on welcoming immigrants and expanding their access to public services and protections.$$,
        ARRAY['https://actonmass.org/legislators/richard-wells/', 'https://malegislature.gov/Legislators/Profile/RGW1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard G. Wells / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Wells voted for the 2020 Police Reform and Accountability Act and has supported expanded diversion and restorative justice programs. He co-sponsored bills to expand expungement opportunities. His criminal justice record reflects progressive-leaning Democratic support for reform focused on rehabilitation and reducing incarceration.$$,
        ARRAY['https://actonmass.org/legislators/richard-wells/', 'https://malegislature.gov/Bills/191/H4990'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard G. Wells / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Wells voted for the 2022 Millionaires Tax (Fair Share Amendment) and has co-sponsored progressive tax measures to fund public services. His ActOnMass scorecard reflects consistent support for progressive taxation to invest in education, healthcare, and infrastructure.$$,
        ARRAY['https://actonmass.org/legislators/richard-wells/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Richard G. Wells / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Wells voted for the 2022 VOTES Act making early voting and vote-by-mail permanent. He has co-sponsored automatic voter registration and supported expanded ballot access measures. His voting rights record reflects strong progressive Democratic support for removing barriers to political participation.$$,
        ARRAY['https://actonmass.org/legislators/richard-wells/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a3131d21-f3ad-4483-ac6d-13c9c7ecdd74';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='a3131d21-f3ad-4483-ac6d-13c9c7ecdd74' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='a3131d21-f3ad-4483-ac6d-13c9c7ecdd74' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
