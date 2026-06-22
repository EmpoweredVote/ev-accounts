-- 1037_norwalk_ramirez_stances.sql
-- Phase 155 Wave 4 (NRWK-01): Rick Ramirez (pol e3b9af1b, ext -201327) evidence-only compass stances.
-- AUDIT-ONLY — raw SQL, NOT registered in schema_migrations. Ledger stays 1035. Idempotent.
-- CHAIRS model (value = the chair the evidence matches). 100% citation. No defaults/neutral. Honest blanks.
-- NO judicial topics (council-manager city). topic_id resolved LIVE by topic_key (never hardcoded).
-- Longest-serving (2003+); shelter-ban YES; 30-yr law-enforcement -> public-safety emphasis.

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
  ('homelessness-response', 4,
   'As the longest-serving councilmember (since 2003), Ramirez voted YES on the unanimous Aug 6 2024 emergency-shelter moratorium and its Sept 17 2024 extension — an urgency zoning ordinance halting new emergency shelters, SRO, supportive and transitional housing, justified under the Housing Crisis Act ''imminent threat to public health and safety'' provision. An enforcement/restriction-leaning posture (halting new shelter capacity via zoning), not expand-shelter-first. Not chair 5 because the city still runs engagement teams and a Social Services Department.',
   ARRAY['https://abc7.com/post/norwalk-council-votes-expand-moratorium-building-new-homeless-shelters/15320866/','https://www.gov.ca.gov/2024/10/03/governor-newsom-takes-action-against-norwalk-for-its-unlawful-shelter-ban/']),
  ('housing', 4,
   'Ramirez voted YES on the moratorium that used Norwalk''s zoning code to block new supportive, transitional, SRO and emergency-shelter housing, the city citing an outdated zoning code and the need to set performance standards first. The documented action restricts new affordable/supportive housing through zoning levers rather than funding or mandating it.',
   ARRAY['https://www.foxla.com/news/norwalk-residents-react-city-extending-ban-homeless-shelters','https://www.gov.ca.gov/2024/11/04/governor-newsom-sues-norwalk-for-unlawful-homeless-shelter-ban/']),
  ('public-safety-approach', 4,
   'Ramirez brings a 30-year law-enforcement career; his official City of Norwalk profile lists public safety and youth crime prevention as core priorities and he serves as council liaison to the Public Safety commission — aligning with prioritizing and strengthening police/public-safety resources.',
   ARRAY['https://www.norwalkca.gov/government/mayor_and_city_council/councilmember_ramirez.php'])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'e3b9af1b-3704-4bc5-a6ef-ab1f814bd29d', topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e3b9af1b-3704-4bc5-a6ef-ab1f814bd29d', topic_id, reasoning, sources FROM t
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
-- Post: 3 answers + 3 paired context rows for e3b9af1b; ledger unchanged (1035).
