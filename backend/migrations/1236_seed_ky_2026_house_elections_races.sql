-- 1236_seed_ky_2026_house_elections_races.sql
-- Phase 164-04 Task 2: KY 2026 Statewide General election + 6 U.S. House races.
-- Field source: 160-field-table-p164.csv (KY rows), KY SoS filings + Wikipedia. KY is NOT
--   redistricted -> no withholding (vanilla new-election). DECIDED general field -> NOT
--   PROVISIONAL. Two open seats (KY-4 Massie lost-primary, KY-6 Barr retired) — the district
--   offices already exist, NO office/district insert. ANTIPARTISAN INVARIANT: party is NEVER
--   stored on race_candidates; races.primary_party stays NULL.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'KY 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'KY'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'KY 2026 Statewide General');

-- 6 races on the EXISTING KY NATIONAL_LOWER US Rep offices (geo 2101..2106)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'Confirmed 2026 general-election field'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '21'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'KY 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
