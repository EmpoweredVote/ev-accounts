-- ============================================================================
-- Migration 450: Thomas J. Walsh Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Thomas J. Walsh (MA State Rep, HD-35,
--   12th Essex District, Peabody/Lynnfield/Saugus).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- NOTE: Walsh did not co-sponsor any of the progressive bills tracked by Act on Mass.
--   His legislative record reflects a moderate/centrist Democrat orientation with
--   focus on public safety, first responder support, and local matters.
--   Stances are limited to areas with specific bill evidence.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: ff2939e8-befb-4c16-ace7-9f677847088c (external_id=-210075)

BEGIN;

-- ----- Thomas J. Walsh / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff2939e8-befb-4c16-ace7-9f677847088c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff2939e8-befb-4c16-ace7-9f677847088c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Walsh sponsored H.1343 relative to direct primary care — a healthcare delivery model that allows patients to pay a flat monthly fee to physicians for comprehensive primary care, reducing administrative overhead and improving access. He also sponsored H.2045 relative to health care proxies (advance directives) and H.2727 relative to overdose fatalities, reflecting attention to addiction and harm reduction. These bills reflect incremental healthcare access improvements rather than universal coverage expansion.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1343', 'https://malegislature.gov/Bills/194/H2045', 'https://malegislature.gov/Bills/194/H2727']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas J. Walsh / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff2939e8-befb-4c16-ace7-9f677847088c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff2939e8-befb-4c16-ace7-9f677847088c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Walsh sponsored H.1574 establishing a first-time homebuyers bill of rights, which would provide legal protections and disclosure requirements for first-time homebuyers navigating the purchase process. He also sponsored H.1345 enhancing homebuyer awareness by providing notice to persons purchasing property near water/flood-prone areas, and H.1344 relative to homeowner's insurance. These bills reflect a focus on buyer protection and homeownership support rather than rental housing or broader affordability.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1574', 'https://malegislature.gov/Bills/194/H1345', 'https://malegislature.gov/Bills/194/H1344']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas J. Walsh / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff2939e8-befb-4c16-ace7-9f677847088c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff2939e8-befb-4c16-ace7-9f677847088c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Walsh sponsored H.4774 to establish a Cambridge employment and job training trust — a workforce development mechanism. He also sponsored H.2726 requiring human trafficking recognition training for certain hospitality workers, reflecting worker protection and labor safety concerns. His H.4622 (Freddy's law) on student athlete protection and his charter work reflect civic and workforce institutions focus for his district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H4774', 'https://malegislature.gov/Bills/194/H2726', 'https://malegislature.gov/Bills/194/H4622']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ff2939e8-befb-4c16-ace7-9f677847088c';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ff2939e8-befb-4c16-ace7-9f677847088c'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ff2939e8-befb-4c16-ace7-9f677847088c'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
