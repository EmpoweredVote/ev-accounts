-- CA_0103_pin_education_topics_season2.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
-- Runs AFTER CA_0075 (the 8 education topics must exist). Renumber to the next free CA_#### if taken.
--
-- =============================================================================
-- CA_0103: Pin the 8 education topics into Season 2 (Season 2 is a DRAFT; NOT opened here)
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT: adds each of the 8 staged education topics (CA_0075) to Season 2's question set via
--   inform.admin_season_add_topic, which pins each topic's current published v1 revision.
--
-- WHY SAFE NOW: Season 2 (86d893a1-…) is a DRAFT. A season serves its pinned questions only
--   when OPEN, so this changes nothing a voter sees today. The topics stay is_live=false and
--   are NOT promoted (the season-gated promoted view lists only the OPEN season's topics). They
--   go live when Season 2 opens (inform.admin_open_season) — a separate, later step. Season 1
--   (open) is untouched.
--
-- IDEMPOTENT: each add is guarded by a season_questions existence check (admin_season_add_topic
--   itself raises ALREADY_IN_SEASON on a duplicate), so a re-run skips topics already pinned.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_actor  CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';   -- Chris Andrews
  v_season CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';   -- Season 2 (draft)
  v_keys   text[] := ARRAY[
    'education-curriculum','education-library-books','education-gender-identity',
    'education-equity-programs','education-school-police','education-charter-authorization',
    'education-school-budget','education-ai'
  ];
  v_key   text;
  v_topic uuid;
  v_added int := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0103: Season 2 is not a draft — question set is frozen, refusing to pin';
  END IF;

  FOREACH v_key IN ARRAY v_keys
  LOOP
    SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = v_key;
    IF v_topic IS NULL THEN
      RAISE EXCEPTION 'CA_0103: topic % is missing — apply CA_0075 first', v_key;
    END IF;

    IF EXISTS (SELECT 1 FROM inform.season_questions WHERE season_id = v_season AND topic_id = v_topic) THEN
      RAISE NOTICE 'CA_0103: % already in Season 2 — skip', v_key;
    ELSE
      PERFORM inform.admin_season_add_topic(v_season, v_topic, v_actor);
      v_added := v_added + 1;
      RAISE NOTICE 'CA_0103: pinned % to Season 2', v_key;
    END IF;
  END LOOP;

  RAISE NOTICE 'CA_0103: % of 8 education topics newly pinned to Season 2', v_added;
END $$;

-- ── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_season CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_keys   text[] := ARRAY[
    'education-curriculum','education-library-books','education-gender-identity',
    'education-equity-programs','education-school-police','education-charter-authorization',
    'education-school-budget','education-ai'
  ];
  v_key   text;
  v_topic uuid;
  v_n     int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_season AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0103 verify: Season 2 is no longer a draft';
  END IF;

  FOREACH v_key IN ARRAY v_keys
  LOOP
    SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = v_key;

    -- pinned into Season 2, to the current published revision
    IF NOT EXISTS (
      SELECT 1 FROM inform.season_questions sq
      JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
      WHERE sq.season_id = v_season AND sq.topic_id = v_topic
        AND r.is_current AND r.status = 'published'
    ) THEN
      RAISE EXCEPTION 'CA_0103 verify: % is not pinned to Season 2 at its current published revision', v_key;
    END IF;

    -- still staged: is_live=false and NOT promoted (draft season promotes nothing)
    IF (SELECT is_live FROM inform.compass_topics WHERE id = v_topic) THEN
      RAISE EXCEPTION 'CA_0103 verify: % is_live=true (must stay staged until Season 2 opens)', v_key;
    END IF;
    IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
      RAISE EXCEPTION 'CA_0103 verify: % is promoted before Season 2 opened', v_key;
    END IF;
  END LOOP;

  SELECT count(*) INTO v_n
    FROM inform.season_questions sq
    JOIN inform.compass_topics t ON t.id = sq.topic_id
   WHERE sq.season_id = v_season AND t.topic_key = ANY(v_keys);
  IF v_n <> 8 THEN
    RAISE EXCEPTION 'CA_0103 verify: expected 8 education topics in Season 2, found %', v_n;
  END IF;

  RAISE NOTICE 'CA_0103 post-verify OK — 8 education topics pinned to Season 2 (draft), still staged & unpromoted. They go live when Season 2 opens.';
END $$;

COMMIT;
