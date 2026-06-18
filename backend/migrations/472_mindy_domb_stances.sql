-- ============================================================================
-- Migration 472: Mindy Domb Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Mindy Domb (MA State Rep, 3rd Hampshire District, HD-57).
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
-- Mindy Domb (HD-57, external_id=-210097)
-- UUID: ecafa801-15b3-4777-9c38-95f5ded5cbe6
-- District: 3rd Hampshire (Amherst area)
-- Democrat; committee: Mental Health, Substance Use and Recovery.
-- ============================================================================

-- ----- Mindy Domb / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Domb sponsored H.119, "An Act to address the impact of climate change on farms and fisheries," and H.560, "An Act implementing elementary and secondary interdisciplinary climate literacy education," mandating climate education in schools. These bills reflect both mitigation support and building long-term public understanding of climate change.$$,
        ARRAY['https://malegislature.gov/Bills/194/H119', 'https://malegislature.gov/Bills/194/H560']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mindy Domb / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Domb sponsored H.931, "An Act establishing the Blue Communities Program," which certifies municipalities committed to protecting public water resources; H.932, "An Act relative to the pesticide board," strengthening pesticide regulation; and H.933, "An Act relative to plastic bag reduction." These three bills together constitute a comprehensive local environmental protection agenda covering water, chemicals, and plastic waste.$$,
        ARRAY['https://malegislature.gov/Bills/194/H931', 'https://malegislature.gov/Bills/194/H932', 'https://malegislature.gov/Bills/194/H933']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mindy Domb / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Domb sponsored H.1137 controlling contagious disease; H.2399, "An Act to improve access to health care for people with Long COVID"; H.2205 expanding loan repayment for primary care physicians to address physician shortages; and H.1360, "An Act preventing discrimination against persons with disabilities in the provision of health care." Her Mental Health committee role further reflects commitment to behavioral health access.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2399', 'https://malegislature.gov/Bills/194/H1360', 'https://malegislature.gov/Bills/194/H2205']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mindy Domb / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Domb sponsored H.220, "An Act establishing a diaper benefits pilot program," providing diaper assistance to low-income families — a direct childcare affordability and child welfare measure. This bill addresses a basic but often overlooked aspect of early childhood care costs.$$,
        ARRAY['https://malegislature.gov/Bills/194/H220']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mindy Domb / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Domb sponsored H.1360, "An Act preventing discrimination against persons with disabilities in the provision of health care," expanding anti-discrimination protections in healthcare settings. She also sponsored H.2401, "An Act providing for safe and consensual sensitive examinations," protecting patients' rights during medical exams. These bills reflect a consistent pattern of expanding civil rights protections for vulnerable groups.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1360', 'https://malegislature.gov/Bills/194/H2401']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mindy Domb / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecafa801-15b3-4777-9c38-95f5ded5cbe6',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Domb sponsored H.223, "An Act relative to a livable wage for human services workers," mandating wage increases for the human services sector; and H.1466, "An Act establishing the hunger free campus initiative," addressing food insecurity for college students. These bills reflect a labor-rights and economic security approach to economic development.$$,
        ARRAY['https://malegislature.gov/Bills/194/H223', 'https://malegislature.gov/Bills/194/H1466']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 6 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ecafa801-15b3-4777-9c38-95f5ded5cbe6';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ecafa801-15b3-4777-9c38-95f5ded5cbe6'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ecafa801-15b3-4777-9c38-95f5ded5cbe6'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
