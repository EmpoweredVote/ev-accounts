-- 1274_seed_wy_2026_house_election_race.sql
-- Phase 165-07: 'WY 2026 Statewide General' + 1 at-large race (geo 5600). PROVISIONAL (WY primary
--   2026-08-18 verified). OPEN seat (Hageman -> Senate). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'WY 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'WY'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'WY 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-18'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '5600'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'WY 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
