-- 1820_readrank_one_selected_per_question.sql
--
-- Re-key the "one served answer per candidate" constraint from the TOPIC to the QUESTION,
-- finishing the migration that 1377 started and the player path never followed.
--
-- Replaces (from migration 293, captioned there "Enforce at most one selected per stance"):
--
--     quotes_one_selected_per_stance  UNIQUE (politician_id, lower(topic_key)) WHERE readrank_selected
--
-- with a pair:
--
--     quotes_one_selected_per_question       UNIQUE (politician_id, question_id)
--                                            WHERE readrank_selected
--     quotes_one_selected_per_legacy_stance  UNIQUE (politician_id, lower(topic_key))
--                                            WHERE readrank_selected AND question_id IS NULL
--
-- TWO indexes, not one, because a unique index treats NULLs as distinct: question_id IS NULL
-- rows (compass-era quotes, which predate 1377) would never collide on the first index at all.
-- The second one preserves 293's exact guarantee for precisely those rows, and its
-- `question_id IS NULL` predicate keeps it from constraining question-bearing rows.
--
-- ── WHY THIS COULD NOT LAND FIRST ─────────────────────────────────────────────────────────────
--
-- 293's index was the only thing standing between an editor and a corrupted card. It is keyed on
-- (politician_id, topic_key), so it never blocked the real defect -- candidate A selected on
-- question 1 plus candidate B selected on question 2 of the same topic satisfied it, and the game
-- still merged them into ONE card pairing answers to DIFFERENT questions under a
-- nondeterministically-chosen question text. What it did block was the accident that produced
-- that state most easily. Relaxing it before the app read paths were question-keyed would have
-- handed editors a silent way to build the merged card.
--
-- (1815's header says this index "PREVENTS a corruption". That overstates it -- it prevents the
-- easy route to one. .planning/todos/2026-08-17-readrank-question-as-unit-vs-topic.md is the
-- accurate account.)
--
-- Shipped ahead of this migration, in the same branch:
--   * getRaceBlindQuotes groups by COALESCE(question_id::text, 'topic:' || lower(topic_key)), so
--     each question is its own card with its own question text (readrankService.ts).
--   * getPlayableRaces counts rankable QUESTIONS on the same key, so a split topic no longer
--     understates playability.
--   * computeRaceMatch keys perTopic and the userTopWinner tie-break on the same card key, so the
--     reveal cannot pool two questions' rankings or award one winner across both.
--   * selectReadrankQuote / clearReadrankSelection are question-scoped. This one was the live
--     trap: the admin "select" button cleared by (politician_id, topic_key), so selecting Raman's
--     downtown quote SILENTLY unselected Raman's film quote -- one click, no error, straight to
--     the merged card. The admin radio groups were per topic for the same reason.
--
-- 🔴 STILL OUTSTANDING WHEN THIS WAS WRITTEN -- read before applying to prod.
--
-- The read-rank game frontend (separate repo, src/store/useReadRankStore.ts) builds race progress
-- as `topics[t.topicKey] = {...}` -- a Record keyed by topicKey, with topicKey also pushed onto
-- topicOrder. Two cards sharing a topicKey therefore COLLIDE: the second overwrites the first,
-- topicOrder lists the key twice, and the player sees one question twice while the other's quotes
-- are never shown. The payload now carries `topics[].key` (and `questionId`) for exactly this --
-- the client must group on `key`, not `topicKey`, before a second question in one topic goes live.
--
-- Applying THIS migration is what makes that state reachable. Until the client ships:
--   * apply this migration only alongside (or after) the client change, OR
--   * apply it and leave the second question unselected -- the CI guard
--     `npm run check:readrank-question-unit --prefix backend` fails the moment two questions in
--     one race/topic both hold served quotes, so the state cannot arrive unnoticed.
--
-- ── WHAT THIS DELIBERATELY NO LONGER PREVENTS ────────────────────────────────────────────────
--
-- Two questions in one topic each holding served quotes. That is the POINT: LA Mayor's econ-dev
-- topic hosts a film question (025217d5, live since 1815) and a downtown question (263728ff, pair
-- prepared -- Bass b2d1f06d selection-ready, Raman f7625f7b de-identification repaired in 1815).
--
-- Consequently 1815's Gate 3 ("no econ-dev quote selected outside the film question for these
-- candidates") is a point-in-time assertion about what 1815 did, NOT a standing invariant. It was
-- written to be deliberately redundant with 293's index so an index rework could not void the
-- invariant silently. This is that rework, stating it out loud: seating the downtown pair will
-- make Gate 3 false by design. The standing invariant that replaces it is the CI guard above --
-- one card per question, never two questions merged onto one card.
--
-- Rankability is still DERIVED, not constrained: a question with one answering candidate is legal
-- and simply not rankable (readrankQuestionsService.ts).
--
-- ── APPLYING ────────────────────────────────────────────────────────────────────────────────
--
-- Idempotent: DROP INDEX IF EXISTS + CREATE UNIQUE INDEX IF NOT EXISTS, so it is safe to re-run.
-- NOT YET DRY-RUN AGAINST PROD. Per CLAUDE.md, wrap the body in BEGIN; ... ROLLBACK; first and
-- confirm the rollback reverted before trusting it. Creating either unique index will ERROR
-- rather than corrupt if live data already violates it, which is the desired failure mode; the
-- post-verify gate below states the same conditions explicitly so a green run means something.

