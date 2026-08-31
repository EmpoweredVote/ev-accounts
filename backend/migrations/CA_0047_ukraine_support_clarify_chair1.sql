BEGIN;

-- =============================================================================
-- CA_0047: Ukraine Support — minor (clarifying) chair-1 rewrite
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT THIS DOES
--   Publishes a version-1 CLARIFYING revision of the ukraine-support topic that
--   rewrites chair 1 so it states a single position:
--     chair 1  was  "significantly increase military aid to Ukraine and commit to
--                     supporting them until complete victory over Russia"
--                     (two welded positions: raise aid, AND an open-ended
--                     until-victory war aim)
--              now  "significantly increase military and financial aid to Ukraine."
--   Two edits, both editorial in effect:
--     1. Drops the "until complete victory over Russia" limb. That is an off-axis
--        war-aim commitment, not part of the aid-magnitude spine the 1..5 scale
--        measures. Dropping it BROADENS the chair (one required clause instead of
--        two) and keeps the discriminator that separates chair 1 from chair 2 —
--        the word "increase" (chair 2 is "continue providing current levels").
--     2. Adds "financial" alongside "military". This harmonizes chair 1 with the
--        topic question ("military and financial support") and with chair 2
--        ("military and economic aid"); chair 1 was the only rung scoped to
--        "military" alone.
--   Chairs 2, 3, 4 and 5 are carried verbatim from the live revision. Rungs do not
--   move (identity rung map). Question text and titles are unchanged.
--
-- WHY MINOR, NOT SUBSTANTIVE (decision 2026-08-30, Chris Andrews)
--   The chair-1 split was previously filed as a SUBSTANTIVE v2 draft (rev2,
--   4974e480) under the 2026-08-28 "file them all" double-barrel ruling, which
--   treated a dropped barrel as a material change requiring re-audit of the 23
--   answers seated on chair 1 and a Season 2 carry. This migration OVERRIDES that
--   ruling for this topic. All 23 chair-1 seatings were reviewed 2026-08-30:
--     - Dropping the "until complete victory" limb can only broaden the chair, so
--       no politician who satisfied the old two-part chair fails the new one.
--     - Every seating that leans on the victory framing (e.g. Rahman, Vindman,
--       Aguilar, Andrews) ALSO cites increased/maximal aid, so none is "victory
--       only"; the reword displaces no one.
--     - The "increase" discriminator is untouched, so the chair-1/chair-2 boundary
--       does not move.
--   The dropped clause is therefore an off-axis limb that no seating depended on,
--   so the change is classed CLARIFYING (version stays 1), with no re-audit owed by
--   THIS edit and no Season 2 staging.
--
--   ⚠ SEPARATE, PRE-EXISTING seating-quality debt (NOT caused by this reword, NOT
--     resolved here): several chair-1 rows rest on evidence that fits a different
--     chair against the "increase" discriminator both wordings share — e.g. Salinas,
--     Anthony Brown, Bonamici, Val Hoyle, Healey read as chair-2 "continue current"
--     aid; Kenneth Kerr and Mark Edelson read as chair-3 diplomacy/de-escalation;
--     Jeffrie Long rests on a condemnation resolution that places no aid chair. These
--     were questionable under the OLD wording too. They are deferred to a standalone
--     chair-evidence audit and do not make this reword substantive.
--
-- WHY IT GOES LIVE ON PUBLISH (no re-pin needed)
--   Open Season 1 pins ukraine-support to rev1 (version 1). The read path
--   (backend/src/lib/compassService.ts getPromotedTopics) serves, for each pinned
--   topic, the LATEST published/superseded revision AT THE PIN'S VERSION. A
--   clarifying revision keeps version 1, so on publish it becomes the newest
--   version-1 revision and is served by the open season automatically. A
--   substantive revision (version 2) would NOT match the pin and would stay
--   invisible until a season pinned v2. See ADR 0006 sec 3 and CA_0031 (the same
--   operation on trans-athletes).
--
-- SUPERSEDES: rejected draft rev2 (4974e480). One reviewable draft per topic.
--
-- Idempotent: re-running after success is a no-op; each lifecycle step is guarded.
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'ukraine-support';
  v_rev2     CONSTANT uuid := '4974e480-d02f-420a-b913-0cd800a6296a';
  v_chair1   CONSTANT text := 'significantly increase military and financial aid to Ukraine.';
  v_topic_id uuid;
  v_new_id   uuid;
  v_stances  jsonb;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = v_key;
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0047: topic % not found', v_key;
  END IF;

  -- Idempotency: already published+current with the reworded chair 1? Nothing to do.
  IF EXISTS (
    SELECT 1
    FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s
      ON s.topic_revision_id = r.id AND s.value = 1
    WHERE r.topic_id = v_topic_id
      AND r.change_class = 'clarifying'
      AND r.status = 'published'
      AND r.is_current
      AND s.text = v_chair1
  ) THEN
    RAISE NOTICE 'CA_0047 already applied — clarifying revision is live; skipping.';
    RETURN;
  END IF;

  -- 1) Close the abandoned substantive v2 draft, if still open.
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = v_rev2 AND status IN ('draft','approved')) THEN
    PERFORM inform.admin_reject_topic_revision(
      v_rev2, v_actor,
      'Re-scoped 2026-08-30 (Chris Andrews) as a minor (clarifying) version-1 edit '
      || '(CA_0047), which fixes the same chair-1 double-barrel and flows into open '
      || 'Season 1 on publish. All 23 chair-1 seatings were reviewed; dropping the '
      || '"until complete victory" limb only broadens the chair and none is '
      || 'victory-only, so no re-audit is owed by this reword. Supersedes this '
      || 'substantive v2 draft; one draft per topic.');
  END IF;

  -- 2) Propose the clarifying revision (version stays 1; identity rung map).
  --    Reuse an existing matching draft/approved/published row if a prior partial
  --    run already created it (resumable).
  SELECT r.id INTO v_new_id
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s
    ON s.topic_revision_id = r.id AND s.value = 1
  WHERE r.topic_id = v_topic_id
    AND r.change_class = 'clarifying'
    AND r.status IN ('draft','approved','published')
    AND s.text = v_chair1
  ORDER BY r.revision DESC
  LIMIT 1;

  IF v_new_id IS NULL THEN
    v_stances := jsonb_build_array(
      jsonb_build_object('value', 1, 'text', v_chair1),
      jsonb_build_object('value', 2, 'text',
        'continue providing current levels of military and economic aid to help Ukraine defend itself.'),
      jsonb_build_object('value', 3, 'text',
        'provide limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end the war.'),
      jsonb_build_object('value', 4, 'text',
        'reduce aid to Ukraine and focus American resources on domestic priorities instead.'),
      jsonb_build_object('value', 5, 'text',
        'end all aid to Ukraine immediately and stay completely out of the conflict.')
    );

    v_new_id := inform.admin_propose_topic_revision(
      v_key, v_actor, 'clarifying',
      'Ukraine - Russia Conflict', 'Ukraine Support',
      'What level of military and financial support should be provided to Ukraine?',
      v_stances,
      -- rationale
      'Minor (clarifying) rewrite. Rewrites chair 1 to state one position: it drops '
      || 'the "and commit to supporting them until complete victory over Russia" limb '
      || '(an off-axis war-aim commitment) and adds "financial" alongside "military" '
      || 'to harmonize with the question and chair 2, keeping "significantly increase '
      || 'military and financial aid to Ukraine". Chairs 2, 3, 4 and 5 are carried '
      || 'verbatim; rungs do not move (identity rung map); question and titles '
      || 'unchanged. DECISION 2026-08-30 (Chris Andrews): classed clarifying, not '
      || 'substantive — dropping the limb only broadens the chair, the "increase" '
      || 'discriminator vs chair 2 is untouched, and all 23 chair-1 seatings were '
      || 'reviewed: every victory-framed row also cites increased aid, so none is '
      || 'victory-only and the reword displaces no one; no re-audit and no Season 2 '
      || 'carry. This OVERRIDES the 2026-08-28 rewording ruling recorded on the '
      || 'now-rejected substantive v2 draft rev2 (4974e480). SEPARATE pre-existing '
      || 'seating debt on chair 1 (chair-2/chair-3 evidence on some rows) is deferred '
      || 'to a standalone chair-evidence audit and is not addressed here.',
      -- public_note
      'Reworded option 1 to state a single position — significantly increase military '
      || 'and financial aid — without changing where any option sits on the scale or '
      || 'what the question asks.',
      -- review_ref
      'CA_0047 — minor re-scope of the chair-1 double-barrel split; supersedes rejected '
      || 'substantive draft rev2 (4974e480).',
      -- rung_map (identity: chair 1 reworded in place, none moved)
      '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb
    );
  END IF;

  -- 3) Approve if still draft.
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = v_new_id AND status = 'draft') THEN
    PERFORM inform.admin_approve_topic_revision(v_new_id, v_actor);
  END IF;

  -- 4) Publish if approved (goes live in the open season via the version-1 lineage).
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = v_new_id AND status = 'approved') THEN
    PERFORM inform.admin_publish_topic_revision(v_new_id, v_actor);
  END IF;

  RAISE NOTICE 'CA_0047: published clarifying revision %', v_new_id;
