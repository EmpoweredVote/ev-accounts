-- CA_0315_school_police_s3_draft_c_revision.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-10-20.
--
-- =============================================================================
-- CA_0315: education-school-police — Season 3 working draft C (v2), approved
--          and pinned in the DRAFT Season 3
-- =============================================================================
-- Drafted 2026-10-20, offline, as the Stage 4 package of the Season 3 pilot for this
-- topic. Actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2 (Chris Andrews).
--
-- APPLIED to production 2026-10-20 on Chris Andrews' explicit go-ahead.
-- Revision 2 = 37728a13-d7c3-4173-b706-e54dd85804c1. At that time 0 of 10 T4 blind labels
-- (Gold Desk t4polc-01 … t4polc-10, bar >= 9 of 10) were in; he approved with T4 still open,
-- as for education-library-books (CA_0310) and education-equity-programs (CA_0314).
-- Dry run on prod 2026-10-20 inside BEGIN … ROLLBACK: gate OK, idempotent double run OK
-- (second run skips propose/approve), voter answers 'reworded' x1, rollback confirmed (1 revision,
-- Season 3 still pins revision 1).
-- Pattern: CA_0314 (education-equity-programs, applied 2026-10-20) and CA_0310.
--
-- WHAT THIS DOES
--   1. Proposes revision 2 of education-school-police: change_class substantive,
--      so version 1 -> 2. NEW question text (ruling Q5, 2026-10-19) and NEW guidance;
--      title and short title UNCHANGED. Five rungs, ordered by how much police
--      presence schools have; the officer's role is off the ladder:
--        1  Remove police officers from all schools
--        2  Remove police officers from some schools
--        3  Fund or assign police officers to some schools
--        4  Place a police officer or armed security staff member in every school
--        5  Place a police officer in every school
--      Rung map (key = revision 1 rung): {"1":1,"2":1,"3":3,"4":5,"5":5}.
--   2. Sets the new guidance on the draft row (guidance is not a propose parameter;
--      the CC_0231 trigger would otherwise copy revision 1's line). guidance is outside
--      the immutable-content trigger.
--   3. Approves it and PARKS it (approved, NOT published, is_current stays on
--      revision 1). Season 2 is open and keeps serving revision 1.
--   4. Pins it into the draft Season 3 (7b3a066c-...). The pin is inert until
--      Season 3 opens; opening publishes pinned revisions (CA_0024).
--   Writes nothing to politician_answers, politician_context or compass_responses.
--
-- L1 POLES (rulebook L1, ruled 2026-10-08: stored internally, not shown to voters)
--   None pole:  No police officer is stationed in any school.
--   Every pole: A sworn police officer is placed in every school.
--   Stored as the first line of `rationale` ("L1 poles: ..."), reviewer-only.
--
-- EVIDENCE (Stage 3, codebook 0.6; ~/Documents/GitHub/.planning/research/s3-pilot-school-police-stage3-c/
-- and -stage3-supp/results.md)
--   v1 set: Draft C 12 of 65 affirmative rows (revision 1: 0); T3 5 of 10, 0 inverted.
--   Supplement census: 48 of 64 (75%) after U1. Pooled ungated (Q6): 60 of 99 (61%);
--   all rows 60 of 129 (47%). T6 lint 0. Rungs 1, 2, 4 untested.
--
-- SEAT COST (T5)
--   0 politician seats in any season (read 2026-10-20: 0 politician_answers,
--   0 politician_context, 0 stance_research_review rows for this topic).
--   1 live voter answer (Season 2, value 1.0, on revision 1). Season 2 is not touched.
--   When Season 3 opens, rung 1 maps to 1 and its neighbour rung 2 changes ->
--   compass_answer_disposition = 'reworded' (CC_0061): the answer is kept.
--
-- 🔴 DO NOT PUSH `--season draft` RESEARCH FOR THIS TOPIC BEFORE THIS IS APPLIED.
-- Rows written earlier would pin revision 1 in Season 3 (the precondition below refuses).
--
-- 🔴 ANNEX. docs/codebook/annex/education-school-police.md stays the Season 2 annex; its
-- "Season 3 draft — Draft C" section moves to docs/codebook/annex/season3/education-school-police.md
-- in the same PR. build-coder-inputs.ts reads season3/ for --season draft bundles (#1031).
--
-- Idempotent: steps are guarded on the rung-4 text of revision 2 (new in this
-- revision); a re-run is a no-op and the gate still asserts the full shape.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id = '15d7e730-119b-43a2-a351-1efb7352b86b' AND topic_key = 'education-school-police') THEN
    RAISE EXCEPTION 'CA_0315 precondition: education-school-police topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND number = 3 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0315 precondition: Season 3 is not a draft (its pins would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND number = 2 AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0315 precondition: Season 2 is not the open season';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = 'd81d7662-3c68-425c-a5c6-ca0717384a9e' AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0315 precondition: revision 1 is not the current published revision';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.politician_answers
              WHERE topic_id = '15d7e730-119b-43a2-a351-1efb7352b86b'
                AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075') THEN
    RAISE EXCEPTION 'CA_0315 precondition: Season 3 already holds politician answers for this topic';
  END IF;
END $$;

-- ── 1. Lifecycle: propose revision 2 → set guidance → approve (park) → pin in Season 3 ──────────
DO $$
DECLARE
  v_actor     CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key       CONSTANT text := 'education-school-police';
  v_topic     CONSTANT uuid := '15d7e730-119b-43a2-a351-1efb7352b86b';
  v_s3        CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_rung4_new CONSTANT text := 'Place a police officer or armed security staff member in every school';
  v_guidance  CONSTANT text := 'Whether schools should have no police officers, officers at some schools, or an officer at every school.';
  v_open      uuid;
  v_rev2      uuid;
BEGIN
  IF EXISTS (
    SELECT 1 FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 4
    WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
      AND r.status IN ('approved','published') AND s.text = v_rung4_new
  ) THEN
    RAISE NOTICE 'CA_0315: approved revision 2 already present — skipping propose/approve.';
  ELSE
    SELECT id INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0315: topic already has an open revision % — resolve it first', v_open;
    END IF;

    v_rev2 := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      'Police in Schools', 'Police in Schools',
      'Should schools have police officers on campus?',
      $stances$[
        {"value":1,"text":"Remove police officers from all schools"},
        {"value":2,"text":"Remove police officers from some schools"},
        {"value":3,"text":"Fund or assign police officers to some schools"},
        {"value":4,"text":"Place a police officer or armed security staff member in every school"},
        {"value":5,"text":"Place a police officer in every school"}
      ]$stances$::jsonb,
      $rat$L1 poles: none = "No police officer is stationed in any school"; every = "A sworn police officer is placed in every school".
Season 3 pilot, working draft C (ruled W1 2026-10-16). The rungs order how much police presence schools have: remove from all schools (1), remove from some (2), fund or assign to some (3), police or armed security staff in every school (4), police in every school (5). The officer's role (discipline, arrests, use of force) is not on the ladder. Revision 1 failed rulebook L1 (no poles), L4 (degree words) and L6 ("and"-compounds), and mixed coverage with role (L2); its T6 lint had 8 hits, Draft C has 0. No nested rung, no rung read from silence.
Rung map: 1->1 (same position; counselor clause dropped), 2->1 (no officer stationed; the call-for-crime clause is role), 3->3 (some schools; role dropped), 4->5 and 5->5 (police in every school; role clauses dropped). Rungs 2 and 4 are new.
Stage 3 (codebook 0.6). Frozen v1 set (65 affirmative rows, 30 gated before wording): Draft C seats 12 (18%), revision 1 seats 0; T3 5 of 10 pairs kept, 0 inverted (Drafts A/B 2 of 10); validation 22 of 25. Supplement census (64 affirmative rows, no gate): 48 (75%) after ruling U1; validation 23 of 23. Pooled T1 judged on ungated rows (Q6): 60 of 99 (61%); all rows 60 of 129 (47%). Seats fall on rungs 3 and 5 only; rungs 1, 2 and 4 are untested (no removal vote, no own-choice every-school record in either set).
Rulings (Chris Andrews): 2026-10-16 Draft C Q1-Q8, Stage 3-C R1-R3 (Texas reassignment compliance; a grant funding an existing every-school duty is not "some schools"; penalty posting direction-only), U1 (menu duty: police chosen for named schools -> 3), W1 (Draft C forward); 2026-10-19 S1 (Virginia MOU statute is not an officer duty), S3 (WI AB 69 crime-triggered posting -> 3), Q5 (new question), Q6 (T1 on ungated rows).
T5: 0 politician seats in any season; 1 Season 2 voter answer (value 1), disposition 'reworded' at Season 3 open (kept). T4: 10 Gold Desk items (t4polc-01 to t4polc-10) unlabelled at drafting; approval is gated on T4 (>= 9 of 10).$rat$,
      $pub$This question now asks whether schools should have police officers on campus, with options from removing them from all schools to placing one in every school. The old question mixed two different things: how many schools have officers, and what officers may do there. Most school and state actions decide only the first, so they matched only part of an option. What officers may do is no longer part of this question. The new options each name one action.$pub$,
      'Season 3 pilot education-school-police: Draft C and rulings Q1-Q8 2026-10-16 (.planning/research/s3-pilot-school-police-stage2/draft-c.md); Stage 3-C results and rulings R1-R3 (s3-pilot-school-police-stage3-c/results.md); Stage 3-supp results and rulings U1, W1, S1, S3, Q5, Q6 (s3-pilot-school-police-stage3-supp/results.md); Stage 4 package (s3-pilot-school-police-stage4/)',
      '{"1":1,"2":1,"3":3,"4":5,"5":5}'::jsonb
    );

    UPDATE inform.compass_topic_revisions SET guidance = v_guidance
     WHERE id = v_rev2 AND status = 'draft';
    IF NOT FOUND THEN RAISE EXCEPTION 'CA_0315: could not set guidance on draft revision %', v_rev2; END IF;

    PERFORM inform.admin_approve_topic_revision(v_rev2, v_actor);  -- approve, NOT publish (park for Season 3)
    RAISE NOTICE 'CA_0315: proposed + approved (parked) substantive revision 2 %', v_rev2;
  END IF;

  SELECT r.id INTO v_rev2 FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 4
   WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
     AND r.status IN ('approved','published') AND s.text = v_rung4_new
   ORDER BY r.revision DESC LIMIT 1;
  IF v_rev2 IS NULL THEN
    RAISE EXCEPTION 'CA_0315: could not locate the approved revision 2 to pin';
  END IF;
  PERFORM inform.admin_season_pin_revision(v_s3, v_topic, v_rev2, v_actor);
  RAISE NOTICE 'CA_0315: Season 3 pinned to revision 2 %', v_rev2;
