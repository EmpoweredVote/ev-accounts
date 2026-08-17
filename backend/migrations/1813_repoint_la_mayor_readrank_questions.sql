-- 1813_repoint_la_mayor_readrank_questions.sql
--
-- Closes the "KNOWN ISSUE, NOT FIXED HERE" left by 1810 (applied as 1626): the LA Mayor GENERAL
-- race (9e888818, Bass v Raman, 2026-11-03) owned only the two moderator questions 1810 created,
-- while every older question for the seat was owned by the JUNE 2 PRIMARY race (24bc3631). Same
-- root cause as the mis-pointed pipeline row fixed in 1803 (applied as 1619): the seat's Read &
-- Rank material was hung off the primary race_id and never moved when the runoff was created.
--
-- Consequence being fixed: readrankQuestionsService.listRaceQuestions('9e888818') returned only
-- those two moderator rows, both at zero coverage, so the admin coverage grid
-- (readrankCoverageService.getCoverageGrid) reported "no material" for a race holding 75 quotes.
--
-- DECISION: REPOINT, not duplicate.
--
--   1. Nothing depends on the primary owning them. Only two read paths key on
--      readrank_questions.race_id, and both are the admin coverage grid:
--      listRaceQuestions() and readrankCoverageService's CELLS_SQL. The player-facing path
--      (readrankService.getRaceBlindQuotes, readrankService.ts:571) resolves question text via
--      `LEFT JOIN readrank_questions rq ON rq.id = q.question_id` with NO race predicate, so
--      ownership is invisible to the game either way -- which is why this defect was never
--      user-visible. readrank_race_topic_questions holds zero rows for either race, and the
--      pipeline row already points at the general (1803).
--
--   2. Repointing loses no coverage. Every quote attached to these questions belongs to Karen
--      Bass or Nithya Raman -- both on the November ballot, both live candidates in BOTH rosters.
--      Zero quotes come from any of the twelve primary-only candidates, so the primary grid holds
--      nothing unique. Verified pre-flight and asserted below: the general race inherits the
--      primary's exact counts (1 rankable question, 6 surfaced, 7 answering candidate-questions).
--
--   3. Duplicating would be actively worse. quotes.question_id would still point at the primary's
--      rows, so the copies would be empty shells: the general grid would show 25 questions at zero
--      coverage, reading as "no material exists" while 75 quotes sit on the originals. Making the
--      copies useful means repointing quotes.question_id as well -- more churn, and it gives one
--      question two identities, contradicting 1377's premise that the question IS the first-class
--      unit of comparison.
--
--   4. The primary is past (2026-06-02; today 2026-08-17) and nobody curates a coverage grid for a
--      concluded race. Its grid goes empty, which ReadRankCoveragePage.tsx:100 already renders as
--      "No confirmed questions for this race yet."
--
-- SCOPE NOTE -- 23 rows, not the 22 named in 1810's header. 1810 counted the questions that carry
-- quotes; a 23rd (`voting-rights`) carries none. It moves too. An empty question is a legitimate
-- bank entry under 1810's own doctrine ("questions outlive any one sourcing pass") -- exactly what
-- 1810 did with its two moderator rows -- and leaving it behind would orphan one question on a
-- concluded race where it can never be filled or seen.
--
-- ECON-DEV INTERACTION: the general race ends up with three economic-development questions --
-- 1810's two neutralised moderator splits, plus the legacy pooled compass question (ded400bd)
-- whose scope 1810 diagnosed as a defect. That is the intended end state, not new drift. 1811
-- (applied as 1627) and 1812 (applied as 1628) already moved Bass's and Raman's answers onto the
-- two splits, and 1812 deliberately left one Raman quote ("Small businesses are what gives a
-- neighborhood its character") on the pooled question because it answers neither split. All eight
-- quotes across the three are DRAFTS (readrank_selected = false), which is why no econ-dev
-- question counts toward the surfaced/rankable guard below -- listRaceQuestions() requires
-- readrank_selected AND deidentified_text.
--
-- This repoint also closes a defect 1812 named but could not reach from where it sat: its header
-- records the pooled question as "owned by the retired JUNE PRIMARY race". It is now owned by the
-- race whose candidates actually answer it.
--
-- Idempotent: re-running matches zero rows once the questions are on the general race.

BEGIN;

UPDATE essentials.readrank_questions
   SET race_id    = '9e888818-c50b-4c61-a106-a0839ff2479d',
       updated_at = now(),
       updated_by = 'migration-1813-repoint-la-mayor-questions'
 WHERE race_id = '24bc3631-22cf-41ab-a731-672481502214';

-- Guard: the primary must own none, and the general must own all 23 moved rows plus the two
-- moderator rows created by 1810. Aborts if the population shifted underneath us.
DO $$
DECLARE n_primary integer; n_general integer;
BEGIN
  SELECT count(*) INTO n_primary FROM essentials.readrank_questions
   WHERE race_id = '24bc3631-22cf-41ab-a731-672481502214';
  IF n_primary <> 0 THEN
    RAISE EXCEPTION
      'Aborting: expected 0 questions left on the LA Mayor primary race, found %.', n_primary;
  END IF;

  SELECT count(*) INTO n_general FROM essentials.readrank_questions
   WHERE race_id = '9e888818-c50b-4c61-a106-a0839ff2479d';
  IF n_general <> 25 THEN
    RAISE EXCEPTION
      'Aborting: expected 25 questions on the LA Mayor general race (23 moved + 2 from 1810), found %.',
      n_general;
  END IF;
END $$;

-- Guard: THE invariant that made repoint safe rather than lossy. Every quote attached to a
-- question now owned by the general race must belong to a live candidate in the general race.
-- A non-zero count means a primary-only candidate's quote was dragged into a race they are not
-- on, and the coverage grid would silently drop it.
DO $$
DECLARE n_stranded integer;
BEGIN
  SELECT count(*) INTO n_stranded
    FROM essentials.quotes q
    JOIN essentials.readrank_questions rq ON rq.id = q.question_id
   WHERE rq.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
     AND NOT EXISTS (
       SELECT 1 FROM essentials.race_candidates rc
        WHERE rc.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
          AND rc.politician_id = q.politician_id
          AND essentials.is_live_candidate(rc.candidate_status, rc.result));
  IF n_stranded <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % quote(s) on general-race questions belong to someone who is not a live general candidate.',
      n_stranded;
  END IF;
END $$;

-- Guard: coverage is carried over intact, not merely relocated. These are the counts the primary
-- grid showed pre-flight (23 questions: 1 rankable, 6 surfaced, 7 answering candidate-questions),
-- recomputed here through listRaceQuestions()' own predicates against the general roster.
DO $$
DECLARE n_rankable integer; n_surfaced integer; n_answering integer;
BEGIN
  SELECT count(*) FILTER (WHERE answering >= 2),
         count(*) FILTER (WHERE answering >= 1),
         COALESCE(sum(answering), 0)
    INTO n_rankable, n_surfaced, n_answering
    FROM (
      SELECT rq.id, count(DISTINCT rc.politician_id) AS answering
        FROM essentials.readrank_questions rq
        LEFT JOIN essentials.quotes q
          ON q.question_id = rq.id
         AND q.readrank_selected = true
         AND q.deidentified_text IS NOT NULL
        LEFT JOIN essentials.race_candidates rc
          ON rc.race_id = rq.race_id
         AND rc.politician_id = q.politician_id
         AND essentials.is_live_candidate(rc.candidate_status, rc.result)
       WHERE rq.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
         AND rq.status = 'confirmed'
       GROUP BY rq.id) s;

  IF (n_rankable, n_surfaced, n_answering) <> (1, 6, 7) THEN
    RAISE EXCEPTION
      'Aborting: expected rankable=1 surfaced=6 answering=7 on the general race, got %/%/%.',
      n_rankable, n_surfaced, n_answering;
  END IF;
END $$;

-- Guard: the move must not have created two rows with the same identity on the general race.
-- There is no unique constraint on (race_id, topic_key, question_text), so assert it.
DO $$
DECLARE n_dupes integer;
BEGIN
  SELECT count(*) INTO n_dupes FROM (
    SELECT 1 FROM essentials.readrank_questions
     WHERE race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
     GROUP BY topic_key, question_text HAVING count(*) > 1) d;
  IF n_dupes <> 0 THEN
    RAISE EXCEPTION
      'Aborting: % duplicate (topic_key, question_text) group(s) on the general race.', n_dupes;
  END IF;
END $$;

COMMIT;
