BEGIN;

-- =============================================================================
-- CA_0079: Judicial Interpretation (judicial-interpretation) — re-cut the five
--          chairs onto ONE clean evolve<->fixed interpretive axis, approve the
--          new revision, and pin it into Season 2 (a DRAFT; NOT open).
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- TOPIC 448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee ('judicial-interpretation',
--   "Judicial Interpretation"). Scope: judicial only (required, single level).
--   71 seated rows on the open Season-1 v1 today (10/19/4/8/30 at chairs 1/2/3/4/5).
--   Reviewed 2026-08-31 under the single-revision ("unchanged") review pass.
--
-- WHAT THIS DOES — three metadata steps, NO answer/context rows written:
--   1. PROPOSE a new substantive revision (becomes rev 2 / version 2) with the
--      SAME question and five re-cut chairs.
--   2. APPROVE it (draft -> approved). NOT published: a substantive rewrite goes
--      live only when its bound season opens, so is_current stays false and
--      published_at stays NULL.
--   3. PIN Season 2 (86d893a1-…, a DRAFT) from v1 (rev 1, a2b29729-…) to the new
--      revision. Season 1 (open, 2d5d67d1-…) is left on v1.
--
-- WHY SUBSTANTIVE (the review findings, 2026-08-31, Chris Andrews):
--   • Chair 1 was OFF-AXIS. Its text ("reconsider old rulings … keeping bad
--     precedent alive is its own injustice") measures stare decisis — willingness
--     to overturn precedent — NOT the text-vs-evolving-meaning axis the other four
--     chairs run on. Worse, on today's courts it is the ORIGINALISTS who overturn
--     precedent most aggressively, so the old chair-1 text was literally claimable
--     by the chair-4/5 pole. Re-cut onto the evolving-meaning end of the one axis.
--   • Chairs 3/4/5 read as a STRENGTH RATING of textualism (text + a little intent /
--     text + original intent for gaps / text only), not three source-checkable
--     postures. Re-cut into three distinct positions: text-first-with-purpose-as-
--     tiebreaker (3), fixed original meaning / no updating (4), strict text + defer
--     to the legislature (5).
--   • The five chairs are now five points on ONE axis: how much a judge lets legal
--     meaning evolve over time. Orientation is EXPLICIT — chair 1 = meaning evolves
--     most, chair 5 = meaning fixed at enactment.
--   • Question kept UNCHANGED — "Does the law change with the times, or does it mean
--     what it said when it was written?" already states that axis plainly and
--     neutrally, and is jurisdiction-neutral. Only the chairs move.
--
--   CURRENT -> NEW (value : text):
--     Q : (unchanged) "Does the law change with the times, or does it mean what it said when it was written?"
--     1 : "Courts should reconsider old rulings when we know more or society has changed. Keeping bad precedent alive is its own injustice."
--       -> "Judges should read the law in light of how society has changed, not only what it meant long ago."
--     2 : "Laws were written for a purpose. When the exact words don't fit a new situation, look at what the law was trying to accomplish."
--       -> "Judges should follow what the law was meant to achieve, even when the exact words don't fit a new situation."
--     3 : "Follow the text closely, but use some common sense about what lawmakers were trying to do."
--       -> "Start with what the law says; when the words are unclear, weigh what lawmakers were trying to do."
--     4 : "The law means what it says. Use original intent to fill gaps, but don't stretch the meaning."
--       -> "Stick to what the words meant when they were written; don't update them to fit new times."
--     5 : "A judge's job is to apply the law as written — not rewrite it. If society has changed, pass a new law. That's what elections are for."
--       -> "Judges should apply the law as written. If it needs to change, that is for elected lawmakers."
--
-- CLASS: substantive -> version 2. rung_map is identity {1:1,2:2,3:3,4:4,5:5}: the
--   five positions stay in place (most-evolving at 1, strict-textualist at 5); each
--   chair is reworded in place, none moves rung. Identity here is a SEAT-CARRY
--   convention for the deferred re-audit, NOT a claim that meaning is unchanged.
--
-- ⚠⚠ DEFERRED RE-AUDIT — OWED BEFORE SEASON 2 OPENS ⚠⚠  (WHOLE SET, like CA_0070)
--   This is a WHOLE-SET re-audit of all 71 seated rows (10/19/4/8/30), NOT a single
--   chair. Two reasons the whole set is in scope:
--     (a) chair 1's meaning MOVED (stare-decisis -> evolving-meaning) and chairs
--         3/4/5 were re-cut from a strength cluster into distinct postures, so no
--         seat's evidence can be assumed to still land on its rung; and
--     (b) POPULATION FINDING — 0 of the 71 seats is a judge. All are legislators /
--         executives / local officials (62 national, 2 state, 5 local, 3 no-office).
--         Judicial interpretation is a judge-only lever; for a non-judge it can only
--         be an OPINION, and the sampled evidence bears this out — it is proxy
--         evidence (judicial-nominee votes, Supreme-Court-expansion stances, praise
--         for liberal vs conservative justices), not the person's own interpretive
--         act. The re-audit must decide, per row, whether each non-judge seat is
--         genuinely evidence-able on interpretation or should be blanked. (This is a
--         cluster-wide pattern: all eight judicial-* topics seat zero judges — worth
--         a separate cluster-level decision, out of scope for this topic's edit.)
--   Do NOT open Season 2 on this revision until that whole-set pass is done. It is a
--   SEPARATE, approved migration against inform.politician_answers, and THAT is where
--   audit-chair-evidence.mjs applies. (This migration sets chair TEXT only and seats
--   no one, so the chair-evidence gate is N/A here.)
--   Per-stance description/supporting_points live in the FROZEN legacy compass_stances
--   copy (0 source reads); the voter-facing revision is text-only, nothing to restore.
--
-- WHY SAFE NOW: a season's pinned wording is served only for the OPEN season. Season 2
--   is a draft, so this pin changes nothing a voter sees today; Season 1 (open) keeps
--   serving v1 via the version mechanic. No answer rows are touched.
--
-- Idempotent: re-running after success is a no-op (the revision already exists/approved;
--   Season 2 already pins it).
-- Model: CA_0071 / CA_0070 (propose substantive + approve + pin S2).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';               -- Chris Andrews
  v_topic    CONSTANT uuid := '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee';               -- judicial-interpretation
  v_topickey CONSTANT text := 'judicial-interpretation';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';               -- Season 2 (draft)
  v_rev1     CONSTANT uuid := 'a2b29729-189f-4ee3-bca6-dc0c7d4cb657';               -- v1 (rev 1, published/current)
  v_stem     CONSTANT text := 'Does the law change with the times, or does it mean what it said when it was written?';
  v_chair1   CONSTANT text := 'Judges should read the law in light of how society has changed, not only what it meant long ago.';
  v_rungmap  CONSTANT jsonb := '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb;
  v_stances  CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value',1,'text','Judges should read the law in light of how society has changed, not only what it meant long ago.'),
    jsonb_build_object('value',2,'text','Judges should follow what the law was meant to achieve, even when the exact words don''t fit a new situation.'),
    jsonb_build_object('value',3,'text','Start with what the law says; when the words are unclear, weigh what lawmakers were trying to do.'),
    jsonb_build_object('value',4,'text','Stick to what the words meant when they were written; don''t update them to fit new times.'),
    jsonb_build_object('value',5,'text','Judges should apply the law as written. If it needs to change, that is for elected lawmakers.')
  );
  v_new      uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- Preconditions -----------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = v_topickey) THEN
    RAISE EXCEPTION 'CA_0079: topic id/key mismatch for %', v_topickey;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND version = 1
                   AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0079: live v1 (rev 1) is not in the expected published/current state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0079: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- Step 1: find-or-create the re-axis revision (rev 2 / v2). Idempotent. --------
  -- Discriminator is the NEW chair-1 text (question is unchanged, so it cannot tell v1 from v2).
  SELECT r.id INTO v_new
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND r.change_class = 'substantive'
    AND r.version = 2
    AND r.status IN ('draft','approved')
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 1 AND s.text = v_chair1);
  IF v_new IS NULL THEN
    v_new := inform.admin_propose_topic_revision(
      v_topickey, v_actor, 'substantive',
      'Judicial Interpretation', 'Interpretation',
      v_stem, v_stances,
      -- rationale
      'Single-revision review 2026-08-31 (Chris Andrews). Re-cut the five chairs onto one clean '
      || 'evolve<->fixed interpretive axis. Chair 1 was OFF-AXIS: its text measured willingness to '
      || 'overturn precedent (stare decisis), not the text-vs-evolving-meaning axis, and was literally '
      || 'claimable by the originalist pole; re-cut onto the evolving-meaning end. Chairs 3/4/5 read as a '
      || 'strength rating of textualism, not three checkable postures; re-cut into text-first-with-purpose-'
      || 'as-tiebreaker (3), fixed original meaning / no updating (4), and strict text + defer to the '
      || 'legislature (5). Question kept unchanged — it already states the axis plainly and neutrally. '
      || 'Substantive (version 2) because chair meanings move (chair 1 leaves the precedent axis; 3/4/5 '
      || 'are re-cut). rung_map identity is a seat-carry convention: the whole 71-row set (10/19/4/8/30) is '
      || 'owed a re-audit before Season 2 opens. Population finding recorded for that re-audit: 0 of 71 seats '
      || 'is a judge — all are legislators/executives whose interpretive "philosophy" is evidenced only by '
      || 'proxy (nominee votes, court-expansion stances, praise for liberal vs conservative justices); the '
      || 're-audit must decide per row whether each non-judge seat is evidence-able or should be blanked. '
      || 'Approved + pinned to Season 2 only; Season 1 stays on v1.',
      -- public_note
      'Rewrote the five options so they measure one thing — how much a judge should let the law''s meaning '
      || 'change over time, from reading it in light of how society has changed, through following what a law '
      || 'was meant to achieve, to sticking strictly to the words and leaving any change to elected lawmakers. '
      || 'The question is unchanged.',
      -- review_ref
      'Single-revision review 2026-08-31 (Chris Andrews), reviewunchangedtopicprompt.md judicial-interpretation '
      || 'pass; seat distribution 10/19/4/8/30 at chairs 1-5; 0 judges seated (population finding).',
      v_rungmap);
    RAISE NOTICE 'CA_0079: proposed re-axis revision %', v_new;
  ELSE
    RAISE NOTICE 'CA_0079: re-axis revision already exists (%); skipping propose.', v_new;
  END IF;

  -- Step 2: approve (draft -> approved), NOT published. Idempotent. --------------
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_new;
  IF v_status = 'draft' THEN
    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);
    RAISE NOTICE 'CA_0079: re-axis revision approved (not published).';
  ELSIF v_status = 'approved' THEN
    RAISE NOTICE 'CA_0079: re-axis revision already approved; skipping approve.';
  ELSE
    RAISE EXCEPTION 'CA_0079: re-axis revision in unexpected status % (expected draft or approved)', v_status;
  END IF;

  -- Step 3: pin Season 2 v1 -> new revision. Idempotent. ------------------------
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new THEN
    RAISE NOTICE 'CA_0079: Season 2 already pins the re-axis revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new, v_actor);
    RAISE NOTICE 'CA_0079: Season 2 repinned % -> % (re-axis revision)', v_cur, v_new;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee';
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_rev1     CONSTANT uuid := 'a2b29729-189f-4ee3-bca6-dc0c7d4cb657';
  v_stem     CONSTANT text := 'Does the law change with the times, or does it mean what it said when it was written?';
  v_chair1   CONSTANT text := 'Judges should read the law in light of how society has changed, not only what it meant long ago.';
  v_new      uuid;
  v_status   text;
  v_pub      timestamptz;
  v_iscur    boolean;
  v_rev      int;
  v_ver      int;
  v_class    text;
  v_qtext    text;
  v_n        int;
  v_v1cur    boolean;
  v_v1stat   text;
  v_pin      uuid;
  v_openver  int;