END $$;

-- =============================================================================
-- POST-VERIFY GATE — resolve exactly as compassService.getPromotedTopics does.
-- =============================================================================
DO $$
DECLARE
  v_topic_id uuid;
  v_eff_id   uuid;
  v_eff_ver  int;
  v_eff_cc   text;
  v_chair1   text;
  v_rungs    int;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'ukraine-support';

  SELECT eff.id, eff.version, eff.change_class::text
    INTO v_eff_id, v_eff_ver, v_eff_cc
  FROM inform.season_questions sq
  JOIN inform.seasons s   ON s.id  = sq.season_id AND s.status = 'open'
  JOIN inform.compass_topic_revisions pin ON pin.id = sq.topic_revision_id
  JOIN LATERAL (
    SELECT ee.id, ee.version, ee.change_class
    FROM inform.compass_topic_revisions ee
    WHERE ee.topic_id = pin.topic_id
      AND ee.version  = pin.version
      AND ee.status IN ('published','superseded')
    ORDER BY ee.revision DESC
    LIMIT 1
  ) eff ON true
  WHERE sq.topic_id = v_topic_id;

  IF v_eff_id IS NULL THEN
    RAISE EXCEPTION 'CA_0047 post-verify: open season resolves no effective revision';
  END IF;
  IF v_eff_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0047 post-verify: effective version is % (expected 1 — clarifying must not bump version)', v_eff_ver;
  END IF;
  IF v_eff_cc <> 'clarifying' THEN
    RAISE EXCEPTION 'CA_0047 post-verify: effective change_class is % (expected clarifying)', v_eff_cc;
  END IF;

  SELECT count(*) INTO v_rungs FROM inform.compass_stance_revisions WHERE topic_revision_id = v_eff_id;
  IF v_rungs <> 5 THEN
    RAISE EXCEPTION 'CA_0047 post-verify: effective revision has % rungs (expected 5)', v_rungs;
  END IF;

  SELECT text INTO v_chair1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_eff_id AND value = 1;
  IF v_chair1 <> 'significantly increase military and financial aid to Ukraine.' THEN
    RAISE EXCEPTION 'CA_0047 post-verify: open season chair 1 is "%" (expected the reworded text)', v_chair1;
  END IF;

  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = '4974e480-d02f-420a-b913-0cd800a6296a' AND status IN ('draft','approved')) THEN
    RAISE EXCEPTION 'CA_0047 post-verify: rev2 is still open (expected rejected)';
  END IF;

  RAISE NOTICE 'CA_0047 post-verify OK: open season serves clarifying v1 revision % (reworded chair 1)', v_eff_id;
END $$;

COMMIT;
