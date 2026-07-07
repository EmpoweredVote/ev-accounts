-- 1222_seed_co_2026_house_elections_races.sql
-- Phase 163-03 Task 2: CO 2026 Statewide General election + 8 U.S. House races.
-- Field source: 160-field-table-p163.csv (CO rows), from Wikipedia 2026 US House elections in
--   Colorado. CO is NOT redistricted -> no withholding (vanilla new-election). Primaries DECIDED
--   2026-06-30 -> NOT PROVISIONAL-marked. ANTIPARTISAN INVARIANT: party is NEVER stored on
--   race_candidates; races.primary_party stays NULL. CO-1 (Diana DeGette) LOST her primary to
--   Melat Kiros but the district office already exists -- NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'CO 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'CO'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'CO 2026 Statewide General');

-- 8 races on the EXISTING CO NATIONAL_LOWER US Rep offices (geo 0801..0808)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'Confirmed nominees (primary decided 2026-06-30)'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '08'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'CO 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
