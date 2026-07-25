-- 1347_retire_ca_governor_economic_development_override.sql
-- Retire the CA-Governor × economic-development race-local question override (seeded by
-- migration 1345). That override existed ONLY to work around the city-scoped global Compass
-- question ("How should your city attract businesses…"), which is now fixed globally by
-- migration 1346 to "How should government attract businesses and support economic
-- development?" — correct for a statewide race.
--
-- Per QUOTE-CURATION-PRINCIPLES §7.1, a per-race override that merely re-scopes (city→state)
-- should not persist once the scope is corrected globally; only genuine race-specific
-- reframes belong in essentials.readrank_race_topic_questions. The CA-Governor × fossil-fuels
-- override (migration 1324) is such a reframe and is intentionally left in place.
--
-- Effect: CA Governor's economic-development ranking question falls back to the (now-neutral)
-- global Compass question. Idempotent; reversible by re-running migration 1345.

BEGIN;

DELETE FROM essentials.readrank_race_topic_questions
WHERE race_id = 'bc936a36-287c-4ffd-abd8-5e4fd798bae5'  -- CA Governor (CA 2026 Statewide General)
  AND topic_key = 'economic-development';

COMMIT;
