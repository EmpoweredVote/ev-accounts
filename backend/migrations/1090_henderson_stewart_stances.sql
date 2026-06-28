-- Migration 1090: City of Henderson stances - Dan H. Stewart (Ward IV) (AUDIT-ONLY)
--
-- Phase 163 (CLARK-03). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1084. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- NOTE: residential-zoning deliberately left blank - the Three Kids Mine vote maps
-- to growth-and-development (a new master-planned community), not to a single-family-
-- vs-density position. homelessness/homelessness-response rest on the unanimous
-- June 2023 camping-ban vote in which Stewart participated (a recorded body vote).
-- politician_id = 50682ef1-360a-4597-9e1a-eaf43c50673d (external_id -3206005, minted by mig 1084).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('economic-development'::text, 5, 'Stewart''s official campaign priorities page lists economic development first, pledging to "attract and recruit new businesses to relocate to our City that provide an excellent tax base and offer high paying jobs" - an aggressive pro-recruitment/incentive posture.', ARRAY['https://danstewartnv.com/priorities/']::text[]),
    ('public-safety-approach'::text, 5, 'His priorities page frames "Community Safety" around "cutting edge technology" plus a stated commitment to "reinvesting in police and fire departments" - a traditional funding-first policing posture.', ARRAY['https://danstewartnv.com/priorities/']::text[]),
    ('growth-and-development'::text, 5, 'On Nov. 21, 2023 Stewart joined a 4-0 council vote approving the development agreement, zoning change and tentative map for the Three Kids Mine 3,000-home community, and publicly defended his pro-development vote against conflict-of-interest questions.', ARRAY['https://www.fox5vegas.com/2023/11/22/henderson-votes-move-redevelopment-three-kids-mine-site-forward/','https://www.reviewjournal.com/local/henderson/3000-homes-to-be-built-on-top-of-old-mine-site-in-henderson-2944452/']::text[]),
    ('local-environment'::text, 2, 'On Mar. 9, 2023 Stewart supported the (unanimous) ordinance cutting golf-course water allocations from 6.3 to 4 acre-feet/year, saying "We''re going to have to continue to focus on conservation... so we can all maintain our quality of lifestyle" - prioritizing desert water conservation.', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-city-council-cuts-water-use-for-golf-courses-lowers-water-rates-2741619/']::text[]),
    ('taxes'::text, 2, 'In Dec. 2023 Stewart voted yes (4-1, Cox dissenting) on the Henderson residential water-rate increase to fund utility infrastructure/operations and argued the council "should not delay the vote" - willing to raise rates/fees to fund services.', ARRAY['https://www.reviewjournal.com/local/henderson/water-rates-to-go-up-in-henderson-2962496/','https://www.fox5vegas.com/2023/12/02/city-henderson-vote-water-rate-hike/']::text[]),
    ('homelessness'::text, 4, 'On June 7, 2023 the council (Stewart present, Cox absent) unanimously passed an ordinance prohibiting public camping/outdoor sleeping with criminal enforcement for those who refuse services - Stewart participated in the camping-ban vote.', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-council-passes-ordinance-outlawing-public-camping-2790502/']::text[]),
    ('homelessness-response'::text, 3, 'The same June 7, 2023 ordinance Stewart''s council passed pairs enforcement with a service-first step: police must first offer services and check shelter-bed availability before any warning or arrest.', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-council-passes-ordinance-outlawing-public-camping-2790502/','https://www.reviewjournal.com/local/henderson/henderson-may-outlaw-camping-in-public-places-affecting-homeless-2784693/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '50682ef1-360a-4597-9e1a-eaf43c50673d'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '50682ef1-360a-4597-9e1a-eaf43c50673d'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
