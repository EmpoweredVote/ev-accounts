BEGIN;

-- =============================================================================
-- Migration 030: Phase 9 XP RPCs
-- =============================================================================
-- Two SECURITY DEFINER functions that form the entire write path for XP:
--
--   connect.calculate_level  — pure arithmetic, IMMUTABLE, computes level info
--                              from a total XP value. Independently callable
--                              for read-time level computation (Phase 10 endpoints).
--
--   connect.award_xp         — atomic entry point for all XP grants. Acquires
--                              an advisory lock, checks idempotency, updates
--                              connected_profiles.total_xp and current_level,
--                              and appends a ledger row to xp_transactions.
--                              Phase 10 API routes call ONLY this function —
--                              no JS-chained awaits for XP writes.
--
-- All functions:
--   - SECURITY DEFINER: runs with definer privileges, bypasses RLS for writes
--   - SET search_path = '': prevents search_path injection (Supabase requirement)
--   - Fully-qualified schema.table references throughout
--
-- Level thresholds (LOCKED — matches MEMORY.md and plan must_haves):
--   Tier 1: Levels  1–3,  2,000 XP each. Cumulative:        0 –  5,999 XP
--   Tier 2: Levels  4–9,  3,000 XP each. Cumulative:    6,000 – 23,999 XP
--   Tier 3: Levels 10–29, 4,000 XP each. Cumulative:   24,000 –103,999 XP
--   Tier 4: Level  30+,   5,000 XP each. Cumulative:  104,000+ XP
-- =============================================================================


