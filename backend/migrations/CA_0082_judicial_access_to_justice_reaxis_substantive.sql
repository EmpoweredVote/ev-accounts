BEGIN;

-- =============================================================================
-- CA_0082: Access to Justice (judicial-access-to-justice) — reframe the question
--          and all five chairs from a policy OPINION about the legal system onto
--          a single ACCESS axis that a legal-system actor enacts through their
--          role, sharpen the neutral middle so chairs 3 and 4 are distinct,
--          approve the new revision, and pin it into Season 2 (a DRAFT; NOT open).
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC 9d45acaf-… ('judicial-access-to-justice', "Access to Justice"). Scope:
--   judicial only (compass_topic_roles = judicial, required). 48 seated rows on
--   the open Season-1 v1 today (10/32/4/2/0 at chairs 1/2/3/4/5). Reviewed
--   2026-08-31 under the single-revision ("unchanged") review pass.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (becomes rev 2 / version 2) with the
--      reviewed question + five chairs.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, 710fc64b-…) to the new
--      revision. Season 1 (open) is left on v1.
--
-- THE CHECKS THAT DROVE THE EDIT (review 2026-08-31, Chris Andrews):
--   • PER-RUNG SCOPE (the core finding). The "judicial" lens here is the people
--     who run the legal system — judges, court clerks, city/county attorneys,
--     attorneys general — not sitting judges alone. The old rungs were written as
--     POLICY OPINIONS about the legal system ("Low barriers mean more access to
--     justice"; "Too much litigation clogs the system and costs everyone money").
--     Framed that way, 4 of 5 rungs could only be evidenced by opinion at the
--     legal-actor level, and the topic was in fact being seated on LEGISLATIVE
--     acts by people outside the lens: ~half the 48 seats are general legislators
--     (US Congress, state legislatures) evidenced on legal-aid funding votes and
--     bills, not on how a legal-system actor treats access. Every rung is rewritten
--     as an ACCESS POSTURE a legal-system actor takes in their own role (a judge in
--     rulings and fee decisions, a clerk in how navigable the court is, an attorney/
--     AG in whether they help people use the system or resist them).
--   • ONE AXIS, made explicit. The five chairs are one spectrum — how easy it is to
--     use the courts — from maximum access (chair 1) to strict gatekeeping (chair 5).
--     Recast as a clear TILT: help people in (1) -> forgive technicalities (2) ->
--     neutral, merits decide (3) -> demand a strong showing (4) -> courts as a last
--     resort (5). The new question states that axis plainly and neutrally.
--   • DISTINCTNESS (chairs 3 vs 4). Old chairs 3 ("keep out frivolous cases") and 4
--     ("higher bars are fine") were both "screen out bad cases", differing only by
--     strength — a rating, not two positions. New chair 3 is the true NEUTRAL middle
--     (same rules for everyone, no thumb on the scale); new chair 4 is a real tilt
--     AGAINST access (raise the threshold, demand a strong showing up front). The
--     old middle rungs were also told apart only by "how strongly", which the recut
--     removes.
--
--   CURRENT -> NEW (value : text):
--     Q : "Should it be easy or hard to take someone to court?"
--       -> "How easy should it be to use the courts?"
--     1 : "Easy. Courts exist for everyone — not just people with expensive lawyers. Low barriers mean more access to justice."
--       -> "Make it easy to bring a case, and clear away the costs and hurdles that shut people out."
--     2 : "Accessible. Some basic requirements are fine, but courts shouldn't be a maze that only the wealthy can navigate."
--       -> "Apply the normal requirements, but don't let small mistakes or technicalities keep a real case out."
--     3 : "Reasonable standards that keep out frivolous cases without blocking legitimate ones."
--       -> "Apply the same rules to everyone, and let a case stand or fall on its own merits."
--     4 : "Higher bars are fine. Too much litigation clogs the system and costs everyone money."
--       -> "Require people to show a strong case up front, and dismiss those that fall short."
--     5 : "Hard. Most disputes should be settled privately. Courts should be a last resort, not a first option."
--       -> "Keep the courts for serious cases only, and steer other disputes elsewhere."
--
-- CLASS: substantive -> version 2. rung_map is identity {1:1,2:2,3:3,4:4,5:5}: the
--   five positions stay in place (maximum access at 1, strict gatekeeping at 5); the
--   FRAME of every rung moves (opinion -> role conduct), which is why the seats need
--   a re-audit rather than carrying forward.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   WHOLE-SET re-audit: all 48 seated rows (10/32/4/2/0). Every rung's frame moved
--   from policy opinion to role conduct, and the topic was being seated outside its
--   lens, so no seat carries automatically. Expected shape:
--     • The ~half of rows that are GENERAL LEGISLATORS seated on funding votes / bills
--       (US Congress, state legislatures) BLANK — that work is not a legal-system
--       actor's access posture. A blank spoke is the honest result.
--     • The legal-system-actor rows (AGs, city/county attorneys, court clerk, and
--       judicial candidates) are RE-READ against "how easy to use the courts". A few
--       evidenced on criminal diversion (e.g. a DA's alternative courts) may also
--       blank, since that belongs to the criminal-justice topic, not this one.
--   Do NOT open Season 2 on this revision until that 48-row pass is done. That is a
--   SEPARATE, approved migration against politician_answers.
--   (Per-stance description/supporting_points live in the FROZEN legacy compass_stances
--   copy; 0 source reads; the voter-facing revision is text-only, nothing to restore
--   here. Any legacy description now mismatches the new wording but is dormant — leave it.)
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2
--   is a draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps
--   serving v1 via the version mechanic (it pins version 1; approving a version-2
--   revision does not change what version 1 resolves to). No answer rows are touched.
--
-- Idempotent: re-running after success is a no-op (the revision already exists/approved;
--   Season 2 already pins it).
-- Model: CA_0071 (single-revision review -> substantive v2, approve + pin S2),
--   CA_0070 (judicial re-axis as role orientation, whole-set re-audit).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := '9d45acaf-1ba4-4cb8-95e1-5ed985223b91';               -- judicial-access-to-justice
  v_topickey CONSTANT text := 'judicial-access-to-justice';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := '710fc64b-4670-4714-b2fa-9076c07459c0';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'How easy should it be to use the courts?';
  v_chair5   CONSTANT text := 'Keep the courts for serious cases only, and steer other disputes elsewhere.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Make it easy to bring a case, and clear away the costs and hurdles that shut people out.'),
    jsonb_build_object('value',2,'text','Apply the normal requirements, but don''t let small mistakes or technicalities keep a real case out.'),
    jsonb_build_object('value',3,'text','Apply the same rules to everyone, and let a case stand or fall on its own merits.'),
    jsonb_build_object('value',4,'text','Require people to show a strong case up front, and dismiss those that fall short.'),
    jsonb_build_object('value',5,'text','Keep the courts for serious cases only, and steer other disputes elsewhere.')
  );
  v_new      uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0082: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0082: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0082: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Step 1: find-or-create the reframe revision (rev 2 / v2). Idempotent. --------
  SELECT r.id INTO v_new
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND r.status IN ('draft','approved')
    AND r.question_text = v_stem
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 5 AND s.text = v_chair5);
  IF v_new IS NULL THEN
    v_new := inform.admin_propose_topic_revision(
      v_topickey, v_actor, 'substantive',
      'Access to Justice', 'Court Access',
      v_stem, v_stances,
      -- rationale
      'Single-revision review 2026-08-31 (Chris Andrews). The "judicial" lens is the people who run the '
      || 'legal system (judges, court clerks, city/county attorneys, attorneys general), not sitting judges '
      || 'alone. The old rungs were POLICY OPINIONS about the legal system, so 4 of 5 could only be evidenced '
      || 'by opinion at that level, and the topic was in fact being seated on LEGISLATIVE acts by people '
      || 'outside the lens — ~half of 48 seats are general legislators evidenced on legal-aid funding votes '
      || 'and bills. Every rung is rewritten as an ACCESS POSTURE a legal-system actor takes in their own role '
      || '(a judge in rulings and fee decisions, a clerk in how navigable the court is, an attorney/AG in '
      || 'whether they help people use the system or resist them). The five chairs are one axis — how easy it '
      || 'is to use the courts — recast as a clear tilt: help people in (1), forgive technicalities (2), '
      || 'neutral so the merits decide (3), demand a strong showing (4), courts as a last resort (5). Old chairs '
      || '3 and 4 were both "screen out bad cases" differing only by strength; the recut makes 3 the true '
      || 'neutral middle and 4 a real tilt against access. Substantive (version 2) because every rung''s frame '
      || 'moves; rung_map is identity, the positions stay in place. WHOLE-SET 48-row re-audit owed before '
      || 'Season 2 opens (general-legislator rows expected to blank; legal-actor rows re-read). Approved + '
      || 'pinned to Season 2 only; Season 1 stays on v1.',
      -- public_note
      'Rewrote this question and its options so they measure one thing — how easy it should be to use the '
      || 'courts — and so each option describes what a court or legal official actually does (help people bring '
      || 'a case, forgive small mistakes, apply the rules evenly, demand a strong case first, or keep court for '
      || 'serious matters), instead of a general opinion about the legal system.',
      -- review_ref
      'Single-revision review 2026-08-31 (Chris Andrews), reviewunchangedtopicprompt.md judicial-access-to-justice '
      || 'pass; scope judicial only; seat distribution 10/32/4/2/0 at chairs 1-5 (48 total).',
      v_rungmap);
    RAISE NOTICE 'CA_0082: proposed reframe revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0082: reframe revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0082: reframe revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0082: reframe revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0082: reframe revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0082: Season 2 already pins the reframe revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0082: Season 2 repinned % -> % (reframe revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '9d45acaf-1ba4-4cb8-95e1-5ed985223b91';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := '710fc64b-4670-4714-b2fa-9076c07459c0';
  v_stem     CONSTANT text := 'How easy should it be to use the courts?';
  v_chair5   CONSTANT text := 'Keep the courts for serious cases only, and steer other disputes elsewhere.';
  v_new      uuid;
  v_status   text;
  v_pub      timestamptz;
  v_iscur    boolean;
  v_rev      int;
  v_ver      int;
  v_class    text;
  v_n        int;
  v_v1cur    boolean;
  v_v1stat   text;
  v_pin      uuid;
  v_openver  int;
