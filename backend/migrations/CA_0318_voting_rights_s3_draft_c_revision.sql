-- CA_0318_voting_rights_s3_draft_c_revision.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-10-21.
--
-- =============================================================================
-- CA_0318: voting-rights — Season 3 revision 4, approved
--           and pinned in the DRAFT season
-- =============================================================================
-- Template: .claude/skills/season-topic-prep/templates/stage4-revision.sql (structure of CA_0314,
-- education-equity-programs, applied 2026-10-20). Fill every placeholder (a name in double curly
-- braces); a grep of the filled file for two opening curly braces must print nothing before the dry
-- run. Recipe: .claude/skills/season-topic-prep/STAGE4-RECIPE.md.
--
-- Drafted 2026-10-21, offline, as the Stage 4 package of the Season 3 prep for this
-- topic. Actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2 (Chris Andrews).
--
-- APPLIED: (fill in on apply — date, who said yes, revision id)
-- Dry run on prod (not yet run) (body twice inside BEGIN, forced RAISE): (fill in — gate OK,
-- second run skipped propose/approve, voter-answer dispositions, rollback confirmed)
--
-- WHAT THIS DOES
--   1. Proposes revision 4 of voting-rights: change_class substantive, version 3.
--      Rungs:
--        1  Require no proof of identity to vote.
--        2  Accept non-photo documents, such as a utility bill or bank statement, as voter ID.
--        3  Require photo ID to vote, with a sworn statement for a voter who has none.
--        4  Require ID before a ballot counts: photo ID at the polls, or an ID number or a copy of an ID with each mail ballot.
--        5  Require documentary proof of citizenship to register or to vote.
--      Rung map (key = the OLD rung of revision 2a18c152-67a0-4380-a381-cb8795110a7c; "invalidated" allowed): {"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}
--   2. Sets the new guidance on the draft row. guidance is NOT a propose parameter; the trigger would
--      otherwise copy the previous revision's line. guidance is outside the immutable-content trigger.
--   3. Approves it and PARKS it (approved, NOT published; is_current stays on the previous revision).
--      The open season keeps serving the previous revision.
--   4. Pins it into the draft season. The pin is inert until that season opens.
--   Writes nothing to politician_answers, politician_context or compass_responses.
--
-- L1 POLES (stored internally as the first line of rationale, not shown to voters)
--   No proof of identity  <->  Documents that prove citizenship
--
-- EVIDENCE: Stage 3 results (~/Documents/GitHub/.planning/research/s3-prep-voting-rights/ (local): stage3/results.md, stage3/disputes.md, stage3/disputes-C.md, stage2/drafts.md, stage2/drafts-c.md, stage4/).
-- SEAT COST (T5): 7 Season 2 seats: 5 fit rung 4, 1 fits rung 5, 1 needs re-research; 4 live voter answers; substantive (question changes), carried seats re-audited
-- EXPERT REVIEW: owed, not done; 62 seated rows queued in stage3/expert-queue.json.
--
-- 🔴 Do not push `--season draft` research for this topic before this is applied: rows written earlier
--    pin the previous revision in the draft season, and the precondition below refuses to re-pin.
-- 🔴 Season question counts in the gate (60 open, 60 draft) were read on 2026-10-21.
--    RE-READ THEM just before the dry run and again before applying.
--
-- Idempotent: steps are guarded on revision number 4 with the five new rung texts (on any
-- revision other than the previous one, so a clarifying revision with unchanged rungs works); a re-run
-- is a no-op and the gate still asserts the full shape.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND topic_key = 'voting-rights') THEN
    RAISE EXCEPTION 'CA_0318 precondition: voting-rights topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0318 precondition: the target season is not a draft (its pins would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0318 precondition: 86d893a1-c1a2-4bbf-b4e5-69ec43221194 is not the open season';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = '2a18c152-67a0-4380-a381-cb8795110a7c' AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0318 precondition: 2a18c152-67a0-4380-a381-cb8795110a7c is not the current published revision';
  END IF;
  -- A draft-season answer on this topic carries the previous revision in its pin key; re-pinning
  -- under it would strand the row. There must be none.
  IF EXISTS (SELECT 1 FROM inform.politician_answers
              WHERE topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075') THEN
    RAISE EXCEPTION 'CA_0318 precondition: the draft season already holds politician answers for this topic';
  END IF;
END $$;

-- ── 1. Lifecycle: propose → set guidance → approve (park) → pin in the draft season ─────────────
DO $$
DECLARE
  v_actor    CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key      CONSTANT text := 'voting-rights';
  v_topic    CONSTANT uuid := 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  v_draft    CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_guidance CONSTANT text := $g$Whether the greater risk is ineligible votes cast, or eligible voters turned away.$g$;
  v_rungs    CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', $r1$Require no proof of identity to vote.$r1$),
    jsonb_build_object('value', 2, 'text', $r2$Accept non-photo documents, such as a utility bill or bank statement, as voter ID.$r2$),
    jsonb_build_object('value', 3, 'text', $r3$Require photo ID to vote, with a sworn statement for a voter who has none.$r3$),
    jsonb_build_object('value', 4, 'text', $r4$Require ID before a ballot counts: photo ID at the polls, or an ID number or a copy of an ID with each mail ballot.$r4$),
    jsonb_build_object('value', 5, 'text', $r5$Require documentary proof of citizenship to register or to vote.$r5$)
  );
  v_open     uuid;
  v_new      uuid;
