-- Migration 149: Fix upsert_compass_answer to un-delete soft-deleted answers
--
-- Bug: when a user answers a topic that was previously soft-deleted,
-- the ON CONFLICT DO UPDATE clause updated value/updated_at but did NOT
-- clear deleted_at. The answer remained invisible to GET /compass/answers
-- (which filters WHERE deleted_at IS NULL).
--
-- Fix: add deleted_at = NULL to the ON CONFLICT DO UPDATE clause so that
-- re-answering a deleted topic always restores it to active.

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

  -- UPSERT the response; deleted_at = NULL ensures a re-answered deleted topic is restored
  INSERT INTO inform.compass_responses (user_id, topic_id, value, write_in_text, inverted, updated_at)
  VALUES (p_user_id, p_topic_id, p_value, p_write_in_text, p_inverted, now())
  ON CONFLICT (user_id, topic_id) DO UPDATE
    SET value         = EXCLUDED.value,
        write_in_text = EXCLUDED.write_in_text,
        inverted      = EXCLUDED.inverted,
        updated_at    = now(),
        deleted_at    = NULL
  RETURNING * INTO v_result;

  -- Append to change_history (always — even same-value recalibration)
  INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
  VALUES (p_user_id, p_topic_id, v_old_value, p_value);

  RETURN row_to_json(v_result)::jsonb;
END;
$$;