BEGIN
  -- Locate the re-axis revision by the NEW chair-1 text (question is unchanged).
  SELECT r.id, r.status, r.published_at, r.is_current, r.revision, r.version, r.change_class::text, r.question_text
    INTO v_new, v_status, v_pub, v_iscur, v_rev, v_ver, v_class, v_qtext
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic
    AND EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                WHERE s.topic_revision_id = r.id AND s.value = 1 AND s.text = v_chair1);
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0079 verify: re-axis revision not found'; END IF;

  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0079 verify: new rev status is % (expected approved)', v_status; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0079 verify: new rev has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0079 verify: new rev is_current is true (must stay false until Season 2 opens)'; END IF;
  IF v_rev <> 2 THEN RAISE EXCEPTION 'CA_0079 verify: new rev revision is % (expected 2)', v_rev; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0079 verify: new rev version is % (expected 2)', v_ver; END IF;
  IF v_class <> 'substantive' THEN RAISE EXCEPTION 'CA_0079 verify: new rev change_class is % (expected substantive)', v_class; END IF;
  IF v_qtext <> v_stem THEN RAISE EXCEPTION 'CA_0079 verify: new rev question_text changed (expected unchanged stem)'; END IF;

  -- Exactly five rungs, all carrying the reviewed NEW text.
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0079 verify: new rev has % rungs (expected 5)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new AND (
       (s.value = 1 AND s.text = 'Judges should read the law in light of how society has changed, not only what it meant long ago.')
    OR (s.value = 2 AND s.text = 'Judges should follow what the law was meant to achieve, even when the exact words don''t fit a new situation.')
    OR (s.value = 3 AND s.text = 'Start with what the law says; when the words are unclear, weigh what lawmakers were trying to do.')
    OR (s.value = 4 AND s.text = 'Stick to what the words meant when they were written; don''t update them to fit new times.')
    OR (s.value = 5 AND s.text = 'Judges should apply the law as written. If it needs to change, that is for elected lawmakers.'));
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0079 verify: new rev rungs do not all match the reviewed wording (matched %)', v_n; END IF;

  -- No old chair wording leaked into the new revision.
  IF EXISTS (SELECT 1 FROM inform.compass_stance_revisions s WHERE s.topic_revision_id = v_new
             AND (s.text ILIKE '%precedent%' OR s.text ILIKE '%common sense%'
               OR s.text ILIKE '%original intent%' OR s.text ILIKE '%elections are for%'
               OR s.text ILIKE '%means what it says%')) THEN
    RAISE EXCEPTION 'CA_0079 verify: new rev still carries old chair wording';
  END IF;

  -- v1 still the published/current revision, and exactly one such.
  SELECT is_current, status INTO v_v1cur, v_v1stat FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_v1cur THEN RAISE EXCEPTION 'CA_0079 verify: v1 is no longer is_current'; END IF;
  IF v_v1stat <> 'published' THEN RAISE EXCEPTION 'CA_0079 verify: v1 status is % (expected published)', v_v1stat; END IF;
  IF (SELECT count(*) FROM inform.compass_topic_revisions
       WHERE topic_id = v_topic AND is_current = true AND status = 'published') <> 1 THEN
    RAISE EXCEPTION 'CA_0079 verify: expected exactly 1 published/current revision (still v1)';
  END IF;

  -- Season 2 pins the new revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin <> v_new THEN RAISE EXCEPTION 'CA_0079 verify: Season 2 pin is % (expected new rev %)', v_pin, v_new; END IF;

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
    RAISE EXCEPTION 'CA_0079 verify: open season resolves version % (expected 1)', v_openver;
  END IF;

  RAISE NOTICE 'CA_0079 post-verify OK: re-axis rev 2/v2 approved (unpublished); Season 2 pins it; Season 1 still serves v1. WHOLE-SET 71-row re-audit (0 judges seated) deferred before Season 2 opens.';
END $$;

COMMIT;
