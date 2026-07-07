-- 1280_seed_sd_2026_house_election_race.sql
-- Phase 165-08: 'SD 2026 Statewide General' + 1 at-large race (geo 4600). DECIDED + FINAL.
--   OPEN seat (Johnson -> Governor). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'SD 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'SD'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'SD 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, 'Confirmed general field (SD SoS certified; independent deadline 2026-04-28 passed — field final)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '4600'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'SD 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
