-- Migration 1080: City of Las Vegas stances - Olivia Diaz (Council Member, Ward 3) (AUDIT-ONLY)
--
-- Phase 162 (CLARK-02). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1075. Evidence-only compass stances (CHAIRS
-- model). 100% cited; honest blanks where no city-level evidence. No defaults.
-- Council-era (2019-2026) evidence only; Assembly-era record not imported.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 168705cc-2899-4432-b062-cb8583ac99e6 (external_id -3205004, minted by mig 1075).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 3, 'Cast one of only two votes AGAINST the 2019 ordinance criminalizing sleeping/camping downtown (council passed 5-2, June 2019) and was the SOLE vote against the Jan 2020 sidewalk-cleaning penalty ordinance - but in Nov 2024 voted FOR the citywide camping-ban expansion. Her arc lands on the middle "enforce only if beds available / divert" chair rather than the punitive end, paired with shelter/housing investment.', ARRAY['https://thenevadaindependent.com/article/las-vegas-city-council-oks-controversial-homeless-ordinance','https://thenevadaindependent.com/article/vegas-council-expected-to-vote-on-ordinance-with-penalties-for-those-who-dont-move-during-sidewalk-cleaning']::text[]),
    ('homelessness-response'::text, 2, 'Frames ending homelessness via housing supply: "we want to see ending homelessness in our community... the way to do that is to ensure that we offer more affordable housing opportunities" (April 2026, advancing a 50-unit senior tiny-home development). Primary documented lever is expanding shelter/housing capacity rather than enforcement.', ARRAY['https://www.fox5vegas.com/2026/04/01/las-vegas-city-council-approves-tiny-homes-development-proposal/']::text[]),
    ('housing'::text, 2, 'Leads the $440M Desert Pines Golf Course redevelopment - the largest affordable-housing project in NV history - explicitly using public financing ("financial engineering, grants, and soft dollars") to make ~2/3 of units accessible to first-time and low-income buyers (council approved July 2025; earlier plan March 2022). Public-fund-driven affordable supply.', ARRAY['https://www.reviewjournal.com/news/politics-and-government/las-vegas/city-oks-plans-to-develop-site-of-desert-pines-golf-course-2546511/amp/','https://www.fox5vegas.com/2026/04/01/las-vegas-city-council-approves-tiny-homes-development-proposal/']::text[]),
    ('growth-and-development'::text, 3, 'Champions planned, mixed-use redevelopment with public investment ahead of growth - Desert Pines combines affordable + market-rate housing, retail, educational facilities and green space as a deliberate plan to address Ward 3 shortages.', ARRAY['https://www.reviewjournal.com/news/politics-and-government/las-vegas/city-oks-plans-to-develop-site-of-desert-pines-golf-course-2546511/amp/']::text[]),
    ('local-environment'::text, 3, 'On the April 2026 tiny-homes project supported approval over a planning-commission denial recommendation but added beautification conditions (more trees, wrought-iron fencing) - consistent standards balanced with development flexibility.', ARRAY['https://www.fox5vegas.com/2026/04/01/las-vegas-city-council-approves-tiny-homes-development-proposal/']::text[]),
    ('economic-development'::text, 3, 'Diaz''s signature Desert Pines plan ties development to community benefit - workforce training spaces, small-business opportunities, educational facilities and green space alongside housing. Targeted, community-benefit-conditioned development.', ARRAY['https://oliviadiazlv.com/about/','https://www.reviewjournal.com/news/politics-and-government/las-vegas/city-oks-plans-to-develop-site-of-desert-pines-golf-course-2546511/amp/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '168705cc-2899-4432-b062-cb8583ac99e6'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '168705cc-2899-4432-b062-cb8583ac99e6'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
