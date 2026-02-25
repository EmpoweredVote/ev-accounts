BEGIN;

-- Migration 003: public schema types and supporting tables
--
-- role_type enum: used across features for civic role assignments.
-- user_roles: multi-role support with soft revocation (revoked_at NULL = active).
-- admin_audit_log: scaffolded now, populated by admin routes in Phase 7 (FOUND-08).
--   Append-only by design; no UPDATE or DELETE policies will be granted.

-- Role type enum
CREATE TYPE public.role_type AS ENUM (
  'maven',
  'journo',
  'arbiter',
  'moderator',
  'juror',
  'educator',
  'guide',
  'scribe'
);

-- user_roles: junction table — a user can hold multiple roles, each revocable independently
CREATE TABLE IF NOT EXISTS public.user_roles (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role_type  public.role_type NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ,               -- NULL = currently active; non-NULL = revoked
  UNIQUE (user_id, role_type)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);

-- admin_audit_log: append-only audit trail for all admin actions
-- Populated in Phase 7 admin routes. actor_id references public.users so the log
-- is preserved even after admin account soft-delete.
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id   UUID NOT NULL REFERENCES public.users(id),
  action     TEXT NOT NULL,
  target_id  UUID,                      -- nullable: some actions have no specific target
  metadata   JSONB,                     -- arbitrary action context
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_actor_id  ON public.admin_audit_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created_at ON public.admin_audit_log(created_at);

COMMIT;
