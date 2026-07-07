-- 1226_seed_al_2026_house_elections_races.sql
-- Phase 163-04 Task 2: AL 2026 Statewide General election + a dedicated NON-GENERAL
-- "AL 2026 Congressional Redistricting - Polygon Pending" election, + 7 severity-routed U.S. House
-- races. Field source: 160-field-table-p163.csv (AL rows), Wikipedia 2026 US House elections in Alabama.
-- ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
--
-- SPLIT-STATE PRIMARY TIMING: AL-1/2/6/7 are late-primary (Aug-11 SCOTUS-ordered special primary) ->
-- PROVISIONAL descriptions, cull >= 2026-08-12; AL-3/4/5 decided -> plain general descriptions.
--
-- D-01b SEVERE-DISTRICT WITHHOLDING: per 163-al-correspondence-audit.md ("Severe geo_id list: 0102"),
-- ONLY AL-2 (0102) shifted severely under the SCOTUS-stayed 2023 map; its race is wired to the withheld
-- "Polygon Pending" election (election_type='special', election_date='2026-06-02' = the SCOTUS
-- stay date, >30 days past at execution) so electionService.ts's ELECTION_VISIBILITY_WINDOW evaluates
-- FALSE for it. office_id is NEVER null for ANY AL race (severe or not) -- it is ALWAYS the district's
-- EXISTING NATIONAL_LOWER office (D-01). essentials.offices is NEVER touched by this migration -- the
-- reps feed continues to show the true incumbent for every AL district. AL-1/6/7 required the special
-- primary but scored NOT-SEVERE (anchors preserved) so they surface normally (PROVISIONAL general).
-- 164.1 un-withholds AL-2 on polygon refresh.
BEGIN;

-- 2 elections (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'AL 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'AL'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'AL 2026 Statewide General');

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'AL 2026 Congressional Redistricting - Polygon Pending', '2026-06-02'::date, 'special', 'state', 'AL'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'AL 2026 Congressional Redistricting - Polygon Pending');

-- 7 severity-routed races (6 general + 1 withheld AL-2); office_id ALWAYS the existing old-CD office
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '0101'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AL 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12 -- SEEDED-BUT-WITHHELD (D-01b): new-map field vs. old-map polygon, see 163-al-correspondence-audit.md'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '0102'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AL 2026 Congressional Redistricting - Polygon Pending'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed nominees (AL primary decided)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '0103'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AL 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed nominees (AL primary decided)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '0104'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AL 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'Confirmed nominees (AL primary decided)'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '0105'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AL 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '0106'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AL 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '0107'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AL 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
