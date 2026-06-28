-- Migration 1088: City of Henderson stances - Monica Larson (Ward II) (AUDIT-ONLY)
--
-- Phase 163 (CLARK-03). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1084. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- Thin record: elected Nov 2024 / sworn Jan 2025; only campaign-era positions
-- are citable - the remaining topics are honest blanks (no fabrication).
-- politician_id = e0d8ef1b-26b6-4e3d-add7-0ff35bc9a486 (external_id -3206003, minted by mig 1084).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('public-safety-approach'::text, 5, 'Larson made police/fire funding her stated "number one priority," campaigning to retain and recruit more officers and arguing Henderson is critically understaffed (~0.6 vs. a recommended 2.34 patrol officers per 1,000 residents); endorsed by the Henderson Police Officers Association (2024 campaign).', ARRAY['https://www.8newsnow.com/news/politics/henderson-city-council-candidate-dr-monica-larson-discusses-government-transparency-public-safety-and-housing/','https://nevadacurrent.com/2024/10/08/shaw-larson-battle-for-henderson-council-seat-in-runoff-election/']::text[]),
    ('residential-zoning'::text, 1, 'Larson campaigned to push for more single-family housing and noted Seven Hills/Inspirada neighbors oppose a proliferation of multi-family developments, framing the city as lacking the public-safety infrastructure to support added density (2024) - a preserve-single-family/local-control posture.', ARRAY['https://nevadacurrent.com/2024/10/08/shaw-larson-battle-for-henderson-council-seat-in-runoff-election/']::text[]),
    ('housing'::text, 2, 'Larson called affordable housing a critical issue and proposed incentivizing developers to build more single-family homes, townhomes, and tiny-home communities - favoring city-driven incentives to expand supply (2024).', ARRAY['https://www.8newsnow.com/news/politics/henderson-city-council-candidate-dr-monica-larson-discusses-government-transparency-public-safety-and-housing/','https://nevadacurrent.com/2024/10/08/shaw-larson-battle-for-henderson-council-seat-in-runoff-election/']::text[]),
    ('economic-development'::text, 4, 'Her platform pledges to support small businesses (cited as ~80% of Henderson''s economy) and to actively bring in new, innovative, high-wage jobs - signaling pro-active business attraction (campaign priorities page).', ARRAY['https://votedrmonicalarson.com/priorities/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'e0d8ef1b-26b6-4e3d-add7-0ff35bc9a486'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'e0d8ef1b-26b6-4e3d-add7-0ff35bc9a486'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
