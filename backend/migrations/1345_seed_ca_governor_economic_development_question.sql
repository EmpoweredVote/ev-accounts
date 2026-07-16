-- 1345_seed_ca_governor_economic_development_question.sql
-- Race-local ranking-question override: CA Governor × economic-development.
-- Bridge fix surfaced by the CA-governor question re-audit: the Compass question is
-- city-scoped ("How should your city attract businesses…"), wrong for a statewide race.
-- That mis-scoping is systemic and is separately escalated to compass-topic-builder; this
-- override re-scopes to California on the SAME axis (attract business / incentives), blind.
-- Idempotent: re-running updates the wording in place.

BEGIN;

INSERT INTO essentials.readrank_race_topic_questions (race_id, topic_key, question_text, updated_by)
VALUES (
  'bc936a36-287c-4ffd-abd8-5e4fd798bae5',  -- essentials.races: CA Governor (CA 2026 Statewide General)
  'economic-development',
  'How should California attract businesses and support economic development?',
  'migration:1345'
)
ON CONFLICT (race_id, topic_key) DO UPDATE
  SET question_text = EXCLUDED.question_text,
      updated_at    = now(),
      updated_by    = EXCLUDED.updated_by;

COMMIT;
