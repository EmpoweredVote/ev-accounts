-- CA_0090_pin_military_intervention_season2.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
-- Runs AFTER CA_0089 (the military-intervention topic must exist).
--
-- =============================================================================
-- CA_0090: Pin "Foreign Military Intervention" into Season 2 (DRAFT; NOT opened here)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: adds the staged 'military-intervention' topic (CA_0089) to Season 2's question set via
--   inform.admin_season_add_topic, which pins the topic's current published v1 revision.
--
-- WHY SAFE NOW: Season 2 (86d893a1-…) is a DRAFT. A season serves its pinned questions only
--   when OPEN, so this changes nothing a voter sees today. The topic stays is_live=false and is
--   NOT promoted (the season-gated promoted view lists only the OPEN season's topics). It goes
--   live when Season 2 opens (inform.admin_open_season) — a separate, later step. Season 1
--   (open) is untouched. This gives the compass its second foreign-policy topic (alongside
--   Ukraine Support) when Season 2 opens.
--
-- IDEMPOTENT: the add is guarded by a season_questions existence check (admin_season_add_topic
--   itself raises ALREADY_IN_SEASON on a duplicate), so a re-run is a no-op.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_actor  CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';   -- Chris Andrews
  v_season CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';   -- Season 2 (draft)
  v_key    CONSTANT text := 'military-intervention';
  v_topic  uuid;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0090: Season 2 is not a draft — question set is frozen, refusing to pin';
  END IF;

  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = v_key;
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0090: topic % is missing — apply CA_0089 first', v_key;
  END IF;

  IF EXISTS (SELECT 1 FROM inform.season_questions WHERE season_id = v_season AND topic_id = v_topic) THEN
    RAISE NOTICE 'CA_0090: % already in Season 2 — skip', v_key;
  ELSE
    PERFORM inform.admin_season_add_topic(v_season, v_topic, v_actor);
    RAISE NOTICE 'CA_0090: pinned % to Season 2', v_key;
  END IF;
END $$;

-- ── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_season CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_key    CONSTANT text := 'military-intervention';
  v_topic  uuid;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0090 verify: Season 2 is no longer a draft';
  END IF;

  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = v_key;

  -- pinned into Season 2, to the current published revision
  IF NOT EXISTS (
    SELECT 1 FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
    WHERE sq.season_id = v_season AND sq.topic_id = v_topic
      AND r.is_current AND r.status = 'published'
  ) THEN
    RAISE EXCEPTION 'CA_0090 verify: % is not pinned to Season 2 at its current published revision', v_key;
  END IF;

  -- still staged: is_live=false and NOT promoted (draft season promotes nothing)
  IF (SELECT is_live FROM inform.compass_topics WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0090 verify: % is_live=true (must stay staged until Season 2 opens)', v_key;
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0090 verify: % is promoted before Season 2 opened', v_key;
  END IF;

  RAISE NOTICE 'CA_0090 post-verify OK — military-intervention pinned to Season 2 (draft), still staged & unpromoted. It goes live when Season 2 opens.';
END $$;

COMMIT;
