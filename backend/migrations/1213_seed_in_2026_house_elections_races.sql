-- 1213_seed_in_2026_house_elections_races.sql
-- Phase 162-07 Task 2: IN 2026 Statewide General election + 9 U.S. House races.
-- Field source: 160-field-table-p162.csv (IN rows) + GreenPapers/Wikipedia 2026 IN US House.
-- DECIDED field (May-5 primary done) -> NOT PROVISIONAL-marked. ANTIPARTISAN INVARIANT: party
--   never stored on race_candidates; races.primary_party stays NULL. All 9 district offices
--   already exist -- NO office/district insert. (IN-9 primary incumbent flags corrected first
--   in migration 1212.)
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'IN 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'IN'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'IN 2026 Statewide General');

-- 9 races on the EXISTING IN NATIONAL_LOWER US Rep offices (geo 1801..1809)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'Confirmed nominee + declared-so-far minor-party field (primary decided May-5)'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '18'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'IN 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
