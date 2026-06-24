-- Migration 1059: Clark County Commission stances - April Becker (District C) (AUDIT-ONLY)
--
-- Phase 161 (CLARK-01). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1055. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- county-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = ef0d7745-8530-4588-aab5-80f6ba175725 (external_id -3200303, minted by mig 1055).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('taxes'::text, 4, 'Cast the sole dissenting vote (6-1) against renewing Clark County''s Fuel Revenue Index tax (Nov 2025), arguing a fuel tax is a regressive tax that hurts the poorest people in our community and should have been done by a vote of the people; also the sole no vote against raising UMC''s CEO pay and against renewing the Dominion contract on fiduciary/taxpayer grounds.', ARRAY['https://thenevadaindependent.com/article/partisan-past-bipartisan-future-april-beckers-first-year-as-clark-county-commissioner']::text[]),
    ('public-safety-approach'::text, 4, 'District C candidate forum (Review-Journal): named safety a top county challenge and proposed providing necessary resources for law enforcement as a core solution (increase/strengthen police resourcing).', ARRAY['https://www.reviewjournal.com/news/politics-and-government/clark-county/crime-homelessness-countys-biggest-challenges-district-c-candidates-say-3054394/']::text[]),
    ('growth-and-development'::text, 4, 'District C candidate forum (Review-Journal): repeatedly cited streamlining development approval processes and removing bureaucratic obstacles as a county priority (streamline-permitting / pro-development).', ARRAY['https://www.reviewjournal.com/news/politics-and-government/clark-county/crime-homelessness-countys-biggest-challenges-district-c-candidates-say-3054394/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'ef0d7745-8530-4588-aab5-80f6ba175725'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'ef0d7745-8530-4588-aab5-80f6ba175725'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
