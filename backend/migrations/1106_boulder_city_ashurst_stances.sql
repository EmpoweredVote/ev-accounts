-- Migration 1106: City of Boulder City stances - Denise E. Ashurst (Council Member) (AUDIT-ONLY)
--
-- Phase 165 (CLARK-05). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1100. Evidence-only compass stances (CHAIRS
-- model). 100% cited; honest blanks for topics without city-level evidence.
-- No defaulted values. topic_id resolved LIVE by topic_key (is_live=true).
-- politician_id = d593c322-4c04-409a-9da4-c77294b1772d (external_id -3208005, minted by mig 1100).
-- NOTE: Ashurst took office Nov/Dec 2024 - shortest record, so only 2 citable stances;
-- the rest are honest blanks (expected for a new member, NOT defaulted).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('data-centers'::text, 3, 'At the Feb. 24, 2026 council meeting Ashurst voted YES (3-1, with Hardy and Walton; Booth no; Jorgensen absent) to place the Eldorado Valley data-center question on the Nov. 2026 ballot - the mechanism by which charter Section 144 requires voter approval before a new land use is allowed. Her cited reasoning was openness subject to that approval ("I know we are small town and we have our ordinance of the type of town we want to be but I think there is always room for technology"), with no incentives or abatements offered.', ARRAY['https://www.bouldercity.com/election-2026-will-boulder-city-voters-permit-data-centers/','https://www.fox5vegas.com/2026/04/02/boulder-city-residents-oppose-proposed-data-center/']::text[]),
    ('homelessness-response'::text, 4, 'Ashurst was part of the unanimous 5-0 council vote (late May 2025, effective June 19, 2025) enacting the ordinance prohibiting camping, sleeping, and storing property in public places, a misdemeanor punishable by up to six months in jail. She defended the enforcement tool directly: the city needed an ordinance "because if you don''t have something in place, then you don''t have anything to lean on" - anti-camping enforcement as the primary tool with only minimal service pairing.', ARRAY['https://bouldercityreview.com/news/council-outlaws-camping-sleeping-in-public-98968/','https://nevadacurrent.com/2025/08/01/boulder-city-latest-to-criminalize-homelessness-with-anti-camping-ordinance/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'd593c322-4c04-409a-9da4-c77294b1772d'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'd593c322-4c04-409a-9da4-c77294b1772d'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
