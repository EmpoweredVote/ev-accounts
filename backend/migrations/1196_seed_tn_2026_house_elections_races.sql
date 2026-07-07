-- 1196_seed_tn_2026_house_elections_races.sql
-- Phase 161-06 Task 1: TN 2026 Statewide General election + a dedicated, deliberately-NON-GENERAL
-- "TN 2026 Congressional Redistricting - Polygon Pending" election, + 9 provisional U.S. House races
-- (severity-routed per the 161-01 correspondence audit). Field source: 160-field-table-p161.csv (TN
-- rows), cross-checked Wikipedia "2026 United States House of Representatives elections in Tennessee"
-- (per-district pages) + the TN SOS certified candidate list (May 29, 2026). Provisional pre-primary
-- field (FL-151 D-04 pattern), culled >= 2026-08-07 (day after TN's Aug-6 primary).
-- ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
--
-- D-01b / SEVERE-DISTRICT WITHHOLDING (161-RESEARCH Pitfall 1): 5 of TN's 9 districts (geo_id
-- 4704, 4705, 4706, 4708, 4709) shifted so severely under the May 2026 mid-cycle redistricting that the
-- new-map candidate slate against the OLD-map polygon (essentials.districts, unchanged until Phase
-- 164.1) would actively mislead a voter. Their races are wired to the withheld "Polygon Pending"
-- election (election_type='special', election_date='2026-05-07', well over 30 days in the past) so
-- electionService.ts's ELECTION_VISIBILITY_WINDOW evaluates FALSE for them across all 3 query paths.
-- office_id is NEVER null for ANY TN race (severe or not) -- it is ALWAYS the district's EXISTING
-- old-CD NATIONAL_LOWER office (D-01). essentials.offices is NEVER touched by this migration -- the
-- reps feed continues to show the true old-map incumbent for every TN district, severe or not.
-- Non-severe districts (geo_id 4701, 4702, 4703, 4707) wire normally to the general election.
BEGIN;

-- 2 elections (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'TN 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'TN'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'TN 2026 Statewide General');

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'TN 2026 Congressional Redistricting - Polygon Pending', '2026-05-07'::date, 'special', 'state', 'TN'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'TN 2026 Congressional Redistricting - Polygon Pending');

-- 4 NOT-SEVERE races on the EXISTING TN NATIONAL_LOWER US Rep offices, wired to the general election
-- (geo 4701, 4702, 4703, 4707)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-07'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '47'
  AND d.geo_id = ANY(ARRAY['4701', '4702', '4703', '4707'])
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'TN 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

-- 5 SEVERE races -- office_id STILL the normal old-CD office (NEVER null); election_id points at the
-- withheld "Polygon Pending" election so the race never surfaces on /elections (D-01b)
-- (geo 4704, 4705, 4706, 4708, 4709)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-07 -- SEEDED-BUT-WITHHELD (D-01b): ' ||
       'new-map field vs. old-map polygon, see 161-tn-correspondence-audit.md'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '47'
  AND d.geo_id = ANY(ARRAY['4704', '4705', '4706', '4708', '4709'])
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'TN 2026 Congressional Redistricting - Polygon Pending'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
