-- Migration 730: Bryan "Bubba" Fish (Culver City Council) Stances
-- Phase 130 — Culver City. Bryan Fish (public name "Bubba Fish"), external_id -700551, UUID 6ed5080f-e7cf-493b-9424-80dcbc8d54d0.
-- Council Member (rotational; serving as Vice Mayor). Elected Nov 2024.
-- Topic UUIDs: housing=669cac97-66a6-4087-b036-936fbe62efb3  homelessness-response=6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- rent-regulation=c308e8e8-caac-44f5-ab04-dbfecf40bbe2  transportation-priorities=ba59337e-30e2-4aba-a39a-426b3366eb27
-- climate-change=f1e44d66-5d27-4b51-b54f-b7ace86f6a3c  public-safety-approach=e9ebefcd-c496-45e8-b816-a79f8442ba85

BEGIN;

-- housing = 1.0 (housing for all incomes; Housing & Homelessness Vice Chair; CA housing history vote)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', '669cac97-66a6-4087-b036-936fbe62efb3', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Council Member Fish makes "housing for people of all incomes" his top priority. As Vice Chair of Culver City's Committee on Housing & Homelessness he worked to increase affordable housing production, and he has championed precedent-setting Culver City housing reforms, a strongly pro-supply, pro-affordability position.$$,
ARRAY['https://bubbafish.org/issues','https://bubbafish.org/news/fg8gw9h4hlw9tk6teb95w4haw8otg5-afbzt-ya2zt']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response = 2.0 (supportive housing + safe sleep; services)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$As Vice Chair of the Committee on Housing & Homelessness, Fish worked to support unhoused residents and advocated for creating supportive housing and safe-sleep projects — a services-and-housing-first approach to homelessness.$$,
ARRAY['https://bubbafish.org/meet-bubba']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- rent-regulation = 2.0 (eviction protections, right to counsel)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Fish, a renter himself, ran on comprehensive tenant protections: eviction protections for tenants owing less than one month's rent, proactive outreach connecting tenants served eviction notices to services, and legal representation for renters facing eviction.$$,
ARRAY['https://patch.com/california/culvercity/meet-bryan-bubba-fish-candidate-city-council-culver-city']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- transportation-priorities = 1.0 (transit/micromobility professional, Streets For All)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$A transportation professional and Streets For All steering-committee member, Fish makes mobility a top priority — investing in transit, expanding the micromobility network, and making streets safer. He co-led state advocacy that lowered speed limits and legalized speed cameras, a strongly multimodal, anti-car-violence transportation stance.$$,
ARRAY['https://la.streetsblog.org/2024/11/22/interview-with-culver-city-councilmember-elect-bubba-fish','https://www.streetsforall.org/culver-city']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change = 2.0 (climate resiliency via transit/streets)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Fish frames mobility explicitly around climate, prioritizing climate resiliency and "climate-resilient safe streets" and fast, frequent transit as tools to cut emissions and address the climate crisis.$$,
ARRAY['https://bubbafish.org/issues']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 2.0 (budget "rooted in services and care")
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ed5080f-e7cf-493b-9424-80dcbc8d54d0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Fish's public-safety framing centers a city budget "rooted in services and care," favoring a services-oriented approach to safety over an enforcement-first model.$$,
ARRAY['https://patch.com/california/culvercity/meet-bryan-bubba-fish-candidate-city-council-culver-city']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
