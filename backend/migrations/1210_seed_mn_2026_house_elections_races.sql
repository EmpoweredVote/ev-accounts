-- 1210_seed_mn_2026_house_elections_races.sql
-- Phase 162-05 Task 2: MN 2026 Statewide General election + 8 provisional U.S. House races.
-- Field source: 160-field-table-p162.csv (MN rows), from candidates.sos.mn.gov 2026 federal
--   filings. MN is NOT redistricted -> no withholding (vanilla new-election). Late primary
--   (Aug-11) -> provisional pre-primary field, culled >= 2026-08-12. ANTIPARTISAN INVARIANT:
--   party is NEVER stored on race_candidates; races.primary_party stays NULL. MN-2 (Craig)
--   is an open seat (ran for US Senate) but its district office already exists -- NO office/
--   district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MN 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'MN'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MN 2026 Statewide General');

-- 8 provisional races on the EXISTING MN NATIONAL_LOWER US Rep offices (geo 2701..2708)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '27'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'MN 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
