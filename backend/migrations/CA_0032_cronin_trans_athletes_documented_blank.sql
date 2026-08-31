BEGIN;

-- =============================================================================
-- CA_0032: Transgender Athletes — retire John J. Cronin's inference-only chair 3
--          to a DOCUMENTED BLANK
-- =============================================================================
-- Created 2026-08-30 by Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- THE ROW
--   politician_id  ef888471-24a9-4a9f-9115-e530c16986ae  (John J. Cronin, MA Senate)
--   topic_id       d1618b9c-0b9e-45af-b986-bb33d270b8e4  (trans-athletes)
--   season_id      2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3  (Season 1, open)
--   topic_revision af2c6427-daf8-4819-93ba-42db212bae68
--   seated at      chair 3 (value 3.0, "decide eligibility case by case")
--
--   Prior reasoning (verbatim):
--     "Did not co-sponsor the Healthy Youth Act on Act on Mass. No evidence of
--      public positions on transgender athletes specifically. Consistent with a
--      case-by-case or separate divisions approach."
--   Prior sources: the Act on Mass legislator scorecard (one web.archive.org URL).
--
-- WHY THIS IS UNEVIDENCED (see CLAUDE.md "Compass chairs are five distinct stances")
--   The five chairs are five distinct stances; a chair is a claim about which stance
--   the person holds, not a rating of intensity. This reasoning names NO bill, act,
--   ordinance or vote about transgender-athlete eligibility (the Healthy Youth Act is
--   sex-education, not sports), and it states outright there is "No evidence of public
--   positions on transgender athletes specifically". Chair 3 was reached by the
--   least-extreme / middle-option tiebreaker ("Consistent with a case-by-case ...
--   approach"), which the standard names explicitly as a TIEBREAKER, not evidence.
--   The row fails the chair-evidence gate on its own merits (already noted in the
--   CA_0031 header). Re-sourcing was attempted 2026-08-30 and found nothing: the Act
--   on Mass scorecard, his campaign site (johnjcronin.com) and a general legislative
--   and news search show no position on how eligibility should be decided. So the
--   honest record is a blank spoke, not a guessed chair.
--
-- DISPOSITION: rewritten-as-blank (NOT deleted).
--   Transgender-athlete eligibility is a live policy question a sitting state senator
--   can hold a position on, so the question genuinely applies to this person (unlike a
--   judicial-conduct ladder posed to a legislator). The record WAS read and failed to
--   place him, so we keep the context row, keep the source that was checked, and
--   rewrite the reasoning as a documented blank that says what was checked and why it
--   failed. The answer (the chair) is removed.
--
--   Removing the answer while leaving a context row is the documented-blank shape
--   (context-without-answer), which is legitimate by design. The new reasoning matches
--   check-stance-sources.mjs's ORPHAN_CONTEXT carve-out on two counts (a leading
--   "Researched YYYY-MM-DD" and a "no scorable public record" phrase), so the pair is
--   not a gate-visible orphan. The guard below proves that against the row this
--   migration touched.
--
--   Note: after this runs, audit-chair-evidence.mjs counts this pair as "blanked"
--   (a blank spoke seats no chair and is resolved), not as unevidenced debt.
--
-- Idempotent: the DELETE removes 0 rows on a second run; the UPDATE is guarded on the
-- reasoning text; the guard and post-verify gate re-assert the end state either way.
-- =============================================================================

