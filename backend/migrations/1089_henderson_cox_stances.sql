-- Migration 1089: City of Henderson stances - Carrie Cox (Ward III) (AUDIT-ONLY)
--
-- Phase 163 (CLARK-03). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1084. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- NOTE: homelessness deliberately left blank - the 2023 public-camping ban passed
-- unanimously while Cox was ABSENT, so no homelessness position is attributable to her.
-- politician_id = 64f92bb3-0d32-44bf-bbb6-2191060a93f7 (external_id -3206004, minted by mig 1084).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('taxes'::text, 2, 'Cox was the sole council member to vote against (4-1) the December 2023 Henderson residential water rate increase, asking to table it until cheaper options were explored; she has also championed higher pay for police officers - signaling spend-on-services / keep-rates-low rather than cut-and-limit.', ARRAY['https://www.reviewjournal.com/local/henderson/water-rates-to-go-up-in-henderson-2962496/','https://thenevadaindependent.com/article/meet-the-council-candidates-running-in-hendersons-most-watched-local-government-race']::text[]),
    ('public-safety-approach'::text, 5, 'Cox''s central record is investment-in-policing: she helped rehire retired officers, backed out-of-state recruiting, founded a first-responder Mental Health/Wellness Center, and says her work is "not done" on "taking care of our police officers" who "should never have had to fight to get paid fair wages."', ARRAY['https://checktheboxforcarriecox.com/','https://thenevadaindependent.com/article/meet-the-council-candidates-running-in-hendersons-most-watched-local-government-race']::text[]),
    ('housing'::text, 2, 'In the 2026 Nevada Independent council profile Cox framed cost-of-living relief as a municipal responsibility ("We have to focus on the municipal level") and backed building affordable housing as the city''s lever - favoring active local-government intervention on affordability.', ARRAY['https://thenevadaindependent.com/article/meet-the-council-candidates-running-in-hendersons-most-watched-local-government-race']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '64f92bb3-0d32-44bf-bbb6-2191060a93f7'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '64f92bb3-0d32-44bf-bbb6-2191060a93f7'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
