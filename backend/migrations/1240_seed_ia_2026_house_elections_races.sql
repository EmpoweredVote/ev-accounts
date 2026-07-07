-- 1240_seed_ia_2026_house_elections_races.sql
-- Phase 164-05 Task 3: IA 2026 Statewide General election + 4 U.S. House races (geo 1901..1904).
--   Decided field -> NOT PROVISIONAL. IA-2 (Hinson retired) + IA-4 (Feenstra retired) open seats —
--   offices exist, NO insert. ANTIPARTISAN INVARIANT: party never stored; races.primary_party NULL.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'IA 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'IA'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'IA 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1,
       'Confirmed 2026 general-election field'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '19'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'IA 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
