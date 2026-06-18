-- ============================================================================
-- Migration 439: Dawne Shand Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Dawne Shand (MA State Rep, HD-24,
--   1st Essex District, Newburyport).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 8ee72aa5-b7a0-422f-817d-a330f29dd2b1 (external_id=-210064)

BEGIN;

-- ----- Dawne Shand / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Shand sponsored H.1991, "An Act relative to further regulating access to abortion care," in the 194th General Court — a bill that would strengthen protections and expand access to abortion services in Massachusetts. This is primary sponsorship of an abortion access expansion bill, reflecting a strong pro-reproductive-rights position.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1991', 'https://malegislature.gov/Legislators/Profile/D_S1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawne Shand / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Shand sponsored H.1050 to assess current and future flood risk to property statewide, H.1051 for a special commission on voluntary acquisition of flood risk properties, H.1052 relative to wetlands restoration, and H.1053 to create a Merrimack River Collaborative to monitor and improve water quality. This suite of environmental bills focused on her coastal Newburyport district demonstrates a strong local environmental protection stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1050', 'https://malegislature.gov/Bills/194/H1051', 'https://malegislature.gov/Bills/194/H1052', 'https://malegislature.gov/Bills/194/H1053']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawne Shand / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Shand co-sponsored the Healthy Youth Act (LGBTQ+ inclusive sex education) as tracked by Act on Mass, and sponsored H.3398 to promote diversity on public boards and commissions. She also co-sponsored the THRIVE Act (Act on Mass), which addresses social services equity. These bills reflect a consistent civil rights and equity focus in her legislative priorities.$$,
        ARRAY['https://actonmass.org/legislators/dawne-shand/', 'https://malegislature.gov/Bills/194/H3398']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawne Shand / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Shand co-sponsored Campaign Childcare legislation as tracked by Act on Mass, which supports affordable childcare access. She also serves on the Joint Committee on Children, Families and Persons with Disabilities, reflecting a committee-level focus on child welfare and family support services.$$,
        ARRAY['https://actonmass.org/legislators/dawne-shand/', 'https://malegislature.gov/Legislators/Profile/D_S1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dawne Shand / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Shand co-sponsored the THRIVE Act (Act on Mass), which supports expanded social and healthcare services. She also serves on the Joint Committee on Children, Families and Persons with Disabilities and the Joint Committee on Consumer Protection and Professional Licensure, committees that oversee health-related regulatory issues. Her co-sponsorship of healthcare-adjacent bills reflects support for expanded public health services.$$,
        ARRAY['https://actonmass.org/legislators/dawne-shand/', 'https://malegislature.gov/Legislators/Profile/D_S1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8ee72aa5-b7a0-422f-817d-a330f29dd2b1';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '8ee72aa5-b7a0-422f-817d-a330f29dd2b1'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '8ee72aa5-b7a0-422f-817d-a330f29dd2b1'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
