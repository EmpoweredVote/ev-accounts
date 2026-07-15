-- 1324_seed_ca_governor_fossil_fuels_question.sql
-- First race-local Read & Rank ranking-question override: CA Governor × fossil fuels.
-- Near-verbatim from the actual debate question (on-the-record meeting
-- 6f206fe5-a18b-4af5-b945-c72178d53289, moderator Julie Watts), tightened for clarity.
-- Axis-invariant: still the fossil-fuels axis (role of oil & gas), just California-local
-- framing. Blind: names no candidate. Resolves via COALESCE over the Compass question.
-- Idempotent: re-running updates the wording in place.

BEGIN;

INSERT INTO essentials.readrank_race_topic_questions (race_id, topic_key, question_text, updated_by)
VALUES (
  'bc936a36-287c-4ffd-abd8-5e4fd798bae5',  -- essentials.races: CA Governor (CA 2026 Statewide General)
  'fossil-fuels',
  'How should California balance environmental concerns and regulations with the cost of gas?',
  'migration:1324'
)
ON CONFLICT (race_id, topic_key) DO UPDATE
  SET question_text = EXCLUDED.question_text,
      updated_at    = now(),
      updated_by    = EXCLUDED.updated_by;

COMMIT;
