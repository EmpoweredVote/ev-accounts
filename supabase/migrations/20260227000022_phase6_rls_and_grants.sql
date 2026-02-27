BEGIN;

-- =============================================================================
-- Migration 022: Phase 6 RLS policies and grants
-- =============================================================================
-- New tables from migrations 019-021 need RLS + grants.
-- Existing tables get additional policies for Phase 6 functionality:
--   - public.user_roles: add owner SELECT policy (previously admin-only)
--   - inform.compass_responses: add friends-visibility and public-visibility policies
--
-- Policy design principles carried from earlier migrations:
--   - (select auth.uid()) subquery form prevents per-row function call overhead
--     and allows Postgres to cache the plan (pattern from migrations 007-009, 014, 016)
--   - No INSERT/UPDATE/DELETE policies on social_relationships — all writes go
--     through SECURITY DEFINER RPCs (create_peer_request) or service layer (pg pool)
--   - friends-visibility MUST include visibility = 'friends' check in USING clause;
--     the EXISTS peer check alone is insufficient (multiple RLS SELECT policies
--     combine with OR — omitting the visibility check would leak 'private' responses)
-- =============================================================================


-- =============================================================================
-- Section 1: RLS for connect.social_relationships
-- =============================================================================

ALTER TABLE connect.social_relationships ENABLE ROW LEVEL SECURITY;

-- Participants (both actor and target) can read their peer relationship rows.
-- Connected users need to see pending requests sent to them (to accept/decline)
-- and accepted connections (for feed access, compass visibility).
CREATE POLICY "social_rel: participant read peers"
  ON connect.social_relationships
  FOR SELECT
  TO authenticated
  USING (
    connection_type = 'peer'
    AND (
      (select auth.uid()) = actor_id OR (select auth.uid()) = target_id
    )
  );

-- Users can read their own outbound follows (to know who they are following).
CREATE POLICY "social_rel: own follows read"
  ON connect.social_relationships
  FOR SELECT
  TO authenticated
  USING (
    connection_type = 'follow'
    AND (select auth.uid()) = actor_id
  );

-- Empowered accounts default to transparency (CONTEXT.md principle):
-- Any authenticated user can see which accounts an Empowered user follows.
-- Empowered = has an active empowered_profiles row (is_active = true).
CREATE POLICY "social_rel: empowered follows public read"
  ON connect.social_relationships
  FOR SELECT
  TO authenticated
  USING (
    connection_type = 'follow'
    AND EXISTS (
      SELECT 1
      FROM empower.empowered_profiles ep
      WHERE ep.user_id = connect.social_relationships.actor_id
        AND ep.is_active = true
    )
  );

-- Followed users can see that they are being followed (for follower count display).
-- The follower LIST is not exposed — only the target can see their own inbound follows.
CREATE POLICY "social_rel: followed sees followers"
  ON connect.social_relationships
  FOR SELECT
  TO authenticated
  USING (
    connection_type = 'follow'
    AND (select auth.uid()) = target_id
  );

-- No INSERT/UPDATE/DELETE policies for social_relationships:
--   - 'peer' rows: exclusively via connect.create_peer_request SECURITY DEFINER RPC
--     (enforces bidirectional block checks, self-request prevention, state validation)
--   - 'follow' rows: written by service layer (pg pool, bypasses RLS)
--   - Updates (accept/decline/block): via service layer pg pool


-- =============================================================================
-- Section 2: RLS for public.roles
-- =============================================================================

ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

-- Roles lookup table is publicly readable by any authenticated user.
-- Callers need to list available roles when assigning or displaying them.
-- is_active filtering is handled at the application layer (inactive rows are
-- legacy ENUM backfill rows, not surfaced to users).
CREATE POLICY "roles: authenticated read"
  ON public.roles
  FOR SELECT
  TO authenticated
  USING (true);


-- =============================================================================
-- Section 3: Update public.user_roles — add owner SELECT policy
-- =============================================================================
-- Migration 007 enabled RLS on user_roles with NO non-service-role policies
-- ("role management is admin-only"). Phase 6 adds user-facing role endpoints
-- (GET /api/roles/mine), requiring users to read their own active role grants.
-- Admin writes still go through service role only — no INSERT/UPDATE/DELETE policies.

CREATE POLICY "user_roles: owner select"
  ON public.user_roles
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);


-- =============================================================================
-- Section 4: Friends and public visibility on inform.compass_responses
-- =============================================================================
-- Migration 016 added "compass_responses: owner select" (owner sees all own rows).
-- Phase 6 adds two SELECT policies for peer-visible and publicly-visible responses.
-- All three policies combine with OR (standard Postgres multi-policy behavior):
--   - owner select:   user sees all their own responses (any visibility value)
--   - friends select: accepted peers see responses where visibility = 'friends'
--   - public select:  any authenticated user sees responses where visibility = 'public'
--
-- CRITICAL: The friends policy MUST include the visibility = 'friends' predicate.
-- If the EXISTS check alone were used, it would combine with OR against the other
-- policies and potentially expose 'private' responses to peers.

-- Accepted peers can see compass responses with visibility = 'friends'.
-- Bidirectional: sr.actor_id may be either the viewer or the responder.
-- Uses the idx_social_rel_accepted partial index for O(log n) performance.
CREATE POLICY "compass_responses: friends select"
  ON inform.compass_responses
  FOR SELECT
  TO authenticated
  USING (
    visibility = 'friends'
    AND EXISTS (
      SELECT 1
      FROM connect.social_relationships sr
      WHERE sr.connection_type = 'peer'
        AND sr.status = 'accepted'
        AND (
          (sr.actor_id = (select auth.uid()) AND sr.target_id = inform.compass_responses.user_id) OR
          (sr.target_id = (select auth.uid()) AND sr.actor_id = inform.compass_responses.user_id)
        )
    )
  );

-- Any authenticated user can see responses marked as public.
-- This covers Empowered account compass data (made public on empowerment by
-- execute_empowerment RPC) and any user who explicitly sets visibility = 'public'.
CREATE POLICY "compass_responses: public select"
  ON inform.compass_responses
  FOR SELECT
  TO authenticated
  USING (visibility = 'public');


-- =============================================================================
-- Section 5: Grants for new Phase 6 tables
-- =============================================================================
-- social_relationships: authenticated SELECT (RLS controls which rows)
-- No INSERT/UPDATE/DELETE — writes via SECURITY DEFINER RPCs or pg pool.
GRANT SELECT ON connect.social_relationships TO authenticated;

-- roles: authenticated SELECT (public read — RLS policy: authenticated read)
GRANT SELECT ON public.roles TO authenticated;

-- user_roles: explicit SELECT grant (table is in public schema; auto-granted for
-- DDL but added explicitly for clarity and alignment with migration 011 pattern).
GRANT SELECT ON public.user_roles TO authenticated;


COMMIT;
