-- =============================================================================
-- Migration 038: Compass Additions (Phase 39)
--
-- Extends the compass schema to support:
--   1. Decimal politician answer values (NUMERIC(3,1) on politician_answers)
--   2. Half-step CHECK constraint on politician_answers.value
--   3. Tightened half-step CHECK constraint on compass_responses.value
--      (migration 030 added range check but not half-step enforcement)
--   4. New inform.compass_verdicts table for Read & Rank session persistence
--   5. RLS + indexes on compass_verdicts
--   6. Replaced admin_update_politician_answers RPC with full-replacement
--      version (DELETE answers not in payload + upsert present answers)
--   7. New upsert_compass_verdicts RPC for atomic batch verdict persistence
--
-- All RPCs use SECURITY DEFINER + SET search_path = '' + fully qualified
-- table references per the established v1.2 pattern.
--
-- Safe to re-run: ALTER COLUMN TYPE is lossless (INT→NUMERIC); DROP CONSTRAINT
-- IF EXISTS is conditional; CREATE TABLE IF NOT EXISTS; CREATE OR REPLACE for
-- RPCs.
-- =============================================================================


-- =============================================================================
-- Section 1: Migrate politician_answers.value from INT to NUMERIC(3,1)
-- =============================================================================

ALTER TABLE inform.politician_answers
  ALTER COLUMN value TYPE NUMERIC(3,1);


-- =============================================================================
-- Section 2: Add half-step CHECK constraint to politician_answers.value
-- =============================================================================

ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_value_half_step
  CHECK (value >= 0.5 AND value <= 5.5 AND (value * 2) = ROUND(value * 2));


-- =============================================================================
-- Section 3: Tighten CHECK constraint on compass_responses.value
--
-- Migration 030 added a range-only check (>= 0.5 AND <= 5.5) but did not
-- enforce half-step precision. Replace it with the full half-step constraint.
-- Existing integer values (1–5) all satisfy (value * 2) = ROUND(value * 2).
-- =============================================================================

ALTER TABLE inform.compass_responses
  DROP CONSTRAINT IF EXISTS compass_responses_value_check;

ALTER TABLE inform.compass_responses
  ADD CONSTRAINT compass_responses_value_half_step
  CHECK (value >= 0.5 AND value <= 5.5 AND (value * 2) = ROUND(value * 2));


-- =============================================================================
-- Section 4: Create inform.compass_verdicts table
--
-- Stores a user's judgment from a Read & Rank session.
-- supported — binary yes/no verdict on a quote
-- rank      — ordinal position among supported quotes in that session (NULL if
--             not supported)
-- session_size — total quotes ranked in this session; enables rank/session_size
--                normalization for "liked mildly vs liked a lot" display
-- Updateable: ON CONFLICT (user_id, quote_id) DO UPDATE — latest verdict wins.
-- =============================================================================

CREATE TABLE IF NOT EXISTS inform.compass_verdicts (
  user_id      UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  quote_id     UUID        NOT NULL REFERENCES essentials.quotes(id) ON DELETE CASCADE,
  supported    BOOLEAN     NOT NULL,
  rank         INTEGER,
  session_size INTEGER     NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, quote_id)
);

CREATE INDEX idx_compass_verdicts_user  ON inform.compass_verdicts(user_id);
CREATE INDEX idx_compass_verdicts_quote ON inform.compass_verdicts(quote_id);


-- =============================================================================
-- Section 5: Enable RLS on compass_verdicts with owner-read policy
-- =============================================================================

ALTER TABLE inform.compass_verdicts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "verdicts: owner read"
  ON inform.compass_verdicts
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

GRANT SELECT ON inform.compass_verdicts TO authenticated;


-- =============================================================================
-- Section 6: Replace admin_update_politician_answers RPC
--
-- Prior version (migration 025) only upserted — answers not in the payload were
-- left in place. The new version implements full replacement: DELETE any answer
-- for this politician that is NOT in the payload, then upsert the payload rows.
--
-- Uses ::numeric cast (not ::int) since politician_answers.value is now
-- NUMERIC(3,1).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.admin_update_politician_answers(
  p_politician_id uuid,
  p_answers jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_answer   jsonb;
  v_topic_ids uuid[];
BEGIN
  -- Collect all topic_ids present in the payload
  SELECT array_agg((elem->>'topic_id')::uuid)
  INTO v_topic_ids
  FROM jsonb_array_elements(p_answers) AS elem;

  -- Delete answers for this politician that are NOT in the payload.
  -- If payload is empty (v_topic_ids IS NULL), delete all answers.
  DELETE FROM inform.politician_answers
  WHERE politician_id = p_politician_id
    AND (v_topic_ids IS NULL OR topic_id != ALL(v_topic_ids));

  -- Upsert each answer present in the payload
  FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    INSERT INTO inform.politician_answers (politician_id, topic_id, value)
    VALUES (
      p_politician_id,
      (v_answer->>'topic_id')::uuid,
      (v_answer->>'value')::numeric
    )
    ON CONFLICT (politician_id, topic_id) DO UPDATE
      SET value = EXCLUDED.value;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_update_politician_answers(uuid, jsonb) TO service_role, authenticated;


-- =============================================================================
-- Section 7: Create upsert_compass_verdicts RPC
--
-- Atomic batch upsert for all verdicts from a single Read & Rank session.
-- Called once per session completion; all verdicts land or none do.
-- rank may be null (client sends JSON null) when quote was not supported.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.upsert_compass_verdicts(
  p_user_id  UUID,
  p_verdicts JSONB
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  elem jsonb;
BEGIN
  FOR elem IN SELECT * FROM jsonb_array_elements(p_verdicts)
  LOOP
    INSERT INTO inform.compass_verdicts (user_id, quote_id, supported, rank, session_size, updated_at)
    VALUES (
      p_user_id,
      (elem->>'quote_id')::uuid,
      (elem->>'supported')::boolean,
      NULLIF(elem->>'rank', 'null')::integer,
      (elem->>'session_size')::integer,
      now()
    )
    ON CONFLICT (user_id, quote_id) DO UPDATE
      SET supported    = EXCLUDED.supported,
          rank         = EXCLUDED.rank,
          session_size = EXCLUDED.session_size,
          updated_at   = now();
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_compass_verdicts(uuid, jsonb) TO service_role;
