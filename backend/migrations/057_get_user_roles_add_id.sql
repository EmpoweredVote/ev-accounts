-- Migration 057: Add ur.id to get_user_roles RPC so UserRoleGrant.id is populated.
-- Without this, matchingGrant.id is undefined in production, causing the stance
-- audit log INSERT to fail with a 500 error.

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
