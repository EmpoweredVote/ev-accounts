-- =============================================================================
-- Seed: Salt Lake County 2026 Primary — Races & Candidates
--
-- Sources:
--   - SLCo GOP 2026 Convention results (slcogop.com/2026-county-convention)
--   - SLCo Dems 2026 candidates (slcountydems.com/2026candidates)
--   - SLCo Dems 2026 convention results (slcountydems.com/2026-convention-election-results)
--   - Wikipedia: 2026 Salt Lake County elections
--   - Campaign sites (kathleen4council.com, electmikebird.com, votechrisnull.com,
--                     traci4countycouncil.com, chris4auditor.com)
--
-- Election date: June 23, 2026 (Utah partisan primary)
--
-- IMPORTANT: County Mayor (Jenny Wilson), Assessor (Chris Stavros), Recorder,
-- and Treasurer are NOT on the 2026 ballot (elected in off-years; next up 2028).
--
-- County Council seats up in 2026: At-Large A, Districts 1, 3, 5
-- (Districts 2, 4, 6 and At-Large B, C were up in 2024 — not this cycle)
--
-- Convention-nominated candidates (no primary ballot appearance) are still
-- seeded so they appear in the elections-by-address feed for the cycle.
--
-- This script is IDEMPOTENT — safe to re-run without creating duplicates.
-- - Election: ON CONFLICT (name, election_date, state) DO UPDATE
-- - Races: ON CONFLICT (election_id, position_name, primary_party) DO UPDATE
-- - Candidates: INSERT ... WHERE NOT EXISTS (race_id, full_name)
--
-- Incumbent politician_id links (from essentials.politicians):
--   Lannie Chapman  (Clerk, D)   — 9b02727d-1e6a-424a-9f0f-9db5b0ecc6fa
--   Chris Harding   (Auditor, R) — 5b3c303d-066c-4828-a241-a39df55dfaef
--   Rosie Rivera    (Sheriff, D) — 8c34f0b8-4201-49b4-95a2-d043e99a3eef
--   Sim Gill        (DA, D)      — 77256186-0ce8-4069-9d06-1d2fd5b4b622
--
-- Usage: psql $DATABASE_URL -f scripts/seed-ut-2026-06-23-primary-slco.sql
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Upsert the election (shares record with UT state/federal races)
-- =============================================================================

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state, description)
VALUES (
  '2026 Utah Primary',
  '2026-06-23',
  'primary',
  'state',
  'UT',
  'Utah 2026 Primary — federal, state, and county races (Salt Lake County county races included)'
)
ON CONFLICT (name, election_date, state)
DO UPDATE SET
  description = EXCLUDED.description,
  updated_at = now();

-- =============================================================================
-- Step 2: Upsert all Salt Lake County races
--
-- office_id = NULL for all county races: they are served by electionService
-- Part B (r.office_id IS NULL AND e.state = 'UT') and appear for all addresses
-- in Salt Lake County via the county geofence. District-specific office_id
-- backfill is a follow-up task once county council district offices are loaded.
-- =============================================================================

