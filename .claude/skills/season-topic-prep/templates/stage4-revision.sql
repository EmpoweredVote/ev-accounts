-- {{SLOT}}_{{FILE_SUFFIX}}.sql
-- Author: {{AUTHOR}} ({{NAMESPACE}}_ namespace). Slot reserved from the steward allocator {{DATE}}.
--
-- =============================================================================
-- {{SLOT}}: {{TOPIC_KEY}} — Season {{SEASON_DRAFT_NUMBER}} revision {{REV_NUM}}, approved
--           and pinned in the DRAFT season
-- =============================================================================
-- Template: .claude/skills/season-topic-prep/templates/stage4-revision.sql (structure of CA_0314,
-- education-equity-programs, applied 2026-10-20). Fill every placeholder (a name in double curly
-- braces); a grep of the filled file for two opening curly braces must print nothing before the dry
-- run. Recipe: .claude/skills/season-topic-prep/STAGE4-RECIPE.md.
--
-- Drafted {{DATE}}, offline, as the Stage 4 package of the Season {{SEASON_DRAFT_NUMBER}} prep for this
-- topic. Actor {{ACTOR_ID}} ({{AUTHOR}}).
--
-- APPLIED: (fill in on apply — date, who said yes, revision id)
-- Dry run on prod {{DRY_RUN_DATE}} (body twice inside BEGIN, forced RAISE): (fill in — gate OK,
-- second run skipped propose/approve, voter-answer dispositions, rollback confirmed)
--
-- WHAT THIS DOES
--   1. Proposes revision {{REV_NUM}} of {{TOPIC_KEY}}: change_class {{CHANGE_CLASS}}, version {{VERSION}}.
--      Rungs:
--        1  {{RUNG_1}}
--        2  {{RUNG_2}}
--        3  {{RUNG_3}}
--        4  {{RUNG_4}}
--        5  {{RUNG_5}}
--      Rung map (key = the OLD rung of revision {{REV_PREV_ID}}; "invalidated" allowed): {{RUNG_MAP}}
--   2. Sets the new guidance on the draft row. guidance is NOT a propose parameter; the trigger would
--      otherwise copy the previous revision's line. guidance is outside the immutable-content trigger.
--   3. Approves it and PARKS it (approved, NOT published; is_current stays on the previous revision).
--      The open season keeps serving the previous revision.
--   4. Pins it into the draft season. The pin is inert until that season opens.
--   Writes nothing to politician_answers, politician_context or compass_responses.
--
-- L1 POLES (stored internally as the first line of rationale, not shown to voters)
--   {{POLE_1}}  <->  {{POLE_5}}
--
-- EVIDENCE: Stage 3 results ({{REVIEW_REF}}).
-- SEAT COST (T5): {{SEAT_COST}}
-- EXPERT REVIEW: owed, not done; {{EXPERT_QUEUE_COUNT}} seated rows queued in stage3/expert-queue.json.
--
-- 🔴 Do not push `--season draft` research for this topic before this is applied: rows written earlier
--    pin the previous revision in the draft season, and the precondition below refuses to re-pin.
-- 🔴 Season question counts in the gate ({{S2_COUNT}} open, {{S3_COUNT}} draft) were read on {{DATE}}.
--    RE-READ THEM just before the dry run and again before applying.
--
-- Idempotent: steps are guarded on revision number {{REV_NUM}} with the five new rung texts (on any
-- revision other than the previous one, so a clarifying revision with unchanged rungs works); a re-run
-- is a no-op and the gate still asserts the full shape.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id = '{{TOPIC_ID}}' AND topic_key = '{{TOPIC_KEY}}') THEN
    RAISE EXCEPTION '{{SLOT}} precondition: {{TOPIC_KEY}} topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '{{SEASON_DRAFT_ID}}' AND status = 'draft') THEN
    RAISE EXCEPTION '{{SLOT}} precondition: the target season is not a draft (its pins would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '{{SEASON_OPEN_ID}}' AND status = 'open') THEN
    RAISE EXCEPTION '{{SLOT}} precondition: {{SEASON_OPEN_ID}} is not the open season';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = '{{REV_PREV_ID}}' AND is_current AND status = 'published') THEN
    RAISE EXCEPTION '{{SLOT}} precondition: {{REV_PREV_ID}} is not the current published revision';
  END IF;
  -- A draft-season answer on this topic carries the previous revision in its pin key; re-pinning
  -- under it would strand the row. There must be none.
  IF EXISTS (SELECT 1 FROM inform.politician_answers
              WHERE topic_id = '{{TOPIC_ID}}' AND season_id = '{{SEASON_DRAFT_ID}}') THEN
    RAISE EXCEPTION '{{SLOT}} precondition: the draft season already holds politician answers for this topic';
  END IF;
