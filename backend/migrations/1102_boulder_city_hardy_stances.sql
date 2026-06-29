-- Migration 1102: City of Boulder City stances - Joe Hardy (Mayor) (AUDIT-ONLY)
--
-- Phase 165 (CLARK-05). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1100. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = df1a6a02-6248-41df-8274-b589f6770aee (external_id -3208001, minted by mig 1100).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development'::text, 1, 'As Mayor and longtime representative of the Boulder City area, Hardy publicly endorses the voter-mandated Controlled Growth Ordinance (~120 residential permits/year cap), saying in his 2025 candidate profile that the ordinance, now over three decades old, "has been effective to keep our city small, safe and secure." Boulder City''s charter also requires voter approval for major land actions, which he has defended - a growth-limits / voter-approval position.', ARRAY['https://bouldercityreview.com/news/candidate-profile-joe-hardy-69702/','https://bouldercityreview.com/news/understanding-the-growth-ordinance-77784/']::text[]),
    ('data-centers'::text, 3, 'At the Feb. 24, 2026 council meeting Hardy voted 3-1 (with Ashurst and Walton; Booth no; Jorgensen absent) to place the Eldorado Valley data-center land-use question on the Nov. 2026 ballot, consistent with charter Section 144''s requirement that such uses receive voter approval. His action subjects the proposal to a formal community-approval process before any use is permitted, rather than welcoming it with incentives or blocking it outright.', ARRAY['https://www.bouldercity.com/election-2026-will-boulder-city-voters-permit-data-centers/','https://www.reviewjournal.com/news/environment/data-centers-will-be-on-the-ballot-in-this-southern-nevada-city-3727498/']::text[]),
    ('economic-development'::text, 3, 'Hardy praises the Eldorado Valley solar leases as "a boon economically and strategically" (they fund roughly one-third of the city budget), endorsing targeted use of city-owned desert land for specific revenue-generating industries rather than broad corporate tax abatements - a targeted, community-benefit economic-development posture.', ARRAY['https://bouldercityreview.com/news/candidate-profile-joe-hardy-69702/','https://bouldercityreview.com/opinion/eldorado-valley-the-gift-that-keeps-on-giving-102319/']::text[]),
    ('homelessness-response'::text, 4, 'Hardy voted with the unanimous 5-0 council majority on May 27, 2025 to outlaw camping, sleeping, and storing property on public land (a misdemeanor punishable by up to six months in jail). He raised a practical concern about enforcement scope but still voted yes, with no companion services-first program in the measure - anti-camping enforcement as the primary tool.', ARRAY['https://bouldercityreview.com/news/council-outlaws-camping-sleeping-in-public-98968/','https://nevadacurrent.com/2025/08/01/boulder-city-latest-to-criminalize-homelessness-with-anti-camping-ordinance/']::text[]),
    ('taxes'::text, 3, 'Hardy touts Boulder City''s status as having the lowest property tax in Nevada and a solar-lease-funded budget, framing the existing low-tax structure as a success to be preserved rather than raised or further cut - a keep-the-current-system position.', ARRAY['https://bouldercityreview.com/news/candidate-profile-joe-hardy-69702/','https://bouldercityreview.com/news/city-adopts-fiscal-year-26-budget-100218/']::text[]),
    ('housing'::text, 3, 'On the Tract 350 / Liberty Ridge development, Hardy supported a managed land sale (Toll Brothers, ~122 lots) with proceeds earmarked for public facilities while demanding the process be "more transparent through every step." He favors targeted, city-facilitated housing via controlled land sales rather than direct public housing or pure market deregulation.', ARRAY['https://bouldercityreview.com/news/candidate-profile-joe-hardy-69702/','https://bouldercityreview.com/news/tract-350-sale-approved-85123/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'df1a6a02-6248-41df-8274-b589f6770aee'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'df1a6a02-6248-41df-8274-b589f6770aee'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
