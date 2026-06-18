-- ============================================================================
-- Migration 443: Andrew F. Tarr Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Andrew F. Tarr (MA State Rep, HD-28,
--   5th Essex District — Essex, Rockport, Manchester-by-the-Sea, Gloucester).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- NOTE: Andrew F. Tarr is a newer House representative (Democrat) with no
-- sponsored bills and no committee assignments recorded in the 194th General Court
-- as of 2026-06-12. No AOM tracker page found. Blank spokes intentional per D-01.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 31aca73c-2006-49d2-901c-89ee2a13acb5 (external_id=-210068)

-- No evidence found for any active compass topic — blank spokes intentional per D-01.
-- Sources checked: malegislature.gov/Legislators/Profile/AFT1, actonmass.org (not found),
--   ballotpedia.org (not found). No sponsored bills or committee assignments in 194th General Court.

BEGIN;
COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (0 expected — no evidence found):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '31aca73c-2006-49d2-901c-89ee2a13acb5';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '31aca73c-2006-49d2-901c-89ee2a13acb5'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '31aca73c-2006-49d2-901c-89ee2a13acb5'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
