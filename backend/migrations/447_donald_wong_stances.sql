-- ============================================================================
-- Migration 447: Donald H. Wong Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Donald H. Wong (MA State Rep, HD-32,
--   9th Essex District, Saugus). Republican.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- NOTE: Wong is a Republican with minimal sponsored legislation (1 local retirement
-- bill) and did not co-sponsor any of the progressive bills tracked by Act on Mass.
-- Without specific bill sponsorship, vote record, or statements for any compass topic,
-- no stances can be inserted per evidence-only rule (D-01). Blank spokes intentional.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 44ca0b25-e4b9-4409-8407-f5119568be3e (external_id=-210072)

-- No evidence found for any active compass topic — blank spokes intentional per D-01.
-- Sources checked: malegislature.gov/Legislators/Profile/DHW1, actonmass.org,
--   ballotpedia.org. Only 1 sponsored bill (local retirement matter). No co-sponsorships
--   on tracked progressive bills. Republican party but no evidence of specific positions
--   on compass topics from bills, votes, or public statements.

BEGIN;
COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (0 expected — no evidence found):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '44ca0b25-e4b9-4409-8407-f5119568be3e';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '44ca0b25-e4b9-4409-8407-f5119568be3e'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '44ca0b25-e4b9-4409-8407-f5119568be3e'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
