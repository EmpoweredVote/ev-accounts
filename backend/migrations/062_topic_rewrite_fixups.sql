BEGIN;

-- =============================================================================
-- Migration 062: Topic Rewrite Workflow fixups
-- =============================================================================
-- Migration 061 was built against out-of-date assumptions:
--   1. It FKs topic_rewrite_stance_proposals.politician_id to inform.politicians,
--      but the real politicians live in essentials.politicians (which is what
--      politician_answers.politician_id actually references).
--   2. It typed old_value as INT, but politician_answers.value is NUMERIC with
--      a half-step CHECK constraint. Round-tripping loses half-unit precision.
--   3. admin_publish_topic_rewrite rounded proposed_value to int when copying
--      into politician_answers; it should preserve the numeric value.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: Repoint politician_id FK to essentials.politicians
-- ---------------------------------------------------------------------------

ALTER TABLE inform.topic_rewrite_stance_proposals
  DROP CONSTRAINT IF EXISTS topic_rewrite_stance_proposals_politician_id_fkey;

ALTER TABLE inform.topic_rewrite_stance_proposals
  ADD CONSTRAINT topic_rewrite_stance_proposals_politician_id_fkey
  FOREIGN KEY (politician_id) REFERENCES essentials.politicians(id) ON DELETE CASCADE;

-- ---------------------------------------------------------------------------
-- Section 2: old_value and proposed_value become NUMERIC with half-step check
-- ---------------------------------------------------------------------------
-- Drop the existing INT CHECK on old_value and the NUMERIC CHECK on
-- proposed_value, widen old_value to NUMERIC, and re-add half-step checks
-- consistent with inform.politician_answers.

ALTER TABLE inform.topic_rewrite_stance_proposals
  DROP CONSTRAINT IF EXISTS topic_rewrite_stance_proposals_old_value_check;
ALTER TABLE inform.topic_rewrite_stance_proposals
  DROP CONSTRAINT IF EXISTS topic_rewrite_stance_proposals_proposed_value_check;

ALTER TABLE inform.topic_rewrite_stance_proposals
  ALTER COLUMN old_value TYPE NUMERIC USING old_value::numeric;

ALTER TABLE inform.topic_rewrite_stance_proposals
  ADD CONSTRAINT topic_rewrite_stance_proposals_old_value_half_step
  CHECK (old_value >= 0.5 AND old_value <= 5.5 AND (old_value * 2) = round(old_value * 2));

ALTER TABLE inform.topic_rewrite_stance_proposals
  ADD CONSTRAINT topic_rewrite_stance_proposals_proposed_value_half_step
  CHECK (proposed_value IS NULL OR (
    proposed_value >= 0.5 AND proposed_value <= 5.5
    AND (proposed_value * 2) = round(proposed_value * 2)
  ));

-- ---------------------------------------------------------------------------
-- Section 3: admin_publish_topic_rewrite — preserve numeric proposed_value
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_publish_topic_rewrite(
  p_rewrite_id UUID,
  p_actor_id   UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_rewrite           inform.topic_rewrites%ROWTYPE;
  v_approved_count    INT;
  v_rejected_count    INT;
BEGIN
  SELECT * INTO v_rewrite FROM inform.topic_rewrites WHERE id = p_rewrite_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: rewrite % does not exist', p_rewrite_id;
  END IF;

  IF v_rewrite.state <> 'publish_ready' THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % must be in publish_ready (is %)',
      p_rewrite_id, v_rewrite.state;
  END IF;

  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT p.politician_id, v_rewrite.new_topic_id, p.proposed_value
  FROM inform.topic_rewrite_stance_proposals p
  WHERE p.rewrite_id = p_rewrite_id AND p.status = 'approved'
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET value = EXCLUDED.value;

  GET DIAGNOSTICS v_approved_count = ROW_COUNT;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT p.politician_id, v_rewrite.new_topic_id,
         COALESCE(p.proposed_reasoning, ''),
         COALESCE(p.proposed_sources, '{}')
  FROM inform.topic_rewrite_stance_proposals p
  WHERE p.rewrite_id = p_rewrite_id AND p.status = 'approved'
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning,
        sources   = EXCLUDED.sources;

  SELECT count(*) INTO v_rejected_count
  FROM inform.topic_rewrite_stance_proposals
  WHERE rewrite_id = p_rewrite_id AND status = 'rejected';

  UPDATE inform.compass_topics
  SET is_live = false
  WHERE id = v_rewrite.old_topic_id;

  UPDATE inform.compass_topics
  SET is_live = true,
      went_live_at = now()
  WHERE id = v_rewrite.new_topic_id;

  UPDATE inform.topic_rewrites
  SET state = 'published',
      published_by = p_actor_id,
      published_at = now()
  WHERE id = p_rewrite_id;

  RETURN jsonb_build_object(
    'approved_copied',  v_approved_count,
    'rejected_skipped', v_rejected_count
  );
END;
$$;

-- politician_context.reasoning is NOT NULL in migration 026; keep COALESCE.

COMMIT;
