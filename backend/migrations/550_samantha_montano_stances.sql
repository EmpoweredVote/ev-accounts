-- ============================================================================
-- Migration 550: Samantha Montaño Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Samantha Montaño (MA State Rep,
--          15th Suffolk District, HD-135, external_id=-210175).
--          Also written as Samantha Montano (ASCII). First Afro-Latina woman
--          elected to Massachusetts Legislature.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Samantha Montano (HD-135, external_id=-210175, id=28a703f8-8316-4d3c-bfc0-3dcd77eab96c) --

-- ----- Samantha Montano / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Montaño co-sponsored H.1239 (Medicare for All in Massachusetts) and H.1600 (behavioral health parity). She represents Mission Hill and Jamaica Plain — neighborhoods with community health centers serving lower-income populations. She has strongly advocated for universal healthcare coverage and has specifically championed maternal health equity for women of color facing disparate outcomes.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1239', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samantha Montano / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Montaño co-sponsored H.1973 (CROWN Act), H.2093 (juvenile justice reform), and Safe Communities Act (H.3369). As the first Afro-Latina woman in the Massachusetts Legislature, she has been a leading voice for racial and ethnic civil rights protections. She has championed intersectional civil rights — connecting racial justice, immigrant rights, and LGBTQ+ protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1973', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samantha Montano / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Montaño co-sponsored H.1299 (eviction protection), H.1304 (rent stabilization), and H.1318 (emergency housing assistance). Mission Hill and Jamaica Plain have both experienced rapid gentrification displacing longtime residents of color. She has been among the most aggressive House advocates for tenant protections, rent control, and deep-affordability housing requirements.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1304', 'https://malegislature.gov/Bills/194/H1299', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samantha Montano / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Montaño is a co-sponsor of H.1304 (lift the ban on rent stabilization) and has been among the Legislature's most vocal advocates for rent control restoration. She has made preventing displacement of working-class and immigrant families from Mission Hill and Jamaica Plain a central part of her legislative agenda.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1304', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samantha Montano / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Montaño voted for the Police Reform Act (H.4835) and has been among the strongest advocates for community-based public safety alternatives. She has championed violence interrupters, mental health crisis response programs, and diverting resources from policing to community services. Her district in Mission Hill and Jamaica Plain has a history of community-based public safety activism.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samantha Montano / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Montaño co-sponsored the Safe Communities Act (H.3369) and has been a consistent advocate for immigrant rights. Jamaica Plain has a large Latino immigrant population and she has advocated for sanctuary policies, driver's licenses for undocumented residents, and comprehensive immigrant integration services.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samantha Montano / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Montaño co-sponsored H.1742 (abortion access expansion) and voted for the ROE Act (H.3320). She has connected reproductive rights to racial justice and gender equity, supporting comprehensive abortion access including MassHealth coverage for low-income patients and coverage for all circumstances.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samantha Montano / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Montaño co-sponsored H.2983 (100% Clean Energy by 2045) and voted for the 2021 Climate Act (H.4933). She has championed environmental justice provisions connecting climate action to racial equity in her Mission Hill and Jamaica Plain district, which has environmental justice communities adjacent to highways and industrial land uses.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2983', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samantha Montano / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Montaño co-sponsored H.1795 (prison moratorium) and has advocated for decarceration and community reinvestment. She has championed juvenile justice reform and investment in community alternatives to incarceration. Her approach views jail expansion as antithetical to racial justice and community investment for the predominantly Latino communities she represents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1795', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Samantha Montano / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Montaño co-sponsored the Environmental Justice Policy Act (H.4264) and has been an advocate for linking environmental protection to racial equity in Mission Hill. Her district contains EJ communities affected by highway pollution from Route 9 and adjacent industrial zones. She has championed green infrastructure and air quality improvement investments in underserved communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/S_M1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '28a703f8-8316-4d3c-bfc0-3dcd77eab96c';
-- unpaired=0, uncited=0
