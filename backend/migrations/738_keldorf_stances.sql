-- Migration 738: Michelle Keldorf (El Segundo Council) Stances
-- Phase 131 — El Segundo. Michelle Keldorf, external_id -700654, UUID 2616c881-04da-4ec4-975b-4f82235ccf21.
-- Council Member (rotational). Commercial real estate / land use; elected 2024.
BEGIN;

-- public-safety-approach = 4.0 (resource Police/Fire chiefs; safety top priority)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2616c881-04da-4ec4-975b-4f82235ccf21', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2616c881-04da-4ec4-975b-4f82235ccf21', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Council Member Keldorf makes resident health and safety her top priority and commits to giving the Police and Fire chiefs the resources needed for the highest level of service, an enforcement/services-supportive public-safety posture.$$,
ARRAY['https://www.votemichellekeldorf.com/positions']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 3.0 (meet state housing requirements while preserving character)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2616c881-04da-4ec4-975b-4f82235ccf21', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2616c881-04da-4ec4-975b-4f82235ccf21', '669cac97-66a6-4087-b036-936fbe62efb3',
$$A former Planning Commissioner who helped secure a state-certified Housing Element, Keldorf supports policies that address state housing requirements while maintaining El Segundo's unique character, a moderate position balancing mandated production against neighborhood preservation.$$,
ARRAY['https://www.votemichellekeldorf.com/positions']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 2.0 (coastline/environment; LA LCV endorsement)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2616c881-04da-4ec4-975b-4f82235ccf21', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2616c881-04da-4ec4-975b-4f82235ccf21', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Keldorf earned the endorsement of the Los Angeles League of Conservation Voters and emphasizes protecting the coastline and local environmental well-being, a pro-environment local stance.$$,
ARRAY['https://www.votemichellekeldorf.com/positions']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
