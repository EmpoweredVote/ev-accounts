-- Migration 885: Daryl Supernaw (Long Beach Council D4, 665834) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 7 placements, 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('public-safety-approach',4),('homelessness-response',3),('homelessness',3),('housing',3),
  ('economic-development',4),('growth-and-development',4),('transportation-priorities',2)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665834
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('public-safety-approach', $$Chairs the Public Safety Committee, says he would not cut police, fire or paramedic levels to balance the budget, and voted for an $85,000 signing bonus for incoming officers.$$, ARRAY['https://lbcurrent.com/news/2024/11/12/supernaw-likely-winner-in-district-4-contest/','https://lbpost.com/news/politics/elections/voter-guide-4th-district-city-council-long-beach-supernaw-chico/']),
  ('homelessness-response', $$Backs CARE Court rollout, outreach and supportive housing while also removing encampments, reflecting a services-plus-reasonable-rules approach.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-4/daryl-supernaw/','https://lbpost.com/news/politics/elections/voter-guide-4th-district-city-council-long-beach-supernaw-chico/']),
  ('homelessness', $$Secured funding for the 77-unit 26.2 supportive-housing project while also removing an encampment near a preschool, indicating enforcement paired with housing/services.$$, ARRAY['https://lbpost.com/news/politics/elections/voter-guide-4th-district-city-council-long-beach-supernaw-chico/']),
  ('housing', $$Serves as a city Housing Authority commissioner and secured funding for affordable/supportive housing units, supporting targeted subsidies rather than public ownership or pure market.$$, ARRAY['https://lbpost.com/news/politics/elections/voter-guide-4th-district-city-council-long-beach-supernaw-chico/','https://cyc.lbpost.com/2024-city-council-district-4/daryl-supernaw/']),
  ('economic-development', $$Actively touts business recruitment wins like Fletcher Jones' Porsche investment, the Retail Renaissance and Sports Basement as district priorities.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-4/daryl-supernaw/']),
  ('growth-and-development', $$Emphasizes business recruitment and economic-development initiatives as a path to new revenue for the district.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-4/daryl-supernaw/','https://lbcurrent.com/news/2024/11/12/supernaw-likely-winner-in-district-4-contest/']),
  ('transportation-priorities', $$Champions the $60M Studebaker Road project adding bike lanes and bus lanes, and has installed bike lanes and traffic circles during his terms.$$, ARRAY['https://lbcurrent.com/news/2024/10/16/long-beach-city-council-district-four-candidates-share-platforms-and-policies-during-forum/'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665834
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
