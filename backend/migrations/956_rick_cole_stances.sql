-- 956_rick_cole_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 947)
-- Rick Cole (D2, ext 657577) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 657577),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('housing', 2::numeric, $stz$Cole supported Measure H tenant protections and calls for a dedicated local funding source plus an affordable-housing authority to build/operate affordable and permanent supportive housing, saying the public sector should take the lead to deliver the state-mandated affordable units — public funding and inclusionary affordability, not deregulation.$stz$, ARRAY[$stz$https://www.rickcoleforcouncil.com/issues$stz$,$stz$https://pasadenanow.com/main/guest-opinion-rick-cole-homelessness-is-getting-worse-in-pasadena-do-we-have-the-will-to-by$stz$]::text[]),
  ('residential-zoning', 3::numeric, $stz$On his SB 79 motion Cole argued the RM-16-to-48 zones already slated for dense multifamily housing around transit should develop by right, while seeking an 18-month study delay only for single-family and the lowest-density duplex/triplex zones — multifamily/mixed-use near transit corridors while protecting the lowest-density residential areas.$stz$, ARRAY[$stz$https://pasadenanow.com/main/pasadena-votes-to-delay-a-state-housing-law-near-the-gold-line-three-top-officials-sit-it-out$stz$,$stz$https://pasadenanow.com/main/guest-opinion-councilmember-rick-cole-one-click-politics-wont-solve-sb-79-challenge$stz$]::text[]),
  ('growth-and-development', 3::numeric, $stz$A new-urbanism planner, Cole champions proactive, design-led planning: objective design standards for higher-density development and, as Mayor, a General Plan focusing growth around transit stations while protecting neighborhoods — planning ahead of growth rather than slow-growth limits or pure deregulation.$stz$, ARRAY[$stz$https://www.rickcoleforcouncil.com/issues$stz$,$stz$https://pasadenanow.com/main/guest-opinion-rick-cole-five-takeaways-from-the-governors-signature-on-sb-79$stz$]::text[]),
  ('rent-regulation', 3::numeric, $stz$Cole states he supported Measure H (the Fair and Equitable Housing Charter Amendment), Pasadena's rent-stabilization measure — backing the existing RSO/tenant protections, with no documented call to expand rent control to all units or roll it back.$stz$, ARRAY[$stz$https://www.rickcoleforcouncil.com/issues$stz$]::text[]),
  ('homelessness-response', 1::numeric, $stz$Cole endorses the Built for Zero / Community Solutions model with a by-name registry, calls for dedicated local funding to build and operate permanent supportive and affordable housing to reach functional zero, and frames the response around housing and services rather than punitive measures — a housing-first orientation.$stz$, ARRAY[$stz$https://pasadenanow.com/main/guest-opinion-rick-cole-homelessness-is-getting-worse-in-pasadena-do-we-have-the-will-to-by$stz$,$stz$https://www.rickcoleforcouncil.com/issues$stz$]::text[]),
  ('transportation-priorities', 1::numeric, $stz$Cole proposes a downtown streetcar, weekend car-free zones, protected bike lanes, and far better local bus transit tied into regional rail; as Santa Monica city manager he launched the region's first bikeshare — a consistent transit/bike/pedestrian-first priority.$stz$, ARRAY[$stz$https://www.rickcoleforcouncil.com/issues$stz$,$stz$https://pasadenanow.com/main/guest-opinion-rick-cole-five-takeaways-from-the-governors-signature-on-sb-79$stz$]::text[]),
  ('public-safety-approach', 2::numeric, $stz$Cole supports smarter approaches to prevent and deter crime including cost-effective 24/7 alternatives for calls that don't require an armed response — shifting non-violent calls to unarmed/alternative responders rather than redirecting the police budget wholesale or simply expanding staffing.$stz$, ARRAY[$stz$https://www.rickcoleforcouncil.com/issues$stz$]::text[]),
  ('climate-change', 2::numeric, $stz$Cole backs carbon-free electricity by 2030, committing to eliminating coal and natural gas from electric generation by 2030 — a rapid renewable transition / fossil-fuel phase-out timeline.$stz$, ARRAY[$stz$https://www.rickcoleforcouncil.com/issues$stz$]::text[])
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
