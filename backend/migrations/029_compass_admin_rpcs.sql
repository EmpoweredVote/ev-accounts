-- =============================================================================
-- Migration 029: Compass admin RPC functions
--
-- Three SECURITY DEFINER functions for admin compass management:
--
--   1. admin_create_topic_with_stances — atomically creates a compass topic and
--      its associated stances in a single transaction. Two-pass design: full
--      validation loop runs before any INSERT, guaranteeing all-or-nothing
--      atomicity. If any stance is malformed, no topic row is committed.
--
--   2. admin_assign_topic_categories — atomically replaces all category
--      assignments for a topic. DELETE + INSERT run in the same transaction.
--      Called by PUT /api/admin/compass/topics/:id/categories.
--
--   3. admin_list_politicians — lists all politicians with answer_count and
--      is_candidate. CREATE OR REPLACE updates the version from migration 025
--      (which omitted is_candidate, added in migration 026). If no prior
--      version exists, this is a fresh install.
--
-- All three use SECURITY DEFINER to bypass RLS and SET search_path = '' to
-- prevent search_path injection. All table references are fully qualified.
--
-- Must be run against the live DB via the admin apply-migration tooling
-- (e.g., `node backend/scripts/applyMigration.js 029`).
-- =============================================================================


-- =============================================================================
-- Function 1: admin_create_topic_with_stances
--
-- Creates a compass topic and its stances atomically.
--
-- Two-pass design (atomicity guarantee):
--   Pass 1 — Full validation loop: iterates all stance elements, raises on the
--             first invalid element. NO writes happen in this pass.
--   Pass 2 — Write loop: runs only after Pass 1 completes without error.
--             INSERTs the topic row, then inserts each stance.
--
-- p_stances is a JSONB array. Each element must contain:
--   value  int   (required — must be BETWEEN 1 AND 5)
--   text   text  (required — must be non-null and non-empty after trim)
--
-- is_active is GENERATED ALWAYS AS (is_live) STORED — never included in INSERT.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.admin_create_topic_with_stances(
  p_title         text,
  p_question_text text,
  p_short_title   text    DEFAULT NULL,
  p_is_live       boolean DEFAULT false,
  p_stances       jsonb   DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  elem       jsonb;
  v_value    int;
  v_text     text;
  v_topic    inform.compass_topics%ROWTYPE;
BEGIN

  -- =========================================================================
  -- Pass 1: Full validation — no writes.
  -- If any stance element is invalid, RAISE immediately; nothing is written.
  -- =========================================================================

  FOR elem IN SELECT * FROM jsonb_array_elements(p_stances)
  LOOP

    -- value must be present
    IF (elem->>'value') IS NULL THEN
      RAISE EXCEPTION 'INVALID_STANCE_VALUE: value is required for each stance';
    END IF;

    -- value must be a valid integer
    BEGIN
      v_value := (elem->>'value')::int;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'INVALID_STANCE_VALUE: value is not an integer: %', elem->>'value';
    END;

    -- value must be in range 1..5
    IF v_value NOT BETWEEN 1 AND 5 THEN
      RAISE EXCEPTION 'INVALID_STANCE_VALUE: value % is out of range (1..5)', v_value;
    END IF;

    -- text must be present and non-empty
    v_text := elem->>'text';
    IF v_text IS NULL OR trim(v_text) = '' THEN
      RAISE EXCEPTION 'INVALID_STANCE_TEXT: text is required and must be non-empty for stance with value %', v_value;
    END IF;

  END LOOP;


  -- =========================================================================
  -- Pass 2: Writes — runs only after full validation above completes.
  -- INSERT topic first, then stances (topic row must exist for FK constraint).
  -- is_active is excluded from INSERT — it is GENERATED ALWAYS AS (is_live) STORED.
  -- =========================================================================

  INSERT INTO inform.compass_topics (
    title,
    short_title,
    question_text,
    is_live,
    went_live_at
  )
  VALUES (
    p_title,
    p_short_title,
    p_question_text,
    p_is_live,
    CASE WHEN p_is_live THEN now() ELSE NULL END
  )
  RETURNING * INTO v_topic;

  FOR elem IN SELECT * FROM jsonb_array_elements(p_stances)
  LOOP
    INSERT INTO inform.compass_stances (topic_id, value, text)
    VALUES (
      v_topic.id,
      (elem->>'value')::int,
      elem->>'text'
    );
  END LOOP;


  -- =========================================================================
  -- Return: topic object + stances array
  -- =========================================================================

  RETURN jsonb_build_object(
    'topic',   row_to_json(v_topic),
    'stances', COALESCE(
      (SELECT jsonb_agg(row_to_json(s))
         FROM inform.compass_stances s
        WHERE s.topic_id = v_topic.id),
      '[]'::jsonb
    )
  );

END;
$$;


-- =============================================================================
-- Function 2: admin_assign_topic_categories
--
-- Atomically replaces all category assignments for a topic.
-- DELETE removes existing assignments; INSERT adds the new set.
-- Both operations occur within the same transaction — atomic replace-all.
--
-- p_category_ids is a JSONB array of UUID strings.
-- Raises NOT_FOUND if the topic does not exist.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.admin_assign_topic_categories(
  p_topic_id     uuid,
  p_category_ids jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN

  -- Verify topic exists before modifying category assignments
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE id = p_topic_id
  ) THEN
    RAISE EXCEPTION 'NOT_FOUND: topic % does not exist', p_topic_id;
  END IF;

  -- Atomic replace-all: delete existing assignments, insert new set
  DELETE FROM inform.compass_topic_categories
   WHERE topic_id = p_topic_id;

  INSERT INTO inform.compass_topic_categories (topic_id, category_id)
  SELECT p_topic_id, (cat_id)::uuid
    FROM jsonb_array_elements_text(p_category_ids) AS cat_id;

END;
$$;


-- =============================================================================
-- Function 3: admin_list_politicians
--
-- Lists all politicians with their answer counts. CREATE OR REPLACE updates
-- any prior version (migration 025 did not include is_candidate; migration 026
-- added the column — this version surfaces it in the result set).
--
-- Returns one row per politician ordered by last_name, first_name.
-- answer_count is a correlated subquery counting rows in politician_answers.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.admin_list_politicians()
RETURNS TABLE(
  id               uuid,
  first_name       text,
  last_name        text,
  preferred_name   text,
  full_name        text,
  office_title     text,
  photo_origin_url text,
  is_active        boolean,
  is_candidate     boolean,
  created_at       timestamptz,
  answer_count     bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.preferred_name,
    p.full_name,
    p.office_title,
    p.photo_origin_url,
    p.is_active,
    p.is_candidate,
    p.created_at,
    (SELECT COUNT(*) FROM inform.politician_answers pa WHERE pa.politician_id = p.id) AS answer_count
  FROM inform.politicians p
  ORDER BY p.last_name, p.first_name;
$$;


-- =============================================================================
-- Grants
-- =============================================================================

GRANT EXECUTE ON FUNCTION public.admin_create_topic_with_stances(text, text, text, boolean, jsonb) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_assign_topic_categories(uuid, jsonb) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_politicians() TO service_role, authenticated;
