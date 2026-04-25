-- =============================================================================
-- Phase 61 — Auth Flow Restyle
-- Migration 071: Add p_display_name parameter to signup_with_invite RPC
--
-- Users must have a civic pseudonym from account creation — the previous
-- implementation inserted display_name = NULL and deferred it to onboarding.
-- This migration updates the RPC to accept and store display_name atomically.
-- =============================================================================

CREATE OR REPLACE FUNCTION connect.signup_with_invite(
  p_user_id      UUID,
  p_legal_name   TEXT,
  p_invite_code  TEXT,
  p_display_name TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_invite_row connect.invite_codes%ROWTYPE;
BEGIN
  -- 1. Lock + validate invite code
  --    FOR UPDATE prevents concurrent claims on the same code.
  SELECT * INTO v_invite_row
    FROM connect.invite_codes
    WHERE code = upper(trim(p_invite_code))
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_OR_CLAIMED_CODE';
  END IF;

  IF v_invite_row.is_claimed THEN
    RAISE EXCEPTION 'INVALID_OR_CLAIMED_CODE';
  END IF;

  IF v_invite_row.expires_at IS NOT NULL AND v_invite_row.expires_at < now() THEN
    RAISE EXCEPTION 'INVALID_OR_CLAIMED_CODE';
  END IF;

  -- 2. Prevent self-invite
  --    Admin-created codes have created_by = NULL — skip this check for them.
  IF v_invite_row.created_by IS NOT NULL AND v_invite_row.created_by = p_user_id THEN
    RAISE EXCEPTION 'SELF_INVITE_BLOCKED';
  END IF;

  -- 3. Claim the invite code
  UPDATE connect.invite_codes
    SET is_claimed = true,
        claimed_by = p_user_id,
        claimed_at = now(),
        updated_at = now()
    WHERE id = v_invite_row.id;

  -- 4. Create connected_profiles row with display_name
  --    verification_method = 'invite' and verification_status = 'verified'
  --    match the existing enrollment pattern.
  --    completed_onboarding = false so post-login routing detects first-time user.
  INSERT INTO connect.connected_profiles (
    user_id, legal_name, display_name, account_standing,
    verification_status, verification_method, total_xp, completed_onboarding
  ) VALUES (
    p_user_id, p_legal_name, p_display_name, 'active',
    'verified', 'invite', 0, false
  );

  -- 5. Record invite chain
  --    Only for user-created codes (created_by IS NOT NULL).
  --    Admin-created codes (created_by = NULL) do not create a chain entry.
  IF v_invite_row.created_by IS NOT NULL THEN
    INSERT INTO connect.invite_chains (inviter_id, invitee_id, invite_code_id)
      VALUES (v_invite_row.created_by, p_user_id, v_invite_row.id);
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'inviter_id', v_invite_row.created_by
  );
END;
$$;