-- The pair(s) this migration blanks. Built unconditionally (not from the surviving
-- answer), so the ORPHAN_CONTEXT guard below re-checks the pair on every run.
CREATE TEMP TABLE ta_blank (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO ta_blank (pid, tid) VALUES
  ('ef888471-24a9-4a9f-9115-e530c16986ae', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4');

-- 1) Remove the chair (Season 1 only — the only season this pair is answered in).
DELETE FROM inform.politician_answers a
USING ta_blank t
WHERE a.politician_id = t.pid
  AND a.topic_id      = t.tid
  AND a.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';

-- 2) Rewrite the surviving context as a documented blank. Sources are kept as-is (the
--    Act on Mass scorecard is what was checked). Guarded so a re-run is a no-op.
UPDATE inform.politician_context pc
SET reasoning = 'Researched 2026-08-30 (Chris Andrews, CA_0032): no scorable public record of a position on transgender-athlete eligibility. Reviewed the Act on Mass legislative scorecard, his campaign site (johnjcronin.com) and a general legislative and news search; none states how he holds that eligibility for transgender athletes in sports should be decided. The prior chair-3 (decide eligibility case by case) seating rested on the least-extreme-option tiebreaker, not on evidence describing that chair, so the honest record is a blank spoke.',
    updated_at = now()
FROM ta_blank t
WHERE pc.politician_id = t.pid
  AND pc.topic_id      = t.tid
  AND pc.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
  AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}';

-- @context-decision: rewritten-as-blank — trans-athlete eligibility is a live policy
-- question a sitting state senator can hold; the record (Act on Mass scorecard,
-- campaign site, legislative/news search) was read 2026-08-30 and shows no scorable
-- position, so the chair-3 inference is retired to a documented blank that names what
-- was checked. The context row and its checked source are kept.

-- GUARD: the answer deleted above must not leave gate-visible orphan context behind. This is
-- check-stance-sources.mjs's ORPHAN_CONTEXT predicate, applied to the rows THIS migration touched, so
-- the decision is forced here instead of surfacing in CI days later as someone else's regression.
-- ⚠ Keep the two regexes character-identical to the gate's. If they drift, this passes while the gate
-- fails, which is worse than not having the guard.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM ta_blank t                               -- the pairs this migration blanked (pid, tid)
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

-- =============================================================================
-- POST-VERIFY GATE — assert the end state: chair gone, context is a documented blank,
-- source preserved, pair is not an orphan.
-- =============================================================================
DO $$
DECLARE
  v_pid    CONSTANT uuid := 'ef888471-24a9-4a9f-9115-e530c16986ae';
  v_tid    CONSTANT uuid := 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
  v_sid    CONSTANT uuid := '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  v_ans    int;
  v_reason text;
  v_src    int;
  v_orph   int;
BEGIN
  SELECT count(*) INTO v_ans
    FROM inform.politician_answers
   WHERE politician_id = v_pid AND topic_id = v_tid AND season_id = v_sid;
  IF v_ans <> 0 THEN
    RAISE EXCEPTION 'CA_0032 post-verify: chair-3 answer still present (% row(s))', v_ans;
  END IF;

  SELECT reasoning, cardinality(sources) INTO v_reason, v_src
    FROM inform.politician_context
   WHERE politician_id = v_pid AND topic_id = v_tid AND season_id = v_sid;
  IF v_reason IS NULL THEN
    RAISE EXCEPTION 'CA_0032 post-verify: context row is missing (a documented blank must keep its context)';
  END IF;
  IF v_reason !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
    RAISE EXCEPTION 'CA_0032 post-verify: reasoning is not the documented blank ("%")', left(v_reason, 60);
  END IF;
  IF v_src < 1 THEN
    RAISE EXCEPTION 'CA_0032 post-verify: the checked source was dropped (expected >= 1, got %)', v_src;
  END IF;

  -- The gate's ORPHAN_CONTEXT predicate, verbatim, for this pair. Must be 0.
  SELECT count(*) INTO v_orph
    FROM inform.politician_context pc
   WHERE pc.politician_id = v_pid AND pc.topic_id = v_tid
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF v_orph <> 0 THEN
    RAISE EXCEPTION 'CA_0032 post-verify: pair is a gate-visible ORPHAN_CONTEXT (% row(s))', v_orph;
  END IF;

  RAISE NOTICE 'CA_0032 post-verify OK: Cronin/trans-athletes chair 3 retired to a documented blank; source kept; not an orphan.';
END $$;

COMMIT;
