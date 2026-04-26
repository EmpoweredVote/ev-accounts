-- =============================================================================
-- Migration 079: Pomona June 2, 2026 races + candidates + discovery jurisdiction
--
-- Races on ballot: City Council Districts 2, 3, 5
-- No citywide offices (Mayor Tim Sandoval re-elected Nov 2024; Clerk/Treasurer
-- are on different cycles or appointed)
--
-- D5 is an open seat — incumbent Steve Lustro not seeking reelection.
-- D2 may be unopposed — only Victor Preciado found; verify with City Clerk.
--
-- Source: Ballotpedia, pomonaca.gov, campaign websites
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id UUID := '1ebca37f-cf96-47f4-bc2b-47ef266721fe';
  v_office_d2   UUID;
  v_office_d3   UUID;
  v_office_d5   UUID;
  v_race_d2     UUID;
  v_race_d3     UUID;
  v_race_d5     UUID;
BEGIN

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Pomona', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_d2;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Pomona', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_d3;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Councilmember', 'Pomona', 'CA', 'Council Member', 1)
  RETURNING id INTO v_office_d5;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_d2, 'Pomona City Council District 2', 1)
  RETURNING id INTO v_race_d2;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_d3, 'Pomona City Council District 3', 1)
  RETURNING id INTO v_race_d3;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats)
  VALUES (v_election_id, v_office_d5, 'Pomona City Council District 5', 1)
  RETURNING id INTO v_race_d5;

  -- -----------------------------------------------------------------------
  -- District 2 — Victor Preciado (incumbent; no opponent confirmed)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source) VALUES
    (v_race_d2, 'Victor Preciado', 'Victor', 'Preciado', 'City Councilmember', true, 'https://www.victorforpomona.com', 'clerk_official');

  -- -----------------------------------------------------------------------
  -- District 3
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source) VALUES
    (v_race_d3, 'Nora Garcia',       'Nora',     'Garcia',  'Councilmember, City of Pomona', true,  'https://www.noraforpomona.com',          'clerk_official'),
    (v_race_d3, 'Veronica Cabrera',  'Veronica', 'Cabrera', 'Real Estate Broker',            false, 'https://www.veronicacabrerapomona.com',  'clerk_official');

  -- -----------------------------------------------------------------------
  -- District 5 — open seat (Lustro not running)
  -- -----------------------------------------------------------------------
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source) VALUES
    (v_race_d5, 'Yvonne Cobarrubias', 'Yvonne',  'Cobarrubias', NULL, false, 'https://www.yvonne-cobarrubias.com', 'clerk_official'),
    (v_race_d5, 'Elliott Rothman',    'Elliott', 'Rothman',     NULL, false, NULL,                                'clerk_official');

END $$;

-- Add Pomona to discovery_jurisdictions
INSERT INTO essentials.discovery_jurisdictions (
  jurisdiction_geoid,
  jurisdiction_name,
  state,
  election_date,
  source_url,
  allowed_domains
) VALUES (
  '0657764',
  'Pomona',
  'CA',
  '2026-06-02',
  'https://www.pomonaca.gov/government/departments/city-clerk/elections-information',
  ARRAY['pomonaca.gov', 'ballotpedia.org']
);

COMMIT;
