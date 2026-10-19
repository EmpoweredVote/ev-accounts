-- CA_0314_equity_programs_s3_draft_b_prime_revision.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-10-19.
--
-- =============================================================================
-- CA_0314: education-equity-programs — Season 3 working draft B′ (v2), approved
--          and pinned in the DRAFT Season 3
-- =============================================================================
-- Drafted 2026-10-19, offline, as the Stage 4 package of the Season 3 pilot for this
-- topic. NOT APPLIED. Actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2 (Chris Andrews).
-- Apply only on Chris Andrews' explicit go-ahead. T4 (Gold Desk t4eq-01 … t4eq-10,
-- bar >= 9 of 10) was unlabelled at drafting and should gate that go-ahead.
-- Pattern: CA_0310 (education-library-books, applied 2026-10-15).
-- Dry run on prod 2026-10-19 inside BEGIN … ROLLBACK: gate OK, idempotent double run OK
-- (second run skips propose/approve), voter answers 'moved' x2, rollback confirmed (1 revision,
-- Season 3 still pins revision 1).
--
-- WHAT THIS DOES
--   1. Proposes revision 2 of education-equity-programs: change_class substantive,
--      so version 1 -> 2. NEW question text (ruling Q2) and NEW guidance; title and
--      short title UNCHANGED. Five rungs, one act each ("the furthest act government
--      takes on equity programmes in K-12 schools"):
--        1  Require schools to have an equity office, committee or plan, or equity training for staff or board members
--        2  Set up or fund an equity office, officer, committee or plan, or equity training for staff or board members, in schools
--        3  Bar schools from requiring staff to take equity training
--        4  Replace equity offices or programs with supports open to every student
--        5  Close equity offices or ban equity programs in schools
--      Rung map (key = revision 1 rung): {"1":2,"2":1,"3":"invalidated","4":4,"5":5}.
--   2. Sets the new guidance on the draft row (guidance is not a propose parameter;
--      the CC_0231 trigger would otherwise copy revision 1's line, which asks about
--      targeting, not programmes). guidance is outside the immutable-content trigger.
--   3. Approves it and PARKS it (approved, NOT published, is_current stays on
--      revision 1). Season 2 is open and keeps serving revision 1.
--   4. Pins it into the draft Season 3 (7b3a066c-...). The pin is inert until
--      Season 3 opens; opening publishes pinned revisions (CA_0024).
--   Writes nothing to politician_answers, politician_context or compass_responses.
--
-- L1 POLES (rulebook L1, ruled 2026-10-08: stored internally, not shown to voters)
--   Require pole: Schools must run equity programs.
--   Ban pole:     Equity programs are banned in schools.
--   Stored as the first line of `rationale` ("L1 poles: ..."), reviewer-only.
--
-- EVIDENCE (Stage 3, 2026-10-19; ~/Documents/GitHub/.planning/research/s3-pilot-equity-programs/stage3/results.md)
--   Frozen v1 set, 44 affirmative-record rows, codebook 0.6. Drafts A and B tied at
--   33 of 44 (75%); revision 1 seats 0. B′ (after rulings R3, R4; exposed set):
--   39 of 44 (89%), T3 9 of 10, blind re-validation 13 of 13, T6 lint 0.
--   Rulings 2026-10-19 (Chris Andrews): Q2-Q5 (Stage 2), R1 (single-subject scope,
--   this topic), R2 (Draft B forward), R3 ("staff or board members"), R4 ("committee").
--
-- SEAT COST (T5)
--   0 politician seats in any season (read 2026-10-19: 0 politician_answers,
--   0 politician_context, 0 stance_research_review rows for this topic).
--   2 live voter answers (Season 2, both value 2.0, on revision 1). Season 2 is not
--   touched. When Season 3 opens, rung 2 maps to 1 -> compass_answer_disposition =
--   'moved' (CC_0061): the value is hidden and both voters are asked again.
--
-- 🔴 DO NOT PUSH `--season draft` RESEARCH FOR THIS TOPIC BEFORE THIS IS APPLIED.
-- Rows written earlier would pin revision 1 in Season 3 (the precondition below refuses).
--
-- 🔴 ANNEX. docs/codebook/annex/education-equity-programs.md stays the Season 2 annex.
-- The Season 3 annex is docs/codebook/annex/season3/education-equity-programs.md
-- (text in the Stage 4 folder). build-coder-inputs.ts does not read season3/ yet.
-- The codebook V4.1 topic-scoped line (ruling R1) ships in the same PR.
--
-- Idempotent: steps are guarded on the rung-3 text of revision 2 (new in this
-- revision); a re-run is a no-op and the gate still asserts the full shape.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id = '66b389c7-86fc-45e9-bf34-964bb747f27b' AND topic_key = 'education-equity-programs') THEN
    RAISE EXCEPTION 'CA_0314 precondition: education-equity-programs topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND number = 3 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0314 precondition: Season 3 is not a draft (its pins would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND number = 2 AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0314 precondition: Season 2 is not the open season';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = '23d87824-d25c-4b9a-8b13-fb2799d75661' AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0314 precondition: revision 1 is not the current published revision';
  END IF;
  -- A Season 3 answer on this topic would carry revision 1 in its pin key; repinning under it would
  -- strand the row. There must be none.
  IF EXISTS (SELECT 1 FROM inform.politician_answers
              WHERE topic_id = '66b389c7-86fc-45e9-bf34-964bb747f27b'
                AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075') THEN
    RAISE EXCEPTION 'CA_0314 precondition: Season 3 already holds politician answers for this topic';
  END IF;
END $$;

-- ── 1. Lifecycle: propose revision 2 → set guidance → approve (park) → pin in Season 3 ──────────
DO $$
DECLARE
  v_actor     CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key       CONSTANT text := 'education-equity-programs';
  v_topic     CONSTANT uuid := '66b389c7-86fc-45e9-bf34-964bb747f27b';
  v_s3        CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_rung3_new CONSTANT text := 'Bar schools from requiring staff to take equity training';
  v_guidance  CONSTANT text := 'Whether government should require, support, limit or end school programs aimed at equity, diversity and inclusion.';
  v_open      uuid;
  v_rev2      uuid;
BEGIN
  IF EXISTS (
    SELECT 1 FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 3
    WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
      AND r.status IN ('approved','published') AND s.text = v_rung3_new
  ) THEN
    RAISE NOTICE 'CA_0314: approved revision 2 already present — skipping propose/approve.';
  ELSE
    SELECT id INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0314: topic already has an open revision % — resolve it first', v_open;
    END IF;

    v_rev2 := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      'Equity and Inclusion Programs in Schools', 'School Equity Programs',
      'What should schools do about equity programs, such as equity offices, plans and staff training?',
      $stances$[
        {"value":1,"text":"Require schools to have an equity office, committee or plan, or equity training for staff or board members"},
        {"value":2,"text":"Set up or fund an equity office, officer, committee or plan, or equity training for staff or board members, in schools"},
        {"value":3,"text":"Bar schools from requiring staff to take equity training"},
        {"value":4,"text":"Replace equity offices or programs with supports open to every student"},
        {"value":5,"text":"Close equity offices or ban equity programs in schools"}
      ]$stances$::jsonb,
      $rat$L1 poles: require = "Schools must run equity programs"; ban = "Equity programs are banned in schools".
Season 3 pilot, working draft B′ (Draft B with rulings R1, R3, R4 of 2026-10-19). Each rung names the furthest act government takes on equity programmes in K-12 schools: require (1), set up or fund (2), bar required training (3), replace with supports open to every student (4), close or ban (5). Revision 1 failed rulebook L1 (no poles), L2 (programmes on rungs 1, 2, 5; targeting on rungs 3, 4), L5 (rung 4 "without"), L6 (and-compounds on all five rungs) and L8 (rung 5 "the district"); its T6 lint had 6 hits, B′ has 0. Targeting rules leave the ladder as adjacent (Q2), with a new question.
Rung map: 1->2 (funding an office is now "set up or fund"), 2->1 (the training mandate; goals dropped), 3 invalidated (targeting is adjacent), 4->4 (same position, stated as a replacement), 5->5. Rung 3 (bar on required training) is new.
Stage 3 (frozen v1 set, 68 rows, 44 affirmative-record rows; codebook 0.6): Drafts A and B tied at 33 of 44 (75%) and gave the same chair on every row; revision 1 seated 0. Draft B′ on the same, now exposed, set: 39 of 44 (89%; school 11 of 16, state 28 of 28), T3 9 of 10 pairs kept (1 unscorable, 0 inverted), blind re-validation 13 of 13, T6 lint 0.
Rulings 2026-10-19 (Chris Andrews): Q2 new question; Q3 + R1 a separate operative part makes a bill multi-subject only when it acts outside K-12 schools (colleges' or state agencies' own operations, other employers); Q4 hiring rules adjacent; Q5 furthest act; R2 Draft B forward (test tie, design grounds: it keeps revision 1's voter position on rung 4); R3 rungs 1-2 say "staff or board members"; R4 rung 1 names "committee".
T5: 0 politician seats in any season; 2 Season 2 voter answers (both value 2), disposition 'moved' at Season 3 open (hidden and re-asked). T4: 10 Gold Desk items (t4eq-01 to t4eq-10) unlabelled at drafting; approval is gated on T4 (>= 9 of 10).$rat$,
      $pub$This question now asks what schools should do about equity programs, such as equity offices, committees, plans and staff training, with options from requiring them to banning them. The old question mixed two different things: equity programs, and how extra support is aimed at groups of students. Because of that, most school and state actions matched only part of an option. The new options each name one action. If you answered the old question, you will be asked again.$pub$,
      'Season 3 pilot education-equity-programs: Stage 3 results and rulings R1-R5 2026-10-19 (.planning/research/s3-pilot-equity-programs/stage3/results.md); working draft B′ (stage3/draft-b-prime.md); Stage 2 drafts and rulings Q1-Q7 (stage2/drafts.md sections 1, 3, 7); Stage 4 package (stage4/)',
      '{"1":2,"2":1,"3":"invalidated","4":4,"5":5}'::jsonb
    );

    UPDATE inform.compass_topic_revisions SET guidance = v_guidance
     WHERE id = v_rev2 AND status = 'draft';
    IF NOT FOUND THEN RAISE EXCEPTION 'CA_0314: could not set guidance on draft revision %', v_rev2; END IF;

    PERFORM inform.admin_approve_topic_revision(v_rev2, v_actor);  -- approve, NOT publish (park for Season 3)
    RAISE NOTICE 'CA_0314: proposed + approved (parked) substantive revision 2 %', v_rev2;
  END IF;

  SELECT r.id INTO v_rev2 FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 3
   WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
     AND r.status IN ('approved','published') AND s.text = v_rung3_new
   ORDER BY r.revision DESC LIMIT 1;
  IF v_rev2 IS NULL THEN
    RAISE EXCEPTION 'CA_0314: could not locate the approved revision 2 to pin';
  END IF;
  PERFORM inform.admin_season_pin_revision(v_s3, v_topic, v_rev2, v_actor);
  RAISE NOTICE 'CA_0314: Season 3 pinned to revision 2 %', v_rev2;
END $$;

-- ── 2. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic  CONSTANT uuid := '66b389c7-86fc-45e9-bf34-964bb747f27b';
  v_s2     CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_s3     CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_rev1   CONSTANT uuid := '23d87824-d25c-4b9a-8b13-fb2799d75661';
  v_rev2   uuid;
  v_ver    int;
  v_num    int;
  v_stat   text;
  v_curr   boolean;
  v_title  text;
  v_short  text;
  v_q      text;
  v_g      text;
  v_rat    text;
  v_map    jsonb;
  v_n      int;
  v_pin    uuid;
  v_bad    text;
  v_disp   text;
BEGIN
  SELECT r.id, r.version, r.revision, r.status::text, r.is_current, r.title, r.short_title,
         r.question_text, r.guidance, r.rationale, r.rung_map
    INTO v_rev2, v_ver, v_num, v_stat, v_curr, v_title, v_short, v_q, v_g, v_rat, v_map
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 3
  WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
    AND s.text = 'Bar schools from requiring staff to take equity training'
  ORDER BY r.revision DESC LIMIT 1;

  IF v_rev2 IS NULL THEN RAISE EXCEPTION 'CA_0314 verify: revision 2 not found'; END IF;
  IF v_num <> 2 THEN RAISE EXCEPTION 'CA_0314 verify: revision number is % (expected 2)', v_num; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0314 verify: version is % (expected 2)', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION 'CA_0314 verify: status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION 'CA_0314 verify: revision 2 is is_current (Season 2 would drift)'; END IF;
  IF v_title <> 'Equity and Inclusion Programs in Schools' OR v_short <> 'School Equity Programs' THEN
    RAISE EXCEPTION 'CA_0314 verify: title/short title changed: "%" / "%"', v_title, v_short;
  END IF;
  IF v_q <> 'What should schools do about equity programs, such as equity offices, plans and staff training?' THEN
    RAISE EXCEPTION 'CA_0314 verify: question text is "%"', v_q;
  END IF;
  IF v_g IS DISTINCT FROM 'Whether government should require, support, limit or end school programs aimed at equity, diversity and inclusion.' THEN
    RAISE EXCEPTION 'CA_0314 verify: guidance is "%" (revision 1''s line was inherited?)', v_g;
  END IF;
  IF v_rat NOT LIKE 'L1 poles: %' THEN RAISE EXCEPTION 'CA_0314 verify: rationale does not start with the L1 poles line'; END IF;
  IF v_map <> '{"1":2,"2":1,"3":"invalidated","4":4,"5":5}'::jsonb THEN
    RAISE EXCEPTION 'CA_0314 verify: rung map is %', v_map;
  END IF;

  -- Exactly the five B′ rungs, word for word.
  SELECT string_agg(format('%s<>%s', x.value, x.text), '; ') INTO v_bad
  FROM (VALUES
    (1, 'Require schools to have an equity office, committee or plan, or equity training for staff or board members'),
    (2, 'Set up or fund an equity office, officer, committee or plan, or equity training for staff or board members, in schools'),
    (3, 'Bar schools from requiring staff to take equity training'),
    (4, 'Replace equity offices or programs with supports open to every student'),
    (5, 'Close equity offices or ban equity programs in schools')
  ) AS x(value, text)
  WHERE NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                     WHERE s.topic_revision_id = v_rev2 AND s.value = x.value AND s.text = x.text);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CA_0314 verify: rung text mismatch: %', v_bad; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_rev2;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0314 verify: revision 2 has % rungs (expected 5)', v_n; END IF;

  -- Revision 1 is still the current published revision (Season 2 unaffected).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = v_rev1 AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0314 verify: revision 1 is no longer current/published';
  END IF;

  -- Season 2 (open) still pins revision 1; Season 3 (draft) pins revision 2.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_s2 AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_rev1 THEN RAISE EXCEPTION 'CA_0314 verify: Season 2 pin is % (expected revision 1)', v_pin; END IF;
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_s3 AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_rev2 THEN RAISE EXCEPTION 'CA_0314 verify: Season 3 pin is % (expected revision 2 %)', v_pin, v_rev2; END IF;

  -- Season sizes unchanged: a repin, not an add. (Counts read 2026-10-19; re-read before applying —
  -- another Season 3 migration may have run since.)
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_s2;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0314 verify: Season 2 holds % questions (expected 60)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_s3;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0314 verify: Season 3 holds % questions (expected 60)', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_s3 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0314 verify: Season 3 is no longer a draft';
  END IF;

  -- No answers written by this migration.
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE topic_id = v_topic;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0314 verify: % politician answers on this topic (expected 0)', v_n; END IF;

  -- What Season 3 opening will do to voter answers (report only; Season 2 is not touched).
  SELECT string_agg(d || ' x' || c, ', ') INTO v_disp FROM (
    SELECT inform.compass_answer_disposition(r.answered_revision_id, v_rev2, r.value) AS d, count(*) AS c
      FROM inform.compass_responses r
     WHERE r.topic_id = v_topic AND r.deleted_at IS NULL
     GROUP BY 1) z;
  RAISE NOTICE 'CA_0314: voter answers against revision 2 at Season 3 open: % (expected moved x2 at drafting)', coalesce(v_disp, 'none');

  RAISE NOTICE 'CA_0314 post-verify OK: revision 2 % approved/parked (v2, is_current=false), Season 3 -> revision 2, Season 2 -> revision 1.', v_rev2;
END $$;

COMMIT;
