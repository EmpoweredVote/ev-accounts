-- 1278_seed_nd_2026_house_election_race.sql
-- Phase 165-08: 'ND 2026 Statewide General' + 1 at-large race (geo 3800). DECIDED -> NOT
--   PROVISIONAL (ND petition window to 2026-08-31 -> Phase 167). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'ND 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'ND'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'ND 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, 'Confirmed general field; ND independent-petition window open to 2026-08-31 -> Phase 167'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '3800'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'ND 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
