-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- TEMPLATE — paste into any migration that DELETEs from inform.politician_answers.
-- Not a migration. Nothing here runs on its own; `_templates/` is skipped by the numbering check.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
--
-- 🔴 WHY THIS EXISTS. Between 2026-08-12 and 2026-08-13, SEVEN passes deleted stance answers and left
-- the reasoning in place -- 1735 (judicial), 1738/1739 (Berkeley), and the four Maryland passes. Every
-- one was a deliberate, correct decision about the ANSWER. Not one of them made a decision about the
-- CONTEXT, and each silently created ORPHAN_CONTEXT violations it never saw. The gate went from 50 to
-- 224 and CI stayed red for 19 runs. Cleaning it up took three more migrations (1755/1756/1757).
--
-- 🔑 RETIRING AN ANSWER AND RETIRING A STANCE ARE NOT THE SAME OPERATION. Deleting the answer removes
-- the chair; the reasoning that argued for that chair survives, still asserting a position, now
-- attached to nothing. It is not published while the row has no answer -- but write an answer for that
-- pair later and Citations.jsx renders the old prose verbatim under "Why this position?".
--
-- ⚠ A GUARD THAT ASSERTS THE CONTEXT SURVIVED IS NOT THIS GUARD. 1735's guard 2 checked that the
-- blanked rows KEPT their context and passed green -- it was verifying the opposite property. What has
-- to be tested is whether the surviving context is still a gate-visible orphan, which means running
-- check-stance-sources.mjs's ORPHAN_CONTEXT predicate against the rows this migration touched.
--
-- ── HOW TO USE ─────────────────────────────────────────────────────────────────────────────────
-- 1. Keep the rows you delete in a temp table with (pid, tid) columns -- most migrations here already
--    do, e.g. `js_target`, `ce_blank`, `bk_blank`. Substitute its name below.
-- 2. Paste the @context-decision line and the DO block AFTER the DELETE, BEFORE COMMIT.
-- 3. Pick the disposition and say why in one line. The four legal values:
--
--      deleted              the question does not apply to this person at all, so a blank would
--                           assert an untested absence. Delete the context too, and capture it to a
--                           rollback file first. (What 1755 did for the judicial ladders.)
--      rewritten-as-blank   the topic genuinely applies and the record WAS read. Rewrite the reasoning
--                           as a documented blank naming what was checked. (1756/1757.)
--      kept-already-blank   the context is already an honest documented blank (empty sources, or it
--                           carves out on its own wording). Nothing to do.
--      no-context-rows      these pairs have no context row at all. Nothing to do.
--
-- ⚠ `rewritten-as-blank` IS EARNED BY TRUTH, NOT BY WORDING. The carve-out fires on a leading
-- "Researched YYYY-MM-DD", so that prefix would exempt anything you prefix it with. Only write it when
-- the reading is genuinely on the record and the row can state what was checked and why it failed.
-- Never widen the carve-out regex in check-stance-sources.mjs to make rows fall out -- widening exempts
-- rows nobody has read.
--
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- ▼▼ PASTE FROM HERE ▼▼

-- @context-decision: rewritten-as-blank — REPLACE THIS with the disposition and one line of why

-- GUARD: the answers deleted above must not leave gate-visible orphan context behind. This is
-- check-stance-sources.mjs's ORPHAN_CONTEXT predicate, applied to the rows THIS migration touched, so
-- the decision is forced here instead of surfacing in CI days later as someone else's regression.
-- ⚠ Keep the two regexes character-identical to the gate's. If they drift, this passes while the gate
-- fails, which is worse than not having the guard.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM my_deleted_pairs t                       -- ⚠ REPLACE with your temp table (pid, tid)
    JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = t.tid
   WHERE coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';

  IF new_orphans > 0 THEN
    RAISE EXCEPTION
      'context guard: % row(s) lost their answer but kept reasoning that still describes a position. '
      'Delete that context, or rewrite it as a documented blank, IN THIS MIGRATION -- not later.',
      new_orphans;
  END IF;
END $$;

-- ▲▲ PASTE TO HERE ▲▲
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
--
-- ── IF THE GUARD FIRES ─────────────────────────────────────────────────────────────────────────
-- It is telling you the pass is half-finished, not that the delete was wrong. Decide which case you
-- are in -- and the two look identical from the row alone, so read the LADDER, not just the prose:
--
--   Does the question even apply to this person?
--     NO  -> `deleted`. A judicial role-conduct ladder asks about the subject's own conduct in a role
--            they neither hold nor seek; a legislator cannot hold a position on how *their office*
--            charges cases. Writing "we looked and found nothing" there asserts an absence nobody
--            tested. Capture reasoning + sources to data/stance-retirement/ first, then delete.
--     YES -> `rewritten-as-blank`, but only if the record really was read. Say what was checked
--            (a count of candidate instruments is ideal) and why it failed to place the person.
--
-- Related: migrations 1755, 1756, 1757 and their headers; the 2026-08-14 handoff block in
-- .planning/todos/2026-07-30-stance-resourcing-backlog.md.
