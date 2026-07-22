-- 1380: FL new-map incumbency flags + two garbled-name repairs (Phase 164.2-04 Task 1)
--
-- WHY: The 2026-07-21 audit of the FL candidate field (already new-map) found three
--   incumbents unflagged on their NEW-map districts and two garbled politician names.
--     * Debbie Wasserman Schultz -> FL-20 (geo_id 1220), Lois Frankel -> FL-23 (1223),
--       Jared Moskowitz -> FL-25 (1225): incumbents on the enacted-2026 map, currently
--       is_incumbent=false on their active "FL 2026 Statewide General" rows.
--     * 'Kedner MaximeDe' -> 'Kedner Maxime' (external_id -1212009, FL-20 challenger).
--     * 'Seth Haskins'    -> 'Seth Haskin'  (external_id -1211914, FL-19 challenger).
--
-- EFFECT: three is_incumbent flips + two renames (politicians.full_name/last_name and the
--   denormalized race_candidates.full_name copies). Sheila Cherfilus-McCormick stays a
--   non-incumbent active candidate in the paired FL-20 field (new-map incumbent pairing),
--   per the audit; only Wasserman Schultz is the flagged FL-20 incumbent.
--
-- Idempotent: every write guarded on its pre-change value; re-run touches 0 rows.

BEGIN;

-- 1) FL-20/23/25 new-map incumbency flags (guarded IS DISTINCT FROM true).
UPDATE essentials.race_candidates rc
SET is_incumbent = true, updated_at = now()
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.offices   o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id IN (-12025, -12022, -12023)
WHERE rc.race_id = r.id
  AND rc.politician_id = p.id
  AND e.name = 'FL 2026 Statewide General'
  AND d.district_type = 'NATIONAL_LOWER'
  AND rc.candidate_status = 'active'
  AND ( (d.geo_id = '1220' AND p.external_id = -12025)    -- Debbie Wasserman Schultz
     OR (d.geo_id = '1223' AND p.external_id = -12022)    -- Lois Frankel
     OR (d.geo_id = '1225' AND p.external_id = -12023) )  -- Jared Moskowitz
  AND rc.is_incumbent IS DISTINCT FROM true;

-- 2a) Rename 'Kedner MaximeDe' -> 'Kedner Maxime' (external_id -1212009).
UPDATE essentials.politicians
SET full_name = 'Kedner Maxime', last_name = 'Maxime'
WHERE external_id = -1212009 AND full_name = 'Kedner MaximeDe';

UPDATE essentials.race_candidates rc
SET full_name = 'Kedner Maxime', last_name = 'Maxime', updated_at = now()
WHERE rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -1212009)
  AND rc.full_name = 'Kedner MaximeDe';

-- 2b) Rename 'Seth Haskins' -> 'Seth Haskin' (external_id -1211914).
UPDATE essentials.politicians
SET full_name = 'Seth Haskin', last_name = 'Haskin'
WHERE external_id = -1211914 AND full_name = 'Seth Haskins';

UPDATE essentials.race_candidates rc
SET full_name = 'Seth Haskin', last_name = 'Haskin', updated_at = now()
WHERE rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -1211914)
  AND rc.full_name = 'Seth Haskins';

COMMIT;
