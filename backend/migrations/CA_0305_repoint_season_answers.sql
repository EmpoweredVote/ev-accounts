BEGIN;

-- =============================================================================
-- CA_0305: inform.repoint_season_answers — the generic version of CC_0058
-- =============================================================================
-- 2026-10-07, Chris Andrews. Findings: docs/superpowers/specs/2026-10-07-season3-repointing-findings.md
--
-- WHY. A revision whose rung_map MOVES rungs will not publish (CC_0060 guard) until
-- every earlier-season answer on the topic has a row in the season that pins it.
-- CC_0058 wrote those rows for two topics, with the topic keys hard-coded. Season 3
-- may move any topic, so the write becomes a function.
--
-- THE RULE (accepted by Chris Andrews, 2026-10-07). Per person with an answer on the
-- topic in ANY earlier season, the target season gets one row:
--
--   MAPPED   the person has a row in the season immediately before the target, that
--            row sits on the revision the map starts from (the topic's CURRENT
--            revision), is not already blank, AND has a reasoning row.
--            value = rung_map[old value]; 'invalidated' becomes 0.
--   BLANK    everyone else — value 0, no reasoning row. That covers people with only
--            an older-season answer, rows on an older ladder than the map starts from
--            (the 13 "chained map" topics), rows already blank, and invalidated rungs.
--
-- A blank is the honest outcome: no rung of the new ladder is evidenced for that
-- person. The earlier seasons keep the original rows (this function only INSERTs).
--
-- 🔴 EDITOR_ID IS NULL ON THE ANSWER, DELIBERATELY (CC_0058). The human decision
-- lives in the rung_map; the row's provenance is this function. Reasoning rows keep
-- the original editor_id and evidence_tier: the prose is that editor's work.
--
-- 🔴 DRAFT SEASONS ONLY, AND ONLY FOR AN APPROVED PIN THAT MOVES RUNGS. A published or
-- identity pin has nothing to re-point and the guard does not ask for rows.
--
-- ⚠ IDEMPOTENT MEANS "ADDS NOTHING THE SECOND TIME". An existing target-season row is
-- never touched, whether this function wrote it or a researcher did. It does NOT
-- repair rows written against a different revision: both pin FKs reference
-- season_questions(season_id, topic_id, topic_revision_id) with no cascade, so
-- re-pinning after rows exist means deleting them first. Run this as the LAST step
-- before opening the season.
--
-- ⚠ WRITE-INS ARE REFUSED. A write-in is a position stated between rungs; a rung_map
-- cannot move it. Prod holds none today (measured 2026-10-07).
--
-- Granted to service_role only. Authorisation is the API's job (same as CA_0024).

