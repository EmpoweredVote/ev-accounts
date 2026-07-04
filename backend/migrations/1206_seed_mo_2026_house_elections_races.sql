-- 1206_seed_mo_2026_house_elections_races.sql
-- Phase 162-02 Task 2: MO 2026 Statewide General election + a dedicated, deliberately-NON-GENERAL
-- "MO 2026 Congressional Redistricting - Polygon Pending" election, + 8 provisional U.S. House races
-- (severity-routed per the 162-01 correspondence audit). Field source: 160-field-table-p162.csv (MO
-- rows), cross-checked Wikipedia "2026 United States House of Representatives elections in Missouri"
-- (raw wikitext cites the MO SOS candidate filing list; the MO SOS ASPX pages are unfetchable).
-- Provisional pre-primary field (FL-151 D-04 pattern), culled >= 2026-08-05 (day after MO's Aug-4 primary).
-- ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
--
-- D-01b / SEVERE-DISTRICT WITHHOLDING (162-RESEARCH Pitfall 1): 5 of MO's 8 districts (geo_id
-- 2902, 2903, 2904, 2905, 2906) shifted so severely under the 2025 mid-decade redistricting that the
-- new-map candidate slate against the OLD-map polygon (essentials.districts, unchanged until Phase
-- 164.1) would actively mislead a voter. Their races are wired to the withheld "Polygon Pending"
-- election (election_type='special', election_date='2026-03-24' = the MO Supreme Court 4-3 upholding
-- date, well over 30 days in the past) so electionService.ts's ELECTION_VISIBILITY_WINDOW evaluates
-- FALSE for them across all 3 query paths.
-- office_id is NEVER null for ANY MO race (severe or not) -- it is ALWAYS the district's EXISTING
-- old-CD NATIONAL_LOWER office (D-01). essentials.offices is NEVER touched by this migration -- the
-- reps feed continues to show the true old-map incumbent for every MO district, severe or not.
-- Non-severe districts (geo_id 2901, 2907, 2908) wire normally to the general election.
-- NOTE (162-01 freshness flag): MO's general-election map is unsettled pending the veto referendum
-- (SoS signature certification ~2026-07-27); if it freezes/reverts, Phase 167 re-pulls MO. The D-01b
-- withholding hedges correctly either way.
BEGIN;

-- 2 elections (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MO 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'MO'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MO 2026 Statewide General');

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MO 2026 Congressional Redistricting - Polygon Pending', '2026-03-24'::date, 'special', 'state', 'MO'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MO 2026 Congressional Redistricting - Polygon Pending');

-- 3 NOT-SEVERE races on the EXISTING MO NATIONAL_LOWER US Rep offices, wired to the general election
-- (geo 2901, 2907, 2908)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '29'
  AND d.geo_id = ANY(ARRAY['2901', '2907', '2908'])
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'MO 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

-- 5 SEVERE races -- office_id STILL the normal old-CD office (NEVER null); election_id points at the
-- withheld "Polygon Pending" election so the race never surfaces on /elections (D-01b)
-- (geo 2902, 2903, 2904, 2905, 2906)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05 -- SEEDED-BUT-WITHHELD (D-01b): ' ||
       'new-map field vs. old-map polygon, see 162-mo-correspondence-audit.md'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '29'
  AND d.geo_id = ANY(ARRAY['2902', '2903', '2904', '2905', '2906'])
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'MO 2026 Congressional Redistricting - Polygon Pending'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
