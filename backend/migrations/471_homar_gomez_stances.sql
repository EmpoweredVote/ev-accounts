-- ============================================================================
-- Migration 471: Homar Gómez Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Homar Gómez (MA State Rep, 2nd Hampshire District, HD-56).
--          Note: Accented name in DB; file uses ASCII filename per plan spec.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics): See migration 456 for full reference block.

BEGIN;

-- ============================================================================
-- Homar Gómez (HD-56, external_id=-210096)
-- UUID: 3ea88aee-8bc7-4ddf-b897-5aa8111fadc8
-- District: 2nd Hampshire (Easthampton area)
-- Democrat; committees: Agriculture, Public Safety and Homeland Security, Revenue.
-- ============================================================================

-- ----- Homar Gómez / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Gómez sponsored H.1557, "An Act creating an office of tenant protections," which would establish a dedicated state office to enforce tenant rights, investigate landlord violations, and provide resources for renters facing eviction or harassment. This is a direct pro-tenant, pro-rent regulation measure creating institutional infrastructure for tenant protection.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1557']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Homar Gómez / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Gómez sponsored H.587, "An Act to require mandatory training on microaggressions and implicit bias for staff members teaching extracurricular activities," which mandates anti-bias training to address systemic discrimination in school programs. This bill targets racial and identity-based bias in educational settings as a civil rights matter.$$,
        ARRAY['https://malegislature.gov/Bills/194/H587']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Homar Gómez / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Gómez sponsored H.1725, "An Act to ban the release of balloons," which prohibits helium balloon releases to reduce plastic and latex pollution in the environment. He also serves on the Joint Committee on Agriculture and Fisheries, connecting to natural resource stewardship. These positions reflect active support for local environmental protection measures.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1725', 'https://malegislature.gov/Legislators/Profile/H_G1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Homar Gómez / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Gómez sponsored H.2435, "An Act relative to APOL1 mediated kidney disease," expanding research and care access for genetic kidney disease disproportionately affecting people of African descent; H.1174, "An Act to create direct dental care agreements," improving dental care access; and H.3498, "An Act to expand the low income home energy assistance program" (LIHEAP), directly supporting low-income healthcare-adjacent needs. These bills consistently favor expanding healthcare access.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2435', 'https://malegislature.gov/Bills/194/H1174', 'https://malegislature.gov/Bills/194/H3498']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Homar Gómez / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3ea88aee-8bc7-4ddf-b897-5aa8111fadc8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Gómez sponsored H.3670, "An Act relative to dangerous high speed pursuits," which restricts or regulates high-speed police chases to reduce traffic fatalities and civilian risk — a police accountability and safety reform measure. He also serves on the Joint Committee on Public Safety and Homeland Security. These positions indicate a reform-oriented approach that emphasizes limiting certain enforcement practices for community safety.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3670', 'https://malegislature.gov/Legislators/Profile/H_G1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 5 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '3ea88aee-8bc7-4ddf-b897-5aa8111fadc8';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '3ea88aee-8bc7-4ddf-b897-5aa8111fadc8'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '3ea88aee-8bc7-4ddf-b897-5aa8111fadc8'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
