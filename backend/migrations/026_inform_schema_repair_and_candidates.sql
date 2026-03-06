-- =============================================================================
-- Migration 026: inform schema repair + new columns (deleted_at, is_candidate)
--
-- This migration is a repair run: migration 015 was recorded as applied in the
-- live database but the inform schema namespace was never created. All CREATE
-- TABLE and CREATE INDEX statements use IF NOT EXISTS so the migration is safe
-- to run on a database where the inform tables already exist.
--
-- Net new changes on top of migration 015:
--   1. ALTER inform.compass_responses  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ
--   2. ALTER inform.politicians        ADD COLUMN IF NOT EXISTS is_candidate BOOLEAN
--   3. CREATE INDEX idx_compass_responses_user_active (partial, WHERE deleted_at IS NULL)
-- =============================================================================

-- =============================================================================
-- 1. Schema namespace
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS inform;


-- =============================================================================
-- 2. Tables (idempotent — safe on DBs that already have these tables)
-- =============================================================================

-- ----------------------------------------------------------------------------
-- inform.compass_categories
-- Reference table for grouping compass topics by theme.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_categories (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title      TEXT        NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- inform.compass_topics
-- Core calibration topics. is_active is a GENERATED column (Phase 3 compat).
-- went_live_at is NULL for manually seeded topics; set when is_live flips true
-- via admin action (Phase 7 wires this to the lapse 30-day window).
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_topics (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT        NOT NULL,
  short_title   TEXT,
  question_text TEXT        NOT NULL,
  is_live       BOOLEAN     NOT NULL DEFAULT false,
  -- Phase 3 connect.ts backward compat: queries WHERE is_active = true
  is_active     BOOLEAN     GENERATED ALWAYS AS (is_live) STORED,
  -- Phase 3 compass-import: references .version on topic objects
  version       INT         NOT NULL DEFAULT 1,
  -- Phase 7 lapse window: NULL for manually seeded topics
  went_live_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- inform.compass_topic_categories (m2m join table)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_topic_categories (
  topic_id    UUID NOT NULL REFERENCES inform.compass_topics(id)    ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES inform.compass_categories(id) ON DELETE CASCADE,
  PRIMARY KEY (topic_id, category_id)
);


-- ----------------------------------------------------------------------------
-- inform.compass_topic_roles
-- Role-scoped topic applicability for completeness filtering.
-- role_scope values: 'city_council', 'state_legislature', 'us_congress', 'president'
-- is_required = true means the topic is mandatory for completeness in that role.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_topic_roles (
  topic_id    UUID    NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  role_scope  TEXT    NOT NULL,
  is_required BOOLEAN NOT NULL DEFAULT true,
  PRIMARY KEY (topic_id, role_scope)
);


-- ----------------------------------------------------------------------------
-- inform.compass_stances
-- 5 stances per topic, values 1–5 (strongly disagree → strongly agree).
-- UNIQUE (topic_id, value) enforces one stance per value per topic.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_stances (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  value    INT  NOT NULL CHECK (value BETWEEN 1 AND 5),
  text     TEXT NOT NULL,
  UNIQUE (topic_id, value)
);


-- ----------------------------------------------------------------------------
-- inform.compass_responses
-- Per-user calibration record. Composite PK (user_id, topic_id) is the UNIQUE
-- constraint used by ON CONFLICT upserts in the service layer.
-- visibility defaults to 'private'; set to 'public' on empowerment (RPC).
-- inverted = true means the user answered with the scale inverted — persisted
-- server-side (not localStorage) per Phase 4 decision.
-- deleted_at: soft-delete column added in migration 026. NULL = active record.
-- No INSERT/UPDATE/DELETE RLS policies — all writes via SECURITY DEFINER.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_responses (
  user_id        UUID        NOT NULL REFERENCES public.users(id)          ON DELETE CASCADE,
  topic_id       UUID        NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  value          INT         NOT NULL CHECK (value BETWEEN 1 AND 5),
  write_in_text  TEXT,
  visibility     TEXT        NOT NULL DEFAULT 'private'
                             CHECK (visibility IN ('private', 'friends', 'public')),
  inverted       BOOLEAN     NOT NULL DEFAULT false,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, topic_id)
);


-- ----------------------------------------------------------------------------
-- inform.compass_change_history
-- Append-only audit log of every value change (including initial calibration).
-- old_value is NULL when the user calibrates a topic for the first time.
-- NO updated_at — this is an immutable audit record, never modified after insert.
-- All inserts via SECURITY DEFINER — no INSERT RLS policy.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_change_history (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES public.users(id)          ON DELETE CASCADE,
  topic_id   UUID        NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  old_value  INT,        -- NULL on first calibration
  new_value  INT         NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- inform.politicians
-- Candidate/politician registry used by the comparison feature.
-- is_active = false hides from public listing without deleting the record.
-- is_candidate: added in migration 026. true = the politician is a current
--   candidate eligible for ZIP-based discovery in the candidate pages feature.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.politicians (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name       TEXT        NOT NULL,
  last_name        TEXT        NOT NULL,
  preferred_name   TEXT,
  full_name        TEXT,
  office_title     TEXT,
  photo_origin_url TEXT,
  is_active        BOOLEAN     NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ----------------------------------------------------------------------------
-- inform.politician_answers
-- Politician's recorded stance per topic. Composite PK ensures one stance per
-- (politician, topic) pair. Admin-managed via Phase 7 routes.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.politician_answers (
  politician_id UUID NOT NULL REFERENCES inform.politicians(id)     ON DELETE CASCADE,
  topic_id      UUID NOT NULL REFERENCES inform.compass_topics(id)  ON DELETE CASCADE,
  value         INT  NOT NULL CHECK (value BETWEEN 1 AND 5),
  PRIMARY KEY (politician_id, topic_id)
);


-- ----------------------------------------------------------------------------
-- inform.politician_context
-- Reasoning and source citations for a politician's stance on a specific topic.
-- Admin-managed via Phase 7 routes.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.politician_context (
  politician_id UUID   NOT NULL REFERENCES inform.politicians(id)    ON DELETE CASCADE,
  topic_id      UUID   NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  reasoning     TEXT   NOT NULL,
  sources       TEXT[] NOT NULL DEFAULT '{}',
  PRIMARY KEY (politician_id, topic_id)
);


-- =============================================================================
-- 3. Indexes from migration 015 (idempotent — IF NOT EXISTS)
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_compass_topics_is_live
  ON inform.compass_topics(is_live)
  WHERE is_live = true;

CREATE INDEX IF NOT EXISTS idx_compass_topic_roles_scope
  ON inform.compass_topic_roles(role_scope);

CREATE INDEX IF NOT EXISTS idx_compass_responses_user_id
  ON inform.compass_responses(user_id);

CREATE INDEX IF NOT EXISTS idx_compass_change_history_user
  ON inform.compass_change_history(user_id);

CREATE INDEX IF NOT EXISTS idx_compass_change_history_topic
  ON inform.compass_change_history(user_id, topic_id);

CREATE INDEX IF NOT EXISTS idx_politicians_is_active
  ON inform.politicians(is_active)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_politician_answers_politician
  ON inform.politician_answers(politician_id);

CREATE INDEX IF NOT EXISTS idx_compass_stances_topic
  ON inform.compass_stances(topic_id);

CREATE INDEX IF NOT EXISTS idx_compass_topic_categories_category
  ON inform.compass_topic_categories(category_id);

CREATE INDEX IF NOT EXISTS idx_politician_context_topic
  ON inform.politician_context(topic_id);

CREATE INDEX IF NOT EXISTS idx_compass_change_history_topic_only
  ON inform.compass_change_history(topic_id);


-- =============================================================================
-- 4. New columns (net-new in migration 026)
-- =============================================================================

-- Soft-delete support for compass_responses.
-- NULL = active row. Rows set to non-NULL are excluded from active queries.
-- Enables reset_compass_answers RPC (migration 027) and re-import flow.
ALTER TABLE inform.compass_responses
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Candidate flag for politicians.
-- true = this politician is an active candidate eligible for ZIP-based discovery.
-- Required by Phase 13 compass compare and candidate pages endpoints.
ALTER TABLE inform.politicians
  ADD COLUMN IF NOT EXISTS is_candidate BOOLEAN NOT NULL DEFAULT false;


-- =============================================================================
-- 5. New index for active-response access pattern (migration 026)
-- =============================================================================

-- Partial index covering the most common read pattern: active responses per user.
-- All GET /compass/answers queries filter WHERE deleted_at IS NULL.
CREATE INDEX IF NOT EXISTS idx_compass_responses_user_active
  ON inform.compass_responses(user_id)
  WHERE deleted_at IS NULL;
