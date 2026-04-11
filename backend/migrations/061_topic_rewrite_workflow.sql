BEGIN;

-- =============================================================================
-- Migration 061: Topic Rewrite Workflow
-- =============================================================================
-- Adds the machinery to safely rewrite a compass topic's framing and stance
-- scale by enforcing two human review gates (framing review, then per-stance
-- re-evaluation). See:
--   docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md
--   docs/superpowers/plans/2026-04-11-plan-d-topic-rewrite-workflow.md
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: Relax the unique index on compass_topics.topic_key
-- ---------------------------------------------------------------------------
-- The current idx_compass_topics_topic_key is UNIQUE on (topic_key) alone,
-- which makes it impossible to stage a new version alongside the live one.
-- Replace with:
--   * UNIQUE (topic_key, version) — each version of a topic is distinct
--   * Partial UNIQUE (topic_key) WHERE is_live = true — only one live version
-- ---------------------------------------------------------------------------

DROP INDEX IF EXISTS inform.idx_compass_topics_topic_key;

CREATE UNIQUE INDEX IF NOT EXISTS idx_compass_topics_topic_key_version
  ON inform.compass_topics (topic_key, version);

CREATE UNIQUE INDEX IF NOT EXISTS idx_compass_topics_topic_key_live
  ON inform.compass_topics (topic_key)
  WHERE is_live = true;

-- ---------------------------------------------------------------------------
-- Section 2: topic_rewrites — the state machine row, one per rewrite attempt
-- ---------------------------------------------------------------------------

