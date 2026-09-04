BEGIN;

-- =============================================================================
-- CA_0058: Misinformation — re-author the ladder onto one content axis, rename
--          the topic, stage into Season 2 (draft; not opened)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote). Topic ddd65d64 (topic_key 'misinformation').
--
-- BACKGROUND — the defect this fixes.
--   The live revision (rev 1) carried two double-barreled chairs:
--     1: require platforms to remove all false information AND regulate algorithms
--     2: mandate fact-checking AND transparency in how algorithms promote content
--   A prior draft (rev 2, 25d14768) split them but kept the WRONG barrel in chair 2:
--   it retained "algorithmic transparency" (off-axis — a rule about the ALGORITHM) and
--   dropped "fact-checking" (on-axis — an action on CONTENT). That left chair 2 measuring
--   a different object than chairs 1/3/4/5, which all act on content. See CLAUDE.md
--   "Compass chairs are five distinct stances" / design principle #1 (one axis only).
--
-- WHAT THIS MIGRATION DOES.
--   1. REJECT draft rev 2 (one open revision per topic; the immutability trigger blocks
--      in-place edits, so a re-author is reject + fresh propose).
--   2. PROPOSE a fresh SUBSTANTIVE revision (becomes revision 3, version 2) that puts the
--      whole ladder on one content axis and renames the topic:
--        title      'Misinformation and the Role of Algorithms in Democracy'
--                -> 'Online Misinformation and Content Moderation'
--        short_title 'Misinformation'  (UNCHANGED — freezes topic_key 'misinformation',
--                                       on which essentials.quotes joins)
--        1: legally require platforms to remove false information
--        2: require platforms to label false content, rather than remove it   <-- new on-axis rung
--        3: encourage voluntary standards for combating misinformation online (unchanged)
--        4: protect free speech online and prevent government censorship        (unchanged)
--        5: ban any government involvement in content moderation decisions      (unchanged)
--      Single axis = how far government compels platforms to counter false CONTENT:
--        remove (1) > label (2) > voluntary (3) > protect speech (4) > no role (5).
--      Chair 2's "rather than remove it" contrast is deliberate: it names the stronger
--      option (removal) and declines it, so a reader who wants removal is pushed up to
--      chair 1 instead of parking at chair 2. Identity rung_map {1:1..5:5}: the five rungs
--      keep their positions and ordinal meaning; only wording changes.
--   3. APPROVE it — NOT published. A substantive/major rewrite goes live only when its
--      bound season opens, never by a direct publish.
--   4. REPIN Season 2's misinformation question from rev 1 -> the new revision. Season 2
--      is a DRAFT and is NOT opened here.
--
-- WHY SUBSTANTIVE (not clarifying). Of the 144 chair-2 seatings, ~64 were seated on pure
--   algorithm-transparency evidence (e.g. SB 1018 Platform Accountability & Transparency
--   Act, AB 886, kids-algorithm-addiction bills) that no longer fits a content-labeling
--   rung. Those rows need RE-AUDIT against the new wording before Season 2 carries them.
--   Chairs 1 and 2 also lost barrels (removal-only; label-only). Version bumps to 2, so the
--   new wording is invisible to voters until Season 2 opens.  <-- FOLLOW-UP OWED, separate
--   stance pass; this migration writes NO politician_answers / politician_context.
--
-- WHY SAFE NOW. A season's pinned wording is served only for the OPEN season
--   (compassService.getPromotedTopics joins seasons status='open'). Season 2 is draft, so
--   this pin changes nothing a voter sees today; Season 1 keeps serving rev 1 (version 1).
--
-- GATES. audit-chair-evidence is N/A here (no chair is SET — no answer writes; it is a
--   reword + metadata migration). The chair-evidence gate applies to the downstream
--   re-audit pass that re-seats rows. No answer deletes, so the answer-delete guard is N/A.
--
-- Idempotent: a re-run after success is a no-op (rev 2 already rejected; the reworked
-- revision already approved; Season 2 already pinned to it).
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic    CONSTANT uuid := 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'; -- misinformation
  v_rev1     CONSTANT uuid := '6fa8a338-153a-430d-bc44-e985b44a357c'; -- current published v1
  v_rev2     CONSTANT uuid := '25d14768-2f1c-4793-b599-0c53339e0985'; -- draft to reject
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'; -- Season 2 (draft)
  v_new_title CONSTANT text := 'Online Misinformation and Content Moderation';
  v_new_id   uuid;
  v_status   text;
  v_cur      uuid;