END $$;

-- ── 1. Lifecycle: propose → set guidance → approve (park) → pin in the draft season ─────────────
DO $$
DECLARE
  v_actor    CONSTANT uuid := '{{ACTOR_ID}}';
  v_key      CONSTANT text := '{{TOPIC_KEY}}';
  v_topic    CONSTANT uuid := '{{TOPIC_ID}}';
  v_draft    CONSTANT uuid := '{{SEASON_DRAFT_ID}}';
  v_guidance CONSTANT text := $g${{GUIDANCE}}$g$;
  v_rungs    CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', $r1${{RUNG_1}}$r1$),
    jsonb_build_object('value', 2, 'text', $r2${{RUNG_2}}$r2$),
    jsonb_build_object('value', 3, 'text', $r3${{RUNG_3}}$r3$),
    jsonb_build_object('value', 4, 'text', $r4${{RUNG_4}}$r4$),
    jsonb_build_object('value', 5, 'text', $r5${{RUNG_5}}$r5$)
  );
  v_open     uuid;
  v_new      uuid;
BEGIN
  -- The new revision is the approved/published revision {{REV_NUM}} whose five rungs match these texts
  -- exactly. Requiring the number stops an older revision that happens to share the rung texts from
  -- being taken for it.
  SELECT r.id INTO v_new FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic AND r.id <> '{{REV_PREV_ID}}' AND r.revision = {{REV_NUM}}
     AND r.status IN ('approved','published')
     AND (SELECT count(*) FROM inform.compass_stance_revisions s
           JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
          WHERE s.topic_revision_id = r.id) = 5
   ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NOT NULL THEN
    RAISE NOTICE '{{SLOT}}: approved revision already present (%) — skipping propose/approve.', v_new;
  ELSE
    SELECT id INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open IS NOT NULL THEN
      RAISE EXCEPTION '{{SLOT}}: topic already has an open revision % — resolve it first', v_open;
    END IF;

    v_new := inform.admin_propose_topic_revision(
      v_key, v_actor, '{{CHANGE_CLASS}}',
      $t${{TITLE}}$t$, $st${{SHORT_TITLE}}$st$,
      $q${{QUESTION}}$q$,
      v_rungs,
      $rat${{RATIONALE}}$rat$,
      $pub${{PUBLIC_NOTE}}$pub$,
      $ref${{REVIEW_REF}}$ref$,
      '{{RUNG_MAP}}'::jsonb
    );

    -- guidance is not a propose parameter: set it on the draft row BEFORE approving.
    UPDATE inform.compass_topic_revisions SET guidance = v_guidance
     WHERE id = v_new AND status = 'draft';
    IF NOT FOUND THEN RAISE EXCEPTION '{{SLOT}}: could not set guidance on draft revision %', v_new; END IF;

    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);  -- approve, NOT publish (park)
    RAISE NOTICE '{{SLOT}}: proposed + approved (parked) {{CHANGE_CLASS}} revision %', v_new;
  END IF;

  PERFORM inform.admin_season_pin_revision(v_draft, v_topic, v_new, v_actor);
  RAISE NOTICE '{{SLOT}}: draft season pinned to revision %', v_new;
END $$;

-- ── 2. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic CONSTANT uuid := '{{TOPIC_ID}}';
  v_openS CONSTANT uuid := '{{SEASON_OPEN_ID}}';
  v_draft CONSTANT uuid := '{{SEASON_DRAFT_ID}}';
  v_prev  CONSTANT uuid := '{{REV_PREV_ID}}';
  v_rungs CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', $r1${{RUNG_1}}$r1$),
    jsonb_build_object('value', 2, 'text', $r2${{RUNG_2}}$r2$),
    jsonb_build_object('value', 3, 'text', $r3${{RUNG_3}}$r3$),
    jsonb_build_object('value', 4, 'text', $r4${{RUNG_4}}$r4$),
    jsonb_build_object('value', 5, 'text', $r5${{RUNG_5}}$r5$)
  );
  v_new   uuid;
  v_ver   int;
  v_num   int;
  v_stat  text;
  v_curr  boolean;
  v_title text;
  v_short text;
  v_q     text;
  v_g     text;
  v_rat   text;
  v_map   jsonb;
  v_n     int;
  v_pin   uuid;
  v_disp  text;
