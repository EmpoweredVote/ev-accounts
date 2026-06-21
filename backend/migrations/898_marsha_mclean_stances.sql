-- 898_marsha_mclean_stances.sql
-- Phase 143 / Plan 04 — Marsha McLean (Councilmember, external_id -201394) evidence-only compass stances.
-- AUDIT-ONLY: apply via raw SQL; does NOT register in schema_migrations (ledger MAX stays 895).
-- Chairs model; evidence-only; 100% citation; honest blanks. 8 evidenced topics.
-- NOTE: McLean's external_id is -201394 (reseated existing row; NOT -700181).

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -201394)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id, v.value
FROM pol, (VALUES
  ('b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 4),  -- local-immigration
  ('ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 2),  -- transportation-priorities
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),  -- local-environment
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),  -- public-safety-approach
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2),  -- growth-and-development
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 2),  -- homelessness-response
  ('669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),  -- housing
  ('eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3)   -- economic-development
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -201394)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id, v.reasoning, v.sources
FROM pol, (VALUES
  ('b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid,
   $$As a seated councilmember (Mayor Pro Tem) in May 2018, McLean was part of the unanimous vote to oppose California's SB54 sanctuary-state law and join the federal lawsuit, aligning the city with federal immigration enforcement. A vote to oppose sanctuary protections and cooperate with federal enforcement matches chair 4.$$,
   ARRAY['https://www.hometownstation.com/santa-clarita-news/politics/santa-clarita-city-council-votes-to-oppose-sanctuary-state-law-232750','https://abc7.com/post/santa-clarita-council-votes-to-opt-out-of-sanctuary-state-law/3448016/']::text[]),
  ('ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid,
   $$McLean is both a major road-investment advocate (secured $250-300M for road improvements and signal synchronization) and a leading transit champion (founded the SCV Transportation Coalition, won doubled weekend Metrolink trains, pushes multimodal centers and zero-emission transit). This balance of roads plus robust multimodal investment matches chair 2.$$,
   ARRAY['https://reelectmarshamclean.com/','https://signalscv.com/2025/09/marsha-mclean-a-city-in-motion-santa-clarita-transit/','https://santaclarita.gov/city-council/marsha-mclean/']::text[]),
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid,
   $$McLean founded the S.C.V. Canyons Preservation Committee, spent 14 years blocking a massive landfill at Elsmere Canyon, and helped preserve over 8,000 acres of open space — a strict protect-parks-and-open-space record where development must offset impacts. Matches chair 2.$$,
   ARRAY['https://santaclarita.gov/city-council/marsha-mclean/','https://reelectmarshamclean.com/']::text[]),
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid,
   $$A former LAPD employee endorsed by police unions, McLean campaigns as 'Tough on Crime,' emphasizes the ~$30M annual Sheriff's contract and backing deputies, and blames the DA for under-charging. Her framing centers on funding/backing law enforcement rather than co-responders, matching chair 4.$$,
   ARRAY['https://signalscv.com/2022/04/marsha-mclean-public-safety-is-top-priority/','https://reelectmarshamclean.com/']::text[]),
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,
   $$McLean campaigns on 'fighting overcrowding,' pledges she 'will not sacrifice older established neighborhoods for new development,' and ties development to adequate roads, schools, parks and infrastructure. This slow-growth, infrastructure-conditioned posture matches chair 2.$$,
   ARRAY['https://reelectmarshamclean.com/','https://santaclaritamagazine.com/2022/08/meet-the-candidate-marsha-mclean-running-for-city-council/']::text[]),
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid,
   $$McLean chairs the city's Community Task Force on Homelessness (Advocacy/Prevention/Direct Services/Housing); under her the city donated land and $2M to build the Bridge to Home and Family Promise shelters. The approach is shelter/services-development primary rather than enforcement-led, matching chair 2.$$,
   ARRAY['https://santaclarita.gov/blog/2024/02/04/tackling-homelessness-in-santa-clarita/','https://www.hometownstation.com/santa-clarita-news/politics/santa-clarita-city-council/we-need-affordable-housing-santa-clarita-city-council-wrestles-with-state-pressures-and-affordable-housing-550309']::text[]),
  ('669cac97-66a6-4087-b036-936fbe62efb3'::uuid,
   $$McLean backs the First Time Home Buyers Program for families, teachers, firefighters and police, advocates expanded senior and veterans' housing, and insists developers build the promised affordable units while resisting heavy density. This targeted-subsidy and first-buyer-help approach matches chair 3.$$,
   ARRAY['https://reelectmarshamclean.com/','https://www.hometownstation.com/santa-clarita-news/politics/santa-clarita-city-council/we-need-affordable-housing-santa-clarita-city-council-wrestles-with-state-pressures-and-affordable-housing-550309']::text[]),
  ('eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,
   $$A small-business owner herself, McLean supports 'quality business recruitment that brings high paying jobs with good benefits,' tying business attraction to job quality rather than blanket subsidies. This targeted, job-quality approach matches chair 3.$$,
   ARRAY['https://reelectmarshamclean.com/','https://santaclarita.gov/city-council/marsha-mclean/']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
