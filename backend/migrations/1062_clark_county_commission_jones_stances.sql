-- Migration 1062: Clark County Commission stances - Justin Jones (District F) (AUDIT-ONLY)
--
-- Phase 161 (CLARK-01). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1055. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- county-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 8b40944d-30a6-42f4-b4d0-bfa9427e36a6 (external_id -3200306, minted by mig 1055).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 3, 'Nov 5, 2024: voted in favor of the camping ordinance, which permits citation/arrest only after a warning and only when an available shelter bed has been offered, with no enforcement when no beds are available: none of us really want to be in this position, but it''s also the reality that we''re all facing on the ground.', ARRAY['https://www.fox5vegas.com/2024/11/07/clark-county-passes-hotly-debated-homeless-camping-ordinance/']::text[]),
    ('homelessness-response'::text, 2, 'Defended the county''s 1/8-cent sales tax increase (Sept 2019) as the right trade off to fund homelessness, affordable housing and truancy prevention, and backed shelter/services investment paired with the 2024 ordinance requiring a shelter bed before enforcement (expand shelter/services as primary response).', ARRAY['https://www.reviewjournal.com/news/politics-and-government/clark-county/conservative-policy-wonk-challenges-incumbent-jones-in-district-f-2653147/','https://www.fox5vegas.com/2024/11/07/clark-county-passes-hotly-debated-homeless-camping-ordinance/']::text[]),
    ('housing'::text, 3, 'Supported the Sept 2022 vote for a $120M investment to build/renovate 3,000+ units and touted a $500M affordable housing program plus a District F pilot offering discounted home purchases and expedited permitting; called affordable housing his top second-term priority (targeted subsidies/first-buyer programs plus easier permits).', ARRAY['https://www.reviewjournal.com/news/politics-and-government/clark-county/conservative-policy-wonk-challenges-incumbent-jones-in-district-f-2653147/','https://thenevadaindependent.com/article/republicans-look-to-unseat-three-incumbents-after-14-year-democratic-hold-on-clark-county-commission']::text[]),
    ('local-environment'::text, 1, 'April 17, 2019: part of the 6-0 vote to deny Gypsum Resources'' waiver, blocking the dense Blue Diamond Hill development overlooking Red Rock Canyon; ran as The Red Rock Guy and previously litigated against the project as Save Red Rock''s attorney (requiring environmental protection/review before approving development).', ARRAY['https://thenevadaindependent.com/article/dealmaking-lobbying-and-delays-inside-the-political-fight-over-homes-at-red-rock','https://thenevadaindependent.com/article/republicans-look-to-unseat-three-incumbents-after-14-year-democratic-hold-on-clark-county-commission']::text[]),
    ('local-immigration'::text, 1, 'July 16, 2019: publicly criticized Metro''s agreement deputizing jail officers as ICE agents at Clark County Detention Center (ICE agents are holding people in cages at the direction of a president who has weaponized an organization), demanded answers and tied future jail-staffing support to Metro clarifying its ICE role (opposition to county cooperation with ICE).', ARRAY['https://www.reviewjournal.com/news/politics-and-government/clark-county/clark-county-official-presses-metro-for-answers-about-ice-cooperation-1744149/']::text[]),
    ('transportation-priorities'::text, 1, 'As an RTC of Southern Nevada board member and self-described avid cyclist, advocates transforming infrastructure to be more inclusive, and therefore safer, for pedestrians and cyclists (Oct 6, 2022) (prioritize pedestrian/cycling infrastructure).', ARRAY['https://www.reviewjournal.com/news/politics-and-government/clark-county/conservative-policy-wonk-challenges-incumbent-jones-in-district-f-2653147/']::text[]),
    ('taxes'::text, 2, 'Advocated for and defended Clark County''s 1/8-cent sales tax increase (approved Sept 3, 2019, ~$54M/yr), calling it critical and the right trade off to fund homelessness, affordable housing, early childhood education and truancy prevention (moderately raising taxes to fund services).', ARRAY['https://www.reviewjournal.com/news/politics-and-government/clark-county/conservative-policy-wonk-challenges-incumbent-jones-in-district-f-2653147/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '8b40944d-30a6-42f4-b4d0-bfa9427e36a6'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '8b40944d-30a6-42f4-b4d0-bfa9427e36a6'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
