BEGIN;

-- =============================================================================
-- Migration 034: Phase 22 — Gem Award Idempotency
-- =============================================================================
-- Adds idempotency support to the gem system, enabling external services (CTC
-- and future feature repos) to award gems via HTTP with safe retry semantics.
--
-- Two sections:
--
--   Section 1: idempotency_key column on connect.gem_transactions
--              Partial unique index ensures non-NULL keys are deduplicated while
--              leaving existing NULL rows unaffected (Postgres UNIQUE constraints
--              treat NULLs as distinct; partial index is the correct approach).
--
--   Section 2: connect.award_gems RPC
--              New function — does NOT modify credit_gems (cron/internal use).
--              Mirrors the award_xp pattern from migration 030:
--                - pg_advisory_xact_lock to serialize per-user
--                - idempotency pre-check before any writes
--                - EXECUTE format for dynamic balance column (injection-safe)
--                - RETURNS TABLE with is_duplicate flag
--
-- IMPORTANT: gem_balance_yellow/blue/red (NOT yellow_gem_balance).
-- SECURITY DEFINER + SET search_path = '' on all functions per project convention.
-- =============================================================================


-- =============================================================================
-- Section 1: idempotency_key column on gem_transactions
-- =============================================================================

ALTER TABLE connect.gem_transactions
  ADD COLUMN idempotency_key TEXT;

-- Partial unique index: only non-NULL keys must be unique.
-- WHY partial: existing rows have NULL idempotency_key; a standard UNIQUE
-- constraint or index would not deduplicate among NULLs anyway in Postgres,
-- but a partial index makes the intent explicit and avoids any ambiguity.
CREATE UNIQUE INDEX idx_gem_transactions_idempotency_key
  ON connect.gem_transactions (idempotency_key)
  WHERE idempotency_key IS NOT NULL;


-- =============================================================================
-- Section 2: connect.award_gems RPC
-- =============================================================================
-- Atomic gem award: the HTTP-facing write path for gem grants from external
-- services. Called by the awards API layer via adminRpc('award_gems', {...}).
-- Never replaces credit_gems — that function remains for cron/internal use.
--
-- Steps (mirrors award_xp from migration 030 and credit_gems from migration 023):
--   1. Validate p_gem_type IN ('red', 'blue', 'yellow') — prevent injection
--   2. Validate p_amount > 0
--   3. Acquire transaction-level advisory lock on user_id hash (serializes
--      concurrent awards for same user; auto-released on COMMIT/ROLLBACK)
--   4. Idempotency pre-check: if idempotency_key already used, return original
--      row + current balance + is_duplicate = TRUE; no second ledger insert
--   5. Lock profile row with SELECT ... FOR UPDATE (double safety layer)
--   6. Compute new balance
--   7. UPDATE denormalized gem_balance_<type> column via EXECUTE format
--   8. INSERT into gem_transactions with idempotency_key + transaction_type
--   9. RETURN all fields + is_duplicate = FALSE
--
-- GRANT EXECUTE to authenticated only (service role bypasses grants entirely).

