BEGIN;

-- =============================================================================
-- Migration 049: Compass Contributor Schema
-- =============================================================================
-- Adds columns required for contributor stance editing:
--   1. essentials.politicians.home_jurisdiction_geoid
--   2. inform.politician_answers.write_in_text
--   3. public.role_audit_log.role_grant_id (+ index)
--   4. Update get_user_roles RPC to include ur.id in SELECT
--
-- user_roles.id already exists as UUID (verified before migration was written).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: home_jurisdiction_geoid on essentials.politicians
-- ---------------------------------------------------------------------------
-- Canonical politician table post-Phase 35. All compass queries use this table.
-- NULL = unassigned jurisdiction. No NOT NULL constraint — fail-open for Alpha.

ALTER TABLE essentials.politicians ADD COLUMN IF NOT EXISTS home_jurisdiction_geoid TEXT;

-- ---------------------------------------------------------------------------
-- Section 2: write_in_text on inform.politician_answers
-- ---------------------------------------------------------------------------
-- Nullable — most stances have no write-in text. Required for stance writes
-- that include contextual reasoning from contributors.

ALTER TABLE inform.politician_answers ADD COLUMN IF NOT EXISTS write_in_text TEXT;

-- ---------------------------------------------------------------------------
-- Section 3: role_grant_id on public.role_audit_log
-- ---------------------------------------------------------------------------
-- Nullable — existing audit entries (grant/revoke) do not reference a grant row.
-- Only stance_write entries populate this. References the user_roles.id UUID.

ALTER TABLE public.role_audit_log ADD COLUMN IF NOT EXISTS role_grant_id UUID;

CREATE INDEX IF NOT EXISTS idx_role_audit_log_role_grant_id
  ON public.role_audit_log (role_grant_id)
  WHERE role_grant_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Section 4: user_roles.id already exists — no action needed
-- ---------------------------------------------------------------------------
-- Confirmed: public.user_roles already has id UUID column (data_type: uuid).

-- ---------------------------------------------------------------------------
-- Section 5: Update get_user_roles RPC to return ur.id
-- ---------------------------------------------------------------------------
-- Adds ur.id to the SELECT so callers can reference the specific grant row
-- UUID in audit log entries (role_grant_id column added in Section 3).

CREATE OR REPLACE FUNCTION public.get_user_roles(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(row_to_json(t))
  INTO v_result
  FROM (
    SELECT ur.id, ur.role_id, r.slug, r.name, ur.granted_at,
           ur.feature_scope, ur.jurisdiction_geoid, ur.resource_id
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id AND ur.revoked_at IS NULL
    ORDER BY ur.granted_at DESC
  ) t;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

COMMIT;
