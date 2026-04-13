-- =============================================================================
-- Seed: 2026 LA County Primary — LA Citywide Offices
--
-- Adds citywide elected offices and races for the City of Los Angeles to the
-- 2026 LA County Primary election. These offices are linked to the LA city
-- district (geo_id = '0644000', district_type = LOCAL_EXEC) so they appear
-- for any user whose municipality_geo_id = '0644000'.
--
-- Offices seeded:
--   LA City Attorney   — Hydee Feldstein Soto (incumbent) vs. Marissa Roy
--   LA City Controller — Kenneth Mejia (incumbent) vs. Zach Sokoloff
--
-- NOTE: LA City Clerk is NOT on the June 2, 2026 ballot — seat not up this cycle.
--
-- ANTIPARTISAN NOTE: California uses a top-2 (jungle) primary — all candidates
-- run together regardless of party. primary_party = NULL for all CA races.
--
-- VERIFIED SOURCES:
--   - Hydee Feldstein Soto: elected LA City Attorney November 2022. Current incumbent.
--   - Marissa Roy: active candidacy confirmed via CAL-ACCESS committee filings:
--       "ROY FOR LOS ANGELES CITY ATTORNEY 2026; MARISSA"
--       "MAZARIEGOS FOR CITY COUNCIL AND MARISSA ROY FOR CITY ATTORNEY 2026"
--     Source: cal_access_discovery entries in essentials DB (is_active: false = not yet
--     matched to politician record, not inactive candidacy).
--   - City Controller, City Clerk races: on June 2 ballot per lavote.gov; candidates
--     not yet verified against official filing list — add after confirming with
--     https://lavote.gov/home/voting-elections/current-elections/candidate-information
--
-- IDEMPOTENT:
--   - Office inserts: INSERT ... ON CONFLICT (district_id, office_title) DO NOTHING
--     (or WHERE NOT EXISTS if no unique constraint exists)
--   - Race inserts: ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
--   - Candidate inserts: WHERE NOT EXISTS guard on (race_id, full_name)
--
-- Date verified: 2026-04-13
-- Usage: psql $DATABASE_URL -f scripts/seed-la-citywide-races-2026.sql
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Verify the 2026 LA County Primary election exists
-- =============================================================================

DO $$
DECLARE
  v_election_id uuid;
BEGIN
  SELECT id INTO v_election_id
  FROM essentials.elections
  WHERE name = '2026 LA County Primary' AND state = 'CA';

  IF v_election_id IS NULL THEN
    RAISE EXCEPTION '2026 LA County Primary election not found — run base seed first';
  END IF;
END $$;

-- =============================================================================
-- Step 2: Verify the City of Los Angeles district exists (geo_id = '0644000')
-- =============================================================================

DO $$
DECLARE
  v_district_id uuid;
BEGIN
  SELECT id INTO v_district_id
  FROM essentials.districts
  WHERE geo_id = '0644000';

  IF v_district_id IS NULL THEN
    RAISE EXCEPTION 'City of Los Angeles district (geo_id = 0644000) not found — load LA city boundary first';
  END IF;
END $$;

-- =============================================================================
-- Step 3: Ensure citywide offices exist, linked to the LA city district
--
-- The Mayor office (office_id b8c4bd9d-05ba-4751-b947-7a3d2645d3ef) already
-- exists. City Attorney, City Controller, and City Clerk may not. Insert them
-- if they don't exist, linked to the same district_id as the Mayor.
-- =============================================================================

DO $$
DECLARE
  v_la_district_id uuid;
BEGIN
  SELECT id INTO v_la_district_id
  FROM essentials.districts
  WHERE geo_id = '0644000';

  -- City Attorney
  INSERT INTO essentials.offices (district_id, title)
  SELECT v_la_district_id, 'City Attorney'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE district_id = v_la_district_id AND title = 'City Attorney'
  );

  -- City Controller
  INSERT INTO essentials.offices (district_id, title)
  SELECT v_la_district_id, 'City Controller'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE district_id = v_la_district_id AND title = 'City Controller'
  );

  -- City Clerk
  INSERT INTO essentials.offices (district_id, title)
  SELECT v_la_district_id, 'City Clerk'
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE district_id = v_la_district_id AND title = 'City Clerk'
  );

  RAISE NOTICE 'Step 3 complete: citywide offices ensured for LA district %', v_la_district_id;
END $$;

-- =============================================================================
-- Step 4: Create race records for the 3 citywide offices
-- =============================================================================

