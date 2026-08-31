BEGIN;

-- =============================================================================
-- CA_0028: Residential Zoning — minor (clarifying) ladder rewrite
-- =============================================================================
-- Created 2026-08-29 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT THIS DOES
--   Publishes a version-1 CLARIFYING revision of the residential-zoning topic that
--   splits three double-barrels so each chair states a single position:
--     chair 1  drops the mechanism "require community votes before any rezoning"
--              (keeps the maximum-protection stance)
--     chair 2  drops "with strong design review and neighborhood input"
--     chair 4  drops "streamline approvals and reduce parking requirements"
--   Rungs do not move (identity rung map). Question text and titles are unchanged.
--
-- WHY MINOR, NOT SUBSTANTIVE (decision 2026-08-29, Chris Andrews)
--   The chair 2/4 splits were previously filed as a SUBSTANTIVE v2 draft (rev3,
--   a383edb9) under a 2026-08-28 ruling that treated a dropped barrel as a material
--   change requiring re-audit of the 275 seated answers on chairs 2 and 4 and a
--   Season 2 carry. This migration OVERRIDES that ruling: the dropped clauses are
--   judged off-axis limbs that no seating depended on, so the change is classed
--   CLARIFYING (version stays 1), with no re-audit and no Season 2 staging.
--
-- WHY IT GOES LIVE ON PUBLISH (no re-pin needed)
--   The open season pins residential-zoning to rev1 (version 1). The read path
--   (backend/src/lib/compassService.ts getPromotedTopics) serves, for each pinned
--   topic, the LATEST published/superseded revision AT THE PIN'S VERSION:
--       e.version = pin.version AND e.status IN ('published','superseded')
--       ORDER BY e.revision DESC LIMIT 1
--   A clarifying revision keeps version 1, so on publish it becomes the newest
--   version-1 revision and is served by the open season automatically. A
--   substantive revision (version 2) would NOT match the pin and would stay
--   invisible until a season pinned v2. See ADR 0006 sec 3.
--
-- SUPERSEDES: rejected drafts rev2 (40120e9c) and rev3 (a383edb9). One reviewable
-- draft per topic; rev3 is closed here.
--
-- Idempotent: re-running after success is a no-op; each lifecycle step is guarded.
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'residential-zoning';
  v_rev3     CONSTANT uuid := 'a383edb9-c963-490e-b1ba-810dee021637';
  v_chair1   CONSTANT text := 'Protect existing single-family neighborhoods; oppose density increases.';
  v_topic_id uuid;
  v_new_id   uuid;
  v_stances  jsonb;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = v_key;
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0028: topic % not found', v_key;
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
    RAISE NOTICE 'CA_0028 already applied — clarifying revision is live; skipping.';
    RETURN;
  END IF;

  -- 1) Close the abandoned substantive v2 draft, if still open.
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = v_rev3 AND status IN ('draft','approved')) THEN
    PERFORM inform.admin_reject_topic_revision(
      v_rev3, v_actor,
      'Re-scoped 2026-08-29 (Chris Andrews) as a minor (clarifying) version-1 edit '
      || '(CA_0028), which also fixes the chair-1 double-barrel and flows into open '
      || 'Season 1 on publish. Supersedes this approved v2 draft; one draft per topic.');
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
        'Allow modest density increases, like duplexes and accessory units, in single-family neighborhoods'),
      jsonb_build_object('value', 3, 'text',
        'Allow multifamily and mixed-use near commercial corridors while protecting most residential zones'),
      jsonb_build_object('value', 4, 'text',
        'Upzone broadly to allow multifamily housing by right in most neighborhoods'),
      jsonb_build_object('value', 5, 'text',
        'Eliminate single-family-only zoning; allow any housing type on any lot communitywide')
    );

    v_new_id := inform.admin_propose_topic_revision(
      v_key, v_actor, 'clarifying',
      'Residential Zoning', 'Residential Zoning',
      'What should guide decisions about housing density and neighborhood character in your community?',
      v_stances,
      -- rationale
      'Minor (clarifying) rewrite. Splits three double-barrels so each chair states one '
      || 'position: chair 1 drops the "require community votes before any rezoning" mechanism '
      || '(keeps the protection stance); chair 2 drops "with strong design review and '
      || 'neighborhood input"; chair 4 drops "streamline approvals and reduce parking '
      || 'requirements". Rungs do not move (identity rung map); question and titles unchanged. '
      || 'DECISION 2026-08-29 (Chris Andrews): classed clarifying, not substantive — the dropped '
      || 'clauses are treated as off-axis limbs no seating depended on, so no re-audit and no '
      || 'Season 2 carry. This OVERRIDES the 2026-08-28 ruling recorded on the now-rejected v2 '
      || 'drafts rev2 (40120e9c) and rev3 (a383edb9), which had classed the chair 2/4 splits as material.',
      -- public_note
      'Reworded three options so each states a single position, without changing where any '
      || 'option sits on the scale or what the question asks.',
      -- review_ref
      'CA_0028 — minor re-scope of the chair 2/4 double-barrel splits plus the chair-1 fix; '
      || 'supersedes rejected drafts rev2/rev3.',
      -- rung_map (identity: rungs reworded in place, none moved)
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

  RAISE NOTICE 'CA_0028: published clarifying revision %', v_new_id;
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
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'residential-zoning';

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
    RAISE EXCEPTION 'CA_0028 post-verify: open season resolves no effective revision';
  END IF;
  IF v_eff_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0028 post-verify: effective version is % (expected 1 — clarifying must not bump version)', v_eff_ver;
  END IF;
  IF v_eff_cc <> 'clarifying' THEN
    RAISE EXCEPTION 'CA_0028 post-verify: effective change_class is % (expected clarifying)', v_eff_cc;
  END IF;

  SELECT count(*) INTO v_rungs FROM inform.compass_stance_revisions WHERE topic_revision_id = v_eff_id;
  IF v_rungs <> 5 THEN
    RAISE EXCEPTION 'CA_0028 post-verify: effective revision has % rungs (expected 5)', v_rungs;
  END IF;

  SELECT text INTO v_chair1 FROM inform.compass_stance_revisions
   WHERE topic_revision_id = v_eff_id AND value = 1;
  IF v_chair1 <> 'Protect existing single-family neighborhoods; oppose density increases.' THEN
    RAISE EXCEPTION 'CA_0028 post-verify: open season chair 1 is "%" (expected the reworded text)', v_chair1;
  END IF;

  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = 'a383edb9-c963-490e-b1ba-810dee021637' AND status IN ('draft','approved')) THEN
    RAISE EXCEPTION 'CA_0028 post-verify: rev3 is still open (expected rejected)';
  END IF;

  RAISE NOTICE 'CA_0028 post-verify OK: open season serves clarifying v1 revision % (reworded chair 1)', v_eff_id;
END $$;

COMMIT;
