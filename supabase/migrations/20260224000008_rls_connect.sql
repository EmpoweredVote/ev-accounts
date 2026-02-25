BEGIN;

-- Migration 008: RLS policies for the connect schema
--
-- Design decisions (from CONTEXT.md):
--   - connected_profiles: tier status (existence) is public to any authenticated user.
--     However, tolerance_rating MUST be blocked at BOTH the RLS/view layer AND the
--     application serialization layer. Tests must assert ABSENCE, not just NULL.
--
-- Implementation approach for tolerance_rating masking:
--   - Base table (connect.connected_profiles): owner-only policy (full row including
--     tolerance_rating). Non-owners have no direct base table access.
--   - Public view (connect.connected_profiles_public): excludes tolerance_rating entirely.
--     Any authenticated user can read this view. The column simply does not exist on it.
--   - This satisfies "tests must assert absence" — querying tolerance_rating on the view
--     is a SQL error (column not found), not a NULL return.

-- -------------------------------------------------------------------------
-- connect.connected_profiles (base table — owner-only)
-- -------------------------------------------------------------------------
ALTER TABLE connect.connected_profiles ENABLE ROW LEVEL SECURITY;

-- Owner sees their full row including tolerance_rating
CREATE POLICY "connected_profiles: owner select"
  ON connect.connected_profiles
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id AND deleted_at IS NULL);

-- -------------------------------------------------------------------------
-- connect.connected_profiles_public (split-visibility view)
-- -------------------------------------------------------------------------
-- Non-owning authenticated users use this view. tolerance_rating is absent.
-- Columns exposed: everything EXCEPT tolerance_rating.
-- Future phases that need another user's connected profile MUST use this view.

CREATE OR REPLACE VIEW connect.connected_profiles_public AS
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
    gem_reserve_cap,
    veracity_rating,
    -- tolerance_rating intentionally OMITTED (internal field, blocked at view layer)
    deleted_at,
    created_at,
    updated_at
  FROM connect.connected_profiles
  WHERE deleted_at IS NULL;

-- Grant SELECT on the view to authenticated users.
-- Views run with owner (postgres) permissions, bypassing RLS on connect.connected_profiles.
-- tolerance_rating is excluded structurally (column absent from view definition).
-- Row restriction (deleted_at IS NULL) is enforced by the view definition itself.
GRANT SELECT ON connect.connected_profiles_public TO authenticated;

-- -------------------------------------------------------------------------
-- connect.verification_sessions (owner-only)
-- -------------------------------------------------------------------------
ALTER TABLE connect.verification_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "verification_sessions: owner select"
  ON connect.verification_sessions
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "verification_sessions: owner insert"
  ON connect.verification_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "verification_sessions: owner update"
  ON connect.verification_sessions
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- -------------------------------------------------------------------------
-- connect.peer_connections (participant read)
-- -------------------------------------------------------------------------
ALTER TABLE connect.peer_connections ENABLE ROW LEVEL SECURITY;

-- Both requester and addressee can see the connection record
CREATE POLICY "peer_connections: participant read"
  ON connect.peer_connections
  FOR SELECT
  TO authenticated
  USING (
    (select auth.uid()) = requester_id
    OR (select auth.uid()) = addressee_id
  );

CREATE POLICY "peer_connections: requester insert"
  ON connect.peer_connections
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = requester_id);

CREATE POLICY "peer_connections: participant update"
  ON connect.peer_connections
  FOR UPDATE
  TO authenticated
  USING (
    (select auth.uid()) = requester_id
    OR (select auth.uid()) = addressee_id
  )
  WITH CHECK (
    (select auth.uid()) = requester_id
    OR (select auth.uid()) = addressee_id
  );

-- -------------------------------------------------------------------------
-- connect.account_follows (follower/followed read)
-- -------------------------------------------------------------------------
ALTER TABLE connect.account_follows ENABLE ROW LEVEL SECURITY;

-- Follower sees their own outbound follows
CREATE POLICY "account_follows: follower read own follows"
  ON connect.account_follows
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = follower_id);

-- Followed user sees who follows them (for Phase 6 social features)
CREATE POLICY "account_follows: followed sees followers"
  ON connect.account_follows
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = followed_id);

CREATE POLICY "account_follows: follower insert"
  ON connect.account_follows
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = follower_id);

CREATE POLICY "account_follows: follower delete"
  ON connect.account_follows
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = follower_id);

-- -------------------------------------------------------------------------
-- connect.gem_transactions (owner read-only; append-only for non-service-role)
-- -------------------------------------------------------------------------
ALTER TABLE connect.gem_transactions ENABLE ROW LEVEL SECURITY;

-- Owners can read their own transaction history
CREATE POLICY "gem_transactions: owner read"
  ON connect.gem_transactions
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- No INSERT policy for non-service-role:
--   All gem transactions are written via SECURITY DEFINER RPC functions
--   (debit check + ledger update must be atomic). Service role client handles writes.

COMMIT;
