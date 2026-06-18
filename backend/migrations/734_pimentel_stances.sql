-- Migration 734: Chris Pimentel (El Segundo Council) Stances
-- Phase 131 — El Segundo. Chris Pimentel, external_id -700650, UUID 1c77d036-8c9e-4831-9bba-40af2d043ed2.
-- Council Member (rotational; Mayor since 2024).
BEGIN;

-- growth-and-development = 4.0 (responsible/controlled growth; preserve character)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c77d036-8c9e-4831-9bba-40af2d043ed2', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c77d036-8c9e-4831-9bba-40af2d043ed2', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Council Member Pimentel campaigns on "Responsible Growth" and has focused his service on preserving and sustaining the elements that make El Segundo a unique small city, favoring controlled, character-preserving development over rapid growth.$$,
ARRAY['https://www.elsegundo.gov/government/departments/city-council-elected-officials/councilmember-chris-pimentel']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 4.0 (Safety & Service priority; well-resourced services)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c77d036-8c9e-4831-9bba-40af2d043ed2', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c77d036-8c9e-4831-9bba-40af2d043ed2', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Pimentel, a former Marine Corps infantry officer, makes "Safety & Service" a central priority, emphasizing well-resourced public-safety services for El Segundo — an enforcement/services-supportive posture.$$,
ARRAY['https://www.facebook.com/pimmyforthecity']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- economic-development = 2.0 (leads city pro-business strategic plan)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c77d036-8c9e-4831-9bba-40af2d043ed2', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c77d036-8c9e-4831-9bba-40af2d043ed2', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$As Mayor, Pimentel leads a city strategic plan whose top priorities include attracting new businesses and fostering B2B networking to retain and grow existing businesses, treating El Segundo as a "thriving economic engine of the region."$$,
ARRAY['https://www.elsegundo.org/government/departments/city-manager-s-office/city-strategic-plan']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
