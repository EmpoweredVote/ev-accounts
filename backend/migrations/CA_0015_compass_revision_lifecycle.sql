BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-21. Verified: 5 functions + one_open index live,
-- 44 topics untouched. Full lifecycle exercised against real data in a rolled-back
-- transaction, 9/9 cases correct:
--   1 editorial propose -> revision 2, version 1 (version did NOT bump)
--   2 second open proposal on same topic -> refused by one_open index
--   3 publish before approval        -> NOT_APPROVED
--   4 approve then publish           -> ok, superseded revision 1
--   5 after publish                  -> exactly 1 current, 1 superseded, version still 1
--   6 ladder changed, no rung_map    -> RUNG_MAP_REQUIRED
--   7 ladder identical, rung_map set -> RUNG_MAP_NOT_NEEDED
--   8 substantive + identity map     -> published, version bumped to 2
--   9 rung map that moves a rung     -> REPOINTING_NOT_IMPLEMENTED
-- Nothing left behind: 44 revisions, all v1, no test rows.

-- =============================================================================
-- CA_0015: Compass revision lifecycle RPCs
-- =============================================================================
-- Implements ADR 0004 §7 — the review surface's mechanism. Requires CA_0011/12.
--
-- Slot note: CA_0013 and CA_0014 are deliberately left unused. The ADR reserves
-- them for the read-path repoint and the ReadRank split, which must land in that
-- order. Numbers are filename labels, so a gap is free; a renumber later is not.
--
-- FOUR TRANSITIONS, and the state machine is deliberately small:
--   propose  → draft
--   approve  → draft     → approved
--   reject   → draft     → rejected      (terminal, retained)
--   publish  → approved  → published     (and the outgoing one → superseded)
--
-- Role checks live in Express middleware (requireRole('compass_stance_editor')),
-- matching routes/compassContributor.ts. These functions take an actor id and
-- record it; they do not re-authorise. That is the house pattern, not an
-- oversight — but it does mean these must never be granted to anon/authenticated.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- Section 1: One open proposal per topic
-- ---------------------------------------------------------------------------
-- Two people rewriting the same ladder concurrently is a merge conflict with
-- voter-facing consequences. Migration 061 had this same guard
-- (idx_topic_rewrites_open_per_key) and it was the right instinct.
--
-- It also nearly eliminates the stale-version problem in Section 3: a draft's
-- `version` is computed when it is proposed, and `version` is immutable, so a
-- publish that happened in between would leave the draft's number wrong. With at
-- most one open proposal per topic that race needs a publish AND a new proposal
-- between the two, and publish re-checks anyway (Section 6).
-- ---------------------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS compass_topic_revisions_one_open
  ON inform.compass_topic_revisions (topic_id)
  WHERE status IN ('draft', 'approved');


-- ---------------------------------------------------------------------------
-- Section 2: Ladder comparison helper
-- ---------------------------------------------------------------------------
-- Returns the five rungs of a topic revision as a canonical JSONB array, so two
-- ladders can be compared for byte equality. Used to decide whether a rung_map
-- is REQUIRED (ladder changed) or FORBIDDEN (ladder identical).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.ladder_fingerprint(p_topic_revision_id UUID)
RETURNS JSONB
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'value', sr.value,
        'text', sr.text,
        'description', COALESCE(sr.description, ''),
        'supporting_points', to_jsonb(sr.supporting_points),
        'example_perspectives', to_jsonb(sr.example_perspectives)
      )
      ORDER BY sr.value
    ),
    '[]'::jsonb
  )
  FROM inform.compass_stance_revisions sr
  WHERE sr.topic_revision_id = p_topic_revision_id;
$$;


