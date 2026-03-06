-- =============================================================================
-- Migration 028: RPC import_compass_calibrations
--
-- SECURITY DEFINER function that atomically imports a batch of compass
-- calibration answers for a user.
-- Called via supabaseAdmin.rpc('import_compass_calibrations', { p_user_id, p_calibrations, ... }).
--
-- p_calibrations is a JSONB array. Each element must contain:
--   topic_id       UUID   (required — must exist in inform.compass_topics)
--   value          int    (required — 1..5)
--   write_in_text  text   (optional)
--   inverted       bool   (optional, defaults false)
--
-- Two-pass design (atomicity guarantee):
--   Pass 1 — Full validation loop: iterates all elements and raises on the first
--             invalid element. NO writes happen in this pass.
--   Pass 2 — Upsert loop: runs only after Pass 1 completes without error.
--             ON CONFLICT (user_id, topic_id) DO UPDATE handles both first-time
--             calibration and re-import (including un-soft-deleting a reset row).
--
-- A single combined loop would allow partial writes before a validation failure
-- is encountered, violating the atomicity guarantee. Two separate loops ensure
-- all-or-nothing semantics: either every element is written, or nothing is.
--
-- Called via supabaseAdmin.rpc() — SECURITY DEFINER bypasses RLS.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.import_compass_calibrations(
  p_user_id                 UUID,
  p_calibrations            JSONB,
  p_set_onboarding_complete BOOLEAN DEFAULT false
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  elem         JSONB;
  v_topic_id   UUID;
  v_value      INT;
  v_topic_exists BOOLEAN;
BEGIN

  -- ===========================================================================
  -- Pass 1: Full validation — no writes.
  -- If any element is invalid, RAISE immediately; nothing will be written.
  -- ===========================================================================

  FOR elem IN SELECT * FROM jsonb_array_elements(p_calibrations)
  LOOP

    -- topic_id must be a valid non-null UUID string
    BEGIN
      v_topic_id := (elem->>'topic_id')::uuid;
    EXCEPTION WHEN invalid_text_representation OR not_null_violation THEN
      RAISE EXCEPTION 'INVALID_CALIBRATION: topic_id is not a valid UUID: %', elem->>'topic_id';
    END;

    IF v_topic_id IS NULL THEN
      RAISE EXCEPTION 'INVALID_CALIBRATION: topic_id is required';
    END IF;

    -- topic_id must exist in inform.compass_topics
    SELECT EXISTS(
      SELECT 1 FROM inform.compass_topics WHERE id = v_topic_id
    ) INTO v_topic_exists;

    IF NOT v_topic_exists THEN
      RAISE EXCEPTION 'INVALID_CALIBRATION: topic_id % not found in compass_topics', v_topic_id;
    END IF;

    -- value must be present and in range 1..5
    IF (elem->>'value') IS NULL THEN
      RAISE EXCEPTION 'INVALID_CALIBRATION: value is required for topic_id %', v_topic_id;
    END IF;

    BEGIN
      v_value := (elem->>'value')::int;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'INVALID_CALIBRATION: value is not an integer for topic_id %', v_topic_id;
    END;

    IF v_value < 1 OR v_value > 5 THEN
      RAISE EXCEPTION 'INVALID_CALIBRATION: value % is out of range (1..5) for topic_id %', v_value, v_topic_id;
    END IF;

  END LOOP;


  -- ===========================================================================
  -- Pass 2: Upsert — runs only after full validation above completes.
  -- ON CONFLICT handles both first calibration and re-import after a reset.
  -- deleted_at = NULL in DO UPDATE un-soft-deletes a previously reset row.
  -- ===========================================================================

  FOR elem IN SELECT * FROM jsonb_array_elements(p_calibrations)
  LOOP

    INSERT INTO inform.compass_responses (
      user_id,
      topic_id,
      value,
      write_in_text,
      inverted,
      updated_at,
      deleted_at
    )
    VALUES (
      p_user_id,
      (elem->>'topic_id')::uuid,
      (elem->>'value')::int,
      elem->>'write_in_text',
      COALESCE((elem->>'inverted')::boolean, false),
      now(),
      NULL  -- explicit NULL: new/re-imported rows are always active
    )
    ON CONFLICT (user_id, topic_id) DO UPDATE
      SET value         = EXCLUDED.value,
          write_in_text = EXCLUDED.write_in_text,
          inverted      = EXCLUDED.inverted,
          updated_at    = now(),
          deleted_at    = NULL;  -- un-soft-delete if row was previously reset

  END LOOP;


  -- ===========================================================================
  -- Step 3: Optionally mark onboarding complete.
  -- Guarded with completed_onboarding = false to avoid touching already-
  -- complete profiles unnecessarily (skips the write if already true).
  -- ===========================================================================

  IF p_set_onboarding_complete THEN
    UPDATE connect.connected_profiles
      SET completed_onboarding = true,
          updated_at            = now()
      WHERE user_id             = p_user_id
        AND completed_onboarding = false;
  END IF;

EXCEPTION WHEN OTHERS THEN
  RAISE;

END;
$$;
