-- 1379_prune_orphaned_readrank_questions.sql
-- Prune the machine-minted readrank_questions rows left quote-less by the 2026-07-25 aggregator
-- quote purge (1,173 ontheissues.org + 273 en.wikipedia.org rows deleted from essentials.quotes).
--
-- WHY THESE ROWS CARRY NO CURATION. All 767 quote-less rows were origin='compass',
-- updated_by='backfill-topic-questions' — minted by 1378 Step A, one per (race, topic). For every
-- one: question_text was byte-identical to inform.compass_topics.question_text, origin_quote_id
-- and source_ref were NULL, and no essentials.readrank_race_topic_questions override existed. They
-- are fully reconstructible from (race_id, topic_key) by re-running 1378 Step A. Every
-- hand-authored question (6 'emergent' tx-senate, 1 'moderator' mi-senate, 1 from 1324) still had
-- quotes — none were touched.
--
-- WHY ONLY 652 OF THE 767. The other 115 (17 races) still have UNATTACHED quotes on the same
-- (race, topic) — 110 of them live (readrank_selected + deidentified_text). Those are the
-- multi-race-politician quotes 1378 Step B skipped on purpose ("the -25 / -3 gap ... resolve via
-- race dedup, separately"). Those question rows legitimately outlive their originating quotes:
-- they are where the pending race-dedup attach will land. KEPT DELIBERATELY.
--
-- BLAST RADIUS. essentials.readrank_questions has exactly one consumer: the admin coverage grid
-- (GET /api/admin/readrank-coverage -> readrankCoverageService.getCoverageGrid +
-- readrankQuestionsService.listRaceQuestions). The public read-rank path
-- (readrankService.getRaceBlindQuotes) does NOT read this table — it still uses
-- essentials.readrank_race_topic_questions + inform.compass_topics. So no user-facing change; the
-- grid simply loses 652 all-empty rows across 201 races that were burying real gaps.
-- No FK fallout: quotes.question_id is NULL for all of these by definition, and their own
-- origin_quote_id was NULL.
--
-- Applied to PROD 2026-07-25 via psql, not this file; saved here as the durable record.
--   Result: essentials.readrank_questions 3081 -> 2429. Remaining orphans: 115 (all reattachable).
--   essentials.quotes untouched (4129 rows, 666 unattached).
--
-- REVERSAL: restorable backup of ALL 767 orphan rows (original UUIDs, ON CONFLICT DO NOTHING),
-- taken before the delete, outside any git repo:
--   /Users/chrisandrews/Documents/ev-db-backups/2026-07-25-orphaned-readrank-questions.restore.sql
--   /Users/chrisandrews/Documents/ev-db-backups/2026-07-25-orphaned-readrank-questions.csv
--     (CSV carries a `reattachable` flag: f = one of the 652 deleted, t = one of the 115 kept.)
-- Alternatively, re-run 1378 Step A to re-mint from inform.compass_topics (new UUIDs; nothing
-- references these ids).
--
-- Idempotent: re-running deletes nothing once the orphan set is empty of dead rows.

BEGIN;

DELETE FROM essentials.readrank_questions rq
WHERE NOT EXISTS (
    SELECT 1 FROM essentials.quotes q WHERE q.question_id = rq.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM essentials.quotes q2
    JOIN essentials.race_candidates rc
      ON rc.politician_id = q2.politician_id
     AND rc.race_id = rq.race_id
     AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
    WHERE q2.question_id IS NULL
      AND lower(q2.topic_key) = rq.topic_key
  );

COMMIT;
