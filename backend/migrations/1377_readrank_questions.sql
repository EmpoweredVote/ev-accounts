-- 1377_readrank_questions.sql
-- Make the Read & Rank QUESTION the first-class unit of comparison.
-- Adds essentials.readrank_questions (N questions per (race, topic_key), each parented
-- to a compass topic via topic_key) and essentials.quotes.question_id (a quote answers
-- exactly one question). Folds the per-(race,topic) override table (1323) in as
-- confirmed 'emergent' questions. Rankability is DERIVED, not stored (see
-- src/lib/readrankQuestionsService.ts).
-- Additive + idempotent: safe to re-run; does not touch existing topic-level read paths.

BEGIN;

CREATE TABLE IF NOT EXISTS essentials.readrank_questions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  race_id         uuid NOT NULL REFERENCES essentials.races(id) ON DELETE CASCADE,
  topic_key       text NOT NULL CHECK (topic_key = lower(topic_key)),
  question_text   text NOT NULL CHECK (length(btrim(question_text)) > 0),
  origin          text NOT NULL CHECK (origin IN ('compass','moderator','emergent')),
  origin_quote_id uuid REFERENCES essentials.quotes(id) ON DELETE SET NULL,
  source_ref      jsonb,
  status          text NOT NULL DEFAULT 'proposed' CHECK (status IN ('proposed','confirmed','rejected')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      text
);

COMMENT ON TABLE essentials.readrank_questions IS
  'Read & Rank ranking questions — the first-class unit of comparison. N per (race, topic_key); topic_key parents to inform.compass_topics for Compass coupling. Rankability is derived, not stored (src/lib/readrankQuestionsService.ts).';

CREATE INDEX IF NOT EXISTS readrank_questions_race_topic_idx
  ON essentials.readrank_questions (race_id, topic_key);

ALTER TABLE essentials.quotes
  ADD COLUMN IF NOT EXISTS question_id uuid REFERENCES essentials.readrank_questions(id) ON DELETE SET NULL;

COMMENT ON COLUMN essentials.quotes.question_id IS
  'The Read & Rank question this quote answers (essentials.readrank_questions.id). NULL until attached by publish/curation. topic_key is retained for Compass coupling.';

CREATE INDEX IF NOT EXISTS quotes_question_id_idx
  ON essentials.quotes (question_id);

-- Fold the per-(race,topic) override table (1323) in as confirmed race-local questions.
-- Overrides were curator-set race-local reframings -> origin 'emergent'; already live -> 'confirmed'.
INSERT INTO essentials.readrank_questions (race_id, topic_key, question_text, origin, status, updated_by)
SELECT src.race_id, src.topic_key, src.question_text, 'emergent', 'confirmed', src.updated_by
FROM essentials.readrank_race_topic_questions src
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.readrank_questions rq
  WHERE rq.race_id = src.race_id
    AND rq.topic_key = src.topic_key
    AND rq.question_text = src.question_text
);

COMMIT;
