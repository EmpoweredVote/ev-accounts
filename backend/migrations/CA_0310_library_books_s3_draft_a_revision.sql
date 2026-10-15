-- CA_0310_library_books_s3_draft_a_revision.sql
-- Author: Chris Andrews (CA_ namespace; slot reserved from the steward allocator 2026-10-15)
--
-- =============================================================================
-- CA_0310: education-library-books — Season 3 Draft A ladder (v2), approved and
--          pinned in the DRAFT Season 3
-- =============================================================================
-- Created 2026-10-15. Stage 4 of the Season 3 pilot for this topic. Actor
-- 854fbc06-40fc-458d-b523-20ef8e5ad1b2 (Chris Andrews).
--
-- APPLIED to production 2026-10-15 on Chris Andrews' explicit go-ahead.
-- Revision 2 = 7bb64029-0103-4df8-a4d8-3dcb2938f27f. At that time 1 of 10 T4
-- blind labels was in (t4lib-10, agrees); he approved with T4 still open.
--
-- WHAT THIS DOES
--   1. Proposes revision 2 of education-library-books: change_class substantive,
--      so version 1 -> 2. Question text, title and short title are UNCHANGED.
--      Five rungs, one act each ("the most a challenge can do to a book"):
--        1  Bar schools from removing or restricting a book because someone objects to its content
--        2  Answer a challenge by letting the parent restrict the book for their own child
--        3  Remove a challenged book for all students after a review body finds it unsuitable
--        4  Pull a challenged book from all students until a review decides
--        5  Remove a challenged book for all students with no review
--      Rung map is identity: Draft A keeps the five positions of revision 1 and
--      only splits their compounds (drafts.md section 1, "Map from control").
--   2. Approves it and PARKS it (approved, NOT published, is_current stays on
--      revision 1). Season 2 is open and keeps serving revision 1.
--   3. Pins it into the draft Season 3 (7b3a066c-...). The pin is inert until
--      Season 3 opens; opening publishes pinned revisions (CA_0024).
--   Writes nothing to politician_answers, politician_context or compass_responses.
--
-- L1 POLES (rulebook L1, ruled 2026-10-08: stored internally, not shown to voters)
--   Access pole:  A challenge cannot remove or restrict a book.
--   Removal pole: A challenge removes a book for all students with no review.
--   There is no poles column. They are stored in this revision's `rationale`,
--   which only compass reviewers can read (GET /api/compass/revisions/* behind
--   requireCompassReviewer; the public history route returns public_note, never
--   rationale). The line starts "L1 poles:" so a later column backfill can parse it.
--
-- EVIDENCE (Stage 3, 2026-10-15; ~/Documents/GitHub/.planning/research/s3-pilot-library-stage3/results.md)
--   Frozen 110-item test set. Under the draft small-body vote rule Draft A seats
--   41 of 53 affirmative-record rows (77%); the control (revision 1) seats 15.
--   T3 kept 8 of 10 pre-registered pairs. The one-pass act checklist agreed 98%
--   with blind holistic coders. T6 lint: 0 hits.
--   Rulings 2026-10-15 (Chris Andrews): Q4 yes (a pull pending review for one
--   class of challenge seats rung 4); Q2 yes (a record that states two
--   neighbouring acts sits on the furthest act); Draft A goes forward. Q3 stays
--   at the default: a content-rule law is direction-only by itself.
--   The small-body vote rule is a separate codebook 0.6 proposal and does not
--   block this revision.
--
-- SEAT COST (T5)
--   0 politician seats in any season (measured 2026-10-15: 0 politician_answers,
--   0 politician_context, 0 stance_research_review rows for this topic).
--   1 live voter answer (Season 2, value 2.0, on revision 1). Season 2 is not
--   touched. When Season 3 opens, that answer is read against this revision:
--   identity rung map -> compass_answer_disposition = 'reworded' (CC_0061):
--   the value is KEPT and the voter is asked to re-confirm. Nobody is suppressed.
--
-- 🔴 DO NOT PUSH `--season draft` RESEARCH FOR THIS TOPIC BEFORE THIS IS APPLIED.
-- Rows written earlier would pin revision 1 in Season 3.
--
-- 🔴 ANNEX. docs/codebook/annex/education-library-books.md stays the Season 2
-- annex (it is pasted into coder prompts by topic key, not by season). The
-- Season 3 annex for this revision is docs/codebook/annex/season3/education-library-books.md.
-- build-coder-inputs.ts does not read it yet: point the loader at it before
-- coding this topic for the draft season.
--
-- Guidance is inherited from revision 1 by trigger (CC_0231): "Who decides what
-- belongs on the shelf when a book is challenged."
--
-- Idempotent: steps are guarded on the rung-3 text of revision 2; a re-run is a
-- no-op and the gate still asserts the full shape.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id = '1fcff1e8-c913-4d97-91da-1145952d7c65' AND topic_key = 'education-library-books') THEN
    RAISE EXCEPTION 'CA_0310 precondition: education-library-books topic id/key mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND number = 3 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0310 precondition: Season 3 is not a draft (its pins would be frozen)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                 WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND number = 2 AND status = 'open') THEN
    RAISE EXCEPTION 'CA_0310 precondition: Season 2 is not the open season';
  END IF;
  -- A Season 3 answer on this topic would carry revision 1 in its pin key; repinning under it would
  -- strand the row. There must be none.
  IF EXISTS (SELECT 1 FROM inform.politician_answers
              WHERE topic_id = '1fcff1e8-c913-4d97-91da-1145952d7c65'
                AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075') THEN
    RAISE EXCEPTION 'CA_0310 precondition: Season 3 already holds politician answers for this topic';
  END IF;
END $$;

-- ── 1. Lifecycle: propose revision 2 → approve (park) → pin in Season 3 ─────────────────────────
DO $$
DECLARE
  v_actor     CONSTANT uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';
  v_key       CONSTANT text := 'education-library-books';
  v_topic     CONSTANT uuid := '1fcff1e8-c913-4d97-91da-1145952d7c65';
  v_s3        CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_rung3_new CONSTANT text := 'Remove a challenged book for all students after a review body finds it unsuitable';
  v_open      uuid;
  v_rev2      uuid;
BEGIN
  IF EXISTS (
    SELECT 1 FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 3
    WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
      AND r.status IN ('approved','published') AND s.text = v_rung3_new
  ) THEN
    RAISE NOTICE 'CA_0310: approved revision 2 already present — skipping propose/approve.';
  ELSE
    SELECT id INTO v_open FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND status IN ('draft','approved');
    IF v_open IS NOT NULL THEN
      RAISE EXCEPTION 'CA_0310: topic already has an open revision % — resolve it first', v_open;
    END IF;

    v_rev2 := inform.admin_propose_topic_revision(
      v_key, v_actor, 'substantive',
      'School Library Books and Instructional Materials', 'School Library Books',
      'How should schools handle challenges to books in libraries and classrooms?',
      $stances$[
        {"value":1,"text":"Bar schools from removing or restricting a book because someone objects to its content"},
        {"value":2,"text":"Answer a challenge by letting the parent restrict the book for their own child"},
        {"value":3,"text":"Remove a challenged book for all students after a review body finds it unsuitable"},
        {"value":4,"text":"Pull a challenged book from all students until a review decides"},
        {"value":5,"text":"Remove a challenged book for all students with no review"}
      ]$stances$::jsonb,
      $rat$L1 poles: access = "A challenge cannot remove or restrict a book"; removal = "A challenge removes a book for all students with no review".
Season 3 pilot, Draft A ("c-lib, split clean"). Each rung names the most a challenge can do to a book, one act per rung. Revision 1 failed rulebook L6 on rungs 1, 2 and 3 (and-compounds): ten Stage 3 rows went compound-partial on "a review committee of educators and parents" alone. Draft A keeps revision 1's five positions and splits each compound: rung 1 drops "every book" and "librarians curate"; rung 2 drops "available to all"; rung 3 accepts any reviewer (c-lib); rung 4 drops "any"; rung 5 drops "who may report". Identity rung map.
Stage 3 (frozen 110-item set, codebook 0.5 plus the draft small-body vote rule): Draft A seats 41 of 53 affirmative-record rows (77%) against 15 for revision 1; Draft B also 41. T3 kept 8 of 10 pre-registered pairs (B 6 of 10). The act checklist agreed 98% with blind holistic coders. T6 lint 0 hits.
Rulings 2026-10-15 (Chris Andrews): Q4 yes, a pull pending review for one class of challenge seats rung 4; Q2 yes, a record that states two neighbouring acts sits on the furthest act; tie-break, Draft A goes forward. Q3 default kept: a content-rule law is direction-only by itself.
T5: 0 politician seats in any season; 1 Season 2 voter answer (value 2), disposition 'reworded' at Season 3 open (kept, re-asked). T4: 1 of 10 blind labels at drafting (agrees); approval is gated on T4.$rat$,
      $pub$Each option now names one thing a book challenge can do, from "it cannot remove or restrict a book" to "it removes the book for all students with no review". The old options combined two or three conditions each, so a school policy often matched part of an option and no whole one. The five positions are the same; the wording is narrower and clearer.$pub$,
      'Season 3 pilot education-library-books, Stage 3 results 2026-10-15 (.planning/research/s3-pilot-library-stage3/results.md); drafts .planning/research/s3-pilot-library-stage2/drafts.md section 1; rulings Q2, Q4, tie-break 2026-10-15 (Chris Andrews)',
      '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb
    );

    PERFORM inform.admin_approve_topic_revision(v_rev2, v_actor);  -- approve, NOT publish (park for Season 3)
    RAISE NOTICE 'CA_0310: proposed + approved (parked) substantive revision 2 %', v_rev2;
  END IF;

  SELECT r.id INTO v_rev2 FROM inform.compass_topic_revisions r
    JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 3
   WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
     AND r.status IN ('approved','published') AND s.text = v_rung3_new
   ORDER BY r.revision DESC LIMIT 1;
  IF v_rev2 IS NULL THEN
    RAISE EXCEPTION 'CA_0310: could not locate the approved revision 2 to pin';
  END IF;
  PERFORM inform.admin_season_pin_revision(v_s3, v_topic, v_rev2, v_actor);
  RAISE NOTICE 'CA_0310: Season 3 pinned to revision 2 %', v_rev2;
END $$;

-- ── 2. Post-verify gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_topic  CONSTANT uuid := '1fcff1e8-c913-4d97-91da-1145952d7c65';
  v_s2     CONSTANT uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  v_s3     CONSTANT uuid := '7b3a066c-815d-43b2-a6a0-6a3029778075';
  v_rev1   CONSTANT uuid := 'f480f827-cb1f-4a2e-83cd-bef8763948b8';
  v_rev2   uuid;
  v_ver    int;
  v_num    int;
  v_stat   text;
  v_curr   boolean;
  v_q      text;
  v_rat    text;
  v_map    jsonb;
  v_n      int;
  v_pin    uuid;
  v_bad    text;
BEGIN
  SELECT r.id, r.version, r.revision, r.status::text, r.is_current, r.question_text, r.rationale, r.rung_map
    INTO v_rev2, v_ver, v_num, v_stat, v_curr, v_q, v_rat, v_map
  FROM inform.compass_topic_revisions r
  JOIN inform.compass_stance_revisions s ON s.topic_revision_id = r.id AND s.value = 3
  WHERE r.topic_id = v_topic AND r.change_class = 'substantive'
    AND s.text = 'Remove a challenged book for all students after a review body finds it unsuitable'
  ORDER BY r.revision DESC LIMIT 1;

  IF v_rev2 IS NULL THEN RAISE EXCEPTION 'CA_0310 verify: revision 2 not found'; END IF;
  IF v_num <> 2 THEN RAISE EXCEPTION 'CA_0310 verify: revision number is % (expected 2)', v_num; END IF;
  IF v_ver <> 2 THEN RAISE EXCEPTION 'CA_0310 verify: version is % (expected 2)', v_ver; END IF;
  IF v_stat <> 'approved' THEN RAISE EXCEPTION 'CA_0310 verify: status is % (expected approved — must NOT be published)', v_stat; END IF;
  IF v_curr THEN RAISE EXCEPTION 'CA_0310 verify: revision 2 is is_current (Season 2 would drift)'; END IF;
  IF v_q <> 'How should schools handle challenges to books in libraries and classrooms?' THEN
    RAISE EXCEPTION 'CA_0310 verify: question text changed: "%"', v_q;
  END IF;
  IF v_rat NOT LIKE 'L1 poles: %' THEN RAISE EXCEPTION 'CA_0310 verify: rationale does not start with the L1 poles line'; END IF;
  IF v_map <> '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb THEN RAISE EXCEPTION 'CA_0310 verify: rung map is % (expected identity)', v_map; END IF;

  -- Exactly the five Draft A rungs, word for word.
  SELECT string_agg(format('%s<>%s', x.value, x.text), '; ') INTO v_bad
  FROM (VALUES
    (1, 'Bar schools from removing or restricting a book because someone objects to its content'),
    (2, 'Answer a challenge by letting the parent restrict the book for their own child'),
    (3, 'Remove a challenged book for all students after a review body finds it unsuitable'),
    (4, 'Pull a challenged book from all students until a review decides'),
    (5, 'Remove a challenged book for all students with no review')
  ) AS x(value, text)
  WHERE NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions s
                     WHERE s.topic_revision_id = v_rev2 AND s.value = x.value AND s.text = x.text);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CA_0310 verify: rung text mismatch: %', v_bad; END IF;
  SELECT count(*) INTO v_n FROM inform.compass_stance_revisions WHERE topic_revision_id = v_rev2;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0310 verify: revision 2 has % rungs (expected 5)', v_n; END IF;

  -- Revision 1 is still the current published revision (Season 2 unaffected).
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                  WHERE id = v_rev1 AND is_current AND status = 'published') THEN
    RAISE EXCEPTION 'CA_0310 verify: revision 1 is no longer current/published';
  END IF;

  -- Season 2 (open) still pins revision 1; Season 3 (draft) pins revision 2.
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_s2 AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_rev1 THEN RAISE EXCEPTION 'CA_0310 verify: Season 2 pin is % (expected revision 1)', v_pin; END IF;
  SELECT topic_revision_id INTO v_pin FROM inform.season_questions WHERE season_id = v_s3 AND topic_id = v_topic;
  IF v_pin IS DISTINCT FROM v_rev2 THEN RAISE EXCEPTION 'CA_0310 verify: Season 3 pin is % (expected revision 2 %)', v_pin, v_rev2; END IF;

  -- Season sizes unchanged: a repin, not an add.
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_s2;
  IF v_n <> 60 THEN RAISE EXCEPTION 'CA_0310 verify: Season 2 holds % questions (expected 60)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.season_questions WHERE season_id = v_s3;
  IF v_n <> 61 THEN RAISE EXCEPTION 'CA_0310 verify: Season 3 holds % questions (expected 61)', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE id = v_s3 AND status = 'draft') THEN
    RAISE EXCEPTION 'CA_0310 verify: Season 3 is no longer a draft';
  END IF;

  -- No answers written by this migration.
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE topic_id = v_topic;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0310 verify: % politician answers on this topic (expected 0)', v_n; END IF;

  RAISE NOTICE 'CA_0310 post-verify OK: revision 2 % approved/parked (v2, is_current=false), Season 3 -> revision 2, Season 2 -> revision 1.', v_rev2;
END $$;

COMMIT;
