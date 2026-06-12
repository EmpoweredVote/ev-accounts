-- ============================================================================
-- Migration 460: Nicholas A. Boldyga Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Nicholas A. Boldyga (MA State Rep, 3rd Hampden District, HD-45).
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
-- Nicholas A. Boldyga (HD-45, external_id=-210085)
-- UUID: 541efc37-b332-4c80-8264-7b655efed5ac
-- District: 3rd Hampden (Southwick/Granville area)
-- Republican; committees: Revenue, Agriculture, Aging.
-- ============================================================================

-- ----- Nicholas A. Boldyga / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Boldyga sponsored H.2573, "An Act to enhance public safety," which explicitly requires mandatory cooperation by local and state law enforcement with U.S. Immigration and Customs Enforcement (ICE). This bill is the direct legislative opposite of the Safe Communities Act, placing him at the maximum-cooperation end of the local-immigration axis — full cooperation with federal immigration enforcement.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2573']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholas A. Boldyga / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Boldyga sponsored H.2573 requiring mandatory ICE cooperation by Massachusetts law enforcement — a strict enforcement position on immigration. This bill directly supports federal deportation enforcement through local cooperation, placing him at the strict-enforcement end of immigration policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2573']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholas A. Boldyga / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Boldyga sponsored H.2376, "An Act to protect medical freedom," which opposes mandating or compelling individuals to undergo medical procedures including vaccination — a market-choice approach to healthcare that limits government health mandates. He also sponsored H.1352, a prescription drug rebate program for seniors, and H.2377-2378 improving patient access to prescriptions and health services. His approach prioritizes individual choice over state mandates.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2376', 'https://malegislature.gov/Bills/194/H1352', 'https://malegislature.gov/Bills/194/H2377']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholas A. Boldyga / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Boldyga sponsored H.3033, "An Act relative to the fuel tax," addressing gasoline and diesel tax rates, and H.3034, "An Act establishing a farm fuel tax rebate" — both targeting fuel tax reduction. His committee role on Joint Committee on Revenue further supports a tax-reduction orientation. These bills consistently reflect an anti-tax approach on the revenue side.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3033', 'https://malegislature.gov/Bills/194/H3034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholas A. Boldyga / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Boldyga sponsored H.3033, legislation addressing the gasoline and diesel fuel tax, and H.3034, a farm fuel tax rebate — both supporting continued use of fossil fuels by reducing their cost burden. His agriculture committee role in a rural district further aligns with support for fuel-intensive farming. These positions consistently favor maintaining fossil fuel access over energy transition.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3033', 'https://malegislature.gov/Bills/194/H3034']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nicholas A. Boldyga / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('541efc37-b332-4c80-8264-7b655efed5ac',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Boldyga sponsored H.114, "An Act to promote economic opportunities for cottage food entrepreneurs," which deregulates small-scale food producers to spur entrepreneurship. He also sponsored H.3891, "An Act enhancing legislative oversight of regulatory actions in Massachusetts," targeting excessive regulation. These bills reflect a pro-deregulation, small-business-first economic development approach.$$,
        ARRAY['https://malegislature.gov/Bills/194/H114', 'https://malegislature.gov/Bills/194/H3891']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 6 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '541efc37-b332-4c80-8264-7b655efed5ac';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '541efc37-b332-4c80-8264-7b655efed5ac'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '541efc37-b332-4c80-8264-7b655efed5ac'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
