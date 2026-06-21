-- 952_steve_madison_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 947)
-- Steve Madison (D6, ext 657581) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 657581),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('transportation-priorities', 2::numeric, $stz$Madison's defining 25-year record is opposing the 710 freeway extension/tunnel — he authored the 2000 City Council resolution against it and drove the 2015 council vote and 2017 Metro cancellation, framed around neighborhood protection and reconnecting the street grid rather than expanding highway capacity. This anti-freeway, neighborhood-over-roadway posture sits at the low (transit/neighborhood) end.$stz$, ARRAY[$stz$https://www.cityofpasadena.net/district6/bio/$stz$,$stz$https://www.cnu.org/highways-boulevards/campaign-cities/pasadena-710$stz$]::text[]),
  ('growth-and-development', 1::numeric, $stz$On Pasadena's RHNA allocation Madison was openly skeptical of the state growth mandate ('We may decide we like the size of our family the way it is and the state comes along and says no... It's endless'), framing imposed housing growth as unwanted intrusion on local control — closest to imposing growth limits / defending local discretion.$stz$, ARRAY[$stz$https://www.pasadenanow.com/main/city-concerned-over-new-housing-numbers$stz$]::text[]),
  ('rent-regulation', 2::numeric, $stz$Madison's record favors and defends rent stabilization: his bio touts enacting tenant protections, he joined the unanimous council vote advancing the Rental Housing Board's strengthening recommendations, and the council under his leadership rejected landlord-backed efforts to expand owner seats and broaden exemptions while approving pro-tenant fixes — consistent with strengthening/maintaining existing stabilization rather than weakening it.$stz$, ARRAY[$stz$https://pasadenanow.com/main/city-council-approves-changes-to-rent-control-law-rejects-more-sweeping-revisions$stz$,$stz$https://www.cityofpasadena.net/district6/bio/$stz$]::text[]),
  ('public-safety-approach', 4::numeric, $stz$In council police-budget deliberations Madison said he intends to ask for increased staffing and argued the city could be doing more to stop violent crime if it had more resources, and that overtime money could instead fund new police officer positions — explicitly favoring increased police staffing.$stz$, ARRAY[$stz$https://www.pasadenanow.com/main/more-money-for-police-a-conflicted-city-council-deliberates$stz$]::text[])
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
