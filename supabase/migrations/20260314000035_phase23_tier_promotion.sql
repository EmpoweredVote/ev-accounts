BEGIN;

-- =============================================================================
-- Migration 035: Phase 23 — Tier Promotion Log + Promote to Connected RPC
-- =============================================================================
-- Establishes the backend schema for admin-driven tier promotion:
--
--   1. connect.tier_promotion_log    — audit log for admin tier promotions
--   2. empower.empowered_profiles    — ADD politician_id FK column
--   3. connect.promote_to_connected  — SECURITY DEFINER RPC for atomic promotion
--
-- All functions:
--   - SECURITY DEFINER (runs with definer's privileges, bypasses RLS)
--   - SET search_path = '' (prevents search_path injection attacks)
--   - Fully-qualified schema.table references throughout
-- =============================================================================


-- =============================================================================
-- Step 1: connect.tier_promotion_log
-- =============================================================================
-- Append-only audit log for every admin-initiated tier promotion.
-- admin_email is denormalized (copied from auth.users at write time) to avoid
-- a join to auth schema at read time. This is the only correct approach —
-- auth schema is not directly queryable from the connect schema in SECURITY
-- DEFINER functions without elevated privileges.

CREATE TABLE IF NOT EXISTS connect.tier_promotion_log (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id         UUID        NOT NULL REFERENCES public.users(id),
  admin_email      TEXT        NOT NULL,
  target_user_id   UUID        NOT NULL REFERENCES public.users(id),
  previous_tier    TEXT        NOT NULL,
  new_tier         TEXT        NOT NULL,
  note             TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for per-user promotion history lookups (GET /admin/accounts/:userId/promotion-history)
CREATE INDEX IF NOT EXISTS idx_tier_promotion_log_target_user_id
  ON connect.tier_promotion_log(target_user_id);

-- Index for admin activity lookups (used by global promotion log filter)
CREATE INDEX IF NOT EXISTS idx_tier_promotion_log_admin_id
  ON connect.tier_promotion_log(admin_id);


-- =============================================================================
-- Step 2: empower.empowered_profiles — ADD politician_id FK column
-- =============================================================================
-- Links an Empowered user to their politician record in inform.politicians.
-- Nullable — not every Empowered user has a linked politician record (e.g.,
-- candidates who haven't yet been matched to a politician record in the system).
-- No backfill needed; seed script in Plan 03 handles existing Empowered accounts.

ALTER TABLE empower.empowered_profiles
  ADD COLUMN IF NOT EXISTS politician_id UUID REFERENCES inform.politicians(id);


-- =============================================================================
-- Step 3: connect.promote_to_connected RPC
-- =============================================================================
-- Atomically promotes an Inform-tier user to Connected:
--   1. Validates target user exists in public.users
--   2. Checks for existing connected_profiles row (idempotency guard)
--   3. INSERTs connected_profiles row with admin_promotion verification method
--   4. INSERTs tier_promotion_log row for audit trail
--   5. Returns JSONB with ok=true and display_name for toast message
--
-- Called by the admin promote endpoint via adminRpc('promote_to_connected', {...}, 'connect').

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

  -- Step 5: Return success with display_name for toast message
  RETURN jsonb_build_object(
    'ok', true,
    'display_name', v_display_name
  );

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

GRANT EXECUTE ON FUNCTION connect.promote_to_connected(UUID, TEXT, UUID, TEXT) TO service_role;


COMMIT;