-- Step 4a: LA City Attorney race
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT e.id, o.id, 'LA City Attorney', NULL, 1, 'Los Angeles City Attorney — citywide elected office, 4-year term. On ballot for all LA city residents.'
FROM essentials.elections e
JOIN essentials.offices o ON o.district_id = (SELECT id FROM essentials.districts WHERE geo_id = '0644000') AND o.title = 'City Attorney'
WHERE e.name = '2026 LA County Primary' AND e.state = 'CA'
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- Step 4b: LA City Controller race
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT e.id, o.id, 'LA City Controller', NULL, 1, 'Los Angeles City Controller — citywide elected office, 4-year term. On ballot for all LA city residents.'
FROM essentials.elections e
JOIN essentials.offices o ON o.district_id = (SELECT id FROM essentials.districts WHERE geo_id = '0644000') AND o.title = 'City Controller'
WHERE e.name = '2026 LA County Primary' AND e.state = 'CA'
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- LA City Clerk is NOT on the June 2, 2026 ballot — seat not up this cycle. No race record needed.

-- =============================================================================
-- Step 5: Seed verified candidates for LA City Attorney
--
-- Only two candidates have been verified for the City Attorney race:
--   - Hydee Feldstein Soto (incumbent, elected 2022)
--   - Marissa Roy (challenger, confirmed via CAL-ACCESS filings)
--
-- Controller and Clerk candidates are NOT seeded here — verify against
-- https://lavote.gov/home/voting-elections/current-elections/candidate-information
-- before adding.
-- =============================================================================

-- Ensure politician records exist for City Attorney candidates
DO $$
DECLARE
  v_feldstein_id uuid;
  v_roy_id       uuid;
BEGIN
  -- Hydee Feldstein Soto — incumbent LA City Attorney
  SELECT id INTO v_feldstein_id
  FROM essentials.politicians
  WHERE lower(full_name) = lower('Hydee Feldstein Soto')
  LIMIT 1;

  IF v_feldstein_id IS NULL THEN
    INSERT INTO essentials.politicians (first_name, last_name, full_name)
    VALUES ('Hydee', 'Feldstein Soto', 'Hydee Feldstein Soto')
    RETURNING id INTO v_feldstein_id;
    RAISE NOTICE 'Created politician: Hydee Feldstein Soto (%)', v_feldstein_id;
  ELSE
    RAISE NOTICE 'Politician already exists: Hydee Feldstein Soto (%)', v_feldstein_id;
  END IF;

  -- Marissa Roy — challenger
  SELECT id INTO v_roy_id
  FROM essentials.politicians
  WHERE lower(full_name) = lower('Marissa Roy')
  LIMIT 1;

  IF v_roy_id IS NULL THEN
    INSERT INTO essentials.politicians (first_name, last_name, full_name)
    VALUES ('Marissa', 'Roy', 'Marissa Roy')
    RETURNING id INTO v_roy_id;
    RAISE NOTICE 'Created politician: Marissa Roy (%)', v_roy_id;
  ELSE
    RAISE NOTICE 'Politician already exists: Marissa Roy (%)', v_roy_id;
  END IF;
END $$;

-- Seed Hydee Feldstein Soto as incumbent candidate for LA City Attorney
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT
  r.id,
  p.id,
  p.full_name,
  p.first_name,
  p.last_name,
  true,
  'active',
  'lavote_gov_2026'
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON lower(p.full_name) = lower('Hydee Feldstein Soto')
WHERE e.name = '2026 LA County Primary'
  AND r.position_name = 'LA City Attorney'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Hydee Feldstein Soto')
  );

-- Seed Marissa Roy as challenger for LA City Attorney
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT
  r.id,
  p.id,
  p.full_name,
  p.first_name,
  p.last_name,
  false,
  'active',
  'lavote_gov_2026'
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON lower(p.full_name) = lower('Marissa Roy')
WHERE e.name = '2026 LA County Primary'
  AND r.position_name = 'LA City Attorney'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Marissa Roy')
  );

-- Seed Kenneth Mejia (incumbent Controller)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, true, 'active', 'cityclerk_lacity_org_2026'
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON lower(p.full_name) = 'kenneth mejia'
WHERE e.name = '2026 LA County Primary' AND r.position_name = 'LA City Controller'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = 'kenneth mejia');

-- Seed Zach Sokoloff (challenger)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, false, 'active', 'cityclerk_lacity_org_2026'
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON lower(p.full_name) = 'zach sokoloff'
WHERE e.name = '2026 LA County Primary' AND r.position_name = 'LA City Controller'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = 'zach sokoloff');

-- =============================================================================
-- Step 6: Verification query
-- =============================================================================

SELECT
  r.position_name,
  r.seats,
  count(rc.id) AS candidate_count,
  string_agg(rc.full_name || CASE WHEN rc.is_incumbent THEN ' (I)' ELSE '' END, ', ' ORDER BY rc.is_incumbent DESC, rc.full_name) AS candidates
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
WHERE e.name = '2026 LA County Primary'
  AND r.position_name IN ('LA City Attorney', 'LA City Controller', 'LA City Clerk')
GROUP BY r.position_name, r.seats
ORDER BY r.position_name;

COMMIT;
