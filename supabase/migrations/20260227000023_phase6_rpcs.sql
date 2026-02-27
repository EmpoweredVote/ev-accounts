BEGIN;

-- =============================================================================
-- Migration 023: Phase 6 SECURITY DEFINER RPCs
-- =============================================================================
-- Three atomic operations required to be SECURITY DEFINER to enforce invariants
-- that cannot be expressed in RLS alone:
--
--   connect.credit_gems       — atomic gem credit: ledger insert + balance column update
--   connect.debit_gems        — atomic gem debit: validates non-negative balance, then ledger insert + balance update
--   connect.create_peer_request — peer connection creation with bidirectional block enforcement
--
-- All functions:
--   - SECURITY DEFINER: runs with definer privileges, bypasses RLS for writes
--   - SET search_path = '': prevents search_path injection (Supabase security requirement)
--   - Fully-qualified schema.table references throughout
--   - pg_advisory_xact_lock(hashtext(user_id::text)) for gem RPCs:
--       Serializes concurrent gem operations for the same user within a transaction.
--       Advisory lock is automatically released on COMMIT or ROLLBACK.
--       hashtext() maps UUID → int8 (advisory lock key type) deterministically.
--   - EXECUTE format(...) with p_gem_type pre-validated against allowlist:
--       gem_type is used in a dynamic column name (gem_balance_%s). The allowlist
--       check before EXECUTE format prevents SQL injection via the column name slot.
--
-- These RPCs are called by:
--   - Phase 6 gem service layer (gemService.ts) via supabase.rpc()
--   - Phase 7 cron for stipend grants
--   - Phase 6 social service layer (socialService.ts) for peer requests
-- =============================================================================


-- =============================================================================
-- Section 1: connect.credit_gems
-- =============================================================================
-- Credits the specified gem type for a user. Steps:
--   1. Validate gem_type (prevent SQL injection in EXECUTE format)
--   2. Validate p_amount > 0
--   3. Acquire transaction-level advisory lock on user_id (serializes concurrent credits/debits)
--   4. SELECT current balance with FOR UPDATE row lock
--   5. UPDATE denormalized gem_balance_<type> column
--   6. INSERT ledger row
--   7. RETURN the inserted gem_transactions row

CREATE OR REPLACE FUNCTION connect.credit_gems(
  p_user_id          UUID,
  p_gem_type         TEXT,
  p_amount           INTEGER,
  p_transaction_type TEXT,
  p_source_ref       UUID DEFAULT NULL
)
RETURNS connect.gem_transactions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_balance INTEGER;
  v_new_balance     INTEGER;
  v_result          connect.gem_transactions;
BEGIN

  -- Validate gem_type before using in EXECUTE format — prevents column-name injection
  IF p_gem_type NOT IN ('red', 'blue', 'yellow') THEN
    RAISE EXCEPTION 'Invalid gem_type: %. Must be red, blue, or yellow.', p_gem_type;
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Credit amount must be positive. Got: %', p_amount;
  END IF;

  -- Transaction-level advisory lock keyed on user_id hash.
  -- Serializes all gem operations (credits and debits) for this user within
  -- the current transaction. Released automatically on COMMIT/ROLLBACK.
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Read current per-type balance with FOR UPDATE row lock on the profile row.
  -- The advisory lock above already serializes, but FOR UPDATE adds a second layer
  -- of safety for any edge cases where the advisory lock key space has a collision.
  EXECUTE format(
    'SELECT gem_balance_%s FROM connect.connected_profiles WHERE user_id = $1 FOR UPDATE',
    p_gem_type
  ) INTO v_current_balance USING p_user_id;

  IF v_current_balance IS NULL THEN
    RAISE EXCEPTION 'User % has no connected_profiles row. Cannot credit gems.', p_user_id;
  END IF;

  v_new_balance := v_current_balance + p_amount;

  -- Update the denormalized per-type balance column
  EXECUTE format(
    'UPDATE connect.connected_profiles SET gem_balance_%s = $1, updated_at = now() WHERE user_id = $2',
    p_gem_type
  ) USING v_new_balance, p_user_id;

  -- Append to the append-only gem ledger
  INSERT INTO connect.gem_transactions (
    user_id,
    gem_type,
    amount,
    transaction_type,
    reference_id,
    balance_after
  )
  VALUES (
    p_user_id,
    p_gem_type,
    p_amount,           -- positive = credit
    p_transaction_type,
    p_source_ref,
    v_new_balance
  )
  RETURNING * INTO v_result;

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  -- Re-raise; Postgres automatically rolls back all changes in this block
  RAISE;
END;
$$;


-- =============================================================================
-- Section 2: connect.debit_gems
-- =============================================================================
-- Debits the specified gem type for a user. Identical to credit_gems except:
--   - Validates v_current_balance >= p_amount (no negative balance allowed)
--   - Inserts -p_amount into ledger (negative = debit)
--   - Raises INSUFFICIENT_BALANCE error with parseable prefix for service layer

