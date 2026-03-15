BEGIN;

-- =============================================================================
-- Migration 038: Phase 28 VQ Confirmation Flow
-- =============================================================================
-- Delivers the full VQ (Validation Quest) confirmation infrastructure:
--
--   connect.vq_confirmation_results
--     Result-cache table for idempotent replay of VQ confirmation events.
--     Primary key on idempotency_key prevents double-processing.
--
--   connect.confirm_vq_stance(...)
--     Atomic SECURITY DEFINER RPC that resolves a VQ question:
--       - Idempotency pre-check (returns cached result if duplicate key)
--       - Validates confirmed_value (1-5) and politician/topic pair existence
--       - Acquires advisory locks in sorted UUID order (deadlock prevention)
--       - Awards Red Gems + increases verification_rating (+3, cap 150) for
--         correct users
--       - Decreases verification_rating (-10, floor 0) for incorrect users;
--         sets vq_hold_until 30 days out when rating hits 0
--       - Upserts confirmed stance into inform.politician_answers
--       - Caches result for replay
--
-- Privacy note:
--   vq_hold_until is an internal enforcement state — excluded from public view
--   (same pattern as tolerance_rating). Phase 27 established this column.
-- =============================================================================


-- =============================================================================
-- Section 1: vq_confirmation_results — idempotency result cache
-- =============================================================================

