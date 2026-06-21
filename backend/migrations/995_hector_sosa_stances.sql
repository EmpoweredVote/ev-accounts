-- 995_hector_sosa_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 992)
-- Hector Sosa (D2, Councilmember, ext_id 675353) — evidence-only compass stances (chairs model), 100% citation.
-- NOTE: Sosa is the ROTATIONAL MAYOR as of Dec 2024 (see migration 992 context); his POLICY stances
--   are scored here regardless of current title.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
-- Pre-tenure discipline: Sosa was seated Dec 2022 — NOT on the Jan 2021 rent-control vote.
--   His rent-regulation stance is scored ONLY from his OWN 2022 campaign statement (A5 rule).
-- NO judicial-* topics — Downey has an appointed City Attorney (council-manager form).
-- Phase 150 Wave 4 (DWNY-01). On-disk counter stays 992; this file is AUDIT-ONLY.
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 675353),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('rent-regulation', 4::numeric, $stz$Sosa has stated "More rent control will not solve the problem at the root. We need more housing" — opposing additional local rent caps and instead favoring supply-side housing development as the solution to affordability. This is his own 2022 campaign position; he was not on the council for the January 2021 rent-control vote (he was seated December 2022).$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2022/10/ask-the-candidates-hector-sosa$stz$]::text[]),
  ('homelessness', 4::numeric, $stz$Sosa has stated that "In Downey, it is illegal to sleep overnight in our parks and sidewalks" and enforces the anti-camping law. His 4-step plan prohibits encampments while simultaneously maintaining nonprofit-delivered services — supporting encampment prohibition with graduated enforcement alongside service options.$stz$, ARRAY[$stz$https://thedowneypatriot.com/articles/hector-sosa-releases-plan-to-reduce-homelessness$stz$]::text[]),
  ('homelessness-response', 4::numeric, $stz$Sosa released a 4-step homelessness plan centered on enforcement of Downey's anti-camping law (which prohibits sleeping overnight in parks and sidewalks) combined with wrap-around services delivered through nonprofits. His approach explicitly leads with law enforcement before services — an enforcement-first model.$stz$, ARRAY[$stz$https://thedowneypatriot.com/articles/hector-sosa-releases-plan-to-reduce-homelessness$stz$]::text[]),
  ('public-safety-approach', 4::numeric, $stz$Sosa supports increases to the police and fire budget as a public safety priority, describing robust public safety staffing as a core city obligation. His 2022 candidate Q&A called for maintaining well-funded police and fire services.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2022/10/ask-the-candidates-hector-sosa$stz$]::text[]),
  ('local-immigration', 1::numeric, $stz$In 2025 Sosa called for a special City Council meeting on ICE immigration raids, describing the raids as "literally terrorizing our community." He co-sponsored the $25,000 city allocation to assist ICE-impacted families — a clear pro-immigrant-community protective stance.$stz$, ARRAY[$stz$https://calonews.com/downey-residents-demand-action$stz$]::text[]),
  ('economic-development', 4::numeric, $stz$Sosa advocates reducing city hall bureaucratic red tape and streamlining permitting to make Downey business-friendly. He emphasizes removing government obstacles to private-sector investment as the primary economic-development strategy.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2022/10/ask-the-candidates-hector-sosa$stz$]::text[])
),
ans AS (
 INSERT INTO inform.politician_answers (politician_id, topic_id, value)
 SELECT pol.id, t.id, d.val
 FROM d JOIN inform.compass_topics t ON t.topic_key=d.topic_key AND t.is_live=true CROSS JOIN pol
 ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value
 RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, t.id, d.reasoning, d.sources
FROM d JOIN inform.compass_topics t ON t.topic_key=d.topic_key AND t.is_live=true CROSS JOIN pol
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
COMMIT;
