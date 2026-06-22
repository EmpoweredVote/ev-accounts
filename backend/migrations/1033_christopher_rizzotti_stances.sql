-- 1033_christopher_rizzotti_stances.sql
-- Phase 154 Burbank deep-seed Wave 4 — evidence-only compass stances for Christopher John Rizzotti
-- AUDIT-ONLY: raw SQL applied live via Supabase MCP, NOT registered in supabase_migrations.schema_migrations (ledger stays 1027).
-- CHAIRS model (value = the chair the evidence matches, never a polarity axis). 100% citation (paired
-- inform.politician_answers + inform.politician_context, every stance with reasoning + >=1 real source URL).
-- No defaulted/neutral values; honest blank spokes omitted. NO judicial-* topics (council-manager city).
-- politician_id a83a63a8-3e0f-4a2e-9226-8c0cd26a1349 | 5 stances.

BEGIN;

-- public-safety-approach = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'Rizzotti received endorsements from both the Burbank Police Officers Association and the Burbank Firefighters Association and pledged he would ''never take our public safety for granted by abolishing or reducing those budgets as our population grows.'' This is an explicit commitment to increase or at minimum protect police and fire resources — matching chair 4 (increase police staffing, equipment, and pay to improve response times and deter crime).', ARRAY['https://myburbank.com/rizzotti-endorsed-by-burbank-police-officers-association/', 'https://outlooknewspapers.com/burbankleader/news/candidates-distinguish-themselves-at-forum/article_1dd0ae74-87e4-11ef-8b32-0fec033cc767.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-immigration = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 4)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 'At the December 9, 2025 city council meeting Rizzotti publicly praised ICE agents and rebuked members of the public who criticized ICE. He then voted (2-2 deadlock) against sending a letter of support for SB 805, which would have required federal law enforcement to identify themselves during operations, dismissing the bill as ''virtue signaling.'' These two on-record acts together match chair 4 (honor ICE detainers and share information proactively when federal agencies request it).', ARRAY['https://outlooknewspapers.com/burbankleader/ice-comments-at-burbank-city-council-meeting-ignite-recall-effort/article_3774b085-66f8-4846-9e9a-db383241ec90.html', 'https://outlooknewspapers.com/burbankleader/news/burbank-council-deadlocks-on-move-to-ban-unmarked-law-enforcement/article_d3b2f77f-48bc-466a-803e-ed118f0c21c9.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- residential-zoning = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 'On the Planning Board, Rizzotti voted against SB 35, SB 9, and AB 2011 (state bills allowing broader housing density in residential zones), rejected most ADU proposals as ''zone changes,'' and during the 2024 candidate forum said development should be directed to vacant commercial sites rather than residential neighborhoods. He supported the very first ADU iteration, indicating he accepts minimal accessory-unit density but opposes broader upzoning — matching chair 2 (allow modest density increases such as accessory units with strong design review and neighborhood input).', ARRAY['https://outlooknewspapers.com/burbankleader/news/candidates-distinguish-themselves-at-forum/article_1dd0ae74-87e4-11ef-8b32-0fec033cc767.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- growth-and-development = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 'Rizzotti consistently opposed state housing mandates (SB 9, SB 35, AB 2011) that would accelerate residential development, advocated targeting growth at vacant commercial parcels (Kmart, former IKEA sites) rather than expanding into residential neighborhoods, and as Planning Board Chair oversaw a board that recommended restrictive measures. This reflects a ''allow growth only where existing infrastructure can support it'' posture matching chair 2.', ARRAY['https://outlooknewspapers.com/burbankleader/news/candidates-distinguish-themselves-at-forum/article_1dd0ae74-87e4-11ef-8b32-0fec033cc767.html', 'https://myburbank.com/city-planning-board-recommends-ban-on-short-term-rentals/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('a83a63a8-3e0f-4a2e-9226-8c0cd26a1349', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 'Rizzotti''s campaign platform listed ''Homeless Programs & Outreach'' as a priority. He cited Burbank''s $10M Measure H contribution while receiving back only ~$200K in services, and pledged to secure a larger share of those funds to support outreach programs and hire more mental health professionals. This is a middle-ground outreach-and-services position — not housing-first (chair 1) and not enforcement-primary (chairs 4-5) — matching chair 3 (invest in outreach, shelter, and mental health services while enforcing reasonable public space rules).', ARRAY['https://www.chrisforburbank.com/', 'https://myburbanktalks.buzzsprout.com/2131974/episodes/15672727-meet-the-candidate-chris-rizzotti-burbank-city-council-candidate']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Post-apply verification:
--   SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id='a83a63a8-3e0f-4a2e-9226-8c0cd26a1349'; -> 5
--   every answer has a paired context row (0 unpaired); 0 judicial-* topics; ledger MAX unchanged (1027).
