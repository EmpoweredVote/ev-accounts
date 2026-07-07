-- 1266_seed_nh_2026_house_election_races.sql
-- Phase 165-06: 'NH 2026 Statewide General' + 2 U.S. House races on existing NATIONAL_LOWER
--   offices (geo 3301-3302). LATE-PRIMARY -> PROVISIONAL (NH primary 2026-09-08, verified).
--   office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'NH 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'NH'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'NH 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-09-08'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '3301'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'NH 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-09-08'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '3302'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'NH 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
