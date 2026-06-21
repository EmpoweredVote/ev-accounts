-- 909_alek_bartrosouf_stances.sql
-- Phase 144 / Plan 04 — Alek Bartrosouf (external_id -700101, incoming) evidence-only compass stances.
-- AUDIT-ONLY: raw SQL, NOT registered in schema_migrations (ledger stays 903). Chairs model; 100% citation.
-- No council votes yet → scored from campaign platform / GAOR questionnaire / GEC endorsement / commission record.
-- 7 stances; public-safety/taxes/rent-regulation deliberately blank (no clean chair match). No judicial (D-13).
-- transportation-priorities 1=transit…5=highways. Armenian/Artsakh: none surfaced, none mapped (D-14).

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -700101)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id::uuid, v.value
FROM pol, (VALUES
  ('ba59337e-30e2-4aba-a39a-426b3366eb27', 2),  -- transportation-priorities
  ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),  -- climate-change
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3),  -- growth-and-development
  ('669cac97-66a6-4087-b036-936fbe62efb3', 3),  -- housing
  ('d4f18138-a2e0-4110-b925-7387d9d0d16d', 3),  -- residential-zoning
  ('eb3d1247-0de1-4b7f-baec-7259861efd53', 2),  -- economic-development
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)   -- local-environment
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = -700101)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id::uuid, v.reasoning, v.sources
FROM pol, (VALUES
  ('ba59337e-30e2-4aba-a39a-426b3366eb27',
   $$As Transportation & Parking Commission chair and a professional transportation planner, his platform pushes multimodal investment — Metro BRT, Safe Routes to School, pedestrian master plan, bike/ped safety — but he explicitly does NOT support removing vehicle lanes solely to add bike lanes (opposed the N. Brand road diet) and defends parking. This balanced roads-plus-multimodal stance matches investing equally in roads and multimodal. (Platform/commission positions, not council votes.)$$,
   ARRAY['https://www.gaor.org/wp-content/uploads/2026/03/Alek-Bartrosouf-Response.pdf','https://www.progressivevotersguide.com/california/2026/primary/alek-bartrosouf','https://gec.eco/gec-2026-city-council-endorsements/']::text[]),
  ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   $$He defends Glendale's Climate Action and Adaptation Plan and supports reducing fossil-fuel consumption through incentives rather than bans — praising "generous financial incentives to switch to heat pump systems" and saying transitions should be "easy for homeowners," plus local clean energy. A gradual, incentive-based clean-energy approach matching invest-in-clean-energy-while-gradually-reducing-fossil-fuels. (Platform positions, not votes.)$$,
   ARRAY['https://www.gaor.org/wp-content/uploads/2026/03/Alek-Bartrosouf-Response.pdf','https://gec.eco/gec-2026-city-council-endorsements/']::text[]),
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
   $$On the GAOR questionnaire he checked "a balance of both," said officials must honor voter sentiment while adhering to state/local zoning law ("any candidate who tells you we can stop development... is lying"), and highlighted proactive community plans (Tropico TOD, Downtown Specific Plan) that inform land-use policy — planning ahead of growth. (Platform positions, not votes.)$$,
   ARRAY['https://www.gaor.org/wp-content/uploads/2026/03/Alek-Bartrosouf-Response.pdf','https://www.crescentavalleyweekly.com/news/05/21/2026/the-candidates-respond-5/']::text[]),
  ('669cac97-66a6-4087-b036-936fbe62efb3',
   $$His platform emphasizes building "missing middle" entry-level for-sale housing (condos/townhomes) so younger residents can build equity, plus more affordable rentals near jobs/transit, paired with streamlining permits (express permitting, preapproved ADUs) — targeted help, first-buyer focus, and easier permits. (Platform positions, not votes.)$$,
   ARRAY['https://www.gaor.org/wp-content/uploads/2026/03/Alek-Bartrosouf-Response.pdf','https://goodparty.org/candidate/alek-bartrosouf/glendale-city-council']::text[]),
  ('d4f18138-a2e0-4110-b925-7387d9d0d16d',
   $$He selected "a balanced mix depending on location" for housing types and supports concentrating new housing/TOD near corridors (Tropico TOD, Downtown Specific Plan) while emphasizing community engagement and updated Comprehensive Design Guidelines to honor neighborhood/historic character — multifamily/mixed-use near corridors, protect most residential. (Platform positions, not votes.)$$,
   ARRAY['https://www.gaor.org/wp-content/uploads/2026/03/Alek-Bartrosouf-Response.pdf','https://goodparty.org/candidate/alek-bartrosouf/glendale-city-council']::text[]),
  ('eb3d1247-0de1-4b7f-baec-7259861efd53',
   $$His economic-development emphasis is revamping/streamlining permitting and expediting permits for small businesses and wildfire-zone households, with repeated references to supporting small business, and no mention of large abatements to recruit major employers — matching small-business/local-entrepreneur support. (Platform positions, not votes.)$$,
   ARRAY['https://www.gaor.org/wp-content/uploads/2026/03/Alek-Bartrosouf-Response.pdf','https://goodparty.org/candidate/alek-bartrosouf/glendale-city-council']::text[]),
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa',
   $$As GEC co-founder and former Sustainability Commissioner he advocates increasing tree canopy, more shade, and more parks, but pairs it with a balanced development stance — updated design guidelines and reasonable flexibility rather than blocking development for environmental review — matching consistent standards with reasonable developer flexibility. (Platform/commission positions, not votes.)$$,
   ARRAY['https://gec.eco/gec-2026-city-council-endorsements/','https://goodparty.org/candidate/alek-bartrosouf/glendale-city-council']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
