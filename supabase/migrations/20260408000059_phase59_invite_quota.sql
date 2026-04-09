BEGIN;

-- =============================================================================
-- Migration 059: Phase 59 Invite Quota — Schema + RPCs
-- =============================================================================
-- Schema additions:
--   connect.connected_profiles  — invite_cap_override column
--   connect.invite_chains       — slot_locked_until column
--
-- Functions:
--   connect.get_invite_cap_for_level(INT)           IMMUTABLE helper
--   connect.generate_invite_code_if_allowed(UUID)   atomic quota-enforced generation
--   connect.get_my_invitees(UUID)                   invitee list with quota summary
--   connect.sanction_invitee(UUID, NUMERIC)         TR + slot lock + notification
--
-- All SECURITY DEFINER functions:
--   SET search_path = ''   (prevents search_path injection)
--   Fully-qualified schema.table references throughout
--   gen_random_bytes unqualified (same pattern as gen_referral_code in migration 001)
--
-- Advisory lock pattern: pg_advisory_xact_lock(hashtext(user_id::text))
-- matches award_xp (migration 030) — transaction-level, auto-released on commit.
-- =============================================================================


-- =============================================================================
-- Section 1: Schema columns
-- =============================================================================

-- 1a. connect.connected_profiles — invite_cap_override
-- NULL   = use level-based default cap (normal path)
-- -1     = unlimited (no cap enforcement)
-- N > 0  = override cap floor (use GREATEST of level cap and this value)
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS invite_cap_override INTEGER DEFAULT NULL;

COMMENT ON COLUMN connect.connected_profiles.invite_cap_override
  IS 'NULL = level-based default, -1 = unlimited, positive = floor override';


-- 1b. connect.invite_chains — slot_locked_until
-- NULL         = slot is free / not locked
-- timestamp    = slot locked until this time or invitee reinstatement
ALTER TABLE connect.invite_chains
  ADD COLUMN IF NOT EXISTS slot_locked_until TIMESTAMPTZ DEFAULT NULL;

COMMENT ON COLUMN connect.invite_chains.slot_locked_until
  IS 'Non-null = slot locked until this time or invitee reinstatement';


-- =============================================================================
-- Section 2: connect.get_invite_cap_for_level
-- =============================================================================
-- Pure function: maps a user's level to their default invite slot cap.
-- IMMUTABLE: no table reads, result entirely determined by p_level.
-- Not SECURITY DEFINER (pure math, no privileged access needed).
--
-- Cap schedule:
--   level 1       → 0  (cannot invite yet)
--   levels 2–5    → 3
--   levels 6–10   → 5
--   levels 11–20  → 10
--   levels 21+    → 15