-- =============================================================================
-- Section 1: connect.calculate_level
-- =============================================================================
-- Pure arithmetic function: given a total_xp value, returns the user's current
-- level, how much XP they have accumulated within that level, and how much XP
-- remains until the next level boundary.
--
-- IMMUTABLE: result is entirely determined by the input — no table reads,
-- no side effects. Postgres can cache/inline the result when called in queries.
--
-- GRANT to authenticated AND anon: calculate_level is called server-side via
-- award_xp (SECURITY DEFINER), and will also be exposed directly for the
-- Phase 10 public XP endpoint (anon can query a user's level without a JWT).
--
-- Tier boundary constants (values derived from threshold spec above):
--   tier2_start =   6,000  (= 3 levels × 2,000)
--   tier3_start =  24,000  (= 6,000 + 6 levels × 3,000)
--   tier4_start = 104,000  (= 24,000 + 20 levels × 4,000)

CREATE OR REPLACE FUNCTION connect.calculate_level(p_total_xp BIGINT)
RETURNS TABLE (level INT, xp_in_level INT, xp_to_next_level INT)
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH thresholds AS (
    SELECT
      6000   AS tier2_start,
      24000  AS tier3_start,
      104000 AS tier4_start,
      2000   AS tier1_step,
      3000   AS tier2_step,
      4000   AS tier3_step,
      5000   AS tier4_step
  ),
  computed AS (
    SELECT
      CASE
        WHEN p_total_xp < t.tier2_start THEN
          -- Tier 1: levels 1–3, 2,000 XP each
          (p_total_xp / t.tier1_step)::INT + 1
        WHEN p_total_xp < t.tier3_start THEN
          -- Tier 2: levels 4–9, 3,000 XP each
          3 + ((p_total_xp - t.tier2_start) / t.tier2_step)::INT + 1
        WHEN p_total_xp < t.tier4_start THEN
          -- Tier 3: levels 10–29, 4,000 XP each
          9 + ((p_total_xp - t.tier3_start) / t.tier3_step)::INT + 1
        ELSE
          -- Tier 4: level 30+, 5,000 XP each
          29 + ((p_total_xp - t.tier4_start) / t.tier4_step)::INT + 1
      END AS level,
      CASE
        WHEN p_total_xp < t.tier2_start THEN
          (p_total_xp % t.tier1_step)::INT
        WHEN p_total_xp < t.tier3_start THEN
          ((p_total_xp - t.tier2_start) % t.tier2_step)::INT
        WHEN p_total_xp < t.tier4_start THEN
          ((p_total_xp - t.tier3_start) % t.tier3_step)::INT
        ELSE
          ((p_total_xp - t.tier4_start) % t.tier4_step)::INT
      END AS xp_in_level,
      CASE
        WHEN p_total_xp < t.tier2_start THEN t.tier1_step
        WHEN p_total_xp < t.tier3_start THEN t.tier2_step
        WHEN p_total_xp < t.tier4_start THEN t.tier3_step
        ELSE t.tier4_step
      END AS tier_step
    FROM thresholds t
  )
  SELECT
    c.level,
    c.xp_in_level,
    (c.tier_step - c.xp_in_level)::INT AS xp_to_next_level
  FROM computed c;
$$;

GRANT EXECUTE ON FUNCTION connect.calculate_level(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION connect.calculate_level(BIGINT) TO anon;


-- =============================================================================
-- Section 2: connect.award_xp
-- =============================================================================
-- Atomic XP credit: the SINGLE write path for all XP awards in the platform.
-- Called by Phase 10 API routes via supabase.rpc('award_xp', {...}).
-- Never call xp_transactions INSERT or connected_profiles XP UPDATE directly —
-- this function owns that path.
--
-- Steps (mirrors credit_gems pattern from migration 023):
--   1. Validate p_amount > 0 (belt-and-suspenders alongside CHECK constraint)
--   2. Acquire transaction-level advisory lock on user_id hash (serializes
--      concurrent awards for the same user within the transaction; auto-released
--      on COMMIT or ROLLBACK — NOT a session-level lock)
--   3. Idempotency pre-check: if idempotency_key already exists, return the
--      original transaction row with is_duplicate = TRUE; no second ledger row
--   4. Lock profile row with SELECT ... FOR UPDATE (double safety layer)
--   5. Compute new total XP
--   6. Call calculate_level to get level, xp_in_level, xp_to_next_level
--   7. UPDATE connected_profiles.total_xp and .current_level atomically
--   8. INSERT ledger row into xp_transactions
--   9. RETURN all fields + computed level info + is_duplicate = FALSE
--  10. EXCEPTION WHEN OTHERS THEN RAISE (Postgres auto-rolls back the block)
--
-- GRANT EXECUTE to authenticated only (anon cannot award XP; service role
-- bypasses grants entirely when called with admin client).

CREATE OR REPLACE FUNCTION connect.award_xp(
  p_user_id         UUID,
  p_source          TEXT,
  p_amount          INT,
  p_idempotency_key TEXT,
  p_metadata        JSONB DEFAULT NULL
)
RETURNS TABLE (
  -- Transaction fields (from xp_transactions row)
  id               UUID,
  user_id          UUID,
  source           TEXT,
  amount           INT,
  metadata         JSONB,
  idempotency_key  TEXT,
  created_at       TIMESTAMPTZ,
  -- Computed level fields (from calculate_level)
  total_xp         BIGINT,
  current_level    INT,
  xp_in_level      INT,
  xp_to_next_level INT,
  -- Idempotency flag
  is_duplicate     BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_existing_tx  connect.xp_transactions;
  v_new_total_xp BIGINT;
  v_level_info   RECORD;
  v_inserted_row connect.xp_transactions;
BEGIN

  -- Step 1: Validate amount (belt-and-suspenders alongside CHECK constraint)
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'XP award amount must be positive. Got: %', p_amount;
  END IF;

  -- Step 2: Acquire transaction-level advisory lock keyed on user_id hash.
  -- Serializes concurrent award_xp calls for the same user within this transaction.
  -- hashtext() maps UUID text → int8 deterministically. Lock auto-released on
  -- COMMIT or ROLLBACK (transaction-level, NOT pg_advisory_lock session-level).
  PERFORM pg_advisory_xact_lock(hashtext(p_user_id::text));

  -- Step 3: Idempotency pre-check.
  -- If this idempotency_key was already processed, return the original row
  -- with the current profile state and is_duplicate = TRUE. No second insert.
  SELECT * INTO v_existing_tx
    FROM connect.xp_transactions xt
    WHERE xt.idempotency_key = p_idempotency_key;

  IF FOUND THEN
    -- Read current total_xp from the profile for the level computation
    SELECT cp.total_xp INTO v_new_total_xp
      FROM connect.connected_profiles cp
      WHERE cp.user_id = p_user_id;

    -- Compute level info against the CURRENT profile total (not the original award)
    SELECT * INTO v_level_info
      FROM connect.calculate_level(v_new_total_xp);

    RETURN QUERY SELECT
      v_existing_tx.id,
      v_existing_tx.user_id,
      v_existing_tx.source,
      v_existing_tx.amount,
      v_existing_tx.metadata,
      v_existing_tx.idempotency_key,
      v_existing_tx.created_at,
      v_new_total_xp,
      v_level_info.level,
      v_level_info.xp_in_level,
      v_level_info.xp_to_next_level,
      TRUE::BOOLEAN;  -- is_duplicate

    RETURN;
  END IF;

  -- Step 4: Lock profile row to prevent concurrent balance updates.
  -- FOR UPDATE acquires a row-level lock that holds until COMMIT/ROLLBACK.
  -- The advisory lock (step 2) already serializes same-user concurrency, but
  -- FOR UPDATE adds a second safety layer for advisory key-space collisions.
  SELECT cp.total_xp INTO v_new_total_xp
    FROM connect.connected_profiles cp
    WHERE cp.user_id = p_user_id
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User % has no connected_profiles row. Cannot award XP.', p_user_id;
  END IF;

  -- Step 5: Compute new total XP
  v_new_total_xp := v_new_total_xp + p_amount;

  -- Step 6: Compute level, xp_in_level, xp_to_next_level for the new total
  SELECT * INTO v_level_info
    FROM connect.calculate_level(v_new_total_xp);

  -- Step 7: Update connected_profiles atomically with the new XP and level
  UPDATE connect.connected_profiles
    SET
      total_xp      = v_new_total_xp,
      current_level = v_level_info.level,
      updated_at    = now()
    WHERE connected_profiles.user_id = p_user_id;

  -- Step 8: Append immutable ledger row to xp_transactions
  INSERT INTO connect.xp_transactions (
    user_id,
    source,
    amount,
    metadata,
    idempotency_key
  )
  VALUES (
    p_user_id,
    p_source,
    p_amount,
    p_metadata,
    p_idempotency_key
  )
  RETURNING * INTO v_inserted_row;

  -- Step 9: Return the inserted row + computed level fields + is_duplicate = FALSE
  RETURN QUERY SELECT
    v_inserted_row.id,
    v_inserted_row.user_id,
    v_inserted_row.source,
    v_inserted_row.amount,
    v_inserted_row.metadata,
    v_inserted_row.idempotency_key,
    v_inserted_row.created_at,
    v_new_total_xp,
    v_level_info.level,
    v_level_info.xp_in_level,
    v_level_info.xp_to_next_level,
    FALSE::BOOLEAN;  -- is_duplicate

-- Step 10: Re-raise any exception; Postgres auto-rolls back all changes in this block
EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

GRANT EXECUTE ON FUNCTION connect.award_xp(UUID, TEXT, INT, TEXT, JSONB) TO authenticated;


COMMIT;
