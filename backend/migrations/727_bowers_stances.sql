-- Migration 727: Jonathan Bowers (Compton City Council, District 3) Stances
-- Phase 129 — Compton Stances. Jonathan Bowers, external_id -700253, UUID 9a37b6e4-13bc-48c0-97b3-22aaa253c054.
-- Council Member (District 3), elected 2021.
-- Topic UUID reference:
-- public-safety-approach= e9ebefcd-c496-45e8-b816-a79f8442ba85
-- economic-development  = eb3d1247-0de1-4b7f-baec-7259861efd53
-- housing               = 669cac97-66a6-4087-b036-936fbe62efb3
-- local-environment     = 1935979c-b290-42e4-baa5-8cb0138b4ffa

BEGIN;

-- public-safety-approach = 3.0 (pragmatic: targeted enforcement + commissions/prevention)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9a37b6e4-13bc-48c0-97b3-22aaa253c054', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9a37b6e4-13bc-48c0-97b3-22aaa253c054', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Council Member Bowers brings four decades in emergency response and pledges to "revamp the public safety model," pairing targeted enforcement — an auto-takeover ordinance with vehicle-confiscation provisions — with structural and preventive measures such as restoring the Public Safety and Beautification Commissions and resident safety education. The combination reflects a pragmatic, balanced public-safety approach.$$,
ARRAY['https://www.comptoncity.org/our-city/elected-officials/district-3-jonathan-bowers']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- economic-development = 2.0 (job training/trades, street-vendor permitting, business revival)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9a37b6e4-13bc-48c0-97b3-22aaa253c054', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9a37b6e4-13bc-48c0-97b3-22aaa253c054', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Council Member Bowers advances economic opportunity through a Path-to-Permit ordinance legalizing street vendors, job-training partnerships teaching residents trades like landscaping and EMT skills, support for reopening local businesses, and the Compton Golf Course revitalization.$$,
ARRAY['https://www.comptoncity.org/our-city/elected-officials/district-3-jonathan-bowers','https://2urbangirls.com/2021/05/jonathan-bowers-is-the-best-choice-for-compton-city-council-district-3/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 2.0 (supported new residential development)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9a37b6e4-13bc-48c0-97b3-22aaa253c054', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9a37b6e4-13bc-48c0-97b3-22aaa253c054', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Council Member Bowers has backed new residential development along Compton Boulevard and Central Avenue, supporting expanded housing production in District 3.$$,
ARRAY['https://www.comptoncity.org/our-city/elected-officials/district-3-jonathan-bowers']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 2.0 (beautification commission, community cleanups)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9a37b6e4-13bc-48c0-97b3-22aaa253c054', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9a37b6e4-13bc-48c0-97b3-22aaa253c054', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Council Member Bowers worked to restore Compton's Beautification Commission and regularly organizes community cleanups with neighborhood block clubs, prioritizing a cleaner, greener public environment in District 3.$$,
ARRAY['https://www.comptoncity.org/our-city/elected-officials/district-3-jonathan-bowers']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
