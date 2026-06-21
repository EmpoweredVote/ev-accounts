-- 906_ardy_kassakhian_stances.sql
-- Phase 144 / Plan 04 — Ardy Kassakhian (external_id 686339, Mayor) evidence-only compass stances.
-- AUDIT-ONLY: raw SQL, NOT registered in schema_migrations (ledger stays 903). Chairs model; 100% citation.
-- transportation-priorities 1=transit…5=highways. No judicial topics (D-13). 9 stances; national topics blank.
-- Armenian/Artsakh (Artsakh blockade condemnation) correctly NOT mapped to any chair (D-14).

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 686339)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id::uuid, v.value
FROM pol, (VALUES
  ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),  -- climate-change
  ('a22215c3-6693-4bc2-b248-01aebba14570', 2),  -- fossil-fuels
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa', 2),  -- local-environment
  ('ba59337e-30e2-4aba-a39a-426b3366eb27', 1),  -- transportation-priorities
  ('669cac97-66a6-4087-b036-936fbe62efb3', 3),  -- housing
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3),  -- growth-and-development
  ('eb3d1247-0de1-4b7f-baec-7259861efd53', 2),  -- economic-development
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85', 3),  -- public-safety-approach
  ('c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 3)   -- rent-regulation
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 686339)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id::uuid, v.reasoning, v.sources
FROM pol, (VALUES
  ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   $$Kassakhian proposed the resolution to put 10% solar-plus-storage on Glendale rooftops by 2027 and voted to direct Glendale Water & Power to integrate the Council's Clean Energy by 2035 Resolution; his platform calls for a grid that "aggressively reduces greenhouse gases." An aggressive but phased clean-energy transition on a 2035 horizon matches investing in clean energy while gradually reducing fossil fuels.$$,
   ARRAY['https://gec.eco/gec-endorses-ardy-kassakhian-karen-kwak/','https://ardykassakhian.com/issues/']::text[]),
  ('a22215c3-6693-4bc2-b248-01aebba14570',
   $$Kassakhian voted NO on the Grayson biogas/thermal generation proposal, rejecting the claim it was renewable: "It isn't a fossil fuel, [and] it is far from renewable." Opposing new gas-fired generation in favor of clean alternatives matches stopping new fossil-fuel projects/permits.$$,
   ARRAY['https://www.crescentavalleyweekly.com/news/12/02/2021/biogas-debate-subject-of-council-meeting/']::text[]),
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa',
   $$He supported Glendale's bans on polystyrene and gas-powered leaf blowers, backs recyclable/biodegradable takeout packaging, and was endorsed by the Glendale Environmental Coalition and Sierra Club for a strong sustainability record — strict local environmental protection beyond state/federal minimums.$$,
   ARRAY['https://gec.eco/gec-endorses-ardy-kassakhian-karen-kwak/','https://ardykassakhian.com/issues/']::text[]),
  ('ba59337e-30e2-4aba-a39a-426b3366eb27',
   $$Kassakhian's platform pledges to "increase bus ridership and take cars off of our streets," and he voted to fund the Beeline portion of a free GoPass transit-pass program; the GEC noted his focus on pedestrian and bicycle safety — prioritizing transit, walking, and cycling over road/parking capacity.$$,
   ARRAY['https://ardykassakhian.com/issues/','https://www.metro.net/about/glendale-community-college-l-a-metro-glendale-beeline-partner-to-offer-gopass-free-transit-pass-program-to-all-students-for-start-of-school-year/']::text[]),
  ('669cac97-66a6-4087-b036-936fbe62efb3',
   $$His platform calls for more affordable housing for low-income families, seniors, and workforce plus a first-time homebuyer-assistance program; at the Sears site he said "I want the largest number of housing units possible" — matching targeted subsidies, first-buyer help, and enabling more units.$$,
   ARRAY['https://ardykassakhian.com/issues/','https://www.crescentavalleyweekly.com/news/10/23/2025/council-rejects-proposal-for-sears-property/']::text[]),
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
   $$Kassakhian wants to "stop the runaway overdevelopment of luxury projects" yet seeks the maximum number of housing units; he voted against the 682-unit Sears proposal on quality grounds, not to block housing — reflecting proactive, quality-conscious planning rather than hard caps or removing all barriers.$$,
   ARRAY['https://ardykassakhian.com/issues/','https://www.crescentavalleyweekly.com/news/10/23/2025/council-rejects-proposal-for-sears-property/']::text[]),
  ('eb3d1247-0de1-4b7f-baec-7259861efd53',
   $$His platform focuses on eliminating "artificial hurdles businesses currently face," supporting small businesses, and making Glendale a "tech hub" by attracting startups, without large tax abatements for major employers — matching small-business/local-entrepreneur support.$$,
   ARRAY['https://ardykassakhian.com/issues/']::text[]),
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85',
   $$Kassakhian's platform makes "ensuring that our police have the resources they need" a top priority and pledges to restore the gun buy-back program, school resource officers, and drug-education programs — maintaining police funding while adding community/support programs.$$,
   ARRAY['https://ardykassakhian.com/issues/']::text[]),
  ('c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
   $$His documented rental-housing actions are to "crack down on slumlords," expand Section 8 units, and propose a strictly voluntary pre-litigation mediation program for renters and providers — working within existing tenant protections rather than expanding rent control.$$,
   ARRAY['https://ardykassakhian.com/issues/','https://members.aagla.org/news/glendale-editorial-nwe-won--glendale-rejects-4-of-5-proposed-new-restrictions-on-housing-providers']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
