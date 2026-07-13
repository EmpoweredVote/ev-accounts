-- =====================================================================================
-- Data retire: Salt Lake County Assessor + Surveyor "2026" races are 2024-cycle
-- carryovers — the offices are not on the 2026 ballot. Delete the race rows.
--
-- Evidence (`.planning/todos/2026-07-09-ut-primary-losers-cull.md`, agent-verified
-- 2026-07-09, live-confirmed 2026-07-12):
--   * The official SLCo Clerk 2026 candidate JSON (apps.saltlakecounty.gov
--     CandidateReporting API, 220 filers) lists NEITHER Assessor NOR Surveyor —
--     both are presidential-cycle (2024) offices.
--   * The DB rows are the literal 2024 matchups: Assessor = Chris Stavros (R) vs
--     Joel Frost (D); Surveyor = Bradley Park (R) vs Kent Setterberg — with the
--     sitting officeholders (Stavros, Park) seeded as non-incumbent "candidates",
--     the classic wrong-cycle-carryover signature. All three races sit on the
--     2026 Utah Primary election (02dee6b2-76cd-4aa3-a365-6ee362f8a719).
--   * Setterberg party flag from the same todo (DB said Republican; he ran as the
--     DEMOCRAT — slcountydems.com + LinkedIn) is resolved BY this deletion: the
--     wrong party lived on the deleted race's primary_party. Politician rows for
--     all four people are kept (real people; Stavros/Park are sitting officials).
--
-- FK order: candidate_staging + race_candidates + meetings.event_races reference
-- races (information_schema FK sweep 2026-07-12) — cleared first.
--
-- AUDIT-ONLY / unregistered (no schema_migrations ledger entry). Idempotent.
-- =====================================================================================

BEGIN;

WITH doomed(race_id) AS (VALUES
  ('370fae9a-c594-4d27-9790-fe9c6bfdec57'::uuid),  -- SLCo Assessor (R shell, Stavros)
  ('db523089-6eb1-4fa5-8b26-454c6b8ed4ba'::uuid),  -- SLCo Assessor (D shell, Frost)
  ('bfee06b8-8242-42e5-b035-cf230ab4b9bb'::uuid)   -- SLCo Surveyor (Park + Setterberg)
),
d1 AS (DELETE FROM essentials.candidate_staging WHERE race_id IN (SELECT race_id FROM doomed)),
d2 AS (DELETE FROM essentials.race_candidates   WHERE race_id IN (SELECT race_id FROM doomed)),
d3 AS (DELETE FROM meetings.event_races         WHERE race_id IN (SELECT race_id FROM doomed))
DELETE FROM essentials.races WHERE id IN (SELECT race_id FROM doomed);

COMMIT;
