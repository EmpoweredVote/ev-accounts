BEGIN;

-- =============================================================================
-- CC_0057: a blank is value 0 — the schema learns to say "no position"
-- =============================================================================
-- Created 2026-09-03 with Chris Cantrell. Step 4 of the Season 2 read audit, and
-- the last thing standing between the audit and the re-pointing it exists for.
--
-- THE PROBLEM, CONCRETELY. Chris Andrews' Season 2 Same-Sex Marriage ladder
-- inserts a new rung 1 and shifts the rest, and its rung_map is
-- {1:2, 2:3, 3:"invalidated", 4:4, 5:5}. Old rung 3 was "let each state decide"
-- — a FEDERALISM position. The new ladder measures only degree of recognition
-- and has no states-rights rung, so 28 politicians have genuinely nowhere to sit.
-- Mapping them to new rung 3 would assert a religious-exemption view they never
-- stated; deleting their Season 1 row would edit history.
--
-- CHRIS RULED 2026-09-02: "If there is nowhere for the 28 to go, they can be
-- blanked. We will remember the difference between seasons 1 and 2." Season 1
-- keeps their rung-3 answer as the historical record; Season 2 shows a blank.
--
-- AND THE BLANK HALF WAS NOT EXPRESSIBLE. politician_answers.value is
-- CHECK (value IN (1,2,3,4,5)) and the table has no deleted_at. There was no way
-- to store "researched, and no rung states what they hold" — which is a distinct
-- fact from an absent row (never researched) and from a deleted row (which, with
-- seasons, does not blank anyone: the read falls back to Season 1).
--
-- WHY value 0 RATHER THAN A deleted_at COLUMN. Someone already built for it and
-- never finished: `value != 0` filters were sitting in the read path, dead code
-- under a CHECK that made 0 impossible. The Season 2 audit found them in
-- getPoliticianAnswers, getCandidateAnswers, getBatchPoliticianAnswers,
-- getCompassPoliticians and getCandidates. A tombstone column would have needed
-- a brand-new filter at every one of those sites instead.
--
-- 🔴 THE READS WERE FIXED FIRST, ON PURPOSE. This migration is deliberately the
-- LAST step, not the first. Landing it before the reads were guarded would have
-- armed a loaded gun: PR #350 guards the five reads that would otherwise have
-- taken a 0 as rung 0 — the alignment score, both stats queries, the admin
-- composition grid and the citation blocks — and PR #354 records the seven that
-- deliberately keep counting blanks. Nothing may write a zero until those land.
--
-- ⚠ THIS MIGRATION WRITES NO ZEROS. It only makes them possible. The 28 are
-- blanked by the re-pointing migration, which is a separate change and a
-- separate review.

-- -----------------------------------------------------------------------------
-- 1. Widen the value domain to include the blank
-- -----------------------------------------------------------------------------
-- Strictly wider than the constraint it replaces, so every existing row already
-- satisfies it and the validation scan cannot fail. Half steps stay illegal here
-- — CC_0002 §5 made them the CITIZEN signal, legal on compass_responses and
-- never on a politician — and this does not reopen that.
ALTER TABLE inform.politician_answers
  DROP CONSTRAINT IF EXISTS politician_answers_value_whole_1_to_5;

ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_value_whole_0_to_5
  CHECK (value IN (0, 1, 2, 3, 4, 5));

-- -----------------------------------------------------------------------------
-- 2. A blank is the absence of a position; a write-in is one
-- -----------------------------------------------------------------------------
-- These two cannot both be true of the same row. A write-in is a politician
-- saying something the ladder does not offer — which is a POSITION, recorded
-- between the rungs. A blank says there is no position to record. Storing both
-- would leave a row that reads as blank everywhere the value is consulted while
-- carrying prose that says otherwise, and the prose is voter-facing.
--
-- Prod holds 0 write-ins today, so this validates trivially now. That is exactly
-- why it goes in now: the first write-in is the wrong time to discover the
-- question was never settled.
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_blank_has_no_write_in
  CHECK (value <> 0 OR write_in_text IS NULL);

