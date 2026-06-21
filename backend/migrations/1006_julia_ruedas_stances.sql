-- 1006_julia_ruedas_stances.sql
-- Phase 151 Wave 4 (ELMN-01): Julia Ruedas (El Monte City Council District 3, ext_id 657390) evidence-only
-- compass stances. AUDIT-ONLY — raw SQL, NOT registered (ledger stays 1001). Idempotent.
-- Chairs model; 100% citation; honest blanks. Record thin (Voter's Edge dead, bio stub) -> 1 solid vote-based stance.

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, v.value
FROM (VALUES ('public-safety-approach',4)) AS v(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = 657390
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, v.reasoning, v.sources
FROM (VALUES
  ('public-safety-approach', $$As a seated D3 councilmember she was confirmed present and voted in the 7-0 unanimous ratification of the 2024-2027 EMPOA police MOU (5% raise in 2024 + 3% in 2025/2026; ~$2.06M budget amendment despite the deficit), and the same meeting's 7-0 votes funding upgraded police body-worn cameras/TASER/Bearcat systems and a police investigations vehicle — a consistent pattern of increasing police pay/staffing/resources.$$, ARRAY['https://www.ci.el-monte.ca.us/AgendaCenter/ViewFile/Minutes/_07162024-1170','https://midvalleynews.com/el-monte-city-council-approves-police-salary-increases/'])
) AS v(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = 657390
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