CREATE OR REPLACE FUNCTION inform.repoint_season_answers(
  p_season_id uuid,
  p_topic_id  uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_status    inform.season_status;
  v_number    int;
  v_pin       uuid;
  v_rev       inform.compass_topic_revisions%ROWTYPE;
  v_base      uuid;
  v_moved     text;
  v_writeins  int;
  v_earlier   int;
  v_on_base   int;
  v_mapped    int;
  v_blanked   int;
  v_context   int;
BEGIN
  SELECT status, number INTO v_status, v_number
    FROM inform.seasons WHERE id = p_season_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUCH_SEASON: season % does not exist', p_season_id;
  END IF;
  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'NOT_DRAFT: season % is %, rows are written only into a draft season', p_season_id, v_status;
  END IF;

  SELECT topic_revision_id INTO v_pin
    FROM inform.season_questions WHERE season_id = p_season_id AND topic_id = p_topic_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_IN_SEASON: topic % is not in season %', p_topic_id, p_season_id;
  END IF;

  SELECT * INTO v_rev FROM inform.compass_topic_revisions WHERE id = v_pin;

  IF v_rev.rung_map IS NOT NULL THEN
    SELECT string_agg(e.key || '->' || (e.value #>> '{}'), ', ' ORDER BY e.key) INTO v_moved
      FROM jsonb_each(v_rev.rung_map) e WHERE (e.value #>> '{}') <> e.key;
  END IF;
  IF v_moved IS NULL THEN
    RAISE EXCEPTION 'NOTHING_TO_REPOINT: the revision pinned for this topic has no rung_map that moves rungs, so the publish guard asks for no rows';
  END IF;
  IF v_rev.status <> 'approved' THEN
    RAISE EXCEPTION 'NOT_APPROVED_PIN: the pinned revision is %, expected approved (a published pin is already live)', v_rev.status;
  END IF;

  -- The rung_map starts from the revision the publish will supersede.
  SELECT id INTO v_base FROM inform.compass_topic_revisions
   WHERE topic_id = p_topic_id AND is_current;
  IF v_base IS NULL THEN
    RAISE EXCEPTION 'NO_CURRENT_REVISION: topic % has no current revision for the map to start from', p_topic_id;
  END IF;

  SELECT count(*) INTO v_writeins
    FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
   WHERE a.topic_id = p_topic_id AND s.number < v_number AND a.write_in_text IS NOT NULL;
  IF v_writeins > 0 THEN
    RAISE EXCEPTION 'WRITE_INS_PRESENT: % write-in(s) on this topic in earlier seasons — a rung_map cannot re-point a write-in; decide those by hand first', v_writeins;
  END IF;

  SELECT count(DISTINCT a.politician_id) INTO v_earlier
    FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
   WHERE a.topic_id = p_topic_id AND s.number < v_number;

  SELECT count(*) INTO v_on_base
    FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
   WHERE a.topic_id = p_topic_id AND s.number = v_number - 1 AND a.topic_revision_id = v_base;

  WITH earlier AS (
    SELECT DISTINCT a.politician_id
      FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
     WHERE a.topic_id = p_topic_id AND s.number < v_number
  ),
  prev AS (
    SELECT a.politician_id, a.value
      FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
     WHERE a.topic_id = p_topic_id AND s.number = v_number - 1
       AND a.topic_revision_id = v_base AND a.value <> 0
       AND EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
                      AND c.season_id = a.season_id AND c.topic_revision_id = v_base)
  ),
  ins AS (
    INSERT INTO inform.politician_answers
      (politician_id, topic_id, season_id, topic_revision_id, value, write_in_text, editor_id, updated_at)
    SELECT e.politician_id, p_topic_id, p_season_id, v_pin,
           CASE WHEN p.politician_id IS NULL THEN 0
                WHEN (v_rev.rung_map ->> p.value::int::text) = 'invalidated' THEN 0
                ELSE (v_rev.rung_map ->> p.value::int::text)::numeric
           END,
           NULL, NULL, now()
      FROM earlier e LEFT JOIN prev p ON p.politician_id = e.politician_id
    ON CONFLICT (politician_id, topic_id, season_id) DO NOTHING
    RETURNING politician_id, value
  ),
  ctx AS (
    INSERT INTO inform.politician_context
      (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, evidence_tier, updated_at)
    SELECT c.politician_id, p_topic_id, p_season_id, v_pin,
           c.reasoning, c.sources, c.editor_id, c.evidence_tier, now()
      FROM ins
      JOIN inform.seasons s ON s.number = v_number - 1
      JOIN inform.politician_context c
        ON c.politician_id = ins.politician_id AND c.topic_id = p_topic_id
       AND c.season_id = s.id AND c.topic_revision_id = v_base
     WHERE ins.value <> 0
    RETURNING politician_id
  )
  SELECT count(*) FILTER (WHERE ins.value <> 0),
         count(*) FILTER (WHERE ins.value = 0),
         (SELECT count(*) FROM ctx)
    INTO v_mapped, v_blanked, v_context
    FROM ins;

  RETURN jsonb_build_object(
    'season_id', p_season_id, 'topic_id', p_topic_id,
    'pinned_revision_id', v_pin, 'base_revision_id', v_base, 'rung_map_moves', v_moved,
    'people_with_earlier_answer', v_earlier,
    'previous_season_rows_on_base_revision', v_on_base,
    'mapped_written', v_mapped, 'blank_written', v_blanked, 'context_written', v_context,
    'already_had_a_row', v_earlier - v_mapped - v_blanked);
END;
$function$;

COMMENT ON FUNCTION inform.repoint_season_answers(uuid, uuid) IS
  'CA_0305. Writes the target-season answer + reasoning rows the publish guard (CC_0060) '
  'requires before a revision with a moving rung_map can publish. Mapped only for a '
  'previous-season row on the current revision with reasoning; everyone else blank (value 0). '
  'Draft season, approved moving pin only. INSERT only; never edits an earlier season.';

REVOKE ALL ON FUNCTION inform.repoint_season_answers(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION inform.repoint_season_answers(uuid, uuid) TO service_role;

-- -----------------------------------------------------------------------------
-- Prove it on real data, then throw the proof away
-- -----------------------------------------------------------------------------
-- A throwaway approved revision with a moving map is pinned into the draft season,
-- the function runs against homelessness-response, the guard publishes it, and every
-- number is checked against an INDEPENDENT count. Rolled back by exception.
-- Skipped (with a notice) when no draft season exists: there is nowhere to pin.
DO $$
DECLARE
  v_topic uuid; v_draft uuid; v_actor uuid; v_cur inform.compass_topic_revisions%ROWTYPE;
  v_stances jsonb; v_rev uuid; v_res jsonb; v_res2 jsonb;
  v_exp_mapped int; v_exp_people int; v_before int; v_after int; v_n int;
  v_ok boolean := false;
BEGIN
  SELECT id INTO v_draft FROM inform.seasons WHERE status = 'draft' ORDER BY number DESC LIMIT 1;
  SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = 'homelessness-response';
  IF v_draft IS NULL OR v_topic IS NULL THEN
    RAISE NOTICE 'CA_0305: probe skipped (no draft season or no probe topic). Function is installed untested.';
    RETURN;
  END IF;
  SELECT approved_by INTO v_actor FROM inform.compass_topic_revisions WHERE approved_by IS NOT NULL LIMIT 1;
  IF v_actor IS NULL THEN RAISE EXCEPTION 'CA_0305: no approver id to borrow for the probe'; END IF;

  BEGIN
    SELECT * INTO v_cur FROM inform.compass_topic_revisions WHERE topic_id = v_topic AND is_current;
    SELECT jsonb_agg(jsonb_build_object('value', value,
             'text', CASE WHEN value = 2 THEN text || ' (PROBE)' ELSE text END,
             'description', description, 'supporting_points', to_jsonb(supporting_points),
             'example_perspectives', to_jsonb(example_perspectives)) ORDER BY value)
      INTO v_stances FROM inform.compass_stance_revisions WHERE topic_revision_id = v_cur.id;

    -- expected numbers, counted independently of the function (map 2->3, 3->4, 4->5, 5->5)
    SELECT count(DISTINCT a.politician_id) INTO v_exp_people
      FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
     WHERE a.topic_id = v_topic AND s.number < (SELECT number FROM inform.seasons WHERE id = v_draft);
    SELECT count(*) INTO v_exp_mapped
      FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
     WHERE a.topic_id = v_topic AND s.number = (SELECT number FROM inform.seasons WHERE id = v_draft) - 1
       AND a.topic_revision_id = v_cur.id AND a.value <> 0
       AND EXISTS (SELECT 1 FROM inform.politician_context c WHERE c.politician_id = a.politician_id
                    AND c.topic_id = a.topic_id AND c.season_id = a.season_id AND c.topic_revision_id = v_cur.id);
    SELECT count(*) INTO v_before FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
     WHERE s.status <> 'draft';

    v_rev := inform.admin_propose_topic_revision('homelessness-response', v_actor, 'substantive',
      v_cur.title, v_cur.short_title, v_cur.question_text, v_stances, 'CA_0305 probe', 'CA_0305 probe', NULL,
      '{"1":1,"2":3,"3":4,"4":5,"5":5}'::jsonb);
    PERFORM inform.admin_approve_topic_revision(v_rev, v_actor);
    PERFORM inform.admin_season_pin_revision(v_draft, v_topic, v_rev, v_actor);

    v_res := inform.repoint_season_answers(v_draft, v_topic);
    IF (v_res ->> 'mapped_written')::int <> v_exp_mapped THEN
      RAISE EXCEPTION 'CA_0305 probe: mapped % expected %', v_res ->> 'mapped_written', v_exp_mapped;
    END IF;
    IF (v_res ->> 'mapped_written')::int + (v_res ->> 'blank_written')::int <> v_exp_people THEN
      RAISE EXCEPTION 'CA_0305 probe: wrote % rows for % people', (v_res ->> 'mapped_written')::int + (v_res ->> 'blank_written')::int, v_exp_people;
    END IF;
    IF (v_res ->> 'context_written')::int <> v_exp_mapped THEN
      RAISE EXCEPTION 'CA_0305 probe: % context rows, expected %', v_res ->> 'context_written', v_exp_mapped;
    END IF;

    -- every mapped row sits on the mapped rung; every blank carries no reasoning
    SELECT count(*) INTO v_n FROM inform.politician_answers n
      JOIN inform.politician_answers o ON o.politician_id = n.politician_id AND o.topic_id = n.topic_id
      JOIN inform.seasons so ON so.id = o.season_id
     WHERE n.season_id = v_draft AND n.topic_id = v_topic AND n.value <> 0
       AND so.number = (SELECT number FROM inform.seasons WHERE id = v_draft) - 1
       AND n.value <> CASE o.value WHEN 2 THEN 3 WHEN 3 THEN 4 WHEN 4 THEN 5 WHEN 5 THEN 5 ELSE o.value END;
    IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0305 probe: % mapped row(s) on the wrong rung', v_n; END IF;
    SELECT count(*) INTO v_n FROM inform.politician_answers n
      JOIN inform.politician_context c ON c.politician_id = n.politician_id AND c.topic_id = n.topic_id AND c.season_id = n.season_id
     WHERE n.season_id = v_draft AND n.topic_id = v_topic AND n.value = 0;
    IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0305 probe: % blank(s) carry reasoning', v_n; END IF;

    -- second run adds nothing
    v_res2 := inform.repoint_season_answers(v_draft, v_topic);
    IF (v_res2 ->> 'mapped_written')::int + (v_res2 ->> 'blank_written')::int <> 0 THEN
      RAISE EXCEPTION 'CA_0305 probe: second run wrote rows (%)', v_res2;
    END IF;

    -- and the guard now accepts it
    PERFORM inform.admin_publish_topic_revision(v_rev, v_actor);

    -- earlier seasons untouched
    SELECT count(*) INTO v_after FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
     WHERE s.status <> 'draft';
    IF v_after <> v_before THEN RAISE EXCEPTION 'CA_0305 probe: non-draft seasons changed % -> %', v_before, v_after; END IF;

    v_ok := true;
    RAISE EXCEPTION 'PROBE_RB';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM <> 'PROBE_RB' THEN RAISE; END IF;
  END;

  IF NOT v_ok THEN RAISE EXCEPTION 'CA_0305: probe did not complete'; END IF;
  RAISE NOTICE 'CA_0305 OK: probe mapped %, blanked %, of % people; guard accepted; rolled back. %',
    v_res ->> 'mapped_written', v_res ->> 'blank_written', v_exp_people, v_res;
END $$;

-- The probe rolled itself back; assert it, do not assume it.
DO $$
DECLARE v_open int; v_probe int;
BEGIN
  SELECT count(*) INTO v_open FROM inform.compass_topic_revisions WHERE status IN ('draft', 'approved');
  SELECT count(*) INTO v_probe FROM inform.compass_topic_revisions WHERE rationale = 'CA_0305 probe';
  IF v_probe <> 0 THEN RAISE EXCEPTION 'CA_0305: % probe revision(s) leaked', v_probe; END IF;
  IF EXISTS (SELECT 1 FROM information_schema.role_routine_grants
              WHERE routine_schema = 'inform' AND routine_name = 'repoint_season_answers'
                AND grantee IN ('anon', 'authenticated', 'PUBLIC')) THEN
    RAISE EXCEPTION 'CA_0305: repoint_season_answers is executable by anon/authenticated';
  END IF;
  RAISE NOTICE 'CA_0305: no probe revision leaked (% open revisions), grants are service_role only.', v_open;
END $$;

COMMIT;
