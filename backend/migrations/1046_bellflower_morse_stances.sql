-- 1046_bellflower_morse_stances.sql
-- Phase 156 Wave 4 (BLFL-01): Wendi Morse (pol d18dcb81, ext -201150, D1, Councilmember) evidence-only stances.
-- AUDIT-ONLY — raw SQL, NOT registered in schema_migrations. Ledger stays 1043. Idempotent.
-- CHAIRS model (value = the chair the evidence matches). 100% citation. No defaults/neutral. Honest blanks.
-- NO judicial topics. topic_id resolved LIVE by topic_key (never hardcoded).
-- Evidence: Morse's own answers in the Downey Latino News "Ask the candidates — Bellflower City Council District 1"
-- questionnaire (Oct 2024). Despite being the newest member (appointed Oct 2023, elected Nov 2024), this
-- questionnaire is her richest citable source. rent-regulation deliberately OMITTED — she answered "Undecided"
-- on caps beyond state limits (context only, NOT a placement).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
  ('public-safety-approach', 4,
   $$In her Oct 2024 District 1 candidate questionnaire, Morse supported increasing the police/public-safety budget: "An increased budget can support hiring of additional deputies improving response times and having adequate patrol coverage." Increasing sheriff-deputy staffing and patrol coverage matches chair 4 (increase police staffing/resources), not maintaining/redirecting (chairs 1-3).$$,
   ARRAY['https://downeylatinonews.com/en/2024/10/ask-the-candidates-bellflower-city-council-district-1/']::text[]),
  ('housing', 3,
   $$Morse said she would "focus on building more affordable housing options" by "working with developers and offering incentives" and would "expand rental assistance programs." Government facilitation via incentives + assistance (not direct public housing or rent caps at chairs 1-2, not pure deregulation at chairs 4-5) matches chair 3 (targeted help: subsidies/incentives for affordable projects and assistance).$$,
   ARRAY['https://downeylatinonews.com/en/2024/10/ask-the-candidates-bellflower-city-council-district-1/']::text[]),
  ('economic-development', 2,
   $$Morse framed economic growth around "new businesses" and "local entrepreneurs," emphasizing a vibrant local business community rather than large corporate subsidies/abatements. Matches chair 2 (small-business support and local entrepreneur programs), not aggressive incentive competition (chairs 4-5).$$,
   ARRAY['https://downeylatinonews.com/en/2024/10/ask-the-candidates-bellflower-city-council-district-1/']::text[]),
  ('transportation-priorities', 2,
   $$On transportation, Morse proposed "dedicated bike lanes," "traffic calming measures" such as roundabouts, and improved crosswalks "to encourage walking and cycling." A multimodal emphasis (bike/pedestrian infrastructure alongside roads) matches chair 2 (invest in roads and multimodal; require bike lanes and sidewalks), short of a car-deprioritizing chair 1 (she does not propose reducing parking or transit-first reallocation).$$,
   ARRAY['https://downeylatinonews.com/en/2024/10/ask-the-candidates-bellflower-city-council-district-1/']::text[]),
  ('homelessness-response', 3,
   $$Morse said she wants to "provide real solutions for those experiencing homelessness, offering support and resources so they can rebuild their lives while making sure our neighborhoods remain welcoming and secure." Pairing support/resources with maintaining neighborhood order matches chair 3 (invest in outreach/shelter/services while enforcing reasonable public-space rules), not housing-first-no-enforcement (chair 1) nor enforcement-first/minimize-services (chairs 4-5).$$,
   ARRAY['https://downeylatinonews.com/en/2024/10/ask-the-candidates-bellflower-city-council-district-1/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'd18dcb81-ad41-468f-9b12-a70ed21fd3a7', topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd18dcb81-ad41-468f-9b12-a70ed21fd3a7', topic_id, reasoning, sources FROM t
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
-- Post: 5 answers + 5 paired context rows for d18dcb81; ledger unchanged (1043).
-- Honest blanks: rent-regulation ("Undecided" — context only), and all topics with no individual evidence.
