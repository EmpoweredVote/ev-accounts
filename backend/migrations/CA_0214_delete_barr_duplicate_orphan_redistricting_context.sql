-- CA_0214_delete_barr_duplicate_orphan_redistricting_context.sql
--
-- Deletes the single inform.politician_context row that check-stance-sources.mjs's ORPHAN_CONTEXT
-- predicate still flags after CA_0204 (#682, #688):
--
--     politician_id d6d297f5-5319-4be1-b938-6bcce63368e7 (Andy Barr's deactivated
--       "Candidate for U.S. Senate — Kentucky" duplicate; is_active=false, no seat, no race)
--     topic_id      48cc9585-ec22-4f53-8d42-6839828dd36f (State Redistricting and Gerrymandering)
--     season_id     2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3 (Season 1, closed)
--
-- PREDATES CA_0204 AND WAS NOT TOUCHED BY IT. created_at/updated_at on this row is 2026-08-26,
-- three weeks before CA_0204 (2026-09-23), and CA_0204's own migration text (line 48) says
-- inform.politician_answers / inform.politician_context were deliberately left alone on both
-- duplicates because Season 1 is closed. CA_0204 only moved the row from the 'ky' state bucket to
-- the stateless '-' bucket (it lost its office/race state when the duplicate's office_terms and
-- race_candidates rows were moved to the seated House row), which is what PR #688 rebucketed in the
-- baseline without touching the underlying data. That baseline entry (ORPHAN_CONTEXT."-": 1) is
-- removed below in the same commit, since this migration removes the row it was standing in for.
--
-- WHY DELETE AND NOT REWRITE AS A DOCUMENTED BLANK. The reasoning is not an unanswered lookup -- it
-- cites a real vote (Barr against the For the People Act of 2019) and describes a real position.
-- Rewriting it to a "no record found" sentence to satisfy the gate would assert an absence that was
-- never true. But the row's subject is a decommissioned duplicate: a "Candidate for U.S. Senate"
-- identity that never became Barr's actual seat and that CA_0204 folded away, keeping it only as
-- inert history. Season 1 is closed and this politician_id holds no office and seeks no race, so no
-- answer can ever legitimately be written for this pair -- there is no chair this reasoning could be
-- seated in. Deleting is the same disposition the answer-delete-context guard template calls
-- "the question does not apply to these people": remove the context rather than assert a false blank.
--
-- SCOPE CHECK (done alongside this migration, not repeated here): the only other politician_context
-- rows on this duplicate with no matching answer are Medicare/Medicaid and Misinformation, and both
-- already read as documented blanks ("No public record found establishing a position on...") --
-- check-stance-sources.mjs's own carve-out regex excludes them, so they are not ORPHAN_CONTEXT and
-- are left untouched. Seth Moulton's duplicate (5ccb1f15-f285-470c-b86a-97f9e6b22dff) has zero
-- politician_context rows without a matching answer in any season. Neither duplicate needs further
-- cleanup of this class.
--
-- 🔴 THIS FILE EDITS A CLOSED SEASON, WITH THE OVERRIDE THE TRIGGER ASKS FOR.
-- inform.closed_season_is_immutable() (CC_0044) blocks every write to a Season 1 politician_context
-- row unless the migration sets inform.allow_closed_season_write = 'on' and states why. CC_0044's own
-- header is explicit that the hatch "is not for re-audits" -- a re-audit belongs in the OPEN season as
-- a new row that shadows the old one. This is not a re-audit: nothing about Barr's redistricting
-- position is being corrected, disputed, or re-researched. The row being removed belongs to a
-- politician_id that CA_0204 already decommissioned -- deactivated, seatless, holding no race -- and
-- there is no "current position" to shadow forward into Season 2 for an identity that no longer
-- represents an active candidacy. This is the "genuine need for surgery" case CC_0044's own comment
-- anticipates: dead metadata on a retired duplicate, not a position change. No value, answer, or
-- context on the SEATED Barr row (164fb70e-b8c1-48cd-a6ef-12d80165c67d) is touched. The override is
-- set with SET LOCAL, so it ends with this transaction.
--
-- Idempotent: a re-run deletes 0.

BEGIN;

CREATE TEMP TABLE ca0214_target ON COMMIT DROP AS
SELECT politician_id, topic_id, season_id, reasoning, sources
FROM inform.politician_context
WHERE politician_id = 'd6d297f5-5319-4be1-b938-6bcce63368e7'
  AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
  AND season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

DO $$
DECLARE v_n int; v_named int; v_has_answer int;
BEGIN
  SELECT count(*) INTO v_n FROM ca0214_target;
  IF v_n NOT IN (0, 1) THEN
    RAISE EXCEPTION 'CA_0214 pre-flight: % row(s) match the pinned key, expected exactly 1 (or 0 on a re-run)', v_n;
  END IF;
  IF v_n = 0 THEN
    RAISE NOTICE 'CA_0214: nothing to do, the target row is already gone';
  END IF;

  -- Pin the content, so this cannot quietly delete a row that has since been rewritten to answer
  -- the redistricting ladder (which would make the delete wrong) or to a documented blank (which
  -- would make it a no-op that should not have run).
  SELECT count(*) INTO v_named FROM ca0214_target
   WHERE reasoning LIKE 'Barr voted against the For the People Act of 2019%'
     AND cardinality(sources) = 1
     AND sources[1] = 'https://www.ontheissues.org/House/Andy_Barr_Government_Reform.htm';
  IF v_n = 1 AND v_named <> 1 THEN
    RAISE EXCEPTION 'CA_0214 pre-flight: the row at this key is not the one this migration was written for -- read it before deleting it';
  END IF;

  -- Must still have no answer in ANY season (the ORPHAN_CONTEXT join, not just this row's season).
  -- If one was written since this was drafted, deleting the context now would create an
  -- ANSWER_WITHOUT_CONTEXT violation, which is zero-tolerance.
  SELECT count(*) INTO v_has_answer FROM ca0214_target t
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers a
                  WHERE a.politician_id = t.politician_id AND a.topic_id = t.topic_id);
  IF v_has_answer <> 0 THEN
    RAISE EXCEPTION 'CA_0214 pre-flight: the target row has acquired an answer since this migration was written -- it is no longer an orphan';
  END IF;
END $$;

SET LOCAL inform.allow_closed_season_write = 'on';

DELETE FROM inform.politician_context c USING ca0214_target t
WHERE c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id;

RESET inform.allow_closed_season_write;

DO $$
DECLARE v_left int; v_ans_wo_ctx int;
BEGIN
  -- The pinned row is gone.
  SELECT count(*) INTO v_left FROM inform.politician_context
   WHERE politician_id = 'd6d297f5-5319-4be1-b938-6bcce63368e7'
     AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
     AND season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF v_left <> 0 THEN RAISE EXCEPTION 'CA_0214: target row still present after delete'; END IF;

  -- No answer anywhere lost its context (the zero-tolerance check the gate itself runs).
  SELECT count(*) INTO v_ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id);
  IF v_ans_wo_ctx > 0 THEN RAISE EXCEPTION 'CA_0214: % answer(s) now have no context', v_ans_wo_ctx; END IF;

  -- The two carved-out documented blanks on this same duplicate are untouched.
  SELECT count(*) INTO v_left FROM inform.politician_context
   WHERE politician_id = 'd6d297f5-5319-4be1-b938-6bcce63368e7'
     AND reasoning LIKE 'No public record found establishing a position on%';
  IF v_left <> 2 THEN
    RAISE EXCEPTION 'CA_0214: expected the 2 documented-blank rows on this duplicate to remain, found %', v_left;
  END IF;

  RAISE NOTICE 'CA_0214 OK: Barr duplicate redistricting orphan context deleted, no answer lost its context';
END $$;

COMMIT;
