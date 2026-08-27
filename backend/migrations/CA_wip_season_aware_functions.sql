BEGIN;

-- =============================================================================
-- CA_wip: Make the five answer-table database functions season-aware
-- =============================================================================
-- Task 5 of docs/superpowers/plans/2026-08-25-compass-seasons.md — the half that
-- is NOT in backend/src. `npm run check:answer-seasons` reports these five and
-- stays red until this lands.
--
-- 🔴🔴 NOT APPLIED YET. Written 2026-08-25, awaiting review. Two reasons to read
-- it before applying:
--
--   1. The `ON CONFLICT (politician_id, topic_id, season_id)` clauses below need
--      the key swap from Task 6. plpgsql bodies are not validated at CREATE
--      time, so this migration APPLIES CLEANLY and the functions then fail at
--      runtime with 42P10 until Task 6 has run. Apply Task 6 FIRST.
--   2. `admin_update_politician_answers` has a behavioural question in it that a
--      human should answer — see the note on its DELETE.
--
-- Why these are functions and not queries: they are SECURITY DEFINER RPCs. No
-- file under backend/src contains their bodies, so the repo-only half of the
-- gate cannot see them. One of them, connect.confirm_vq_stance, was missed by a
-- hand-written pg_proc query scoped to four schemas.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. public.admin_update_politician_answers — THE ADMIN COMPASS WRITE PATH
-- -----------------------------------------------------------------------------
-- ⚠ THE DELETE IS GONE ENTIRELY — see CA_wip_answers_upsert_not_replace, which
-- removes it ahead of this migration and explains why (measured: one admin-UI
-- save destroyed 40 of a politician's 41 answers). Scoping it to the open season
-- was this file's first answer and it was not good enough: it still let a
-- single-topic save wipe the rest of that season. Do NOT reinstate it here.
--
-- The original, for the record:
--
--     DELETE FROM inform.politician_answers
--      WHERE politician_id = p_politician_id
--        AND (v_topic_ids IS NULL OR topic_id != ALL(v_topic_ids));
--
-- After the key swap that deletes the politician's answers in EVERY season for
-- every topic absent from the payload. An admin editing season 2 would silently
-- destroy season 1's record — the one thing seasons exist to prevent. It is now
-- scoped to the open season.
--
-- ⚠ QUESTION FOR A HUMAN, deliberately NOT decided here: this DELETE leaves the
-- matching inform.politician_context row in place, so clearing an answer strands
-- its reasoning. That is how gate-visible ORPHAN_CONTEXT rows appear at RUNTIME
-- rather than through a migration; CLAUDE.md obliges a migration that deletes
-- answers to decide the context's fate, and this path never has. Fixing it means
-- choosing between deleting the reasoning and keeping it as a documented blank,
-- which is an editorial call. Behaviour is preserved here so that the season fix
-- does not smuggle in a data-loss change.
-- 🔴 THE SIGNATURE MUST NOT CHANGE. An earlier draft added
-- `p_editor_id uuid DEFAULT NULL`, which makes CREATE OR REPLACE an OVERLOAD
-- rather than a replacement: the dry run showed TWO
-- public.admin_update_politician_answers in pg_proc, the old broken 2-arg one
-- still live and still what PostgREST resolves a 2-arg call to. The editor is
-- taken from auth.uid() instead — this is SECURITY DEFINER behind a user JWT, so
-- that is the caller, and auth.users and public.users share ids.
CREATE OR REPLACE FUNCTION public.admin_update_politician_answers(
  p_politician_id uuid, p_answers jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_answer    jsonb;
  v_season    uuid;
  v_editor    uuid := auth.uid();
BEGIN
  SELECT id INTO v_season FROM inform.seasons WHERE status = 'open';
  IF v_season IS NULL THEN
    RAISE EXCEPTION 'NO_OPEN_SEASON: nothing can be written until a season is open';
  END IF;

  FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    -- The pin comes from season_questions, never from the caller.
    INSERT INTO inform.politician_answers
      (politician_id, topic_id, season_id, topic_revision_id, value, editor_id, updated_at)
    SELECT p_politician_id, (v_answer->>'topic_id')::uuid, sq.season_id,
           sq.topic_revision_id, (v_answer->>'value')::numeric, v_editor, now()
      FROM inform.season_questions sq
     WHERE sq.season_id = v_season
       AND sq.topic_id = (v_answer->>'topic_id')::uuid
    ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
      SET value = EXCLUDED.value, editor_id = EXCLUDED.editor_id, updated_at = now();

    IF NOT FOUND THEN
      RAISE EXCEPTION 'TOPIC_NOT_IN_SEASON: topic % is not in the open season''s question set',
        (v_answer->>'topic_id');
    END IF;
  END LOOP;
END;
$function$;


-- -----------------------------------------------------------------------------
-- 2. connect.confirm_vq_stance — the Verification Questions reward path
-- -----------------------------------------------------------------------------
-- Only the final answer write changes. Everything above it (gem transactions,
-- verification ratings, advisory locks in sorted order, the idempotency cache)
-- is untouched. Left as ON CONFLICT on the bare pair it raises 42P10, which
-- aborts the whole function and rolls back the gems and ratings with it — and
-- because the idempotency row is written after, a retry would find no cache
-- entry and fail again.
CREATE OR REPLACE FUNCTION connect.confirm_vq_stance(
  p_politician_id uuid, p_topic_id uuid, p_confirmed_value integer,
  p_correct_users uuid[], p_incorrect_users uuid[], p_idempotency_key text,
  p_gems_amount integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_cached_result     JSONB;
  v_return_result     JSONB;
  v_politician_exists BOOLEAN;
  v_all_users         UUID[];
  v_sorted_users      UUID[];
  v_uid               UUID;
  v_vr                INTEGER;
  v_gem_balance_red   INTEGER;
  v_new_rating        INTEGER;
  v_rating_delta      INTEGER;
  v_user_results      JSONB[] := ARRAY[]::JSONB[];
  v_unresolved_users  UUID[]  := ARRAY[]::UUID[];
  v_correct_count     INTEGER := 0;
  v_incorrect_count   INTEGER := 0;
  v_written           INTEGER := 0;
BEGIN
  IF p_confirmed_value < 1 OR p_confirmed_value > 5 THEN
    RAISE EXCEPTION 'INVALID_VALUE: confirmed_value must be between 1 and 5';
  END IF;
  SELECT result_json INTO v_cached_result FROM connect.vq_confirmation_results WHERE idempotency_key = p_idempotency_key;
  IF FOUND THEN RETURN v_cached_result || '{"replayed": true}'::JSONB; END IF;
  SELECT EXISTS (
    SELECT 1 FROM essentials.politicians p
     WHERE p.id = p_politician_id
       AND EXISTS (SELECT 1 FROM inform.compass_topics t WHERE t.id = p_topic_id)
  ) INTO v_politician_exists;
  IF NOT v_politician_exists THEN
    RAISE EXCEPTION 'QUESTION_NOT_FOUND: politician % or topic % does not exist', p_politician_id, p_topic_id;
  END IF;

  -- Checked BEFORE any gems move: a stance that cannot be recorded must not
  -- award anything, and finding out at the final INSERT would mean unwinding.
  IF NOT EXISTS (
    SELECT 1 FROM inform.season_questions sq
      JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
     WHERE sq.topic_id = p_topic_id
  ) THEN
    RAISE EXCEPTION 'NO_OPEN_SEASON_FOR_TOPIC: topic % is not in an open season''s question set',
      p_topic_id;
  END IF;

  v_all_users := ARRAY(SELECT DISTINCT unnest(p_correct_users || p_incorrect_users));
  SELECT ARRAY(SELECT u FROM unnest(v_all_users) u ORDER BY u::TEXT) INTO v_sorted_users;
  FOREACH v_uid IN ARRAY v_sorted_users LOOP
    PERFORM pg_advisory_xact_lock(hashtext(v_uid::TEXT));
  END LOOP;
  FOREACH v_uid IN ARRAY p_correct_users LOOP
    SELECT verification_rating, gem_balance_red INTO v_vr, v_gem_balance_red FROM connect.connected_profiles WHERE user_id = v_uid FOR UPDATE;
    IF NOT FOUND THEN v_unresolved_users := v_unresolved_users || v_uid; CONTINUE; END IF;
    v_new_rating := LEAST(v_vr + 3, 150);
    v_rating_delta := v_new_rating - v_vr;
    UPDATE connect.connected_profiles SET verification_rating = v_new_rating WHERE user_id = v_uid;
    INSERT INTO connect.gem_transactions (user_id, gem_type, amount, transaction_type, idempotency_key, balance_after) VALUES (v_uid, 'red', p_gems_amount, 'vq_correct', p_idempotency_key || ':' || v_uid::TEXT, v_gem_balance_red + p_gems_amount);
    UPDATE connect.connected_profiles SET gem_balance_red = gem_balance_red + p_gems_amount WHERE user_id = v_uid;
    v_user_results := v_user_results || jsonb_build_object('user_id', v_uid, 'result', 'correct', 'gems_awarded', p_gems_amount, 'rating_delta', v_rating_delta, 'new_rating', v_new_rating);
    v_correct_count := v_correct_count + 1;
  END LOOP;
  FOREACH v_uid IN ARRAY p_incorrect_users LOOP
    SELECT verification_rating INTO v_vr FROM connect.connected_profiles WHERE user_id = v_uid FOR UPDATE;
    IF NOT FOUND THEN v_unresolved_users := v_unresolved_users || v_uid; CONTINUE; END IF;
    v_new_rating := GREATEST(v_vr - 10, 0);
    v_rating_delta := v_new_rating - v_vr;
    UPDATE connect.connected_profiles SET verification_rating = v_new_rating, vq_hold_until = CASE WHEN v_new_rating = 0 THEN now() + INTERVAL '30 days' ELSE vq_hold_until END WHERE user_id = v_uid;
    v_user_results := v_user_results || jsonb_build_object('user_id', v_uid, 'result', 'incorrect', 'gems_awarded', 0, 'rating_delta', v_rating_delta, 'new_rating', v_new_rating);
    v_incorrect_count := v_incorrect_count + 1;
  END LOOP;

  INSERT INTO inform.politician_answers
    (politician_id, topic_id, season_id, topic_revision_id, value, updated_at)
  SELECT p_politician_id, p_topic_id, sq.season_id, sq.topic_revision_id,
         p_confirmed_value, now()
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
   WHERE sq.topic_id = p_topic_id
  ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
    SET value = EXCLUDED.value, updated_at = now();
  GET DIAGNOSTICS v_written = ROW_COUNT;
  IF v_written = 0 THEN
    RAISE EXCEPTION 'STANCE_NOT_WRITTEN: no open season accepted topic %', p_topic_id;
  END IF;

  v_return_result := jsonb_build_object('politician_id', p_politician_id, 'topic_id', p_topic_id, 'confirmed_value', p_confirmed_value, 'correct_count', v_correct_count, 'incorrect_count', v_incorrect_count, 'users', to_jsonb(v_user_results), 'unresolved_users', to_jsonb(v_unresolved_users));
  INSERT INTO connect.vq_confirmation_results (idempotency_key, result_json) VALUES (p_idempotency_key, v_return_result);
  RETURN v_return_result;
END;
$function$;


-- -----------------------------------------------------------------------------
-- 3. inform.admin_publish_topic_rewrite — two upserts, both on the bare pair
-- -----------------------------------------------------------------------------
-- It copies approved proposals onto a NEW topic id. Under seasons that new topic
-- must be in the open season's question set, or there is no pinned ladder
-- revision to record the copied answers against — so that is checked up front
-- rather than discovered as a silent zero-row copy.
--
-- ⚠ The GET DIAGNOSTICS after the first INSERT counted rows copied; it still
-- does, and it is still reported as approved_copied.
CREATE OR REPLACE FUNCTION inform.admin_publish_topic_rewrite(
  p_rewrite_id uuid, p_actor_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_rewrite        inform.topic_rewrites%ROWTYPE;
  v_approved_count INT;
  v_rejected_count INT;
  v_season         uuid;
  v_pin            uuid;
BEGIN
  SELECT * INTO v_rewrite FROM inform.topic_rewrites WHERE id = p_rewrite_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: rewrite % does not exist', p_rewrite_id;
  END IF;
  IF v_rewrite.state <> 'publish_ready' THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % must be in publish_ready (is %)',
      p_rewrite_id, v_rewrite.state;
  END IF;

  SELECT sq.season_id, sq.topic_revision_id INTO v_season, v_pin
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
   WHERE sq.topic_id = v_rewrite.new_topic_id;
  IF v_season IS NULL THEN
    RAISE EXCEPTION
      'NEW_TOPIC_NOT_IN_SEASON: topic % is not in the open season''s question set, '
      'so its copied answers would have no pinned ladder revision',
      v_rewrite.new_topic_id;
  END IF;

  INSERT INTO inform.politician_answers
    (politician_id, topic_id, season_id, topic_revision_id, value, editor_id, updated_at)
  SELECT p.politician_id, v_rewrite.new_topic_id, v_season, v_pin,
         p.proposed_value, p_actor_id, now()
    FROM inform.topic_rewrite_stance_proposals p
   WHERE p.rewrite_id = p_rewrite_id AND p.status = 'approved'
  ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
    SET value = EXCLUDED.value, editor_id = EXCLUDED.editor_id, updated_at = now();
  GET DIAGNOSTICS v_approved_count = ROW_COUNT;

  INSERT INTO inform.politician_context
    (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
  SELECT p.politician_id, v_rewrite.new_topic_id, v_season, v_pin,
         COALESCE(p.proposed_reasoning, ''), COALESCE(p.proposed_sources, '{}'),
         p_actor_id, now()
    FROM inform.topic_rewrite_stance_proposals p
   WHERE p.rewrite_id = p_rewrite_id AND p.status = 'approved'
  ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources,
        editor_id = EXCLUDED.editor_id, updated_at = now();

  SELECT count(*) INTO v_rejected_count
    FROM inform.topic_rewrite_stance_proposals
   WHERE rewrite_id = p_rewrite_id AND status = 'rejected';

  UPDATE inform.compass_topics SET is_live = false WHERE id = v_rewrite.old_topic_id;
  UPDATE inform.compass_topics SET is_live = true, went_live_at = now()
   WHERE id = v_rewrite.new_topic_id;
  UPDATE inform.topic_rewrites
     SET state = 'published', published_by = p_actor_id, published_at = now()
   WHERE id = p_rewrite_id;

  RETURN jsonb_build_object(
    'approved_copied',  v_approved_count,
    'rejected_skipped', v_rejected_count);
END;
$function$;


-- -----------------------------------------------------------------------------
-- 4. inform.admin_approve_rewrite_framing — A SILENT FAN-OUT, not a 42P10
-- -----------------------------------------------------------------------------
-- 🔴 It seeds topic_rewrite_stance_proposals from
--     politician_answers LEFT JOIN politician_context ON (politician_id, topic_id)
-- After the key swap that produces one row per answer-season TIMES one per
-- context-season, so it would seed DUPLICATE proposals and pair an answer from
-- one season with reasoning from another. Nothing errors; the reviewer just sees
-- each politician listed more than once with mismatched prose.
--
-- Now: one proposal per politician, from their newest answered season, with the
-- context taken from THAT SAME season.
CREATE OR REPLACE FUNCTION inform.admin_approve_rewrite_framing(
  p_rewrite_id uuid, p_actor_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_rewrite      inform.topic_rewrites%ROWTYPE;
  v_seeded_count INT;
BEGIN
  SELECT * INTO v_rewrite FROM inform.topic_rewrites WHERE id = p_rewrite_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: rewrite % does not exist', p_rewrite_id;
  END IF;
  IF v_rewrite.state <> 'pending_framing_review' THEN
    RAISE EXCEPTION 'INVALID_TRANSITION: rewrite % must be in pending_framing_review (is %)',
      p_rewrite_id, v_rewrite.state;
  END IF;

  INSERT INTO inform.topic_rewrite_stance_proposals (
    rewrite_id, politician_id, old_value, old_reasoning, old_sources
  )
  SELECT p_rewrite_id, latest.politician_id, latest.value,
         COALESCE(pc.reasoning, ''), COALESCE(pc.sources, '{}')
    FROM (
      -- One row per politician: their newest season on the old topic.
      SELECT DISTINCT ON (pa.politician_id)
             pa.politician_id, pa.value, pa.season_id
        FROM inform.politician_answers pa
        JOIN inform.seasons s ON s.id = pa.season_id
       WHERE pa.topic_id = v_rewrite.old_topic_id
       ORDER BY pa.politician_id, s.number DESC
    ) latest
    -- Same season as the value, so the reviewer never sees an answer beside
    -- reasoning written against a different ladder text.
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = latest.politician_id
     AND pc.topic_id      = v_rewrite.old_topic_id
     AND pc.season_id     = latest.season_id;

  GET DIAGNOSTICS v_seeded_count = ROW_COUNT;

  UPDATE inform.topic_rewrites
     SET state = 're_evaluation_queue',
         framing_approved_by = p_actor_id,
         framing_approved_at = now()
   WHERE id = p_rewrite_id;

  RETURN v_seeded_count;
END;
$function$;


-- -----------------------------------------------------------------------------
-- 5. public.admin_list_politicians — an INFLATING COUNT, no error
-- -----------------------------------------------------------------------------
-- answer_count was COUNT(*) over politician_answers. After the swap it climbs by
-- one per season per topic, so a politician with 44 answers in each of two
-- seasons reads 88. Nothing breaks; the number admins use to judge coverage is
-- simply wrong. Collapsed to one answer per topic — their newest season — which
-- is what the compass itself displays.
CREATE OR REPLACE FUNCTION public.admin_list_politicians()
 RETURNS TABLE(id uuid, first_name text, last_name text, preferred_name text,
   full_name text, office_title text, photo_origin_url text, is_active boolean,
   is_candidate boolean, is_vacant boolean, representing_city text,
   representing_state text, district_type text, district_label text,
   district_id text, chamber_name text, chamber_name_formal text,
   government_name text, created_at timestamp with time zone, answer_count bigint)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT * FROM (
    SELECT DISTINCT ON (p.id)
      p.id, p.first_name, p.last_name, p.preferred_name, p.full_name,
      o.title AS office_title, p.photo_origin_url, p.is_active,
      false::boolean AS is_candidate, p.is_vacant,
      o.representing_city, o.representing_state,
      NULL::text AS district_type, NULL::text AS district_label,
      NULL::text AS district_id, NULL::text AS chamber_name,
      NULL::text AS chamber_name_formal, NULL::text AS government_name,
      NULL::timestamptz AS created_at,
      (
        SELECT COUNT(*) FROM (
          SELECT DISTINCT ON (pa.topic_id) pa.topic_id
            FROM inform.politician_answers pa
            JOIN inform.seasons s ON s.id = pa.season_id
           WHERE pa.politician_id = p.id
           ORDER BY pa.topic_id, s.number DESC
        ) latest
      ) AS answer_count
    FROM essentials.politicians p
    -- ADR 0002 phase 5: occupancy via office_current_holder, not offices.politician_id.
    LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
    LEFT JOIN essentials.offices o ON o.id = och.office_id
    WHERE p.is_active = true
    ORDER BY p.id, o.id
  ) sub
  ORDER BY
    COALESCE(NULLIF(TRIM(sub.last_name), ''), sub.full_name),
    sub.first_name
$function$;


DO $$
DECLARE v_bad text;
BEGIN
  -- Every one of the five must now name a season, and none may keep a bare-pair
  -- ON CONFLICT. Same predicate the CI gate applies.
  SELECT string_agg(n.nspname||'.'||p.proname, ', ')
    INTO v_bad
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE p.prokind = 'f'
     AND n.nspname IN ('public','inform','connect','essentials','treasury','empower','connect')
     AND pg_get_functiondef(p.oid) ~* '\ypolitician_(answers|context)\y'
     AND (pg_get_functiondef(p.oid) !~* 'season'
       OR pg_get_functiondef(p.oid) ~* 'on\s+conflict\s*\(\s*(\w+\.)?politician_id\s*,\s*(\w+\.)?topic_id\s*\)');
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'still not season-aware: %', v_bad;
  END IF;

  -- The rewrite seeder must not be able to fan out again.
  IF (SELECT pg_get_functiondef(oid) FROM pg_proc
       WHERE proname = 'admin_approve_rewrite_framing') !~* 'DISTINCT ON' THEN
    RAISE EXCEPTION 'admin_approve_rewrite_framing lost its DISTINCT ON — it can fan out';
  END IF;

  RAISE NOTICE 'season-aware functions OK — 5 rewritten, none names the bare pair';
END $$;

COMMIT;

-- =============================================================================
-- DRY-RUN RECORD, 2026-08-25 — NOT APPLIED
-- =============================================================================
-- Run through the Supabase MCP inside BEGIN … ROLLBACK. Four of the five
-- functions created cleanly and pg_proc then reported them season-aware with no
-- bare-pair ON CONFLICT. connect.confirm_vq_stance was not included in that run
-- (60 lines of untouched gem/rating logic); only its tail differs and it still
-- needs its own dry run before this is applied.
--
-- 🔴 THE DRY RUN CAUGHT A DEFECT IN THIS FILE. An earlier draft of
-- admin_update_politician_answers added a p_editor_id parameter, and pg_proc came
-- back with TWO functions of that name: CREATE OR REPLACE with a changed
-- signature is an OVERLOAD, not a replacement, so the old unseasoned 2-arg body
-- stayed live and is what PostgREST resolves a 2-arg call to. Applying it would
-- have looked successful and fixed nothing. Signature restored; re-verified as
-- 1 overload, arguments "p_politician_id uuid, p_answers jsonb", season-aware.
--
-- STILL TO DO BEFORE APPLYING:
--   · Apply Task 6 first. These ON CONFLICT clauses need the 3-column key; until
--     then they raise 42P10 at runtime (plpgsql bodies are not checked at CREATE).
--   · Dry-run confirm_vq_stance on its own.
--   · Decide the ORPHAN_CONTEXT question flagged on the DELETE above.
--   · Take a CA_ slot and add the applied-date header.
