-- 1268_seed_ri_2026_house_election_races.sql
-- Phase 165-07: 'RI 2026 Statewide General' + 2 races (geo 4401-4402). PROVISIONAL (RI primary
--   2026-09-09 verified). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'RI 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'RI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'RI 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-09-09'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '4401'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'RI 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-09-09'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '4402'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'RI 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
