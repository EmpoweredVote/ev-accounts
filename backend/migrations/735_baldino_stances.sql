-- Migration 735: Ryan Baldino (El Segundo Council) Stances
-- Phase 131 — El Segundo. Ryan Baldino, external_id -700651, UUID eb515636-52b5-4c48-8052-f60d5d2f4652.
-- Council Member (rotational; Mayor Pro Tem). Attorney; 14 years Planning Commission.
BEGIN;

-- taxes = 4.0 (fiscal restraint: spend tax dollars wisely, balanced budget)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb515636-52b5-4c48-8052-f60d5d2f4652', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb515636-52b5-4c48-8052-f60d5d2f4652', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Council Member Baldino pledges to ensure tax dollars are spent wisely and the city budget stays balanced, a fiscally conservative orientation toward spending and taxation.$$,
ARRAY['https://baldinoforelsegundo.com/about-ryan/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 4.0 (highest level of safety and services)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb515636-52b5-4c48-8052-f60d5d2f4652', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb515636-52b5-4c48-8052-f60d5d2f4652', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Baldino prioritizes the highest level of safety and community services for residents, supporting well-resourced police and public-safety provision.$$,
ARRAY['https://baldinoforelsegundo.com/about-ryan/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- growth-and-development = 4.0 (grow responsibly, maintain small-town appeal)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb515636-52b5-4c48-8052-f60d5d2f4652', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb515636-52b5-4c48-8052-f60d5d2f4652', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$A 14-year Planning Commissioner who worked on rezoning and specific plans, Baldino commits to "growing responsibly while maintaining the small-town appeal and deep sense of community," a controlled-growth, preservationist position.$$,
ARRAY['https://baldinoforelsegundo.com/about-ryan/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
