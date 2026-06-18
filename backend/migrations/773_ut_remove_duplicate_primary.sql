-- Migration 773: remove the duplicate UT primary election 'UT 2026 Primary' (id 585f588b)
--
-- Background: two UT primary elections exist for 2026-06-23:
--   • '2026 Utah Primary' (id 02dee6b2) — CANONICAL. Populated by the discovery pipeline; races
--      carry office_id so they geofence-match ("Part A"). Keep this one.
--   • 'UT 2026 Primary'  (id 585f588b) — DUPLICATE created by migration 267. Its races have
--      office_id = NULL, so they fall to the statewide "Part B" fallback and were served to ALL
--      Utah addresses — i.e. Utah voters saw duplicate races. Remove it.
--
-- Apply AFTER migration 772 (which links the canonical election's candidates).
-- Pre-check (2026-06-18): 0 candidate_staging refs, 0 meetings refs for this election.
--   Cascade removes its 138 races and 171 race_candidates (FKs are ON DELETE CASCADE).
--   Politician records are NOT deleted (FK is race_candidate -> politician).
-- Backup before delete: backend/migrations/_backup_ut_duplicate_election_585f588b/*.csv
--
-- Idempotent: matches by id + name; no-op if already removed.
-- NOTE: already applied to production 2026-06-18 (recorded here for history).

BEGIN;

DELETE FROM essentials.elections
WHERE id = '585f588b-cc9c-4a42-b7bf-695a02e1d792'
  AND name = 'UT 2026 Primary';

DO $$
DECLARE v_remaining int;
BEGIN
  SELECT count(*) INTO v_remaining FROM essentials.elections WHERE state = 'UT' AND election_date = '2026-06-23';
  RAISE NOTICE 'UT 2026-06-23 elections remaining: % (expect 1)', v_remaining;
END $$;

COMMIT;