CREATE OR REPLACE FUNCTION connect.award_gems(
  p_user_id            UUID,
  p_gem_type           TEXT,
  p_amount             INTEGER,
  p_idempotency_key    TEXT,
  p_transaction_type   TEXT DEFAULT 'service_award',
  p_source_ref         UUID DEFAULT NULL
)
RETURNS TABLE (
  id               UUID,
  user_id          UUID,
  gem_type         TEXT,
  amount           INTEGER,
  idempotency_key  TEXT,
  balance_after    INTEGER,
  created_at       TIMESTAMPTZ,
  is_duplicate     BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_existing_tx     connect.gem_transactions;
  v_current_balance INTEGER;
  v_new_balance     INTEGER;
  v_txn_id          UUID;
  v_txn_created_at  TIMESTAMPTZ;
BEGIN

  -- Step 1: Validate gem_type before using in EXECUTE format — prevents column-name injection
  IF p_gem_type NOT IN ('red', 'blue', 'yellow') THEN
    RAISE EXCEPTION 'Invalid gem_type: %. Must be red, blue, or yellow.', p_gem_type;
  END IF;

  -- Step 2: Validate amount
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Gem award amount must be positive. Got: %', p_amount;
  END IF;

  -- Step 3: Acquire transaction-level advisory lock keyed on user_id hash.
  -- Serializes concurrent award_gems calls for the same user within this
  -- transaction. hashtext() maps UUID text → int8 deterministically.
  -- Lock is auto-released on COMMIT or ROLLBACK (transaction-level).
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Step 4: Idempotency pre-check.
  -- If this idempotency_key was already processed, return the original row
  -- with the current balance and is_duplicate = TRUE. No second insert.
  SELECT * INTO v_existing_tx
    FROM connect.gem_transactions gt
    WHERE gt.idempotency_key = p_idempotency_key;

  IF FOUND THEN
    -- Read the current balance for the relevant gem type
    EXECUTE format(
      'SELECT gem_balance_%s FROM connect.connected_profiles WHERE user_id = $1',
      p_gem_type
    ) INTO v_current_balance USING p_user_id;

    RETURN QUERY SELECT
      v_existing_tx.id,
      v_existing_tx.user_id,
      v_existing_tx.gem_type,
      v_existing_tx.amount,
      v_existing_tx.idempotency_key,
      v_existing_tx.balance_after,
      v_existing_tx.created_at,
      TRUE::BOOLEAN;  -- is_duplicate

    RETURN;
  END IF;

  -- Step 5: Lock profile row to prevent concurrent balance updates.
  -- FOR UPDATE acquires a row-level lock until COMMIT/ROLLBACK.
  -- The advisory lock (step 3) already serializes same-user concurrency,
  -- but FOR UPDATE adds a second safety layer for advisory key-space collisions.
  EXECUTE format(
    'SELECT gem_balance_%s FROM connect.connected_profiles WHERE user_id = $1 FOR UPDATE',
    p_gem_type
  ) INTO v_current_balance USING p_user_id;

  IF v_current_balance IS NULL THEN
    RAISE EXCEPTION 'User % has no connected_profiles row. Cannot award gems.', p_user_id;
  END IF;

  -- Step 6: Compute new balance
  v_new_balance := v_current_balance + p_amount;

  -- Step 7: Update the denormalized per-type balance column
  EXECUTE format(
    'UPDATE connect.connected_profiles SET gem_balance_%s = $1, updated_at = now() WHERE user_id = $2',
    p_gem_type
  ) USING v_new_balance, p_user_id;

  -- Step 8: Append to the append-only gem ledger, including idempotency_key and transaction_type
  INSERT INTO connect.gem_transactions (
    user_id,
    gem_type,
    amount,
    idempotency_key,
    transaction_type,
    balance_after,
    reference_id
  )
  VALUES (
    p_user_id,
    p_gem_type,
    p_amount,
    p_idempotency_key,
    p_transaction_type,
    v_new_balance,
    p_source_ref
  )
  RETURNING
    connect.gem_transactions.id,
    connect.gem_transactions.created_at
  INTO v_txn_id, v_txn_created_at;

  -- Step 9: Return the inserted row fields + is_duplicate = FALSE
  RETURN QUERY SELECT
    v_txn_id,
    p_user_id,
    p_gem_type,
    p_amount,
    p_idempotency_key,
    v_new_balance,
    v_txn_created_at,
    FALSE::BOOLEAN;  -- is_duplicate

-- Re-raise any exception; Postgres auto-rolls back all changes in this block
EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

GRANT EXECUTE ON FUNCTION connect.award_gems(UUID, TEXT, INTEGER, TEXT, TEXT, UUID) TO authenticated;


COMMIT;
