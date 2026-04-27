-- =============================================================================
-- Phase 66 — Inform Profiles Backend Foundation
-- Migration 086: inform.yellow_gem_events ledger + award_inform_yellow_gem RPC (IBAK-04)
-- =============================================================================

-- 1. yellow_gem_events ledger table (idempotency + audit)
CREATE TABLE IF NOT EXISTS inform.yellow_gem_events (
  id               BIGSERIAL   PRIMARY KEY,
  user_id          UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount           INT         NOT NULL CHECK (amount > 0),
  transaction_type TEXT        NOT NULL,
  source_ref       TEXT,
  idempotency_key  TEXT        NOT NULL,
  balance_after    INT         NOT NULL,
  is_duplicate     BOOLEAN     NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_yellow_gem_events_idempotency UNIQUE (idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_yellow_gem_events_user_id
  ON inform.yellow_gem_events (user_id, created_at DESC);

-- 2. award_inform_yellow_gem RPC (mirrors connect.award_gems pattern)
CREATE OR REPLACE FUNCTION inform.award_inform_yellow_gem(
  p_user_id          UUID,
  p_amount           INT,
  p_idempotency_key  TEXT,
  p_transaction_type TEXT DEFAULT 'service_award',
  p_source_ref       TEXT DEFAULT NULL
)
RETURNS TABLE (
  gem_type     TEXT,
  amount       INT,
  balance_after INT,
  is_duplicate BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_lock_key    BIGINT;
  v_existing    inform.yellow_gem_events%ROWTYPE;
  v_new_balance INT;
BEGIN
  -- Idempotency pre-check (no lock needed — unique constraint protects)
  SELECT * INTO v_existing
    FROM inform.yellow_gem_events
    WHERE idempotency_key = p_idempotency_key;

  IF FOUND THEN
    RETURN QUERY SELECT
      'yellow'::TEXT,
      v_existing.amount,
      v_existing.balance_after,
      true::BOOLEAN;
    RETURN;
  END IF;

  -- Advisory lock on user to serialize concurrent awards
  v_lock_key := ('x' || substr(md5(p_user_id::TEXT), 1, 15))::BIT(60)::BIGINT;
  PERFORM pg_advisory_xact_lock(v_lock_key);

  -- Re-check after acquiring lock (race window)
  SELECT * INTO v_existing
    FROM inform.yellow_gem_events
    WHERE idempotency_key = p_idempotency_key;

  IF FOUND THEN
    RETURN QUERY SELECT
      'yellow'::TEXT,
      v_existing.amount,
      v_existing.balance_after,
      true::BOOLEAN;
    RETURN;
  END IF;

  -- Validate amount
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'amount must be positive';
  END IF;

  -- Ensure inform_profiles row exists (defensive — trigger should have created it)
  INSERT INTO inform.inform_profiles (user_id)
  VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  -- Increment balance
  UPDATE inform.inform_profiles
    SET yellow_gem_balance = yellow_gem_balance + p_amount
    WHERE user_id = p_user_id
  RETURNING yellow_gem_balance INTO v_new_balance;

  -- Insert ledger row
  INSERT INTO inform.yellow_gem_events (
    user_id, amount, transaction_type, source_ref,
    idempotency_key, balance_after, is_duplicate
  ) VALUES (
    p_user_id, p_amount, p_transaction_type, p_source_ref,
    p_idempotency_key, v_new_balance, false
  );

  RETURN QUERY SELECT
    'yellow'::TEXT,
    p_amount,
    v_new_balance,
    false::BOOLEAN;
END;
$$;