BEGIN
  -- The new revision is the approved/published revision 4 whose five rungs match these texts
  -- exactly. Requiring the number stops an older revision that happens to share the rung texts from
  -- being taken for it.
  SELECT r.id INTO v_new FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic AND r.id <> '2a18c152-67a0-4380-a381-cb8795110a7c' AND r.revision = 4
     AND r.status IN ('approved','published')
     AND (SELECT count(*) FROM inform.compass_stance_revisions s
           JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
          WHERE s.topic_revision_id = r.id) = 5
   ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NOT NULL THEN
    RAISE NOTICE 'CA_0318: approved revision already present (%) — skipping propose/approve.', v_new;
  ELSE
    SELECT id INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0318: topic already has an open revision % — resolve it first', v_open;
    END IF;

    v_new := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      $t$Voting Rights and Electoral Integrity$t$, $st$Voting Rights$st$,
      $q$What proof of identity or citizenship should a person have to show to vote?$q$,
      v_rungs,
      $rat$L1 poles: none = "No proof of identity"; citizenship = "Documents that prove citizenship". Axis: how much proof a person must show before their vote counts.
Season 3 rewrite of revision 3 (Season 2), the third blind draft (Draft C) of the season-topic-prep skill's Wording path. Each rung names one kind of act a law states: 1 ends every proof-of-identity rule; 2 accepts non-photo documents on their own as voter ID; 3 requires photo ID with a sworn-statement path open to any voter without it; 4 makes ID a condition of the ballot counting with no sworn substitute, at the polls (photo ID with a provisional ballot cured by showing it) or by mail (an ID number or copy with each mail ballot); 5 requires documentary proof of citizenship to register or to vote.
Why the control failed: rung 4 joined two acts with "and" (photo ID in person AND an ID number on every mail ballot; L6), so all 6 of its seats rested on one clause only; rung 1 joined a no-ID clause to an officials' signature check (L6, L9); rung 5 moved from voting to registration (L2); no poles were named (L1).
Rung map: identity (1->1 ... 5->5). Rung 1 drops the signature clause; rung 3 names a sworn statement for an affidavit; rung 4 turns the "and" into "or" over the same point on the axis (ruling C-Q1); rung 5 widens to "or to vote" (Q3). No position moves.
Stage 3 on a frozen set of 129 items (105 people, 16 instruments), deduplicated: T1 54/62 = 87.1% of affirmative records (control 34/62 = 54.8%; Drafts A and B 46/62 each), no regression; T3 10/10 pre-registered order pairs (control 3, A 5, B 8); T6 0 lint hits; blind validation 16/16 on Draft C (all ladders 64/64 after one fix to the validators' inputs); adversarial check on Draft C: one surviving dispute (DC1), ruled. Draft C was written knowing the Stage 3 lesson by kind (ruling C1), so its score on this set is not a fully blind test.
Rulings (Chris Andrews): P1 Wording path (2026-10-20); census Q1 private election funding is not campaign-finance evidence; J1 SAVE Act items exposed and scored apart; J2-J10 sampling; Q1-Q8 drafting (2026-10-20/21; Q2 new question; Q3 rung 5 widened; Q4 omnibus election bills follow codebook V4.1; Q5 officials' checks adjacent; Q6 non-documentary registration rules blank; Q7 a winner must seat strict photo ID; Q8 one scale for Season 3, a split into ID-to-vote and proof-to-register topics noted for a later season); D1-D6 disputes (2026-10-21); C1, C-Q1-C-Q5 and DC1 (Draft C, 2026-10-21).
T5: of 7 Season 2 seats, 5 fit rung 4 on the evidence they rest on, 1 fits rung 5, 1 needs re-research; the question changes (substantive), so every carried seat is re-audited against this wording before Season 3 research. 4 live voter answers.
Expert review is owed: 62 seated rows that rest on a bill are queued (stage3/expert-queue.json); disputes ruled: 7.$rat$,
      $pub$This question now asks what proof of identity or citizenship a person should have to show to vote, from none at all up to documents that prove citizenship. The old wording joined two separate rules in one option (photo ID at the polls and an ID number on mail ballots), so many real laws fit no option. Each option now names one kind of rule, and an ID rule for the polls or for mail ballots sits on the same option. If you answered this question before, your answer is kept on the matching option; please check that it still describes your view.$pub$,
      $ref$~/Documents/GitHub/.planning/research/s3-prep-voting-rights/ (local): stage3/results.md, stage3/disputes.md, stage3/disputes-C.md, stage2/drafts.md, stage2/drafts-c.md, stage4/$ref$,
      '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb
    );

    -- guidance is not a propose parameter: set it on the draft row BEFORE approving.
    UPDATE inform.compass_topic_revisions SET guidance = v_guidance
     WHERE id = v_new AND status = 'draft';
    IF NOT FOUND THEN RAISE EXCEPTION 'CA_0318: could not set guidance on draft revision %', v_new; END IF;

    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);  -- approve, NOT publish (park)
    RAISE NOTICE 'CA_0318: proposed + approved (parked) substantive revision %', v_new;
  END IF;

  PERFORM inform.admin_season_pin_revision(v_draft, v_topic, v_new, v_actor);
  RAISE NOTICE 'CA_0318: draft season pinned to revision %', v_new;
