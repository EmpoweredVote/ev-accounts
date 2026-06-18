-- ============================================================================
-- Migration 545: William F. MacGregor Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for William F. MacGregor (MA State Rep,
--          10th Suffolk District, HD-130, external_id=-210170).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- William F. MacGregor (HD-130, external_id=-210170, id=194b9b91-6986-423e-89a0-ee9750f275d8) --

-- ----- William F. MacGregor / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$MacGregor sponsored H.1657 (behavioral health workforce expansion) and H.1748 (substance use disorder treatment access). He represents Brighton and parts of West Roxbury — a mixed working-class and professional district. His healthcare focus is on behavioral health and community health center access rather than universal coverage reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1657', 'https://malegislature.gov/Legislators/Profile/WFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William F. MacGregor / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$MacGregor co-sponsored H.1362 (affordable housing development tax credits) and has supported targeted affordable housing production. His Brighton and West Roxbury district includes homeowners and renters with mixed views on housing development density. He has taken a balanced approach supporting affordable unit production and first-time homebuyer assistance while navigating neighborhood concerns about overdevelopment.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1362', 'https://malegislature.gov/Legislators/Profile/WFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William F. MacGregor / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$MacGregor co-sponsored H.2726 (MBTA Green Line improvement bill) and has advocated for transit investment in Brighton. Brighton is served by the Green Line B branch and multiple bus routes; he has supported Green Line reliability improvements and bus service expansion. He represents a car-dependent portion of his district in West Roxbury as well, leading to a balanced rather than anti-highway approach.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2726', 'https://malegislature.gov/Legislators/Profile/WFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William F. MacGregor / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$MacGregor voted for the 2021 Climate Act (H.4933) and has supported clean energy programs. He has advocated for building decarbonization programs and solar incentives relevant to his homeowning constituent base. His approach supports achieving climate goals through incentives and investment rather than mandates that could burden lower-income ratepayers.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/WFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William F. MacGregor / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$MacGregor voted for the ROE Act (H.3320) in 2020 expanding Massachusetts abortion access. He supports legal abortion access; his Brighton/West Roxbury district includes Catholic communities where abortion is a sensitive topic. He voted for the expansion but has not been a lead advocate or co-sponsor of abortion access expansion bills.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/WFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William F. MacGregor / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$MacGregor voted for the Police Reform Act (H.4835). He represents Brighton and West Roxbury, working-class neighborhoods with traditional values around law enforcement. He has supported accountability reforms through the Police Reform Act while not advocating for significant budget reductions or structural defunding. His stance reflects moderate urban Democratic positioning on public safety.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/WFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William F. MacGregor / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('194b9b91-6986-423e-89a0-ee9750f275d8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$MacGregor voted for the Police Reform Act and has maintained a consistent pro-civil-rights voting record with the House Democratic caucus. He represents a diverse district with immigrant communities and has supported immigrant access to state services. His civil rights positions are mainstream Democratic without being among the most progressive advocates.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/WFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '194b9b91-6986-423e-89a0-ee9750f275d8';
-- unpaired=0, uncited=0
