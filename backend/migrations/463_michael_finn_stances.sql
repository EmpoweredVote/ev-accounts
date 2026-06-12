-- ============================================================================
-- Migration 463: Michael J. Finn Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael J. Finn (MA State Rep, 6th Hampden District, HD-48).
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
-- Michael J. Finn (HD-48, external_id=-210088)
-- UUID: 949b1930-0574-44f5-9389-efc75c654139
-- District: 6th Hampden (West Springfield area)
-- Democrat; committee: Bonding, Capital Expenditures and State Assets.
-- ============================================================================

-- ----- Michael J. Finn / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('949b1930-0574-44f5-9389-efc75c654139',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('949b1930-0574-44f5-9389-efc75c654139',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Finn sponsored H.232 "An Act relative to individuals with intellectual and developmental disabilities," H.235 "An Act establishing a bill of rights for children in foster care," and H.261 "An Act relative to supported decision-making agreements for certain adults" — a disability rights bill allowing adults with cognitive disabilities to designate support persons instead of requiring guardianship. He also sponsored H.233 establishing children's advocacy centers. These bills consistently expand civil rights protections for vulnerable populations.$$,
        ARRAY['https://malegislature.gov/Bills/194/H232', 'https://malegislature.gov/Bills/194/H235', 'https://malegislature.gov/Bills/194/H261']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Finn / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('949b1930-0574-44f5-9389-efc75c654139',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('949b1930-0574-44f5-9389-efc75c654139',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Finn sponsored H.1154, "An Act relative to insurance coverage of mobile integrated health," expanding insurance coverage for mobile health services — improving access especially in underserved areas. He also sponsored H.1155, "An Act empowering health care consumers," and H.364, "An Act relative to the collection of debt," protecting patients from aggressive medical debt collection. These bills consistently favor expanding healthcare access and consumer protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1154', 'https://malegislature.gov/Bills/194/H1155', 'https://malegislature.gov/Bills/194/H364']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Finn / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('949b1930-0574-44f5-9389-efc75c654139',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('949b1930-0574-44f5-9389-efc75c654139',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Finn sponsored H.1501, "An Act to improve municipal equity within the emergency assistance shelter program," which seeks to address inequities in how MA's emergency shelter system distributes funding and obligations across municipalities. This bill directly addresses homelessness response infrastructure and reflects a supportive, systems-improvement approach to emergency shelter.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1501']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Finn / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('949b1930-0574-44f5-9389-efc75c654139',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('949b1930-0574-44f5-9389-efc75c654139',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Finn sponsored H.2101, "An Act to enforce laws protecting worksite safety," which strengthens enforcement of occupational safety standards — a labor-rights approach to economic development. His committee on Bonding and Capital Expenditures is focused on state investment in infrastructure, consistent with a public-investment approach to economic development.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2101', 'https://malegislature.gov/Legislators/Profile/MJF1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 4 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '949b1930-0574-44f5-9389-efc75c654139';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '949b1930-0574-44f5-9389-efc75c654139'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '949b1930-0574-44f5-9389-efc75c654139'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
