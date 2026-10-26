-- CA_0334_voting_rights_s3_draft_f_revision.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-10-26.
--
-- =============================================================================
-- CA_0334: voting-rights — Season 3 revision 5, approved
--           and pinned in the DRAFT season
-- =============================================================================
-- Template: .claude/skills/season-topic-prep/templates/stage4-revision.sql (structure of CA_0314,
-- education-equity-programs, applied 2026-10-20). Fill every placeholder (a name in double curly
-- braces); a grep of the filled file for two opening curly braces must print nothing before the dry
-- run. Recipe: .claude/skills/season-topic-prep/STAGE4-RECIPE.md.
--
-- Drafted 2026-10-26, offline, as the Stage 4 package of the Season 3 prep for this
-- topic. Actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2 (Chris Andrews).
--
-- APPLIED: (fill in on apply — date, who said yes, revision id)
-- Dry run on prod (not yet run) (body twice inside BEGIN, forced RAISE): (fill in — gate OK,
-- second run skipped propose/approve, voter-answer dispositions, rollback confirmed)
--
-- WHAT THIS DOES
--   1. Proposes revision 5 of voting-rights: change_class substantive, version 3.
--      Rungs:
--        1  Require no proof of identity to cast a ballot.
--        2  Accept non-photo documents, such as a utility bill or bank statement, as ID to cast a ballot.
--        3  Require photo ID to cast a ballot, with a sworn statement for a voter who has none.
--        4  Require ID before a ballot counts: photo ID at the polls, or an ID number or a copy of an ID with each mail ballot.
--        5  Require a document that proves citizenship, such as a passport, birth certificate or naturalization papers, to register to vote or to cast a ballot.
--      Rung map (key = the OLD rung of revision 2a18c152-67a0-4380-a381-cb8795110a7c; "invalidated" allowed): {"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}
--   2. Sets the new guidance on the draft row. guidance is NOT a propose parameter; the trigger would
--      otherwise copy the previous revision's line. guidance is outside the immutable-content trigger.
--   3. Approves it and PARKS it (approved, NOT published; is_current stays on the previous revision).
--      The open season keeps serving the previous revision.
--   4. Pins it into the draft season. The pin is inert until that season opens.
--   0. (Before 1) REJECTS revision 4 (08e7026f-8eb5-4386-9288-f1dbfc3185c3), the approved but never-published Draft C wording this
--      revision replaces (RULINGS.md, Stage 4: a draft that replaces an approved, unpublished revision is measured
--      from the current published revision, and the approved one is rejected in the same migration).
--   4b. CARRIES the 57 draft-season answer and context rows on this topic from revision 4 to the new revision,
--      unchanged (ruled 2026-10-26, Chris Andrews, package question P2: Stage 3 found 0 of 57 move). The composite
--      pin keys (politician_answers_pin_fkey, politician_context_pin_fkey) do not cascade, so they are dropped,
--      the season is re-pinned, the rows are re-pointed, and the keys are re-added (which re-checks every row),
--      all inside this one transaction. No value, reasoning or evidence row changes; compass_responses untouched.
--
-- L1 POLES (stored internally as the first line of rationale, not shown to voters)
--   No proof of identity with the ballot  <->  A document that proves citizenship, such as a passport, birth certificate or naturalization papers
--
-- EVIDENCE: Stage 3 results (~/Documents/GitHub/.planning/research/s3-prep-voting-rights/ (local): stage3-fg/results.md, stage3-fg/disputes-F.md, stage2/drafts-fg.md, stage4-f/).
-- SEAT COST (T5): Season 3 draft: 57 seated rows carried unchanged from revision 4 to revision 5 (Stage 3: 0 of 57 move). Season 2: 7 seats, 6 carry per stage4/reaudit/carry.json (same acts as revision 4). Voter answers: 6 rows (4 given on revision 1, 2 on revision 3), identity map
-- EXPERT REVIEW: owed, not done; 62 seated rows queued in stage3/expert-queue.json.
--
-- 🔴 Do not push `--season draft` research for this topic before this is applied: rows written earlier
--    pin the previous revision in the draft season, and the precondition below refuses to re-pin.
-- 🔴 Season question counts in the gate (60 open, 60 draft) were read on 2026-10-26.
--    RE-READ THEM just before the dry run and again before applying.
--
-- Idempotent: steps are guarded on revision number 5 with the five new rung texts (on any
-- revision other than the previous one, so a clarifying revision with unchanged rungs works); a re-run
-- is a no-op and the gate still asserts the full shape.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND topic_key = 'voting-rights') THEN
    RAISE EXCEPTION 'CA_0334 precondition: voting-rights topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0334 precondition: the target season is not a draft (its pins would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0334 precondition: 86d893a1-c1a2-4bbf-b4e5-69ec43221194 is not the open season';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = '2a18c152-67a0-4380-a381-cb8795110a7c' AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0334 precondition: 2a18c152-67a0-4380-a381-cb8795110a7c is not the current published revision';
  END IF;
  -- The 57 draft-season rows on this topic are carried, not refused (P2). They must cite revision 4 or, on a
  -- re-run, the new revision, and number exactly 57.
  IF (SELECT count(*) FROM inform.politician_answers
       WHERE topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075') <> 57 THEN
    RAISE EXCEPTION 'CA_0334 precondition: expected 57 draft-season answers on this topic (re-measure; the carry was ruled on 57)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = '08e7026f-8eb5-4386-9288-f1dbfc3185c3' AND status IN ('approved','rejected')) THEN
    RAISE EXCEPTION 'CA_0334 precondition: revision 4 is neither approved nor already rejected';
  END IF;
END $$;

CREATE TEMP TABLE IF NOT EXISTS slot_pre_answers ON COMMIT DROP AS
  SELECT politician_id, value FROM inform.politician_answers
   WHERE topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075';

-- ── 0b. Reject revision 4 (approved, pinned, never published) ───────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '08e7026f-8eb5-4386-9288-f1dbfc3185c3' AND status = 'approved') THEN
    PERFORM inform.admin_reject_topic_revision('08e7026f-8eb5-4386-9288-f1dbfc3185c3', '854fbc06-40fc-458d-b523-20ef8e5ad1b2',
      'Replaced before Season 3 opened by revision 5 (Draft F): same acts, clearer wording on registering vs casting a ballot. Stage 3 2026-10-26.');
    RAISE NOTICE 'CA_0334: revision 4 rejected';
  ELSE
    RAISE NOTICE 'CA_0334: revision 4 already rejected — skipping';
  END IF;
