-- ============================================================================
-- Migration 503: Kate Lipper-Garabedian Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kate Lipper-Garabedian (MA House HD-88,
--   32nd Middlesex District, Melrose area). External ID: -210128.
--   Lipper-Garabedian has served since 2019; Democrat known for mental health,
--   healthcare, housing, and education advocacy.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Kate Lipper-Garabedian (HD-88, external_id=-210128)
-- Politician UUID: 37e88d74-8fdf-4a66-8685-989248512b29

-- ----- Kate Lipper-Garabedian / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Lipper-Garabedian co-sponsored the ROE Act (H.3320) and has voted consistently for reproductive rights legislation. She received NARAL Pro-Choice Massachusetts endorsement. Her ActOnMass scorecard confirms consistent support for abortion access.$$,
        ARRAY['https://actonmass.org/legislators/kate-lipper-garabedian/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Lipper-Garabedian / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lipper-Garabedian co-sponsored the Affordable and Accessible Child Care for All Act and has advocated for universal pre-K and subsidized childcare for working families. She has been active on early education issues, recognizing childcare access as critical for working parents and child development.$$,
        ARRAY['https://actonmass.org/legislators/kate-lipper-garabedian/', 'https://actonmass.org/bills/universal-childcare/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Lipper-Garabedian / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lipper-Garabedian voted for the 2021 MA climate roadmap committing to net-zero emissions by 2050. She has supported clean energy investment and building efficiency programs. Her record shows consistent Democratic support for the state's climate framework.$$,
        ARRAY['https://actonmass.org/legislators/kate-lipper-garabedian/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Lipper-Garabedian / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lipper-Garabedian co-sponsored the Medicare for All Massachusetts Act (H.1279) and has been a strong advocate for universal healthcare coverage. She has particularly focused on mental health parity and substance use treatment, filing and supporting legislation to ensure mental health is treated equally with physical health in insurance coverage and access to care.$$,
        ARRAY['https://actonmass.org/legislators/kate-lipper-garabedian/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Lipper-Garabedian / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lipper-Garabedian has voted for affordable housing funding legislation and supported MBTA Communities zoning reform to encourage transit-oriented development near Boston. She has backed increased housing production to address the affordability crisis in her district while supporting tenant protection measures.$$,
        ARRAY['https://actonmass.org/legislators/kate-lipper-garabedian/', 'https://malegislature.gov/Legislators/Profile/KLG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Lipper-Garabedian / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Lipper-Garabedian voted for the Work and Family Mobility Act (drivers' licenses for all residents) and the DREAM Act. She has supported immigrant integration policies and services. Her record reflects mainstream Democratic support for immigrant inclusion measures.$$,
        ARRAY['https://actonmass.org/legislators/kate-lipper-garabedian/', 'https://malegislature.gov/Legislators/Profile/KLG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Lipper-Garabedian / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Lipper-Garabedian co-sponsored the Medicare for All Massachusetts Act and has consistently voted to protect and expand MassHealth. She has supported mental health coverage expansions within MassHealth and opposed cuts to the program. Her record reflects strong support for government-funded healthcare programs.$$,
        ARRAY['https://actonmass.org/legislators/kate-lipper-garabedian/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Lipper-Garabedian / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lipper-Garabedian voted for the 2022 Millionaires Tax (Fair Share Amendment) supporting the 4% surtax on high incomes to fund education and transportation. Her tax record reflects progressive-leaning Democratic positions supporting revenue increases for public services.$$,
        ARRAY['https://actonmass.org/legislators/kate-lipper-garabedian/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kate Lipper-Garabedian / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37e88d74-8fdf-4a66-8685-989248512b29',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Lipper-Garabedian voted for the 2022 VOTES Act making early voting and mail voting permanent. She has supported expanded ballot access and participated in efforts to increase voter participation in her district.$$,
        ARRAY['https://actonmass.org/legislators/kate-lipper-garabedian/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '37e88d74-8fdf-4a66-8685-989248512b29';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='37e88d74-8fdf-4a66-8685-989248512b29' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='37e88d74-8fdf-4a66-8685-989248512b29' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
