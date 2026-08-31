BEGIN;

-- =============================================================================
-- CA_0070: Criminal Justice Approach (judicial-criminal-justice) — reject the
--          mechanism rework, replace it with a single-axis orientation ladder,
--          approve it, and pin it into Season 2 (Season 2 is a draft; NOT opened)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC 9db07b16-… ('judicial-criminal-justice'). Scoped to federal + state +
--   judicial (the only judicial-* topic opened past judges). All ~250 seatings
--   today are legislators, prosecutors and executives; zero judges — but the
--   ladder is KEPT judicial-valid on purpose (see WHY ORIENTATION below).
--
-- WHAT THIS DOES — four metadata steps, no answer/context rows written:
--   1. REJECT the open mechanism draft (rev 2 / version 2, id 7fcb6b78-…).
--   2. PROPOSE a new substantive revision (becomes rev 3 / version 2) whose five
--      rungs sit on ONE support->punishment axis.
--   3. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   4. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, bebe2e98-…) to the new
--      revision. Season 1 (open) is left on v1.
--
-- WHY THE MECHANISM DRAFT WAS REJECTED (rev 2).  Rev 2 reworded chairs 4-5 into
--   MECHANISMS ("penalties fixed and known in advance"; "matching punishment to
--   seriousness") while chairs 1-3 stayed PURPOSES ("helping the person change";
--   "make things right"). A goal and a mechanism are different kinds of claim, so
--   a voter can hold one of each at once — the "fixed penalties" chair (4) did not
--   exclude the "help them change" chair (1). That breaks single-select: a chair
--   is one voter-facing position, and no one may sit in two. Rev 2 is rejected and
--   RETAINED as the record of what was refused (CA_0016 keeps the reject in the
--   revision history; the next propose numbers past it).
--
-- THE NEW LADDER (reviewed 2026-08-31, Chris Andrews) — question restated so all
--   five rungs answer the SAME thing (how the response should lean), and the goal
--   ("why") is factored out so it cannot form a second, overlapping chair:
--     Q: "When someone breaks the law, how should the system respond?"
--     1 Focus on support and treatment, not punishment.
--     2 Give the person a chance to make things right through service or restitution, rarely punishment.
--     3 Each situation is different — some people need support, some need consequences.
--     4 Breaking the law needs to have real consequences — accountability is the priority.
--     5 Impose the toughest penalties the law allows.
--   One axis (support -> punishment), five distinct convictions about the ROLE of
--   punishment: reject it (1) / rare, last resort (2) / depends (3) / it must
--   always follow (4) / make it the harshest (5). The "tough love" voter who
--   believes punishment changes people rejects 1 ("not punishment") and 2 ("rarely
--   punishment") and lands at 4 or 5 — one person, one chair.
--
-- WHY ORIENTATION, NOT MECHANISM (keeps judicial scope valid).  Every rung is a
--   SENTENCING ORIENTATION, not a legislative instrument. A judge acts on it
--   through sentencing discretion (diversion/treatment at the low end; top-of-range,
--   "the toughest penalties the law allows" at 5), a legislator through the laws
--   they write, a prosecutor through charging. Rev 2's "mandatory minimums / fixed
--   penalties" were legislature-only levers a judge cannot pull; this ladder names
--   none, so it is valid across all three scopes with one wording. It also avoids
--   the deterrence-vs-retribution PURPOSES the WA sweep flagged as unevidenceable
--   (statutes state mechanisms and orientation, not motive).
--
-- CLASS: substantive -> version 2. rung_map is identity {1:1,2:2,3:3,4:4,5:5}:
--   the five positions stay in place (support end low, punitive end high); only the
--   wording frame moved.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   Because ALL five rungs were reframed from goal to response, every seated row was
--   evidenced against wording that no longer stands, so the WHOLE seated set is in
--   scope: ~250 rows (Season 1, v1) — value distribution 66 / 112 / 34 / 46 / 32 at
--   chairs 1/2/3/4/5. BUT the axis DIRECTION is preserved (lenient stays lenient,
--   harsh stays harsh), so this is a VALIDATION pass, not fresh research: most rows
--   confirm in place, and the real work is at the 1<->2 (treatment vs make-amends)
--   and 4<->5 (real-consequences vs harshest) boundaries, plus the ~5 old chair-4
--   rows seated purely on "deterrence"/"think twice", which that concept no longer
--   names. Do NOT open Season 2 on this revision until that pass is done.
--   (per-stance description / supporting_points / example_perspectives were empty on
--   both v1 and the rejected rev 2 — nothing to restore; the new rungs are text-only.)
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season.
--   Season 2 is a draft, so this pin changes nothing a voter sees today; Season 1
--   (open) keeps serving v1 via the version mechanic (it pins version 1; approving a
--   version-2 revision does not change what version 1 resolves to). No answer rows
--   are touched.
--
-- Idempotent: re-running after success is a no-op (rev 2 already rejected; the
--   orientation revision already exists/approved; Season 2 already pins it).
-- Models: CA_0063 (approve v2 + pin S2), CA_0016 (propose numbering past a reject).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := '9db07b16-1076-4b7d-ad89-ebe7b51f4336';               -- judicial-criminal-justice
  v_topickey CONSTANT text := 'judicial-criminal-justice';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := 'bebe2e98-f513-4353-baab-09fd92c899d2';               -- v1 (rev 1, published/current)
  v_rev2     CONSTANT uuid := '7fcb6b78-7075-4b2f-a804-8a6d5f27058b';               -- v2 (rev 2, mechanism draft to reject)
  v_stem     CONSTANT text := 'When someone breaks the law, how should the system respond?';
  v_chair1   CONSTANT text := 'Focus on support and treatment, not punishment.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Focus on support and treatment, not punishment.'),
    jsonb_build_object('value',2,'text','Give the person a chance to make things right through service or restitution, rarely punishment.'),
    jsonb_build_object('value',3,'text','Each situation is different — some people need support, some need consequences.'),
    jsonb_build_object('value',4,'text','Breaking the law needs to have real consequences — accountability is the priority.'),
    jsonb_build_object('value',5,'text','Impose the toughest penalties the law allows.')
  );
  v_rev2stat text;
  v_new      uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0070: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0070: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0070: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Step 1: reject the mechanism draft rev 2 (draft -> rejected). Idempotent. ---
  SELECT status INTO v_rev2stat FROM inform.compass_topic_revisions WHERE id = v_rev2 AND topic_id = v_topic;
  IF v_rev2stat IS NULL THEN
    RAISE EXCEPTION 'CA_0070: mechanism draft rev 2 % not found', v_rev2;
  ELSIF v_rev2stat = 'draft' THEN
    PERFORM inform.admin_reject_topic_revision(v_rev2, v_actor,
      'Superseded by CA_0070: the mechanism rework (chairs 4-5 fixed-penalties / proportionality) '
      || 'mixed mechanism-chairs with purpose-chairs 1-3 and broke single-select exclusivity. '
      || 'Replaced by a single support-to-punishment orientation ladder.');
    RAISE NOTICE 'CA_0070: rev 2 rejected (draft -> rejected).';
  ELSIF v_rev2stat = 'rejected' THEN
    RAISE NOTICE 'CA_0070: rev 2 already rejected; skipping reject.';
  ELSE
    RAISE EXCEPTION 'CA_0070: rev 2 in unexpected status % (expected draft or rejected)', v_rev2stat;
  END IF;

  -- Step 2: find-or-create the orientation revision (rev 3 / v2). Idempotent. ---
  SELECT r.id INTO v_new
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND r.status IN ('draft','approved')
    AND r.question_text = v_stem
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 1 AND s.text = v_chair1);
  IF v_new IS NULL THEN
    v_new := inform.admin_propose_topic_revision(
      v_topickey, v_actor, 'substantive',
      'Criminal Justice Approach', 'Criminal Justice',
      v_stem, v_stances,
      -- rationale
      'Single-axis reauthor (2026-08-31, Chris Andrews). The prior mechanism draft (rev 2) broke '
      || 'single-select exclusivity: chairs 4-5 described mechanisms while chairs 1-3 described purposes, '
      || 'so a voter could sit in a goal-chair and a mechanism-chair at once. This ladder puts all five '
      || 'rungs on one support-to-punishment axis (reject punishment / rare / depends / consequences first / '
      || 'harshest), so one person sits in exactly one chair. Kept judicial-valid: every rung is a sentencing '
      || 'orientation a judge (discretion), legislator (law) and prosecutor (charging) can each act on — no '
      || 'legislature-only instruments. Substantive (version 2): all five rungs reframed goal->response, so a '
      || 'direction-preserving VALIDATION re-audit of the ~250 seated rows (66/112/34/46/32 at chairs 1-5) is '
      || 'owed before Season 2 opens. Approved + pinned to Season 2 only; Season 1 stays on v1.',
      -- public_note
      'Reworded the five options onto one clear scale — from focusing on support and treatment to imposing '
      || 'the toughest penalties the law allows — so each option is a distinct position and no one fits two at once.',
      -- review_ref
      'Exclusivity redesign 2026-08-31 (Chris Andrews); origin diagnostic: Five Broken Chairs (WA sweep), '
      || 'backend/data/stance-research/COMPASS-LADDER-TROUBLE-SPOTS.md',
      v_rungmap);
    RAISE NOTICE 'CA_0070: proposed orientation revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0070: orientation revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 3: approve (draft -> approved), NOT published. Idempotent. -------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0070: orientation revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0070: orientation revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0070: orientation revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 4: pin Season 2 v1 -> new revision. Idempotent. -----------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0070: Season 2 already pins the orientation revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0070: Season 2 repinned % -> % (orientation revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := 'bebe2e98-f513-4353-baab-09fd92c899d2';
  v_rev2     CONSTANT uuid := '7fcb6b78-7075-4b2f-a804-8a6d5f27058b';
  v_stem     CONSTANT text := 'When someone breaks the law, how should the system respond?';
  v_chair1   CONSTANT text := 'Focus on support and treatment, not punishment.';
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
  v_r2stat   text;
