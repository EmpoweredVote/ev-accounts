-- Migration 890: Tunua Thrash-Ntuk (Long Beach Council D8, -700050) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 10 placements, 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('housing',2),('residential-zoning',3),('growth-and-development',3),('homelessness-response',2),
  ('economic-development',3),('climate-change',2),('fossil-fuels',2),('local-environment',2),
  ('public-safety-approach',3),('campaign-finance',2)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = -700050
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('housing', $$Campaign platform champions affordable housing via inclusionary zoning with enforcement/in-lieu fees, community land trusts on vacant city property, and tenant-purchase programs, and she criticized the prior incumbent for opposing a $300M housing bond.$$, ARRAY['https://forthe.org/interview-thrash-ntuk/','https://cyc.lbpost.com/2024-city-council-district-8/835/']),
  ('residential-zoning', $$Said upzoning has 'gotta be' and accepts state land-use authority over blanket NIMBY objections, while favoring ADU infill that adds units along corridors and still maintains neighborhood character.$$, ARRAY['https://forthe.org/interview-thrash-ntuk/']),
  ('growth-and-development', $$Advocates careful, planned commercial-corridor development that adds units and recruits business while avoiding displacement, reflecting plan-and-invest-ahead growth management.$$, ARRAY['https://forthe.org/interview-thrash-ntuk/']),
  ('homelessness-response', $$Says the city must 'treat homelessness like the emergency that it is,' addressing root causes through jobs, affordable units, motel-to-housing conversions, and localized mental-health/substance-abuse services, with no enforcement emphasis.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-8/835/']),
  ('economic-development', $$Supports targeted corridor revitalization, business recruitment, and microloan/pop-up programs explicitly framed to avoid gentrification and displacement, treating vacancy taxes only as a last resort.$$, ARRAY['https://forthe.org/interview-thrash-ntuk/','https://cyc.lbpost.com/2024-city-council-district-8/835/']),
  ('climate-change', $$Calls for electrifying the 710 freeway and idling port ships 'as quickly as we can,' urgent climate-adaptation, and phasing the city off oil revenue.$$, ARRAY['https://forthe.org/interview-thrash-ntuk/','https://cyc.lbpost.com/2024-city-council-district-8/835/']),
  ('fossil-fuels', $$Wants the city to 'rely less and less' on oil revenue, phase out fossil-fuel dependence, and monitor oil-field/refinery emissions.$$, ARRAY['https://forthe.org/interview-thrash-ntuk/']),
  ('local-environment', $$Prioritizes expanding park access (citing only 8% park land vs 15% national average), tree-canopy growth, and protecting frontline environmental-justice communities.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-8/835/','https://forthe.org/interview-thrash-ntuk/']),
  ('public-safety-approach', $$Backs recruiting roughly 100 new police academy recruits and maintaining staffing while emphasizing community policing and transparency reforms, rather than redirecting or maximizing the police budget.$$, ARRAY['https://cyc.lbpost.com/2024-city-council-district-8/835/','https://forthe.org/interview-thrash-ntuk/']),
  ('campaign-finance', $$Advocates a public campaign-finance infrastructure over individual fundraising, opposes unlimited corporate donations, and supported ending officeholder accounts funneling money to political campaigns.$$, ARRAY['https://forthe.org/interview-thrash-ntuk/'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = -700050
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
