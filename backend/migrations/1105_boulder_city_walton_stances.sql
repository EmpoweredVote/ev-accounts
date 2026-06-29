-- Migration 1105: City of Boulder City stances - Steve Walton (Council Member) (AUDIT-ONLY)
--
-- Phase 165 (CLARK-05). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1100. Evidence-only compass stances (CHAIRS
-- model). 100% cited; honest blanks for topics without city-level evidence.
-- No defaulted values. topic_id resolved LIVE by topic_key (is_live=true).
-- politician_id = 59d2cdfd-ca4a-4a1b-9a62-1e00ec79b549 (external_id -3208004, minted by mig 1100).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('data-centers'::text, 3, 'At the Feb. 24, 2026 council meeting Walton voted YES (3-1, with Hardy and Ashurst; Booth no; Jorgensen absent) to place the Eldorado Valley data-center question on the Nov. 2026 ballot, framing it as letting voters decide a charter-required land-use question. He noted that if approved the Council "could place restrictive measures on any data center project to protect City residents from negative affects like increased utility costs" - emphasizing safeguards and community approval, not incentives.', ARRAY['https://www.bouldercity.com/election-2026-will-boulder-city-voters-permit-data-centers/','https://www.reviewjournal.com/news/environment/data-centers-will-be-on-the-ballot-in-this-southern-nevada-city-3727498/']::text[]),
    ('growth-and-development'::text, 1, 'In his candidate profile Walton said "I support the charter and ordinances in place that are part of the growth management of our community," expects future growth to be minimal, and says voters should ultimately decide growth levels. In July 2024 he objected that consultant language about modifying/eliminating housing regulatory barriers did not belong in the city strategic plan, and the council removed it - consistent with defending growth limits and voter approval.', ARRAY['https://bouldercityreview.com/news/candidate-profile-steve-walton-69722/','https://bouldercityreview.com/news/looking-back-at-24-some-more-90429/']::text[]),
    ('homelessness-response'::text, 4, 'Walton was part of the unanimous 5-0 council vote on May 27, 2025 enacting the public-camping/sleeping ban (effective June 19, 2025), making camping in public a misdemeanor - an anti-camping enforcement ordinance as the primary tool.', ARRAY['https://bouldercityreview.com/news/council-outlaws-camping-sleeping-in-public-98968/','https://nevadacurrent.com/2025/08/01/boulder-city-latest-to-criminalize-homelessness-with-anti-camping-ordinance/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '59d2cdfd-ca4a-4a1b-9a62-1e00ec79b549'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '59d2cdfd-ca4a-4a1b-9a62-1e00ec79b549'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
