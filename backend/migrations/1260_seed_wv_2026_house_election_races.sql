-- 1260_seed_wv_2026_house_election_races.sql
-- Phase 165-05: 'WV 2026 Statewide General' + 2 U.S. House races on existing NATIONAL_LOWER
--   offices (geo 5401-5402). DECIDED -> NOT PROVISIONAL (WV independent window to 2026-08-03 ->
--   Phase 167). office_id never NULL. ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'WV 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'WV'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'WV 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field; WV independent filing window open to 2026-08-03 -> Phase 167'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '5401'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'WV 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed general field; WV independent filing window open to 2026-08-03 -> Phase 167'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '5402'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'WV 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
