-- Migration 882: Mary Zendejas (Long Beach Council D1, 665830) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 10 placements, 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('housing',2),('rent-regulation',2),('homelessness',2),('homelessness-response',2),
  ('public-safety-approach',2),('immigration',2),('local-immigration',2),('local-environment',2),
  ('climate-change',3),('economic-development',3)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665830
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('housing', $$Led a citywide Inclusionary Housing policy requiring affordable units in new developments and invested in affordable housing plus first-time homebuyer support.$$, ARRAY['https://www.maryzendejas.com/issues','https://www.maryzendejas.com/about']),
  ('rent-regulation', $$Authored tenant protections preventing unfair 'substantial remodel' evictions and invested in projects to prevent displacement.$$, ARRAY['https://www.maryzendejas.com/about','https://lbpost.com/news/politics/elections/long-beach-voter-guide-city-council-district-1/']),
  ('homelessness', $$Secured $6.5M for a new homeless shelter and funded outreach/Crisis Response Teams rather than pursuing criminalization.$$, ARRAY['https://www.maryzendejas.com/about','https://www.maryzendejas.com/issues']),
  ('homelessness-response', $$Expanded shelter capacity by 125 beds (183 more in progress) and backed State Encampment Resolution Grants as the primary strategy.$$, ARRAY['https://www.maryzendejas.com/issues']),
  ('public-safety-approach', $$Expanded Community Crisis Response into a permanent citywide non-police mental health emergency response while keeping fire/paramedic staffing.$$, ARRAY['https://www.maryzendejas.com/issues']),
  ('immigration', $$Voted to denounce ICE enforcement actions and publicly advocates for immigrant communities, including canceling events over enforcement fears.$$, ARRAY['https://www.cbsnews.com/amp/losangeles/news/long-beach-dia-de-los-muertos-canceled-immigration-enforcement','https://lbwatchdog.com/we-asked-long-beach-officials-your-questions-about-ice/']),
  ('local-immigration', $$Joined a unanimous council vote denouncing federal immigration agents' actions, signaling opposition to local cooperation with aggressive ICE enforcement.$$, ARRAY['https://www.cbsnews.com/amp/losangeles/news/long-beach-dia-de-los-muertos-canceled-immigration-enforcement']),
  ('local-environment', $$Doubled annual tree planting (745 new street trees) and leveraged $1.97M in climate grants for canopy and resiliency.$$, ARRAY['https://www.maryzendejas.com/issues']),
  ('climate-change', $$Pursued cleaner-air initiatives and Port emission reductions (28% diesel particulate, 11% GHG cut) through incremental clean-energy measures.$$, ARRAY['https://www.maryzendejas.com/issues','https://lbpost.com/news/politics/elections/long-beach-voter-guide-city-council-district-1/']),
  ('economic-development', $$Secured federal aerospace/manufacturing investment plus small-business grants and a business liaison, targeting growth with community revitalization benefits.$$, ARRAY['https://www.maryzendejas.com/issues','https://www.maryzendejas.com/about'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665830
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