END $$;

-- ── 1. Lifecycle: propose → set guidance → approve (park) → pin in the draft season ─────────────
DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'voting-rights';
  v_topic    CONSTANT uuid := 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  v_draft    CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_guidance CONSTANT text := $g$Options 1 to 4 are about what a voter shows with a ballot, in person or by mail. Option 5 is about proving citizenship, usually when registering: choose it if you want that, whatever you want at the ballot. Federal law already requires anyone registering to vote to give a driver's license or Social Security number, if they have one. The trade-off: ineligible votes cast, or eligible voters turned away.$g$;
  v_rungs    CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', $r1$Require no proof of identity to cast a ballot.$r1$),
    jsonb_build_object('value', 2, 'text', $r2$Accept non-photo documents, such as a utility bill or bank statement, as ID to cast a ballot.$r2$),
    jsonb_build_object('value', 3, 'text', $r3$Require photo ID to cast a ballot, with a sworn statement for a voter who has none.$r3$),
    jsonb_build_object('value', 4, 'text', $r4$Require ID before a ballot counts: photo ID at the polls, or an ID number or a copy of an ID with each mail ballot.$r4$),
    jsonb_build_object('value', 5, 'text', $r5$Require a document that proves citizenship, such as a passport, birth certificate or naturalization papers, to register to vote or to cast a ballot.$r5$)
  );
  v_open     uuid;
  v_new      uuid;
