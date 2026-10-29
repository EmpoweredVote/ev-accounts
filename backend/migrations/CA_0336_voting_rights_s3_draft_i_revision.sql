-- CA_0336_voting_rights_s3_draft_i_revision.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-10-29.
--
-- =============================================================================
-- CA_0336: voting-rights — Season 3 revision 6 (Draft I2, rung 2 reworded), approved
--           and pinned in the DRAFT season
-- =============================================================================
-- Template: .claude/skills/season-topic-prep/templates/stage4-revision.sql, as adapted in CA_0334 (which rejected an
-- approved, unpublished revision and carried the draft-season rows). Recipe: STAGE4-RECIPE.md.
--
-- Drafted 2026-10-29, offline. NOT dry-run, NOT applied. Actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2 (Chris Andrews).
--
-- WHAT THIS DOES
--   0. REJECTS revision 5 (9429596c-4727-4a6d-8403-94509ec54466, Draft F, CA_0334), approved and pinned, never published.
--   1. Proposes revision 6: change_class substantive, version 3, measured from the published revision 3
--      (2a18c152-67a0-4380-a381-cb8795110a7c), rung map identity {"1":1,...,"5":5}. Only rung 2's text differs from revision 5:
--        2  Do not require photo ID to cast a ballot. Accept other proof, such as a utility bill or a bank statement.
--      Question, guidance, title and rungs 1, 3, 4, 5 are revision 5's, word for word.
--   2. Sets guidance on the draft row (not a propose parameter), approves (parks; NOT published).
--   3. Pins it in the draft Season 3 and CARRIES the 57 draft-season answer and context rows from revision 5 to
--      revision 6 unchanged (drop/re-add the two composite pin keys inside the transaction, as CA_0334 did).
--   Gate: 57 + 57 rows on revision 6, values unchanged, revision 5 rejected, both pin keys present, open season
--   still on revision 3, season sizes 60/60 (re-read before the dry run and before applying).
--
-- 🔴 No `--season draft` research on this topic before this is applied.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND topic_key = 'voting-rights') THEN
    RAISE EXCEPTION 'CA_0336 precondition: voting-rights topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0336 precondition: the target season is not a draft (its pins would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0336 precondition: 86d893a1-c1a2-4bbf-b4e5-69ec43221194 is not the open season';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id = '2a18c152-67a0-4380-a381-cb8795110a7c' AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0336 precondition: 2a18c152-67a0-4380-a381-cb8795110a7c is not the current published revision';
  END IF;
  -- The 57 draft-season rows on this topic are carried, not refused (P2). They must cite revision 5 or, on a
  -- re-run, the new revision, and number exactly 57.
  IF (SELECT count(*) FROM inform.politician_answers
       WHERE topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075') <> 57 THEN
    RAISE EXCEPTION 'CA_0336 precondition: expected 57 draft-season answers on this topic (re-measure; the carry was ruled on 57)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = '9429596c-4727-4a6d-8403-94509ec54466' AND status IN ('approved','rejected')) THEN
    RAISE EXCEPTION 'CA_0336 precondition: revision 5 is neither approved nor already rejected';
  END IF;
END $$;

CREATE TEMP TABLE IF NOT EXISTS slot_pre_answers ON COMMIT DROP AS
  SELECT politician_id, value FROM inform.politician_answers
   WHERE topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075';

-- ── 0b. Reject revision 5 (approved, pinned, never published) ───────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '9429596c-4727-4a6d-8403-94509ec54466' AND status = 'approved') THEN
    PERFORM inform.admin_reject_topic_revision('9429596c-4727-4a6d-8403-94509ec54466', '854fbc06-40fc-458d-b523-20ef8e5ad1b2',
      'Replaced before Season 3 opened by revision 6 (Draft I2): rung 2 reworded to lead with not requiring photo ID; other rungs, question and guidance unchanged. Stage 3 2026-10-29.');
    RAISE NOTICE 'CA_0336: revision 5 rejected';
  ELSE
    RAISE NOTICE 'CA_0336: revision 5 already rejected — skipping';
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
    jsonb_build_object('value', 2, 'text', $r2$Do not require photo ID to cast a ballot. Accept other proof, such as a utility bill or a bank statement.$r2$),
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
   WHERE r.topic_id = v_topic AND r.id <> '2a18c152-67a0-4380-a381-cb8795110a7c' AND r.revision = 6
     AND r.status IN ('approved','published')
     AND (SELECT count(*) FROM inform.compass_stance_revisions s
           JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
          WHERE s.topic_revision_id = r.id) = 5
   ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NOT NULL THEN
    RAISE NOTICE 'CA_0336: approved revision already present (%) — skipping propose/approve.', v_new;
  ELSE
    SELECT id INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0336: topic already has an open revision % — resolve it first', v_open;
    END IF;

    v_new := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      $t$Voting Rights and Electoral Integrity$t$, $st$Voting Rights$st$,
      $q$What proof of identity or citizenship should a person have to show to cast a ballot or to register to vote?$q$,
      v_rungs,
      $rat$L1 poles: none = "No proof of identity with the ballot"; citizenship = "A document that proves citizenship, such as a passport, birth certificate or naturalization papers". Axis: how much proof a person must show before their vote counts: proof of identity with the ballot, then proof of citizenship.