-- -----------------------------------------------------------------------------
-- 3. Prove it, then throw the proof away
-- -----------------------------------------------------------------------------
-- Same shape as CC_0044's probe. A constraint that was not exercised is a
-- constraint nobody has seen work — and the failure mode here is silent in the
-- worst direction: if the widening did not take, the re-pointing migration fails
-- 2,685 rows in, halfway through a season changeover.
--
-- Every write below is rolled back by a deliberate exception before COMMIT.
DO $$
DECLARE
  v_pol    uuid;
  v_topic  uuid;
  v_season uuid;
  v_zero_accepted   boolean := false;
  v_six_blocked     boolean := false;
  v_half_blocked    boolean := false;
  v_writein_blocked boolean := false;
BEGIN
  -- An OPEN season: the closed-season immutability trigger (CC_0044) would
  -- refuse the probe on a closed one, and would be right to.
  SELECT a.politician_id, a.topic_id, a.season_id
    INTO v_pol, v_topic, v_season
    FROM inform.politician_answers a
    JOIN inform.seasons s ON s.id = a.season_id AND s.status = 'open'
   LIMIT 1;

  IF v_pol IS NULL THEN
    RAISE EXCEPTION 'CC_0057: no answer row in an open season to probe against — cannot verify the constraint';
  END IF;

  BEGIN
    -- The thing this migration exists for.
    UPDATE inform.politician_answers SET value = 0
     WHERE politician_id = v_pol AND topic_id = v_topic AND season_id = v_season;
    v_zero_accepted := true;

    -- Widening must not have become "anything goes". Each expected failure gets
    -- its own subtransaction so its rollback does not undo the zero above.
    BEGIN
      UPDATE inform.politician_answers SET value = 6
       WHERE politician_id = v_pol AND topic_id = v_topic AND season_id = v_season;
    EXCEPTION WHEN check_violation THEN v_six_blocked := true;
    END;

    BEGIN
      UPDATE inform.politician_answers SET value = 2.5
       WHERE politician_id = v_pol AND topic_id = v_topic AND season_id = v_season;
    EXCEPTION WHEN check_violation THEN v_half_blocked := true;
    END;

    -- A blank carrying a write-in.
    BEGIN
      UPDATE inform.politician_answers SET value = 0, write_in_text = 'a position'
       WHERE politician_id = v_pol AND topic_id = v_topic AND season_id = v_season;
    EXCEPTION WHEN check_violation THEN v_writein_blocked := true;
    END;

    RAISE EXCEPTION 'CC_0057_ROLLBACK_PROBE';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM <> 'CC_0057_ROLLBACK_PROBE' THEN RAISE; END IF;
  END;

  IF NOT v_zero_accepted THEN
    RAISE EXCEPTION 'CC_0057: value 0 was REFUSED — the blank is still inexpressible and the re-pointing would fail mid-flight';
  END IF;
  IF NOT v_six_blocked THEN
    RAISE EXCEPTION 'CC_0057: value 6 was ACCEPTED — the widening removed the range instead of extending it';
  END IF;
  IF NOT v_half_blocked THEN
    RAISE EXCEPTION 'CC_0057: value 2.5 was ACCEPTED — half steps are the citizen signal and must stay illegal here (CC_0002 §5)';
  END IF;
  IF NOT v_writein_blocked THEN
    RAISE EXCEPTION 'CC_0057: a blank carrying a write-in was ACCEPTED — a row cannot both hold no position and state one';
  END IF;

  RAISE NOTICE 'CC_0057 OK: 0 accepted; 6, 2.5 and blank-with-write-in all refused. No rows changed.';
END $$;

-- -----------------------------------------------------------------------------
-- 4. Nothing was written
-- -----------------------------------------------------------------------------
-- The probe rolls itself back, but "the probe rolled back" and "no zeros exist"
-- are different claims and only the second one matters. Assert the second.
DO $$
DECLARE v_zeros int;
BEGIN
  SELECT count(*) INTO v_zeros FROM inform.politician_answers WHERE value = 0;
  IF v_zeros <> 0 THEN
    RAISE EXCEPTION 'CC_0057: % row(s) hold value 0 — this migration writes none, so the probe leaked', v_zeros;
  END IF;
  RAISE NOTICE 'CC_0057: 0 blanked answers, as expected — this migration only makes them possible.';
END $$;

COMMIT;
