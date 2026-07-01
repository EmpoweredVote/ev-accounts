-- 1146_seed_mi_2026_house_elections_races.sql
-- Phase 159-01 Task 1: MI 2026 Statewide General election + 13 provisional U.S. House races.
-- Field source: MI Bureau of Elections PRI-2026 report (mi-boe.entellitrak.com), cross-checked
--   Ballotpedia/Wikipedia (159-RESEARCH.md MI section). Provisional pre-primary field (FL-151 D-04),
--   culled >= 2026-08-05 in Phase 159-05. ANTIPARTISAN INVARIANT: party is NEVER stored on
--   race_candidates; races.primary_party stays NULL. MI-10/MI-11 are OPEN SEATS (James->Gov,
--   Stevens->Senate) but their district offices already exist -- NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MI 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'MI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MI 2026 Statewide General');

-- 13 provisional races on the EXISTING MI NATIONAL_LOWER US Rep offices (geo 2601..2613)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '26'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'MI 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
