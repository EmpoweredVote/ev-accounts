-- 1212_fix_in9_incumbent_flags.sql
-- Phase 162-07 Task 1 (D-02): correct the IN-9 primary incumbent flags BEFORE any IN
-- general race is authored, so no incumbency-derived logic inherits the error.
--
-- DEVIATION FROM PLAN (A2 mitigation fired — live SELECT re-verify contradicted the audit CSV):
--   The plan/160-race-preexistence-audit.csv assumed all 5 rows sat on ONE race
--   (7d3f0042) with Houchin's race_candidates.id = 9d2de2ae. LIVE prod shows otherwise:
--     * 7d3f0042 = IN-9 DEMOCRATIC primary (primary_party=Democratic). Holds the 4 Dem
--       candidates (Meyer/Graham/Roark/Peck), ALL wrongly is_incumbent=true.
--     * 9d2de2ae = IN-9 REPUBLICAN primary RACE id (NOT a race_candidates.id). Holds only
--       Erin Houchin (the incumbent), row a61ab808-..., wrongly is_incumbent=false.
--   All five specific race_candidates.id values in the CSV were stale. The ids below are the
--   live-verified ones. Intent preserved: exactly 1 incumbent=true across IN-9 (Houchin).
-- Primary races and their rows are NOT deleted (D-02a). Each UPDATE is guarded by the
-- opposite is_incumbent value → re-apply is a 0-row no-op.
BEGIN;

-- Houchin (R incumbent) on the Republican primary: false -> true
UPDATE essentials.race_candidates
SET is_incumbent = true
WHERE id = 'a61ab808-846a-4bb7-9544-f9f33357b078'  -- Erin Houchin (race 9d2de2ae, R primary)
  AND is_incumbent = false;

-- 4 Democratic primary candidates: true -> false (none are incumbents)
UPDATE essentials.race_candidates
SET is_incumbent = false
WHERE id IN (
  'e013947d-ae17-4f26-bb7c-c35f485fd1bc',  -- Brad A. Meyer
  '22151151-db64-4f41-8b06-068df102d9f4',  -- James H. (Jim) Graham
  'ec6f181a-aeb8-43bd-8e32-83ed47070781',  -- Keil L. Roark
  '9fe223d8-1fcc-43b5-8869-b88a5bb5f7ea'   -- Tim Peck
) AND is_incumbent = true;

COMMIT;
