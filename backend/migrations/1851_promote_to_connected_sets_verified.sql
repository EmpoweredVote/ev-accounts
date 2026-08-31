-- 1851_promote_to_connected_sets_verified.sql
-- Admin promotion produced an account that could use neither tier.
--
-- connect.promote_to_connected inserted verification_status = 'pending'. Nothing
-- in the codebase ever sets 'verified' — grep it: the only writer is
-- signup_with_invite, and there is no separate "verify later" flow. So an
-- admin-promoted user landed in a state with no exit:
--
--   requireConnected → 403, because verification_status <> 'verified'
--   requireInform    → 403, because a connected_profiles row EXISTS
--
-- Both guards refuse them. That closes 17 routes in social.ts, 8 in empower.ts,
-- plus gems, xp, invites, referral and parts of account and essentials — to a
-- user an admin had just deliberately promoted.
--
-- ALREADY HIT IN PRODUCTION. The one admin_promotion account in prod carries
-- verification_status = 'verified', which no code path can produce. Somebody
-- fixed it by hand and the gap stayed open behind them.
--
-- Promotion is the admin asserting this account is legitimate. That IS the
-- verification, and the audit trail already records who did it and why
-- (tier_promotion_log, plus verification_method = 'admin_promotion' naming the
-- route in). Recording it as 'pending' claimed a review was outstanding when no
-- review was ever going to happen.
--
-- Based on the LIVE definition, not migration 035's — the function has since
-- gained the display_name fallback (039) and the invite_chains seed (041). Only
-- the verification_status literal changes.

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
  --
  -- 'verified', not 'pending'. See the header: 'pending' had no exit, and left
  -- the promoted user unable to use either tier. verification_method still
  -- records HOW they were verified, so an admin promotion stays distinguishable
  -- from an invite at signup.
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
    'verified',
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

-- Release anyone already stranded by the old behaviour. Scoped to
-- admin_promotion so it cannot touch a genuine pending review from some future
-- flow. Zero rows match today — both pending accounts were hand-made test
-- personas and have been cleared — but this covers anything promoted between
-- writing and deploying, and makes the migration correct on its own.
UPDATE connect.connected_profiles
   SET verification_status = 'verified',
       updated_at          = now()
 WHERE verification_method = 'admin_promotion'
   AND verification_status = 'pending'
   AND deleted_at IS NULL;
