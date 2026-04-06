-- =============================================================================
-- Migration 056: Add granted_by_id to user_roles, update grant_role and
--               get_user_roles RPCs to track and surface the granting user.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Section 1: Add granted_by_id column to user_roles
-- ---------------------------------------------------------------------------

ALTER TABLE public.user_roles
  ADD COLUMN IF NOT EXISTS granted_by_id uuid REFERENCES public.users(id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------------
-- Section 2: Replace grant_role RPC to accept and store granted_by_id
-- ---------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.grant_role(uuid, text, text, text, text);

CREATE OR REPLACE FUNCTION public.grant_role(
  p_user_id            uuid,
  p_role_slug          text,
  p_feature_scope      text DEFAULT 'platform',
  p_jurisdiction_geoid text DEFAULT NULL,
  p_resource_id        text DEFAULT NULL,
  p_granted_by_id      uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role_id            uuid;
  v_role_required_tier text;
  v_role_is_active     bool;
BEGIN
  SELECT id, required_tier, is_active
  INTO v_role_id, v_role_required_tier, v_role_is_active
  FROM public.roles
  WHERE slug = p_role_slug;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ROLE_NOT_FOUND';
  END IF;

  IF NOT v_role_is_active THEN
    RAISE EXCEPTION 'ROLE_INACTIVE';
  END IF;

  IF v_role_required_tier = 'empowered' THEN
    IF NOT EXISTS (
      SELECT 1 FROM empower.empowered_profiles
      WHERE user_id = p_user_id AND is_active = true
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  ELSIF v_role_required_tier = 'connected' THEN
    IF NOT EXISTS (
      SELECT 1 FROM connect.connected_profiles
      WHERE user_id = p_user_id AND verification_status = 'verified'
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  END IF;

  BEGIN
    INSERT INTO public.user_roles (user_id, role_id, feature_scope, jurisdiction_geoid, resource_id, granted_by_id)
    VALUES (p_user_id, v_role_id, p_feature_scope, p_jurisdiction_geoid, p_resource_id, p_granted_by_id);
  EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION 'ROLE_ALREADY_GRANTED';
  END;
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 3: Replace get_user_roles RPC to return granted_by_display_name
-- ---------------------------------------------------------------------------

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
    SELECT ur.role_id, r.slug, r.name, ur.granted_at,
           ur.feature_scope, ur.jurisdiction_geoid, ur.resource_id,
           cp.display_name AS granted_by_display_name
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    LEFT JOIN connect.connected_profiles cp ON cp.user_id = ur.granted_by_id
    WHERE ur.user_id = p_user_id AND ur.revoked_at IS NULL
    ORDER BY ur.granted_at DESC
  ) t;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

COMMIT;
