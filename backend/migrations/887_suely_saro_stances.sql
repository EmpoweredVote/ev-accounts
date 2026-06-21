-- Migration 887: Suely Saro (Long Beach Council D6, 665838) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 8 placements, 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('rent-regulation',1),('housing',2),('homelessness-response',2),('homelessness',2),
  ('public-safety-approach',2),('transportation-priorities',2),('economic-development',3),('fossil-fuels',4)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665838
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('rent-regulation', $$Co-authored Long Beach's temporary ban on remodel-driven evictions ('This process must stop and it must stop today') and publicly advocated rent control, eviction-moratorium extensions, and an anti-landlord-harassment ordinance.$$, ARRAY['https://lbpost.com/news/city-council-approves-temporary-ban-on-remodel-driven-evictions','https://lbpost.com/news/video-6th-district-candidates-discuss-covid-19-evictions-and-police-reform']),
  ('housing', $$Co-authored tenant-protection ordinances and supports public funding for affordable housing creation in District 6 alongside rent regulation advocacy.$$, ARRAY['https://lbpost.com/news/city-council-approves-temporary-ban-on-remodel-driven-evictions','https://lbpost.com/news/video-6th-district-candidates-discuss-covid-19-evictions-and-police-reform']),
  ('homelessness-response', $$Supported the city's local emergency declaration on homelessness and the $17.4M LA Riverbed program centered on permanent supportive housing, rapid rehousing, shelter, and street outreach.$$, ARRAY['https://sigtrib.com/long-beach-la-river-homeless-encampment-rehousing/','https://www.cbsnews.com/amp/losangeles/news/long-beach-declares-a-state-of-emergency-on-homelessness']),
  ('homelessness', $$Backed investment in shelter, supportive housing, and outreach via the homelessness emergency declaration rather than criminalization.$$, ARRAY['https://sigtrib.com/long-beach-la-river-homeless-encampment-rehousing/','https://www.cbsnews.com/amp/losangeles/news/long-beach-declares-a-state-of-emergency-on-homelessness']),
  ('public-safety-approach', $$Advocated redirecting social-issue calls from police to mental-health and trauma-informed first responders and said she would consider reallocating some police budget to community programs.$$, ARRAY['https://lbpost.com/news/video-6th-district-candidates-discuss-covid-19-evictions-and-police-reform']),
  ('transportation-priorities', $$Made pedestrian and street safety a priority via Vision Zero goals (Anaheim Corridor project) while framing safety for both pedestrians and drivers.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-6/suely-saro-3/']),
  ('economic-development', $$Voted to approve the mayor's 'Grow Long Beach' initiative to foster targeted growth in aerospace, education, healthcare, and the Port.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-6/suely-saro-3/']),
  ('fossil-fuels', $$Voted with the unanimous council on March 22, 2023 to approve the 5-Year Program extending and expanding municipal oil drilling production.$$, ARRAY['https://www.sierraclub.org/press-releases/2023/03/long-beach-city-council-approves-plan-extend-and-expand-oil-drilling'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665838
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
