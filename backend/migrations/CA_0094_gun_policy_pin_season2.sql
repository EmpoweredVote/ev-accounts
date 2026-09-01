BEGIN;

-- =============================================================================
-- CA_0094: pin "Gun Policy" (gun-policy) into draft Season 2
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews. Follows CA_0093 (which created the
-- topic staged). Decision: Gun Policy IS a Season 2 topic (2026 midterm issue).
--
-- WHAT THIS DOES
-- Adds gun-policy to the draft Season 2 via inform.admin_season_add_topic
-- (CA_0022), which pins the topic's current PUBLISHED v1 revision as a new
-- season question. It goes live only when Season 2 OPENS
-- (inform.admin_open_season). This is a pin-only migration — no topic content
-- changes.
--
-- ⚠ IT WILL OPEN WITH EMPTY SPOKES. No politician is seated on gun-policy yet
-- (a brand-new topic has no answers). Until a stance-research pass seats real
-- 2026 officials at the five rungs, every official shows a BLANK spoke here.
-- Run research BEFORE Season 2 opens, or the topic launches unanswered.
--
-- WHY A MIGRATION (not a one-off RPC call): the repo records every prod data
-- change as a numbered, idempotent migration with a post-verify gate (see
-- CA_0068/CA_0069, the sibling season-2 pins). This matches that house style.
--
-- IDEMPOTENT: guarded on season_questions(season_id, topic_id) so a re-run is a
-- no-op (the RPC itself raises ALREADY_IN_SEASON, which an unguarded re-run would
-- abort on). Requires Season 2 to still be 'draft' (the RPC enforces this) and a
-- current published revision on the topic (CA_0093 created one).
--
-- To revert: inform.admin_season_remove_topic(season_id, topic_id, actor), or
-- delete the season_questions row. No topic content is touched.
--
-- IDs (verified 2026-08-31):
--   Season 2 (draft): 86d893a1-c1a2-4bbf-b4e5-69ec43221194
--   gun-policy topic: 56125933-b82a-46c5-847b-b2e9a146b89f
-- Resolved by key/number below rather than hard-coded, so the migration stays
-- correct if an id differs between environments.
-- =============================================================================

DO $$
DECLARE
  v_season uuid;
  v_topic  uuid;
BEGIN
  SELECT id INTO v_season FROM inform.seasons WHERE number = 2;
  IF v_season IS NULL THEN
    RAISE EXCEPTION 'CA_0094: Season 2 not found';
  END IF;

  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'gun-policy';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0094: topic gun-policy not found (run CA_0093 first)';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.season_questions
     WHERE season_id = v_season AND topic_id = v_topic
  ) THEN
    PERFORM inform.admin_season_add_topic(v_season, v_topic, NULL);
    RAISE NOTICE 'CA_0094: pinned gun-policy into Season 2';
  ELSE
    RAISE NOTICE 'CA_0094: gun-policy already pinned in Season 2 — skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Post-verify gate.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_season uuid;
  v_topic  uuid;
  v_rev    uuid;
  v_pinned uuid;
  v_status inform.season_status;
BEGIN
  SELECT id, status INTO v_season, v_status FROM inform.seasons WHERE number = 2;
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'gun-policy';

  -- the season must still be a draft (opening it is a separate, later step)
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'CA_0094: Season 2 is % (expected draft)', v_status;
  END IF;

  -- exactly one season_questions row for this topic, pinned to its current
  -- published revision
  SELECT topic_revision_id INTO v_pinned
    FROM inform.season_questions
   WHERE season_id = v_season AND topic_id = v_topic;
  IF v_pinned IS NULL THEN
    RAISE EXCEPTION 'CA_0094: gun-policy is not pinned into Season 2';
  END IF;

  SELECT id INTO v_rev
    FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published';
  IF v_pinned <> v_rev THEN
    RAISE EXCEPTION 'CA_0094: pinned revision % is not the current published revision %', v_pinned, v_rev;
  END IF;

  RAISE NOTICE 'CA_0094 OK — gun-policy pinned into draft Season 2 at its current published v1';
END $$;

COMMIT;
