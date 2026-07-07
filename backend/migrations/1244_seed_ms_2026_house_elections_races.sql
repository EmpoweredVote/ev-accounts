-- 1244_seed_ms_2026_house_elections_races.sql
-- Phase 164-06 Task 3: MS 2026 Statewide General election + 4 U.S. House races (geo 2801..2804).
--   Decided field -> NOT PROVISIONAL. All incumbents renominated (no open seats). ANTIPARTISAN
--   INVARIANT: party never stored on race_candidates; races.primary_party NULL.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MS 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'MS'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MS 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1,
       'Confirmed 2026 general-election field'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '28'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'MS 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
