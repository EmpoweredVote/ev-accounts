-- 1378_backfill_readrank_topic_questions.sql
-- Behavior-preserving backfill: shift existing topic-attached quotes onto the question model.
-- Mints ONE readrank_question per (race, topic_key) that has quotes on a LIVE compass topic
-- (question_text = per-race override ?? Compass question), then attaches each quote's question_id.
-- Because it is one question per (race, topic), question-level rankability == today's topic-level
-- rankability (the playable-races set is unchanged; it is just re-expressed on the question model).
--
-- Applied to PROD 2026-07-21 via the Supabase MCP (execute_sql), not this file, and saved here as
-- the durable record. Idempotent + additive; safe to re-run.
--   Result: 3079 questions created (+1 pre-existing fold-in); 4322 quotes attached.
--   New rankable questions 634 / 163 races vs. old topic-level 659 / 166 — the -25 / -3 gap is the
--   87 quotes of 8 multi-race politicians (same-seat primary+general or duplicate race rows), left
--   UNATTACHED on purpose (a quote row carries one question_id). Resolve via race dedup, separately.
--
-- REVERSAL (nothing else writes question_id yet):
--   UPDATE essentials.quotes SET question_id = NULL;
--   DELETE FROM essentials.readrank_questions WHERE updated_by = 'backfill-topic-questions';

BEGIN;

-- Step A: one confirmed question per (race, topic) with quotes on a live compass topic.
INSERT INTO essentials.readrank_questions (race_id, topic_key, question_text, origin, status, updated_by)
SELECT DISTINCT rc.race_id,
       lower(q.topic_key) AS topic_key,
       COALESCE(rtq.question_text, t.question_text) AS question_text,
       CASE WHEN rtq.question_text IS NOT NULL THEN 'emergent' ELSE 'compass' END AS origin,
       'confirmed', 'backfill-topic-questions'
FROM essentials.quotes q
JOIN essentials.race_candidates rc
  ON rc.politician_id = q.politician_id AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
JOIN inform.compass_topics t
  ON t.topic_key = lower(q.topic_key) AND t.is_live = true
LEFT JOIN essentials.readrank_race_topic_questions rtq
  ON rtq.race_id = rc.race_id AND rtq.topic_key = lower(q.topic_key)
WHERE q.question_id IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.readrank_questions rq
    WHERE rq.race_id = rc.race_id AND rq.topic_key = lower(q.topic_key)
  );

-- Step B: attach quotes whose politician is in exactly ONE non-withdrawn race (unambiguous).
-- Multi-race politicians are left unattached for deliberate race-dedup handling.
UPDATE essentials.quotes q
SET question_id = rq.id, updated_at = now()
FROM essentials.readrank_questions rq,
     essentials.race_candidates rc,
     inform.compass_topics t
WHERE q.question_id IS NULL
  AND rc.politician_id = q.politician_id
  AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn'
  AND rq.race_id = rc.race_id
  AND rq.topic_key = lower(q.topic_key)
  AND t.topic_key = lower(q.topic_key) AND t.is_live = true
  AND (SELECT count(DISTINCT rc2.race_id) FROM essentials.race_candidates rc2
       WHERE rc2.politician_id = q.politician_id
         AND COALESCE(rc2.candidate_status, 'active') <> 'withdrawn') = 1;

COMMIT;
