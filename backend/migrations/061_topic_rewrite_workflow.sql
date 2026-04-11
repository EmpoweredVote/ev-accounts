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

COMMIT;
