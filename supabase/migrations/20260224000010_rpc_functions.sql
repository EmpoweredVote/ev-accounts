BEGIN;

-- Migration 010: RPC functions (SECURITY DEFINER, Phase 1 versions)
--
-- CRITICAL: These Phase 1 functions DO NOT reference inform.compass_responses.
--   That table does not exist in Phase 1. Phase 4 will CREATE OR REPLACE each
--   function with the full body including compass visibility updates.
--
-- All functions:
--   - Use SECURITY DEFINER so they run with the definer's privileges (service role)
--   - Include SET search_path = '' to prevent search_path injection attacks
--   - Use fully-qualified schema.table references throughout
--   - Roll back all changes on EXCEPTION (Postgres does this implicitly for PL/pgSQL)
--
-- FOUND-03: execute_empowerment, execute_demotion, get_calibration_lapsed_users

-- -------------------------------------------------------------------------
-- empower.execute_empowerment
-- -------------------------------------------------------------------------
-- Atomically creates an empowered_profiles row and generates a candidate_page_slug.
-- Slug format: kebab-case(legal_name) + '-' + 4-char random alphanumeric suffix.
-- Example: "Jane Smith" → "jane-smith-a3b4"
-- Slug uniqueness enforced by the UNIQUE constraint on candidate_page_slug.
-- Phase 4 will add: UPDATE inform.compass_responses SET visibility = 'public' WHERE user_id = p_user_id;
--
-- Returns: the newly created empower.empowered_profiles row.

CREATE OR REPLACE FUNCTION empower.execute_empowerment(
  p_user_id              UUID,
  p_legal_name           TEXT,
  p_connected_profile_id UUID
)
RETURNS empower.empowered_profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_slug   TEXT;
  v_suffix TEXT;
  v_result empower.empowered_profiles;
BEGIN
  -- Generate 4-char random alphanumeric suffix from md5 of a random UUID
  v_suffix := substring(md5(gen_random_uuid()::text) FROM 1 FOR 4);

  -- Build slug: lowercase, non-alphanumeric runs → single hyphen, trailing hyphens stripped
  v_slug := rtrim(
    lower(regexp_replace(p_legal_name, '[^a-zA-Z0-9]+', '-', 'g')),
    '-'
  ) || '-' || v_suffix;

  INSERT INTO empower.empowered_profiles (
    user_id,
    connected_profile_id,
    legal_name,
    candidate_page_slug,
    empowered_at
  ) VALUES (
    p_user_id,
    p_connected_profile_id,
    p_legal_name,
    v_slug,
    now()
  )
  RETURNING * INTO v_result;

  -- Phase 4 will add:
  -- UPDATE inform.compass_responses
  --   SET visibility = 'public', updated_at = now()
  --   WHERE user_id = p_user_id;

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  -- Re-raise the original exception; Postgres rolls back all changes in this block.
  RAISE;
END;
$$;

-- -------------------------------------------------------------------------
-- empower.execute_demotion
-- -------------------------------------------------------------------------
-- Atomically sets is_active = false for a user's empowered profile.
-- Does NOT delete the row — slug is preserved forever (CAND-03).
-- Phase 4 will add: UPDATE inform.compass_responses SET visibility = 'private' WHERE user_id = p_user_id;

CREATE OR REPLACE FUNCTION empower.execute_demotion(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE empower.empowered_profiles
    SET
      is_active  = false,
      updated_at = now()
    WHERE user_id = p_user_id
      AND is_active = true;

  -- Phase 4 will add:
  -- UPDATE inform.compass_responses
  --   SET visibility = 'private', updated_at = now()
  --   WHERE user_id = p_user_id;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

-- -------------------------------------------------------------------------
-- public.get_calibration_lapsed_users
-- -------------------------------------------------------------------------
-- Phase 1 placeholder for the Phase 7 calibration lapse cron job (CRON-01).
-- Returns empty set — inform.compass_topics/responses tables don't exist yet.
-- Phase 4 will CREATE OR REPLACE with the real query:
--   SELECT DISTINCT ep.user_id
--   FROM empower.empowered_profiles ep
--   JOIN inform.compass_responses cr ON cr.user_id = ep.user_id
--   ...
-- Phase 7 wires this to the daily scheduled job.

CREATE OR REPLACE FUNCTION public.get_calibration_lapsed_users()
RETURNS TABLE (user_id UUID)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  -- Phase 1 placeholder: inform schema has no tables yet.
  -- Returns empty result set. Phase 4 replaces this with the real lapse query.
  SELECT NULL::uuid WHERE false;
$$;

-- -------------------------------------------------------------------------
-- public.soft_delete_user
-- -------------------------------------------------------------------------
-- Cascades soft delete across all tier tables.
-- Sets deleted_at on public.users, connect.connected_profiles, empower.empowered_profiles.
-- Also sets is_active = false on empowered_profiles (demotion semantics for deleted accounts).
-- The user's invite chain position is preserved for Tolerance Rating accountability.

CREATE OR REPLACE FUNCTION public.soft_delete_user(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Soft-delete the base user record
  UPDATE public.users
    SET
      deleted_at = now(),
      updated_at = now()
    WHERE id = p_user_id
      AND deleted_at IS NULL;

  -- Soft-delete the connected profile (if exists)
  UPDATE connect.connected_profiles
    SET
      deleted_at = now(),
      updated_at = now()
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;

  -- Soft-delete and demote the empowered profile (if exists)
  -- is_active = false ensures the public candidate page disappears immediately.
  UPDATE empower.empowered_profiles
    SET
      is_active  = false,
      deleted_at = now(),
      updated_at = now()
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

COMMIT;
