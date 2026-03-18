-- Migration 037: Add revoke_invite_code RPC
-- Replaces the direct table UPDATE in adminService.revokeInvite(), which fails
-- with "permission denied for table invite_codes" because service_role lacks
-- direct UPDATE access on connect schema tables via PostgREST.
-- SECURITY DEFINER runs as the function owner (postgres) and bypasses this.

CREATE OR REPLACE FUNCTION public.revoke_invite_code(p_code_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  DELETE FROM connect.invite_codes WHERE id = p_code_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.revoke_invite_code(UUID) TO service_role;
