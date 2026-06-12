-- ============================================================================
-- Migration 467: Carlos González Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Carlos González (MA State Rep, 10th Hampden District, HD-52).
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
-- Carlos González (HD-52, external_id=-210092)
-- UUID: 64e0eeb2-c83a-4da4-b6a2-2047b1e25cab
-- District: 10th Hampden (Springfield area)
-- Democrat; committees: Ethics, Rules, Operations.
-- ============================================================================

-- ----- Carlos González / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$González co-sponsored H.431, "An Act to end housing discrimination in the Commonwealth," targeting real estate discrimination. He sponsored H.485, "An Act relative to state grants targeting minority communities," and H.1727, "An Act relative to increasing racial diversity among judges in Massachusetts." He also sponsored H.1729, "An Act relative to abuse prevention." These bills reflect a strong civil rights agenda across housing, judicial representation, and community equity.$$,
        ARRAY['https://malegislature.gov/Bills/194/H431', 'https://malegislature.gov/Bills/194/H1727', 'https://malegislature.gov/Bills/194/H485']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carlos González / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$González sponsored H.1178, "An Act to improve outcomes for persons with limb loss and limb difference," expanding prosthetics coverage and care access, and H.1179, "An Act increasing access to universal dental care," which would expand dental care coverage to all Massachusetts residents. These bills reflect a pro-expansion, pro-universal-coverage approach to healthcare access.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1178', 'https://malegislature.gov/Bills/194/H1179']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carlos González / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$González sponsored H.1511, "An Act establishing the Massachusetts rental assistance and financial stability program," creating a state-funded rental assistance program; H.1510, "An Act relative to provide tenant ownership in government assisted housing," expanding tenant property rights; H.1730, "An Act establishing a foreclosure review division," protecting homeowners from improper foreclosure; and co-sponsored H.431 ending housing discrimination. This is among the most comprehensive housing-justice legislative records in this batch.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1511', 'https://malegislature.gov/Bills/194/H1510', 'https://malegislature.gov/Bills/194/H1730']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carlos González / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$González sponsored H.1511, establishing a statewide rental assistance and financial stability program, and H.1510, providing tenant ownership rights in government-assisted housing. Together these bills directly protect renters and expand tenant rights, placing him firmly on the pro-tenant side of rent regulation and tenant protection policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1511', 'https://malegislature.gov/Bills/194/H1510']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carlos González / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$González sponsored H.300, "An Act improving micro business and small business representation," expanding economic opportunities for small businesses in gateway cities like Springfield. He also sponsored H.485, "An Act relative to state grants targeting minority communities," and H.1177, "An Act relative to community reinvestment goals for banks," requiring banks to invest in underserved communities. These bills favor equitable, community-centered economic development.$$,
        ARRAY['https://malegislature.gov/Bills/194/H300', 'https://malegislature.gov/Bills/194/H1177', 'https://malegislature.gov/Bills/194/H485']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 5 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '64e0eeb2-c83a-4da4-b6a2-2047b1e25cab';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '64e0eeb2-c83a-4da4-b6a2-2047b1e25cab'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '64e0eeb2-c83a-4da4-b6a2-2047b1e25cab'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
