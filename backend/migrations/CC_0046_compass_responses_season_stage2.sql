BEGIN;

-- =============================================================================
-- CC_0046: user compass answers, stage 2 — history turns on here
-- =============================================================================
-- Created 2026-09-02 with Chris Cantrell. Completes what CC_0045 staged.
--
-- CC_0045 added season_id, moved the primary key to
-- (user_id, topic_id, season_id), and held everything still behind a scaffold
-- UNIQUE (user_id, topic_id) so no read or RPC had to change. This removes the
-- scaffold and makes the rest true:
--
--   2. season-scope reset_compass_answers        <- here
--   3. repoint the four ON CONFLICT clauses      <- here
--   4. drop the scaffold                         <- here
--   5. attach the closed-season trigger          <- here
--
-- (Step 1, the ~12 read sites, ships in the same PR as backend code. The view
-- below is what the PostgREST reads use, since .select() cannot express
-- DISTINCT ON.)
--
-- 🔴 THE ORDERING RULE THAT MAKES THIS SAFE: steps 3 and 4 MUST be in one
-- transaction. The four RPCs say ON CONFLICT (user_id, topic_id); the moment the
-- scaffold is dropped that clause has no matching unique index and EVERY user
-- answer write raises. Likewise 4 and 5 belong together — with the scaffold up
-- and Season 2 open, a returning user's write would ON CONFLICT onto their
-- Season 1 row, which is closed, and the trigger would abort it.
--
-- -----------------------------------------------------------------------------
-- THE COLLAPSE, AND WHY deleted_at IS FILTERED *AFTER* IT
-- -----------------------------------------------------------------------------
-- Reads take the newest season a user answered each topic in, exactly as the
-- politician side does. The order matters more than it looks:
--
--   collapse first, THEN drop soft-deleted rows.
--
-- Filtering deleted_at inside the collapse would drop a Season 2 tombstone and
-- let the Season 1 answer win — silently undoing the person's deletion. Doing it
-- after means a tombstone in the newer season correctly suppresses the older
-- answer. This is how "I have no position on this any more" becomes expressible
-- per season for users — something the politician tables still cannot do,
-- because politician_answers has no deleted_at at all.
--
-- The view therefore does NOT filter deleted_at; it exposes the column so each
-- caller keeps its own existing predicate, applied after the collapse.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- The current-answer view, for callers that cannot write DISTINCT ON.
-- -----------------------------------------------------------------------------
-- 🔴 security_invoker = on IS NOT OPTIONAL. inform.compass_responses has RLS
-- with a single owner-only policy ("compass_responses: owner select",
-- auth.uid() = user_id). A view without security_invoker runs as its owner, so
-- it would hand every authenticated caller every user's answers through
-- PostgREST. With it on, the base table's RLS still applies to the caller.
-- Postgres 17.6 here, so the option is available.

CREATE OR REPLACE VIEW inform.compass_responses_current
WITH (security_invoker = on) AS
SELECT DISTINCT ON (cr.user_id, cr.topic_id) cr.*
  FROM inform.compass_responses cr
  JOIN inform.seasons s ON s.id = cr.season_id
 ORDER BY cr.user_id, cr.topic_id, s.number DESC;

COMMENT ON VIEW inform.compass_responses_current IS
  'CC_0046. One row per (user, topic): the newest season that user answered it '
  'in. Does NOT filter deleted_at — callers apply that themselves, AFTER the '
  'collapse, so a tombstone in a newer season correctly suppresses an older '
  'answer. security_invoker=on so the base table RLS still applies.';

GRANT SELECT ON inform.compass_responses_current TO authenticated;
GRANT SELECT ON inform.compass_responses_current TO service_role;


-- -----------------------------------------------------------------------------
-- Step 3: the four ON CONFLICT clauses, repointed to the real primary key.
-- -----------------------------------------------------------------------------
-- Each function is otherwise unchanged. season_id is still supplied by the
-- CC_0045 BEFORE INSERT trigger, which runs before conflict detection, so the
-- three-column arbiter resolves correctly without any function passing a season.

