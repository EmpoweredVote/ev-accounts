-- 908_vartan_gharpetian_stances.sql
-- Phase 144 / Plan 04 — Vartan Gharpetian (external_id 686336) evidence-only compass stances.
-- AUDIT-ONLY: raw SQL, NOT registered in schema_migrations (ledger stays 903). Chairs model; 100% citation.
-- Thinner record → 5 stances; most topics honest-blank (residential-zoning/rent-regulation deliberately
-- blank for contradictory/ambiguous evidence). No judicial topics (D-13). Armenian/Artsakh NOT mapped (D-14).

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 686336)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id::uuid, v.value
FROM pol, (VALUES
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa', 2),  -- local-environment
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 2),  -- growth-and-development
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2),  -- homelessness-response
  ('669cac97-66a6-4087-b036-936fbe62efb3', 3),  -- housing
  ('eb3d1247-0de1-4b7f-baec-7259861efd53', 3)   -- economic-development
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 686336)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id::uuid, v.reasoning, v.sources
FROM pol, (VALUES
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa',
   $$In the 2024 Glendale Historical Society "Ask the Candidates" questionnaire Gharpetian took consistently strong preservation positions: he would have voted AGAINST the 2023 demolition of the 1913 Craftsman, supports designating additional historic districts, voted to fund the South Glendale Historic Survey to "identify and protect" resources, and wants stricter fines plus a longer (5-year) permit ban after illegal demolition — strictly protecting historic/neighborhood resources while requiring developers to offset impacts.$$,
   ARRAY['https://glendalehistorical.org/2024-question-1','https://glendalehistorical.org/2024-question-3','https://glendalehistorical.org/2024-question-5']::text[]),
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
   $$Gharpetian repeatedly criticized Glendale being "overbuilt" with one-bedroom apartments, said the city should "build projects that will serve families," and supported the Glendale building moratorium, framing new growth as needing supporting infrastructure (notably parking) — matching allowing growth only where infrastructure supports it with a more cautious approval posture.$$,
   ARRAY['https://mirrorspectator.com/2017/09/21/glendales-mayor-vartan-gharpetian-talks-politics/','https://www.crescentavalleyweekly.com/news/02/20/2020/meet-glendale-city-council-candidates-part-2/']::text[]),
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
   $$His documented platform reduces homelessness by "adding affordable housing and increasing mental health services," describing a housing-and-services approach rather than any documented anti-camping/enforcement-first stance — matching expanding shelter/services as the primary tool.$$,
   ARRAY['https://ballotpedia.org/Vartan_Gharpetian_(Glendale_City_Council_At-Large,_California,_candidate_2024)','https://massispost.com/2019/12/a-discussion-with-longtime-public-servant-vartan-gharpetian/']::text[]),
  ('669cac97-66a6-4087-b036-936fbe62efb3',
   $$As Glendale Housing Authority Chair he pushed to bring 400-500 affordable and family-sized units, championed entry-level housing, and created a recurring senior rent-subsidy program (about $300/month to ~1,000 families) plus veterans' housing support and adaptive reuse — a mix of targeted subsidies, senior/first-time help, and easier paths to affordable units.$$,
   ARRAY['https://mirrorspectator.com/2017/09/21/glendales-mayor-vartan-gharpetian-talks-politics/','https://massispost.com/2019/12/a-discussion-with-longtime-public-servant-vartan-gharpetian/']::text[]),
  ('eb3d1247-0de1-4b7f-baec-7259861efd53',
   $$Gharpetian wants to build a Glendale technology hub and "create incentives for manufacturing technology components" (e.g., chip manufacturing) to grow the sales/property tax base — targeted, industry-specific incentive recruitment rather than blanket maximum incentives.$$,
   ARRAY['https://mirrorspectator.com/2017/09/21/glendales-mayor-vartan-gharpetian-talks-politics/']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
