-- Migration 1926 — withdraw 165 chairs whose own reasoning says the evidence cannot seat them.
--
-- WHAT THIS IS. Measured 2026-10-22:
-- `backend/data/stance-research/2026-10-22-repair-marker-remainder/MEASUREMENT.md`.
-- 165 voter-facing Season 2 rows carry this sentence, written by migration 1903 (the Texas cohort):
--
--   "⚠ WHAT THIS DOES AND DOES NOT SETTLE. The instrument places this member firmly on their side
--    of the ladder; IT DOES NOT BY ITSELF SEPARATE THE RUNGS WITHIN THAT SIDE, and the chair keeps
--    the placement THE ORIGINAL RESEARCH gave it. Registered as a ladder-reachability finding
--    rather than silently absorbed."
--
-- ⚖⚖ THIS IS NOT A SAMPLE AND NOT AN INFERENCE. It is a census of rows that state the defect in
-- their own published text, and it is dispositive against the standing bar:
--   "Evidence that establishes only the DIRECTION (pro/anti) under-determines which of the two or
--    three chairs on that side applies. Seating anyway is an unevidenced claim — the same defect
--    class as a composed citation, expressed as a number." (CLAUDE.md)
--
-- 🔴 AND NOTE WHAT THE CHAIR RESTS ON: "the placement the original research gave it." The original
-- research is the generic-profile-sourced research that this whole queue exists because it was
-- never evidenced. So the repair attached a REAL roll-call vote which proves the SIDE, left the
-- RUNG standing on the unevidenced guess, and the added citation made the row LOOK sourced. That is
-- the migration-1921 failure at 165 rows instead of 40, and it documents itself.
--
-- ⚖ WHAT A BLANK HERE ASSERTS, AND WHAT IT DOES NOT. It asserts that the row's own reasoning does
-- not support the rung it carries. It does NOT assert the person holds no view, and it does not
-- doubt the vote: every one of these rows cites a real, verified roll call, and those votes are
-- good evidence of the side. 🔑 THE EVIDENCE IS THEREFORE KEPT, NOT DISCARDED — the original
-- reasoning is PRESERVED VERBATIM beneath the withdrawal notice, and the sources are untouched, so
-- a re-read against the ladder starts from the record rather than from nothing. These rows are
-- candidates for re-seating, not write-offs.
--
-- ⚠ WHY NOT RE-SEAT THEM HERE INSTEAD. Re-seating 165 rows needs 165 reads against 15 ladders, each
-- deciding which rung a known vote supports. That is research, and it is not what a blanking pass
-- can honestly do in bulk — the exact error that produced these rows. A blank spoke is correct
-- until someone reads them.
--
-- SCOPE, AND WHY IT IS SAFE. The sentence appears in NO OTHER SEASON (measured: 0 rows outside
-- Season 2), so Season 1 cannot be touched by this predicate. All 165 were written by migration
-- 1903 and none has been rewritten by migrations 1920-1925. 165 rows is ~4.4% of the 3,718 seated
-- Season 2 rows. A blank writes 0, which SUPPRESSES (NULLIF(pa.value, 0)); the row and its
-- citations stay, so coverage rollups still count the research as having happened.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards below fail the whole transaction rather than write a partial result.

-- Freeze the target set ONCE, so the update, the count and the verification all speak about the
-- same rows. 🔴 A predicate re-evaluated after the UPDATE would match nothing and pass vacuously.
CREATE TEMP TABLE mig1926_targets AS
SELECT pc.politician_id, pc.topic_id, pa.value AS value_before, pc.reasoning AS reasoning_before
  FROM inform.politician_context pc
  JOIN inform.politician_answers pa
    ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.season_id = pc.season_id
 WHERE pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND pc.reasoning LIKE '%does not by itself separate the rungs%'
   AND pa.value > 0;

-- Record the before-picture for a delta check that does not depend on the predicate.
CREATE TEMP TABLE mig1926_before AS
SELECT count(*) AS seated_season2
  FROM inform.politician_answers
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;

-- GUARD 1 — the population is exactly what was measured. 🔴 This is the staleness gate: if another
-- session has worked these rows since 2026-10-22, the count moves and this migration refuses.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1926_targets;
  IF n <> 165 THEN
    RAISE EXCEPTION 'migration 1926: expected 165 target rows, found % — the population moved, re-measure', n;
  END IF;
  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1926_targets) s;
  IF n <> 165 THEN RAISE EXCEPTION 'migration 1926: duplicate (politician, topic) pairs; % distinct of 165', n; END IF;
  SELECT count(DISTINCT politician_id) INTO n FROM mig1926_targets;
  IF n <> 74 THEN RAISE EXCEPTION 'migration 1926: expected 74 people, found %', n; END IF;
  SELECT count(DISTINCT topic_id) INTO n FROM mig1926_targets;
  IF n <> 15 THEN RAISE EXCEPTION 'migration 1926: expected 15 topics, found %', n; END IF;
END $$;