CREATE OR REPLACE FUNCTION public.upsert_compass_answer(
  p_user_id uuid, p_topic_id uuid, p_value numeric,
  p_write_in_text text DEFAULT NULL::text, p_inverted boolean DEFAULT false)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE
  v_old_value NUMERIC;
  v_result    inform.compass_responses;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE id = p_topic_id AND is_live = true
  ) THEN
    RAISE EXCEPTION 'TOPIC_NOT_FOUND';
  END IF;

  -- The value being replaced is the one the user can currently see, which after
  -- CC_0045 is the newest season's — not an arbitrary row. Without the collapse
  -- this picked whichever season the planner happened to return, so the change
  -- history could record a diff against a stale season.
  SELECT value INTO v_old_value
  FROM inform.compass_responses_current
  WHERE user_id = p_user_id AND topic_id = p_topic_id AND deleted_at IS NULL;

  INSERT INTO inform.compass_responses (user_id, topic_id, value, write_in_text, inverted, updated_at)
  VALUES (p_user_id, p_topic_id, p_value, p_write_in_text, p_inverted, now())
  ON CONFLICT (user_id, topic_id, season_id) DO UPDATE
    SET value         = EXCLUDED.value,
        write_in_text = EXCLUDED.write_in_text,
        inverted      = EXCLUDED.inverted,
        updated_at    = now(),
        deleted_at    = NULL
  RETURNING * INTO v_result;

  INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
  VALUES (p_user_id, p_topic_id, v_old_value, p_value);

  RETURN row_to_json(v_result)::jsonb;
END;
$function$;

CREATE OR REPLACE FUNCTION public.import_compass_calibrations(
  p_user_id uuid, p_calibrations jsonb, p_set_onboarding_complete boolean DEFAULT false)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE
  elem           JSONB;
  v_topic_id     UUID;
  v_value        INT;
  v_topic_exists BOOLEAN;
BEGIN
  -- Pass 1: full validation, no writes.
  FOR elem IN SELECT * FROM jsonb_array_elements(p_calibrations)
  LOOP
    BEGIN
      v_topic_id := (elem->>'topic_id')::uuid;
    EXCEPTION WHEN invalid_text_representation OR not_null_violation THEN
      RAISE EXCEPTION 'INVALID_CALIBRATION: topic_id is not a valid UUID: %', elem->>'topic_id';
    END;

    IF v_topic_id IS NULL THEN
      RAISE EXCEPTION 'INVALID_CALIBRATION: topic_id is required';
    END IF;

    SELECT EXISTS(SELECT 1 FROM inform.compass_topics WHERE id = v_topic_id)
      INTO v_topic_exists;
    IF NOT v_topic_exists THEN
      RAISE EXCEPTION 'INVALID_CALIBRATION: topic_id % not found in compass_topics', v_topic_id;
    END IF;

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

  -- Pass 2: upsert.
  FOR elem IN SELECT * FROM jsonb_array_elements(p_calibrations)
  LOOP
    INSERT INTO inform.compass_responses (
      user_id, topic_id, value, write_in_text, inverted, updated_at, deleted_at
    )
    VALUES (
      p_user_id,
      (elem->>'topic_id')::uuid,
      (elem->>'value')::int,
      elem->>'write_in_text',
      COALESCE((elem->>'inverted')::boolean, false),
      now(),
      NULL
    )
    ON CONFLICT (user_id, topic_id, season_id) DO UPDATE
      SET value         = EXCLUDED.value,
          write_in_text = EXCLUDED.write_in_text,
          inverted      = EXCLUDED.inverted,
          updated_at    = now(),
          deleted_at    = NULL;
  END LOOP;

  IF p_set_onboarding_complete THEN
    UPDATE connect.connected_profiles
      SET completed_onboarding = true, updated_at = now()
      WHERE user_id = p_user_id AND completed_onboarding = false;
  END IF;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.migrate_guest_compass_state(
  p_user_id uuid, p_answers jsonb, p_selected_topics uuid[] DEFAULT NULL::uuid[])
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE
  v_answer   JSONB;
  v_topic_id UUID;
  v_value    NUMERIC;
  v_write_in TEXT;
