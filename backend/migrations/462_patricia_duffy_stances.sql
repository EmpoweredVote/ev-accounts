-- ============================================================================
-- Migration 462: Patricia A. Duffy Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Patricia A. Duffy (MA State Rep, 5th Hampden District, HD-47).
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
-- Patricia A. Duffy (HD-47, external_id=-210087)
-- UUID: 4a0609a0-7073-4de1-9bf8-b3ecaebc9638
-- District: 5th Hampden (Holyoke area)
-- Democrat; committees: Cannabis Policy, Ways and Means, Veterans Affairs.
-- ============================================================================

-- ----- Patricia A. Duffy / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Duffy co-sponsored H.938, "An Act establishing sustainable and equitable funding for climate change adaptation and mitigation," which creates dedicated funding streams for climate resilience programs. She also sponsored H.3325, "An Act to create the buy clean Massachusetts program," which requires state procurement to account for embodied carbon and lifecycle emissions — a direct climate policy measure.$$,
        ARRAY['https://malegislature.gov/Bills/194/H938', 'https://malegislature.gov/Bills/194/H3325']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia A. Duffy / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Duffy sponsored H.121, "An Act relative to urban farmland," protecting urban agricultural land in Holyoke and similar cities. She co-sponsored H.120, "An Act supporting the Commonwealth's food system," and H.565, "An Act establishing the Massachusetts farm to school program." These bills together reflect consistent support for local food systems, urban green space, and sustainable land use practices.$$,
        ARRAY['https://malegislature.gov/Bills/194/H121', 'https://malegislature.gov/Bills/194/H120', 'https://malegislature.gov/Bills/194/H565']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia A. Duffy / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Duffy sponsored three healthcare bills: H.1147 requiring adequate reimbursements for public health dental hygienists to sustain community dental care; H.1361 addressing healthcare cost benchmarks through rate review to increase affordability; and H.2410, "An Act to improve oral health for all Massachusetts residents." This pattern of dental and healthcare access legislation reflects a pro-coverage, pro-access stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1147', 'https://malegislature.gov/Bills/194/H1361', 'https://malegislature.gov/Bills/194/H2410']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia A. Duffy / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Duffy sponsored H.1679, "An Act to protect survivors of spousal abuse from alimony liability," shielding domestic abuse survivors from continued financial obligations to abusers. She also sponsored H.1429, "An Act promoting an adjunct bill of rights," establishing workplace rights for adjunct faculty — a labor and civil rights measure. Both bills reflect a pattern of protecting vulnerable populations through civil rights legislation.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1679', 'https://malegislature.gov/Bills/194/H1429']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patricia A. Duffy / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a0609a0-7073-4de1-9bf8-b3ecaebc9638',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Duffy sponsored H.3838, "An Act to support veteran-owned businesses," which provides economic support and contracting preferences for veterans as entrepreneurs. She also sponsored H.565, a farm-to-school program, and H.120, supporting the Commonwealth's food system — all reflecting a community-investment, labor-friendly approach to economic development prioritizing underserved groups.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3838', 'https://malegislature.gov/Bills/194/H565']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 5 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '4a0609a0-7073-4de1-9bf8-b3ecaebc9638';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '4a0609a0-7073-4de1-9bf8-b3ecaebc9638'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '4a0609a0-7073-4de1-9bf8-b3ecaebc9638'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
