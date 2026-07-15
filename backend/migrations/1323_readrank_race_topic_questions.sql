-- 1323_readrank_race_topic_questions.sql
-- Per-(race, topic) override for the Read & Rank "ranking question".
-- The public payload resolves COALESCE(override, inform.compass_topics.question_text),
-- so an unset row falls back to the canonical Compass question. Axis-invariant by
-- curation policy (QUOTE-CURATION-PRINCIPLES §7.3): stores reframed wording only,
-- never a different topic/axis.

BEGIN;

CREATE TABLE IF NOT EXISTS essentials.readrank_race_topic_questions (
  race_id       uuid NOT NULL REFERENCES essentials.races(id) ON DELETE CASCADE,
  topic_key     text NOT NULL CHECK (topic_key = lower(topic_key)),
  question_text text NOT NULL CHECK (length(btrim(question_text)) > 0),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    text,
  PRIMARY KEY (race_id, topic_key)
);

COMMENT ON TABLE essentials.readrank_race_topic_questions IS
  'Read & Rank per-race ranking-question override; resolves via COALESCE over inform.compass_topics.question_text. Axis-invariant (QUOTE-CURATION-PRINCIPLES §7.3).';

COMMIT;
