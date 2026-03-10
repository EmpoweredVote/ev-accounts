-- =============================================================================
-- Migration 030: Decimal compass values + guest state migration RPC
--
-- CompassV2 allows write-in answers to be placed at half-integer positions
-- between predefined stances (e.g., 1.5 between stances 1 and 2). The current
-- INT column and upsert_compass_answer RPC reject any non-integer value.
--
-- Changes:
--
--   1. compass_responses.value — INT → NUMERIC(3,1). Existing integer values
--      (1, 2, 3, 4, 5) cast losslessly to 1.0, 2.0, etc. CHECK constraint
--      updated to accept 0.5-increment values from 0.5 to 5.5.
--
--   2. compass_change_history.old_value / new_value — INT → NUMERIC(3,1) to
--      stay consistent with compass_responses.value (audit log must match).
--
--   3. upsert_compass_answer — p_value parameter changed from INT to NUMERIC.
--      All other logic preserved exactly. Adds SET search_path = '' (missing
--      from the migration 025 version).
--
--   4. migrate_guest_compass_state — new RPC for atomic guest answer migration
--      on signup. Bulk-inserts guest answers and optionally sets selected
--      topic IDs. ON CONFLICT DO NOTHING throughout — never overwrites
--      post-signup activity. Required by Plan 18-03.
--
-- Idempotency: ALTER COLUMN TYPE from INT to NUMERIC(3,1) is safe to re-run
-- (Postgres casts INT→NUMERIC losslessly; if already NUMERIC(3,1) it is a
-- no-op). CREATE OR REPLACE functions are inherently idempotent.
--
-- Must be run against the live DB via the admin apply-migration tooling
-- (e.g., `node backend/scripts/applyMigration.js 030`).
-- =============================================================================


-- =============================================================================
-- Section 1: compass_responses.value column type change
-- =============================================================================

-- Drop the existing INT check constraint (name may vary across environments)
ALTER TABLE inform.compass_responses
  DROP CONSTRAINT IF EXISTS compass_responses_value_check;

-- Change column type from INT to NUMERIC(3,1)
-- Implicit cast from INT is lossless — existing integer values (1, 2, 3, 4, 5)
-- become 1.0, 2.0, 3.0, 4.0, 5.0 with no data loss.
ALTER TABLE inform.compass_responses
  ALTER COLUMN value TYPE NUMERIC(3,1);

-- Add updated check constraint: 0.5-increment values from 0.5 to 5.5.
-- Predefined stances remain at integer positions (1, 2, 3, 4, 5).
-- Write-in placements use half-integer positions (1.5, 2.5, 3.5, 4.5).
-- Outer bounds 0.5 and 5.5 allow placement just outside the defined range.
ALTER TABLE inform.compass_responses
  ADD CONSTRAINT compass_responses_value_check CHECK (value >= 0.5 AND value <= 5.5);


-- =============================================================================
-- Section 2: compass_change_history history columns
-- =============================================================================

-- Keep audit log column types consistent with compass_responses.value.
-- Existing integer values cast losslessly.
ALTER TABLE inform.compass_change_history
  ALTER COLUMN old_value TYPE NUMERIC(3,1);

ALTER TABLE inform.compass_change_history
  ALTER COLUMN new_value TYPE NUMERIC(3,1);


-- =============================================================================
-- Section 3: Updated upsert_compass_answer RPC
-- =============================================================================

-- Replaces the version from migration 025. Only change: p_value INT → NUMERIC.
-- Also adds SET search_path = '' (missing from 025 version).
-- All body logic preserved exactly.
CREATE OR REPLACE FUNCTION public.upsert_compass_answer(
  p_user_id       UUID,
  p_topic_id      UUID,
  p_value         NUMERIC,
  p_write_in_text TEXT    DEFAULT NULL,
  p_inverted      BOOLEAN DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old_value NUMERIC;
  v_result    inform.compass_responses;
BEGIN
  -- Validate topic exists and is live
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE id = p_topic_id AND is_live = true
  ) THEN
    RAISE EXCEPTION 'TOPIC_NOT_FOUND';
  END IF;

  -- Capture old value for change_history (NULL on first calibration)
  SELECT value INTO v_old_value
  FROM inform.compass_responses
  WHERE user_id = p_user_id AND topic_id = p_topic_id;

  -- UPSERT the response
  INSERT INTO inform.compass_responses (user_id, topic_id, value, write_in_text, inverted, updated_at)
  VALUES (p_user_id, p_topic_id, p_value, p_write_in_text, p_inverted, now())
  ON CONFLICT (user_id, topic_id) DO UPDATE
    SET value         = EXCLUDED.value,
        write_in_text = EXCLUDED.write_in_text,
        inverted      = EXCLUDED.inverted,
        updated_at    = now()
  RETURNING * INTO v_result;

  -- Append to change_history (always — even same-value recalibration)
  INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
  VALUES (p_user_id, p_topic_id, v_old_value, p_value);

  RETURN row_to_json(v_result)::jsonb;
END;
$$;


-- =============================================================================
-- Section 4: New migrate_guest_compass_state RPC
-- =============================================================================

-- Atomically migrates guest compass state for a newly-created user.
-- Called at the end of the signup flow after auth.signUp succeeds.
--
-- p_answers        — array of {topic_id, value, write_in_text?} objects.
-- p_selected_topics — optional array of topic UUIDs the guest had selected.
--
-- Safety guarantees:
--   - ON CONFLICT DO NOTHING for answer rows — never overwrites post-signup
--     activity if the user answers topics before migration runs.
--   - Per-row FK exception handler — a stale guest topic_id that no longer
--     exists in compass_topics skips that row instead of aborting the whole
--     migration.
--   - selected_topic_ids update is conditional — only applied when the user's
--     connected_profiles row has no existing selection (NULL or empty array).
CREATE OR REPLACE FUNCTION public.migrate_guest_compass_state(
  p_user_id        UUID,
  p_answers        JSONB,          -- [{topic_id: uuid, value: numeric, write_in_text?: text}]
  p_selected_topics UUID[] DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_answer   JSONB;
  v_topic_id UUID;
  v_value    NUMERIC;
  v_write_in TEXT;
BEGIN
  -- Migrate answers: one INSERT per element in p_answers array.
  -- ON CONFLICT DO NOTHING: if user already has an answer for this topic
  -- (e.g., they answered again between guest state save and migration),
  -- keep the newer post-signup answer unchanged.
  FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    BEGIN
      v_topic_id := (v_answer->>'topic_id')::UUID;
      v_value    := (v_answer->>'value')::NUMERIC;
      v_write_in := v_answer->>'write_in_text';  -- NULL if key absent

      INSERT INTO inform.compass_responses
        (user_id, topic_id, value, write_in_text, visibility, inverted, updated_at)
      VALUES
        (p_user_id, v_topic_id, v_value, v_write_in, 'private', false, NOW())
      ON CONFLICT (user_id, topic_id) DO NOTHING;

    EXCEPTION WHEN foreign_key_violation THEN
      -- Topic does not exist (stale guest data) — skip and continue.
      NULL;
    END;
  END LOOP;

  -- Migrate selected topics: only update when no topics already selected.
  -- Avoids wiping a selection the user made immediately after signup.
  IF p_selected_topics IS NOT NULL AND array_length(p_selected_topics, 1) > 0 THEN
    UPDATE connect.connected_profiles
    SET selected_topic_ids = p_selected_topics,
        updated_at         = NOW()
    WHERE user_id = p_user_id
      AND (selected_topic_ids IS NULL OR selected_topic_ids = '{}');
  END IF;

END;
$$;
