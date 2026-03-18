-- Migration: referral_codes
-- Each Connected user gets one active referral code after reaching level 2.
-- The code refreshes when their invitee reaches level 2.
-- Reuses the existing invite_codes + invite_chains tables for accountability.

-- ─── 1. Columns on connected_profiles ───────────────────────────────────────

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS referral_unlocked  BOOLEAN  NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS referral_code      TEXT     UNIQUE,
  ADD COLUMN IF NOT EXISTS referral_invite_id UUID     REFERENCES connect.invite_codes(id);

-- ─── 2. Code generation helper ───────────────────────────────────────────────
-- Same charset as the JS inviteService: 32 unambiguous chars, no bias.

CREATE OR REPLACE FUNCTION connect.gen_referral_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_charset TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_bytes   BYTEA;
  v_code    TEXT := '';
  v_i       INT;
BEGIN
  v_bytes := gen_random_bytes(8);
  FOR v_i IN 0..7 LOOP
    v_code := v_code || substr(v_charset, (get_byte(v_bytes, v_i) % 32) + 1, 1);
  END LOOP;
  RETURN substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4);
END;
$$;

-- ─── 3. unlock_referral_code ─────────────────────────────────────────────────
-- Called when a user first reaches level 2.
-- Idempotent: no-op if referral_unlocked is already true.

CREATE OR REPLACE FUNCTION connect.unlock_referral_code(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_already_unlocked BOOLEAN;
  v_code             TEXT;
  v_invite_id        UUID;
  v_attempts         INT := 0;
BEGIN
  -- Lock profile row to serialize concurrent calls for same user
  SELECT referral_unlocked
  INTO   v_already_unlocked
  FROM   connect.connected_profiles
  WHERE  user_id = p_user_id
  FOR UPDATE;

  IF v_already_unlocked IS NULL OR v_already_unlocked THEN
    RETURN;  -- no profile row, or already unlocked
  END IF;

  -- Generate a unique code with collision retry
  LOOP
    v_attempts := v_attempts + 1;
    IF v_attempts > 10 THEN
      RAISE EXCEPTION 'unlock_referral_code: could not generate unique code after 10 attempts';
    END IF;
    v_code := connect.gen_referral_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM connect.invite_codes WHERE code = v_code
    );
  END LOOP;

  -- Create the invite_codes row (no expiry for referral codes)
  INSERT INTO connect.invite_codes (code, created_by, expires_at)
  VALUES (v_code, p_user_id, NULL)
  RETURNING id INTO v_invite_id;

  UPDATE connect.connected_profiles
  SET referral_unlocked  = true,
      referral_code      = v_code,
      referral_invite_id = v_invite_id
  WHERE user_id = p_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION connect.unlock_referral_code(UUID) TO authenticated;

-- ─── 4. maybe_refresh_referral_for_invitee ───────────────────────────────────
-- Called after any XP award to a user at level >= 2.
-- Finds if there is a referrer whose active referral code was claimed by this
-- invitee and, if so, issues a fresh code for the referrer.
-- Idempotent: the condition (claimed_by = p_invitee_id) is only true once.

CREATE OR REPLACE FUNCTION connect.maybe_refresh_referral_for_invitee(p_invitee_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_inviter_id         UUID;
  v_referrer_invite_id UUID;
  v_claimed_by         UUID;
  v_invitee_level      INT;
  v_new_code           TEXT;
  v_new_invite_id      UUID;
  v_attempts           INT := 0;
BEGIN
  -- Quick level check: invitee must be >= 2
  SELECT current_level
  INTO   v_invitee_level
  FROM   connect.connected_profiles
  WHERE  user_id = p_invitee_id;

  IF v_invitee_level IS NULL OR v_invitee_level < 2 THEN
    RETURN;
  END IF;

  -- Find referrer via invite_chains
  SELECT inviter_id
  INTO   v_inviter_id
  FROM   connect.invite_chains
  WHERE  invitee_id = p_invitee_id;

  IF v_inviter_id IS NULL THEN
    RETURN;  -- admin-created account, no chain
  END IF;

  -- Lock referrer's profile row
  SELECT referral_invite_id
  INTO   v_referrer_invite_id
  FROM   connect.connected_profiles
  WHERE  user_id = v_inviter_id
  FOR UPDATE;

  IF v_referrer_invite_id IS NULL THEN
    RETURN;  -- referrer never had a referral code (shouldn't happen but guard it)
  END IF;

  -- Check whether this invitee is the one who claimed the referrer's current code
  SELECT claimed_by
  INTO   v_claimed_by
  FROM   connect.invite_codes
  WHERE  id = v_referrer_invite_id;

  IF v_claimed_by IS DISTINCT FROM p_invitee_id THEN
    RETURN;  -- already refreshed, or a different person used the code
  END IF;

  -- Generate fresh code for referrer
  LOOP
    v_attempts := v_attempts + 1;
    IF v_attempts > 10 THEN
      RAISE EXCEPTION 'maybe_refresh_referral_for_invitee: could not generate unique code after 10 attempts';
    END IF;
    v_new_code := connect.gen_referral_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM connect.invite_codes WHERE code = v_new_code
    );
  END LOOP;

  INSERT INTO connect.invite_codes (code, created_by, expires_at)
  VALUES (v_new_code, v_inviter_id, NULL)
  RETURNING id INTO v_new_invite_id;

  UPDATE connect.connected_profiles
  SET referral_code      = v_new_code,
      referral_invite_id = v_new_invite_id
  WHERE user_id = v_inviter_id;
END;
$$;

GRANT EXECUTE ON FUNCTION connect.maybe_refresh_referral_for_invitee(UUID) TO authenticated;
