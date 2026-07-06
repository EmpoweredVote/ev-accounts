-- 1233_seed_ct_2026_house_elections_races.sql
-- Phase 164-02 Task 2: CT 2026 Statewide General election + 5 provisional U.S. House races.
-- Field source: 160-field-table-p164.csv (CT rows) + Task-1 D-02 directly-fetched re-verification
--   (FEC candidate API + Ballotpedia). CT is NOT redistricted -> no withholding (vanilla new-
--   election). Late primary (Aug-11) -> provisional convention/petition field, culled >= 2026-08-12.
--   ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays
--   NULL. All 5 incumbents renominated/running (Larson lost endorsement but is a primary candidate)
--   -> no open-seat/office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'CT 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'CT'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'CT 2026 Statewide General');

-- 5 provisional races on the EXISTING CT NATIONAL_LOWER US Rep offices (geo 0901..0905)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary convention/petition qualified field, cull >= 2026-08-12'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '09'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'CT 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
