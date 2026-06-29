-- Migration 1097: City of North Las Vegas stances - Ruth Garcia-Anderson (Council Member, Ward 2) (AUDIT-ONLY)
--
-- Phase 164 (CLARK-04). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1093. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- Thin record (appointed Dec 2022 / elected Nov 2024) - honest blanks expected.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = cefd942b-7c4f-4d7b-9726-95d8c5a42c9f (external_id -3207003, minted by mig 1093).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('taxes'::text, 3, 'In a Sept. 18, 2024 Nevada Current interview about two expiring North Las Vegas property taxes (street-improvement and public-safety levies), Garcia-Anderson said: "I''m 100% in support of maintaining these taxes. The tax is not increasing. The city''s not going to be increasing the tax, we''re just maintaining it to keep our city safe." She backs continuing the existing tax structure without raising or cutting rates.', ARRAY['https://nevadacurrent.com/2024/09/18/barbershop-chain-owner-challenges-incumbent-for-north-las-vegas-city-council/']::text[]),
    ('public-safety-approach'::text, 4, 'In the same Sept. 18, 2024 Nevada Current interview she backed maintaining the dedicated public-safety property tax specifically to fund more officers: "I think it''s important to ensure that we have enough trained officers patrolling our communities especially at night, so that their response time is improved." Her stated priority is increasing trained-officer staffing/patrol coverage, not redirecting funds or adding co-responder teams.', ARRAY['https://nevadacurrent.com/2024/09/18/barbershop-chain-owner-challenges-incumbent-for-north-las-vegas-city-council/']::text[]),
    ('housing'::text, 3, 'Her official Ward 2 newsletter states "Affordable housing is one of the priorities this Council is addressing"; she celebrated the Lake Mead West Apartments (156-unit affordable complex built via public-private partnership with HopeLink wrap-around services) and gave remarks at the PuraVida senior supportive-housing groundbreaking (March 2025). In her RJ candidate interview she cited working on "a 156-unit housing complex that includes wrap-around resources" and ensuring federal affordable-housing dollars are used appropriately - targeted public support for affordable projects, not city-built public housing or rent caps.', ARRAY['https://www.reviewjournal.com/news/politics-and-government/nlv-councilwoman-garcia-anderson-and-business-owner-activist-running-for-ward-2-seat-3175659/','https://nevadabusiness.com/2025/04/senior-supportive-housing-community-coming-to-north-las-vegas/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'cefd942b-7c4f-4d7b-9726-95d8c5a42c9f'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'cefd942b-7c4f-4d7b-9726-95d8c5a42c9f'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
