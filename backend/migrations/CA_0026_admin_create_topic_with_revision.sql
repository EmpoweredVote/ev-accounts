BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-28. Dry-run first (BEGIN…ROLLBACK): the
-- post-verify gate passed on real data and rolled back. Then applied for real;
-- the gate passed again and committed. Verified inform.admin_create_topic_with_revision
-- exists with the expected 7-arg signature. An earlier rolled-back probe also
-- confirmed a topic created by this RPC pins into the draft season via
-- inform.admin_season_add_topic.

-- =============================================================================
-- CA_0026: admin_create_topic_with_revision — create a topic on the REVISION model
-- =============================================================================
-- Created 2026-08-28 with Chris Andrews.
--
-- THE PROBLEM
-- The admin "create topic" flow (POST /api/admin/compass/topics and the
-- Go-compatible POST /api/compass/topics/create) both call the legacy
-- public.admin_create_topic_with_stances RPC (migration 029). That RPC writes
-- ONLY inform.compass_topics + the legacy inform.compass_stances ladder. It
-- creates NO inform.compass_topic_revisions / inform.compass_stance_revisions.
--
-- Under ADR 0004 (content versioning) + ADR 0006 (per-season version binding,
-- Option Y, merged), the voter/season read path resolves display from the
-- current PUBLISHED revision, not the legacy tables. So a topic created the old
-- way is invisible to the season read path and cannot be pinned into a season —
-- inform.admin_season_add_topic (CA_0022) requires a revision that is
-- `is_current AND status = 'published'`, which the legacy RPC never writes.
--
-- THE FIX
-- A new SECURITY DEFINER RPC (service_role only, mirroring the CA_0015 revision
-- RPCs) that bootstraps a topic across every layer atomically, exactly the way
-- the CA_0025 (Border Security) migration did by hand:
--
--   1. inform.compass_topics            — identity row (topic_key set explicitly,
--                                          consistent with the migration-055 derive
--                                          trigger: lower(replace(name,' ','-'))).
--   2. inform.compass_stances (1..5)    — legacy ladder, corpus 5:5 parity only.
--   3. inform.compass_topic_revisions   — v1: revision=1, version=1,
--                                          change_class='substantive',
--                                          status='published', is_current=true,
--                                          rung_map=NULL (no prior ladder),
--                                          published_at=now(), approved_* NULL.
--   4. inform.compass_stance_revisions  — the five voter-facing rungs of that v1.
--   5. inform.compass_topic_roles       — only when scopes are supplied; absence
--                                          of rows defaults the topic to
--                                          federal+state+local (never judicial).
--
-- The founding revision's rationale/public_note are auto-generated — a v1 created
-- from the admin panel needs no hand-written edit summary — so the create UI needs
-- no new fields. Later EDITS still go through inform.admin_propose_topic_revision
-- (CA_0015/CA_0016), the append-only review path; this RPC is create-only.
--
-- A published+current v1 on a topic that is in NO season shows on NO voter surface:
-- the promoted view (CA_0021) is season-gated, not is_live-gated. is_live therefore
-- does not gate the season read path; it defaults to false (staged), matching
-- CA_0025. The topic goes live only when a draft season pins it and opens.
--
-- Purely additive: creates one function, revokes/grants it. A DROP FUNCTION
-- reverts it completely. No existing object is altered; no data moves.
-- =============================================================================

