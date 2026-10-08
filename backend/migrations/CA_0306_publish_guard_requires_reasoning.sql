BEGIN;

-- =============================================================================
-- CA_0306: a moving revision may not publish a non-blank answer that has no reasoning
-- =============================================================================
-- 2026-10-07, Chris Andrews. Findings: docs/superpowers/specs/2026-10-07-season3-repointing-findings.md
-- REQUIRES CA_0305 (the probe below calls inform.repoint_season_answers).
--
-- WHAT THE GUARD MISSED. CC_0060 taught admin_publish_topic_revision to ask "does every
-- earlier-season answer have a row in the pinning season?". A row of any kind passes.
-- So an answer could reach the new season on a moved rung with no reasoning row at all,
-- and voters would see a position with an empty "Why this position?".
--
-- WHAT IT ASKS NOW, ONLY for a revision whose rung_map moves rungs (the branch CC_0060
-- already gates): every NON-BLANK answer in the season that pins this revision must have
-- a politician_context row in that season. A blank (value 0) needs none — it asserts no
-- position. Measured on prod 2026-10-07: 0 non-blank Season 2 answers lack reasoning, so
-- the rule is already true of today's data.
--
-- ⚠ WHAT IT DELIBERATELY DOES NOT ASK: that a carried value equals rung_map[old value].
-- That was the plan, and it cannot be built honestly. editor_id is NULL on 3,975 of the
-- 4,041 Season 2 answers, including researched ones (migrations 1870-1881 write NULL on
-- purpose), so no column tells a mechanical carry from a researched row. A value check
-- keyed on editor_id would refuse real research and abort the season open. Value
-- correctness is instead asserted by repoint_season_answers' own probe (CA_0305).
--
-- Everything else in the function is CC_0060 byte for byte (verified against prod).

