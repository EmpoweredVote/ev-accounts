-- ============================================================================
-- Migration 544: John F. Moran Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for John F. Moran (MA State Rep,
--          9th Suffolk District, HD-129, external_id=-210169).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- John F. Moran (HD-129, external_id=-210169, id=7cc9694b-3bca-44ec-ab75-762c1f6d5136) --

-- ----- John F. Moran / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Moran sponsored H.1653 (behavioral health access) and H.1810 (substance use disorder prevention and treatment). He represents Allston-Brighton — a dense urban neighborhood with significant healthcare access needs. His healthcare focus is on community health center funding, behavioral health expansion, and substance use treatment rather than structural reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1653', 'https://malegislature.gov/Legislators/Profile/JFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Moran / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Moran sponsored H.1342 (An Act to increase affordable housing in transit areas) and supported tenant protections. Allston-Brighton has Boston's highest concentration of university students and young renters, with severe housing cost burdens. He has advocated for increased affordable unit production, student tenant protections, and affordability requirements in transit-oriented development.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1342', 'https://malegislature.gov/Legislators/Profile/JFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Moran / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Moran sponsored H.2714 (MBTA service reliability improvements) and has been a consistent advocate for transit investment. Allston-Brighton is served by the Green Line B branch and multiple bus routes and has historically been underserved by transit relative to inner neighborhoods. He has advocated for Green Line improvements, bus rapid transit, and bike infrastructure as priorities for his district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2714', 'https://malegislature.gov/Legislators/Profile/JFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Moran / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Moran voted for the 2021 Climate Act (H.4933) and has supported clean energy investment. He represents an urban district with significant building energy use and transportation emissions. He has backed clean building requirements and transit electrification as climate priorities relevant to his dense urban district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/JFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Moran / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Moran voted for the ROE Act (H.3320) in 2020 expanding Massachusetts abortion access. He supports legal abortion access in his district, which includes Boston College and other university communities. He has not been a lead co-sponsor of abortion access expansion bills but has voted in support of the major expansion measures that have come to the House floor.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/JFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Moran / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Moran co-sponsored the Safe Communities Act (H.3369) and has supported immigrant access to state services. Allston-Brighton has a significant immigrant population from Brazil, China, and other countries. He has backed sanctuary policies and immigrant integration services while not being among the most prominent advocates for immigration reform in the House.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Moran / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Moran voted for the Police Reform Act (H.4835) and co-sponsored the Safe Communities Act (H.3369). He has maintained a consistent pro-civil-rights voting record in line with the House Democratic caucus. His Allston-Brighton district includes a diverse population of students, immigrants, and long-term residents who benefit from civil rights protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John F. Moran / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cc9694b-3bca-44ec-ab75-762c1f6d5136',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Moran voted for the Police Reform Act (H.4835). He represents Allston-Brighton, which has a college-town dynamic with both community safety concerns and civil liberties interests. He has supported accountability reforms without being among the most progressive voices on police defunding, reflecting a moderate approach for his diverse constituency.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/JFM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '7cc9694b-3bca-44ec-ab75-762c1f6d5136';
-- unpaired=0, uncited=0
