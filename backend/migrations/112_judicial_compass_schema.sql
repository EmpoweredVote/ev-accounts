-- Migration 112: Judicial Compass Schema Foundation
--
-- Phase 27 — Judicial Compass DB
--
-- Change 1: Adds `judicial_role` column to inform.compass_topics to encode sub-role
-- specificity for judicial topics. NULL = universal (applies to all judicial roles:
-- judges and City Attorney/DA alike). Non-NULL values narrow a topic to a specific
-- sub-role.
--
-- Change 2: Expands the CHECK constraint on inform.compass_topic_roles.role_scope
-- to accept 'judicial' as a valid value. Previously constrained to:
--   ('federal', 'state', 'local')
-- Now expanded to:
--   ('federal', 'state', 'local', 'judicial')
--
-- This migration is schema-only — no existing data is modified.

BEGIN;

-- Change 1: Add judicial_role column to inform.compass_topics
ALTER TABLE inform.compass_topics
  ADD COLUMN IF NOT EXISTS judicial_role TEXT
  CHECK (judicial_role IN ('judge', 'city_attorney_da'));
-- NULL = universal (applies to all judicial roles); no default needed (nullable)

-- Change 2: Expand CHECK constraint on inform.compass_topic_roles.role_scope
-- to accept 'judicial' as a valid scope value.
ALTER TABLE inform.compass_topic_roles
  DROP CONSTRAINT IF EXISTS chk_role_scope_tier;

ALTER TABLE inform.compass_topic_roles
  ADD CONSTRAINT chk_role_scope_tier
  CHECK (role_scope IN ('federal', 'state', 'local', 'judicial'));

COMMIT;