-- GUARD 2 — every target really is a migration-1903 row that carries the marker, and none has been
-- rewritten by the 1920-1925 passes. Reading the shape of the text, not trusting the predicate.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1926_targets
   WHERE reasoning_before NOT LIKE '%migration 1903%'
      OR reasoning_before NOT LIKE '%THE CHAIR IS UNCHANGED%'
      OR reasoning_before LIKE '%migration 192%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1926: % target(s) are not untouched migration-1903 marker rows', n; END IF;
END $$;

-- GUARD 3 — 🔴 SEASON 1 IS CLOSED AND MUST BE UNREACHABLE BY THIS PREDICATE, not merely unvisited.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context pc
   WHERE pc.season_id <> '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pc.reasoning LIKE '%does not by itself separate the rungs%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1926: the target sentence appears in % row(s) outside Season 2 — the predicate is no longer season-safe', n;
  END IF;
END $$;

-- GUARD 4 — nothing may lose its citations, and every target must already have some.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1926_targets t
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
        AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND coalesce(cardinality(pc.sources), 0) > 0);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1926: % target(s) have no citations to carry forward', n; END IF;
END $$;

-- The answer: blank. value 0 suppresses the spoke; the row and its citations remain.
UPDATE inform.politician_answers pa
   SET value = 0, updated_at = now()
  FROM mig1926_targets t
 WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The record of WHY — and 🔑 THE ORIGINAL REASONING IS PRESERVED VERBATIM BENEATH IT. The roll call
-- is real and is good evidence of the side; throwing it away would make the re-read start from
-- nothing. Sources are deliberately not touched.
UPDATE inform.politician_context pc
   SET reasoning = 'INTERNAL RECORD - blanked by migration 1926: the chair does not stand on the evidence this row cites, and the row says so itself. Shape: DIRECTION ONLY, SELF-DECLARED - the cited instrument establishes which side of the ladder the person is on and cannot separate the rungs within that side, which the reasoning below states in its own words ("it does not by itself separate the rungs WITHIN that side, and the chair keeps the placement the original research gave it"). WHY THIS IS A DEFECT: the placement the original research gave it is the generic-profile-sourced research that was never evidenced, so the repair attached a real vote proving the SIDE, left the RUNG on the guess, and the new citation made the row look sourced. Evidence that establishes only a direction under-determines which chair on that side applies, and seating anyway is an unevidenced claim. 🔑 THE VOTE IS NOT DOUBTED AND THE EVIDENCE IS KEPT: the original reasoning follows verbatim and the sources are unchanged, so a re-read against the Season 2 ladder starts from the record. THIS ROW IS A CANDIDATE FOR RE-SEATING, NOT A WRITE-OFF. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show which rung they occupy. Measured in data/stance-research/2026-10-22-repair-marker-remainder/MEASUREMENT.md. ---- ORIGINAL REASONING, PRESERVED ---- '
                  || t.reasoning_before,
       updated_at = now()
  FROM mig1926_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- GUARD 5 — verify the RESULT, not the absence of an error.
DO $$
DECLARE n int; before_seated int; after_seated int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1926_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 0;
  IF n <> 165 THEN RAISE EXCEPTION 'migration 1926: expected 165 rows blanked, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1926_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1926: % row(s) lost their citations', n; END IF;

  -- A blank must say which kind of nothing it is.
  SELECT count(*) INTO n
    FROM mig1926_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE 'INTERNAL RECORD - blanked by migration 1926%'
      OR pc.reasoning NOT LIKE '%Shape:%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1926: % row(s) do not record what was done to them', n; END IF;

  -- 🔑 The promise this pass makes: the original reasoning survives on every row.
  SELECT count(*) INTO n
    FROM mig1926_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE '%---- ORIGINAL REASONING, PRESERVED ----%'
      OR position(t.reasoning_before in pc.reasoning) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1926: % row(s) lost their original reasoning', n; END IF;

  -- 🔴 BLAST RADIUS, measured as a delta rather than asserted: exactly 165 seated Season 2 rows
  -- fewer than before, so nothing outside the target set was blanked or seated.
  SELECT seated_season2 INTO before_seated FROM mig1926_before;
  SELECT count(*) INTO after_seated
    FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;
  IF before_seated - after_seated <> 165 THEN
    RAISE EXCEPTION 'migration 1926: seated Season 2 rows fell by % , expected exactly 165', before_seated - after_seated;
  END IF;

  -- No row carrying the sentence may still be seated: that is the defect this pass clears.
  SELECT count(*) INTO n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.season_id = pc.season_id
   WHERE pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pc.reasoning LIKE '%does not by itself separate the rungs%'
     AND pa.value > 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1926: % direction-only row(s) are still seated', n; END IF;

  -- Season 1 is closed and must not have moved.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
    JOIN mig1926_targets t ON t.politician_id = pa.politician_id AND t.topic_id = pa.topic_id
   WHERE pa.updated_at > now() - interval '5 minutes';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1926: % Season 1 answer(s) were modified — Season 1 is closed', n; END IF;

  RAISE NOTICE 'migration 1926: blanked 165 direction-only chairs; seated Season 2 % -> %', before_seated, after_seated;
END $$;

DROP TABLE mig1926_targets;
DROP TABLE mig1926_before;
