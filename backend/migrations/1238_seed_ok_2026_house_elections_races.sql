-- 1238_seed_ok_2026_house_elections_races.sql
-- Phase 164-05 Task 2: OK 2026 Statewide General election + 5 U.S. House races (geo 4001..4005).
--   Decided field -> NOT PROVISIONAL. OK-1 open seat (Hern retired) — office exists, NO insert.
--   ANTIPARTISAN INVARIANT: party never stored on race_candidates; races.primary_party NULL.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'OK 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'OK'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'OK 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1,
       'Confirmed 2026 general-election field'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '40'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'OK 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