BEGIN
  -- Locate the reframe revision by stem + chair-5 text.
  SELECT r.id, r.status, r.published_at, r.is_current, r.revision, r.version, r.change_class::text
    INTO v_new, v_status, v_pub, v_iscur, v_rev, v_ver, v_class
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic AND r.question_text = v_stem
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 5 AND s.text = v_chair5);
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0082 verify: reframe revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0082 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0082 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0082 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 2 THEN RAISE EXCEPTION 'CA_0082 verify: new rev revision is % (expected 2)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0082 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0082 verify: new rev change_class is % (expected substantive)', v_class; END IF;

  -- Exactly five rungs, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0082 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'Make it easy to bring a case, and clear away the costs and hurdles that shut people out.')
    OR (s.value = 2 AND s.text = 'Apply the normal requirements, but don''t let small mistakes or technicalities keep a real case out.')
    OR (s.value = 3 AND s.text = 'Apply the same rules to everyone, and let a case stand or fall on its own merits.')
    OR (s.value = 4 AND s.text = 'Require people to show a strong case up front, and dismiss those that fall short.')
    OR (s.value = 5 AND s.text = 'Keep the courts for serious cases only, and steer other disputes elsewhere.'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0082 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No old wording leaked into the new revision.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%expensive lawyers%' OR s.text ILIKE '%frivolous%'
               OR s.text ILIKE '%clogs the system%' OR s.text ILIKE '%settled privately%'
               OR s.text ILIKE '%last resort, not a first option%')) THEN
    RAISE EXCEPTION 'CA_0082 verify: new rev still carries old chair wording';
  END IF;
  IF v_stem ILIKE '%take someone to court%' THEN
    RAISE EXCEPTION 'CA_0082 verify: new question still carries old wording';
  END IF;

  -- v1 still the published/current revision, and exactly one such.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0082 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0082 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0082 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0082 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

  -- Season 1 (open) still resolves version 1.
  SELECT eff.version INTO v_openver
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
  JOIN inform.compass_topic_revisions pin ON pin.id = sq.topic_revision_id
  JOIN LATERAL (
    SELECT ee.version FROM inform.compass_topic_revisions ee
    WHERE ee.topic_id = pin.topic_id AND ee.version = pin.version
      AND ee.status IN ('published','superseded')
    ORDER BY ee.revision DESC LIMIT 1
  ) eff ON true
  WHERE sq.topic_id = v_topic;
  IF v_openver IS NOT NULL AND v_openver <> 1 THEN
    RAISE EXCEPTION 'CA_0082 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0082 post-verify OK: reframe rev 2/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. Whole-set 48-row re-audit deferred before Season 2 opens.';
END $$;

COMMIT;
