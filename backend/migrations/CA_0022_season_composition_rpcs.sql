BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-28. Verified: all 7 functions live and
-- SECURITY DEFINER, EXECUTE granted to service_role only (anon refused),
-- post-verify gate passed, 1 season / 44 season_questions untouched.
-- Dry-run first inside BEGIN…ROLLBACK, then a rolled-back behavioral probe,
-- 16/16: carry pins compose-time revisions (Bail pinned rev 3, not S1's rev 1);
-- DRAFT_EXISTS / NOT_IN_SEASON / ALREADY_IN_SEASON / NAME_REQUIRED /
-- SCAFFOLD_INDEXES_PRESENT all raised; after simulating the scaffold drop,
-- open_season closed S1, opened the draft, renumbered 1..44 contiguously,
-- and NOT_DRAFT then protected pins and deletion.

-- =============================================================================
-- CA_0022: Season composition RPCs — author a draft season, then open it
-- =============================================================================
-- ADR 0005 deferred "how a season is authored"; this is that, for the
-- single-national-set case (per-jurisdiction stays out of scope, §3.1).
--
-- THE PIN IS SET AT COMPOSE TIME (decision 2026-08-28, Chris Andrews): every
-- write here pins the topic's CURRENT published revision at the moment of the
-- call. A revision published later does not move a draft's pin; the admin sees
-- a "newer revision available" flag and may re-pin explicitly while the season
-- is still draft. season_questions_pin_immutable (CC_0002) already freezes
-- pins once the season leaves draft, so the schema agrees.
--
-- admin_open_season REFUSES while the CC_0002 scaffolding indexes exist:
-- dropping them is rollout step 3 (ADR 0005 §1.6) and irreversible — an
-- explicit operational decision that must not happen as a side effect.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: admin_create_draft_season
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_create_draft_season(
  p_actor_id        UUID,
  p_name            TEXT,
  p_public_note     TEXT,
  p_carry_from_open BOOLEAN DEFAULT TRUE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_open_id  UUID;
  v_new_id   UUID;
  v_number   INTEGER;
  v_missing  TEXT;
  v_count    INTEGER := 0;
BEGIN
  IF p_name IS NULL OR btrim(p_name) = '' THEN
    RAISE EXCEPTION 'NAME_REQUIRED: a season needs a name';
  END IF;
  IF p_public_note IS NULL OR btrim(p_public_note) = '' THEN
    RAISE EXCEPTION 'NOTE_REQUIRED: seasons are a transparency surface (ADR 0005); write the public note first';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.seasons WHERE status = 'draft') THEN
    RAISE EXCEPTION 'DRAFT_EXISTS: a draft season already exists — edit it or delete it first';
  END IF;

  SELECT id INTO v_open_id FROM inform.seasons WHERE status = 'open';
  IF p_carry_from_open AND v_open_id IS NULL THEN
    RAISE EXCEPTION 'NO_OPEN_SEASON: nothing to carry from — no season is open';
  END IF;

  SELECT COALESCE(max(number), 0) + 1 INTO v_number FROM inform.seasons;

  INSERT INTO inform.seasons (number, name, status, public_note)
  VALUES (v_number, btrim(p_name), 'draft', p_public_note)
  RETURNING id INTO v_new_id;

  IF p_carry_from_open THEN
    -- Compose-time pin: every carried topic needs a current published revision.
    SELECT string_agg(t.topic_key, ', ') INTO v_missing
      FROM inform.season_questions sq
      JOIN inform.compass_topics t ON t.id = sq.topic_id
     WHERE sq.season_id = v_open_id
       AND NOT EXISTS (
         SELECT 1 FROM inform.compass_topic_revisions r
          WHERE r.topic_id = sq.topic_id AND r.is_current AND r.status = 'published');
    IF v_missing IS NOT NULL THEN
      RAISE EXCEPTION 'NO_CURRENT_REVISION: cannot pin at compose time — no current published revision for: %', v_missing;
    END IF;

    INSERT INTO inform.season_questions
      (season_id, topic_id, topic_revision_id, question_number, display_order)
    SELECT v_new_id, sq.topic_id, r.id, sq.question_number, sq.display_order
      FROM inform.season_questions sq
      JOIN inform.compass_topic_revisions r
        ON r.topic_id = sq.topic_id AND r.is_current AND r.status = 'published'
     WHERE sq.season_id = v_open_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
  END IF;

  RETURN jsonb_build_object(
    'season_id', v_new_id, 'number', v_number, 'question_count', v_count);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 2: admin_update_draft_season (NULL argument = keep current value)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_update_draft_season(
  p_season_id   UUID,
  p_actor_id    UUID,
  p_name        TEXT,
  p_public_note TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, only drafts are editable', p_season_id, v_status;
  END IF;
  IF p_name IS NOT NULL AND btrim(p_name) = '' THEN
    RAISE EXCEPTION 'NAME_REQUIRED: a season needs a name';
  END IF;
  IF p_public_note IS NOT NULL AND btrim(p_public_note) = '' THEN
    RAISE EXCEPTION 'NOTE_REQUIRED: the public note cannot be blanked';
  END IF;

  UPDATE inform.seasons
     SET name        = COALESCE(btrim(p_name), name),
         public_note = COALESCE(p_public_note, public_note),
         updated_at  = now()
   WHERE id = p_season_id;

  RETURN jsonb_build_object('season_id', p_season_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 3: admin_delete_draft_season (cascade removes its question rows)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_delete_draft_season(
  p_season_id UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
  v_count  INTEGER;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, only drafts may be deleted', p_season_id, v_status;
  END IF;

  SELECT count(*)::int INTO v_count FROM inform.season_questions WHERE season_id = p_season_id;
  DELETE FROM inform.seasons WHERE id = p_season_id;

  RETURN jsonb_build_object('deleted_season_id', p_season_id, 'question_count', v_count);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 4: admin_season_add_topic — pin the CURRENT revision at call time
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_season_add_topic(
  p_season_id UUID,
  p_topic_id  UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
  v_rev    UUID;
  v_qn     INTEGER;
  v_do     INTEGER;
BEGIN
  -- FOR UPDATE serialises concurrent adds so max()+1 numbering cannot collide.
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, its question set is frozen', p_season_id, v_status;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id = p_topic_id) THEN
    RAISE EXCEPTION 'NO_SUCH_TOPIC: topic % does not exist', p_topic_id;
  END IF;
  IF EXISTS (SELECT 1 FROM inform.season_questions
              WHERE season_id = p_season_id AND topic_id = p_topic_id) THEN
    RAISE EXCEPTION 'ALREADY_IN_SEASON: topic % is already in this season', p_topic_id;
  END IF;

  SELECT r.id INTO v_rev
    FROM inform.compass_topic_revisions r
   WHERE r.topic_id = p_topic_id AND r.is_current AND r.status = 'published';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_CURRENT_REVISION: topic % has no current published revision to pin', p_topic_id;
  END IF;

  SELECT COALESCE(max(question_number), 0) + 1, COALESCE(max(display_order), 0) + 1
    INTO v_qn, v_do
    FROM inform.season_questions WHERE season_id = p_season_id;

  INSERT INTO inform.season_questions
    (season_id, topic_id, topic_revision_id, question_number, display_order)
  VALUES (p_season_id, p_topic_id, v_rev, v_qn, v_do);

  RETURN jsonb_build_object(
    'topic_id', p_topic_id, 'topic_revision_id', v_rev, 'question_number', v_qn);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 5: admin_season_remove_topic
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_season_remove_topic(
  p_season_id UUID,
  p_topic_id  UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, its question set is frozen', p_season_id, v_status;
  END IF;

  DELETE FROM inform.season_questions
   WHERE season_id = p_season_id AND topic_id = p_topic_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_IN_SEASON: topic % is not in this season', p_topic_id;
  END IF;

  RETURN jsonb_build_object('removed_topic_id', p_topic_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 6: admin_season_repin_topic — move a draft pin to the newest revision
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_season_repin_topic(
  p_season_id UUID,
  p_topic_id  UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status inform.season_status;
  v_old    UUID;
  v_new    UUID;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    -- The season_questions_pin_immutable trigger would refuse anyway; refuse
    -- here first so the caller gets the same NOT_DRAFT code as everywhere else.
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, its pins are frozen', p_season_id, v_status;
  END IF;

  SELECT topic_revision_id INTO v_old
    FROM inform.season_questions
   WHERE season_id = p_season_id AND topic_id = p_topic_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_IN_SEASON: topic % is not in this season', p_topic_id;
  END IF;

  SELECT r.id INTO v_new
    FROM inform.compass_topic_revisions r
   WHERE r.topic_id = p_topic_id AND r.is_current AND r.status = 'published';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_CURRENT_REVISION: topic % has no current published revision to pin', p_topic_id;
  END IF;

  IF v_new = v_old THEN
    RETURN jsonb_build_object(
      'repinned', false, 'from_revision_id', v_old, 'to_revision_id', v_new);
  END IF;

  UPDATE inform.season_questions
     SET topic_revision_id = v_new
   WHERE season_id = p_season_id AND topic_id = p_topic_id;

  RETURN jsonb_build_object(
    'repinned', true, 'from_revision_id', v_old, 'to_revision_id', v_new);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 7: admin_open_season — the changeover, one transaction
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION inform.admin_open_season(
  p_season_id UUID,
  p_actor_id  UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status  inform.season_status;
  v_count   INTEGER;
  v_closed  UUID;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, only a draft can be opened', p_season_id, v_status;
  END IF;

  SELECT count(*)::int INTO v_count
    FROM inform.season_questions WHERE season_id = p_season_id;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'EMPTY_SEASON: season % has no questions — an empty open season blanks every compass surface', p_season_id;
  END IF;

  -- Rollout interlock (ADR 0005 §1.6 step 3). While the CC_0002 scaffold
  -- indexes exist, the database cannot hold answers in two seasons; opening a
  -- second season would make every write fail at insert time instead. Dropping
  -- the indexes is irreversible and belongs to an explicit ops migration, so
  -- this function refuses rather than "helpfully" dropping them.
  IF EXISTS (
    SELECT 1 FROM pg_indexes
     WHERE schemaname = 'inform'
       AND indexname IN ('politician_answers_legacy_pair_scaffold',
                         'politician_context_legacy_pair_scaffold')
  ) THEN
    RAISE EXCEPTION 'SCAFFOLD_INDEXES_PRESENT: the CC_0002 scaffolding indexes still limit answers to one season. Dropping them is rollout step 3 (ADR 0005 §1.6) and an explicit operational migration — apply that first, then open the season';
  END IF;

  -- Renumber 1..N by display_order. Two passes: the UNIQUE constraints are not
  -- deferrable, so shift out of range first, then land on the final numbers.
  UPDATE inform.season_questions
     SET question_number = -question_number, display_order = -display_order
   WHERE season_id = p_season_id;
  WITH ordered AS (
    SELECT topic_id, row_number() OVER (ORDER BY display_order DESC) AS rn
      FROM inform.season_questions
     WHERE season_id = p_season_id
  )
  UPDATE inform.season_questions sq
     SET question_number = o.rn, display_order = o.rn
    FROM ordered o
   WHERE sq.season_id = p_season_id AND sq.topic_id = o.topic_id;

  -- Close the incumbent, then open the draft. seasons_one_open is checked per
  -- statement, so this order never trips it.
  UPDATE inform.seasons
     SET status = 'closed', closed_at = now(), updated_at = now()
   WHERE status = 'open'
  RETURNING id INTO v_closed;

  UPDATE inform.seasons
     SET status = 'open', opened_at = now(), updated_at = now()
   WHERE id = p_season_id;

  RETURN jsonb_build_object(
    'opened_season_id', p_season_id,
    'closed_season_id', v_closed,
    'question_count', v_count);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 8: Grants — service_role ONLY (authorisation is the API's job)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION inform.admin_create_draft_season(UUID, TEXT, TEXT, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_update_draft_season(UUID, UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_delete_draft_season(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_season_add_topic(UUID, UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_season_remove_topic(UUID, UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_season_repin_topic(UUID, UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_open_season(UUID, UUID) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION inform.admin_create_draft_season(UUID, TEXT, TEXT, BOOLEAN) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_update_draft_season(UUID, UUID, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_delete_draft_season(UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_season_add_topic(UUID, UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_season_remove_topic(UUID, UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_season_repin_topic(UUID, UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_open_season(UUID, UUID) TO service_role;

-- ---------------------------------------------------------------------------
-- Section 9: Post-verify gate
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_missing TEXT[] := '{}';
  v_fn TEXT;
BEGIN
  FOREACH v_fn IN ARRAY ARRAY[
    'admin_create_draft_season', 'admin_update_draft_season',
    'admin_delete_draft_season', 'admin_season_add_topic',
    'admin_season_remove_topic', 'admin_season_repin_topic',
    'admin_open_season'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'inform' AND p.proname = v_fn AND p.prosecdef
    ) THEN
      v_missing := v_missing || v_fn;
    END IF;
  END LOOP;

  IF array_length(v_missing, 1) > 0 THEN
    RAISE EXCEPTION 'CA_0022 INCOMPLETE: missing security-definer functions: %',
      array_to_string(v_missing, ', ');
  END IF;

  -- This migration must not have touched data.
  IF (SELECT count(*) FROM inform.seasons) <> 1 THEN
    RAISE EXCEPTION 'season count changed: expected 1, got %',
      (SELECT count(*) FROM inform.seasons);
  END IF;
  IF (SELECT count(*) FROM inform.season_questions) <> 44 THEN
    RAISE EXCEPTION 'season_questions count changed: expected 44, got %',
      (SELECT count(*) FROM inform.season_questions);
  END IF;

  RAISE NOTICE 'CA_0022 OK — 7 season RPCs, data untouched';
END $$;

COMMIT;
