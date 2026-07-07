-- 1252_seed_ut_2026_house_election_races.sql
-- Phase 165-02: 'UT 2026 Statewide General' election + 4 U.S. House races on UT's EXISTING
--   NATIONAL_LOWER offices (geo_ids 4901-4904 persist; polygons already G5200V26 per 164.1-03).
--   BINDING 164.1-ut-wiring-contract: offices stay keyed to OLD incumbents until the Jan-2027
--   promotion phase — this migration contains NO writes to the offices / geo-districts /
--   user-districts tables (forbidden strings intentionally not spelled out). office_id is never NULL.
--   DECIDED field (Jun-23 primary done) -> NOT PROVISIONAL. ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'UT 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'UT'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'UT 2026 Statewide General');

-- 4 races on the EXISTING offices (NOT EXISTS on (election_id, office_id))
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field on the court-ordered 2026 map (LWV v. Utah Legislature; geo_ids persist, polygons G5200V26)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '4901'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'UT 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field on the court-ordered 2026 map (LWV v. Utah Legislature; geo_ids persist, polygons G5200V26)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '4902'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'UT 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field on the court-ordered 2026 map (LWV v. Utah Legislature; geo_ids persist, polygons G5200V26)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '4903'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'UT 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field on the court-ordered 2026 map (LWV v. Utah Legislature; geo_ids persist, polygons G5200V26)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '4904'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'UT 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
