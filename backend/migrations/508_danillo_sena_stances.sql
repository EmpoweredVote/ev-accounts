-- ============================================================================
-- Migration 508: Danillo Sena Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Danillo Sena (MA House HD-93,
--   37th Middlesex District, Acton area). External ID: -210133.
--   Sena has served since 2021; Democrat, progressive on healthcare, climate,
--   and voting rights; represents Acton, Stow, and parts of other Middlesex towns.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Danillo Sena (HD-93, external_id=-210133)
-- Politician UUID: f8986c05-2e32-4184-bfb2-9d4c244ffd3a

-- ----- Danillo Sena / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Sena co-sponsored the ROE Act to codify and expand abortion rights in Massachusetts. He has consistently voted for reproductive rights legislation since his election and received NARAL Pro-Choice Massachusetts endorsement. His ActOnMass profile confirms strong support for abortion access.$$,
        ARRAY['https://actonmass.org/legislators/danillo-sena/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danillo Sena / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sena co-sponsored the 100% Renewable Energy Act and voted for the 2021 climate roadmap. He represents Acton, which has been a leader in local climate initiatives, and he has championed state-level clean energy investment and building electrification legislation. He has been active on the Joint Committee on Telecommunications, Utilities and Energy on climate-related bills.$$,
        ARRAY['https://actonmass.org/legislators/danillo-sena/', 'https://actonmass.org/bills/100-renewable-energy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danillo Sena / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sena co-sponsored the Stop Wage Theft Act and supported worker protections in the MA House. He has backed minimum wage increases and economic policies that support working families in his Acton-area suburban district. His economic record reflects progressive-leaning Democratic positions on worker rights.$$,
        ARRAY['https://actonmass.org/legislators/danillo-sena/', 'https://actonmass.org/bills/stop-wage-theft/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danillo Sena / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Sena co-sponsored legislation to phase out fossil fuel infrastructure in buildings and supports aggressive electrification goals. He has opposed new fossil fuel infrastructure and supported clean energy transition policies. His Acton district's environmental consciousness aligns with his strong fossil fuel phase-out positions.$$,
        ARRAY['https://actonmass.org/legislators/danillo-sena/', 'https://actonmass.org/bills/100-renewable-energy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danillo Sena / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sena co-sponsored the Medicare for All Massachusetts Act (H.1279) and has been an advocate for universal healthcare coverage. He has voted for MassHealth expansion and mental health parity legislation. His healthcare record reflects progressive support for single-payer universal coverage.$$,
        ARRAY['https://actonmass.org/legislators/danillo-sena/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danillo Sena / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sena has voted for affordable housing funding and MBTA Communities zoning reform. He has supported transit-oriented development policies to increase housing supply in his suburban district. His housing positions reflect progressive-leaning Democratic support for housing production with affordability requirements.$$,
        ARRAY['https://actonmass.org/legislators/danillo-sena/', 'https://malegislature.gov/Legislators/Profile/DAS1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danillo Sena / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Sena co-sponsored the Safe Communities Act to limit MA cooperation with ICE enforcement. He is a first-generation Brazilian immigrant himself, making immigration a personal issue, and has supported the DREAM Act, drivers' licenses for all residents, and comprehensive immigrant rights legislation. His personal background informs his strong advocacy for immigrant communities.$$,
        ARRAY['https://actonmass.org/legislators/danillo-sena/', 'https://actonmass.org/bills/safe-communities-act/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danillo Sena / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Sena voted for the 2022 Millionaires Tax (Fair Share Amendment) and has supported progressive tax measures to fund public education and services. His ActOnMass scorecard reflects consistent support for tax-the-wealthy bills. His progressive approach to taxation aligns with his broader support for government investment in public goods.$$,
        ARRAY['https://actonmass.org/legislators/danillo-sena/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Danillo Sena / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Sena voted for the 2022 VOTES Act making early voting and vote-by-mail permanent. He has supported automatic voter registration and noncitizen local voting rights bills. As a first-generation immigrant, he has spoken about the importance of participation and voting rights for all community members.$$,
        ARRAY['https://actonmass.org/legislators/danillo-sena/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'f8986c05-2e32-4184-bfb2-9d4c244ffd3a';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='f8986c05-2e32-4184-bfb2-9d4c244ffd3a' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='f8986c05-2e32-4184-bfb2-9d4c244ffd3a' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
