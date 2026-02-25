BEGIN;

-- Migration 007: RLS policies for the public schema
--
-- Design decisions (from CONTEXT.md):
--   - public.users: direct table access is owner-only. Non-owners must use the
--     public.users_public VIEW which exposes only safe columns.
--   - Safe columns: id, display_name, avatar_url
--   - Blocked columns: email (lives in auth.users), account_standing, created_at,
--     deleted_at, tolerance_rating, legal_name (all internal)
--   - user_roles: admin-only (no non-service-role policies)
--   - admin_audit_log: admin-only (no non-service-role policies)

-- -------------------------------------------------------------------------
-- public.users
-- -------------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Owners see their own full row (all columns including created_at etc.)
-- auth.uid() wrapped in (select ...) to allow query-plan caching.
CREATE POLICY "users: owner select"
  ON public.users
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = id AND deleted_at IS NULL);

-- No INSERT policy for non-service-role:
--   Inserts are handled exclusively by the handle_new_user() SECURITY DEFINER trigger.
-- No UPDATE policy:
--   Updates go through application service functions (Phase 2 /account/me PATCH).
--   For Phase 1, service role performs updates directly.
-- No DELETE policy:
--   Hard deletes are prohibited; soft-delete only via soft_delete_user() RPC.

-- -------------------------------------------------------------------------
-- public.users_public (split-visibility view)
-- -------------------------------------------------------------------------
-- Non-owning users must query this view to read another user's display_name/avatar.
-- This view intentionally excludes ALL sensitive columns.
-- Future phases that need a user's display name for social features MUST use this view.

CREATE OR REPLACE VIEW public.users_public AS
  SELECT
    id,
    display_name,
    avatar_url
  FROM public.users
  WHERE deleted_at IS NULL;

-- Grant SELECT on the view to authenticated users.
-- Views run with owner (postgres) permissions, bypassing RLS on public.users.
-- Column restriction (id, display_name, avatar_url only) and row restriction
-- (deleted_at IS NULL) are enforced structurally by the view definition itself.
GRANT SELECT ON public.users_public TO authenticated;

-- -------------------------------------------------------------------------
-- public.user_roles
-- -------------------------------------------------------------------------
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- No non-service-role policies: role management is admin-only.
-- Phase 7 admin routes will use the service role client to read/write roles.

-- -------------------------------------------------------------------------
-- public.admin_audit_log
-- -------------------------------------------------------------------------
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

-- No non-service-role policies: audit log is append-only, admin read-only.
-- Service role is used for all admin_audit_log writes.
-- No policy = deny by default for all non-service-role connections.

COMMIT;