BEGIN
  -- Rev 2 rejected & retained.
  SELECT status INTO v_r2stat FROM inform.compass_topic_revisions WHERE id = v_rev2;
  IF v_r2stat <> 'rejected' THEN RAISE EXCEPTION 'CA_0070 verify: rev 2 status is % (expected rejected)', v_r2stat; END IF;

  -- Locate the orientation revision by stem + chair-1 text.
  SELECT r.id, r.status, r.published_at, r.is_current, r.revision, r.version, r.change_class::text
    INTO v_new, v_status, v_pub, v_iscur, v_rev, v_ver, v_class
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic AND r.question_text = v_stem
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 1 AND s.text = v_chair1);
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0070 verify: orientation revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0070 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0070 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0070 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 3 THEN RAISE EXCEPTION 'CA_0070 verify: new rev revision is % (expected 3)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0070 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0070 verify: new rev change_class is % (expected substantive)', v_class; END IF;

  -- Exactly five rungs, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0070 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'Focus on support and treatment, not punishment.')
    OR (s.value = 2 AND s.text = 'Give the person a chance to make things right through service or restitution, rarely punishment.')
    OR (s.value = 3 AND s.text = 'Each situation is different — some people need support, some need consequences.')
    OR (s.value = 4 AND s.text = 'Breaking the law needs to have real consequences — accountability is the priority.')
    OR (s.value = 5 AND s.text = 'Impose the toughest penalties the law allows.'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0070 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No old wording leaked into the new revision (deterrence / retribution / mechanism / old stem).
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%think twice%' OR s.text ILIKE '%fixed and known%' OR s.text ILIKE '%how serious the act%')) THEN
    RAISE EXCEPTION 'CA_0070 verify: new rev still carries old chair-4/5 wording';
  END IF;

  -- v1 still the published/current revision.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0070 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0070 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0070 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0070 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

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
    RAISE EXCEPTION 'CA_0070 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0070 post-verify OK: rev 2 rejected; orientation rev 3/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. ~250-row validation re-audit deferred.';
END $$;

COMMIT;
