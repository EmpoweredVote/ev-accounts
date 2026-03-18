-- =============================================================================
-- Phase 24 — Public Auth Hub
-- Migration 036: access_requests table + signup_with_invite RPC
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: public.access_requests
-- Captures emails from users who don't have an invite code.
-- Admin reads via supabaseAdmin in admin routes (service role).
-- No user-facing read policy — intentional (no self-service lookup).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.access_requests (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email        TEXT        NOT NULL,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS enabled — writes via service role only, no authenticated user reads.
-- Admin reads via supabaseAdmin in admin routes.
ALTER TABLE public.access_requests ENABLE ROW LEVEL SECURITY;

-- Grant SELECT to authenticated so PostgREST doesn't hide the table entirely;
-- the RLS policy (none defined) still blocks all reads for non-admin users.
GRANT SELECT ON public.access_requests TO authenticated;

-- ---------------------------------------------------------------------------
-- Section 2: connect.signup_with_invite RPC
-- Atomically validates an invite code, claims it, creates a connected_profiles
-- row, and records the invite chain — all in one transaction.
--
-- Pattern modeled on claim_invite_code (migration 025, lines 633–684).
-- All three invalid/claimed/expired error paths return the same exception
-- to avoid leaking whether a code exists (OWASP enumeration protection).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION connect.signup_with_invite(
  p_user_id    UUID,
  p_legal_name TEXT,
  p_invite_code TEXT
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

  -- 4. Create connected_profiles row
  --    verification_method = 'invite' and verification_status = 'pending'
  --    match the existing enrollment pattern (migration 014).
  --    completed_onboarding = false so post-login routing detects first-time user.
  INSERT INTO connect.connected_profiles (
    user_id, legal_name, display_name, account_standing,
    verification_status, verification_method, total_xp, completed_onboarding
  ) VALUES (
    p_user_id, p_legal_name, NULL, 'active',
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
