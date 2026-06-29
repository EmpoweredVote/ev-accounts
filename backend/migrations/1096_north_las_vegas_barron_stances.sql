-- Migration 1096: City of North Las Vegas stances - Isaac E. Barron (Council Member, Ward 1) (AUDIT-ONLY)
--
-- Phase 164 (CLARK-04). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1093. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 59c8b352-1ffb-44fc-89c2-68627ade8a8c (external_id -3207002, minted by mig 1093).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('local-immigration'::text, 3, 'In March 2017 at a Latin Chamber of Commerce event, when asked whether he would make North Las Vegas a sanctuary city, Barron said "We''re going to be taking some steps to protect all our residents. We have the backing of our police chief." He committed to protecting vulnerable/immigrant residents and signaled the city would not direct police toward proactive immigration enforcement, but did not specify a detainer or information-sharing policy - a protective posture best matching follow-federal-law-but-no-city-resources-for-proactive-enforcement.', ARRAY['https://www.reviewjournal.com/local/north-las-vegas/isaac-barron-has-big-lead-to-winning-north-las-vegas-city-council-seat/']::text[]),
    ('economic-development'::text, 4, 'Barron led North Las Vegas''s aggressive effort to recruit major employers to the APEX Industrial Park, personally pursuing Faraday Future after Tesla passed on the city in 2014; the project came with a $335 million state incentive package approved in December 2015, and Barron called it "a game-changer, not just for North Las Vegas, but for the entire region." He has repeatedly stated his goal of attracting manufacturing, warehouse and tech jobs to APEX - actively competing for major employers with significant tax abatements and infrastructure.', ARRAY['https://thenevadaindependent.com/article/a-timeline-of-faraday-future-and-nevada-from-great-expectations-to-a-factory-freeze','https://www.reviewjournal.com/local/north-las-vegas/barron-rivera-focus-on-jobs-revitalization-in-north-las-vegas-ward-1/']::text[]),
    ('public-safety-approach'::text, 4, 'In his Ward 1 campaign, Barron stated "We need to hire more police officers, firefighters and people to handle city services" while remaining "fiscally responsible and sustainable" (Las Vegas Review-Journal, Ward 1 jobs-and-revitalization coverage) - an explicit call to increase police staffing.', ARRAY['https://www.reviewjournal.com/local/north-las-vegas/barron-rivera-focus-on-jobs-revitalization-in-north-las-vegas-ward-1/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '59c8b352-1ffb-44fc-89c2-68627ade8a8c'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '59c8b352-1ffb-44fc-89c2-68627ade8a8c'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