Season 3 rewrite of revision 3 (Season 2). It replaces revision 5 (Draft F, approved 2026-10-26, never published) and changes only rung 2's words: revision 5 said "Accept non-photo documents, such as a utility bill or bank statement, as ID to cast a ballot"; revision 6 says "Do not require photo ID to cast a ballot. Accept other proof, such as a utility bill or a bank statement." The Stage 5 early check found that the largest group whose stance no rung held (39 people) speaks against requiring photo ID without naming what a voter should show instead; the old rung 2 named only the documents, so neither voters nor coders could place that view. Each rung names one kind of act a law states: 1 ends every proof-of-identity rule for casting a ballot; 2 accepts proof other than photo ID on its own (a non-photo document, or a signed statement in place of any document); 3 requires photo ID with a sworn-statement path open to any voter without it; 4 makes ID a condition of the ballot counting with no sworn substitute, at the polls or by mail; 5 requires a document proving citizenship to register or to vote. Rung 2's negative opening is never met by silence: a record meets it only by stating what proof it accepts, and own words only by stating the rejection (Season 3 annex).
Rung map from revision 3: identity (1->1 ... 5->5). The 57 draft-season rows carry unchanged (10 on rung 2 rest on a law that accepts a utility bill or bank statement on its own; none is on rung 1).
Stage 3 (2026-10-29): frozen set T1 54/62 = 87.1% and T3 10/10, unchanged (no frozen item moves); T6 0 lint hits; voter test (3 voters per ladder, 21 views): rung-2 views placed 9/12 (revision 5: 6/12), rung-3 views 6/6 with none drawn to 2, main views 24/30 (revision 5: 25/30); coder test on 41 Stage 5 people who spoke against photo ID: 18 seat on 2, two independent passes agree on 39/41; 35 records with no photo condition: none seated by silence; 25 current seats: no move caused by the wording. A variant that also named "a signed statement" on rung 2 (I1) moved the only rung-1 seat to 2 and lost under the pre-registered rule. Rulings: "Yes, start it" and "Yes, count barrier talk" (2026-10-29, Chris Andrews); Q1-Q4 of stage3-i/disputes-I.md.
Expert review is owed: no new seated row rests on a bill or ordinance (the new seats are own words); the queue of stage3-h/expert-queue.json carries over; disputes ruled: 4.$rat$,
      $pub$Option 2 now says plainly that it is for people who do not want voters to need a photo ID, while still asking for some proof, such as a utility bill or a bank statement. Before, it only listed those documents, so people who mainly oppose photo-ID rules could not tell where they fit. The other options are unchanged. If you chose option 2 before, your answer is kept; please check that it still describes your view.$pub$,
      $ref$~/Documents/GitHub/.planning/research/s3-prep-voting-rights/ (local): stage3-i/results.md, stage3-i/disputes-I.md, stage2-i/drafts-i.md, stage4-i/; Stage 5 origin stage5/wave3/draft-rung2.md$ref$,
      '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb
    );

    -- guidance is not a propose parameter: set it on the draft row BEFORE approving.
    UPDATE inform.compass_topic_revisions SET guidance = v_guidance
     WHERE id = v_new AND status = 'draft';
    IF NOT FOUND THEN RAISE EXCEPTION 'CA_0336: could not set guidance on draft revision %', v_new; END IF;

    PERFORM inform.admin_approve_topic_revision(v_new, v_actor);  -- approve, NOT publish (park)
    RAISE NOTICE 'CA_0336: proposed + approved (parked) substantive revision %', v_new;
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
  v_rev5  CONSTANT uuid := '9429596c-4727-4a6d-8403-94509ec54466';
  v_new   uuid;
  v_a     int;
  v_c     int;