-- ---------------------------------------------------------------------------
-- Section 3: admin_propose_topic_revision
-- ---------------------------------------------------------------------------
-- Creates a `draft` revision plus its five rungs. Computes revision and version.
--
-- `version` bumps ONLY for change_class = 'substantive' (ADR §3). 'editorial' and
-- 'clarifying' reuse the current version, so the public milestone number does not
-- move for a comma.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_propose_topic_revision(
  p_topic_key      TEXT,
  p_actor_id       UUID,
  p_change_class   TEXT,
  p_title          TEXT,
  p_short_title    TEXT,
  p_question_text  TEXT,
  p_stances        JSONB,   -- [{value, text, description?, supporting_points?, example_perspectives?}] x5
  p_rationale      TEXT,
  p_public_note    TEXT,
  p_review_ref     TEXT DEFAULT NULL,
  p_rung_map       JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_topic_id     UUID;
  v_cur          inform.compass_topic_revisions%ROWTYPE;
  v_new_id       UUID;
  v_next_rev     INT;
  v_next_ver     INT;
  v_stance       JSONB;
  v_count        INT;
  v_old_ladder   JSONB;
  v_new_ladder   JSONB;
BEGIN
  SELECT id INTO v_topic_id FROM inform.compass_topics WHERE topic_key = p_topic_key;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_TOPIC: %', p_topic_key;
  END IF;

  SELECT * INTO v_cur FROM inform.compass_topic_revisions
  WHERE topic_id = v_topic_id AND is_current;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_CURRENT_REVISION: topic % has no current revision', p_topic_key;
  END IF;

  IF p_change_class NOT IN ('editorial', 'clarifying', 'substantive') THEN
    RAISE EXCEPTION 'BAD_CHANGE_CLASS: % (expected editorial|clarifying|substantive)', p_change_class;
  END IF;

  -- Exactly five rungs, values 1..5, no duplicates. A four-rung ladder is not a
  -- ladder — the five options are a spectrum and rung meaning is relational.
  SELECT count(*) INTO v_count FROM jsonb_array_elements(p_stances);
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'BAD_LADDER: % rungs supplied, expected exactly 5', v_count;
  END IF;
  SELECT count(DISTINCT (e->>'value')::int) INTO v_count FROM jsonb_array_elements(p_stances) e;
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

  v_next_rev := v_cur.revision + 1;
  v_next_ver := CASE WHEN p_change_class = 'substantive'
                     THEN v_cur.version + 1
                     ELSE v_cur.version END;

  INSERT INTO inform.compass_topic_revisions (
    topic_id, revision, version, change_class,
    title, short_title, question_text,
    rationale, public_note, review_ref, rung_map,
    status, is_current, proposed_by
  ) VALUES (
    v_topic_id, v_next_rev, v_next_ver, p_change_class::inform.change_class,
    p_title, p_short_title, p_question_text,
    p_rationale, p_public_note, p_review_ref, p_rung_map,
    'draft', false, p_actor_id
  )
  RETURNING id INTO v_new_id;

  FOR v_stance IN SELECT * FROM jsonb_array_elements(p_stances)
  LOOP
    INSERT INTO inform.compass_stance_revisions (
      topic_revision_id, value, text, description, supporting_points, example_perspectives
    ) VALUES (
      v_new_id,
      (v_stance->>'value')::int,
      v_stance->>'text',
      v_stance->>'description',
      COALESCE(
        (SELECT array_agg(x) FROM jsonb_array_elements_text(
           COALESCE(v_stance->'supporting_points', '[]'::jsonb)) x), '{}'),
      COALESCE(
        (SELECT array_agg(x) FROM jsonb_array_elements_text(
           COALESCE(v_stance->'example_perspectives', '[]'::jsonb)) x), '{}')
    );
  END LOOP;

  -- rung_map is REQUIRED when the ladder changed and FORBIDDEN when it did not.
  -- Enforced here because a CHECK constraint cannot see the predecessor row.
  v_old_ladder := inform.ladder_fingerprint(v_cur.id);
  v_new_ladder := inform.ladder_fingerprint(v_new_id);

  IF v_old_ladder = v_new_ladder AND p_rung_map IS NOT NULL THEN
    RAISE EXCEPTION 'RUNG_MAP_NOT_NEEDED: the ladder is byte-identical to revision %, so a rung map would be noise', v_cur.revision;
  END IF;
  IF v_old_ladder <> v_new_ladder AND p_rung_map IS NULL THEN
    RAISE EXCEPTION 'RUNG_MAP_REQUIRED: the ladder changed, so every rung needs a disposition (identity, a new rung, or invalidated). See ADR 0004 §4.';
  END IF;

  RETURN v_new_id;
END;
$$;


-- ---------------------------------------------------------------------------
-- Section 4: admin_approve_topic_revision
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_approve_topic_revision(
  p_revision_id UUID,
  p_actor_id    UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_proposed_by UUID;
BEGIN
  SELECT proposed_by INTO v_proposed_by
  FROM inform.compass_topic_revisions
  WHERE id = p_revision_id AND status = 'draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_DRAFT: revision % is missing or not in draft', p_revision_id;
  END IF;

  -- Self-approval is allowed but recorded plainly, so the record shows it. With
  -- four editors and often one author, a hard block would deadlock a small team;
  -- the honest alternative is visibility, not prevention.
  UPDATE inform.compass_topic_revisions
  SET status = 'approved', approved_by = p_actor_id, approved_at = now()
  WHERE id = p_revision_id;
END;
$$;


-- ---------------------------------------------------------------------------
-- Section 5: admin_reject_topic_revision
-- ---------------------------------------------------------------------------
-- Terminal, and the row is RETAINED. A rejected revision is part of the internal
-- record of what the team refused. It is not publicly readable (CA_0011's RLS
-- withholds 'rejected'), because publishing refused wording would misrepresent it
-- as something we considered saying.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_reject_topic_revision(
  p_revision_id UUID,
  p_actor_id    UUID,
  p_reason      TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF btrim(COALESCE(p_reason, '')) = '' THEN
    RAISE EXCEPTION 'REASON_REQUIRED: rejecting a revision requires saying why';
  END IF;

  UPDATE inform.compass_topic_revisions
  SET status = 'rejected', approved_by = p_actor_id, approved_at = now(),
      review_ref = COALESCE(review_ref, '') ||
        CASE WHEN COALESCE(review_ref, '') = '' THEN '' ELSE ' | ' END ||
        'REJECTED: ' || p_reason
  WHERE id = p_revision_id AND status IN ('draft', 'approved');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_OPEN: revision % is missing or already decided', p_revision_id;
  END IF;
END;
$$;


-- ---------------------------------------------------------------------------
-- Section 6: admin_publish_topic_revision
-- ---------------------------------------------------------------------------
-- 🔴 REFUSES ANY REVISION WHOSE rung_map MOVES OR INVALIDATES A RUNG.
--
-- ADR §4 says answers are re-pointed mechanically from the rung map. That
-- machinery is NOT BUILT. Publishing a remap without it would leave 32,887
-- politician answers indexing into a ladder whose positions moved — silently
-- wrong voter-facing positions, the exact defect class of migrations 1729/1730.
--
-- Worse, an 'invalidated' rung means deleting answers, which per CLAUDE.md
-- obliges a decision about the matching inform.politician_context row in the
-- same change, with the answer_delete_context_guard. None of that exists yet.
--
-- So this refuses, loudly, naming what is missing. Framing-prose revisions and
-- reworded-but-same-position ladders publish fine, which covers the review
-- workflow we are actually trying to prove.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inform.admin_publish_topic_revision(
  p_revision_id UUID,
  p_actor_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_rev      inform.compass_topic_revisions%ROWTYPE;
  v_cur      inform.compass_topic_revisions%ROWTYPE;
  v_moved    TEXT;
BEGIN
  SELECT * INTO v_rev FROM inform.compass_topic_revisions WHERE id = p_revision_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: revision %', p_revision_id;
  END IF;
  IF v_rev.status <> 'approved' THEN
    RAISE EXCEPTION 'NOT_APPROVED: revision % is % — a Compass Stance Editor must approve it first',
      p_revision_id, v_rev.status;
  END IF;

  -- Answer re-pointing is not built. Refuse rather than corrupt.
  IF v_rev.rung_map IS NOT NULL THEN
    SELECT string_agg(e.key || '->' || (e.value #>> '{}'), ', ' ORDER BY e.key)
      INTO v_moved
    FROM jsonb_each(v_rev.rung_map) e
    WHERE (e.value #>> '{}') <> e.key;

    IF v_moved IS NOT NULL THEN
      RAISE EXCEPTION
        'REPOINTING_NOT_IMPLEMENTED: rung map moves or invalidates rungs (%). '
        'Publishing this would leave existing politician answers indexing into a '
        'ladder whose positions changed. Answer re-pointing and the '
        'answer_delete_context_guard are not built yet (ADR 0004 §4). '
        'Reword rungs in place, or build the re-pointing migration first.', v_moved;
    END IF;
  END IF;

  SELECT * INTO v_cur FROM inform.compass_topic_revisions
  WHERE topic_id = v_rev.topic_id AND is_current;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_CURRENT_REVISION: topic % has nothing to supersede', v_rev.topic_id;
  END IF;

  -- The draft's version was computed when it was proposed. If something published
  -- in between, that number is now wrong — and `version` is immutable, so it
  -- cannot be corrected in place. Refuse and make the author re-propose.
  IF v_rev.version NOT IN (v_cur.version, v_cur.version + 1) THEN
    RAISE EXCEPTION
      'STALE_VERSION: this draft was numbered v% against v%, but the current revision is now v%. Re-propose it.',
      v_rev.version, v_rev.version, v_cur.version;
  END IF;

  -- Clear the outgoing flag FIRST: the partial unique index on (topic_id) WHERE
  -- is_current permits exactly one, so the order is not stylistic.
  UPDATE inform.compass_topic_revisions
  SET is_current = false, status = 'superseded'
  WHERE id = v_cur.id;

  UPDATE inform.compass_topic_revisions
  SET is_current = true, status = 'published',
      published_by = p_actor_id, published_at = now()
  WHERE id = p_revision_id;

  RETURN jsonb_build_object(
    'published_revision', v_rev.revision,
    'published_version',  v_rev.version,
    'superseded_revision', v_cur.revision
  );
END;
$$;


-- ---------------------------------------------------------------------------
-- Section 7: Grants
-- ---------------------------------------------------------------------------
-- service_role ONLY. Authorisation is the API's job (requireRole), and these
-- functions are SECURITY DEFINER — granting them to authenticated would let any
-- logged-in user publish compass content.
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION inform.admin_propose_topic_revision(TEXT, UUID, TEXT, TEXT, TEXT, TEXT, JSONB, TEXT, TEXT, TEXT, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_approve_topic_revision(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_reject_topic_revision(UUID, UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION inform.admin_publish_topic_revision(UUID, UUID) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION inform.admin_propose_topic_revision(TEXT, UUID, TEXT, TEXT, TEXT, TEXT, JSONB, TEXT, TEXT, TEXT, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_approve_topic_revision(UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_reject_topic_revision(UUID, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION inform.admin_publish_topic_revision(UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION inform.ladder_fingerprint(UUID) TO service_role;


-- ---------------------------------------------------------------------------
-- Section 8: Post-verify gate
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_missing TEXT[] := '{}';
  v_fn      TEXT;
BEGIN
  FOREACH v_fn IN ARRAY ARRAY[
    'admin_propose_topic_revision',
    'admin_approve_topic_revision',
    'admin_reject_topic_revision',
    'admin_publish_topic_revision',
    'ladder_fingerprint'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'inform' AND p.proname = v_fn
    ) THEN
      v_missing := v_missing || v_fn;
    END IF;
  END LOOP;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'inform'
    AND indexname = 'compass_topic_revisions_one_open'
  ) THEN
    v_missing := v_missing || 'one_open index';
  END IF;

  IF array_length(v_missing, 1) > 0 THEN
    RAISE EXCEPTION 'CA_0015 INCOMPLETE: missing %', array_to_string(v_missing, ', ');
  END IF;

  -- The backfilled revisions must all still be current and published; this
  -- migration must not have disturbed them.
  IF (SELECT count(*) FROM inform.compass_topic_revisions WHERE is_current AND status = 'published')
     <> (SELECT count(*) FROM inform.compass_topics) THEN
    RAISE EXCEPTION 'CA_0015: current/published revision count no longer matches topic count';
  END IF;

  RAISE NOTICE 'CA_0015 OK — 5 functions, one_open index, % topics untouched',
    (SELECT count(*) FROM inform.compass_topics);
END $$;

COMMIT;