BEGIN
  -- The new revision is the approved/published revision 5 whose five rungs match these texts
  -- exactly. Requiring the number stops an older revision that happens to share the rung texts from
  -- being taken for it.
  SELECT r.id INTO v_new FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic AND r.id <> '2a18c152-67a0-4380-a381-cb8795110a7c' AND r.revision = 5
     AND r.status IN ('approved','published')
     AND (SELECT count(*) FROM inform.compass_stance_revisions s
           JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
          WHERE s.topic_revision_id = r.id) = 5
   ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NOT NULL THEN
    RAISE NOTICE 'CA_0334: approved revision already present (%) — skipping propose/approve.', v_new;
  ELSE
    SELECT id INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0334: topic already has an open revision % — resolve it first', v_open;
    END IF;

    v_new := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      $t$Voting Rights and Electoral Integrity$t$, $st$Voting Rights$st$,
      $q$What proof of identity or citizenship should a person have to show to cast a ballot or to register to vote?$q$,
      v_rungs,
      $rat$L1 poles: none = "No proof of identity with the ballot"; citizenship = "A document that proves citizenship, such as a passport, birth certificate or naturalization papers". Axis: how much proof a person must show before their vote counts: proof of identity with the ballot, then proof of citizenship.
Season 3 rewrite of revision 3 (Season 2). It replaces revision 4 (Draft C, approved 2026-10-21, never published), keeping every act revision 4 named and changing only the words, after the Stage 5 early check and a voter-reading review found that registration appeared only at rung 5, so a voter could not tell whether rung 1 meant registering, voting or both. Rungs 1–3 now say "to cast a ballot"; rung 5 names the documents and both points ("to register to vote or to cast a ballot"); the guidance says which options cover the ballot and which registering. Each rung names one kind of act a law states: 1 ends every proof-of-identity rule for casting a ballot; 2 accepts non-photo documents on their own; 3 requires photo ID with a sworn-statement path open to any voter without it; 4 makes ID a condition of the ballot counting with no sworn substitute, at the polls or by mail; 5 requires a document proving citizenship to register or to vote.
Rung map from revision 3: identity (1->1 ... 5->5), as revision 4's.
Stage 3 (2026-10-26) on the frozen set of 129 items: T1 54/62 = 87.1% of affirmative records, identical to revision 4, no regression; T3 10/10 pre-registered order pairs; T6 0 lint hits; blind validation 32/32; a new voter-placement test (T7: three voters per ladder, ten views) put 25/30 voters on the intended option (revision 4: 19/30); Draft G, a "proof at how many points" ladder, was tested and failed the pre-registered winner rule (rung 4 empty; one order failure). Re-code of the Stage 5 early-check sample (221 people with on-topic evidence): every revision-4 seat holds on the same rung (105 seated). Rulings: F-Q2 (citizenship documents to register sit on 5 whatever ballot rule is stated beside them), the registration-ID-number floor, named documents read as examples (D6 kept), DF1 (KY SB 2 stays at 3), SS-HB958 (NC HB 958 multi-subject).
Expert review is owed: 62 seated rows that rest on a bill or ordinance are queued (stage3/expert-queue.json; the Draft F chairs equal Draft C's); disputes ruled: 1 (DF1).$rat$,
      $pub$This question now says plainly which options are about showing ID when you vote and which are about proving citizenship when you register. Options 1 to 4 cover what a voter shows with a ballot, in person or by mail; option 5 covers proving citizenship, usually at registration. The positions themselves are the same as before. If you answered this question before, your answer is kept on the matching option; please check that it still describes your view.$pub$,
      $ref$~/Documents/GitHub/.planning/research/s3-prep-voting-rights/ (local): stage3-fg/results.md, stage3-fg/disputes-F.md, stage2/drafts-fg.md, stage4-f/$ref$,
      '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb
    );

    -- guidance is not a propose parameter: set it on the draft row BEFORE approving.
    UPDATE inform.compass_topic_revisions SET guidance = v_guidance
     WHERE id = v_new AND status = 'draft';
    IF NOT FOUND THEN RAISE EXCEPTION 'CA_0334: could not set guidance on draft revision %', v_new; END IF;

    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);  -- approve, NOT publish (park)
    RAISE NOTICE 'CA_0334: proposed + approved (parked) substantive revision %', v_new;
  END IF;