END $$;

-- ── 2. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic  CONSTANT uuid := '15d7e730-119b-43a2-a351-1efb7352b86b';
  v_s2     CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_s3     CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_rev1   CONSTANT uuid := 'd81d7662-3c68-425c-a5c6-ca0717384a9e';
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
  JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 4
  WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
    AND s.text = 'Place a police officer or armed security staff member in every school'
  ORDER BY r.revision DESC LIMIT 1;

  IF v_rev2 IS NULL THEN RAISE EXCEPTION 'CA_0315 verify: revision 2 not found'; END IF;
  IF v_num <> 2 THEN RAISE EXCEPTION 'CA_0315 verify: revision number is % (expected 2)', v_num; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0315 verify: version is % (expected 2)', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION 'CA_0315 verify: status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION 'CA_0315 verify: revision 2 is is_current (Season 2 would drift)'; END IF;
  IF v_title <> 'Police in Schools' OR v_short <> 'Police in Schools' THEN
    RAISE EXCEPTION 'CA_0315 verify: title/short title changed: "%" / "%"', v_title, v_short;
  END IF;
  IF v_q <> 'Should schools have police officers on campus?' THEN
    RAISE EXCEPTION 'CA_0315 verify: question text is "%"', v_q;
  END IF;
  IF v_g IS DISTINCT FROM 'Whether schools should have no police officers, officers at some schools, or an officer at every school.' THEN
    RAISE EXCEPTION 'CA_0315 verify: guidance is "%" (revision 1''s line was inherited?)', v_g;
  END IF;
  IF v_rat NOT LIKE 'L1 poles: %' THEN RAISE EXCEPTION 'CA_0315 verify: rationale does not start with the L1 poles line'; END IF;
  IF v_map <> '{"1":1,"2":1,"3":3,"4":5,"5":5}'::jsonb THEN
    RAISE EXCEPTION 'CA_0315 verify: rung map is %', v_map;
  END IF;

  -- Exactly the five Draft C rungs, word for word.
  SELECT string_agg(format('%s<>%s', x.value, x.text), '; ') INTO v_bad
  FROM (VALUES
    (1, 'Remove police officers from all schools'),
    (2, 'Remove police officers from some schools'),
    (3, 'Fund or assign police officers to some schools'),
    (4, 'Place a police officer or armed security staff member in every school'),
    (5, 'Place a police officer in every school')
  ) AS x(value, text)
  WHERE NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                     WHERE s.topic_revision_id = v_rev2 AND s.value = x.value AND s.text = x.text);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CA_0315 verify: rung text mismatch: %', v_bad; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_rev2;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0315 verify: revision 2 has % rungs (expected 5)', v_n; END IF;

  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = v_rev1 AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0315 verify: revision 1 is no longer current/published';
  END IF;

  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_s2 AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_rev1 THEN RAISE EXCEPTION 'CA_0315 verify: Season 2 pin is % (expected revision 1)', v_pin; END IF;
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_s3 AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_rev2 THEN RAISE EXCEPTION 'CA_0315 verify: Season 3 pin is % (expected revision 2 %)', v_pin, v_rev2; END IF;

  -- Season sizes unchanged: a repin, not an add. (Counts read 2026-10-20; re-read before applying.)
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_s2;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0315 verify: Season 2 holds % questions (expected 60)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_s3;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0315 verify: Season 3 holds % questions (expected 60)', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_s3 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0315 verify: Season 3 is no longer a draft';
  END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE topic_id = v_topic;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0315 verify: % politician answers on this topic (expected 0)', v_n; END IF;

  -- What Season 3 opening will do to voter answers (report only; Season 2 is not touched).
  SELECT string_agg(d || ' x' || c, ', ') INTO v_disp FROM (
    SELECT inform.compass_answer_disposition(r.answered_revision_id, v_rev2, r.value) AS d, count(*) AS c
      FROM inform.compass_responses r
     WHERE r.topic_id = v_topic AND r.deleted_at IS NULL
     GROUP BY 1) z;
  RAISE NOTICE 'CA_0315: voter answers against revision 2 at Season 3 open: % (expected reworded x1 at drafting)', coalesce(v_disp, 'none');

  RAISE NOTICE 'CA_0315 post-verify OK: revision 2 % approved/parked (v2, is_current=false), Season 3 -> revision 2, Season 2 -> revision 1.', v_rev2;
END $$;

COMMIT;
