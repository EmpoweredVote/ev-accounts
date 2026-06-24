-- Migration 1060: Clark County Commission stances - William McCurdy II (District D, Vice-Chair) (AUDIT-ONLY)
--
-- Phase 161 (CLARK-01). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1055. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- county-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 6cdeb125-85fa-4e9c-80d3-7528a890fd0b (external_id -3200304, minted by mig 1055).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 3, 'Cast the lone dissenting vote (6-1) against Clark County''s homeless camping ban on Nov 6, 2024, citing that shelter beds were 85% full and the county was prematurely getting ready to implement this before adequate shelter capacity existed (enforcement should not occur without available beds).', ARRAY['https://www.fox5vegas.com/2024/11/07/clark-county-passes-hotly-debated-homeless-camping-ordinance/','https://www.reviewjournal.com/news/politics-and-government/clark-county/clark-county-commission-approves-camping-ban-3206913/']::text[]),
    ('homelessness-response'::text, 2, 'In his Nov 6, 2024 dissent against the camping ban, argued the county had not yet created enough shelter/facility capacity and noted the homeless population includes the working poor, opposing criminalization in favor of building out shelter and services first.', ARRAY['https://www.fox5vegas.com/2024/11/07/clark-county-passes-hotly-debated-homeless-camping-ordinance/','https://lasvegasweekly.com/news/2025/jan/30/clark-countys-camping-ban-goes-into-effect/']::text[]),
    ('housing'::text, 2, 'Backed the May 7, 2024 unanimous approval of ~$66M to build/rehab ~1,273 low-income units (walking the walk) and partnered with Brinshore on a $53M county-backed Historic Westside mixed-use development (76 units at 80%-or-below AMI), groundbreaking March 20, 2025 (public funding/subsidized affordable housing).', ARRAY['https://lasvegassun.com/news/2024/may/08/clark-county-allocates-funds-to-help-build-1273-af/','https://hoodline.com/2025/03/commissioner-mccurdy-ii-and-brinshore-to-launch-53m-mixed-use-development-in-clark-county-s-historic-westside/']::text[]),
    ('economic-development'::text, 3, 'Led the county-backed $53M Historic Westside Mixed-Use Microbusiness Park (groundbreaking March 20, 2025) combining affordable workforce housing with 20,000+ sq ft retail/office and entrepreneurial space targeting local small businesses and residents at 80%-or-below AMI (targeted incentive tied to community benefit and local job creation).', ARRAY['https://hoodline.com/2025/03/commissioner-mccurdy-ii-and-brinshore-to-launch-53m-mixed-use-development-in-clark-county-s-historic-westside/','https://www.clarkcountynv.gov/news/news-detail-t28-r1159']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '6cdeb125-85fa-4e9c-80d3-7528a890fd0b'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '6cdeb125-85fa-4e9c-80d3-7528a890fd0b'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
