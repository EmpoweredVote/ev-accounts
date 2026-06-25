-- Migration 1068: Same statewide-visibility fix for the remaining states' Governor races
--
-- Follow-up to 1067 (CA Governor). The elections feed surfaces statewide races via
-- fetchStatewideRaceRows() = `WHERE r.office_id IS NULL AND e.state = $state`.
-- These Governor races were seeded WITH an office_id (linked to the statewide
-- Governor office), so they were invisible to the statewide path AND to the
-- district/government-geo paths. Null the office_id to match the convention.
--
-- Affected (verified role_canonical = 'governor'):
--   MA Governor (2026-11-03), MD Governor (2026-11-03),
--   ME Governor (2026-06-09 primary + 2026-11-03 general), OR Governor (2026-11-03)
--
-- Set-based + guarded to office role_canonical = 'governor' so only true
-- statewide Governor races are touched. Candidates are unaffected (race_candidates
-- link via race_id). Expected: 5 rows updated.

BEGIN;

UPDATE essentials.races r
SET office_id = NULL
FROM essentials.offices o
WHERE r.office_id = o.id
  AND o.role_canonical = 'governor'
  AND r.position_name ILIKE '%governor%'
  AND r.position_name NOT ILIKE '%lieutenant%';

-- Verify: no Governor race retains an office_id anymore.
SELECT count(*) AS governor_races_still_linked
FROM essentials.races r
WHERE r.office_id IS NOT NULL
  AND r.position_name ILIKE '%governor%'
  AND r.position_name NOT ILIKE '%lieutenant%';

-- Confirm each now satisfies the statewide-feed predicate for its state.
SELECT r.position_name, e.state, e.name AS election, e.election_date,
       (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id) AS candidates
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
WHERE r.office_id IS NULL
  AND r.position_name ILIKE '%governor%'
  AND r.position_name NOT ILIKE '%lieutenant%'
ORDER BY e.state, e.election_date;

COMMIT;
