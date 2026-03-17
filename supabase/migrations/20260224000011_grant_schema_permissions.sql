BEGIN;

-- Migration 011: Grant schema USAGE and table permissions for connect and empower schemas
--
-- PostgreSQL requires explicit GRANT USAGE on a schema before any role can query
-- tables within it. Supabase pre-grants this for the public schema; custom schemas
-- require it explicitly. RLS policies on each table then control row-level access.

-- -------------------------------------------------------------------------
-- connect schema
-- -------------------------------------------------------------------------
GRANT USAGE ON SCHEMA connect TO anon, authenticated;

-- connected_profiles: authenticated attempts SELECT (RLS: owner-only)
GRANT SELECT ON connect.connected_profiles TO authenticated;

-- connected_profiles_public view: authenticated reads safe columns (no tolerance_rating)
GRANT SELECT ON connect.connected_profiles_public TO authenticated;

-- verification_sessions: authenticated can SELECT, INSERT, UPDATE (RLS: owner-only)
GRANT SELECT, INSERT, UPDATE ON connect.verification_sessions TO authenticated;

-- peer_connections: authenticated can SELECT, INSERT, UPDATE (RLS: participant)
GRANT SELECT, INSERT, UPDATE ON connect.peer_connections TO authenticated;

-- account_follows: authenticated can SELECT, INSERT, DELETE (RLS: follower/followed)
GRANT SELECT, INSERT, DELETE ON connect.account_follows TO authenticated;

-- gem_transactions: authenticated can SELECT (RLS: owner-only)
-- No INSERT for non-service-role: writes go through SECURITY DEFINER RPC functions
GRANT SELECT ON connect.gem_transactions TO authenticated;
GRANT SELECT ON connect.gem_transactions TO service_role;

-- -------------------------------------------------------------------------
-- empower schema
-- -------------------------------------------------------------------------
GRANT USAGE ON SCHEMA empower TO anon, authenticated;

-- empowered_profiles: anon + authenticated can SELECT
-- (RLS filters: anon sees active-only; authenticated sees active + own inactive)
GRANT SELECT ON empower.empowered_profiles TO anon, authenticated;

COMMIT;