DO $$ BEGIN
  CREATE TYPE inform.topic_rewrite_state AS ENUM (
    'draft',
    'pending_framing_review',
    're_evaluation_queue',
    'publish_ready',
    'published',
    'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS inform.topic_rewrites (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_key        TEXT NOT NULL,
  old_topic_id     UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE RESTRICT,
  new_topic_id     UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE RESTRICT,
  state            inform.topic_rewrite_state NOT NULL DEFAULT 'draft',
  created_by       UUID REFERENCES public.users(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  framing_approved_by   UUID REFERENCES public.users(id),
  framing_approved_at   TIMESTAMPTZ,
  published_by     UUID REFERENCES public.users(id),
  published_at     TIMESTAMPTZ,
  notes            TEXT
);

-- At most one open rewrite per topic_key (rows in states other than
-- 'published' and 'cancelled'). Prevents parallel rewrites colliding.
CREATE UNIQUE INDEX IF NOT EXISTS idx_topic_rewrites_open_per_key
  ON inform.topic_rewrites (topic_key)
  WHERE state NOT IN ('published', 'cancelled');

CREATE INDEX IF NOT EXISTS idx_topic_rewrites_state
  ON inform.topic_rewrites (state);

-- ---------------------------------------------------------------------------
-- Section 3: topic_rewrite_stance_proposals — per-politician proposed values
-- ---------------------------------------------------------------------------
-- One row per (rewrite_id, politician_id). Seeded from the set of politicians
-- that have an existing politician_answers row for old_topic_id. Each proposal
-- carries the old snapshot (value + reasoning + sources) so the admin UI can
-- render side-by-side without another JOIN.
-- ---------------------------------------------------------------------------

DO $$ BEGIN
  CREATE TYPE inform.stance_proposal_status AS ENUM (
    'pending',
    'approved',
    'rejected'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS inform.topic_rewrite_stance_proposals (
  rewrite_id         UUID NOT NULL REFERENCES inform.topic_rewrites(id) ON DELETE CASCADE,
  politician_id      UUID NOT NULL REFERENCES inform.politicians(id) ON DELETE CASCADE,

  -- Snapshot of the stance under the OLD framing (copied at seed time)
  old_value          INT NOT NULL CHECK (old_value BETWEEN 1 AND 5),
  old_reasoning      TEXT,
  old_sources        TEXT[] NOT NULL DEFAULT '{}',

  -- Proposed stance under the NEW framing (editable until approved)
  proposed_value     NUMERIC CHECK (proposed_value IS NULL OR proposed_value BETWEEN 1 AND 5),
  proposed_reasoning TEXT,
  proposed_sources   TEXT[] NOT NULL DEFAULT '{}',

  status             inform.stance_proposal_status NOT NULL DEFAULT 'pending',
  reviewed_by        UUID REFERENCES public.users(id),
  reviewed_at        TIMESTAMPTZ,
  reviewer_notes     TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

  PRIMARY KEY (rewrite_id, politician_id)
);

CREATE INDEX IF NOT EXISTS idx_stance_proposals_status
  ON inform.topic_rewrite_stance_proposals (rewrite_id, status);

-- ---------------------------------------------------------------------------
-- Section 4: admin_create_topic_rewrite
-- ---------------------------------------------------------------------------
-- Takes a topic_key plus the proposed new framing. Creates a new row in
-- compass_topics with version = old_version + 1, is_live = false, and an
-- accompanying topic_rewrites row in state 'draft'. Also copies the stance
-- scale into compass_stances so the new version is independently editable.
-- Returns the new rewrite_id.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_create_topic_rewrite(
  p_topic_key      TEXT,
  p_actor_id       UUID,
  p_new_title      TEXT,
  p_new_short_title TEXT,
  p_new_question_text TEXT,
  p_new_stances    JSONB,  -- array of {value: int, text: text}
  p_notes          TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old_topic    inform.compass_topics%ROWTYPE;
  v_new_topic_id UUID;
  v_rewrite_id   UUID;
  v_stance       JSONB;
BEGIN
  -- Find the current live version
  SELECT * INTO v_old_topic
  FROM inform.compass_topics
  WHERE topic_key = p_topic_key AND is_live = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_LIVE_TOPIC: topic_key % has no live version', p_topic_key;
  END IF;

  -- Guard: disallow if there is already an open rewrite for this topic_key
  IF EXISTS (
    SELECT 1 FROM inform.topic_rewrites
    WHERE topic_key = p_topic_key
      AND state NOT IN ('published', 'cancelled')
  ) THEN
    RAISE EXCEPTION 'OPEN_REWRITE_EXISTS: an open rewrite already exists for %', p_topic_key;
  END IF;

  -- Insert the new topic version (is_live=false, version bumped)
  INSERT INTO inform.compass_topics (
    topic_key, title, short_title, question_text,
    is_live, version, went_live_at
  ) VALUES (
    p_topic_key, p_new_title, p_new_short_title, p_new_question_text,
    false, v_old_topic.version + 1, NULL
  )
  RETURNING id INTO v_new_topic_id;

  -- Copy the proposed stance scale into compass_stances for the new topic id
  FOR v_stance IN SELECT * FROM jsonb_array_elements(p_new_stances)
  LOOP
    INSERT INTO inform.compass_stances (topic_id, value, text)
    VALUES (
      v_new_topic_id,
      (v_stance->>'value')::int,
      v_stance->>'text'
    );
  END LOOP;

  -- Create the rewrite row in 'draft' state
  INSERT INTO inform.topic_rewrites (
    topic_key, old_topic_id, new_topic_id, state, created_by, notes
  ) VALUES (
    p_topic_key, v_old_topic.id, v_new_topic_id, 'draft', p_actor_id, p_notes
  )
  RETURNING id INTO v_rewrite_id;

  RETURN v_rewrite_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 5: admin_submit_rewrite_for_framing_review
-- ---------------------------------------------------------------------------
-- State transition: draft → pending_framing_review.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_submit_rewrite_for_framing_review(
  p_rewrite_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE inform.topic_rewrites
  SET state = 'pending_framing_review'
  WHERE id = p_rewrite_id AND state = 'draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % is not in draft state', p_rewrite_id;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 6: admin_approve_rewrite_framing
-- ---------------------------------------------------------------------------
-- State transition: pending_framing_review → re_evaluation_queue.
-- Seeds topic_rewrite_stance_proposals with one row per politician that has
-- an existing politician_answers row on the OLD topic. Copies old
-- value/reasoning/sources and leaves proposed_* NULL.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_approve_rewrite_framing(
  p_rewrite_id UUID,
  p_actor_id   UUID
)
RETURNS INT  -- number of stance proposals seeded
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_rewrite       inform.topic_rewrites%ROWTYPE;
  v_seeded_count  INT;
BEGIN
  SELECT * INTO v_rewrite FROM inform.topic_rewrites WHERE id = p_rewrite_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: rewrite % does not exist', p_rewrite_id;
  END IF;

  IF v_rewrite.state <> 'pending_framing_review' THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % must be in pending_framing_review (is %)',
      p_rewrite_id, v_rewrite.state;
  END IF;

  INSERT INTO inform.topic_rewrite_stance_proposals (
    rewrite_id, politician_id, old_value, old_reasoning, old_sources
  )
  SELECT
    p_rewrite_id,
    pa.politician_id,
    pa.value,
    COALESCE(pc.reasoning, ''),
    COALESCE(pc.sources, '{}')
  FROM inform.politician_answers pa
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id
   AND pc.topic_id = pa.topic_id
  WHERE pa.topic_id = v_rewrite.old_topic_id;

  GET DIAGNOSTICS v_seeded_count = ROW_COUNT;

  UPDATE inform.topic_rewrites
  SET state = 're_evaluation_queue',
      framing_approved_by = p_actor_id,
      framing_approved_at = now()
  WHERE id = p_rewrite_id;

  RETURN v_seeded_count;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 7: admin_upsert_stance_proposal
-- ---------------------------------------------------------------------------
-- Writes proposed_value / proposed_reasoning / proposed_sources. Does NOT
-- change status — that requires explicit approve. Only valid while 'pending'.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_upsert_stance_proposal(
  p_rewrite_id   UUID,
  p_politician_id UUID,
  p_proposed_value NUMERIC,
  p_proposed_reasoning TEXT,
  p_proposed_sources TEXT[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE inform.topic_rewrite_stance_proposals
  SET proposed_value     = p_proposed_value,
      proposed_reasoning = p_proposed_reasoning,
      proposed_sources   = COALESCE(p_proposed_sources, '{}'),
      updated_at         = now()
  WHERE rewrite_id = p_rewrite_id
    AND politician_id = p_politician_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND_OR_LOCKED: proposal (%, %) is missing or already decided',
      p_rewrite_id, p_politician_id;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 8: admin_approve_stance_proposal / admin_reject_stance_proposal
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_approve_stance_proposal(
  p_rewrite_id    UUID,
  p_politician_id UUID,
  p_actor_id      UUID,
  p_reviewer_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE inform.topic_rewrite_stance_proposals
  SET status         = 'approved',
      reviewed_by    = p_actor_id,
      reviewed_at    = now(),
      reviewer_notes = p_reviewer_notes,
      updated_at     = now()
  WHERE rewrite_id = p_rewrite_id
    AND politician_id = p_politician_id
    AND status = 'pending'
    AND proposed_value IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID: proposal (%, %) missing, already decided, or has no proposed_value',
      p_rewrite_id, p_politician_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION inform.admin_reject_stance_proposal(
  p_rewrite_id    UUID,
  p_politician_id UUID,
  p_actor_id      UUID,
  p_reviewer_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE inform.topic_rewrite_stance_proposals
  SET status         = 'rejected',
      reviewed_by    = p_actor_id,
      reviewed_at    = now(),
      reviewer_notes = p_reviewer_notes,
      updated_at     = now()
  WHERE rewrite_id = p_rewrite_id
    AND politician_id = p_politician_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID: proposal (%, %) missing or already decided',
      p_rewrite_id, p_politician_id;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 9: admin_mark_rewrite_publish_ready
-- ---------------------------------------------------------------------------
-- State transition: re_evaluation_queue -> publish_ready.
-- Only allowed when every proposal has status IN ('approved','rejected').
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_mark_rewrite_publish_ready(
  p_rewrite_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_pending_count INT;
  v_state         inform.topic_rewrite_state;
BEGIN
  SELECT state INTO v_state FROM inform.topic_rewrites WHERE id = p_rewrite_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: rewrite % does not exist', p_rewrite_id;
  END IF;

  IF v_state <> 're_evaluation_queue' THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % must be in re_evaluation_queue (is %)',
      p_rewrite_id, v_state;
  END IF;

  SELECT count(*) INTO v_pending_count
  FROM inform.topic_rewrite_stance_proposals
  WHERE rewrite_id = p_rewrite_id AND status = 'pending';

  IF v_pending_count > 0 THEN
    RAISE EXCEPTION 'PROPOSALS_PENDING: % proposals still need review', v_pending_count;
  END IF;

  UPDATE inform.topic_rewrites
  SET state = 'publish_ready'
  WHERE id = p_rewrite_id;
END;
$$;

COMMIT;