END $$;

-- ── 1b. Carry the 57 draft-season rows to the new revision (P2) ─────────────────────────────────
ALTER TABLE inform.politician_answers DROP CONSTRAINT IF EXISTS politician_answers_pin_fkey;
ALTER TABLE inform.politician_context DROP CONSTRAINT IF EXISTS politician_context_pin_fkey;
DO $$
DECLARE
  v_actor CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_topic CONSTANT uuid := 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  v_draft CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_rev4  CONSTANT uuid := '08e7026f-8eb5-4386-9288-f1dbfc3185c3';
  v_new   uuid;
  v_a     int;
  v_c     int;
BEGIN
  SELECT r.id INTO v_new FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic AND r.revision = 5 AND r.status = 'approved';
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0334 carry: approved revision 5 not found'; END IF;
  PERFORM inform.admin_season_pin_revision(v_draft, v_topic, v_new, v_actor);
  UPDATE inform.politician_answers SET topic_revision_id = v_new
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_rev4;
  GET DIAGNOSTICS v_a = ROW_COUNT;
  UPDATE inform.politician_context SET topic_revision_id = v_new
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_rev4;
  GET DIAGNOSTICS v_c = ROW_COUNT;
  RAISE NOTICE 'CA_0334: draft season pinned to revision %; carried % answer and % context row(s)', v_new, v_a, v_c;
END $$;
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_pin_fkey
  FOREIGN KEY (season_id, topic_id, topic_revision_id)
  REFERENCES inform.season_questions (season_id, topic_id, topic_revision_id);
ALTER TABLE inform.politician_context
  ADD CONSTRAINT politician_context_pin_fkey
  FOREIGN KEY (season_id, topic_id, topic_revision_id)
  REFERENCES inform.season_questions (season_id, topic_id, topic_revision_id);

