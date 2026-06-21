-- 955_jess_rivas_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 947)
-- Jess Rivas (D5, ext -700150) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -700150),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('rent-regulation', 2::numeric, $stz$Rivas championed Measure H (2022 rent stabilization), is the council's leading defender of the resulting Rental Housing Board, and in her 2025 State of the City called for strong enforcement of the Article 18 tenant protections — backing strengthening and protecting the existing stabilization regime rather than universal expansion to all units.$stz$, ARRAY[$stz$https://pasadenanow.com/main/guest-opinion-district-5-councilmember-jess-rivas-rental-board-is-democracy-in-action$stz$,$stz$https://pasadenanow.com/main/guest-opinion-l-vice-mayor-jess-rivas-state-of-the-city-remarks$stz$]::text[]),
  ('housing', 2::numeric, $stz$Rivas is focused on bringing more affordable housing to Pasadena, champions rent caps via Measure H, and backed the regional tri-city housing trust and mixed-income development, noting renters are a majority of the city but underrepresented.$stz$, ARRAY[$stz$https://laist.com/news/politics/voter-guides/2026-election-california-primary-pasadena-city-councilmember-district-5$stz$]::text[]),
  ('homelessness-response', 2::numeric, $stz$Rivas supported the city finding funding for a homeless shelter project, thanking staff for working toward it, and frames rent control as a tool to keep people housed — a shelter/services-oriented record with no enforcement framing.$stz$, ARRAY[$stz$https://pasadenanow.com/main/pasadena-floats-2-million-first-step-on-a-homeless-shelter$stz$]::text[]),
  ('climate-change', 2::numeric, $stz$Rivas helped pass and publicly recommitted to Pasadena's goal of 100% carbon-free energy by 2030 (Resolution 9977): 'We must not back away from our goal to achieve carbon free energy by 2030.'$stz$, ARRAY[$stz$https://pasadenanow.com/main/guest-opinion-l-vice-mayor-jess-rivas-state-of-the-city-remarks$stz$]::text[]),
  ('campaign-finance', 2::numeric, $stz$Rivas led efforts to end unlimited campaign contributions in Pasadena city elections — a documented pro-reform position favoring stricter contribution limits.$stz$, ARRAY[$stz$https://laist.com/news/politics/voter-guides/2026-election-california-primary-pasadena-city-councilmember-district-5$stz$]::text[]),
  ('local-immigration', 2::numeric, $stz$Rivas defends Pasadena's policy of not assisting federal immigration enforcement, criticized the federal administration's misguided priorities, and noted the city joined lawsuits and refused to enforce the administration's executive orders — protecting residents and declining city cooperation with immigration enforcement.$stz$, ARRAY[$stz$https://laist.com/news/politics/voter-guides/2026-election-california-primary-pasadena-city-councilmember-district-5$stz$,$stz$https://pasadenanow.com/main/guest-opinion-l-vice-mayor-jess-rivas-state-of-the-city-remarks$stz$]::text[])
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
