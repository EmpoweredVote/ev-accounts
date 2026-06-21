-- 1005_martin_herrera_stances.sql
-- Phase 151 Wave 4 (ELMN-01): Martin Herrera (El Monte City Council District 2, ext_id -201204) evidence-only
-- compass stances. AUDIT-ONLY — raw SQL, NOT registered (ledger stays 1001). Idempotent.
-- Chairs model; 100% citation; honest blanks. Record very shallow (campaign site offline, bio stub) -> 1 stance.
-- District-elections advocacy left out (governance/voting-structure, no compass fit; the April 2022 vote also
-- predates his Nov 2022 election — pre-tenure).

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, v.value
FROM (VALUES ('public-safety-approach',4)) AS v(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = -201204
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, v.reasoning, v.sources
FROM (VALUES
  ('public-safety-approach', $$As a sitting District 2 councilmember, Herrera was part of the El Monte City Council that on July 16, 2024 unanimously ratified a new EMPOA police MOU (FY2024–2027) granting a 5% pay raise in 2024 plus 3% in 2025 and 2026, approved despite a resulting ~$2.2M budget deficit — voting to increase police pay maps to maintaining/boosting police resourcing.$$, ARRAY['https://midvalleynews.com/el-monte-city-council-approves-police-salary-increases/','https://www.ci.el-monte.ca.us/AgendaCenter/ViewFile/Minutes/_07162024-1170'])
) AS v(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = -201204
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