CREATE OR REPLACE FUNCTION inform.admin_create_topic_with_revision(
  p_title         text,
  p_question_text text,
  p_short_title   text    DEFAULT NULL,
  p_is_live       boolean DEFAULT false,
  p_stances       jsonb   DEFAULT '[]'::jsonb,
  p_actor_id      uuid    DEFAULT NULL,
  p_role_scopes   jsonb   DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_title       text := btrim(p_title);
  v_question    text := btrim(p_question_text);
  v_short_title text := nullif(btrim(p_short_title), '');
  v_topic_key   text;
  v_actor       uuid;
  v_topic       inform.compass_topics%ROWTYPE;
  v_rev_id      uuid;
  v_count       int;
  v_scope       text;
  v_stance      jsonb;
BEGIN
  -- -------------------------------------------------------------------------
  -- Validate identity fields.
  -- -------------------------------------------------------------------------
  IF v_title IS NULL OR v_title = '' THEN
    RAISE EXCEPTION 'INVALID_TITLE: title is required';
  END IF;
  IF v_question IS NULL OR v_question = '' THEN
    RAISE EXCEPTION 'INVALID_QUESTION: question_text is required';
  END IF;

  -- -------------------------------------------------------------------------
  -- Validate the ladder: exactly 5 rungs, values 1..5 distinct, non-empty text.
  -- Matches inform.admin_propose_topic_revision's BAD_LADDER guards so create and
  -- edit enforce the same 5:5 invariant the season read path depends on.
  -- -------------------------------------------------------------------------
  SELECT count(*) INTO v_count FROM jsonb_array_elements(p_stances);
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'BAD_LADDER: % rungs supplied, expected exactly 5', v_count;
  END IF;
  SELECT count(DISTINCT (e->>'value')::int) INTO v_count
    FROM jsonb_array_elements(p_stances) e;
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'BAD_LADDER: rung values must be 1..5 with no duplicates';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_stances) e
    WHERE (e->>'value')::int NOT BETWEEN 1 AND 5
       OR btrim(COALESCE(e->>'text', '')) = ''
  ) THEN
    RAISE EXCEPTION 'BAD_LADDER: each rung needs value 1..5 and non-empty text';
  END IF;

  -- -------------------------------------------------------------------------
  -- Validate optional role scopes. NULL/empty => no rows written (topic then
  -- defaults to federal+state+local; never judicial by default).
  -- -------------------------------------------------------------------------
  IF p_role_scopes IS NOT NULL THEN
    IF jsonb_typeof(p_role_scopes) <> 'array' THEN
      RAISE EXCEPTION 'INVALID_ROLE_SCOPE: role_scopes must be a JSON array';
    END IF;
    FOR v_scope IN SELECT jsonb_array_elements_text(p_role_scopes)
    LOOP
      IF v_scope NOT IN ('federal', 'state', 'local', 'judicial') THEN
        RAISE EXCEPTION 'INVALID_ROLE_SCOPE: % (expected federal|state|local|judicial)', v_scope;
      END IF;
    END LOOP;
  END IF;

  -- -------------------------------------------------------------------------
  -- Derive topic_key the same way the migration-055 trigger would, but set it
  -- explicitly so a NULL short_title (trigger would derive NULL -> NOT NULL
  -- violation) is handled, and so it is guaranteed consistent with short_title.
  -- essentials.quotes joins on topic_key, so it is frozen at creation.
  -- -------------------------------------------------------------------------
  v_topic_key := lower(replace(COALESCE(v_short_title, v_title), ' ', '-'));
  IF v_topic_key IS NULL OR v_topic_key = '' THEN
    RAISE EXCEPTION 'INVALID_TOPIC_KEY: could not derive a topic_key from title/short_title';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = v_topic_key) THEN
    RAISE EXCEPTION 'DUPLICATE_TOPIC_KEY: a topic with key % already exists', v_topic_key;
  END IF;

  -- Only stamp a real users row as author; a stale/unknown id becomes NULL rather
  -- than failing the FK and aborting the whole create.
  SELECT id INTO v_actor FROM public.users WHERE id = p_actor_id;

  -- -------------------------------------------------------------------------
  -- (1) Identity row.
  -- -------------------------------------------------------------------------
  INSERT INTO inform.compass_topics
    (title, short_title, question_text, is_live, went_live_at, topic_key)
  VALUES
    (v_title, v_short_title, v_question, p_is_live,
     CASE WHEN p_is_live THEN now() ELSE NULL END, v_topic_key)
  RETURNING * INTO v_topic;

  -- -------------------------------------------------------------------------
  -- (2) Legacy ladder — parity only; the season path reads stance revisions.
  -- -------------------------------------------------------------------------
  FOR v_stance IN SELECT * FROM jsonb_array_elements(p_stances)
  LOOP
    INSERT INTO inform.compass_stances (topic_id, value, text)
    VALUES (v_topic.id, (v_stance->>'value')::int, v_stance->>'text');
  END LOOP;

  -- -------------------------------------------------------------------------
  -- (3) Founding v1 topic revision — published + current, rung_map NULL.
  -- -------------------------------------------------------------------------
  INSERT INTO inform.compass_topic_revisions
    (topic_id, revision, version, change_class,
     title, short_title, question_text,
     rationale, public_note, rung_map,
     status, is_current,
     proposed_by, proposed_at, approved_by, approved_at, published_by, published_at)
  VALUES
    (v_topic.id, 1, 1, 'substantive',
     v_title, v_short_title, v_question,
     'Founding revision (v1) for a new compass topic, created through the admin panel. '
       || 'Bootstraps the ADR 0004 revision model so the topic can display on the season '
       || 'read path (ADR 0006) and be pinned into a season. Ladder and wording as entered '
       || 'by the admin author; refine later via a proposed revision.',
     'First published version of this topic.',
     NULL,
     'published', true,
     v_actor, now(), NULL, NULL, v_actor, now())
  RETURNING id INTO v_rev_id;

  -- -------------------------------------------------------------------------
  -- (4) The five rungs of that revision (the voter-facing ladder).
  -- -------------------------------------------------------------------------
  FOR v_stance IN SELECT * FROM jsonb_array_elements(p_stances)
  LOOP
    INSERT INTO inform.compass_stance_revisions
      (topic_revision_id, value, text, description, supporting_points, example_perspectives)
    VALUES
      (v_rev_id, (v_stance->>'value')::int, v_stance->>'text', NULL, '{}', '{}');
  END LOOP;

  -- -------------------------------------------------------------------------
  -- (5) Optional scope rows.
  -- -------------------------------------------------------------------------
  IF p_role_scopes IS NOT NULL THEN
    FOR v_scope IN SELECT DISTINCT jsonb_array_elements_text(p_role_scopes)
    LOOP
      INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
      VALUES (v_topic.id, v_scope, true)
      ON CONFLICT (topic_id, role_scope) DO NOTHING;
    END LOOP;
  END IF;

  -- -------------------------------------------------------------------------
  -- Return the same { topic, stances } shape the routes/UI already consume.
  -- -------------------------------------------------------------------------
  RETURN jsonb_build_object(
    'topic',   row_to_json(v_topic),
    'stances', COALESCE(
      (SELECT jsonb_agg(row_to_json(s) ORDER BY s.value)
         FROM inform.compass_stances s
        WHERE s.topic_id = v_topic.id),
      '[]'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION inform.admin_create_topic_with_revision(text, text, text, boolean, jsonb, uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION inform.admin_create_topic_with_revision(text, text, text, boolean, jsonb, uuid, jsonb) TO service_role;


-- ---------------------------------------------------------------------------
-- Post-verify gate
-- ---------------------------------------------------------------------------
-- Exercises the function end-to-end on a probe topic, asserts every invariant a
-- season-pinnable topic must satisfy, then rolls the probe back via a sentinel
-- SQLSTATE caught in the inner block (its implicit savepoint undoes the inserts,
-- so nothing has to fight the append-only immutability triggers). A real
-- assertion failure raises the default P0001 code, which is NOT caught here and
-- so aborts the whole migration.
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_res   jsonb;
  v_topic uuid;
  v_n     int;
BEGIN
  BEGIN
    v_res := inform.admin_create_topic_with_revision(
      'CA_0026 Probe Topic',
      'CA_0026 probe — does the founding revision bootstrap correctly?',
      'CA_0026 Probe Topic',
      false,
      '[{"value":1,"text":"Rung one."},{"value":2,"text":"Rung two."},'
        '{"value":3,"text":"Rung three."},{"value":4,"text":"Rung four."},'
        '{"value":5,"text":"Rung five."}]'::jsonb,
      NULL,
      '["federal"]'::jsonb
    );

    v_topic := (v_res->'topic'->>'id')::uuid;
    IF v_topic IS NULL THEN
      RAISE EXCEPTION 'CA_0026: function returned no topic id';
    END IF;

    -- exactly one published/current v1 substantive revision, rung_map NULL
    SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND is_current AND status = 'published'
       AND revision = 1 AND version = 1 AND change_class = 'substantive'
       AND rung_map IS NULL;
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'CA_0026: expected 1 published/current v1 substantive revision (rung_map NULL), got %', v_n;
    END IF;

    -- five distinct stance-revision values on the current revision
    SELECT count(DISTINCT sr.value) INTO v_n
      FROM inform.compass_stance_revisions sr
      JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
     WHERE r.topic_id = v_topic AND r.is_current;
    IF v_n <> 5 THEN
      RAISE EXCEPTION 'CA_0026: expected 5 stance revisions, got %', v_n;
    END IF;

    -- five legacy stances (corpus 5:5 invariant)
    SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
    IF v_n <> 5 THEN
      RAISE EXCEPTION 'CA_0026: expected 5 legacy stances, got %', v_n;
    END IF;

    -- exactly the one requested scope row
    SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'CA_0026: expected exactly 1 role row, got %', v_n;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles
                    WHERE topic_id = v_topic AND role_scope = 'federal') THEN
      RAISE EXCEPTION 'CA_0026: federal role row missing';
    END IF;

    -- must NOT leak onto a voter surface: no season pins it, so the season-gated
    -- promoted view must not list it
    IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
      RAISE EXCEPTION 'CA_0026: probe topic leaked into an open season (promoted view)';
    END IF;

    -- all invariants hold — undo the probe
    RAISE EXCEPTION USING ERRCODE = 'CA026', MESSAGE = 'CA_0026 probe OK';
  EXCEPTION
    WHEN SQLSTATE 'CA026' THEN
      RAISE NOTICE 'CA_0026 OK — founding-revision bootstrap verified (1 published/current v1, 5 rungs, 5 legacy stances, 1 federal role, not promoted); probe rolled back';
  END;
END $$;

COMMIT;
