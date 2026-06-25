-- Migration 1069: Statewide-exec race visibility sweep (completes 1067/1068)
--
-- Same fix as 1067 (CA Governor) / 1068 (other governors): a statewide race must
-- have office_id IS NULL to surface via electionService.fetchStatewideRaceRows().
-- A full sweep of statewide executive races (by office role_canonical AND by
-- statewide-office name patterns) found two remaining races still carrying an
-- office_id, both Maryland statewide constitutional officers:
--
--   Attorney General of Maryland (role_canonical = attorney_general)
--     race c08f3d4e-2188-4d7c-a598-f8b2bbfaa573
--   Comptroller of Maryland (statewide elected officer; office role_canonical
--     was left NULL — MD's elected Comptroller was intentionally out of the
--     v2.18 Big-5 treasurer mapping — but it is still a statewide race)
--     race e80f817e-e292-4c8c-a10c-8b801fb32a13
--
-- Both: MD, 2026-11-03 general, 0 seeded candidates (candidate population is a
-- separate data gap; the visibility fix is still correct). Targeted by explicit
-- race id since the Comptroller office carries no role_canonical. District and
-- city/at-large races are deliberately untouched (they need office_id).

BEGIN;

UPDATE essentials.races
SET office_id = NULL
WHERE id IN (
  'c08f3d4e-2188-4d7c-a598-f8b2bbfaa573',  -- Attorney General of Maryland
  'e80f817e-e292-4c8c-a10c-8b801fb32a13'   -- Comptroller of Maryland
);

-- Verify: no statewide-exec race retains an office_id (role-tagged OR by name).
SELECT count(*) AS statewide_exec_still_linked
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
WHERE o.role_canonical IN ('governor','lieutenant_governor','attorney_general','secretary_of_state','treasurer')
   OR (o.role_canonical IS NULL
       AND o.representing_city IS NULL
       AND r.position_name ~* '(lieutenant gov|attorney general|secretary of state|state treasurer|treasurer of|comptroller|state controller|state auditor|auditor of|insurance commissioner|superintendent of public|land commissioner|^governor| governor of)');

COMMIT;
