-- 899_bill_miranda_stances.sql
-- Phase 143 / Plan 04 — Bill Miranda (Councilmember, external_id -200980) evidence-only compass stances.
-- AUDIT-ONLY: apply via raw SQL; does NOT register in schema_migrations (ledger MAX stays 895).
-- Chairs model; evidence-only; 100% citation; honest blanks. 6 evidenced topics.
-- Seated May 2018 confirmed (appointed Jan 2017) -> SB54 vote attributable.
-- NOTE: Miranda's external_id is -200980 (reseated existing row; NOT -700182).

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -200980)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id, v.value
FROM pol, (VALUES
  ('b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 4),  -- local-immigration
  ('f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),  -- taxes
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),  -- public-safety-approach
  ('669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),  -- housing
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 3),  -- growth-and-development
  ('eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 4)   -- economic-development
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -200980)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id, v.reasoning, v.sources
FROM pol, (VALUES
  ('b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid,
   $$On May 8, 2018 Miranda, a then-seated councilmember, joined the unanimous 5-0 vote to oppose California's SB54 sanctuary-state law and back the federal lawsuit, saying 'It's about doing the right thing.' Voting to reject sanctuary protections and cooperate with federal immigration enforcement matches chair 4.$$,
   ARRAY['https://www.hometownstation.com/santa-clarita-news/politics/santa-clarita-city-council-votes-to-oppose-sanctuary-state-law-232750','https://signalscv.com/2018/05/santa-clarita-city-council-oks-support-for-sb-54-lawsuit/']::text[]),
  ('f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,
   $$Miranda joined the council's unanimous vote to formally oppose Measure ER (a half-cent county sales-tax increase) and said 'We should be taxed less... our economies would be more vibrant... if we tax less,' criticizing government spending. Advocating cutting taxes and scaling back spending matches chair 4.$$,
   ARRAY['https://www.hometownstation.com/santa-clarita-latest-news/santa-clarita-to-officially-take-over-fourth-of-july-parade-council-opposes-county-sales-tax-594010']::text[]),
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid,
   $$Miranda states 'Public safety is and always will be the top priority of our city,' advocated increased law-enforcement resources, opened the new SCV Sheriff Station as mayor, and supported the FY2026-27 budget making law enforcement the largest general-fund line (~$36.5M) with a sheriff-contract increase. Prioritizing added police resources matches chair 4.$$,
   ARRAY['https://scvelitemagazine.com/bill-miranda-a-dedicated-leader-of-santa-clarita/','https://www.hometownstation.com/santa-clarita-news/politics/santa-clarita-city-council/santa-clarita-city-council-passes-361-4-million-budget-for-2026-27-592719']::text[]),
  ('669cac97-66a6-4087-b036-936fbe62efb3'::uuid,
   $$Miranda says 'We have a very serious affordable housing problem... We need affordable housing here,' and on the MetroWalk project directed staff to revise the plan while preserving the affordable senior-housing component, noting developers' difficulty getting tax credits. Backing targeted affordable units through the approval process matches chair 3.$$,
   ARRAY['https://www.hometownstation.com/santa-clarita-news/politics/santa-clarita-city-council/we-need-affordable-housing-santa-clarita-city-council-wrestles-with-state-pressures-and-affordable-housing-550309']::text[]),
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,
   $$Miranda backs large-scale managed growth (e.g., the 6,500-home Sunridge development and downtown mixed-use) while pairing it with proactive investment in parks, transportation and infrastructure, saying 'Progress happens.' Planning proactively and investing in infrastructure to support expansion matches chair 3.$$,
   ARRAY['https://www.hometownstation.com/santa-clarita-news/community-news/santa-clarita-set-for-major-expansion-with-new-housing-parks-and-infrastructure-projects-538699']::text[]),
  ('eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,
   $$A former founder/CEO of the SCV Latino Chamber of Commerce, Miranda lists Local Economy as a top priority and has 'championed initiatives to attract businesses and create job opportunities'; the city actively competes for business via its film-incentive program subsidizing permit/safety costs. Actively recruiting business with incentives matches chair 4.$$,
   ARRAY['https://scvelitemagazine.com/bill-miranda-a-dedicated-leader-of-santa-clarita/','https://www.scvedc.org/blog/new-extension-in-film-tax-credits-is-good-news-for-santa-clarita']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
