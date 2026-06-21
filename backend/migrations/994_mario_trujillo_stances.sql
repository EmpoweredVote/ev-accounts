-- 994_mario_trujillo_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 992)
-- Mario Trujillo (D5, ext_id -201200) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
-- Pre-tenure discipline: the Jan 2021 unanimous rent-control vote IS attributable to Trujillo
--   (seated Dec 2020, so he was on the council). Sosa/Pemberton/Ortiz were NOT (seated later).
-- NO judicial-* topics — Downey has an appointed City Attorney (council-manager form).
-- Phase 150 Wave 4 (DWNY-01). On-disk counter stays 992; this file is AUDIT-ONLY.
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -201200),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('rent-regulation', 4::numeric, $stz$Trujillo voted with the unanimous Downey City Council in January 2021 to reject Councilmember Alvarez's rent control proposal, stating "any additional rent control measures would be redundant and unnecessary" given California's 2019 Tenant Protection Act. In his 2024 re-election Q&A he called for a "balance that protects tenants from unreasonable rent hikes while also considering the interests of property owners" — consistently opposing additional local rent caps while acknowledging existing state law.$stz$, ARRAY[$stz$https://caanet.org/downey-rejects-rent-control-proposal/$stz$,$stz$https://thedowneypatriot.com/articles/council-decides-against-stricter-rent-control$stz$,$stz$https://downeylatinonews.com/en/2024/10/making-downey-a-destination$stz$]::text[]),
  ('public-safety-approach', 4::numeric, $stz$Trujillo is a strong public safety supporter: he introduced a $25,000 police officer recruitment incentive and authorized private security personnel for Downey parks to supplement patrol coverage. His 2024 campaign emphasized maintaining well-funded police and fire services as a core city responsibility.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2024/10/making-downey-a-destination$stz$]::text[]),
  ('transportation-priorities', 2::numeric, $stz$Trujillo committed in his 2024 Q&A to implementing the 33.6 miles of bike lanes called for in Downey's 2015 Bicycle Master Plan, describing it as a key infrastructure priority — a multi-modal commitment that prioritizes dedicated bicycle infrastructure alongside existing roadway investment.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2024/10/making-downey-a-destination$stz$]::text[]),
  ('economic-development', 4::numeric, $stz$Trujillo highlighted recruiting a Sprouts grocery store and securing a bowling alley/arcade tenant for a vacant Sears anchor space as signature economic-development achievements during his tenure — active business attraction and site-reuse efforts to maintain a vibrant commercial tax base.$stz$, ARRAY[$stz$https://downeylatinonews.com/en/2024/10/making-downey-a-destination$stz$]::text[]),
  ('local-immigration', 1::numeric, $stz$In June 2025 Trujillo moved to convene a special Downey City Council meeting in response to ICE immigration raids, calling the raids "absolutely horrendous" and pushing the city to consider a potential lawsuit to protect immigrant residents. He co-sponsored the $25,000 allocation to assist families impacted by the raids — a clear pro-sanctuary/pro-immigrant-protection stance.$stz$, ARRAY[$stz$https://thedowneypatriot.com/articles/council-decides-against-stricter-rent-control$stz$,$stz$https://calonews.com/downey-residents-demand-action$stz$]::text[])
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
