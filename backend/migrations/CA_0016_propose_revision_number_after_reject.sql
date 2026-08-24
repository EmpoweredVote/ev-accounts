BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-24. Dry-run first (rolled back), then applied.
-- Post-verify gate output both times:
--   "CA_0016 OK — proposing on judicial-bail-pretrial past a retained revision 2
--    produced revision 3"

-- =============================================================================
-- CA_0016: a rejected draft must not block all future proposals
-- =============================================================================
-- Fixes a real bug in CA_0015's admin_propose_topic_revision, found the first
-- time the reject path was ever exercised (2026-08-24, judicial-bail-pretrial).
--
-- THE BUG
-- The function numbered a new draft as `current.revision + 1`, where `current`
-- is the is_current (published) revision. But `UNIQUE (topic_id, revision)`
-- covers EVERY row, and rejected and superseded revisions are RETAINED by
-- design — a rejected proposal is part of the record of what the team refused.
--
-- So the moment any draft was rejected, its revision number was consumed
-- forever, and every subsequent proposal for that topic failed with a duplicate
-- key error:
--
--   ERROR: duplicate key value violates unique constraint
--          "compass_topic_revisions_topic_revision_uniq"
--   DETAIL: Key (topic_id, revision)=(..., 2) already exists.
--
-- One rejection permanently bricked a topic. The failure was loud rather than
-- silent, which is the only reason it did not corrupt anything — but it made
-- "request changes, then send a revised version" impossible, which is the
-- ordinary path a review workflow exists to support.
--
-- THE FIX
-- `revision` is a monotonic counter over ALL rows for the topic, so it must be
-- max(revision) + 1, not current.revision + 1.
--
-- `version` is deliberately left deriving from the CURRENT revision. The two
-- numbers answer different questions (ADR 0004 §3): `revision` counts every
-- write ever made, including refused ones; `version` is the public milestone and
-- must follow the PUBLISHED lineage, so a rejected v2 must not push the next
-- real proposal to v3. Do not "simplify" these to the same source.
-- =============================================================================


CREATE OR REPLACE FUNCTION inform.admin_propose_topic_revision(
  p_topic_key      TEXT,
  p_actor_id       UUID,
  p_change_class   TEXT,
  p_title          TEXT,
  p_short_title    TEXT,
  p_question_text  TEXT,
  p_stances        JSONB,
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

  -- 🔴 THE FIX. Was `v_cur.revision + 1`, which collided with any retained
  -- rejected or superseded row. UNIQUE (topic_id, revision) covers all statuses.
  SELECT COALESCE(max(revision), 0) + 1 INTO v_next_rev
  FROM inform.compass_topic_revisions
  WHERE topic_id = v_topic_id;

  -- Unchanged and deliberately different: the public milestone follows the
  -- PUBLISHED lineage, so a refused proposal must not advance it.
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

  v_old_ladder := inform.ladder_fingerprint(v_cur.id);
  v_new_ladder := inform.ladder_fingerprint(v_new_id);

  IF v_old_ladder = v_new_ladder AND p_rung_map IS NOT NULL THEN
    RAISE EXCEPTION 'RUNG_MAP_NOT_NEEDED: the ladder is byte-identical to revision %, so a rung map would be noise', v_cur.revision;
  END IF;
  IF v_old_ladder <> v_new_ladder AND p_rung_map IS NULL THEN
    RAISE EXCEPTION 'RUNG_MAP_REQUIRED: the ladder changed, so every rung needs a disposition (identity, a new rung, or invalidated). See ADR 0004 sec 4.';
  END IF;

  RETURN v_new_id;
END;
$$;

REVOKE ALL ON FUNCTION inform.admin_propose_topic_revision(TEXT,UUID,TEXT,TEXT,TEXT,TEXT,JSONB,TEXT,TEXT,TEXT,JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION inform.admin_propose_topic_revision(TEXT,UUID,TEXT,TEXT,TEXT,TEXT,JSONB,TEXT,TEXT,TEXT,JSONB) TO service_role;


-- ---------------------------------------------------------------------------
-- Post-verify gate
-- ---------------------------------------------------------------------------
-- Proves the bug is actually gone by reproducing the exact condition that
-- triggered it: a topic whose highest revision is a RETAINED non-current row.
-- Everything is rolled back inside the block.
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_topic_key TEXT;
  v_max       INT;
  v_cur_rev   INT;
  v_new_id    UUID;
  v_got_rev   INT;
BEGIN
  -- Pick a topic where max(revision) is ahead of the current revision — i.e.
  -- one carrying a retained rejected/superseded row. If none exists yet the
  -- assertion below is skipped rather than faked.
  SELECT t.topic_key, max(r.revision), max(r.revision) FILTER (WHERE r.is_current)
    INTO v_topic_key, v_max, v_cur_rev
  FROM inform.compass_topics t
  JOIN inform.compass_topic_revisions r ON r.topic_id = t.id
  GROUP BY t.topic_key
  HAVING max(r.revision) > max(r.revision) FILTER (WHERE r.is_current)
  LIMIT 1;

  IF v_topic_key IS NULL THEN
    RAISE NOTICE 'CA_0016: no topic with a retained higher revision — fix applied, assertion skipped';
  ELSE
    v_new_id := inform.admin_propose_topic_revision(
      v_topic_key, NULL, 'editorial',
      'CA_0016 probe', 'probe', 'CA_0016 probe?',
      (SELECT jsonb_agg(jsonb_build_object(
                'value', sr.value, 'text', sr.text, 'description', sr.description,
                'supporting_points', to_jsonb(sr.supporting_points),
                'example_perspectives', to_jsonb(sr.example_perspectives)) ORDER BY sr.value)
       FROM inform.compass_stance_revisions sr
       JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
       JOIN inform.compass_topics t ON t.id = r.topic_id
       WHERE t.topic_key = v_topic_key AND r.is_current),
      'CA_0016 post-verify probe', 'CA_0016 post-verify probe');

    SELECT revision INTO v_got_rev FROM inform.compass_topic_revisions WHERE id = v_new_id;

    IF v_got_rev <> v_max + 1 THEN
      RAISE EXCEPTION 'CA_0016: expected revision %, got % — numbering still wrong', v_max + 1, v_got_rev;
    END IF;

    -- Undo the probe. Rungs cascade; the row is still a draft so no immutability
    -- trigger objects.
    DELETE FROM inform.compass_topic_revisions WHERE id = v_new_id;

    RAISE NOTICE 'CA_0016 OK — proposing on % past a retained revision % produced revision %',
      v_topic_key, v_max, v_got_rev;
  END IF;
END $$;

COMMIT;
