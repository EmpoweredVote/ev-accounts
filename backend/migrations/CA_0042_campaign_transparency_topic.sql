-- CA_0042_campaign_transparency_topic.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
--
-- =============================================================================
-- CA_0042: "Campaign Transparency" — a new compass topic (revision model), STAGED + UNPINNED
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT THIS ADDS
--   A new voter-facing compass topic on the campaign-money TRANSPARENCY axis (how much
--   disclosure government should require), topic_key frozen at 'campaign-transparency'.
--
-- WHY IT EXISTS — the split from campaign-finance (see CA_0041)
--   CA_0041 rebuilt `campaign-finance` onto a single LIMITS axis and dropped its old option 3
--   ("require full disclosure of all political donations"), which measured transparency — a lever
--   orthogonal to limits (a voter can want full disclosure AND fewer limits at once). 96 of the 99
--   answers seated on that old option were well-sourced disclosure positions (69 name a primary
--   instrument). Rather than blank them, this topic gives disclosure its own clean axis so those
--   seatings are preserved. See backend/data/season2-carry/campaign-finance-chair3-reaudit.json.
--
-- THE AXIS (1 = maximum transparency, 5 = none). Monotonic, single axis:
--     1  Require real-time public disclosure of every donor, including dark-money groups
--     2  Require full disclosure of all donations above a small threshold
--     3  Require disclosure of direct donations only            (status-quo middle)
--     4  Reduce disclosure requirements to protect donor privacy
--     5  Require no public disclosure of political donors
--   Polarity note: corpus lean is "value 1 = maximum government action", which holds here
--   (1 = the most disclosure government can mandate). Do not invert.
--
-- LEVELS: federal + state + local (disclosure rules exist at every level). Not judicial.
--
-- 🔴 STAGED AND UNPINNED — SHOWS TO NO ONE, MOVES NO ANSWERS.
--   is_live=false and NO season pins it, so it appears on no voter surface (the season-gated
--   promoted view gates display, not is_live). This migration creates only the topic; it writes NO
--   politician_answers. Creating the destination does NOT move the 96 disclosure seatings — those
--   are currently correct on campaign-finance for the open Season 1 and must not be touched.
--
--   For the 96 to actually re-home here, TWO further steps are needed, in order:
--     1. Pin this topic into Season 2 (inform.admin_season_add_topic) — a separate, later decision.
--     2. At Season 2 assembly, run the carry: write the 96 answers onto this topic at rung 2
--        (carrying reasoning + sources), per the carry JSON. If this topic is NOT pinned to Season 2
--        before assembly, the 96 have nowhere to land on the limits topic and would blank instead.
--
-- IDEMPOTENT: the create runs only when topic_key 'campaign-transparency' is absent; the category
--   assignment is ON CONFLICT DO NOTHING. The post-verify gate asserts the full shape either way.
--   To revert: delete the topic row (its revisions/stances/roles/category cascade). No existing
--   object is altered.
-- =============================================================================

BEGIN;

-- ── 1. Create the topic (guarded so a re-run does not hit DUPLICATE_TOPIC_KEY) ────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'campaign-transparency') THEN
    PERFORM inform.admin_create_topic_with_revision(
      'Campaign Finance Transparency',                                          -- p_title
      'What should the public be able to know about who funds political campaigns?', -- p_question_text
      'Campaign Transparency',                                                  -- p_short_title -> topic_key 'campaign-transparency'
      false,                                                                    -- p_is_live (staged)
      '[
        {"value":1,"text":"Require real-time public disclosure of every donor, including dark-money groups"},
        {"value":2,"text":"Require full disclosure of all donations above a small threshold"},
        {"value":3,"text":"Require disclosure of direct donations only"},
        {"value":4,"text":"Reduce disclosure requirements to protect donor privacy"},
        {"value":5,"text":"Require no public disclosure of political donors"}
      ]'::jsonb,                                                                -- p_stances
      '854fbc06-40fc-458d-b523-20ef8e5ad1b2',                                   -- p_actor_id (Chris Andrews)
      '["federal","state","local"]'::jsonb                                      -- p_role_scopes (all levels; not judicial)
    );
    RAISE NOTICE 'CA_0042: created topic campaign-transparency';
  ELSE
    RAISE NOTICE 'CA_0042: topic campaign-transparency already present — create skipped';
  END IF;
END $$;

-- ── 2. Assign category (same as campaign-finance: Governance, Democracy, and Institutional Reform) ─
INSERT INTO inform.compass_topic_categories (topic_id, category_id)
SELECT t.id, '6e958103-8877-4421-9279-39e96e00e6f9'
  FROM inform.compass_topics t
 WHERE t.topic_key = 'campaign-transparency'
ON CONFLICT (topic_id, category_id) DO NOTHING;

-- ── 3. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic uuid;
  v_n     int;
  v_t1    text;
  v_t5    text;
BEGIN
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'campaign-transparency';
  IF v_topic IS NULL THEN
    RAISE EXCEPTION 'CA_0042: topic campaign-transparency is missing after create';
  END IF;

  -- exactly one published/current v1 substantive revision, rung_map NULL
  SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
   WHERE topic_id = v_topic AND is_current AND status = 'published'
     AND revision = 1 AND version = 1 AND change_class = 'substantive' AND rung_map IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0042: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
  END IF;

  -- five distinct stance-revision values on the current revision
  SELECT count(DISTINCT sr.value) INTO v_n
    FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0042: expected 5 stance revisions, got %', v_n; END IF;

  -- five legacy stances (corpus 5:5 invariant)
  SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0042: expected 5 legacy stances, got %', v_n; END IF;

  -- exactly the three requested role rows: federal, state, local (never judicial)
  SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
  IF v_n <> 3 THEN RAISE EXCEPTION 'CA_0042: expected exactly 3 role rows, got %', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'federal')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'state')
     OR NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'local') THEN
    RAISE EXCEPTION 'CA_0042: expected federal + state + local role rows';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = v_topic AND role_scope = 'judicial') THEN
    RAISE EXCEPTION 'CA_0042: unexpected judicial role row';
  END IF;

  -- polarity guard: value 1 is the maximum-transparency pole, value 5 the no-disclosure pole
  SELECT sr.text INTO v_t1 FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 1;
  SELECT sr.text INTO v_t5 FROM inform.compass_stance_revisions sr
    JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
   WHERE r.topic_id = v_topic AND r.is_current AND sr.value = 5;
  IF v_t1 NOT ILIKE '%real-time%' OR v_t5 NOT ILIKE '%no public disclosure%' THEN
    RAISE EXCEPTION 'CA_0042: polarity check failed (v1=%, v5=%)', v_t1, v_t5;
  END IF;

  -- category assigned
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_categories
                 WHERE topic_id = v_topic AND category_id = '6e958103-8877-4421-9279-39e96e00e6f9') THEN
    RAISE EXCEPTION 'CA_0042: category not assigned';
  END IF;

  -- must NOT be live: no season pins it, so the season-gated promoted view must not list it
  IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
    RAISE EXCEPTION 'CA_0042: topic leaked into an open season before being pinned';
  END IF;

  RAISE NOTICE 'CA_0042 OK — campaign-transparency staged & UNPINNED (1 published/current v1, 5 rungs, 5 legacy, 3 roles, polarity 1=real-time/5=none, category set, not promoted)';
END $$;

COMMIT;
