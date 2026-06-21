-- Migration 883: Cindy Allen (Long Beach Council D2, 665831) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 12 placements, 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('rent-regulation',1),('housing',2),('homelessness',2),('homelessness-response',2),
  ('public-safety-approach',3),('local-immigration',1),('immigration',2),('climate-change',3),
  ('local-environment',3),('economic-development',3),('transportation-priorities',4),('campaign-finance',4)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665831
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('rent-regulation', $$Stated 'I continue to support stricter forms of local rent control because many families are unable to cope with sudden rent increases.'$$, ARRAY['https://forthe.org/quiz-allen/']),
  ('housing', $$Authored the substantial-remodel/just-cause eviction reform and supported the city's first Inclusionary Housing Ordinance and affordable-housing funding.$$, ARRAY['https://lbpost.com/news/long-beach-will-make-it-harder-more-expensive-to-evict-tenants-to-remodel-units/','https://www.cindyallen.com/our_work']),
  ('homelessness', $$Backs a comprehensive 'mix of solutions' centered on affordable housing, housing-first centers and 24/7 mental-health services rather than enforcement.$$, ARRAY['https://forthe.org/quiz-allen/','https://cyc.lbpost.com/2024-city-council-district-2/cindy-allen-3/']),
  ('homelessness-response', $$Touts expanding shelter capacity (125 beds at 702 W. Anaheim, tiny homes, 78-room facility) and housing placements as the city's primary strategy.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-2/cindy-allen-3/','https://www.cindyallen.com/our_work']),
  ('public-safety-approach', $$As a former officer she opposed police cuts but said 'instead of merely increasing the numbers of police, my goal is to improve our strategy,' co-sponsoring an officer-misconduct (LEWIS) registry and a gun buyback alongside youth/mental-health investment.$$, ARRAY['https://forthe.org/quiz-allen/','https://www.cindyallen.com/our_work','https://lbpost.com/news/police-budget-long-beach-defund-city-council/']),
  ('local-immigration', $$Allocated $300,000 to the Long Beach Justice Fund for immigrant deportation legal defense and backed the city's sanctuary Values Act.$$, ARRAY['https://www.cindyallen.com/our_work','https://www.longbeach.gov/recovery/news/long-beach-justice-fund/']),
  ('immigration', $$Funded immigrant legal-defense services (Justice Fund) and supported sanctuary protections, indicating welcoming legal/services posture.$$, ARRAY['https://www.cindyallen.com/our_work','https://www.longbeach.gov/recovery/news/long-beach-justice-fund/']),
  ('climate-change', $$Led council adoption of Long Beach's first Climate Action and Adaptation Plan and backed ARCHES hydrogen and solar-permit streamlining (gradual clean-energy transition).$$, ARRAY['https://www.cindyallen.com/our_work','https://lbpost.com/news/city-council-approves-sweeping-climate-action-plan/']),
  ('local-environment', $$Focuses on reducing 710-Freeway/port/refinery air pollution via green tech while still supporting beach development with environmental responsibility.$$, ARRAY['https://forthe.org/quiz-allen/']),
  ('economic-development', $$Supports Grow Long Beach/Elevate 28 plans to recruit aerospace, logistics and healthcare employers paired with local-hire requirements and a guaranteed-income pilot.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-2/cindy-allen-3/','https://www.cindyallen.com/our_work']),
  ('transportation-priorities', $$Her documented District 2 transportation focus is expanding parking — repurposing vacant lots for parking, reducing red curbs, and permit parking for drivers.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-2/cindy-allen-3/']),
  ('campaign-finance', $$Opposes abolishing officeholder accounts, stating 'I would not be in favor of abolishing officeholder accounts' and that 'contributions have their part within any election.'$$, ARRAY['https://forthe.org/quiz-allen/'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665831
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
