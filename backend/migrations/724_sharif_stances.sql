-- Migration 724: Emma Sharif (Compton Mayor) Stances
-- Phase 129 — Compton Stances. Emma Sharif, external_id -700250, UUID 174f3f47-e4ee-4775-ab6f-f1039d608098.
-- Directly elected Mayor (LOCAL_EXEC) — "Mayor Sharif" is correct; NOT rotational.
-- Topic UUID reference (44 active topics):
-- homelessness-response = 6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing               = 669cac97-66a6-4087-b036-936fbe62efb3
-- growth-and-development= fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- economic-development  = eb3d1247-0de1-4b7f-baec-7259861efd53
-- public-safety-approach= e9ebefcd-c496-45e8-b816-a79f8442ba85
-- transportation-priorities = ba59337e-30e2-4aba-a39a-426b3366eb27
-- local-environment     = 1935979c-b290-42e4-baa5-8cb0138b4ffa

BEGIN;

-- homelessness-response = 2.0 (Housing First / permanent supportive housing)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Mayor Sharif champions a Housing First approach to homelessness, prioritizing moving residents into safe permanent housing to reduce chronic homelessness rather than enforcement-first clearance. Her administration supported the Willow Tree permanent supportive housing project and a Project Homekey permanent housing development in Compton, and she has coordinated regional partnerships with LA County agencies to address homelessness.$$,
ARRAY['https://www.reelectmayorsharif.com/meet-emma','https://homeless.lacounty.gov/news/first-project-homekey-permanent-housing-opens-in-compton/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 2.0 (affordable housing in mixed-use development)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Mayor Sharif has actively advanced affordable housing through mixed-use development, announcing a $21 million mixed-use retail-and-affordable-housing project and backing the 501/601 Compton Boulevard downtown development that includes up to 300 residential units with 20 percent designated affordable. She frames new housing production as central to addressing both affordability and homelessness.$$,
ARRAY['https://lasentinel.net/comptons-corner.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- growth-and-development = 2.0 (downtown revitalization, mixed-use density)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Mayor Sharif is pro-development, driving a downtown Compton revitalization centered on a seven-story, 266,792-square-foot mixed-use project with a pedestrian plaza, the Compton Innovation Hub, and creative studios. She supports denser mixed-use growth as a path to new revenue and amenities for residents.$$,
ARRAY['https://lasentinel.net/comptons-corner.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- economic-development = 2.0 (business recruitment, small-business support, workforce training)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Mayor Sharif prioritizes active economic development: recruiting businesses to grow general-fund revenue, supporting small businesses and local entrepreneurs to keep dollars in Compton, and providing workforce training and job pathways connected to real employment opportunities.$$,
ARRAY['https://www.reelectmayorsharif.com/meet-emma','https://www.ballotready.org/people/emma-sharif']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 2.0 (community violence prevention, youth intervention, trust-building)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Mayor Sharif emphasizes a prevention-oriented public-safety approach, backing a Violence Reduction Network that pairs the Sheriff's Compton station with community-based violence prevention, youth intervention, services for mental illness and homelessness, and trust-building between residents and law enforcement rather than enforcement alone.$$,
ARRAY['https://lasentinel.net/compton-officials-announce-violence-reduction-network.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- transportation-priorities = 2.0 (pedestrian/bicycle safety, crosswalk upgrades)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Mayor Sharif launched a $19.5 million infrastructure improvement program that funds road maintenance alongside pedestrian and bicycle safety measures and more than 100 crosswalk upgrades across all four council districts, reflecting a multimodal, safety-focused transportation priority.$$,
ARRAY['https://www.comptoncity.org/our-city/elected-officials/mayor-emma-sharif','https://www.reelectmayorsharif.com/meet-emma']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 2.0 (tree maintenance, beautification)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('174f3f47-e4ee-4775-ab6f-f1039d608098', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Mayor Sharif invested $1.2 million in professional tree maintenance through an eco-friendly partnership and launched a Clean and Beautify Compton initiative to revitalize public space, signaling support for local environmental and urban-greening efforts.$$,
ARRAY['https://www.reelectmayorsharif.com/meet-emma']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