END $$;

-- ── 2. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic CONSTANT uuid := 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  v_openS CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_draft CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_prev  CONSTANT uuid := '2a18c152-67a0-4380-a381-cb8795110a7c';
  v_rungs CONSTANT jsonb := jsonb_build_array(
    jsonb_build_object('value', 1, 'text', $r1$Require no proof of identity to vote.$r1$),
    jsonb_build_object('value', 2, 'text', $r2$Accept non-photo documents, such as a utility bill or bank statement, as voter ID.$r2$),
    jsonb_build_object('value', 3, 'text', $r3$Require photo ID to vote, with a sworn statement for a voter who has none.$r3$),
    jsonb_build_object('value', 4, 'text', $r4$Require ID before a ballot counts: photo ID at the polls, or an ID number or a copy of an ID with each mail ballot.$r4$),
    jsonb_build_object('value', 5, 'text', $r5$Require documentary proof of citizenship to register or to vote.$r5$)
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
  WHERE r.topic_id = v_topic AND r.id <> '2a18c152-67a0-4380-a381-cb8795110a7c' AND r.revision = 4
    AND (SELECT count(*) FROM inform.compass_stance_revisions s
          JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
         WHERE s.topic_revision_id = r.id) = 5
  ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0318 verify: new revision not found (rung text mismatch?)'; END IF;
  IF v_num <> 4 THEN RAISE EXCEPTION 'CA_0318 verify: revision number is % (expected 4)', v_num; END IF;
  IF v_ver <> 3 THEN RAISE EXCEPTION 'CA_0318 verify: version is % (expected 3)', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION 'CA_0318 verify: status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION 'CA_0318 verify: new revision is is_current (the open season would drift)'; END IF;
  IF v_title <> $t$Voting Rights and Electoral Integrity$t$ OR v_short <> $st$Voting Rights$st$ THEN
    RAISE EXCEPTION 'CA_0318 verify: title/short title are "%" / "%"', v_title, v_short;
  END IF;
  IF v_q <> $q$What proof of identity or citizenship should a person have to show to vote?$q$ THEN RAISE EXCEPTION 'CA_0318 verify: question text is "%"', v_q; END IF;
  IF v_g IS DISTINCT FROM $g$Whether the greater risk is ineligible votes cast, or eligible voters turned away.$g$ THEN
    RAISE EXCEPTION 'CA_0318 verify: guidance is "%" (the previous line was inherited?)', v_g;
  END IF;
  IF v_rat NOT LIKE 'L1 poles: %' THEN RAISE EXCEPTION 'CA_0318 verify: rationale does not start with the L1 poles line'; END IF;
  IF v_map <> '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb THEN RAISE EXCEPTION 'CA_0318 verify: rung map is %', v_map; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0318 verify: new revision has % rungs (expected 5)', v_n; END IF;

  -- The previous revision is still the current published one (the open season is unaffected).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = v_prev AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0318 verify: 2a18c152-67a0-4380-a381-cb8795110a7c is no longer current/published';
  END IF;

  -- The open season still pins the previous revision; the draft season pins the new one.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_openS AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_prev THEN RAISE EXCEPTION 'CA_0318 verify: open-season pin is % (expected the previous revision)', v_pin; END IF;
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_draft AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_new THEN RAISE EXCEPTION 'CA_0318 verify: draft-season pin is % (expected %)', v_pin, v_new; END IF;

  -- Season sizes unchanged: a re-pin, not an add. RE-READ these counts before the dry run and before
  -- applying: another season migration may have run since 2026-10-21.
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_openS;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0318 verify: open season holds % questions (expected 60)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_draft;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0318 verify: draft season holds % questions (expected 60)', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_draft AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0318 verify: the target season is no longer a draft';
  END IF;

  -- No answers written into the draft season by this migration.
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE topic_id = v_topic AND season_id = v_draft;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0318 verify: % draft-season politician answers on this topic (expected 0)', v_n; END IF;

  -- What opening the draft season will do to voter answers (report only; the open season is not touched).
  SELECT string_agg(d || ' x' || c, ', ') INTO v_disp FROM (
    SELECT inform.compass_answer_disposition(r.answered_revision_id, v_new, r.value) AS d, count(*) AS c
      FROM inform.compass_responses r
     WHERE r.topic_id = v_topic AND r.deleted_at IS NULL
     GROUP BY 1) z;
  RAISE NOTICE 'CA_0318: voter answers against the new revision at season open: % (expected reworded x4 under the identity map (to be confirmed by the dry run))', coalesce(v_disp, 'none');

  RAISE NOTICE 'CA_0318 post-verify OK: revision % approved/parked (v3, is_current=false), draft season -> new, open season -> previous.', v_new;
END $$;

COMMIT;
