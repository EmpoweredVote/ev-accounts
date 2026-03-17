-- =============================================================================
-- Migration 039: Fix promote_to_connected for accounts with NULL display_name
-- =============================================================================
-- Bug: Old alpha accounts have NULL display_name in public.users. The
-- promote_to_connected RPC passes that NULL directly into connected_profiles.
-- display_name, which has a NOT NULL constraint — causing a 500.
--
-- Fix: After looking up display_name from public.users, fall back to the
-- email prefix from auth.users if it is NULL. This handles all pre-Connect-
-- flow accounts that signed up before display_name was collected at signup.
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

  -- Fallback: old alpha accounts have NULL display_name in public.users.
  -- Use the email prefix from auth.users so the NOT NULL constraint is satisfied.
  IF v_display_name IS NULL THEN
    SELECT split_part(email, '@', 1) INTO v_display_name
      FROM auth.users
      WHERE id = p_target_user_id;
  END IF;

  -- Last resort: should never reach this, but guard against auth.users also returning null.
  v_display_name := COALESCE(v_display_name, 'Member');

  -- Step 2: Check for existing connected_profiles row
  SELECT user_id INTO v_existing_id
    FROM connect.connected_profiles
    WHERE user_id = p_target_user_id;

  IF FOUND THEN
    RAISE EXCEPTION 'ALREADY_CONNECTED_OR_HIGHER';
  END IF;

  -- Step 3: INSERT connected_profiles row
  -- gem_balance columns use DB defaults (0) — do not include in column list
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

  -- Step 4: INSERT tier_promotion_log row
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
