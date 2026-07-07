-- 1228_seed_la_2026_house_elections_races.sql
-- Phase 163-06 Task 2: LA 2026 Statewide General election + a dedicated NON-GENERAL
-- "LA 2026 Congressional Redistricting - Polygon Pending" election, + 6 JUNGLE U.S. House races.
-- JUNGLE MODEL: each district = EXACTLY ONE race with primary_party=NULL; ALL qualified candidates
-- (incumbent + every party) are wired to that single race (CA convention). NO per-party primary races.
-- NO December-2026 runoff election/race (deferred to Phase 167 -- unknowable until Nov-3 results).
-- Field source: 160-field-table-p163.csv (LA rows), Wikipedia 2026 US House elections in Louisiana.
-- ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
-- All 6 districts late-primary (qualifying closes 2026-08-07) -> PROVISIONAL declared-so-far.
--
-- D-01b SEVERE-DISTRICT WITHHOLDING: per 163-la-correspondence-audit.md ("Severe geo_id list: 2202,
-- 2206"), LA-2 (2202) and LA-6 (2206) shifted severely under SB121/Act 2 (dissolved CD-6); their races
-- are wired to the withheld "Polygon Pending" election (election_type='special', election_date=
-- '2026-05-29' = the SB121 signing date, >30 days past at execution) so electionService.ts's
-- ELECTION_VISIBILITY_WINDOW evaluates FALSE. office_id is NEVER null for ANY LA race -- it is ALWAYS
-- the district's EXISTING NATIONAL_LOWER office (D-01). essentials.offices is NEVER touched. 164.1
-- un-withholds LA-2/LA-6 on polygon refresh.
BEGIN;

-- 2 elections (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'LA 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'LA'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'LA 2026 Statewide General');

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'LA 2026 Congressional Redistricting - Polygon Pending', '2026-05-29'::date, 'special', 'state', 'LA'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'LA 2026 Congressional Redistricting - Polygon Pending');

-- 6 jungle races (one per district, primary_party NULL; 4 general + 2 withheld LA-2/LA-6)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '2201'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'LA 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: declared-so-far field, re-pull after 2026-08-07 qualifying close -- SEEDED-BUT-WITHHELD (D-01b): new-map field vs. old-map polygon, see 163-la-correspondence-audit.md'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '2202'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'LA 2026 Congressional Redistricting - Polygon Pending'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '2203'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'LA 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '2204'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'LA 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: declared-so-far field, re-pull after 2026-08-07 qualifying close'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '2205'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'LA 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: declared-so-far field, re-pull after 2026-08-07 qualifying close -- SEEDED-BUT-WITHHELD (D-01b): new-map field vs. old-map polygon, see 163-la-correspondence-audit.md'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '2206'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'LA 2026 Congressional Redistricting - Polygon Pending'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
