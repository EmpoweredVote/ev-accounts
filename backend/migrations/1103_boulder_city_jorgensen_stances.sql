-- Migration 1103: City of Boulder City stances - Sherri Jorgensen (Council Member) (AUDIT-ONLY)
--
-- Phase 165 (CLARK-05). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1100. Evidence-only compass stances (CHAIRS
-- model). 100% cited; honest blanks for topics without city-level evidence.
-- No defaulted values. topic_id resolved LIVE by topic_key (is_live=true).
-- politician_id = d604777b-9e3a-4f3b-b1a3-3ee965177788 (external_id -3208002, minted by mig 1100).
-- NOTE: data-centers is an honest blank - Jorgensen was ABSENT from the Feb 24, 2026 vote.

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development'::text, 1, 'Jorgensen voted NO on the Tract 350 / Toll Brothers subdivision (Resolution 7480) in July 2022, helping deny it, citing community input ("We had a large outpouring tonight"). As allotment-committee chair she defends Boulder City''s voter-rooted Controlled Growth Ordinance ("Our growth policies have kept us from becoming Henderson"), favoring strict limits and voter/community constraints on major development.', ARRAY['https://bouldercityreview.com/news/land-sale-in-limbo-70455/','https://bouldercityreview.com/news/candidate-profile-sherri-jorgensen-64412/']::text[]),
    ('economic-development'::text, 3, 'Jorgensen frames Boulder City''s solar fields as a beneficial, targeted revenue source consistent with community values ("a fortunate and much-needed source of revenue to our city in our characteristic clean, green fashion") and supports Boulder Creek area development "only if it makes economic sense, is done at a measured pace within the growth ordinance''s parameters" - targeted, community-benefit-conditioned development rather than maximal incentives.', ARRAY['https://bouldercityreview.com/news/candidate-profile-sherri-jorgensen-64412/']::text[]),
    ('homelessness-response'::text, 4, 'On May 27, 2025 the council unanimously (5-0) passed Ordinance 1862 prohibiting camping, sleeping, and storing property in public places without a permit; Jorgensen, a sitting council member and Mayor Pro Tem present at that meeting, was part of the unanimous majority. The measure makes anti-camping enforcement the primary tool with no accompanying shelter/services expansion.', ARRAY['https://bouldercityreview.com/news/council-outlaws-camping-sleeping-in-public-98968/','https://www.bouldercity.com/no-camping-ordinance-mirrors-valleys-restrictions/']::text[]),
    ('housing'::text, 3, 'Jorgensen supports residential development on the voter-approved Boulder Creek area "only if it makes economic sense, is done at a measured pace within the growth ordinance''s parameters" and aligned with existing community style - a targeted, conditions-based approach rather than deregulation or public housing.', ARRAY['https://bouldercityreview.com/news/candidate-profile-sherri-jorgensen-64412/']::text[]),
    ('taxes'::text, 3, 'Jorgensen repeatedly emphasizes funding capital projects (e.g., the pool replacement) through existing voter-approved capital-improvement funds, donations, and budget augmentations on a pay-as-you-go basis "without raising taxes or out-of-pocket cost to taxpayers" - a keep-the-current-system fiscal posture.', ARRAY['https://bouldercityreview.com/news/a-look-at-candidates-for-boulder-city-council-sherri-jorgensen-85105/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'd604777b-9e3a-4f3b-b1a3-3ee965177788'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'd604777b-9e3a-4f3b-b1a3-3ee965177788'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