WITH election AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT e.id, NULL, v.position_name, v.primary_party, v.seats, v.description
FROM election e,
(VALUES
  -- County Council At-Large Seat A (6-year term; incumbent Laurie Stringham not seeking re-election)
  ('Salt Lake County Council At-Large A', 'Republican', 1, 'SLCo Council At-Large Seat A — Republican (convention nominee: Kathleen Anderson)'),
  ('Salt Lake County Council At-Large A', 'Democratic', 1, 'SLCo Council At-Large Seat A — Democratic (convention nominee: Zach Robinson)'),

  -- County Council District 1 (4-year term; incumbent Jiro Johnson, D, appointed)
  ('Salt Lake County Council District 1', 'Democratic', 1, 'SLCo Council District 1 — Democratic'),

  -- County Council District 3 (4-year term; open seat — Aimee Winder Newton, R, not seeking 4th term)
  ('Salt Lake County Council District 3', 'Republican', 1, 'SLCo Council District 3 — Republican (convention nominee: Mike Bird)'),
  ('Salt Lake County Council District 3', 'Democratic', 1, 'SLCo Council District 3 — Democratic (convention nominee: Luke Maynes)'),

  -- County Council District 5 (4-year term; open seat — Sheldon Stewart, R, withdrew)
  -- REPUBLICAN PRIMARY: Chris Null vs Traci Crockett (both cleared convention threshold)
  ('Salt Lake County Council District 5', 'Republican', 1, 'SLCo Council District 5 — Republican Primary'),
  ('Salt Lake County Council District 5', 'Democratic', 1, 'SLCo Council District 5 — Democratic (convention nominee: Sara Cimmers)'),

  -- County Auditor (incumbent Chris Harding, R; no primary for either party)
  ('Salt Lake County Auditor', 'Republican', 1, 'SLCo Auditor — Republican (convention nominee: Chris Harding, incumbent)'),
  ('Salt Lake County Auditor', 'Democratic', 1, 'SLCo Auditor — Democratic (convention nominee: Ali Cloward)'),

  -- County Clerk (incumbent Lannie Chapman, D; no Republican opposition found)
  ('Salt Lake County Clerk', 'Democratic', 1, 'SLCo Clerk — Democratic (convention nominee: Lannie Chapman, incumbent)'),

  -- County District Attorney (DEMOCRATIC PRIMARY: Sim Gill vs Shawn Robinson)
  ('Salt Lake County District Attorney', 'Republican', 1, 'SLCo District Attorney — Republican (convention nominee: Kent Davis)'),
  ('Salt Lake County District Attorney', 'Democratic', 1, 'SLCo District Attorney — Democratic Primary (Sim Gill vs Shawn Robinson)'),

  -- County Sheriff (REPUBLICAN PRIMARY: Shane Manwaring vs Nicholas Roberts)
  ('Salt Lake County Sheriff', 'Republican', 1, 'SLCo Sheriff — Republican Primary'),
  ('Salt Lake County Sheriff', 'Democratic', 1, 'SLCo Sheriff — Democratic (convention nominee: Rosie Rivera, incumbent)')

) AS v(position_name, primary_party, seats, description)
ON CONFLICT (election_id, position_name, primary_party)
DO UPDATE SET
  seats = EXCLUDED.seats,
  description = EXCLUDED.description,
  updated_at = now();

-- =============================================================================
-- Step 3: Insert candidates (idempotent via NOT EXISTS on race_id + full_name)
-- =============================================================================

-- ---- County Council At-Large A ----

-- At-Large A — Republican (Kathleen Anderson, convention nominee, no primary)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', 'slco_gop_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Council At-Large A' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Kathleen Anderson', 'Kathleen', 'Anderson', false)
) AS v(full_name, first_name, last_name, is_incumbent)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- At-Large A — Democratic (Zach Robinson, convention nominee, no primary)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', 'slco_dems_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Council At-Large A' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Zach Robinson', 'Zach', 'Robinson', false)
) AS v(full_name, first_name, last_name, is_incumbent)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- ---- County Council District 1 ----

-- District 1 — Democratic (Jiro Johnson, appointed incumbent; no Republican opposition)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', 'slco_dems_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Council District 1' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Jiro Johnson', 'Jiro', 'Johnson', true)
) AS v(full_name, first_name, last_name, is_incumbent)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- ---- County Council District 3 ----

-- District 3 — Republican (Mike Bird, convention nominee, no primary)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', 'slco_gop_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Council District 3' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Mike Bird', 'Mike', 'Bird', false)
) AS v(full_name, first_name, last_name, is_incumbent)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- District 3 — Democratic (Luke Maynes, convention nominee, no primary)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', 'slco_dems_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Council District 3' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Luke Maynes', 'Luke', 'Maynes', false)
) AS v(full_name, first_name, last_name, is_incumbent)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- ---- County Council District 5 ----

-- District 5 — Republican PRIMARY (Chris Null vs Traci Crockett; both cleared convention)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', 'slco_gop_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Council District 5' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Chris Null',     'Chris',  'Null',    false),
  ('Traci Crockett', 'Traci',  'Crockett', false)
) AS v(full_name, first_name, last_name, is_incumbent)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- District 5 — Democratic (Sara Cimmers, convention nominee)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', 'slco_dems_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Council District 5' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Sara Cimmers', 'Sara', 'Cimmers', false)
) AS v(full_name, first_name, last_name, is_incumbent)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- ---- County Auditor ----