BEGIN
  SELECT r.id, r.version, r.revision, r.status::text, r.is_current, r.title, r.short_title,
         r.question_text, r.guidance, r.rationale, r.rung_map
    INTO v_new, v_ver, v_num, v_stat, v_curr, v_title, v_short, v_q, v_g, v_rat, v_map
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = v_topic AND r.id <> '{{REV_PREV_ID}}' AND r.revision = {{REV_NUM}}
    AND (SELECT count(*) FROM inform.compass_stance_revisions s
          JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
         WHERE s.topic_revision_id = r.id) = 5
  ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NULL THEN RAISE EXCEPTION '{{SLOT}} verify: new revision not found (rung text mismatch?)'; END IF;
  IF v_num <> {{REV_NUM}} THEN RAISE EXCEPTION '{{SLOT}} verify: revision number is % (expected {{REV_NUM}})', v_num; END IF;
  IF v_ver <> {{VERSION}} THEN RAISE EXCEPTION '{{SLOT}} verify: version is % (expected {{VERSION}})', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION '{{SLOT}} verify: status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION '{{SLOT}} verify: new revision is is_current (the open season would drift)'; END IF;
  IF v_title <> $t${{TITLE}}$t$ OR v_short <> $st${{SHORT_TITLE}}$st$ THEN
    RAISE EXCEPTION '{{SLOT}} verify: title/short title are "%" / "%"', v_title, v_short;
  END IF;
  IF v_q <> $q${{QUESTION}}$q$ THEN RAISE EXCEPTION '{{SLOT}} verify: question text is "%"', v_q; END IF;
  IF v_g IS DISTINCT FROM $g${{GUIDANCE}}$g$ THEN
    RAISE EXCEPTION '{{SLOT}} verify: guidance is "%" (the previous line was inherited?)', v_g;
  END IF;
  IF v_rat NOT LIKE 'L1 poles: %' THEN RAISE EXCEPTION '{{SLOT}} verify: rationale does not start with the L1 poles line'; END IF;
  IF v_map <> '{{RUNG_MAP}}'::jsonb THEN RAISE EXCEPTION '{{SLOT}} verify: rung map is %', v_map; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION '{{SLOT}} verify: new revision has % rungs (expected 5)', v_n; END IF;

  -- The previous revision is still the current published one (the open season is unaffected).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = v_prev AND is_current AND status = 'published') THEN
    RAISE EXCEPTION '{{SLOT}} verify: {{REV_PREV_ID}} is no longer current/published';
  END IF;

  -- The open season still pins the previous revision; the draft season pins the new one.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_openS AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_prev THEN RAISE EXCEPTION '{{SLOT}} verify: open-season pin is % (expected the previous revision)', v_pin; END IF;
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_draft AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_new THEN RAISE EXCEPTION '{{SLOT}} verify: draft-season pin is % (expected %)', v_pin, v_new; END IF;

  -- Season sizes unchanged: a re-pin, not an add. RE-READ these counts before the dry run and before
  -- applying: another season migration may have run since {{DATE}}.
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_openS;
  IF v_n <> {{S2_COUNT}} THEN RAISE EXCEPTION '{{SLOT}} verify: open season holds % questions (expected {{S2_COUNT}})', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_draft;
  IF v_n <> {{S3_COUNT}} THEN RAISE EXCEPTION '{{SLOT}} verify: draft season holds % questions (expected {{S3_COUNT}})', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_draft AND status = 'draft') THEN
    RAISE EXCEPTION '{{SLOT}} verify: the target season is no longer a draft';
  END IF;

  -- No answers written into the draft season by this migration.
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE topic_id = v_topic AND season_id = v_draft;
  IF v_n <> 0 THEN RAISE EXCEPTION '{{SLOT}} verify: % draft-season politician answers on this topic (expected 0)', v_n; END IF;

  -- What opening the draft season will do to voter answers (report only; the open season is not touched).
  SELECT string_agg(d || ' x' || c, ', ') INTO v_disp FROM (
    SELECT inform.compass_answer_disposition(r.answered_revision_id, v_new, r.value) AS d, count(*) AS c
      FROM inform.compass_responses r
     WHERE r.topic_id = v_topic AND r.deleted_at IS NULL
     GROUP BY 1) z;
  RAISE NOTICE '{{SLOT}}: voter answers against the new revision at season open: % (expected {{EXPECTED_DISPOSITIONS}})', coalesce(v_disp, 'none');

  RAISE NOTICE '{{SLOT}} post-verify OK: revision % approved/parked (v{{VERSION}}, is_current=false), draft season -> new, open season -> previous.', v_new;
END $$;

COMMIT;