CREATE TABLE IF NOT EXISTS connect.vq_confirmation_results (
  idempotency_key  TEXT        PRIMARY KEY,
  result_json      JSONB       NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Service can re-read its own cached results; all writes via SECURITY DEFINER RPC
GRANT SELECT, INSERT ON connect.vq_confirmation_results TO authenticated;


-- =============================================================================
-- Section 2: confirm_vq_stance RPC
-- =============================================================================
-- Atomically resolves a Validation Quest question. Single transaction;
-- all-or-nothing. Advisory locks prevent deadlocks when concurrent calls
-- share users.
--
-- Arguments:
--   p_politician_id    UUID  — the politician whose stance is being confirmed
--   p_topic_id         UUID  — the compass topic (question) being confirmed
--   p_confirmed_value  INT   — the confirmed answer (1–5)
--   p_correct_users    UUID[] — users who answered correctly (earn gems + VR)
--   p_incorrect_users  UUID[] — users who answered incorrectly (lose VR)
--   p_idempotency_key  TEXT  — caller-provided dedup key
--   p_gems_amount      INT   — red gems to award to each correct user
--
-- Returns JSONB result object (see build result section for shape).

CREATE OR REPLACE FUNCTION connect.confirm_vq_stance(
  p_politician_id    UUID,
  p_topic_id         UUID,
  p_confirmed_value  INTEGER,
  p_correct_users    UUID[],
  p_incorrect_users  UUID[],
  p_idempotency_key  TEXT,
  p_gems_amount      INTEGER
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_cached_result     JSONB;
  v_return_result     JSONB;
  v_politician_exists BOOLEAN;
  v_all_users         UUID[];
  v_sorted_users      UUID[];
  v_uid               UUID;
  -- correct user processing vars
  v_vr                INTEGER;
  v_gem_balance_red   INTEGER;
  v_new_rating        INTEGER;
  v_rating_delta      INTEGER;
  -- result accumulators
  v_user_results      JSONB[] := ARRAY[]::JSONB[];
  v_unresolved_users  UUID[]  := ARRAY[]::UUID[];
  v_correct_count     INTEGER := 0;
  v_incorrect_count   INTEGER := 0;
BEGIN

  -- -------------------------------------------------------------------------
  -- Step 1: Validate confirmed_value (1–5)
  -- -------------------------------------------------------------------------
  IF p_confirmed_value < 1 OR p_confirmed_value > 5 THEN
    RAISE EXCEPTION 'INVALID_VALUE: confirmed_value must be between 1 and 5';
  END IF;

  -- -------------------------------------------------------------------------
  -- Step 2: Idempotency pre-check — no locks, no writes
  -- -------------------------------------------------------------------------
  SELECT result_json
    INTO v_cached_result
    FROM connect.vq_confirmation_results
   WHERE idempotency_key = p_idempotency_key;

  IF FOUND THEN
    -- Add replayed flag and return immediately
    RETURN v_cached_result || '{"replayed": true}'::JSONB;
  END IF;

  -- -------------------------------------------------------------------------
  -- Step 3: Validate politician/topic pair exists
  -- -------------------------------------------------------------------------
  SELECT EXISTS (
    SELECT 1
      FROM inform.politicians p
     WHERE p.id = p_politician_id
       AND EXISTS (
         SELECT 1
           FROM inform.compass_topics t
          WHERE t.id = p_topic_id
       )
  ) INTO v_politician_exists;

  IF NOT v_politician_exists THEN
    RAISE EXCEPTION 'QUESTION_NOT_FOUND: politician % or topic % does not exist',
      p_politician_id, p_topic_id;
  END IF;

  -- -------------------------------------------------------------------------
  -- Step 4: Collect all user IDs and acquire advisory locks in sorted order
  --         Sorted order prevents deadlocks when concurrent calls share users.
  -- -------------------------------------------------------------------------
  v_all_users := ARRAY(
    SELECT DISTINCT unnest(p_correct_users || p_incorrect_users)
  );

  -- Sort UUIDs lexicographically (cast to text for ordering)
  SELECT ARRAY(
    SELECT u FROM unnest(v_all_users) u ORDER BY u::TEXT
  ) INTO v_sorted_users;

  FOREACH v_uid IN ARRAY v_sorted_users LOOP
    PERFORM pg_advisory_xact_lock(hashtext(v_uid::TEXT));
  END LOOP;

  -- -------------------------------------------------------------------------
  -- Step 5: Process correct users
  -- -------------------------------------------------------------------------
  FOREACH v_uid IN ARRAY p_correct_users LOOP
    -- Lock acquired above; just read for update
    SELECT verification_rating, gem_balance_red
      INTO v_vr, v_gem_balance_red
      FROM connect.connected_profiles
     WHERE user_id = v_uid
       FOR UPDATE;

    IF NOT FOUND THEN
      v_unresolved_users := v_unresolved_users || v_uid;
      CONTINUE;
    END IF;

    -- Rating: +3, cap at 150
    v_new_rating  := LEAST(v_vr + 3, 150);
    v_rating_delta := v_new_rating - v_vr;

    -- Update rating
    UPDATE connect.connected_profiles
       SET verification_rating = v_new_rating
     WHERE user_id = v_uid;

    -- Insert gem transaction ledger row (idempotency_key per-user)
    INSERT INTO connect.gem_transactions (
      user_id,
      gem_type,
      amount,
      transaction_type,
      idempotency_key,
      balance_after
    ) VALUES (
      v_uid,
      'red',
      p_gems_amount,
      'vq_correct',
      p_idempotency_key || ':' || v_uid::TEXT,
      v_gem_balance_red + p_gems_amount
    );

    -- Update gem balance
    UPDATE connect.connected_profiles
       SET gem_balance_red = gem_balance_red + p_gems_amount
     WHERE user_id = v_uid;

    v_user_results := v_user_results || jsonb_build_object(
      'user_id',      v_uid,
      'result',       'correct',
      'gems_awarded', p_gems_amount,
      'rating_delta', v_rating_delta,
      'new_rating',   v_new_rating
    );

    v_correct_count := v_correct_count + 1;
  END LOOP;

  -- -------------------------------------------------------------------------
  -- Step 6: Process incorrect users
  -- -------------------------------------------------------------------------
  FOREACH v_uid IN ARRAY p_incorrect_users LOOP
    SELECT verification_rating
      INTO v_vr
      FROM connect.connected_profiles
     WHERE user_id = v_uid
       FOR UPDATE;

    IF NOT FOUND THEN
      v_unresolved_users := v_unresolved_users || v_uid;
      CONTINUE;
    END IF;

    -- Rating: -10, floor at 0
    v_new_rating  := GREATEST(v_vr - 10, 0);
    v_rating_delta := v_new_rating - v_vr;

    -- Update rating; set vq_hold_until if floor hit (always overwrite — resets clock)
    UPDATE connect.connected_profiles
       SET verification_rating = v_new_rating,
           vq_hold_until = CASE
             WHEN v_new_rating = 0 THEN now() + INTERVAL '30 days'
             ELSE vq_hold_until
           END
     WHERE user_id = v_uid;

    v_user_results := v_user_results || jsonb_build_object(
      'user_id',      v_uid,
      'result',       'incorrect',
      'gems_awarded', 0,
      'rating_delta', v_rating_delta,
      'new_rating',   v_new_rating
    );

    v_incorrect_count := v_incorrect_count + 1;
  END LOOP;

  -- -------------------------------------------------------------------------
  -- Step 7: Upsert confirmed politician stance
  -- -------------------------------------------------------------------------
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
    VALUES (p_politician_id, p_topic_id, p_confirmed_value)
    ON CONFLICT (politician_id, topic_id)
    DO UPDATE SET value = EXCLUDED.value;

  -- -------------------------------------------------------------------------
  -- Step 8: Build result JSON
  -- -------------------------------------------------------------------------
  v_return_result := jsonb_build_object(
    'politician_id',    p_politician_id,
    'topic_id',         p_topic_id,
    'confirmed_value',  p_confirmed_value,
    'correct_count',    v_correct_count,
    'incorrect_count',  v_incorrect_count,
    'users',            to_jsonb(v_user_results),
    'unresolved_users', to_jsonb(v_unresolved_users)
  );

  -- -------------------------------------------------------------------------
  -- Step 9: Cache result for replay
  -- -------------------------------------------------------------------------
  INSERT INTO connect.vq_confirmation_results (idempotency_key, result_json)
    VALUES (p_idempotency_key, v_return_result);

  -- -------------------------------------------------------------------------
  -- Step 10: Return result
  -- -------------------------------------------------------------------------
  RETURN v_return_result;

END;
$$;

GRANT EXECUTE ON FUNCTION connect.confirm_vq_stance(
  UUID, UUID, INTEGER, UUID[], UUID[], TEXT, INTEGER
) TO authenticated;


COMMIT;
