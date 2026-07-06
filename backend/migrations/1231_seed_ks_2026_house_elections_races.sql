-- 1231_seed_ks_2026_house_elections_races.sql
-- Phase 164-01 Task 2: KS 2026 Statewide General election + 4 provisional U.S. House races.
-- Field source: 160-field-table-p164.csv (KS rows), from the KS 2026 Wikipedia election page
--   + KS SoS 2026 federal filings. KS is NOT redistricted -> no withholding (vanilla new-
--   election). Late primary (Aug-4) -> provisional pre-primary field, culled >= 2026-08-05.
--   ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party
--   stays NULL. All 4 incumbents renominated -> no open-seat/office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'KS 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'KS'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'KS 2026 Statewide General');

-- 4 provisional races on the EXISTING KS NATIONAL_LOWER US Rep offices (geo 2001..2004)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '20'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'KS 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
