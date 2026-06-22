-- 1038_norwalk_rios_stances.sql
-- Phase 155 Wave 4 (NRWK-01): Margarita L. Rios (pol bd64253b, ext -201328, Vice Mayor) evidence-only stances.
-- AUDIT-ONLY — NOT registered. Ledger stays 1035. Idempotent. CHAIRS model, 100% citation, honest blanks.
-- topic_id resolved LIVE by topic_key. NO judicial topics. 2024 rotational Mayor; shelter-ban YES; LE/SRO background.

BEGIN;
WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
  ('homelessness-response', 4,
   'As Norwalk''s 2024 Mayor, Rios led and voted YES on the Aug 6 2024 unanimous urgency moratorium banning new emergency shelters, supportive and transitional housing (extended Sept 17 2024), defending it on public-safety grounds and framing strategy around her ''Safe and Clean'' theme — enforcement/restriction-first rather than expand-shelter-first.',
   ARRAY['https://abc7.com/post/norwalk-council-votes-expand-moratorium-building-new-homeless-shelters/15320866/','https://www.calonews.com/communities/norwalk/norwalk-votes-to-expand-moratorium-on-building-new-homeless-shelters-and-housing/article_3631142c-75f6-11ef-aa93-0fd3f267eb8d.html']),
  ('homelessness', 4,
   'As 2024 Mayor, Rios supported the unanimous moratorium prohibiting new homeless shelters and transitional housing, defending it on public-safety grounds — consistent with prohibiting expansion of encampment-/shelter-serving facilities rather than protecting a right to shelter in place.',
   ARRAY['https://abc7.com/post/norwalk-council-votes-expand-moratorium-building-new-homeless-shelters/15320866/','https://heysocal.com/2024/11/04/state-sues-norwalk-over-ban-on-new-homeless-shelters-housing/']),
  ('housing', 4,
   'Her YES vote on the moratorium blocked new supportive/transitional/SRO housing development; state HCD found it violated the Housing Crisis Act and Newsom sued. Her posture restricted new affordable-housing approvals via zoning rather than funding or mandating them.',
   ARRAY['https://heysocal.com/2024/10/03/state-revokes-norwalks-eligibility-for-housing-homelessness-funds/','https://www.calonews.com/communities/norwalk/norwalk-votes-to-expand-moratorium-on-building-new-homeless-shelters-and-housing/article_3631142c-75f6-11ef-aa93-0fd3f267eb8d.html']),
  ('public-safety-approach', 4,
   'Rios spent ~20 years in law enforcement (criminal investigations, school resource officer) and lists Public Safety as her top priority. She emphasizes close partnership with the LA County Sheriff (''When we work together, we make the biggest impact''), credits low crime to that approach, and founded the Business Watch program — favoring strong, well-resourced policing.',
   ARRAY['https://norwalk.org/government/mayor_and_city_council/rios.php','http://www.thenorwalkpatriot.com/news/2019/4/3/margarita-rios-named-mayor-for-2019-20']),
  ('city-sanitation', 3,
   'Rios made ''Safe and Clean'' her 2024 mayoral theme and lists ''safe and clean public spaces'' among her top priorities, serving as a Neighborhood Watch Block Captain — a maintain-and-keep-orderly emphasis on public-space cleanliness.',
   ARRAY['https://norwalk.org/government/mayor_and_city_council/rios.php']),
  ('economic-development', 3,
   'Rios lists Community Development as a top priority and founded a Business Watch program supporting local businesses, with targeted workforce/career-technical articulation work — a community-benefit-oriented development approach rather than blanket incentives.',
   ARRAY['https://norwalk.org/government/mayor_and_city_council/rios.php']),
  ('climate-change', 3,
   'As 2024 Mayor, Rios led Norwalk to add Strategic Goal #4: ''Support sustainability and climate resilience throughout the community,'' indicating support for investing in sustainability/resilience through city planning rather than emergency mandates or rejection.',
   ARRAY['https://norwalk.org/government/mayor_and_city_council/rios.php'])
),
t AS (SELECT s.*, ct.id AS topic_id FROM s JOIN inform.compass_topics ct ON ct.topic_key=s.topic_key AND ct.is_live=true),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'bd64253b-0bd1-4b9f-85b1-76180c760d07', topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'bd64253b-0bd1-4b9f-85b1-76180c760d07', topic_id, reasoning, sources FROM t
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
COMMIT;
-- Post: 7 answers + 7 paired context for bd64253b; ledger unchanged (1035).
