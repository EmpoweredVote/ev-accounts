-- 1004_marisol_cortez_stances.sql
-- Phase 151 Wave 4 (ELMN-01): Marisol Cortez (El Monte City Council District 6, ext_id -701001) evidence-only
-- compass stances. AUDIT-ONLY — raw SQL, NOT registered (ledger stays 1001). Idempotent.
-- Modeled as the D6 council incumbent (she ran for Mayor 2024 and LOST — NOT a mayor). Chairs model; 100%
-- citation; honest blanks. Record thin/high-level (no Ballotpedia/Vote411 survey) -> 4 well-cited stances.

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, v.value
FROM (VALUES ('housing',3),('public-safety-approach',4),('economic-development',3),('transportation-priorities',4)) AS v(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = -701001
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, v.reasoning, v.sources
FROM (VALUES
  ('housing', $$Her campaign states "I supported building housing to help working families stay in El Monte" — an affirmative pro-housing-production stance for affordability/retention, without rent-cap/inclusionary-mandate or public-housing language (targeted measures to enable building).$$, ARRAY['https://www.marisolcortezformayor.com/','https://www.ci.el-monte.ca.us/685/Marisol-Cortez']),
  ('public-safety-approach', $$"As your councilmember, I voted to keep our police funded and fire stations open" — she frames protecting/maintaining police funding as a campaign pillar, with no crisis-team or unarmed-responder language.$$, ARRAY['https://www.marisolcortezformayor.com/','https://midvalleynews.com/ancona-wins/']),
  ('economic-development', $$"We need to invest in repaving roads, bringing in retail businesses, restaurants, and entertainment to create jobs and new revenue sources" — recruiting business/jobs for community benefit and city revenue, with no abatement/incentive language.$$, ARRAY['https://www.marisolcortezformayor.com/priorities','https://www.marisolcortezformayor.com/']),
  ('transportation-priorities', $$Her sole stated transportation priority is to "invest in repaving roads" — a roads/driver-capacity focus with no transit, pedestrian, or bike component mentioned.$$, ARRAY['https://www.marisolcortezformayor.com/','https://www.marisolcortezformayor.com/priorities'])
) AS v(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = -701001
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
