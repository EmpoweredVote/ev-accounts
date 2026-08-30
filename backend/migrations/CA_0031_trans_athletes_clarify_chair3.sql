BEGIN;

-- =============================================================================
-- CA_0031: Transgender Athletes — minor (clarifying) chair-3 rewrite
-- =============================================================================
-- Created 2026-08-29 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT THIS DOES
--   Publishes a version-1 CLARIFYING revision of the trans-athletes topic that
--   splits the chair-3 double-barrel so the chair states a single position:
--     chair 3  was  "create separate transgender divisions OR allow case-by-case
--                     decisions based on individual circumstances and sport
--                     requirements" (two welded policies)
--              now  "decide transgender athletes' eligibility case by case based on
--                     individual circumstances and the requirements of each sport"
--   Chairs 1, 2, 4 and 5 are carried verbatim from the live revision. Rungs do not
--   move (identity rung map). Question text and titles are unchanged.
--
-- WHY MINOR, NOT SUBSTANTIVE (decision 2026-08-29, Chris Andrews)
--   The chair-3 split was previously filed as a SUBSTANTIVE v2 draft (rev2,
--   5f63910f) under the 2026-08-28 rewording ruling, which treated a dropped
--   barrel as a material change requiring re-audit of the 15 answers seated on
--   chair 3 and a Season 2 carry. This migration OVERRIDES that ruling for this
--   topic. All 15 chair-3 seatings were reviewed 2026-08-29: every one rests on a
--   case-by-case rationale, which the surviving wording states directly. NONE rests
--   on the dropped "separate transgender divisions" branch. (One row — John J.
--   Cronin — names "separate divisions" only as a vague alternative on a seating
--   that cites no instrument and fails the chair-evidence gate on its own merits,
--   independent of this rewrite.) The dropped clause is therefore an off-axis limb
--   that no seating depended on, so the change is classed CLARIFYING (version stays
--   1), with no re-audit and no Season 2 staging.
--
-- WHY IT GOES LIVE ON PUBLISH (no re-pin needed)
--   Open Season 1 pins trans-athletes to rev1 (version 1). The read path
--   (backend/src/lib/compassService.ts getPromotedTopics) serves, for each pinned
--   topic, the LATEST published/superseded revision AT THE PIN'S VERSION. A
--   clarifying revision keeps version 1, so on publish it becomes the newest
--   version-1 revision and is served by the open season automatically. A
--   substantive revision (version 2) would NOT match the pin and would stay
--   invisible until a season pinned v2. See ADR 0006 sec 3 and CA_0028 (the same
--   operation on residential-zoning).
--
-- SUPERSEDES: rejected draft rev2 (5f63910f). One reviewable draft per topic.
--
-- Idempotent: re-running after success is a no-op; each lifecycle step is guarded.
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'trans-athletes';
  v_rev2     CONSTANT uuid := '5f63910f-1ece-45a3-9b24-4b252beaf9e3';
  v_chair3   CONSTANT text := 'decide transgender athletes'' eligibility case by case based on individual circumstances and the requirements of each sport.';
  v_topic_id uuid;
  v_new_id   uuid;
  v_stances  jsonb;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = v_key;
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0031: topic % not found', v_key;
  END IF;

  -- Idempotency: already published+current with the reworded chair 3? Nothing to do.
  IF EXISTS (
    SELECT 1
    FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s
      ON s.topic_revision_id = r.id AND s.value = 3
    WHERE r.topic_id = v_topic_id
      AND r.change_class = 'clarifying'
      AND r.status = 'published'
      AND r.is_current
      AND s.text = v_chair3
  ) THEN
    RAISE NOTICE 'CA_0031 already applied — clarifying revision is live; skipping.';
    RETURN;
  END IF;

  -- 1) Close the abandoned substantive v2 draft, if still open.
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = v_rev2 AND status IN ('draft','approved')) THEN
    PERFORM inform.admin_reject_topic_revision(
      v_rev2, v_actor,
      'Re-scoped 2026-08-29 (Chris Andrews) as a minor (clarifying) version-1 edit '
      || '(CA_0031), which fixes the same chair-3 double-barrel and flows into open '
      || 'Season 1 on publish. All 15 chair-3 seatings rest on case-by-case reasoning; '
      || 'none depended on the dropped "separate divisions" branch, so no re-audit is '
      || 'owed. Supersedes this substantive v2 draft; one draft per topic.');
  END IF;

  -- 2) Propose the clarifying revision (version stays 1; identity rung map).
  --    Reuse an existing matching draft/approved/published row if a prior partial
  --    run already created it (resumable).
  SELECT r.id INTO v_new_id
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s
    ON s.topic_revision_id = r.id AND s.value = 3
  WHERE r.topic_id = v_topic_id
    AND r.change_class = 'clarifying'
    AND r.status IN ('draft','approved','published')
    AND s.text = v_chair3
  ORDER BY r.revision DESC
  LIMIT 1;

  IF v_new_id IS NULL THEN
    v_stances := jsonb_build_array(
      jsonb_build_object('value', 1, 'text',
        'allow all transgender athletes to compete on teams matching their gender identity without any restrictions or requirements.'),
      jsonb_build_object('value', 2, 'text',
        'should allow transgender athletes to compete on teams matching their gender identity after completing basic documentation of their transition.'),
      jsonb_build_object('value', 3, 'text', v_chair3),
      jsonb_build_object('value', 4, 'text',
        'require transgender athletes to compete only on teams matching their biological sex assigned at birth.'),
      jsonb_build_object('value', 5, 'text',
        'completely ban all transgender athletes from competing in any organized sports competitions.')
    );

    v_new_id := inform.admin_propose_topic_revision(
      v_key, v_actor, 'clarifying',
      'Transgender Athletes', 'Trans Athletes',
      'How should sports leagues determine eligibility for transgender athletes?',
      v_stances,
      -- rationale
      'Minor (clarifying) rewrite. Splits the chair-3 double-barrel so the chair '
      || 'states one position: it drops the "create separate transgender divisions" '
      || 'branch and keeps "decide eligibility case by case based on individual '
      || 'circumstances and the requirements of each sport". Chairs 1, 2, 4 and 5 are '
      || 'carried verbatim; rungs do not move (identity rung map); question and titles '
      || 'unchanged. DECISION 2026-08-29 (Chris Andrews): classed clarifying, not '
      || 'substantive — all 15 chair-3 seatings were reviewed and every one rests on a '
      || 'case-by-case rationale that the surviving wording states directly; none '
      || 'depended on the dropped "separate divisions" branch (which had zero '
      || 'occupants), so no re-audit and no Season 2 carry. This OVERRIDES the '
      || '2026-08-28 rewording ruling recorded on the now-rejected substantive v2 '
      || 'draft rev2 (5f63910f).',
      -- public_note
      'Reworded option 3 to state a single position — decide eligibility case by case '
      || '— without changing where any option sits on the scale or what the question asks.',
      -- review_ref
      'CA_0031 — minor re-scope of the chair-3 double-barrel split; supersedes rejected '
      || 'substantive draft rev2 (5f63910f).',
      -- rung_map (identity: chair 3 reworded in place, none moved)
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

  RAISE NOTICE 'CA_0031: published clarifying revision %', v_new_id;
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
  v_chair3   text;
  v_rungs    int;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'trans-athletes';

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
    RAISE EXCEPTION 'CA_0031 post-verify: open season resolves no effective revision';
  END IF;
  IF v_eff_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0031 post-verify: effective version is % (expected 1 — clarifying must not bump version)', v_eff_ver;
  END IF;
  IF v_eff_cc <> 'clarifying' THEN
    RAISE EXCEPTION 'CA_0031 post-verify: effective change_class is % (expected clarifying)', v_eff_cc;
  END IF;

  SELECT count(*) INTO v_rungs FROM inform.compass_stance_revisions WHERE topic_revision_id = v_eff_id;
  IF v_rungs <> 5 THEN
    RAISE EXCEPTION 'CA_0031 post-verify: effective revision has % rungs (expected 5)', v_rungs;
  END IF;

  SELECT text INTO v_chair3 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_eff_id AND value = 3;
  IF v_chair3 <> 'decide transgender athletes'' eligibility case by case based on individual circumstances and the requirements of each sport.' THEN
    RAISE EXCEPTION 'CA_0031 post-verify: open season chair 3 is "%" (expected the reworded text)', v_chair3;
  END IF;

  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = '5f63910f-1ece-45a3-9b24-4b252beaf9e3' AND status IN ('draft','approved')) THEN
    RAISE EXCEPTION 'CA_0031 post-verify: rev2 is still open (expected rejected)';
  END IF;

  RAISE NOTICE 'CA_0031 post-verify OK: open season serves clarifying v1 revision % (reworded chair 3)', v_eff_id;
END $$;

COMMIT;
