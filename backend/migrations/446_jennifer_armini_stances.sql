-- ============================================================================
-- Migration 446: Jennifer Balinsky Armini Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jennifer Balinsky Armini (MA State Rep,
--   HD-31, 8th Essex District, Marblehead).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 6148f954-b8cc-4204-96ca-34f2afc1d24a (external_id=-210071)

BEGIN;

-- ----- Jennifer Balinsky Armini / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Armini co-sponsored the Abortion Access Act as tracked by Act on Mass. She also co-sponsored H.2362 relative to chaperones for medical exams, improving patient safety and consent in medical settings. These bills reflect strong support for reproductive rights and women's healthcare protections.$$,
        ARRAY['https://actonmass.org/legislators/jennifer-armini/', 'https://malegislature.gov/Bills/194/H2362']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Balinsky Armini / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Armini co-sponsored 100% Renewable Energy by 2045 (Act on Mass) and serves on the House Committee on Global Warming and Climate Change. She sponsored H.3445 for solar panel installations on school property, H.3539 relative to clean thermal energy, and co-sponsored H.3753 to electrify MBTA commuter rail lines. Her comprehensive climate legislation portfolio reflects a strong commitment to the clean energy transition.$$,
        ARRAY['https://actonmass.org/legislators/jennifer-armini/', 'https://malegislature.gov/Bills/194/H3445', 'https://malegislature.gov/Bills/194/H3539', 'https://malegislature.gov/Bills/194/H3753']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Balinsky Armini / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Armini co-sponsored H.3400 to prohibit the use of ratepayer funds for utility lobbying, promotions, or perks — directly targeting the political influence of fossil fuel utilities. She also sponsored H.3446 to further regulate gas companies' use of public ways. Combined with her clean energy bill portfolio (solar, clean thermal, rail electrification), these bills reflect a strong anti-fossil-fuel and pro-regulation stance on utility companies.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3400', 'https://malegislature.gov/Bills/194/H3446', 'https://malegislature.gov/Bills/194/H3445']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Balinsky Armini / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Armini sponsored H.1050/1051 on flood risk assessment and voluntary property acquisition for at-risk coastal properties, H.1013 on a municipal reforestation program, H.888 relative to recreation on private tidelands, H.889 on boat wrap recycling, and H.3285 to designate eelgrass as the official marine flora of the Commonwealth. This marine environment and coastal resilience focus reflects the priorities of her Marblehead coastal district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1050', 'https://malegislature.gov/Bills/194/H1013', 'https://malegislature.gov/Bills/194/H888', 'https://malegislature.gov/Bills/194/H3285']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Balinsky Armini / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Armini sponsored H.3609 relative to the operation of bicycles and motor vehicles at certain intersections (bike safety/multi-modal transportation) and co-sponsored H.3753 relative to the electrification of MBTA commuter rail lines. Both bills reflect a transit-forward and active transportation approach to mobility, consistent with her coastal North Shore district's commuter rail access priorities.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3609', 'https://malegislature.gov/Bills/194/H3753']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Balinsky Armini / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Armini co-sponsored Medicare for All, Overdose Prevention Centers, and the THRIVE Act (Act on Mass). She sponsored H.1164 relative to the definition of licensed mental health professional in insurance laws, expanding mental health coverage. She also co-sponsored H.2362 on chaperones for medical exams. These bills reflect strong support for universal healthcare and mental health parity.$$,
        ARRAY['https://actonmass.org/legislators/jennifer-armini/', 'https://malegislature.gov/Bills/194/H1164']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Balinsky Armini / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Armini co-sponsored Campaign Childcare legislation as tracked by Act on Mass, which supports affordable and accessible childcare. She also co-sponsored H.201 relative to child support enforcement, reflecting an interest in family economic security and child welfare.$$,
        ARRAY['https://actonmass.org/legislators/jennifer-armini/', 'https://malegislature.gov/Bills/194/H201']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Balinsky Armini / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6148f954-b8cc-4204-96ca-34f2afc1d24a',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Armini co-sponsored Progressive Revenue legislation as tracked by Act on Mass, which supports raising taxes on high-income earners and corporations to fund public services. She also co-sponsored the Stop Corporate Offshoring bill. Her tax stance reflects a progressive position consistent with her broad social investment priorities.$$,
        ARRAY['https://actonmass.org/legislators/jennifer-armini/', 'https://malegislature.gov/Legislators/Profile/JBA1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '6148f954-b8cc-4204-96ca-34f2afc1d24a';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '6148f954-b8cc-4204-96ca-34f2afc1d24a'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '6148f954-b8cc-4204-96ca-34f2afc1d24a'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
