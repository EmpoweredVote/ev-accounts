BEGIN;

-- =============================================================================
-- Migration 019: Phase 6 gem schema extension
-- =============================================================================
-- Extends connect.gem_transactions with a gem_type column to support three
-- distinct gem currencies: red (impact), blue (value), yellow (predictive).
--
-- Adds per-type denormalized balance columns to connect.connected_profiles so
-- that balance reads are O(1) without summing the full ledger. The SECURITY
-- DEFINER RPCs (migration 023) maintain these atomically alongside ledger inserts.
--
-- Updates connect.connected_profiles_public view to expose the new balance columns.
-- The existing GRANT SELECT on the view (migration 008) remains valid after
-- CREATE OR REPLACE — Postgres preserves view grants on replacement.
--
-- XP: the existing `xp` column on connected_profiles serves as the XP placeholder
-- for Phase 6. No xp_total or separate XP ledger is added — deferred until use
-- cases are clearer (CONTEXT.md decision).
--
-- Reserve cap: NOT added here — deferred until spending mechanics are designed.
-- =============================================================================


-- =============================================================================
-- Section 1: Add gem_type column to connect.gem_transactions
-- =============================================================================
-- DEFAULT 'blue' handles any existing rows (Alpha: no production data).
-- After the ALTER, the default is removed — future inserts must specify gem_type
-- explicitly (enforced by the credit_gems / debit_gems RPCs in migration 023).

ALTER TABLE connect.gem_transactions
  ADD COLUMN gem_type TEXT NOT NULL DEFAULT 'blue'
    CHECK (gem_type IN ('red', 'blue', 'yellow'));

ALTER TABLE connect.gem_transactions ALTER COLUMN gem_type DROP DEFAULT;


-- =============================================================================
-- Section 2: Add per-type gem balance columns to connect.connected_profiles
-- =============================================================================
-- Denormalized balance per gem type. Atomically updated by credit_gems /
-- debit_gems SECURITY DEFINER RPCs (migration 023).
-- The existing gem_balance column (single total) is preserved for backward
-- compatibility — it is not updated by Phase 6 RPCs and may be deprecated later.

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS gem_balance_red    INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS gem_balance_blue   INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS gem_balance_yellow INTEGER NOT NULL DEFAULT 0;


-- =============================================================================
-- Section 3: Update connected_profiles_public view to include per-type balances
-- =============================================================================
-- DROP + recreate is required because CREATE OR REPLACE cannot insert new columns
-- in the middle of an existing column list (only append at end is allowed).
-- Re-grant SELECT to authenticated after drop to restore the permission.
-- Columns added: gem_balance_red, gem_balance_blue, gem_balance_yellow.
-- tolerance_rating remains intentionally OMITTED — masked at the view layer.

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
-- Section 4: Index on gem_transactions for per-type history queries
-- =============================================================================
-- Supports GET /api/gems/balance (Phase 6 route) and future per-type history
-- queries without scanning the full user ledger.

CREATE INDEX IF NOT EXISTS idx_gem_transactions_user_type
  ON connect.gem_transactions(user_id, gem_type);


COMMIT;
