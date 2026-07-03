-- 1187_seed_az_2026_house_elections_races.sql
-- Phase 161-02 Task 1: AZ 2026 Statewide General election + 9 provisional U.S. House races.
-- Field source: 160-field-table-p161.csv (AZ rows), cross-checked Wikipedia "2026 United States
--   House of Representatives elections in Arizona" (per-district pages). Provisional pre-primary
--   field (FL-151 D-04 pattern), culled >= 2026-07-22 (day after AZ's Jul-21 primary). D-02 hard
--   target: AZ live before its primary. ANTIPARTISAN INVARIANT: party is NEVER stored on
--   race_candidates; races.primary_party stays NULL. AZ-1 (Schweikert) and AZ-5 (Biggs) are
--   RETIRED open seats but their district offices already exist -- NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'AZ 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'AZ'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'AZ 2026 Statewide General');

-- 9 provisional races on the EXISTING AZ NATIONAL_LOWER US Rep offices (geo 0401..0409)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-07-22'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '04'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'AZ 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
