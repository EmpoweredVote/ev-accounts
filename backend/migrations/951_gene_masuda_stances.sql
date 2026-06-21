-- 951_gene_masuda_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 947)
-- Gene Masuda (D4, ext 657579) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 657579),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('growth-and-development', 1::numeric, $stz$Masuda is a longtime neighborhood and quality-of-life advocate who built his record on resisting overdevelopment and preserving open space (e.g., stopping the Edison right-of-way storage development) and called the state RHNA housing targets unrealistic and unattainable — a growth-limiting posture.$stz$, ARRAY[$stz$https://www.cityofpasadena.net/district4/gene-masuda-bio/$stz$,$stz$https://pasadenanow.com/main/council-directs-city-to-prepare-appeal-for-rhna-numbers$stz$]::text[]),
  ('residential-zoning', 1::numeric, $stz$He campaigns on saving open space by opposing high-density housing projects and preserving the character of residential neighborhoods, consistently fighting density and upzoning in his East Pasadena/Hastings Ranch district.$stz$, ARRAY[$stz$https://laist.com/news/politics/2024-election-california-primary-pasadena-city-council$stz$,$stz$https://www.cityofpasadena.net/district4/gene-masuda-bio/$stz$]::text[]),
  ('housing', 3::numeric, $stz$Masuda lists affordable housing as a priority and supports including affordable units and open space in projects like the 710 stub redevelopment, but opposes broad density and state mandates — favoring targeted, neighborhood-vetted affordable housing rather than large-scale public building.$stz$, ARRAY[$stz$https://pasadenanow.com/main/district-4-councilmember-masuda-wants-to-continue-the-good-work$stz$]::text[]),
  ('local-environment', 1::numeric, $stz$He is described as a leader in Pasadena's open-space movement, having fought to keep the Edison right-of-way from being developed into storage units, and frames land-use decisions around preserving natural open space ahead of development.$stz$, ARRAY[$stz$https://www.cityofpasadena.net/district4/gene-masuda-bio/$stz$,$stz$https://pasadenanow.com/main/district-4-councilmember-masuda-wants-to-continue-the-good-work$stz$]::text[]),
  ('public-safety-approach', 4::numeric, $stz$Masuda backed adding sworn police officer positions to the budget, citing personnel reductions, and promotes active community policing and increasing neighborhood patrols for the highest level of public-safety protection.$stz$, ARRAY[$stz$https://www.coloradoboulevard.net/pasadena-council-approves-1-4-billion-budget-advances-eifd-proposal/$stz$,$stz$https://laist.com/news/politics/2024-election-california-primary-pasadena-city-council$stz$]::text[]),
  ('transportation-priorities', 4::numeric, $stz$Though he voted to oppose the 710 freeway tunnel extension on neighborhood grounds, Masuda's governing frame is car/quality-of-life oriented — resisting density to limit traffic and treating transportation as managing road/driver needs rather than a transit/bike/ped redesign.$stz$, ARRAY[$stz$https://www.cityofpasadena.net/district6/featured-stories/the-vote-on-the-710-freeway-extension/$stz$,$stz$https://pasadenanow.com/main/district-4-councilmember-masuda-wants-to-continue-the-good-work$stz$]::text[]),
  ('homelessness-response', 3::numeric, $stz$He calls homelessness the greatest challenge facing the city and works to secure temporary housing, job training, and employment placement, while supporting the state law permitting court-ordered treatment — a services-plus-reasonable-rules approach.$stz$, ARRAY[$stz$https://pasadenanow.com/main/district-4-councilmember-masuda-wants-to-continue-the-good-work$stz$]::text[]),
  ('homelessness', 3::numeric, $stz$Masuda pairs service provision (temporary housing, treatment) with accountability, noting residents have to follow the rules at any housing establishment and backing court-ordered treatment — allowing some enforcement/conditions while emphasizing services rather than criminalization or a pure right-to-sleep stance.$stz$, ARRAY[$stz$https://pasadenanow.com/main/district-4-councilmember-masuda-wants-to-continue-the-good-work$stz$]::text[]),
  ('rent-regulation', 3::numeric, $stz$Operating under voter-approved Measure H, Masuda has worked within the RSO framework (nominating a Rental Housing Board member, supporting creation of the Rent Stabilization Department) but repeatedly voiced property-owner concerns (e.g., struggling with the Ellis Act 10-year right-of-first-refusal) — maintaining existing tenant protections without seeking to expand rent control.$stz$, ARRAY[$stz$https://pasadenanow.com/main/pasadena-city-council-delays-ellis-act-tenant-protections-decision$stz$,$stz$https://therealdeal.com/la/2023/11/08/pasadena-moves-to-create-rent-stabilization-department/$stz$]::text[])
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
