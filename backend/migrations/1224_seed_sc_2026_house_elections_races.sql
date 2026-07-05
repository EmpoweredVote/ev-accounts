-- 1224_seed_sc_2026_house_elections_races.sql
-- Phase 163-05 Task 2: SC 2026 Statewide General election + 7 U.S. House races.
-- Field source: 160-field-table-p163.csv (SC rows), from Wikipedia 2026 US House elections in
--   South Carolina. SC is NOT redistricted -> no withholding (vanilla new-election). Primaries
--   DECIDED -> NOT PROVISIONAL-marked. ANTIPARTISAN INVARIANT: party is NEVER stored on
--   race_candidates; races.primary_party stays NULL. SC-1 (Mace) + SC-5 (Norman) both retired to
--   run for Governor but their district offices already exist -- NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'SC 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'SC'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'SC 2026 Statewide General');

-- 7 races on the EXISTING SC NATIONAL_LOWER US Rep offices (geo 4501..4507)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'Confirmed nominees (SC primary decided)'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '45'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'SC 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
