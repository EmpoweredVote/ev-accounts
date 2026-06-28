-- Migration 1083: City of Las Vegas stances - Nancy E. Brune (Council Member, Ward 6) (AUDIT-ONLY)
--
-- Phase 162 (CLARK-02). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1075. Evidence-only compass stances (CHAIRS
-- model). 100% cited; honest blanks where no city-level evidence. No defaults.
-- Council-era + campaign evidence only; nonpartisan Guinn Center think-tank
-- leadership was NOT converted into personal stances.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 0a0ea0c6-ed7b-4e84-833d-f6a04d3350e9 (external_id -3205007, minted by mig 1075).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('local-environment'::text, 2, 'First council ordinance/resolution (May 2023) protected Floyd Lamb Park from over-commercialization at residents'' request and prohibited large commercial events to preserve it as open space - "preserving it as open space for future generations."', ARRAY['https://thenevadaindependent.com/article/meet-the-challengers-looking-to-oust-nancy-brune-in-las-vegas-ward-6','https://brune4vegas.com/priorities-and-work/']::text[]),
    ('growth-and-development'::text, 3, 'Champions "smart growth that protects our unique Ward 6 character while expanding amenities"; negotiated developer concessions for parks/green space and approved the Kyle Canyon Special Area Plan to guide long-term growth of the northwest valley (2024-2025).', ARRAY['https://brune4vegas.com/priorities-and-work/','https://thenevadaindependent.com/article/meet-the-challengers-looking-to-oust-nancy-brune-in-las-vegas-ward-6']::text[]),
    ('public-safety-approach'::text, 4, 'Self-identified "Public Safety Advocate"; successfully advocated for a new Skye Canyon Police Substation to bring faster response times and opened a new fire station, plus LVMPD-partnered enforcement measures (first-party priorities; 2026 reporting).', ARRAY['https://brune4vegas.com/priorities-and-work/','https://www.yahoo.com/news/articles/police-union-president-addiction-recovery-115515870.html']::text[]),
    ('housing'::text, 3, 'As Chair of the Southern Nevada Regional Housing Authority she advocates "attainable housing projects," supports public-private partnerships and bringing Community Development Corporations to develop affordable housing, and backed the 2025 Monument Hills plan including 300 military housing units.', ARRAY['https://brune4vegas.com/priorities-and-work/','https://ballotpedia.org/Nancy_Brune']::text[]),
    ('homelessness-response'::text, 3, 'Touts a service/shelter approach: city funds emergency shelter, a Recuperative Care Center for medically vulnerable unhoused ("We don''t want them to go out into the streets to recover") and Campus for Hope, plus a chronic-homelessness program (April 2026); no enforcement-first framing.', ARRAY['https://www.yahoo.com/news/articles/police-union-president-addiction-recovery-115515870.html','https://thenevadaindependent.com/article/meet-the-challengers-looking-to-oust-nancy-brune-in-las-vegas-ward-6']::text[]),
    ('taxes'::text, 3, 'Holds the line on revenue without raising taxes: "We don''t have the authority to raise taxes. We are building parking garages to try to account for the traffic and the increased visitation," and says the city has been "extremely conservative" with spending (May 2026).', ARRAY['https://www.yahoo.com/news/articles/police-union-president-addiction-recovery-115515870.html','https://thenevadaindependent.com/article/meet-the-challengers-looking-to-oust-nancy-brune-in-las-vegas-ward-6']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '0a0ea0c6-ed7b-4e84-833d-f6a04d3350e9'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '0a0ea0c6-ed7b-4e84-833d-f6a04d3350e9'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
