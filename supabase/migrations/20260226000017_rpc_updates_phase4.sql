BEGIN;

-- =============================================================================
-- Migration 017: Phase 4 RPC function updates
-- =============================================================================
-- Updates 3 functions that were created with Phase 1 stubs in migration 010:
--   1. empower.execute_empowerment — adds compass_responses visibility = 'public'
--   2. empower.execute_demotion    — adds compass_responses visibility = 'private'
--   3. public.get_calibration_lapsed_users — replaces placeholder with real query
--
-- All functions:
--   - SECURITY DEFINER (runs with definer's privileges, bypasses RLS)
--   - SET search_path = '' (prevents search_path injection attacks)
--   - Fully-qualified schema.table references throughout
--   - CREATE OR REPLACE preserves existing grants on the functions
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. empower.execute_empowerment (updated)
-- -----------------------------------------------------------------------------
-- Phase 4 addition: after creating the empowered_profiles row, set all of the
-- user's compass_responses to visibility = 'public'. This ensures their
-- calibration data is visible on their public candidate page.
--
-- The UPDATE is part of the same atomic transaction as the INSERT. If the
-- UPDATE fails, the entire empowerment transaction rolls back (Postgres
-- implicit rollback on EXCEPTION WHEN OTHERS THEN RAISE).
-- -----------------------------------------------------------------------------

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

  -- Phase 4: make all compass calibration data public for Empowered candidates.
  -- Runs atomically with the empowered_profiles INSERT above.
  UPDATE inform.compass_responses
    SET visibility = 'public',
        updated_at = now()
    WHERE user_id = p_user_id;

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  -- Re-raise the original exception; Postgres rolls back all changes in this block.
  RAISE;
END;
$$;


-- -----------------------------------------------------------------------------
-- 2. empower.execute_demotion (updated)
-- -----------------------------------------------------------------------------
-- Phase 4 addition: after marking the empowered_profiles row inactive, reset
-- all of the user's compass_responses visibility to 'private'. This ensures
-- their calibration data is hidden from the public candidate page immediately.
--
-- The UPDATE is part of the same atomic transaction as the empowered_profiles
-- UPDATE. If it fails, both updates roll back together.
-- -----------------------------------------------------------------------------

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

  -- Phase 4: revoke public visibility on all compass responses after demotion.
  -- Runs atomically with the empowered_profiles UPDATE above.
  UPDATE inform.compass_responses
    SET visibility = 'private',
        updated_at = now()
    WHERE user_id = p_user_id;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;


-- -----------------------------------------------------------------------------
-- 3. public.get_calibration_lapsed_users (Phase 4 real implementation)
-- -----------------------------------------------------------------------------
-- Phase 4 simplified version: returns any Empowered user missing any live
-- topic response. Phase 7 replaces with a timestamp-aware query using
-- went_live_at for the 30-day calibration lapse window.
--
-- Logic:
--   - Start from empower.empowered_profiles WHERE is_active = true
--   - Find any live compass topic the user has NOT answered
--   - If such a topic exists, the user is considered "lapsed"
--
-- Uses EXISTS / NOT EXISTS for correctness with NULLs and efficiency
-- (Postgres short-circuits EXISTS on first matching row).
-- Phase 7 wires this return set to the daily demotion cron job (CRON-01).
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_calibration_lapsed_users()
RETURNS TABLE (user_id UUID)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  -- Phase 4 simplified version: returns any Empowered user missing any live
  -- topic response. Phase 7 replaces with timestamp-aware query using
  -- went_live_at for the 30-day window.
  SELECT DISTINCT ep.user_id
  FROM empower.empowered_profiles ep
  WHERE ep.is_active = true
  AND EXISTS (
    SELECT 1
    FROM inform.compass_topics ct
    WHERE ct.is_live = true
    AND NOT EXISTS (
      SELECT 1
      FROM inform.compass_responses cr
      WHERE cr.user_id = ep.user_id
        AND cr.topic_id = ct.id
    )
  );
$$;


COMMIT;
