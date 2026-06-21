-- 897_laurene_weste_stances.sql
-- Phase 143 / Plan 04 — Laurene Weste (Mayor, external_id 665693) evidence-only compass stances.
-- AUDIT-ONLY: apply via raw SQL; does NOT register in schema_migrations (ledger MAX stays 895).
-- Chairs model: each value 1-5 is the position statement matching her documented record (no polarity).
-- Evidence-only, 100% citation, honest blanks (national topics left blank — no local record).
-- 7 evidenced topics. politician_id resolved by external_id at apply time.

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 665693)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id, v.value
FROM pol, (VALUES
  ('b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 4),  -- local-immigration
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 2),  -- local-environment
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2),  -- growth-and-development
  ('ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 4),  -- transportation-priorities
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),  -- public-safety-approach
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 2),  -- homelessness-response
  ('eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 3)   -- economic-development
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 665693)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id, v.reasoning, v.sources
FROM pol, (VALUES
  ('b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid,
   $$In May 2018, while a seated councilmember, Weste joined the unanimous Santa Clarita City Council vote to oppose California's SB54 'sanctuary state' law and direct the city attorney to file an amicus brief supporting the federal lawsuit; she argued limiting law-enforcement cooperation 'is a mistake.' Matches chair 4 (honor detainers + cooperate with federal enforcement).$$,
   ARRAY['https://www.hometownstation.com/santa-clarita-news/politics/santa-clarita-city-council-votes-to-oppose-sanctuary-state-law-232750','https://abc7.com/santa-clarita-sanctuary-state-law-california-sb54/3448016/','https://signalscv.com/2018/05/santa-clarita-city-council-oks-support-for-sb-54-lawsuit/']::text[]),
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid,
   $$Weste spearheaded the Santa Clarita Open Space Preservation District (11,000-13,000+ acres preserved), founded the 100+ mile trail system, works to protect the Santa Clara River, and led the city's decades-long fight to block the CEMEX Soledad Canyon mega-mine. This strict parks/open-space protection record matches chair 2.$$,
   ARRAY['https://santaclarita.gov/city-council/laurene-weste/','https://www.hometownstation.com/santa-clarita-news/community-news/decades-long-battle-against-cemex-soledad-canyon-mega-mine-could-be-over-337973','https://signalscv.com/2019/10/no-11-laurene-weste/']::text[]),
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,
   $$Weste's signature growth strategy is an open-space 'green belt' to surround the city and limit where development can occur, plus preserving thousands of acres while pursuing 'sustainable growth.' Constraining sprawl and channeling growth matches chair 2 (allow growth only where supported; slow/limit expansion).$$,
   ARRAY['https://santaclarita.gov/city-council/laurene-weste/','https://santaclaritamagazine.com/2022/09/meet-the-candidate-laurene-weste-running-for-city-council/','https://signalscv.com/2019/10/no-11-laurene-weste/']::text[]),
  ('ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid,
   $$Weste's stated transportation priority is building roads to ease congestion; she championed the Cross Valley Connector and has repeatedly secured federal funding to expand capacity at the city's highest-volume intersections. This driver/road-capacity focus matches chair 4.$$,
   ARRAY['https://santaclarita.gov/city-council/laurene-weste/','https://santaclaritamagazine.com/2010/08/cross-valley-connector-reduces-traffic-across-city/','https://www.hometownstation.com/santa-clarita-news/press-releases/representative-whitesides-to-announce-over-1-million-investment-for-traffic-and-pedestrian-safety-improvements-in-santa-clarita-592203']::text[]),
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid,
   $$After Deputy Ryan Clinkunbroomer's murder, Weste pushed Santa Clarita to investigate creating a city prosecutor to increase prosecutions, blaming a lack of prosecutions for rising thefts/robberies, and stressed residents feeling 'secure and safe.' Her emphasis on stronger enforcement/prosecution capacity matches chair 4.$$,
   ARRAY['https://signalscv.com/2023/09/weste-asks-santa-clarita-to-look-into-city-prosecutor/','https://santaclaritamagazine.com/2022/09/meet-the-candidate-laurene-weste-running-for-city-council/']::text[]),
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid,
   $$Under Weste the city donated land to build the permanent Bridge to Home full-service shelter (beds plus family units, case management, mental health and job services), which she called 'a pivotal moment in our city.' Her record centers on expanding shelter/services with no enforcement emphasis, matching chair 2.$$,
   ARRAY['https://signalscv.com/2022/03/building-a-bridge-to-home-dignitaries-break-ground-on-the-scvs-new-permanent-homeless-shelter/','https://www.hometownstation.com/santa-clarita-news/community-news/a-new-dawn-in-santa-clarita-family-promises-new-housing-center-brings-hope-to-homeless-families-527582']::text[]),
  ('eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,
   $$Weste says she has 'expanded economic development projects to create more local jobs and boost our economy' while balancing business needs with environmental standards, and drove the Old Town Newhall revitalization. This targeted, jobs-and-community-conscious approach matches chair 3.$$,
   ARRAY['https://santaclaritamagazine.com/2022/09/meet-the-candidate-laurene-weste-running-for-city-council/','https://signalscv.com/2019/10/no-11-laurene-weste/']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