CREATE OR REPLACE FUNCTION inform.admin_publish_topic_revision(
  p_revision_id uuid,
  p_actor_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_rev inform.compass_topic_revisions%ROWTYPE;
  v_cur inform.compass_topic_revisions%ROWTYPE;
  v_moved TEXT;
  v_pins int;
  v_stranded int;
  v_noreasoning int;
  v_example text;
BEGIN
  SELECT * INTO v_rev FROM inform.compass_topic_revisions WHERE id = p_revision_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND: revision %', p_revision_id; END IF;
  IF v_rev.status <> 'approved' THEN
    RAISE EXCEPTION 'NOT_APPROVED: revision % is % - a Compass Stance Editor must approve it first',
      p_revision_id, v_rev.status;
  END IF;

  IF v_rev.rung_map IS NOT NULL THEN
    SELECT string_agg(e.key || '->' || (e.value #>> '{}'), ', ' ORDER BY e.key) INTO v_moved
    FROM jsonb_each(v_rev.rung_map) e WHERE (e.value #>> '{}') <> e.key;

    IF v_moved IS NOT NULL THEN
      SELECT count(*) INTO v_pins
        FROM inform.season_questions sq WHERE sq.topic_revision_id = p_revision_id;

      IF v_pins = 0 THEN
        RAISE EXCEPTION
          'REPOINTING_NOT_IMPLEMENTED: rung map moves or invalidates rungs (%), and no season pins this revision — there is no target season for the answers to have been re-pointed into. Add it to a season''s question set first, re-point, then publish.', v_moved;
      END IF;

      SELECT count(*), min(p.full_name)
        INTO v_stranded, v_example
        FROM inform.season_questions sq
        JOIN inform.seasons s_target ON s_target.id = sq.season_id
        JOIN inform.politician_answers old_a ON old_a.topic_id = sq.topic_id
        JOIN inform.seasons s_old ON s_old.id = old_a.season_id
                                 AND s_old.number < s_target.number
        LEFT JOIN essentials.politicians p ON p.id = old_a.politician_id
       WHERE sq.topic_revision_id = p_revision_id
         AND NOT EXISTS (
           SELECT 1 FROM inform.politician_answers new_a
            WHERE new_a.politician_id = old_a.politician_id
              AND new_a.topic_id      = sq.topic_id
              AND new_a.season_id     = sq.season_id);

      IF v_stranded > 0 THEN
        RAISE EXCEPTION
          'REPOINTING_INCOMPLETE: rung map moves or invalidates rungs (%), and % answer(s) from an earlier season have no row in the season that pins this revision (for example %). Run the re-pointing for this topic first — a blanked answer counts, but it must exist as a row (value 0), not be left out.',
          v_moved, v_stranded, coalesce(v_example, 'unknown politician');
      END IF;

      -- 🟢 CA_0306. A non-blank answer on the moved ladder must carry its reasoning.
      SELECT count(*), min(p.full_name)
        INTO v_noreasoning, v_example
        FROM inform.season_questions sq
        JOIN inform.politician_answers n
          ON n.season_id = sq.season_id AND n.topic_id = sq.topic_id
         AND n.topic_revision_id = sq.topic_revision_id
        LEFT JOIN essentials.politicians p ON p.id = n.politician_id
       WHERE sq.topic_revision_id = p_revision_id
         AND n.value <> 0
         AND NOT EXISTS (
           SELECT 1 FROM inform.politician_context c
            WHERE c.politician_id = n.politician_id
              AND c.topic_id      = n.topic_id
              AND c.season_id     = n.season_id);

      IF v_noreasoning > 0 THEN
        RAISE EXCEPTION
          'REPOINTING_NO_REASONING: rung map moves or invalidates rungs (%), and % non-blank answer(s) in the season that pins this revision have no reasoning row (for example %). Write the reasoning, or blank the answer (value 0).',
          v_moved, v_noreasoning, coalesce(v_example, 'unknown politician');
      END IF;
    END IF;
  END IF;

  SELECT * INTO v_cur FROM inform.compass_topic_revisions
  WHERE topic_id = v_rev.topic_id AND is_current;
  IF NOT FOUND THEN RAISE EXCEPTION 'NO_CURRENT_REVISION: topic % has nothing to supersede', v_rev.topic_id; END IF;

  IF v_rev.version NOT IN (v_cur.version, v_cur.version + 1) THEN
    RAISE EXCEPTION 'STALE_VERSION: this draft was numbered v%, but the current revision is now v%. Re-propose it.',
      v_rev.version, v_cur.version;
  END IF;

  UPDATE inform.compass_topic_revisions SET is_current = false, status = 'superseded' WHERE id = v_cur.id;
  UPDATE inform.compass_topic_revisions
  SET is_current = true, status = 'published', published_by = p_actor_id, published_at = now()
  WHERE id = p_revision_id;

  RETURN jsonb_build_object('published_revision', v_rev.revision,
    'published_version', v_rev.version, 'superseded_revision', v_cur.revision);
END;
$function$;

-- CREATE OR REPLACE keeps the owner and grants, but state them: this is a security boundary.
REVOKE ALL ON FUNCTION inform.admin_publish_topic_revision(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION inform.admin_publish_topic_revision(uuid, uuid) TO service_role;

-- -----------------------------------------------------------------------------
-- Prove it in both directions, then throw the proof away
-- -----------------------------------------------------------------------------
-- 1. With CA_0305's rows in place the revision must publish.
-- 2. Delete one mapped answer's reasoning and it must refuse with REPOINTING_NO_REASONING.
-- 3. With NO target rows it must still refuse with REPOINTING_INCOMPLETE (CC_0060 intact).
-- Skipped with a notice when no draft season exists.
DO $$
DECLARE
  v_topic uuid; v_draft uuid; v_actor uuid; v_cur inform.compass_topic_revisions%ROWTYPE;
  v_stances jsonb; v_rev uuid; v_victim uuid;
  v_published boolean := false; v_refused_ctx boolean := false; v_refused_inc boolean := false;
BEGIN
  IF to_regprocedure('inform.repoint_season_answers(uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'CA_0306: apply CA_0305 first (inform.repoint_season_answers is missing)';
  END IF;
  SELECT id INTO v_draft FROM inform.seasons WHERE status = 'draft' ORDER BY number DESC LIMIT 1;
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'homelessness-response';
  IF v_draft IS NULL OR v_topic IS NULL THEN
    RAISE NOTICE 'CA_0306: probe skipped (no draft season or no probe topic). Guard is installed untested.';
    RETURN;
  END IF;
  SELECT approved_by INTO v_actor FROM inform.compass_topic_revisions WHERE approved_by IS NOT NULL LIMIT 1;
  IF v_actor IS NULL THEN RAISE EXCEPTION 'CA_0306: no approver id to borrow for the probe'; END IF;

  BEGIN
    SELECT * INTO v_cur FROM inform.compass_topic_revisions WHERE topic_id = v_topic AND is_current;
    SELECT jsonb_agg(jsonb_build_object('value', value,
             'text', CASE WHEN value = 2 THEN text || ' (PROBE)' ELSE text END,
             'description', description, 'supporting_points', to_jsonb(supporting_points),
             'example_perspectives', to_jsonb(example_perspectives)) ORDER BY value)
      INTO v_stances FROM inform.compass_stance_revisions WHERE topic_revision_id = v_cur.id;
    v_rev := inform.admin_propose_topic_revision('homelessness-response', v_actor, 'substantive',
      v_cur.title, v_cur.short_title, v_cur.question_text, v_stances, 'CA_0306 probe', 'CA_0306 probe', NULL,
      '{"1":1,"2":3,"3":4,"4":5,"5":5}'::jsonb);
    PERFORM inform.admin_approve_topic_revision(v_rev, v_actor);
    PERFORM inform.admin_season_pin_revision(v_draft, v_topic, v_rev, v_actor);

    -- 3. no rows yet
    BEGIN
      PERFORM inform.admin_publish_topic_revision(v_rev, v_actor);
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM LIKE 'REPOINTING_INCOMPLETE:%' THEN v_refused_inc := true; ELSE RAISE; END IF;
    END;

    PERFORM inform.repoint_season_answers(v_draft, v_topic);

    -- 2. strand one mapped answer's reasoning
    SELECT n.politician_id INTO v_victim
      FROM inform.politician_answers n
     WHERE n.season_id = v_draft AND n.topic_id = v_topic AND n.value <> 0 LIMIT 1;
    IF v_victim IS NULL THEN RAISE EXCEPTION 'CA_0306 probe: no non-blank row to strand'; END IF;
    DELETE FROM inform.politician_context
     WHERE politician_id = v_victim AND topic_id = v_topic AND season_id = v_draft;
    BEGIN
      PERFORM inform.admin_publish_topic_revision(v_rev, v_actor);
    EXCEPTION WHEN OTHERS THEN
      IF SQLERRM LIKE 'REPOINTING_NO_REASONING:%' THEN v_refused_ctx := true; ELSE RAISE; END IF;
    END;

    -- 1. blank the stranded answer instead (the other option the message offers) and it publishes
    UPDATE inform.politician_answers SET value = 0
     WHERE politician_id = v_victim AND topic_id = v_topic AND season_id = v_draft;
    PERFORM inform.admin_publish_topic_revision(v_rev, v_actor);
    v_published := true;
    RAISE EXCEPTION 'PROBE_RB';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM <> 'PROBE_RB' THEN RAISE; END IF;
  END;

  IF NOT v_refused_inc THEN RAISE EXCEPTION 'CA_0306: CC_0060 check lost — published with no target rows'; END IF;
  IF NOT v_refused_ctx THEN RAISE EXCEPTION 'CA_0306: published a non-blank answer with no reasoning'; END IF;
  IF NOT v_published THEN RAISE EXCEPTION 'CA_0306: a complete re-point did not publish'; END IF;
  RAISE NOTICE 'CA_0306 OK: no rows -> REPOINTING_INCOMPLETE; no reasoning -> REPOINTING_NO_REASONING; blanked -> publishes. Rolled back.';
END $$;

DO $$
DECLARE v_probe int;
BEGIN
  SELECT count(*) INTO v_probe FROM inform.compass_topic_revisions WHERE rationale = 'CA_0306 probe';
  IF v_probe <> 0 THEN RAISE EXCEPTION 'CA_0306: % probe revision(s) leaked', v_probe; END IF;
  IF EXISTS (SELECT 1 FROM information_schema.role_routine_grants
              WHERE routine_schema = 'inform' AND routine_name = 'admin_publish_topic_revision'
                AND grantee IN ('anon', 'authenticated', 'PUBLIC')) THEN
    RAISE EXCEPTION 'CA_0306: admin_publish_topic_revision is executable by anon/authenticated';
  END IF;
  RAISE NOTICE 'CA_0306: no probe revision leaked, grants are service_role only.';
END $$;

COMMIT;
