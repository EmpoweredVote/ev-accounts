-- =============================================================================
-- Migration 080: Covina June 2, 2026 races + candidates + discovery jurisdiction
--
-- Races on ballot: City Council Districts 1, 3, 5 + City Clerk + City Treasurer
--
-- Notes:
--   D1: Hector Delgado (incumbent, current Mayor) — no opponent confirmed
--   D5: Open seat — John King (incumbent) did not file; Drew Aleman (current
--       City Clerk) running for Council instead of reelection to Clerk
--   City Clerk: open race — Aleman running for Council, not reelection
--
-- Source: Covina Certified List of Qualified Candidates (covinaca.gov),
--         Ballotpedia, LACDP endorsements
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id   UUID := '1ebca37f-cf96-47f4-bc2b-47ef266721fe';
  v_office_d1     UUID;
  v_office_d3     UUID;
  v_office_d5     UUID;
  v_office_clerk  UUID;
  v_office_treas  UUID;
  v_race_d1       UUID;
  v_race_d3       UUID;
  v_race_d5       UUID;
  v_race_clerk    UUID;
  v_race_treas    UUID;
BEGIN

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Covina', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_d1;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Covina', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_d3;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Covina', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_d5;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('City Clerk', 'Covina', 'CA', 'City Clerk', 1)
  RETURNING id INTO v_office_clerk;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('City Treasurer', 'Covina', 'CA', 'City Treasurer', 1)
  RETURNING id INTO v_office_treas;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_d1, 'Covina City Council District 1', 1)
  RETURNING id INTO v_race_d1;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_d3, 'Covina City Council District 3', 1)
  RETURNING id INTO v_race_d3;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_d5, 'Covina City Council District 5', 1)
  RETURNING id INTO v_race_d5;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_clerk, 'Covina City Clerk', 1)
  RETURNING id INTO v_race_clerk;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_treas, 'Covina City Treasurer', 1)
  RETURNING id INTO v_race_treas;

  -- -----------------------------------------------------------------------
  -- District 1 — Hector Delgado (incumbent; no opponent confirmed)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source) VALUES
    (v_race_d1, 'Hector Delgado', 'Hector', 'Delgado', 'Councilmember, City of Covina', true, 'clerk_official');

  -- -----------------------------------------------------------------------
  -- District 3
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source) VALUES
    (v_race_d3, 'Victor Linares',   'Victor',  'Linares',  'Councilmember, City of Covina',   true,  'https://www.linaresforcovina.com', 'clerk_official'),
    (v_race_d3, 'Adrian Fernandez', 'Adrian',  'Fernandez','Technology Product Director',      false, NULL,                              'clerk_official'),
    (v_race_d3, 'Sarah Rizvi',      'Sarah',   'Rizvi',    'Grant Writer/Instructor',          false, NULL,                              'clerk_official');

  -- -----------------------------------------------------------------------
  -- District 5 — open seat (King not filing; Aleman leaving Clerk for Council)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source) VALUES
    (v_race_d5, 'Bri Sérráno',    'Bri',    'Sérráno', 'College Assistant Dean', false, 'https://www.serrano4covina.com',   'clerk_official'),
    (v_race_d5, 'Andrew Aleman',  'Andrew', 'Aleman',  'City Clerk/Teacher',     false, 'https://www.drewforcovina.com',    'clerk_official');

  -- -----------------------------------------------------------------------
  -- City Clerk — open race (Aleman vacating to run for Council)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source) VALUES
    (v_race_clerk, 'Rosie Richardson', 'Rosie', 'Richardson', 'Public Outreach Manager', false, 'https://www.rosierichardson.com',  'clerk_official'),
    (v_race_clerk, 'Susan Zermeno',    'Susan', 'Zermeno',    'Retired City Planner',    false, 'https://www.zermeno4clerk.com',    'clerk_official');

  -- -----------------------------------------------------------------------
  -- City Treasurer
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source) VALUES
    (v_race_treas, 'Neil Polzin',      'Neil',   'Polzin', 'City Treasurer, City of Covina', true,  'https://www.neil4covina.com', 'clerk_official'),
    (v_race_treas, 'Thomas Nass',      'Thomas', 'Nass',   'Senior Transit Executive',       false, NULL,                         'clerk_official');

END $$;

-- Add Covina to discovery_jurisdictions
INSERT INTO essentials.discovery_jurisdictions (
  jurisdiction_geoid,
  jurisdiction_name,
  state,
  election_date,
  source_url,
  allowed_domains
) VALUES (
  '0616742',
  'Covina',
  'CA',
  '2026-06-02',
  'https://covinaca.gov/city-departments/city-clerk/elections-and-voting/',
  ARRAY['covinaca.gov', 'ballotpedia.org']
);

COMMIT;
