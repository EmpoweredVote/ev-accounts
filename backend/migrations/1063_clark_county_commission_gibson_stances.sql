-- Migration 1063: Clark County Commission stances - James B. Gibson (District G) (AUDIT-ONLY)
--
-- Phase 161 (CLARK-01). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1055. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- county-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = b9411246-f74d-4502-9f6b-ed5facc37fa6 (external_id -3200307, minted by mig 1055).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 3, 'Voted yes on the public-camping ban (passed 6-1 Nov 5/6, 2024); the ordinance bars arrest when no shelter bed is available and uses a warning-first graduated process. Gibson (Oct 1, 2024): this isn''t about going out and arresting people; the objective here is to educate them, to give them an opportunity to get to a place where they can understand what the alternatives are.', ARRAY['https://www.fox5vegas.com/2024/11/07/clark-county-passes-hotly-debated-homeless-camping-ordinance/','https://lasvegassun.com/news/2024/oct/15/clark-county-introduces-ordinance-to-ban-camping-i/']::text[]),
    ('homelessness-response'::text, 3, 'On the same Nov 2024 camping ban (voted yes), framed enforcement around outreach and services: officers must educate, provide shelter/resource information and direct people to alternatives before citation (enforcement of rules paired with outreach/shelter referral).', ARRAY['https://www.fox5vegas.com/2024/11/07/clark-county-passes-hotly-debated-homeless-camping-ordinance/','https://lasvegassun.com/news/2024/oct/15/clark-county-introduces-ordinance-to-ban-camping-i/']::text[]),
    ('growth-and-development'::text, 5, 'Publicly dismissed sprawl concerns and advocated opening federal public land to development to lower housing costs (Nevada Current, Nov 20, 2024): sprawl is something that has been studied in this valley many times, it''s not what we face; the availability of land is suppressing economic opportunity and driving housing costs to a place where we can''t tolerate them anymore. Reiterated in an Oct 26, 2025 RJ op-ed (removing barriers to growth).', ARRAY['https://nevadacurrent.com/2024/11/20/clark-county-lands-bills-boosters-see-economic-growth-critics-see-unsustainable-urban-sprawl/','https://www.reviewjournal.com/opinion/letters/letter-clark-county-commissioner-downplays-local-sprawl-3531234/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'b9411246-f74d-4502-9f6b-ed5facc37fa6'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'b9411246-f74d-4502-9f6b-ed5facc37fa6'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
