-- CC_0337 — race_candidates.result_certainty: is a recorded result CALLED or CERTIFIED?
--
-- WHY. The 2026-11-03 general moved an unknown number of seats and we record zero results for
-- it. Working those 2,159 races means seating winners before their results are certified: the
-- California canvass runs up to 30 days, and ~173 California local seats are sworn in during
-- December, so those seats take office BEFORE their result is official. The read path must be
-- able to say which of the two a row is.
--
-- `result_source` already exists and is already mandatory alongside any result
-- (race_candidates_result_needs_source, migration 1574). It is free text. Recovering
-- "called vs certified" by matching strings inside it would make a predicate read the SHAPE of
-- a value to recover a FACT, which is the failure this repo has a standing rule against. So the
-- distinction gets a real column.
--
-- WHAT "CALLED" MEANS HERE. We hold no AP contract — there is no AP client, endpoint or
-- credential anywhere in this repo, and the feed is paid. Both stages therefore come from the
-- state itself at two different moments:
--     called     the state's unofficial / election-night returns. Enough to name a winner;
--                totals may still move.
--     certified  the state's official canvass. Final.
--
-- 🔴 PRE-STATE, MEASURED AGAINST PRODUCTION 2026-11-04 BEFORE WRITING THIS FILE:
--
--     won_rows = 489 · any non-NULL result = 1917 · result_certainty column = DOES NOT EXIST
--
--   🔴 THE OVERWRITE RECORD THIS REPO REQUIRES: the backfill below sets result_certainty on
--   489 rows. The value it overwrites on every one of them is NULL — necessarily, because the
--   column does not exist until this migration creates it. There is no prior value to lose.
--
-- WHY THE BACKFILL IS TRUE AND NOT A CONVENIENCE. Those 489 `won` rows belong to elections that
-- have already happened and been canvassed; every one of them is certified by now. Writing
-- 'certified' states a fact about them. The alternative — adding the constraint NOT VALID and
-- leaving them unchecked — would leave a gate that does not cover the table it is on.
--
-- IDEMPOTENT: re-running adds nothing, backfills nothing, and re-asserts the same gate.

BEGIN;

ALTER TABLE essentials.race_candidates
  ADD COLUMN IF NOT EXISTS result_certainty text;

COMMENT ON COLUMN essentials.race_candidates.result_certainty IS
  'Provenance of `result`: ''called'' = the state''s unofficial/election-night returns; '
  '''certified'' = the state''s official canvass. Required whenever result = ''won'' '
  '(that row can seat an officeholder). NULL is forbidden with a NULL result. CC_0337.';

-- Backfill: every historical win is certified. Guarded, so a re-run is a no-op.
UPDATE essentials.race_candidates
   SET result_certainty = 'certified'
 WHERE result = 'won'
   AND result_certainty IS NULL;

ALTER TABLE essentials.race_candidates
  DROP CONSTRAINT IF EXISTS race_candidates_result_certainty_check;
ALTER TABLE essentials.race_candidates
  ADD CONSTRAINT race_candidates_result_certainty_check
  CHECK (result_certainty IS NULL OR result_certainty IN ('called', 'certified'));

-- No certainty without a result: certainty ABOUT WHAT?
ALTER TABLE essentials.race_candidates
  DROP CONSTRAINT IF EXISTS race_candidates_certainty_needs_result;
ALTER TABLE essentials.race_candidates
  ADD CONSTRAINT race_candidates_certainty_needs_result
  CHECK (result IS NOT NULL OR result_certainty IS NULL);

-- A win must say which it is. This is the gate the backfill exists to make satisfiable.
-- NOTE: deliberately NOT extended to 'lost'. A lost row may carry a certainty (Task 4 writes
-- losers from the same source as the winner) but is not REQUIRED to, because 387 historical
-- 'lost' rows predate this column and nothing downstream reads their provenance. Widening this
-- later is additive; narrowing it would not be.
ALTER TABLE essentials.race_candidates
  DROP CONSTRAINT IF EXISTS race_candidates_won_needs_certainty;
ALTER TABLE essentials.race_candidates
  ADD CONSTRAINT race_candidates_won_needs_certainty
  CHECK (result <> 'won' OR result_certainty IS NOT NULL);

-- Post-verify gate. Asserts the DELTA this file is responsible for, not a total somebody else
-- can move while this is being written.
DO $$
DECLARE
  v_won_without_certainty int;
  v_certified            int;
  v_bad_value            int;
BEGIN
  SELECT count(*) INTO v_won_without_certainty
    FROM essentials.race_candidates
   WHERE result = 'won' AND result_certainty IS NULL;

  SELECT count(*) INTO v_certified
    FROM essentials.race_candidates
   WHERE result = 'won' AND result_certainty = 'certified';

  SELECT count(*) INTO v_bad_value
    FROM essentials.race_candidates
   WHERE result_certainty IS NOT NULL
     AND result_certainty NOT IN ('called', 'certified');

  IF v_won_without_certainty <> 0 THEN
    RAISE EXCEPTION 'CC_0337: % won rows still carry no result_certainty', v_won_without_certainty;
  END IF;

  IF v_bad_value <> 0 THEN
    RAISE EXCEPTION 'CC_0337: % rows carry a result_certainty outside (called, certified)', v_bad_value;
  END IF;

  IF v_certified < 489 THEN
    RAISE EXCEPTION 'CC_0337: expected at least the 489 measured historical wins to be certified, found %',
                    v_certified;
  END IF;

  RAISE NOTICE 'CC_0337 OK: % won rows certified, 0 uncertain, 0 out-of-domain values',
               v_certified;
END $$;

COMMIT;
