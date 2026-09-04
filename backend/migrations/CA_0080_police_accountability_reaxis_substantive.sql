BEGIN;

-- =============================================================================
-- CA_0080: Police Accountability (judicial-police-accountability) — re-axis all
--          five chairs onto ONE instrument-neutral "protect <-> hold-accountable"
--          orientation so a District Attorney (charge / decline) AND a City
--          Attorney (settle / defend) both seat honestly on the same rung;
--          reword the question; approve the new revision; pin it into Season 2
--          (a DRAFT; NOT open).
-- =============================================================================
-- Created 2026-09-01 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC 7bad33eb-… ('judicial-police-accountability', "Police Accountability").
--   Scope: judicial (one required level); judicial_role = city_attorney_da.
--   16 seated rows on the open Season-1 v1 today (3/5/5/3/0 at chairs 1/2/3/4/5).
--   Reviewed 2026-09-01 under the single-revision ("unchanged") review pass.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (becomes rev 2 / version 2) with the
--      reviewed question + five chairs.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, b188675d-…) to the new
--      revision. Season 1 (open, 2d5d67d1-…) is left on v1.
--
-- THE DEFECTS THAT DROVE THE EDIT (review 2026-09-01, Chris Andrews):
--   • OFFICE MISMATCH (the core defect). judicial_role = city_attorney_da bundles
--     two offices with DIFFERENT accountability levers. The v1 chairs 2-5 were
--     written as ONE office's instrument — civil-defense-counsel language ("settle
--     valid claims", "settlements invite lawsuits", "the client is the government")
--     — which only a City Attorney pulls. A DA / AG never settles a civil claim;
--     their police-accountability lever is CHARGE vs DECLINE to prosecute an
--     officer. Only v1 chair 1 fit them. The seated data proved the splice: DAs/AGs
--     (Hochman, Campbell) sat at chair 1; City Attorneys (Chiu, McIntosh, Feldstein
--     Soto, Ferbert) spread 2-4. Fix (CA_0070 move): rewrite every rung as an
--     instrument-neutral orientation both offices enact through their own lever, and
--     leave the lever implicit. Tested each new rung against a real position/campaign
--     line for BOTH a DA and a City Attorney.
--   • DOUBLE-BARREL. Old chair 2 welded "settle valid claims quickly" AND "pursue
--     real accountability" — separable actions; split away in the reworded rung.
--   • COLLAPSED TOP. Old chairs 4 and 5 both said "defend aggressively" and differed
--     only by framing (a rating, not a distinct position); chair 5 held 0 seats.
--     Re-cut into two distinct positions: chair 4 = lean toward defense (benefit of
--     the doubt, act only on clear wrongdoing); chair 5 = defense is the role
--     (stand behind employees rather than hold them accountable).
--   • SLOGANS removed; plain declarative wording throughout.
--
--   CURRENT -> NEW (value : text):
--     Q : "When government employees do wrong, does the office defend them or hold them accountable?"
--       -> "When a government employee is accused of misconduct, should the office defend them or hold them accountable?"
--     1 : "Investigate independently. The office works for the public — not the officials it's supposed to keep accountable."
--       -> "Actively hold government employees accountable when they do wrong, even when they are on the office's own side."
--     2 : "Settle valid claims quickly and pursue real accountability. Defending misconduct wastes money and public trust."
--       -> "Take misconduct complaints seriously, and act on the ones that hold up."
--     3 : "Represent the government fairly while acknowledging when claims have merit."
--       -> "Defend government employees when a complaint is weak, and hold them accountable when it has merit."
--     4 : "Defend government employees vigorously. That's the job. Settlements invite more lawsuits."
--       -> "Give government employees the benefit of the doubt, and act only when the wrongdoing is clear."
--     5 : "The client is the government. Defending its employees and decisions — aggressively when needed — is the core function."
--       -> "Stand behind government employees and defend their conduct rather than hold them accountable."
--
-- ORIENTATION: chair 1 = maximum accountability, chair 5 = maximum defense.
-- CLASS: substantive -> version 2. rung_map is identity {1:1,2:2,3:3,4:4,5:5}: the
--   five positions stay in place (accountability at 1, defense at 5); every rung is
--   reworded in place, none moves rung.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   This IS a WHOLE-SET re-audit (unlike CA_0071): all five rungs reframe from a
--   single-office instrument to a cross-office orientation, so every seat was
--   evidenced against wording that no longer exists. Scope = all 16 seated rows
--   (3/5/5/3/0). It is a direction-preserving VALIDATION, not fresh research:
--   accountability-side seats (chairs 1-2, 8 rows) stay accountability-side; the
--   middle (chair 3, 5 rows) stays middle; defense-side (chair 4, 3 rows) stays
--   defense-side. Real work is the 1<->2 boundary (pursue vs act-on-valid) and the
--   4<->5 boundary — the 3 current chair-4 rows sort between new 4 (benefit of the
--   doubt) and new 5 (defense is the role). Watch new chair 3 so it stays a genuine
--   both-ways centre, not an "equal justice" default.
--   Do NOT open Season 2 on this revision until that 16-row pass is done. That is a
--   SEPARATE, approved migration against politician_answers.
--   (Per-stance description/supporting_points live in the FROZEN legacy
--   compass_stances copy, 0 source reads; the voter-facing revision is text-only,
--   nothing to restore here.)
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season.
--   Season 2 is a draft, so this pin changes nothing a voter sees today; Season 1
--   (open) keeps serving v1 via the version mechanic (it pins version 1; approving a
--   version-2 revision does not change what version 1 resolves to). No answer rows
--   are touched.
--
-- Idempotent: re-running after success is a no-op (the revision already
--   exists/approved; Season 2 already pins it).
-- Model: CA_0071 (propose substantive + approve + pin S2), CA_0070 (judicial
--   orientation-rung re-axis).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := '7bad33eb-e93e-4d94-8822-97212d49bde5';               -- judicial-police-accountability
  v_topickey CONSTANT text := 'judicial-police-accountability';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := 'b188675d-8b8c-4767-b174-f4096094e720';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'When a government employee is accused of misconduct, should the office defend them or hold them accountable?';
  v_chair5   CONSTANT text := 'Stand behind government employees and defend their conduct rather than hold them accountable.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Actively hold government employees accountable when they do wrong, even when they are on the office''s own side.'),
    jsonb_build_object('value',2,'text','Take misconduct complaints seriously, and act on the ones that hold up.'),
    jsonb_build_object('value',3,'text','Defend government employees when a complaint is weak, and hold them accountable when it has merit.'),
    jsonb_build_object('value',4,'text','Give government employees the benefit of the doubt, and act only when the wrongdoing is clear.'),
    jsonb_build_object('value',5,'text','Stand behind government employees and defend their conduct rather than hold them accountable.')
  );
  v_new      uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0080: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0080: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0080: Season 2 is not a draft (pin would be frozen)';
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
      'Police Accountability', 'Police Accountability',
      v_stem, v_stances,
      -- rationale
      'Single-revision review 2026-09-01 (Chris Andrews). Core defect: judicial_role = city_attorney_da '
      || 'bundles two offices with different accountability levers, but v1 chairs 2-5 were written as one '
      || 'office''s instrument — civil-defense-counsel language ("settle valid claims", "settlements invite '
      || 'lawsuits", "the client is the government") that only a City Attorney pulls. A DA/AG never settles a '
      || 'civil claim; their lever is charge vs decline to prosecute an officer, and only v1 chair 1 fit them '
      || '(the seated data confirmed: DAs/AGs at chair 1, City Attorneys spread 2-4). Fix (CA_0070 move): all '
      || 'five rungs re-axed onto one instrument-neutral protect<->hold-accountable orientation both offices '
      || 'enact through their own lever, lever left implicit. Also de-barreled old chair 2 (welded settle + '
      || 'pursue accountability) and split the collapsed old chairs 4/5 (both "defend aggressively", chair 5 '
      || 'held 0 seats) into two distinct positions. Slogans removed. Substantive (version 2) because every '
      || 'rung''s meaning is reframed. rung_map identity; orientation chair 1 = maximum accountability, chair 5 '
      || '= maximum defense. Whole-set re-audit owed before Season 2 opens: all 16 seated rows '
      || '(3/5/5/3/0), a direction-preserving validation. Approved + pinned to Season 2 only; Season 1 stays on v1.',
      -- public_note
      'Rewrote the question and options so they measure one thing — whether the office defends government '
      || 'employees or holds them accountable — in plain language that fits both a District Attorney (who can '
      || 'charge or decline) and a City Attorney (who can settle or defend). Split the two "defend" options into '
      || 'genuinely different positions and removed slogans.',
      -- review_ref
      'Single-revision review 2026-09-01 (Chris Andrews), reviewunchangedtopicprompt.md '
      || 'judicial-police-accountability pass; seat distribution 3/5/5/3/0 at chairs 1-5 (16 rows).',
      v_rungmap);
    RAISE NOTICE 'CA_0080: proposed re-axis revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0080: re-axis revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0080: re-axis revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0080: re-axis revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0080: re-axis revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0080: Season 2 already pins the re-axis revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0080: Season 2 repinned % -> % (re-axis revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '7bad33eb-e93e-4d94-8822-97212d49bde5';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := 'b188675d-8b8c-4767-b174-f4096094e720';
  v_stem     CONSTANT text := 'When a government employee is accused of misconduct, should the office defend them or hold them accountable?';
  v_chair5   CONSTANT text := 'Stand behind government employees and defend their conduct rather than hold them accountable.';
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
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0080 verify: re-axis revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0080 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0080 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0080 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 2 THEN RAISE EXCEPTION 'CA_0080 verify: new rev revision is % (expected 2)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0080 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0080 verify: new rev change_class is % (expected substantive)', v_class; END IF;

  -- Exactly five rungs, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0080 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'Actively hold government employees accountable when they do wrong, even when they are on the office''s own side.')
    OR (s.value = 2 AND s.text = 'Take misconduct complaints seriously, and act on the ones that hold up.')
    OR (s.value = 3 AND s.text = 'Defend government employees when a complaint is weak, and hold them accountable when it has merit.')
    OR (s.value = 4 AND s.text = 'Give government employees the benefit of the doubt, and act only when the wrongdoing is clear.')
    OR (s.value = 5 AND s.text = 'Stand behind government employees and defend their conduct rather than hold them accountable.'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0080 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No old wording leaked into the new revision.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%investigate independently%' OR s.text ILIKE '%settle valid claims%'
               OR s.text ILIKE '%the client is the government%' OR s.text ILIKE '%settlements invite%'
               OR s.text ILIKE '%represent the government fairly%')) THEN
    RAISE EXCEPTION 'CA_0080 verify: new rev still carries old chair wording';
  END IF;
  IF v_stem ILIKE '%do wrong%' THEN
    RAISE EXCEPTION 'CA_0080 verify: new question still carries old "do wrong" wording';
  END IF;

  -- v1 still the published/current revision, and exactly one such.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0080 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0080 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0080 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0080 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

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
    RAISE EXCEPTION 'CA_0080 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0080 post-verify OK: re-axis rev 2/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. 16-row whole-set direction-preserving re-audit deferred before Season 2 opens.';
END $$;

COMMIT;
