-- ============================================================================
-- Migration 546: Judith A. Garcia Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Judith A. Garcia (MA State Rep,
--          11th Suffolk District, HD-131, external_id=-210171).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Judith A. Garcia (HD-131, external_id=-210171, id=c4c3ed02-2592-4505-a26c-0195d0b5314e) --

-- ----- Judith A. Garcia / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Garcia co-sponsored H.1239 (Medicare for All in Massachusetts) and H.1600 (behavioral health parity). She is the first Dominican-American woman elected to the Massachusetts Legislature, representing Chelsea — one of the poorest cities in Massachusetts with among the worst healthcare access. She has been a leading advocate for universal healthcare coverage and immigrant access to MassHealth regardless of immigration status.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1239', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Garcia is a lead co-sponsor of H.3369 (Safe Communities Act) and has been the Legislature's most prominent voice on immigrant rights. Chelsea has Massachusetts's highest concentration of immigrants per capita; she has championed sanctuary policies, driver's license access for undocumented residents (Work & Family Mobility Act), and comprehensive immigration reform. She spoke extensively during the 2022 Work & Family Mobility Act debate as a lead advocate.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Garcia is a lead advocate for the Safe Communities Act (H.3369), preventing local police from cooperating with ICE. Her Chelsea constituency is overwhelmingly immigrant; she has championed policies ensuring immigrants can access city services including police protection without fear of deportation. She led the 2022 Work & Family Mobility Act effort enabling undocumented immigrants to obtain driver's licenses.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Garcia has been among the Legislature's strongest voices opposing deportation. She co-sponsored the Safe Communities Act (H.3369) to limit state cooperation with federal deportation actions and has spoken publicly against ICE raids in Chelsea. She advocates for keeping families together regardless of immigration status and has opposed deportation of long-term community members without criminal records.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Garcia co-sponsored H.1299 (tenant eviction protection), H.1304 (rent stabilization), and H.1318 (emergency housing assistance). Chelsea has among the highest rates of housing cost burden in Massachusetts; she has been a leading advocate for rent stabilization, emergency rental assistance, and deep-affordability housing production to protect immigrant and working-class families in her district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1304', 'https://malegislature.gov/Bills/194/H1299', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Garcia is a co-sponsor of H.1304 (lift the ban on rent stabilization) and has been among the Legislature's strongest advocates for rent control restoration. Chelsea renters pay among the highest rent-to-income ratios in Massachusetts; she views rent stabilization as essential to preventing mass displacement of her immigrant constituency.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1304', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Garcia co-sponsored H.1973 (CROWN Act), H.2093 (juvenile justice reform), and the Safe Communities Act (H.3369). As the first Dominican-American woman in the Legislature, she has been a leading voice for racial equity and civil rights protections for communities of color and immigrants. She has championed anti-discrimination enforcement and LGBTQ+ protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1973', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Garcia co-sponsored H.1742 (abortion access expansion) and voted for the ROE Act (H.3320). She has connected reproductive rights to racial justice, noting that abortion restrictions disproportionately affect immigrant women and women of color. She supports comprehensive abortion access including MassHealth coverage without restrictions.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Garcia sponsored H.1895 (minority business procurement equity) and H.2068 (workforce development for immigrant communities). Chelsea has high rates of poverty and unemployment; she has championed targeted economic development focusing on job training, small business support for immigrant entrepreneurs, and workforce development programs for low-income residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1895', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Garcia voted for the 2021 Climate Act (H.4933) and has championed environmental justice as inseparable from climate action. Chelsea Creek — in her district — is a major fossil fuel import terminal and industrial waterway; she has been among the most vocal advocates for shutting down fossil fuel infrastructure in EJ communities and transitioning to clean energy.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Garcia co-sponsored the Environmental Justice Policy Act (H.4264) and has been among its most passionate advocates. Chelsea is the state's most densely populated city and has long served as a sacrifice zone for industrial and fossil fuel infrastructure. She has championed air quality monitoring, GreenWave clean energy incentives for EJ communities, and phasing out the Chelsea Creek fuel terminal.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Judith A. Garcia / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c4c3ed02-2592-4505-a26c-0195d0b5314e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Garcia voted for the Police Reform Act (H.4835) and has advocated for accountability reforms and community-based violence prevention. She has specifically highlighted the connection between immigration enforcement and public safety — arguing that immigrant communities avoid calling police for fear of deportation. Her approach emphasizes accountability, community trust, and diversion from incarceration.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/JAG2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c4c3ed02-2592-4505-a26c-0195d0b5314e';
-- unpaired=0, uncited=0
