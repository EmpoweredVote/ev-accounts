BEGIN;

-- =============================================================================
-- CA_0071: Deportation Priorities (deportation) — reword the question onto the
--          real axis, normalise the referent across all five chairs, split the
--          chair 4/5 boundary off "how fast" and onto a real policy fork,
--          approve the new revision, and pin it into Season 2 (a DRAFT; NOT open).
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC 44905f3b-… ('deportation', "Deportation Priorities"). Scope: federal +
--   state (both required). 1,359 seated rows on the open Season-1 v1 today
--   (171/540/120/415/113 at chairs 1/2/3/4/5). Reviewed 2026-08-31 under the
--   single-revision ("unchanged") review pass.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (becomes rev 2 / version 2) with the
--      reviewed question + five chairs.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, 673c3758-…) to the new
--      revision. Season 1 (open) is left on v1.
--
-- THE FIVE CHECKS THAT DROVE THE EDIT (review 2026-08-31, Chris Andrews):
--   • The ladder is ONE axis — breadth of removal, from "deport no one" to "deport
--     everyone". "how aggressively" in the old question named a second dimension the
--     chairs never measured (it survived only as flavour words in old chairs 4-5).
--     New question states the real axis plainly and neutrally.
--   • Old chairs 4 and 5 shared the SAME endpoint ("deport everyone undocumented")
--     and differed only by SPEED / sequencing ("criminals first" vs "move quickly").
--     That is a strength rating, not a distinct position: a source saying "deport all
--     undocumented immigrants" could not be sorted between them, and a mass-deportation
--     supporter was describable as both at once (fails exclusivity + evidence-able).
--     New chair 5 re-cuts the top rung onto a real policy fork: chair 4 = comprehensive
--     but PRIORITISED / routine enforcement (criminals first); chair 5 = a deliberate
--     MASS-DEPORTATION PROGRAM that removes even long-settled families. That fork a
--     source can state.
--   • Referent was inconsistent across chairs ("undocumented residents" / "people" /
--     "recent arrivals" / "long-term residents" / "everyone without legal status").
--     Normalised to "undocumented immigrants" throughout so each chair is clear and
--     self-contained where it renders without the question (profile spokes, citations).
--
--   CURRENT -> NEW (value : text):
--     Q : "Who should be deported, and how aggressively?"
--       -> "How far should the government go in deporting undocumented immigrants?"
--     1 : "Stop deportations entirely and protect undocumented residents from removal"
--       -> "Stop deportations entirely and protect undocumented immigrants from removal"
--     2 : "Only deport people convicted of serious violent crimes"
--       -> "Only deport undocumented immigrants convicted of serious violent crimes"
--     3 : "Focus deportation on recent arrivals while leaving long-term residents in place"
--       -> "Focus deportation on recent arrivals while leaving long-settled undocumented immigrants in place"
--     4 : "Deport everyone without legal status, starting with those who have criminal records"
--       -> "Deport all undocumented immigrants, starting with those who have criminal records"
--     5 : "Move quickly to deport all undocumented people regardless of how long they've lived here or family ties"
--       -> "Carry out a mass-deportation program to remove all undocumented immigrants, including long-settled families and workers"
--
-- CLASS: substantive -> version 2. rung_map is identity {1:1,2:2,3:3,4:4,5:5}: the
--   five positions stay in place (protect-all at 1, mass-removal at 5); chair 5 is
--   reworded in place, it does not move rung.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠
--   This is NOT a whole-set re-audit. Chairs 1-4 changed only their WORDING, not their
--   meaning (referent normalisation on 1-3; "everyone without legal status" = "all
--   undocumented immigrants" on 4). Those edits are CLARIFYING — same position, clearer
--   words — so their seats (171/540/120/415) carry forward with NO re-audit, per the
--   2026-08-28 rewording ruling.
--   Only CHAIR 5's meaning moved (from "everyone, fast" to "a deliberate mass-deportation
--   program including long-settled families"), so its 113 seated rows are the re-audit
--   scope:
--     • keyword scan of the 113 chair-5 reasonings (avg 333 chars, all present):
--       64 carry mass/all/no-exception language (likely confirm at 5), ~10 read
--       criminal-first only (likely drop to chair 4), ~39 generic (need a read).
--     • PLUS a light scan of chair 4 for mass-program-including-settled supporters who
--       should migrate UP to 5: ~12 clear candidates (of 415; the other 110 that say
--       "all" also say "criminals first" and stay at 4).
--   Do NOT open Season 2 on this revision until that ~113-row pass (+ ~12-row chair-4
--   scan) is done. That is a SEPARATE, approved migration against politician_answers.
--   (Per-stance description/supporting_points live in the FROZEN legacy compass_stances
--   copy (CA_0012), 0 source reads; the voter-facing revision is text-only, nothing to
--   restore here. The legacy chair-5 description now mismatches the new wording but is
--   dormant — leave it.)
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2
--   is a draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps
--   serving v1 via the version mechanic (it pins version 1; approving a version-2
--   revision does not change what version 1 resolves to). No answer rows are touched.
--   NOTE: because the CLARIFYING referent fixes on chairs 1-4 are bundled into this
--   version-2 revision, they reach voters only when Season 2 opens — Season 1 keeps the
--   old wording. That is intended (this is Season-2 prep); if the referent fix is wanted
--   live in Season 1 too, that needs a separate clarifying v1 revision.
--
-- Idempotent: re-running after success is a no-op (the revision already exists/approved;
--   Season 2 already pins it).
-- Model: CA_0070 (propose substantive + approve + pin S2), CA_0063 (approve v2 + pin S2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := '44905f3b-e105-4f6c-afc7-5d223813dbac';               -- deportation
  v_topickey CONSTANT text := 'deportation';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := '673c3758-448d-46ce-ab09-5869488a131f';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'How far should the government go in deporting undocumented immigrants?';
  v_chair5   CONSTANT text := 'Carry out a mass-deportation program to remove all undocumented immigrants, including long-settled families and workers';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Stop deportations entirely and protect undocumented immigrants from removal'),
    jsonb_build_object('value',2,'text','Only deport undocumented immigrants convicted of serious violent crimes'),
    jsonb_build_object('value',3,'text','Focus deportation on recent arrivals while leaving long-settled undocumented immigrants in place'),
    jsonb_build_object('value',4,'text','Deport all undocumented immigrants, starting with those who have criminal records'),
    jsonb_build_object('value',5,'text','Carry out a mass-deportation program to remove all undocumented immigrants, including long-settled families and workers')
  );
  v_new      uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0071: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0071: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0071: Season 2 is not a draft (pin would be frozen)';
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
      'Deportation Priorities', 'Deportation',
      v_stem, v_stances,
      -- rationale
      'Single-revision review 2026-08-31 (Chris Andrews). Three fixes: (1) the question named a '
      || 'second axis ("how aggressively") the chairs never measured, so it is restated onto the real '
      || 'axis — breadth of removal — neutrally. (2) Old chairs 4 and 5 shared one endpoint (deport all '
      || 'undocumented) and differed only by speed/sequencing, which is a rating not a position and broke '
      || 'exclusivity; chair 5 is re-cut onto a real fork — chair 4 = comprehensive-but-prioritised/routine '
      || 'enforcement, chair 5 = a deliberate mass-deportation program that removes even long-settled '
      || 'families. (3) The referent was normalised to "undocumented immigrants" across all five chairs. '
      || 'Substantive (version 2) because chair 5''s meaning moves. Chairs 1-4 changed WORDING only (referent '
      || 'normalisation; "everyone without legal status" = "all undocumented immigrants"), which is clarifying '
      || 'and carries their seats forward. Re-audit scope is therefore chair 5 only: 113 seated rows (+ a '
      || '~12-row chair-4 upward-migrant scan), owed before Season 2 opens. Approved + pinned to Season 2 only; '
      || 'Season 1 stays on v1.',
      -- public_note
      'Reworded the question and options so they measure one thing — how far removal should go — and split the '
      || 'two toughest options onto a real difference (enforce the law prioritising criminals, vs a mass-deportation '
      || 'program that removes even long-settled families) instead of just "how fast". Also names "undocumented '
      || 'immigrants" consistently in every option.',
      -- review_ref
      'Single-revision review 2026-08-31 (Chris Andrews), reviewunchangedtopicprompt.md deportation pass; '
      || 'seat distribution 171/540/120/415/113 at chairs 1-5.',
      v_rungmap);
    RAISE NOTICE 'CA_0071: proposed re-axis revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0071: re-axis revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0071: re-axis revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0071: re-axis revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0071: re-axis revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0071: Season 2 already pins the re-axis revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0071: Season 2 repinned % -> % (re-axis revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '44905f3b-e105-4f6c-afc7-5d223813dbac';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := '673c3758-448d-46ce-ab09-5869488a131f';
  v_stem     CONSTANT text := 'How far should the government go in deporting undocumented immigrants?';
  v_chair5   CONSTANT text := 'Carry out a mass-deportation program to remove all undocumented immigrants, including long-settled families and workers';
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
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0071 verify: re-axis revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0071 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0071 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0071 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 2 THEN RAISE EXCEPTION 'CA_0071 verify: new rev revision is % (expected 2)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0071 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0071 verify: new rev change_class is % (expected substantive)', v_class; END IF;

  -- Exactly five rungs, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0071 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'Stop deportations entirely and protect undocumented immigrants from removal')
    OR (s.value = 2 AND s.text = 'Only deport undocumented immigrants convicted of serious violent crimes')
    OR (s.value = 3 AND s.text = 'Focus deportation on recent arrivals while leaving long-settled undocumented immigrants in place')
    OR (s.value = 4 AND s.text = 'Deport all undocumented immigrants, starting with those who have criminal records')
    OR (s.value = 5 AND s.text = 'Carry out a mass-deportation program to remove all undocumented immigrants, including long-settled families and workers'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0071 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No old wording leaked into the new revision.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%move quickly%' OR s.text ILIKE '%without legal status%'
               OR s.text ILIKE '%undocumented residents%' OR s.text ILIKE '%people convicted%'
               OR s.text ILIKE '%long-term residents%')) THEN
    RAISE EXCEPTION 'CA_0071 verify: new rev still carries old chair wording';
  END IF;
  IF v_stem ILIKE '%how aggressively%' THEN
    RAISE EXCEPTION 'CA_0071 verify: new question still carries old "how aggressively" wording';
  END IF;

  -- v1 still the published/current revision, and exactly one such.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0071 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0071 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0071 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0071 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

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
    RAISE EXCEPTION 'CA_0071 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0071 post-verify OK: re-axis rev 2/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. 113-row chair-5 re-audit (+~12 chair-4 scan) deferred before Season 2 opens.';
END $$;

COMMIT;
