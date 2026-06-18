-- Migration 726: Andre Spicer (Compton City Council, District 2) Stances
-- Phase 129 — Compton Stances. Andre Spicer, external_id -700252, UUID f63d8129-c569-4ea5-bd77-5cda877b2185.
-- Council Member (District 2), currently Mayor Pro Tem.
-- Topic UUID reference:
-- homelessness-response = 6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing               = 669cac97-66a6-4087-b036-936fbe62efb3
-- public-safety-approach= e9ebefcd-c496-45e8-b816-a79f8442ba85
-- economic-development  = eb3d1247-0de1-4b7f-baec-7259861efd53
-- local-environment     = 1935979c-b290-42e4-baa5-8cb0138b4ffa

BEGIN;

-- homelessness-response = 2.0 (shelter-first + wrap-around services)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Council Member Spicer makes shelter development his top homelessness priority and emphasizes wrap-around services that address root causes such as mental illness, substance use, and reentry from incarceration so people do not return to the street, saying "we clean up the community by housing the community." His approach centers on building shelter capacity and services rather than enforcement alone.$$,
ARRAY['https://www.ursulavari.com/post/interview-with-councilman-andre-spicer']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 2.0 (garage-conversion / ADU program for unhoused and low-income tenants)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Council Member Spicer supports a program letting homeowners legally convert garages into livable units and collect up to $1,000 in rent to house unhoused and low-income tenants, expanding housing supply through accessory units.$$,
ARRAY['https://www.lawattstimes.com/index.php?option=com_content&view=article&id=7530','https://www.ursulavari.com/post/interview-with-councilman-andre-spicer']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 1.0 (rejects enforcement-first; ceasefire, resources, intervention)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Council Member Spicer explicitly rejects an enforcement-first model, stating "Public safety for me has almost nothing to do with law enforcement." He favors ceasefire agreements, community resources, and job training for formerly incarcerated residents, and personally engages gang members and transients through dialogue, arguing crime falls when the community is given resources.$$,
ARRAY['https://www.ursulavari.com/post/interview-with-councilman-andre-spicer']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- economic-development = 2.0 (local-business destination, small-business growth, investment)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Council Member Spicer envisions Compton Boulevard as a destination of locally owned restaurants, shops, and entertainment, encouraging outside investment while supporting small businesses to grow; he has himself opened local businesses to promote economic growth.$$,
ARRAY['https://www.ursulavari.com/post/interview-with-councilman-andre-spicer','https://www.lawattstimes.com/index.php?option=com_content&view=article&id=7530']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 2.0 (tree trimming, cleanliness, urban upkeep)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f63d8129-c569-4ea5-bd77-5cda877b2185', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Council Member Spicer emphasizes neighborhood environmental upkeep — tree trimming, graffiti removal, and community cleanliness — framing a clean, well-maintained public realm as a shared municipal and resident responsibility.$$,
ARRAY['https://www.ursulavari.com/post/interview-with-councilman-andre-spicer']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
