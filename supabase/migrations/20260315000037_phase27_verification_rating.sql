BEGIN;

-- =============================================================================
-- Migration 037: Phase 27 Verification Rating schema
-- =============================================================================
-- Adds two new columns to connect.connected_profiles:
--
--   verification_rating  INTEGER NOT NULL DEFAULT 60
--     Numeric score (0–150) representing how verified a user's identity is.
--     CHECK constraint enforces the 0–150 range at the DB layer.
--     Default 60 = "baseline unverified" (below 90 = no Red Gem quests).
--     Phase 28 (VQ Confirmation Flow) adjusts this value when stances
--     are confirmed or challenged by peer validators.
--
--   vq_hold_until  TIMESTAMPTZ (nullable)
--     When non-NULL and in the future, the user is in a "hold" period —
--     they cannot submit new Validation Quest stances.
--     NULL = no hold (normal state). Phase 28 sets this on confirmation events.
--
-- Privacy note on connected_profiles_public view:
--   verification_rating IS included — it is a public stat (users can see
--   each other's rating, same as veracity_rating).
--   vq_hold_until is intentionally OMITTED — it is an internal enforcement
--   state (same privacy pattern as tolerance_rating). Publishing hold state
--   would allow users to predict enforcement windows.
-- =============================================================================


-- =============================================================================
-- Section 1: ALTER TABLE connect.connected_profiles — add new columns
-- =============================================================================

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS verification_rating INTEGER NOT NULL DEFAULT 60
    CHECK (verification_rating >= 0 AND verification_rating <= 150),
  ADD COLUMN IF NOT EXISTS vq_hold_until TIMESTAMPTZ;


-- =============================================================================
-- Section 2: Partial index for hold-state queries
-- =============================================================================
-- Phase 28 needs to efficiently find users currently in a hold period.
-- Only indexes rows where vq_hold_until IS NOT NULL (partial index).
-- Rows with NULL vq_hold_until (the majority) are excluded — smaller index,
-- faster scans.

CREATE INDEX IF NOT EXISTS idx_connected_profiles_vq_hold
  ON connect.connected_profiles(vq_hold_until)
  WHERE vq_hold_until IS NOT NULL;


-- =============================================================================
-- Section 3: DROP and recreate connected_profiles_public view
-- =============================================================================
-- DROP + recreate required because CREATE OR REPLACE cannot insert new columns
-- mid-list. Baseline column order from migration 029 is preserved; only
-- verification_rating is inserted after veracity_rating.
-- tolerance_rating remains intentionally OMITTED (internal field).
-- vq_hold_until is intentionally OMITTED (internal enforcement state).
-- Re-grant SELECT to authenticated after DROP (DROP removes inherited grants).

DROP VIEW IF EXISTS connect.connected_profiles_public;

CREATE VIEW connect.connected_profiles_public AS
  SELECT
    id,
    user_id,
    display_name,
    account_standing,
    verification_status,
    verification_method,
    verified_region,
    xp,
    total_xp,
    current_level,
    gem_balance,
    gem_balance_red,
    gem_balance_blue,
    gem_balance_yellow,
    gem_reserve_cap,
    veracity_rating,
    verification_rating,
    -- tolerance_rating intentionally OMITTED (internal field, blocked at view layer)
    -- vq_hold_until intentionally OMITTED (internal enforcement state)
    deleted_at,
    created_at,
    updated_at
  FROM connect.connected_profiles
  WHERE deleted_at IS NULL;

GRANT SELECT ON connect.connected_profiles_public TO authenticated;


COMMIT;
