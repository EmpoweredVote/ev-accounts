-- Migration 736: Drew Boyles (El Segundo Council) Stances
-- Phase 131 — El Segundo. Drew Boyles, external_id -700652, UUID 4e485d3a-79a0-40ce-a52f-f84d187bf5de.
-- Council Member (rotational; Mayor 2018–2024). Entrepreneur/CEO.
BEGIN;

-- economic-development = 2.0 (business-recruitment champion)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4e485d3a-79a0-40ce-a52f-f84d187bf5de', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4e485d3a-79a0-40ce-a52f-f84d187bf5de', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$As Mayor and former Economic Development Advisory Council chair, Boyles spearheaded aggressive economic-development efforts, courting hundreds of new businesses and promoting El Segundo as having the highest venture funding per square mile, a strongly pro-business-development position.$$,
ARRAY['https://www.elsegundo.gov/government/departments/city-council-elected-officials/mayor-drew-boyles']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- residential-zoning = 4.0 (advocated to protect single-family neighborhoods)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4e485d3a-79a0-40ce-a52f-f84d187bf5de', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4e485d3a-79a0-40ce-a52f-f84d187bf5de', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Boyles advocated regionally and statewide to protect single-family housing neighborhoods, a position favoring preservation of low-density residential zoning against upzoning mandates.$$,
ARRAY['https://drewforelsegundo.com/about-drew/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- growth-and-development = 4.0 (preserve small-town charm + fiscal restraint)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4e485d3a-79a0-40ce-a52f-f84d187bf5de', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4e485d3a-79a0-40ce-a52f-f84d187bf5de', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Boyles paired business growth with "preserving El Segundo's small-town charm" and responsible fiscal management, favoring measured, character-preserving development.$$,
ARRAY['https://www.elsegundo.gov/government/departments/city-council-elected-officials/mayor-drew-boyles']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes = 4.0 (responsible fiscal management)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4e485d3a-79a0-40ce-a52f-f84d187bf5de', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4e485d3a-79a0-40ce-a52f-f84d187bf5de', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Boyles, an entrepreneur and former finance consultant, emphasized responsible fiscal management as a hallmark of his mayoral tenure, a fiscally conservative orientation.$$,
ARRAY['https://cdn.southbaycities.org/sites/default/files/Boyles%20Bio.pdf']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
