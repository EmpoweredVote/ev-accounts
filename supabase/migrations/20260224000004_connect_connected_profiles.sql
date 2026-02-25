BEGIN;

-- Migration 004: connect.connected_profiles
--
-- Core tier-2 table. A connected_profiles row existing = user is a Connected member.
-- Tier is determined by child record presence, NEVER a status flag.
--
-- tolerance_rating: INTERNAL ONLY — never returned to non-owning users.
--   Enforced at BOTH the RLS/view layer (migration 008) AND the application
--   serialization layer. Tests MUST assert absence, not just null.
--
-- account_standing: ('active', 'suspended', 'quarantined') — all 3 values included
--   now to avoid ALTER TYPE on a populated table later (FOUND-09 + CONTEXT.md).
--   Both 'suspended' and 'quarantined' have the same lockout level; semantic
--   distinction (reason/origin) belongs to the Communal Council feature repo.
--
-- deleted_at: soft delete support; NULL = active.

CREATE TABLE IF NOT EXISTS connect.connected_profiles (
  id                  UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID    NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  display_name        TEXT    NOT NULL,
  account_standing    TEXT    NOT NULL DEFAULT 'active'
    CHECK (account_standing IN ('active', 'suspended', 'quarantined')),
  verification_status TEXT    NOT NULL DEFAULT 'pending'
    CHECK (verification_status IN ('pending', 'verified', 'suspended')),
  verification_method TEXT,
  verified_region     TEXT,
  xp                  INTEGER NOT NULL DEFAULT 0,
  gem_balance         INTEGER NOT NULL DEFAULT 0,
  gem_reserve_cap     INTEGER NOT NULL DEFAULT 1000,
  veracity_rating     NUMERIC(4,2),
  tolerance_rating    NUMERIC(4,2),     -- NEVER returned to non-owning users
  deleted_at          TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Primary lookup index
CREATE INDEX IF NOT EXISTS idx_connected_profiles_user_id
  ON connect.connected_profiles(user_id);

-- Partial index: quickly identify non-active accounts without scanning the full table.
-- Most rows will be 'active'; this index stays small and performant.
CREATE INDEX IF NOT EXISTS idx_connected_profiles_standing
  ON connect.connected_profiles(account_standing)
  WHERE account_standing != 'active';

-- Partial index: soft-delete aware queries; filters to active (non-deleted) rows.
CREATE INDEX IF NOT EXISTS idx_connected_profiles_not_deleted
  ON connect.connected_profiles(user_id)
  WHERE deleted_at IS NULL;

COMMIT;