-- Auditor — Republican (Chris Harding, incumbent, linked to existing politician record)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, '5b3c303d-066c-4828-a241-a39df55dfaef'::uuid, 'Chris Harding', 'Chris', 'Harding', true, 'active', 'slco_gop_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Auditor' AND r.primary_party = 'Republican'
) race
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = 'Chris Harding'
);

-- Auditor — Democratic (Ali Cloward, convention nominee)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, 'Ali Cloward', 'Ali', 'Cloward', false, 'active', 'slco_dems_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Auditor' AND r.primary_party = 'Democratic'
) race
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = 'Ali Cloward'
);

-- Add campaign website for Chris Harding
INSERT INTO essentials.politician_contacts (politician_id, contact_type, website_url, source)
SELECT '5b3c303d-066c-4828-a241-a39df55dfaef', 'campaign', 'https://chris4auditor.com', 'manual'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts
  WHERE politician_id = '5b3c303d-066c-4828-a241-a39df55dfaef'
    AND contact_type = 'campaign'
    AND website_url = 'https://chris4auditor.com'
);

-- ---- County Clerk ----

-- Clerk — Democratic (Lannie Chapman, incumbent, linked to existing politician record)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, '9b02727d-1e6a-424a-9f0f-9db5b0ecc6fa'::uuid, 'Lannie Chapman', 'Lannie', 'Chapman', true, 'active', 'slco_dems_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Clerk' AND r.primary_party = 'Democratic'
) race
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = 'Lannie Chapman'
);

-- ---- County District Attorney ----

-- DA — Republican (Kent Davis, convention nominee, no primary)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, 'Kent Davis', 'Kent', 'Davis', false, 'active', 'slco_gop_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County District Attorney' AND r.primary_party = 'Republican'
) race
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = 'Kent Davis'
);

-- DA — Democratic PRIMARY (Sim Gill, incumbent, vs Shawn Robinson)
-- Sim Gill — linked to existing politician record
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, '77256186-0ce8-4069-9d06-1d2fd5b4b622'::uuid, 'Sim Gill', 'Sim', 'Gill', true, 'active', 'slco_dems_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County District Attorney' AND r.primary_party = 'Democratic'
) race
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = 'Sim Gill'
);

-- Shawn Robinson — challenger
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, 'Shawn Robinson', 'Shawn', 'Robinson', false, 'active', 'slco_dems_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County District Attorney' AND r.primary_party = 'Democratic'
) race
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = 'Shawn Robinson'
);

-- ---- County Sheriff ----

-- Sheriff — Republican PRIMARY (Shane Manwaring vs Nicholas Roberts)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', 'slco_gop_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Sheriff' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Shane Manwaring',   'Shane',    'Manwaring', false),
  ('Nicholas Roberts',  'Nicholas', 'Roberts',   false)
) AS v(full_name, first_name, last_name, is_incumbent)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Sheriff — Democratic (Rosie Rivera, incumbent, linked to existing politician record)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, '8c34f0b8-4201-49b4-95a2-d043e99a3eef'::uuid, 'Rosie Rivera', 'Rosie', 'Rivera', true, 'active', 'slco_dems_convention'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Utah Primary' AND e.election_date = '2026-06-23' AND e.state = 'UT'
    AND r.position_name = 'Salt Lake County Sheriff' AND r.primary_party = 'Democratic'
) race
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = 'Rosie Rivera'
);

-- Note: Kathleen Anderson (At-Large A, R) campaign site: https://www.kathleen4council.com
-- No politician record yet — contact stored in race_candidates row only until record is created.

COMMIT;

-- =============================================================================
-- Verification queries (run after COMMIT to confirm)
-- =============================================================================

-- Race + candidate counts:
-- SELECT r.position_name, r.primary_party, COUNT(rc.id) AS candidates
-- FROM essentials.races r
-- JOIN essentials.elections e ON r.election_id = e.id
-- LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
-- WHERE e.name = '2026 Utah Primary' AND e.state = 'UT'
--   AND r.position_name ILIKE '%Salt Lake County%'
-- GROUP BY r.position_name, r.primary_party ORDER BY r.position_name, r.primary_party;
--
-- Expected: 14 races, ~20 candidates total
-- Active primaries: DA-D (2 candidates), Sheriff-R (2), Council D5-R (2)
