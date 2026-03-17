-- =============================================================================
-- Migration 042: Fix promote_to_connected invite_chains ON CONFLICT
-- =============================================================================
-- Migration 041 backfilled invite_chains rows for users whose promotions had
-- previously failed. When those users are now promoted via the admin tool,
-- migration 040's promote_to_connected tries to INSERT a new invite_chains row
-- but hits the UNIQUE (invitee_id) constraint.
--
-- Fix: use INSERT ... ON CONFLICT (invitee_id) DO NOTHING so promoting a user
-- who already has a chain row (from backfill or a prior partial run) succeeds
-- cleanly rather than throwing.
-- =============================================================================

CREATE OR REPLACE FUNCTION connect.promote_to_connected(
  p_admin_id       UUID,
  p_admin_email    TEXT,
  p_target_user_id UUID,
  p_note           TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_display_name TEXT;
  v_existing_id  UUID;
BEGIN

  -- Step 1: Look up display_name from public.users
  SELECT display_name INTO v_display_name
    FROM public.users
    WHERE id = p_target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'USER_NOT_FOUND';
  END IF;

  -- Fallback: old alpha accounts may have NULL display_name (migration 039)
  IF v_display_name IS NULL THEN
    SELECT split_part(email, '@', 1) INTO v_display_name
      FROM auth.users
      WHERE id = p_target_user_id;
  END IF;

  v_display_name := COALESCE(v_display_name, 'Member');

  -- Step 2: Check for existing connected_profiles row
  SELECT user_id INTO v_existing_id
    FROM connect.connected_profiles
    WHERE user_id = p_target_user_id;

  IF FOUND THEN
    RAISE EXCEPTION 'ALREADY_CONNECTED_OR_HIGHER';
  END IF;

  -- Step 3: INSERT connected_profiles row
  INSERT INTO connect.connected_profiles (
    user_id,
    display_name,
    account_standing,
    verification_status,
    verification_method,
    total_xp,
    completed_onboarding
  ) VALUES (
    p_target_user_id,
    v_display_name,
    'active',
    'pending',
    'admin_promotion',
    0,
    false
  );

  -- Step 4: INSERT invite_chains row — admin is the inviter seed.
  -- ON CONFLICT DO NOTHING: if a chain row already exists (e.g. from the
  -- migration 041 backfill), keep it as-is rather than failing.
  INSERT INTO connect.invite_chains (inviter_id, invitee_id, invite_code_id)
    VALUES (p_admin_id, p_target_user_id, NULL)
    ON CONFLICT (invitee_id) DO NOTHING;

  -- Step 5: INSERT tier_promotion_log row
  INSERT INTO connect.tier_promotion_log (
    admin_id,
    admin_email,
    target_user_id,
    previous_tier,
    new_tier,
    note
  ) VALUES (
    p_admin_id,
    p_admin_email,
    p_target_user_id,
    'inform',
    'connected',
    p_note
  );

  RETURN jsonb_build_object(
    'ok', true,
    'display_name', v_display_name
  );
END;
$$;
