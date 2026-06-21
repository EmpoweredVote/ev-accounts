-- 907_elen_asatryan_stances.sql
-- Phase 144 / Plan 04 — Elen Asatryan (external_id 686337) evidence-only compass stances.
-- AUDIT-ONLY: raw SQL, NOT registered in schema_migrations (ledger stays 903). Chairs model; 100% citation.
-- transportation-priorities 1=transit…5=highways. No judicial topics (D-13). 10 stances; national topics blank.
-- Armenian/Artsakh diaspora advocacy correctly NOT mapped to any chair (D-14).

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 686337)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id::uuid, v.value
FROM pol, (VALUES
  ('ba59337e-30e2-4aba-a39a-426b3366eb27', 1),  -- transportation-priorities
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa', 2),  -- local-environment
  ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),  -- climate-change
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3),  -- homelessness-response
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85', 3),  -- public-safety-approach
  ('c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),  -- rent-regulation
  ('669cac97-66a6-4087-b036-936fbe62efb3', 3),  -- housing
  ('eb3d1247-0de1-4b7f-baec-7259861efd53', 2),  -- economic-development
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 2),  -- growth-and-development
  ('0bc588c6-39e1-4084-b5de-cac909b8b762', 2)   -- civil-rights
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 686337)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id::uuid, v.reasoning, v.sources
FROM pol, (VALUES
  ('ba59337e-30e2-4aba-a39a-426b3366eb27',
   $$Asatryan is a sustained champion of the Beeline transit system, advocating its expansion and full electrification (zero-emissions fleet by 2035); GEC endorsed her specifically for backing "safe and convenient local public transportation especially the BeeLine" plus bicycle/pedestrian safety, and she frames safety around "safer street design, traffic calming... pedestrian protections" — prioritizing transit and active mobility.$$,
   ARRAY['https://gec.eco/gec-2026-city-council-endorsements/','https://www.glendaleca.gov/government/city-council/mayor-elen-asatryan','https://www.electelen.com/whyiamrunning']::text[]),
  ('1935979c-b290-42e4-baa5-8cb0138b4ffa',
   $$As mayor she secured property for the largest park in South Glendale and "meaningful investments in our parks and open spaces," and joined a 3-1 vote to deny an 8-story Sears-site project because the developer ignored community/council design requests — requiring developers to address impact rather than rubber-stamp development.$$,
   ARRAY['https://www.electelen.com/whyiamrunning','https://outlooknewspapers.com/glendalenewspress/glendale-city-council-denies-demolition-project-application-at-former-sears-site/article_125c968f-b85c-4912-843e-2f5777599aa0.html']::text[]),
  ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   $$GEC endorsed her as "a strong advocate for clean energy" and building electrification, and she backs tree canopy and transit electrification (zero-emissions Beeline by 2035), while stressing clean-energy implementation must be "accessible for all, including renters and small businesses" — a measured invest-in-clean-energy posture rather than emergency bans.$$,
   ARRAY['https://gec.eco/gec-2026-city-council-endorsements/','https://www.glendaleca.gov/government/city-council/mayor-elen-asatryan']::text[]),
  ('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
   $$As mayor she said the city "expanded outreach and wraparound services for our homeless population" and moved homeless services into Community Development to coordinate outreach, housing, and assistance, framing safety as "compassion... housing... mental health support" — outreach/shelter/services delivered alongside reasonable public-space management.$$,
   ARRAY['https://outlooknewspapers.com/glendalenewspress/mayor-outlines-growth-improvements-in-city-address/article_c16462db-0275-4499-91de-8b262571f144.html','https://www.electelen.com/whyiamrunning']::text[]),
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85',
   $$Asatryan "strengthened public safety staffing" and praised the Police Department's new Real Time Intelligence Center, while stating safety "means more than patrols. It means compassion, it means housing, it means mental health support" — keeping police funding intact while adding prevention and mental-health/crisis-oriented elements.$$,
   ARRAY['https://outlooknewspapers.com/glendalenewspress/mayor-outlines-growth-improvements-in-city-address/article_c16462db-0275-4499-91de-8b262571f144.html','https://www.electelen.com/whyiamrunning']::text[]),
  ('c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
   $$During the Oct 2025 renters'-rights debate she backed city notification of eviction notices, city-funded legal counsel for renters, and a tenant self-service portal (rejected by the majority), and as Housing Authority chair "worked to protect residents facing housing insecurity" — strengthening/extending tenant protections beyond the status quo, with no evidence she sought citywide rent caps.$$,
   ARRAY['https://outlooknewspapers.com/glendalenewspress/council-debates-proposed-renters-rights-programs/article_a71f3848-76b0-11ef-a8f9-1f130481a4b5.html','https://www.electelen.com/whyiamrunning']::text[]),
  ('669cac97-66a6-4087-b036-936fbe62efb3',
   $$She "pushed for investments in affordable housing and stronger housing stability programs," "brought back rental assistance," and as mayor the city completed the Piedmont (68 senior units) and Citrus Crossing (127 family units) projects — targeted subsidies, rental assistance, and supporting affordable projects rather than city-run public housing or rent caps.$$,
   ARRAY['https://www.electelen.com/whyiamrunning','https://outlooknewspapers.com/glendalenewspress/mayor-outlines-growth-improvements-in-city-address/article_c16462db-0275-4499-91de-8b262571f144.html']::text[]),
  ('eb3d1247-0de1-4b7f-baec-7259861efd53',
   $$Asatryan centers small-business support: she launched a COVID-era Community Resource Center to help small businesses access grants, grew the Small Business Summit, and emphasizes "cutting the bureaucratic red tape that... keeps small businesses locked out" — small/local business support rather than large corporate abatements.$$,
   ARRAY['https://www.electelen.com/about','https://www.electelen.com/whyiamrunning']::text[]),
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
   $$On the former Sears site she joined a 3-1 vote to deny an 8-story, 682-unit project because the developer "did not take into consideration requests from the community and council regarding design," even after legal counsel warned of Housing Accountability Act exposure — willing to slow/condition major development on community and design concerns.$$,
   ARRAY['https://outlooknewspapers.com/glendalenewspress/glendale-city-council-denies-demolition-project-application-at-former-sears-site/article_125c968f-b85c-4912-843e-2f5777599aa0.html']::text[]),
  ('0bc588c6-39e1-4084-b5de-cac909b8b762',
   $$Asatryan founded the Glendale Domestic Violence Task Force, supported the Glendale Black Scholars Fund, highlighted Glendale joining the California Equal Pay Pledge (Feb 2024), and registered over 50,000 new voters; her platform lists equity and women's issues as priorities — an active enforcement-and-equity record matching strengthening enforcement and addressing discrimination.$$,
   ARRAY['https://en.wikipedia.org/wiki/Elen_Asatryan','https://www.electelen.com/about']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
