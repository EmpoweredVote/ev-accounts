-- =============================================================================
-- Migration 076: Pasadena June 2, 2026 races + candidates
--
-- Seeds 3 council races (Districts 3, 5, 7) and 5 candidates.
-- Fixes the discovery_jurisdictions election_date for Pasadena (was 2026-11-03,
-- should be 2026-06-02 to match the primary).
-- Updates discovery source_url and allowed_domains for Pasadena.
--
-- Office mapping (incumbents already in DB):
--   D3 → Justin Jones  office: e3617ff5-4a83-4bbb-8fe8-eaff01d877b1
--   D7 → Jason Lyon    office: 0cd97f4e-ce8c-4280-b8cd-24800e047d17
--   D5 → Jess Rivas    (new office, no existing DB row for Rivas)
--
-- Source: City of Pasadena City Clerk + LAist voter guides
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id UUID := '1ebca37f-cf96-47f4-bc2b-47ef266721fe'; -- 2026 LA County Primary
  v_office_d3   UUID := 'e3617ff5-4a83-4bbb-8fe8-eaff01d877b1'; -- Justin Jones
  v_office_d7   UUID := '0cd97f4e-ce8c-4280-b8cd-24800e047d17'; -- Jason Lyon
  v_office_d5   UUID;
  v_race_d3     UUID;
  v_race_d5     UUID;
  v_race_d7     UUID;
BEGIN

  -- Create D5 office for Jess Rivas (not in DB yet)
  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Pasadena', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_d5;

  -- Seed races
  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_d3, 'Pasadena City Council District 3', 1)
  RETURNING id INTO v_race_d3;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_d5, 'Pasadena City Council District 5', 1)
  RETURNING id INTO v_race_d5;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_d7, 'Pasadena City Council District 7', 1)
  RETURNING id INTO v_race_d7;

  -- District 3 candidates
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  VALUES (v_race_d3, 'Justin Jones', 'Justin', 'Jones', 'Civil Engineer, Los Angeles County', true, 'https://www.justinljonespasadena.com', 'clerk_official');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source)
  VALUES (v_race_d3, 'Erica Margarita Múnoz', 'Erica', 'Múnoz', 'Housing Navigator, Union Station Homeless Services', false, 'clerk_official');

  -- District 5 candidates (unopposed)
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  VALUES (v_race_d5, 'Jess Rivas', 'Jess', 'Rivas', 'Attorney', true, 'https://www.jessforpasadena.com', 'clerk_official');

  -- District 7 candidates
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  VALUES (v_race_d7, 'Jason Lyon', 'Jason', 'Lyon', 'Attorney', true, 'https://www.jasonlyonforpasadena.com', 'clerk_official');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source)
  VALUES (v_race_d7, 'Alethea O''Toole', 'Alethea', 'O''Toole', 'Small Business Owner/Accountant', false, 'clerk_official');

END $$;

-- Fix discovery_jurisdictions: wrong election_date + update source
UPDATE essentials.discovery_jurisdictions
SET
  election_date = '2026-06-02',
  source_url    = 'https://www.cityofpasadena.net/city-clerk/primary-elections-2026/',
  allowed_domains = ARRAY['cityofpasadena.net', 'ballotpedia.org']
WHERE jurisdiction_name = 'Pasadena';

COMMIT;