BEGIN
  FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    BEGIN
      v_topic_id := (v_answer->>'topic_id')::UUID;
      v_value    := (v_answer->>'value')::NUMERIC;
      v_write_in := v_answer->>'write_in_text';
      INSERT INTO inform.compass_responses
        (user_id, topic_id, value, write_in_text, visibility, inverted, updated_at)
      VALUES
        (p_user_id, v_topic_id, v_value, v_write_in, 'private', false, NOW())
      ON CONFLICT (user_id, topic_id, season_id) DO NOTHING;
    EXCEPTION WHEN foreign_key_violation THEN
      NULL;
    END;
  END LOOP;

  IF p_selected_topics IS NOT NULL AND array_length(p_selected_topics, 1) > 0 THEN
    UPDATE connect.connected_profiles
    SET selected_topic_ids = p_selected_topics, updated_at = NOW()
    WHERE user_id = p_user_id
      AND (selected_topic_ids IS NULL OR selected_topic_ids = '{}');
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.promote_compass_import_draft(p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_draft         jsonb;
  v_cal           jsonb;
  v_stance_value  int;
  v_rows_inserted int;
BEGIN
  SELECT compass_import_draft INTO v_draft
  FROM connect.verification_sessions
  WHERE user_id = p_user_id;

  IF v_draft IS NULL OR jsonb_array_length(v_draft) = 0 THEN
    RETURN;
  END IF;

  BEGIN
    FOR v_cal IN SELECT * FROM jsonb_array_elements(v_draft)
    LOOP
      SELECT value INTO v_stance_value
      FROM inform.compass_stances
      WHERE id = (v_cal->>'stance_id')::uuid
        AND topic_id = (v_cal->>'topic_id')::uuid;

      IF NOT FOUND THEN
        CONTINUE;
      END IF;

      INSERT INTO inform.compass_responses (user_id, topic_id, value, inverted)
      VALUES (
        p_user_id,
        (v_cal->>'topic_id')::uuid,
        v_stance_value,
        COALESCE((v_cal->>'inverted')::boolean, false)
      )
      ON CONFLICT (user_id, topic_id, season_id) DO NOTHING;

      GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

      IF v_rows_inserted > 0 THEN
        INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
        VALUES (p_user_id, (v_cal->>'topic_id')::uuid, NULL, v_stance_value);
      END IF;
    END LOOP;

    UPDATE connect.verification_sessions
    SET compass_import_draft = NULL, updated_at = now()
    WHERE user_id = p_user_id;

  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '[promote_compass_import_draft] error for user %: %', p_user_id, SQLERRM;
  END;
END;
$function$;


-- -----------------------------------------------------------------------------
-- Step 2: reset_compass_answers, season-scoped — and it TOMBSTONES.
-- -----------------------------------------------------------------------------
-- 🔴 THE OLD BODY WOULD BREAK IN TWO WAYS ONCE SEASON 2 OPENS. It ran
--
--     UPDATE inform.compass_responses SET deleted_at = now() WHERE user_id = ...
--
-- with no season predicate. That would (a) soft-delete the person's answers in
-- EVERY season, erasing the history this whole migration exists to create, and
-- (b) once step 5 attaches the closed-season trigger, simply raise — because
-- most of those rows live in a closed season. Reset Compass would stop working.
--
-- Scoping it to the open season alone is not enough either: a user whose only
-- row is in Season 1 would get a silent no-op, and the collapse would keep
-- showing that Season 1 answer. So reset writes a TOMBSTONE in the open season —
-- a row with deleted_at set — which the collapse picks as newest and the
-- caller's deleted_at filter then removes. The Season 1 row is never touched.
--
-- This is only possible because compass_responses HAS deleted_at.
-- politician_answers does not, which is exactly why blanking a politician
-- per-season is still an open problem.

CREATE OR REPLACE FUNCTION public.reset_compass_answers(
  p_user_id uuid, p_full_reset boolean DEFAULT false)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE
  v_open uuid;
BEGIN
  SELECT id INTO v_open FROM inform.seasons WHERE status = 'open';
  IF v_open IS NULL THEN
    RAISE EXCEPTION 'NO_OPEN_SEASON: cannot reset a compass while no season is open';
  END IF;

  -- Tombstone every answer the user can currently see, in the OPEN season.
  -- value is carried over only because the column is NOT NULL; the row is
  -- soft-deleted, so it is never read as a position.
  INSERT INTO inform.compass_responses
    (user_id, topic_id, season_id, value, write_in_text, visibility, inverted,
     deleted_at, updated_at)
  SELECT c.user_id, c.topic_id, v_open, c.value, c.write_in_text, c.visibility,
         c.inverted, now(), now()
    FROM inform.compass_responses_current c
   WHERE c.user_id = p_user_id
     AND c.deleted_at IS NULL
  ON CONFLICT (user_id, topic_id, season_id) DO UPDATE
    SET deleted_at = now(),
        updated_at = now();

  UPDATE inform.inform_profiles
    SET selected_topic_ids = '[]'::jsonb
    WHERE user_id = p_user_id;

  -- Transitional: the legacy column is no longer read, but is still written so a
  -- rollback to the previous release does not resurrect a stale compass.
  UPDATE connect.connected_profiles
    SET selected_topic_ids = '[]'::jsonb, updated_at = now()
    WHERE user_id = p_user_id;

  IF p_full_reset THEN
    UPDATE connect.connected_profiles
      SET completed_onboarding = false, updated_at = now()
      WHERE user_id = p_user_id;
  END IF;

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$function$;


-- -----------------------------------------------------------------------------
-- Steps 4 and 5: drop the scaffold, arm the trigger. Together, in this order.
-- -----------------------------------------------------------------------------

DROP INDEX IF EXISTS inform.compass_responses_legacy_pair_scaffold;

DROP TRIGGER IF EXISTS compass_responses_closed_season_immutable ON inform.compass_responses;
CREATE TRIGGER compass_responses_closed_season_immutable
  BEFORE INSERT OR UPDATE OR DELETE ON inform.compass_responses
  FOR EACH ROW EXECUTE FUNCTION inform.closed_season_is_immutable();


-- -----------------------------------------------------------------------------
-- Verification.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_open      uuid;
  v_draft     uuid;
  v_user      uuid;
  v_topic     uuid;
  v_rows      int;
  v_seen      numeric;
  v_scaffold  int;
BEGIN
  SELECT id INTO v_open  FROM inform.seasons WHERE status = 'open';
  SELECT id INTO v_draft FROM inform.seasons WHERE status = 'draft';

  -- (a) The scaffold is gone and the trigger is on.
  SELECT count(*) INTO v_scaffold FROM pg_indexes
   WHERE schemaname = 'inform' AND indexname = 'compass_responses_legacy_pair_scaffold';
  IF v_scaffold <> 0 THEN
    RAISE EXCEPTION 'CC_0046: the scaffold is still present';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
     WHERE NOT t.tgisinternal AND c.relname = 'compass_responses'
       AND t.tgname = 'compass_responses_closed_season_immutable'
  ) THEN
    RAISE EXCEPTION 'CC_0046: the closed-season trigger is not attached';
  END IF;

  -- (b) The view collapses, and it is security_invoker.
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'inform' AND c.relname = 'compass_responses_current'
       AND 'security_invoker=on' = ANY (c.reloptions)
  ) THEN
    RAISE EXCEPTION
      'CC_0046: compass_responses_current is not security_invoker — it would leak every user''s answers';
  END IF;

  -- (c) A second season row is now ACCEPTED (the scaffold no longer blocks it),
  --     the collapse returns exactly one row, and it is the newer season's.
  --     Proved against a real row inside a rolled-back subtransaction.
  SELECT user_id, topic_id INTO v_user, v_topic
    FROM inform.compass_responses WHERE season_id = v_open LIMIT 1;

  IF v_user IS NOT NULL AND v_draft IS NOT NULL THEN
    BEGIN
      -- The draft season has to look open for the write to be legal.
      UPDATE inform.seasons SET status = 'closed', closed_at = now() WHERE id = v_open;
      UPDATE inform.seasons SET status = 'open', opened_at = now() WHERE id = v_draft;

      INSERT INTO inform.compass_responses
        (user_id, topic_id, value, visibility, inverted)
      VALUES (v_user, v_topic, 5, 'private', false);

      SELECT count(*) INTO v_rows
        FROM inform.compass_responses
       WHERE user_id = v_user AND topic_id = v_topic;
      IF v_rows <> 2 THEN
        RAISE EXCEPTION 'CC_0046: expected 2 season rows after the scaffold drop, found %', v_rows;
      END IF;

      SELECT count(*) INTO v_rows
        FROM inform.compass_responses_current
       WHERE user_id = v_user AND topic_id = v_topic;
      IF v_rows <> 1 THEN
        RAISE EXCEPTION 'CC_0046: the collapse returned % rows, expected exactly 1', v_rows;
      END IF;

      SELECT value INTO v_seen
        FROM inform.compass_responses_current
       WHERE user_id = v_user AND topic_id = v_topic;
      IF v_seen <> 5 THEN
        RAISE EXCEPTION 'CC_0046: the collapse returned the OLD season''s value (%), not the newest', v_seen;
      END IF;

      RAISE EXCEPTION 'CC_0046_ROLLBACK_PROBE';
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM <> 'CC_0046_ROLLBACK_PROBE' THEN RAISE; END IF;
    END;
  END IF;

  RAISE NOTICE 'CC_0046 OK: scaffold dropped, trigger armed, collapse returns the newest season.';
END $$;

COMMIT;
