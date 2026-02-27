BEGIN;

-- =============================================================================
-- Migration 015: inform schema — 9 tables + indexes + ALTER connected_profiles
-- =============================================================================
-- New schema:  inform
-- New tables:  compass_categories, compass_topics, compass_topic_categories,
--              compass_topic_roles, compass_stances, compass_responses,
--              compass_change_history, politicians, politician_answers,
--              politician_context
-- ALTER:       connect.connected_profiles (completed_onboarding, selected_topic_ids)
--
-- Design notes:
--   - is_active on compass_topics is a GENERATED column mirroring is_live.
--     Phase 3 connect.ts queries WHERE is_active = true — backward compat shim.
--   - version column on compass_topics defaults to 1.
--     Phase 3 compass-import.ts references .version on topic objects.
--   - went_live_at on compass_topics is NULL for seeded topics.
--     Phase 7 calibration lapse cron uses this for the 30-day window.
--   - compass_responses composite PK (user_id, topic_id) serves double duty
--     as the UNIQUE constraint for ON CONFLICT UPSERT in compassService.ts.
--   - compass_change_history is append-only — no updated_at column.
--   - No INSERT/UPDATE/DELETE RLS on compass_responses or compass_change_history;
--     all writes go through the service layer (pg pool) and SECURITY DEFINER RPCs.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. inform.compass_categories
-- Reference table for grouping compass topics by theme.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_categories (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title      TEXT        NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- -----------------------------------------------------------------------------
-- 2. inform.compass_topics
-- Core calibration topics. is_active is a GENERATED column (Phase 3 compat).
-- went_live_at is NULL for manually seeded topics; set when is_live flips true
-- via admin action (Phase 7 wires this to the lapse 30-day window).
-- -----------------------------------------------------------------------------

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


-- -----------------------------------------------------------------------------
-- 3. inform.compass_topic_categories (m2m join table)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_topic_categories (
  topic_id    UUID NOT NULL REFERENCES inform.compass_topics(id)    ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES inform.compass_categories(id) ON DELETE CASCADE,
  PRIMARY KEY (topic_id, category_id)
);


-- -----------------------------------------------------------------------------
-- 4. inform.compass_topic_roles
-- Role-scoped topic applicability for completeness filtering (GET /compass/progress).
-- role_scope values: 'city_council', 'state_legislature', 'us_congress', 'president'
-- is_required = true means the topic is mandatory for completeness in that role.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_topic_roles (
  topic_id   UUID    NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  role_scope TEXT    NOT NULL,
  is_required BOOLEAN NOT NULL DEFAULT true,
  PRIMARY KEY (topic_id, role_scope)
);


-- -----------------------------------------------------------------------------
-- 5. inform.compass_stances
-- 5 stances per topic, values 1–5 (strongly disagree → strongly agree).
-- UNIQUE (topic_id, value) enforces one stance per value per topic.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_stances (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  value    INT  NOT NULL CHECK (value BETWEEN 1 AND 5),
  text     TEXT NOT NULL,
  UNIQUE (topic_id, value)
);


-- -----------------------------------------------------------------------------
-- 6. inform.compass_responses
-- Per-user calibration record. Composite PK (user_id, topic_id) is the UNIQUE
-- constraint used by ON CONFLICT upserts in the service layer.
-- visibility defaults to 'private'; set to 'public' on empowerment (RPC).
-- inverted = true means the user answered with the scale inverted — persisted
-- server-side (not localStorage) per Phase 4 decision.
-- No INSERT/UPDATE/DELETE RLS policies — all writes via pg pool / SECURITY DEFINER.
-- -----------------------------------------------------------------------------

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


-- -----------------------------------------------------------------------------
-- 7. inform.compass_change_history
-- Append-only audit log of every value change (including initial calibration).
-- old_value is NULL when the user calibrates a topic for the first time.
-- NO updated_at — this is an immutable audit record, never modified after insert.
-- All inserts via pg pool / SECURITY DEFINER — no INSERT RLS policy.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.compass_change_history (
  id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id   UUID        NOT NULL REFERENCES public.users(id)          ON DELETE CASCADE,
  topic_id  UUID        NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  old_value INT,        -- NULL on first calibration
  new_value INT         NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- -----------------------------------------------------------------------------
-- 8. inform.politicians
-- Candidate/politician registry used by the comparison feature.
-- is_active = false hides from public listing without deleting the record.
-- -----------------------------------------------------------------------------

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


-- -----------------------------------------------------------------------------
-- 9. inform.politician_answers
-- Politician's recorded stance per topic. Composite PK ensures one stance per
-- (politician, topic) pair. Admin-managed via Phase 7 routes.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.politician_answers (
  politician_id UUID NOT NULL REFERENCES inform.politicians(id)     ON DELETE CASCADE,
  topic_id      UUID NOT NULL REFERENCES inform.compass_topics(id)  ON DELETE CASCADE,
  value         INT  NOT NULL CHECK (value BETWEEN 1 AND 5),
  PRIMARY KEY (politician_id, topic_id)
);


-- -----------------------------------------------------------------------------
-- 10. inform.politician_context
-- Reasoning and source citations for a politician's stance on a specific topic.
-- Admin-managed via Phase 7 routes.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS inform.politician_context (
  politician_id UUID     NOT NULL REFERENCES inform.politicians(id)    ON DELETE CASCADE,
  topic_id      UUID     NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  reasoning     TEXT     NOT NULL,
  sources       TEXT[]   NOT NULL DEFAULT '{}',
  PRIMARY KEY (politician_id, topic_id)
);


-- =============================================================================
-- Indexes
-- =============================================================================

-- Partial index: live topics only (most queries filter is_live = true)
CREATE INDEX idx_compass_topics_is_live
  ON inform.compass_topics(is_live)
  WHERE is_live = true;

-- Role-scope lookups for GET /compass/progress with ?role= param
CREATE INDEX idx_compass_topic_roles_scope
  ON inform.compass_topic_roles(role_scope);

-- User's own responses — primary access pattern for GET /compass/answers
CREATE INDEX idx_compass_responses_user_id
  ON inform.compass_responses(user_id);

-- Change history: user-scoped queries
CREATE INDEX idx_compass_change_history_user
  ON inform.compass_change_history(user_id);

-- Change history: user+topic (point lookup for last change on a topic)
CREATE INDEX idx_compass_change_history_topic
  ON inform.compass_change_history(user_id, topic_id);

-- Active politicians only (most queries filter is_active = true)
CREATE INDEX idx_politicians_is_active
  ON inform.politicians(is_active)
  WHERE is_active = true;

-- Politician answers by politician (loading a candidate's full stance profile)
CREATE INDEX idx_politician_answers_politician
  ON inform.politician_answers(politician_id);

-- FK columns: PostgreSQL does NOT auto-index FK columns, so we add explicit indexes

-- compass_stances.topic_id — FK to compass_topics (loaded in batch with topics)
CREATE INDEX idx_compass_stances_topic
  ON inform.compass_stances(topic_id);

-- compass_topic_categories.category_id — FK join direction for GET /categories
CREATE INDEX idx_compass_topic_categories_category
  ON inform.compass_topic_categories(category_id);

-- politician_context.topic_id — FK to compass_topics
CREATE INDEX idx_politician_context_topic
  ON inform.politician_context(topic_id);

-- compass_change_history.topic_id — topic-only lookup (admin/analytics)
CREATE INDEX idx_compass_change_history_topic_only
  ON inform.compass_change_history(topic_id);


-- =============================================================================
-- ALTER connect.connected_profiles
-- =============================================================================
-- completed_onboarding: set to true by POST /api/auth/complete-onboarding.
--   The CompassV2 frontend checks this flag to determine whether to show
--   the onboarding flow or skip directly to the calibration dashboard.
-- selected_topic_ids: JSONB array of topic UUIDs saved by PUT /compass/selected-topics.
--   Stored as JSONB for flexible ordering; validated as UUID[] at the application layer.
-- =============================================================================

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS completed_onboarding BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS selected_topic_ids JSONB NOT NULL DEFAULT '[]';


COMMIT;
