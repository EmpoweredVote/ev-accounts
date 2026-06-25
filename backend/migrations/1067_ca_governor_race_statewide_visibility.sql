-- Migration 1067: Make the CA Governor race visible in the elections feed
--
-- Bug: the CA 2026 Governor race (Nov 3 general) did not surface for Los Angeles
-- (or any CA) users — only the LA Mayor race showed.
--
-- Root cause: electionService.ts resolves statewide races (Governor, US Senate,
-- statewide execs) via fetchStatewideRaceRows(), which selects
--   WHERE r.office_id IS NULL AND e.state = $state.
-- The CA Governor race was seeded WITH an office_id (linked to the statewide
-- Governor office, whose district is the whole state). That makes it invisible:
--   - skipped by the statewide path (office_id is NOT NULL), and
--   - skipped by the district / government-geo paths (a statewide "district" is
--     not in an LA user's resolved district stack).
-- Every other working statewide race (18 of them: CA AG/SoS/LtGov/Treasurer/etc.)
-- follows the convention office_id IS NULL. This aligns the Governor race with it.
--
-- Candidates are unaffected (race_candidates link to race_id directly, not via
-- office). office_id is nullable and already NULL on 18 statewide races.
--
-- Race:     bc936a36-287c-4ffd-abd8-5e4fd798bae5  (CA Governor)
-- Election: CA 2026 Statewide General (2026-11-03, state, CA)

BEGIN;

UPDATE essentials.races
SET office_id = NULL
WHERE id = 'bc936a36-287c-4ffd-abd8-5e4fd798bae5'
  AND position_name = 'CA Governor';

-- Verify the race now satisfies the statewide-feed predicate AND simulate the
-- exact fetchStatewideRaceRows window for CA (Governor must appear).
SELECT DISTINCT r.position_name, e.name AS election, e.election_date,
       count(rc.id) OVER (PARTITION BY r.id) AS candidates
FROM essentials.elections e
JOIN essentials.races r ON r.election_id = e.id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
WHERE r.office_id IS NULL
  AND e.state = 'CA'
  AND (
    (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
    OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
  )
  AND r.position_name = 'CA Governor';

COMMIT;