BEGIN
  -- ---- Preconditions ----
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = v_topic AND topic_key = 'misinformation') THEN
    RAISE EXCEPTION 'CA_0058: misinformation topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = v_rev1 AND topic_id = v_topic AND revision = 1 AND is_current) THEN
    RAISE EXCEPTION 'CA_0058: rev1 is not the current revision';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season2 AND number = 2 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0058: Season 2 is not a draft (pin would be frozen)';
  END IF;

  -- ---- Idempotency: has the reworked revision already been created + approved? ----
  SELECT id INTO v_new_id
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND version = 2 AND change_class = 'substantive'
     AND title = v_new_title AND status IN ('approved', 'published', 'superseded');

  IF v_new_id IS NOT NULL THEN
    RAISE NOTICE 'CA_0058: reworked revision already present (%); skipping reject/propose/approve.', v_new_id;
  ELSE
    -- Step 1: reject draft rev2 (idempotent).
    SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_rev2;
    IF v_status = 'draft' THEN
      PERFORM inform.admin_reject_topic_revision(
        v_rev2, v_actor,
        'Superseded by CA_0058: the rev2 split kept the off-axis algorithmic-transparency '
        || 'barrel in chair 2 and dropped the on-axis fact-checking barrel. Re-authored so '
        || 'chair 2 is an on-axis content-labeling rung and the topic is renamed.');
      RAISE NOTICE 'CA_0058: rejected draft rev2 %', v_rev2;
    ELSIF v_status = 'rejected' THEN
      RAISE NOTICE 'CA_0058: rev2 already rejected; skipping reject.';
    ELSE
      RAISE EXCEPTION 'CA_0058: rev2 in unexpected status % (expected draft or rejected)', v_status;
    END IF;

    -- Step 2: propose the reworked substantive revision (rev3, version2).
    v_new_id := inform.admin_propose_topic_revision(
      'misinformation',
      v_actor,
      'substantive',
      v_new_title,
      'Misinformation',                                                       -- short_title unchanged -> topic_key frozen
      'What responsibility do platforms and government have in combating online misinformation?',
      $stances$[
        {"value":1,"text":"legally require platforms to remove false information"},
        {"value":2,"text":"require platforms to label false content, rather than remove it"},
        {"value":3,"text":"encourage voluntary standards for combating misinformation online"},
        {"value":4,"text":"protect free speech online and prevent government censorship"},
        {"value":5,"text":"ban any government involvement in content moderation decisions"}
      ]$stances$::jsonb,
      -- rationale (internal): the axis fix and the substantive classification.
      'Axis fix (review 2026-08-31, Path B). The rev2 double-barrel split kept the WRONG '
      || 'barrel in chair 2: it retained algorithmic transparency (off-axis — regulates the '
      || 'algorithm) and dropped fact-checking (on-axis — acts on content), so chair 2 '
      || 'measured a different object than chairs 1/3/4/5. Re-authored chair 2 as the on-axis '
      || 'labeling rung "require platforms to label false content, rather than remove it" — the '
      || 'position between compelled removal (1) and voluntary standards (3). Chair 1 also '
      || 'de-barreled: dropped "and regulate algorithms" and "all", added "legally". One axis '
      || 'now: how far government compels platforms to counter false CONTENT — remove(1) > '
      || 'label(2) > voluntary(3) > protect speech(4) > no role(5). Title renamed to "Online '
      || 'Misinformation and Content Moderation" (topic no longer scores an algorithm axis; '
      || 'short_title/topic_key unchanged). SUBSTANTIVE (version 2): ~64 of 144 chair-2 rows '
      || 'were seated on pure algorithm-transparency evidence (SB 1018, AB 886, '
      || 'kids-algorithm bills) that no longer fits a content-labeling rung and need re-audit '
      || 'before Season 2 carry. Identity rung_map: the five rungs keep positions and ordinal '
      || 'meaning; only wording changes. Supersedes rejected rev2 (25d14768).',
      -- public_note (voter-facing edit summary).
      'Reframed so every option is about how false content itself is handled — from removing '
      || 'it, to labeling it, to leaving platforms to self-regulate. Option 2 now states a '
      || 'single labeling position instead of a separate rule about algorithm transparency, '
      || 'and the topic is renamed to Online Misinformation and Content Moderation.',
      NULL,                                                                   -- review_ref
      '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb                                 -- identity rung_map
    );
    RAISE NOTICE 'CA_0058: proposed reworked revision %', v_new_id;

    -- Step 3: approve (draft -> approved). NOT published.
    PERFORM inform.admin_approve_topic_revision(v_new_id, v_actor);
    RAISE NOTICE 'CA_0058: approved % (unpublished)', v_new_id;
  END IF;

  -- Step 4: repin Season 2 rev1 -> reworked revision (idempotent).
  SELECT topic_revision_id INTO v_cur FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_cur = v_new_id THEN
    RAISE NOTICE 'CA_0058: Season 2 already pins the reworked revision; skipping pin.';
  ELSE
    PERFORM inform.admin_season_pin_revision(v_season2, v_topic, v_new_id, v_actor);
    RAISE NOTICE 'CA_0058: Season 2 misinformation repinned % -> %', v_cur, v_new_id;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY
