-- Migration 759: Maria Davila (South Gate Council) Stances
-- Phase 135 — South Gate. Maria Davila, external_id -700200, UUID cbc8c88e-492d-4e7b-8e8d-cfd573a1afc5. Rotational mayor.
BEGIN;
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('cbc8c88e-492d-4e7b-8e8d-cfd573a1afc5','669cac97-66a6-4087-b036-936fbe62efb3',2.0) ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('cbc8c88e-492d-4e7b-8e8d-cfd573a1afc5','669cac97-66a6-4087-b036-936fbe62efb3',$$Council Member Davila serves as Chairperson of the South Gate Housing Authority, leading the city's affordable-housing and rental-assistance programs, a housing-supportive role.$$,ARRAY['https://www.cityofsouthgate.org/Government/City-Council/Meet-the-City-Council/Council-Member-Maria-Davila']::text[]::text[]) ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
COMMIT;
