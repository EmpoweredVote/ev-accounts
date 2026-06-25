-- Migration 1070: US Senate races — same statewide-visibility fix (extends 1067-1069)
--
-- The statewide-exec sweep surfaced the identical defect in federal statewide
-- races: US Senate races are resolved by electionService.fetchStatewideRaceRows()
-- (office_id IS NULL AND e.state = $state), but these were seeded WITH an
-- office_id, hiding them from the feed. US Senate is federal (not a state exec),
-- but it is the same bug and the same fix; included here to fully clear hidden
-- statewide races.
--
-- Affected (7): MA (primary 2026-09-01 + general 2026-11-03), MD, ME (primary
-- 2026-06-09 + general 2026-11-03), OR, VA. Targeted by explicit race id.
-- District/city races untouched.

BEGIN;

UPDATE essentials.races
SET office_id = NULL
WHERE id IN (
  '7eda9036-9eb6-4f2d-86a1-c1e7cbb51864',  -- U.S. Senate Massachusetts (primary)
  '65b552af-ac06-45ac-bafb-f21f2015a4ec',  -- U.S. Senate Massachusetts (general)
  '961f1dd1-6751-415e-8741-0483493bdfe7',  -- U.S. Senate Maryland
  '726895fa-bd50-4a09-9782-88c1afffbc65',  -- U.S. Senate Maine (general)
  '5b6ed92b-ca02-4988-ac2e-334fb12ce916',  -- U.S. Senate Maine (primary)
  '08051b89-7c0d-4609-9543-e685f44f6821',  -- U.S. Senate Oregon
  '8857c4d8-fc3f-4823-b09d-542acb484bef'   -- U.S. Senate Virginia
);

-- Final catch-all: confirm NO statewide race (state exec, governor, or federal
-- US Senate / President) still carries an office_id.
SELECT count(*) AS statewide_races_still_linked
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
WHERE o.role_canonical IN ('governor','lieutenant_governor','attorney_general','secretary_of_state','treasurer')
   OR (o.representing_city IS NULL AND r.position_name ~* '(lieutenant gov|attorney general|secretary of state|state treasurer|treasurer of|comptroller|state controller|state auditor|auditor of|insurance commissioner|superintendent of public|land commissioner|^governor| governor of|u\.?s\.? senate|united states senate|^senator| for senate|president)');

COMMIT;
