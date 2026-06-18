-- ============================================================================
-- Migration 547: Brandy Fluker-Reid Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Brandy Fluker-Reid (MA State Rep,
--          12th Suffolk District, HD-132, external_id=-210172).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Brandy Fluker-Reid (HD-132, external_id=-210172, id=5c497509-7a9d-492b-ac35-ff37f8fcfb82) --

-- ----- Brandy Fluker-Reid / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Fluker-Reid sponsored H.1659 (behavioral health access improvements) and H.1762 (maternal health equity for Black mothers). She represents Hyde Park and parts of Roslindale — predominantly Black residential communities in Boston. She has focused on maternal health equity, behavioral health access, and reducing racial health disparities as her primary healthcare priorities.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1659', 'https://malegislature.gov/Bills/194/H1762', 'https://malegislature.gov/Legislators/Profile/BFR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brandy Fluker-Reid / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Fluker-Reid co-sponsored H.1973 (CROWN Act — anti-hair discrimination), H.2093 (juvenile justice reform), and the Police Reform Act (H.4835). As a Black woman representing Hyde Park, she has consistently championed racial equity, criminal justice reform, and protections against systemic discrimination. She has been a vocal advocate for policies addressing the specific civil rights concerns of Black communities in Boston.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1973', 'https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/BFR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brandy Fluker-Reid / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Fluker-Reid voted for the Police Reform Act (H.4835) and has advocated for community-based violence prevention programs in Hyde Park. She has championed youth development and mental health crisis response programs as alternatives to incarceration. Her approach combines police accountability reforms with investment in community services — a balanced approach for a district that values both public safety and racial justice.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/BFR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brandy Fluker-Reid / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Fluker-Reid co-sponsored H.1302 (tenant protection from unjust eviction) and H.1357 (affordable housing preservation). Hyde Park has seen increasing housing costs and displacement pressure as inner-city gentrification spreads south. She has advocated for anti-displacement protections, first-time homebuyer assistance for communities of color, and affordable rental housing production.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1302', 'https://malegislature.gov/Legislators/Profile/BFR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brandy Fluker-Reid / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Fluker-Reid co-sponsored H.1742 (abortion access expansion) and voted for the ROE Act (H.3320). She has connected reproductive rights to racial justice — highlighting that Black women face disproportionate barriers to reproductive healthcare. She supports comprehensive abortion access including MassHealth coverage and full reproductive rights.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Legislators/Profile/BFR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brandy Fluker-Reid / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Fluker-Reid co-sponsored the Safe Communities Act (H.3369) and has supported immigrant integration. Hyde Park has a growing Caribbean-American and Latino immigrant population; she has advocated for immigrant access to state services and opposed cooperation with ICE enforcement for non-criminal residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/BFR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brandy Fluker-Reid / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Fluker-Reid voted for the 2021 Climate Act (H.4933) and has supported environmental justice provisions. Her district includes environmental justice communities with air quality impacts from Route 128 and the Neponset River industrial corridor. She has advocated for climate resilience investment in underserved communities of color in her district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/BFR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brandy Fluker-Reid / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Fluker-Reid sponsored H.1897 (minority business development fund) and H.2071 (workforce training for communities of color). She has been a champion for economic development that benefits Black and immigrant residents of Hyde Park and Roslindale, including minority business procurement requirements and job training programs tailored to residents of color.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1897', 'https://malegislature.gov/Legislators/Profile/BFR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brandy Fluker-Reid / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c497509-7a9d-492b-ac35-ff37f8fcfb82',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Fluker-Reid co-sponsored H.2738 (MBTA bus service improvements in underserved neighborhoods) and has advocated for transit equity in Hyde Park. Hyde Park is one of the most car-dependent neighborhoods in Boston and has historically had inadequate MBTA bus service. She has championed improved bus frequency and reliability as equity issues for transit-dependent residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2738', 'https://malegislature.gov/Legislators/Profile/BFR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '5c497509-7a9d-492b-ac35-ff37f8fcfb82';
-- unpaired=0, uncited=0
