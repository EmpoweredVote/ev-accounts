BEGIN;

-- =============================================================================
-- Migration 021: Phase 6 unified social_relationships table
-- =============================================================================
-- Replaces two separate Phase 1 tables:
--   - connect.peer_connections   (bidirectional connection requests)
--   - connect.account_follows    (unidirectional follows)
-- with a single unified connect.social_relationships table using a
-- connection_type discriminator column.
--
-- Design rationale:
--   - One table simplifies the friends-visibility RLS join (migration 022):
--     a single EXISTS subquery covers both follow and peer context.
--   - The connection_type column enables different semantics:
--       'follow' — unidirectional, no approval, status IS NULL
--       'peer'   — bidirectional, requires state machine (pending/accepted/declined/blocked)
--   - The chk_peer_has_status constraint enforces this invariant at the DB level.
--   - UNIQUE(actor_id, target_id, connection_type) prevents duplicate follow/peer rows.
--
-- Data migration:
--   - Existing peer_connections rows are migrated (requester → actor, addressee → target).
--   - Existing account_follows rows are migrated (follower → actor, followed → target).
--   - Old tables are dropped with CASCADE (removes their RLS policies and grants).
--
-- Phase 6 write path:
--   - 'peer' rows: written exclusively via connect.create_peer_request SECURITY DEFINER RPC
--     (migration 023) to enforce bidirectional block checks.
--   - 'follow' rows: written by service layer (pg pool) — no RLS INSERT policy,
--     no SECURITY DEFINER needed (follow is unilateral, no block check required here;
--     block enforcement is on peer requests only per CONTEXT.md decisions).
-- =============================================================================


-- =============================================================================
-- Section 1: Create connect.social_relationships
-- =============================================================================

CREATE TABLE IF NOT EXISTS connect.social_relationships (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id        UUID    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_id       UUID    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  connection_type TEXT    NOT NULL CHECK (connection_type IN ('follow', 'peer')),
  -- status: NULL for follows (no approval needed), state-machine for peers
  status          TEXT    CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Peers must have a status; follows must not
  CONSTRAINT chk_peer_has_status CHECK (
    (connection_type = 'peer'   AND status IS NOT NULL) OR
    (connection_type = 'follow' AND status IS NULL)
  ),

  -- Self-relationships are never valid
  CONSTRAINT chk_no_self_relationship CHECK (actor_id != target_id),

  -- One row per (actor, target, type) pair — prevents duplicate follows and duplicate
  -- peer requests. The create_peer_request RPC handles the declined-resend edge case
  -- by deleting the old declined row before inserting a fresh pending row.
  UNIQUE (actor_id, target_id, connection_type)
);


-- =============================================================================
-- Section 2: Indexes
-- =============================================================================
-- Actor and target lookups — standard FK coverage
CREATE INDEX IF NOT EXISTS idx_social_rel_actor
  ON connect.social_relationships(actor_id);

CREATE INDEX IF NOT EXISTS idx_social_rel_target
  ON connect.social_relationships(target_id);

-- Peer lookups by actor (for "my pending requests", "my accepted peers")
CREATE INDEX IF NOT EXISTS idx_social_rel_peers
  ON connect.social_relationships(actor_id, target_id)
  WHERE connection_type = 'peer';

-- MANDATORY: accepted peers index for friends-visibility RLS policy (migration 022).
-- The compass_responses "friends select" RLS policy performs an EXISTS subquery
-- on social_relationships WHERE connection_type='peer' AND status='accepted'.
-- Without this index, every compass response read triggers a sequential scan of
-- the full social_relationships table.
CREATE INDEX IF NOT EXISTS idx_social_rel_accepted
  ON connect.social_relationships(actor_id, target_id)
  WHERE connection_type = 'peer' AND status = 'accepted';

-- Follow lookups by target (for follower count on Empowered profiles)
CREATE INDEX IF NOT EXISTS idx_social_rel_follows
  ON connect.social_relationships(target_id)
  WHERE connection_type = 'follow';


-- =============================================================================
-- Section 3: Data migration from old tables → new table
-- =============================================================================
-- Migrate peer_connections: requester→actor, addressee→target, preserve status.
-- ON CONFLICT DO NOTHING is a safety net (table is empty in Alpha, but safe
-- to run idempotently in case this migration is replayed).

INSERT INTO connect.social_relationships
  (actor_id, target_id, connection_type, status, created_at, updated_at)
SELECT
  requester_id,
  addressee_id,
  'peer',
  status,
  created_at,
  updated_at
FROM connect.peer_connections
ON CONFLICT (actor_id, target_id, connection_type) DO NOTHING;

-- Migrate account_follows: follower→actor, followed→target, status NULL (follows have no status).
INSERT INTO connect.social_relationships
  (actor_id, target_id, connection_type, status, created_at, updated_at)
SELECT
  follower_id,
  followed_id,
  'follow',
  NULL,
  created_at,
  created_at  -- account_follows has no updated_at column; use created_at for both
FROM connect.account_follows
ON CONFLICT (actor_id, target_id, connection_type) DO NOTHING;

-- Drop old tables. CASCADE removes their associated RLS policies and grants.
-- These tables are fully replaced by connect.social_relationships.
DROP TABLE IF EXISTS connect.peer_connections CASCADE;
DROP TABLE IF EXISTS connect.account_follows CASCADE;


COMMIT;
