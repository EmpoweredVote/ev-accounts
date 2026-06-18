-- ============================================================================
-- Migration 542: Chynah Tyler Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Chynah Tyler (MA State Rep,
--          7th Suffolk District, HD-127, external_id=-210167).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Chynah Tyler (HD-127, external_id=-210167, id=fd3bf15c-265b-46a9-aa72-c9097749d762) --

-- ----- Chynah Tyler / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Tyler co-sponsored H.1239 (Medicare for All in Massachusetts) and H.1600 (behavioral health parity). She has consistently advocated for universal healthcare access and has specifically championed health equity for Black communities experiencing racial health disparities. Her healthcare positions reflect strong support for comprehensive coverage expansion and public health investment.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1239', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Tyler co-sponsored H.1973 (CROWN Act — anti-hair discrimination) and was a lead advocate for the 2020 Police Reform Act (H.4835). As a Black woman from Roxbury, she has championed racial equity legislation including mandatory anti-racism training, ending solitary confinement, and criminal justice reform. She has been among the most progressive voices on civil rights in the House.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1973', 'https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Tyler voted for the Police Reform Act (H.4835) and has been among the House's most vocal advocates for community-based alternatives to policing. She has specifically championed violence interrupter programs, CAHOOTS-style mental health response, and investment in Roxbury community violence prevention. Her public safety approach strongly emphasizes accountability and redirecting resources from police to community services.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Tyler co-sponsored H.1304 (rent stabilization), H.1299 (eviction protection), and H.2219 (local option rent control). Roxbury has experienced dramatic gentrification displacing longtime Black residents. She has been among the most aggressive advocates for tenant protections, community land trusts, and publicly funded affordable housing production with deep affordability requirements.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1304', 'https://malegislature.gov/Bills/194/H1299', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Tyler is a co-sponsor of H.1304 (An Act to lift the ban on rent stabilization) and has been one of the Legislature's strongest voices for restoring local rent control authority. She has publicly advocated for rent stabilization as essential to preventing the displacement of Black residents from Roxbury amid rising rents throughout Boston's inner neighborhoods.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1304', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Tyler co-sponsored H.1795 (prison moratorium) and H.2093 (juvenile justice reform). She has been a leading advocate for abolishing the use of solitary confinement in MA and reducing the prison population. Her Roxbury district has been deeply affected by mass incarceration and she views expanding jail capacity as antithetical to racial justice and community investment goals.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1795', 'https://malegislature.gov/Bills/194/H2093', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Tyler co-sponsored H.1742 (abortion access expansion) and voted for the ROE Act (H.3320). She has connected reproductive rights to racial justice — noting that abortion restrictions have disproportionate impacts on women of color — and strongly supports comprehensive abortion access including MassHealth coverage.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Tyler co-sponsored the Safe Communities Act (H.3369) and has advocated for comprehensive immigration reform. She has drawn connections between immigration enforcement and racial justice, opposing ICE cooperation and supporting sanctuary policies that allow immigrant residents of Roxbury to access city services without fear of deportation.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Tyler sponsored H.1893 (minority business development and procurement equity) and H.2097 (community wealth building). She advocates for economic development that centers Black and immigrant-owned businesses in Roxbury and supports community benefits agreements for large developments in her district. Her economic development approach explicitly prioritizes racial equity and community control over conventional growth metrics.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1893', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Tyler voted for the 2021 Climate Act (H.4933) and co-sponsored environmental justice provisions linking climate action to racial equity. She has been vocal about the environmental justice dimensions of climate change — specifically how Roxbury and Dorchester communities of color bear disproportionate heat and pollution burdens from highways and industrial land uses.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chynah Tyler / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fd3bf15c-265b-46a9-aa72-c9097749d762',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Tyler co-sponsored the Environmental Justice Policy Act (H.4264) and has been among its strongest advocates in the House. Roxbury is a designated EJ community with elevated air pollution from I-93 and Route 1. She has championed green infrastructure investment, urban heat island mitigation, and air quality improvements specifically for EJ communities of color.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/C_T1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'fd3bf15c-265b-46a9-aa72-c9097749d762';
-- unpaired=0, uncited=0
