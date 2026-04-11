BEGIN;

-- =============================================================================
-- Migration 059: Topic Scoping Data Foundation
-- =============================================================================
-- Adds tier flag infrastructure (CHECK + UNIQUE on existing compass_topic_roles),
-- adds office_scope metadata column to compass_topics, and adds a
-- policy_engagement_level enum + column on essentials.chambers.
--
-- Spec: docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md
-- Plan: docs/superpowers/plans/2026-04-11-plan-a-topic-scoping-data-foundation.md
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: Constrain compass_topic_roles.role_scope to tier values
-- ---------------------------------------------------------------------------
-- The table already exists and is queried by compassService.getCompassTopics.
-- It is empty in the data. We constrain role_scope so future inserts must
-- use one of the three valid tier values.

DO $$ BEGIN
  ALTER TABLE inform.compass_topic_roles
    ADD CONSTRAINT chk_role_scope_tier
    CHECK (role_scope IN ('federal', 'state', 'local'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Section 2: Unique constraint on (topic_id, role_scope)
-- ---------------------------------------------------------------------------
-- Prevents duplicate rows for the same (topic, tier) pair. This also makes
-- the ON CONFLICT clause in the backfill script work cleanly.

DO $$ BEGIN
  ALTER TABLE inform.compass_topic_roles
    ADD CONSTRAINT uq_compass_topic_roles_topic_scope
    UNIQUE (topic_id, role_scope);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Section 3: Add office_scope column to compass_topics
-- ---------------------------------------------------------------------------
-- Optional metadata for topics primarily relevant to specific office types
-- (e.g., bail reform for judges, curriculum for school boards). NULL means
-- "cross-cutting." Array values reference district_type enum values.
-- Informational only — never used as a render filter per spec principle #2.

ALTER TABLE inform.compass_topics
  ADD COLUMN IF NOT EXISTS office_scope TEXT[] NULL;

-- ---------------------------------------------------------------------------
-- Section 4: Create policy_engagement_level enum
-- ---------------------------------------------------------------------------
-- Distinguishes policy-making offices (compass applies) from administrative
-- offices (no compass) and retention judges (track record, not positions).

DO $$ BEGIN
  CREATE TYPE essentials.policy_engagement_level AS ENUM ('full', 'record_only', 'none');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Section 5: Add policy_engagement_level column to essentials.chambers
-- ---------------------------------------------------------------------------
-- Default 'full' preserves current behavior — every existing chamber gets the
-- policy-making treatment until the backfill script overrides specific ones.

ALTER TABLE essentials.chambers
  ADD COLUMN IF NOT EXISTS policy_engagement_level essentials.policy_engagement_level NOT NULL DEFAULT 'full';

COMMIT;
