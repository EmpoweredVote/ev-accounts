-- ============================================================================
-- Migration 452: Adrianne P. Ramos Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Adrianne P. Ramos (MA State Rep, HD-37,
--   14th Essex District, North Andover).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: ee861f58-dabf-429f-97ee-32591bdd3650 (external_id=-210077)

BEGIN;

-- ----- Adrianne P. Ramos / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ramos co-sponsored the Abortion Access Act as tracked by Act on Mass (green checkmark on AOM profile). This bill would strengthen and codify abortion access protections in Massachusetts. Her co-sponsorship reflects a strong support for reproductive rights.$$,
        ARRAY['https://actonmass.org/legislators/adrianne-ramos/', 'https://malegislature.gov/Legislators/Profile/APR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrianne P. Ramos / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ramos co-sponsored LGBTQ+ Rights and the Healthy Youth Act (LGBTQ+ inclusive sex education) as tracked by Act on Mass (green checkmarks). She serves on the Joint Committee on the Judiciary, which handles civil rights and family law matters, and she sponsored multiple family law reform bills (H.1940 uniform family law arbitration, H.1942 uniform child custody jurisdiction) reflecting attention to equitable legal treatment.$$,
        ARRAY['https://actonmass.org/legislators/adrianne-ramos/', 'https://malegislature.gov/Legislators/Profile/APR1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrianne P. Ramos / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ramos co-sponsored the Cherish Act (fully funded public higher education, which includes support services and mental health) and the THRIVE Act as tracked by Act on Mass. These bills reflect support for expanding publicly funded health and support infrastructure. She did not co-sponsor Medicare for All — her healthcare approach appears incrementalist rather than single-payer.$$,
        ARRAY['https://actonmass.org/legislators/adrianne-ramos/', 'https://malegislature.gov/Legislators/Profile/APR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrianne P. Ramos / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ramos sponsored H.3547 to prevent gas expansion in Massachusetts in order to protect climate, community health and safety — a direct anti-fossil-fuel infrastructure bill that would halt new natural gas connections and pipeline expansion. This is among the most direct anti-fossil-fuel bills in the 194th General Court, reflecting a strong position against natural gas expansion.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3547', 'https://malegislature.gov/Legislators/Profile/APR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrianne P. Ramos / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ramos serves on the Joint Committee on Housing, giving her a direct legislative role in housing policy. She sponsored H.1941 relative to housing court jurisdiction — a bill to clarify and improve enforcement of housing law through the courts. Her committee assignment and sponsored bill reflect a commitment to housing access and tenant legal protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1941', 'https://malegislature.gov/Legislators/Profile/APR1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrianne P. Ramos / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ramos serves on the Joint Committee on Labor and Workforce Development, reflecting a sustained focus on worker economic development. She sponsored H.532 on the teacher leadership program (investing in educator career development) and H.676 studying the financing of Chapter 74 vocational-technical and agricultural schools — a targeted effort to improve workforce training pathways for students in North Andover and Essex County.$$,
        ARRAY['https://malegislature.gov/Bills/194/H532', 'https://malegislature.gov/Bills/194/H676', 'https://malegislature.gov/Legislators/Profile/APR1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adrianne P. Ramos / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee861f58-dabf-429f-97ee-32591bdd3650',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Ramos sponsored H.4111 to establish a battery recycling program in Massachusetts — addressing electronic waste and hazardous material disposal at the local level. Her anti-gas-expansion bill H.3547 also has direct local environmental health implications for North Andover and surrounding communities. These bills reflect a local environmental protection focus including waste management and air quality.$$,
        ARRAY['https://malegislature.gov/Bills/194/H4111', 'https://malegislature.gov/Bills/194/H3547']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ee861f58-dabf-429f-97ee-32591bdd3650';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ee861f58-dabf-429f-97ee-32591bdd3650'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ee861f58-dabf-429f-97ee-32591bdd3650'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