CREATE OR REPLACE FUNCTION connect.debit_gems(
  p_user_id          UUID,
  p_gem_type         TEXT,
  p_amount           INTEGER,
  p_transaction_type TEXT,
  p_source_ref       UUID DEFAULT NULL
)
RETURNS connect.gem_transactions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_balance INTEGER;
  v_new_balance     INTEGER;
  v_result          connect.gem_transactions;
BEGIN

  -- Validate gem_type before using in EXECUTE format — prevents column-name injection
  IF p_gem_type NOT IN ('red', 'blue', 'yellow') THEN
    RAISE EXCEPTION 'Invalid gem_type: %. Must be red, blue, or yellow.', p_gem_type;
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Debit amount must be positive. Got: %', p_amount;
  END IF;

  -- Transaction-level advisory lock keyed on user_id hash.
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Read current per-type balance with FOR UPDATE row lock
  EXECUTE format(
    'SELECT gem_balance_%s FROM connect.connected_profiles WHERE user_id = $1 FOR UPDATE',
    p_gem_type
  ) INTO v_current_balance USING p_user_id;

  IF v_current_balance IS NULL THEN
    RAISE EXCEPTION 'User % has no connected_profiles row. Cannot debit gems.', p_user_id;
  END IF;

  -- Enforce non-negative balance invariant
  IF v_current_balance < p_amount THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE: % gem balance is % but debit requested %',
      p_gem_type, v_current_balance, p_amount;
  END IF;

  v_new_balance := v_current_balance - p_amount;

  -- Update the denormalized per-type balance column
  EXECUTE format(
    'UPDATE connect.connected_profiles SET gem_balance_%s = $1, updated_at = now() WHERE user_id = $2',
    p_gem_type
  ) USING v_new_balance, p_user_id;

  -- Append to the append-only gem ledger (negative amount = debit)
  INSERT INTO connect.gem_transactions (
    user_id,
    gem_type,
    amount,
    transaction_type,
    reference_id,
    balance_after
  )
  VALUES (
    p_user_id,
    p_gem_type,
    -p_amount,          -- negative = debit (ledger convention from migration 005)
    p_transaction_type,
    p_source_ref,
    v_new_balance
  )
  RETURNING * INTO v_result;

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;


-- =============================================================================
-- Section 3: connect.create_peer_request
-- =============================================================================
-- Creates a peer connection request from p_actor_id to p_target_id.
--
-- Enforcement invariants (all checked before INSERT):
--   1. SELF_REQUEST: actor cannot peer with themselves
--   2. Bidirectional lookup: checks BOTH directions in social_relationships
--      (actor→target AND target→actor) — no direction escapes the check
--   3. BLOCKED: either direction blocked → reject; block is always mutual
--   4. ALREADY_CONNECTED: accepted peer → reject (already friends)
--   5. PENDING: existing pending request in either direction → reject
--   6. DECLINED: re-sendable — DELETE the declined row, INSERT fresh pending row
--      (per CONTEXT.md: declined requests can be re-sent)
--
-- Called by: socialService.ts (POST /api/social/peer-requests)
-- NOT called for follows — follows go through service layer directly.

CREATE OR REPLACE FUNCTION connect.create_peer_request(
  p_actor_id  UUID,
  p_target_id UUID
)
RETURNS connect.social_relationships
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_existing RECORD;
  v_result   connect.social_relationships;
BEGIN

  -- Self-request guard
  IF p_actor_id = p_target_id THEN
    RAISE EXCEPTION 'SELF_REQUEST: Cannot send a peer request to yourself';
  END IF;

  -- Bidirectional relationship check: look for ANY existing peer row in either direction.
  -- A single SELECT with OR covers both actor→target and target→actor cases.
  SELECT status, actor_id INTO v_existing
  FROM connect.social_relationships
  WHERE connection_type = 'peer'
    AND (
      (actor_id = p_actor_id  AND target_id = p_target_id) OR
      (actor_id = p_target_id AND target_id = p_actor_id)
    )
  LIMIT 1;

  IF FOUND THEN
    IF v_existing.status = 'blocked' THEN
      -- Block is mutual: neither party can initiate a new request
      RAISE EXCEPTION 'BLOCKED: Cannot send a peer request to or from a blocked user';

    ELSIF v_existing.status = 'accepted' THEN
      RAISE EXCEPTION 'ALREADY_CONNECTED: These users are already connected as peers';

    ELSIF v_existing.status = 'pending' THEN
      RAISE EXCEPTION 'PENDING: A peer request already exists between these users';

    ELSIF v_existing.status = 'declined' THEN
      -- Declined requests are re-sendable per CONTEXT.md.
      -- Delete the old declined row (in either direction) before inserting a fresh
      -- pending row. The new row will always be actor→target (normalized direction).
      DELETE FROM connect.social_relationships
      WHERE connection_type = 'peer'
        AND (
          (actor_id = p_actor_id  AND target_id = p_target_id) OR
          (actor_id = p_target_id AND target_id = p_actor_id)
        );
      -- Fall through to INSERT below

    END IF;
  END IF;

  -- Insert the pending peer request
  INSERT INTO connect.social_relationships (actor_id, target_id, connection_type, status)
  VALUES (p_actor_id, p_target_id, 'peer', 'pending')
  RETURNING * INTO v_result;

  RETURN v_result;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;


COMMIT;