BEGIN;

-- Order matters within the transaction only for clarity; all three statements commit together.
DROP INDEX IF EXISTS essentials.quotes_one_selected_per_stance;

-- The question is the unit of comparison (1377). One served answer per candidate per question.
CREATE UNIQUE INDEX IF NOT EXISTS quotes_one_selected_per_question
  ON essentials.quotes (politician_id, question_id)
  WHERE readrank_selected;

COMMENT ON INDEX essentials.quotes_one_selected_per_question IS
  'At most one readrank_selected quote per (politician, question). Replaces quotes_one_selected_per_stance (293), which keyed on topic_key and so could not express the question-as-unit model 1377 introduced. Does NOT constrain question_id IS NULL rows — unique indexes treat NULLs as distinct; quotes_one_selected_per_legacy_stance covers those.';

-- 293's guarantee, preserved for exactly the rows that still need it.
CREATE UNIQUE INDEX IF NOT EXISTS quotes_one_selected_per_legacy_stance
  ON essentials.quotes (politician_id, lower(topic_key))
  WHERE readrank_selected AND question_id IS NULL;

COMMENT ON INDEX essentials.quotes_one_selected_per_legacy_stance IS
  'Migration 293''s guarantee, narrowed to compass-era quotes (question_id IS NULL) which group by topic because they answer no readrank_question. Question-bearing rows are constrained by quotes_one_selected_per_question instead.';

-- ── POST-VERIFY ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  has_old      boolean;
  has_question boolean;
  has_legacy   boolean;
  n_dup_q      integer;
  n_dup_topic  integer;
  n_split      integer;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'essentials' AND c.relname = 'quotes_one_selected_per_stance'
  ) INTO has_old;
  IF has_old THEN
    RAISE EXCEPTION 'Aborting: quotes_one_selected_per_stance still exists — the topic-keyed constraint was not replaced.';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'essentials' AND c.relname = 'quotes_one_selected_per_question'
  ) INTO has_question;
  SELECT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'essentials' AND c.relname = 'quotes_one_selected_per_legacy_stance'
  ) INTO has_legacy;
  IF NOT (has_question AND has_legacy) THEN
    RAISE EXCEPTION 'Aborting: expected both replacement indexes (question=%, legacy=%).', has_question, has_legacy;
  END IF;

  -- Both of these are what the indexes enforce. Asserted anyway: an index that exists is not
  -- proof it is the index we meant, and a wrong predicate would pass the existence checks.
  SELECT count(*) INTO n_dup_q FROM (
    SELECT politician_id, question_id
      FROM essentials.quotes
     WHERE readrank_selected AND question_id IS NOT NULL
     GROUP BY politician_id, question_id
    HAVING count(*) > 1
  ) d;
  IF n_dup_q <> 0 THEN
    RAISE EXCEPTION 'Aborting: % (politician, question) pair(s) hold more than one selected quote.', n_dup_q;
  END IF;

  SELECT count(*) INTO n_dup_topic FROM (
    SELECT politician_id, lower(topic_key) AS tk
      FROM essentials.quotes
     WHERE readrank_selected AND question_id IS NULL
     GROUP BY politician_id, lower(topic_key)
    HAVING count(*) > 1
  ) d;
  IF n_dup_topic <> 0 THEN
    RAISE EXCEPTION 'Aborting: % compass-era (politician, topic) pair(s) hold more than one selected quote — 293''s guarantee was lost.', n_dup_topic;
  END IF;

  -- Informational, not a gate: how many race/topic pairs now host two questions with served
  -- quotes. Expected 0 immediately after this migration (nothing is seated by it). A non-zero
  -- count here means the read-rank client MUST already be keying cards on `key` — see the
  -- outstanding note in the header — and is what check-readrank-question-unit.mjs fails on.
  SELECT count(*) INTO n_split FROM (
    SELECT rq.race_id, rq.topic_key
      FROM essentials.readrank_questions rq
      JOIN essentials.quotes q
        ON q.question_id = rq.id
       AND q.readrank_selected
       AND q.deidentified_text IS NOT NULL
     GROUP BY rq.race_id, rq.topic_key
    HAVING count(DISTINCT rq.id) > 1
  ) s;

  RAISE NOTICE 'OK: constraint re-keyed to (politician, question); 293''s guarantee retained for compass-era rows. % race/topic pair(s) currently host >1 question with served quotes.', n_split;
END $$;

COMMIT;
