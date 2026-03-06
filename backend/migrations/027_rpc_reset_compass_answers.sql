-- =============================================================================
-- Migration 027: RPC reset_compass_answers
--
-- SECURITY DEFINER function that atomically resets a user's compass state.
-- Called via supabaseAdmin.rpc('reset_compass_answers', { p_user_id, p_full_reset }).
--
-- Steps performed (all within a single PL/pgSQL block — implicit transaction):
--   1. Soft-delete all active compass_responses for the user.
--   2. Clear selected_topic_ids on connected_profiles.
--   3. (full reset only) Reset completed_onboarding to false.
--
-- If any step throws, the implicit PL/pgSQL transaction is rolled back and the
-- exception propagates to the caller unchanged.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.reset_compass_answers(
  p_user_id    UUID,
  p_full_reset BOOLEAN DEFAULT false
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN

  -- Step 1: Soft-delete all active compass responses for this user.
  -- NULL deleted_at = active row; we set it to now() to mark as deleted.
  -- Hard deletes are not used — preserves data for recovery and audit.
  UPDATE inform.compass_responses
    SET deleted_at = now()
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;

  -- Step 2: Clear the user's selected topic IDs.
  -- Resetting answers makes any prior topic selection stale.
  UPDATE connect.connected_profiles
    SET selected_topic_ids = '[]'::jsonb,
        updated_at         = now()
    WHERE user_id = p_user_id;

  -- Step 3: (optional) Reset onboarding flag so the user goes through the
  -- onboarding flow again on next login. Only triggered for full resets
  -- (e.g. admin-initiated or user-requested clean slate).
  IF p_full_reset THEN
    UPDATE connect.connected_profiles
      SET completed_onboarding = false,
          updated_at            = now()
      WHERE user_id = p_user_id;
  END IF;

EXCEPTION WHEN OTHERS THEN
  RAISE;

END;
$$;
