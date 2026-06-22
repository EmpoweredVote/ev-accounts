-- 1041_norwalk_valencia_stances.sql
-- Phase 155 Wave 4 (NRWK-01): Ana Valencia (pol ba647863, ext -201329) evidence-only stances.
-- AUDIT-ONLY — NOT registered. Ledger stays 1035. Idempotent. CHAIRS model, 100% citation, honest blanks.
-- topic_id resolved LIVE by topic_key. NO judicial topics. Newest member (2020+) — thinnest record, honest blanks.

BEGIN;
WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
  ('homelessness-response', 4,
   'Valencia voted YES with the unanimous council to adopt the Aug 6 2024 urgency ordinance banning new emergency shelters, supportive, transitional, and SRO housing, and again YES to EXTEND it Sept 17 2024 — blocking new shelter/supportive-housing development rather than expanding it (Newsom sued; city settled 2025, overturning the ban + $250K into a housing trust). Places her at the restrictive/enforcement-leaning end of the city''s homelessness strategy.',
   ARRAY['https://abc7.com/post/norwalk-council-votes-expand-moratorium-building-new-homeless-shelters/15320866/','https://www.gov.ca.gov/2024/10/03/governor-newsom-takes-action-against-norwalk-for-its-unlawful-shelter-ban/']),
  ('housing', 4,
   'Her unanimous YES votes on the Aug 6 2024 moratorium and Sept 17 2024 extension specifically barred new supportive, transitional, and SRO housing; the council''s rationale was that such uses ''just didn''t fit in our economic development plan.'' A restrictive stance toward subsidized/affordable-housing siting; the city settled with the state in 2025 to overturn the ordinance.',
   ARRAY['https://calmatters.org/housing/2024/10/norwalk-builders-remedy/','https://www.cbsnews.com/losangeles/news/norwalk-overturn-new-homeless-shelter-ban-settlement-state-california/']),
  ('public-safety-approach', 4,
   'In her 2024 Ballotpedia Candidate Connection survey, Valencia named Public Safety her top priority, pledging to ''enhance community policing and increase support for emergency services'' — favoring increased police and emergency-services support rather than redirecting funds.',
   ARRAY['https://ballotpedia.org/Ana_Valencia_(Norwalk_City_Council_At-large,_California,_candidate_2024)']),
  ('economic-development', 4,
   'Economic Development is her stated second priority; she touts that during her 2023 mayoralty Norwalk saw ''the highest economic boost in 30 years,'' and the council''s shelter-moratorium rationale prioritized its economic-development plan over supportive-housing uses — an actively pro-growth, business-attraction posture.',
   ARRAY['https://ballotpedia.org/Ana_Valencia_(Norwalk_City_Council_At-large,_California,_candidate_2024)','https://calmatters.org/housing/2024/10/norwalk-builders-remedy/'])
),
t AS (SELECT s.*, ct.id AS topic_id FROM s JOIN inform.compass_topics ct ON ct.topic_key=s.topic_key AND ct.is_live=true),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'ba647863-25fb-4ccf-9cb0-5a1c912d1b27', topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ba647863-25fb-4ccf-9cb0-5a1c912d1b27', topic_id, reasoning, sources FROM t
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
COMMIT;
-- Post: 4 answers + 4 paired context for ba647863 (newest member, honest blanks); ledger unchanged (1035).
