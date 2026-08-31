BEGIN;

-- =============================================================================
-- CA_0048: Transportation Priorities — minor (clarifying) chair-1 & chair-2 rewrite
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT THIS DOES
--   Publishes a version-1 CLARIFYING revision of the transportation-priorities
--   topic that rewrites chairs 1 and 2 so each states a single position. Chairs 3,
--   4 and 5 are carried VERBATIM from the live revision (confirmed byte-identical
--   2026-08-30). Rungs do not move (identity rung map). Question text and titles
--   are unchanged.
--
--     chair 1  was  "Prioritize pedestrian infrastructure, cycling networks, and
--                     public transit; reduce parking requirements communitywide"
--              now  "Prioritize pedestrian infrastructure, cycling networks, and
--                     public transit over new road capacity"
--       - Drops the "reduce parking requirements communitywide" clause (a lowering).
--       - Adds "over new road capacity", making the transit-first direction explicit.
--
--     chair 2  was  "Invest equally in roads and multimodal options; require bike
--                     lanes and sidewalks on all new road projects"
--              now  "Invest equally in road capacity and in multimodal options like
--                     transit, bike lanes, and sidewalks"
--       - Drops the "require bike lanes and sidewalks on all new road projects"
--         mandate (a lowering). The retained core — invest equally in roads and
--         multimodal — is unchanged; the trailing list is illustrative, not required.
--
-- WHY MINOR, NOT SUBSTANTIVE (decision 2026-08-30, Chris Andrews)
--   The chairs 1/2 splits were previously filed as a SUBSTANTIVE v2 draft (rev2,
--   1654f2aa) under the 2026-08-28 double-barrel ruling, which treated a dropped
--   barrel as a material change requiring re-audit of the seated answers. This
--   migration OVERRIDES that ruling for this topic. The full re-audit was run
--   2026-08-30 and comes back empty:
--     - The edit touches ONLY chairs 1 and 2. Chairs 3, 4, 5 are byte-identical, so
--       the 169 rows seated on them (108/58/3) sit on unchanged text and cannot be
--       stranded.
--     - Chair 2 is safe by logic: the edit only REMOVES a requirement, so every row
--       that met the stricter old text still meets the looser new text (189 rows).
--     - Chair 1 is safe by evidence (88 rows tested): 0 rows seated only on parking
--       with no transit/bike/ped evidence; 0 rows that read as "balanced" rather than
--       transit-first (which the new "over new road capacity" wording would
--       contradict). The 23 chair-1 rows mentioning parking all establish transit
--       prioritization independently (bond measures, BRT builds, opposing highway
--       expansion). The parking detail was extra, not load-bearing.
--   The dropped clauses are therefore off-axis limbs that no seating depended on, and
--   the one addition ("over new road capacity") strands zero rows, so the change is
--   classed CLARIFYING (version stays 1), with no re-audit owed by THIS edit and no
--   Season 2 staging.
--
--   -- SEPARATE, PRE-EXISTING seating-quality debt (NOT caused by this reword, NOT
--     resolved here): ~69 chair-2 rows read transit-first / anti-highway
--     ("reducing car dependence", "over car-centric infrastructure", "opposing
--     highway expansion") and cite little or no road-investment evidence; some may
--     belong in chair 1. This was already true under revision 1. It is being reviewed
--     as a SEPARATE re-seating pass and does not make this reword substantive.
--
-- WHY IT GOES LIVE ON PUBLISH (no re-pin needed)
--   Open Season 1 pins transportation-priorities to rev1 (version 1). The read path
--   (backend/src/lib/compassService.ts getPromotedTopics) serves, for each pinned
--   topic, the LATEST published/superseded revision AT THE PIN'S VERSION. A
--   clarifying revision keeps version 1, so on publish it becomes the newest
--   version-1 revision and is served by the open season automatically. Season 2 also
--   pins version 1, so it serves the same wording. See ADR 0006 sec 3 and CA_0047
--   (the same operation on ukraine-support).
--
-- SUPERSEDES: rejected draft rev2 (1654f2aa). One reviewable draft per topic.
--
-- Idempotent: re-running after success is a no-op; each lifecycle step is guarded.
-- =============================================================================

DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'transportation-priorities';
  v_rev2     CONSTANT uuid := '1654f2aa-cac4-4762-9779-40f0b4b151f0';
  v_chair1   CONSTANT text := 'Prioritize pedestrian infrastructure, cycling networks, and public transit over new road capacity';
  v_chair2   CONSTANT text := 'Invest equally in road capacity and in multimodal options like transit, bike lanes, and sidewalks';
  v_chair3   CONSTANT text := 'Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it';
  v_chair4   CONSTANT text := 'Focus on road capacity and traffic flow; transportation investment should serve the majority who drive';
  v_chair5   CONSTANT text := 'Prioritize highway access and abundant free parking as the foundation of local transportation policy';
  v_topic_id uuid;
  v_new_id   uuid;
  v_stances  jsonb;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = v_key;
  IF v_topic_id IS NULL THEN
    RAISE EXCEPTION 'CA_0048: topic % not found', v_key;
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
    RAISE NOTICE 'CA_0048 already applied — clarifying revision is live; skipping.';
    RETURN;
  END IF;

  -- 1) Close the abandoned substantive v2 draft, if still open.
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = v_rev2 AND status IN ('draft','approved')) THEN
    PERFORM inform.admin_reject_topic_revision(
      v_rev2, v_actor,
      'Re-scoped 2026-08-30 (Chris Andrews) as a minor (clarifying) version-1 edit '
      || '(CA_0048), which makes the same chair-1/chair-2 de-barrel and flows into '
      || 'open Season 1 on publish. Full re-audit run: the edit touches only chairs 1 '
      || 'and 2, chairs 3-5 are byte-identical, chair 2 only removes a requirement, '
      || 'and 0 chair-1 rows are stranded by the "over new road capacity" wording, so '
      || 'no re-audit is owed by this reword. Supersedes this substantive v2 draft; '
      || 'one draft per topic.');
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
      jsonb_build_object('value', 2, 'text', v_chair2),
      jsonb_build_object('value', 3, 'text', v_chair3),
      jsonb_build_object('value', 4, 'text', v_chair4),
      jsonb_build_object('value', 5, 'text', v_chair5)
    );

    v_new_id := inform.admin_propose_topic_revision(
      v_key, v_actor, 'clarifying',
      'Transportation Priorities', 'Transportation Priorities',
      'Where should government focus its transportation investment?',
      v_stances,
      -- rationale
      'Minor (clarifying) rewrite. Rewrites chairs 1 and 2 to each state one position, '
      || 'carrying chairs 3-5 verbatim. Chair 1 drops "reduce parking requirements '
      || 'communitywide" and adds "over new road capacity"; chair 2 drops the "require '
      || 'bike lanes and sidewalks on all new road projects" mandate, keeping "invest '
      || 'equally in road capacity and multimodal". Rungs do not move (identity rung '
      || 'map); question and titles unchanged. DECISION 2026-08-30 (Chris Andrews): '
      || 'classed clarifying, not substantive — full re-audit run and empty: the edit '
      || 'touches only chairs 1/2 (chairs 3-5 byte-identical, 169 rows untouched), '
      || 'chair 2 only removes a requirement (189 rows all still fit), and 0 of the 88 '
      || 'chair-1 rows are stranded by the "over road capacity" wording (0 parking-only, '
      || '0 balanced). This OVERRIDES the 2026-08-28 double-barrel ruling recorded on '
      || 'the now-rejected substantive v2 draft rev2 (1654f2aa). SEPARATE pre-existing '
      || 'chair-2 seating debt (~69 transit-first rows) is handled as a separate '
      || 're-seating pass and is not addressed here.',
      -- public_note
      'Reworded options 1 and 2 so each states a single position, without changing '
      || 'where any option sits on the scale or what the question asks.',
      -- review_ref
      'CA_0048 — minor re-scope of the chair-1/chair-2 double-barrel splits; supersedes '
      || 'rejected substantive draft rev2 (1654f2aa).',
      -- rung_map (identity: chairs reworded in place, none moved)
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

  RAISE NOTICE 'CA_0048: published clarifying revision %', v_new_id;
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
  v_text     text;
  v_rungs    int;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = 'transportation-priorities';

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
    RAISE EXCEPTION 'CA_0048 post-verify: open season resolves no effective revision';
  END IF;
  IF v_eff_ver <> 1 THEN
    RAISE EXCEPTION 'CA_0048 post-verify: effective version is % (expected 1 — clarifying must not bump version)', v_eff_ver;
  END IF;
  IF v_eff_cc <> 'clarifying' THEN
    RAISE EXCEPTION 'CA_0048 post-verify: effective change_class is % (expected clarifying)', v_eff_cc;
  END IF;

  SELECT count(*) INTO v_rungs FROM inform.compass_stance_revisions WHERE topic_revision_id = v_eff_id;
  IF v_rungs <> 5 THEN
    RAISE EXCEPTION 'CA_0048 post-verify: effective revision has % rungs (expected 5)', v_rungs;
  END IF;

  -- reworded chairs 1 and 2
  SELECT text INTO v_text FROM inform.compass_stance_revisions WHERE topic_revision_id = v_eff_id AND value = 1;
  IF v_text <> 'Prioritize pedestrian infrastructure, cycling networks, and public transit over new road capacity' THEN
    RAISE EXCEPTION 'CA_0048 post-verify: chair 1 is "%" (expected the reworded text)', v_text;
  END IF;
  SELECT text INTO v_text FROM inform.compass_stance_revisions WHERE topic_revision_id = v_eff_id AND value = 2;
  IF v_text <> 'Invest equally in road capacity and in multimodal options like transit, bike lanes, and sidewalks' THEN
    RAISE EXCEPTION 'CA_0048 post-verify: chair 2 is "%" (expected the reworded text)', v_text;
  END IF;

  -- chairs 3-5 must be carried verbatim
  SELECT text INTO v_text FROM inform.compass_stance_revisions WHERE topic_revision_id = v_eff_id AND value = 3;
  IF v_text <> 'Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it' THEN
    RAISE EXCEPTION 'CA_0048 post-verify: chair 3 changed (expected verbatim carry): "%"', v_text;
  END IF;
  SELECT text INTO v_text FROM inform.compass_stance_revisions WHERE topic_revision_id = v_eff_id AND value = 4;
  IF v_text <> 'Focus on road capacity and traffic flow; transportation investment should serve the majority who drive' THEN
    RAISE EXCEPTION 'CA_0048 post-verify: chair 4 changed (expected verbatim carry): "%"', v_text;
  END IF;
  SELECT text INTO v_text FROM inform.compass_stance_revisions WHERE topic_revision_id = v_eff_id AND value = 5;
  IF v_text <> 'Prioritize highway access and abundant free parking as the foundation of local transportation policy' THEN
    RAISE EXCEPTION 'CA_0048 post-verify: chair 5 changed (expected verbatim carry): "%"', v_text;
  END IF;

  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions
             WHERE id = '1654f2aa-cac4-4762-9779-40f0b4b151f0' AND status IN ('draft','approved')) THEN
    RAISE EXCEPTION 'CA_0048 post-verify: rev2 is still open (expected rejected)';
  END IF;

  RAISE NOTICE 'CA_0048 post-verify OK: open season serves clarifying v1 revision % (reworded chairs 1 & 2, chairs 3-5 verbatim)', v_eff_id;
END $$;

COMMIT;
