-- Migration 1095: City of North Las Vegas stances - Pamela Goynes-Brown (Mayor) (AUDIT-ONLY)
--
-- Phase 164 (CLARK-04). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1093. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = bc59a9f6-e308-4c1c-af96-0aebb8ac72c6 (external_id -3207001, minted by mig 1093).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('housing'::text, 3, 'In her 2026 vision and March 2026 Q&A, Goynes-Brown emphasized bringing nearly 1,200 new affordable housing units to North Las Vegas "through partnerships with the state and private developers" (single/multi-family/senior projects), framing it as a people-first priority. This is targeted public help for affordable projects via subsidies/partnerships rather than building public housing directly or imposing rent caps.', ARRAY['https://thenevadaglobe.com/702times/building-a-complete-city-mayor-goynes-brown-unveils-2026-vision-for-north-las-vegas/','https://lasvegasweekly.com/ae/2026/mar/05/north-las-vegas-mayor-pamela-goynes-qa/']::text[]),
    ('public-safety-approach'::text, 4, 'Goynes-Brown''s 2025/2026 State of the City and strategic plan prioritize "the recruitment of new police and fire personnel to keep pace with the city''s population boom" and modernization of public safety facilities. She touted the 2025 police class that trained 81 new officers and said she was relieved the community sees the benefit in maintaining public safety funding after voter-approved June 2024 measures funded new police and fire stations - increasing police/fire staffing and facilities to keep pace with growth.', ARRAY['https://www.reviewjournal.com/local/north-las-vegas/not-waiting-for-opportunity-nlv-mayor-goynes-brown-gives-her-final-state-of-the-city-address-3731519/','https://www.ktnv.com/news/north-las-vegas-mayor-pamela-goynes-brown-touts-successes-in-annual-state-of-the-city-speech']::text[]),
    ('economic-development'::text, 4, 'Goynes-Brown has made aggressively recruiting major employers a defining priority: she touts the ~30 million-sq-ft Apex Industrial Park (estimated 70,000+ jobs), the $380M Hylo Park development, the $200M downtown Gateway Project, a Nevada State University campus, and "more than $1 billion in private investments each of the past eight years." She praised the federal Apex Area Technical Correction Act (July 2025) for fast-tracking infrastructure to create quality jobs - active competition for major employers backed by infrastructure and streamlined permitting.', ARRAY['https://www.reviewjournal.com/local/north-las-vegas/not-waiting-for-opportunity-nlv-mayor-goynes-brown-gives-her-final-state-of-the-city-address-3731519/','https://www.cortezmasto.senate.gov/news/press-releases/signed-cortez-mastos-legislation-to-create-jobs-at-apex-industrial-park-in-north-las-vegas/']::text[]),
    ('growth-and-development'::text, 3, 'Goynes-Brown frames North Las Vegas growth around becoming a "complete city" via "disciplined infrastructure investment," launching a $638M growth plan and 2025-2030 Strategic Plan that pairs new development with infrastructure built alongside it - new fire and police stations, a medical hub, parks, and the Nevada State University campus - planning and investing in infrastructure to support growth rather than removing barriers.', ARRAY['https://1027vgs.com/2025/04/10/north-las-vegas-kicks-off-638-million-growth-plan-with-parks-homes-medical-hub/','https://thenevadaglobe.com/702times/building-a-complete-city-mayor-goynes-brown-unveils-2026-vision-for-north-las-vegas/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'bc59a9f6-e308-4c1c-af96-0aebb8ac72c6'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'bc59a9f6-e308-4c1c-af96-0aebb8ac72c6'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
