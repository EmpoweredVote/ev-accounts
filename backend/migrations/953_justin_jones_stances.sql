-- 953_justin_jones_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 947)
-- Justin Jones (D3, ext 657578) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 657578),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('rent-regulation', 3::numeric, $stz$As a sitting councilmember Jones was on the council that created Pasadena's Measure H Rent Stabilization Department (6-0, Nov 2023), and he states the city must continue to find opportunities to stabilize rent — favoring continuation of existing tenant protections plus income-tied rents via public benefit agreements rather than expanding rent control to all units or repealing it.$stz$, ARRAY[$stz$https://therealdeal.com/la/2023/11/08/pasadena-moves-to-create-rent-stabilization-department/$stz$,$stz$https://pasadenanow.com/main/district-3-candidate-jones-talks-affordable-housing-traffic-and-public-safety$stz$]::text[]),
  ('housing', 2::numeric, $stz$Jones advocates public benefit agreements that tie rent to income and require affordability, converting vacant buildings/motels into workforce and permanent supportive housing, and city negotiation to purchase motels — i.e., requiring affordable units and publicly funding new housing.$stz$, ARRAY[$stz$https://pasadenanow.com/main/district-3-candidate-jones-talks-affordable-housing-traffic-and-public-safety$stz$,$stz$https://laist.com/news/politics/voter-guides/2026-election-california-primary-pasadena-city-councilmember-district-3$stz$]::text[]),
  ('homelessness-response', 1::numeric, $stz$Jones's stated approach is housing-first and services-based: negotiating motel purchases to convert into permanent supportive housing, housing subsidies, and expanded case management with Union Station and Friends In Deed, with no enforcement/anti-camping component cited.$stz$, ARRAY[$stz$https://pasadenanow.com/main/district-3-candidate-jones-talks-affordable-housing-traffic-and-public-safety$stz$]::text[]),
  ('public-safety-approach', 3::numeric, $stz$Jones says he has led efforts to improve public safety and that the police chief must respect civilian oversight, transparency and accountability while maintaining a motivated workforce — maintaining police while emphasizing oversight/accountability rather than cutting or sharply expanding the budget.$stz$, ARRAY[$stz$https://pasadenanow.com/main/district-3-candidate-jones-talks-affordable-housing-traffic-and-public-safety$stz$]::text[]),
  ('transportation-priorities', 2::numeric, $stz$Jones emphasizes multimodal planning, traffic safety, EV infrastructure, and a pedestrian-friendly carbon-neutral vision for the 710 stub land — balancing road safety with transit/bike/pedestrian investment.$stz$, ARRAY[$stz$https://laist.com/news/politics/voter-guides/2026-election-california-primary-pasadena-city-councilmember-district-3$stz$]::text[]),
  ('climate-change', 2::numeric, $stz$Jones (former Environmental Advisory Commission chair and PWP integrated-resource-plan advisory member) backs a clear path toward 100% renewable energy, aligning with Pasadena's goal of 100% carbon-free electricity by 2030, plus conservation and stormwater capture.$stz$, ARRAY[$stz$https://pasadenanow.com/main/district-3-candidate-jones-talks-affordable-housing-traffic-and-public-safety$stz$,$stz$https://www.cityofpasadena.net/district3/bio/$stz$]::text[]),
  ('growth-and-development', 3::numeric, $stz$Jones advocates smart-growth policies and a proactively planned mixed-use vision (affordable housing, open space, tech/biotech workspace) for the ~50-acre 710 stub land, investing in coordinated infrastructure rather than limiting or deregulating growth.$stz$, ARRAY[$stz$https://laist.com/news/politics/voter-guides/2026-election-california-primary-pasadena-city-councilmember-district-3$stz$,$stz$https://www.justinforcitycouncil.com/$stz$]::text[]),
  ('economic-development', 2::numeric, $stz$Jones emphasizes supporting local small businesses and employment ('train local, hire local'), backing Playhouse Village priorities and growing city revenue around the 2028 Olympics — focused on local/small-business support rather than large corporate tax abatements.$stz$, ARRAY[$stz$https://pasadenanow.com/main/district-3-candidate-jones-talks-affordable-housing-traffic-and-public-safety$stz$,$stz$https://laist.com/news/politics/voter-guides/2026-election-california-primary-pasadena-city-councilmember-district-3$stz$]::text[])
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
