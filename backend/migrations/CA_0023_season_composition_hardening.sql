BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-28. Verified: seasons_one_draft up, both
-- functions replaced (SECURITY DEFINER, service_role-only), the structural
-- interlock confirmed firing against the live CC_0002 scaffolds, 1 season /
-- 44 season_questions untouched. Dry-run first; then a rolled-back prod probe,
-- 6/6: second create → DRAFT_EXISTS; direct second-draft INSERT blocked by the
-- index; open refused structurally, STILL refused after RENAMING a scaffold
-- (the case the name-based check missed); open succeeded only after both
-- scaffolds were dropped inside the probe transaction.

-- =============================================================================
-- CA_0023: Season composition hardening — review findings on CA_0022
-- =============================================================================
-- Three fixes from the PR #211 review, all on the CA_0022 RPCs:
--
-- 1. "One draft at a time" becomes a SCHEMA rule. CA_0022 enforced it with a
--    check-then-insert inside admin_create_draft_season — two concurrent
--    creates could both pass the EXISTS and either die on seasons_number_key
--    (surfaced as a 500) or land two drafts, the second invisible to a UI that
--    renders only one. seasons_one_open's idiom, extended: a partial unique
--    index on status='draft', plus a unique_violation handler in the RPC so
--    the racing loser gets DRAFT_EXISTS instead of a raw 23505.
--
-- 2. The open-season rollout interlock becomes STRUCTURAL. CA_0022 tested the
--    CC_0002 scaffold indexes by name; a rename (soft-delete before drop) or a
--    REINDEX under a new name would fool it, and admin_open_season has no
--    inverse. The question it actually needs answered is "does any UNIQUE
--    index on exactly (politician_id, topic_id) still exist on the answer
--    tables" — asked of pg_index directly, name-free.
--
-- 3. admin_open_season's renumbering keeps the negate-then-land two-pass.
--    ⚠ Do NOT add CHECK (question_number > 0) to season_questions without
--    rewriting that pass — the negation is transient but real.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: at most one draft season, enforced like seasons_one_open
-- ---------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS seasons_one_draft
  ON inform.seasons ((status)) WHERE status = 'draft';

-- ---------------------------------------------------------------------------
-- Section 2: admin_create_draft_season — map the race to DRAFT_EXISTS
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

  BEGIN
    INSERT INTO inform.seasons (number, name, status, public_note)
    VALUES (v_number, btrim(p_name), 'draft', p_public_note)
    RETURNING id INTO v_new_id;
  EXCEPTION WHEN unique_violation THEN
    -- The racing loser: another create landed between the EXISTS check and
    -- this INSERT (seasons_one_draft or seasons_number_key). Same answer as
    -- the pre-flight, so a double-click never reads as a server bug.
    RAISE EXCEPTION 'DRAFT_EXISTS: a draft season already exists — edit it or delete it first';
  END;

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
-- Section 3: admin_open_season — structural interlock, not a name lookup
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

  -- Rollout interlock (ADR 0005 §1.6 step 3), asked structurally: does ANY
  -- unique index on exactly (politician_id, topic_id) still exist on the
  -- answer tables? That is what the CC_0002 scaffolds ARE — while one stands,
  -- the database cannot hold answers in two seasons, so opening a second
  -- season would move that refusal to every politician's first write. A name
  -- check would pass after a rename or a REINDEX under a new name; this one
  -- cannot. Dropping the scaffolds stays an explicit ops migration.
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
-- Section 4: Grants — re-stated so a REPLACE can never widen them
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION inform.admin_create_draft_season(UUID, TEXT, TEXT, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_open_season(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION inform.admin_create_draft_season(UUID, TEXT, TEXT, BOOLEAN) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_open_season(UUID, UUID) TO service_role;

-- ---------------------------------------------------------------------------
-- Section 5: Post-verify gate
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes
                 WHERE schemaname = 'inform' AND indexname = 'seasons_one_draft') THEN
    RAISE EXCEPTION 'CA_0023 INCOMPLETE: seasons_one_draft index missing';
  END IF;
  IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
       WHERE n.nspname = 'inform' AND p.prosecdef
         AND p.proname IN ('admin_create_draft_season', 'admin_open_season')) <> 2 THEN
    RAISE EXCEPTION 'CA_0023 INCOMPLETE: replaced functions missing or not SECURITY DEFINER';
  END IF;
  -- The structural interlock must currently FIRE: both CC_0002 scaffolds are
  -- still up in prod. If this finds nothing, the detection is broken and
  -- admin_open_season would wave the changeover through.
  IF NOT EXISTS (
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
    RAISE EXCEPTION 'CA_0023 INCOMPLETE: structural scaffold detection finds nothing while the CC_0002 scaffolds are up — the interlock would not fire';
  END IF;
  IF (SELECT count(*) FROM inform.seasons WHERE status = 'draft') > 1 THEN
    RAISE EXCEPTION 'CA_0023: more than one draft season exists — resolve before this index can hold';
  END IF;

  RAISE NOTICE 'CA_0023 OK — one-draft index up, both RPCs replaced, interlock verified live';
END $$;

COMMIT;