BEGIN
  SELECT r.id INTO v_new FROM inform.compass_topic_revisions r
   WHERE r.topic_id = v_topic AND r.revision = 6 AND r.status = 'approved';
  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0336 carry: approved revision 6 not found'; END IF;
  PERFORM inform.admin_season_pin_revision(v_draft, v_topic, v_new, v_actor);
  UPDATE inform.politician_answers SET topic_revision_id = v_new
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_rev5;
  GET DIAGNOSTICS v_a = ROW_COUNT;
  UPDATE inform.politician_context SET topic_revision_id = v_new
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_rev5;
  GET DIAGNOSTICS v_c = ROW_COUNT;
  RAISE NOTICE 'CA_0336: draft season pinned to revision %; carried % answer and % context row(s)', v_new, v_a, v_c;
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
    jsonb_build_object('value', 2, 'text', $r2$Do not require photo ID to cast a ballot. Accept other proof, such as a utility bill or a bank statement.$r2$),
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
  WHERE r.topic_id = v_topic AND r.id <> '2a18c152-67a0-4380-a381-cb8795110a7c' AND r.revision = 6
    AND (SELECT count(*) FROM inform.compass_stance_revisions s
          JOIN jsonb_array_elements(v_rungs) AS x(elem) ON (x.elem->>'value')::int = s.value AND x.elem->>'text' = s.text
         WHERE s.topic_revision_id = r.id) = 5
  ORDER BY r.revision DESC LIMIT 1;

  IF v_new IS NULL THEN RAISE EXCEPTION 'CA_0336 verify: new revision not found (rung text mismatch?)'; END IF;
  IF v_num <> 6 THEN RAISE EXCEPTION 'CA_0336 verify: revision number is % (expected 6)', v_num; END IF;
  IF v_ver <> 3 THEN RAISE EXCEPTION 'CA_0336 verify: version is % (expected 3)', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION 'CA_0336 verify: status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION 'CA_0336 verify: new revision is is_current (the open season would drift)'; END IF;
  IF v_title <> $t$Voting Rights and Electoral Integrity$t$ OR v_short <> $st$Voting Rights$st$ THEN
    RAISE EXCEPTION 'CA_0336 verify: title/short title are "%" / "%"', v_title, v_short;
  END IF;
  IF v_q <> $q$What proof of identity or citizenship should a person have to show to cast a ballot or to register to vote?$q$ THEN RAISE EXCEPTION 'CA_0336 verify: question text is "%"', v_q; END IF;
  IF v_g IS DISTINCT FROM $g$Options 1 to 4 are about what a voter shows with a ballot, in person or by mail. Option 5 is about proving citizenship, usually when registering: choose it if you want that, whatever you want at the ballot. Federal law already requires anyone registering to vote to give a driver's license or Social Security number, if they have one. The trade-off: ineligible votes cast, or eligible voters turned away.$g$ THEN
    RAISE EXCEPTION 'CA_0336 verify: guidance is "%" (the previous line was inherited?)', v_g;
  END IF;
  IF v_rat NOT LIKE 'L1 poles: %' THEN RAISE EXCEPTION 'CA_0336 verify: rationale does not start with the L1 poles line'; END IF;
  IF v_map <> '{"1": 1, "2": 2, "3": 3, "4": 4, "5": 5}'::jsonb THEN RAISE EXCEPTION 'CA_0336 verify: rung map is %', v_map; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_new;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0336 verify: new revision has % rungs (expected 5)', v_n; END IF;

  -- The previous revision is still the current published one (the open season is unaffected).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = v_prev AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0336 verify: 2a18c152-67a0-4380-a381-cb8795110a7c is no longer current/published';
  END IF;

  -- The open season still pins the previous revision; the draft season pins the new one.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_openS AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_prev THEN RAISE EXCEPTION 'CA_0336 verify: open-season pin is % (expected the previous revision)', v_pin; END IF;
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_draft AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_new THEN RAISE EXCEPTION 'CA_0336 verify: draft-season pin is % (expected %)', v_pin, v_new; END IF;

  -- Season sizes unchanged: a re-pin, not an add. RE-READ these counts before the dry run and before
  -- applying: another season migration may have run since 2026-10-26.
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_openS;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0336 verify: open season holds % questions (expected 60)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_draft;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0336 verify: draft season holds % questions (expected 60)', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_draft AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0336 verify: the target season is no longer a draft';
  END IF;

  -- The 57 draft-season rows were carried, unchanged, to the new revision (P2).
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_new;
  IF v_n <> 57 THEN RAISE EXCEPTION 'CA_0336 verify: % draft-season answers cite the new revision (expected 57)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE topic_id = v_topic AND season_id = v_draft AND topic_revision_id = v_new;
  IF v_n <> 57 THEN RAISE EXCEPTION 'CA_0336 verify: % draft-season context rows cite the new revision (expected 57)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.topic_id = v_topic AND a.season_id = v_draft
     AND NOT EXISTS (SELECT 1 FROM slot_pre_answers p WHERE p.politician_id = a.politician_id AND p.value = a.value);
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0336 verify: % carried answer(s) changed value or person', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id = '9429596c-4727-4a6d-8403-94509ec54466' AND status = 'rejected') THEN
    RAISE EXCEPTION 'CA_0336 verify: revision 5 is not rejected';
  END IF;
  IF (SELECT count(*) FROM pg_constraint
       WHERE conname IN ('politician_answers_pin_fkey','politician_context_pin_fkey')) <> 2 THEN
    RAISE EXCEPTION 'CA_0336 verify: a pin key is missing after the carry';
  END IF;

  -- What opening the draft season will do to voter answers (report only; the open season is not touched).
  -- Counts ANSWER ROWS of compass_responses (not deleted), not voters: take the expected figure from the
  -- 'voter_answer_rows' lines of templates/stage4-facts.sql, never from compass_answer_dispositions.
  SELECT string_agg(d || ' x' || c, ', ') INTO v_disp FROM (
    SELECT inform.compass_answer_disposition(r.answered_revision_id, v_new, r.value) AS d, count(*) AS c
      FROM inform.compass_responses r
     WHERE r.topic_id = v_topic AND r.deleted_at IS NULL
     GROUP BY 1) z;
  RAISE NOTICE 'CA_0336: voter answers against the new revision at season open: % (expected, as answer rows: 6 rows (4 given on revision 1, 2 on revision 3), identity map; exact labels to be read from the dry run)', coalesce(v_disp, 'none');

  RAISE NOTICE 'CA_0336 post-verify OK: revision % approved/parked (v3, is_current=false), draft season -> new, open season -> previous, revision 5 rejected, 57 rows carried.', v_new;
END $$;

COMMIT;
