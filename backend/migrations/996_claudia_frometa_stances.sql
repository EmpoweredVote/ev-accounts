-- 996_claudia_frometa_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 992)
-- Claudia Frometa (D4, Mayor — rotational, ext_id 675361) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
-- Pre-tenure discipline: Frometa was seated Dec 2018 — she IS attributable to the Jan 2021 rent-control
--   vote (on the council; A5 rule confirmed).
-- LOCAL-IMMIGRATION: Frometa's 2025 position is GENUINELY NUANCED ("nothing we can do as local government"
--   vs "the terror that ICE is instilling"). This does not land cleanly on a single chair — left BLANK per
--   evidence-only / no-forcing rule (plan spec Task 2). Honest blank documented here and in SUMMARY.
-- NO judicial-* topics — Downey has an appointed City Attorney (council-manager form).
-- Phase 150 Wave 4 (DWNY-01). On-disk counter stays 992; this file is AUDIT-ONLY.
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 675361),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('rent-regulation', 4::numeric, $stz$Frometa voted with the unanimous Downey City Council in January 2021 to reject a rent control proposal brought by Councilmember Alvarez, stating opposition to additional local rent caps. She was seated in December 2018 and thus was on the council for this vote. This vote establishes her as consistently opposing expansion of local rent regulation beyond California's existing state-law tenant protections.$stz$, ARRAY[$stz$https://thedowneypatriot.com/articles/council-decides-against-stricter-rent-control$stz$,$stz$https://caanet.org/downey-rejects-rent-control-proposal/$stz$]::text[]),
  ('public-safety-approach', 4::numeric, $stz$Frometa opposes defunding police. Downey adopted body cameras and de-escalation training during her tenure on the council, which she has supported as part of a pro-accountability, pro-law-enforcement approach — maintaining police budgets and adding accountability tools rather than redirecting police funding.$stz$, ARRAY[$stz$https://downeylegend.com/get-to-know-mayor-claudia-frometa/$stz$]::text[]),
  ('housing', 3::numeric, $stz$Frometa has stated "We need housing" and supports housing development in Downey. During redistricting she proposed a district boundary approach that would accommodate future growth. Her position reflects support for housing development without specific advocacy for aggressive upzoning or expanded rent regulation — pro-development within a balanced framework.$stz$, ARRAY[$stz$https://thedowneypatriot.com/articles/downey-moves-forward-with-new-electoral-system-creating-fifth-district$stz$]::text[])
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
