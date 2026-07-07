-- 1264_seed_hi_2026_house_election_races.sql
-- Phase 165-06: 'HI 2026 Statewide General' + 2 U.S. House races on existing NATIONAL_LOWER
--   offices (geo 1501-1502). LATE-PRIMARY -> PROVISIONAL (HI primary 2026-08-08, verified).
--   office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'HI 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'HI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'HI 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-08'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '1501'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'HI 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-08'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '1502'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'HI 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
