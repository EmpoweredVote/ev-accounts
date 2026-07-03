-- 1189_seed_wa_2026_house_elections_races.sql
-- Phase 161-04 Task 1: WA 2026 Statewide General election + 10 provisional U.S. House races.
-- Field source: 160-field-table-p161.csv (WA rows). WA is ballot_system=top-two but is seeded
--   EXACTLY like any other late-primary state: one race per district, all qualified candidates
--   from all parties active (top-two cull is Phase 167's concern, NOT this migration's). Provisional
--   pre-primary field, culled >= 2026-08-05 (day after WA's Aug-4 top-two primary). ANTIPARTISAN
--   INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL. WA-4
--   (Dan Newhouse) is a RETIRED open seat but its district office already exists -- NO
--   office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'WA 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'WA'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'WA 2026 Statewide General');

-- 10 provisional races on the EXISTING WA NATIONAL_LOWER US Rep offices (geo 5301..5310)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '53'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'WA 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
