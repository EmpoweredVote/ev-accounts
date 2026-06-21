-- 998_horacio_ortiz_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 992)
-- Horacio Ortiz (D1, Mayor Pro Tem, ext_id -700991) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
-- Pre-tenure discipline: Ortiz was seated Dec 2023 — he was NOT on the Jan 2021 rent-control vote.
--   His rent-regulation stance is scored from his OWN 2023 candidate Q&A only (A5 rule).
-- THIN RECORD (seated Dec 2023, first term): Many honest blanks preserved — only 4 stances documented.
-- Transit/transportation: Ortiz stated "undecided on fare-free transit; willing to explore options" —
--   undecided is not a documentable chair position; transportation-priorities left BLANK (honest gap).
-- Cannabis: Ortiz opposes commercial dispensaries (2023 Q&A), but this topic_key is unconfirmed as
--   live non-judicial in the DB; left BLANK pending confirmation (honest gap).
-- NO judicial-* topics — Downey has an appointed City Attorney (council-manager form).
-- Phase 150 Wave 4 (DWNY-01). On-disk counter stays 992; this file is AUDIT-ONLY.
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -700991),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('homelessness', 5::numeric, $stz$Ortiz supports strict enforcement of Downey's anti-camping law and states "The solution is not to provide more shelter" — an explicit anti-shelter/enforcement-primary stance that relies on existing social services for those who seek help rather than expanding shelter capacity. This places him at the highest-enforcement end of the criminalization spectrum.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2023/10/the-solution-is-not-to-provide-more-shelter-horacio-ortiz-candidate-for-district-1$stz$]::text[]),
  ('homelessness-response', 4::numeric, $stz$Ortiz explicitly stated "The solution is not to provide more shelter" — opposing new shelter development in Downey. He supports strict enforcement of Downey's anti-camping law as the primary tool, with enforcement-first measures. While he rejects new shelter construction, his documented position does not explicitly call for eliminating existing outreach programs — placing him at the enforcement-primary end while maintaining basic services.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2023/10/the-solution-is-not-to-provide-more-shelter-horacio-ortiz-candidate-for-district-1$stz$]::text[]),
  ('rent-regulation', 4::numeric, $stz$Ortiz opposes additional local rent control "beyond state limits" — favoring reliance on California's existing state-law tenant protections (AB 1482) rather than local rent caps. This is his own 2023 campaign position; he was not on the council for the January 2021 vote (seated December 2023).$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2023/10/the-solution-is-not-to-provide-more-shelter-horacio-ortiz-candidate-for-district-1$stz$]::text[]),
  ('public-safety-approach', 4::numeric, $stz$Ortiz stated "I stand by the Downey Police Department. I will make sure they have the resources they need" and has specifically advocated for a police substation in District 1 — a strong pro-police-funding and pro-enforcement position.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2023/10/the-solution-is-not-to-provide-more-shelter-horacio-ortiz-candidate-for-district-1$stz$]::text[]),
  ('local-immigration', 1::numeric, $stz$Ortiz seconded Councilmember Trujillo's 2025 motion to convene a special City Council meeting on ICE immigration raids and co-voted for the $25,000 allocation to assist families impacted by the raids — aligning with the pro-immigrant-protection majority.$stz$, ARRAY[$stz$https://calonews.com/downey-residents-demand-action$stz$]::text[])
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
