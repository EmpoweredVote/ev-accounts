-- 950_tyron_hampton_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 947)
-- Tyron Hampton (D1, ext -201094) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -201094),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('rent-regulation', 3::numeric, $stz$Hampton voted 6-0 (Nov 2023) to create a Rent Stabilization Department implementing voter-approved Measure H and worked within the existing framework — later open to only minor changes (a seat or two for property owners) while the council kept current tenant protections and rejected sweeping landlord-favoring rollbacks. He maintains the existing stabilization regime rather than expanding it to all units or repealing it.$stz$, ARRAY[$stz$https://therealdeal.com/la/2023/11/08/pasadena-moves-to-create-rent-stabilization-department/$stz$,$stz$https://pasadenanow.com/main/city-council-approves-changes-to-rent-control-law-rejects-more-sweeping-revisions$stz$]::text[]),
  ('public-safety-approach', 3::numeric, $stz$As Vice Mayor after the 2020 police shooting of Anthony McClain, Hampton joined the unanimous council vote creating an 11-member Community Police Oversight Commission and independent auditor with subpoena power, while framing the department as doing many things well with room for improvement — supporting added accountability/crisis-response while keeping police funded, not defunding.$stz$, ARRAY[$stz$https://www.pasadenanow.com/main/city-council-approves-community-police-oversight-commission-independent-auditor$stz$]::text[]),
  ('homelessness-response', 2::numeric, $stz$Hampton said he was very supportive of the year-round shelter during budget talks and, in a first-party guest column, committed that no resident needing hotel/motel vouchers would be denied assistance — favoring expanded shelter capacity and services rather than enforcement-first approaches.$stz$, ARRAY[$stz$https://pasadenanow.com/main/guest-opinion-councilmember-tyron-hampton-a-clearer-vision$stz$]::text[]),
  ('economic-development', 3::numeric, $stz$Hampton chairs the City Council's Economic Development & Technology Committee and centers his District 1 (Northwest Pasadena) agenda on targeted, place-based economic development and workforce resources, reflecting targeted-incentive/community-benefit economic development rather than blanket subsidies.$stz$, ARRAY[$stz$https://www.cityofpasadena.net/district1/bio/$stz$,$stz$https://pasadenanow.com/main/guest-opinion-councilmember-tyron-hampton-a-clearer-vision$stz$]::text[])
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
