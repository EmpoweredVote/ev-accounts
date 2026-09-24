-- CA_0279_race_candidates_is_write_in.sql
--
-- Slot CA_0279 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Adds essentials.race_candidates.is_write_in: TRUE when the candidate is a registered WRITE-IN for
-- this race — standing, but not printed on the ballot. Ruling 2026-09-24 (Chris Andrews): registered
-- write-ins are seeded, and Essentials marks them, the way it marks Withdrawn and Unopposed.
--
-- WHY A BOOLEAN, NOT A candidate_status VALUE. candidate_status answers "are they still running"
-- (active / withdrawn / filed), and a write-in is still running — so is_live_candidate() must keep
-- returning true for them, and every liveness count keeps counting them. How a candidate reaches the
-- voter is a different axis. Folding it into candidate_status would make each of the eleven
-- is_live_candidate() call sites (mig 1582) and the two `= 'active'` sites decide about write-ins
-- by accident.
--
-- It is PER RACE, not per person: Arizona's 2026 primary had David Redkey and Gary Swing win as
-- write-ins, and both are PRINTED on the November ballot. A person can be a write-in in one race
-- and on the ballot in the next.
--
-- DEFAULT false is the honest reading of every existing row: each was seeded from a ballot or
-- qualified-candidate list. No backfill. CA_0280 seeds the first write-ins (7 AZ House).
--
-- Deploy order: this column must exist before the API that selects it deploys (PR with this file).
--
-- IDEMPOTENT: ADD COLUMN IF NOT EXISTS; COMMENT is replace-in-place.
-- ROLLBACK: ALTER TABLE essentials.race_candidates DROP COLUMN is_write_in;  (revert the API first)

BEGIN;

ALTER TABLE essentials.race_candidates
  ADD COLUMN IF NOT EXISTS is_write_in boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN essentials.race_candidates.is_write_in IS
  'TRUE = a registered write-in candidate for this race: standing (is_live_candidate stays true), but not printed on the ballot. Per race, not per person. Essentials badges it "Write-in" and does not count it toward Unopposed. CA_0279.';

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'race_candidates' AND column_name = 'is_write_in'
     AND data_type = 'boolean' AND is_nullable = 'NO' AND column_default = 'false';
  IF n <> 1 THEN RAISE EXCEPTION 'POST: race_candidates.is_write_in missing or wrong shape'; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates WHERE is_write_in;
  IF n <> 0 AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE source LIKE '%CA_0280%') THEN
    RAISE EXCEPTION 'POST: % rows are write-ins before CA_0280 seeded any', n;
  END IF;

  RAISE NOTICE 'CA_0279 applied: race_candidates.is_write_in boolean NOT NULL DEFAULT false';
END $$;

COMMIT;
