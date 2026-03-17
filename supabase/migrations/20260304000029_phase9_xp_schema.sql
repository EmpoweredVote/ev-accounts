BEGIN;

-- =============================================================================
-- Migration 029: Phase 9 XP schema foundation
-- =============================================================================
-- Creates the XP ledger infrastructure: append-only xp_transactions table,
-- denormalized total_xp / current_level columns on connected_profiles, an
-- updated connected_profiles_public view, RLS policies, and grants.
--
-- Design decisions:
--   - xp_transactions is append-only. No UPDATE or DELETE policies exist.
--     All writes go through award_xp() SECURITY DEFINER RPC (migration 030).
--   - Idempotency is enforced at the DB layer via UNIQUE on idempotency_key.
--     The application passes a deterministic key so duplicate deliveries are
--     silently ignored rather than double-credited.
--   - total_xp (BIGINT) and current_level (INT) are denormalized on
--     connected_profiles for O(1) reads. The award_xp RPC updates them
--     atomically alongside the ledger insert (advisory lock pattern).
--   - The legacy `xp` column on connected_profiles is NOT touched here.
--     Phase 10 handles the migration to the new columns and its removal.
--   - xp_in_level and xp_to_next_level are computed on read (not stored).
--     Level thresholds: 2k × 3, 3k × 6, 4k × 20, 5k/level thereafter.
-- =============================================================================


-- =============================================================================
-- Section 1: Create connect.xp_transactions table (append-only XP ledger)
-- =============================================================================
-- Mirrors the gem_transactions ledger pattern. Each row is an immutable credit
-- event. No debit rows — XP is never taken away (deferred to content policy).
-- source: identifies the feature that granted XP (e.g., 'compass_answer').
-- amount: positive-only enforced by CHECK constraint.
-- metadata: optional JSONB context for the source feature (e.g., topic_id).
-- idempotency_key: unique per event; prevents double-credit on retries.

CREATE TABLE IF NOT EXISTS connect.xp_transactions (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  source           TEXT        NOT NULL,
  amount           INT         NOT NULL CHECK (amount > 0),
  metadata         JSONB,
  idempotency_key  TEXT        NOT NULL UNIQUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- =============================================================================
-- Section 2: Index for user XP history queries (reverse chronological)
-- =============================================================================
-- Supports GET /api/xp/history (Phase 10) without scanning the full table.
-- The UNIQUE constraint on idempotency_key auto-creates its own index — no
-- additional index is needed for idempotency lookups.

CREATE INDEX IF NOT EXISTS idx_xp_transactions_user_created
  ON connect.xp_transactions(user_id, created_at DESC);


-- =============================================================================
-- Section 3: Add total_xp and current_level to connect.connected_profiles
-- =============================================================================
-- Denormalized balance columns updated atomically by award_xp RPC (migration 030).
-- Defaults to 0 for all existing rows — no backfill needed (Alpha: no XP yet awarded).
-- The legacy `xp` column (Phase 6 placeholder) is intentionally left untouched.
-- Phase 10 will migrate any data and drop the legacy column when ready.

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS total_xp      BIGINT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS current_level INT    NOT NULL DEFAULT 0;


-- =============================================================================
-- Section 4: DROP and recreate connected_profiles_public view
-- =============================================================================
-- DROP + recreate is required because CREATE OR REPLACE cannot reorder or insert
-- new columns in the middle of an existing column list.
-- Re-grant SELECT to authenticated after DROP (DROP removes inherited grants).
-- Columns added: total_xp, current_level (after legacy xp, before gem_balance).
-- tolerance_rating remains intentionally OMITTED — blocked at the view layer.
-- legal_name and home_address also OMITTED (internal-only fields).

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
    -- tolerance_rating intentionally OMITTED (internal field, blocked at view layer)
    deleted_at,
    created_at,
    updated_at
  FROM connect.connected_profiles
  WHERE deleted_at IS NULL;

GRANT SELECT ON connect.connected_profiles_public TO authenticated;


-- =============================================================================
-- Section 5: Enable RLS on xp_transactions
-- =============================================================================
-- RLS is required on all user-data tables in the connect schema.
-- Without RLS, any authenticated user could read all XP records.

ALTER TABLE connect.xp_transactions ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- Section 6: RLS policy — owner read only
-- =============================================================================
-- Authenticated users may only SELECT their own XP transaction history.
-- No INSERT, UPDATE, or DELETE policies exist on this table — all writes go
-- through award_xp() SECURITY DEFINER RPC which bypasses RLS entirely.

CREATE POLICY "xp_transactions: owner read"
  ON connect.xp_transactions
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);


-- =============================================================================
-- Section 7: GRANT SELECT on xp_transactions to authenticated and anon
-- =============================================================================
-- authenticated: enables owner-filtered SELECT via the RLS policy above.
-- anon: GRANT prevents a permission-denied error on unauthenticated queries.
--   No anon RLS policy exists, so anon always receives an empty result set
--   rather than a 403. This matches the empty-set-over-error convention used
--   elsewhere in the connect schema.

GRANT SELECT ON connect.xp_transactions TO authenticated;
GRANT SELECT ON connect.xp_transactions TO anon;
GRANT SELECT ON connect.xp_transactions TO service_role;


COMMIT;
