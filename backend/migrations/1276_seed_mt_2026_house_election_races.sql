-- 1276_seed_mt_2026_house_election_races.sql
-- Phase 165-08: 'MT 2026 Statewide General' + 2 races (geo 3001-3002). DECIDED -> NOT PROVISIONAL
--   (MT independent cert window to 2026-08-20 -> Phase 167). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MT 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'MT'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MT 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field; MT independent certification pending to 2026-08-20 -> Phase 167'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '3001'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'MT 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field; MT independent certification pending to 2026-08-20 -> Phase 167'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '3002'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'MT 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
