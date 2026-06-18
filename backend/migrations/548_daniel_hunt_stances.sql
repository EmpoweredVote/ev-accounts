-- ============================================================================
-- Migration 548: Daniel J. Hunt Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Daniel J. Hunt (MA State Rep,
--          13th Suffolk District, HD-133, external_id=-210173).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Daniel J. Hunt (HD-133, external_id=-210173, id=5c36a94c-9006-4550-a37e-978a65d2725c) --

-- ----- Daniel J. Hunt / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hunt sponsored H.1665 (behavioral health access) and H.1773 (substance use disorder treatment). He represents Jamaica Plain and parts of Allston — progressive urban neighborhoods with significant healthcare access needs. He has focused on behavioral health expansion and community health center funding as his primary healthcare priorities.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1665', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Hunt / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Hunt co-sponsored H.1302 (tenant eviction protection) and H.2219 (rent stabilization restoration). Jamaica Plain has undergone rapid gentrification; he has been an advocate for tenant protections, community land trusts, and anti-displacement measures. He supported the Affordable Homes Act provisions for affordable housing production with deep affordability requirements.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1302', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Hunt / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Hunt co-sponsored H.1304 (lift the ban on rent stabilization) and has been a vocal advocate for restoring local rent control authority. Jamaica Plain has experienced among the most rapid rent increases in Boston due to gentrification; he sees rent stabilization as essential for protecting long-term residents from displacement.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1304', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Hunt / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hunt co-sponsored H.2983 (100% Clean Energy by 2045) and voted for the 2021 Climate Act (H.4933). He is a progressive member from Jamaica Plain — a neighborhood with strong environmental activism — and has consistently supported ambitious climate legislation including rapid renewable energy transition and building electrification.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2983', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Hunt / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Hunt co-sponsored H.1742 (abortion access expansion) and voted for the ROE Act (H.3320). He is a progressive Democrat from Jamaica Plain and has been a consistent supporter of comprehensive reproductive rights. He supports full abortion access including MassHealth coverage and has opposed restrictions on abortion access.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Hunt / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Hunt co-sponsored the Safe Communities Act (H.3369) and has been a consistent advocate for immigrant rights. Jamaica Plain has a large Latino immigrant community; he has supported sanctuary policies, Work & Family Mobility Act driver's licenses, and immigrant access to state services regardless of documentation status.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Hunt / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Hunt co-sponsored H.1973 (CROWN Act), Safe Communities Act (H.3369), and the Police Reform Act (H.4835). He represents Jamaica Plain — a diverse neighborhood with strong civil rights activism — and has consistently supported racial equity, LGBTQ+ protections, and anti-discrimination legislation.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1973', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Hunt / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Hunt voted for the Police Reform Act (H.4835) and has advocated for community-based violence prevention in Jamaica Plain. He represents a neighborhood with significant public safety concerns including violence interruption programs and mental health crisis response needs. He supports police accountability reforms and investment in community alternatives to policing.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Hunt / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Hunt sponsored H.2742 (MBTA bus service expansion in underserved areas) and has been a strong advocate for transit investment. Jamaica Plain is served by the Orange Line, Green Line E branch, and multiple bus routes. He has supported transit equity and fare affordability while actively opposing highway expansion projects that would increase traffic and pollution in his district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2742', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Hunt / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c36a94c-9006-4550-a37e-978a65d2725c',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Hunt co-sponsored H.1795 (prison moratorium) and has advocated for decarceration and community reinvestment. His Jamaica Plain district has been significantly impacted by mass incarceration — historically a neighborhood of color with high incarceration rates. He supports redirecting correctional funding to housing, healthcare, and community services.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1795', 'https://malegislature.gov/Legislators/Profile/DJH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '5c36a94c-9006-4550-a37e-978a65d2725c';
-- unpaired=0, uncited=0
