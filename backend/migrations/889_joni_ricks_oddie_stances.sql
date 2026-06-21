-- Migration 889: Joni Ricks-Oddie (Long Beach Council D9, 665842) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 8 placements, 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('housing',2),('homelessness-response',2),('rent-regulation',2),('residential-zoning',3),
  ('growth-and-development',3),('economic-development',3),('local-environment',2),('climate-change',2)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665842
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('housing', $$Led North Long Beach's first major rezoning in 30 years, delivered 84 townhomes, advanced a 200-unit affordable housing campus and student housing while emphasizing protecting families from displacement.$$, ARRAY['https://www.votedrjoni.com/platform']),
  ('homelessness-response', $$Expanded shelters, launched a Safe Parking Program, added modular housing and secured homes for 570+ residents through vouchers, prioritizing permanent supportive housing and mental health services.$$, ARRAY['https://www.votedrjoni.com/platform','https://www.longbeach.gov/press-releases/city-extends-operations-for-safe-parking-program-relocates-site-to-close-to-multi-service-center/']),
  ('rent-regulation', $$As Budget Oversight chair she supports the city's tenant right-to-counsel/eviction defense fund and proposed adding up to $500,000 to strengthen eviction protections if surplus funds materialize.$$, ARRAY['https://lbpost.com/news/budget-committee-tenant-eviction-fund-budget-oversight/']),
  ('residential-zoning', $$Championed North Long Beach's first major rezoning in three decades to enable townhomes and multifamily growth along the district's corridors.$$, ARRAY['https://www.votedrjoni.com/platform']),
  ('growth-and-development', $$Led rezoning aimed at 'smart, equitable growth while protecting families from displacement,' favoring planned, equity-oriented development.$$, ARRAY['https://www.votedrjoni.com/platform']),
  ('economic-development', $$Connected 2,900+ businesses to city resources through Small Business Walks and storefront support and plans to strengthen corridors and support micro-businesses, a targeted community-benefits approach.$$, ARRAY['https://www.votedrjoni.com/platform']),
  ('local-environment', $$Secured nearly $10 million for a greenbelt along the 91 freeway, funded parks/playground upgrades in the city's most park-deficient district, and championed cool pavement and tree canopy growth.$$, ARRAY['https://www.votedrjoni.com/platform']),
  ('climate-change', $$An epidemiologist who champions clean air initiatives at the Port and environmental justice for residents affected by 710/91 freeway pollution, supporting clean energy and green jobs.$$, ARRAY['https://www.votedrjoni.com/platform','https://www.votedrjoni.com/about'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665842
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
