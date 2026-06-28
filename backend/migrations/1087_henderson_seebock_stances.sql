-- Migration 1087: City of Henderson stances - Jim Seebock (Ward I) (AUDIT-ONLY)
--
-- Phase 163 (CLARK-03). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1084. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- NOTE: public-safety-approach rests on his explicit campaign platform language,
-- NOT merely his prior LVMPD Deputy Chief role.
-- politician_id = 99d43f01-4b07-471f-bacf-e89d2a1c36b2 (external_id -3206002, minted by mig 1084).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 4, 'Seebock voted for and championed Henderson''s June 7, 2023 ordinance expanding the definition of camping and prohibiting public camping, saying "We need to take this first step because our community has been demanding it... our businesses need it" - but paired with shelter/service offers before warnings, so enforcement-leaning rather than a pure ban.', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-council-passes-ordinance-outlawing-public-camping-2790502/']::text[]),
    ('homelessness-response'::text, 3, 'As a candidate he backed working with faith-based/local orgs and centralizing services AND giving police "the tools to address homelessness," plus jail-based addiction help; the enacted ordinance requires police to offer a service and check shelter availability before any warning (June 2023) - an outreach-plus-enforcement mix.', ARRAY['https://www.reviewjournal.com/local/henderson/homelessness-a-hot-topic-for-henderson-council-candidates-2752583/','https://www.reviewjournal.com/local/henderson/henderson-council-passes-ordinance-outlawing-public-camping-2790502/']::text[]),
    ('public-safety-approach'::text, 5, 'On his campaign Priorities page Seebock frames "Public Safety Infrastructure" around giving police, fire and public health the "tools, resources and support they need" and aims to make Henderson the safest city - a funding/support-first traditional policing posture stated as explicit platform (not merely his LVMPD background).', ARRAY['https://votejimseebock.com/priorities/']::text[]),
    ('growth-and-development'::text, 5, 'At the May 3, 2023 Eldorado Valley annexation (290+ acres, industrial/commercial zoning, Station Casinos resort approval) Seebock said "It''s a significant investment in Henderson... I am very much looking forward to its continued development"; his platform centers continuing Water Street/Ward 1 redevelopment.', ARRAY['https://www.reviewjournal.com/local/henderson/a-significant-investment-henderson-annexes-eldorado-valley-land-2771502/','https://votejimseebock.com/jim-seebock-announces-run-for-henderson-city-council-seat-ward-one/']::text[]),
    ('economic-development'::text, 4, 'His Priorities page calls for "smart growth of business and development," "insightful economic development and recruiting the right types of businesses," and "strategic zoning"; he voted to annex land and approve a casino resort / commercial subdivision (May 2023).', ARRAY['https://votejimseebock.com/priorities/','https://www.reviewjournal.com/local/henderson/a-significant-investment-henderson-annexes-eldorado-valley-land-2771502/']::text[]),
    ('city-sanitation'::text, 4, 'The camping ordinance he championed amended city code to bar outdoor sleeping/tents/cooking in public spaces with an enforcement protocol, reflecting a strict public-order/code-enforcement orientation toward use of public space (June 2023).', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-council-passes-ordinance-outlawing-public-camping-2790502/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '99d43f01-4b07-471f-bacf-e89d2a1c36b2'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '99d43f01-4b07-471f-bacf-e89d2a1c36b2'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
