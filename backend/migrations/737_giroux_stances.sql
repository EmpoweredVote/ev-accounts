-- Migration 737: Lance Giroux (El Segundo Council) Stances
-- Phase 131 — El Segundo. Lance Giroux, external_id -700653, UUID 70dec2bf-c58c-4e3e-abbb-59a600d444d7.
-- Council Member (rotational). Business executive (Dynasty Footwear); reelected 2024.
BEGIN;

-- economic-development = 2.0 (backs business attraction/retention priorities)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70dec2bf-c58c-4e3e-abbb-59a600d444d7', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70dec2bf-c58c-4e3e-abbb-59a600d444d7', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$A longtime business executive, Council Member Giroux backs the council's adopted top priority of attracting new businesses and fostering B2B networking to retain and grow existing El Segundo businesses.$$,
ARRAY['https://www.elsegundo.org/government/departments/city-manager-s-office/city-strategic-plan']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- growth-and-development = 4.0 (growth that preserves quality of life / small-town character)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('70dec2bf-c58c-4e3e-abbb-59a600d444d7', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('70dec2bf-c58c-4e3e-abbb-59a600d444d7', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Giroux supports the council priority of land-use and enforcement policies that "encourage growth while preserving El Segundo's quality of life and small-town character," a controlled-growth, preservationist stance.$$,
ARRAY['https://www.elsegundo.org/government/departments/city-manager-s-office/city-strategic-plan']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