-- ── 2. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic CONSTANT uuid := 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  v_openS CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_draft CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_prev  CONSTANT uuid := '2a18c152-67a0-4380-a381-cb8795110a7c';
  v_rungs CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', $r1$Require no proof of identity to cast a ballot.$r1$),
    jsonb_build_object('value', 2, 'text', $r2$Accept non-photo documents, such as a utility bill or bank statement, as ID to cast a ballot.$r2$),
    jsonb_build_object('value', 3, 'text', $r3$Require photo ID to cast a ballot, with a sworn statement for a voter who has none.$r3$),
    jsonb_build_object('value', 4, 'text', $r4$Require ID before a ballot counts: photo ID at the polls, or an ID number or a copy of an ID with each mail ballot.$r4$),
    jsonb_build_object('value', 5, 'text', $r5$Require a document that proves citizenship, such as a passport, birth certificate or naturalization papers, to register to vote or to cast a ballot.$r5$)
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
  WHERE r.topic_id = v_topic AND r.id <> '2a18c152-67a0-4380-a381-cb8795110a7c' AND r.revision = 5
    AND (SELECT count(*) FROM inform.compass_stance_revisions s
          JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
         WHERE s.topic_revision_id = r.id) = 5
  ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0334 verify: new revision not found (rung text mismatch?)'; END IF;
  IF v_num <> 5 THEN RAISE EXCEPTION 'CA_0334 verify: revision number is % (expected 5)', v_num; END IF;
  IF v_ver <> 3 THEN RAISE EXCEPTION 'CA_0334 verify: version is % (expected 3)', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION 'CA_0334 verify: status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION 'CA_0334 verify: new revision is is_current (the open season would drift)'; END IF;
  IF v_title <> $t$Voting Rights and Electoral Integrity$t$ OR v_short <> $st$Voting Rights$st$ THEN
    RAISE EXCEPTION 'CA_0334 verify: title/short title are "%" / "%"', v_title, v_short;
  END IF;
  IF v_q <> $q$What proof of identity or citizenship should a person have to show to cast a ballot or to register to vote?$q$ THEN RAISE EXCEPTION 'CA_0334 verify: question text is "%"', v_q; END IF;
  IF v_g IS DISTINCT FROM $g$Options 1 to 4 are about what a voter shows with a ballot, in person or by mail. Option 5 is about proving citizenship, usually when registering: choose it if you want that, whatever you want at the ballot. Federal law already requires anyone registering to vote to give a driver's license or Social Security number, if they have one. The trade-off: ineligible votes cast, or eligible voters turned away.$g$ THEN
    RAISE EXCEPTION 'CA_0334 verify: guidance is "%" (the previous line was inherited?)', v_g;
  END IF;
  IF v_rat NOT LIKE 'L1 poles: %' THEN RAISE EXCEPTION 'CA_0334 verify: rationale does not start with the L1 poles line'; END IF;
  IF v_map <> '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb THEN RAISE EXCEPTION 'CA_0334 verify: rung map is %', v_map; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0334 verify: new revision has % rungs (expected 5)', v_n; END IF;

  -- The previous revision is still the current published one (the open season is unaffected).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = v_prev AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0334 verify: 2a18c152-67a0-4380-a381-cb8795110a7c is no longer current/published';
  END IF;

  -- The open season still pins the previous revision; the draft season pins the new one.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_openS AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_prev THEN RAISE EXCEPTION 'CA_0334 verify: open-season pin is % (expected the previous revision)', v_pin; END IF;
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_draft AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_new THEN RAISE EXCEPTION 'CA_0334 verify: draft-season pin is % (expected %)', v_pin, v_new; END IF;

  -- Season sizes unchanged: a re-pin, not an add. RE-READ these counts before the dry run and before
  -- applying: another season migration may have run since 2026-10-26.
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_openS;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0334 verify: open season holds % questions (expected 60)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_draft;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0334 verify: draft season holds % questions (expected 60)', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_draft AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0334 verify: the target season is no longer a draft';
  END IF;

  -- The 57 draft-season rows were carried, unchanged, to the new revision (P2).
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_new;
  IF v_n <> 57 THEN RAISE EXCEPTION 'CA_0334 verify: % draft-season answers cite the new revision (expected 57)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_new;
  IF v_n <> 57 THEN RAISE EXCEPTION 'CA_0334 verify: % draft-season context rows cite the new revision (expected 57)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.topic_id = v_topic AND a.season_id = v_draft
     AND NOT EXISTS (SELECT 1 FROM slot_pre_answers p WHERE p.politician_id = a.politician_id AND p.value = a.value);
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0334 verify: % carried answer(s) changed value or person', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '08e7026f-8eb5-4386-9288-f1dbfc3185c3' AND status = 'rejected') THEN
    RAISE EXCEPTION 'CA_0334 verify: revision 4 is not rejected';
  END IF;
  IF (SELECT count(*) FROM pg_constraint
       WHERE conname IN ('politician_answers_pin_fkey','politician_context_pin_fkey')) <> 2 THEN
    RAISE EXCEPTION 'CA_0334 verify: a pin key is missing after the carry';
  END IF;

  -- What opening the draft season will do to voter answers (report only; the open season is not touched).
  -- Counts ANSWER ROWS of compass_responses (not deleted), not voters: take the expected figure from the
  -- 'voter_answer_rows' lines of templates/stage4-facts.sql, never from compass_answer_dispositions.
  SELECT string_agg(d || ' x' || c, ', ') INTO v_disp FROM (
    SELECT inform.compass_answer_disposition(r.answered_revision_id, v_new, r.value) AS d, count(*) AS c
      FROM inform.compass_responses r
     WHERE r.topic_id = v_topic AND r.deleted_at IS NULL
     GROUP BY 1) z;
  RAISE NOTICE 'CA_0334: voter answers against the new revision at season open: % (expected, as answer rows: 6 rows (4 given on revision 1, 2 on revision 3), identity map; exact labels to be read from the dry run)', coalesce(v_disp, 'none');

  RAISE NOTICE 'CA_0334 post-verify OK: revision % approved/parked (v3, is_current=false), draft season -> new, open season -> previous, revision 4 rejected, 57 rows carried.', v_new;
END $$;

COMMIT;
