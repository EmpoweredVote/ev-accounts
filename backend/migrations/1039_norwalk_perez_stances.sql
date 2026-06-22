-- 1039_norwalk_perez_stances.sql
-- Phase 155 Wave 4 (NRWK-01): Jennifer Perez (pol 3ed36508, ext 666845, Mayor) evidence-only stances.
-- AUDIT-ONLY — NOT registered. Ledger stays 1035. Idempotent. CHAIRS model, 100% citation, honest blanks.
-- topic_id resolved LIVE by topic_key. NO judicial topics. Shelter-ban YES; combined services+restriction record.

BEGIN;
WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
  ('homelessness-response', 3,
   'As a seated councilmember Perez voted YES on Norwalk''s Aug 6 2024 emergency-shelter/supportive-housing moratorium (extended Sept 17 2024) — a restrictive limit on new shelter facilities — while the city she helps lead runs the H.O.P.E. Team combining outreach, social services and public-safety personnel (credited with housing 108 of 150 contacted individuals and cutting encampments). Her record pairs services/outreach with reasonable restrictions rather than housing-first-no-preconditions.',
   ARRAY['https://abc7.com/post/norwalk-council-votes-expand-moratorium-building-new-homeless-shelters/15320866/','https://www.gov.ca.gov/2024/10/03/governor-newsom-takes-action-against-norwalk-for-its-unlawful-shelter-ban/']),
  ('housing', 3,
   'Perez voted for the 2024 moratorium that blocked new supportive/transitional housing development, yet also participated in the groundbreaking of Norwalk''s 60-unit Mercy Housing affordable apartment project for veterans — a targeted-subsidy/selective-permit approach rather than broad rent caps or pure market deregulation.',
   ARRAY['https://www.loscerritosnews.net/2022/10/19/norwalk-breaks-ground-on-sixty-unit-affordable-housing-facility-for-veterans/','https://www.gov.ca.gov/2024/10/03/governor-newsom-takes-action-against-norwalk-for-its-unlawful-shelter-ban/']),
  ('economic-development', 3,
   'As President of the California Contract Cities Association with an economic-development orientation, Perez was on the council that approved the updated Economic Development Opportunities Plan (Oct 2023) identifying areas for future growth, and states every tax dollar should be ''spent wisely and with direct benefit to residents'' — targeted economic development tied to community benefit rather than maximal no-strings incentives.',
   ARRAY['https://www.ci.norwalk.ca.us/government/mayor_and_city_council/perez.php','https://norwalkchamber.com/elected-officials/']),
  ('growth-and-development', 3,
   'Perez began her public service as a Norwalk Planning Commissioner and the council under her tenure adopted the Economic Development Opportunities Plan that identified areas great for future growth — a plan-and-invest-ahead approach to managed growth rather than hard caps or unrestricted upzoning.',
   ARRAY['https://www.ci.norwalk.ca.us/government/mayor_and_city_council/perez.php']),
  ('taxes', 3,
   'Perez''s stated governing principle is that ''every tax dollar should be spent wisely and with direct benefit to residents,'' emphasizing fiscal stewardship of existing revenue and efficient spending rather than raising taxes for new services or drastically cutting government.',
   ARRAY['https://www.ci.norwalk.ca.us/government/mayor_and_city_council/perez.php'])
),
t AS (SELECT s.*, ct.id AS topic_id FROM s JOIN inform.compass_topics ct ON ct.topic_key=s.topic_key AND ct.is_live=true),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '3ed36508-9ae9-41af-aaba-e5e39bb87aa7', topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '3ed36508-9ae9-41af-aaba-e5e39bb87aa7', topic_id, reasoning, sources FROM t
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
COMMIT;
-- Post: 5 answers + 5 paired context for 3ed36508; ledger unchanged (1035).
