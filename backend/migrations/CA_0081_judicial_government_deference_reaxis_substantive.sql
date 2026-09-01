BEGIN;

-- =============================================================================
-- CA_0081: Judicial Deference to Government (judicial-government-deference) —
--          RE-AXIS. Rewrite the question and all five chairs onto ONE coherent
--          axis (how closely courts should review decisions by elected officials
--          and agencies), pin the axis to a single referent, retitle to drop the
--          "& Prosecutorial" half, approve the new revision, and pin it into
--          Season 2 (a DRAFT; NOT open). Season 1 (open) is left on v1.
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC e5e48f0e-… ('judicial-government-deference'). Scope: judicial only
--   (compass_topic_roles = {judicial:required}). 22 seated rows on the open
--   Season-1 v1 today (7/9/4/1/1 at chairs 1/2/3/4/5). Reviewed 2026-08-31 under
--   the single-revision ("unchanged") review pass.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (becomes rev 2 / version 2) with the
--      reviewed title + question + five chairs.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, a71cd985-…) to the new
--      revision. Season 1 (2d5d67d1-…, open) is left on v1.
--
-- WHY A RE-AXIS, NOT A REWORD (the seven-check finding, review 2026-08-31):
--   • FAILS check 1 (one spectrum) and check 6 (evidence-able). The old ladder
--     ("When government and a citizen clash, who gets the benefit of the doubt?")
--     welds at least THREE independent deference axes into one dial: checking the
--     EXECUTIVE (separation of powers), deference to regulatory AGENCIES (Chevron),
--     and deference to the COERCIVE state (police/searches). For a progressive
--     these point OPPOSITE ways (pro-agency but anti-executive), so a single chair
--     cannot sort them. Proven by the live seatings: pro-agency-deference
--     progressives (Warren, Markey, McGovern, Neal, Trahan, Clark) are seated at
--     chairs 1-2 (the LEAST-deference / pro-citizen end) alongside anti-executive
--     attorneys (Bonta, Chiu) and civil-liberties skeptics — an axis inversion.
--   • FIX: pin the axis to ONE referent — decisions by elected officials and
--     agencies — and ask one question: how closely should courts review them?
--     Every chair becomes a single checkable posture on a burden-of-proof gradient
--     (chair 1 = burden on the government / least deference; chair 5 = near-absolute
--     deference / most deference). Direction is preserved end-to-end (1 = least
--     deference, 5 = most), so rung_map is identity — but the AXIS changed, so the
--     seats need FRESH placement (see re-audit note).
--   • PASSES check 4 (per-rung judicial scope): every rung is a genuine adjudicative
--     posture a judge enacts through rulings (burdens, presumptions, standards of
--     review). No rung is opinion-only. The "& Prosecutorial" half of the old title
--     is dropped because prosecutors do not exercise this review; scope stays judicial.
--
--   CURRENT -> NEW:
--     Title : "Judicial & Prosecutorial Discretion" -> "Judicial Deference to Government"
--     Short : "Government Deference" (unchanged — stable spoke label)
--     Q : "When government and a citizen clash, who gets the benefit of the doubt?"
--       -> "When elected officials or a government agency make a decision, how closely should courts review it?"
--     1 : "The citizen, almost always. Government has lawyers, money, and power. Regular people need courts to level the playing field."
--       -> "When the law is unclear, courts should side with the individual and require the government to prove its decision was clearly within its legal authority."
--     2 : "The citizen usually — unless the government has clear legal authority on its side."
--       -> "When the law is unclear, courts should lean toward the individual and overturn decisions whose legal basis is doubtful."
--     3 : "Neither side automatically. Look at the facts and apply the law evenly."
--       -> "Courts should not favor either side. When the law is unclear, neither the government nor the individual gets the benefit of the doubt."
--     4 : "The government usually — it represents everyone, and its decisions deserve respect unless clearly wrong."
--       -> "When the law is unclear, courts should lean toward the government and uphold its decision unless it clearly broke the law."
--     5 : "The government, unless it has obviously overreached. Officials make decisions for good reasons — courts shouldn't second-guess them constantly."
--       -> "Courts should defer to elected officials and agencies almost entirely, overturning a decision only for a plain and serious violation of the law."
--
-- CLASS: substantive -> version 2. rung_map is identity {1:1,2:2,3:3,4:4,5:5}: the
--   burden-of-proof direction is preserved (least deference at 1, most at 5). Identity
--   keeps the structure honest; it does NOT mean the seats carry unchanged — the axis
--   moved, so placement is re-decided in the re-audit below.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   WHOLE-SET re-audit (like CA_0070, unlike CA_0071's single-chair pass). All five
--   rungs were re-axed and the live seatings are demonstrably incoherent with the new
--   single-referent axis (pro-agency progressives mis-poled at 1-2). So every one of
--   the 22 seated rows (7/9/4/1/1) needs FRESH placement against the new wording — a
--   real read, NOT a direction-preserving validation. Expect pole moves and blanks:
--   e.g. a "defer to the EPA / opposed Loper Bright" reasoning is a chair-4/5 position
--   on the new axis, not chair 1. A blank spoke is the honest outcome where the
--   evidence describes a different clash (police, an individual criminal defendant)
--   than the new agency/executive-review referent.
--   Do NOT open Season 2 on this revision until that 22-row pass is done. That is a
--   SEPARATE, approved migration against politician_answers (+ inform.politician_context,
--   with the answer-delete context guard for any blanks).
--   (Per-stance description/supporting_points live in the FROZEN legacy compass_stances
--   copy (CA_0012), 0 source reads; the voter-facing revision is text-only, nothing to
--   restore here.)
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2
--   is a draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps
--   serving v1 via the version mechanic (it pins version 1; approving a version-2
--   revision does not change what version 1 resolves to). No answer rows are touched.
--   The retitle + re-axis reach voters only when Season 2 opens — Season 1 keeps the
--   old title, question and chairs. That is intended (this is Season-2 prep).
--
-- Idempotent: re-running after success is a no-op (the revision already exists/approved;
--   Season 2 already pins it).
-- Model: CA_0071 (deportation re-axis), CA_0070 (whole-set re-axis + judicial scope).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := 'e5e48f0e-8f3a-40e1-8080-889fea389603';               -- judicial-government-deference
  v_topickey CONSTANT text := 'judicial-government-deference';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := 'a71cd985-843e-4891-b3a5-812fb81fbe41';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'When elected officials or a government agency make a decision, how closely should courts review it?';
  v_chair5   CONSTANT text := 'Courts should defer to elected officials and agencies almost entirely, overturning a decision only for a plain and serious violation of the law.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','When the law is unclear, courts should side with the individual and require the government to prove its decision was clearly within its legal authority.'),
    jsonb_build_object('value',2,'text','When the law is unclear, courts should lean toward the individual and overturn decisions whose legal basis is doubtful.'),
    jsonb_build_object('value',3,'text','Courts should not favor either side. When the law is unclear, neither the government nor the individual gets the benefit of the doubt.'),
    jsonb_build_object('value',4,'text','When the law is unclear, courts should lean toward the government and uphold its decision unless it clearly broke the law.'),
    jsonb_build_object('value',5,'text','Courts should defer to elected officials and agencies almost entirely, overturning a decision only for a plain and serious violation of the law.')
  );
  v_new      uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0081: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0081: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0081: Season 2 is not a draft (pin would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic) THEN
    RAISE EXCEPTION 'CA_0081: topic is not in Season 2 (pin requires an existing season_questions row)';
  END IF;

  -- Step 1: find-or-create the re-axis revision (rev 2 / v2). Idempotent. --------
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
      'Judicial Deference to Government', 'Government Deference',
      v_stem, v_stances,
      -- rationale
      'Single-revision review 2026-08-31 (Chris Andrews). RE-AXIS. The old ladder failed the '
      || 'one-spectrum and evidence-able checks: "who gets the benefit of the doubt when government and a '
      || 'citizen clash" welded three independent deference axes (checking the executive, deference to '
      || 'regulatory agencies, deference to the coercive state) into one dial, which point opposite ways for '
      || 'the same person — proven by the live seatings, where pro-agency-deference progressives (Warren, '
      || 'Markey, McGovern, Neal, Trahan, Clark) sit at chairs 1-2 (least deference) beside anti-executive '
      || 'attorneys. Fix: pin the axis to one referent (decisions by elected officials and agencies) and ask '
      || 'one question — how closely should courts review them — on a burden-of-proof gradient from chair 1 '
      || '(burden on the government, least deference) to chair 5 (near-absolute deference). Direction is '
      || 'preserved so rung_map is identity, but because the axis moved every seat needs fresh placement. '
      || 'Per-rung judicial scope passes: each rung is an adjudicative posture a judge enacts through rulings; '
      || 'the "& Prosecutorial" half of the title is dropped because prosecutors do not exercise this review. '
      || 'Approved + pinned to Season 2 only; Season 1 stays on v1. WHOLE-SET re-audit of all 22 seated rows '
      || '(7/9/4/1/1) owed before Season 2 opens.',
      -- public_note
      'Reworked this topic so all five options measure one thing: how closely courts should review decisions '
      || 'made by elected officials and government agencies — from siding with the individual and putting the '
      || 'burden on the government, through a neutral middle, to deferring to the government almost entirely. '
      || 'The old version mixed several different kinds of government power into one scale, which pulled '
      || 'opposite ways depending on the case.',
      -- review_ref
      'Single-revision review 2026-08-31 (Chris Andrews), reviewunchangedtopicprompt.md judicial-government-deference pass; '
      || 'seat distribution 7/9/4/1/1 at chairs 1-5 (22 rows).',
      v_rungmap);
    RAISE NOTICE 'CA_0081: proposed re-axis revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0081: re-axis revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0081: re-axis revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0081: re-axis revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0081: re-axis revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0081: Season 2 already pins the re-axis revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0081: Season 2 repinned % -> % (re-axis revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := 'e5e48f0e-8f3a-40e1-8080-889fea389603';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := 'a71cd985-843e-4891-b3a5-812fb81fbe41';
  v_stem     CONSTANT text := 'When elected officials or a government agency make a decision, how closely should courts review it?';
  v_chair5   CONSTANT text := 'Courts should defer to elected officials and agencies almost entirely, overturning a decision only for a plain and serious violation of the law.';
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
  -- Locate the re-axis revision by stem + chair-5 text.
  SELECT r.id, r.status, r.published_at, r.is_current, r.revision, r.version, r.change_class::text
    INTO v_new, v_status, v_pub, v_iscur, v_rev, v_ver, v_class
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic AND r.question_text = v_stem
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 5 AND s.text = v_chair5);
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0081 verify: re-axis revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0081 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0081 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0081 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 2 THEN RAISE EXCEPTION 'CA_0081 verify: new rev revision is % (expected 2)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0081 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0081 verify: new rev change_class is % (expected substantive)', v_class; END IF;

  -- Exactly five rungs, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0081 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'When the law is unclear, courts should side with the individual and require the government to prove its decision was clearly within its legal authority.')
    OR (s.value = 2 AND s.text = 'When the law is unclear, courts should lean toward the individual and overturn decisions whose legal basis is doubtful.')
    OR (s.value = 3 AND s.text = 'Courts should not favor either side. When the law is unclear, neither the government nor the individual gets the benefit of the doubt.')
    OR (s.value = 4 AND s.text = 'When the law is unclear, courts should lean toward the government and uphold its decision unless it clearly broke the law.')
    OR (s.value = 5 AND s.text = 'Courts should defer to elected officials and agencies almost entirely, overturning a decision only for a plain and serious violation of the law.'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0081 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No old wording leaked into the new revision.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%level the playing field%' OR s.text ILIKE '%lawyers, money%'
               OR s.text ILIKE '%second-guess them constantly%' OR s.text ILIKE '%deserve respect%'
               OR s.text ILIKE '%almost always%')) THEN
    RAISE EXCEPTION 'CA_0081 verify: new rev still carries old chair wording';
  END IF;
  IF v_stem ILIKE '%clash%' OR v_stem ILIKE '%benefit of the doubt%' THEN
    RAISE EXCEPTION 'CA_0081 verify: new question still carries old wording';
  END IF;

  -- v1 still the published/current revision, and exactly one such.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0081 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0081 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0081 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0081 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

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
    RAISE EXCEPTION 'CA_0081 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0081 post-verify OK: re-axis rev 2/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. WHOLE-SET 22-row re-audit (7/9/4/1/1) deferred before Season 2 opens.';
END $$;

COMMIT;
