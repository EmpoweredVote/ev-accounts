-- 1220_seed_wi_2026_house_elections_races.sql
-- Phase 163-02 Task 2: WI 2026 Statewide General election + 8 provisional U.S. House races.
-- Field source: 160-field-table-p163.csv (WI rows), from Wikipedia 2026 US House elections in
--   Wisconsin + local news. WI is NOT redistricted -> no withholding (vanilla new-election).
--   Late primary (Aug-11) -> provisional pre-primary field, culled >= 2026-08-12. ANTIPARTISAN
--   INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
--   WI-7 (Tiffany) is an open seat (ran for Governor) but its district office already exists --
--   NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'WI 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'WI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'WI 2026 Statewide General');

-- 8 provisional races on the EXISTING WI NATIONAL_LOWER US Rep offices (geo 5501..5508)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '55'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'WI 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
