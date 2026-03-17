-- =============================================================================
-- Migration 040: Record admin as inviter in invite_chains on promotion
-- =============================================================================
-- When an admin promotes a user to Connected, the admin becomes the seed of
-- that user's invite chain — the same accountability link that exists for
-- code-based invites. This makes invite tree traversal consistent regardless
-- of how a user was promoted.
--
-- Two changes:
--   1. invite_chains.invite_code_id becomes nullable.
--      NULL = admin promotion (no code). Non-null = normal invite code path.
--      All existing queries join on inviter_id/invitee_id — none filter on
--      invite_code_id — so this is backward-compatible.
--
--   2. promote_to_connected RPC inserts an invite_chains row with
--      inviter_id = p_admin_id and invite_code_id = NULL.
-- =============================================================================

-- Step 1: Make invite_code_id nullable
ALTER TABLE connect.invite_chains
  ALTER COLUMN invite_code_id DROP NOT NULL;

COMMENT ON COLUMN connect.invite_chains.invite_code_id IS
  'NULL for admin-promotion chains (no invite code used). Non-null for standard invite-code path.';


-- Step 2: Update promote_to_connected to insert the chain row
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

  -- Fallback: old alpha accounts may have NULL display_name in public.users
  -- (migration 039). Use email prefix from auth.users.
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

  -- Step 4: INSERT invite_chains row — admin is the inviter seed
  -- invite_code_id is NULL (no code used for admin promotion).
  INSERT INTO connect.invite_chains (inviter_id, invitee_id, invite_code_id)
    VALUES (p_admin_id, p_target_user_id, NULL);

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
