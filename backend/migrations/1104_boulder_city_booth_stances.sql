-- Migration 1104: City of Boulder City stances - Cokie Booth (Council Member) (AUDIT-ONLY)
--
-- Phase 165 (CLARK-05). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1100. Evidence-only compass stances (CHAIRS
-- model). 100% cited; honest blanks for topics without city-level evidence.
-- No defaulted values. topic_id resolved LIVE by topic_key (is_live=true).
-- politician_id = 49226ba0-9a4f-4269-8415-eac2395fe696 (external_id -3208003, minted by mig 1100).
-- NOTE: data-centers is an honest blank - Booth cast the lone NO vote on Feb 24, 2026
-- but her only documented reasoning ("not for or against...don''t know much about them")
-- matches no chair, so no value is placed (evidence-only / no inference).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development'::text, 1, 'In her Boulder City Review candidate profile Booth said the high-density Tract 350 proposal "does not conform to our standard zoning" or to "the slow-growth ordinance or the historic charm of our community," and that she "absolutely do[es] not want it to look like or become Henderson," defending the controlled/slow-growth ordinance - keeping statutory growth limits in place rather than streamlining or removing them.', ARRAY['https://bouldercityreview.com/news/candidate-profile-cokie-booth-64440/','https://bouldercityreview.com/news/understanding-the-growth-ordinance-77784/']::text[]),
    ('homelessness-response'::text, 4, 'Booth was part of the council''s unanimous 5-0 vote on May 27, 2025 to pass the ordinance prohibiting camping, sleeping, and storing property in public places, a misdemeanor punishable by up to six months in jail. The ordinance establishes anti-camping enforcement as the primary tool.', ARRAY['https://bouldercityreview.com/news/council-outlaws-camping-sleeping-in-public-98968/','https://www.bouldercity.com/no-camping-ordinance-mirrors-valleys-restrictions/']::text[]),
    ('local-environment'::text, 1, 'Per her candidate profile, Booth''s record includes fighting to stop a Class 4 landfill in the Eldorado Valley and instead pushing for solar use of the land, prioritizing preservation/environmental protection of city open land over higher-impact development - a preservation-and-review-before-development posture.', ARRAY['https://bouldercityreview.com/news/candidate-profile-cokie-booth-64440/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '49226ba0-9a4f-4269-8415-eac2395fe696'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '49226ba0-9a4f-4269-8415-eac2395fe696'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
