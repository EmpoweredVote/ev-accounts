-- Migration 888: Roberto Uranga (Long Beach Council D7, 665839) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 9 placements, 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('fossil-fuels',4),('climate-change',3),('local-environment',2),('transportation-priorities',2),
  ('homelessness-response',1),('homelessness',2),('public-safety-approach',2),('housing',3),
  ('growth-and-development',2)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665839
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('fossil-fuels', $$Voted with the unanimous City Council in March 2023 to approve the oil 5-Year Program extending and expanding neighborhood drilling with higher production rates and a postponed phaseout.$$, ARRAY['https://www.sierraclub.org/press-releases/2023/03/long-beach-city-council-approves-plan-extend-and-expand-oil-drilling']),
  ('climate-change', $$Voted for the unanimously adopted Climate Action and Adaptation Plan setting a gradual path to carbon neutrality by 2045 (40% cut by 2030) while allowing oil drilling to continue through 2035.$$, ARRAY['https://lbpost.com/news/city-council-approves-sweeping-climate-action-plan/','https://www.longbeach.gov/press-releases/city-of-long-beach-adopts-comprehensive-plan-to-combat-climate-change/']),
  ('local-environment', $$Has a documented record securing green-space and park funding (Willow Springs, Wrigley Greenbelt, Tanaka Park) and championing environmental-justice air-quality work near the port via the Westside Promise.$$, ARRAY['https://cyc.lbpost.com/2022-city-council-district-7/roberto-uranga/','https://www.longbeach.gov/mayor/mayor-priorities/climate-action-and-sustainability/']),
  ('transportation-priorities', $$Voted for the Climate Action Plan that prioritizes walkable communities and expanded public transit to reduce vehicle dependence.$$, ARRAY['https://lbpost.com/news/city-council-approves-sweeping-climate-action-plan/']),
  ('homelessness-response', $$Advocates meeting people where they are in encampments with services-first outreach, rapid rehousing and permanent supportive housing rather than enforcement.$$, ARRAY['https://cyc.lbpost.com/2022-city-council-district-7/roberto-uranga/']),
  ('homelessness', $$Emphasizes outreach and services for people in encampments and flexible funding for rehousing rather than criminalizing public sleeping.$$, ARRAY['https://cyc.lbpost.com/2022-city-council-district-7/roberto-uranga/']),
  ('public-safety-approach', $$Champions the REACH program (public-health nurse, mental-health clinician, outreach workers) and root-cause/youth-mentorship approaches over traditional enforcement.$$, ARRAY['https://cyc.lbpost.com/2022-city-council-district-7/roberto-uranga/']),
  ('housing', $$Supports streamlining and incentivizing affordable-unit construction plus rental and first-time-homebuyer assistance, a targeted subsidy/permit approach.$$, ARRAY['https://cyc.lbpost.com/2022-city-council-district-7/roberto-uranga/']),
  ('growth-and-development', $$Promotes 'smart growth that ensures community and public engagement' while pursuing affordable-housing goals.$$, ARRAY['https://cyc.lbpost.com/2022-city-council-district-7/roberto-uranga/'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665839
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
