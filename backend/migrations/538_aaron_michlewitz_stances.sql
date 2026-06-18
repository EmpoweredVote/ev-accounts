-- ============================================================================
-- Migration 538: Aaron Michlewitz Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Aaron Michlewitz (MA State Rep,
--          3rd Suffolk District, HD-123, external_id=-210163).
--          Chair of the House Committee on Ways and Means — House budget writer.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Aaron Michlewitz (HD-123, external_id=-210163, id=9cf147de-64e0-4116-b461-95933e18c423) --

-- ----- Aaron Michlewitz / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$As Chair of Ways and Means, Michlewitz drafted the House FY2024 and FY2025 budgets that significantly increased healthcare funding including expanded MassHealth coverage and behavioral health investments. He co-sponsored H.1700 (behavioral health parity) and supported the 2021 telehealth expansion law. His budget leadership has translated healthcare priorities into funded programs while maintaining a pragmatic rather than single-payer approach.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1700', 'https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Michlewitz played a key role in advancing the Affordable Homes Act (H.4977/S.2834) through the House in 2024, including $5.16 billion for housing programs. As Ways and Means Chair, he shaped the housing funding provisions and inclusion of tenant protections. He represents the North End and Waterfront — areas with significant housing affordability challenges — and has supported mixed-income development and anti-displacement measures.$$,
        ARRAY['https://malegislature.gov/Bills/193/H4977', 'https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Ways and Means Chair, Michlewitz led the House implementation of the 2023 tax reform package (H.4104), which included both surtax revenue allocation from the millionaires' surtax and business-friendly tax relief (estate tax, short-term capital gains, child credits). His approach balances progressive tax revenue from high earners with maintaining competitive tax rates for businesses — a centrist tax position within the Democratic caucus.$$,
        ARRAY['https://malegislature.gov/Bills/193/H4104', 'https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$As Ways and Means Chair, Michlewitz crafted the House economic development bond bill (H.5033) with billions in capital investment for infrastructure, workforce development, and innovation. He supported the Mass Life Sciences Center funding and economic development in the Seaport/Innovation District adjacent to his North End/Waterfront district. His approach favors public-private partnerships and targeted investment over broad redistribution.$$,
        ARRAY['https://malegislature.gov/Bills/194/H5033', 'https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Michlewitz voted for the 2021 Climate Act (H.4933) and as Ways and Means Chair, he included clean energy and climate resilience funding in successive House budgets. He supported the 2022 Clean Energy Bill (offshore wind contracting) and climate adaptation measures for coastal areas, including his North End/Waterfront district vulnerable to sea level rise. He has funded climate programs while balancing ratepayer and economic competitiveness concerns.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Michlewitz co-sponsored the Safe Communities Act (H.3369) limiting ICE cooperation. As Ways and Means Chair, he included immigrant integration services and legal aid funding in the House budget. He represents Boston's North End and Waterfront, historically an immigrant neighborhood (Italian-American community), and has consistently supported immigrant access to state services.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Michlewitz voted for the ROE Act (H.3320) in 2020 expanding abortion access in Massachusetts. He is a pragmatic Democrat from a historically Catholic North End community; he voted for the expansion without being a lead co-sponsor. His vote demonstrates support for broad abortion access including later-term exceptions while operating in a district with conservative Catholic influences.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Michlewitz voted for the 2020 Police Reform Act (H.4835) but as a centrist leader did not join more progressive colleagues in pushing for deeper defunding. His House budgets have maintained traditional public safety spending levels while including funding for mental health crisis response. He represents the North End — a densely populated urban neighborhood — and supports maintaining community safety while endorsing accountability reforms.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Michlewitz supported the Safe Communities Act and Police Reform Act. In his budgets as Ways and Means Chair, he included funding for civil rights enforcement and anti-discrimination programs. He has maintained a pro-civil-rights voting record consistent with the House Democratic caucus, including LGBTQ+ protections and anti-discrimination measures, without being among the most progressive advocates.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$As Ways and Means Chair, Michlewitz has included substantial MBTA capital funding in House budgets and supported the FY2024 transportation bond bill. His district — Boston North End and Waterfront — is heavily transit-dependent and pedestrian-oriented with limited parking. He has consistently supported MBTA investment and opposed cuts to public transportation while also supporting the Big Dig and waterfront infrastructure as economic drivers.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Michlewitz has consistently opposed voucher-type diversion of public education funds. His House budgets increased Chapter 70 aid to public schools and he has voted against charter school cap expansions. As Ways and Means Chair, he controls education funding and has directed it toward public school systems rather than private alternatives.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron Michlewitz / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cf147de-64e0-4116-b461-95933e18c423',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$As a senior House Democratic leader, Michlewitz participated in the 2021 redistricting process through the legislature-controlled Joint Committee on Redistricting rather than an independent commission. He did not co-sponsor independent redistricting reform legislation. His position within the House leadership reflects institutional preference for legislative control of redistricting over external independent commissions.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/AMM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9cf147de-64e0-4116-b461-95933e18c423';
-- unpaired=0, uncited=0
