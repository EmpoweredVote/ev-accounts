-- 905_daniel_brotman_stances.sql
-- Phase 144 / Plan 04 — Dan Brotman (external_id 686340) evidence-only compass stances.
-- AUDIT-ONLY: apply via raw SQL, does NOT register in supabase_migrations.schema_migrations (ledger stays 903).
-- Chairs model (value = the discrete chair the documented record matches). 100% citation. Honest blanks.
-- transportation-priorities: 1=transit … 5=highways. No judicial topics (appointed City Attorney, D-13).
-- 7 stances; all national topics + local-immigration left blank for lack of an attributable record.

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 686340)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id::uuid, v.value
FROM pol, (VALUES
  ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2),  -- climate-change
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa', 2),  -- local-environment
  ('ba59337e-30e2-4aba-a39a-426b3366eb27', 1),  -- transportation-priorities
  ('669cac97-66a6-4087-b036-936fbe62efb3', 3),  -- housing
  ('d4f18138-a2e0-4110-b925-7387d9d0d16d', 3),  -- residential-zoning
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3),  -- homelessness-response
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)   -- public-safety-approach
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 686340)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id::uuid, v.reasoning, v.sources
FROM pol, (VALUES
  ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   $$Brotman co-founded the Glendale Environmental Coalition and led the campaign to repower the Grayson Power Plant with renewables and battery storage instead of new gas; on council he has pushed battery/V2X integration and heat-pump electrification, citing the "worsening climate crisis." Record reflects rapidly transitioning to renewables and phasing out fossil fuels.$$,
   ARRAY['https://laist.com/news/glendale-just-approved-what-may-be-californias-last-natural-gas-lit-power-plant','https://gec.eco/gec-2026-city-council-endorsements/']::text[]),
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa',
   $$Brotman's documented record strongly prioritizes environmental protection — expanding tree canopy, building electrification, electric equipment for homes/parks, and plastic reduction; the Glendale Environmental Coalition endorsed him for consistent "deep support for environmental causes."$$,
   ARRAY['https://gec.eco/gec-2026-city-council-endorsements/','https://www.glendaleca.gov/government/city-council/councilmember-dan-brotman']::text[]),
  ('ba59337e-30e2-4aba-a39a-426b3366eb27',
   $$In his Bike The Vote LA questionnaire Brotman called to "build more public transit, make Glendale more walkable and bikeable," backed a large interconnected protected bike-lane network, supported dedicated bus-rapid-transit lanes and Vision Zero design, and argued residents should not "subsidize our car culture" through free parking — prioritizing transit/walk/bike over cars.$$,
   ARRAY['https://www.bikethevote.com/dan-brotmans-response-to-bike-the-vote-la/']::text[]),
  ('669cac97-66a6-4087-b036-936fbe62efb3',
   $$Brotman backs removing "barriers that are preventing the development of for-sale housing" so young families have a path to ownership, stronger design standards, and tenant protections like a first right to return for displaced renters — targeted help and easier permitting rather than public housing or broad rent caps.$$,
   ARRAY['https://www.crescentavalleyweekly.com/news/05/21/2026/the-candidates-respond-5/']::text[]),
  ('d4f18138-a2e0-4110-b925-7387d9d0d16d',
   $$Brotman supports "higher-density apartments downtown, low-to mid-density townhouses... along our commercial corridors, and detached homes, perhaps with ADUs, in the single-family neighborhoods," and moved to expand ADU allowances — concentrating multifamily/mixed-use near corridors while preserving most single-family areas.$$,
   ARRAY['https://www.crescentavalleyweekly.com/news/05/21/2026/the-candidates-respond-5/','https://outlooknewspapers.com/glendalenewspress/city-council-retains-several-zoning-codes/article_f622f418-b399-11ef-bf7e-ffa2cb0e2dca.html']::text[]),
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
   $$When Glendale added daytime enforcement to its anti-camping ordinance after Grants Pass, Brotman supported it as comprehensive, noting the city has enough hotel vouchers to offer 30-day temporary housing and framing enforcement as "an extra tool to encourage individuals to accept services" — pairing outreach/services with enforcement of public-space rules.$$,
   ARRAY['https://outlooknewspapers.com/glendalenewspress/day-enforcement-added-to-camping-rules/article_fbc1f7c6-b2b7-11ef-b62b-dbeccaab2be5.html']::text[]),
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85',
   $$In the FY2025-26 budget Brotman affirmed "We're not cutting police or fire" and that the budget "adds 23 police officers" while finding cheaper ways to maintain services — supporting increased police staffing.$$,
   ARRAY['https://www.crescentavalleyweekly.com/news/06/26/2025/billion-dollar-budget-approved-by-council/']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
