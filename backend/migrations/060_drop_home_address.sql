-- Migration 060: Drop home_address from connected_profiles
--
-- home_address was stored as plain text, violating the platform privacy model
-- (EV should not be able to read where someone lives). Encrypted coordinates
-- (encrypted_lat / encrypted_lng) have been the canonical location store since
-- Phase 19. Path 2 of /representatives/me (geocode fallback) is also removed.
--
-- home_address_draft in verification_sessions is ephemeral enrollment state —
-- it is intentionally NOT removed here.

-- 1. Replace complete_connect_flow: remove home_address from INSERT
CREATE OR REPLACE FUNCTION public.complete_connect_flow(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_session connect.verification_sessions;
BEGIN
  -- Lock the verification_session row for this transaction
  SELECT * INTO v_session
  FROM connect.verification_sessions
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SESSION';
  END IF;

  IF v_session.step_reached != 'review' THEN
    RAISE EXCEPTION 'INCOMPLETE_SESSION';
  END IF;

  IF v_session.display_name_draft IS NULL
     OR v_session.legal_name_draft IS NULL
     OR v_session.region_draft IS NULL
     OR v_session.home_address_draft IS NULL
  THEN
    RAISE EXCEPTION 'MISSING_REQUIRED_FIELDS';
  END IF;

  -- Idempotency check
  IF EXISTS (SELECT 1 FROM connect.connected_profiles WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'ALREADY_CONNECTED';
  END IF;

  -- Create connected_profiles record (home_address intentionally excluded)
  INSERT INTO connect.connected_profiles
    (user_id, display_name, legal_name, account_standing, verification_status, tolerance_rating, verified_region)
  VALUES
    (p_user_id, v_session.display_name_draft, v_session.legal_name_draft,
     'active', 'verified', 10.00, v_session.region_draft);

  -- Advance session to complete
  UPDATE connect.verification_sessions
  SET step_reached = 'complete', updated_at = now()
  WHERE user_id = p_user_id;

  -- Sync display_name to public.users
  UPDATE public.users
  SET display_name = v_session.display_name_draft, updated_at = now()
  WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'connected', true,
    'verification_status', 'verified',
    'tier', 'connected'
  );
END;
$$;

-- 2. Drop the column
ALTER TABLE connect.connected_profiles DROP COLUMN IF EXISTS home_address;
