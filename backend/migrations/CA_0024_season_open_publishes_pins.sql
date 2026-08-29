BEGIN;

-- =============================================================================
-- CA_0024: A season may stage an approved revision; opening it publishes them
-- =============================================================================
-- ADR 0006 (per-season version binding, Option Y), Model Q — decision 2026-08-29
-- with Chris Andrews. This REVISES the CA_0022 compose-time rule ("pins are set
-- to the topic's CURRENT PUBLISHED revision") for the staging case, now that the
-- Option Y read path (PR #217) makes it safe.
--
-- The problem CA_0022's model left: to put a major rewrite (e.g. abortion v2)
-- into a future season, you had to PUBLISH it first — which moves is_current and
-- shows the new wording on every non-season surface (quote cards) while the open
-- season's compass still shows the old version. A visible split-brain before the
-- season even changes.
--
-- Model Q closes it. A draft season may pin an APPROVED (not-yet-published)
-- revision; is_current stays on the outgoing version; and admin_open_season
-- PUBLISHES each still-approved pin at the moment of changeover — atomically with
-- closing the incumbent and opening the draft. So a version goes live exactly
-- when its season does, and never before.
--
-- Two changes, both to the CA_0022/0023 RPCs:
--   1. NEW  admin_season_pin_revision — pin a specific revision by id (approved,
--           published, or superseded), not only the current published one.
--   2. REPLACE admin_open_season — publish every pinned revision still in
--           'approved' status, then do the existing changeover unchanged.
--
-- The season_questions_pin_immutable trigger (CC_0002) still freezes pins once a
-- season leaves draft, so staging is a draft-only act, as before.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: admin_season_pin_revision — stage a specific revision on a draft
-- ---------------------------------------------------------------------------
-- Unlike admin_season_repin_topic (which always lands on the current published
-- revision), this pins the revision the caller names. That revision must belong
-- to the topic and be live-capable — approved, published, or superseded — never
-- a draft (unreviewed) or rejected (dead) one. The topic must already be in the
-- season; add it first with admin_season_add_topic.
CREATE OR REPLACE FUNCTION inform.admin_season_pin_revision(
  p_season_id   UUID,
  p_topic_id    UUID,
  p_revision_id UUID,
  p_actor_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_status     inform.season_status;
  v_old        UUID;
  v_rev_topic  UUID;
  v_rev_status inform.revision_status;
BEGIN
  SELECT status INTO v_status FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    -- season_questions_pin_immutable would refuse anyway; refuse first so the
    -- caller gets the same NOT_DRAFT code as the rest of the composition RPCs.
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, its pins are frozen', p_season_id, v_status;
  END IF;

  SELECT topic_revision_id INTO v_old
    FROM inform.season_questions
   WHERE season_id = p_season_id AND topic_id = p_topic_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_IN_SEASON: topic % is not in this season — add it first', p_topic_id;
  END IF;

  SELECT topic_id, status INTO v_rev_topic, v_rev_status
    FROM inform.compass_topic_revisions WHERE id = p_revision_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_REVISION: revision % does not exist', p_revision_id;
  END IF;
  IF v_rev_topic <> p_topic_id THEN
    RAISE EXCEPTION 'WRONG_TOPIC: revision % belongs to a different topic', p_revision_id;
  END IF;
  IF v_rev_status NOT IN ('approved', 'published', 'superseded') THEN
    RAISE EXCEPTION 'UNPINNABLE_STATUS: revision % is % — a season may pin only an approved, published, or superseded revision', p_revision_id, v_rev_status;
  END IF;

  IF p_revision_id = v_old THEN
    RETURN jsonb_build_object(
      'repinned', false, 'from_revision_id', v_old, 'to_revision_id', p_revision_id,
      'revision_status', v_rev_status::text);
  END IF;

  UPDATE inform.season_questions
     SET topic_revision_id = p_revision_id
   WHERE season_id = p_season_id AND topic_id = p_topic_id;

  RETURN jsonb_build_object(
    'repinned', true, 'from_revision_id', v_old, 'to_revision_id', p_revision_id,
    'revision_status', v_rev_status::text);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 2: admin_open_season — publish still-approved pins, then change over
-- ---------------------------------------------------------------------------
-- Identical to the CA_0023 version except for the publish loop marked below.
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
  v_status    inform.season_status;
  v_count     INTEGER;
  v_closed    UUID;
  v_pin       RECORD;
  v_published INTEGER := 0;
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

  -- Rollout interlock (ADR 0005 §1.6 step 3), asked structurally: does ANY
  -- unique index on exactly (politician_id, topic_id) still exist on the answer
  -- tables? While one stands the database cannot hold answers in two seasons, so
  -- opening a second season would move that refusal to every politician's first
  -- write. Dropping the scaffolds stays an explicit ops migration.
  IF EXISTS (
    SELECT 1
      FROM pg_index i
      JOIN pg_class t ON t.oid = i.indrelid
      JOIN pg_namespace n ON n.oid = t.relnamespace
     WHERE n.nspname = 'inform'
       AND t.relname IN ('politician_answers', 'politician_context')
       AND i.indisunique
       AND i.indnkeyatts = 2
       AND (SELECT array_agg(a.attname ORDER BY k.ord)
              FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
              JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = k.attnum
           ) = ARRAY['politician_id', 'topic_id']::name[]
  ) THEN
    RAISE EXCEPTION 'SCAFFOLD_INDEXES_PRESENT: a unique index on (politician_id, topic_id) still limits answers to one season (the CC_0002 scaffolding). Dropping it is rollout step 3 (ADR 0005 §1.6) and an explicit operational migration — apply that first, then open the season';
  END IF;

  -- 🟢 CA_0024, ADR 0006 Model Q: publish every pin still in 'approved' status.
  -- This is where a season's staged majors go live — atomically with the
  -- changeover below, so is_current stayed on the outgoing version until now.
  -- admin_publish_topic_revision enforces its own guards (must be approved,
  -- version not stale, rung_map may not move rungs); a failure aborts the whole
  -- open, which is correct — a season must not half-open.
  FOR v_pin IN
    SELECT sq.topic_revision_id AS rev_id
      FROM inform.season_questions sq
      JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
     WHERE sq.season_id = p_season_id AND r.status = 'approved'
  LOOP
    PERFORM inform.admin_publish_topic_revision(v_pin.rev_id, p_actor_id);
    v_published := v_published + 1;
  END LOOP;

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
    'question_count', v_count,
    'published_count', v_published);
END;
$$;

-- ---------------------------------------------------------------------------
-- Section 3: Grants — service_role ONLY (authorisation is the API's job)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION inform.admin_season_pin_revision(UUID, UUID, UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_open_season(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION inform.admin_season_pin_revision(UUID, UUID, UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_open_season(UUID, UUID) TO service_role;

-- ---------------------------------------------------------------------------
-- Section 4: Post-verify gate (function-only migration — no DML)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'inform' AND p.prosecdef
         AND p.proname IN ('admin_season_pin_revision', 'admin_open_season')) <> 2 THEN
    RAISE EXCEPTION 'CA_0024 INCOMPLETE: expected both SECURITY DEFINER functions present';
  END IF;

  -- admin_open_season must now reference the publisher — guard against a REPLACE
  -- that silently dropped the publish loop.
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'inform' AND p.proname = 'admin_open_season'
       AND pg_get_functiondef(p.oid) LIKE '%admin_publish_topic_revision%'
  ) THEN
    RAISE EXCEPTION 'CA_0024 INCOMPLETE: admin_open_season does not call admin_publish_topic_revision — the publish-at-open step is missing';
  END IF;

  -- anon/authenticated must not have gained EXECUTE on the new function.
  IF EXISTS (
    SELECT 1 FROM information_schema.role_routine_grants
     WHERE routine_schema = 'inform' AND routine_name = 'admin_season_pin_revision'
       AND grantee IN ('anon', 'authenticated', 'PUBLIC')
  ) THEN
    RAISE EXCEPTION 'CA_0024 INCOMPLETE: admin_season_pin_revision is executable by anon/authenticated';
  END IF;

  RAISE NOTICE 'CA_0024 OK — pin-by-revision added, admin_open_season publishes approved pins';
END $$;

COMMIT;
