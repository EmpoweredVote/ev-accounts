BEGIN;

-- =============================================================================
-- CC_0037: Jeff Gonzalez — remove 12 seatings evidenced against a DIFFERENT PERSON
-- =============================================================================
-- Created 2026-09-01 with Chris Cantrell (4e6dde8f-2bd0-4054-824f-4164744165ea).
--
-- 🔴 WHAT IS WRONG: twelve of Jeff Gonzalez's twenty-two compass seatings are
--    evidenced against LOLA SMALLWOOD-CUEVAS's record, not his. Ten name her
--    outright ("Smallwood-Cuevas is a career civil rights and labor activist
--    who authored SCR 89..."); the other two describe her in the third person
--    feminine ("Her office states...", "Her 100/100 ACLU score...").
--
--    Jeff Gonzalez is the Republican Assemblymember for California's AD-36.
--    Lola Smallwood-Cuevas is a Democratic state senator. He is currently
--    published holding her positions on twelve topics, including
--    civil-rights=1, medicare/aid=1 (Medicare for All), school-vouchers=1
--    (opposes vouchers) and social-security=1 (expand benefits). This is a
--    factual misrepresentation of a named living person, which is why it is
--    being removed rather than queued behind the Season 2 work.
--
-- HOW THE SPLIT WAS DRAWN — it is unusually clean:
--    * the 12 removed rows name Smallwood-Cuevas or use she/her, and NEVER
--      name Gonzalez;
--    * the 10 retained rows name Gonzalez, cite AD-36 roll calls
--      ("Gonzalez voted NO on SB-7 (2025)", "12% lifetime environmental score
--      from California Environmental Voters"), and use no feminine pronoun.
--    No row falls in both sets or neither. The retained ten are untouched.
--
-- WHY DELETE RATHER THAN CORRECT: the correct seating for Gonzalez on these
--    twelve topics is UNKNOWN. Writing a value would be inventing one. Deleting
--    leaves the spokes blank, which is the honest state, and mirrors the
--    blank disposition used in CA_0035 and CA_0056.
--
-- ⚠ SMALLWOOD-CUEVAS IS NOT MISSING DATA. She holds her own 21 seatings with
--    her own separately-written reasoning (her civil-rights is chair 2, not the
--    chair 1 recorded on Gonzalez). Nothing here needs re-homing to her; these
--    rows are duplicated research about her that landed on the wrong id.
--
-- ⚠ THIS DELETES FROM OPEN SEASON 1. The schema cannot express "blank in one
--    season, seated in another" — politician_answers.value is CHECK 1..5 with no
--    zero, and the compare read falls back to the newest season. Same decision
--    and same rationale as CA_0035/CA_0056: an unevidenced seat is wrong in
--    every season, so it is removed live.
--
-- SCOPE — CHECKED, AND ISOLATED. A scan of every politician_context row for a
--    leading token that is a person's name absent from that politician's own
--    full_name returns Jeff Gonzalez and nobody else. Every other hit is a
--    source name ("Researched", "OnTheIssues", "Ballotpedia", "CitizensCount"),
--    a place ("Texas", "Cambridge", "Worcester"), or a verb ("Voted", "Signed").
--    This is one mis-keyed research pass, not a systemic class.
--
-- SIDE EFFECT ON THE CIVIL-RIGHTS AUDIT: civil-rights chair 1 goes 210 -> 209.
--    Gonzalez was in that population; he was never a legitimate member of it.
--
-- @context-decision: deleted-with-context — the context row is removed together
--    with the answer, because the context is the thing that is wrong. No orphan
--    context remains and no documented-blank is written: we are not asserting
--    anything about Gonzalez's views, only withdrawing an assertion about them.
--
-- IDEMPOTENT: both DELETEs are guarded by the same reasoning predicate that
--    identified the rows, so a re-run matches nothing.
-- =============================================================================

DO $$
DECLARE
  v_pol CONSTANT uuid := '5ad32852-789e-4013-995b-6f0aa6a5a5d4';  -- Jeff Gonzalez
  v_ctx_deleted int;
  v_ans_deleted int;
  v_remaining   int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = v_pol AND full_name = 'Jeff Gonzalez') THEN
    RAISE EXCEPTION 'CC_0037: politician id does not resolve to Jeff Gonzalez';
  END IF;

  -- Answers first: the context predicate is what identifies them, so it has to
  -- still be readable when they are selected.
  WITH bad AS (
    SELECT pc.topic_id FROM inform.politician_context pc
     WHERE pc.politician_id = v_pol
       AND pc.reasoning ~* '(\mher\M|\mshe\M|Smallwood)'
       AND pc.reasoning !~* '\mGonzalez\M'
  )
  DELETE FROM inform.politician_answers pa
   USING bad WHERE pa.politician_id = v_pol AND pa.topic_id = bad.topic_id;
  GET DIAGNOSTICS v_ans_deleted = ROW_COUNT;

  DELETE FROM inform.politician_context pc
   WHERE pc.politician_id = v_pol
     AND pc.reasoning ~* '(\mher\M|\mshe\M|Smallwood)'
     AND pc.reasoning !~* '\mGonzalez\M';
  GET DIAGNOSTICS v_ctx_deleted = ROW_COUNT;

  SELECT count(*) INTO v_remaining FROM inform.politician_context WHERE politician_id = v_pol;

  RAISE NOTICE 'CC_0037: removed % answers and % context rows; % context rows retained',
    v_ans_deleted, v_ctx_deleted, v_remaining;
END $$;

-- ---------------------------------------------------------------------------
-- Post-verify gate.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_pol CONSTANT uuid := '5ad32852-789e-4013-995b-6f0aa6a5a5d4';
  v_bad int; v_ctx int; v_ans int; v_lola int;
BEGIN
  -- nothing referencing the wrong person survives
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = v_pol AND reasoning ~* '(\mher\M|\mshe\M|Smallwood)' AND reasoning !~* '\mGonzalez\M';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0037: % mis-attributed context rows still present', v_bad;
  END IF;

  -- the genuine ten survive intact
  SELECT count(*) INTO v_ctx FROM inform.politician_context WHERE politician_id = v_pol;
  IF v_ctx <> 10 THEN
    RAISE EXCEPTION 'CC_0037: % context rows retained (expected 10)', v_ctx;
  END IF;

  -- data-centers carries context but never carried an answer, so 9 answers remain
  SELECT count(*) INTO v_ans FROM inform.politician_answers WHERE politician_id = v_pol;
  IF v_ans <> 9 THEN
    RAISE EXCEPTION 'CC_0037: % answers retained (expected 9)', v_ans;
  END IF;

  -- no answer is left without its context
  SELECT count(*) INTO v_bad FROM inform.politician_answers pa
   WHERE pa.politician_id = v_pol
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context pc
                      WHERE pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id);
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0037: % orphaned answers', v_bad;
  END IF;

  -- Smallwood-Cuevas's own record is untouched
  SELECT count(*) INTO v_lola FROM inform.politician_context
   WHERE politician_id = 'cb9b6b95-ace4-4ae3-a7e6-ae2349abd741';
  IF v_lola <> 21 THEN
    RAISE EXCEPTION 'CC_0037: Smallwood-Cuevas has % context rows (expected 21, untouched)', v_lola;
  END IF;

  RAISE NOTICE 'CC_0037 OK — 12 mis-attributed seatings removed, 10 genuine retained, Smallwood-Cuevas untouched';
END $$;

COMMIT;
