-- 1256_seed_nm_2026_house_election_races.sql
-- Phase 165-04: 'NM 2026 Statewide General' + 3 U.S. House races on existing NATIONAL_LOWER
--   offices (geo 3501-3503). DECIDED field -> NOT PROVISIONAL. office_id never NULL.
--   ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'NM 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'NM'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'NM 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field (NM SoS certified 2026 candidate list)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '3501'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'NM 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field (NM SoS certified 2026 candidate list)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '3502'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'NM 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field (NM SoS certified 2026 candidate list)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '3503'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'NM 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