CREATE OR REPLACE FUNCTION connect.get_invite_cap_for_level(p_level INT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN p_level <= 1  THEN 0
    WHEN p_level <= 5  THEN 3
    WHEN p_level <= 10 THEN 5
    WHEN p_level <= 20 THEN 10
    ELSE 15
  END;
$$;

GRANT EXECUTE ON FUNCTION connect.get_invite_cap_for_level(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION connect.get_invite_cap_for_level(INT) TO anon;


-- =============================================================================
-- Section 3: connect.generate_invite_code_if_allowed
-- =============================================================================
-- Atomic quota-enforced invite code generation.
-- Uses pg_advisory_xact_lock to prevent concurrent double-generation for the
-- same user (same pattern as award_xp in migration 030).
--
-- Active slot count logic:
--   Counts claimed invitees who are below level 2 (not yet graduated), EXCLUDING
--   those whose lock has expired AND who have returned to active standing.
--   This means an expired-lock + suspended invitee still holds the slot.
--
-- Returns: TABLE (ok, code, error, active_count, cap)
--   ok = false → code is NULL, error is one of: 'NOT_CONNECTED', 'CAP_REACHED'
--   ok = true  → code is the newly generated code

CREATE OR REPLACE FUNCTION connect.generate_invite_code_if_allowed(p_user_id UUID)
RETURNS TABLE (
  ok           BOOLEAN,
  code         TEXT,
  error        TEXT,
  active_count INT,
  cap          INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_level          INT;
  v_override       INTEGER;
  v_level_cap      INT;
  v_effective_cap  INT;
  v_active_count   INT;
  v_code           TEXT;
  v_charset        TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_bytes          BYTEA;
  v_i              INT;
  v_attempts       INT := 0;
BEGIN

  -- Step 1: Acquire transaction-level advisory lock keyed on user_id hash.
  -- Serializes concurrent generate calls for the same user within this transaction.
  -- Auto-released on COMMIT or ROLLBACK.
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Step 2: Read profile row with FOR UPDATE to prevent concurrent profile updates.
  SELECT cp.current_level, cp.invite_cap_override
  INTO   v_level, v_override
  FROM   connect.connected_profiles cp
  WHERE  cp.user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false::BOOLEAN, NULL::TEXT, 'NOT_CONNECTED'::TEXT, 0::INT, 0::INT;
    RETURN;
  END IF;

  -- Step 3: Compute level-based cap.
  v_level_cap := connect.get_invite_cap_for_level(v_level);

  -- Step 4: Compute effective cap, handling unlimited override.
  IF v_override = -1 THEN
    -- -1 = unlimited: use max int (no cap enforcement)
    v_effective_cap := 2147483647;
  ELSE
    -- GREATEST of level cap and the override floor (or just level cap if no override)
    v_effective_cap := GREATEST(v_level_cap, COALESCE(v_override, 0));
  END IF;

  -- Step 5: Count active invitee slots.
  -- Active = claimed invitee below level 2, EXCLUDING expired-lock + active-standing
  -- (expired lock + returned to active = slot freed by invitee's reinstatement).
  SELECT COUNT(*)::INT INTO v_active_count
  FROM connect.invite_chains ic
  JOIN connect.invite_codes code ON code.id = ic.invite_code_id
  JOIN connect.connected_profiles invitee ON invitee.user_id = ic.invitee_id
  WHERE ic.inviter_id = p_user_id
    AND code.is_claimed = true
    AND invitee.current_level < 2
    AND NOT (
      ic.slot_locked_until IS NOT NULL
      AND ic.slot_locked_until < now()
      AND invitee.account_standing = 'active'
    );

  -- Step 6: Enforce cap.
  IF v_active_count >= v_effective_cap THEN
    RETURN QUERY SELECT false::BOOLEAN, NULL::TEXT, 'CAP_REACHED'::TEXT, v_active_count, v_effective_cap;
    RETURN;
  END IF;

  -- Step 7: Generate code with collision retry (up to 3 attempts).
  -- Charset: 32 unambiguous chars (no O, 0, I, 1), format XXXX-XXXX.
  -- gen_random_bytes unqualified — same pattern as gen_referral_code.
  LOOP
    v_attempts := v_attempts + 1;
    IF v_attempts > 3 THEN
      RAISE EXCEPTION 'generate_invite_code_if_allowed: could not generate unique code after 3 attempts';
    END IF;

    v_bytes := gen_random_bytes(8);
    v_code := '';
    FOR v_i IN 0..7 LOOP
      v_code := v_code || substr(v_charset, (get_byte(v_bytes, v_i) % 32) + 1, 1);
    END LOOP;
    v_code := substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4);

    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM connect.invite_codes WHERE code = v_code
    );
  END LOOP;

  -- Step 8: Insert the new invite code (expires in 30 days).
  INSERT INTO connect.invite_codes (code, created_by, expires_at)
  VALUES (v_code, p_user_id, now() + interval '30 days');

  -- Step 9: Return success with the generated code.
  RETURN QUERY SELECT true::BOOLEAN, v_code, NULL::TEXT, v_active_count, v_effective_cap;

END;
$$;

GRANT EXECUTE ON FUNCTION connect.generate_invite_code_if_allowed(UUID) TO authenticated;


-- =============================================================================
-- Section 4: connect.get_my_invitees
-- =============================================================================
-- Returns all claimed invitees for a user (complete list: active, graduated,
-- lock-expired) plus the user's current active_count and effective_cap.
--
-- active_count and effective_cap are repeated on every row (same value on all).
-- The canonical active-slot query is identical to generate_invite_code_if_allowed.
-- graduated = current_level >= 2 (slot freed, no longer holding capacity).

CREATE OR REPLACE FUNCTION connect.get_my_invitees(p_user_id UUID)
RETURNS TABLE (
  invitee_id       UUID,
  display_name     TEXT,
  account_standing TEXT,
  current_level    INT,
  graduated        BOOLEAN,
  slot_locked_until TIMESTAMPTZ,
  claimed_at       TIMESTAMPTZ,
  active_count     INT,
  effective_cap    INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_level         INT;
  v_override      INTEGER;
  v_level_cap     INT;
  v_effective_cap INT;
  v_active_count  INT;
BEGIN

  -- Step 1: Compute effective cap for this user.
  SELECT cp.current_level, cp.invite_cap_override
  INTO   v_level, v_override
  FROM   connect.connected_profiles cp
  WHERE  cp.user_id = p_user_id;

  IF NOT FOUND THEN
    -- Not connected — return empty result set
    RETURN;
  END IF;

  v_level_cap := connect.get_invite_cap_for_level(v_level);

  IF v_override = -1 THEN
    v_effective_cap := 2147483647;
  ELSE
    v_effective_cap := GREATEST(v_level_cap, COALESCE(v_override, 0));
  END IF;

  -- Step 2: Count active invitee slots (canonical query — matches generate RPC).
  SELECT COUNT(*)::INT INTO v_active_count
  FROM connect.invite_chains ic
  JOIN connect.invite_codes code ON code.id = ic.invite_code_id
  JOIN connect.connected_profiles invitee ON invitee.user_id = ic.invitee_id
  WHERE ic.inviter_id = p_user_id
    AND code.is_claimed = true
    AND invitee.current_level < 2
    AND NOT (
      ic.slot_locked_until IS NOT NULL
      AND ic.slot_locked_until < now()
      AND invitee.account_standing = 'active'
    );

  -- Step 3: Return all claimed invitees (complete list: active, graduated, expired-lock).
  RETURN QUERY
  SELECT ic.invitee_id,
         u.display_name,
         invitee.account_standing,
         invitee.current_level,
         (invitee.current_level >= 2) AS graduated,
         ic.slot_locked_until,
         code_row.claimed_at,
         v_active_count AS active_count,
         v_effective_cap AS effective_cap
  FROM connect.invite_chains ic
  JOIN connect.invite_codes code_row ON code_row.id = ic.invite_code_id
  JOIN connect.connected_profiles invitee ON invitee.user_id = ic.invitee_id
  JOIN public.users u ON u.id = ic.invitee_id
  WHERE ic.inviter_id = p_user_id
    AND code_row.is_claimed = true
  ORDER BY code_row.claimed_at DESC;

END;
$$;

GRANT EXECUTE ON FUNCTION connect.get_my_invitees(UUID) TO authenticated;


-- =============================================================================
-- Section 5: connect.sanction_invitee
-- =============================================================================
-- Atomic sanction: adjusts inviter TR, locks slot, sends notification.
-- Called by admin or moderation system when an invitee is sanctioned.
--
-- TR adjustment is inline (NOT via nested adjust_inviter_tolerance_rating RPC)
-- following the v1.4 no-nested-SECURITY-DEFINER pattern. This avoids double-
-- notification (adjust_inviter_tolerance_rating writes to notification_events;
-- this function writes to public.notifications).
--
-- Phase 59: flat -0.25 penalty. Severity-scaled TR penalties deferred to later.
--
-- If no inviter found (admin-created invite), returns immediately — no chain.

CREATE OR REPLACE FUNCTION connect.sanction_invitee(
  p_invitee_id UUID,
  p_tr_delta   NUMERIC DEFAULT -0.25
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_inviter_id    UUID;
  v_new_tr        NUMERIC;
  v_lock_until    TIMESTAMPTZ := now() + interval '60 days';
BEGIN

  -- Step 1: Find inviter via invite_chains.
  SELECT ic.inviter_id
  INTO   v_inviter_id
  FROM   connect.invite_chains ic
  WHERE  ic.invitee_id = p_invitee_id;

  -- Step 2: No inviter = admin-created invite, no accountability chain.
  IF NOT FOUND OR v_inviter_id IS NULL THEN
    RETURN;
  END IF;

  -- Step 3: Lock the invitee's slot for 60 days.
  UPDATE connect.invite_chains
  SET    slot_locked_until = v_lock_until
  WHERE  invitee_id = p_invitee_id
    AND  inviter_id = v_inviter_id;

  -- Step 4: Adjust inviter TR inline (v1.4 pattern: no nested SECURITY DEFINER calls).
  UPDATE connect.connected_profiles
  SET    tolerance_rating = GREATEST(0.00, COALESCE(tolerance_rating, 1.00) + p_tr_delta),
         updated_at       = now()
  WHERE  user_id = v_inviter_id
  RETURNING tolerance_rating INTO v_new_tr;

  -- Step 5: Auto-suspend if TR hit 0.
  IF v_new_tr <= 0.00 THEN
    UPDATE connect.connected_profiles
    SET    account_standing = 'suspended'
    WHERE  user_id = v_inviter_id;
  END IF;

  -- Step 6: Notify inviter via public.notifications.
  INSERT INTO public.notifications (user_id, type, payload)
  VALUES (
    v_inviter_id,
    'invitee_sanctioned',
    jsonb_build_object(
      'invitee_id',        p_invitee_id,
      'slot_locked_until', v_lock_until::text,
      'tr_impact',         p_tr_delta
    )
  );

END;
$$;

GRANT EXECUTE ON FUNCTION connect.sanction_invitee(UUID, NUMERIC) TO authenticated;


COMMIT;