-- =============================================================================
DO $$
DECLARE
  v_topic    CONSTANT uuid := 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';
  v_rev1     CONSTANT uuid := '6fa8a338-153a-430d-bc44-e985b44a357c';
  v_rev2     CONSTANT uuid := '25d14768-2f1c-4793-b599-0c53339e0985';
  v_season1  CONSTANT uuid := '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'; -- Season 1 (open)
  v_season2  CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_new_title CONSTANT text := 'Online Misinformation and Content Moderation';
  v_new_id   uuid;
  v_status   text;
  v_pub      timestamptz;
  v_iscur    boolean;
  v_ver      int;
  v_nstance  int;
  v_ch2      text;
  v_key      text;
  v_short    text;
  v_pin      uuid;
  v_open_ver int;
BEGIN
  -- rev2 rejected.
  SELECT status INTO v_status FROM inform.compass_topic_revisions WHERE id = v_rev2;
  IF v_status <> 'rejected' THEN RAISE EXCEPTION 'CA_0058 verify: rev2 status is % (expected rejected)', v_status; END IF;

  -- Exactly one reworked revision, approved, version 2, not published, not current.
  SELECT id, status, version, published_at, is_current, short_title
    INTO v_new_id, v_status, v_ver, v_pub, v_iscur, v_short
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND title = v_new_title;
  IF v_new_id IS NULL THEN RAISE EXCEPTION 'CA_0058 verify: reworked revision not found'; END IF;
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'CA_0058 verify: reworked status is % (expected approved)', v_status; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0058 verify: reworked version is % (expected 2)', v_ver; END IF;
  IF v_pub IS NOT NULL THEN RAISE EXCEPTION 'CA_0058 verify: reworked revision has published_at (must stay unpublished)'; END IF;
  IF v_iscur THEN RAISE EXCEPTION 'CA_0058 verify: reworked revision is_current true (must stay false until season opens)'; END IF;
  IF v_short <> 'Misinformation' THEN RAISE EXCEPTION 'CA_0058 verify: short_title changed to % (must stay Misinformation)', v_short; END IF;

  -- 5 distinct stance rungs; chair 2 carries the new labeling text.
  SELECT count(*), count(DISTINCT value) INTO v_nstance, v_ver
    FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new_id;
  IF v_nstance <> 5 OR v_ver <> 5 THEN RAISE EXCEPTION 'CA_0058 verify: reworked revision has %/% stance rungs (expected 5/5 distinct)', v_nstance, v_ver; END IF;
  SELECT text INTO v_ch2 FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new_id AND value = 2;
  IF v_ch2 <> 'require platforms to label false content, rather than remove it' THEN
    RAISE EXCEPTION 'CA_0058 verify: chair 2 text is "%"', v_ch2;
  END IF;

  -- topic_key still frozen.
  SELECT topic_key INTO v_key FROM inform.compass_topics WHERE id = v_topic;
  IF v_key <> 'misinformation' THEN RAISE EXCEPTION 'CA_0058 verify: topic_key drifted to %', v_key; END IF;

  -- rev1 still current + published (untouched).
  SELECT is_current, status INTO v_iscur, v_status FROM inform.compass_topic_revisions WHERE id = v_rev1;
  IF NOT v_iscur OR v_status <> 'published' THEN
    RAISE EXCEPTION 'CA_0058 verify: rev1 is_current=% status=% (expected true/published)', v_iscur, v_status;
  END IF;

  -- Season 2 pins the reworked revision.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions
   WHERE season_id = v_season2 AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_new_id THEN RAISE EXCEPTION 'CA_0058 verify: Season 2 pin is % (expected reworked %)', v_pin, v_new_id; END IF;

  -- Season 1 (open) still resolves version 1.
  SELECT eff.version INTO v_open_ver
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
  JOIN inform.compass_topic_revisions pin ON pin.id = sq.topic_revision_id
  JOIN LATERAL (
    SELECT ee.version FROM inform.compass_topic_revisions ee
    WHERE ee.topic_id = pin.topic_id AND ee.version = pin.version
      AND ee.status IN ('published','superseded')
    ORDER BY ee.revision DESC LIMIT 1
  ) eff ON true
  WHERE sq.season_id = v_season1 AND sq.topic_id = v_topic;
  IF v_open_ver IS NOT NULL AND v_open_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0058 verify: open season resolves version % (expected 1)', v_open_ver;
  END IF;

  RAISE NOTICE 'CA_0058 post-verify OK: rev2 rejected; reworked rev % approved (unpublished, v2); Season 2 pins it; Season 1 still serves v1; topic_key frozen.', v_new_id;
END $$;

COMMIT;
